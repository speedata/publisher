package translatelayout

import (
	"bytes"
	"encoding/xml"
	"fmt"
	"io/ioutil"
	"os"
	"strings"

	"sphelper/commandsxml"
)

func Translate(basedir, inputfilename, outputfilename string) error {
	c, err := commandsxml.ReadCommandsFile(basedir)
	if err != nil {
		return err
	}
	in, err := os.Open(inputfilename)
	if err != nil {
		return err
	}
	defer in.Close()
	var outbuf bytes.Buffer
	dec := xml.NewDecoder(in)
	var sourcelang, destlang string
	for {
		tok, err := dec.Token()
		if tok == nil {
			break
		}
		if err != nil {
			return err
		}
		switch t := tok.(type) {
		case xml.StartElement:
			if t.Name.Local == "Layout" {
				if t.Name.Space == "urn:speedata.de:2009/publisher/en" {
					sourcelang = "en"
					destlang = "de"
				} else {
					sourcelang = "de"
					destlang = "en"
				}
			}
			outbuf.WriteByte('<')
			outbuf.WriteString(c.TranslateCommand(sourcelang, destlang, t.Name.Local))
			for _, v := range t.Attr {
				if v.Name.Local == "xmlns" {
					outbuf.WriteString(fmt.Sprintf(` xmlns="urn:speedata.de:2009/publisher/%s"`, destlang))
				} else if strings.HasPrefix(v.Value, "urn:speedata:2009/publisher/functions/") {
					outbuf.WriteString(fmt.Sprintf(` xmlns:%s="urn:speedata:2009/publisher/functions/%s"`, v.Name.Local, destlang))
				} else {
					outbuf.WriteByte(' ')
					attname, attvalue := c.TranslateAttribute(sourcelang, destlang, t.Name.Local, v.Name.Local, v.Value)
					outbuf.WriteString(attname)
					outbuf.WriteByte('=')
					outbuf.WriteByte('"')
					xml.EscapeText(&outbuf, []byte(attvalue))
					outbuf.WriteByte('"')
				}
			}
			outbuf.WriteByte('>')
		case xml.EndElement:
			outbuf.WriteByte('<')
			outbuf.WriteByte('/')
			outbuf.WriteString(c.TranslateCommand(sourcelang, destlang, t.Name.Local))
			outbuf.WriteByte('>')
		case xml.CharData:
			outbuf.Write(t.Copy())
		case xml.ProcInst:
			outbuf.WriteString(fmt.Sprintf(`<?%s %s?>`, t.Target, t.Copy().Inst))
		case xml.Comment:
			outbuf.WriteString(fmt.Sprintf(`<!-- %s -->`, t.Copy()))
		default:
			fmt.Println(tok)
		}
	}
	if outputfilename == "" {
		fmt.Println(outbuf.String())
	} else {
		err = ioutil.WriteFile(outputfilename, outbuf.Bytes(), 0644)
		return err
	}
	return nil
}
