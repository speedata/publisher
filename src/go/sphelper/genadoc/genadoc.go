// Package genadoc creates a docbook file from
// adoc sources, commands.xml and changelog.xml
package genadoc

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"sync"
	"text/template"
	"time"

	"speedatapublisher/sphelper/changelog"
	"speedatapublisher/sphelper/commandsxml"
	"speedatapublisher/sphelper/config"
	"speedatapublisher/sphelper/fileutils"
)

var (
	wg            sync.WaitGroup
	templates     *template.Template
	ghIssueRegexp *regexp.Regexp
	ttReplace     *strings.Replacer
)

func init() {
	ghIssueRegexp = regexp.MustCompile(`#(\d+)`)
	ttReplace = strings.NewReplacer(`<tt>`, "`", `</tt>`, "`")
}

func translate(lang, text string) string {
	if lang == "en" {
		return text
	}
	switch text {
	case "Attribute index":
		return "Attribute Index"
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
func attributes(lang string, attributes []*commandsxml.Attribute) string {
	if len(attributes) == 0 {
		return "(" + translate(lang, "none") + ")"
	}
	var ret []string
	for _, att := range attributes {
		ret = append(ret, fmt.Sprintf("<<%s,`%s`>>", att.Attlink(), att.Name))
	}
	return strings.Join(ret, ", ")
}

func sortedcommands(commands *commandsxml.Commands) []*commandsxml.Command {
	return commands.Commands()
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
		"boolean":                "yes oder no",
		"xpath":                  `<<ch-xpathfunktionen,XPath-Ausdruck>>`,
		"text":                   "Text",
		"number":                 "Zahl",
		"length":                 "Längenangabe",
		"yesnolength":            "yes, no oder Längenangabe",
		"yesnonumber":            "yes, no oder eine Zahl",
		"numberorlength":         "Zahl oder Längenangabe",
		"numberlengthorstar":     "Zahl, Maßangabe oder *-Angaben",
		"zerotohundred":          "0 bis 100",
		"zerohundredtwofivefive": "0 bis 100 bzw. 0 bis 255",
	}
	atttypesEn := map[string]string{
		"boolean":                "yes or no",
		"xpath":                  `<<ch-xpathfunctions,XPath expression>>`,
		"numberorlength":         "number or length",
		"numberlengthorstar":     "Number, length or *-numbers",
		"yesnolength":            "yes, no or length",
		"zerotohundred":          "0 up to 100",
		"zerohundredtwofivefive": "0 to 100 or 0 to 255",
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

type sortAllAttributeNamesT []string

func (a sortAllAttributeNamesT) Len() int           { return len(a) }
func (a sortAllAttributeNamesT) Swap(i, j int)      { a[i], a[j] = a[j], a[i] }
func (a sortAllAttributeNamesT) Less(i, j int) bool { return a[i] < a[j] }

// GenerateAdocFiles reads the commands.xml file and creates the files in the
// ref directory. mode is the asciidoctor mode.
func GenerateAdocFiles(cfg *config.Config, lang string, mode ...string) error {
	var err error
	srcpath := filepath.Join(cfg.Basedir(), "doc", "newmanual")
	destpath := filepath.Join(cfg.Builddir, "newdoc", "newmanual", "adoc-"+lang)

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
	allAttributes := make(map[string][]*commandsxml.Command)
	for _, cmd := range c.Commands() {
		for _, attr := range cmd.Attr {
			allAttributes[attr.Name] = append(allAttributes[attr.Name], cmd)
		}
	}

	allAttributeNames := make(sortAllAttributeNamesT, 0, len(allAttributes))

	for attr := range allAttributes {
		allAttributeNames = append(allAttributeNames, attr)
	}

	sort.Sort(allAttributeNames)

	refdir := filepath.Join(srcpath, "adoc-"+lang, "ref")
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
	templates, err = template.New("").Funcs(funcMap).ParseFiles(filepath.Join(srcpath, "templates", "command.txt"), filepath.Join(srcpath, "templates", "attributesref.txt"))
	if err != nil {
		return err
	}
	fullpath := filepath.Join(refdir, "00attributes.adoc")
	f, err := os.Create(fullpath)
	if err != nil {
		panic(err)
	}
	err = templates.ExecuteTemplate(f, "attributesref.txt", struct{ Lang, AttributeNames, AttributeMap interface{} }{lang, allAttributeNames, allAttributes})
	if err != nil {
		fmt.Println(err)
	}

	for _, v := range c.Commands() {
		fullpath := filepath.Join(refdir, v.Adoclink())
		wg.Add(1)
		go builddoc(c, v, lang, fullpath)
	}
	wg.Wait()

	fileutils.CpR(filepath.Join(srcpath, "adoc-"+lang), destpath)
	cl, err := changelog.ReadChangelog(cfg)
	if err != nil {
		return err
	}

	changelog := filepath.Join(destpath, "changelog.adoc")
	clw, err := os.Create(changelog)
	if err != nil {
		return err
	}
	defer clw.Close()

	fmt.Fprintln(clw, "[[ch-changelog]]")
	fmt.Fprintln(clw)
	fmt.Fprintln(clw, "\n=", translate(lang, "Changelog"))

	type release struct {
		date    time.Time
		version string
		entries []string
	}

	for _, chap := range cl.Chapter {
		fmt.Fprintf(clw, "== %s\n\n", chap.Version)
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
			var e string
			if lang == "en" {
				e = entry.En.Text
			} else {
				e = entry.De.Text
			}
			e = ghIssueRegexp.ReplaceAllString(e, `https://github.com/speedata/publisher/issues/$1[$1]`)
			e = ttReplace.Replace(e)
			r.entries = append(r.entries, e)
		}
		rr = append(rr, r)

		fmt.Fprintln(clw)
		for _, r := range rr {
			if lang == "en" {
				fmt.Fprintf(clw, "%s (%s)::\n", r.version, r.date.Format("2006-01-02"))
			} else {
				fmt.Fprintf(clw, "%s (%s)::\n", r.version, r.date.Format("2.1.2006"))
			}
			for _, e := range r.entries {
				fmt.Fprintf(clw, " * %s\n", e)
			}
		}
		fmt.Fprintln(clw)
	}
	var manualfile string
	switch lang {
	case "en":
		manualfile = "publishermanual.adoc"
	case "de":
		manualfile = "publisherhandbuch.adoc"
	}
	adocfile, err := filepath.Abs(filepath.Join(destpath, manualfile))
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

// DoThings creates the documentation in asciidoctor format. The output directory
func DoThings(cfg *config.Config, lang string) error {
	var err error
	err = GenerateAdocFiles(cfg, lang)
	if err != nil {
		return err
	}
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
