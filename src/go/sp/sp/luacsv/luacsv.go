package luacsv

import (
	"bytes"
	"encoding/csv"
	"fmt"
	"io"
	"os"
	"regexp"

	"speedatapublisher/sp/sp/lualib"

	lua "github.com/speedata/go-lua"
	"golang.org/x/text/encoding/charmap"
)

func decode(l *lua.State) int {
	if l.Top() < 1 {
		return lualib.PushError(l, "The first argument of decode must be the filename of the CSV.")
	}
	filename := lua.CheckString(l, 1)

	columns := []int{}
	var charset, separator string

	if l.Top() > 1 {
		lua.CheckType(l, -1, lua.TypeTable)
		if v, ok := lualib.FieldString(l, -1, "charset"); ok {
			charset = v
		}
		if v, ok := lualib.FieldString(l, -1, "separator"); ok {
			separator = v
		}
		l.Field(-1, "columns")
		if l.IsTable(-1) {
			n := l.RawLength(-1)
			for i := 1; i <= n; i++ {
				l.RawGetInt(-1, i)
				if l.IsNumber(-1) {
					if v, ok := l.ToInteger(-1); ok {
						columns = append(columns, v)
					}
				}
				l.Pop(1)
			}
		}
		l.Pop(1)
	}

	var err error
	var rd io.Reader

	rd, err = os.Open(filename)
	if err != nil {
		return lualib.PushError(l, err.Error())
	}

	switch charset {
	case "ISO-8859-1":
		rd = charmap.ISO8859_1.NewDecoder().Reader(rd)
	}

	data, err := io.ReadAll(rd)
	if err != nil {
		return lualib.PushError(l, err.Error())
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
		return lualib.PushError(l, err.Error())
	}
	l.NewTable()
	for i, row := range records {
		if i == 0 && len(columns) == 0 {
			for z := 1; z <= len(row); z++ {
				columns = append(columns, z)
			}
		}
		l.NewTable()
		for j, entry := range columns {
			if entry-1 < 0 || entry > len(row) {
				return lualib.PushError(l, fmt.Sprintf("Column %d out of range. Must be between 1 and %d (# of columns)", entry, len(row)))
			}
			l.PushString(row[entry-1])
			l.RawSetInt(-2, j+1)
		}
		l.RawSetInt(-2, i+1)
	}
	return 1
}

var exports = []lua.RegistryFunction{
	{Name: "decode", Function: decode},
}

// Open is the loader for the csv module.
func Open(l *lua.State) int {
	lua.NewLibrary(l, exports)
	return 1
}
