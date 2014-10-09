package main

import (
	"fmt"
	"log"
	"os"
	"sphelper/config"
	"sphelper/genluatranslations"
	"sphelper/translatelayout"

	"github.com/speedata/optionparser"
)

func main() {
	cfg := config.NewConfig()

	op := optionparser.NewOptionParser()
	op.On("--basedir DIR", "Base dir", &cfg.Basedir)
	op.Command("genluatranslations", "Generate Lua translations")
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

	switch command {
	case "genluatranslations":
		err = genluatranslations.DoThings(cfg)
		if err != nil {
			log.Fatal(err)
		}
	case "translate":
		if len(op.Extra) > 1 {
			if len(op.Extra) > 2 {
				err = translatelayout.Translate(cfg, op.Extra[1], op.Extra[2])
				if err != nil {
					log.Fatal(err)
				}
			} else {
				err = translatelayout.Translate(cfg, op.Extra[1], "")
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
