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

type lspAnnotationsXML struct {
	Defines    []lspSymbolXML `xml:"defines"`
	References []lspSymbolXML `xml:"references"`
	Formats    []lspFormatXML `xml:"format"`
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

// warnUnmatchedLspRules reports lspannotations rules that do not match any
// command/attribute combination, which usually indicates a typo.
func warnUnmatchedLspRules(c *commandsXML) {
	symbolRuleMatches := func(r *lspSymbolXML) bool {
		for _, cmd := range c.Commands {
			for _, attr := range cmd.Attributes {
				if r.matches(cmd.Name, attr.Name, r.Command != "") {
					return true
				}
			}
		}
		return false
	}
	for i := range c.LspAnnotations.Defines {
		if r := &c.LspAnnotations.Defines[i]; !symbolRuleMatches(r) {
			fmt.Fprintf(os.Stderr, "genschema: lsp defines rule (command %q, attribute %q) matches nothing\n", r.Command, r.Attribute)
		}
	}
	for i := range c.LspAnnotations.References {
		if r := &c.LspAnnotations.References[i]; !symbolRuleMatches(r) {
			fmt.Fprintf(os.Stderr, "genschema: lsp references rule (command %q, attribute %q) matches nothing\n", r.Command, r.Attribute)
		}
	}
	for _, f := range c.LspAnnotations.Formats {
		found := false
		for _, cmd := range c.Commands {
			if containsField(f.Command, cmd.Name) {
				found = true
				break
			}
		}
		if !found {
			fmt.Fprintf(os.Stderr, "genschema: lsp format rule for unknown command %q\n", f.Command)
		}
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

func (c *commandsxmlAttribute) GetDescription(lang string) string {
	for _, v := range c.Description {
		if v.Lang == lang {
			return v.Para
		}
	}
	return ""
}
