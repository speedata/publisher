package commandsxml

import (
	"encoding/xml"
	"fmt"
	"io/ioutil"
	"path/filepath"
	"strings"
)

var (
	commandTranslationsEnDe map[string]string
)

type ChoiceXML struct {
	Description []DescriptionXML `xml:"description"`
	En          string           `xml:"en,attr"`
	De          string           `xml:"de,attr"`
}

type NameAtt struct {
	Name string `xml:"name,attr"`
}

type CommandsxmlAttribute struct {
	Description []DescriptionXML `xml:"description"`
	Optional    string           `xml:"optional,attr"`
	En          string           `xml:"en,attr"`
	De          string           `xml:"de,attr"`
	Choice      []ChoiceXML      `xml:"choice"`
	Reference   NameAtt          `xml:"referenceattribute"`
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
						switch desc.Lang {
						case "en":
							txt = append(txt, attribute.Value)
						case "de":
							txt = append(txt, commandTranslationsEnDe[attribute.Value])
						}
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
	return nil
}

type ChildelementsXML struct {
	Text []byte `xml:",innerxml"`
}

type CommandsxmlCommand struct {
	Description   []DescriptionXML       `xml:"description"`
	En            string                 `xml:"en,attr"`
	De            string                 `xml:"de,attr"`
	Attributes    []CommandsxmlAttribute `xml:"attribute"`
	Childelements ChildelementsXML       `xml:"childelements"`
}

type CommandsxmlValue struct {
	En      string `xml:"en,attr"`
	De      string `xml:"de,attr"`
	Key     string `xml:"key,attr"`
	Context string `xml:"context,attr"`
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
	Defines      []DefineXML                   `xml:"define"`
	DefineAttrs  []DefineAttrXML               `xml:"defineattribute"`
	Commands     []CommandsxmlCommand          `xml:"command"`
	Translations []CommandsxmlValue            `xml:"translations>values>value"`
	de           map[string]CommandsxmlCommand `xml:"-"`
	en           map[string]CommandsxmlCommand `xml:"-"`
}

// first run, only parse the de/en
type CommandsxmlCommandSimple struct {
	En string `xml:"en,attr"`
	De string `xml:"de,attr"`
}

type CommandsXMLSimple struct {
	Commands []CommandsxmlCommandSimple `xml:"command"`
}

func ReadCommandsFile(basedir string) (*CommandsXML, error) {
	commandsdata, err := ioutil.ReadFile(filepath.Join(basedir, "doc", "commands-xml", "commands.xml"))
	if err != nil {
		return nil, err
	}
	cs := &CommandsXMLSimple{}
	err = xml.Unmarshal(commandsdata, cs)
	if err != nil {
		return nil, err
	}

	c := &CommandsXML{}
	c.de = make(map[string]CommandsxmlCommand)
	c.en = make(map[string]CommandsxmlCommand)
	commandTranslationsEnDe = make(map[string]string)

	for _, v := range cs.Commands {
		commandTranslationsEnDe[v.En] = v.De
	}
	err = xml.Unmarshal(commandsdata, c)
	if err != nil {
		return nil, err
	}
	if false {
		fmt.Println(c.DefineAttrs)
	}
	for _, v := range c.Commands {
		c.de[v.De] = v
		c.en[v.En] = v
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

func (c *ChoiceXML) GetValue(lang string) string {
	switch lang {
	case "en":
		return c.En
	case "de":
		return c.De
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

func (c *CommandsXML) TranslateCommand(sourcelang, destlang, commandname string) string {
	if sourcelang == destlang {
		return commandname
	}
	if sourcelang == "de" && destlang == "en" {
		tmp := c.de[commandname]
		return tmp.En
	}
	if sourcelang == "en" && destlang == "de" {
		tmp := c.en[commandname]
		return tmp.De
	}
	return "xxx"
}

func (c *CommandsXML) TranslateAttribute(sourcelang, destlang, commandname, attname, attvalue string) (string, string) {
	if sourcelang == destlang {
		return attname, attvalue
	}
	// if sourcelang == "de" && destlang == "en" {
	// 	tmp := c.de[commandname]
	// 	return tmp.En
	// }
	if sourcelang == "en" && destlang == "de" {
		for _, v := range c.en[commandname].Attributes {
			if v.En == attname {
				for _, c := range v.Choice {
					if attvalue == c.En {
						return v.De, c.De
					}
				}
				return v.De, attvalue
			}
		}
		return "yyy", "yyy"
	}
	return "xxx", "xxx"
}
