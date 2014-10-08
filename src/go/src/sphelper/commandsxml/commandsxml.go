package commandsxml

import (
	"encoding/xml"
	"io/ioutil"
	"path/filepath"

	"sphelper/config"
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
}

func ReadCommandsFile(cfg *config.Config) (*CommandsXML, error) {
	commandsdata, err := ioutil.ReadFile(filepath.Join(cfg.Basedir, "doc", "commands-xml", "commands.xml"))
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
