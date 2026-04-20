package commandsxml

import (
	"bytes"
	"encoding/xml"
	"fmt"
	"io"
	"strings"
)

// Markdown returns the para content as a Markdown string.
func (p *para) Markdown(lang string) string {
	ret := []string{}
	c := p.commands
	r := bytes.NewReader(p.Text)
	dec := xml.NewDecoder(r)

	for {
		tok, err := dec.Token()
		if err != nil && err == io.EOF {
			break
		}
		if err != nil {
			panic(err)
		}
		switch v := tok.(type) {
		case xml.StartElement:
			switch v.Name.Local {
			case "cmd":
				var x *Command
				var cmdname string
				for _, attribute := range v.Attr {
					if attribute.Name.Local == "name" {
						x = c.commandsEn[attribute.Value]
						if x == nil {
							fmt.Printf("There is an unknown cmd in the para section of %q\n", attribute.Value)
						}
						cmdname = x.Name
					}
				}
				ret = append(ret, "[`"+cmdname+"`]({{% relref \""+x.Mdlink()+"\" %}})")
			case "tt":
				ret = append(ret, "`")
			}
		case xml.CharData:
			ret = append(ret, string(v.Copy()))
		case xml.EndElement:
			switch v.Name.Local {
			case "tt":
				ret = append(ret, "`")
			}
		}
	}
	ret = append(ret, "\n\n")
	return strings.Join(ret, "")
}

// MarkdownDescription returns the description in Markdown format.
func (d *description) Markdown() string {
	if d == nil {
		return ""
	}
	r := bytes.NewReader(d.Text)
	dec := xml.NewDecoder(r)
	var ret []string
	for {
		tok, err := dec.Token()
		if err != nil && err == io.EOF {
			break
		}
		if err != nil {
			panic(err)
		}
		switch v := tok.(type) {
		case xml.StartElement:
			switch v.Name.Local {
			case "para":
				p := &para{}
				p.commands = d.commands
				err = dec.DecodeElement(p, &v)
				if err != nil {
					panic(err)
				}
				ret = append(ret, p.Markdown(d.Lang))
			}
		}
	}
	return strings.Join(ret, "")
}

// DescriptionMarkdown returns the description of the command as a Markdown string.
func (c *Command) DescriptionMarkdown(lang string) string {
	switch lang {
	case "en":
		return c.descriptionEn.Markdown()
	case "de":
		return c.descriptionDe.Markdown()
	}
	return ""
}

// RemarkMarkdown returns the remark section as a Markdown string.
func (c *Command) RemarkMarkdown(lang string) string {
	switch lang {
	case "en":
		return c.remarkEn.Markdown()
	case "de":
		return c.remarkDe.Markdown()
	}
	return ""
}

// InfoMarkdown returns the info section as a Markdown string.
func (c *Command) InfoMarkdown(lang string) string {
	var r *bytes.Reader
	switch lang {
	case "en":
		if x := c.infoEn; x != nil {
			r = bytes.NewReader(x.Text)
		} else {
			return ""
		}
	case "de":
		if x := c.infoDe; x != nil {
			r = bytes.NewReader(x.Text)
		} else {
			return ""
		}
	}

	var ret []string
	dec := xml.NewDecoder(r)

	inListing := false
	for {
		tok, err := dec.Token()
		if err != nil && err == io.EOF {
			break
		}
		if err != nil {
			panic(err)
		}
		switch v := tok.(type) {
		case xml.StartElement:
			switch v.Name.Local {
			case "listing":
				inListing = true
			case "image":
				var fn string
				for _, a := range v.Attr {
					if a.Name.Local == "file" {
						fn = a.Value
					}
				}
				ret = append(ret, fmt.Sprintf("\n![%s](/img/%s)\n", fn, fn))
			case "para":
				p := &para{}
				p.commands = c.commands
				err = dec.DecodeElement(p, &v)
				if err != nil {
					panic(err)
				}
				ret = append(ret, "\n")
				ret = append(ret, p.Markdown(lang))
				ret = append(ret, "\n")
			}
		case xml.CharData:
			if inListing {
				ret = append(ret, "\n```xml\n")
				ret = append(ret, string(v))
				ret = append(ret, "\n```\n")
			}
		case xml.EndElement:
			switch v.Name.Local {
			case "listing":
				inListing = false
			}
		}
	}
	return strings.Join(ret, "")
}

// ExampleMarkdown returns the examples section as a Markdown string.
func (c *Command) ExampleMarkdown(lang string) string {
	var x []*example
	switch lang {
	case "en":
		if x = c.examplesEn; len(x) == 0 {
			return ""
		}
	case "de":
		if x = c.examplesDe; len(x) == 0 {
			return ""
		}
	}
	var ret []string
	for _, ex := range x {
		r := bytes.NewReader(ex.Text)
		dec := xml.NewDecoder(r)

		inListing := false
		for {
			tok, err := dec.Token()
			if err != nil && err == io.EOF {
				break
			}
			if err != nil {
				panic(err)
			}
			switch v := tok.(type) {
			case xml.StartElement:
				switch v.Name.Local {
				case "listing":
					inListing = true
				case "image":
					var fn string
					for _, a := range v.Attr {
						if a.Name.Local == "file" {
							fn = a.Value
						}
					}
					ret = append(ret, fmt.Sprintf("\n![%s](/img/%s)\n", fn, fn))
				case "para":
					p := &para{}
					p.commands = c.commands
					err = dec.DecodeElement(p, &v)
					if err != nil {
						panic(err)
					}
					ret = append(ret, "\n")
					ret = append(ret, p.Markdown(lang))
					ret = append(ret, "\n")
				}
			case xml.CharData:
				if inListing {
					ret = append(ret, "\n```xml\n")
					ret = append(ret, string(v))
					ret = append(ret, "\n```\n")
				}
			case xml.EndElement:
				switch v.Name.Local {
				case "listing":
					inListing = false
				}
			}
		}
	}
	return strings.Join(ret, "")
}

// DescriptionMarkdown returns the description of the attribute as a Markdown string.
func (a *Attribute) DescriptionMarkdown(lang string) string {
	var ret []string
	switch lang {
	case "en":
		ret = append(ret, a.descriptionEn.Markdown())
	case "de":
		ret = append(ret, a.descriptionDe.Markdown())
	default:
		return ""
	}
	for _, c := range a.Choice {
		var name, desc string
		switch lang {
		case "en":
			name = c.Name
			desc = c.descriptionEn.Markdown()
		case "de":
			name = c.Name
			desc = c.descriptionDe.Markdown()
		}
		ret = append(ret, fmt.Sprintf("  - `%s`: %s", name, strings.TrimSpace(desc)))
	}
	return strings.Join(ret, "\n")
}

// Mdlink returns the command name with ".md"
func (c *Command) Mdlink() string {
	if c == nil {
		return ""
	}
	return strings.ToLower(c.Name)
}
