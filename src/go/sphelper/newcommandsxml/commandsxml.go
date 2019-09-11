package newcommandsxml

import (
	"bytes"
	"encoding/xml"
	"fmt"
	"html"
	"html/template"
	"io"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"sync"
)

var (
	multipleSpace       *regexp.Regexp
	everysecondast      *regexp.Regexp
	everysecondbacktick *regexp.Regexp
	mutex               = &sync.Mutex{}
)

func init() {
	multipleSpace = regexp.MustCompile(`\s+`)
	everysecondast = regexp.MustCompile(`(?s)(.*?)\*(.*?)\*`)
	everysecondbacktick = regexp.MustCompile("(?s)(.*?\\S)`(\\*)`")
}

type para struct {
	commands *Commands
	Text     []byte `xml:",innerxml"`
}

func (p *para) HTML(lang string) string {
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
						x = c.CommandsEn[attribute.Value]
						if x == nil {
							fmt.Printf("There is an unknown cmd in the para section of %q\n", attribute.Value)
							os.Exit(-1)
						}
						cmdname = x.Name
					}
				}
				ret = append(ret, fmt.Sprintf(`<a href=%q>%s</a>`, x.Htmllink(), cmdname))
			case "tt":
				ret = append(ret, "<tt>")
			}
		case xml.CharData:
			ret = append(ret, string(v.Copy()))
		case xml.EndElement:
			switch v.Name.Local {
			case "tt":
				ret = append(ret, "</tt>")
			}
		}
	}
	return "<p>" + strings.Join(ret, "") + "</p>"
}

func (p *para) Adoc(lang string) string {
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
						x = c.CommandsEn[attribute.Value]
						if x == nil {
							fmt.Printf("There is an unknown cmd in the para section of %q\n", attribute.Value)
							os.Exit(-1)
						}
						cmdname = x.Name
					}
				}
				ret = append(ret, fmt.Sprintf(`<<%s,%s>>`, x.CmdLink(), cmdname))
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
	a := strings.Join(ret, "")
	a = everysecondast.ReplaceAllString(a, "$1\\*$2*")
	a = everysecondbacktick.ReplaceAllString(a, "$1`$2`")
	a = strings.Replace(a, "&", "\\&", -1)
	return a
}

func (p *para) String(lang string) string {
	ret := []string{}
	r := bytes.NewReader(p.Text)
	dec := xml.NewDecoder(r)
outer:
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
				var cmdname string
				for _, attribute := range v.Attr {
					if attribute.Name.Local == "name" {
						cmdname = attribute.Value
					}
				}
				ret = append(ret, cmdname)
			}
		case xml.CharData:
			ret = append(ret, string(v.Copy()))
		case xml.EndElement:
			switch v.Name.Local {
			case "description":
				break outer
			}
		}
	}
	return multipleSpace.ReplaceAllString(strings.Join(ret, ""), " ")
}

type define struct {
	Name string `xml:"name,attr"`
	Text []byte `xml:",innerxml"`
}

type choice struct {
	commands      *Commands
	Text          []byte `xml:",innerxml"`
	Name          string `xml:"en,attr"`
	DescriptionEn *description
	DescriptionDe *description
}

type Attribute struct {
	commands      *Commands
	DescriptionEn *description
	DescriptionDe *description
	Choice        []*choice
	Name          string
	Css           string
	Since         string
	Type          string
	Optional      bool
}

func (c *choice) UnmarshalXML(dec *xml.Decoder, start xml.StartElement) error {
	for {
		tok, err := dec.Token()
		if err != nil && err == io.EOF {
			return nil
		}
		if err != nil {
			return err
		}
		switch v := tok.(type) {
		case xml.StartElement:
			switch v.Name.Local {
			case "description":
				d := &description{}
				d.commands = c.commands
				dec.DecodeElement(d, &v)
				switch d.Lang {
				case "en":
					c.DescriptionEn = d
				case "de":
					c.DescriptionDe = d
				}
			}
		}
	}
	return nil
}

