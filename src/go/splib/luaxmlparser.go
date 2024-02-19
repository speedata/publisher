package main

import (
	"encoding/xml"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"os"
	"speedatapublisher/splibaux"
)

func (l *LuaState) buildXMLTable() error {
	var xmlfilename string
	xmltype := "(unknown)"
	var ok bool
	xmlfilename, ok = l.getString(1)
	if ok {
		l.remove(1)
		xmltype, ok = l.getString(1)
		if ok {
			l.remove(1)
		}
	}
	slog.Info("Read XML file", "type", xmltype)
	ret, err := splibaux.GetFullPath(xmlfilename)
	if err != nil {
		return err
	}
	xmlReader, err := os.Open(ret)
	if err != nil {
		return err
	}
	defer xmlReader.Close()

	l.createTable(0, 0)
	l.addKeyValueToTable(-1, ".__type", "document")
	err = l.readXMLFile(xmlReader, 1)
	if err != nil {
		slog.Error("Parsing XML file failed", "message", err.Error())
		return err
	}

	return nil
}

func (l *LuaState) readXMLFile(r io.Reader, startindex int) error {
	i := 1

	stackcounter := []int{startindex}

	dec := xml.NewDecoder(r)
	dec.Entity = xml.HTMLEntity
	indentlevel := 0
	for {
		tok, err := dec.Token()
		if err == io.EOF {
			break
		}
		if err != nil {
			if f, ok := r.(*os.File); ok {
				return fmt.Errorf("%w, file name %s", err, f.Name())
			}
			return err
		}

		switch v := tok.(type) {
		case xml.StartElement:
			var href string
			if v.Name.Space == "http://www.w3.org/2001/XInclude" && v.Name.Local == "include" {
				for _, attr := range v.Attr {
					if attr.Name.Local == "href" {
						href = attr.Value
					}
				}
				err := l.handleXInclude(href, stackcounter[indentlevel])
				if err != nil {
					return err
				}
			} else {
				// no xinclude
				l.pushInt(stackcounter[indentlevel])
				l.createTable(0, 8)
				l.addKeyValueToTable(-1, ".__name", v.Name.Local)
				l.addKeyValueToTable(-1, ".__local_name", v.Name.Local)
				l.addKeyValueToTable(-1, ".__type", "element")
				l.addKeyValueToTable(-1, ".__id", i)
				line, col := dec.InputPos()
				l.addKeyValueToTable(-1, ".__col", col)
				l.addKeyValueToTable(-1, ".__line", line)
				l.addKeyValueToTable(-1, ".__namespace", v.Name.Space)
				i++
				namespaces := map[string]string{}

				l.pushString(".__attributes")
				l.createTable(0, 0)
				for _, attr := range v.Attr {
					if attr.Name.Space == "xmlns" {
						namespaces[attr.Name.Local] = attr.Value
					} else if attr.Name.Local == "xmlns" {
						namespaces[""] = attr.Value
					} else {
						l.addKeyValueToTable(-1, attr.Name.Local, attr.Value)
					}
				}
				l.rawSet(-3)
				l.pushString(".__ns")
				l.createTable(0, len(namespaces))
				for k, v := range namespaces {
					l.addKeyValueToTable(-1, k, v)
				}
				l.rawSet(-3)
			}
			stackcounter[indentlevel]++
			indentlevel++
			stackcounter = append(stackcounter, 1)
		case xml.CharData:
			if indentlevel > 0 {
				index := stackcounter[indentlevel]
				stackcounter[indentlevel] = index + 1

				l.pushInt(index)
				l.pushString(string(v.Copy()))
				l.rawSet(-3)
			}
		case xml.EndElement:
			if v.Name.Space == "http://www.w3.org/2001/XInclude" && v.Name.Local == "include" {
				// ignore
			} else {
				l.rawSet(-3)
			}

			stackcounter = stackcounter[:len(stackcounter)-1]
			indentlevel--
		}
	}
	return nil
}

func (l *LuaState) handleXInclude(href string, startindex int) error {
	fullpath := splibaux.LookupFile(href)
	f, err := os.Open(fullpath)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			slog.Error("File not found", "filename", href)
		}
		return err
	}
	return l.readXMLFile(f, startindex)
}
