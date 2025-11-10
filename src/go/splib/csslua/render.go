package csslua

import (
	"sort"
	"strings"

	"golang.org/x/net/html"

	csspkg "speedatapublisher/css"
)

// LuaStater matches the xmltree interface: implement it for *LuaState once.
type LuaStater interface {
	CreateTable(narr, nrec int)
	AddKeyValueToTable(idx int, key string, value any)
	RawSet(idx int)
	PushInt(v int)
	PushString(s string)
}

type mode int

const (
	modeHorizontal mode = iota
	modeVertical
)

func (m mode) String() string {
	if m == modeHorizontal {
		return "→"
	}
	return "↓"
}

// Render builds the same structure as your old string dumper, but directly on the Lua stack.
func Render(l LuaStater, res *csspkg.Result) {
	// Top-level table: { typ="csshtmltree", lang=?, fontfamilies=?, pages=?, [1]=root }
	l.CreateTable(0, 4)
	l.AddKeyValueToTable(-1, "typ", "csshtmltree")
	if res.Lang != "" {
		l.AddKeyValueToTable(-1, "lang", res.Lang)
	}
	pushFontFamilies(l, res)
	pushPages(l, res)

	// Root element as [1]
	l.PushInt(1)
	pushNode(l, res, res.Root, modeVertical, false)
	l.RawSet(-3)
}

func pushFontFamilies(l LuaStater, res *csspkg.Result) {
	// Push "fontfamilies" table
	l.PushString("fontfamilies")
	l.CreateTable(0, len(res.Fontfamilies))

	// Optional: deterministic order
	names := make([]string, 0, len(res.Fontfamilies))
	for n := range res.Fontfamilies {
		names = append(names, n)
	}
	sort.Strings(names)

	for _, name := range names {
		ff := res.Fontfamilies[name]

		l.PushString(name)
		// Always create the 4 variants as keys: regular, bold, bolditalic, italic
		l.CreateTable(0, 4)

		emitFontVariant(l, "regular", ff.Regular)
		emitFontVariant(l, "bold", ff.Bold)
		emitFontVariant(l, "bolditalic", ff.BoldItalic)
		emitFontVariant(l, "italic", ff.Italic)

		l.RawSet(-3) // set family table
	}

	l.RawSet(-3) // set "fontfamilies"
}

// emitFontVariant creates a nested table for a single font variant.
// It always creates a table (even if empty) to match the desired shape.
func emitFontVariant(l LuaStater, key string, src csspkg.FontSource) {
	l.PushString(key)
	// We may have up to 2 fields: url, local. Create empty table if none.
	// (record count is just a hint)
	rec := 0
	if src.URL != "" {
		rec++
	}
	if src.Local != "" {
		rec++
	}
	l.CreateTable(0, rec)

	if src.URL != "" {
		l.AddKeyValueToTable(-1, "url", src.URL)
	}
	if src.Local != "" {
		l.AddKeyValueToTable(-1, "local", src.Local)
	}

	l.RawSet(-3)
}

func pushPages(l LuaStater, res *csspkg.Result) {
	// Note: If res.Pages is already normalized, we can just dump it.
	l.PushString("pages")
	l.CreateTable(0, len(res.Pages))
	for k, p := range res.Pages {
		key := k
		if key == "" {
			key = "*"
		}
		l.PushString(key)
		l.CreateTable(0, 8)

		// Expand shorthand attributes of page here if they aren't already normalized.
		styles, _ := resolveAttributes(p.Attributes)
		for k2, v2 := range styles {
			l.AddKeyValueToTable(-1, k2, v2)
		}
		wd, ht := papersize(p.Papersize)
		l.AddKeyValueToTable(-1, "width", wd)
		l.AddKeyValueToTable(-1, "height", ht)

		for area, rules := range p.Pagearea {
			l.PushString(area)
			l.CreateTable(0, len(rules))
			for _, r := range rules {
				l.AddKeyValueToTable(-1, r.Key, r.Value.String())
			}
			l.RawSet(-3)
		}
		l.RawSet(-3)
	}
	l.RawSet(-3)
}

// Returns the flow direction for node `tag`.
// Priority:
// 1) computed CSS 'display' (if present)
// 2) known block/inline tag lists
// 3) otherwise: keep parent direction unchanged
func flowDirByStyle(tag string, styles map[string]string, parent mode) mode {
	// 1) Computed display has highest priority.
	if d, ok := styles["display"]; ok {
		switch strings.ToLower(d) {
		case "block", "list-item", "table", "flex", "grid", "flow-root":
			return modeVertical
		case "inline", "inline-block", "inline-flex", "inline-grid", "inline-table", "ruby", "run-in":
			return modeHorizontal
		default:
			// Unknown display value → fall through
		}
	}

	// 2) Tag-based fallback for *known* elements only.
	if isBlockElement(tag) {
		return modeVertical
	}
	if isInlineishElement(tag) {
		return modeHorizontal
	}

	// 3) Unknown tag → keep parent's direction
	return parent
}

func hasBlockyElementChild(node *html.Node, res *csspkg.Result) bool {
	for c := node.FirstChild; c != nil; c = c.NextSibling {
		if c.Type != html.ElementNode {
			continue
		}
		st := res.Styles[c]
		if st != nil {
			if d, ok := st["display"]; ok {
				switch strings.ToLower(d) {
				case "block", "list-item", "table", "flex", "grid", "flow-root",
					"table-row-group", "table-header-group", "table-footer-group",
					"table-row", "table-cell":
					return true
				}
			}
		}
		if isBlockElement(c.Data) {
			return true
		}
		if isInlineishElement(c.Data) {
			return false
		}
		// Unknown child without display: keep scanning siblings; in your trees,
		// the first element child is typically decisive (e.g., <table>).
	}
	return false
}

