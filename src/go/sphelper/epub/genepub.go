package epub

import (
	"io/ioutil"
	"path/filepath"
	"strings"

	"github.com/speedata/go-epub"
)

func isImage(fn string) bool {
	return strings.HasSuffix(fn, ".png") || strings.HasSuffix(fn, ".svg") || strings.HasSuffix(fn, ".jpg")
}

func isFont(fn string) bool {
	return strings.HasSuffix(fn, ".woff") || strings.HasSuffix(fn, ".woff2") || strings.HasSuffix(fn, ".otf") || strings.HasSuffix(fn, ".otf")
}

func writeEpub(conf ebpubconf, outdir string) error {
	var err error
	ep := epub.NewEpub(conf.Title)
	ep.SetAuthor(conf.Author)
	ep.SetCover(conf.Cover, "")
	ep.SetLang(conf.Language)

	for _, fntdir := range conf.Fonts {
		fonts, err := filepath.Glob(filepath.Join(fntdir, "*"))
		if err != nil {
			return err
		}

		for _, img := range fonts {
			if isFont(img) {
				_, err := ep.AddFont(img, strings.TrimPrefix(img, fntdir+"/"))
				if err != nil {
					return err
				}
			}
		}
	}

	var cssfilename string
	if cssfilename, err = ep.AddCSS(conf.CSS, ""); err != nil {
		return err
	}

	for _, sec := range conf.Sections {
		filename := sec[0]
		destfilename := filename
		// destfilename := strings.TrimPrefix(filename, "out/")
		b, err := ioutil.ReadFile(filepath.Join(outdir, filename))
		if err != nil {
			return err
		}
		title := sec[1]
		children := sec[2:]
		for {
			if len(children) > 1 {
				children[1] = "xhtml/" + destfilename + "#" + children[1]
				children = children[2:]
			} else {
				break
			}
		}

		_, err = ep.AddSection(string(b), title, destfilename, cssfilename, sec[2:]...)
		if err != nil {
			return err
		}
	}
	for _, imgdir := range conf.Images {
		imgs, err := filepath.Glob(filepath.Join(imgdir, "*"))
		if err != nil {
			return err
		}

		for _, img := range imgs {
			if isImage(img) {
				_, err := ep.AddImage(img, strings.TrimPrefix(img, imgdir+"/"))
				if err != nil {
					return err
				}
				// fmt.Println("resulting filename", fn)
			}
		}
	}
	return ep.Write(conf.Filename)
}
