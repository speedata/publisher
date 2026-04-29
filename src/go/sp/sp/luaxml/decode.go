package luaxml

import (
	"encoding/xml"
	"io"
	"os"

	"speedatapublisher/sp/sp/lualib"

	lua "github.com/speedata/go-lua"
)

func decodeXML(l *lua.State) int {
	filename := lua.CheckString(l, 1)
	f, err := os.Open(filename)
	if err != nil {
		return lualib.PushError(l, err.Error())
	}
	defer f.Close()

	dec := xml.NewDecoder(f)

	// childCounters[i] = next array index for the element table at depth i.
	var childCounters []int
	hasRoot := false

done:
	for {
		tok, err := dec.Token()
		if err != nil {
			if err == io.EOF {
				break done
			}
			return lualib.PushError(l, err.Error())
		}
		switch t := tok.(type) {
		case xml.StartElement:
			l.NewTable()
			lualib.SetFieldString(l, -1, "_type", "element")
			lualib.SetFieldString(l, -1, "_name", t.Name.Local)
			for _, attr := range t.Attr {
				lualib.SetFieldString(l, -1, attr.Name.Local, attr.Value)
			}
			if len(childCounters) > 0 {
				l.PushValue(-2)
				l.SetField(-2, ".__parent")
			}
			childCounters = append(childCounters, 0)
			hasRoot = true
		case xml.CharData:
			if n := len(childCounters); n > 0 {
				l.PushString(string(t.Copy()))
				childCounters[n-1]++
				l.RawSetInt(-2, childCounters[n-1])
			}
		case xml.EndElement:
			n := len(childCounters)
			if n > 1 {
				childCounters[n-2]++
				l.RawSetInt(-2, childCounters[n-2])
			}
			childCounters = childCounters[:n-1]
		}
	}

	l.PushBoolean(true)
	if hasRoot {
		l.Insert(-2)
	} else {
		l.PushNil()
	}
	return 2
}
