package dirstructure

import (
	"fmt"
	"os"
	"path/filepath"

	"sphelper/config"
	"sphelper/fileutils"
)

// build dir contains the documentation
func MkBuilddir(cfg *config.Config, srcbindir string) error {
	var err error

	destdir := filepath.Join(cfg.Builddir, "speedata-publisher")
	os.RemoveAll(destdir)
	os.MkdirAll(destdir, 0755)

	srcdir := filepath.Join(cfg.Basedir(), "src")

	mapping := []struct {
		src    string
		dest   string
		reject []string
	}{
		{src: srcbindir, dest: filepath.Join(destdir, "sdluatex")},
		{src: filepath.Join(cfg.Builddir, "manual"), dest: filepath.Join(destdir, "share", "doc")},
		{src: filepath.Join(cfg.Basedir(), "lib"), dest: filepath.Join(destdir, "share", "lib"), reject: []string{".gitignore", "libsplib.h", "libsplib.dll", "libsplib.so", "libsplib.dylib", "trang.jar"}},
		{src: filepath.Join(cfg.Basedir(), "schema"), dest: filepath.Join(destdir, "share", "schema"), reject: []string{"changelog.rng", "readme.txt"}},
		{src: filepath.Join(cfg.Basedir(), "fonts"), dest: filepath.Join(destdir, "sw", "fonts")},
		{src: filepath.Join(cfg.Basedir(), "img"), dest: filepath.Join(destdir, "sw", "img")},
		{src: filepath.Join(srcdir, "tex"), dest: filepath.Join(destdir, "sw", "tex")},
		{src: filepath.Join(srcdir, "lua"), dest: filepath.Join(destdir, "sw", "lua"), reject: []string{"viznodelist.lua", "fileutils.lua", ".gitignore"}},
		{src: filepath.Join(srcdir, "hyphenation"), dest: filepath.Join(destdir, "sw", "hyphenation")},
	}

	for _, v := range mapping {
		reject := append(v.reject, ".DS_Store")
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
