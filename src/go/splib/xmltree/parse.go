package xmltree

import (
	"encoding/xml"
	"io"
	"strings"

	"golang.org/x/net/html/charset"
)

// stackmap keeps track of namespace bindings using a stack of maps.
// Each level represents the in-scope namespaces for that element depth.
type stackmap struct {
	m []map[string]string // URI -> prefix
}

func (sm *stackmap) ensureTop() {
	if len(sm.m) == 0 {
		sm.m = append(sm.m, make(map[string]string))
	}
}

func (sm *stackmap) Set(uri, prefix string) {
	sm.ensureTop()
	sm.m[len(sm.m)-1][uri] = prefix
}

func (sm *stackmap) Get(uri string) (string, bool) {
	if len(sm.m) == 0 {
		return "", false
	}
	v, ok := sm.m[len(sm.m)-1][uri]
	return v, ok
}

func (sm *stackmap) GetPrefixToURIMap() map[string]string {
	out := map[string]string{}
	if len(sm.m) == 0 {
		return out
	}
	for uri, pfx := range sm.m[len(sm.m)-1] {
		out[pfx] = uri
	}
	return out
}

func (sm *stackmap) Push() {
	// Always push a new map (even if stack empty)
	var base map[string]string
	if len(sm.m) == 0 {
		base = map[string]string{}
	} else {
		base = sm.m[len(sm.m)-1]
	}
	copyMap := make(map[string]string, len(base))
	for k, v := range base {
		copyMap[k] = v
	}
	sm.m = append(sm.m, copyMap)
}

func (sm *stackmap) Pop() {
	if len(sm.m) > 0 {
		sm.m = sm.m[:len(sm.m)-1]
	}
}

const xiNS = "http://www.w3.org/2001/XInclude"

// Options allows customizing parsing behavior (e.g., XInclude resolution).
type Options struct {
	// ResolveInclude should open and return the content for a given href.
	// Return (nil, nil) to skip/leave the xi:include unexpanded.
	ResolveInclude func(href string) (io.ReadCloser, error)

	// DataMode omits metadata fields that are only needed for layout XML
	// (.__file, .__col) to reduce memory usage for large data files.
	DataMode bool

	// IgnoreEOL replaces newline characters with spaces in text nodes
	// during parsing, avoiding a separate post-processing pass.
	IgnoreEOL bool
}

// ParseXML is a convenience wrapper for ParseXMLWithOptions with nil options.
func ParseXML(r io.Reader) (*Node, error) {
	return ParseXMLWithOptions(r, nil)
}

// ParseXMLWithOptions parses XML from r into a tree of Nodes.
func ParseXMLWithOptions(r io.Reader, opts *Options) (*Node, error) {
	return parseXMLInternal(r, opts, "")
}

// ParseXMLWithOptionsAndFilename is like ParseXMLWithOptions, but also
// provides a filename for error reporting and for the File field of Nodes.
func ParseXMLWithOptionsAndFilename(r io.Reader, opts *Options, filename string) (*Node, error) {
	return parseXMLInternal(r, opts, filename)
}

// parseXMLInternal does the actual parsing work, with options and filename for error reporting.
func parseXMLInternal(r io.Reader, opts *Options, filename string) (*Node, error) {
	nr, err := charset.NewReader(r, "text/xml;charset=utf-8")
	if err != nil {
		return nil, err
	}
	dec := xml.NewDecoder(nr)
	dec.CharsetReader = func(label string, input io.Reader) (io.Reader, error) { return input, nil }
	dec.Entity = xml.HTMLEntity

	doc := &Node{
		Type:      Document,
		Name:      "document",
		LocalName: "document",
		File:      filename,
		Attrs:     map[string]string{},
		NS:        map[string]string{},
	}

	var (
		ns        stackmap
		idCounter = 1
		stack     = []*Node{doc}
	)

	for {
		tok, err := dec.Token()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}

		switch v := tok.(type) {
		case xml.StartElement:
			// Handle XInclude specially: do NOT push NS stack, do NOT push node stack.
			if v.Name.Space == xiNS && v.Name.Local == "include" {
				var href string
				for _, a := range v.Attr {
					if a.Name.Local == "href" && a.Name.Space == "" {
						href = a.Value
						break
					}
				}
				if href != "" && opts != nil && opts.ResolveInclude != nil {
					rc, err := opts.ResolveInclude(href)
					if err != nil {
						return nil, err
					}
					if rc != nil {
						incDoc, err := parseXMLInternal(rc, opts, href)
						rc.Close()
						if err != nil {
							return nil, err
						}

						// current parent element in the main file
						parent := stack[len(stack)-1]

						// Flatten: include the *children* of the included root(s)
						for _, ch := range incDoc.Children {
							if ch.Elem != nil && ch.Elem.LocalName == "Layout" &&
								ch.Elem.Namespace == "urn:speedata.de:2009/publisher/en" {
								parent.Children = append(parent.Children, ch.Elem.Children...)
							} else {
								parent.Children = append(parent.Children, ch)
							}
						}
					}
				}
				// We consumed the include; skip creating any element for it.
				continue
			}

			// Normal element
			ns.Push()

			// Collect xmlns declarations
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

			line, col := dec.InputPos()
			n := &Node{
				Type:      Element,
				Name:      name,
				LocalName: v.Name.Local,
				Namespace: v.Name.Space,
				Line:      line,
				File:      filename,
				Col:       col,
				ID:        idCounter,
				Attrs:     map[string]string{},
				NS:        ns.GetPrefixToURIMap(),
			}
			idCounter++

			for _, a := range v.Attr {
				if a.Name.Space == "xmlns" || a.Name.Local == "xmlns" {
					continue
				}
				n.Attrs[a.Name.Local] = a.Value
			}

			parent := stack[len(stack)-1]
			parent.Children = append(parent.Children, Child{Elem: n})
			stack = append(stack, n)

		case xml.CharData:
			if len(stack) == 0 {
				continue
			}
			text := string(v.Copy())
			// Ignore pure whitespace at document level
			if len(stack) == 1 && strings.TrimSpace(text) == "" {
				continue
			}
			parent := stack[len(stack)-1]
			parent.Children = append(parent.Children, Child{Text: &text})

		case xml.EndElement:
			// Skip EndElement for xi:include (we didn't push anything at StartElement)
			if v.Name.Space == xiNS && v.Name.Local == "include" {
				continue
			}
			ns.Pop()
			if len(stack) > 1 {
				stack = stack[:len(stack)-1]
			}
		}
	}

	return doc, nil
}
