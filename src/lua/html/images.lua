--- Image sizing helpers for the HTML parser.
--- Depends on global `tex` and the provided `publisher`/`xpath` via runtime.
local units = require("html.units")

local M = {}

---Compute scaled image width/height respecting width/height attrs and page max size.
---Mutates `image.width` / `image.height`.
---@param image any                     -- luatex image (copied img)
---@param styles table                  -- HtmlStyles-like table with fontsize_sp etc.
---@param width_sp number               -- target width in sp (0 = auto)
---@param height_sp number              -- target height in sp (0 = auto)
---@param dataxml table                 -- data context (vars with __maxwidth/__maxheight when newxpath=true)
---@return number calc_width            -- resulting width (sp)
---@return number calc_height           -- resulting height (sp)
function M.set_image_dimensions(image, styles, width_sp, height_sp, dataxml)
    local publisher        = publisher -- from global legacy env
    local tex              = tex -- from global legacy env

    local orig_w, orig_h   = image.width, image.height
    local image_w, image_h = orig_w, orig_h
    local factor           = 1

    -- width constraint
    if width_sp ~= 0 then
        image_w = width_sp
        factor = orig_w / image_w
    end

    -- height constraint
    if height_sp ~= 0 then
        image_h = tex.sp(image_h)
        image_h = units.calculate_height(height_sp, orig_h)
        factor = orig_h / image_h
    end

    if factor ~= 1 then
        image_w = orig_w / factor
        image_h = orig_h / factor
    end

    -- page max constraints
    local maxwd, maxht
    if publisher.newxpath then
        maxwd = dataxml.vars["__maxwidth"]
        maxht = dataxml.vars["__maxheight"]
    else
        maxwd = xpath.get_variable("__maxwidth")
        maxht = xpath.get_variable("__maxheight")
    end

    -- small headroom below line box
    maxht                = maxht - styles.fontsize_sp * 0.25

    local calc_w, calc_h =
        publisher.calculate_image_width_height(image, image_w, image_h, 0, 0, maxwd, maxht)

    image.width          = calc_w
    image.height         = calc_h
    return calc_w, calc_h
end

return M
