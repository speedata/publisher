-- xmlbuilder.lua
-- Minimalistic XML builder library – Lua-idiomatic.

local xml = {}

-- ========== Utilities ==========
local function escape_attr(s)
  s = tostring(s)
  s = s:gsub("&", "&amp;")
       :gsub("<", "&lt;")
       :gsub(">", "&gt;")
       :gsub('"', "&quot;")
       :gsub("'", "&apos;")
  return s
end

local function escape_text(s)
  s = tostring(s)
  s = s:gsub("&", "&amp;")
       :gsub("<", "&lt;")
       :gsub(">", "&gt;")
  return s
end

-- Attribute store as a list to preserve insertion order
local function new_attrlist()
  return { order = {}, map = {} }
end

local function attr_set(attrs, name, value)
  if attrs.map[name] == nil then
    attrs.map[name] = value
    table.insert(attrs.order, name)
  else
    attrs.map[name] = value
  end
end

local function attr_pairs(attrs)
  local i = 0
  return function()
    i = i + 1
    local k = attrs.order[i]
    if k then return k, attrs.map[k] end
  end
end

-- ========== Node Types ==========
local ElementMT, DocumentMT = {}, {}
ElementMT.__index = ElementMT
DocumentMT.__index = DocumentMT

-- ========== Element ==========
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

function ElementMT:add_element(name)
  local child = new_element(name)
  child.parent = self
  table.insert(self.children, child)
  return child
end

function ElementMT:set_attr(name, value)
  attr_set(self.attrs, name, value)
  return self
end

function ElementMT:set_text(s)
  self.text = (s == nil) and nil or tostring(s)
  return self
end

function ElementMT:add_child(node) -- manually add an existing node
  assert(type(node) == "table" and node._type, "invalid node")
  node.parent = self
  table.insert(self.children, node)
  return self
end

-- NEW: place PI/comment inside this element
function ElementMT:add_pi(target, data)
  local pi = { _type = "pi", target = target, data = data or "" }
  pi.parent = self
  table.insert(self.children, pi)
  return pi
end

function ElementMT:add_comment(text)
  local c = { _type = "comment", text = text or "" }
  c.parent = self
  table.insert(self.children, c)
  return c
end

function ElementMT:up() -- return parent node (for chaining)
  return self.parent
end

-- Serialize an element
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
        table.insert(buf, ind .. "<?" .. ch.target .. (ch.data and (" " .. ch.data) or "") .. "?>" .. (opts.pretty and "\n" or ""))
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
local function new_pi(target, data)
  return { _type = "pi", target = target, data = data or "" }
end

local function new_comment(text)
  return { _type = "comment", text = text or "" }
end

-- ========== Document ==========
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

function DocumentMT:set_xml_decl(version, encoding, standalone)
  self.prolog.xml_decl = { version = version or "1.0", encoding = encoding, standalone = standalone, omit = false }
  return self
end

-- CHANGED: context-aware placement
-- - before root exists: goes to prolog (existing behavior)
-- - after root exists: goes to epilog (new behavior)
function DocumentMT:add_pi(target, data)
  local pi = new_pi(target, data)
  if self.root == nil then
    table.insert(self.prolog.nodes, pi)
  else
    table.insert(self.epilog, pi)
  end
  return pi
end

function DocumentMT:add_comment(text)
  local c = new_comment(text)
  if self.root == nil then
    table.insert(self.prolog.nodes, c)
  else
    table.insert(self.epilog, c)
  end
  return c
end

function DocumentMT:add_element(name)
  local el = new_element(name)
  if not self.root then
    self.root = el
  else
    error("XML requires a single root element; root already set to <" .. self.root.name .. ">")
  end
  return el
end

-- Serialize document prolog
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
      table.insert(buf, "<?" .. n.target .. (n.data and (" " .. n.data) or "") .. "?>" .. (opts.pretty and "\n" or ""))
    elseif n._type == "comment" then
      table.insert(buf, "<!--" .. (n.text or "") .. "-->" .. (opts.pretty and "\n" or ""))
    end
  end
end

-- NEW: serialize epilog nodes (after root)
local function serialize_epilog(doc, opts, buf)
  for _, n in ipairs(doc.epilog) do
    if n._type == "pi" then
      table.insert(buf, "<?" .. n.target .. (n.data and (" " .. n.data) or "") .. "?>" .. (opts.pretty and "\n" or ""))
    elseif n._type == "comment" then
      table.insert(buf, "<!--" .. (n.text or "") .. "-->" .. (opts.pretty and "\n" or ""))
    end
  end
end

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

function DocumentMT:set_pretty(pretty, indent)
  self._pretty = pretty
  self._indent = indent or self._indent
  return self
end

function DocumentMT:write_to_string()
  return self:to_string({ pretty = (self._pretty ~= false), indent = self._indent or "  " })
end

-- Public API
xml.new_document = new_document
xml.new_element  = new_element
xml.pi           = new_pi
xml.comment      = new_comment

return xml
