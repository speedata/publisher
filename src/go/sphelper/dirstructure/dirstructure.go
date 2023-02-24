// Package dirstructure creates the directory structure used in the distribution ZIP files.
package dirstructure

import (
	"fmt"
	"os"
	"path/filepath"

	"speedatapublisher/sphelper/config"
	"speedatapublisher/sphelper/fileutils"
)

// MkBuilddir builds the directory structure. srcbindir contains all files necessary to run LuaTeX
func MkBuilddir(cfg *config.Config, srcbindir string) error {
	var err error
	var filename string

	if cfg.IsPro {
		filename = "speedata-publisherpro"
	} else {
		filename = "speedata-publisher"

	}
	destdir := filepath.Join(cfg.Builddir, filename)
	os.RemoveAll(destdir)
	os.MkdirAll(destdir, 0755)

	srcdir := filepath.Join(cfg.Basedir(), "src")

	mapping := []struct {
		src    string
		dest   string
		reject []string
	}{
		{src: srcbindir, dest: filepath.Join(destdir, "sdluatex")},
		{src: filepath.Join(cfg.Basedir(), "lib"), dest: filepath.Join(destdir, "share", "lib"), reject: []string{".gitignore", "libsplib.h", "libsplib.dll", "libsplib.so", "libsplib.dylib", "trang.jar"}},
		{src: filepath.Join(cfg.Basedir(), "schema"), dest: filepath.Join(destdir, "share", "schema"), reject: []string{"changelog.rng", "readme.txt"}},
		{src: filepath.Join(cfg.Basedir(), "fonts"), dest: filepath.Join(destdir, "sw", "fonts")},
		{src: filepath.Join(cfg.Basedir(), "img"), dest: filepath.Join(destdir, "sw", "img")},
		{src: filepath.Join(srcdir, "tex"), dest: filepath.Join(destdir, "sw", "tex")},
		{src: filepath.Join(srcdir, "colorprofiles"), dest: filepath.Join(destdir, "sw", "colorprofiles")},
		{src: filepath.Join(srcdir, "metapost"), dest: filepath.Join(destdir, "sw", "metapost")},
		{src: filepath.Join(srcdir, "lua"), dest: filepath.Join(destdir, "sw", "lua"), reject: []string{"viznodelist.lua", "fileutils.lua", ".gitignore"}},
		{src: filepath.Join(srcdir, "hyphenation"), dest: filepath.Join(destdir, "sw", "hyphenation")},
	}

	for _, v := range mapping {
		reject := append(v.reject, ".DS_Store", ".gitignore")
		err = fileutils.CpR(v.src, v.dest, reject...)
		if err != nil {
			return err
		}
	}
	exefiles, err := filepath.Glob(filepath.Join(destdir, "bin", "*"))
	if err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}
	for _, v := range exefiles {
		os.Chmod(v, 0755)
	}
	exefiles, err = filepath.Glob(filepath.Join(destdir, "sdluatex", "*"))
	if err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}
	for _, v := range exefiles {
		os.Chmod(v, 0755)
	}
	return nil
}
