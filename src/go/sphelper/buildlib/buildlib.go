// Package buildlib builds the dynamic library for LuaTeX
package buildlib

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"

	"speedatapublisher/sphelper/config"
)

// BuildCLib builds the dynamic C library
func BuildCLib(cfg *config.Config, goos string, goarch string) error {
	fmt.Println("Building dynamic lua glue library for", goos)
	srcdir := cfg.Srcdir
	os.Chdir(filepath.Join(srcdir, "c"))
	dylibbuild := filepath.Join(cfg.Builddir, "dylib")

	var cmd *exec.Cmd
	var triple string
	switch goos {
	case "darwin":
		switch goarch {
		case "amd64":
			triple = "x86_64-apple-macos11"
		case "arm64":
			triple = "arm64-apple-macos11"
		}
		cmd = exec.Command("clang", "-dynamiclib", "-target", triple, "-fPIC", "-undefined", "dynamic_lookup", "-o", filepath.Join(dylibbuild, "luaglue.so"), "luaglue.c", "-I/opt/homebrew/opt/lua@5.3/include/lua")
	case "linux":
		cmd = exec.Command("cc", "-shared", "-fPIC", "-o", filepath.Join(dylibbuild, "luaglue.so"), "luaglue.c", "-I/usr/include/lua5.3/")
	case "freebsd":
		cmd = exec.Command("cc", "-shared", "-fPIC", "-o", filepath.Join(dylibbuild, "luaglue.so"), "luaglue.c", "-I/usr/local/include/lua53/")
	case "windows":
		cmd = exec.Command("/usr/bin/x86_64-w64-mingw32-gcc", "-shared", "-o", filepath.Join(dylibbuild, "luaglue.dll"), "luaglue.c", "-I/usr/include/lua5.3/", "-L/luatex-bin/luatex/windows/amd64/default/", "-llua53w64", "-llibsplib", "-L"+dylibbuild)
	}
	outbuf, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println(string(outbuf))
		return err
	}
	return nil
}

// BuildLib builds the dynamic library
func BuildLib(cfg *config.Config, goos string, goarch string) error {
	fmt.Println("Building dynamic library for", goos)
	srcdir := cfg.Srcdir
	os.Chdir(filepath.Join(srcdir, "go", "splib"))
	libraryextension := ".so"
	switch goos {
	case "darwin":
		libraryextension = ".dylib"
	case "windows":
		libraryextension = ".dll"
	}
	dylibbuild := filepath.Join(cfg.Builddir, "dylib")
	var cmd *exec.Cmd
	if cfg.IsPro {
		cmd = exec.Command("go", "build", "-tags", "pro", "-buildmode=c-shared", "-o", filepath.Join(dylibbuild, "libsplib"+libraryextension), "speedatapublisher/splib")
	} else {
		cmd = exec.Command("go", "build", "-buildmode=c-shared", "-o", filepath.Join(dylibbuild, "libsplib"+libraryextension), "speedatapublisher/splib")
	}
	cmd.Env = os.Environ()
	if goos != runtime.GOOS {
		ccenv := os.Getenv("CC_" + goos)
		cmd.Env = append(cmd.Env, "CC="+ccenv)
		cmd.Env = append(cmd.Env, "GOOS="+goos)
	}
	if goarch != "" {
		cmd.Env = append(cmd.Env, "GOARCH="+goarch)
	}
	cmd.Env = append(cmd.Env, "CGO_LDFLAGS=-undefined dynamic_lookup")
	cmd.Env = append(cmd.Env, "CGO_ENABLED=1")
	outbuf, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println(string(outbuf))
		return err
	}
	return nil

}
