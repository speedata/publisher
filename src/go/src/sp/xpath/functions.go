package xpath

import (
	"bytes"
	"encoding/xml"
	"fmt"
	"io"
	"regexp"
	"strings"
)

// replace() xpath function
func Replace(text []byte, rexpr string, repl []byte) []byte {
	r, err := regexp.Compile(rexpr)
	if err != nil {
		return nil
	}

	// xpath uses $12 for $12 or $1, depending on the existence of $12 or $1.
	// go on the other hand uses $12 for $12 and never for $1, so you have to write
	// $1 as ${1} if there is text after the $1.
	// We escape the $n backwards to prevent expansion of $12 to ${1}2
	for i := r.NumSubexp(); i > 0; i-- {
		// first create rexepx that match "$i"
		x := fmt.Sprintf(`\$(%d)`, i)
		nummatcher := regexp.MustCompile(x)
		repl = nummatcher.ReplaceAll(repl, []byte(`$${1}`))
	}
	str := r.ReplaceAll(text, repl)
	return str
}

// tokenize() xpath function
func Tokenize(text []byte, rexpr string) []string {
	r, err := regexp.Compile(rexpr)
	if err != nil {
		return nil
	}
	idx := r.FindAllIndex(text, -1)
	pos := 0
	var res []string
	for _, v := range idx {
		res = append(res, string(text[pos:v[0]]))
		pos = v[1]
	}
	res = append(res, string(text[pos:]))
	return res
}

func HtmlToXml(input string) (string, error) {
	input = "<toplevel·toplevel>" + input + "</toplevel·toplevel>"
	r := strings.NewReader(input)
	var w bytes.Buffer

	enc := xml.NewEncoder(&w)
	dec := xml.NewDecoder(r)

	dec.Strict = false
	dec.AutoClose = xml.HTMLAutoClose
	for {
		t, err := dec.Token()
		if err == io.EOF {
			break
		}
		if err != nil {
			enc.Flush()
			return w.String(), err
		}
		switch v := t.(type) {
		case xml.StartElement:
			if v.Name.Local != "toplevel·toplevel" {
				enc.EncodeToken(t)
			}
		case xml.EndElement:
			if v.Name.Local != "toplevel·toplevel" {
				enc.EncodeToken(t)
			}
		case xml.CharData:
			enc.EncodeToken(t)
		default:
			// fmt.Println(v)
		}
	}
	enc.Flush()
	return w.String(), nil
}
