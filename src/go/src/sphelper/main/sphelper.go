package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"

	"sphelper/buildsp"
	"sphelper/config"
	"sphelper/genluatranslations"
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
	op.Command("genluatranslations", "Generate Lua translations")
	op.Command("translate", "Translate layout")
	op.Command("build", "build go binary")
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
	case "genluatranslations":
		err = genluatranslations.DoThings(basedir)
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
	case "build":
		buildsp.BuildGo(cfg, filepath.Join(basedir, "bin"), "", "", "local")
	default:
		op.Help()
		os.Exit(-1)
	}
}
