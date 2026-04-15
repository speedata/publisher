package css

import (
	"fmt"
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
			selector := block.ComponentValues.String()
			selectors, err := cascadia.ParseGroupWithPseudoElements(selector)
			if err != nil {
				// Keep going; bad selectors should not break the whole tree
				// (previous code printed error, we do the same semantics-wise)
				continue
			}
			for _, sel := range selectors {
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

			// Inline style: parse and append as !key=value (kept as a single "layer")
			if styleStr, has := sel.Attr("style"); has && styleStr != "" {
				for k, v := range keyValueFromToks(parseCSSString(styleStr)) {
					virt = append(virt, html.Attribute{
						Key: "!" + k,
						Val: v,
					})
				}
			}

			// Store the virtual slice temporarily in the node's DataAtom via map (cannot extend Node).
			// We re-attach via closure below to keep code simple.
			// We will finalize (resolveAttributes) after adding stylesheet rules.
			// To avoid a big side structure, we attach via a local map keyed by *html.Node.

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
				for _, single := range sr.rule {
					bareKey := stringValue(single.Key)
					k := prefix + bareKey
					v := stringValue(single.Value)
					switch bareKey {
					case "content", "list-style-type":
						v = trimQuotes(v)
					}
					virt = append(virt, html.Attribute{
						Key: "!" + k,
						Val: v,
					})
				}
				nodeVirtAttrs[n] = virt
			}
		}
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
