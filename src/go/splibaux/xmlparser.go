package splibaux

import (
	"fmt"
	"io"
	"strings"

	"speedatapublisher/xml"
)

func luaescape(s string) string {
	return nr.Replace(s)
}

func indent(i int) string {
	return strings.Repeat("    ", i)
}

func readXMLFile(r io.Reader, startindex, extraindentlevel int) (string, error) {
	var out strings.Builder

	stackcounter := []int{startindex}

	dec := xml.NewDecoder(r)
	dec.Entity = xml.HTMLEntity
	indentlevel := 0
	for {
		tok, err := dec.Token()
		if err == io.EOF {
			break
		}
		if err != nil {
			return "", err
		}
		indentamount := indentlevel + extraindentlevel + 1

		switch v := tok.(type) {
		case xml.StartElement:
			var href string
			if v.Name.Space == "http://www.w3.org/2001/XInclude" && v.Name.Local == "include" {
				for _, attr := range v.Attr {
					if attr.Name.Local == "href" {
						href = attr.Value
					}
				}
				str, err := handleXInclude(href, stackcounter[indentlevel], indentamount-1)
				if err != nil {
					return "", err
				}
				fmt.Fprintf(&out, "%s", str)
			} else {

				fmt.Fprintf(&out, "%s[%d] = {", indent(indentamount-1), stackcounter[indentlevel])
				fmt.Fprintln(&out)
				fmt.Fprintf(&out, `%s[".__name"] = "%s",`, indent(indentamount), luaescape(v.Name.Local))
				fmt.Fprintln(&out)
				fmt.Fprintf(&out, `%s[".__type"] = "element",`, indent(indentamount))
				fmt.Fprintln(&out)
				fmt.Fprintf(&out, `%s[".__local_name"] = "%s",`, indent(indentamount), luaescape(v.Name.Local))
				fmt.Fprintln(&out)
				fmt.Fprintf(&out, `%s[".__namespace"] = "%s",`, indent(indentamount), luaescape(v.Name.Space))
				fmt.Fprintln(&out)
				line, col := dec.InputPos()
				fmt.Fprintf(&out, `%s[".__line"] = %d,[".__col"] = %d,`, indent(indentamount), line, col)
				fmt.Fprintln(&out)

				attributes := make(map[string]string)

				fmt.Fprintf(&out, `%s[".__ns"] = {`, indent(indentamount))
				fmt.Fprintln(&out)
				for _, attr := range v.Attr {
					if attr.Name.Space == "xmlns" {
						fmt.Fprintf(&out, `%s["%s"] = "%s",`, indent(indentamount+1), attr.Name.Local, attr.Value)
						fmt.Fprintln(&out)
					} else if attr.Name.Local == "xmlns" {
						fmt.Fprintf(&out, `%s[""] = "%s",`, indent(indentamount+1), attr.Value)
						fmt.Fprintln(&out)
					} else {
						attributes[attr.Name.Local] = attr.Value
					}
				}
				fmt.Fprintf(&out, "%s},\n", indent(indentamount))
				for k, val := range attributes {
					fmt.Fprintf(&out, `%s["%s"] = "%s", `, indent(indentamount), luaescape(k), luaescape(val))
					fmt.Fprintln(&out)
				}
			}
			stackcounter[indentlevel]++
			indentlevel++
			stackcounter = append(stackcounter, 1)
		case xml.CharData:
			if indentlevel > 0 {

				index := stackcounter[indentlevel]
				stackcounter[indentlevel] = index + 1
				fmt.Fprintf(&out, "%s[%d] = ", indent(indentlevel+extraindentlevel), index)
				fmt.Fprintf(&out, `"%s",`, luaescape(string(v.Copy())))
				fmt.Fprintln(&out)
			}
		case xml.EndElement:
			if v.Name.Space == "http://www.w3.org/2001/XInclude" && v.Name.Local == "include" {
				// ignore
			} else {
				fmt.Fprintf(&out, "%s},\n", indent(indentlevel+extraindentlevel))
			}

			stackcounter = stackcounter[:len(stackcounter)-1]
			indentlevel--
		}
	}
	return out.String(), nil
}
