// Package commandsxml reads the commands.xml file.
package commandsxml

import (
	"bytes"
	"encoding/xml"
	"fmt"
	"io"
	"regexp"
	"sort"
	"strings"
	"sync"
)

var (
	multipleSpace *regexp.Regexp
	mutex         = &sync.Mutex{}
)

func init() {
	multipleSpace = regexp.MustCompile(`\s+`)
}

type para struct {
	commands *Commands
	Text     []byte `xml:",innerxml"`
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

// Choice represents alternative attribute values
type Choice struct {
	commands      *Commands
	Text          []byte `xml:",innerxml"`
	Name          string `xml:"en,attr"`
	Pro           bool
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
	Deprecated    bool
	Optional      bool
	AllowXPath    bool
	Pro           bool
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
					case "pro":
						c.Pro = attribute.Value == "yes"
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
	Pro            bool
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
					case "pro":
						a.Pro = attribute.Value == "yes"
					case "deprecated":
						a.Deprecated = true
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
				ret = append(ret, strings.TrimSpace(p.String(lang)))
			}
		}
	}
	return strings.Join(ret, " ")
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

// Attributes returns all attributes for the command
func (c *Command) Attributes() []*Attribute {
	mutex.Lock()
	sort.Sort(attributesbyen{c.Attr})
	ret := make([]*Attribute, len(c.Attr))
	copy(ret, c.Attr)
	mutex.Unlock()
	return ret
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
				// Skip pseudo-references like "html" that are only used for schema generation
				if def := c.defines[refname]; def != nil {
					dec = xml.NewDecoder(bytes.NewReader(def.Text))
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

// HasHTMLChildren returns true if this command allows HTML elements as children
func (c *Command) HasHTMLChildren() bool {
	if c == nil || c.childelement == nil {
		return false
	}
	return bytes.Contains(c.childelement.Text, []byte(`name="html"`))
}

// HasMathMLChildren returns true if this command allows MathML elements as children
func (c *Command) HasMathMLChildren() bool {
	if c == nil || c.childelement == nil {
		return false
	}
	return bytes.Contains(c.childelement.Text, []byte(`name="mathml"`))
}

// Commands returns a list of all commands sorted by name.
func (c *Commands) Commands() []*Command {
	return c.commandsSortedEn
}

// Commands is the root structure of all Commands
type Commands struct {
	commandsEn       map[string]*Command
	commandsSortedEn []*Command
	commandGroups    []*CommandGroup
	manualPages      map[string]*ManualPage
	defines          map[string]*define
}

// ManualPage is a page of the Hugo manual that a <ref name="..."/> in a
// seealso section can point to. Href is the path relative to the language's
// content root.
type ManualPage struct {
	Href    string
	titleEn string
	titleDe string
}

// Title returns the link text of the manual page in the given language.
func (mp *ManualPage) Title(lang string) string {
	if lang == "de" {
		return mp.titleDe
	}
	return mp.titleEn
}

// ManualPage returns the manual page for the given ref name or nil.
func (c *Commands) ManualPage(name string) *ManualPage {
	return c.manualPages[name]
}

// CommandGroup is a thematic group of commands, used for the overview page of
// the reference documentation.
type CommandGroup struct {
	nameEn   string
	nameDe   string
	Commands []*Command
}

// Name returns the title of the group in the given language.
func (cg *CommandGroup) Name(lang string) string {
	if lang == "de" {
		return cg.nameDe
	}
	return cg.nameEn
}

// CommandGroups returns the thematic command groups in document order.
func (c *Commands) CommandGroups() []*CommandGroup {
	return c.commandGroups
}

// sorting (de, en)
type (
	sortcommands   []*Command
	sortattributes []*Attribute
)

func (s sortcommands) Len() int        { return len(s) }
func (s sortcommands) Swap(i, j int)   { s[i], s[j] = s[j], s[i] }
func (s sortattributes) Len() int      { return len(s) }
func (s sortattributes) Swap(i, j int) { s[i], s[j] = s[j], s[i] }

type (
	commandsbyen   struct{ sortcommands }
	attributesbyen struct{ sortattributes }
)

func (s commandsbyen) Less(i, j int) bool { return s.sortcommands[i].Name < s.sortcommands[j].Name }
func (s attributesbyen) Less(i, j int) bool {
	return s.sortattributes[i].Name < s.sortattributes[j].Name
}

// ReadCommandsFile reads from the reader. It must be in the format of a commands file.
func ReadCommandsFile(r io.Reader) (*Commands, error) {
	type xmlCommandGroups struct {
		Groups []struct {
			En  string `xml:"en,attr"`
			De  string `xml:"de,attr"`
			Cmd []struct {
				Name string `xml:"name,attr"`
			} `xml:"cmd"`
		} `xml:"commandgroup"`
	}
	var rawgroups xmlCommandGroups

	type xmlManualPages struct {
		Pages []struct {
			Name string `xml:"name,attr"`
			Href string `xml:"href,attr"`
			En   string `xml:"en,attr"`
			De   string `xml:"de,attr"`
		} `xml:"page"`
	}
	var rawpages xmlManualPages

	commands := &Commands{}
	commands.defines = make(map[string]*define)
	commands.commandsEn = make(map[string]*Command)
	commands.manualPages = make(map[string]*ManualPage)
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
			case "commandgroups":
				err = dec.DecodeElement(&rawgroups, &v)
				if err != nil {
					return nil, err
				}
			case "manualpages":
				err = dec.DecodeElement(&rawpages, &v)
				if err != nil {
					return nil, err
				}
				for _, p := range rawpages.Pages {
					commands.manualPages[p.Name] = &ManualPage{Href: p.Href, titleEn: p.En, titleDe: p.De}
				}
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
					if attribute.Name.Local == "pro" {
						c.Pro = attribute.Value == "yes"
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
	for _, g := range rawgroups.Groups {
		group := &CommandGroup{nameEn: g.En, nameDe: g.De}
		for _, cmd := range g.Cmd {
			if c, ok := commands.commandsEn[cmd.Name]; ok {
				group.Commands = append(group.Commands, c)
			} else {
				fmt.Printf("commandgroup %q: unknown command %q\n", g.En, cmd.Name)
			}
		}
		commands.commandGroups = append(commands.commandGroups, group)
	}
	return commands, nil
}
