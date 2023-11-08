package luaxml

import (
	"bytes"
	"encoding/xml"
	"fmt"
	"os"

	lua "github.com/yuin/gopher-lua"
)

func lerr(l *lua.LState, errormessage string) int {
	l.SetTop(0)
	l.Push(lua.LFalse)
	l.Push(lua.LString(errormessage))
	return 2
}

func encodeComment(tbl *lua.LTable, enc *xml.Encoder) error {
	var comment string
	val := tbl.RawGetString("_value")
	if val.Type() == lua.LTString {
		comment = val.String()
	} else {
		return fmt.Errorf("error reading comment")
	}

	c := xml.Comment([]byte(comment))
	return enc.EncodeToken(c)
}

func encodeElement(tbl *lua.LTable, enc *xml.Encoder) error {
	var localName, namespace string
	val := tbl.RawGetString("_name")
	if val.Type() == lua.LTString {
		localName = val.String()
	}
	// namespace not used yet
	start := xml.StartElement{
		Name: xml.Name{
			Local: localName,
			Space: namespace,
		},
	}
	// attributes
	tbl.ForEach(func(key lua.LValue, value lua.LValue) {
		if str, ok := key.(lua.LString); ok {
			if string(str)[0] != '_' {
				attr := xml.Attr{
					Value: value.String(),
					Name: xml.Name{
						Local: str.String(),
						Space: "",
					},
				}
				start.Attr = append(start.Attr, attr)
			}
		}
	})
	err := enc.EncodeToken(start)
	if err != nil {
		fmt.Println(err)
		return err
	}
	// children
	tbl.ForEach(func(key lua.LValue, value lua.LValue) {
		if _, ok := key.(lua.LNumber); ok {
			switch val := value.Type(); val {
			case lua.LTTable:
				err := encodeItem(value.(*lua.LTable), enc)
				if err != nil {
					fmt.Println(err)
				}
			case lua.LTString:
				enc.EncodeToken(xml.CharData([]byte(value.String())))
			default:
				fmt.Println("unknown type")
			}
		}
	})

	enc.EncodeToken(start.End())
	return nil
}

func encodeItem(tbl *lua.LTable, enc *xml.Encoder) error {
	var typ string
	val := tbl.RawGetString("_type")
	if val.Type() == lua.LTString {
		typ = val.String()
	} else {
		typ = "element"
	}
	// get the name of the element
	switch typ {
	case "element":
		return encodeElement(tbl, enc)
	case "comment":
		return encodeComment(tbl, enc)
	}
	return nil
}

// Encode the table given in the first argument to an XML file and
// write this to the hard drive with the name `data.xml`
func encodeTable(l *lua.LState) int {
	filename := "data.xml"
	if l.GetTop() > 1 {
		filename = l.CheckString(2)
	}
	var b bytes.Buffer
	enc := xml.NewEncoder(&b)
	if tbl := l.CheckTable(1); tbl.Type() == lua.LTTable {
		err := encodeItem(tbl, enc)
		if err != nil {
			fmt.Println(err)
			return lerr(l, err.Error())
		}
	}
	l.SetTop(0)
	l.Push(lua.LTrue)
	enc.Flush()
	os.WriteFile(filename, b.Bytes(), 0644)
	return 1
}

var exports = map[string]lua.LGFunction{
	"encode_table": encodeTable,
	"decode_xml":   decodeXML,
}

// Open starts this lua instance
func Open(l *lua.LState) int {
	mod := l.SetFuncs(l.NewTable(), exports)
	l.Push(mod)
	return 1
}
