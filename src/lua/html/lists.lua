--- List handling helpers for the HTML parser.
--- Provides resolve_list_style_type().
local images = require("html.images")

local M = {}

---Resolve list-style-type or list-style-image to a string or image node.
---@param styles table            -- CSS style table
---@param olcounter table         -- current list-level counters
---@param dataxml table           -- data context (needed for image sizing)
---@return string|any             -- list marker text or image node
function M.resolve_list_style_type(styles, olcounter, dataxml)
    local liststyletype  = styles["list-style-type"]
    local liststyleimage = styles["list-style-image"]

    -- If list-style-image is given, it overrides list-style-type
    if liststyleimage then
        local filename = string.match(liststyleimage, "url%((.*)%)")
        local it = publisher.new_image(filename, 1, nil, nil)
        it = img.copy(it.img)
        images.set_image_dimensions(it, styles, 0, styles.fontsize_sp * 0.9, dataxml)
        return img.node(it)
    end

    -- Otherwise handle standard list-style-type
    local counter = olcounter[styles.listlevel]
    local str = ""

    if liststyletype == "decimal" then
        str = tostring(counter) .. "."
    elseif liststyletype == "none" then
        -- nothing
    elseif liststyletype == "decimal-leading-zero" then
        str = string.format("%02d.", counter)
    elseif liststyletype == "lower-roman" then
        str = tex.romannumeral(counter) .. "."
    elseif liststyletype == "upper-roman" then
        str = string.upper(tex.romannumeral(counter)) .. "."
    elseif liststyletype == "disc" then
        str = "•"
    elseif liststyletype == "circle" then
        str = "◦"
    elseif liststyletype == "square" then
        str = "□"
    else
        str = liststyletype or ""
    end

    return str
end

return M
