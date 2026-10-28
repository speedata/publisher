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
---@field structural? boolean True if a selector may depend on the position of an element.
---@field position_limit? integer Positions up to this value are passed unchanged (see `analyze_positions`).
---@field position_period? integer Positions above `position_limit` are equivalent modulo this value, nil if every position counts.
---@field __index? CSSRules Set when the table serves as a metatable in `new`.

---@class CSSResult
---@field [1] table<string, string> Declarations after the cascade.
---@field [2] table<string, boolean> Properties whose value comes from an `!important` declaration.

---@class CSSLevel
---@field element string Lower case element name.
---@field attributes? table<string, boolean> Attribute groups set on the element (see `attribute_groups`).
---@field inherited? table<string, string> Values the descendants inherit (computed on demand).
---@field children? integer Number of child elements with a position (see `positioned`) entered so far.

---@class CSSChain
---@field stack string[]
---@field levels CSSLevel[]

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
    table = true,
    tablefoot = true,
    tablehead = true,
    td = true,
    textblock = true,
    tr = true,
}

-- Elements that know their position among their siblings, for
-- :nth-child() and :first-child. A row counts within the table (or table
-- head or foot), a cell within the row.
local positioned = {
    td = true,
    tr = true,
}

-- The CSS properties an attribute stands for. An attribute takes
-- precedence over CSS rules for these properties (except for !important
-- ones) and over values inherited from the surrounding elements. An
-- attribute that stands for a single property is given by the property
-- name (for example `text-align` for the attribute align of Td).
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

-- Returns the greatest common divisor of two positive integers.
---@param a integer
---@param b integer
---@return integer
local function gcd(a, b)
    while b ~= 0 do
        a, b = b, a % b
    end
    return a
end

-- Parses the argument of :nth-child() (`odd`, `even`, `an+b`, `b`) and
-- returns a and b, or nil if the argument is not understood.
---@param arg string
---@return integer? a
---@return integer? b
local function parse_nth(arg)
    arg = string.lower(string.gsub(arg, "%s", ""))
    if arg == "odd" then
        return 2, 1
    elseif arg == "even" then
        return 2, 0
    elseif string.match(arg, "^[+-]?%d+$") then
        return 0, tonumber(arg)
    end
    local a, b = string.match(arg, "^([+-]?%d*)n([+-]?%d*)$")
    if not a then
        return nil
    end
    if a == "" or a == "+" then
        a = "1"
    elseif a == "-" then
        a = "-1"
    end
    if b == "" then
        b = "0"
    elseif not tonumber(b) then
        return nil
    end
    return tonumber(a), tonumber(b)
end

-- Determines which positions the selectors can tell apart. All selectors
-- that depend on the position (:nth-child(an+b), :first-child, the
-- sibling combinators) give the same result for two positions above the
-- largest b that are equal modulo every a. Positions are reduced
-- accordingly in `enter`, so that the results can be cached and the chain
-- passed to Go stays short in long tables.
---@param self CSSRules
---@return nil
local function analyze_positions(self)
    local limit, period = 2, 1
    for _, csstext in ipairs(self.text) do
        for arg in string.gmatch(csstext, ":nth%-child%(([^)]*)%)") do
            local a, b = parse_nth(arg)
            if not a or not b then
                -- unknown syntax: every position counts
                self.position_limit, self.position_period = nil, nil
                return
            end
            limit = math.max(limit, b)
            if a ~= 0 then
                period = period * math.abs(a) // gcd(period, math.abs(a))
            end
        end
        if string.find(csstext, ":nth%-of%-type") then
            self.position_limit, self.position_period = nil, nil
            return
        end
    end
    self.position_limit, self.position_period = limit, period
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
    -- the positions make every row and cell distinct, so they are only
    -- part of the chain if a selector may need them
    for _, pattern in ipairs({ ":nth%-", ":first%-", ":last%-", ":only%-", "%+", "~" }) do
        if string.find(csstext, pattern) then
            self.structural = true
        end
    end
    if self.structural then
        analyze_positions(self)
    end
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
    local stack, levels = self.stack, self.levels
    local depth = #stack
    local position
    if positioned[element] and depth > 0 then
        local parent = levels[depth]
        parent.children = (parent.children or 0) + 1
        if self.structural then
            position = parent.children
            local limit, period = self.position_limit, self.position_period
            if limit and period and position > limit then
                position = limit + 1 + (position - limit - 1) % period
            end
        end
    end
    stack[depth + 1] = segment(element, class, id, position)
    levels[depth + 1] = { element = element }
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

-- Returns the chain of the layout commands being executed, to continue it
-- later with `set_chain` (for example when a table head is created again
-- on a new page).
---@param self CSSRules
---@return CSSChain
local function get_chain(self)
    return { stack = { table.unpack(self.stack) }, levels = { table.unpack(self.levels) } }
end

-- Replaces the chain of the layout commands being executed by `chain`
-- (from `get_chain`) and returns the previous one.
---@param self CSSRules
---@param chain CSSChain
---@return CSSChain previous
local function set_chain(self, chain)
    local previous = { stack = self.stack, levels = self.levels }
    self.stack = { table.unpack(chain.stack) }
    self.levels = { table.unpack(chain.levels) }
    return previous
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
    return attributes ~= nil and (attributes[group_of[property]] == true or attributes[property] == true)
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
-- `textformat`) or single properties the command has set. Call it before
-- the commands inside are executed, they inherit the values according to
-- the attributes. The properties these attributes stand
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
    get_chain = get_chain,
    set_chain = set_chain,
    rules = rules,
    standalone = standalone,
    pick = pick,
    style = style,
    set_inherited = set_inherited,
}