// cmd-commandname-attname
func (a *Attribute) Attlink(cmd *Command) string {
	ret := []string{}
	ret = append(ret, cmd.CmdLink())
	tmp := strings.ToLower(a.Name)
	tmp = strings.Replace(tmp, ":", "_", -1)
	ret = append(ret, tmp)
	return strings.Join(ret, "-")
}

func (a *Attribute) UnmarshalXML(dec *xml.Decoder, start xml.StartElement) error {
	for {
		tok, err := dec.Token()
		if err != nil && err == io.EOF {
			return nil
		}
		if err != nil {
			return err
		}
		switch v := tok.(type) {
		case xml.StartElement:
			switch v.Name.Local {
			case "description":
				d := &description{}
				d.commands = a.commands
				dec.DecodeElement(d, &v)
				switch d.Lang {
				case "en":
					a.DescriptionEn = d
				case "de":
					a.DescriptionDe = d
				}
			case "choice":
				c := &choice{}
				c.commands = a.commands
				dec.DecodeElement(c, &v)
				for _, attribute := range v.Attr {
					switch attribute.Name.Local {
					case "en":
						c.Name = attribute.Value
					}
				}
				a.Choice = append(a.Choice, c)
			}
		}
	}
	return nil
}

func (a *Attribute) DescriptionHTML(lang string) template.HTML {
	var ret []string
	switch lang {
	case "en":
		ret = append(ret, a.DescriptionEn.HTML())
	case "de":
		ret = append(ret, a.DescriptionDe.HTML())
	default:
		return ""
	}
	if len(a.Choice) > 0 {
		ret = append(ret, `<table class="attributechoice">`)
	}
	var name string
	var desc string
	for _, c := range a.Choice {
		switch lang {
		case "en":
			name = c.Name
			desc = c.DescriptionEn.HTML()
		case "de":
			name = c.Name
			desc = c.DescriptionDe.HTML()
		}
		ret = append(ret, "<tr><td><p>")
		ret = append(ret, name+":")
		ret = append(ret, "</p></td><td>")
		ret = append(ret, desc)
		ret = append(ret, "</td></tr>")
	}
	if len(a.Choice) > 0 {
		ret = append(ret, `</table>`)
	}
	return template.HTML(strings.Join(ret, "\n"))
}

func (a *Attribute) DescriptionAdoc(lang string) string {
	var ret []string
	switch lang {
	case "en":
		ret = append(ret, a.DescriptionEn.Adoc())
	case "de":
		ret = append(ret, a.DescriptionDe.Adoc())
	default:
		return ""
	}
	var name string
	var desc string
	for _, c := range a.Choice {
		switch lang {
		case "en":
			name = c.Name
			desc = c.DescriptionEn.Adoc()
		case "de":
			name = c.Name
			desc = c.DescriptionDe.Adoc()
		}
		ret = append(ret, "\n`"+name+"`:::\n"+desc)
	}
	return string(strings.Join(ret, "\n"))
}

func (a *Attribute) HTMLFragment() string {
	return a.Name
}

type Childelement struct {
	commands *Commands
	Text     []byte `xml:",innerxml"`
}

type example struct {
	commands *Commands
	Lang     string `xml:"http://www.w3.org/XML/1998/namespace lang,attr"`
	Text     []byte `xml:",innerxml"`
}

type seealso struct {
	commands *Commands
	Text     []byte `xml:",innerxml"`
}

type description struct {
	commands *Commands
	Lang     string `xml:"http://www.w3.org/XML/1998/namespace lang,attr"`
	Text     []byte `xml:",innerxml"`
}

func (d *description) HTML() string {
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
				ret = append(ret, p.HTML(d.Lang))

			}
		}
	}
	return strings.Join(ret, "")
}

