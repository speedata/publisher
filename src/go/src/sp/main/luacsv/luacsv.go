package luacsv

import (
	"bytes"
	"encoding/csv"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"regexp"

	"github.com/Shopify/go-lua"
	"golang.org/x/text/encoding/charmap"
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
	if l.Top() < 1 {
		return lerr(l, "The first argument of decode must be the filename of the CSV.")
	}
	filename, ok := l.ToString(1)
	if !ok {
		return lerr(l, "first argument must be a string")
	}
	columns := []int{}
	var charset, separator string

	if l.Top() > 0 {
		// hopefully the next argument is a table
		if l.IsTable(2) {
			l.PushString("charset")
			l.Table(2)
			if str, ok := l.ToString(-1); ok {
				charset = str
			}
			l.Pop(1)

			l.PushString("separator")
			l.Table(2)
			if str, ok := l.ToString(-1); ok {
				separator = str
			}
			l.Pop(1)

			l.PushString("columns")
			l.Table(2)
			if l.IsTable(-1) {
				l.Length(-1)
				var length int
				if i, ok := l.ToInteger(-1); !ok {
					return lerr(l, "Should be an int")
				} else {
					length = i
				}

				l.Pop(1)
				for i := 1; i <= length; i++ {
					l.PushInteger(i)
					l.Table(-2)
					col := lua.CheckInteger(l, -1)
					columns = append(columns, col)
					l.Pop(1)
				}
			}
			l.Pop(1)
		}
		l.SetTop(0)
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

	l.NewTable()
	for i, row := range records {
		l.PushInteger(i + 1)
		l.NewTable()
		// -1 inner table
		// -2 int (i + 1)
		// -3 outer table
		for j, entry := range columns {
			if entry-1 < 0 || entry > len(row) {
				return lerr(l, fmt.Sprintf("Column %d out of range. Must be between 1 and %d (# of columns)", entry, len(row)))
			}
			l.PushInteger(j + 1)
			l.PushString(row[entry-1])
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
