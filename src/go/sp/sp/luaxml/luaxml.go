package luaxml

import (
	"bytes"
	"encoding/xml"
	"fmt"
	"os"

	"speedatapublisher/sp/sp/lualib"

	lua "github.com/speedata/go-lua"
)

// encodeComment serializes the table at idx as an XML comment.
func encodeComment(l *lua.State, idx int, enc *xml.Encoder) error {
	idx = l.AbsIndex(idx)
	comment, ok := lualib.FieldString(l, idx, "_value")
	if !ok {
		return fmt.Errorf("error reading comment")
	}
	c := xml.Comment([]byte(comment))
	return enc.EncodeToken(c)
}

// encodeElement serializes the table at idx as an XML element.
func encodeElement(l *lua.State, idx int, enc *xml.Encoder) error {
	idx = l.AbsIndex(idx)

	var localName string
	if v, ok := lualib.FieldString(l, idx, "_name"); ok {
		localName = v
	}
	start := xml.StartElement{
		Name: xml.Name{Local: localName},
	}

	// Attributes: string keys not starting with "_".
	l.PushNil()
	for l.Next(idx) {
		if l.TypeOf(-2) == lua.TypeString {
			keyStr, _ := l.ToString(-2)
			if len(keyStr) > 0 && keyStr[0] != '_' {
				if valStr, ok := l.ToString(-1); ok {
					start.Attr = append(start.Attr, xml.Attr{
						Value: valStr,
						Name:  xml.Name{Local: keyStr},
					})
				}
			}
		}
		l.Pop(1)
	}

	if err := enc.EncodeToken(start); err != nil {
		fmt.Println(err)
		return err
	}

	// Children: integer keys 1..n.
	n := l.RawLength(idx)
	for i := 1; i <= n; i++ {
		l.RawGetInt(idx, i)
		switch l.TypeOf(-1) {
		case lua.TypeTable:
			if err := encodeItem(l, -1, enc); err != nil {
				fmt.Println(err)
			}
		case lua.TypeString:
			s, _ := l.ToString(-1)
			enc.EncodeToken(xml.CharData([]byte(s)))
		default:
			fmt.Println("unknown type")
		}
		l.Pop(1)
	}

	enc.EncodeToken(start.End())
	return nil
}

func encodeItem(l *lua.State, idx int, enc *xml.Encoder) error {
	idx = l.AbsIndex(idx)
	typ := "element"
	if v, ok := lualib.FieldString(l, idx, "_type"); ok {
		typ = v
	}
	switch typ {
	case "element":
		return encodeElement(l, idx, enc)
	case "comment":
		return encodeComment(l, idx, enc)
	}
	return nil
}

// encodeTable encodes the table given in the first argument to an XML file
// and writes it under the file name passed as the second argument
// (default: data.xml).
func encodeTable(l *lua.State) int {
	filename := "data.xml"
	if l.Top() > 1 {
		filename = lua.CheckString(l, 2)
	}
	var b bytes.Buffer
	enc := xml.NewEncoder(&b)
	lua.CheckType(l, 1, lua.TypeTable)
	if err := encodeItem(l, 1, enc); err != nil {
		fmt.Println(err)
		return lualib.PushError(l, err.Error())
	}
	l.SetTop(0)
	l.PushBoolean(true)
	enc.Flush()
	os.WriteFile(filename, b.Bytes(), 0644)
	return 1
}

var exports = []lua.RegistryFunction{
	{Name: "encode_table", Function: encodeTable},
	{Name: "decode_xml", Function: decodeXML},
}

// Open is the loader for the xml module.
func Open(l *lua.State) int {
	lua.NewLibrary(l, exports)
	return 1
}
