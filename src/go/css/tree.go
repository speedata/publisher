package css

import (
	"fmt"
	"io"
	"os"
	"regexp"
	"sort"
	"strings"

	"golang.org/x/net/html"

	"github.com/PuerkitoBio/goquery"
	"github.com/andybalholm/cascadia"
	"github.com/speedata/css/scanner"
)

var (
	level              int
	out                io.Writer
	dimen              *regexp.Regexp
	zeroDimen          *regexp.Regexp
	style              *regexp.Regexp
	reInsideWS         *regexp.Regexp
	reLeadcloseWhtsp   *regexp.Regexp
	toprightbottomleft [4]string
	isSpace            *regexp.Regexp
	quoteString        *strings.Replacer
)

type mode int

func (m mode) String() string {
	if m == modeHorizontal {
		return "→"
	}
	return "↓"
}

const (
	modeHorizontal mode = iota
	modeVertial
)

func init() {
	toprightbottomleft = [...]string{"top", "right", "bottom", "left"}
	dimen = regexp.MustCompile(`px|mm|cm|in|pt|pc|ch|em|ex|lh|rem|0`)
	zeroDimen = regexp.MustCompile(`^0+(px|mm|cm|in|pt|pc|ch|em|ex|lh|rem)?`)
	style = regexp.MustCompile(`none|hidden|dotted|dashed|solid|double|groove|ridge|inset|outset`)
	reLeadcloseWhtsp = regexp.MustCompile(`^[\s\p{Zs}]+|[\s\p{Zs}]+$`)
	reInsideWS = regexp.MustCompile(`\n|[\s\p{Zs}]{2,}`) //to match 2 or more whitespace symbols inside a string or NL
	isSpace = regexp.MustCompile(`^\s*$`)
	// go %s must escape quotes and newlines for Lua
	quoteString = strings.NewReplacer(`"`, `\"`, "\n", `\n`, `\`, `\\`)
}

func normalizespace(input string) string {
	return strings.Join(strings.Fields(input), " ")
}

func stringValue(toks tokenstream) string {
	ret := []string{}
	negative := false
	prevNegative := false
	for _, tok := range toks {
		prevNegative = negative
		negative = false
		switch tok.Type {
		case scanner.Ident, scanner.String:
			ret = append(ret, tok.Value)
		case scanner.Number, scanner.Dimension:
			if prevNegative {
				ret = append(ret, "-"+tok.Value)
			} else {
				ret = append(ret, tok.Value)
			}
		case scanner.Percentage:
			ret = append(ret, tok.Value+"%")
		case scanner.Hash:
			ret = append(ret, "#"+tok.Value)
		case scanner.Function:
			ret = append(ret, tok.Value+"(")
		case scanner.S:
			// ret = append(ret, " ")
		case scanner.Delim:
			switch tok.Value {
			case ";":
				// ignore
			case ",", ")":
				ret = append(ret, tok.Value)
			case "-":
				negative = true
			default:
				w("unhandled delimiter", tok)
			}
		case scanner.URI:
			ret = append(ret, "url("+tok.Value+")")
		default:
			w("unhandled token", tok)
		}
	}
	return strings.Join(ret, " ")
}

// Recurse through the HTML tree and resolve the style attribute
func resolveStyle(i int, sel *goquery.Selection) {
	a, b := sel.Attr("style")
	if b {
		var tokens tokenstream

		s := scanner.New(a)
		for {
			token := s.Next()
			if token.Type == scanner.EOF || token.Type == scanner.Error {
				break
			}
			switch token.Type {
			case scanner.Comment, scanner.S:
				// ignore
			default:
				tokens = append(tokens, token)
			}
		}
		var i int
		var key, val tokenstream
		start := 0
		colon := 0
		for {
			tok := tokens[i]
			switch tok.Type {
			case scanner.Delim:
				switch tok.Value {
				case ":":
					key = tokens[start:i]
					colon = i + 1
				case ";":
					val = tokens[colon:i]

					sel.SetAttr(key.String(), val.String())
					start = i
				default:
					w("unknown delimiter", tok.Value)
				}
			default:
				// w("unknown token type", tok.Type, tok.Value)
			}
			i = i + 1
			if i == len(tokens) {
				break
			}
		}
		val = tokens[colon:i]
		sel.SetAttr(stringValue(key), stringValue(val))
		sel.RemoveAttr("style")
	}
	sel.Children().Each(resolveStyle)
}

func isDimension(str string) (bool, string) {
	switch str {
	case "thick":
		return true, "2pt"
	case "medium":
		return true, "1pt"
	case "thin":
		return true, "0.5pt"
	}
	return dimen.MatchString(str), str
}
func isBorderStyle(str string) (bool, string) {
	return style.MatchString(str), str
}

func getFourValues(str string) map[string]string {
	fields := strings.Fields(str)
	fourvalues := make(map[string]string)
	switch len(fields) {
	case 1:
		fourvalues["top"] = fields[0]
		fourvalues["bottom"] = fields[0]
		fourvalues["left"] = fields[0]
		fourvalues["right"] = fields[0]
	case 2:
		fourvalues["top"] = fields[0]
		fourvalues["bottom"] = fields[0]
		fourvalues["left"] = fields[1]
		fourvalues["right"] = fields[1]
	case 3:
		fourvalues["top"] = fields[0]
		fourvalues["left"] = fields[1]
		fourvalues["right"] = fields[1]
		fourvalues["bottom"] = fields[2]
	case 4:
		fourvalues["top"] = fields[0]
		fourvalues["right"] = fields[1]
		fourvalues["bottom"] = fields[2]
		fourvalues["left"] = fields[3]
	}

	return fourvalues
}

// Change "margin: 1cm;" into "margin-left: 1cm; margin-right: 1cm; ..."
func resolveAttributes(attrs []html.Attribute) map[string]string {
	resolved := make(map[string]string)
	// attribute resolving must be in order of appearance. For example the following border-left-style has no effect:
	//    border-left-style: dotted;
	//    border-left: thick green;
	// because the second line overrides the first line (style defaults to "none")

	for _, attr := range attrs {
		switch attr.Key {
		case "margin":
			values := getFourValues(attr.Val)
			for _, margin := range toprightbottomleft {
				resolved["margin-"+margin] = values[margin]
			}
		case "list-style":
			for _, part := range strings.Split(attr.Val, " ") {
				switch part {
				case "inside", "outside":
					resolved["list-style-position"] = part
				default:
					if strings.HasPrefix(part, "url") {
						resolved["list-style-image"] = part
					} else {
						resolved["list-style-type"] = part
					}
				}
			}
		case "padding":
			values := getFourValues(attr.Val)
			for _, padding := range toprightbottomleft {
				resolved["padding-"+padding] = values[padding]
			}
		case "border":
			// This does not work with colors such as rgb(1 , 2 , 4) which have spaces in them
			for _, part := range strings.Split(attr.Val, " ") {
				for _, border := range toprightbottomleft {
					if ok, str := isDimension(part); ok {
						resolved["border-"+border+"-width"] = str
					} else if ok, str := isBorderStyle(part); ok {
						resolved["border-"+border+"-style"] = str
					} else {
						resolved["border-"+border+"-color"] = part
					}
				}
			}
		case "border-radius":
			for _, lr := range []string{"left", "right"} {
				for _, tb := range []string{"top", "bottom"} {
					resolved["border-"+tb+"-"+lr+"-radius"] = attr.Val
				}
			}
		case "border-top", "border-right", "border-bottom", "border-left":
			resolved[attr.Key+"-width"] = "1pt"
			resolved[attr.Key+"-style"] = "none"

			for _, part := range strings.Split(attr.Val, " ") {
				if ok, str := isDimension(part); ok {
					resolved[attr.Key+"-width"] = str
				} else if ok, str := isBorderStyle(part); ok {
					resolved[attr.Key+"-style"] = str
				} else {
					resolved[attr.Key+"-color"] = str
				}
			}
		case "border-color":
			values := getFourValues(attr.Val)
			for _, loc := range toprightbottomleft {
				resolved["border-"+loc+"-color"] = values[loc]
			}
		case "border-style":
			values := getFourValues(attr.Val)
			for _, loc := range toprightbottomleft {
				resolved["border-"+loc+"-style"] = values[loc]
			}
		case "border-width":
			values := getFourValues(attr.Val)
			for _, loc := range toprightbottomleft {
				resolved["border-"+loc+"-width"] = values[loc]
			}
		case "background":
			// background-clip, background-color, background-image, background-origin, background-position, background-repeat, background-size, and background-attachment
			for _, part := range strings.Split(attr.Val, " ") {
				resolved["background-color"] = part
			}
		default:
			resolved[attr.Key] = attr.Val
		}
	}
	return resolved
}

var preserveWhitespace = []bool{false}

func hasBorder(attrs map[string]string) bool {
	var borderwidthKey, borderstyleKey string
	for _, loc := range toprightbottomleft {
		borderwidthKey = "border-" + loc + "-width"
		borderstyleKey = "border-" + loc + "-style"
		if wd, ok := attrs[borderwidthKey]; ok {
			if st, ok := attrs[borderstyleKey]; ok {
				if st != "none" {
					if !zeroDimen.MatchString(wd) {
						return true
					}
				}
			}
		}
	}
	return false
}

func dumpElement(thisNode *html.Node, level int, direction mode) {
	indent := strings.Repeat("  ", level)
	newDir := direction
	for {
		if thisNode == nil {
			break
		}

		switch thisNode.Type {
		case html.CommentNode:
			// ignore
		case html.TextNode:
			ws := preserveWhitespace[len(preserveWhitespace)-1]
			txt := thisNode.Data
			if !ws {
				if isSpace.MatchString(txt) {
					txt = " "
				}
			}
			if !isSpace.MatchString(txt) {
				if direction == modeVertial {
					newDir = modeHorizontal
				}
			}
			if txt != "" {
				if !ws {
					txt = reLeadcloseWhtsp.ReplaceAllString(txt, " ")
					txt = reInsideWS.ReplaceAllString(txt, " ")
				}
				fmt.Fprintf(out, `%s "%s",`, indent, quoteString.Replace(txt))
				fmt.Fprintf(out, "\n")
			}

		case html.ElementNode:
			ws := preserveWhitespace[len(preserveWhitespace)-1]
			eltname := thisNode.Data
			if eltname == "body" || eltname == "address" || eltname == "article" || eltname == "aside" || eltname == "blockquote" || eltname == "br" || eltname == "canvas" || eltname == "dd" || eltname == "div" || eltname == "dl" || eltname == "dt" || eltname == "fieldset" || eltname == "figcaption" || eltname == "figure" || eltname == "footer" || eltname == "form" || eltname == "h1" || eltname == "h2" || eltname == "h3" || eltname == "h4" || eltname == "h5" || eltname == "h6" || eltname == "header" || eltname == "hr" || eltname == "li" || eltname == "main" || eltname == "nav" || eltname == "noscript" || eltname == "ol" || eltname == "p" || eltname == "pre" || eltname == "section" || eltname == "table" || eltname == "tfoot" || eltname == "thead" || eltname == "tbody" || eltname == "tr" || eltname == "td" || eltname == "th" || eltname == "ul" || eltname == "video" {
				newDir = modeVertial
			} else if eltname == "b" || eltname == "big" || eltname == "i" || eltname == "small" || eltname == "tt" || eltname == "abbr" || eltname == "acronym" || eltname == "cite" || eltname == "code" || eltname == "dfn" || eltname == "em" || eltname == "kbd" || eltname == "strong" || eltname == "samp" || eltname == "var" || eltname == "a" || eltname == "bdo" || eltname == "img" || eltname == "map" || eltname == "object" || eltname == "q" || eltname == "script" || eltname == "span" || eltname == "sub" || eltname == "sup" || eltname == "button" || eltname == "input" || eltname == "label" || eltname == "select" || eltname == "textarea" {
				newDir = modeHorizontal
			} else {
				// keep dir
			}
			fmt.Fprintf(out, "%s { elementname = %q, direction = %q,\n", indent, eltname, newDir)

			attributes := thisNode.Attr
			if len(attributes) > 0 {
				fmt.Fprintf(out, "%s   attributes = {", indent)
				resolvedAttributes := resolveAttributes(attributes)
				for key, value := range resolvedAttributes {

					if key == "white-space" {
						if value == "pre" {
							ws = true
						} else {
							ws = false
						}
					}
					fmt.Fprintf(out, "[%q] = %q ,", key, value)
				}
				fmt.Fprintf(out, "has_border = %t ,", hasBorder(resolvedAttributes))
				fmt.Fprintln(out, "},")
			}
			preserveWhitespace = append(preserveWhitespace, ws)
			dumpElement(thisNode.FirstChild, level+1, newDir)
			preserveWhitespace = preserveWhitespace[:len(preserveWhitespace)-1]
			fmt.Fprintln(out, indent, "},")
		default:
			fmt.Println(thisNode.Type)
		}
		thisNode = thisNode.NextSibling
	}
}

func (c *CSS) dumpTree(outfile io.Writer) {
	out = outfile
	type selRule struct {
		selector cascadia.Sel
		rule     []qrule
	}

	rules := map[int][]selRule{}
	c.document.Each(resolveStyle)
	for _, stylesheet := range c.Stylesheet {
		for _, block := range stylesheet.Blocks {
			selector := block.ComponentValues.String()
			selectors, err := cascadia.ParseGroupWithPseudoElements(selector)
			if err != nil {
				fmt.Println(err)
			} else {
				for _, sel := range selectors {
					selSpecificity := sel.Specificity()
					s := selSpecificity[0]*100 + selSpecificity[1]*10 + selSpecificity[2]
					rules[s] = append(rules[s], selRule{selector: sel, rule: block.Rules})
				}
			}
		}
	}
	// sort map keys
	n := len(rules)
	keys := make([]int, 0, n)
	for k := range rules {
		keys = append(keys, k)
	}
	sort.Ints(keys)
	doc := c.document.Get(0)
	for _, k := range keys {
		for _, r := range rules[k] {
			for _, singlerule := range r.rule {
				for _, node := range cascadia.QueryAll(doc, r.selector) {
					var prefix string
					if pe := r.selector.PseudoElement(); pe != "" {
						prefix = pe + "::"
					}
					node.Attr = append(node.Attr, html.Attribute{Key: prefix + stringValue(singlerule.Key), Val: stringValue(singlerule.Value)})
				}
			}
		}
	}
	html := c.document.Find(":root")
	var lang string
	if langattr, ok := html.Attr("lang"); ok {
		lang = fmt.Sprintf("lang='%s',", langattr)
	}

	elt := c.document.Find(":root > body").Nodes[0]
	fmt.Fprintf(out, "csshtmltree = { typ = 'csshtmltree', %s\n", lang)
	c.dumpFonts()
	c.dumpPages()

	dumpElement(elt, 0, modeVertial)

	fmt.Fprintln(out, "}")
}

func (c *CSS) dumpPages() {
	fmt.Fprintln(out, "  pages = {")
	for k, v := range c.Pages {
		if k == "" {
			k = "*"
		}
		fmt.Fprintf(out, "    [%q] = {", k)
		for k, v := range resolveAttributes(v.attributes) {
			fmt.Fprintf(out, "[%q]=%q,", k, v)
		}
		wd, ht := papersize(v.papersize)
		fmt.Fprintf(out, "       width = %q, height = %q,\n", wd, ht)
		for paname, parea := range v.pagearea {
			fmt.Fprintf(out, "       [%q] = {\n", paname)
			for _, rule := range parea {
				fmt.Fprintf(out, "           [%q] = %q ,\n", rule.Key, stringValue(rule.Value))
			}
			fmt.Fprintln(out, "       },")
		}
		fmt.Fprintln(out, "     },")
	}

	fmt.Fprintln(out, "  },")
}

func (c *CSS) dumpFonts() {
	fmt.Fprintln(out, " fontfamilies = {")
	for name, ff := range c.Fontfamilies {
		fmt.Fprintf(out, "     [%q] = { regular = %s, bold=%s, bolditalic=%s, italic=%s },\n", name, ff.Regular, ff.Bold, ff.BoldItalic, ff.Italic)
	}
	fmt.Fprintln(out, " },")
}

func papersize(typ string) (string, string) {
	switch typ {
	case "a5":
		return "148mm", "210mm"
	}
	return "210mm", "297mm"
}

func (c *CSS) readHTMLChunk(htmltext string) error {
	var err error
	r := strings.NewReader(htmltext)
	c.document, err = goquery.NewDocumentFromReader(r)
	if err != nil {
		return err
	}
	var errcond error
	c.document.Find(":root > head link").Each(func(i int, sel *goquery.Selection) {
		if stylesheetfile, attExists := sel.Attr("href"); attExists {
			block, err := parseCSSFile(stylesheetfile)
			if err != nil {
				errcond = err
			}
			parsedStyles := consumeBlock(block, false)
			c.Stylesheet = append(c.Stylesheet, parsedStyles)
		}
	})
	return errcond
}

func (c *CSS) openHTMLFile(filename string) error {
	r, err := os.Open(filename)
	if err != nil {
		return err
	}
	c.document, err = goquery.NewDocumentFromReader(r)
	if err != nil {
		return err
	}
	var errcond error
	c.document.Find(":root > head link").Each(func(i int, sel *goquery.Selection) {
		if stylesheetfile, attExists := sel.Attr("href"); attExists {
			block, err := parseCSSFile(stylesheetfile)
			if err != nil {
				errcond = err
			}
			parsedStyles := consumeBlock(block, false)
			c.Stylesheet = append(c.Stylesheet, parsedStyles)
		}
	})
	return errcond
}
