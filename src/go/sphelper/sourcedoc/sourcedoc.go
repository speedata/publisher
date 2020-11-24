// Package sourcedoc creates a documentation of the Lua source code
package sourcedoc

import (
	"bufio"
	"fmt"
	"html/template"
	"log"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"strings"

	"sphelper/config"
	"sphelper/fileutils"

	"github.com/russross/blackfriday"
)

var (
	linemarker, functionmarker, linkmarker *regexp.Regexp
	escaper                                *strings.Replacer
)

func init() {
	linemarker = regexp.MustCompile(`^\s*?--- ?(.*)$`)
	functionmarker = regexp.MustCompile(`(function\s+)([^ (]*)`)
	linkmarker = regexp.MustCompile(`(\w+\.)?(\w+)#(\w+)(\(\))?`)

	escaper = strings.NewReplacer("<", "&lt;", "&", "&amp;")
}

func toMarkdown(input string) string {
	htmlFlags := 0
	htmlFlags |= blackfriday.HTML_USE_XHTML
	htmlFlags |= blackfriday.HTML_SMARTYPANTS_FRACTIONS
	htmlFlags |= blackfriday.HTML_SMARTYPANTS_LATEX_DASHES

	renderer := blackfriday.HtmlRenderer(htmlFlags, "", "")

	extensions := 0
	extensions |= blackfriday.EXTENSION_NO_INTRA_EMPHASIS
	extensions |= blackfriday.EXTENSION_TABLES
	extensions |= blackfriday.EXTENSION_FENCED_CODE
	extensions |= blackfriday.EXTENSION_AUTOLINK
	extensions |= blackfriday.EXTENSION_STRIKETHROUGH
	extensions |= blackfriday.EXTENSION_SPACE_HEADERS
	extensions |= blackfriday.EXTENSION_HEADER_IDS

	b := blackfriday.Markdown([]byte(input), renderer, extensions)
	return string(b)

}

type collection struct {
	Luafile  string
	HTMLFile string
}

type section struct {
	Doc  template.HTML
	Code template.HTML
}

type sourcedoc struct {
	cfg          *config.Config
	htmltemplate *template.Template
	srcpath      string
	outpath      string
	luafiles     []string
}

func (s *sourcedoc) genHTML(srcfile, destpath string) {
	var jumpTo []collection
	htmlnamesource := s.htmlPathFromLua(srcfile)
	for _, v := range s.luafiles {
		c := collection{
			Luafile:  strings.TrimPrefix(v, s.srcpath+"/"),
			HTMLFile: s.relLink(htmlnamesource, s.htmlPathFromLua(v)),
		}
		jumpTo = append(jumpTo, c)
	}
	os.MkdirAll(filepath.Dir(destpath), 0755)

	out, err := os.Create(destpath)
	if err != nil {
		log.Fatal(err)
	}
	defer out.Close()

	in, err := os.Open(srcfile)
	if err != nil {
		log.Fatal(err)
	}
	defer in.Close()
	scanner := bufio.NewScanner(in)
	var document []section

	var doc []string
	var code []string

	// a function to link to other source files such as publisher#mknodes()
	replace := func(in string) string {
		filebase := strings.TrimSuffix(filepath.Base(srcfile), ".lua")
		x := linkmarker.FindAllStringSubmatch(in, -1)[0]
		if len(x[1]) > 0 {
			// subdirectory
			return fmt.Sprintf(`[%s#%s%s](%s/%s.html#%s)`, x[2], x[3], x[4], strings.TrimSuffix(x[1], "."), x[2], x[3])
		}
		if x[2] == filebase {
			// this file
			return fmt.Sprintf(`[%s%s](#%s)`, x[3], x[4], x[3])
		}
		return fmt.Sprintf(`[%s#%s%s](%s.html#%s)`, x[2], x[3], x[4], x[2], x[3])
	}
	inner := func(doc []string) {
		sec := section{}
		txt := strings.Join(doc, "\n")
		// autolink function foo#bar to foo.html#bar
		txt = linkmarker.ReplaceAllStringFunc(txt, replace)
		sec.Doc = template.HTML(toMarkdown(txt))
		codelines := strings.Join(code, "\n")
		codelines = escaper.Replace(codelines)
		codelines = functionmarker.ReplaceAllString(codelines, `<a id="${2}">${1}${2}`)
		sec.Code = template.HTML(codelines)
		document = append(document, sec)
	}

	inCode := true
	for scanner.Scan() {
		line := scanner.Text()
		if linemarker.MatchString(line) {
			if inCode {
				if len(doc) > 0 || len(code) > 0 {
					inner(doc)
					doc = doc[0:0]
					code = code[0:0]
				}
				inCode = false
			}
			mdpart := linemarker.FindAllStringSubmatch(line, 1)
			line = mdpart[0][1]
			doc = append(doc, line)
		} else {
			inCode = true

			code = append(code, line)
		}
	}
	inner(doc)

	data := struct {
		Title    string
		Document []section
		Destpath string
		JumpTo   []collection
	}{
		Title:    filepath.Base(srcfile),
		Document: document,
		Destpath: filepath.Dir(destpath),
		JumpTo:   jumpTo,
	}
	err = s.htmltemplate.Execute(out, data)
	if err != nil {
		log.Fatal(err)
	}
}

