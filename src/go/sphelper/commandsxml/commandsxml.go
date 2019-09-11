package commandsxml

import (
	"encoding/xml"
	"io/ioutil"
	"path/filepath"
	"strings"
)

type ChoiceXML struct {
	Description []DescriptionXML `xml:"description"`
	Name        string           `xml:"en,attr"`
}

type NameAtt struct {
	Name string `xml:"name,attr"`
}

type CommandsxmlAttribute struct {
	Description []DescriptionXML `xml:"description"`
	Optional    string           `xml:"optional,attr"`
	Name        string           `xml:"en,attr"`
	Choice      []ChoiceXML      `xml:"choice"`
	Reference   NameAtt          `xml:"referenceattribute"`
	Type        string           `xml:"type,attr"`
	AllowXPath  string           `xml:"allowxpath,attr"`
}

type DescriptionXML struct {
	Lang string `xml:"lang,attr"`
	Para string `xml:"para"`
}

func (desc *DescriptionXML) UnmarshalXML(d *xml.Decoder, start xml.StartElement) error {
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

type ChildelementsXML struct {
	Text []byte `xml:",innerxml"`
}

type RulesXML struct {
	Lang  string `xml:"lang,attr"`
	Rules string `xml:",innerxml"`
}

type CommandsxmlCommand struct {
	Description   []DescriptionXML       `xml:"description"`
	Name          string                 `xml:"en,attr"`
	Attributes    []CommandsxmlAttribute `xml:"attribute"`
	Childelements ChildelementsXML       `xml:"childelements"`
	Rules         []RulesXML             `xml:"rules"`
}

type DefineXML struct {
	Name string `xml:"name,attr"`
	Text []byte `xml:",innerxml"`
}

type DefineAttrXML struct {
	Name    string      `xml:"name,attr"`
	Choices []ChoiceXML `xml:"choice"`
}

type CommandsXML struct {
	Defines     []DefineXML          `xml:"define"`
	DefineAttrs []DefineAttrXML      `xml:"defineattribute"`
	Commands    []CommandsxmlCommand `xml:"command"`
}

func ReadCommandsFile(basedir string) (*CommandsXML, error) {
	commandsdata, err := ioutil.ReadFile(filepath.Join(basedir, "doc", "commands-xml", "commands.xml"))
	if err != nil {
		return nil, err
	}
	c := &CommandsXML{}

	err = xml.Unmarshal(commandsdata, c)
	if err != nil {
		return nil, err
	}
	return c, err
}

func (c *ChoiceXML) GetDescription(lang string) string {
	for _, v := range c.Description {
		if v.Lang == lang {
			return v.Para
		}
	}
	return ""
}

func (c *CommandsXML) GetDefine(section string) []byte {
	for _, v := range c.Defines {
		if v.Name == section {
			return v.Text
		}
	}
	return []byte("")
}

func (c *CommandsxmlCommand) GetCommandDescription(lang string) string {
	for _, v := range c.Description {
		if v.Lang == lang {
			return v.Para
		}
	}
	return ""
}

func (c *CommandsxmlAttribute) GetDescription(lang string) string {
	for _, v := range c.Description {
		if v.Lang == lang {
			return v.Para
		}
	}
	return ""
}
