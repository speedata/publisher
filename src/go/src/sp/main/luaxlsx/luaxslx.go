package luaxlsx

import (
	"fmt"

	"github.com/Shopify/go-lua"
	"github.com/speedata/goxlsx"
)

// Lua error message in the form of bool, string.
// bool indicates success, string the error message in case of a false value.
func lerr(l *lua.State, errormessage string) int {
	l.SetTop(0)
	l.PushBoolean(false)
	l.PushString(errormessage)
	return 2
}

var spreadsheetMetamethods = []lua.RegistryFunction{
	{"__index", indexSpreadSheet},
	{"__len", lengthSpreadSheet},
}

var worksheetMetamethods = []lua.RegistryFunction{
	{"__call", callWorksheet},
	{"__index", indexWorksheet},
}

func indexSpreadSheet(l *lua.State) int {
	var idx int
	if i, ok := l.ToInteger(2); ok {
		idx = i
	} else {
		return 0
	}
	l.Pop(1)
	ss := l.ToUserData(1)
	if spreadsheet, ok := ss.(*goxlsx.Spreadsheet); ok {
		ws, err := spreadsheet.GetWorksheet(idx - 1)
		if err != nil {
			return 0
		}
		l.Pop(1)

		l.PushUserData(ws)
		lua.NewMetaTable(l, "worksheet")
		lua.SetFunctions(l, worksheetMetamethods, 0)

		l.SetMetaTable(1)
		return 1
	}
	return 0
}

func lengthSpreadSheet(l *lua.State) int {
	ss := l.ToUserData(1)
	if spreadsheet, ok := ss.(*goxlsx.Spreadsheet); ok {
		l.PushInteger(spreadsheet.NumWorksheets())
		return 1
	} else {
		fmt.Println("!ok")
		return lerr(l, "Cannot get the number of worksheets in the spreadsheet")
	}
	return 0
}

func indexWorksheet(l *lua.State) int {
	var arg string
	if str, ok := l.ToString(-1); !ok {
		return 0
	} else {
		arg = str
	}

	ws := l.ToUserData(1)
	if worksheet, ok := ws.(*goxlsx.Worksheet); ok {
		switch arg {
		case "minrow":
			l.PushInteger(worksheet.MinRow)
		case "maxrow":
			l.PushInteger(worksheet.MaxRow)
		case "mincol":
			l.PushInteger(worksheet.MinColumn)
		case "maxcol":
			l.PushInteger(worksheet.MaxColumn)
		case "name":
			l.PushString(worksheet.Name)
		}

		return 1
	}
	return 0
}

// Get the contents of a table cell.
func callWorksheet(l *lua.State) int {
	x, _ := l.ToInteger(-2)
	y, _ := l.ToInteger(-1)
	ws := l.ToUserData(1)
	if worksheet, ok := ws.(*goxlsx.Worksheet); ok {
		l.PushString(worksheet.Cell(x, y))
		return 1
	}
	return 0
}

func openfile(l *lua.State) int {
	if l.Top() < 1 {
		return lerr(l, "The first argument of open must be the filename of the Excel file.")
	}
	filename, ok := l.ToString(1)
	if !ok {
		return lerr(l, "first argument must be a string")
	}
	l.Pop(1)

	sh, err := goxlsx.OpenFile(filename)
	if err != nil {
		return lerr(l, err.Error())
	}

	l.PushUserData(sh)
	lua.NewMetaTable(l, "spreadsheet")
	lua.SetFunctions(l, spreadsheetMetamethods, 0)
	l.SetMetaTable(1)

	return 1
}

var xlsxlib = []lua.RegistryFunction{
	{"open", openfile},
}

func Open(l *lua.State) {
	requireXSLX := func(l *lua.State) int {
		lua.NewLibrary(l, xlsxlib)
		return 1
	}
	lua.Require(l, "xlsx", requireXSLX, true)
	l.Pop(1)
}
