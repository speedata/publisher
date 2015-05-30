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
	"regexp"
	"sort"
	"strings"
)

var (
	multipleSpace *regexp.Regexp
)

func init() {
	multipleSpace = regexp.MustCompile(`\s+`)
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
						if lang == "en" {
							cmdname = x.NameEn
						} else {
							cmdname = x.NameDe
						}
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

func (p *para) String(lang string) string {
	ret := []string{}
	c := p.commands
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
						if lang == "en" {
							cmdname = attribute.Value
						} else {
							cmdname = c.CommandsEn[attribute.Value].NameDe
						}
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
	NameEn        string `xml:"en,attr"`
	NameDe        string `xml:"de,attr"`
	DescriptionEn *description
	DescriptionDe *description
}

type Attribute struct {
	commands      *Commands
	DescriptionEn *description
	DescriptionDe *description
	Choice        []*choice
	NameEn        string
	NameDe        string
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
						c.NameEn = attribute.Value
					case "de":
						c.NameDe = attribute.Value
					}
				}
				a.Choice = append(a.Choice, c)
			}
		}
	}
	return nil
}

func (a *Attribute) Name(lang string) string {
	if lang == "en" {
		return a.NameEn
	} else {
		return a.NameDe
	}
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
			name = c.NameEn
			desc = c.DescriptionEn.HTML()
		case "de":
			name = c.NameDe
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

func (a *Attribute) HTMLFragment() string {
	return a.NameEn
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
	NameEn         string
	NameDe         string
	Css            string
	Since          string
	seealso        *seealso
}

func (c *Command) Parents(lang string) []*Command {
	var cmds []*Command
	for k, _ := range c.parentelements {
		cmds = append(cmds, k)
	}

	if lang == "en" {
		sort.Sort(commandsbyen{cmds})
	} else {
		sort.Sort(commandsbyde{cmds})
	}

	return cmds
}

func (c *Command) String() string {
	return c.NameEn
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
						a.NameEn = attribute.Value
					case "de":
						a.NameDe = attribute.Value
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

func (c *Command) Htmllink() string {
	if c == nil {
		return ""
	}
	tmp := url.URL{Path: strings.ToLower(c.NameEn)}
	filenameSansExtension := tmp.String()
	return filenameSansExtension + ".html"
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

func (c *Command) InfoHTML(lang string) template.HTML {
	var ret string
	switch lang {
	case "en":
		ret = c.InfoEn.HTML()
	case "de":
		ret = c.InfoDe.HTML()
	default:
		ret = ""
	}
	return template.HTML(ret)
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

// Return the name of the command in the given language.
func (c *Command) Name(lang string) string {
	if lang == "en" {
		return c.NameEn
	} else {
		return c.NameDe
	}
}

type reference struct {
	longnameEn string
	longnameDe string
	pagename   string
}

var (
	references map[string]reference
)

func init() {
	references = map[string]reference{
		"fonts": {
			"How to use fonts", "Einbinden von Schriftarten", "fonts.html",
		},
		"directories": {
			"How to generate a table of contents and other directories", "Wie werden Verzeichnisse erstellt?", "directories.html",
		},
		"cutmarks": {
			"Cutmarks and bleed", "Schnittmarken und Beschnittzugabe", "cutmarks.html",
		},
		"xpath": {
			"XPath expressions", "XPath-Ausdrücke", "xpath.html",
		},
		"css": {
			"Using CSS with the speedata Publisher", "CSS im speedata Publisher", "css.html",
		},
	}
}

func (c *Command) Seealso(lang string) template.HTML {
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
							fmt.Printf("There is an unknown cmd in the seealso section of %q (%q)\n", c.NameEn, attribute.Value)
							os.Exit(-1)
						}
						if lang == "en" {
							cmdname = x.NameEn
						} else {
							cmdname = x.NameDe
						}
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

func (c *Command) Attributes(lang string) []*Attribute {
	if lang == "en" {
		sort.Sort(attributesbyen{c.Attr})
	} else {
		sort.Sort(attributesbyde{c.Attr})
	}
	return c.Attr
}

func (c *Command) Example(lang string) template.HTML {
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
	if x := c.Children[lang]; x != nil {
		return x
	}

	r := bytes.NewReader(c.Childelement.Text)
	dec := xml.NewDecoder(r)

	cmds := getchildren(c.commands, dec)

	for _, v := range cmds {
		v.parentelements[c] = true
	}
	if lang == "en" {
		sort.Sort(commandsbyen{cmds})
	} else {
		sort.Sort(commandsbyde{cmds})
	}
	c.Children[lang] = cmds
	return cmds
}

type Commands struct {
	defines          map[string]*define
	CommandsEn       map[string]*Command
	CommandsDe       map[string]*Command
	CommandsSortedDe []*Command
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
type commandsbyde struct{ sortcommands }
type attributesbyen struct{ sortattributes }
type attributesbyde struct{ sortattributes }

func (s commandsbyde) Less(i, j int) bool { return s.sortcommands[i].NameDe < s.sortcommands[j].NameDe }
func (s commandsbyen) Less(i, j int) bool { return s.sortcommands[i].NameEn < s.sortcommands[j].NameEn }
func (s attributesbyde) Less(i, j int) bool {
	return s.sortattributes[i].NameDe < s.sortattributes[j].NameDe
}
func (s attributesbyen) Less(i, j int) bool {
	return s.sortattributes[i].NameEn < s.sortattributes[j].NameEn
}

func ReadCommandsFile(r io.Reader) (*Commands, error) {
	commands := &Commands{}
	commands.defines = make(map[string]*define)
	commands.CommandsDe = make(map[string]*Command)
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
				commands.CommandsSortedDe = append(commands.CommandsSortedDe, c)
				commands.CommandsSortedEn = append(commands.CommandsSortedEn, c)

				for _, attribute := range v.Attr {
					if attribute.Name.Local == "de" {
						commands.CommandsDe[attribute.Value] = c
						c.NameDe = attribute.Value
					}
					if attribute.Name.Local == "en" {
						commands.CommandsEn[attribute.Value] = c
						c.NameEn = attribute.Value
					}
					if attribute.Name.Local == "css" {
						c.Css = attribute.Value
					}
					if attribute.Name.Local == "since" {
						c.Since = attribute.Value
					}
				}
			}
		}
	}
	sort.Sort(commandsbyde{commands.CommandsSortedDe})
	sort.Sort(commandsbyen{commands.CommandsSortedEn})
	return commands, nil
}
