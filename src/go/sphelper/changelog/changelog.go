package changelog

import (
	"encoding/xml"
	"io/ioutil"
	"path/filepath"
	"sphelper/config"
)

type clText struct {
	Text string `xml:",innerxml"`
}

type clEntry struct {
	Version string `xml:"version,attr"`
	Date    string `xml:"date,attr"`
	En      clText `xml:"en"`
	De      clText `xml:"de"`
}

type clChapter struct {
	Version string    `xml:"version,attr"`
	Date    string    `xml:"date,attr"`
	Entries []clEntry `xml:"entry"`
}

type changelog struct {
	Chapter []clChapter `xml:"chapter"`
}

func parseChangelog(filename string) (*changelog, error) {
	data, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, err
	}
	cl := &changelog{}
	err = xml.Unmarshal(data, cl)
	if err != nil {
		return nil, err
	}
	return cl, nil
}

func ReadChangelog(cfg *config.Config) (*changelog, error) {
	cl, err := parseChangelog(filepath.Join(cfg.Basedir(), "doc", "changelog.xml"))
	return cl, err
}
