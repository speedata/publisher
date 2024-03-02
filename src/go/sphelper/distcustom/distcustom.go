package distcustom

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"speedatapublisher/sphelper/buildlib"
	"speedatapublisher/sphelper/buildsp"
	"speedatapublisher/sphelper/config"
	"speedatapublisher/sphelper/dirstructure"
	"strings"
)

// CreateCustomBuild creates a custom directory structure for distribution
func CreateCustomBuild(cfg *config.Config, arguments []string) error {
	builddirSw := os.Getenv("SP_BUILDDIR_SW")
	if builddirSw == "" {
		return fmt.Errorf("Please set SP_BUILDDIR_SW to a custom build directory for the source files")
	}
	builddirShare := os.Getenv("SP_BUILDDIR_SHARE")
	if builddirShare == "" {
		return fmt.Errorf("Please set SP_BUILDDIR_SHARE to a custom build directory for the shared files")
	}
	builddirBin := os.Getenv("SP_BUILDDIR_BIN")
	if builddirBin == "" {
		return fmt.Errorf("Please set SP_BUILDDIR_BIN to a custom build directory for the binary files")
	}
	destdirSw := os.Getenv("SP_DESTDIR_SW")
	if destdirSw == "" {
		return fmt.Errorf("Please set SP_DESTDIR_SW to a custom dest directory for the source files")
	}
	destdirShare := os.Getenv("SP_DESTDIR_SHARE")
	if destdirShare == "" {
		return fmt.Errorf("Please set SP_DESTDIR_SHARE to a custom dest directory for the shared files")
	}
	destdirBin := os.Getenv("SP_DESTDIR_BIN")
	if destdirBin == "" {
		return fmt.Errorf("Please set SP_DESTDIR_BIN to a custom dest directory for the binary files")
	}
	libBuildDir := filepath.Join(builddirShare, "lib")
	libDestDir := filepath.Join(destdirShare, "lib")
	if len(arguments) != 1 {
		return fmt.Errorf("Please provide one combination of [darwin|linux|windows]/[arm64|amd64].\nFor example sphelper distcustom darwin/arm64")
	}
	osArch := strings.Split(arguments[0], "/")
	platform := osArch[0]
	arch := osArch[1]
	fmt.Println(platform, arch)
	luatexdir, err := dirstructure.GetLuaTeXDir(platform, arch)
	if err != nil {
		log.Fatal(err)
	}
	err = dirstructure.FillBuildDir(cfg, luatexdir, builddirBin, builddirShare, builddirSw)
	if err != nil {
		return err
	}
	extraldflags := fmt.Sprintf("-X main.libdir=%s -X main.srcdir=%s", libDestDir, destdirSw)
	err = buildsp.BuildGo(cfg, destdirBin, platform, arch, "custom", builddirBin, extraldflags)
	if err != nil {
		os.Exit(-1)
	}

	err = buildlib.BuildLib(cfg, platform, arch)
	if err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}

	switch platform {
	case "windows":
		os.Rename(filepath.Join(cfg.Builddir, "dylib", "libsplib.dll"), filepath.Join(destdirBin, "libsplib.dll"))
	case "linux":
		os.Rename(filepath.Join(cfg.Builddir, "dylib", "libsplib.so"), filepath.Join(libBuildDir, "libsplib.so"))
	case "darwin":
		os.Rename(filepath.Join(cfg.Builddir, "dylib", "libsplib.so"), filepath.Join(libBuildDir, "libsplib.so"))
	}

	return nil
}
