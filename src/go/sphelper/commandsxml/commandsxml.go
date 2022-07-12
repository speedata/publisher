// Package commandsxml reads the commands.xml file.
package commandsxml

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
						x = c.commandsEn[attribute.Value]
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
						x = c.commandsEn[attribute.Value]
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

// DescriptionText returns the description of the attribute without markup.
func (c *Choice) DescriptionText(lang string) string {
	var ret string
	switch lang {
	case "en":
		ret = descriptiontext(c.commands, c.descriptionEn.Text, lang)
	case "de":
		ret = descriptiontext(c.commands, c.descriptionDe.Text, lang)
	}
	return ret
}

// Choice represents alternative attribute values
type Choice struct {
	commands      *Commands
	Text          []byte `xml:",innerxml"`
	Name          string `xml:"en,attr"`
	descriptionEn *description
	descriptionDe *description
}

// Attribute has all information about each attribute
type Attribute struct {
	Choice        []*Choice
	Name          string
	CSS           string
	Since         string
	Type          string
	Optional      bool
	AllowXPath    bool
	commands      *Commands
	command       *Command
	descriptionEn *description
	descriptionDe *description
}

// UnmarshalXML fills the Choice value
func (c *Choice) UnmarshalXML(dec *xml.Decoder, start xml.StartElement) error {
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
					c.descriptionEn = d
				case "de":
					c.descriptionDe = d
				}
			}
		}
	}
}

// Attlink returns a string in the form of cmd-commandname-attribute e.g. cmd-setvariable-select
func (a *Attribute) Attlink() string {
	cmd := a.command
	ret := []string{}
	ret = append(ret, cmd.CmdLink())
	tmp := strings.ToLower(a.Name)
	tmp = strings.Replace(tmp, ":", "_", -1)
	ret = append(ret, tmp)
	return strings.Join(ret, "-")
}

// UnmarshalXML fills the attribute from the given XML segment
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
					a.descriptionEn = d
				case "de":
					a.descriptionDe = d
				}
			case "choice":
				c := &Choice{}
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
}

// DescriptionText returns the description of the attribute without markup.
func (a *Attribute) DescriptionText(lang string) string {
	var ret string
	switch lang {
	case "en":
		ret = descriptiontext(a.commands, a.descriptionEn.Text, lang)
	case "de":
		ret = descriptiontext(a.commands, a.descriptionDe.Text, lang)
	}
	return ret

}

// DescriptionHTML returns the the attribute description as an HTML blob.
func (a *Attribute) DescriptionHTML(lang string) template.HTML {
	var ret []string
	switch lang {
	case "en":
		ret = append(ret, a.descriptionEn.HTML())
	case "de":
		ret = append(ret, a.descriptionDe.HTML())
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
			desc = c.descriptionEn.HTML()
		case "de":
			name = c.Name
			desc = c.descriptionDe.HTML()
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

// DescriptionAdoc returns the description of the attribute as an asciidoctor blob.
func (a *Attribute) DescriptionAdoc(lang string) string {
	var ret []string
	switch lang {
	case "en":
		ret = append(ret, a.descriptionEn.Adoc())
	case "de":
		ret = append(ret, a.descriptionDe.Adoc())
	default:
		return ""
	}
	var name string
	var desc string
	for _, c := range a.Choice {
		switch lang {
		case "en":
			name = c.Name
			desc = c.descriptionEn.Adoc()
		case "de":
			name = c.Name
			desc = c.descriptionDe.Adoc()
		}
		ret = append(ret, "\n`"+name+"`:::\n"+desc)
	}
	return string(strings.Join(ret, "\n"))
}

// Childelement has all child elements of a command.
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

// Adoc returns the description in asciidoctor format.
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

// SchematronRules represents schematron rules
type SchematronRules struct {
	Lang  string `xml:"lang,attr"`
	Rules string `xml:",innerxml"`
}

// Command has information about a command
type Command struct {
	Attr           []*Attribute
	Name           string
	CSS            string
	Since          string
	Deprecated     bool
	Rules          []SchematronRules `xml:"rules"`
	childelement   *Childelement
	remarkEn       *description
	remarkDe       *description
	infoEn         *description
	infoDe         *description
	descriptionEn  *description
	descriptionDe  *description
	commands       *Commands
	parentelements map[*Command]bool
	examplesEn     []*example
	examplesDe     []*example
	children       map[string][]*Command
	seealso        *seealso
}

// Parents returns all parent commands
func (c *Command) Parents(lang string) []*Command {

	var cmds []*Command
	mutex.Lock()
	for k := range c.parentelements {
		cmds = append(cmds, k)
	}
	mutex.Unlock()
	sort.Sort(commandsbyen{cmds})

	return cmds
}

func (c *Command) String() string {
	return c.Name
}

// UnmarshalXML fills the command from the XML segment
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
					c.descriptionEn = d
				case "de":
					c.descriptionDe = d
				}
			case "info":
				d := &description{}
				d.commands = c.commands
				dec.DecodeElement(d, &v)
				switch d.Lang {
				case "en":
					c.infoEn = d
				case "de":
					c.infoDe = d
				}
			case "remark":
				d := &description{}
				d.commands = c.commands
				dec.DecodeElement(d, &v)
				switch d.Lang {
				case "en":
					c.remarkEn = d
				case "de":
					c.remarkDe = d
				}

			case "attribute":
				a := &Attribute{}
				a.commands = c.commands
				a.command = c
				dec.DecodeElement(a, &v)
				for _, attribute := range v.Attr {
					switch attribute.Name.Local {
					case "en":
						a.Name = attribute.Value
					case "css":
						a.CSS = attribute.Value
					case "since":
						a.Since = attribute.Value
					case "optional":
						a.Optional = attribute.Value == "yes"
					case "type":
						a.Type = attribute.Value
					case "allowxpath":
						a.AllowXPath = attribute.Value == "yes"
					}
				}

				c.Attr = append(c.Attr, a)
			case "childelements":
				child := &Childelement{}
				child.commands = c.commands
				dec.DecodeElement(child, &v)
				c.childelement = child
			case "example":
				e := &example{}
				e.commands = c.commands
				dec.DecodeElement(e, &v)
				switch e.Lang {
				case "en":
					c.examplesEn = append(c.examplesEn, e)
				case "de":
					c.examplesDe = append(c.examplesDe, e)
				}
			case "seealso":
				e := &seealso{}
				e.commands = c.commands
				dec.DecodeElement(e, &v)
				c.seealso = e
			case "rules":
				r := &SchematronRules{}
				dec.DecodeElement(r, &v)
				c.Rules = append(c.Rules, *r)
			}
		}
	}
}

