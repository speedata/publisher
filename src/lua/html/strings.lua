--- String helpers for HTML parsing.
--- EmmyLua annotations are used for Lua LS (sumneko).
local M = {}

---Remove surrounding matching quotes (single or double) from a string.
---@param str any
---@return any unquoted If input is a string with matching quotes, returns inner part; otherwise returns the original value.
function M.remove_quotes(str)
    if type(str) ~= "string" then return str end
    local first, last = string.sub(str, 1, 1), string.sub(str, -1, -1)
    if (first == '"' and last == '"') or (first == "'" and last == "'") then
        return string.sub(str, 2, -2)
    end
    return str
end

---Check whether a string is surrounded by matching single or double quotes.
---@param str any
---@return boolean
function M.has_quotes(str)
    if type(str) ~= "string" then return false end
    local first, last = string.sub(str, 1, 1), string.sub(str, -1, -1)
    return (first == '"' and last == '"') or (first == "'" and last == "'")
end

---Split a comma-separated list while respecting quoted segments.
---@param inputstr string
---@return string[] parts
function M.split_string_quote(inputstr)
    local t ---@type string[]
    t = {}
    local inquote = false
    local buf = ""
    for i = 1, #inputstr do
        local c = string.sub(inputstr, i, i)
        if c == '"' or c == "'" then
            buf = buf .. c
            inquote = not inquote
        elseif c == "," and not inquote then
            t[#t + 1] = buf
            buf = ""
        else
            if c ~= " " or inquote then
                buf = buf .. c
            end
        end
    end
    t[#t + 1] = buf
    return t
end

return M
