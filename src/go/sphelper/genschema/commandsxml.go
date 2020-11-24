package genschema

import (
	"encoding/xml"
	"io/ioutil"
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

type commandsXML struct {
	Defines     []defineXML          `xml:"define"`
	DefineAttrs []defineAttrXML      `xml:"defineattribute"`
	DefineList  []defineListXML      `xml:"definelist"`
	Commands    []commandsxmlCommand `xml:"command"`
}

func readCommandsFile(basedir string) (*commandsXML, error) {
	commandsdata, err := ioutil.ReadFile(filepath.Join(basedir, "doc", "commands-xml", "commands.xml"))
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

func (c *commandsxmlAttribute) GetDescription(lang string) string {
	for _, v := range c.Description {
		if v.Lang == lang {
			return v.Para
		}
	}
	return ""
}
