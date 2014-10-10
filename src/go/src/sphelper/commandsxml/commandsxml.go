package commandsxml

import (
	"encoding/xml"
	"io/ioutil"
	"path/filepath"
)

type CommandsxmlAttribute struct {
	En     string `xml:"en,attr"`
	De     string `xml:"de,attr"`
	Choice []struct {
		En string `xml:"en,attr"`
		De string `xml:"de,attr"`
	} `xml:"choice"`
}

type CommandsxmlCommand struct {
	En         string                 `xml:"en,attr"`
	De         string                 `xml:"de,attr"`
	Attributes []CommandsxmlAttribute `xml:"attribute"`
}

type CommandsxmlValue struct {
	En      string `xml:"en,attr"`
	De      string `xml:"de,attr"`
	Key     string `xml:"key,attr"`
	Context string `xml:"context,attr"`
}

type CommandsXML struct {
	Commands     []CommandsxmlCommand `xml:"command"`
	Translations []CommandsxmlValue   `xml:"translations>values>value"`
	de           map[string]CommandsxmlCommand
	en           map[string]CommandsxmlCommand
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
	c.de = make(map[string]CommandsxmlCommand)
	c.en = make(map[string]CommandsxmlCommand)

	for _, v := range c.Commands {
		c.de[v.De] = v
		c.en[v.En] = v
	}
	return c, err
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
