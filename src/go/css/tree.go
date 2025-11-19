package css

import (
	"fmt"
	"regexp"
	"strings"

	"golang.org/x/net/html"

	"github.com/PuerkitoBio/goquery"
	"github.com/speedata/css/scanner"
)

var (
	dimen                             = regexp.MustCompile(`^(-?\d*\.?\d+)(px|mm|cm|in|pt|pc|ch|em|ex|lh|rem)?$`)
	style              *regexp.Regexp = regexp.MustCompile(`^none|hidden|dotted|dashed|solid|double|groove|ridge|inset|outset$`)
	toprightbottomleft                = [4]string{"top", "right", "bottom", "left"}
)

func stringValue(toks tokenstream) string {
	ret := []string{}
	negative := false
	prevNegative := false
	for _, tok := range toks {
		prevNegative = negative
		negative = false
		switch tok.Type {
		case scanner.Ident:
			ret = append(ret, tok.Value)
		case scanner.String:
			ret = append(ret, "\""+tok.Value+"\"")
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
				fmt.Println("unhandled delimiter", tok)
			}
		case scanner.URI:
			ret = append(ret, "url("+tok.Value+")")
		default:
			fmt.Println("unhandled token", tok)
		}
	}
	return strings.Join(ret, " ")
}

func keyValueFromToks(toks tokenstream) map[string]string {
	kv := make(map[string]string)
	var key, val tokenstream
	start := 0
	colon := 0
	i := 0
	for {
		tok := toks[i]
		switch tok.Type {
		case scanner.Delim:
			switch tok.Value {
			case ":":
				key = toks[start:i]
				colon = i + 1
			case ";":
				val = toks[colon:i]
				kv[stringValue(key)] = stringValue(val)
				start = i + 1
				key = toks[:0]
				val = toks[:0]
			default:
				// w("unknown delimiter", tok.Value)
			}
		default:
			// w("unknown token type", tok.Type, tok.Value)
		}
		i = i + 1
		if i == len(toks) {
			if start < i {
				key = toks[start : colon-1]
				val = toks[colon:i]
				kv[stringValue(key)] = stringValue(val)
			}
			break
		}
	}
	return kv
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

	if dimen.MatchString(str) {
		return true, str
	}
	return false, str
}

func isBorderStyle(str string) (bool, string) {
	return style.MatchString(str), str
}

func getFourValues(str string) map[string]string {
	fields := splitCSSParts(str)
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

// splitCSSParts splits a shorthand value into parts, but keeps anything inside
// parentheses together (e.g. "rgb(164, 164, 127)" stays one token).
func splitCSSParts(s string) []string {
	var parts []string
	var buf strings.Builder
	depth := 0 // parenthesis depth

	flush := func() {
		if buf.Len() == 0 {
			return
		}
		part := strings.TrimSpace(buf.String())
		if part != "" {
			parts = append(parts, part)
		}
		buf.Reset()
	}

	for _, r := range s {
		switch r {
		case '(':
			depth++
			buf.WriteRune(r)
		case ')':
			buf.WriteRune(r)
			depth--
		case ' ', '\t', '\n', '\r':
			if depth == 0 {
				// split here
				flush()
			} else {
				// inside parentheses, keep whitespace
				buf.WriteRune(r)
			}
		default:
			buf.WriteRune(r)
		}
	}
	flush()
	return parts
}

// resolveAttributes expands shorthand CSS-style attributes into their
// longhand form and separates "computed style" properties from ordinary
// HTML attributes.
//
// It takes the attribute list from an HTML element — typically including
// both regular attributes (like `class`, `id`, `href`, ...) and internally
// prefixed style attributes (like `!margin`, `!border`, `!font`, ...),
// which represent inline styles or merged CSS rules.
//
// The function returns two maps:
//
//  1. resolved (map[string]string)
//     Fully expanded style properties. Shorthands such as
//     "margin", "padding", "border", "font", or "list-style" are split
//     into their directional or property-specific equivalents
//     (e.g. "margin-top", "border-left-width", etc.).
//     Default values are added where appropriate, for example
//     `border-style: none` and `border-width: 1pt` when `border` is used
//     without explicit subproperties. The helper also normalizes certain
//     values (e.g. `font`, `text-decoration`, or `background`) to match
//     CSS2.1 semantics.
//
//  2. attributes (map[string]string)
//     Non-style HTML attributes that do not start with the internal
//     `!` prefix. These are passed through unchanged and preserved
//     for the renderer (e.g. "class", "src", "alt", ...).
//
// The order in which attributes appear in the input slice is significant:
// later declarations override earlier ones, matching CSS cascade behavior.
//
// This function is used only during the *CSS-to-tree normalization phase*,
// when the engine builds the computed style maps for each HTML node
// (`Result.Styles` and `Result.Attributes`). The renderer should never
// call this function again — it consumes the already computed maps
// without further interpretation.
//
// Example:
//
//	Input:  [ {Key:"!margin", Val:"1cm"} ]
//	Output: (
//	    map[string]string{
//	        "margin-top": "1cm",
//	        "margin-right": "1cm",
//	        "margin-bottom": "1cm",
//	        "margin-left": "1cm",
//	    },
//	    map[string]string{} // no plain HTML attributes
//	)
//
// In the following example, the color="blue" attribute has no exclamation mark,
// the other style attributes have them.
//
//		<h1 style="color: green;">h1</h1>
//		<p color="blue">This is a paragraph with text.</p>
//
//	 The return value would is:
//	     resolved map[font-size:1em margin-bottom:1.5em margin-left:0 margin-right:0 margin-top:1.5em]
//	     attributes map[color:blue]
//
// since the default style for <p> includes the margin and font-size properties:
// p { font-size: 1em; margin: 1.5em 0 }
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
			for _, part := range splitCSSParts(attr.Val) {
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
			resolved[key+"-width"] = "1pt"
			resolved[key+"-style"] = "none"
			resolved[key+"-color"] = "currentcolor"

			for _, part := range splitCSSParts(attr.Val) {
				if ok, str := isDimension(part); ok {
					resolved[key+"-width"] = str
				} else if ok, str := isBorderStyle(part); ok {
					resolved[key+"-style"] = str
				} else {
					resolved[key+"-color"] = part
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
				switch part {
				case "none", "underline", "overline", "line-through":
					resolved["text-decoration-line"] = part
				case "solid", "double", "dotted", "dashed", "wavy":
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
