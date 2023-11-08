// Package config holds information about the paths and version of the speedata Publisher
package config

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

// Config is the basic configuration object
type Config struct {
	basedir                  string
	Srcdir, Builddir, Libdir string
	Publisherversion         Version
	IsPro                    bool
	SearchAPIKey             string
}

// Version holds the speedata version information
type Version struct {
	Major int
	Minor int
	Patch int
}

func (v Version) String() string {
	return fmt.Sprintf("%d.%d.%d", v.Major, v.Minor, v.Patch)
}

// SetBasedir sets the root of the speedata Publisher source files
func (cfg *Config) SetBasedir(basedir string) {
	cfg.basedir = basedir
	cfg.Srcdir = filepath.Join(basedir, "src")
	cfg.Builddir = filepath.Join(basedir, "build")
	cfg.Libdir = filepath.Join(basedir, "lib")
}

// Basedir returns the root of the speedata Publisher source files
func (cfg *Config) Basedir() string {
	return cfg.basedir
}

// NewConfig creates a new configuration struct
func NewConfig(basedir string) *Config {
	cfg := &Config{}
	cfg.SetBasedir(basedir)
	cfg.Publisherversion = readVersion("publisher", basedir)
	cfg.SearchAPIKey = os.Getenv("SP_SEARCH_API_KEY")
	return cfg
}

// Read the file `version' and parse the information
func readVersion(product string, basedir string) Version {
	curwd, err := os.Getwd()
	if err != nil {
		panic(err)
	}
	err = os.Chdir(basedir)
	if err != nil {
		panic(err)
	}
	defer os.Chdir(curwd)

	buf, err := os.ReadFile("version")
	if err != nil {
		panic("Cannot read version file")
	}
	ver := Version{}
	for _, v := range strings.Split(string(buf), "\n") {
		if strings.HasPrefix(v, product) {
			versionString := strings.Split(v, "=")[1]
			versionStrings := strings.Split(versionString, ".")
			ver.Major, err = strconv.Atoi(versionStrings[0])
			if err != nil {
				panic("Cannot parse major number in version")
			}
			ver.Minor, err = strconv.Atoi(versionStrings[1])
			if err != nil {
				panic("Cannot parse minor number in version")
			}
			ver.Patch, err = strconv.Atoi(strings.ReplaceAll(versionStrings[2], "\r", ""))
			if err != nil {
				panic("Cannot parse patch number in version")
			}
			return ver
		}
	}
	panic("Cannot find version number")
}
