--- Inline options builder for publisher.mknodes.
--- Extracted from the legacy set_options_for_mknodes implementation.

local publisher = require("publisher")

local fonts = require("html.fonts")
local units = require("html.units")
local colors_module = require("publisher.colors")

local M = {}

---Configure options for publisher.mknodes based on the given styles.
---Mutates and returns `options`.
---@param styles table                       -- CSS-like style table (must include fontsize_sp etc.)
---@param options table|nil                  -- options table to fill; a new one if nil
---@param publisher any                      -- publisher environment (for colors etc.)
---@param fontfamilies table<string, any>    -- global fontfamilies map from the HTML tree
---@return table options
function M.set_options_for_mknodes(styles, options, publisher, fontfamilies)
    options            = options or {}

    -- Font family / size
    local family       = styles["font-family"]
    local fontsize     = styles["font-size"]
    options.fontfamily = fonts.get_fontfamily(
        family,
        styles.fontsize_sp,
        fontsize,
        styles,
        publisher,
        fontfamilies
    )

    if styles.has_border then
        local styles_fontsize_sp = styles.fontsize_sp
        local margin_top = units.getsize(styles,styles["margin-top"],styles_fontsize_sp)
        local margin_right = units.getsize(styles,styles["margin-right"],styles_fontsize_sp)
        local margin_bottom = units.getsize(styles,styles["margin-bottom"],styles_fontsize_sp)
        local margin_left = units.getsize(styles,styles["margin-left"],styles_fontsize_sp)

        local padding_top = units.getsize(styles,styles["padding-top"],styles_fontsize_sp)
        local padding_right = units.getsize(styles,styles["padding-right"],styles_fontsize_sp)
        local padding_bottom = units.getsize(styles,styles["padding-bottom"],styles_fontsize_sp)
        local padding_left = units.getsize(styles,styles["padding-left"],styles_fontsize_sp)

        local border_top_style = styles["border-top-style"] or "none"
        local border_right_style = styles["border-right-style"] or "none"
        local border_bottom_style = styles["border-bottom-style"] or "none"
        local border_left_style = styles["border-left-style"] or "none"

        local border_top_width = units.getsize(styles,styles["border-top-width"],styles_fontsize_sp)
        local border_right_width = units.getsize(styles,styles["border-right-width"],styles_fontsize_sp)
        local border_bottom_width = units.getsize(styles,styles["border-bottom-width"],styles_fontsize_sp)
        local border_left_width = units.getsize(styles,styles["border-left-width"],styles_fontsize_sp)

        local border_top_color = styles["border-top-color"]
        local border_right_color = styles["border-right-color"]
        local border_bottom_color = styles["border-bottom-color"]
        local border_left_color = styles["border-left-color"]

        border_top_color = border_top_color or styles.color or "black"
        border_right_color = border_right_color or styles.color or "black"
        border_bottom_color = border_bottom_color or styles.color or "black"
        border_left_color = border_left_color or styles.color or "black"

        local border_bottom_right_radius = styles["border-bottom-right-radius"] or 0
        local border_bottom_left_radius = styles["border-bottom-left-radius"] or 0
        local border_top_right_radius = styles["border-top-right-radius"] or 0
        local border_top_left_radius = styles["border-top-left-radius"] or 0

        options.border = {
            borderstart = true,
            border_top_style = border_top_style,
            border_right_style = border_right_style,
            border_bottom_style = border_bottom_style,
            border_left_style = border_left_style,
            padding_top = padding_top,
            padding_right = padding_right,
            padding_bottom = padding_bottom,
            padding_left = padding_left,
            border_top_width = border_top_width,
            border_right_width = border_right_width,
            border_bottom_width = border_bottom_width,
            border_left_width = border_left_width,
            border_top_color = border_top_color,
            border_right_color = border_right_color,
            border_bottom_color = border_bottom_color,
            border_left_color = border_left_color,
            border_bottom_right_radius = tex.sp(border_bottom_right_radius),
            border_bottom_left_radius = tex.sp(border_bottom_left_radius),
            border_top_right_radius = tex.sp(border_top_right_radius),
            border_top_left_radius = tex.sp(border_top_left_radius),
            margin_top = margin_top,
            margin_right = margin_right,
            margin_bottom = margin_bottom,
            margin_left = margin_left,
            debug = ( styles["sp-debugbox"] == "border" ) or false,
        }
    end

    -- Font style & weight
    local fontstyle    = styles["font-style"]
    local fontweight   = styles["font-weight"]
    if fontweight == "bold" then options.bold = 1 end
    if fontstyle == "italic" then options.italic = 1 end

    -- Colors (foreground + background)
    local bg = styles["background-color"]
    if styles.color then
        local col = colors_module.colors[styles.color]
        if col then
            local fg_index = col.index
            options.color = fg_index
            options.textdecorationcolor = fg_index
            styles.currentcolor = styles.color
        else
            splib.log("warning","HTML: color not defined", "color", styles.color)
        end
    end
    if bg then
        options.backgroundcolor = colors_module.colors[bg].index
    end

    -- Background paddings (publisher-specific extensions)
    local bg_padding_top = styles["background-padding-top"]
    if bg_padding_top then
        options.bg_padding_top = bg_padding_top
    end
    local bg_padding_bottom = styles["background-padding-bottom"]
    if bg_padding_bottom then
        options.bg_padding_bottom = bg_padding_bottom
    end

    -- Text decoration
    local line  = styles["text-decoration-line"]
    local style = styles["text-decoration-style"]
    local color = styles["text-decoration-color"]
    if color and color ~= "currentcolor" then
        options.textdecorationcolor = color
    end
    if line == "underline" or line == "line-through" then
        options.textdecorationline  = line
        options.textdecorationstyle = style
    end

    -- Whitespace handling
    local whitespace = styles["white-space"]
    if whitespace == "pre" then
        options.whitespace = "pre"
    end

    -- Vertical align (+ script-size tweak when family number is fixed)
    local valign = styles["vertical-align"]
    local famnum = tonumber(styles["font-family-number"])
    if valign == "super" or valign == "sub" then
        options.verticalalign = valign
        if famnum and famnum > 0 then
            options.fontsize = "small"
        end
    end

    return options
end

return M
