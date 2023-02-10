// Package db2html creates HTML files from the docbook documenation.
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

	"speedatapublisher/sphelper/config"
	"speedatapublisher/sphelper/fileutils"

	"github.com/alecthomas/chroma/formatters/html"
	"github.com/alecthomas/chroma/lexers"
	"github.com/alecthomas/chroma/styles"
)

var (
	sanitizer     = strings.NewReplacer("<", "&lt;", "LuaTeX", `LuaT<span class="TeX-e">e</span><span class="TeX-x">X</span>`)
	escaper       = strings.NewReplacer("&", "&amp;", "<", "&lt;")
	unescaper     = strings.NewReplacer("&amp;", "&", "&lt;", "<")
	sectH         = strings.NewReplacer("sect", "h")
	coReplace     = regexp.MustCompile(`CO\d+-(\d+)`)
	tagRemover    = regexp.MustCompile(`[^>]*>`)
	assetsTrim    = regexp.MustCompile(`^(\.\./)*dbmanual/assets(.*)$`)
	leadcloseWSRe = regexp.MustCompile(`^[\s\p{Zs}]+|[\s\p{Zs}]+$`)
	insideWSRe    = regexp.MustCompile(`[\s\p{Zs}]{2,}`)
	redirects     = map[string]string{
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
	rp    *strings.Replacer
	refrp *strings.Replacer
)

func init() {
	pairs := []string{
		"grundlagen", "basics",
		"einleitung", "introduction",
		"appendix-schema-assigning", "anhang-schemazuweisen",
		"images", "bildereinbinden",
		"configuration", "konfiguration",
		"commandline", "kommandozeile",
		"compatibilitylist", "kompatibilitaet",
		"cookbook-tcoinonerun", "kochbuch-verzeichnisseeindurchlauf",
		"filenames", "dateinamen",
		"defaults", "voreinstellungenimpublisher",
		"glossary", "glossar",
		"cookbook", "kochbuch",
		"hallowelt", "helloworld",
		"erstellenlayoutwerk", "writelayoutfile",
		"datenstrukturierung", "structuredatafile",
		"objekteausgeben", "outputtingobjects",
		"advancedtopics", "fortgeschrittenethemen",
		"advanced-cotrollayout", "fortgeschrittenethemen-steuerunglayout",
		"metapostgrafiken", "metapostgraphics",
		"preprocessing", "luafilter",
		"schemavalidation", "schemavalidierung",
		"servermode", "servermodus",
		"sortingdata", "sortierenvondaten",
		"pagetypes", "seitentypen",
		"outputforprinter", "druckausgabe",
		"groups", "gruppen",
		"elementattribute", "xmlstrukturen",
		"wraparoundimages", "umfliessenvonbildern",
		"troubleshooting", "tracing",
		"fileorganization", "organisationdaten",
		"colors", "farben",
		"fonts", "einbindungschriftarten",
		"rotation", "rotierenvoninahlten",
		"grid", "raster",
		"hyphenation-language", "silbentrennung-sprache",
		"outputtingobjects", "objekteausgeben",
		"structuredatafile", "datenstrukturierung",
		"textformats", "textformate",
		"writelayoutfile", "erstellenlayoutwerk",
		"textformatting", "textformatierung",
		"tables2", "tabellen2",
		"internalvariables", "internevariablen",
		"thumbindex", "griffmarken",
		"multipagepdf", "mehrseitigepdf",
		"directories-marker", "verzeichnisseerstellen-marker",
		"layoutoptimizationusinggroups", "optimierung-mit-gruppen",
		"xpathfunctions", "xpathfunktionen",
		"pagexofy", "seitexvony",
		"programming", "programmierung",
		"lengthsunits", "massangaben",
		"qa", "qualitaetssicherung",
	}
	// replace will be a, b, b, a, c, d, d, c, ...
	replace := make([]string, len(pairs)*2)
	for i := 0; i < len(pairs)/2; i++ {
		replace[i*4] = pairs[i*2+1]
		replace[i*4+1] = pairs[i*2]
		replace[i*4+2] = pairs[i*2]
		replace[i*4+3] = pairs[i*2+1]
	}
	rp = strings.NewReplacer(replace...)
	refrp = strings.NewReplacer("befehlsreferenz", "commandreference", "commandreference", "befehlsreferenz")
}

func formatSource(source, lang string) (string, error) {
	xmllexer := lexers.Get(lang)

	style := styles.Get("borland")
	if style == nil {
		style = styles.Fallback
	}

	formatter := html.New(html.WithClasses(true))
	var str strings.Builder
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
	PutInIndex   bool
}

func (s *section) WriteString(input string) (int, error) {
	var i int
	var err error
	i, err = s.Contents.WriteString(input)
	if s.PutInIndex {
		i, err = s.RawContents.WriteString(tagRemover.ReplaceAllString(unescaper.Replace(input), " "))
	}
	return i, err

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
	var chardata strings.Builder
	oStartRecording := func() {
		chardata.Reset()
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
				curFilenameStack = append(curFilenameStack, curFilename)

				d.chain = append(d.chain, newSec)
			case "chapter", "appendix":
				curID = attr(elt, "id")
				idStack = append(idStack, curID)
				chaptername := strings.TrimPrefix(curID, "ch-")
				chaptername = strings.TrimPrefix(chaptername, "app-")
				chaptername = strings.TrimPrefix(chaptername, "ch-")
				// basics, advanced topics, cookbook and reference are split chapters/appendices
				// Those should get their own prefix, such as basics/writelayoutfile.html or
				// basics/writelayoutfile/index.html
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
				// if there is a split chapter (such as basics), the first section within this chapter
				// determines the name of the current file
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
					curFilenameStack = append(curFilenameStack, curFilename)
				}
				curFilename = curFilenameStack[len(curFilenameStack)-1]
				d.idfilemapping[id] = curFilename
			case "title":
				oStartRecording()
			}
		case xml.CharData:
			_, err = chardata.WriteString(sanitizeInput(string(elt.Copy())))
			if err != nil {
				panic(err)
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
					curFilenameStack = curFilenameStack[:len(curFilenameStack)-1]
				}
				sectionlevel--
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
	var sectionRole string
	var figureid string
	var figuretitle string
	var imagedata string
	var phrase string
	var contentwidth string
	var brideheadLevel string
	var calloutcounter int
	var inFigure bool
	var inThead bool
	var verbatim bool
	var literal bool

	var curpage *section
	var attribution string
	var phraserole string
	var sectionid string
	var headinglevel int
	var titlecounter int
	var omitP bool
	var variablelistPro bool
	var programlistingLanguage string
	var chardata strings.Builder
	var curOutput io.StringWriter
	// switchOutputGetString switches back to recording to the current section
	// and returns the string that has been recorded in the mean time.
	switchOutputGetString := func() string {
		curChardata := chardata.String()
		curOutput = curpage
		chardata.Reset()
		return curChardata
	}
	oStartRecording := func() {
		chardata.Reset()
		curOutput = &chardata
	}
	oStartRecording()
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
				curOutput.WriteString(`<div class="quoteblock"><blockquote>`)
				omitP = true
			case "bridgehead":
				brideheadLevel = sectH.Replace(attr(elt, "renderas"))
				oStartRecording()
			case "callout":
				calloutcounter++
				omitP = true
				curOutput.WriteString(`<p>` + string('①'+calloutcounter-1) + ` `)
			case "calloutlist":
				calloutcounter = 0
			case "co":
				thisid := attr(elt, "id")
				conumRaw := coReplace.ReplaceAllString(thisid, "$1")
				conum, err := strconv.Atoi(conumRaw)
				if err != nil {
					return err
				}
				curOutput.WriteString(string('①' + conum - 1))
			case "emphasis":
				class := ""
				if attr(elt, "role") == "strong" {
					class = ` class="strong"`
				}
				curOutput.WriteString(fmt.Sprintf(`<em%s>`, class))
			case "entry":
				if inThead {
					curpage.WriteString(`<th>`)
				} else {
					curpage.WriteString(`<td>`)
				}
				omitP = true
			case "figure":
				figureid = attr(elt, "id")
				inFigure = true
			case "formalpara":
				var thisid string
				if id := attr(elt, "id"); id != "" {
					thisid = fmt.Sprintf(" id=%q", id)
				}
				omitP = true
				curOutput.WriteString(fmt.Sprintf(`<div%s class="imageblock"><div class="content">`, thisid))
				inFigure = true
			case "info":
				dec.Skip()
			case "informaltable":
				curOutput.WriteString("\n")
				curOutput.WriteString(`<table>`)
			case "itemizedlist":
				listlevel = append(listlevel, lItemize)
				curOutput.WriteString("\n<ul>")
				omitP = true
			case "chapter", "appendix", "preface":
				id := attr(elt, "id")
				sectionid = id
				if cp, ok := idIndex[id]; ok {
					curpage = cp
					titlecounter = 0
					switchOutputGetString()
				}
				if role := attr(elt, "role"); role == "split" {
					headinglevel = 0
				} else {
					headinglevel = 1
					if role != "" {
						sectionRole = role
					}
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
				linkend := attr(elt, "linkend")
				if linkend != "" {
					page := d.idfilemapping[linkend]
					page = "/" + d.Lang + "/" + page + "#" + linkend

					href = d.linkToPage(page, *curpage)
				} else {
					href = attr(elt, "href")
				}

				curOutput.WriteString(fmt.Sprintf(`<a href="%s">`, href))
			case "literal":
				verbatim = true
				literal = true
				curOutput.WriteString(`<code>`)
				// oStartRecording()
			case "listitem":
				curOutput.WriteString("\n")
				curlist := listlevel[len(listlevel)-1]
				switch curlist {
				case lVarlist:
					curOutput.WriteString(`<dd>`)
					omitP = false
				case lItemize, lEnumerate:
					curOutput.WriteString(`<li>`)
				}
			case "mediaobject":
				// ignore
			case "orderedlist":
				listlevel = append(listlevel, lEnumerate)
				curOutput.WriteString("\n<ol>")
				omitP = true
			case "phrase":
				if phraserole = attr(elt, "role"); phraserole != "" {
					curOutput.WriteString(fmt.Sprintf(`<span class="%s">`, phraserole))
				} else {
					oStartRecording()
				}

			case "programlisting":
				verbatim = true
				programlistingLanguage = attr(elt, "language")
				// we need to pass the listing through the formatter
				oStartRecording()
			case "quote":
				curOutput.WriteString(`“`)
			case "row":
				curOutput.WriteString("\n")
				curOutput.WriteString(`<tr>`)
			case "para", "simpara":
				if !omitP {
					curOutput.WriteString(`<p>`)
				}
			case "section":
				id := attr(elt, "id")
				sectionid = id
				if cp, ok := idIndex[id]; ok {
					curpage = cp
					titlecounter = 0
				}
				if role := attr(elt, "role"); role != "" {
					sectionRole = role
				}

				headinglevel++
			case "subscript":
				curOutput.WriteString(`<sub>`)
			case "superscript":
				curOutput.WriteString(`<sup>`)
			case "thead":
				inThead = true
				curOutput.WriteString(`<thead>`)
			case "tbody":
				inThead = false
				curOutput.WriteString(`<tbody>`)
			case "term":
				curOutput.WriteString("\n")
				curOutput.WriteString(`<dt>`)
			case "tip", "warning":
				curOutput.WriteString(`<div class="admonitionblock tip">
				<table>
				<tbody>
					<tr><td class="icon"><i class="fa fa-2x fa-lightbulb-o" aria-hidden="true"></i></td>
				<td class="content">`)
				omitP = true
			case "screen", "literallayout":
				verbatim = true
				curOutput.WriteString("\n")
				curOutput.WriteString(`<pre><code>`)
				oStartRecording()
			case "title":
				oStartRecording()
			case "variablelist":
				if attr(elt, "role") == "profeature" {
					variablelistPro = true
				}
				curOutput.WriteString("\n")
				curOutput.WriteString(`<dl>`)
				listlevel = append(listlevel, lVarlist)
			case "xref":
				linkend := attr(elt, "linkend")
				if page, ok := idIndex[linkend]; ok {
					curOutput.WriteString(fmt.Sprintf(`<a href="%s">%s</a>`, d.linkToPage(page.Link, *curpage), page.Title))
				} else {
					if fn, ok := d.idfilemapping[linkend]; ok {
						if page, ok := filenamePagemap[fn]; ok {
							title := page.Title
							if t, ok := d.idTitlemapping[linkend]; ok {
								title = t
							}
							curOutput.WriteString(fmt.Sprintf(`<a href="%s#%s">%s</a>`, d.linkToPage(page.Link, *curpage), linkend, title))
						} else {
							panic("could not get filename mapping for " + fn)
						}
					} else {
						panic("could not resolve " + linkend + " " + curpage.Pagename)
					}

				}
			default:
				fmt.Println(elt.Name.Local)
			}
		case xml.CharData:
			input := string(elt.Copy())
			if !verbatim {
				input = sanitizeInput(input)
			}
			if literal {
				input = escaper.Replace(input)
			}
			curOutput.WriteString(input)
		case xml.EndElement:
			switch elt.Name.Local {
			case "attribution":
				attribution = switchOutputGetString()
			case "blockquote":
				curOutput.WriteString(fmt.Sprintf(`</blockquote><div class="attribution">— %s</div></div>`, attribution))
				omitP = false
			case "bridgehead":
				src := switchOutputGetString()
				curOutput.WriteString("\n")
				curOutput.WriteString(fmt.Sprintf(`<%s>%s</%s>`, brideheadLevel, src, brideheadLevel))
				curOutput.WriteString("\n")
			case "callout":
				curOutput.WriteString("</p>\n")
			case "calloutlist":
				omitP = false
			case "emphasis":
				curOutput.WriteString(`</em>`)
			case "entry":
				omitP = false
				if inThead {
					curOutput.WriteString(`</th>`)
				} else {
					curOutput.WriteString(`</td>`)
				}
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

				curOutput.WriteString(fmt.Sprintf(`<div id="%s" class="imageblock">
				<div class="content">
				<a href="%s" class="glightbox"><img src="%s" %s%s></a>
				</div>
				<div class="caption">%s</div>
				</div>`, figureid, src, src, alt, wd, figuretitle))
				inFigure = false
			case "formalpara":
				curOutput.WriteString(fmt.Sprintf(`</div><div class="caption">%s</div></div>`, figuretitle))
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
				curOutput.WriteString(fmt.Sprintf("\n<a href='%s' class='glightbox'><img src='%s'%s%s></a>", src, src, wd, alt))
			case "itemizedlist":
				curlist := listlevel[len(listlevel)-1]
				listlevel = listlevel[:len(listlevel)-1]
				if curlist != lItemize {
					panic("stack top is not itemize list")
				}
				curOutput.WriteString("\n</ul>")
				if len(listlevel) == 0 {
					omitP = false
				}
			case "link":
				curOutput.WriteString(`</a>`)
			case "literal":
				curOutput.WriteString(`</code>`)
				verbatim = false
				literal = false
			case "listitem":
				curlist := listlevel[len(listlevel)-1]
				switch curlist {
				case lVarlist:
					curOutput.WriteString(`</dd>`)
				case lItemize, lEnumerate:
					curOutput.WriteString(`</li>`)
				}
				curOutput.WriteString("\n")
			case "orderedlist":
				curlist := listlevel[len(listlevel)-1]
				listlevel = listlevel[:len(listlevel)-1]
				if curlist != lEnumerate {
					panic("stack top is not ordered list")
				}
				curOutput.WriteString("\n</ol>")
				if len(listlevel) == 0 {
					omitP = false
				}
			case "phrase":
				if phraserole != "" {
					curOutput.WriteString(`</span>`)
				} else {
					phrase = switchOutputGetString()
				}
			case "programlisting":
				verbatim = false
				cd := switchOutputGetString()
				src, err := formatSource(cd, programlistingLanguage)
				if err != nil {
					return err
				}
				curOutput.WriteString(fmt.Sprintf(`<div class="highlight"><pre class="chroma"><code class="language-%s">%s</code></pre></div>`, programlistingLanguage, src))
			case "quote":
				curOutput.WriteString(`”`)
			case "row":
				curOutput.WriteString(`</tr>`)
			case "para", "simpara":
				if !omitP {
					curOutput.WriteString(`</p>`)
				}
			case "screen", "literallayout":
				verbatim = false
				cd := switchOutputGetString()
				curOutput.WriteString(escaper.Replace(cd))
				curOutput.WriteString(`</code></pre>`)
				curOutput.WriteString("\n")
			case "section":
				headinglevel--
			case "subscript":
				curOutput.WriteString(`</sub>`)
			case "superscript":
				curOutput.WriteString(`</sup>`)
			case "informaltable":
				curOutput.WriteString(`</table>`)
				curOutput.WriteString("\n")
			case "tip", "warning":
				curOutput.WriteString(`</td>
				</tr>
				</tbody></table>
				</div>`)
				omitP = false
			case "tbody":
				curOutput.WriteString(`<tbody>`)
				inThead = false
			case "thead":
				curOutput.WriteString(`<thead>`)
				inThead = false
			case "term":
				proLink := ""
				if variablelistPro {
					proLink = fmt.Sprintf(`<a href="https://www.speedata.de/%s" class="prolink" data-tooltip="%s" data-flow="top">PRO</a>`, d.translate(d.Lang, "en/product/prices/"), d.translate(d.Lang, "Available in the PRO plan"))
					variablelistPro = false
				}
				curOutput.WriteString(fmt.Sprintf("%s\n", proLink))
				curOutput.WriteString(`</dt>`)
			case "title":
				title := switchOutputGetString()
				if title == "Child elements" || title == "Kindelemente" || title == "Parent elements" || title == "Elternelemente" {
					curpage.PutInIndex = false
				} else {
					curpage.PutInIndex = true
				}
				if inFigure {
					figuretitle = title
				} else {
					var thisid string
					if sectionid != "" {
						thisid = fmt.Sprintf(" id=%q", sectionid)
						sectionid = ""
					}
					curOutput.WriteString("\n")
					lvl := headinglevel
					if headinglevel == 0 {
						lvl = 1
					}
					proLink := ""
					if sectionRole == "profeature" {
						proLink = fmt.Sprintf(`<a href="https://www.speedata.de/%s" class="prolink" data-tooltip="%s" data-flow="top">PRO</a>`, d.translate(d.Lang, "en/product/prices/"), d.translate(d.Lang, "Available in the PRO plan"))
						sectionRole = ""
					}

					curOutput.WriteString(fmt.Sprintf(`<h%d%s>%s%s</h%d>`, lvl, thisid, title, proLink, lvl))
					curOutput.WriteString("\n")
					if curpage.Index == 0 && titlecounter == 0 {
						switch d.Lang {
						case "en":
							curOutput.WriteString(`<div class="epub"><p>Also as ebook</p><a href="https://doc.speedata.de/publisher/en/publishermanual.epub">Download</a></div>`)
						case "de":
							curOutput.WriteString(`<div class="epub"><p>Auch als ebook</p><a href="https://doc.speedata.de/publisher/de/publisherhandbuch.epub">Download</a></div>`)
						}
						curOutput.WriteString("\n")
					}
					titlecounter++

				}
				chardata.Reset()
				omitP = false
			case "variablelist":
				curOutput.WriteString("\n")
				curOutput.WriteString(`</dl>`)
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
	case "Available in the PRO plan":
		return "Verfügbar im PRO-Paket"
	case "en/product/prices/":
		return "de/produkt/preise/"
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

func (d *DocBook) otherManual(page section) string {
	var ret string
	// simple replaceemnt in command reference
	linkparts := strings.Split(page.Link, "/")
	for i, b := range linkparts {
		switch b {
		case "de":
			linkparts[i] = "en"
		case "en":
			linkparts[i] = "de"
		default:
			if strings.Contains(page.Link, "befehlsreferenz") || strings.Contains(page.Link, "commandreference") {
				linkparts[i] = refrp.Replace(b)
			} else {
				linkparts[i] = rp.Replace(b)
			}
		}
	}
	ret = d.linkToPage(strings.Join(linkparts, "/"), page)
	return ret
}

func (d *DocBook) genNavi(thissection *section, navi bool) string {
	prevSecLevel := 0
	var nav strings.Builder
	for _, page := range d.chain {
		if page.Sectionlevel < prevSecLevel {
			nav.WriteString("</li></ul>")
		}
		if page.Sectionlevel > prevSecLevel {
			if prevSecLevel == 0 && navi {
				nav.WriteString("<ul class='navi2mobile'>")
			} else {
				nav.WriteString("<ul>")
			}
		} else {
			nav.WriteString("</li>\n")
		}
		nav.WriteString(fmt.Sprintf(`<li><a href="%s">%s</a>`, d.linkToPage("/"+d.Lang+"/"+page.Pagename, *thissection), page.Title))
		prevSecLevel = page.Sectionlevel
	}
	nav.WriteString("</li></ul></li></ul>")
	return nav.String()
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
		"linkTo":      func(dest string, page section) string { return d.linkToPage(dest, page) },
		"translate":   func(lang string, text string) string { return d.translate(lang, text) },
		"otherManual": func(page section) string { return d.otherManual(page) },
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
	// jsonpages is an array containing search contents
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
			Navi          template.HTML
			NaviMobile    template.HTML
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
			Navi:        template.HTML(d.genNavi(page, false)),
			NaviMobile:  template.HTML(d.genNavi(page, true)),
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
		contents := leadcloseWSRe.ReplaceAllString(page.RawContents.String(), "")
		contents = insideWSRe.ReplaceAllString(contents, " ")
		title := page.Title

		if strings.Contains(page.Link, "befehlsreferenz") || strings.Contains(page.Link, "commandreference") {
			title += " (ref)"
		}
		jsonpages = append(jsonpages, jsonpage{
			Title:   title,
			Content: contents,
			Href:    d.linkToPage(page.Link, *searchpage),
		})
		err = tmpl.ExecuteTemplate(f, "main.html", data)
		if err != nil {
			return err
		}
		f.Close()
	}

	// b is the search contents
	b, err := json.MarshalIndent(jsonpages, "", " ")
	if err != nil {
		return (err)
	}

	data := struct {
		Navi          template.HTML
		NaviMobile    template.HTML
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
		Navi:          template.HTML(d.genNavi(searchpage, false)),
		NaviMobile:    template.HTML(d.genNavi(searchpage, true)),
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
	// getIds sets d.Lang
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
