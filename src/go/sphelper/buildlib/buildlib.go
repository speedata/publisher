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

// BuildLib builds the dynamic library
func BuildLib(cfg *config.Config, goos string, goarch string) error {
	fmt.Println("Building dynamic library for", goos)
	srcdir := cfg.Srcdir
	os.Chdir(filepath.Join(srcdir, "go", "splib"))
	libraryextension := ".so"
	switch goos {
	case "darwin":
		libraryextension = ".so"
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
	switch goos {
	case "darwin":
		cmd.Env = append(cmd.Env, "CGO_CFLAGS: -I/opt/homebrew/opt/lua@5.3/include/lua")
		cmd.Env = append(cmd.Env, "CGO_LDFLAGS=-undefined dynamic_lookup")
	case "linux":
		cmd.Env = append(cmd.Env, "CGO_CFLAGS=-I/usr/include/lua5.3")
	case "windows":
		cmd.Env = append(cmd.Env, "CGO_CFLAGS=-I/usr/include/lua5.3")
		cmd.Env = append(cmd.Env, "CGO_LDFLAGS=-llua53w64 -L/luatex-bin/luatex/windows/amd64/default/")
	}
	cmd.Env = append(cmd.Env, "CGO_ENABLED=1")
	outbuf, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println(string(outbuf))
		return err
	}
	return nil

}
