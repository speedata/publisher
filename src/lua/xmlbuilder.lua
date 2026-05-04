-- xmlbuilder.lua
-- Minimalistic XML builder library – Lua-idiomatic.

---@class xmlbuilder_module
local xml = {}

-- ========== Utilities ==========

---@param s any Coerced via `tostring`.
---@return string escaped
local function escape_attr(s)
    s = tostring(s)
    s = s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;")
    return s
end

---@param s any
---@return string escaped
local function escape_text(s)
    s = tostring(s)
    s = s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    return s
end

---@class XmlAttrlist
---@field order string[] Insertion-order list of attribute names.
---@field map table<string, any> Name → value map.

-- Returns a fresh empty attribute store that preserves insertion order.
---@return XmlAttrlist
local function new_attrlist()
    return { order = {}, map = {} }
end

---@param attrs XmlAttrlist
---@param name string
---@param value any
---@return nil
local function attr_set(attrs, name, value)
    if attrs.map[name] == nil then
        attrs.map[name] = value
        table.insert(attrs.order, name)
    else
        attrs.map[name] = value
    end
end

-- Iterator over the attributes in insertion order.
---@param attrs XmlAttrlist
---@return fun(): string?, any?
local function attr_pairs(attrs)
    local i = 0
    return function()
        i = i + 1
        local k = attrs.order[i]
        if k then
            return k, attrs.map[k]
        end
    end
end

-- ========== Node Types ==========

---@class XmlElement
---@field _type "element"
---@field name string
---@field attrs XmlAttrlist
---@field text string?
---@field children (XmlElement|XmlPI|XmlComment)[]
---@field parent XmlElement?

---@class XmlPI
---@field _type "pi"
---@field target string
---@field data string
---@field parent? XmlElement

---@class XmlComment
---@field _type "comment"
---@field text string
---@field parent? XmlElement

---@class XmlDocument
---@field _type "document"
---@field prolog { xml_decl: { version: string, encoding?: string, standalone?: boolean, omit: boolean }, nodes: (XmlPI|XmlComment)[] }
---@field root XmlElement?
---@field epilog (XmlPI|XmlComment)[]

local ElementMT, DocumentMT = {}, {}
ElementMT.__index = ElementMT
DocumentMT.__index = DocumentMT

-- ========== Element ==========

-- Creates a new XML element with no attributes and no children.
---@param name string Element name (required).
---@return XmlElement
local function new_element(name)
    return setmetatable({
        _type = "element",
        name = assert(name, "element name required"),
        attrs = new_attrlist(),
        text = nil,
        children = {},
        parent = nil,
    }, ElementMT)
end

-- Appends a new child element to `self`.
---@param self XmlElement
---@param name string
---@return XmlElement child
function ElementMT:add_element(name)
    local child = new_element(name)
    child.parent = self
    table.insert(self.children, child)
    return child
end

-- Sets an attribute on the element, preserving insertion order.
---@param self XmlElement
---@param name string
---@param value any
---@return XmlElement self For chaining.
function ElementMT:set_attr(name, value)
    attr_set(self.attrs, name, value)
    return self
end

-- Sets the element's text content; pass `nil` to clear it.
---@param self XmlElement
---@param s any
---@return XmlElement self
function ElementMT:set_text(s)
    self.text = (s == nil) and nil or tostring(s)
    return self
end

-- Appends an externally constructed node as a child of `self`.
---@param self XmlElement
---@param node XmlElement|XmlPI|XmlComment
---@return XmlElement self
function ElementMT:add_child(node) -- manually add an existing node
    assert(type(node) == "table" and node._type, "invalid node")
    node.parent = self
    table.insert(self.children, node)
    return self
end

-- Appends an XML processing instruction (`<?target data?>`) as a child.
---@param self XmlElement
---@param target string
---@param data? string
---@return XmlPI pi
function ElementMT:add_pi(target, data)
    local pi = { _type = "pi", target = target, data = data or "" }
    pi.parent = self
    table.insert(self.children, pi)
    return pi
