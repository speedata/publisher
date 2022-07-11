package luacsv

import (
	"bytes"
	"encoding/csv"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"regexp"

	lua "github.com/yuin/gopher-lua"
	"golang.org/x/text/encoding/charmap"
)

func lerr(l *lua.LState, errormessage string) int {
	l.SetTop(0)
	l.Push(lua.LFalse)
	l.Push(lua.LString(errormessage))
	return 2
}

func decode(l *lua.LState) int {
	if l.GetTop() < 1 {
		return lerr(l, "The first argument of decode must be the filename of the CSV.")
	}
	filename := l.CheckString(1)

	columns := []int{}
	var charset, separator string

	if l.GetTop() > 1 {
		if tbl := l.CheckTable(-1); tbl.Type() == lua.LTTable {
			val := tbl.RawGetString("charset")
			if val.Type() == lua.LTString {
				charset = val.String()
			}
			val = tbl.RawGetString("separator")
			if val.Type() == lua.LTString {
				separator = val.String()
			}
			val = tbl.RawGetString("columns")
			if cols, ok := val.(*lua.LTable); ok {
				for i := 1; i <= cols.Len(); i++ {
					val = cols.RawGetInt(i)
					if f, ok := val.(lua.LNumber); ok {
						columns = append(columns, int(f))
					}
				}
			}
		}
	}

	var err error
	var rd io.Reader

	rd, err = os.Open(filename)
	if err != nil {
		return lerr(l, err.Error())
	}

	// Currently only latin-1 is supported
	switch charset {
	case "ISO-8859-1":
		rd = charmap.ISO8859_1.NewDecoder().Reader(rd)
	}

	data, err := ioutil.ReadAll(rd)
	if err != nil {
		return lerr(l, err.Error())
	}

	re := regexp.MustCompile(`\r`)
	data = re.ReplaceAll(data, []byte{10})
	br := bytes.NewReader(data)
	reader := csv.NewReader(br)
	if separator != "" {
		reader.Comma = rune(separator[0])
	}

	reader.LazyQuotes = true

	records, err := reader.ReadAll()
	if err != nil {
		return lerr(l, err.Error())
	}
	rows := l.NewTable()
	for i, row := range records {
		if i == 0 && len(columns) == 0 {
			for z := 1; z <= len(row); z++ {
				columns = append(columns, z)
			}
		}
		col := l.NewTable()
		for j, entry := range columns {
			if entry-1 < 0 || entry > len(row) {
				return lerr(l, fmt.Sprintf("Column %d out of range. Must be between 1 and %d (# of columns)", entry, len(row)))
			}
			col.RawSetInt(j+1, lua.LString(row[entry-1]))
		}
		rows.RawSetInt(i+1, col)
	}

	l.Push(rows)
	return 1
}

var exports = map[string]lua.LGFunction{
	"decode": decode,
}

func Open(l *lua.LState) int {
	mod := l.SetFuncs(l.NewTable(), exports)
	l.Push(mod)
	return 1
}
