--- Inline options builder for publisher.mknodes.
--- Extracted from the legacy set_options_for_mknodes implementation.

local fonts = require("html.fonts")
local units = require("html.units")
local colors_module = require("publisher.colors")

local M = {}

-- The background color of an element, nil for none or transparent.
---@param styles table
---@return string?
local function background_color(styles)
    local bg = styles["background-color"]
    if bg == "transparent" then
        return nil
    end
    return bg
end

-- An inline element is drawn as a box (see publisher.htmlbox) when it
-- has a border, a background with rounded corners or a background and
-- display: inline-block. The box draws the background, so it can follow
-- the rounded corners and covers the vertical padding.
---@param styles table
---@return boolean
function M.is_boxed(styles)
    if styles.has_border then
        return true
    end
    if not background_color(styles) then
        return false
    end
    if styles.display == "inline-block" then
        return true
    end
    for _, corner in ipairs({ "top-left", "top-right", "bottom-right", "bottom-left" }) do
        if units.getsize(styles, styles["border-" .. corner .. "-radius"], styles.fontsize_sp) > 0 then
            return true
        end
    end
    return false
end

---Configure options for publisher.mknodes based on the given styles.
---Mutates and returns `options`.
---@param styles table                       -- CSS-like style table (must include fontsize_sp etc.)
---@param options table|nil                  -- options table to fill; a new one if nil
---@param publisher any                      -- publisher environment (for colors etc.)
---@param fontfamilies table<string, any>    -- global fontfamilies map from the HTML tree
---@return table options
function M.set_options_for_mknodes(styles, options, publisher, fontfamilies)
    options = options or {}

    -- Font family / size
    local family = styles["font-family"]
    local fontsize = styles["font-size"]
    local fixedfam = tonumber(styles["font-family-number"])
    local script = styles["vertical-align"] == "sub" or styles["vertical-align"] == "super"
    if fixedfam and fixedfam > 0 and (script or options.fontsize == "small") then
        -- Sub- and superscripts (and their contents) take the script size of
        -- the family (see below), not the font-size of the default style
        -- sheet.
        options.fontfamily = fixedfam
    else
        options.fontfamily = fonts.get_fontfamily(family, styles.fontsize_sp, fontsize, styles, publisher, fontfamilies)
    end

    local boxed = M.is_boxed(styles)
    if boxed then
        local styles_fontsize_sp = styles.fontsize_sp
        local margin_top = units.getsize(styles, styles["margin-top"], styles_fontsize_sp)
        local margin_right = units.getsize(styles, styles["margin-right"], styles_fontsize_sp)
        local margin_bottom = units.getsize(styles, styles["margin-bottom"], styles_fontsize_sp)
        local margin_left = units.getsize(styles, styles["margin-left"], styles_fontsize_sp)

        local padding_top = units.getsize(styles, styles["padding-top"], styles_fontsize_sp)
        local padding_right = units.getsize(styles, styles["padding-right"], styles_fontsize_sp)
        local padding_bottom = units.getsize(styles, styles["padding-bottom"], styles_fontsize_sp)
        local padding_left = units.getsize(styles, styles["padding-left"], styles_fontsize_sp)

        local border_top_style = styles["border-top-style"] or "none"
        local border_right_style = styles["border-right-style"] or "none"
        local border_bottom_style = styles["border-bottom-style"] or "none"
        local border_left_style = styles["border-left-style"] or "none"

        -- A side without a border style has no border width (as in CSS).
        local function borderwidth(side, style)
            if style == "none" or style == "hidden" then
                return 0
            end
            return units.getsize(styles, styles["border-" .. side .. "-width"], styles_fontsize_sp)
        end
        local border_top_width = borderwidth("top", border_top_style)
        local border_right_width = borderwidth("right", border_right_style)
        local border_bottom_width = borderwidth("bottom", border_bottom_style)
        local border_left_width = borderwidth("left", border_left_style)

        local border_top_color = styles["border-top-color"]
        local border_right_color = styles["border-right-color"]
        local border_bottom_color = styles["border-bottom-color"]
        local border_left_color = styles["border-left-color"]

        border_top_color = border_top_color or styles.color or "black"
        border_right_color = border_right_color or styles.color or "black"
        border_bottom_color = border_bottom_color or styles.color or "black"
        border_left_color = border_left_color or styles.color or "black"

        local function radius(corner)
            return units.getsize(styles, styles["border-" .. corner .. "-radius"], styles_fontsize_sp)
        end

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
            border_bottom_right_radius = radius("bottom-right"),
            border_bottom_left_radius = radius("bottom-left"),
            border_top_right_radius = radius("top-right"),
            border_top_left_radius = radius("top-left"),
            background = background_color(styles),
            margin_top = margin_top,
            margin_right = margin_right,
            margin_bottom = margin_bottom,
            margin_left = margin_left,
            debug = (styles["sp-debugbox"] == "border") or false,
        }
    end

    -- Font style & weight
    local fontstyle = styles["font-style"]
    local fontweight = styles["font-weight"]
    -- Bold from 600 on, as in cssstyle.paragraph_options. "normal" and the
    -- like reset the value copied from the parent's options; unknown values
    -- (such as var()) keep it, as a browser ignores them.
    local weightnum = tonumber(fontweight)
    if fontweight == "bold" or fontweight == "bolder" or (weightnum and weightnum >= 600) then
        options.bold = 1
    elseif fontweight == "normal" or fontweight == "lighter" or weightnum then
        options.bold = nil
    end
    if fontstyle == "italic" or (fontstyle and string.match(fontstyle, "^oblique")) then
        options.italic = 1
    elseif fontstyle == "normal" then
        options.italic = nil
    end

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
            splib.log("warning", "HTML: color not defined", "color", styles.color)
        end
    end
    -- A boxed element draws its own background; the text keeps the
    -- background of the parent (if any), which shows at the rounded corners.
    if bg and not boxed then
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
    local line = styles["text-decoration-line"]
    local style = styles["text-decoration-style"]
    local color = styles["text-decoration-color"]
    if color and color ~= "currentcolor" then
        local col = colors_module.colors[color]
        if col then
            options.textdecorationcolor = col.index
        else
            splib.log("warning", "HTML: color not defined", "color", color)
        end
    end
    if line == "underline" or line == "overline" or line == "line-through" then
        options.textdecorationline = line
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
    elseif type(valign) == "string" and (string.match(valign, "^[-+.%d]") or string.match(valign, "^calc%(")) then
        -- A length raises (positive) or lowers the text, relative to the
        -- (possibly shifted) baseline of the parent. A percentage refers
        -- to the line height of the element.
        local shift
        local percent = string.match(valign, "^([-+]?[%d.]+)%%$")
        if percent then
            shift = math.round(fonts.lineheight(styles, styles.fontsize_sp) * tonumber(percent) / 100)
        else
            shift = units.getsize(styles, valign, styles.fontsize_sp)
        end
        if shift ~= 0 then
            options.yoffset = (options.yoffset or 0) + shift
        end
    end

    return options
end

return M
