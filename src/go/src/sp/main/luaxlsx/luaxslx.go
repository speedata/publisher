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

	return 1
}

func numWorksheets(l *lua.State) int {
	if l.Top() < 1 {
		return lerr(l, "The first argument of num_worksheets must be the spreadsheet object.")
	}
	sh := l.ToUserData(1)
	l.Pop(1)
	var spreadsheet *goxlsx.Spreadsheet
	var ok bool

	if spreadsheet, ok = sh.(*goxlsx.Spreadsheet); !ok {
		return lerr(l, "first argument must be the spreadsheet object")
	}
	l.PushInteger(spreadsheet.NumWorksheets())
	return 1
}

func getWorksheet(l *lua.State) int {
	if l.Top() < 2 {
		return lerr(l, "get_worksheet requires two parameters. The spreadsheet and the index (starting from 0) .")
	}
	sh := l.ToUserData(-2)
	var spreadsheet *goxlsx.Spreadsheet
	var ok bool
	if spreadsheet, ok = sh.(*goxlsx.Spreadsheet); !ok {
		return lerr(l, "first argument must be the spreadsheet object")
	}
	var num int
	if num, ok = l.ToInteger(-1); !ok {
		return lerr(l, "second argument must be a number")
	}
	l.Pop(2)

	ws, err := spreadsheet.GetWorksheet(num)
	if err != nil {
		return lerr(l, err.Error())
	}

	l.PushUserData(ws)
	return 1
}

func cell(l *lua.State) int {
	if l.Top() < 3 {
		return lerr(l, "cell requires three parameters. The worksheet and x and y coordinate (starting at 1,1).")
	}
	var worksheet *goxlsx.Worksheet
	var ok bool
	var x, y int
	ws := l.ToUserData(-3)
	if worksheet, ok = ws.(*goxlsx.Worksheet); !ok {
		return lerr(l, "first argument must be the worksheet object")
	}

	if x, ok = l.ToInteger(-2); !ok {
		return lerr(l, "second argument must be a number (column)")
	}
	if y, ok = l.ToInteger(-1); !ok {
		return lerr(l, "third argument must be a number (row)")
	}
	l.Pop(3)

	l.PushString(worksheet.Cell(x, y))
	return 1
}

// Gets a worksheet and removes the value at index
func getLuaWorksheet(l *lua.State, index int) (*goxlsx.Worksheet, error) {
	var worksheet *goxlsx.Worksheet
	var ok bool

	ws := l.ToUserData(index)
	l.Remove(index)
	if worksheet, ok = ws.(*goxlsx.Worksheet); !ok {
		return nil, fmt.Errorf("The argument must be the worksheet object")
	}
	return worksheet, nil
}

func wsname(l *lua.State) int {
	if l.Top() < 1 {
		return lerr(l, "wsname requires the worksheet object as the first argument.")
	}

	ws, err := getLuaWorksheet(l, 1)
	if err != nil {
		return lerr(l, "first argument must be a worksheet object")
	}
	l.PushString(ws.Name)
	return 1
}

func wsmaxrow(l *lua.State) int {
	if l.Top() < 1 {
		return lerr(l, "wsmaxrow requires the worksheet object as the first argument.")
	}

	ws, err := getLuaWorksheet(l, 1)
	if err != nil {
		return lerr(l, "first argument must be a worksheet object")
	}
	l.PushInteger(ws.MaxRow)
	return 1
}

func wsminrow(l *lua.State) int {
	if l.Top() < 1 {
		return lerr(l, "wsminrow requires the worksheet object as the first argument.")
	}

	ws, err := getLuaWorksheet(l, 1)
	if err != nil {
		return lerr(l, "first argument must be a worksheet object")
	}
	l.PushInteger(ws.MinRow)
	return 1
}

func wsmaxcol(l *lua.State) int {
	if l.Top() < 1 {
		return lerr(l, "wsmaxcol requires the worksheet object as the first argument.")
	}

	ws, err := getLuaWorksheet(l, 1)
	if err != nil {
		return lerr(l, "first argument must be a worksheet object")
	}
	l.PushInteger(ws.MaxColumn)
	return 1
}

func wsmincol(l *lua.State) int {
	if l.Top() < 1 {
		return lerr(l, "wsmincol requires the worksheet object as the first argument.")
	}

	ws, err := getLuaWorksheet(l, 1)
	if err != nil {
		return lerr(l, "first argument must be a worksheet object")
	}
	l.PushInteger(ws.MinColumn)
	return 1
}

var xlsxlib = []lua.RegistryFunction{
	{"open", openfile},
	{"num_worksheets", numWorksheets},
	{"get_worksheet", getWorksheet},
	{"cell", cell},
	{"wsname", wsname},
	{"wsmaxrow", wsmaxrow},
	{"wsminrow", wsminrow},
	{"wsmaxcol", wsmaxcol},
	{"wsmincol", wsmincol},
}

func Open(l *lua.State) {
	requireXSLX := func(l *lua.State) int {
		lua.NewLibrary(l, xlsxlib)
		return 1
	}
	lua.Require(l, "xlsx", requireXSLX, true)
	l.Pop(1)

}
