package main

import (
	"log"
	"os"
	"sphelper/config"
	"sphelper/genluatranslations"

	"github.com/speedata/optionparser"
)

func main() {
	cfg := config.NewConfig()

	op := optionparser.NewOptionParser()
	op.On("--basedir DIR", "Base dir", &cfg.Basedir)
	op.Command("genluatranslations", "Generate Lua translations")
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
	default:
		op.Help()
		os.Exit(-1)
	}
}
