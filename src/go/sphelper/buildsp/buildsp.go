// Package buildsp builds the sp executable
package buildsp

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"

	"speedatapublisher/sphelper/config"
)

// BuildGo builds the speedata Publisher runner
func BuildGo(cfg *config.Config, destbin, goos, goarch, targettype, location, extraldflags string) error {
	os.Chdir(filepath.Join(cfg.Srcdir, "go"))

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
	var arguments []string
	if cfg.IsPro {
		fmt.Println("build pro")
		arguments = []string{"build", "-ldflags", fmt.Sprintf("%s -X main.dest=%s -X main.version=%s -X main.pro=yes -s -w", extraldflags, targettype, publisherversion), "-tags", "pro", "-o", location, "speedatapublisher/sp/sp"}
	} else {
		fmt.Println("build std")
		arguments = []string{"build", "-ldflags", fmt.Sprintf("%s -X main.dest=%s -X main.version=%s -s -w", extraldflags, targettype, publisherversion), "-o", location, "speedatapublisher/sp/sp"}
	}
	cmd := exec.Command("go", arguments...)
	cmd.Env = os.Environ()

	if goos != runtime.GOOS {
		cmd.Env = append(cmd.Env, "GOOS="+goos)
	}
	if goarch != "" {
		cmd.Env = append(cmd.Env, "GOARCH="+goarch)
	}

	outbuf, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println(string(outbuf))
		return err
	}
	return nil
}
