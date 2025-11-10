--- List handling helpers for the HTML parser.
--- Provides resolve_list_style_type().
local images = require("html.images")

local M = {}


-- format lower-alpha returns a-z, aa-az, ba-bz, ...
local function format_lower_alpha(counter)
    local result = ""
    local n = counter
    while n > 0 do
        n = n - 1
        local remainder = n % 26
        result = string.char(97 + remainder) .. result
        n = math.floor(n / 26)
    end
    return result
end


---Resolve list-style-type or list-style-image to a string or image node.
---@param styles table            -- CSS style table
---@param olcounter table         -- current list-level counters
---@param oltype table            -- current list-level type
---@param dataxml table           -- data context (needed for image sizing)
---@return string|any             -- list marker text or image node
function M.resolve_list_style_type(styles, olcounter, oltype, dataxml)
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

    if oltype == "A" then
        liststyletype = "upper-alpha"
    elseif oltype == "a" then
        liststyletype = "lower-alpha"
    elseif oltype == "I" then
        liststyletype = "upper-roman"
    elseif oltype == "i" then
        liststyletype = "lower-roman"
    elseif oltype == "1" then
        liststyletype = "decimal"
    elseif oltype == "circle" then -- not standard
        liststyletype = "circle"
    end

    if liststyletype == "decimal" then
        str = tostring(counter) .. "."
    elseif liststyletype == "none" then
        -- nothing
    elseif liststyletype == "decimal-leading-zero" then
        str = string.format("%02d.", counter)
    elseif liststyletype == "lower-roman" then
        str = tex.romannumeral(counter) .. "."
    elseif liststyletype == "lower-alpha" then
        str = format_lower_alpha(counter) .. "."
    elseif liststyletype == "upper-alpha" then
        str = string.upper(format_lower_alpha(counter)) .. "."
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
