-- This file contains the CSS handling for the layout commands. Parsing,
-- selector matching and the cascade happen in Go (splib); this file keeps
-- the chain of the layout commands being executed, caches the results and
-- resolves the precedence of attributes, CSS rules and inherited values.
--
--  css.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

local splib = splib

---@class CSSRules
---@field text string[] Concatenation of every parsed CSS source (kept for the Go HTML renderer).
---@field stack string[] Encoded chain of the layout commands being executed, innermost last.
---@field levels CSSLevel[] One entry for each element of `stack`.
---@field cache table<string, CSSResult> Match results by chain.
---@field fontfaces? table<string, table> Font families from @font-face rules (see `get_fontfaces`).
---@field __index? CSSRules Set when the table serves as a metatable in `new`.

---@class CSSResult
---@field [1] table<string, string> Declarations after the cascade.
---@field [2] table<string, boolean> Properties whose value comes from an `!important` declaration.

---@class CSSLevel
---@field element string Lower case element name.
---@field attributes? table<string, boolean> Attribute groups set on the element (see `attribute_groups`).
---@field inherited? table<string, string> Values the descendants inherit (computed on demand).

-- Result for elements without matching rules. Shared, like cached results.
---@type table
local empty = {}

-- Properties that descendants inherit, as in CSS.
local inherited_properties = {
    ["color"] = true,
    ["font-family"] = true,
    ["font-size"] = true,
    ["font-style"] = true,
    ["font-weight"] = true,
    ["hyphens"] = true,
    ["letter-spacing"] = true,
    ["line-height"] = true,
    ["orphans"] = true,
    ["text-align"] = true,
    ["text-indent"] = true,
    ["widows"] = true,
}

-- Elements whose CSS rules are inherited by the elements inside.
local inheritance_sources = {
    paragraph = true,
    textblock = true,
}

-- The CSS properties an attribute stands for. An attribute takes
-- precedence over CSS rules for these properties (except for !important
-- ones) and over values inherited from the surrounding elements.
local attribute_groups = {
    color = { "color" },
    fontfamily = { "font-family", "font-size", "line-height" },
    textformat = {
        "break-after",
        "break-before",
        "hyphens",
        "letter-spacing",
        "margin-bottom",
        "margin-top",
        "orphans",
        "text-align",
        "text-indent",
        "widows",
    },
}

-- Attribute group by property.
---@type table<string, string>
local group_of = {}
for group, properties in pairs(attribute_groups) do
    for _, property in ipairs(properties) do
        group_of[property] = group
    end
end

-- Constructs a fresh empty CSS rule store.
---@param self CSSRules
---@return CSSRules
local function new(self)
    local c = {
        text = {},
        stack = {},
        levels = {},
        cache = {},
    }
    setmetatable(c, self)
    self.__index = self
    return c
end

-- Returns the concatenation of every CSS source ever fed into this store.
-- Used to forward the raw CSS to the Go HTML renderer.
---@param self CSSRules
---@return string
local function gettext(self)
    return table.concat(self.text)
end

