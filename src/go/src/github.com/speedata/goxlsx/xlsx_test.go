package goxlsx

import (
	"path/filepath"
	"testing"
)

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
	if len(ws.rows) != 5 {
		t.Error("ws.rows != 5")
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

}
