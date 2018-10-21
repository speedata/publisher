package goxlsx

import (
	"path/filepath"
	"testing"
	"time"
)

func TestLibreofficeOpen(t *testing.T) {
	filename := filepath.Join("_testdata", "libreoffice.xlsx")
	_, err := OpenFile(filename)
	if err != nil {
		t.Error(err)
	}
}

func TestDateTime(t *testing.T) {
	filename := filepath.Join("_testdata", "datetime.xlsx")
	xlsx, err := OpenFile(filename)
	if err != nil {
		t.Error(err)
	}
	ws, err := xlsx.GetWorksheet(0)
	if err != nil {
		t.Error(err)
	}

	if val, expected := ws.Cell(1, 1), "43589.563194444447"; val != expected {
		t.Errorf("1,1 should be %q, but is %q", expected, val)
	}

	if val, expectedTime := ws.Cellt(1, 1), time.Date(2019, time.May, 4, 13, 31, 0, 0, time.UTC); !val.Equal(expectedTime) {
		t.Errorf("1,1 should be %q, but is %q", expectedTime, val)
	}
	if val, expectedTime := ws.Cellt(2, 1), ExcelNulltime; !val.Equal(expectedTime) {
		t.Errorf("1,1 should be %q, but is %q", expectedTime, val)
	}
}

// Second spreadsheet is empty
func TestEmptySpreadsheet(t *testing.T) {
	filename := filepath.Join("_testdata", "oneempty.xlsx")
	xlsx, err := OpenFile(filename)
	if err != nil {
		t.Error(err)
	}
	if xlsx.NumWorksheets() != 2 {
		t.Error("num of worksheets != 2")
	}
	_, err = xlsx.GetWorksheet(1)
	if err != nil {
		t.Error(err)
	}
}

func TestOpenFile(t *testing.T) {
	filename := filepath.Join("_testdata", "Worksheet1.xlsx")
	xlsx, err := OpenFile(filename)
	if err != nil {
		t.Error(err)
	}
	if xlsx.NumWorksheets() != 2 {
		t.Error("num of worksheets != 2")
	}

	ws, err := xlsx.GetWorksheet(0)
	if err != nil {
		t.Error(err)
	}
	if ws.filename != "xl/worksheets/sheet1.xml" {
		t.Error("filename mismatch, got", ws.filename)
	}
	if len(ws.rows) != 6 {
		t.Error("ws.rows != 6")
	}

	row := ws.rows[1]
	if row.Cells[1].Value != "A" {
		t.Errorf("First value should be A, but got %q", row.Cells[1].Value)
	}
	if row.Cells[2].Value != "B" {
		t.Errorf("Second value should be B, but is %q", row.Cells[2].Value)
	}
	if ws.Cell(1, 1) != "A" {
		t.Errorf("1,1 should be A, but is %q", ws.Cell(1, 1))
	}
	if f, err := ws.Cellf(4, 2); f != 4.0 || err != nil {
		t.Error("4,2 should be 4.0")
	}
	if val, expected := ws.Cell(5, 5), "a\n\nb"; val != expected {
		t.Errorf("5,5 should be %q, but is %q", expected, val)
	}

}
