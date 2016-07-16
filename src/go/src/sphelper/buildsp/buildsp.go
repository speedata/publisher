package buildsp

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"sphelper/config"
)

func BuildGo(cfg *config.Config, destbin, goos, goarch, targettype string) error {
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
		binaryname += ".exe"
	}
	// separator should be " " or "=".
	// Old versions of Go use " ", newer versions use "=" for setting the linker flags
	separator := " "
	if tmp := os.Getenv("BUILDSEPERATOR"); tmp != "" {
		separator = tmp
	}

	// Now compile the go executable
	arguments := []string{"build", "-ldflags", fmt.Sprintf("-X main.dest%s%s -X main.version%s%s", separator, targettype, separator, publisher_version), "-o", filepath.Join(destbin, binaryname), "sp/main"}
	cmd := exec.Command("go", arguments...)
	outbuf, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println(string(outbuf))
		return err
	}
	return nil
}
