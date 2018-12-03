package sourcedoc

import (
	"bufio"
	"fmt"
	"html/template"
	"io"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/russross/blackfriday"
	"github.com/speedata/decorate"
)

var (
	srcpath, outpath, csspath, jspath      string
	htmltemplate                           *template.Template
	luafiles                               []string
	linemarker, functionmarker, linkmarker *regexp.Regexp
)

type collection struct {
	Luafile  string
	HTMLFile string
}

type section struct {
	Doc  template.HTML
	Code template.HTML
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

func genHTML(srcfile, destpath string) {
	var jumpTo []collection
	for _, v := range luafiles {
		rel, err := filepath.Rel(filepath.Dir(srcfile), v)
		if err != nil {
			log.Fatal(err)
		}
		if rel != "." {
			c := collection{}
			luafile, err := filepath.Rel(srcpath, v)
			if err != nil {
				log.Fatal(err)
			}

			c.Luafile = luafile
			c.HTMLFile = strings.TrimSuffix(rel, ".lua") + ".html"
			jumpTo = append(jumpTo, c)
		}
	}

	os.MkdirAll(filepath.Dir(destpath), 0755)

	csslink, err := filepath.Rel(filepath.Dir(destpath), csspath)
	if err != nil {
		log.Fatal(err)
	}

	jslink, err := filepath.Rel(filepath.Dir(destpath), jspath)
	if err != nil {
		log.Fatal(err)
	}

	out, err := os.OpenFile(destpath, os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal(err)
	}
	defer out.Close()

	in, err := os.Open(srcfile)
	if err != nil {
		log.Fatal(err)
	}
	defer in.Close()
	s := bufio.NewScanner(in)
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
		} else {
			if x[2] == filebase {
				// this file
				return fmt.Sprintf(`[%s%s](#%s)`, x[3], x[4], x[3])
			} else {
				return fmt.Sprintf(`[%s#%s%s](%s.html#%s)`, x[2], x[3], x[4], x[2], x[3])
			}
		}
		return in
	}

	inCode := true
	for s.Scan() {
		line := s.Text()
		if linemarker.MatchString(line) {
			if inCode {
				if len(doc) > 0 || len(code) > 0 {
					sec := section{}
					txt := strings.Join(doc, "\n")
					// autolink function foo#bar to foo.html#bar
					txt = linkmarker.ReplaceAllStringFunc(txt, replace)
					sec.Doc = template.HTML(toMarkdown(txt))
					codelines := strings.Join(code, "\n")
					c, err := decorate.Highlight([]byte(codelines), "lua", "html")
					if err != nil {
						log.Fatal(err)
					}
					c = functionmarker.ReplaceAllString(c, `${1}<a name="${2}">${2}`)
					sec.Code = template.HTML(c)
					document = append(document, sec)
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
	sec := section{}
	txt := strings.Join(doc, "\n")
	// autolink function foo#bar to foo.html#bar
	txt = linkmarker.ReplaceAllStringFunc(txt, replace)
	sec.Doc = template.HTML(toMarkdown(txt))
	codelines := strings.Join(code, "\n")
	c, err := decorate.Highlight([]byte(codelines), "lua", "html")
	if err != nil {
		log.Fatal(err)
	}
	c = functionmarker.ReplaceAllString(c, `${1}<a name="${2}">${2}`)
	sec.Code = template.HTML(c)
	document = append(document, sec)

	data := struct {
		Title    string
		Document []section
		Csslink  string
		JSlink   string
		JumpTo   []collection
	}{
		filepath.Base(srcfile),
		document,
		csslink,
		jslink,
		jumpTo,
	}
	err = htmltemplate.Execute(out, data)
	if err != nil {
		log.Fatal(err)
	}
}

// Add all lua files to the collection list. This will be the base
// for the 'jump to' list in each HTML file
func collectJumpTo(path string, info os.FileInfo, err error) error {
	if !info.IsDir() && strings.HasSuffix(path, ".lua") {
		luafiles = append(luafiles, path)
	}
	return nil
}

// Convert Lua file to HTML file
func convertLuaFile(path string, info os.FileInfo, err error) error {
	if err != nil {
		log.Fatal(err)
	}
	if !info.IsDir() && strings.HasSuffix(path, ".lua") {
		outpath := strings.Replace(path, srcpath, outpath, 1)
		outpath = strings.TrimSuffix(outpath, ".lua") + ".html"
		genHTML(path, outpath)
	}
	return nil
}

func copyFile(src, dest string) error {
	r, err := os.Open(src)
	if err != nil {
		return err
	}
	defer r.Close()

	w, err := os.Create(dest)
	if err != nil {
		return err
	}
	defer w.Close()

	_, err = io.Copy(w, r)
	if err != nil {
		return err
	}

	return nil
}

func copyDir(dir ...string) error {
	for _, v := range dir {
		indir, err := filepath.Abs(v)
		if err != nil {
			return err
		}
		outdir := filepath.Join(outpath, filepath.Base(v))

		err = filepath.Walk(indir, func(path string, info os.FileInfo, err error) error {
			rel, err := filepath.Rel(indir, path)
			if err != nil {
				return err
			}
			if info.IsDir() {
				os.Mkdir(filepath.Join(outdir, rel), 0755)
			} else {
				err = copyFile(path, filepath.Join(outdir, rel))
				if err != nil {
					return err
				}
			}
			return nil
		})
		if err != nil {
			return err
		}
	}

	return nil
}

func GenSourcedoc(_srcpath, _outpath, _assets, _images string) error {
	linemarker = regexp.MustCompile(`^.*?--- ?(.*)$`)
	functionmarker = regexp.MustCompile(`(span class="kw">function</span>\s+)([^ (]*)`)
	linkmarker = regexp.MustCompile(`(\w+\.)?(\w+)#(\w+)(\(\))?`)
	var err error

	srcpath, err = filepath.Abs(_srcpath)
	if err != nil {
		return err
	}
	outpath, err = filepath.Abs(_outpath)
	if err != nil {
		return err
	}
	csspath, err = filepath.Abs(filepath.Join(_outpath, "css", "gocco.css"))
	if err != nil {
		return err
	}
	jspath, err = filepath.Abs(filepath.Join(_outpath, "js", "MathJax.js"))
	if err != nil {
		return err
	}

	htmltemplate, err = template.New("HTML").Parse(tmplatesrc)
	if err != nil {
		return err
	}
	fmt.Println("Removing all files from", outpath)
	os.RemoveAll(outpath)

	// First collect info about all lua files
	err = filepath.Walk(srcpath, collectJumpTo)
	if err != nil {
		return err
	}

	// Then convert all the files
	err = filepath.Walk(srcpath, convertLuaFile)
	if err != nil {
		return err
	}

	err = copyDir(filepath.Join(_assets, "css"), filepath.Join(_assets, "js"), _images)
	return err
}

var tmplatesrc string = `<!DOCTYPE html>
<html>
<head>
    <title>{{.Title}}</title>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8">
    <link rel="stylesheet" media="all" href="{{ .Csslink}}" >
    <script type="text/javascript" src="{{.JSlink}}?config=TeX-AMS_HTML"></script>
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
{{ range .Document}}<tr><td class="docs">{{ .Doc }}</td><td class="code"><pre>{{.Code}}</pre></td></tr>{{end}}</table>
</body>
</html>
`
