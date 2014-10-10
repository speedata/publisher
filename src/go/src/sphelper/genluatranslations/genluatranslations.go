package genluatranslations

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"sphelper/commandsxml"
)

type attributeHash struct {
	en     string
	choice map[string]string
}

type commandHash struct {
	en         string
	attributes map[string]attributeHash
}

func DoThings(basedir string) error {
	c, err := commandsxml.ReadCommandsFile(basedir)
	if err != nil {
		return err
	}

	contexts := make(map[string][]commandsxml.CommandsxmlValue)

	for _, v := range c.Translations {
		contexts[v.Context] = append(contexts[v.Context], v)
	}

	out := new(bytes.Buffer)
	fmt.Fprint(out, `-- generated from genluatranslations.go (`, time.Now().Format("2006-01-02 15:04"))
	fmt.Fprintln(out, `)`)
	fmt.Fprintln(out, `-- do not edit!`)
	fmt.Fprintln(out, "module(...)")
	fmt.Fprintln(out, `return {`)
	fmt.Fprintln(out, `  de = {`)
	for _, v := range c.Commands {
		fmt.Fprintf(out, "      [%q] = { %q,\n", v.De, v.En)
		for _, attr := range v.Attributes {
			fmt.Fprintf(out, "        [%q] = %q,\n", attr.De, attr.En)
		}
		fmt.Fprintln(out, `        },`)
	}

	fmt.Fprintln(out, `  ["__values"] = {`)
	for ctx, values := range contexts {
		fmt.Fprintf(out, "    [%q] = {\n", ctx)
		for _, v := range values {
			fmt.Fprintf(out, "      [%q] = %q,\n", v.De, v.En)
		}
		fmt.Fprintln(out, `   },`)
	}
	fmt.Fprintln(out, `   } `)
	fmt.Fprintln(out, `  },`)
	fmt.Fprintln(out, `}`)

	outfile, err := os.OpenFile(filepath.Join(basedir, "src", "lua", "translations.lua"), os.O_WRONLY|os.O_TRUNC, 0644)
	if err != nil {
		return err
	}
	_, err = out.WriteTo(outfile)
	if err != nil {
		return err
	}
	outfile.Close()
	return nil
}
