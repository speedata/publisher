// Package buildlib builds the dynamic library for LuaTeX
package buildlib

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"

	"sphelper/config"
)

// BuildLib builds the dynamic library and
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
	os.RemoveAll(dylibbuild)
	os.MkdirAll(dylibbuild, 0755)
	cmd := exec.Command("go", "build", "-buildmode=c-shared", "-o", filepath.Join(dylibbuild, "libsplib"+libraryextension), "splib")
	if goos != runtime.GOOS {
		ccenv := os.Getenv("CC_" + goos)
		cmd.Env = append(cmd.Env, "CC="+ccenv)
		cmd.Env = append(cmd.Env, "GOOS="+goos)
	}
	if goarch != "" {
		cmd.Env = append(cmd.Env, "GOARCH="+goarch)
	}
	cmd.Env = append(cmd.Env, "CGO_ENABLED=1")
	// put the pkg file in tempdir, get the files from src
	cmd.Env = append(cmd.Env, "GOPATH="+os.TempDir()+":"+filepath.Join(srcdir, "go"))
	cmd.Env = append(cmd.Env, "GOCACHE="+os.Getenv("GOCACHE"))
	cmd.Env = append(cmd.Env, "PATH="+os.Getenv("PATH"))
	outbuf, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println(string(outbuf))
		return err
	}
	return nil

}
