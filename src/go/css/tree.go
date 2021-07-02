package css

import (
	"fmt"
	"io"
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
	style = regexp.MustCompile(`^none|hidden|dotted|dashed|solid|double|groove|ridge|inset|outset$`)
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
			case scanner.Comment:
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
					sel.SetAttr("!"+key.String(), val.String())
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
		sel.SetAttr("!"+stringValue(key), stringValue(val))
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
func resolveAttributes(attrs []html.Attribute) (map[string]string, map[string]string) {
	resolved := make(map[string]string)
	attributes := make(map[string]string)
	// attribute resolving must be in order of appearance.
	// For example the following border-left-style has no effect:
	//    border-left-style: dotted;
	//    border-left: thick green;
	// because the second line overrides the first line (style defaults to "none")
	for _, attr := range attrs {
		key := attr.Key
		if !strings.HasPrefix(key, "!") {
			attributes[key] = attr.Val
			continue
		}
		key = strings.TrimPrefix(key, "!")

		switch key {
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
			for _, loc := range toprightbottomleft {
				resolved["border-"+loc+"-style"] = "none"
				resolved["border-"+loc+"-width"] = "1pt"
				resolved["border-"+loc+"-color"] = "currentcolor"
			}

			// This does not work with colors such as rgb(1 , 2 , 4) which have spaces in them
			for _, part := range strings.Split(attr.Val, " ") {
				for _, border := range toprightbottomleft {
					if ok, str := isBorderStyle(part); ok {
						resolved["border-"+border+"-style"] = str
					} else if ok, str := isDimension(part); ok {
						resolved["border-"+border+"-width"] = str
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
			resolved[attr.Key+"-color"] = "currentcolor"

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
		case "font":
			fontstyle := "normal"
			fontweight := "normal"

			/*
				it must include values for:
					<font-size>
					<font-family>
				it may optionally include values for:
					<font-style>
					<font-variant>
					<font-weight>
					<font-stretch>
					<line-height>
				* font-style, font-variant and font-weight must precede font-size
				* font-variant may only specify the values defined in CSS 2.1, that is normal and small-caps
				* font-stretch may only be a single keyword value.
				* line-height must immediately follow font-size, preceded by "/", like this: "16px/3"
				* font-family must be the last value specified.
			*/
			val := attr.Val
			fields := strings.Fields(val)
			l := len(fields)
			for idx, field := range fields {
				if idx > l-3 {
					if dimen.MatchString(field) || strings.Contains(field, "%") {
						resolved["font-size"] = field
					} else {
						resolved["font-name"] = field
					}
				}
			}
			resolved["font-style"] = fontstyle
			resolved["font-weight"] = fontweight
		// font-stretch: ultra-condensed; extra-condensed; condensed; semi-condensed; normal; semi-expanded; expanded; extra-expanded; ultra-expanded;
		case "text-decoration":
			for _, part := range strings.Split(attr.Val, " ") {
				if part == "none" || part == "underline" || part == "overline" || part == "line-through" {
					resolved["text-decoration-line"] = part
				} else if part == "solid" || part == "double" || part == "dotted" || part == "dashed" || part == "wavy" {
					resolved["text-decoration-style"] = part
				}
			}

		case "background":
			// background-clip, background-color, background-image, background-origin, background-position, background-repeat, background-size, and background-attachment
			for _, part := range strings.Split(attr.Val, " ") {
				resolved["background-color"] = part
			}
		default:
			resolved[key] = attr.Val
		}
	}
	if str, ok := resolved["text-decoration-line"]; ok && str != "none" {
		resolved["text-decoration-style"] = "solid"
	}
	return resolved, attributes
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
			isBlock := false
			if eltname == "address" || eltname == "article" || eltname == "aside" || eltname == "audio" || eltname == "video" || eltname == "blockquote" || eltname == "canvas" || eltname == "dd" || eltname == "div" || eltname == "dl" || eltname == "fieldset" || eltname == "figcaption" || eltname == "figure" || eltname == "footer" || eltname == "form" || eltname == "h1" || eltname == "h2" || eltname == "h3" || eltname == "h4" || eltname == "h5" || eltname == "h6" || eltname == "header" || eltname == "hgroup" || eltname == "hr" || eltname == "noscript" || eltname == "ol" || eltname == "output" || eltname == "p" || eltname == "pre" || eltname == "section" || eltname == "table" || eltname == "tfoot" || eltname == "ul" {
				isBlock = true
			}
			fmt.Fprintf(out, "%s { elementname = %q, direction = %q,", indent, eltname, newDir)
			if isBlock {
				fmt.Fprint(out, " block=true,")
			}
			fmt.Fprintln(out)
			attributes := thisNode.Attr
			if len(attributes) > 0 {
				fmt.Fprintf(out, "%s  styles = {", indent)
				resolvedStyles, resolvedAttributes := resolveAttributes(attributes)
				for key, value := range resolvedStyles {
					if key == "white-space" {
						if value == "pre" {
							ws = true
						} else {
							ws = false
						}
					}
					fmt.Fprintf(out, "[%q] = %q ,", key, value)
				}
				fmt.Fprintf(out, "has_border = %t ,", hasBorder(resolvedStyles))
				fmt.Fprintf(out, "%s  }, attributes = {", indent)
				for key, value := range resolvedAttributes {
					fmt.Fprintf(out, "[%q] = %q ,", key, value)
				}
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
					node.Attr = append(node.Attr, html.Attribute{Key: "!" + prefix + stringValue(singlerule.Key), Val: stringValue(singlerule.Value)})
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
		styles, _ := resolveAttributes(v.attributes)
		for k, v := range styles {
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
	typ = strings.ToLower(typ)
	var width, height string
	portrait := true
	for i, e := range strings.Fields(typ) {
		switch e {
		case "portrait":
			// good, nothing to do
		case "landscape":
			portrait = false
		case "a5":
			width = "148mm"
			height = "210mm"
		case "a4":
			width = "210mm"
			height = "297mm"
		case "a3":
			width = "297mm"
			height = "420mm"
		case "b5":
			width = "176mm"
			height = "250mm"
		case "b4":
			width = "250mm"
			height = "353mm"
		case "jis-b5":
			width = "182mm"
			height = "257mm"
		case "jis-b4":
			width = "257mm"
			height = "364mm"
		case "letter":
			width = "8.5in"
			height = "11in"
		case "legal":
			width = "8.5in"
			height = "14in"
		case "ledger":
			width = "11in"
			height = "17in"
		default:
			if i == 0 {
				width = e
				height = e
			} else {
				height = e
			}
		}
	}

	if portrait {
		return width, height
	}
	return height, width
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
			block, err := c.parseCSSFile(stylesheetfile)
			if err != nil {
				errcond = err
			}
			parsedStyles := consumeBlock(block, false)
			c.Stylesheet = append(c.Stylesheet, parsedStyles)
		}
	})
	return errcond
}
