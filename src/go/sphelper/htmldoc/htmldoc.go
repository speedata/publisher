// Package is for documenting each command
package htmldoc

import (
	"fmt"
	"html"
	"html/template"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"sphelper/config"
	commandsxml "sphelper/newcommandsxml"
)

var (
	wg        sync.WaitGroup
	templates *template.Template
)

func translate(lang, text string) string {
	if lang == "en" {
		return text
	}
	switch text {
	case "Description":
		return "Beschreibung"
	case "Commands":
		return "Befehlsübersicht"
	case "Example":
		return "Beispiel"
	case "Attributes":
		return "Attribute"
	case "Child elements":
		return "Kindelemente"
	case "Allowed attributes":
		return "Erlaubte Attribute"
	case "Parent elements":
		return "Elternelemente"
	case "See also":
		return "Siehe auch"
	case "Info":
		return "Hinweis"
	case "none":
		return "keine"
	case "Remarks":
		return "Bemerkungen"
	case "CSS name":
		return "CSS Name"
	case "CSS property":
		return "CSS Eigenschaft"
	case "since version":
		return "seit Version"
	}
	return "--"
}
func attributes(lang string, attributes []*commandsxml.Attribute) template.HTML {
	if len(attributes) == 0 {
		return template.HTML("(" + translate(lang, "none") + ")")
	}
	var ret []string
	for _, att := range attributes {
		switch lang {
		case "en":
			ret = append(ret, fmt.Sprintf(`<a href="#%s"><span class="tt">%s</span></a>`, att.HTMLFragment(), att.Name))
		case "de":
			ret = append(ret, fmt.Sprintf(`<a href="#%s"><span class="tt">%s</span></a>`, att.HTMLFragment(), att.Name))
		}
	}
	return template.HTML(strings.Join(ret, ", "))
}

func sortedcommands(commands *commandsxml.Commands) []*commandsxml.Command {
	return commands.CommandsSortedEn
}

func parentelements(lang string, cmd *commandsxml.Command) template.HTML {
	var ret []string
	x := cmd.Parents(lang)
	if len(x) == 0 {
		return template.HTML("(" + translate(lang, "none") + ")")
	}
	for _, v := range x {
		ret = append(ret, fmt.Sprintf(`<a href=%q>%s</a>`, v.Htmllink(), v.Name))
	}
	return template.HTML(strings.Join(ret, ", "))
}

func childelements(lang string, children []*commandsxml.Command) template.HTML {
	if len(children) == 0 {
		return template.HTML("(" + translate(lang, "none") + ")")
	}

	var ret []string
	for _, cmd := range children {
		ret = append(ret, fmt.Sprintf(`<a title="%s" href="%s">%s</a>`, html.EscapeString(cmd.DescriptionText(lang)), cmd.Htmllink(), cmd.Name))
	}
	return template.HTML(strings.Join(ret, ", "))
}

// Version | Startpage | ...
func footer(version, lang string, command *commandsxml.Command) template.HTML {
	return template.HTML(fmt.Sprintf(`Version: %s | <a href="../index.html">Start page</a> | <a href="../commands-en/layout.html">Command reference</a> | Other language: <a href="../../de/index.html">German</a>`, version))
}

func atttypeinfo(att *commandsxml.Attribute, lang string) template.HTML {
	atttypesDe := map[string]string{
		"boolean":            "yes oder no",
		"xpath":              `<a href="../description-de/xpath.html">XPath Ausdruck</a>`,
		"text":               "Text",
		"number":             "Zahl",
		"yesnolength":        "yes, no oder Längenangabe",
		"yesnonumber":        "yes, no oder Zahl",
		"numberorlength":     "Zahl oder Längenangabe",
		"numberlengthorstar": "Zahl, Maßangabe oder *-Angaben",
		"zerotohundred":      "0 bis 100",
	}
	atttypesEn := map[string]string{
		"boolean":            "yes or no",
		"xpath":              `<a href="../description-en/xpath.html">XPath Expression</a>`,
		"numberorlength":     "number or length",
		"numberlengthorstar": "Number, length or *-numbers",
		"yesnolength":        "yes, no or length",
		"yesnonumber":        "yes, no or number",
		"zerotohundred":      "0 up to 100",
	}
	ret := []string{}
	if att.Type != "" {
		switch lang {
		case "en":
			if x, ok := atttypesEn[att.Type]; ok {
				ret = append(ret, x)
			} else {
				ret = append(ret, att.Type)
			}
		case "de":
			if x, ok := atttypesDe[att.Type]; ok {
				ret = append(ret, x)
			} else {
				ret = append(ret, att.Type)
			}

		}
	}
	if att.Optional {
		ret = append(ret, "optional")
	}
	return template.HTML(strings.Join(ret, ", "))
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
	for _, cmd := range c.CommandsEn {
		cmd.Childelements("en")
	}
	outdir := filepath.Join(cfg.Builddir, "manual", "en")
	err = os.MkdirAll(outdir, 0755)
	if err != nil {
		return err
	}

	funcMap := template.FuncMap{
		"translate":      translate,
		"attributes":     attributes,
		"childelements":  childelements,
		"parentelements": parentelements,
		"sortedcommands": sortedcommands,
		"footer":         footer,
		"atttypeinfo":    atttypeinfo,
	}
	templates, err = template.New("").Funcs(funcMap).ParseFiles(filepath.Join(cfg.Basedir(), "doc", "manual", "templates", "command.html"))
	if err != nil {
		return err
	}
	os.MkdirAll(filepath.Join(outdir, "commands-en"), 0755)

	version := cfg.Publisherversion.String()
	for _, lang := range []string{"en"} {
		for _, v := range c.CommandsEn {
			fullpath := filepath.Join(outdir, "commands-"+lang, v.Htmllink())
			wg.Add(1)
			go builddoc(c, v, version, lang, fullpath)
		}
	}
	wg.Wait()
	return nil
}

func builddoc(c *commandsxml.Commands, v *commandsxml.Command, version string, lang string, fullpath string) {
	type sdata struct {
		Commands         *commandsxml.Commands
		Command          *commandsxml.Command
		Publisherversion string
		Lang             string
	}

	f, err := os.OpenFile(fullpath, os.O_WRONLY|os.O_TRUNC|os.O_CREATE, 0644)
	if err != nil {
		panic(err)
	}
	err = templates.ExecuteTemplate(f, "command.html", sdata{Commands: c, Command: v, Lang: lang, Publisherversion: version})
	if err != nil {
		fmt.Println(err)
	}
	f.Close()
	wg.Done()
}