func (d *description) Adoc() string {
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
				ret = append(ret, p.Adoc(d.Lang))

			}
		}
	}
	return strings.Join(ret, "")
}

func (d *description) String() string {
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
				ret = append(ret, p.String(d.Lang))

			}
		}
	}
	return strings.Join(ret, "")
}

type Command struct {
	commands       *Commands
	parentelements map[*Command]bool
	DescriptionEn  *description
	DescriptionDe  *description
	RemarkEn       *description
	RemarkDe       *description
	InfoEn         *description
	InfoDe         *description
	Attr           []*Attribute
	ExamplesEn     []*example
	ExamplesDe     []*example
	Childelement   *Childelement
	Children       map[string][]*Command
	Name           string
	Css            string
	Since          string
	Deprecated     bool
	seealso        *seealso
}

func (c *Command) Parents(lang string) []*Command {
	var cmds []*Command
	mutex.Lock()
	for k, _ := range c.parentelements {
		cmds = append(cmds, k)
	}
	mutex.Unlock()
	sort.Sort(commandsbyen{cmds})

	return cmds
}

func (c *Command) String() string {
	return c.Name
}

func (c *Command) UnmarshalXML(dec *xml.Decoder, start xml.StartElement) error {
	for {
		tok, err := dec.Token()
		if err != nil && err == io.EOF {
			return nil
		}
		if err != nil {
			return err
		}
		switch v := tok.(type) {
		case xml.StartElement:
			switch v.Name.Local {
			case "description":
				d := &description{}
				d.commands = c.commands
				dec.DecodeElement(d, &v)
				switch d.Lang {
				case "en":
					c.DescriptionEn = d
				case "de":
					c.DescriptionDe = d
				}
			case "info":
				d := &description{}
				d.commands = c.commands
				dec.DecodeElement(d, &v)
				switch d.Lang {
				case "en":
					c.InfoEn = d
				case "de":
					c.InfoDe = d
				}
			case "remark":
				d := &description{}
				d.commands = c.commands
				dec.DecodeElement(d, &v)
				switch d.Lang {
				case "en":
					c.RemarkEn = d
				case "de":
					c.RemarkDe = d
				}

			case "attribute":
				a := &Attribute{}
				a.commands = c.commands
				dec.DecodeElement(a, &v)
				for _, attribute := range v.Attr {
					switch attribute.Name.Local {
					case "en":
						a.Name = attribute.Value
					case "css":
						a.Css = attribute.Value
					case "since":
						a.Since = attribute.Value
					case "optional":
						a.Optional = attribute.Value == "yes"
					case "type":
						a.Type = attribute.Value
					}
				}

				c.Attr = append(c.Attr, a)
			case "childelements":
				child := &Childelement{}
				child.commands = c.commands
				dec.DecodeElement(child, &v)
				c.Childelement = child
			case "example":
				e := &example{}
				e.commands = c.commands
				dec.DecodeElement(e, &v)
				switch e.Lang {
				case "en":
					c.ExamplesEn = append(c.ExamplesEn, e)
				case "de":
					c.ExamplesDe = append(c.ExamplesDe, e)
				}
			case "seealso":
				e := &seealso{}
				e.commands = c.commands
				dec.DecodeElement(e, &v)
				c.seealso = e
			}
		}
	}
	return nil
}

func (c *Command) Adoclink() string {
	if c == nil {
		return ""
	}
	tmp := url.URL{Path: strings.ToLower(c.Name)}
	filenameSansExtension := tmp.String()
	return filenameSansExtension + ".adoc"
}

func (c *Command) Htmllink() string {
	if c == nil {
		return ""
	}
	tmp := url.URL{Path: strings.ToLower(c.Name)}
	filenameSansExtension := tmp.String()
	return filenameSansExtension + ".html"
}

