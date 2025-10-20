// Package buildlib builds the dynamic library for LuaTeX
package buildlib

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"

	"speedatapublisher/sphelper/config"
)

func setEnvIfNotExists(cmd *exec.Cmd, envVarName, envVarValue string) {
	// Check if the environment variable already exists in cmd.Env
	for _, envVar := range cmd.Env {
		if strings.HasPrefix(envVar, envVarName) {
			return // Environment variable already exists, no need to set
		}
	}

	// If the environment variable doesn't exist, add it to cmd.Env
	cmd.Env = append(cmd.Env, envVarName+"="+envVarValue)
}

// BuildCLib builds the dynamic C library
func BuildCLib(cfg *config.Config, goos string, goarch string) error {
	fmt.Println("Building dynamic lua glue library for", goos, goarch)
	srcdir := cfg.Srcdir
	os.Chdir(filepath.Join(srcdir, "c"))
	dylibbuild := filepath.Join(cfg.Builddir, "dylib")
	ccenv := os.Getenv("CC_" + goarch + "_" + goos)

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
		switch goarch {
		case "amd64":
			cmd = exec.Command(ccenv, "-shared", "-fPIC", "-o", filepath.Join(dylibbuild, "luaglue.so"), "luaglue.c", "-I/usr/include/lua5.3/")
		case "arm64":
			cmd = exec.Command(ccenv, "-shared", "-fPIC", "-o", filepath.Join(dylibbuild, "luaglue.so"), "luaglue.c", "-I/usr/include/lua5.3/")
		}
	case "freebsd":
		cmd = exec.Command("cc", "-shared", "-fPIC", "-o", filepath.Join(dylibbuild, "luaglue.so"), "luaglue.c", "-I/usr/local/include/lua53/")
	case "windows":
		cmd = exec.Command(ccenv, "-shared", "-o", filepath.Join(dylibbuild, "luaglue.dll"), "luaglue.c", "-I/usr/include/lua5.3/", "-L/luatex-bin/luatex/windows/amd64/default/", "-llua53w64", "-llibsplib", "-L"+dylibbuild)
	}
	outbuf, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println(string(outbuf))
		return err
	}
	return nil
}

// BuildRustLib builds the dynamic rust library
func BuildRustLib(cfg *config.Config, goos string, goarch string) error {
	fmt.Println("Building dynamic rust library for", goos, goarch)
	srcdir := cfg.Srcdir
	os.Chdir(filepath.Join(srcdir, "rust", "rlib"))
	args := []string{"build", "--release"}

	if cfg.IsPro {
		args = append(args, "--features", "pro")
	}
	if goos == "windows" {
		args = append(args, "--target", "x86_64-pc-windows-gnu")
	} else {
		if goarch == "arm64" && goos == "linux" {
			args = append(args, "--target", "aarch64-unknown-linux-gnu")
		}
	}
	cmd := exec.Command("cargo", args...)
	cmd.Env = os.Environ()
	if goos != runtime.GOOS || goarch != runtime.GOARCH {
		ccenv := os.Getenv("CC_" + goarch + "_" + goos)
		cmd.Env = append(cmd.Env, "CC="+ccenv)
		cmd.Env = append(cmd.Env, "GOOS="+goos)
		fmt.Println("Looking for environment variable", "CC_"+goarch+"_"+goos, "found value", ccenv)
	}

	if goarch != "" {
		cmd.Env = append(cmd.Env, "GOARCH="+goarch)
	}
	outbuf, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println(string(outbuf))
		return err
	}
	// Now copy the resulting library to the build dir
	var libraryextension, librarydestextension string
	switch goos {
	case "darwin":
		libraryextension = "dylib"
		librarydestextension = "so"
	case "windows":
		libraryextension = "dll"
		librarydestextension = "dll"
	default:
		libraryextension = "so"
		librarydestextension = "so"
	}
	var targetdir string
	if goos == "windows" {
		targetdir = filepath.Join(cfg.Basedir(), "target", "x86_64-pc-windows-gnu", "release")
	} else {
		if goarch == "arm64" && goos == "linux" {
			targetdir = filepath.Join(cfg.Basedir(), "target", "aarch64-unknown-linux-gnu", "release")
		} else {
			targetdir = filepath.Join(cfg.Basedir(), "target", "release")
		}
	}
	dylibbuild := filepath.Join(cfg.Builddir, "dylib")
	var inputlib string
	switch goos {
	case "windows":
		inputlib = filepath.Join(targetdir, "rlib.dll")
	default:
		inputlib = filepath.Join(targetdir, "librlib."+libraryextension)
	}
	outputlib := filepath.Join(dylibbuild, "rlib."+librarydestextension)
	input, err := os.Open(inputlib)
	if err != nil {
		fmt.Println(err)
		return err
	}
	defer input.Close()
	output, err := os.Create(outputlib)
	if err != nil {
		fmt.Println(err)
		return err
	}
	defer output.Close()
	_, err = io.Copy(output, input)
	if err != nil {
		return err
	}
	return nil
}

// BuildLib builds the dynamic library
func BuildLib(cfg *config.Config, goos string, goarch string) error {
	fmt.Println("Building dynamic library for", goos, goarch)
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
	if goos != runtime.GOOS || goarch != runtime.GOARCH {
		ccenv := os.Getenv("CC_" + goarch + "_" + goos)
		cmd.Env = append(cmd.Env, "CC="+ccenv)
		cmd.Env = append(cmd.Env, "GOOS="+goos)
		fmt.Println("Looking for environment variable", "CC_"+goarch+"_"+goos, "found value", ccenv)
	}

	if goarch != "" {
		cmd.Env = append(cmd.Env, "GOARCH="+goarch)
	}
	switch goos {
	case "darwin":
		setEnvIfNotExists(cmd, "CGO_CFLAGS", "-I/opt/homebrew/opt/lua@5.3/include/lua")
		setEnvIfNotExists(cmd, "CGO_LDFLAGS", "-undefined dynamic_lookup")
	case "windows":
		setEnvIfNotExists(cmd, "CGO_CFLAGS", "-I/usr/include/lua5.3")
		setEnvIfNotExists(cmd, "CGO_LDFLAGS", "-llua53w64 -L/luatex-bin/luatex/windows/amd64/default/")
	default:
		setEnvIfNotExists(cmd, "CGO_CFLAGS", "-I/usr/include/lua5.3")
	}
	cmd.Env = append(cmd.Env, "CGO_ENABLED=1")
	outbuf, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println(string(outbuf))
		return err
	}
	return nil
}
