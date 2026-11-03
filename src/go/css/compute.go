package css

import (
	"fmt"
	"maps"
	"sort"

	"github.com/PuerkitoBio/goquery"
	"github.com/andybalholm/cascadia"
	"golang.org/x/net/html"
)

// selRule keeps a parsed selector and the rule list for a single block.
type selRule struct {
	selector cascadia.Sel
	rule     []qrule
}

// nodeVirtAttrs is a per-call scratch pad mapping nodes to their "virtual attributes".
// Keep it unexported and reset per FillComputedMaps call (not global state).
var nodeVirtAttrs = map[*html.Node][]html.Attribute{}

// FillComputedMaps populates r.Styles and r.Attributes based on:
// - original attributes (non-style),
// - inline style attribute,
// - stylesheet rules applied by ascending specificity.
// It does NOT mutate the DOM.
func (c *CSS) FillComputedMaps(r *Result) error {
	nodeVirtAttrs := make(map[*html.Node][]html.Attribute)
	varState := make(map[*html.Node]*nodeVarState)
	haveVars := false
	state := func(n *html.Node) *nodeVarState {
		st := varState[n]
		if st == nil {
			st = &nodeVarState{haveVars: &haveVars}
			varState[n] = st
		}
		return st
	}

	if c.document == nil {
		return fmt.Errorf("document not loaded")
	}
	doc := c.document.Get(0)
	if doc == nil {
		return fmt.Errorf("empty document")
	}

	// 1) Collect all selectors grouped by specificity.
	rulesBySpec := map[int][]selRule{}

	// Inline default + user CSS are already in c.Stylesheet (as in your ParseHTMLFragment).
	for _, stylesheet := range c.Stylesheet {
		for _, block := range stylesheet.Blocks {
			selector := sourceString(block.ComponentValues)
			for _, sel := range parseSelectorGroup(selector) {
				sp := sel.Specificity()
				s := sp[0]*100 + sp[1]*10 + sp[2]
				rulesBySpec[s] = append(rulesBySpec[s], selRule{selector: sel, rule: block.Rules})
			}
		}
	}

	// Sort specificity keys (ascending) to preserve your previous order.
	specs := make([]int, 0, len(rulesBySpec))
	for s := range rulesBySpec {
		specs = append(specs, s)
	}
	sort.Ints(specs)

	// 2) Build a virtual attribute slice per node.
	//    Start by traversing the DOM and initializing entries.
	goDoc := c.document // for goquery traversals
	goDoc.Find("*").Each(func(_ int, sel *goquery.Selection) {
		for _, n := range sel.Nodes {
			if n.Type != html.ElementNode {
				continue
			}
			// Initialize maps
			if _, ok := r.Styles[n]; !ok {
				r.Styles[n] = make(map[string]string)
			}
			if _, ok := r.Attributes[n]; !ok {
				r.Attributes[n] = make(map[string]string)
			}

			// Build virtual attribute list for this node:
			// - copy original (except style)
			// - later append inline style as !props
			// - later append matched rules as !props in ascending specificity
			virt := make([]html.Attribute, 0, len(n.Attr)+8)

			// Copy original attributes excluding "style"
			for _, a := range n.Attr {
				if a.Key == "style" {
					continue
				}
				virt = append(virt, a)
			}

			// Inline style: append as !key=value (kept as a single "layer")
			if styleStr, has := sel.Attr("style"); has && styleStr != "" {
				st := state(n)
				for _, single := range consumeBlock(parseCSSString(styleStr), true).Rules {
					virt = st.add(virt, "", single, true)
				}
			}

			nodeVirtAttrs[n] = virt
		}
	})

	// 3) Apply stylesheet rules by ascending specificity, append as !props.
	//    For equal specificity, insertion order is the source order (your original behavior).
	for _, s := range specs {
		for _, sr := range rulesBySpec[s] {
			// Find all nodes matching this selector.
			for _, n := range cascadia.QueryAll(doc, sr.selector) {
				// Build prefix for pseudo-element (like your original code)
				var prefix string
				if pe := sr.selector.PseudoElement(); pe != "" {
					prefix = pe + "::"
				}
				virt := nodeVirtAttrs[n]
				st := state(n)
				for _, single := range sr.rule {
					virt = st.add(virt, prefix, single, false)
				}
				nodeVirtAttrs[n] = virt
			}
		}
	}

	// 3b) Custom properties: inherit them from the root down and replace
	//     the var() references.
	if haveVars || len(c.InitialVars) > 0 {
		resolveNodeVars(doc, c.InitialVars, varState, nodeVirtAttrs)
	}

	// 4) Final pass: resolveAttributes(virt) -> styles + attributes, store in r.
	for n, virt := range nodeVirtAttrs {
		styles, attrs := resolveAttributes(virt)

		// Ensure destination maps exist before writing
		if r.Styles[n] == nil {
			r.Styles[n] = make(map[string]string, len(styles))
		}
		if r.Attributes[n] == nil {
			r.Attributes[n] = make(map[string]string, len(attrs))
		}

		// Copy styles (computed)
		for k, v := range styles {
			r.Styles[n][k] = v
		}

		// Copy attributes (non-style)
		for k, v := range attrs {
			r.Attributes[n][k] = v
		}
	}
	return nil
}

