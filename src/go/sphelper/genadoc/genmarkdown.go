package genadoc

import (
	"fmt"
	"os"
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
)

var wg sync.WaitGroup

func translate(lang, text string) string {
	switch text {
	case "Attributes":
		if lang == "de" {
			return "Attribute"
		}
	case "Child elements":
		if lang == "de" {
			return "Kindelemente"
		}
	case "Parent elements":
		if lang == "de" {
			return "Elternelemente"
		}
	case "Example":
		if lang == "de" {
			return "Beispiel"
		}
	case "Info":
		if lang == "de" {
			return "Hinweis"
		}
	case "Remarks":
		if lang == "de" {
			return "Bemerkungen"
		}
	case "CSS property":
		if lang == "de" {
			return "CSS Eigenschaft"
		}
	case "since version":
		if lang == "de" {
			return "seit Version"
		}
	case "none":
		if lang == "de" {
			return "keine"
		}
	case "deprecated":
		if lang == "de" {
			return "veraltet"
		}
	case "Attribute index":
		if lang == "de" {
			return "Attribut-Index"
		}
	case "profeature tooltip":
		if lang == "de" {
			return "Dieses Feature ist nur im Pro-Paket verfügbar"
		}
		return "This feature is only available in the Pro plan"
	}
	return text
}

type sortAllAttributeNamesT []string

func (a sortAllAttributeNamesT) Len() int           { return len(a) }
func (a sortAllAttributeNamesT) Swap(i, j int)      { a[i], a[j] = a[j], a[i] }
func (a sortAllAttributeNamesT) Less(i, j int) bool { return a[i] < a[j] }

func childelemsMarkdown(lang string, cmd *commandsxml.Command) string {
	if cmd.HasHTMLChildren() {
		if lang == "de" {
			return "HTML-Elemente"
		}
		return "HTML elements"
	}

	children := cmd.Childelements()
	if len(children) == 0 {
		return "(" + translate(lang, "none") + ")"
	}

	var ret []string
	for _, c := range children {
		ret = append(ret, `<a href="../`+c.Mdlink()+`"><code>`+c.Name+`</code></a>`)
	}
	return strings.Join(ret, ", ")
}

func parentelemsMarkdown(lang string, cmd *commandsxml.Command) string {
	x := cmd.Parents(lang)
	if len(x) == 0 {
		return "(" + translate(lang, "none") + ")"
	}

	var ret []string
	for _, v := range x {
		ret = append(ret, `<a href="../`+v.Mdlink()+`"><code>`+v.Name+`</code></a>`)
	}
	return strings.Join(ret, ", ")
}

