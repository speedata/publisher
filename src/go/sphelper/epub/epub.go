// Package epub is for generating an EPUB file
package epub

import (
	"os"
	"path/filepath"
	"speedatapublisher/sphelper/config"
	"speedatapublisher/sphelper/genadoc"
)

type ebpubconf struct {
	Author   string
	Title    string
	Language string
	Filename string
	Cover    string
	CSS      string
	Images   []string
	Fonts    []string
	Sections [][]string
}

func generateEpubForLang(cfg *config.Config, lang string, name string) error {
	var err error
	// make sure we have the docbook file
	if err = genadoc.GenerateAdocFiles(cfg, lang, "epub", "version="+cfg.Publisherversion.String()); err != nil {
		return err
	}

	r, err := os.Open(filepath.Join(cfg.Builddir, name+".xml"))
	if err != nil {
		return err
	}
	outdir := filepath.Join(cfg.Builddir, "epub", "out")
	if err := os.MkdirAll(outdir, 0755); err != nil {
		return err
	}
	conf := ebpubconf{
		Author:   "Patrick Gundlach",
		Language: lang,
		Filename: filepath.Join(cfg.Builddir, name+".epub"),
		Images:   []string{filepath.Join(cfg.Basedir(), "doc", "dbmanual", "assets", "img"), filepath.Join(cfg.Basedir(), "doc", "epub", "img")},
		Cover:    "../images/ebook-cover-" + lang + ".png",
		Fonts:    []string{filepath.Join(cfg.Basedir(), "doc", "epub", "fonts")},
		CSS:      filepath.Join(cfg.Basedir(), "doc", "epub", "style.css"),
	}
	if lang == "de" {
		conf.Title = "speedata Publisher: Anwendung und Referenz"
	} else {
		conf.Title = "speedata Publisher: The manual"
	}
	if err := splitDocBookChapters(r, outdir, &conf); err != nil {
		return err
	}

	err = writeEpub(conf, outdir)
	if err != nil {
		return err
	}
	return nil

}

// GenerateEpub creates an epub file
func GenerateEpub(cfg *config.Config) error {
	var err error
	for _, lang := range []string{"en", "de"} {
		var manualfile string
		switch lang {
		case "en":
			manualfile = "publishermanual"
		case "de":
			manualfile = "publisherhandbuch"
		}
		err = generateEpubForLang(cfg, lang, manualfile)
		if err != nil {
			return err
		}
	}
	return nil
}
