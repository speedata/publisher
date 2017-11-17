// Package goxlsx accesses Excel 2007 (.xslx) for reading.
package goxlsx

import (
	"archive/zip"
	"bytes"
	"encoding/xml"
	"errors"
	"fmt"
	"io"
	"strconv"
	"strings"
)

// NumWorksheets returns the number of worksheets in a file.
func (s *Spreadsheet) NumWorksheets() int {
	return len(s.worksheets)
}

func readWorkbook(data []byte, s *Spreadsheet) ([]*Worksheet, error) {
	wb := &workbook{}
	err := xml.Unmarshal(data, wb)
	if err != nil {
		return nil, err
	}

	var worksheets []*Worksheet

	for i := 0; i < len(wb.Sheets); i++ {
		w := &Worksheet{}
		w.spreadsheet = s
		w.Name = wb.Sheets[i].Name
		w.id = wb.Sheets[i].SheetID
		w.rid = wb.Sheets[i].Rid
		worksheets = append(worksheets, w)
	}
	return worksheets, nil
}

func readStrings(data []byte) ([]string, error) {
	var (
		err           error
		token         xml.Token
		sharedStrings []string
		buf           []byte
	)

	d := xml.NewDecoder(bytes.NewReader(data))
	for {
		token, err = d.Token()
		if err != nil {
			if err != io.EOF {
				return nil, err
			}
			break
		}
		switch x := token.(type) {
		case xml.StartElement:
			switch x.Name.Local {
			case "sst":
				// root element
				for i := 0; i < len(x.Attr); i++ {
					if x.Attr[i].Name.Local == "uniqueCount" {
						count, err := strconv.Atoi(x.Attr[i].Value)
						if err != nil {
							return nil, err
						}
						sharedStrings = make([]string, 0, count)
					}
				}
			}
		case xml.CharData:
			buf = x.Copy()
		case xml.EndElement:
			switch x.Name.Local {
			case "t":
				sharedStrings = append(sharedStrings, string(buf))
			}
		}

	}
	return sharedStrings, nil
}

// OpenFile reads a file located at the given path and returns a spreadsheet object.
func OpenFile(path string) (*Spreadsheet, error) {
	xlsx := new(Spreadsheet)
	xlsx.filepath = path
	xlsx.uncompressedFiles = make(map[string][]byte)
	xlsx.sharedCells = make(map[string]*cell)

	r, err := zip.OpenReader(path)
	if err != nil {
		return nil, err
	}
	defer r.Close()

	for _, f := range r.File {
		buf := make([]byte, f.UncompressedSize64)
		rc, err := f.Open()
		if err != nil {
			return nil, err
		}
		size, err := io.ReadFull(rc, buf)
		if err != nil {
			return nil, err
		}
		if size != int(f.UncompressedSize64) {
			return nil, fmt.Errorf("read (%d) not equal to uncompressed size (%d)", size, f.UncompressedSize64)
		}

		xlsx.uncompressedFiles[f.Name] = buf
	}
	xlsx.relationships, err = readRelationships(xlsx.uncompressedFiles["xl/_rels/workbook.xml.rels"])
	if err != nil {
		return nil, err
	}
	xlsx.worksheets, err = readWorkbook(xlsx.uncompressedFiles["xl/workbook.xml"], xlsx)
	if err != nil {
		return nil, err
	}
	xlsx.sharedStrings, err = readStrings(xlsx.uncompressedFiles["xl/sharedStrings.xml"])
	if err != nil {
		return nil, err
	}
	xlsx.uncompressedFiles["xl/sharedStrings.xml"] = nil

	return xlsx, nil
}

func readRelationships(data []byte) (map[string]relationship, error) {
	rels := &xslxRelationships{}
	err := xml.Unmarshal(data, rels)
	if err != nil {
		return nil, err
	}
	ret := make(map[string]relationship)
	for _, v := range rels.Relationship {
		ret[v.Id] = relationship{Type: v.Type, Target: v.Target}
	}
	return ret, nil
}

// excelpos is something like "AC101"
func stringToPosition(excelpos string) (int, int) {
	var columnnumber, rownumber rune
	for _, v := range excelpos {
		if v >= 'A' && v <= 'Z' {
			columnnumber = columnnumber*26 + v - 'A' + 1
		}
		if v >= '0' && v <= '9' {
			rownumber = rownumber*10 + v - '0'
		}
	}
	return int(columnnumber), int(rownumber)
}