func atttypeinfoMarkdown(att *commandsxml.Attribute, lang string) string {
	atttypesDe := map[string]string{
		"boolean":                "yes oder no",
		"xpath":                  "[XPath-Ausdruck]({{% relref \"../manual/xpathref/xpath\" %}})",
		"text":                   "Text",
		"number":                 "Zahl",
		"length":                 "Längenangabe",
		"yesnolength":            "yes, no oder Längenangabe",
		"yesnonumber":            "yes, no oder eine Zahl",
		"numberorlength":         "Zahl oder Längenangabe",
		"numberlengthorstar":     "Zahl, Maßangabe oder *-Angaben",
		"topcurnumber":           "top, cur oder Zahl",
		"zerotohundred":          "0 bis 100",
		"zerohundredtwofivefive": "0 bis 100 bzw. 0 bis 255",
	}
	atttypesEn := map[string]string{
		"boolean":                "yes or no",
		"xpath":                  "[XPath expression]({{% relref \"../manual/xpathref/xpath\" %}})",
		"numberorlength":         "number or length",
		"numberlengthorstar":     "Number, length or *-numbers",
		"topcurnumber":           "top, cur or number",
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
	return strings.Join(ret, ", ")
}

// GenerateMarkdownFiles reads the commands.xml file and creates Markdown files
// for use with Hugo/Hextra in the doc/manual/content/{lang}/reference/ directory.
func GenerateMarkdownFiles(cfg *config.Config, lang string) error {
	srcpath := filepath.Join(cfg.Basedir(), "doc", "manual")
	destpath := filepath.Join(cfg.Basedir(), "doc", "manual", "content", lang, "reference")

	err := os.MkdirAll(destpath, 0755)
	if err != nil {
		return err
	}

	r, err := os.Open(filepath.Join(cfg.Basedir(), "doc", "commands-xml", "commands.xml"))
	if err != nil {
		return err
	}
	defer r.Close()

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

	funcMap := template.FuncMap{
		"translate":            translate,
		"childelemsMarkdown":   childelemsMarkdown,
		"parentelemsMarkdown":  parentelemsMarkdown,
		"atttypeinfoMarkdown":  atttypeinfoMarkdown,
	}

	mdTemplates, err := template.New("").Funcs(funcMap).ParseFiles(
		filepath.Join(srcpath, "templates", "command-md.txt"),
		filepath.Join(srcpath, "templates", "attributesref-md.txt"),
	)
	if err != nil {
		return err
	}

	// Generate attribute index
	fullpath := filepath.Join(destpath, "00attributes.md")
	f, err := os.Create(fullpath)
	if err != nil {
		return err
	}
	err = mdTemplates.ExecuteTemplate(f, "attributesref-md.txt", struct {
		Lang, AttributeNames, AttributeMap interface{}
	}{lang, allAttributeNames, allAttributes})
	f.Close()
	if err != nil {
		return err
	}

	// Generate one Markdown file per command
	commands := c.Commands()
	for i, v := range commands {
		fullpath := filepath.Join(destpath, strings.ToLower(v.Name)+".md")
		wg.Add(1)
		go buildMarkdownDoc(mdTemplates, c, v, lang, fullpath, (i+2)*10)
	}
	wg.Wait()

	return nil
}

// GenerateChangelogMarkdown reads changelog.xml and writes a Markdown file
// for use with Hugo in doc/manual/content/{lang}/manual/changelog.md.
func GenerateChangelogMarkdown(cfg *config.Config, lang string) error {
	cl, err := changelog.ReadChangelog(cfg)
	if err != nil {
		return err
	}

	destpath := filepath.Join(cfg.Basedir(), "doc", "manual", "content", lang, "manual")
	err = os.MkdirAll(destpath, 0755)
	if err != nil {
		return err
	}

	fullpath := filepath.Join(destpath, "changelog.md")
	f, err := os.Create(fullpath)
	if err != nil {
		return err
	}
	defer f.Close()

	title := "Changelog"
	if lang == "de" {
		title = "Liste der Änderungen"
	}
	fmt.Fprintf(f, "---\ntitle: \"%s\"\nweight: 900\ntype: docs\n---\n\n", title)

	ghIssueRe := regexp.MustCompile(`#(\d+)`)
	ttRepl := strings.NewReplacer(`<tt>`, "`", `</tt>`, "`")

	type release struct {
		date    time.Time
		version string
		entries []string
	}

	for _, chap := range cl.Chapter {
		fmt.Fprintf(f, "## %s\n\n", chap.Version)
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
			e = ghIssueRe.ReplaceAllString(e, `[#$1](https://github.com/speedata/publisher/issues/$1)`)
			e = ttRepl.Replace(e)
			r.entries = append(r.entries, e)
		}
		rr = append(rr, r)

		for _, r := range rr {
			if lang == "en" {
				fmt.Fprintf(f, "### %s (%s)\n\n", r.version, r.date.Format("2006-01-02"))
			} else {
				fmt.Fprintf(f, "### %s (%s)\n\n", r.version, r.date.Format("2.1.2006"))
			}
			for _, e := range r.entries {
				fmt.Fprintf(f, "- %s\n", e)
			}
			fmt.Fprintln(f)
		}
	}
	return nil
}

func buildMarkdownDoc(mdTemplates *template.Template, c *commandsxml.Commands, v *commandsxml.Command, lang string, fullpath string, weight int) {
	type sdata struct {
		Commands *commandsxml.Commands
		Command  *commandsxml.Command
		Lang     string
		Weight   int
	}

	f, err := os.Create(fullpath)
	if err != nil {
		panic(err)
	}
	err = mdTemplates.ExecuteTemplate(f, "command-md.txt", sdata{Commands: c, Command: v, Lang: lang, Weight: weight})
	if err != nil {
		fmt.Println(err)
	}
	f.Close()
	wg.Done()
}
