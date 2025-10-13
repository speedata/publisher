package xmltree

import (
	"encoding/json"
	"strings"
	"testing"
)

// elems returns only element-children of a node (filters out text nodes).

// hasTextSubstr checks whether any direct text child contains the substring s.
func hasTextSubstr(n *Node, s string) bool {
	for _, ch := range n.Children {
		if ch.Text != nil && strings.Contains(*ch.Text, s) {
			return true
		}
	}
	return false
}

func TestParseXMLBasic(t *testing.T) {
	input := `
<root xmlns="urn:base" xmlns:a="urn:one">
  <a:item width="10cm" height="5cm">Hello</a:item>
  <empty />
</root>`

	doc, err := ParseXML(strings.NewReader(input))
	if err != nil {
		t.Fatalf("ParseXML failed: %v", err)
	}

	// Document should have exactly one element child (<root>); ignore top-level whitespace.
	docElems := elems(doc)
	if len(docElems) != 1 {
		// Log tree for debugging to see what's going on
		if b, _ := json.MarshalIndent(doc, "", "  "); b != nil {
			t.Logf("Parsed tree:\n%s", b)
		}
		t.Fatalf("expected 1 root element, got %d", len(docElems))
	}
	root := docElems[0]
	if root.LocalName != "root" || root.Namespace != "urn:base" {
		t.Fatalf("expected <root> in urn:base, got name=%q ns=%q", root.LocalName, root.Namespace)
	}

	// Children of <root>: may include whitespace text nodes; filter to elements.
	rootElems := elems(root)
	if len(rootElems) != 2 {
		if b, _ := json.MarshalIndent(root, "", "  "); b != nil {
			t.Logf("Root subtree:\n%s", b)
		}
		t.Fatalf("expected 2 element children under <root>, got %d", len(rootElems))
	}

	item := rootElems[0]
	if item.Name != "a:item" || item.LocalName != "item" || item.Namespace != "urn:one" {
		t.Errorf("expected first element to be a:item (ns urn:one), got name=%q local=%q ns=%q",
			item.Name, item.LocalName, item.Namespace)
	}
	if got := item.Attrs["width"]; got != "10cm" {
		t.Errorf("wrong width attribute: %q", got)
	}
	if got := item.Attrs["height"]; got != "5cm" {
		t.Errorf("wrong height attribute: %q", got)
	}
	if !hasTextSubstr(item, "Hello") {
		t.Errorf("expected text 'Hello' inside <a:item>")
	}

	empty := rootElems[1]
	if empty.LocalName != "empty" || empty.Namespace != "urn:base" {
		t.Errorf("expected second element to be <empty> in urn:base, got local=%q ns=%q",
			empty.LocalName, empty.Namespace)
	}
}