// Adoclink returns the command name with ".adoc"
func (c *Command) Adoclink() string {
	if c == nil {
		return ""
	}
	tmp := url.URL{Path: strings.ToLower(c.Name)}
	filenameSansExtension := tmp.String()
	return filenameSansExtension + ".adoc"
}

// Htmllink returns a text such as "mycmd.html"
func (c *Command) Htmllink() string {
	if c == nil {
		return ""
	}
	tmp := url.URL{Path: strings.ToLower(c.Name)}
	filenameSansExtension := tmp.String()
	return filenameSansExtension + ".html"
}

// CmdLink returns a text such as cmd-atpageshipout
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

// DescriptionHTML returns the description as a HTML blob
func (c *Command) DescriptionHTML(lang string) template.HTML {
	var ret string
	switch lang {
	case "en":
		ret = c.descriptionEn.HTML()
	case "de":
		ret = c.descriptionDe.HTML()
	default:
		ret = ""
	}
	return template.HTML(ret)
}

// DescriptionAdoc returns the description of the command as a asciidoctor blob.
func (c *Command) DescriptionAdoc(lang string) string {
	var ret string
	switch lang {
	case "en":
		ret = c.descriptionEn.Adoc()
	case "de":
		ret = c.descriptionDe.Adoc()
	default:
		ret = ""
	}
	return ret
}

// RemarkHTML returns the remark section as a formatted HTML blob.
func (c *Command) RemarkHTML(lang string) template.HTML {
	var ret string
	switch lang {
	case "en":
		ret = c.remarkEn.HTML()
	case "de":
		ret = c.remarkDe.HTML()
	default:
		ret = ""
	}
	return template.HTML(ret)
}

// RemarkAdoc returns the remark section as a formatted asciidoctor blob.
func (c *Command) RemarkAdoc(lang string) string {
	var ret string
	switch lang {
	case "en":
		ret = c.remarkEn.Adoc()
	case "de":
		ret = c.remarkDe.Adoc()
	default:
		ret = ""
	}
	return ret
}

