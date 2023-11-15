local M = {
    private = {},
}

---@return table
local function split_chars(str)
    local runes = {}
    for _, c in utf8.codes(str) do
        runes[#runes + 1] = utf8.char(c)
    end
    runes.pos = 1
    return runes
end
M.private.split_chars = split_chars


local function is_letter(str)
    return string.match(str, "%w")
end

local function is_space(str)
    return string.match(str, "%s")
end

local function is_digit(str)
    return string.match(str, "[0-9]")
end




---@return string
---@return boolean
local function read_rune(tbl)
    local r = tbl[tbl.pos]
    tbl.pos = tbl.pos + 1
    if tbl.pos > #tbl + 1 then return r, true end
    return r, false
end

local function unread_rune(tbl)
    tbl.pos = tbl.pos - 1
end

local function get_varname(runes)
    local word = {}
    local r, eof
    while true do
        r, eof = read_rune(runes)
        if eof then break end
        if is_letter(r) or is_digit(r) or r == '_' or r == '-' or r == '·' or r == '‿' or r == '⁀' then
            word[#word + 1] = r
        else
            unread_rune(runes)
            break
        end
    end
    return table.concat(word)
end

local function read_number(tbl)
    local collect = {}
    local number_read = false
    local unit_found = false
    local r, eof
    r, eof = read_rune(tbl)
    if eof then return tonumber(table.concat(collect)) end
    if r == "-" or r == "+" then
        collect[#collect+1] = r
    else
        unread_rune(tbl)
    end
    while true do
        r, eof = read_rune(tbl)
        if eof then break end
        if '0' <= r and r <= '9' or r == "." then
            collect[#collect+1] = r
        else
            number_read = true
            unread_rune(tbl)
        end
        if number_read then
            while true do
                r, eof = read_rune(tbl)
                if eof then break end
                if is_space(r) then
                    if unit_found then
                        break
                    end
                    -- ok, ignore
                elseif is_letter(r) then
                    unit_found = true
                    collect[#collect+1] = r
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


local tokenlist = {}


function tokenlist:new(o)
    o = o or {} -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
end



function M.string_to_tokenlist(str,ctx)
    if str == nil then return {} end
    -- replace all variables
    str = string.gsub(str,"%$([a-zA-Z-_]+)",function(input) return xpath.string_value(ctx.vars[input]) end)
    local tokens = tokenlist:new()
    local nextrune
    local eof
    local num
    local runes = split_chars(str)
    while true do
        local r
        r, eof = read_rune(runes)
        if eof then break end
        if is_space(r) then
            -- ignore
        elseif r == "+" or r == "-" then
            nextrune, _ = read_rune(runes)
            if nextrune and tonumber(nextrune) then
                unread_rune(runes)
                unread_rune(runes)
                num = read_number(runes)
                tokens[#tokens+1] = num
            else
                tokens[#tokens+1] = r
            end
        elseif '0' <= r and r <= '9' then
            unread_rune(runes)
            num = read_number(runes)
            tokens[#tokens+1] = num
        else
            tokens[#tokens+1] = r
        end
    end
    return table.concat(tokens," ")
end

return M