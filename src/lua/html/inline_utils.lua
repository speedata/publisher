--- Inline/whitespace utilities for HTML node handling.
--- Relies on global `node` and `publisher` like legacy code.
local M = {}

---Trim trailing interword space (glue) at the end of a node list.
---Matches the legacy behavior: if the tail is a glue node, it gets removed.
---@param nodelist any # head of an hlist/vlist (node or head pointer)
---@return any head # potentially the same reference (tail glue removed)
function M.trim_space_end(nodelist)
    if not nodelist then return nodelist end
    local t = node.tail(nodelist)
    if not t then return nodelist end
    if t.id == publisher.glue_node then
        -- cut off tail glue; keep properties on the previous node untouched
        if t.prev then t.prev.next = nil end
    end
    return nodelist
end

---Trim leading interword space (glue) at the beginning of a node list.
---@param nodelist any
---@return any head
function M.trim_space_beginning(nodelist)
    if not nodelist then return nodelist end
    local dir = publisher.getprop(nodelist, "direction")
    -- In horizontal mode ("→") we keep the leading glue as-is.
    if dir == "→" then return nodelist end

    if nodelist.id ~= publisher.glue_node then
        return nodelist
    end
    -- a glue node at the beginning: remove it and return the next node
    local tmp = node.getproperty(nodelist)
    local next_item = nodelist.next
    nodelist.next = nil
    nodelist.prev = nil
    if next_item then
        if next_item.prev then
            next_item.prev.next = nil
            next_item.prev = nil
        end
        node.setproperty(next_item, tmp)
    end
    return next_item
end

return M
