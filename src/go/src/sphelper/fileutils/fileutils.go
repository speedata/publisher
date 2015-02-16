package fileutils

import (
	"io"
	"os"
	"path/filepath"
)

func IsDir(path string) bool {
	fi, err := os.Stat(path)
	if err != nil {
		return false
	}
	return fi.IsDir()
}

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

func CpR(srcdir, destdir string, reject ...string) error {
	a := func(path string, info os.FileInfo, err error) error {
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
			} else {
				return CopyFile(path, dest)
			}

		}
		return nil
	}
	return filepath.Walk(srcdir, a)
}
