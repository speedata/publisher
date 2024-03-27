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
	"speedatapublisher/sphelper/distcustom"
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
	cfg.IsPro = os.Getenv("SDPRO") == "yes"

	var commandlinebasedir string
	op := optionparser.NewOptionParser()
	op.On("--basedir DIR", "Base dir", &commandlinebasedir)
	op.Command("build", "Build go binary")
	op.Command("builddeb", "Build sp binary for debian (/usr/)")
	op.Command("buildlib", "Build sp library")
	op.Command("dbmanual", "Generate docbook based documentation")
	op.Command("dist", "Generate zip files and windows installers")
	op.Command("distcustom", "Generate custom directory structure for distribution")
	op.Command("doc", "Generate speedata Publisher documentation (standalone)")
	op.Command("epub", "Generate EPUB documentation")
	op.Command("genschema", "Generate schema (layoutschema-en.xml)")
	op.Command("mkreadme", "Make readme for installation/distribution")
	op.Command("sitedoc", "Generate speedata Publisher documentation to be used with a web server")
	op.Command("sourcedoc", "Generate the source documentation")
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
		err := buildsp.BuildGo(cfg, filepath.Join(basedir, "bin"), "", "", "local", "", "")
		if err != nil {
			os.Exit(-1)
		}
	case "buildlib":
		// build the library
		goos, goarch := runtime.GOOS, runtime.GOARCH
		err := buildlib.BuildLib(cfg, goos, goarch)
		if err != nil {
			fmt.Println(err)
			os.Exit(-1)
		}
		err = buildlib.BuildCLib(cfg, goos, goarch)
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
		err := buildsp.BuildGo(cfg, filepath.Join(basedir, "bin"), op.Extra[1], op.Extra[2], "linux-usr", op.Extra[3], "")
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
	case "genschema":
		err = genschema.DoThings(cfg)
		if err != nil {
			log.Fatal(err)
		}
	case "dist":
		fmt.Println("Generate ZIP files and windows installer")
		os.RemoveAll(cfg.Builddir)
		var filename string
		if cfg.IsPro {
			filename = "speedata-publisherpro"
		} else {
			filename = "speedata-publisher"
		}

		destdir := filepath.Join(cfg.Builddir, filename)
		bindestdir := filepath.Join(destdir, "bin")
		sharedestdir := filepath.Join(destdir, "share")
		swdestdir := filepath.Join(destdir, "sw")
		libdestdir := filepath.Join(sharedestdir, "lib")
		dylibbuild := filepath.Join(cfg.Builddir, "dylib")

		var srcbindir string
		if srcbindir = os.Getenv("LUATEX_BIN"); srcbindir == "" || !fileutils.IsDir(srcbindir) {
			fmt.Println("Error: environment variable LUATEX_BIN not set or does not point to a directory")
			os.Exit(-1)
		}

		var t *texttemplate.Template
		if runtime.GOOS == "windows" {
			t = texttemplate.Must(texttemplate.ParseFiles(filepath.Join(cfg.Srcdir, "other", "nsitemplate_win.txt")))
		} else {
			t = texttemplate.Must(texttemplate.ParseFiles(filepath.Join(cfg.Srcdir, "other", "nsitemplate.txt")))
		}

		for i := 1; i < len(op.Extra); i++ {
			osArch := strings.Split(op.Extra[i], "/")
			platform := osArch[0]
			arch := osArch[1]
			fmt.Println(platform, arch)
			luatexdir, err := dirstructure.GetLuaTeXDir(platform, arch)
			if err != nil {
				log.Fatal(err)
			}

			os.RemoveAll(destdir)
			os.MkdirAll(destdir, 0755)
			os.RemoveAll(dylibbuild)
			os.MkdirAll(dylibbuild, 0755)

			err = dirstructure.FillBuildDir(cfg, luatexdir, bindestdir, sharedestdir, swdestdir)
			if err != nil {
				log.Fatal(err)
			}

			err = buildsp.BuildGo(cfg, bindestdir, platform, arch, "directory", "", "")
			if err != nil {
				os.Exit(-1)
			}

			err = buildlib.BuildLib(cfg, platform, arch)
			if err != nil {
				fmt.Println(err)
				os.Exit(-1)
			}
			err = buildlib.BuildCLib(cfg, platform, arch)
			if err != nil {
				fmt.Println(err)
				os.Exit(-1)
			}

			switch platform {
			case "windows":
				os.Rename(filepath.Join(cfg.Builddir, "dylib", "libsplib.dll"), filepath.Join(bindestdir, "libsplib.dll"))
				os.Rename(filepath.Join(cfg.Builddir, "dylib", "luaglue.dll"), filepath.Join(libdestdir, "luaglue.dll"))
			case "linux":
				os.Rename(filepath.Join(cfg.Builddir, "dylib", "libsplib.so"), filepath.Join(libdestdir, "libsplib.so"))
				os.Rename(filepath.Join(cfg.Builddir, "dylib", "luaglue.so"), filepath.Join(libdestdir, "luaglue.so"))
			case "darwin":
				os.Rename(filepath.Join(cfg.Builddir, "dylib", "libsplib.so"), filepath.Join(libdestdir, "libsplib.so"))
				os.Rename(filepath.Join(cfg.Builddir, "dylib", "luaglue.so"), filepath.Join(libdestdir, "luaglue.so"))
			}

			os.Chdir(cfg.Builddir)
			mkreadme(cfg, platform, destdir)
			zipname := fmt.Sprintf("%s-%s-%s-%s.zip", filename, platform, arch, cfg.Publisherversion)
			os.Remove(zipname)
			exec.Command("zip", "-rq", zipname, filename).Run()

			if platform == "windows" {
				exename := fmt.Sprintf("%s-%s-%s-%s-installer.exe", filename, platform, arch, cfg.Publisherversion)
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
	case "distcustom":
		err = distcustom.CreateCustomBuild(cfg, op.Extra[1:])
		if err != nil {
			log.Fatal(err)
		}
	case "mkreadme":
		if len(op.Extra) < 3 {
			fmt.Println("Not enough arguments, use `mkreadme <os> <destdir>'.")
			fmt.Println("Where <os> is one of 'linux', 'darwin' or 'windows'.")
			os.Exit(-1)
		}
		if err := mkreadme(cfg, op.Extra[1], op.Extra[2]); err != nil {
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

func mkreadme(cfg *config.Config, osname string, destdir string) error {
	w, err := os.Create(filepath.Join(destdir, "installation.txt"))
	if err != nil {
		return err
	}
	defer w.Close()
	t := template.Must(template.ParseFiles(filepath.Join(cfg.Basedir(), "doc", "installation.txt")))
	data := struct {
		Os      string
		Version string
	}{
		Os: osname,
	}
	if cfg.IsPro {
		data.Version = fmt.Sprintf("%s (Pro)", cfg.Publisherversion)
	} else {
		data.Version = cfg.Publisherversion.String()
	}
	if err = t.Execute(w, data); err != nil {
		return err
	}
	return nil
}
