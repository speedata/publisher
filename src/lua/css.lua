-- This file contains the CSS handling for the layout commands. Parsing,
-- selector matching and the cascade happen in Go (splib); this file keeps
-- the chain of the layout commands being executed and caches the results.
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
---@field cache table<string, CSSResult> Match results by chain.
---@field __index? CSSRules Set when the table serves as a metatable in `new`.

---@class CSSResult
---@field [1] table<string, string> Declarations after the cascade.
---@field [2] table<string, boolean> Properties whose value comes from an `!important` declaration.

-- Result for elements without matching rules. Shared, like cached results.
---@type table
local empty = {}

-- Constructs a fresh empty CSS rule store.
---@param self CSSRules
---@return CSSRules
local function new(self)
    local c = {
        text = {},
        stack = {},
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
    return depth
end

-- Leaves a layout command (and everything entered below it).
---@param self CSSRules
---@param depth integer Return value of `enter`.
---@return nil
local function leave(self, depth)
    local stack = self.stack
    for i = #stack, depth + 1, -1 do
        stack[i] = nil
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

return {
    new = new,
    parse = parse,
    parsetxt = parsetxt,
    gettext = gettext,
    enter = enter,
    leave = leave,
    rules = rules,
    standalone = standalone,
}