// cmd-atpageshipout
func (c *Command) CmdLink() string {
	if c == nil {
		return ""
	}
	tmp := url.URL{Path: strings.ToLower(c.Name)}
	filenameSansExtension := tmp.String()
	filenameSansExtension = strings.Replace(filenameSansExtension, "-", "_", -1)
	// this works around a bug in Hugo
	// https://github.com/gohugoio/hugo/issues/4666
	if strings.HasSuffix(filenameSansExtension, "index") {
		filenameSansExtension = strings.TrimSuffix(filenameSansExtension, "index") + "index_"
	}
	return "cmd-" + filenameSansExtension
}

//
func (c *Command) DescriptionHTML(lang string) template.HTML {
	var ret string
	switch lang {
	case "en":
		ret = c.DescriptionEn.HTML()
	case "de":
		ret = c.DescriptionDe.HTML()
	default:
		ret = ""
	}
	return template.HTML(ret)
}

func (c *Command) DescriptionAdoc(lang string) string {
	var ret string
	switch lang {
	case "en":
		ret = c.DescriptionEn.Adoc()
	case "de":
		ret = c.DescriptionDe.Adoc()
	default:
		ret = ""
	}
	return ret
}

func (c *Command) RemarkHTML(lang string) template.HTML {
	var ret string
	switch lang {
	case "en":
		ret = c.RemarkEn.HTML()
	case "de":
		ret = c.RemarkDe.HTML()
	default:
		ret = ""
	}
	return template.HTML(ret)
}

func (c *Command) RemarkAdoc(lang string) string {
	var ret string
	switch lang {
	case "en":
		ret = c.RemarkEn.Adoc()
	case "de":
		ret = c.RemarkDe.Adoc()
	default:
		ret = ""
	}
	return ret
}

func (c *Command) InfoHTML(lang string) template.HTML {
	var r *bytes.Reader
	switch lang {
	case "en":
		if x := c.InfoEn; x == nil {
			return template.HTML("")
		} else {
			r = bytes.NewReader(x.Text)
		}
	case "de":
		if x := c.InfoDe; x == nil {
			return template.HTML("")
		} else {
			r = bytes.NewReader(x.Text)
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
				var fn, wd string
				for _, a := range v.Attr {
					wd = "max-width: 90%;"
					if a.Name.Local == "file" {
						fn = a.Value
					} else if a.Name.Local == "width" {
						wd = fmt.Sprintf(`width: %s;`, a.Value)
					}
				}
				ret = append(ret, fmt.Sprintf(`<img style="%s padding-left: 1em;" src="../img/%s">`, wd, fn))
			case "para":
				p := &para{}
				p.commands = c.commands
				err = dec.DecodeElement(p, &v)
				if err != nil {
					panic(err)
				}
				ret = append(ret, p.HTML(lang))
			}
		case xml.CharData:
			if inListing {
				ret = append(ret, `<pre class="syntax xml">`+html.EscapeString(string(v))+`</pre>`)
			}
		case xml.EndElement:
			switch v.Name.Local {
			case "listing":
				inListing = false
			}
		}
	}
	return template.HTML(strings.Join(ret, ""))
}

func (c *Command) InfoAdoc(lang string) string {
	var r *bytes.Reader
	switch lang {
	case "en":
		if x := c.InfoEn; x == nil {
			return ""
		} else {
			r = bytes.NewReader(x.Text)
		}
	case "de":
		if x := c.InfoDe; x == nil {
			return ""
		} else {
			r = bytes.NewReader(x.Text)
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
				var fn, wd string
				for _, a := range v.Attr {
					wd = "auto"
					if a.Name.Local == "file" {
						fn = a.Value
					} else if a.Name.Local == "width" {
						wd = fmt.Sprintf(`%s`, a.Value)
					}
				}
				ret = append(ret, fmt.Sprintf("\nimage::%s[width=%s]\n", fn, wd))
			case "para":
				p := &para{}
				p.commands = c.commands
				err = dec.DecodeElement(p, &v)
				if err != nil {
					panic(err)
				}
				ret = append(ret, "\n")
				ret = append(ret, p.Adoc(lang))
				ret = append(ret, "\n")
			}
		case xml.CharData:
			if inListing {
				ret = append(ret, `[source, xml]
-------------------------------------------------------------------------------
`)
				ret = append(ret, string(v))
				ret = append(ret, `
-------------------------------------------------------------------------------
`)

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

func (c *Command) DescriptionText(lang string) string {
	var r *bytes.Reader
	switch lang {
	case "en":
		r = bytes.NewReader(c.DescriptionEn.Text)
	case "de":
		r = bytes.NewReader(c.DescriptionDe.Text)
	default:
		return ""
	}
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
				p.commands = c.commands
				err = dec.DecodeElement(p, &v)
				if err != nil {
					panic(err)
				}
				ret = append(ret, p.String(lang))
			}
		}
	}
	return strings.Join(ret, "")
}

