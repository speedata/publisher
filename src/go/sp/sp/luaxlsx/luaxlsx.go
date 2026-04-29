package luaxlsx

import (
	"speedatapublisher/sp/sp/lualib"

	lua "github.com/speedata/go-lua"
	"github.com/speedata/goxlsx"
)

const (
	spreadsheetTypeName = "spreadsheet"
	worksheetTypeName   = "worksheet"
)

// ----------------------- spreadsheet

func indexSpreadSheet(l *lua.State) int {
	sh, ok := lua.CheckUserData(l, 1, spreadsheetTypeName).(*goxlsx.Spreadsheet)
	if !ok {
		return 0
	}
	n, _ := l.ToInteger(2)
	ws, err := sh.GetWorksheet(n - 1)
	if err != nil {
		lua.Errorf(l, "%s", err.Error())
		return 0
	}
	pushWorksheet(l, ws)
	return 1
}

func lenSpreadSheet(l *lua.State) int {
	sh, ok := lua.CheckUserData(l, 1, spreadsheetTypeName).(*goxlsx.Spreadsheet)
	if !ok {
		return 0
	}
	l.PushInteger(sh.NumWorksheets())
	return 1
}

func pushSpreadsheet(l *lua.State, sh *goxlsx.Spreadsheet) {
	l.PushUserData(sh)
	lua.SetMetaTableNamed(l, spreadsheetTypeName)
}

// ----------------------- worksheet

func indexWorksheet(l *lua.State) int {
	ws, ok := lua.CheckUserData(l, 1, worksheetTypeName).(*goxlsx.Worksheet)
	if !ok {
		return 0
	}
	arg, _ := l.ToString(2)
	switch arg {
	case "minrow":
		l.PushInteger(ws.MinRow)
		return 1
	case "maxrow":
		l.PushInteger(ws.MaxRow)
		return 1
	case "mincol":
		l.PushInteger(ws.MinColumn)
		return 1
	case "maxcol":
		l.PushInteger(ws.MaxColumn)
		return 1
	case "name":
		l.PushString(ws.Name)
		return 1
	}
	return 0
}

func callWorksheet(l *lua.State) int {
	ws, ok := lua.CheckUserData(l, 1, worksheetTypeName).(*goxlsx.Worksheet)
	if !ok {
		return 0
	}
	x, _ := l.ToInteger(2)
	y, _ := l.ToInteger(3)
	l.PushString(ws.Cell(x, y))
	return 1
}

func pushWorksheet(l *lua.State, ws *goxlsx.Worksheet) {
	l.PushUserData(ws)
	lua.SetMetaTableNamed(l, worksheetTypeName)
}

// stringToDate returns a table with keys day, month, year, hour, minute,
// second.
func stringToDate(l *lua.State) int {
	n := lua.CheckString(l, 1)
	t := goxlsx.DateFromString(n)
	l.NewTable()
	lualib.SetFieldInteger(l, -1, "day", t.Day())
	lualib.SetFieldInteger(l, -1, "month", int(t.Month()))
	lualib.SetFieldInteger(l, -1, "year", t.Year())
	lualib.SetFieldInteger(l, -1, "hour", t.Hour())
	lualib.SetFieldInteger(l, -1, "minute", t.Minute())
	lualib.SetFieldInteger(l, -1, "second", t.Second())
	return 1
}

func openfile(l *lua.State) int {
	if l.Top() < 1 {
		return lualib.PushError(l, "The first argument of open must be the filename of the Excel file.")
	}
	filename := lua.CheckString(l, 1)

	sh, err := goxlsx.OpenFile(filename)
	if err != nil {
		return lualib.PushError(l, err.Error())
	}
	pushSpreadsheet(l, sh)
	return 1
}

var exports = []lua.RegistryFunction{
	{Name: "open", Function: openfile},
	{Name: "string_to_date", Function: stringToDate},
}

// Open is the loader for the xlsx module.
func Open(l *lua.State) int {
	lua.NewMetaTable(l, spreadsheetTypeName)
	l.PushGoFunction(indexSpreadSheet)
	l.SetField(-2, "__index")
	l.PushGoFunction(lenSpreadSheet)
	l.SetField(-2, "__len")
	l.Pop(1)

	lua.NewMetaTable(l, worksheetTypeName)
	l.PushGoFunction(indexWorksheet)
	l.SetField(-2, "__index")
	l.PushGoFunction(callWorksheet)
	l.SetField(-2, "__call")
	l.Pop(1)

	lua.NewLibrary(l, exports)
	return 1
}
