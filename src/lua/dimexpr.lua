local publisher = require("publisher")

---@class dimexpr_module
---@field ["private"] table<string, function> Module-private helpers exposed for tests.
local M = {
    private = {},
}

-- A rune array with a cursor, as produced by `split_chars`.
---@class RuneBuffer: string[]
---@field pos integer Cursor position (1-based).

-- Splits a UTF-8 string into a positional rune array.
---@param str string
---@return RuneBuffer runes
local function split_chars(str)
    ---@type RuneBuffer
    local runes = { pos = 1 }
    for _, c in utf8.codes(str) do
        runes[#runes + 1] = utf8.char(c)
    end
    return runes
end
M.private.split_chars = split_chars

---@param str string
---@return string?
local function is_letter(str)
    return string.match(str, "%w")
end

---@param str string
---@return string?
local function is_space(str)
    return string.match(str, "%s")
end

-- Reads the next rune from `tbl` and advances the cursor.
---@param tbl RuneBuffer
---@return string rune
---@return boolean eof
local function read_rune(tbl)
    local r = tbl[tbl.pos]
    tbl.pos = tbl.pos + 1
    if tbl.pos > #tbl + 1 then
        return r, true
    end
    return r, false
end

-- Steps the cursor back by one so the previously read rune can be read again.
---@param tbl RuneBuffer
---@return nil
local function unread_rune(tbl)
    tbl.pos = tbl.pos - 1
end

-- Reads a signed number with optional unit (`5mm`, `12.5pt`, `-3`) from
-- the rune buffer. Numbers with units are converted via `tex.sp`,
-- numbers without units are returned as plain Lua numbers.
---@param tbl RuneBuffer
---@return integer|number? value
local function read_number(tbl)
    local collect = {}
    local number_read = false
    local unit_found = false
    local r, eof
    r, eof = read_rune(tbl)
    if eof then
        return tonumber(table.concat(collect))
    end
    if r == "-" or r == "+" then
        collect[#collect + 1] = r
    else
        unread_rune(tbl)
    end
    while true do
        r, eof = read_rune(tbl)
        if eof then
            break
        end
        if "0" <= r and r <= "9" or r == "." then
            collect[#collect + 1] = r
        else
            number_read = true
            unread_rune(tbl)
        end
        if number_read then
            while true do
                r, eof = read_rune(tbl)
                if eof then
                    break
                end
                if is_space(r) then
                    if unit_found then
                        break
                    end
                    -- ok, ignore
                elseif is_letter(r) then
                    unit_found = true
                    collect[#collect + 1] = r
                else
                    unread_rune(tbl)
                    goto skip
                end
            end
        end
    end
    ::skip::
    if unit_found then
        return tex.sp(table.concat(collect))
    else
        return tonumber(table.concat(collect))
    end
end

---@class DimexprTokenlist
local tokenlist = {}

-- Creates a fresh tokenlist instance.
---@param self DimexprTokenlist
---@param o? table
---@return DimexprTokenlist
function tokenlist:new(o)
    o = o or {} -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Parses a dimension expression into a normalized space-separated string
-- with `$variables` substituted from `ctx.vars`.
---@param str string? Source expression.
---@param ctx table XPath context with `vars`.
---@return string|table tokens Normalized expression, or `{}` if `str` is nil.
function M.string_to_tokenlist(str, ctx)
    if str == nil then
        return {}
    end
    -- replace all variables
    str = string.gsub(str, "%$([a-zA-Z-_]+)", function(input)
        return publisher.xpath.string_value(ctx.vars[input])
    end)
    local tokens = tokenlist:new()
    local nextrune
    local eof
    local num
    local runes = split_chars(str)
    while true do
        local r
        r, eof = read_rune(runes)
        if eof then
            break
        end
        if is_space(r) then
            -- ignore
        elseif r == "+" or r == "-" then
            nextrune, _ = read_rune(runes)
            if nextrune and tonumber(nextrune) then
                unread_rune(runes)
                unread_rune(runes)
                num = read_number(runes)
                tokens[#tokens + 1] = num
            else
                tokens[#tokens + 1] = r
            end
        elseif "0" <= r and r <= "9" then
            unread_rune(runes)
            num = read_number(runes)
            tokens[#tokens + 1] = num
        else
            tokens[#tokens + 1] = r
        end
    end
    return table.concat(tokens, " ")
end

return M
