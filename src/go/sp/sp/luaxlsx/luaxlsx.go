package luaxlsx

import (
	"github.com/speedata/goxlsx"
	lua "github.com/yuin/gopher-lua"
)

func lerr(l *lua.LState, errormessage string) int {
	l.SetTop(0)
	l.Push(lua.LFalse)
	l.Push(lua.LString(errormessage))
	return 2
}

const luaSpreadsheetTypeName = "spreadsheet"
const luaWorksheetTypeName = "worksheet"

// ----------------------- spreadsheet

func indexSpreadSheet(l *lua.LState) int {
	sh := checkSpreadsheet(l)
	n := l.ToInt(-1)
	ws, err := sh.GetWorksheet(n - 1)
	if err != nil {
		l.RaiseError(err.Error())
	}

	mt := l.NewTypeMetatable(luaWorksheetTypeName)
	l.SetField(mt, "__call", l.NewFunction(callWorksheet))
	l.SetField(mt, "__index", l.NewFunction(indexWorksheet))

	ud := l.NewUserData()
	ud.Value = ws
	l.SetMetatable(ud, mt)

	l.Push(ud)
	return 1
}

func lenSpreadSheet(l *lua.LState) int {
	sh := checkSpreadsheet(l)
	l.Push(lua.LNumber(sh.NumWorksheets()))
	return 1
}

func checkSpreadsheet(l *lua.LState) *goxlsx.Spreadsheet {
	ud := l.CheckUserData(1)
	if v, ok := ud.Value.(*goxlsx.Spreadsheet); ok {
		return v
	}
	l.ArgError(1, "spreadsheet expected")
	return nil
}

// ----------------------- worksheet

func checkWorksheet(l *lua.LState) *goxlsx.Worksheet {
	ud := l.CheckUserData(1)
	if v, ok := ud.Value.(*goxlsx.Worksheet); ok {
		return v
	}
	l.ArgError(1, "worksheet expected")
	return nil
}

func indexWorksheet(l *lua.LState) int {
	ws := checkWorksheet(l)
	arg := l.ToString(2)
	switch arg {
	case "minrow":
		l.Push(lua.LNumber(ws.MinRow))
		return 1
	case "maxrow":
		l.Push(lua.LNumber(ws.MaxRow))
		return 1
	case "mincol":
		l.Push(lua.LNumber(ws.MinColumn))
		return 1
	case "maxcol":
		l.Push(lua.LNumber(ws.MaxColumn))
		return 1
	case "name":
		l.Push(lua.LString(ws.Name))
		return 1
	}
	return 0
}

func callWorksheet(l *lua.LState) int {
	ws := checkWorksheet(l)
	y := l.ToInt(-1)
	x := l.ToInt(-2)
	str := ws.Cell(x, y)
	l.Push(lua.LString(str))
	return 1
}

// Return a table with keys day,month,year,hour,minute and second
func stringToDate(l *lua.LState) int {
	n := l.CheckString(1)
	t := goxlsx.DateFromString(n)
	date := l.NewTable()
	date.RawSetString("day", lua.LNumber(t.Day()))
	date.RawSetString("month", lua.LNumber(t.Month()))
	date.RawSetString("year", lua.LNumber(t.Year()))
	date.RawSetString("hour", lua.LNumber(t.Hour()))
	date.RawSetString("minute", lua.LNumber(t.Minute()))
	date.RawSetString("second", lua.LNumber(t.Second()))
	l.Push(date)
	return 1
}

func openfile(l *lua.LState) int {
	if l.GetTop() < 1 {
		return lerr(l, "The first argument of open must be the filename of the Excel file.")
	}
	var filename string
	filename = l.CheckString(1)

	sh, err := goxlsx.OpenFile(filename)
	if err != nil {
		return lerr(l, err.Error())
	}

	mt := l.NewTypeMetatable(luaSpreadsheetTypeName)
	l.SetField(mt, "__index", l.NewFunction(indexSpreadSheet))
	l.SetField(mt, "__len", l.NewFunction(lenSpreadSheet))

	ud := l.NewUserData()
	ud.Value = sh
	l.SetMetatable(ud, mt)

	l.Push(ud)
	return 1
}

var exports = map[string]lua.LGFunction{
	"open":           openfile,
	"string_to_date": stringToDate,
}

// Open sets up the XSLX Lua module.
func Open(l *lua.LState) int {
	mod := l.SetFuncs(l.NewTable(), exports)
	l.Push(mod)
	return 1
}
