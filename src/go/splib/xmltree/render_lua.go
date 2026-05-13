package xmltree

import "errors"

// errStackExhausted is returned when the Lua stack cannot be grown further.
// In practice this requires deeply pathological input (hundreds of thousands
// of nesting levels) and is virtually never hit; it exists so a hard limit
// surfaces as a clean error instead of undefined behaviour.
var errStackExhausted = errors.New("Lua stack could not be grown (LUAI_MAXSTACK reached)")

// LuaStater defines the minimal interface required to build a Lua table.
// Methods are exported so external types (like *LuaState) can implement it.
// The Add*ValueToTable helpers are typed so the parser's hot path does not
// route every key/value through an interface{} box.
type LuaStater interface {
	CheckStack(n int) bool
	CreateTable(narr, nrec int)
	AddStringValueToTable(idx int, key, value string)
	AddIntValueToTable(idx int, key string, value int)
	AddBoolValueToTable(idx int, key string, value bool)
	RawSet(idx int)
	PushInt(v int)
	PushString(s string)
}

// stackHeadroom is the number of Lua stack slots reserved before each
// element push. Covers the worst-case push pattern in a single element:
// child-index + element table + .__attributes key/table (+ 2 per attr
// transiently) + .__ns key/table — with comfortable margin. Lua's default
// LUA_MINSTACK is only 20, so this must be requested explicitly on every
// iteration via lua_checkstack.
const stackHeadroom = 16

// RenderToLua converts a parsed XML tree (Node) into a Lua table representation
// following your original format (. __type, . __ns, numbered children, etc.).
func RenderToLua(l LuaStater, doc *Node) {
	l.CheckStack(stackHeadroom)
	l.CreateTable(len(doc.Children), 1)
	l.AddStringValueToTable(-1, ".__type", "document")

	// Add child elements or text nodes as numbered indices
	idx := 1
	for _, ch := range doc.Children {
		l.CheckStack(stackHeadroom)
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
	l.CheckStack(stackHeadroom)
	l.CreateTable(len(n.Children), 10)

	l.AddStringValueToTable(-1, ".__type", "element")
	l.AddIntValueToTable(-1, ".__id", n.ID)
	l.AddStringValueToTable(-1, ".__name", n.Name)
	l.AddStringValueToTable(-1, ".__local_name", n.LocalName)
	l.AddStringValueToTable(-1, ".__namespace", n.Namespace)
	l.AddIntValueToTable(-1, ".__line", n.Line)
	l.AddStringValueToTable(-1, ".__file", n.File)
	l.AddIntValueToTable(-1, ".__col", n.Col)

	// .__attributes
	l.PushString(".__attributes")
	l.CreateTable(0, len(n.Attrs))
	for k, v := range n.Attrs {
		l.AddStringValueToTable(-1, k, v)
	}
	l.RawSet(-3)

	// .__ns (prefix -> URI)
	l.PushString(".__ns")
	l.CreateTable(0, len(n.NS))
	for pfx, uri := range n.NS {
		l.AddStringValueToTable(-1, pfx, uri)
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
