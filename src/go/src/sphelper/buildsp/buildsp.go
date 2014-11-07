package buildsp

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"sphelper/config"
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

	// publisher_version = @versions['publisher_version']
	//  let's always add the sha1 to the minor versions, so we
	//  _,minor,_ = publisher_version.split(/\./)
	//  if minor.to_i() % 2 == 1 then
	// 	rev = `git rev-parse HEAD`[0,8]
	// 	publisher_version = publisher_version + "-#{rev}"
	// # end
	binaryname := "sp"
	if goos == "windows" {
		binaryname += ".exe"
	}

	// Now compile the go executable
	arguments := []string{"build", "-ldflags", fmt.Sprintf("-X main.dest %s -X main.version %s", targettype, cfg.Publisherversion), "-o", filepath.Join(destbin, binaryname), "sp/main"}

	cmd := exec.Command("go", arguments...)
	outbuf, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println(string(outbuf))
		fmt.Println(err)
		return false
	}
	// arguments = "go build -ldflags '-X main.dest #{targettype} -X main.version #{publisher_version}' -o #{destbin}/#{binaryname} sp/main"
	// sh arguments do |ok, res|
	// 	if ! ok
	//     	puts "Go compilation failed"
	//     	return false
	//     end
	// end
	return true

}
