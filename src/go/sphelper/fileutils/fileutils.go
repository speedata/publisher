// Package fileutils provides some helper functions for file / directory copying
package fileutils

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
)

// IsDir returns true if the given path exists and is a directory.
func IsDir(path string) bool {
	fi, err := os.Stat(path)
	if err != nil {
		return false
	}
	return fi.IsDir()
}

// IsExeFile returns true if the path exists and is a regular file.
func IsExeFile(path string) bool {
	fi, err := os.Stat(path)
	if err != nil {
		return false
	}
	if fm := fi.Mode(); fm.IsRegular() {
		return true
	}
	return false
}

// CopyFile copies the source file to the destination path.
// If dest is a directory, the dest file name will have the same name as source.
func CopyFile(source string, dest string) (err error) {
	sf, err := os.Open(source)
	if err != nil {
		return err
	}
	defer sf.Close()
	if IsDir(dest) {
		dest = filepath.Join(dest, filepath.Base(source))
	}
	df, err := os.Create(dest)
	if err != nil {
		return err
	}
	defer df.Close()
	_, err = io.Copy(df, sf)
	if err == nil {
		si, err := os.Stat(source)
		if err != nil {
			err = os.Chmod(dest, si.Mode())
		}

	}
	return
}

// CpR copies every file in sourcedir into destdir
// while rejecting anything that is in reject. reject must contain file names, not full paths.
// Beware: this function behaves a bit weird.
func CpR(srcdir, destdir string, reject ...string) error {
	a := func(path string, info os.FileInfo, err error) error {
		if info == nil {
			return fmt.Errorf("info is nil for path %s", path)
		}

		rel, err := filepath.Rel(srcdir, path)
		if err != nil {
			return err
		}

		dest := filepath.Join(destdir, rel)
		if info.IsDir() {
			err = os.MkdirAll(dest, 0755)
			if os.IsExist(err) {
				// ok
			} else if err != nil {
				return err
			}
		} else {
			dontcopy := false
			for _, v := range reject {
				if filepath.Base(path) == v {
					dontcopy = true
				}
			}
			if dontcopy {
				return nil
			}
			return CopyFile(path, dest)

		}
		return nil
	}
	return filepath.Walk(srcdir, a)
}