type reference struct {
	longnameEn  string
	longnameDe  string
	pagename    string
	chaptername string
}

var (
	references map[string]reference
)

func init() {
	references = map[string]reference{
		"fonts": {
			"How to use fonts", "Einbinden von Schriftarten", "fonts.html", "",
		},
		"directories": {
			"How to generate a table of contents and other directories", "Wie werden Verzeichnisse erstellt?", "directories.html", "",
		},
		"cutmarks": {
			"Cutmarks and bleed", "Schnittmarken und Beschnittzugabe", "cutmarks.html", "",
		},
		"xpath": {
			"XPath expressions", "XPath-Ausdrücke", "xpath.html", "ch-xpathfunktionen",
		},
		"css": {
			"Using CSS with the speedata Publisher", "CSS im speedata Publisher", "css.html", "",
		},
	}
}

func (c *Command) SeealsoHTML(lang string) template.HTML {
	if c.seealso == nil {
		return ""
	}
	ret := []string{}
	r := bytes.NewReader(c.seealso.Text)
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
						x = c.commands.CommandsEn[attribute.Value]
						if x == nil {
							fmt.Printf("There is an unknown cmd in the seealso section of %q (%q)\n", c.Name, attribute.Value)
							os.Exit(-1)
						}
						cmdname = x.Name
					}
				}
				ret = append(ret, fmt.Sprintf(`<a href=%q>%s</a>`, x.Htmllink(), cmdname))
			case "ref":
				var nameatt string
				for _, attribute := range v.Attr {
					if attribute.Name.Local == "name" {
						nameatt = attribute.Value
					}
				}
				if x, ok := references[nameatt]; ok {
					switch lang {
					case "en":
						ret = append(ret, fmt.Sprintf(`<a href="../description-en/%s">%s</a>`, x.pagename, x.longnameEn))
					case "de":
						ret = append(ret, fmt.Sprintf(`<a href="../description-de/%s">%s</a>`, x.pagename, x.longnameDe))
					}
				} else {
					ret = append(ret, nameatt)
				}
			}
		case xml.CharData:
			ret = append(ret, string(v.Copy()))
		}
	}
	return template.HTML(strings.Join(ret, ""))
}

func (c *Command) SeealsoAdoc(lang string) string {
	if c.seealso == nil {
		return ""
	}
	ret := []string{}
	r := bytes.NewReader(c.seealso.Text)
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
						x = c.commands.CommandsEn[attribute.Value]
						if x == nil {
							fmt.Printf("There is an unknown cmd in the seealso section of %q (%q)\n", c.Name, attribute.Value)
							os.Exit(-1)
						}
						cmdname = x.Name
					}
				}
				ret = append(ret, fmt.Sprintf(`<a href=%q>%s</a>`, x.Htmllink(), cmdname))
			case "ref":
				var nameatt string
				for _, attribute := range v.Attr {
					if attribute.Name.Local == "name" {
						nameatt = attribute.Value
					}
				}
				if x, ok := references[nameatt]; ok {
					switch lang {
					case "en":
						ret = append(ret, fmt.Sprintf(`<<%s,%s>>`, x.pagename, x.longnameEn))
					case "de":
						ret = append(ret, fmt.Sprintf(`<<%s,%s>>`, x.pagename, x.longnameDe))
					}
				} else {
					ret = append(ret, nameatt)
				}
			}
		case xml.CharData:
			ret = append(ret, string(v.Copy()))
		}
	}
	return strings.Join(ret, "")
}

