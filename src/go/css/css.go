package css

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"golang.org/x/net/html"

	"internal/github-css/scanner"

	"github.com/PuerkitoBio/goquery"
)

type tokenstream []*scanner.Token

type qrule struct {
	Key   tokenstream
	Value tokenstream
}

type sBlock struct {
	Name            string      // only set if this is an at-rule
	ComponentValues tokenstream // the "selector"
	ChildAtRules    []*sBlock   // the block's at-rules, if any
	Blocks          []*sBlock   // the at-rule's blocks, if any
	Rules           []qrule     // the key-value pairs
}

type cssPage struct {
	pagearea   map[string][]qrule
	attributes []html.Attribute
	papersize  string
}

// CSS has all the information
type CSS struct {
	document     *goquery.Document
	Stylesheet   []sBlock
	Fontfamilies map[string]FontFamily
	Pages        map[string]cssPage
}

// FontSource has URL/file names for fonts
type FontSource struct {
	Local string
	URL   string
}

func (f FontSource) String() string {
	ret := []string{}
	if f.Local != "" {
		ret = append(ret, fmt.Sprintf(`["local"] = %q`, f.Local))
	}
	if f.URL != "" {
		ret = append(ret, fmt.Sprintf("url = %q", f.URL))
	}
	return "{" + strings.Join(ret, ",") + "}"
}

// A FontFamily consists of the four standard shapes: regular, bold, italic, bolditalic
type FontFamily struct {
	Regular    FontSource
	Bold       FontSource
	Italic     FontSource
	BoldItalic FontSource
}

var cssdefaults = `
li              { display: list-item; padding-inline-start: 40pt; }
head            { display: none }
table           { display: table }
tr              { display: table-row }
thead           { display: table-header-group }
tbody           { display: table-row-group }
tfoot           { display: table-footer-group }
td, th          { display: table-cell }
caption         { display: table-caption }
th              { font-weight: bold; text-align: center }
caption         { text-align: center }
body            { margin: 0pt; font-family: sans-serif; font-size: 10pt; line-height: 1.2; hyphens: auto; }
h1              { font-size: 2em; margin: .67em 0 }
h2              { font-size: 1.5em; margin: .75em 0 }
h3              { font-size: 1.17em; margin: .83em 0 }
h4, p,
blockquote, ul,
fieldset, form,
ol, dl, dir,
h5              { font-size: 1em; margin: 1.5em 0 }
h6              { font-size: .75em; margin: 1.67em 0 }
h1, h2, h3, h4,
h5, h6, b,
strong          { font-weight: bold }
blockquote      { margin-left: 40px; margin-right: 40px }
i, cite, em,
var, address    { font-style: italic }
pre, tt, code,
kbd, samp       { font-family: monospace }
pre             { white-space: pre; margin: 1em 0px; }
button, textarea,
input, select   { display: inline-block }
big             { font-size: 1.17em }
small, sub, sup { font-size: .83em }
sub             { vertical-align: sub }
sup             { vertical-align: super }
table           { border-spacing: 2pt; }
thead, tbody,
tfoot           { vertical-align: middle }
td, th, tr      { vertical-align: inherit }
s, strike, del  { text-decoration: line-through }
hr              { border: 1px inset }
ol, ul, dir, dd { padding-left: 20pt }
ol              { list-style-type: decimal }
ul              { list-style-type: disc }
ol ul, ul ol,
ul ul, ol ol    { margin-top: 0; margin-bottom: 0 }
u, ins          { text-decoration: underline }
center          { text-align: center }
`

// :link           { text-decoration: underline }

// Return the position of the matching closing brace "}"
func findClosingBrace(toks tokenstream) int {
	level := 1
	for i, t := range toks {
		if t.Type == scanner.Delim {
			switch t.Value {
			case "{":
				level++
			case "}":
				level--
				if level == 0 {
					return i + 1
				}
			}
		}
	}
	return len(toks)
}

// fixupComponentValues changes DELIM[.] + IDENT[foo] to IDENT[.foo]
func fixupComponentValues(toks tokenstream) tokenstream {
	toks = trimSpace(toks)
	var combineNext bool
	for i := 0; i < len(toks)-1; i++ {
		combineNext = false
		if toks[i].Type == scanner.Delim && toks[i].Value == "." && toks[i+1].Type == scanner.Ident {
			toks[i+1].Value = "." + toks[i+1].Value
			combineNext = true
		} else if toks[i].Type == scanner.Delim && toks[i].Value == ":" && toks[i+1].Type == scanner.Ident {
			toks[i+1].Value = ":" + toks[i+1].Value
			combineNext = true
		}
		if combineNext {
			toks = append(toks[:i], toks[i+1:]...)
			i++
		}
	}
	return toks
}

func trimSpace(toks tokenstream) tokenstream {
	i := 0
	for {
		if i == len(toks) {
			break
		}
		if t := toks[i]; t.Type == scanner.S {
			i++
		} else {
			break
		}
	}
	toks = toks[i:]
	return toks
}

