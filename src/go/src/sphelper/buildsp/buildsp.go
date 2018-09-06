package buildsp

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"sphelper/config"
)

func BuildGo(cfg *config.Config, destbin, goos, goarch, targettype, location string) error {
	srcdir := cfg.Srcdir
	os.Chdir(cfg.Basedir())

	os.Setenv("GOPATH", filepath.Join(srcdir, "go"))
	if goarch != "" {
		os.Setenv("GOARCH", goarch)
	}

	if goos != "" {
		os.Setenv("GOOS", goos)
	}

	publisher_version := cfg.Publisherversion.String()

	binaryname := "sp"
	if goos == "windows" {
		binaryname = "sp.exe"
	}
	if location == "" {
		location = filepath.Join(destbin, binaryname)
	}
	// Now compile the go executable
	arguments := []string{"build", "-ldflags", fmt.Sprintf("-X main.dest=%s -X main.version=%s -s", targettype, publisher_version), "-o", location, "sp/sp"}
	cmd := exec.Command("go", arguments...)
	outbuf, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println(string(outbuf))
		return err
	}
	return nil
}
