package css

import (
	"log/slog"
	"sort"
	"strings"

	"github.com/andybalholm/cascadia"
	"github.com/speedata/css/scanner"
	"golang.org/x/net/html"
)

// LayoutElement is one element in the chain of layout commands that
// surround the element whose CSS rules are requested.
type LayoutElement struct {
	Name     string // lower case element name, such as "td"
	Class    string // space separated class names
	ID       string
	Position int // 1-based position among its siblings, 0 if unknown
}

// layoutDecl is a single declaration of a layout CSS rule.
type layoutDecl struct {
	key       string
	value     string
	important bool
}

// layoutRule is a single selector with its declarations. A rule with a
// selector group (a, b) is stored once per selector.
type layoutRule struct {
	sel    cascadia.Sel
	spec   cascadia.Specificity
	pseudo string
	decls  []layoutDecl
}

// LayoutStylesheet holds the CSS rules for the layout commands. The rules
// are kept in source order.
type LayoutStylesheet struct {
	rules []layoutRule
}

// NewLayoutStylesheet returns an empty stylesheet.
func NewLayoutStylesheet() *LayoutStylesheet {
	return &LayoutStylesheet{}
}

// sourceString serializes tokens close to their source form. Unlike
// stringValue it keeps the original spacing, so that values such as
// rgb(1,2,3) or "1pt solid red" reach the layout commands unchanged.
func sourceString(toks tokenstream) string {
	var b strings.Builder
	for _, tok := range toks {
		switch tok.Type {
		case scanner.S:
			b.WriteByte(' ')
		case scanner.String:
			b.WriteByte('"')
			b.WriteString(strings.ReplaceAll(tok.Value, `"`, `\"`))
			b.WriteByte('"')
		case scanner.Hash:
			b.WriteString("#" + tok.Value)
		case scanner.AtKeyword:
			b.WriteString("@" + tok.Value)
		case scanner.Percentage:
			b.WriteString(tok.Value + "%")
		case scanner.Function:
			b.WriteString(tok.Value + "(")
		case scanner.URI:
			b.WriteString("url(" + tok.Value + ")")
		default:
			b.WriteString(tok.Value)
		}
	}
	return strings.TrimSpace(b.String())
}

// splitImportant removes a trailing "!important" from the value tokens.
func splitImportant(toks tokenstream) (tokenstream, bool) {
	i := len(toks) - 1
	for i >= 0 && toks[i].Type == scanner.S {
		i--
	}
	if i < 1 || toks[i].Type != scanner.Ident || !strings.EqualFold(toks[i].Value, "important") {
		return toks, false
	}
	i--
	for i >= 0 && toks[i].Type == scanner.S {
		i--
	}
	if i < 0 || toks[i].Type != scanner.Delim || toks[i].Value != "!" {
		return toks, false
	}
	return toks[:i], true
}

// AddCSS parses csstext and appends its rules. At-rules such as @media or
// @font-face are not used for layout commands and are skipped.
func (ls *LayoutStylesheet) AddCSS(csstext string) {
	block := consumeBlock(parseCSSString(csstext), false)
	for _, b := range block.Blocks {
		decls := make([]layoutDecl, 0, len(b.Rules))
		for _, r := range b.Rules {
			key := sourceString(r.Key)
			if key == "" {
				continue
			}
			valtoks, important := splitImportant(r.Value)
			decls = append(decls, layoutDecl{key: key, value: sourceString(valtoks), important: important})
		}
		selector := sourceString(b.ComponentValues)
		group, err := cascadia.ParseGroupWithPseudoElements(selector)
		if err != nil {
			slog.Error("CSS: cannot parse selector", "selector", selector, "msg", err.Error())
			continue
		}
		for _, sel := range group {
			ls.rules = append(ls.rules, layoutRule{
				sel:    sel,
				spec:   sel.Specificity(),
				pseudo: sel.PseudoElement(),
				decls:  decls,
			})
		}
	}
}

// buildChain creates a small DOM below a root element "layout" and returns
// the innermost element. Elements with a position get empty preceding
// siblings, so that structural pseudo classes like :nth-child work.
func buildChain(chain []LayoutElement) *html.Node {
	doc := &html.Node{Type: html.DocumentNode}
	n := &html.Node{Type: html.ElementNode, Data: "layout"}
	doc.AppendChild(n)
	for _, elt := range chain {
		parent := n
		for i := 1; i < elt.Position; i++ {
			parent.AppendChild(&html.Node{Type: html.ElementNode, Data: elt.Name})
		}
		n = &html.Node{Type: html.ElementNode, Data: elt.Name}
		if elt.Class != "" {
			n.Attr = append(n.Attr, html.Attribute{Key: "class", Val: elt.Class})
		}
		if elt.ID != "" {
			n.Attr = append(n.Attr, html.Attribute{Key: "id", Val: elt.ID})
		}
		parent.AppendChild(n)
	}
	return n
}

// Match returns the declarations for the last element of the chain (or its
// pseudo element, if pseudo is not empty). Rules are applied by ascending
// specificity, rules with the same specificity in source order, and
// declarations marked !important after all others. The second return value
// contains the properties whose value comes from an !important declaration.
func (ls *LayoutStylesheet) Match(chain []LayoutElement, pseudo string) (map[string]string, map[string]bool) {
	decls := map[string]string{}
	important := map[string]bool{}
	if len(ls.rules) == 0 || len(chain) == 0 {
		return decls, important
	}
	n := buildChain(chain)
	var matched []*layoutRule
	for i := range ls.rules {
		r := &ls.rules[i]
		if r.pseudo == pseudo && r.sel.Match(n) {
			matched = append(matched, r)
		}
	}
	sort.SliceStable(matched, func(a, b int) bool {
		return matched[a].spec.Less(matched[b].spec)
	})
	for _, r := range matched {
		for _, d := range r.decls {
			if !d.important {
				decls[d.key] = d.value
			}
		}
	}
	for _, r := range matched {
		for _, d := range r.decls {
			if d.important {
				decls[d.key] = d.value
				important[d.key] = true
			}
		}
	}
	return decls, important
}
