--- Tree utilities for the HTML parser.
--- Provides normalize_html_tree(), which normalizes element trees into
--- horizontal and vertical node groups.
local M = {}

---Normalize the HTML element tree so that consecutive horizontal or text
---elements are grouped into a single "horizontal" table entry.
---This is called recursively to ensure the whole tree is properly shaped.
---@param elt table
---@return nil
function M.normalize_html_tree(elt)
    local lasthorizontal
    local delete = {}

    for i = 1, #elt do
        local thiselt = elt[i]
        local typ = type(thiselt)

        -- Recursively process children first
        if typ == "table" and thiselt.direction == "↓" then
            M.normalize_html_tree(thiselt)
            lasthorizontal = nil
        end

        -- Group horizontal runs (strings or → direction)
        if typ == "string" or (typ == "table" and thiselt.direction == "→") then
            -- Strip whitespace-only strings between block elements (CSS behavior)
            if typ == "string" and string.match(thiselt, "^%s*$") and lasthorizontal == nil then
                -- Check if next sibling is a block element
                local next = elt[i + 1]
                if next == nil or (type(next) == "table" and next.direction == "↓") then
                    delete[#delete + 1] = i
                    goto continue
                end
            end
            if lasthorizontal then
                -- Append to previous horizontal group
                local lasthorizontalelt = elt[lasthorizontal]
                lasthorizontalelt[#lasthorizontalelt + 1] = thiselt
                delete[#delete + 1] = i
            else
                -- Start new horizontal group
                elt[i] = { mode = "horizontal", thiselt }
                lasthorizontal = i
            end
        end
        ::continue::
    end

    -- Remove merged entries (from end to start)
    for i = #delete, 1, -1 do
        table.remove(elt, delete[i])
    end
end

---Tell whether a horizontal group or inline element shows anything. A group
---of whitespace and empty elements creates no line box (CSS 2.1, 9.4.2).
---@param elt table
---@return boolean
function M.has_inline_content(elt)
    for i = 1, #elt do
        local thiselt = elt[i]
        if type(thiselt) == "string" then
            if string.match(thiselt, "%S") then
                return true
            end
        elseif type(thiselt) == "table" then
            local eltname = thiselt.elementname
            if eltname == "img" or eltname == "br" or eltname == "wbr" then
                return true
            end
            for k in pairs(thiselt.styles or {}) do
                if string.match(k, "^%a+::") then
                    return true
                end
            end
            if M.has_inline_content(thiselt) then
                return true
            end
        end
    end
    return false
end

return M
