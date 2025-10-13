package main

import (
	"fmt"
	"io"
	"log/slog"
	"os"
	"speedatapublisher/splib/xmltree"
	"speedatapublisher/splibaux"
)

type luaAdapter struct{ l *LuaState }

func (a luaAdapter) CreateTable(narr, nrec int) { a.l.createTable(narr, nrec) }
func (a luaAdapter) AddKeyValueToTable(idx int, key string, v any) {
	a.l.addKeyValueToTable(idx, key, v)
}
func (a luaAdapter) RawSet(idx int)      { a.l.rawSet(idx) }
func (a luaAdapter) PushInt(v int)       { a.l.pushInt(v) }
func (a luaAdapter) PushString(s string) { a.l.pushString(s) }

func (l *LuaState) buildXMLTable() error {
	xmlfilename, ok := l.getString(1)
	if ok {
		l.remove(1)
	}
	xmltype := "(unknown)"
	if t, ok := l.getString(1); ok {
		xmltype = t
		l.remove(1)
	}
	slog.Info("Read XML file", "type", xmltype)

	full, err := splibaux.GetFullPath(xmlfilename)
	if err != nil {
		return err
	}

	f, err := os.Open(full)
	if err != nil {
		return err
	}
	defer f.Close()

	doc, err := xmltree.ParseXMLWithOptionsAndFilename(f, &xmltree.Options{
		ResolveInclude: func(href string) (io.ReadCloser, error) {
			// Deine bisherige Logik:
			full := splibaux.LookupFile(href)
			return os.Open(full)
		},
	}, xmlfilename)
	if err != nil {
		return fmt.Errorf("Cannot parse XML file %s (%w)", xmlfilename, err)
	}
	xmltree.RenderToLua(luaAdapter{l: l}, doc)
	return nil
}

func (l *LuaState) readXMLFile(r io.Reader, _ int) error {
	doc, err := xmltree.ParseXMLWithOptions(r, &xmltree.Options{
		ResolveInclude: func(href string) (io.ReadCloser, error) {
			// Deine bisherige Logik:
			full := splibaux.LookupFile(href)
			return os.Open(full)
		},
	})
	if err != nil {
		return err
	}
	xmltree.RenderToLua(luaAdapter{l: l}, doc)
	return nil
}
