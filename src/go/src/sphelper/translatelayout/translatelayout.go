package translatelayout

import (
	"bytes"
	"encoding/xml"
	"fmt"
	"os"
	"sphelper/commandsxml"
	"sphelper/config"
)

func Translate(cfg *config.Config, inputfilename, outputfilename string) error {
	fmt.Println("translate", inputfilename, outputfilename)
	c, err := commandsxml.ReadCommandsFile(cfg)
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
			outbuf.WriteByte('<')
			outbuf.WriteString(c.TranslateCommand("en", "de", t.Name.Local))
			for _, v := range t.Attr {
				outbuf.WriteByte(' ')
				attname, attvalue := c.TranslateAttribute("en", "de", t.Name.Local, v.Name.Local, v.Value)
				outbuf.WriteString(attname)
				outbuf.WriteByte('=')
				outbuf.WriteByte('"')
				xml.EscapeText(&outbuf, []byte(attvalue))
				outbuf.WriteByte('"')
			}
			outbuf.WriteByte('>')
		case xml.EndElement:
			outbuf.WriteByte('<')
			outbuf.WriteByte('/')
			outbuf.WriteString(c.TranslateCommand("en", "de", t.Name.Local))
			outbuf.WriteByte('>')
		case xml.CharData:
			outbuf.Write(t.Copy())
		default:
			// fmt.Println(tok)
		}

	}
	if true {
		fmt.Println(outbuf.String())
	}
	return nil
}
