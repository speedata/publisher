package buildlib

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"

	"sphelper/config"
)

func BuildLib(cfg *config.Config, goos string, goarch string) error {
	fmt.Println("Building dynamic library for", goos)
	srcdir := cfg.Srcdir

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
	cmd.Env = append(cmd.Env, "GOPATH="+filepath.Join(srcdir, "go"))
	cmd.Env = append(cmd.Env, "GOCACHE="+os.Getenv("GOCACHE"))
	cmd.Env = append(cmd.Env, "PATH="+os.Getenv("PATH"))
	outbuf, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println(string(outbuf))
		return err
	}
	return nil

}
