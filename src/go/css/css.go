package css

import (
	"fmt"
	"strings"

	"github.com/PuerkitoBio/goquery"
	"github.com/speedata/css/scanner"
	"golang.org/x/net/html"
)

// FontFamilyFiles lists the font file paths for the four standard text styles.
type FontFamilyFiles struct {
	Regular    string
	Bold       string
	BoldItalic string
	Italic     string
}

// PageAreaRule stores a single CSS key/value pair for a named @page area.
type PageAreaRule struct {
	Key   string
	Value tokenstream // du hast bereits stringValue()
}

// Page is the normalized representation of the parsed @page rule.
type Page struct {
	Attributes []html.Attribute
	Papersize  string
	Pagearea   map[string][]PageAreaRule
}

// Result contains the computed DOM, language, fonts, pages, and per-node styles.
type Result struct {
	Root         *html.Node
	Lang         string
	Fontfamilies map[string]FontFamily
	Pages        map[string]Page

	// resolved style and attributes per node
	Styles     map[*html.Node]map[string]string
	Attributes map[*html.Node]map[string]string
}

// tokenstream contains the raw tokens emitted by the CSS scanner.
type tokenstream []*scanner.Token

// String concatenates all token values; useful when the tokens represent
// identifiers or numbers that should be read without whitespace.
func (t tokenstream) String() string {
	ret := []string{}
	for _, tok := range t {
		ret = append(ret, tok.Value)
	}
	return strings.Join(ret, "")
}

// qrule represents a CSS declaration (key/value pair) without any post-processing.
type qrule struct {
	Key   tokenstream
	Value tokenstream
}

// sBlock models a segment of the stylesheet, either a qualified rule or an at-rule.
type sBlock struct {
	Name            string      // only set if this is an at-rule
	ComponentValues tokenstream // the "selector"
	ChildAtRules    []*sBlock   // the block's at-rules, if any
	Blocks          []*sBlock   // the at-rule's blocks, if any
	Rules           []qrule     // the key-value pairs
}

// cssPage represents the intermediate state of a parsed @page rule before export.
type cssPage struct {
	pagearea   map[string][]qrule
	attributes []html.Attribute
	papersize  string
}

// CSS encapsulates the parsed stylesheet, document, and derived metadata.
type CSS struct {
	dirstack     []string
	document     *goquery.Document
	Stylesheet   []sBlock
	Fontfamilies map[string]FontFamily
	Pages        map[string]cssPage
}

// FontSource holds the origin of a font as parsed from a @font-face src list.
type FontSource struct {
	Local string
	URL   string
}

// String renders the source in Lua table syntax as expected by the consumer.
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

// FontFamily bundles the four commonly used style variants of a font family.
type FontFamily struct {
	Regular    FontSource
	Bold       FontSource
	Italic     FontSource
	BoldItalic FontSource
}

// cssdefaults defines the built-in UA stylesheet that seeds every parsed document.
var cssdefaults = `
:root           { font-family: sans-serif;  font-size: 10pt; line-height: 1.2; }
a               { text-decoration: underline; color: blue; }
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
body            { margin: 0pt; hyphens: auto; }
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

// findClosingBrace returns the index of the token following the matching '}'.
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

// fixupComponentValues merges punctuation tokens with identifiers (e.g. ".foo").
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

// trimSpace removes leading whitespace tokens from the provided slice.
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

// consumeBlock parses the body between matching braces and returns a structured
// sBlock; it does not set the at-rule name or selector, those are added later.
func consumeBlock(toks tokenstream, inblock bool) sBlock {
	// This is the whole block between the opening { and closing }
	if len(toks) <= 1 {
		return sBlock{}
	}
	b := sBlock{}
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
				// l is the length of the sub block
				l := findClosingBrace(toks[i+1:])
				if l == 1 {
					break
				}
				subblock := toks[i+1 : i+l]
				// subblock is without the enclosing curly braces
				starttok := toks[start]
				startsWithATKeyword := starttok.Type == scanner.AtKeyword && (starttok.Value == "media" || starttok.Value == "supports")
				nb = consumeBlock(subblock, !startsWithATKeyword)
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
		b.Rules = append(b.Rules, qrule{Key: toks[start:colon], Value: toks[colon+1:]})
	}
	return b
}

// doFontFace updates the Fontfamilies map with the sources defined in @font-face.
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

// doPage captures the parsed @page rule and stores it in the Pages map.
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

// processAtRules walks the stylesheet blocks and extracts structured metadata.
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

// Findfunc locates external resources and returns their textual contents.
type Findfunc func(string) (string, error)

// NewCSSParser returns an empty CSS parser instance ready for incremental use.
func NewCSSParser() *CSS {
	return &CSS{}
}

// ParseHTMLFragment parses DOM and CSS snippets, computes all rules, and returns
// a Result ready for downstream processing.
func (c *CSS) ParseHTMLFragment(htmlfrag, csstext string) (*Result, error) {
	c.Stylesheet = append(c.Stylesheet, consumeBlock(parseCSSString(cssdefaults), false))
	c.Stylesheet = append(c.Stylesheet, consumeBlock(parseCSSString(csstext), false))

	if err := c.readHTMLChunk(htmlfrag); err != nil {
		return nil, err
	}
	c.processAtRules()

	roots := c.document.Find(":root").Nodes
	if len(roots) == 0 {
		return nil, fmt.Errorf("no :root element found")
	}
	r := &Result{
		Root:         roots[0],
		Lang:         "",
		Fontfamilies: c.Fontfamilies, // same type as CSS.Fontfamilies
		Pages:        map[string]Page{},
		Styles:       map[*html.Node]map[string]string{},
		Attributes:   map[*html.Node]map[string]string{},
	}
	if lang, ok := c.document.Find(":root").Attr("lang"); ok {
		r.Lang = lang
	}

	// Compute final styles/attributes (no DOM mutation)
	if err := c.FillComputedMaps(r); err != nil {
		return nil, err
	}

	// You can also normalize pages here if desired (expand shorthands once):
	// for k, v := range c.Pages { ... } -> r.Pages[k] = normalized Page

	return r, nil
}
