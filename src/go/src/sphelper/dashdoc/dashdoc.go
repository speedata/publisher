package dashdoc

import (
	"database/sql"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"

	"sphelper/config"
	commandsxml "sphelper/newcommandsxml"

	_ "github.com/mattn/go-sqlite3"
)

var (
	manualpath string
	destpath   string
)

func CopyFile(source string, dest string) (err error) {
	sf, err := os.Open(source)
	if err != nil {
		return err
	}
	defer sf.Close()
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

func cp(path string, info os.FileInfo, err error) error {
	rel, err := filepath.Rel(manualpath, path)
	if err != nil {
		return err
	}
	dest := filepath.Join(destpath, rel)
	if info.IsDir() {
		os.Mkdir(dest, 0755)
	} else {
		return CopyFile(path, dest)
	}
	return nil
}

func plist(lang string) string {
	var idx string
	if lang == "en" {
		idx = "index.html"
	} else {
		idx = "index-de.html"
	}
	return fmt.Sprintf(`<?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>CFBundleIdentifier</key>
        <string>speedatapublisher%s</string>
        <key>CFBundleName</key>
        <string>speedata Publisher (%s)</string>
        <key>DocSetPlatformFamily</key>
        <string>sp%s</string>
        <key>isDashDocset</key>
        <true/>
        <key>dashIndexFilePath</key>
        <string>%s</string></dict>
    </plist>
`, lang, lang, lang, idx)
}

func DoThings(cfg *config.Config) error {

	r, err := os.Open(filepath.Join(cfg.Basedir(), "doc", "commands-xml", "commands.xml"))
	if err != nil {
		return err
	}
	c, err := commandsxml.ReadCommandsFile(r)
	if err != nil {
		return err
	}
	manualpath = filepath.Join(cfg.Builddir, "manual")

	for _, lang := range []string{"de", "en"} {
		docbase := filepath.Join(cfg.Builddir, "speedatapublisher-"+lang+".docset")
		destpath = filepath.Join(docbase, "Contents", "Resources", "Documents")
		plistpath := filepath.Join(docbase, "Contents", "info.plist")

		err = os.RemoveAll(docbase)
		if err != nil {
			return err
		}

		err = os.MkdirAll(destpath, 0755)
		if err != nil {
			return err
		}

		filepath.Walk(manualpath, cp)

		err = ioutil.WriteFile(plistpath, []byte(plist(lang)), 0644)
		if err != nil {
			return err
		}

		db, err := sql.Open("sqlite3", filepath.Join(docbase, "Contents", "Resources", "docSet.dsidx"))
		if err != nil {
			return err
		}
		defer db.Close()

		_, err = db.Exec(`CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);`)
		if err != nil {
			return err
		}

		for _, v := range c.CommandsEn {
			_, err = db.Exec(`INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES (?, ?, ?);`, v.Name(lang), "Command", filepath.Join("commands-"+lang, v.Htmllink()))
			if err != nil {
				return err
			}
			for _, attr := range v.Attributes(lang) {
				_, err = db.Exec(`INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES (?, ?, ?);`, attr.Name(lang), "Function", filepath.Join("commands-"+lang, v.Htmllink()+"#"+attr.HTMLFragment()))
				if err != nil {
					return err
				}
			}
		}
	}
	return nil
}
