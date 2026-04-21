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

return M
