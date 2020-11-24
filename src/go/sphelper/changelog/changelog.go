// Package changelog reads a changelog.xml file
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

// Changelog is a sequence of chapters.
type Changelog struct {
	Chapter []clChapter `xml:"chapter"`
}

func parseChangelog(filename string) (*Changelog, error) {
	data, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, err
	}
	cl := &Changelog{}
	err = xml.Unmarshal(data, cl)
	if err != nil {
		return nil, err
	}
	return cl, nil
}

// ReadChangelog reads the file in basedir/doc/changelog.xml and returns the parsed file as an object.
func ReadChangelog(cfg *config.Config) (*Changelog, error) {
	cl, err := parseChangelog(filepath.Join(cfg.Basedir(), "doc", "changelog.xml"))
	return cl, err
}
