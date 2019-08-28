// Package is for documenting each command
package newdoc

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"text/template"
	"time"

	"sphelper/changelog"
	"sphelper/config"
	"sphelper/fileutils"
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
	case "Changelog":
		return "Liste der Änderungen"
	}
	return "--"
}
func attributes(lang string, attributes []*commandsxml.Attribute, cmd *commandsxml.Command) string {
	if len(attributes) == 0 {
		return "(" + translate(lang, "none") + ")"
	}
	var ret []string
	for _, att := range attributes {
		ret = append(ret, fmt.Sprintf("<<%s,`%s`>>", att.Attlink(cmd), att.Name))
	}
	return strings.Join(ret, ", ")
}

func sortedcommands(commands *commandsxml.Commands) []*commandsxml.Command {
	return commands.CommandsSortedEn
}

func parentelements(lang string, cmd *commandsxml.Command) string {
	var ret []string
	x := cmd.Parents(lang)
	if len(x) == 0 {
		return "(" + translate(lang, "none") + ")"
	}

	for _, v := range x {
		ret = append(ret, fmt.Sprintf("<<%s,`%s`>>", v.CmdLink(), v.Name))
	}
	return strings.Join(ret, ", ")
}

func childelements(lang string, children []*commandsxml.Command) string {
	if len(children) == 0 {
		return string("(" + translate(lang, "none") + ")")
	}

	var ret []string
	for _, cmd := range children {
		ret = append(ret, fmt.Sprintf("<<%s,`%s`>>", cmd.CmdLink(), cmd.Name))
	}
	return strings.Join(ret, ", ")
}

