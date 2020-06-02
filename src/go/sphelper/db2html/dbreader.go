package db2html

import (
	"encoding/json"
	"encoding/xml"
	"fmt"
	"html/template"
	"io"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"

	"sphelper/config"
	"sphelper/fileutils"

	"github.com/alecthomas/chroma/formatters/html"
	"github.com/alecthomas/chroma/lexers"
	"github.com/alecthomas/chroma/styles"
)

var (
	repl       = strings.NewReplacer("&lt;", "<", "&gt;", ">")
	sanitizer  = strings.NewReplacer("<", "&lt;", ">", "&gt;")
	sectH      = strings.NewReplacer("sect", "h")
	coReplace  *regexp.Regexp
	assetsTrim *regexp.Regexp
	tagRemover *regexp.Regexp
	redirects  = map[string]string{
		"changelog":        "changelog",
		"colors":           "basics/colors",
		"commandline":      "commandline",
		"configuration":    "configuration",
		"css":              "advancedtopics/css",
		"cutmarks":         "advancedtopics/outputforprinter",
		"defaults":         "defaults",
		"directories":      "cookbook/automaticdirectories-marker",
		"firststeps":       "helloworld",
		"fonts":            "basics/fonts",
		"installation":     "installation",
		"lengths":          "lengthsunits",
		"luafilter":        "advancedtopics/luafilter",
		"publisherusage":   "introduction",
		"qualityassurance": "advancedtopics/qa",
		"servermode":       "advancedtopics/servermode",
		"xmlediting":       "basics/writelayoutfile",
		"xpath":            "xpathfunctions",
	}
)

func init() {
	coReplace = regexp.MustCompile(`CO\d+-(\d+)`)
	tagRemover = regexp.MustCompile(`<[^>]*>`)
	assetsTrim = regexp.MustCompile(`^(\.\./)*dbmanual/assets(.*)$`)
}

func formatSource(source, lang string) (string, error) {
	xmllexer := lexers.Get(lang)

	style := styles.Get("borland")
	if style == nil {
		style = styles.Fallback
	}

	formatter := html.New(html.WithClasses())
	// err := formatter.WriteCSS(os.Stdout, style)
	var str strings.Builder
	source = repl.Replace(source)
	iterator, err := xmllexer.Tokenise(nil, source)
	if err != nil {
		return "", err
	}

	err = formatter.Format(&str, style, iterator)
	return str.String(), err
}

func attr(s xml.StartElement, attrname string) string {
	for _, attr := range s.Attr {
		if attr.Name.Local == attrname {
			return attr.Value
		}
	}
	return ""
}

func sanitizeInput(input string) string {
	return sanitizer.Replace(input)
}

type toutputMode int

const (
	outputDiscard toutputMode = iota
	outputSave
	outputWrite
	outputPause
)

type section struct {
	Sectionlevel int
	Title        string
	Link         string
	Pagename     string
	Contents     strings.Builder
	RawContents  strings.Builder
	id           string
	Index        int
	Split        bool
	IsSearch     bool
}

func (s *section) writeString(input string) {
	s.Contents.WriteString(input)
	s.RawContents.WriteString(tagRemover.ReplaceAllString(input, ""))
}

// DocBook is the main structure for basic docbook 5 files
type DocBook struct {
	Lang           string
	Version        string
	cfg            *config.Config
	r              io.ReadSeeker
	staticmode     bool
	idfilemapping  map[string]string
	idTitlemapping map[string]string
	chain          []*section
}

// make previous and next link
func (d *DocBook) prevNext(i int) (*section, *section) {
	var p, n *section
	if i > 0 {
		p = d.chain[i-1]
	}
	if i < len(d.chain)-1 {
		n = d.chain[i+1]
	}

	return p, n
}

