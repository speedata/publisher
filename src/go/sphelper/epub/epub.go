// package is for generating an EPUB file
package epub

import (
	"os"
	"path/filepath"
	"sphelper/config"
	"sphelper/newdoc"
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

func DoThings(cfg *config.Config) error {
	var err error
	// make sure we have the docbook file
	if err = newdoc.GenerateAdocFiles(cfg, "epub", "version="+cfg.Publisherversion.String()); err != nil {
		return err
	}

	r, err := os.Open(filepath.Join(cfg.Builddir, "publisherhandbuch.xml"))
	if err != nil {
		return err
	}
	outdir := filepath.Join(cfg.Builddir, "epub", "out")
	if err := os.MkdirAll(outdir, 0755); err != nil {
		return err
	}
	conf := ebpubconf{
		Author:   "Patrick Gundlach",
		Title:    "speedata Publisher: Anwendung und Referenz",
		Language: "de",
		Filename: filepath.Join(cfg.Builddir, "publisherhandbuch.epub"),
		Images:   []string{filepath.Join(cfg.Builddir, "newdoc", "newmanual", "adoc", "img"), filepath.Join(cfg.Basedir(), "doc", "epub", "img")},
		Cover:    "../images/ebook-cover-de.png",
		Fonts:    []string{filepath.Join(cfg.Basedir(), "doc", "epub", "fonts")},
		CSS:      filepath.Join(cfg.Basedir(), "doc", "epub", "style.css"),
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