// Get the contents of a block. The name (in case of an at-rule)
// and the selector will be added later on
func consumeBlock(toks tokenstream, inblock bool) sBlock {
	// This is the whole block between the opening { and closing }
	if len(toks) <= 1 {
		return sBlock{}
	}
	b := sBlock{}
	if len(toks) == 0 {
		return b
	}
	i := 0
	// we might start with whitespace, skip it
	for {
		if i == len(toks) {
			break
		}
		if t := toks[i]; t.Type == scanner.S {
			i++
		} else {
			break
		}
	}
	start := i
	colon := 0
	for {
		if i == len(toks) {
			break
		}
		// There are only two cases: a key-value rule or something with
		// curly braces
		if t := toks[i]; t.Type == scanner.Delim {
			switch t.Value {
			case ":":
				if inblock {
					colon = i
				}
			case ";":
				key := trimSpace(toks[start:colon])
				value := trimSpace(toks[colon+1 : i])
				q := qrule{Key: key, Value: value}
				b.Rules = append(b.Rules, q)
				colon = 0
				start = i + 1
			case "{":
				var nb sBlock
				l := findClosingBrace(toks[i+1:])
				if i+1 == l {
					break
				}
				nb = consumeBlock(toks[i+1:i+l], true)
				if toks[start].Type == scanner.AtKeyword {
					nb.Name = toks[start].Value
					b.ChildAtRules = append(b.ChildAtRules, &nb)
					nb.ComponentValues = fixupComponentValues(toks[start+1 : i])
				} else {
					b.Blocks = append(b.Blocks, &nb)
					nb.ComponentValues = fixupComponentValues(toks[start:i])
				}
				i = i + l
				start = i + 1
				// skip over whitespace
				if start < len(toks) && toks[start].Type == scanner.S {
					start++
					i++
				}
			default:
				// w("unknown delimiter", t.Value)
			}
		}
		i++
		if i == len(toks) {
			break
		}
	}
	if colon > 0 {
		b.Rules = append(b.Rules, qrule{Key: toks[start:colon], Value: toks[colon+1 : len(toks)]})
	}
	return b
}

func (c *CSS) doFontFace(ff []qrule) {
	var fontfamily, fontstyle, fontweight string
	var fontsource FontSource
	for _, rule := range ff {
		key := strings.TrimSpace(rule.Key.String())
		value := strings.TrimSpace(rule.Value.String())
		switch key {
		case "font-family":
			fontfamily = value
		case "font-style":
			fontstyle = value
		case "font-weight":
			fontweight = value
		case "src":
			for _, v := range rule.Value {
				if v.Type == scanner.URI {
					fontsource.URL = v.Value
				} else if v.Type == scanner.Local {
					fontsource.Local = v.Value
				}
			}
		}
	}
	fam := c.Fontfamilies[fontfamily]
	if fontweight == "bold" {
		if fontstyle == "italic" {
			fam.BoldItalic = fontsource
		} else {
			fam.Bold = fontsource
		}
	} else {
		if fontstyle == "italic" {
			fam.Italic = fontsource
		} else {
			fam.Regular = fontsource
		}
	}
	c.Fontfamilies[fontfamily] = fam
}

func (c *CSS) doPage(block *sBlock) {
	selector := block.ComponentValues.String()
	pg := c.Pages[selector]
	if pg.pagearea == nil {
		pg.pagearea = make(map[string][]qrule)
	}
	for _, v := range block.Rules {
		switch v.Key.String() {
		case "size":
			pg.papersize = v.Value.String()
		default:
			a := html.Attribute{Key: v.Key.String(), Val: stringValue(v.Value)}
			pg.attributes = append(pg.attributes, a)
		}
	}
	for _, rule := range block.ChildAtRules {
		pg.pagearea[rule.Name] = rule.Rules
	}
	c.Pages[selector] = pg
}

func (c *CSS) processAtRules() {
	c.Fontfamilies = make(map[string]FontFamily)
	c.Pages = make(map[string]cssPage)
	for _, stylesheet := range c.Stylesheet {
		for _, atrule := range stylesheet.ChildAtRules {
			switch atrule.Name {
			case "font-face":
				c.doFontFace(atrule.Rules)
			case "page":
				c.doPage(atrule)
			}
		}

	}
}

// ParseHTMLFragment takes the HTML text and the CSS text and returns a
// Lua table as a string and perhaps an error.
func ParseHTMLFragment(htmltext, csstext string) (string, error) {
	c := CSS{}

	c.Stylesheet = append(c.Stylesheet, consumeBlock(parseCSSString(cssdefaults), false))
	c.Stylesheet = append(c.Stylesheet, consumeBlock(parseCSSString(csstext), false))
	err := c.readHTMLChunk(htmltext)
	if err != nil {
		return "", err
	}
	c.processAtRules()
	var b strings.Builder
	c.dumpTree(&b)
	return b.String(), nil
}

// Run returns a Lua tree
func Run(tmpdir string, arguments []string) (string, error) {
	var err error
	curwd, err := os.Getwd()
	if err != nil {
		return "", err
	}
	c := CSS{}

	c.Stylesheet = append(c.Stylesheet, consumeBlock(parseCSSString(cssdefaults), false))
	htmlfilename := arguments[0]
	// read additional stylesheets given on the command line
	for i := 1; i < len(arguments); i++ {
		block, err := parseCSSFile(arguments[i])
		if err != nil {
			return "", err
		}
		c.Stylesheet = append(c.Stylesheet, consumeBlock(block, false))
	}

	fn := filepath.Base(htmlfilename)
	p, err := filepath.Abs(filepath.Dir(htmlfilename))
	if err != nil {
		return "", err
	}
	os.Setenv("SPHTMLBASE", p)
	os.Chdir(p)
	defer os.Chdir(curwd)
	err = c.openHTMLFile(fn)
	if err != nil {
		return "", err
	}
	c.processAtRules()
	var b strings.Builder
	c.dumpTree(&b)

	return b.String(), nil
}