// make breadcrumbs for page index i
func (d *DocBook) makeBreadcrumbs(i int) []*section {
	ret := []*section{
		d.chain[0],
	}
	if i == 0 {
		return ret
	}
	prevlvl := d.chain[i].Sectionlevel
	pos := i

	lvl := d.chain[pos].Sectionlevel
	for lvl > 0 && pos > 0 {
		if lvl < prevlvl {
			ret = append(ret, d.chain[pos])
			prevlvl = lvl
		}
		if lvl == 1 {
			break
		}
		pos--
		lvl = d.chain[pos].Sectionlevel
	}

	ret = append(ret, d.chain[i])
	return ret
}

func (d *DocBook) getIds() error {
	mkLink := func(link string) string {
		return "/" + d.Lang + "/" + link
	}
	curFilename := "index.html"
	var curID string
	dirPrefix := []string{}
	titleStack := []string{}
	idStack := []string{}
	curFilenameStack := []string{}
	splitChapter := false
	sectionlevel := 0
	var sectionChain []*section
	var err error
	var outputMode toutputMode
	var chardata strings.Builder
	oStartRecording := func() {
		if outputMode != outputPause {
			chardata.Reset()
		}
		outputMode = outputSave
	}

	dec := xml.NewDecoder(d.r)
gatherid:
	for {
		tok, err := dec.Token()
		if err == io.EOF {
			break gatherid
		}
		if err != nil {
			break gatherid
		}

		switch elt := tok.(type) {
		case xml.StartElement:
			switch elt.Name.Local {
			case "book":
				d.Lang = attr(elt, "lang")
			case "preface":
				curID = attr(elt, "id")
				d.idfilemapping[curID] = curFilename
				newSec := &section{
					Sectionlevel: 1,
					Link:         mkLink(curFilename),
					Title:        d.translate(d.Lang, "Main page"),
					Pagename:     curFilename,
					id:           curID,
				}
				d.chain = append(d.chain, newSec)
			case "chapter", "appendix":
				curID = attr(elt, "id")
				idStack = append(idStack, curID)
				chaptername := strings.TrimPrefix(curID, "ch-")
				chaptername = strings.TrimPrefix(chaptername, "app-")
				chaptername = strings.TrimPrefix(chaptername, "ch-")
				splitChapter = (attr(elt, "role") == "split")
				if splitChapter || !d.staticmode {
					dirPrefix = append(dirPrefix, chaptername)
				}
				if d.staticmode {
					d.idfilemapping[curID] = chaptername + ".html"
				} else {
					d.idfilemapping[curID] = filepath.Join(chaptername, "index.html")
				}
				curFilenameStack = append(curFilenameStack, d.idfilemapping[curID])
				sectionChain = []*section{}
			case "bridgehead":
				curID = attr(elt, "id")
				if curID != "" {
					d.idfilemapping[curID] = curFilename
				}
			case "figure", "formalpara":
				curID = attr(elt, "id")
				idStack = append(idStack, curID)
				if curID != "" {
					d.idfilemapping[curID] = curFilename
				}
			case "section":
				sectionlevel++
				id := attr(elt, "id")
				idStack = append(idStack, id)
				// only the first section determines the name
				if splitChapter && sectionlevel == 1 {
					sectionName := strings.TrimPrefix(id, "ch-")
					sectionName = strings.TrimPrefix(sectionName, "cmd-")

					if d.staticmode {
						curFilename = filepath.Join(dirPrefix...)
						curFilename = filepath.Join(curFilename, sectionName) + ".html"
					} else {
						curFilename = filepath.Join(dirPrefix...)
						curFilename = filepath.Join(curFilename, sectionName, "index.html")
					}
				}
				d.idfilemapping[id] = curFilename
				curFilenameStack = append(curFilenameStack, curFilename)
			case "title":
				oStartRecording()
			}
		case xml.CharData:
			switch outputMode {
			case outputDiscard:
				// ignore
			case outputWrite:
				panic("outputWrite not allowed in the first phase.")
			case outputSave:
				_, err = chardata.WriteString(sanitizeInput(string(elt.Copy())))
				if err != nil {
					panic(err)
				}
			}
		case xml.EndElement:
			switch elt.Name.Local {
			case "chapter", "appendix":
				if splitChapter || !d.staticmode {
					dirPrefix = dirPrefix[:len(dirPrefix)-1]
				}
				thistitle := titleStack[len(titleStack)-1]
				titleStack = titleStack[:len(titleStack)-1]
				thisid := idStack[len(idStack)-1]
				idStack = idStack[:len(idStack)-1]
				tmp := curFilenameStack[len(curFilenameStack)-1]
				newSec := &section{
					Title:        thistitle,
					Sectionlevel: 1,
					Link:         mkLink(tmp),
					Pagename:     tmp,
					id:           thisid,
					Split:        splitChapter,
				}
				d.chain = append(d.chain, newSec)

				d.chain = append(d.chain, sectionChain...)
				curFilenameStack = curFilenameStack[:len(curFilenameStack)-1]
			case "bridgehead":
			case "figure", "formalpara":
				thistitle := titleStack[len(titleStack)-1]
				titleStack = titleStack[:len(titleStack)-1]
				thisid := idStack[len(idStack)-1]
				idStack = idStack[:len(idStack)-1]
				d.idTitlemapping[thisid] = thistitle
			case "section":
				// There are many level 1 sections in the reference appendix, and everyone
				// should get its own file, so we must detect that we are on a level 1 section
				thistitle := titleStack[len(titleStack)-1]
				titleStack = titleStack[:len(titleStack)-1]
				thisid := idStack[len(idStack)-1]
				idStack = idStack[:len(idStack)-1]
				d.idTitlemapping[thisid] = thistitle

				tmp := curFilenameStack[len(curFilenameStack)-1]

				if sectionlevel == 1 && splitChapter {
					newSec := &section{
						Title:        thistitle,
						Sectionlevel: 2,
						Link:         mkLink(tmp),
						Pagename:     tmp,
						id:           thisid,
					}
					sectionChain = append(sectionChain, newSec)
				}
				sectionlevel--
				curFilenameStack = curFilenameStack[:len(curFilenameStack)-1]
			case "title":
				thistitle := chardata.String()
				titleStack = append(titleStack, thistitle)
			}

		}

	}
	return err
}

