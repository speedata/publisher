package main

import (
	"fmt"
	"html/template"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"sphelper/fileutils"
	"strings"
	texttemplate "text/template"

	"sphelper/buildsp"
	"sphelper/config"
	"sphelper/dashdoc"
	"sphelper/dirstructure"
	"sphelper/genluatranslations"
	"sphelper/genschema"
	"sphelper/gomddoc"
	"sphelper/htmldoc"
	"sphelper/sourcedoc"
	"sphelper/translatelayout"

	"github.com/speedata/optionparser"
)

var (
	basedir string
)

func init() {
}

func makedoc(cfg *config.Config) error {
	os.RemoveAll(filepath.Join(cfg.Builddir, "manual"))
	err := gomddoc.DoThings(cfg)
	if err != nil {
		return err
	}
	return htmldoc.DoThings(cfg)
}

func main() {
	cfg := config.NewConfig(basedir)

	var commandlinebasedir string
	op := optionparser.NewOptionParser()
	op.On("--basedir DIR", "Base dir", &commandlinebasedir)
	op.Command("build", "Build go binary")
	op.Command("dashdoc", "Generate speedata Publisher documentation (for dash)")
	op.Command("doc", "Generate speedata Publisher documentation")
	op.Command("dist", "Generate zip files and windows installers")
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
		err := buildsp.BuildGo(cfg, filepath.Join(basedir, "bin"), "", "", "local")
		if err != nil {
			os.Exit(-1)
		}
	case "doc":
		os.RemoveAll(cfg.Builddir)
		err = makedoc(cfg)
		if err != nil {
			log.Fatal(err)
		}
	case "dashdoc":
		err = dashdoc.DoThings(cfg)
		if err != nil {
			log.Fatal(err)
		}
	case "genschema":
		err = genluatranslations.DoThings(basedir)
		if err != nil {
			log.Fatal(err)
		}
		err = genschema.DoThings(basedir)
		if err != nil {
			log.Fatal(err)
		}
	case "dist":
		fmt.Println("Generate ZIP files and windows installer")
		makedoc(cfg)
		destdir := filepath.Join(cfg.Builddir, "speedata-publisher")
		var srcbindir string
		if srcbindir = os.Getenv("LUATEX_BIN"); srcbindir == "" || !fileutils.IsDir(srcbindir) {
			fmt.Println("Error: environment variable LUATEX_BIN not set or does not point to a directory")
			os.Exit(-1)
		}
		t := texttemplate.Must(texttemplate.ParseFiles(filepath.Join(cfg.Srcdir, "other", "nsitemplate.txt")))

		for i := 1; i < len(op.Extra); i++ {
			os_arch := strings.Split(op.Extra[i], "/")
			platform := os_arch[0]
			arch := os_arch[1]
			fmt.Println(platform, arch)
			d := filepath.Join(srcbindir, platform, arch, "default")
			if !fileutils.IsDir(d) {
				fmt.Println("Does not exist:", d, "... skipping")
			} else {
				bindir, err := filepath.EvalSymlinks(d)
				if err != nil {
					log.Fatal(err)
				}
				err = dirstructure.MkBuilddir(cfg, bindir)
				if err != nil {
					log.Fatal(err)
				}
				err = buildsp.BuildGo(cfg, filepath.Join(cfg.Builddir, "speedata-publisher", "bin"), platform, arch, "directory")
				if err != nil {
					os.Exit(-1)
				}

				os.Chdir(cfg.Builddir)
				zipname := fmt.Sprintf("speedata-publisher-%s-%s-%s.zip", platform, arch, cfg.Publisherversion)
				os.Remove(zipname)
				exec.Command("zip", "-rq", zipname, "speedata-publisher").Run()

				if platform == "windows" {
					exename := fmt.Sprintf("speedata-publisher-%s-%s-%s-installer.exe", platform, arch, cfg.Publisherversion)
					os.Remove(exename)
					data := struct {
						Exename   string
						Sourcedir string
						Arch      string
					}{
						Exename:   exename,
						Sourcedir: destdir,
						Arch:      arch,
					}
					f, err := os.Create("installer.nsi")
					if err != nil {
						log.Fatal(err)
					}
					t.Execute(f, data)
					out, err := exec.Command("makensis", "installer.nsi").Output()
					if err != nil {
						fmt.Println(string(out))
						log.Fatal(err)
					}
					f.Close()
				}
			}
		}
		if false {

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
