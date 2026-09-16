package genschema

import (
	"encoding/xml"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

type choiceXML struct {
	Description []descriptionXML `xml:"description"`
	Name        string           `xml:"en,attr"`
}

type nameAtt struct {
	Name string `xml:"name,attr"`
}

type commandsxmlAttribute struct {
	Description []descriptionXML `xml:"description"`
	Optional    string           `xml:"optional,attr"`
	Name        string           `xml:"en,attr"`
	Choice      []choiceXML      `xml:"choice"`
	Reference   nameAtt          `xml:"referenceattribute"`
	Type        string           `xml:"type,attr"`
	AllowXPath  string           `xml:"allowxpath,attr"`
}

type descriptionXML struct {
	Lang string `xml:"lang,attr"`
	Para string `xml:"para"`
}

func (desc *descriptionXML) UnmarshalXML(d *xml.Decoder, start xml.StartElement) error {
	txt := []string{}
	for _, v := range start.Attr {
		if v.Name.Local == "lang" {
			desc.Lang = v.Value
		}
	}
	for {
		tok, err := d.Token()
		if err != nil {
			return err
		}
		switch v := tok.(type) {
		case xml.StartElement:
			if v.Name.Local == "cmd" {
				for _, attribute := range v.Attr {
					if attribute.Name.Local == "name" {
						txt = append(txt, attribute.Value)
					}
				}
			}
		case xml.EndElement:
			if v.Name.Local == "description" {
				desc.Para = strings.TrimSpace(strings.Join(txt, ""))
				return nil
			}
		case xml.CharData:
			txt = append(txt, string(v.Copy()))
		}
	}
}

type childelementsXML struct {
	Text []byte `xml:",innerxml"`
}

type rulesXML struct {
	Lang  string `xml:"lang,attr"`
	Rules string `xml:",innerxml"`
}

type commandsxmlCommand struct {
	Description   []descriptionXML       `xml:"description"`
	Name          string                 `xml:"en,attr"`
	Attributes    []commandsxmlAttribute `xml:"attribute"`
	Childelements childelementsXML       `xml:"childelements"`
	Rules         []rulesXML             `xml:"rules"`
}

type defineXML struct {
	Name string `xml:"name,attr"`
	Text []byte `xml:",innerxml"`
}

type defineAttrXML struct {
	Name    string      `xml:"name,attr"`
	Choices []choiceXML `xml:"choice"`
}

type defineListXML struct {
	Name string `xml:"name,attr"`
	Text []byte `xml:",innerxml"`
}

// lspSymbolXML is a defines or references rule from the lspannotations
// section. Command and Attribute hold space separated name lists; an empty
// Command means the rule applies to every command.
type lspSymbolXML struct {
	Command   string `xml:"command,attr"`
	Attribute string `xml:"attribute,attr"`
	Symbol    string `xml:"symbol,attr"`
	Form      string `xml:"form,attr"`
}

type lspFormatXML struct {
	Command    string `xml:"command,attr"`
	Preserve   string `xml:"preserve,attr"`
	BlankLines string `xml:"blank-lines,attr"`
	Inline     string `xml:"inline,attr"`
}

// lspBuiltinXML lists names of a symbol that exist without being defined in
// the layout, such as the predefined text format "text".
type lspBuiltinXML struct {
	Symbol string `xml:"symbol,attr"`
	Names  string `xml:"names,attr"`
}

// lspDocSymbolXML turns a command into a document symbol (outline entry).
// Label and Detail are templates in which {@attr} is replaced by the value
// of that attribute.
type lspDocSymbolXML struct {
	Command string `xml:"command,attr"`
	Kind    string `xml:"kind,attr"`
	Label   string `xml:"label,attr"`
	Detail  string `xml:"detail,attr"`
}

// lspExclusiveXML states that the listed attributes and (with Content set to
// yes) the element content are mutually exclusive.
type lspExclusiveXML struct {
	Command    string `xml:"command,attr"`
	Attributes string `xml:"attributes,attr"`
	Content    string `xml:"content,attr"`
}

// lspWhenXML is a conditional attribute rule: when Attribute has one of the
// values in Value (or is absent, if Value is empty), the attributes in
// Requires must be present and the attributes in Forbids must not.
type lspWhenXML struct {
	Command   string `xml:"command,attr"`
	Attribute string `xml:"attribute,attr"`
	Value     string `xml:"value,attr"`
	Requires  string `xml:"requires,attr"`
	Forbids   string `xml:"forbids,attr"`
}

// lspNamespaceXML is a namespace prefix the editor should offer for xmlns
// completion. The URI is the same in both schema languages.
type lspNamespaceXML struct {
	Prefix string `xml:"prefix,attr"`
	URI    string `xml:"uri,attr"`
}

type lspAnnotationsXML struct {
	Defines    []lspSymbolXML    `xml:"defines"`
	References []lspSymbolXML    `xml:"references"`
	Builtins   []lspBuiltinXML   `xml:"builtin"`
	Formats    []lspFormatXML    `xml:"format"`
	Symbols    []lspDocSymbolXML `xml:"symbol"`
	Exclusives []lspExclusiveXML `xml:"exclusive"`
	Whens      []lspWhenXML      `xml:"when"`
	Namespaces []lspNamespaceXML `xml:"namespace"`
}

type commandsXML struct {
	Defines        []defineXML          `xml:"define"`
	DefineAttrs    []defineAttrXML      `xml:"defineattribute"`
	DefineList     []defineListXML      `xml:"definelist"`
	LspAnnotations lspAnnotationsXML    `xml:"lspannotations"`
	Commands       []commandsxmlCommand `xml:"command"`
}

func readCommandsFile(basedir string) (*commandsXML, error) {
	commandsdata, err := os.ReadFile(filepath.Join(basedir, "doc", "commands-xml", "commands.xml"))
	if err != nil {
		return nil, err
	}
	c := &commandsXML{}

	err = xml.Unmarshal(commandsdata, c)
	if err != nil {
		return nil, err
	}
	return c, err
}

func (c *choiceXML) GetDescription(lang string) string {
	for _, v := range c.Description {
		if v.Lang == lang {
			return v.Para
		}
	}
	return ""
}

func (c *commandsXML) getDefine(section string) []byte {
	for _, v := range c.Defines {
		if v.Name == section {
			return v.Text
		}
	}
	return []byte("")
}

func (c *commandsxmlCommand) getCommandDescription(lang string) string {
	for _, v := range c.Description {
		if v.Lang == lang {
			return v.Para
		}
	}
	return ""
}

func containsField(list string, name string) bool {
	for _, f := range strings.Fields(list) {
		if f == name {
			return true
		}
	}
	return false
}

func (r *lspSymbolXML) matches(cmdname, attname string, specific bool) bool {
	if specific != (r.Command != "") {
		return false
	}
	if r.Command != "" && !containsField(r.Command, cmdname) {
		return false
	}
	return containsField(r.Attribute, attname)
}

// lspSymbolAnnotation returns the annotation ("defines" or "references") for
// an attribute of a command, along with its symbol kind and optional form.
// Rules naming a command win over generic rules, so for example Mark/select
// keeps its defines annotation while select on all other commands is a
// variable reference. An empty kind means no annotation applies.
func (c *commandsXML) lspSymbolAnnotation(cmdname, attname string) (kind, symbol, form string) {
	for _, specific := range []bool{true, false} {
		for _, r := range c.LspAnnotations.Defines {
			if r.matches(cmdname, attname, specific) {
				return "defines", r.Symbol, r.Form
			}
		}
		for _, r := range c.LspAnnotations.References {
			if r.matches(cmdname, attname, specific) {
				return "references", r.Symbol, r.Form
			}
		}
	}
	return "", "", ""
}

// hasAttribute reports whether the command declares the attribute.
func (c *commandsxmlCommand) hasAttribute(name string) bool {
	for _, a := range c.Attributes {
		if a.Name == name {
			return true
		}
	}
	return false
}

// warnUnmatchedLspRules reports lspannotations rules that name a command or
// an attribute that does not exist. Such a rule is almost always a typo and
// would otherwise silently produce no annotation.
func warnUnmatchedLspRules(c *commandsXML) {
	byName := map[string]*commandsxmlCommand{}
	for i := range c.Commands {
		byName[c.Commands[i].Name] = &c.Commands[i]
	}
	warn := func(format string, args ...any) {
		fmt.Fprintf(os.Stderr, "genschema: "+format+"\n", args...)
	}
	// checkCommands warns about unknown commands in the space separated list
	// and returns the known ones.
	checkCommands := func(rule, list string) []*commandsxmlCommand {
		var ret []*commandsxmlCommand
		for _, name := range strings.Fields(list) {
			cmd, ok := byName[name]
			if !ok {
				warn("lsp %s rule names unknown command %q", rule, name)
				continue
			}
			ret = append(ret, cmd)
		}
		return ret
	}
	// checkAttributes warns when an attribute in list is missing on every
	// command in cmds. Generic rules (empty command list) are checked against
	// all commands.
	checkAttributes := func(rule string, cmds []*commandsxmlCommand, list string) {
		if cmds == nil {
			for i := range c.Commands {
				cmds = append(cmds, &c.Commands[i])
			}
		}
		for _, attr := range strings.Fields(list) {
			found := false
			for _, cmd := range cmds {
				if cmd.hasAttribute(attr) {
					found = true
					break
				}
			}
			if !found {
				warn("lsp %s rule: attribute %q matches nothing", rule, attr)
			}
		}
	}
	symbolRule := func(kind string, rules []lspSymbolXML) {
		for _, r := range rules {
			var cmds []*commandsxmlCommand
			if r.Command != "" {
				cmds = checkCommands(kind, r.Command)
			}
			checkAttributes(kind, cmds, r.Attribute)
		}
	}
	symbolRule("defines", c.LspAnnotations.Defines)
	symbolRule("references", c.LspAnnotations.References)
	for _, r := range c.LspAnnotations.Formats {
		checkCommands("format", r.Command)
	}
	for _, r := range c.LspAnnotations.Symbols {
		checkCommands("symbol", r.Command)
	}
	for _, r := range c.LspAnnotations.Exclusives {
		cmds := checkCommands("exclusive", r.Command)
		checkAttributes("exclusive", cmds, r.Attributes)
	}
	for _, r := range c.LspAnnotations.Whens {
		cmds := checkCommands("when", r.Command)
		checkAttributes("when", cmds, r.Attribute)
		checkAttributes("when", cmds, r.Requires)
		checkAttributes("when", cmds, r.Forbids)
	}
}

// lspFormatAnnotation returns the format rule for a command or nil.
func (c *commandsXML) lspFormatAnnotation(cmdname string) *lspFormatXML {
	for i, r := range c.LspAnnotations.Formats {
		if containsField(r.Command, cmdname) {
			return &c.LspAnnotations.Formats[i]
		}
	}
	return nil
}

// lspDocSymbolAnnotation returns the document symbol rule for a command or
// nil.
func (c *commandsXML) lspDocSymbolAnnotation(cmdname string) *lspDocSymbolXML {
	for i, r := range c.LspAnnotations.Symbols {
		if containsField(r.Command, cmdname) {
			return &c.LspAnnotations.Symbols[i]
		}
	}
	return nil
}

// lspExclusiveAnnotations returns all exclusive rules for a command.
func (c *commandsXML) lspExclusiveAnnotations(cmdname string) []*lspExclusiveXML {
	var ret []*lspExclusiveXML
	for i, r := range c.LspAnnotations.Exclusives {
		if containsField(r.Command, cmdname) {
			ret = append(ret, &c.LspAnnotations.Exclusives[i])
		}
	}
	return ret
}

// lspWhenAnnotations returns all conditional attribute rules for a command.
func (c *commandsXML) lspWhenAnnotations(cmdname string) []*lspWhenXML {
	var ret []*lspWhenXML
	for i, r := range c.LspAnnotations.Whens {
		if containsField(r.Command, cmdname) {
			ret = append(ret, &c.LspAnnotations.Whens[i])
		}
	}
	return ret
}

// lspDocURL returns the URL of the reference page of the command in the
// online manual for the given schema language.
func lspDocURL(cmdname, lang string) string {
	base := "https://doc.speedata.de/publisher/en/commandreference/"
	if lang == "de" {
		base = "https://doc.speedata.de/publisher/de/befehlsreferenz/"
	}
	return base + strings.ToLower(cmdname) + "/"
}

func (c *commandsxmlAttribute) GetDescription(lang string) string {
	for _, v := range c.Description {
		if v.Lang == lang {
			return v.Para
		}
	}
	return ""
}
