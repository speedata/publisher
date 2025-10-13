package xmltree

// NodeType represents the type of an XML node.
type NodeType string

const (
	Element  NodeType = "element"
	Document NodeType = "document"
	Text     NodeType = "text"
)

// Child represents either a text node or an element node.
// Only one of the fields will be non-nil.
type Child struct {
	Text *string `json:"text,omitempty"`
	Elem *Node   `json:"elem,omitempty"`
}

// Node is a tree representation of XML elements.
type Node struct {
	Type      NodeType          `json:"type"`
	Name      string            `json:"name"`       // Possibly with prefix, e.g. "a:x"
	LocalName string            `json:"local_name"` // Local part only, e.g. "x"
	Namespace string            `json:"namespace"`  // Namespace URI
	File      string            `json:"file,omitempty"`
	Line      int               `json:"line"`
	Col       int               `json:"col"`
	ID        int               `json:"id"`
	Attrs     map[string]string `json:"attributes"` // attributeName -> value
	NS        map[string]string `json:"ns"`         // prefix -> URI
	Children  []Child           `json:"children"`   // mixed content
}
