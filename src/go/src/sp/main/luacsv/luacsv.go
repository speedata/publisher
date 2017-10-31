package luacsv

import (
	"encoding/csv"
	"os"

	"github.com/Shopify/go-lua"
)

// Lua error message in the form of bool, string.
// bool indicates success, string the error message in case of a false value.
func lerr(l *lua.State, errormessage string) int {
	l.SetTop(0)
	l.PushBoolean(false)
	l.PushString(errormessage)
	return 2
}

func decode(l *lua.State) int {
	if l.Top() != 1 {
		return lerr(l, "decode needs exactly one argument: the file name.")
	}
	filename, ok := l.ToString(-1)
	if !ok {
		return lerr(l, "first argument must be a string")
	}
	l.Pop(1)
	r, err := os.Open(filename)
	if err != nil {
		return lerr(l, err.Error())
	}

	reader := csv.NewReader(r)
	reader.LazyQuotes = true
	records, err := reader.ReadAll()
	if err != nil {
		return lerr(l, err.Error())
	}

	l.NewTable()
	for i, rows := range records {
		l.PushInteger(i + 1)
		l.NewTable()
		// -1 inner table
		// -2 int (i + 1)
		// -3 outer table
		for j, entry := range rows {
			l.PushInteger(j + 1)
			l.PushString(entry)
			l.SetTable(-3)
		}
		l.SetTable(-3)
	}

	// return "ok" and the table
	l.PushBoolean(true)
	l.Insert(-2)
	return 2
}

var csvlib = []lua.RegistryFunction{
	{"decode", decode},
}

func Open(l *lua.State) {
	requireCSV := func(l *lua.State) int {
		lua.NewLibrary(l, csvlib)
		return 1
	}
	lua.Require(l, "csv", requireCSV, true)
	l.Pop(1)

}
