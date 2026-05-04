--- Inline image helper for the HTML parser.
--- Builds a TeX box for <img> using styles and attributes.

local publisher = require("publisher")

local units = require("html.units")
local images = require("html.images")

local M = {}

---Build a box node for an <img> element.
---Mirrors the legacy <img> handling from collect_horizontal_nodes.
---@param styles table              -- computed style table (needs .calculated_width, .fontsize_sp)
---@param attributes table          -- element attributes (expects .src, optional .width/.height)
---@param dataxml table             -- data context for max width/height
---@return any box                  -- TeX hbox/vbox with the image node inside
function M.build_image_box(styles, attributes, dataxml)
    -- env: publisher/img/node/tex are globals in the legacy environment
    local source = attributes.src
    local it = publisher.images.new_image(source, 1, nil, nil)
    -- copy so that size changes don't affect future uses of the same image
    it = img.copy(it.img)

    -- width: if HTML width given, we use styles.calculated_width as target width in sp
    local width_sp
    if attributes.width then
        width_sp = units.getsize(styles, attributes.width, styles.fontsize_sp) or 0
    else
        width_sp = styles.calculated_width
    end

    -- height: resolve CSS-like units
    local height_sp = units.getsize(styles, attributes.height, styles.fontsize_sp) or 0

    -- compute final dimensions and mutate image.width/height
    local calc_w, calc_h = images.set_image_dimensions(it, styles, width_sp, height_sp, dataxml)

    -- wrap image node into a box (prevent line-height adjustment, orphan/widow logic, etc.)
    local box = publisher.drawing.box(calc_w, calc_h, "-")
    node.set_attribute(box, publisher.att_dontadjustlineheight, 1)
    node.set_attribute(box, publisher.att_ignore_orphan_widowsetting, 1)

    -- insert the image node at box head
    box.head = node.insert_before(box.head, box.head, img.node(it))

    return box
end

return M
