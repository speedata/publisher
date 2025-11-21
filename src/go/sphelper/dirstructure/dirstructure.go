// Package dirstructure creates the directory structure used in the distribution ZIP files.
package dirstructure

import (
	"fmt"
	"os"
	"path/filepath"

	"speedatapublisher/sphelper/config"
	"speedatapublisher/sphelper/fileutils"
)

// GetLuaTeXDir returns the directory with the LuaTeX binaries for the specific
// platform.
func GetLuaTeXDir(platform, arch string) (string, error) {
	var srcbindir string
	if srcbindir = os.Getenv("LUATEX_BIN"); srcbindir == "" || !fileutils.IsDir(srcbindir) {
		fmt.Println("Error: environment variable LUATEX_BIN not set or does not point to a directory")
		os.Exit(-1)
	}

	d := filepath.Join(srcbindir, platform, arch, "default")
	luatexdir, err := filepath.EvalSymlinks(d)
	return luatexdir, err
}

// FillBuildDir builds the directory structure.  srcbindir contains all files necessary to run LuaTeX
func FillBuildDir(cfg *config.Config, luatexbindir, bindir, sharedir, swdir string) error {
	var err error
	srcdir := filepath.Join(cfg.Basedir(), "src")

	mapping := []struct {
		src    string
		dest   string
		reject []string
	}{
		{src: luatexbindir, dest: bindir},
		{src: filepath.Join(cfg.Basedir(), "lib"), dest: filepath.Join(sharedir, "lib"), reject: []string{".gitignore", "libsplib.h", "libsplib.dll", "libsplib.so", "libsplib.dylib", "trang.jar", "luaglue.so"}},
		{src: filepath.Join(cfg.Basedir(), "schema"), dest: filepath.Join(sharedir, "schema"), reject: []string{"changelog.rng", "readme.txt"}},
		{src: filepath.Join(cfg.Basedir(), "fonts"), dest: filepath.Join(swdir, "fonts")},
		{src: filepath.Join(cfg.Basedir(), "img"), dest: filepath.Join(swdir, "img")},
		{src: filepath.Join(srcdir, "tex"), dest: filepath.Join(swdir, "tex")},
		{src: filepath.Join(srcdir, "colorprofiles"), dest: filepath.Join(swdir, "colorprofiles")},
		{src: filepath.Join(srcdir, "metapost"), dest: filepath.Join(swdir, "metapost")},
		{src: filepath.Join(srcdir, "lua"), dest: filepath.Join(swdir, "lua"), reject: []string{"viznodelist.lua", "lua-visual-debug.lua", "fileutils.lua", ".gitignore"}},
		{src: filepath.Join(srcdir, "hyphenation"), dest: filepath.Join(swdir, "hyphenation")},
	}

	for _, v := range mapping {
		reject := append(v.reject, ".DS_Store", ".gitignore")
		err = fileutils.CpR(v.src, v.dest, reject...)
		if err != nil {
			return err
		}
	}
	exefiles, err := filepath.Glob(filepath.Join(bindir, "*"))
	if err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}
	for _, v := range exefiles {
		os.Chmod(v, 0755)
	}
	return nil
}
