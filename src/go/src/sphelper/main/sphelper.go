package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"sphelper/config"
	"sphelper/genluatranslations"
	"sphelper/translatelayout"

	"github.com/speedata/optionparser"
)

type version struct {
	major int
	minor int
	patch int
}

func (v version) String() string {
	return fmt.Sprintf("%d.%d.%d", v.major, v.minor, v.patch)
}

var (
	basedir          string
	srcdir, builddir string
	publisherversion version
)

func readVersion(product string) version {
	buf, err := ioutil.ReadFile("version")
	if err != nil {
		panic("Cannot read version file")
	}
	ver := version{}
	for _, v := range strings.Split(string(buf), "\n") {
		if strings.HasPrefix(v, product) {
			versionString := strings.Split(v, "=")[1]
			versionStrings := strings.Split(versionString, ".")
			ver.major, err = strconv.Atoi(versionStrings[0])
			if err != nil {
				panic("Cannot parse major number in version")
			}
			ver.minor, err = strconv.Atoi(versionStrings[1])
			if err != nil {
				panic("Cannot parse minor number in version")
			}
			ver.patch, err = strconv.Atoi(versionStrings[2])
			if err != nil {
				panic("Cannot parse patch number in version")
			}
			return ver
		}
	}
	panic("Cannot find version number")
	return ver
}

func init() {
	srcdir = filepath.Join(basedir, "src")
	builddir = filepath.Join(basedir, "build")
	os.Chdir(basedir)
	publisherversion = readVersion("publisher")
	fmt.Println(publisherversion)
}

func buildGo(srcdir, destbin, goos, goarch, targettype string) bool {
	if goarch != "" {
		os.Setenv("GOARCH", goarch)
	}

	if goos != "" {
		os.Setenv("GOOS", goos)
	}

	// publisher_version = @versions['publisher_version']
	//  let's always add the sha1 to the minor versions, so we
	//  _,minor,_ = publisher_version.split(/\./)
	//  if minor.to_i() % 2 == 1 then
	// 	rev = `git rev-parse HEAD`[0,8]
	// 	publisher_version = publisher_version + "-#{rev}"
	// # end
	binaryname := "sp"
	if goos == "windows" {
		binaryname += ".exe"
	}

	// Now compile the go executable
	// cmdline = "go build -ldflags '-X main.dest #{targettype} -X main.version #{publisher_version}' -o #{destbin}/#{binaryname} sp/main"
	// sh cmdline do |ok, res|
	// 	if ! ok
	//     	puts "Go compilation failed"
	//     	return false
	//     end
	// end
	return true

}

func main() {
	cfg := config.NewConfig()

	op := optionparser.NewOptionParser()
	op.On("--basedir DIR", "Base dir", &cfg.Basedir)
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

	if cfg.Basedir != "" {
		basedir = cfg.Basedir
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
		fmt.Println("build")
		buildGo(srcdir, "#{installdir}/bin", "", "", "local")
		fmt.Println(srcdir)
	default:
		op.Help()
		os.Exit(-1)
	}
}