func (d *DocBook) collectContents() error {
	_, err := d.r.Seek(0, io.SeekStart)
	if err != nil {
		return err
	}
	type listtype int

	const (
		lItemize listtype = iota
		lEnumerate
		lVarlist
	)
	listlevel := []listtype{}

	idIndex := make(map[string]*section)
	filenamePagemap := make(map[string]*section)
	for i, page := range d.chain {
		idIndex[page.id] = page
		filenamePagemap[page.Pagename] = page
		page.Index = i
	}

	var figureid string
	var figuretitle string
	var imagedata string
	var phrase string
	var contentwidth string
	var brideheadLevel string
	var calloutcounter int
	var writeCalloutItem bool
	var inFigure bool
	var inThead bool

	var curpage *section
	var attribution string
	var simpara []string
	var sectionid string
	var headinglevel int
	var titlecounter int
	var collectSimPara bool
	var omitP bool
	var programlistingLanguage string
	var chardata strings.Builder
	var outputMode toutputMode
	oStartRecording := func() {
		if outputMode != outputPause {
			chardata.Reset()
		}
		outputMode = outputSave
	}

	dec := xml.NewDecoder(d.r)
getContents:
	for {
		tok, err := dec.Token()
		if err == io.EOF {
			break getContents
		}
		if err != nil {
			break getContents
		}

		switch elt := tok.(type) {
		case xml.StartElement:
			switch elt.Name.Local {
			case "anchor", "book", "textobject", "tgroup", "colspec", "varlistentry":
				// ignore
			case "attribution":
				oStartRecording()
			case "blockquote":
				collectSimPara = true
			case "bridgehead":
				brideheadLevel = sectH.Replace(attr(elt, "renderas"))
				oStartRecording()
			case "callout":
				calloutcounter++
				curpage.writeString("\n")
				writeCalloutItem = true
			case "calloutlist":
				calloutcounter = 0
			case "co":
				thisid := attr(elt, "id")
				conumRaw := coReplace.ReplaceAllString(thisid, "$1")
				conum, err := strconv.Atoi(conumRaw)
				if err != nil {
					return err
				}
				chardata.WriteRune(rune('①' + conum - 1))
			case "emphasis":
				class := ""
				if attr(elt, "role") == "strong" {
					class = ` class="strong"`
				}
				chardata.WriteString(fmt.Sprintf(`<em%s>`, class))
			case "entry":
				oStartRecording()
				collectSimPara = true
				simpara = simpara[:0]
				if inThead {
					curpage.writeString(`<th>`)
				} else {
					curpage.writeString(`<td>`)
				}
			case "figure":
				figureid = attr(elt, "id")
				inFigure = true
			case "formalpara":
				var thisid string
				if id := attr(elt, "id"); id != "" {
					thisid = fmt.Sprintf(" id=%q", id)
				}
				omitP = true
				curpage.writeString(fmt.Sprintf(`<div%s class="imageblock"><div class="content">`, thisid))
				inFigure = true
			case "info":
				dec.Skip()
			case "informaltable":
				curpage.writeString("\n")
				curpage.writeString(`<table>`)
			case "itemizedlist":
				listlevel = append(listlevel, lItemize)
				curpage.writeString("\n<ul>")
				omitP = true
			case "chapter", "appendix", "preface":
				id := attr(elt, "id")
				sectionid = id
				if cp, ok := idIndex[id]; ok {
					curpage = cp
					titlecounter = 0
				}
				if attr(elt, "role") == "split" {
					headinglevel = 0
				} else {
					headinglevel = 1
				}
			case "informalfigure":
				imagedata = ""
				contentwidth = ""
				phrase = ""
			case "imagedata":
				imagedata = attr(elt, "fileref")
				if cw := attr(elt, "contentwidth"); cw != "" {
					contentwidth = cw
				} else {
					contentwidth = attr(elt, "width")
				}
			case "imageobject":
				// ignore
			case "indexterm":
				dec.Skip()
			case "link":
				var href string
				// href := attr(elt, "href")
				linkend := attr(elt, "linkend")
				if linkend != "" {
					page := d.idfilemapping[linkend]
					page = "/" + d.Lang + "/" + page

					href = d.linkToPage(page, *curpage)
				} else {
					href = attr(elt, "href")
				}

				chardata.WriteString(fmt.Sprintf(`<a href="%s">`, href))
			case "literal":
				if outputMode == outputSave {
					chardata.WriteString(`<code>`)
				} else {
					curpage.writeString(`<code>`)
				}
			case "listitem":
				curpage.writeString("\n")
				curlist := listlevel[len(listlevel)-1]
				switch curlist {
				case lVarlist:
					collectSimPara = false
					curpage.writeString(`<dd>`)
				case lItemize:
					curpage.writeString(`<li>`)
				}
			case "mediaobject":
				// ignore
			case "orderedlist":
				listlevel = append(listlevel, lEnumerate)
				curpage.writeString("\n<ol>")
				omitP = true
			case "phrase":
				oStartRecording()
			case "programlisting":
				programlistingLanguage = attr(elt, "language")
				// we need to pass the listing through the formatter
				oStartRecording()
			case "row":
				curpage.writeString("\n")
				curpage.writeString(`<tr>`)
			case "para", "simpara":
				oStartRecording()
				if writeCalloutItem {
					chardata.WriteString(string('①' + calloutcounter - 1))
					chardata.WriteString("\n")
					writeCalloutItem = false
				}
			case "section":
				id := attr(elt, "id")
				sectionid = id
				if cp, ok := idIndex[id]; ok {
					curpage = cp
					titlecounter = 0
				}
				headinglevel++
			case "subscript":
				chardata.WriteString(`<sub>`)
			case "superscript":
				chardata.WriteString(`<sup>`)
			case "thead":
				inThead = true
				curpage.writeString(`<thead>`)
			case "tbody":
				inThead = false
				curpage.writeString(`<tbody>`)
			case "term":
				curpage.writeString("\n")
				curpage.writeString(`<dt>`)
				outputMode = outputWrite
			case "tip", "warning":
				collectSimPara = true
				curpage.writeString(`<div class="admonitionblock tip">
				<table>
				<tbody>
					<tr><td class="icon"><i class="fa fa-2x fa-lightbulb-o" aria-hidden="true"></i></td>
				<td class="content">`)
			case "screen", "literallayout":
				curpage.writeString("\n")
				curpage.writeString(`<pre><code>`)
				outputMode = outputWrite
			case "title":
				oStartRecording()
			case "variablelist":
				curpage.writeString("\n")
				curpage.writeString(`<dl>`)
				listlevel = append(listlevel, lVarlist)
			case "xref":
				linkend := attr(elt, "linkend")
				if page, ok := idIndex[linkend]; ok {
					chardata.WriteString(fmt.Sprintf(`<a href="%s">%s</a>`, d.linkToPage(page.Link, *curpage), page.Title))
				} else {
					if fn, ok := d.idfilemapping[linkend]; ok {
						if page, ok := filenamePagemap[fn]; ok {
							title := page.Title
							if t, ok := d.idTitlemapping[linkend]; ok {
								title = t
							}
							chardata.WriteString(fmt.Sprintf(`<a href="%s#%s">%s</a>`, d.linkToPage(page.Link, *curpage), linkend, title))
						} else {
							panic("could not get filename mapping for " + fn)
						}
					} else {
						panic("could not resolve " + linkend)
					}

				}
			default:
				fmt.Println(elt.Name.Local)
			}
		case xml.CharData:
			switch outputMode {
			case outputDiscard:
				// ignore
			case outputWrite:
				curpage.writeString(sanitizeInput(string(elt.Copy())))
			case outputSave:
				_, err = chardata.WriteString(sanitizeInput(string(elt.Copy())))
				if err != nil {
					panic(err)
				}
			}
		case xml.EndElement:
			switch elt.Name.Local {
			case "attribution":
				attribution = chardata.String()
			case "blockquote":
				curpage.writeString(fmt.Sprintf(`<div class="quoteblock"><blockquote>%s</blockquote><div class="attribution">— %s</div></div>`, strings.Join(simpara, ""), attribution))
				collectSimPara = false
			case "bridgehead":
				curpage.writeString("\n")
				curpage.writeString(fmt.Sprintf(`<%s>%s</%s>`, brideheadLevel, chardata.String(), brideheadLevel))
				curpage.writeString("\n")
				chardata.Reset()
			case "emphasis":
				chardata.WriteString(`</em>`)
			case "entry":
				curpage.writeString(chardata.String())
				// curpage.writeString(strings.Join(simpara, ""))
				if inThead {
					curpage.writeString(`</th>`)
				} else {
					curpage.writeString(`</td>`)
				}
				collectSimPara = false
			case "figure":
				var wd string
				if contentwidth != "" {
					wd = fmt.Sprintf(` width="%s"`, contentwidth)
				}
				var alt string
				if phrase != "" {
					alt = fmt.Sprintf(` alt="%s"`, phrase)
				}
				imagedata = assetsTrim.ReplaceAllString(imagedata, "$2")
				src := d.linkToPage("/static/"+imagedata, *curpage)

				curpage.writeString(fmt.Sprintf(`<div id="%s" class="imageblock">
				<div class="content">
				<img src="%s" %s%s>
				</div>
				<div class="caption">%s</div>
				</div>`, figureid, src, alt, wd, figuretitle))
				inFigure = false
			case "formalpara":
				curpage.writeString(fmt.Sprintf(`</div><div class="caption">%s</div></div>`, figuretitle))
				inFigure = false
				omitP = false
			case "informalfigure":
				var wd string
				if contentwidth != "" {
					wd = fmt.Sprintf(` width="%s"`, contentwidth)
				}
				var alt string
				if phrase != "" {
					alt = fmt.Sprintf(` alt="%s"`, phrase)
				}
				imagedata = assetsTrim.ReplaceAllString(imagedata, "$2")
				src := d.linkToPage("/static/"+imagedata, *curpage)
				curpage.writeString(fmt.Sprintf("\n<img src='%s'%s%s>", src, wd, alt))
			case "itemizedlist":
				curlist := listlevel[len(listlevel)-1]
				listlevel = listlevel[:len(listlevel)-1]
				if curlist != lItemize {
					panic("stack top is not itemize list")
				}
				curpage.writeString("\n</ul>")
				omitP = false
			case "link":
				chardata.WriteString(`</a>`)
			case "literal":
				if outputMode == outputSave {
					chardata.WriteString(`</code>`)
				} else {
					curpage.writeString(`</code>`)
				}
			case "listitem":
				curlist := listlevel[len(listlevel)-1]
				switch curlist {
				case lVarlist:
					curpage.writeString(`</dd>`)
				case lItemize:
					chardata.WriteString(`</li>`)
					curpage.writeString(chardata.String())
				}
				curpage.writeString("\n")
			case "orderedlist":
				curlist := listlevel[len(listlevel)-1]
				listlevel = listlevel[:len(listlevel)-1]
				if curlist != lEnumerate {
					panic("stack top is not ordered list")
				}
				curpage.writeString("\n</ol>")
				omitP = false
			case "phrase":
				phrase = chardata.String()
				chardata.Reset()
			case "programlisting":
				src, err := formatSource(chardata.String(), programlistingLanguage)
				if err != nil {
					return err
				}
				curpage.writeString(fmt.Sprintf(`<div class="highlight"><pre class="chroma"><code class="language-%s">%s</code></pre></div>`, programlistingLanguage, src))
				chardata.Reset()
			case "row":
				curpage.writeString(`</tr>`)
			case "para", "simpara":
				if collectSimPara {
					simpara = append(simpara, chardata.String())
				} else {
					if omitP {
						curpage.writeString(chardata.String())
					} else {
						curpage.writeString("\n")
						curpage.writeString(fmt.Sprintf("<p>%s</p>", chardata.String()))
					}
					simpara = simpara[:0]
					chardata.Reset()
				}
			case "screen", "literallayout":
				curpage.writeString(`</code></pre>`)
				curpage.writeString("\n")
			case "section":
				headinglevel--
			case "subscript":
				chardata.WriteString(`</sub>`)
			case "superscript":
				chardata.WriteString(`</sup>`)
			case "informaltable":
				curpage.writeString(`</table>`)
				curpage.writeString("\n")
			case "tip", "warning":
				curpage.writeString(strings.Join(simpara, ""))
				curpage.writeString(`</td>
				</tr>
				</tbody></table>
				</div>`)
				collectSimPara = false
			case "tbody":
				curpage.writeString(`<tbody>`)
				inThead = false
			case "thead":
				curpage.writeString(`<thead>`)
				inThead = false
			case "term":
				curpage.writeString("\n")
				curpage.writeString(`</dt>`)
			case "title":
				if inFigure {
					figuretitle = chardata.String()
				} else {
					var thisid string
					if sectionid != "" {
						thisid = fmt.Sprintf(" id=%q", sectionid)
						sectionid = ""
					}
					curpage.writeString("\n")
					lvl := headinglevel
					if headinglevel == 0 {
						lvl = 1
					}
					curpage.writeString(fmt.Sprintf(`<h%d%s>%s</h%d>`, lvl, thisid, chardata.String(), lvl))
					curpage.writeString("\n")
					if curpage.Index == 0 && titlecounter == 0 && d.Lang == "de" {
						curpage.writeString(`<div class="epub"><p>Neu! Jetzt auch als ebook</p><a href="https://doc.speedata.de/publisher/de/publisherhandbuch.epub">Download</a></div>`)
						curpage.writeString("\n")
					}
					titlecounter++

				}
				chardata.Reset()
			case "variablelist":
				curpage.writeString("\n")
				curpage.writeString(`</dl>`)
				listlevel = listlevel[:len(listlevel)-1]
			}
		}
	}
	return nil
}

