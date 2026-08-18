-- Generic Lua/table helpers.
--
--  utilities.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("utilities.lua")

local publisher = require("publisher")

---@class utilities_module
local M = {}

-- Deep-copies any Lua value. For tables, descends recursively, preserves
-- metatables and copies node lists with `node.copy_list`. Skips a few
-- well-known back-reference keys (`.__parent`, `.__context`, `_layoutxml`,
-- `_dataxml`) to avoid infinite loops. Used by the `<Copy-of>` command.
---@generic T
---@param t T
---@return T
function M.deepcopy(t)
    local typ = type(t)
    if typ ~= "table" then
        return t
    end
    local mt = getmetatable(t)
    local res = {}
    for k, v in pairs(t) do
        typ = type(v)
        if typ == "table" then
            if k ~= ".__parent" and k ~= ".__context" and k ~= "_layoutxml" and k ~= "_dataxml" then
                v = M.deepcopy(v)
            end
        else
            if node.is_node(v) then
                v = node.copy_list(v)
            end
        end
        res[k] = v
    end
    setmetatable(res, mt)
    return res
end

-- Returns a shallow copy of `defaults`. Non-table inputs are returned as-is.
---@generic T
---@param defaults T
---@return T
function M.copy_table_from_defaults(defaults)
    if type(defaults) ~= "table" then
        return defaults
    end
    local newtbl = {}
    for key, value in next, defaults, nil do
        newtbl[key] = value
    end
    return newtbl
end

-- Stable sort, public domain / cc0
local max_chunk_size = 12

---@alias OrderFn fun(a: any, b: any): boolean Strict less-than predicate; must return `false` when `a == b`.

-- Sorts `array[first..last]` in place using insertion sort.
---@param array any[]
---@param first integer
---@param last integer
---@param goes_before OrderFn
---@return nil
function M.insertion_sort(array, first, last, goes_before)
    for i = first + 1, last do
        local k = first
        local v = array[i]
        for j = i, first + 1, -1 do
            if goes_before(v, array[j - 1]) then
                array[j] = array[j - 1]
            else
                k = j
                break
            end
        end
        array[k] = v
    end
end

-- Merges the two already-sorted runs `array[low..middle]` and
-- `array[middle+1..high]` in place, using `workspace` as scratch space.
---@param array any[]
---@param workspace any[] Scratch buffer; `array[low..middle]` is copied into it.
---@param low integer
---@param middle integer
---@param high integer
---@param goes_before OrderFn
---@return nil
function M.merge(array, workspace, low, middle, high, goes_before)
    local i, j, k
    i = 1
    for idx = low, middle do
        workspace[i] = array[idx]
        i = i + 1
    end
    i = 1
    j = middle + 1
    k = low
    while true do
        if (k >= j) or (j > high) then
            break
        end
        if goes_before(array[j], workspace[i]) then
            array[k] = array[j]
            j = j + 1
        else
            array[k] = workspace[i]
            i = i + 1
        end
        k = k + 1
    end
    for kk = k, j - 1 do
        array[kk] = workspace[i]
        i = i + 1
    end
end

-- Recursively merge-sorts `array[low..high]` in place. Falls back to
-- `insertion_sort` for chunks smaller than `max_chunk_size`.
---@param array any[]
---@param workspace any[]
---@param low integer
---@param high integer
---@param goes_before OrderFn
---@return nil
function M.merge_sort(array, workspace, low, high, goes_before)
    if high - low < max_chunk_size then
        M.insertion_sort(array, low, high, goes_before)
    else
        local middle = math.floor((low + high) / 2)
        M.merge_sort(array, workspace, low, middle, goes_before)
        M.merge_sort(array, workspace, middle + 1, high, goes_before)
        M.merge(array, workspace, low, middle, high, goes_before)
    end
end

-- Sorts `array` in place using a stable merge sort.
---@generic T
---@param array T[]
---@param goes_before? OrderFn Defaults to `function(a,b) return a < b end`.
---@return T[] array Same instance, now sorted.
function M.stable_sort(array, goes_before)
    local n = #array
    if n < 2 then
        return array
    end
    goes_before = goes_before or function(a, b)
        return a < b
    end
    local workspace = {}
    workspace[math.floor((n + 1) / 2)] = array[1]
    if goes_before(array[1], array[1]) then
        error("invalid order function for sorting")
    end
    M.merge_sort(array, workspace, 1, n, goes_before)
    return array
end

-- Garbage Collection helpers

-- Recursively walks a table and frees node lists found in userdata fields
-- via `node.flush_list`. Skips back-reference keys (`.__context`, `.__parent`).
---@param tbl table
---@return nil
function M.flush_table(tbl)
    for k, v in pairs(tbl) do
        if k == ".__context" or k == ".__parent" then
            -- nothing, to prevent infinite loops
        elseif type(v) == "table" then
            M.flush_table(v)
        elseif type(v) == "userdata" then
            node.flush_list(v --[[@as Node]])
        end
    end
end

-- Looks up a publisher variable by name and runs `flush_table` on it if it
-- holds a table. The lookup uses `publisher.data.vars` for the new XPath
-- parser and `xpath.get_variable` for the legacy parser.
---@param varname string
---@return nil
function M.flush_variable(varname)
    local x
    x = publisher.data.vars[varname]
    if type(x) == "table" then
        M.flush_table(x)
    end
end

-- random string https://gist.github.com/haggen/2fd643ea9a261fea2094
---@type string[]
local charset = {}
for i = 48, 57 do
    table.insert(charset, string.char(i))
end
for i = 65, 90 do
    table.insert(charset, string.char(i))
end
for i = 97, 122 do
    table.insert(charset, string.char(i))
end

-- Returns a random alphanumeric string of `length` characters.
---@param length integer
---@return string
function M.string_random(length)
    if length > 0 then
        return M.string_random(length - 1) .. charset[math.random(1, #charset)]
    else
        return ""
    end
end

file_end("utilities.lua")

return M