// Add all lua files to the collection list. This will be the base
// for the 'jump to' list in each HTML file
func (s *sourcedoc) preprocess(srcfile string, info os.FileInfo, err error) error {
	if !info.IsDir() && strings.HasSuffix(srcfile, ".lua") {
		s.luafiles = append(s.luafiles, srcfile)
	}
	return nil
}

func (s *sourcedoc) htmlPathFromLua(src string) string {
	dest := strings.Replace(src, s.srcpath, s.outpath, 1)
	dest = strings.TrimSuffix(dest, ".lua") + ".html"
	return dest
}

// Convert Lua file to HTML file
func (s *sourcedoc) convertLuaFile(path string, info os.FileInfo, err error) error {
	if err != nil {
		log.Fatal(err)
	}
	if !info.IsDir() && strings.HasSuffix(path, ".lua") {
		dest := s.htmlPathFromLua(path)
		s.genHTML(path, dest)
	}
	return nil
}

func (s *sourcedoc) relLink(src, dest string) string {
	srcdir := filepath.Dir(src)
	destdir := filepath.Dir(dest)
	destbase := filepath.Base(dest)
	rel, err := filepath.Rel(srcdir, destdir)
	if err != nil {
		panic(err)
	}
	return path.Join(rel, destbase)
}

func (s *sourcedoc) linkToPage(src, dest string) string {
	sourcedir := filepath.Dir(filepath.Join(s.outpath, src))
	base := filepath.Base(src)
	rel, err := filepath.Rel(dest, sourcedir)
	if err != nil {
		panic(err)
	}
	return path.Join(rel, base)
}

func (s *sourcedoc) prepareDirectories() error {
	sources := filepath.Join(s.cfg.Basedir(), "doc", "sourcedoc")
	assets := filepath.Join(sources, "assets")
	images := filepath.Join(sources, "img")

	fmt.Println("Removing all files from", s.outpath)
	os.RemoveAll(s.outpath)

	var err error
	if err = fileutils.CpR(assets, s.outpath); err != nil {
		return err
	}

	if err = fileutils.CpR(images, filepath.Join(s.outpath, "img")); err != nil {
		return err
	}
	return nil
}

// GenSourcedoc reads all source files from the source dir and generate HTML files
// in outdir
func GenSourcedoc(cfg *config.Config) error {
	s := sourcedoc{
		cfg:     cfg,
		srcpath: filepath.Join(cfg.Srcdir, "lua"),
		outpath: filepath.Join(cfg.Builddir, "sourcedoc"),
	}
	var err error
	if err = s.prepareDirectories(); err != nil {
		return err
	}

	funcMap := template.FuncMap{
		"linkTo": func(dest string, page string) string { return s.linkToPage(dest, page) },
	}
	s.htmltemplate = template.Must(template.New("dummy").Funcs(funcMap).Parse(tmplatesrc))

	// First collect info about all lua files
	if err = filepath.Walk(s.srcpath, s.preprocess); err != nil {
		return err
	}

	// Then convert all the files
	if err = filepath.Walk(s.srcpath, s.convertLuaFile); err != nil {
		return err
	}
	return nil
}

var tmplatesrc string = `<!DOCTYPE html>
<html>
<head>
    <title>{{.Title}}</title>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8">
    <link rel="stylesheet" href="{{ linkTo "css/vs.css" .Destpath }}" >
    <link rel="stylesheet" href="{{ linkTo "css/gocco.css" .Destpath }}" >
    <script type="text/javascript" src="{{ linkTo "js/highlight.pack.js" .Destpath }}"></script>
    <script type="text/javascript" src="{{ linkTo "js/MathJax.js" .Destpath }}?config=TeX-AMS_HTML"></script>
    <script type="text/x-mathjax-config">
      MathJax.Hub.Config({
        extensions: ["tex2jax.js"],
        jax: ["input/TeX","output/HTML-CSS"],
        menuSettings: {zoom: "Double-Click", zscale: "300%"},
        tex2jax: {inlineMath: [["\\(","\\)"]]},
        MathMenu: {showRenderer: false},
        "HTML-CSS": {
            availableFonts: ["TeX"],
            preferredFont: "TeX",
            imageFont: null
        }
      });
    </script>
</head>
<body>
<div id="jump_to">
  	Jump To &hellip;
  	<div id="jump_wrapper">
		<div id="jump_page">
		{{ range .JumpTo }}<a class="source" href="{{.HTMLFile}}">{{.Luafile}}</a>{{ end }}
		</div>
  	</div>
</div>
<table>
<tr><td class="docs"><h1>{{.Title}}</h1></td><td class="code"></td></tr>
{{ range .Document}}<tr><td class="docs">{{ .Doc }}</td><td class="code"><pre><code class="lua">{{.Code}}</code></pre></td></tr>{{end}}</table>
<script>hljs.initHighlightingOnLoad();</script>
</body>
</html>
`