func (c *Command) Attributes() []*Attribute {
	mutex.Lock()
	sort.Sort(attributesbyen{c.Attr})
	ret := make([]*Attribute, len(c.Attr))
	copy(ret, c.Attr)
	mutex.Unlock()
	return ret
}

func (c *Command) ExampleAdoc(lang string) string {
	var r *bytes.Reader
	switch lang {
	case "en":
		if x := c.ExamplesEn; len(x) == 0 {
			return ""
		} else {
			r = bytes.NewReader(x[0].Text)
		}
	case "de":
		if x := c.ExamplesDe; len(x) == 0 {
			return ""
		} else {
			r = bytes.NewReader(x[0].Text)
		}
	default:
		return ""
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
				var fn, wd string
				for _, a := range v.Attr {
					wd = "auto"
					if a.Name.Local == "file" {
						fn = a.Value
					} else if a.Name.Local == "width" {
						wd = fmt.Sprintf(`%s`, a.Value)
					}
				}
				ret = append(ret, fmt.Sprintf("\nimage::%s[width=%s]\n", fn, wd))
			case "para":
				p := &para{}
				p.commands = c.commands
				err = dec.DecodeElement(p, &v)
				if err != nil {
					panic(err)
				}
				ret = append(ret, "\n")
				ret = append(ret, p.Adoc(lang))
				ret = append(ret, "\n")
			}
		case xml.CharData:
			if inListing {
				ret = append(ret, `[source, xml]
-------------------------------------------------------------------------------
`)
				ret = append(ret, string(v))
				ret = append(ret, `
-------------------------------------------------------------------------------
`)
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

func (c *Command) ExampleHTML(lang string) template.HTML {
	var r *bytes.Reader
	switch lang {
	case "en":
		if x := c.ExamplesEn; len(x) == 0 {
			return template.HTML("")
		} else {
			r = bytes.NewReader(x[0].Text)
		}
	case "de":
		if x := c.ExamplesDe; len(x) == 0 {
			return template.HTML("")
		} else {
			r = bytes.NewReader(x[0].Text)
		}
	default:
		return template.HTML("")
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
				var fn, wd string
				for _, a := range v.Attr {
					wd = "max-width: 90%;"
					if a.Name.Local == "file" {
						fn = a.Value
					} else if a.Name.Local == "width" {
						wd = fmt.Sprintf(`width: %s;`, a.Value)
					}
				}
				ret = append(ret, fmt.Sprintf(`<img style="%s padding-left: 1em;" src="../img/%s">`, wd, fn))
			case "para":
				p := &para{}
				p.commands = c.commands
				err = dec.DecodeElement(p, &v)
				if err != nil {
					panic(err)
				}
				ret = append(ret, p.HTML(lang))
			}
		case xml.CharData:
			if inListing {
				ret = append(ret, `<pre class="syntax xml">`+html.EscapeString(string(v))+`</pre>`)
			}
		case xml.EndElement:
			switch v.Name.Local {
			case "listing":
				inListing = false
			}
		}
	}
	return template.HTML(strings.Join(ret, ""))
}