// InfoHTML returns the info section as a HTML blob
func (c *Command) InfoHTML(lang string) template.HTML {
	var r *bytes.Reader
	switch lang {
	case "en":
		if x := c.infoEn; x != nil {
			r = bytes.NewReader(x.Text)
		} else {
			return template.HTML("")
		}
	case "de":
		if x := c.infoDe; x != nil {
			r = bytes.NewReader(x.Text)
		} else {
			return template.HTML("")
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

// InfoAdoc returns the info section as a asciidoctor blob.
func (c *Command) InfoAdoc(lang string) string {
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

func descriptiontext(c *Commands, text []byte, lang string) string {
	r := bytes.NewReader(text)
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
				p.commands = c
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

// DescriptionText returns the description as text.
func (c *Command) DescriptionText(lang string) string {
	switch lang {
	case "en":
		return descriptiontext(c.commands, c.descriptionEn.Text, lang)
	case "de":
		return descriptiontext(c.commands, c.descriptionDe.Text, lang)
	default:
		return ""
	}
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

// SeealsoHTML returns the see also section as a HTML blob
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
						x = c.commands.commandsEn[attribute.Value]
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

// SeealsoAdoc returns the see also section as an asciidoctor blob
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
						x = c.commands.commandsEn[attribute.Value]
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

// Attributes returns all attributes for the command
func (c *Command) Attributes() []*Attribute {
	mutex.Lock()
	sort.Sort(attributesbyen{c.Attr})
	ret := make([]*Attribute, len(c.Attr))
	copy(ret, c.Attr)
	mutex.Unlock()
	return ret
}

// ExampleAdoc returns the examples section as an asciidoctor blob.
func (c *Command) ExampleAdoc(lang string) string {
	var r *bytes.Reader
	switch lang {
	case "en":
		if x := c.examplesEn; len(x) != 0 {
			r = bytes.NewReader(x[0].Text)
		} else {
			return ""
		}
	case "de":
		if x := c.examplesDe; len(x) != 0 {
			r = bytes.NewReader(x[0].Text)
		} else {
			return ""
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

// ExampleHTML returns the examples section as a HTML blob
func (c *Command) ExampleHTML(lang string) template.HTML {
	var r *bytes.Reader
	switch lang {
	case "en":
		if x := c.examplesEn; len(x) != 0 {
			r = bytes.NewReader(x[0].Text)
		} else {
			return template.HTML("")
		}
	case "de":
		if x := c.examplesDe; len(x) != 0 {
			r = bytes.NewReader(x[0].Text)
		} else {
			return template.HTML("")
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
				cmds = append(cmds, c.commandsEn[cmdname])
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

// Command returns a Command structure for the command named in commandname.
func (c *Commands) Command(commandname string) *Command {
	return c.commandsEn[commandname]
}

// Childelements returns a list of commands that are allowed within this command.
func (c *Command) Childelements() []*Command {
	if c == nil {
		return nil
	}
	mutex.Lock()
	x := c.children["en"]
	mutex.Unlock()
	if x != nil {
		return x
	}

	r := bytes.NewReader(c.childelement.Text)
	dec := xml.NewDecoder(r)

	cmds := getchildren(c.commands, dec)

	mutex.Lock()
	for _, v := range cmds {
		v.parentelements[c] = true
	}
	mutex.Unlock()
	sort.Sort(commandsbyen{cmds})
	mutex.Lock()
	c.children["en"] = cmds
	mutex.Unlock()
	return cmds
}

// GetDefineText returns the byte value of a define section in the commands xml
func (c *Commands) GetDefineText(section string) []byte {
	if t, ok := c.defines[section]; ok {
		return t.Text
	}
	return []byte("")
}

// Commands returns a list of all commands sorted by name.
func (c *Commands) Commands() []*Command {
	return c.commandsSortedEn
}

// Commands is the root structure of all Commands
type Commands struct {
	commandsEn       map[string]*Command
	commandsSortedEn []*Command
	defines          map[string]*define
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

// ReadCommandsFile reads from the reader. It must be in the format of a commands file.
func ReadCommandsFile(r io.Reader) (*Commands, error) {
	commands := &Commands{}
	commands.defines = make(map[string]*define)
	commands.commandsEn = make(map[string]*Command)
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
				c.children = make(map[string][]*Command)
				c.parentelements = make(map[*Command]bool)

				err = dec.DecodeElement(c, &v)
				if err != nil {
					return nil, err
				}
				commands.commandsSortedEn = append(commands.commandsSortedEn, c)

				for _, attribute := range v.Attr {
					if attribute.Name.Local == "en" {
						commands.commandsEn[attribute.Value] = c
						c.Name = attribute.Value
					}
					if attribute.Name.Local == "css" {
						c.CSS = attribute.Value
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
	sort.Sort(commandsbyen{commands.commandsSortedEn})
	// to get the full list of parent elements, the child element of each command
	// have to be called at least once. I know this sucks...
	for _, v := range commands.commandsEn {
		v.Childelements()
	}
	return commands, nil
}

// LoadCommandsFile opens the doc/commands.xml/commands.xml in the given base dir
func LoadCommandsFile(basedir string) (*Commands, error) {
	r, err := os.Open(filepath.Join(basedir, "doc", "commands-xml", "commands.xml"))
	if err != nil {
		return nil, err
	}
	defer r.Close()
	return ReadCommandsFile(r)
}