end

-- Appends an XML comment (`<!-- text -->`) as a child.
---@param self XmlElement
---@param text? string
---@return XmlComment comment
function ElementMT:add_comment(text)
    local c = { _type = "comment", text = text or "" }
    c.parent = self
    table.insert(self.children, c)
    return c
end

-- Returns the parent of this element (or `nil` for the root).
---@param self XmlElement
---@return XmlElement?
function ElementMT:up() -- return parent node (for chaining)
    return self.parent
end

-- Serializes an element (and its descendants) into the buffer.
---@param el XmlElement
---@param opts { pretty: boolean, indent: string }
---@param depth integer? Recursion depth (used internally).
---@param buf string[]
---@return nil
local function serialize_element(el, opts, depth, buf)
    local indent = opts.pretty and string.rep(opts.indent, depth or 0) or ""
    local newline = opts.pretty and "\n" or ""

    -- Start tag + attributes
    table.insert(buf, indent .. "<" .. el.name)
    for k, v in attr_pairs(el.attrs) do
        table.insert(buf, " " .. k .. '="' .. escape_attr(v) .. '"')
    end

    local has_children = #el.children > 0
    local has_text = el.text ~= nil and el.text ~= ""

    if not has_children and not has_text then
        table.insert(buf, "/>" .. newline)
        return
    end

    table.insert(buf, ">")

    -- Text
    if has_text then
        table.insert(buf, escape_text(el.text))
    end

    -- Children
    if has_children then
        if opts.pretty and not has_text then
            table.insert(buf, newline)
        end
        for _, ch in ipairs(el.children) do
            if ch._type == "element" then
                serialize_element(ch, opts, (depth or 0) + 1, buf)
            elseif ch._type == "pi" then
                local ind = opts.pretty and string.rep(opts.indent, (depth or 0) + 1) or ""
                table.insert(
                    buf,
                    ind
                        .. "<?"
                        .. ch.target
                        .. (ch.data and (" " .. ch.data) or "")
                        .. "?>"
                        .. (opts.pretty and "\n" or "")
                )
            elseif ch._type == "comment" then
                local ind = opts.pretty and string.rep(opts.indent, (depth or 0) + 1) or ""
                table.insert(buf, ind .. "<!--" .. (ch.text or "") .. "-->" .. (opts.pretty and "\n" or ""))
            end
        end
        if opts.pretty and not has_text then
            table.insert(buf, indent)
        end
    end

    -- End tag
    table.insert(buf, "</" .. el.name .. ">" .. newline)
end

-- ========== ProcInst & Comment node makers ==========

-- Creates a stand-alone processing instruction node.
---@param target string
---@param data? string
---@return XmlPI
local function new_pi(target, data)
    return { _type = "pi", target = target, data = data or "" }
end

-- Creates a stand-alone comment node.
---@param text? string
---@return XmlComment
local function new_comment(text)
    return { _type = "comment", text = text or "" }
end

-- ========== Document ==========

-- Creates a fresh empty XML document.
---@return XmlDocument
local function new_document()
    return setmetatable({
        _type = "document",
        prolog = { -- XML declaration optional, plus processing instructions / comments
            xml_decl = { version = "1.0", encoding = nil, standalone = nil, omit = true },
            nodes = {},
        },
        root = nil,
        epilog = {}, -- NEW: nodes (PI/comment) after the root element
    }, DocumentMT)
end

-- Configures the XML declaration `<?xml version="..." encoding="..." standalone="..."?>`.
---@param self XmlDocument
---@param version? string
---@param encoding? string
---@param standalone? boolean
---@return XmlDocument self
function DocumentMT:set_xml_decl(version, encoding, standalone)
    self.prolog.xml_decl = { version = version or "1.0", encoding = encoding, standalone = standalone, omit = false }
    return self
end