// Decide if an element should be marked as block-level in output.
// Priority: computed display > known tags > otherwise false.
func isBlockByStyle(tag string, styles map[string]string) bool {
	if d, ok := styles["display"]; ok {
		d = strings.ToLower(d)
		switch d {
		case "block", "list-item", "table", "flex", "grid", "flow-root":
			return true
		case "inline", "inline-block", "inline-flex", "inline-grid", "inline-table", "ruby", "run-in":
			return false
		}
		// Unknown display -> fall through
	}
	if isBlockElement(tag) {
		return true
	}
	if isInlineishElement(tag) {
		return false
	}
	// Unknown tag: keep parent direction elsewhere; here we don't assert "block"
	return false
}

func pushNode(l LuaStater, res *csspkg.Result, n *html.Node, dir mode, ws bool) {
	switch n.Type {
	case html.TextNode:
		txt := normalizeText(n.Data, ws)
		if txt == "" {
			return
		}
		// Caller must set the index before calling pushNode for text nodes.
		l.PushString(txt)
		return

	case html.ElementNode:
		st := res.Styles[n]
		if st == nil {
			st = map[string]string{}
		}

		// Decide flow direction using display > known tags > keep parent
		newDir := flowDirByStyle(n.Data, st, dir)

		l.CreateTable(0, 8)
		l.AddKeyValueToTable(-1, "elementname", n.Data)
		l.AddKeyValueToTable(-1, "direction", newDir.String())

		// Emit "block = true" only if the element is effectively block-level
		// (same precedence as flowDir: display first, then known tags).
		if isBlockByStyle(n.Data, st) {
			l.AddKeyValueToTable(-1, "block", true)
		}

		// ----- styles (computed) -----
		// Add derived fields before deciding whether to emit the table
		// 1) Default font-family-number if font-family exists and number missing
		if _, ok := st["font-family"]; ok {
			if _, ok2 := st["font-family-number"]; !ok2 {
				st["font-family-number"] = "0"
			}
		}
		// 2) Compute has_border
		hb := hasBorder(st)

		// Only create styles table if we have any entries or hb == true
		if len(st) > 0 || hb {
			l.PushString("styles")
			// +1 to hold has_border if we add it
			l.CreateTable(0, len(st)+1)
			for k, v := range st {
				l.AddKeyValueToTable(-1, k, v)
			}
			l.AddKeyValueToTable(-1, "has_border", hb)
			l.RawSet(-3)
		}

		// ----- attributes (computed) -----
		at := res.Attributes[n]
		if len(at) > 0 {
			l.PushString("attributes")
			l.CreateTable(0, len(at))
			for k, v := range at {
				l.AddKeyValueToTable(-1, k, v)
			}
			l.RawSet(-3)
		}

		// White-space policy for children
		ws := false
		if v, ok := st["white-space"]; ok && v == "pre" {
			ws = true
		}

		// Children as [1], [2], ...
		idx := 1

		// Start sibling flow with this element’s *own* direction.
		siblingDir := newDir

		for ch := n.FirstChild; ch != nil; ch = ch.NextSibling {
			switch ch.Type {
			case html.TextNode:
				txt := normalizeText(ch.Data, ws)
				if txt == "" {
					continue
				}
				// Text in a vertical flow flips the *subsequent sibling flow* to horizontal.
				if siblingDir == modeVertical {
					siblingDir = modeHorizontal
				}
				l.PushInt(idx)
				l.PushString(txt)
				l.RawSet(-3)
				idx++

			case html.ElementNode:
				// Compute the child’s direction with this precedence:
				// 1) computed display (if present)
				// 2) known block/inline elements
				// 3) unknown-without-display → inherit *current sibling flow*
				stChild := res.Styles[ch]
				if stChild == nil {
					stChild = map[string]string{}
				}

				childDir := func() mode {
					if d, ok := stChild["display"]; ok {
						d = strings.ToLower(d)
						switch d {
						case "block", "list-item", "table", "flex", "grid", "flow-root",
							"table-row-group", "table-header-group", "table-footer-group",
							"table-row", "table-cell":
							return modeVertical
						case "inline", "inline-block", "inline-flex", "inline-grid",
							"inline-table", "ruby", "run-in":
							return modeHorizontal
						}
						// Unknown display → fall through
					}
					if isBlockElement(ch.Data) {
						return modeVertical
					}
					if isInlineishElement(ch.Data) {
						return modeHorizontal
					}
					// Unknown, no display → inherit *current sibling flow*
					return siblingDir
				}()

				// Safety valve: if this is an unknown-without-display and it obviously
				// contains block/table structure, keep it vertical even if siblingDir is horizontal.
				if _, hasDisp := stChild["display"]; !hasDisp &&
					!isBlockElement(ch.Data) && !isInlineishElement(ch.Data) &&
					childDir == modeHorizontal && hasBlockyElementChild(ch, res) {
					childDir = modeVertical
				}

				l.PushInt(idx)
				pushNode(l, res, ch, childDir, ws)
				l.RawSet(-3)
				idx++

			default:
				// ignore
			}
		}
	}
}