// Cell returns the contents of cell at column, row, where 1,1 is the top left corner. The return value is always a string.
// The user is in charge to convert this value to a number, if necessary. Formulae are not returned.
func (ws *Worksheet) Cell(column, row int) string {
	xrow := ws.rows[row]
	if xrow == nil {
		return ""
	}
	if xrow.Cells[column] == nil {
		return ""
	}
	return xrow.Cells[column].Value
}

// Cell returns the contents of cell at column, row, where 1,1 is the top left corner.
// The return value is always a float64 and an error code != nil if the cell contents can't be
// decoded as a float.
func (ws *Worksheet) Cellf(column, row int) (float64, error) {
	var tmpstr string
	xrow := ws.rows[row]
	if xrow == nil {
		return 0, errors.New("Not a float")
	}
	if xrow.Cells[column] == nil {
		return 0, errors.New("Not a float")
	}
	tmpstr = xrow.Cells[column].Value
	flt, err := strconv.ParseFloat(tmpstr, 64)
	return flt, err
}

func (s *Spreadsheet) readWorksheet(data []byte) (*Worksheet, error) {
	r := bytes.NewReader(data)
	dec := xml.NewDecoder(r)
	ws := &Worksheet{}
	rows := make(map[int]*row)

	const (
		CTSharedString = iota
		CTNumber
		CTOther
	)

	var (
		err        error
		token      xml.Token
		rownum     int
		currentRow *row
		celltype   int
		incell     bool
		cellnumber rune
	)
	for {
		token, err = dec.Token()
		if err != nil {
			if err != io.EOF {
				return nil, err
			}
			break
		}
		switch x := token.(type) {
		case xml.StartElement:
			switch x.Name.Local {
			case "dimension":
				for _, a := range x.Attr {
					if a.Name.Local == "ref" {
						// example: ref="A1:AC101"
						tmp := strings.Split(a.Value, ":")
						ws.MinColumn, ws.MinRow = stringToPosition(tmp[0])
						ws.MaxColumn, ws.MaxRow = stringToPosition(tmp[1])
					}
				}
			case "row":
				currentRow = &row{}
				currentRow.Cells = make(map[int]*cell)
				for _, a := range x.Attr {
					if a.Name.Local == "r" {
						rownum, err = strconv.Atoi(a.Value)
						if err != nil {
							return nil, err
						}
					}
				}
				currentRow.Num = rownum
				rows[rownum] = currentRow
			case "v":
				incell = true
			case "c":
				celltype = CTOther
				cellnumber = 0
				for _, a := range x.Attr {
					switch a.Name.Local {
					case "r":
						for _, v := range a.Value {
							if v >= 'A' && v <= 'Z' {
								cellnumber = cellnumber*26 + v - 'A' + 1
							}
						}
					case "t":
						if a.Value == "s" {
							celltype = CTSharedString
						} else if a.Value == "n" {
							celltype = CTNumber
						}
					}

				}
			}
		case xml.EndElement:
			switch x.Name.Local {
			case "v":
				incell = false
			}
		case xml.CharData:
			if incell {
				var currentCell *cell

				if celltype == CTSharedString {
					currentCell = s.getSharedCell(string(x))
				} else {
					currentCell = &cell{}
					currentCell.Value = string(x)
				}
				currentRow.Cells[int(cellnumber)] = currentCell
			}
		}
	}
	ws.rows = rows
	return ws, nil
}

func (s *Spreadsheet) getSharedCell(idx string) *cell {
	if c, ok := s.sharedCells[idx]; ok {
		return c
	}

	valInt, _ := strconv.Atoi(idx)

	c := &cell{}
	c.Value = s.sharedStrings[valInt]
	s.sharedCells[idx] = c
	return c
}

// GetWorksheet returns the worksheet with the given number, starting at 0.
func (s *Spreadsheet) GetWorksheet(number int) (*Worksheet, error) {
	if number >= len(s.worksheets) || number < 0 {
		return nil, errors.New("index out of range")
	}
	rid := s.worksheets[number].rid
	filename := "xl/" + s.relationships[rid].Target
	ws, err := s.readWorksheet(s.uncompressedFiles[filename])
	ws.filename = filename
	ws.Name = s.worksheets[number].Name
	if err != nil {
		return nil, err
	}
	return ws, nil
}