func (d *DocBook) translate(lang, text string) string {
	if lang == "en" {
		return text
	}
	switch text {
	case "manual":
		return "Handbuch"
	case "Search":
		return "Suche"
	case "Results":
		return "Ergebnisse"
	case "No results":
		return "Keine Ergebnisse"
	case "Main page":
		return "Startseite"
	case "Search manual":
		return "Handbuch durchsuchen"
	case "let's surpass the mainstream":
		return "Überholen wir den Mainstream"
	case "More information":
		return "Weiterführende Links"
	case "Website":
		return "Webseite"
	default:
		panic(fmt.Sprintf("not translated: %q", text))
	}
}

func (d *DocBook) linkToPage(dest string, page section) string {
	base := path.Base(dest)
	a := path.Join("/publisher", path.Dir(page.Link))
	b := path.Join("/publisher", path.Dir(dest))
	rel, err := filepath.Rel(a, b)
	if err != nil {
		panic(err)
	}
	ret := path.Join(rel, base)
	if !d.staticmode {
		ret = strings.TrimSuffix(ret, "index.html")
		if ret == "" {
			ret = "."
		}
	}
	return ret
}

// WriteHTMLFiles creates a directory and writes all HTML and static
// files used for the documentation
func (d *DocBook) WriteHTMLFiles(basedir string) error {
	// basedir should be something like build/manual
	fmt.Println("Base directory for docbook based manual:", basedir)
	var err error
	reject := []string{".DS_Store"}
	staticDir := filepath.Join(basedir, "static")
	err = os.MkdirAll(staticDir, 0755)
	if err != nil {
		return err
	}
	templatesdir := filepath.Join(d.cfg.Basedir(), "doc", "dbmanual", "templates", "*.html")
	funcMap := template.FuncMap{
		"linkTo":    func(dest string, page section) string { return d.linkToPage(dest, page) },
		"translate": func(lang string, text string) string { return d.translate(lang, text) },
	}
	tmpl := template.Must(template.New("dummy").Funcs(funcMap).ParseGlob(filepath.Join(templatesdir)))

	assetsdir := filepath.Join(d.cfg.Basedir(), "doc", "dbmanual", "assets")
	fileutils.CpR(assetsdir, staticDir, reject...)
	langDir := filepath.Join(basedir, d.Lang)
	err = os.RemoveAll(langDir)
	if err != nil {
		return err
	}
	err = os.Mkdir(langDir, 0755)
	if err != nil {
		return err
	}
	type jsonpage struct {
		Title   string `json:"title"`
		Content string `json:"content"`
		Href    string `json:"href"`
	}
	jsonpages := make([]jsonpage, 0, len(d.chain))

	// now the search page
	var searchpath string
	var link string
	var pagename string
	if d.staticmode {
		searchpath = filepath.Join(langDir, "search.html")
		pagename = "search.html"
	} else {
		dirname := filepath.Join(langDir, "search")
		err = os.MkdirAll(dirname, 0755)
		if err != nil {
			return err
		}
		searchpath = filepath.Join(dirname, "index.html")
		pagename = "search/index.html"
	}
	link = "/" + d.Lang + "/" + pagename
	f, err := os.Create(searchpath)
	if err != nil {
		return err
	}
	searchpage := &section{
		Title:    "Search",
		Pagename: pagename,
		Link:     link,
		IsSearch: true,
	}

	for idx, page := range d.chain {
		outfile := filepath.Join(langDir, page.Pagename)
		dirname := filepath.Dir(outfile)
		err = os.MkdirAll(dirname, 0755)
		if err != nil {
			return err
		}
		f, err := os.Create(outfile)
		if err != nil {
			return err
		}
		prevsection, nextsection := d.prevNext(idx)
		var children []int
		if page.Split {
			thissectionlevel := page.Sectionlevel
			nextpage := d.chain[page.Index+1]
			for {
				children = append(children, nextpage.Index)

				if nextpage.Index+1 >= len(d.chain) {
					break
				}
				nextpage = d.chain[nextpage.Index+1]
				if nextpage.Sectionlevel == thissectionlevel {
					break
				}
			}
		}
		data := struct {
			Contents      template.HTML
			Section       *section
			Searchpage    *section
			Language      string
			Version       string
			Chain         []*section
			Breadcrumbs   []*section
			Prev          *section
			Next          *section
			Children      []int
			SearchContent template.JS
		}{
			Contents:    template.HTML(page.Contents.String()),
			Section:     page,
			Searchpage:  searchpage,
			Language:    d.Lang,
			Version:     d.Version,
			Chain:       d.chain,
			Breadcrumbs: d.makeBreadcrumbs(idx),
			Prev:        prevsection,
			Next:        nextsection,
			Children:    children,
		}
		jsonpages = append(jsonpages, jsonpage{
			Title:   page.Title,
			Content: page.RawContents.String(),
			Href:    d.linkToPage(page.Link, *searchpage),
		})
		err = tmpl.ExecuteTemplate(f, "main.html", data)
		if err != nil {
			return err
		}
		f.Close()
	}

	b, err := json.MarshalIndent(jsonpages, "", " ")
	if err != nil {
		return (err)
	}

	data := struct {
		Contents      template.HTML
		Section       *section
		Searchpage    *section
		Language      string
		Version       string
		Chain         []*section
		Breadcrumbs   []*section
		Prev          *section
		Next          *section
		Children      []int
		SearchContent template.JS
	}{
		Contents:      template.HTML("foo"),
		Section:       searchpage,
		Searchpage:    searchpage,
		Language:      d.Lang,
		Version:       d.Version,
		Chain:         d.chain,
		Breadcrumbs:   nil,
		Prev:          nil,
		Next:          nil,
		Children:      nil,
		SearchContent: template.JS(string(b)),
	}

	err = tmpl.ExecuteTemplate(f, "main.html", data)
	if err != nil {
		return err
	}
	f.Close()

	// to maintain old links / bookmarks, let's write some redirects
	if d.Lang == "en" && !d.staticmode {
		redir := `<!DOCTYPE HTML>
<html lang="en-US">
<head>
  <meta charset="UTF-8">
  <meta http-equiv="refresh" content="0; url=%s">
  <script type="text/javascript">
      window.location.href = "%s"
  </script>
  <title>Page Redirection</title>
</head>
<body> If you are not redirected automatically, follow this <a href='%s'>link to the webpage</a>.</body>
</html>
`
		descriptiondir := filepath.Join(basedir, "en", "description-en")
		if err = os.Mkdir(descriptiondir, 0755); err != nil {
			return err
		}

		for k, v := range redirects {
			dest := path.Join("/publisher/en", v)
			w, err := os.Create(filepath.Join(descriptiondir, k+".html"))
			if err != nil {
				return err
			}
			defer w.Close()
			fmt.Fprintf(w, redir, dest, dest, dest)
		}
	}

	return nil
}

// ReadFile reads a Docbook 5 file and returns a docbook object
// and an error. If staticmode is true, then links will work in the browser
// without a server.
func ReadFile(filename string, staticmode bool) (*DocBook, error) {
	fmt.Println("ReadFile", filename)
	d := &DocBook{}
	d.idfilemapping = make(map[string]string)
	d.idTitlemapping = make(map[string]string)

	f, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	d.r = f
	d.staticmode = staticmode
	d.getIds()
	if !(d.Lang == "de" || d.Lang == "en") {
		return nil, fmt.Errorf("could not recognize docbook language %q", d.Lang)
	}

	return d, nil
}

// DoThings is the entry point to create the docbook based HTML manual
func DoThings(cfg *config.Config, manualname string, sitedoc bool) error {
	d, err := ReadFile(filepath.Join(cfg.Builddir, manualname+".xml"), !sitedoc)
	if err != nil {
		return err
	}
	d.cfg = cfg
	d.Version = cfg.Publisherversion.String()

	d.collectContents()

	outdir := filepath.Join(cfg.Builddir, "manual")
	err = d.WriteHTMLFiles(outdir)
	if err != nil {
		return err
	}
	return nil

}
