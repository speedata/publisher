package luaxml

import (
	"bytes"
	"encoding/xml"
	"fmt"
	"io/ioutil"

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

func encodeItem(l *lua.State, enc *xml.Encoder) error {
	l.Field(-1, "_type")
	// -1 value of _type
	// -2 the table
	typ, ok := l.ToString(-1)
	if !ok {
		// return fmt.Errorf("error reading type")
		typ = "element"
	}

	l.Pop(1)
	// -1 the table

	// get the name of the element
	switch typ {
	case "element":
		return encodeElement(l, enc)
	case "comment":
		return encodeComment(l, enc)
	default:
		return nil
	}

	return nil
}

func encodeComment(l *lua.State, enc *xml.Encoder) error {
	l.Field(-1, "_value")
	// -1 value of _value
	// -2 the table
	var comment string
	if str, ok := l.ToString(-1); !ok {
		l.Pop(1)
		return fmt.Errorf("error reading comment")
	} else {
		l.Pop(1)
		comment = str
	}

	c := xml.Comment([]byte(comment))
	return enc.EncodeToken(c)
}

func encodeElement(l *lua.State, enc *xml.Encoder) error {
	// -1: table with _local, _space and [1]...[n] child element
	if l.Top() < 1 || !l.IsTable(-1) {
		return fmt.Errorf("Something is wrong with the first argument, it must be a table")
	}
	// -1 the table
	var localName, namespace string
	l.Field(-1, "_name")
	// -1 value of _space
	// -2 the table
	if str, ok := l.ToString(-1); !ok {
		return fmt.Errorf("error reading name space")
	} else {
		localName = str
	}
	l.Pop(1)
	// -1 the table

	start := xml.StartElement{
		Name: xml.Name{
			Local: localName,
			Space: namespace,
		},
	}

	l.PushNil() // Add nil entry on stack (need 2 free slots).
	for l.Next(-2) {
		l.PushValue(-2)
		typeOfKey := l.TypeOf(-1)
		key, _ := l.ToString(-1)
		val, _ := l.ToString(-2)
		switch v := typeOfKey; v {
		case lua.TypeNumber:
			// ignore
		case lua.TypeString:
			// Attributes are string keys that don't start with an underscore.
			if key[0] != '_' {
				attr := xml.Attr{
					Value: val,
					Name: xml.Name{
						Local: key,
						Space: "",
					},
				}
				start.Attr = append(start.Attr, attr)
			}
		}

		l.Pop(2) // Remove val, but need key for the next iter.
	}
	err := enc.EncodeToken(start)
	if err != nil {
		fmt.Println(err)
		return err
	}

	count := 0
eachindex:
	for {
		count++
		l.PushInteger(count)
		// -1 value of count
		// -2 the table
		l.Table(-2)
		// -1 the value of whatever is at idx count
		// -2 the table
		switch v := l.TypeOf(-1); v {
		case lua.TypeTable:
			err := encodeItem(l, enc)
			if err != nil {
				l.Pop(1)
				// -1 the table
				return err
			}
		case lua.TypeString:
			str, _ := l.ToString(-1)
			enc.EncodeToken(xml.CharData([]byte(str)))
		case lua.TypeNil:
			l.Pop(1)
			// -1 the table
			break eachindex
		default:
			fmt.Println("last element not a table", v)
		}
		l.Pop(1)
		// -1 the table
	}
	enc.EncodeToken(start.End())
	return nil
}

// ------------
func encodeTable(l *lua.State) int {
	var b bytes.Buffer
	enc := xml.NewEncoder(&b)
	err := encodeItem(l, enc)
	if err != nil {
		fmt.Println(err)
		return lerr(l, err.Error())
	}
	l.SetTop(0)
	l.PushBoolean(true)
	enc.Flush()
	ioutil.WriteFile("data.xml", b.Bytes(), 0644)
	return 1
}

var xmllib = []lua.RegistryFunction{
	{"encode_table", encodeTable},
}

func Open(l *lua.State) {
	requireXML := func(l *lua.State) int {
		lua.NewLibrary(l, xmllib)
		return 1
	}
	lua.Require(l, "xml", requireXML, true)
	l.Pop(1)

}
