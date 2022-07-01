package luaxml

import (
	"encoding/xml"
	"io"
	"os"

	lua "github.com/yuin/gopher-lua"
)

func decodeXML(l *lua.LState) int {
	filename := l.CheckString(1)
	f, err := os.Open(filename)
	if err != nil {
		return lerr(l, err.Error())
	}

	defer f.Close()

	dec := xml.NewDecoder(f)

	var curtbl, root *lua.LTable
done:
	for {
		tok, err := dec.Token()
		if err != nil {
			if err == io.EOF {
				break done
			}
			return lerr(l, err.Error())
		}
		switch t := tok.(type) {
		case xml.StartElement:
			elttbl := &lua.LTable{}
			elttbl.RawSetString("_type", lua.LString("element"))
			elttbl.RawSetString("_name", lua.LString(t.Name.Local))

			for _, attr := range t.Attr {
				elttbl.RawSetString(attr.Name.Local, lua.LString(attr.Value))
			}

			if root == nil {
				root = elttbl
			}

			if curtbl != nil {
				elttbl.RawSetString(".__parent", curtbl)
				curtbl.Append(elttbl)
			}
			curtbl = elttbl
		case xml.CharData:
			if curtbl != nil {
				curtbl.Append(lua.LString(t.Copy()))
			}
		case xml.EndElement:
			entry := curtbl.RawGetString(".__parent")
			if tbl, ok := entry.(*lua.LTable); ok {
				// lv is LTable
				curtbl = tbl
			}

		}
	}
	l.Push(lua.LTrue)
	l.Push(root)
	return 2
}
