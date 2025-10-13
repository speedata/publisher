package xmltree

import (
	"io"
	"strings"
	"testing"
)

// elems filters direct element-children (ignores text nodes).
func elems(n *Node) []*Node {
	var out []*Node
	for _, ch := range n.Children {
		if ch.Elem != nil {
			out = append(out, ch.Elem)
		}
	}
	return out
}

// firstText returns the first direct text child of a node (or empty string).
func firstText(n *Node) string {
	for _, ch := range n.Children {
		if ch.Text != nil {
			return *ch.Text
		}
	}
	return ""
}

func TestParseXML_XInclude_Flattened(t *testing.T) {
	mainXML := `
<Layout
  xmlns:sd="urn:speedata:2009/publisher/functions/en"
  xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:xi="http://www.w3.org/2001/XInclude"
  version="4.5.1">
  <Pageformat height="5cm" width="4cm" />
  <xi:include href="include.xml" />
  <xi:include href="include2.xml" />
  <Record element="data">
    <PlaceObject>
      <Textblock>
        <Paragraph>
          <Value select="$myvar"/>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>`

	include1 := `<Layout xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en">
    <SetVariable variable="myvar"><Value>Include 1</Value></SetVariable>
</Layout>`

	include2 := `<Layout xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en">
    <SetVariable variable="myvar2"><Value>Include 2</Value></SetVariable>
</Layout>`

	// XInclude resolver providing in-memory files.
	opts := &Options{
		ResolveInclude: func(href string) (io.ReadCloser, error) {
			switch href {
			case "include.xml":
				return io.NopCloser(strings.NewReader(include1)), nil
			case "include2.xml":
				return io.NopCloser(strings.NewReader(include2)), nil
			default:
				return nil, nil
			}
		},
	}

	doc, err := ParseXMLWithOptions(strings.NewReader(mainXML), opts)
	if err != nil {
		t.Fatalf("ParseXMLWithOptions failed: %v", err)
	}

	// Document → root <Layout>
	docElems := elems(doc)
	if len(docElems) != 1 {
		t.Fatalf("expected 1 root element, got %d", len(docElems))
	}
	root := docElems[0]
	if root.LocalName != "Layout" || root.Namespace != "urn:speedata.de:2009/publisher/en" {
		t.Fatalf("expected root <Layout> in publisher ns, got name=%q ns=%q", root.LocalName, root.Namespace)
	}

	// Expected flattened order under <Layout>:
	// 1) <Pageformat>
	// 2) <SetVariable variable="myvar">...</SetVariable> (from include.xml)
	// 3) <SetVariable variable="myvar2">...</SetVariable> (from include2.xml)
	// 4) <Record>...</Record>
	children := elems(root)
	if len(children) < 4 {
		t.Fatalf("expected at least 4 element children under <Layout>, got %d", len(children))
	}

	// 1) Pageformat
	if children[0].LocalName != "Pageformat" {
		t.Fatalf("expected first child <Pageformat>, got <%s>", children[0].LocalName)
	}
	if children[0].Attrs["height"] != "5cm" || children[0].Attrs["width"] != "4cm" {
		t.Errorf("Pageformat attributes mismatch: height=%q width=%q",
			children[0].Attrs["height"], children[0].Attrs["width"])
	}

	// 2) Flattened from include.xml → SetVariable (myvar)
	set1 := children[1]
	if set1.LocalName != "SetVariable" {
		t.Fatalf("expected second child <SetVariable>, got <%s>", set1.LocalName)
	}
	if v := set1.Attrs["variable"]; v != "myvar" {
		t.Errorf("include1 SetVariable@variable mismatch: %q", v)
	}
	// <SetVariable><Value>Include 1</Value></SetVariable>
	set1Kids := elems(set1)
	if len(set1Kids) != 1 || set1Kids[0].LocalName != "Value" {
		t.Fatalf("expected <SetVariable><Value>…</Value></SetVariable> for include1")
	}
	if txt := strings.TrimSpace(firstText(set1Kids[0])); txt != "Include 1" {
		t.Errorf("include1 Value text mismatch: %q", txt)
	}

	// 3) Flattened from include2.xml → SetVariable (myvar2)
	set2 := children[2]
	if set2.LocalName != "SetVariable" {
		t.Fatalf("expected third child <SetVariable>, got <%s>", set2.LocalName)
	}
	if v := set2.Attrs["variable"]; v != "myvar2" {
		t.Errorf("include2 SetVariable@variable mismatch: %q", v)
	}
	set2Kids := elems(set2)
	if len(set2Kids) != 1 || set2Kids[0].LocalName != "Value" {
		t.Fatalf("expected <SetVariable><Value>…</Value></SetVariable> for include2")
	}
	if txt := strings.TrimSpace(firstText(set2Kids[0])); txt != "Include 2" {
		t.Errorf("include2 Value text mismatch: %q", txt)
	}

	// 4) Record
	if children[3].LocalName != "Record" {
		t.Fatalf("expected fourth child <Record>, got <%s>", children[3].LocalName)
	}
}