func atttypeinfo(att *commandsxml.Attribute, lang string) string {
	atttypesDe := map[string]string{
		"boolean":            "yes oder no",
		"xpath":              `<<ch-xpathfunktionen,XPath-Ausdruck>>`,
		"text":               "Text",
		"number":             "Zahl",
		"length":             "Längenangabe",
		"yesnolength":        "yes, no oder Längenangabe",
		"yesnonumber":        "yes, no oder eine Zahl",
		"numberorlength":     "Zahl oder Längenangabe",
		"numberlengthorstar": "Zahl, Maßangabe oder *-Angaben",
		"zerotohundred":      "0 bis 100",
	}
	atttypesEn := map[string]string{
		"boolean":            "yes or no",
		"xpath":              `<<ch-xpathfunktionen,XPath expression>>`,
		"numberorlength":     "number or length",
		"numberlengthorstar": "Number, length or *-numbers",
		"yesnolength":        "yes, no or length",
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
	return string(strings.Join(ret, ", "))
}

// Read the commands.xml file and create the files in the ref directory. The result of this function
// is the file commands.xml
func GenerateAdocFiles(cfg *config.Config, mode ...string) error {
	var err error
	srcpath := filepath.Join(cfg.Basedir(), "doc", "newmanual")
	destpath := filepath.Join(cfg.Builddir, "newdoc", "newmanual", "adoc")

	err = os.RemoveAll(destpath)
	if err != nil {
		return err
	}

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

	refdir := filepath.Join(srcpath, "adoc", "ref")
	err = os.MkdirAll(refdir, 0755)
	if err != nil {
		return err
	}

	funcMap := template.FuncMap{
		"translate":      translate,
		"attributes":     attributes,
		"childelements":  childelements,
		"parentelements": parentelements,
		"sortedcommands": sortedcommands,
		"atttypeinfo":    atttypeinfo,
	}
	templates, err = template.New("").Funcs(funcMap).ParseFiles(filepath.Join(srcpath, "templates", "command.txt"))
	if err != nil {
		return err
	}

	for _, v := range c.CommandsEn {
		fullpath := filepath.Join(refdir, v.Adoclink())
		wg.Add(1)
		go builddoc(c, v, "de", fullpath)
	}
	wg.Wait()

	fileutils.CpR(filepath.Join(srcpath, "adoc"), destpath)
	adocfile, err := filepath.Abs(filepath.Join(destpath, "publisherhandbuch.adoc"))
	if err != nil {
		return err
	}
	var cmd *exec.Cmd
	cmdline := []string{"-b", "docbook", adocfile, "-D", cfg.Builddir}
	for len(mode) > 0 {
		cmdline = append(cmdline, "-a", mode[0])
		mode = mode[1:]
	}
	cmd = exec.Command("asciidoctor", cmdline...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err = cmd.Run()
	if err != nil {
		return err
	}
	return nil
}

func DoThings(cfg *config.Config, sitedoc bool) error {
	var err error
	newmanualsourcepath := filepath.Join(cfg.Basedir(), "doc", "newmanual")
	newmanualdestpath := filepath.Join(cfg.Builddir, "newdoc", "newmanual")
	newmanualadocpath := filepath.Join(newmanualdestpath, "adoc")

	err = os.RemoveAll(newmanualdestpath)
	if err != nil {
		return err
	}

	err = GenerateAdocFiles(cfg)
	if err != nil {
		return err
	}

	// Copy the adoc and hugo files from the main dir into the build dir.
	// In the adoc path we add the reference files from commands.xml (subdir ref),
	// then build the docbook file and finally create the hugo site from the docbook file.
	newmanualhugopath := filepath.Join(newmanualdestpath, "hugo")
	fileutils.CpR(filepath.Join(newmanualsourcepath, "hugo"), newmanualhugopath)
	fileutils.CpR(filepath.Join(newmanualadocpath, "img"), filepath.Join(newmanualhugopath, "static", "img"))

	newmanualhugopath, err = filepath.Abs(newmanualhugopath)
	if err != nil {
		return err
	}
	xsltfile, err := filepath.Abs(filepath.Join(newmanualsourcepath, "db2md.xsl"))
	if err != nil {
		return err
	}
	docbookfile, err := filepath.Abs(filepath.Join(cfg.Builddir, "publisherhandbuch.xml"))
	if err != nil {
		return err
	}

	cmd := exec.Command("java", "-jar", filepath.Join(cfg.Basedir(), "lib", "saxon9804he.jar"), fmt.Sprintf("-xsl:%s", xsltfile), "-o:publisherhandbuch.txt", docbookfile, fmt.Sprintf("outputdir=file:%s", newmanualhugopath), fmt.Sprintf("version=%s", cfg.Publisherversion))
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err = cmd.Run()
	if err != nil {
		return err
	}

	// do the changelog
	cl, err := changelog.ReadChangelog(cfg)
	if err != nil {
		return err
	}

	contentpath := filepath.Join(newmanualhugopath, "content")

	clw, err := os.Create(filepath.Join(contentpath, "ch-changelog.md"))
	if err != nil {
		return err
	}
	defer clw.Close()
	fmt.Fprintln(clw, "+++\ntitle = \"Changelog\"\n+++")
	fmt.Fprintln(clw)
	fmt.Fprintln(clw, "\n#", translate("de", "Changelog"))

	type release struct {
		date    time.Time
		version string
		entries []string
	}

	for _, chap := range cl.Chapter {
		fmt.Fprintf(clw, "## %s\n\n", chap.Version)
		version := ""
		var rr []release
		var r release
		for _, entry := range chap.Entries {
			if entry.Version != version {
				if version != "" {
					rr = append(rr, r)
				}
				d, err := time.Parse("2006-01-02", entry.Date)
				if err != nil {
					return err
				}
				r = release{date: d, version: entry.Version}
				version = entry.Version
			}
			r.entries = append(r.entries, entry.De.Text)
		}
		rr = append(rr, r)

		fmt.Fprintln(clw, "\n<dl>")
		for _, r := range rr {
			fmt.Fprintf(clw, "<dt>%s &nbsp;&nbsp;&nbsp;&nbsp;(%s)</dt><dd><ul>\n", r.version, r.date.Format("2.1.2006"))
			for _, e := range r.entries {
				fmt.Fprintf(clw, "<li>%s</li>\n", e)
			}
			fmt.Fprintln(clw, "</ul>")
		}
		fmt.Fprintln(clw, "</dl>")
		fmt.Fprintln(clw)
	}
	fmt.Println("generating doc")
	cmd = exec.Command("hugo")
	if sitedoc {
		cmd.Env = append(os.Environ(), "HUGO_UGLYURLS=false")
	} else {
		cmd.Env = append(os.Environ(), "HUGO_UGLYURLS=true")
	}
	cmd.Dir = newmanualhugopath
	cmd.Env = append(cmd.Env, fmt.Sprintf("PUBLISHER_VERSION=%s", cfg.Publisherversion))
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	err = cmd.Run()
	if err != nil {
		return err
	}

	fileutils.CpR(filepath.Join(newmanualhugopath, "public"), filepath.Join(cfg.Builddir, "manual", "de"))
	return nil
}

func builddoc(c *commandsxml.Commands, v *commandsxml.Command, lang string, fullpath string) {
	type sdata struct {
		Commands *commandsxml.Commands
		Command  *commandsxml.Command
		Lang     string
	}

	f, err := os.Create(fullpath)
	if err != nil {
		panic(err)
	}
	err = templates.ExecuteTemplate(f, "command.txt", sdata{Commands: c, Command: v, Lang: lang})
	if err != nil {
		fmt.Println(err)
	}
	f.Close()
	wg.Done()
}
