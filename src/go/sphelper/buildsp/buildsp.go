// Package buildsp builds the sp executable
package buildsp

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"

	"sphelper/config"
)

// BuildGo builds the speedata Publisher runner
func BuildGo(cfg *config.Config, destbin, goos, goarch, targettype, location string) error {
	// srcdir := cfg.Srcdir
	os.Chdir(filepath.Join(cfg.Srcdir, "go", "sp", "sp"))

	if goarch != "" {
		os.Setenv("GOARCH", goarch)
	}

	if goos != "" {
		os.Setenv("GOOS", goos)
	}

	publisherversion := cfg.Publisherversion.String()

	binaryname := "sp"
	if goos == "windows" {
		binaryname = "sp.exe"
	}
	if location == "" {
		location = filepath.Join(destbin, binaryname)
	}

	// Now compile the go executable
	arguments := []string{"build", "-ldflags", fmt.Sprintf("-X main.dest=%s -X main.version=%s -s -w", targettype, publisherversion), "-o", location, "sp/sp"}
	cmd := exec.Command("go", arguments...)
	cmd.Env = append(cmd.Env, "GOPATH="+os.TempDir()+":"+filepath.Join(cfg.Srcdir, "go"))
	cmd.Env = append(cmd.Env, "GOCACHE="+os.Getenv("GOCACHE"))
	cmd.Env = append(cmd.Env, "HOME="+os.Getenv("HOME"))

	if goos != runtime.GOOS {
		cmd.Env = append(cmd.Env, "GOOS="+goos)
	}
	if goarch != "" {
		cmd.Env = append(cmd.Env, "GOARCH="+goarch)
	}

	// cmd.Dir = filepath.Join(srcdir, "go")

	outbuf, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println(string(outbuf))
		return err
	}
	return nil
}
