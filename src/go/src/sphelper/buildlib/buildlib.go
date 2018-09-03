package buildlib

import (
	"os/exec"
	"path/filepath"

	"sphelper/config"
)

func BuildLib(cfg *config.Config) error {
	cmd := exec.Command("go", "build", "-buildmode=c-shared", "-o", filepath.Join(cfg.Libdir, "libsplib.dylib"), "splib")
	return cmd.Run()
}
