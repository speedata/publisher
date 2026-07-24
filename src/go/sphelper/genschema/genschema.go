// Package genschema creates Relax NG and XSD schema files for English and German
package genschema

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"speedatapublisher/sphelper/config"
)

const (
	// SDNAMESPACE is the speedata layout rules namespace
	SDNAMESPACE string = "urn:speedata.de:2009/publisher/en"
)

// DoThings creates two schema files for »en« and »de«
func DoThings(cfg *config.Config) error {
	basedir := cfg.Basedir()
	libdir := cfg.Libdir
	c, err := readCommandsFile(basedir)
	if err != nil {
		return err
	}
	warnUnmatchedLspRules(c)
	var buf []byte
	rngSchemaENPath := filepath.Join(basedir, "schema", "layoutschema-en.rng")
	rngSchemaDEPath := filepath.Join(basedir, "schema", "layoutschema-de.rng")
	xsdSchemaENPath := filepath.Join(basedir, "schema", "layoutschema-en.xsd")
	xsdSchemaDEPath := filepath.Join(basedir, "schema", "layoutschema-de.xsd")
	// in the first pass we generate the RELAX NG layout schema without “foreign nodes” and convert those to
	// XSD. This is easier than creating XSD programatically.
	buf, err = genRelaxNGSchema(c, "en", false)
	if err != nil {
		return err
	}
	err = os.WriteFile(rngSchemaENPath, buf, 0644)
	if err != nil {
		return err
	}

	buf, err = genRelaxNGSchema(c, "de", false)
	if err != nil {
		return err
	}
	err = os.WriteFile(rngSchemaDEPath, buf, 0644)
	if err != nil {
		return err
	}
	// now use TRANG to convert these to XSD
	cmd := exec.Command("java", "-jar", filepath.Join(libdir, "trang.jar"), rngSchemaENPath, xsdSchemaENPath)
	err = cmd.Run()
	if err != nil {
		return err
	}

	cmd = exec.Command("java", "-jar", filepath.Join(libdir, "trang.jar"), rngSchemaDEPath, xsdSchemaDEPath)
	err = cmd.Run()
	if err != nil {
		return err
	}

	buf, err = genRelaxNGSchema(c, "en", true)
	if err != nil {
		return err
	}
	err = os.WriteFile(rngSchemaENPath, buf, 0644)
	if err != nil {
		return err
	}
	buf, err = genRelaxNGSchema(c, "de", true)
	if err != nil {
		return err
	}
	err = os.WriteFile(rngSchemaDEPath, buf, 0644)
	if err != nil {
		return err
	}
	buf = genLuaAttributeList(c)
	err = os.WriteFile(filepath.Join(basedir, "src", "lua", "publisher", "commandattributes.lua"), buf, 0644)
	if err != nil {
		return err
	}
	return nil
}

// genLuaAttributeList returns a Lua module that maps each command name to
// the set of its allowed attribute names. The publisher uses this table at
// runtime to warn about unknown attributes in the layout file.
func genLuaAttributeList(c *commandsXML) []byte {
	var b bytes.Buffer
	b.WriteString("-- Generated from doc/commands-xml/commands.xml by \"sphelper genschema\". Do not edit.\n")
	b.WriteString("return {\n")
	for _, cmd := range c.Commands {
		fmt.Fprintf(&b, "    [%q] = {", cmd.Name)
		for i, attr := range cmd.Attributes {
			if i > 0 {
				b.WriteString(", ")
			}
			fmt.Fprintf(&b, "[%q] = true", attr.Name)
		}
		b.WriteString(" },\n")
	}
	b.WriteString("}\n")
	return b.Bytes()
}