-- Adds the rules of a CSS source string.
---@param self CSSRules
---@param csstext string
---@return nil
local function parsetxt(self, csstext)
    -- save it for later to pass to the Go routine
    self.text[#self.text + 1] = csstext
    splib.css_add(csstext)
    self.cache = {}
    self.fontfaces = nil
end

-- Loads a CSS file from disk (resolved via `kpse.find_file`) and adds its
-- rules via `parsetxt`.
---@param self CSSRules
---@param filename string
---@return nil
local function parse(self, filename)
    local path = kpse.find_file(filename)
    if not path then
        main.log("error", string.format("CSS: cannot find filename %q.", filename or "--"))
        return
    end
    main.log("info", string.format("Loading CSS %q", path))
    local cssio = io.open(path, "rb")
    if not cssio then
        main.log("error", string.format("CSS: cannot open file %q.", path))
        return
    end
    local csstext = cssio:read("*all")
    cssio:close()
    return parsetxt(self, csstext)
end

-- Returns the font families from the @font-face rules, in the shape of
-- `publisher.fontgroup`.
---@param self CSSRules
---@return table<string, table>
local function get_fontfaces(self)
    if not self.fontfaces then
        self.fontfaces = #self.text > 0 and splib.css_fontfaces() or {}
    end
    return self.fontfaces
end

-- Encodes one element of the chain in the format splib.css_match expects.
---@param element string Lower case element name.
---@param class? string
---@param id? string
---@param position? integer Position among the siblings.
---@return string
local function segment(element, class, id, position)
    return element .. "\1" .. (class or "") .. "\1" .. (id or "") .. "\1" .. (position or "")
end

-- Enters a layout command. Returns the stack depth before the push, which
-- `leave` restores.
---@param self CSSRules
---@param element string Lower case element name.
---@param class? string
---@param id? string
---@return integer depth
local function enter(self, element, class, id)
    local stack = self.stack
    local depth = #stack
    stack[depth + 1] = segment(element, class, id)
    self.levels[depth + 1] = { element = element }
    return depth
end

-- Leaves a layout command (and everything entered below it).
---@param self CSSRules
---@param depth integer Return value of `enter`.
---@return nil
local function leave(self, depth)
    local stack, levels = self.stack, self.levels
    for i = #stack, depth + 1, -1 do
        stack[i] = nil
        levels[i] = nil
    end
end

-- Returns the declarations for an encoded chain.
---@param self CSSRules
---@param chain string
---@param pseudo? string
---@return table<string, string> declarations
---@return table<string, boolean> important
local function lookup(self, chain, pseudo)
    if #self.text == 0 then
        return empty, empty
    end
    local key = pseudo and chain .. "\3" .. pseudo or chain
    local res = self.cache[key]
    if not res then
        local decls, important = splib.css_match(chain, pseudo)
        res = { decls or {}, important or {} }
        self.cache[key] = res
    end
    return res[1], res[2]
end

-- Returns the declarations for the element at stack position `n`.
---@param self CSSRules
---@param n integer
---@return table<string, string> declarations
---@return table<string, boolean> important
local function rules_at(self, n)
    return lookup(self, table.concat(self.stack, "\2", 1, n))
end

-- Returns the CSS declarations for the innermost layout command being
-- executed. With `child`, the declarations are for a child element of that
-- name (for example `li` in a list), with `pseudo` for a pseudo element
-- (`marker` for `li::marker`). The returned tables are shared and must not
-- be changed.
---@param self CSSRules
---@param pseudo? string
---@param child? string
---@return table<string, string> declarations
---@return table<string, boolean> important
local function rules(self, pseudo, child)
    if #self.stack == 0 then
        return empty, empty
    end
    local chain = table.concat(self.stack, "\2")
    if child then
        chain = chain .. "\2" .. segment(child)
    end
    return lookup(self, chain, pseudo)
end

-- Returns the CSS declarations for an element directly below the root,
-- independent of the commands being executed (for example a positioning
-- area).
---@param self CSSRules
---@param element string
---@param class? string
---@param id? string
---@return table<string, string> declarations
---@return table<string, boolean> important
local function standalone(self, element, class, id)
    return lookup(self, segment(element, class, id))
end

-- Returns the value of an attribute or of a CSS property, whichever takes
-- precedence: an !important declaration wins over the attribute, the
-- attribute over a normal declaration.
---@generic T
---@param decls table<string, string> First return value of `rules`.
---@param important table<string, boolean> Second return value of `rules`.
---@param property string
---@param attvalue T? Value of the attribute.
---@return T|string|nil
local function pick(decls, important, property, attvalue)
    if important[property] or attvalue == nil then
        return decls[property]
    end
    return attvalue
end

-- Returns true if the attributes of a level cover the property.
---@param attributes? table<string, boolean>
---@param property string
---@return boolean
local function covered(attributes, property)
    return attributes ~= nil and attributes[group_of[property]] == true
end

-- Returns the values that the elements inside the element at stack
-- position `n` inherit.
---@param self CSSRules
---@param n integer
---@return table<string, string>
local function inherited_at(self, n)
    if n == 0 then
        return empty
    end
    local level = self.levels[n]
    if level.inherited then
        return level.inherited
    end
    local ret = {}
    for k, v in pairs(inherited_at(self, n - 1)) do
        ret[k] = v
    end
    local attributes = level.attributes
    if attributes then
        -- an attribute replaces the inherited values it stands for
        for k in pairs(ret) do
            if covered(attributes, k) then
                ret[k] = nil
            end
        end
    end
    if inheritance_sources[level.element] then
        local decls, important = rules_at(self, n)
        for k, v in pairs(decls) do
            if inherited_properties[k] and (important[k] or not covered(attributes, k)) then
                ret[k] = v
            end
        end
    end
    level.inherited = ret
    return ret
end

-- Returns the CSS properties of the layout command being executed: its own
-- declarations and the inherited values, after the precedence rules.
-- `attributes` names the attribute groups (`color`, `fontfamily`,
-- `textformat`) the command has set. The properties these attributes stand
-- for are left out unless they come from an !important declaration of the
-- element itself, so every value in the result takes precedence over the
-- attributes.
---@param self CSSRules
---@param attributes? table<string, boolean>
---@return table<string, string>
local function style(self, attributes)
    local n = #self.levels
    if n == 0 or #self.text == 0 then
        return {}
    end
    local level = self.levels[n]
    level.attributes = attributes
    level.inherited = nil
    local ret = {}
    for k, v in pairs(inherited_at(self, n)) do
        ret[k] = v
    end
    local decls, important = rules_at(self, n)
    for k, v in pairs(decls) do
        if not inherited_properties[k] and (important[k] or not covered(attributes, k)) then
            ret[k] = v
        end
    end
    return ret
end

-- Replaces a value the elements inside the current command inherit, for
-- example a font size in `em` by its absolute value. Call after `style`.
---@param self CSSRules
---@param property string
---@param value string
---@return nil
local function set_inherited(self, property, value)
    local n = #self.levels
    if n == 0 then
        return
    end
    inherited_at(self, n)[property] = value
end

return {
    new = new,
    parse = parse,
    parsetxt = parsetxt,
    gettext = gettext,
    get_fontfaces = get_fontfaces,
    enter = enter,
    leave = leave,
    rules = rules,
    standalone = standalone,
    pick = pick,
    style = style,
    set_inherited = set_inherited,
}
