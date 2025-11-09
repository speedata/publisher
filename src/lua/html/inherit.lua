--- Inheritance-aware styles stack for the HTML parser.
--- Provides new_stack(), push(), pop(), top().
local M = {}

---@class HtmlStyles : table
---@field pos integer                 -- 1-based index in the stack
---@field calculated_width number|nil
---@field fontsize_sp number|nil
---@field rootfontsize_sp number|nil
---@field lineheight_sp number|nil

---@class HtmlStylesStack
---@field _stack HtmlStyles[]
---@field _inherited table<string, boolean>
---@field _mt table                   -- level metatable (with __index)

---Create a new inheritance-aware styles stack.
---@param inherited table<string, boolean>  -- keys that should inherit
---@return HtmlStylesStack stack
function M.new_stack(inherited)
    -- metatable for the outer stack: when pushing, auto-annotate pos
    local stylesstack = {
        _stack = {},
        _inherited = inherited or {},
        _mt = nil, -- filled below
    }

    -- level metatable: implements inheritance lookup via previous level
    local levelmt = {
        __index = function(tbl, key)
            if tbl.pos == 1 then
                return nil
            end
            if stylesstack._inherited[key] then
                return stylesstack._stack[tbl.pos - 1][key]
            end
            return nil
        end
    }
    stylesstack._mt = levelmt

    return stylesstack
end

---Push a new level onto the stack and return it.
---@param stack HtmlStylesStack
---@return HtmlStyles level
function M.push(stack)
    local level = setmetatable({}, stack._mt)
    local idx = #stack._stack + 1
    level.pos = idx
    stack._stack[idx] = level
    return level
end

---Pop the top level from the stack.
---@param stack HtmlStylesStack
---@return HtmlStyles|nil popped
function M.pop(stack)
    local idx = #stack._stack
    if idx == 0 then return nil end
    local top = stack._stack[idx]
    stack._stack[idx] = nil
    return top
end

---Get the current top level (without popping).
---@param stack HtmlStylesStack
---@return HtmlStyles|nil level
function M.top(stack)
    local idx = #stack._stack
    if idx == 0 then return nil end
    return stack._stack[idx]
end

return M
