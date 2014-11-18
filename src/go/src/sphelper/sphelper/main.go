package main

import (
	"fmt"
	"html/template"
	"log"
	"os"
	"path/filepath"

	"sphelper/buildsp"
	"sphelper/config"
	"sphelper/genluatranslations"
	"sphelper/genschema"
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
	op.Command("doc", "Generate speedata Publisher documentation (md only)")
	op.Command("mkreadme", "Make readme for installation/distribution")
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
	case "genschema":
		err = genluatranslations.DoThings(basedir)
		if err != nil {
			log.Fatal(err)
		}
		err = genschema.DoThings(basedir)
		if err != nil {
			log.Fatal(err)
		}
	case "mkreadme":
		if len(op.Extra) < 3 {
			fmt.Println("Not enough arguments, use `mkreadme <os> <destdir>'.")
			fmt.Println("Where <os> is one of 'linux', 'darwin' or 'windows'.")
			os.Exit(-1)
		}
		t := template.Must(template.ParseFiles("doc/installation.txt"))
		data := struct {
			Os string
		}{
			op.Extra[1],
		}

		w, err := os.OpenFile(filepath.Join(op.Extra[2], "installation.txt"), os.O_WRONLY|os.O_TRUNC|os.O_CREATE, 0644)
		if err != nil {
			fmt.Println(err)
			os.Exit(-1)
		}

		err = t.Execute(w, data)
		if err != nil {
			fmt.Println(err)
			os.Exit(-1)
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
