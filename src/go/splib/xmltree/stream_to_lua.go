package xmltree

import (
	"encoding/xml"
	"io"
	"strings"

	"golang.org/x/net/html/charset"
)

// ParseXMLToLua parses XML from r and builds Lua tables directly on the Lua
// stack via l, without constructing an intermediate Go tree. This dramatically
// reduces peak memory usage for large data files because only the Lua
// representation exists in memory.
//
// XInclude (xi:include) elements are handled by falling back to the tree-based
// parser for the included file (which is typically small) and then rendering
// its nodes inline.
//
// On success the Lua stack contains one value: the document table.
func ParseXMLToLua(r io.Reader, l LuaStater, opts *Options, filename string) error {
	nr, err := charset.NewReader(r, "text/xml;charset=utf-8")
	if err != nil {
		return err
	}
	dec := xml.NewDecoder(nr)
	dec.CharsetReader = func(label string, input io.Reader) (io.Reader, error) { return input, nil }
	dec.Entity = xml.HTMLEntity

	dataMode := opts != nil && opts.DataMode
	ignoreEOL := opts != nil && opts.IgnoreEOL

	var ns stackmap
	idCounter := 1

	// Track the next child index per nesting level.
	type level struct {
		childIdx int
	}
	stack := []level{{childIdx: 1}} // document level

	// Create the document table.
	if !l.CheckStack(stackHeadroom) {
		return errStackExhausted
	}
	l.CreateTable(0, 1)
	l.AddStringValueToTable(-1, ".__type", "document")

	for {
		tok, err := dec.Token()
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}

		// Reserve headroom for whatever this iteration pushes. Each
		// nesting level leaves child-index + element table on the stack
		// until the EndElement pops them, so checkstack must be called
		// per-iteration (not just once up front).
		if !l.CheckStack(stackHeadroom) {
			return errStackExhausted
		}

		switch v := tok.(type) {
		case xml.StartElement:
			// ---- XInclude ------------------------------------------------
			if v.Name.Space == xiNS && v.Name.Local == "include" {
				var href string
				for _, a := range v.Attr {
					if a.Name.Local == "href" && a.Name.Space == "" {
						href = a.Value
						break
					}
				}
				if href != "" && opts != nil && opts.ResolveInclude != nil {
					rc, incErr := opts.ResolveInclude(href)
					if incErr != nil {
						return incErr
					}
					if rc != nil {
						// Parse included file into a Go tree (included
						// files are small layout fragments).
						incDoc, incErr := parseXMLInternal(rc, opts, href)
						rc.Close()
						if incErr != nil {
							return incErr
						}
						// Render included children inline.
						cur := &stack[len(stack)-1]
						for _, ch := range incDoc.Children {
							if ch.Elem != nil && ch.Elem.LocalName == "Layout" &&
								ch.Elem.Namespace == "urn:speedata.de:2009/publisher/en" {
								// Flatten: include the children of <Layout>.
								for _, lch := range ch.Elem.Children {
									l.PushInt(cur.childIdx)
									if lch.Elem != nil {
										pushElement(l, lch.Elem)
									} else if lch.Text != nil {
										l.PushString(*lch.Text)
									}
									l.RawSet(-3)
									cur.childIdx++
								}
							} else {
								l.PushInt(cur.childIdx)
								if ch.Elem != nil {
									pushElement(l, ch.Elem)
								} else if ch.Text != nil {
									l.PushString(*ch.Text)
								}
								l.RawSet(-3)
								cur.childIdx++
							}
						}
					}
				}
				continue
			}

			// ---- Normal element ------------------------------------------
			ns.Push()

			// Collect xmlns declarations.
			for _, a := range v.Attr {
				if a.Name.Space == "xmlns" {
					ns.Set(a.Value, a.Name.Local)
				} else if a.Name.Local == "xmlns" {
					ns.Set(a.Value, "")
				}
			}

			name := v.Name.Local
			if sp := v.Name.Space; sp != "" {
				if pfx, ok := ns.Get(sp); ok && pfx != "" {
					name = pfx + ":" + name
				}
			}

			line, _ := dec.InputPos()

			// Push child index for later RawSet into parent table.
			cur := &stack[len(stack)-1]
			l.PushInt(cur.childIdx)
			cur.childIdx++

			// Count non-xmlns attributes for size hint.
			attrCount := 0
			for _, a := range v.Attr {
				if a.Name.Space != "xmlns" && a.Name.Local != "xmlns" {
					attrCount++
				}
			}

			// In DataMode we omit .__file and .__ns (except on the
			// root element where .__ns is read by the XPath context
			// setup). We also skip .__namespace when empty.
			isRootElement := len(stack) == 1 // direct child of document
			includeNS := !dataMode || isRootElement
			includeNamespace := !dataMode || v.Name.Space != ""

			// Count hash fields for accurate size hint.
			nrec := 6 // .__type, .__id, .__name, .__local_name, .__line, .__attributes
			if includeNamespace {
				nrec++ // .__namespace
			}
			if includeNS {
				nrec++ // .__ns
			}
			if !dataMode {
				nrec++ // .__file
			}
			l.CreateTable(0, nrec)
			l.AddStringValueToTable(-1, ".__type", "element")
			l.AddIntValueToTable(-1, ".__id", idCounter)
			l.AddStringValueToTable(-1, ".__name", name)
			l.AddStringValueToTable(-1, ".__local_name", v.Name.Local)
			if includeNamespace {
				l.AddStringValueToTable(-1, ".__namespace", v.Name.Space)
			}
			l.AddIntValueToTable(-1, ".__line", line)
			if !dataMode {
				l.AddStringValueToTable(-1, ".__file", filename)
			}
			idCounter++

			// .__attributes
			l.PushString(".__attributes")
			l.CreateTable(0, attrCount)
			foreignAttrCount := 0
			for _, a := range v.Attr {
				if a.Name.Space == "xmlns" || a.Name.Local == "xmlns" {
					continue
				}
				if !dataMode && a.Name.Space != "" {
					foreignAttrCount++
				}
				l.AddStringValueToTable(-1, a.Name.Local, a.Value)
			}
			l.RawSet(-3)

			// .__foreign_attributes (layout XML only): set of local names
			// of attributes that live in another namespace (xml:lang,
			// user annotations, ...). The unknown-attribute warning must
			// skip these.
			if foreignAttrCount > 0 {
				l.PushString(".__foreign_attributes")
				l.CreateTable(0, foreignAttrCount)
				for _, a := range v.Attr {
					if a.Name.Space != "" && a.Name.Space != "xmlns" {
						l.AddStringValueToTable(-1, a.Name.Local, "true")
					}
				}
				l.RawSet(-3)
			}

			// .__ns (prefix -> URI) — only for layout XML or the
			// data root element.
			if includeNS {
				nsMap := ns.GetPrefixToURIMap()
				l.PushString(".__ns")
				l.CreateTable(0, len(nsMap))
				for pfx, uri := range nsMap {
					l.AddStringValueToTable(-1, pfx, uri)
				}
				l.RawSet(-3)
			}

			// Push new nesting level.
			stack = append(stack, level{childIdx: 1})

		case xml.CharData:
			if len(stack) == 0 {
				continue
			}
			text := string(v.Copy())
			if ignoreEOL {
				text = strings.ReplaceAll(text, "\n", " ")
			}
			// Ignore pure whitespace at document level.
			if len(stack) == 1 && strings.TrimSpace(text) == "" {
				continue
			}

			cur := &stack[len(stack)-1]
			l.PushInt(cur.childIdx)
			l.PushString(text)
			l.RawSet(-3) // parent_table[childIdx] = text
			cur.childIdx++

		case xml.EndElement:
			// Skip EndElement for xi:include (we didn't push anything).
			if v.Name.Space == xiNS && v.Name.Local == "include" {
				continue
			}
			ns.Pop()
			stack = stack[:len(stack)-1]

			if len(stack) > 0 {
				// Stack has: [..., parent_table, child_index, this_table]
				// RawSet pops child_index + this_table and sets
				// parent_table[child_index] = this_table.
				l.RawSet(-3)
			}
		}
	}

	return nil
}
