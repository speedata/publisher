package config

import (
	"fmt"
	"io/ioutil"
	"path/filepath"
	"strconv"
	"strings"
)

type Config struct {
	basedir          string
	Srcdir, Builddir string
	Publisherversion Version
}

type Version struct {
	Major int
	Minor int
	Patch int
}

func (v Version) String() string {
	return fmt.Sprintf("%d.%d.%d", v.Major, v.Minor, v.Patch)
}

func (cfg *Config) SetBasedir(basedir string) {
	cfg.basedir = basedir
	cfg.Srcdir = filepath.Join(basedir, "src")
	cfg.Builddir = filepath.Join(basedir, "build")
}

func (cfg *Config) Basedir() string {
	return cfg.basedir
}

func NewConfig(basedir string) *Config {
	cfg := &Config{}
	cfg.SetBasedir(basedir)
	cfg.Publisherversion = readVersion("publisher")
	return cfg
}

func readVersion(product string) Version {
	buf, err := ioutil.ReadFile("version")
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
			ver.Patch, err = strconv.Atoi(versionStrings[2])
			if err != nil {
				panic("Cannot parse patch number in version")
			}
			return ver
		}
	}
	panic("Cannot find version number")
	return ver
}