// nodeVarState collects the custom properties and the var() references of
// an element.
type nodeVarState struct {
	// custom property declarations per pseudo element prefix ("" for the
	// element itself), cascade order
	decls map[string][]varDecl
	// custom property declarations of the style attribute, they win over
	// the stylesheet
	inline []varDecl
	// declarations with var() references, the value is filled in later
	refs     []varRef
	haveVars *bool
}

// varRef is a declaration whose value contains var(). idx is the position
// in the virtual attribute list.
type varRef struct {
	idx    int
	key    string // property name without prefix
	prefix string // pseudo element prefix such as "before::"
	src    string // source text of the value
}

// htmlValue serializes the value of a declaration for the HTML renderer.
func htmlValue(key string, toks tokenstream) string {
	v := stringValue(toks)
	switch key {
	case "content", "list-style-type":
		v = trimQuotes(v)
	}
	return v
}

// add appends a declaration to the virtual attribute list virt and returns
// the new list. Custom properties are kept in st.
func (st *nodeVarState) add(virt []html.Attribute, prefix string, single qrule, inline bool) []html.Attribute {
	// The scanner splits "--name" into "-" and "-name", stringValue does
	// not restore it, so check the source text.
	if name := sourceString(single.Key); isCustomProperty(name) {
		d := varDecl{name: name, value: sourceString(single.Value)}
		if inline {
			st.inline = append(st.inline, d)
		} else {
			if st.decls == nil {
				st.decls = map[string][]varDecl{}
			}
			st.decls[prefix] = append(st.decls[prefix], d)
		}
		*st.haveVars = true
		return virt
	}
	key := stringValue(single.Key)
	if src := sourceString(single.Value); hasVar(src) {
		st.refs = append(st.refs, varRef{idx: len(virt), key: key, prefix: prefix, src: src})
		*st.haveVars = true
		return append(virt, html.Attribute{Key: "!" + prefix + key})
	}
	return append(virt, html.Attribute{Key: "!" + prefix + key, Val: htmlValue(key, single.Value)})
}

// resolveNodeVars computes the custom properties of every element below n
// and fills in the values of the declarations with var(). Declarations that
// cannot be resolved are removed from the virtual attribute lists. The root
// element inherits the initial values (from the layout commands around the
// HTML content), and they win over its own declarations: :root matches the
// root of the layout chain as well as the html element, a :root rule must
// not reset the values of the layout commands in between.
func resolveNodeVars(n *html.Node, initial map[string]string, varState map[*html.Node]*nodeVarState, nodeVirtAttrs map[*html.Node][]html.Attribute) {
	warned := map[string]bool{}
	warnAll := func(errs []error) {
		for _, err := range errs {
			warnDropped(warned, "", err)
		}
	}
	var walk func(n *html.Node, inherited map[string]string)
	walk = func(n *html.Node, inherited map[string]string) {
		vars := inherited
		if st := varState[n]; st != nil && n.Type == html.ElementNode {
			var errs []error
			if len(st.decls[""])+len(st.inline) > 0 {
				own := append(append([]varDecl{}, st.decls[""]...), st.inline...)
				vars, errs = computeVars(inherited, own)
				warnAll(errs)
				if n.Parent != nil && n.Parent.Type == html.DocumentNode && len(initial) > 0 {
					// vars is a new map here
					maps.Copy(vars, initial)
				}
			}
			if len(st.refs) > 0 {
				virt := nodeVirtAttrs[n]
				pseudoVars := map[string]map[string]string{"": vars}
				drop := map[int]bool{}
				for _, ref := range st.refs {
					pv, ok := pseudoVars[ref.prefix]
					if !ok {
						pv, errs = computeVars(vars, st.decls[ref.prefix])
						warnAll(errs)
						pseudoVars[ref.prefix] = pv
					}
					val, err := resolveValue(ref.src, pv)
					if err != nil {
						warnDropped(warned, ref.prefix+ref.key, err)
						drop[ref.idx] = true
						continue
					}
					virt[ref.idx].Val = htmlValue(ref.key, parseCSSString(val))
				}
				if len(drop) > 0 {
					kept := virt[:0]
					for i, a := range virt {
						if !drop[i] {
							kept = append(kept, a)
						}
					}
					virt = kept
				}
				nodeVirtAttrs[n] = virt
			}
		}
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			walk(c, vars)
		}
	}
	walk(n, initial)
}
