--- Inline options builder for publisher.mknodes.
--- Extracted from the legacy set_options_for_mknodes implementation.

local fonts = require("html.fonts")

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

    -- Font style & weight
    local fontstyle    = styles["font-style"]
    local fontweight   = styles["font-weight"]
    if fontweight == "bold" then options.bold = 1 end
    if fontstyle == "italic" then options.italic = 1 end

    -- Colors (foreground + background)
    local bg = styles["background-color"]
    if styles.color then
        local fg_index = publisher.colors[styles.color].index
        options.color = fg_index
        options.textdecorationcolor = fg_index
        styles.currentcolor = styles.color
    end
    if bg then
        options.backgroundcolor = publisher.colors[bg].index
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
