package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"

	"sphelper/buildsp"
	"sphelper/config"
	"sphelper/genluatranslations"
	"sphelper/gomddoc"
	"sphelper/sourcedoc"
	"sphelper/translatelayout"

	"github.com/speedata/optionparser"
)

var (
	basedir string
)

func init() {
}

func main() {
	cfg := config.NewConfig(basedir)

	var commandlinebasedir string
	op := optionparser.NewOptionParser()
	op.On("--basedir DIR", "Base dir", &commandlinebasedir)
	op.Command("build", "Build go binary")
	op.Command("genluatranslations", "Generate Lua translations")
	op.Command("doc", "Generate speedata Publisher documentation (md only)")
	op.Command("sourcedoc", "Generate the source documentation")
	op.Command("translate", "Translate layout")
	err := op.Parse()
	if err != nil {
		log.Fatal(err)
	}

	var command string
	if len(op.Extra) > 0 {
		command = op.Extra[0]
	} else {
		op.Help()
		os.Exit(-1)
	}

	if commandlinebasedir != "" {
		cfg.SetBasedir(commandlinebasedir)
	}

	switch command {
	case "build":
		buildsp.BuildGo(cfg, filepath.Join(basedir, "bin"), "", "", "local")
	case "doc":

		curwd, err := os.Getwd()
		if err != nil {
			log.Fatal(err)
		}
		err = os.Chdir(filepath.Join(cfg.Basedir(), "doc", "manual"))
		if err != nil {
			log.Fatal(err)
		}

		root := "doc"
		basedir := "."
		dest := filepath.Join(cfg.Builddir, "manual")
		changelog := filepath.Join(cfg.Basedir(), "doc", "changelog.xml")

		d, err := gomddoc.NewMDDoc(root, dest, basedir, changelog)
		if err != nil {
			log.Fatal(err)
		}
		d.Version = cfg.Publisherversion.String()
		err = d.DoThings()
		if err != nil {
			log.Fatal(err)
		}

		os.Chdir(curwd)

	case "genluatranslations":
		err = genluatranslations.DoThings(basedir)
		if err != nil {
			log.Fatal(err)
		}
	case "sourcedoc":
		// 1 = srcpath, 2 = outpath, 3 = assets, 4 = images
		err := sourcedoc.GenSourcedoc(filepath.Join(cfg.Srcdir, "lua"), filepath.Join(cfg.Builddir, "sourcedoc"), filepath.Join(cfg.Basedir(), "doc", "sourcedoc", "assets"), filepath.Join(cfg.Basedir(), "doc", "sourcedoc", "img"))
		if err != nil {
			log.Fatal(err)
		}
	case "translate":
		if len(op.Extra) > 1 {
			if len(op.Extra) > 2 {
				err = translatelayout.Translate(basedir, op.Extra[1], op.Extra[2])
				if err != nil {
					log.Fatal(err)
				}
			} else {
				err = translatelayout.Translate(basedir, op.Extra[1], "")
				if err != nil {
					log.Fatal(err)
				}
			}
		} else {
			fmt.Println("translate needs the input and output filename: sphelper translate infile.xml [outfile.xml]")
			os.Exit(-1)
		}
	default:
		op.Help()
		os.Exit(-1)
	}
}
