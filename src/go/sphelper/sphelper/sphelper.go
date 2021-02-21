// Package sphelper is the starting point for creating documentation/schema and building the binaries
package main

import (
	"fmt"
	"html/template"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	texttemplate "text/template"

	"speedatapublisher/sphelper/buildlib"
	"speedatapublisher/sphelper/buildsp"
	"speedatapublisher/sphelper/config"
	"speedatapublisher/sphelper/db2html"
	"speedatapublisher/sphelper/dirstructure"
	"speedatapublisher/sphelper/epub"
	"speedatapublisher/sphelper/fileutils"
	"speedatapublisher/sphelper/genadoc"
	"speedatapublisher/sphelper/genschema"
	"speedatapublisher/sphelper/sourcedoc"

	"github.com/speedata/optionparser"
)

var (
	basedir string
)

// sitedoc: true: needs webserver, false: standalone HTML files
func makedoc(cfg *config.Config, sitedoc bool) error {
	var err error
	err = os.RemoveAll(filepath.Join(cfg.Builddir, "manual"))
	if err != nil {
		return err
	}

	for _, lang := range []string{"en", "de"} {
		err = genadoc.DoThings(cfg, lang)
		if err != nil {
			return err
		}
		var manualfile string
		switch lang {
		case "en":
			manualfile = "publishermanual"
		case "de":
			manualfile = "publisherhandbuch"
		}
		err = db2html.DoThings(cfg, manualfile, sitedoc)
		if err != nil {
			return err
		}
	}

	// Let's try to generate an EPUB
	err = epub.GenerateEpub(cfg)
	if err != nil {
		return err
	}
	return nil
}

func main() {
	cfg := config.NewConfig(basedir)

	var commandlinebasedir string
	op := optionparser.NewOptionParser()
	op.On("--basedir DIR", "Base dir", &commandlinebasedir)
	op.Command("build", "Build go binary")
	op.Command("buildlib", "Build sp library")
	op.Command("builddeb", "Build sp binary for debian (/usr/)")
	op.Command("doc", "Generate speedata Publisher documentation (standalone)")
	op.Command("epub", "Generate EPUB documentation (German only)")
	op.Command("sitedoc", "Generate speedata Publisher documentation to be used with a web server")
	op.Command("dist", "Generate zip files and windows installers")
	op.Command("genschema", "Generate schema (layoutschema-en.xml)")
	op.Command("mkreadme", "Make readme for installation/distribution")
	op.Command("sourcedoc", "Generate the source documentation")
	op.Command("dbmanual", "Generate docbook based documentation")
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
		// build the sp executable
		err := buildsp.BuildGo(cfg, filepath.Join(basedir, "bin"), "", "", "local", "")
		if err != nil {
			os.Exit(-1)
		}
	case "buildlib":
		// build the library
		err := buildlib.BuildLib(cfg, runtime.GOOS, runtime.GOARCH)
		if err != nil {
			fmt.Println(err)
			os.Exit(-1)
		}
	case "builddeb":
		// build debian package
		if len(op.Extra) != 4 {
			fmt.Println("Need three arguments: sphelper builddeb <platform> <arch> <dest>")
			os.Exit(-1)
		}
		err := buildsp.BuildGo(cfg, filepath.Join(basedir, "bin"), op.Extra[1], op.Extra[2], "linux-usr", op.Extra[3])
		if err != nil {
			fmt.Println(err)
			os.Exit(-1)
		}
	case "doc":
		err = makedoc(cfg, false)
		if err != nil {
			log.Fatal(err)
		}
	case "epub":
		err = epub.GenerateEpub(cfg)
		if err != nil {
			log.Fatal(err)
		}
	case "sitedoc":
		err = makedoc(cfg, true)
		if err != nil {
			log.Fatal(err)
		}
	case "db2html":
		err = db2html.DoThings(cfg, "publisherhandbuch", false)
		if err != nil {
			log.Fatal(err)
		}
	case "genschema":
		err = genschema.DoThings(cfg)
		if err != nil {
			log.Fatal(err)
		}
	case "dist":
		fmt.Println("Generate ZIP files and windows installer")
		os.RemoveAll(cfg.Builddir)
		makedoc(cfg, false)
		destdir := filepath.Join(cfg.Builddir, "speedata-publisher")
		var srcbindir string
		if srcbindir = os.Getenv("LUATEX_BIN"); srcbindir == "" || !fileutils.IsDir(srcbindir) {
			fmt.Println("Error: environment variable LUATEX_BIN not set or does not point to a directory")
			os.Exit(-1)
		}
		t := texttemplate.Must(texttemplate.ParseFiles(filepath.Join(cfg.Srcdir, "other", "nsitemplate.txt")))

		for i := 1; i < len(op.Extra); i++ {
			osArch := strings.Split(op.Extra[i], "/")
			platform := osArch[0]
			arch := osArch[1]
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

				buildbindir := filepath.Join(cfg.Builddir, "speedata-publisher", "bin")
				buildsdluatexdir := filepath.Join(cfg.Builddir, "speedata-publisher", "sdluatex")
				err = buildsp.BuildGo(cfg, buildbindir, platform, arch, "directory", "")
				if err != nil {
					os.Exit(-1)
				}

				err = buildlib.BuildLib(cfg, platform, arch)
				if err != nil {
					fmt.Println(err)
					os.Exit(-1)
				}

				switch platform {
				case "windows":
					os.Rename(filepath.Join(cfg.Builddir, "dylib", "libsplib.dll"), filepath.Join(buildsdluatexdir, "libsplib.dll"))
				case "linux":
					os.Rename(filepath.Join(cfg.Builddir, "dylib", "libsplib.so"), filepath.Join(cfg.Builddir, "speedata-publisher", "share", "lib", "libsplib.so"))
				case "darwin":
					os.Rename(filepath.Join(cfg.Builddir, "dylib", "libsplib.dylib"), filepath.Join(cfg.Builddir, "speedata-publisher", "share", "lib", "libsplib.dylib"))
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
		err := sourcedoc.GenSourcedoc(cfg)
		if err != nil {
			log.Fatal(err)
		}
	default:
		op.Help()
		os.Exit(-1)
	}
}
