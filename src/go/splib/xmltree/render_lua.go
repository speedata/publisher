package xmltree

// LuaStater defines the minimal interface required to build a Lua table.
// Methods are exported so external types (like *LuaState) can implement it.
type LuaStater interface {
	CreateTable(narr, nrec int)
	AddKeyValueToTable(idx int, key string, value any)
	RawSet(idx int)
	PushInt(v int)
	PushString(s string)
}

// RenderToLua converts a parsed XML tree (Node) into a Lua table representation
// following your original format (. __type, . __ns, numbered children, etc.).
func RenderToLua(l LuaStater, doc *Node) {
	l.CreateTable(0, 1)
	l.AddKeyValueToTable(-1, ".__type", "document")

	// Add child elements or text nodes as numbered indices
	idx := 1
	for _, ch := range doc.Children {
		l.PushInt(idx)
		if ch.Text != nil {
			l.PushString(*ch.Text)
			l.RawSet(-3)
		} else if ch.Elem != nil {
			pushElement(l, ch.Elem)
			l.RawSet(-3)
		}
		idx++
	}
}

// pushElement builds a Lua table for a single XML element node.
func pushElement(l LuaStater, n *Node) {
	l.CreateTable(0, 8)

	l.AddKeyValueToTable(-1, ".__type", "element")
	l.AddKeyValueToTable(-1, ".__id", n.ID)
	l.AddKeyValueToTable(-1, ".__name", n.Name)
	l.AddKeyValueToTable(-1, ".__local_name", n.LocalName)
	l.AddKeyValueToTable(-1, ".__namespace", n.Namespace)
	l.AddKeyValueToTable(-1, ".__line", n.Line)
	l.AddKeyValueToTable(-1, ".__file", n.File)
	l.AddKeyValueToTable(-1, ".__col", n.Col)

	// .__attributes
	l.PushString(".__attributes")
	l.CreateTable(0, len(n.Attrs))
	for k, v := range n.Attrs {
		l.AddKeyValueToTable(-1, k, v)
	}
	l.RawSet(-3)

	// .__ns (prefix -> URI)
	l.PushString(".__ns")
	l.CreateTable(0, len(n.NS))
	for pfx, uri := range n.NS {
		l.AddKeyValueToTable(-1, pfx, uri)
	}
	l.RawSet(-3)

	// Children (mixed content)
	idx := 1
	for _, ch := range n.Children {
		l.PushInt(idx)
		if ch.Text != nil {
			l.PushString(*ch.Text)
		} else if ch.Elem != nil {
			pushElement(l, ch.Elem)
		}
		l.RawSet(-3)
		idx++
	}
}