func getchildren(c *Commands, dec *xml.Decoder) []*Command {
	var cmds []*Command
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
			switch eltname := v.Name.Local; eltname {
			case "cmd":
				var cmdname string
				for _, attribute := range v.Attr {
					if attribute.Name.Local == "name" {
						cmdname = attribute.Value
					}
				}
				cmds = append(cmds, c.CommandsEn[cmdname])
			case "reference":
				var refname string
				for _, attribute := range v.Attr {
					if attribute.Name.Local == "name" {
						refname = attribute.Value
					}
				}
				{
					dec = xml.NewDecoder(bytes.NewReader(c.defines[refname].Text))
					x := getchildren(c, dec)
					for _, command := range x {
						cmds = append(cmds, command)
					}
				}
			default:
			}
		}
	}
	return cmds
}

func (c *Command) Childelements(lang string) []*Command {
	if c == nil {
		return nil
	}
	mutex.Lock()
	x := c.Children[lang]
	mutex.Unlock()
	if x != nil {
		return x
	}

	r := bytes.NewReader(c.Childelement.Text)
	dec := xml.NewDecoder(r)

	cmds := getchildren(c.commands, dec)

	mutex.Lock()
	for _, v := range cmds {
		v.parentelements[c] = true
	}
	mutex.Unlock()
	if lang == "en" {
		sort.Sort(commandsbyen{cmds})
	} else {
		sort.Sort(commandsbyen{cmds})
	}
	mutex.Lock()
	c.Children[lang] = cmds
	mutex.Unlock()
	return cmds
}

type Commands struct {
	defines          map[string]*define
	CommandsEn       map[string]*Command
	CommandsSortedEn []*Command
}

// sorting (de, en)
type sortcommands []*Command
type sortattributes []*Attribute

func (s sortcommands) Len() int        { return len(s) }
func (s sortcommands) Swap(i, j int)   { s[i], s[j] = s[j], s[i] }
func (s sortattributes) Len() int      { return len(s) }
func (s sortattributes) Swap(i, j int) { s[i], s[j] = s[j], s[i] }

type commandsbyen struct{ sortcommands }
type attributesbyen struct{ sortattributes }

func (s commandsbyen) Less(i, j int) bool { return s.sortcommands[i].Name < s.sortcommands[j].Name }
func (s attributesbyen) Less(i, j int) bool {
	return s.sortattributes[i].Name < s.sortattributes[j].Name
}

func ReadCommandsFile(r io.Reader) (*Commands, error) {
	commands := &Commands{}
	commands.defines = make(map[string]*define)
	commands.CommandsEn = make(map[string]*Command)
	dec := xml.NewDecoder(r)
	for {
		tok, err := dec.Token()
		if err != nil && err != io.EOF {
			return nil, err
		}
		if err == io.EOF {
			break
		}

		switch v := tok.(type) {
		case xml.StartElement:

			switch v.Name.Local {
			// case "commands":
			// 	// OK, root element
			case "define":
				d := &define{}
				err = dec.DecodeElement(d, &v)
				if err != nil {
					return nil, err
				}
				commands.defines[d.Name] = d
			case "command":
				c := &Command{}
				c.commands = commands
				c.Children = make(map[string][]*Command)
				c.parentelements = make(map[*Command]bool)

				err = dec.DecodeElement(c, &v)
				if err != nil {
					return nil, err
				}
				commands.CommandsSortedEn = append(commands.CommandsSortedEn, c)

				for _, attribute := range v.Attr {
					if attribute.Name.Local == "en" {
						commands.CommandsEn[attribute.Value] = c
						c.Name = attribute.Value
					}
					if attribute.Name.Local == "css" {
						c.Css = attribute.Value
					}
					if attribute.Name.Local == "since" {
						c.Since = attribute.Value
					}
					if attribute.Name.Local == "deprecated" {
						c.Deprecated = attribute.Value == "yes"
					}
				}
			}
		}
	}
	sort.Sort(commandsbyen{commands.CommandsSortedEn})
	return commands, nil
}

func LoadCommandsFile(basedir string) (*Commands, error) {
	r, err := os.Open(filepath.Join(basedir, "doc", "commands-xml", "commands.xml"))
	if err != nil {
		return nil, err
	}
	return ReadCommandsFile(r)
}