-- Adds a processing instruction. Placed in the prolog when called before
-- the root element exists, in the epilog after the root has been added.
---@param self XmlDocument
---@param target string
---@param data? string
---@return XmlPI
function DocumentMT:add_pi(target, data)
    local pi = new_pi(target, data)
    if self.root == nil then
        table.insert(self.prolog.nodes, pi)
    else
        table.insert(self.epilog, pi)
    end
    return pi
end

-- Adds a comment. Placement follows the same rule as `add_pi`.
---@param self XmlDocument
---@param text? string
---@return XmlComment
function DocumentMT:add_comment(text)
    local c = new_comment(text)
    if self.root == nil then
        table.insert(self.prolog.nodes, c)
    else
        table.insert(self.epilog, c)
    end
    return c
end

-- Sets the root element. Errors when a root has already been added.
---@param self XmlDocument
---@param name string
---@return XmlElement
function DocumentMT:add_element(name)
    local el = new_element(name)
    if not self.root then
        self.root = el
    else
        error("XML requires a single root element; root already set to <" .. self.root.name .. ">")
    end
    return el
end

---@param doc XmlDocument
---@param opts { pretty: boolean, indent: string }
---@param buf string[]
---@return nil
local function serialize_prolog(doc, opts, buf)
    local decl = doc.prolog.xml_decl
    if not decl.omit then
        local s = '<?xml version="' .. escape_attr(decl.version or "1.0") .. '"'
        if decl.encoding then
            s = s .. ' encoding="' .. escape_attr(decl.encoding) .. '"'
        end
        if decl.standalone ~= nil then
            s = s .. ' standalone="' .. (decl.standalone and "yes" or "no") .. '"'
        end
        s = s .. "?>"
        table.insert(buf, s .. (opts.pretty and "\n" or ""))
    end
    for _, n in ipairs(doc.prolog.nodes) do
        if n._type == "pi" then
            table.insert(
                buf,
                "<?" .. n.target .. (n.data and (" " .. n.data) or "") .. "?>" .. (opts.pretty and "\n" or "")
            )
        elseif n._type == "comment" then
            table.insert(buf, "<!--" .. (n.text or "") .. "-->" .. (opts.pretty and "\n" or ""))
        end
    end
end

---@param doc XmlDocument
---@param opts { pretty: boolean, indent: string }
---@param buf string[]
---@return nil
local function serialize_epilog(doc, opts, buf)
    for _, n in ipairs(doc.epilog) do
        if n._type == "pi" then
            table.insert(
                buf,
                "<?" .. n.target .. (n.data and (" " .. n.data) or "") .. "?>" .. (opts.pretty and "\n" or "")
            )
        elseif n._type == "comment" then
            table.insert(buf, "<!--" .. (n.text or "") .. "-->" .. (opts.pretty and "\n" or ""))
        end
    end
end

-- Serializes the document into a string.
---@param self XmlDocument
---@param opts? { pretty?: boolean, indent?: string } Pretty-print is on when `indent` is set or `pretty=true`.
---@return string xml
function DocumentMT:to_string(opts)
    opts = opts or {}
    opts.pretty = opts.pretty ~= false and (opts.pretty == true or opts.indent ~= nil)
    opts.indent = opts.indent or "  "

    local buf = {}
    serialize_prolog(self, opts, buf)
    if self.root then
        serialize_element(self.root, opts, 0, buf)
    end
    serialize_epilog(self, opts, buf) -- << NEW
    return table.concat(buf)
end

-- Stores pretty-print preferences for later use by `write_to_string`.
---@param self XmlDocument
---@param pretty boolean
---@param indent? string Defaults to `"  "`.
---@return XmlDocument self
function DocumentMT:set_pretty(pretty, indent)
    self._pretty = pretty
    self._indent = indent or self._indent
    return self
end

-- Serializes the document using the previously stored pretty-print
-- preferences (or defaults).
---@param self XmlDocument
---@return string
function DocumentMT:write_to_string()
    return self:to_string({ pretty = (self._pretty ~= false), indent = self._indent or "  " })
end

-- Public API
xml.new_document = new_document
xml.new_element = new_element
xml.pi = new_pi
xml.comment = new_comment

return xml
