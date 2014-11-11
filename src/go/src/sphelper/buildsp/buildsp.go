package buildsp

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"

	"sphelper/config"

	"github.com/speedata/gogit"
)

func BuildGo(cfg *config.Config, destbin, goos, goarch, targettype string) bool {
	srcdir := cfg.Srcdir
	os.Chdir(cfg.Basedir())

	os.Setenv("GOPATH", filepath.Join(srcdir, "go"))
	if goarch != "" {
		os.Setenv("GOARCH", goarch)
	}

	if goos != "" {
		os.Setenv("GOOS", goos)
	}

	// We add the git sha1 to the version number
	repo, err := gogit.OpenRepository(filepath.Join(cfg.Basedir(), ".git"))
	if err != nil {
		log.Fatal(err)
	}
	rev, err := repo.LookupReference("HEAD")
	if err != nil {
		log.Fatal(err)
	}
	headsha1 := rev.Target().String()[:8]

	publisher_version := cfg.Publisherversion.String() + "-" + headsha1
	binaryname := "sp"
	if goos == "windows" {
		binaryname += ".exe"
	}

	// Now compile the go executable
	arguments := []string{"build", "-ldflags", fmt.Sprintf("-X main.dest %s -X main.version %s", targettype, publisher_version), "-o", filepath.Join(destbin, binaryname), "sp/main"}

	cmd := exec.Command("go", arguments...)
	outbuf, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println(string(outbuf))
		fmt.Println(err)
		return false
	}
	return true
}
