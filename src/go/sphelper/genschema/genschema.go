package genschema

import (
	"io/ioutil"
	"os/exec"
	"path/filepath"
	"sphelper/config"

	"sphelper/commandsxml"
)

const (
	SDNAMESPACE string = "urn:speedata.de:2009/publisher/en"
)

// DoThings creates two schema files for »en« and »de«
func DoThings(cfg *config.Config) error {
	basedir := cfg.Basedir()
	libdir := cfg.Libdir
	c, err := commandsxml.ReadCommandsFile(basedir)
	if err != nil {
		return err
	}
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
	err = ioutil.WriteFile(rngSchemaENPath, buf, 0644)
	if err != nil {
		return err
	}

	buf, err = genRelaxNGSchema(c, "de", false)
	if err != nil {
		return err
	}
	err = ioutil.WriteFile(rngSchemaDEPath, buf, 0644)
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
	err = ioutil.WriteFile(rngSchemaENPath, buf, 0644)
	if err != nil {
		return err
	}
	buf, err = genRelaxNGSchema(c, "de", true)
	if err != nil {
		return err
	}
	err = ioutil.WriteFile(rngSchemaDEPath, buf, 0644)
	if err != nil {
		return err
	}
	return nil
}
