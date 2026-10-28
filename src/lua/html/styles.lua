-- Style helpers for HTML parser: width calculation and attribute copying.
-- Uses global `tex` and `math` like the legacy code.
-- The `HtmlStyles` class is defined in `html/inherit.lua`, where instances are created.
local units = require("html.units")

local M = {}

---Recompute styles.calculated_width based on CSS-like width and box extras.
---@param styles HtmlStyles
---@return nil
function M.set_calculated_width(styles)
    local sw = styles.width or "auto"
    local cw = styles.calculated_width

    if type(sw) == "string" and string.match(sw, "%%$") then
        local amount = string.match(sw, "([%d.]+)%%$")
        cw = math.round(cw * tonumber(amount) / 100, 0)
    elseif type(sw) == "string" and string.match(sw, "em$") then
        cw = units.getsize(styles, sw, styles.fontsize_sp)
    elseif sw == "auto" then
        cw = styles.calculated_width

        if styles.height and styles.height ~= "auto" then
            styles.height = tex.sp(styles.height)
        else
            styles.height = nil
        end
    elseif tonumber(sw) then
        cw = tex.sp(string.format("%spx", sw))
    elseif type(sw) == "string" and tex.sp(sw) then
        cw = tex.sp(sw)
    end

    styles.calculated_width = cw
end

---Copy (inline-)style attributes into styles table and post-process line-height & width.
---@param styles HtmlStyles
---@param attributes table<string, any>
---@param _elementname string|nil
---@return nil
function M.copy_attributes(styles, attributes, _elementname)
    local remember_currentcolor ---@type string[]
    remember_currentcolor = {}

    for k, v in pairs(attributes) do
        if k == "font-size" then
            if type(v) == "string" and string.match(v, "rem$") then
                local amount = string.gsub(v, "^(.*)rem$", "%1")
                styles.fontsize_sp = math.round(styles.rootfontsize_sp * amount)
            elseif type(v) == "string" and string.match(v, "em$") then
                local amount = string.gsub(v, "^(.*)em$", "%1")
                styles.fontsize_sp = math.round(styles.fontsize_sp * amount)
            elseif type(v) == "string" and string.match(v, "%d+%%$") then
                local amount = string.match(v, "(%d+)%%$")
                styles.fontsize_sp = math.round(styles.fontsize_sp * tonumber(amount) / 100, 0)
            elseif v == "small" or v == "smaller" then
                styles.fontsize_sp = math.round(styles.fontsize_sp * 0.8)
            elseif v == "larger" then
                styles.fontsize_sp = math.round(styles.fontsize_sp * 1.2)
            else
                styles.fontsize_sp = tex.sp(v)
            end
        elseif k == "width" then
            styles.width = v
            M.set_calculated_width(styles)
        end

        if v == "currentcolor" then
            remember_currentcolor[#remember_currentcolor + 1] = k
        end

        styles[k] = v
    end

    -- Resolve "currentcolor" after color has possibly been set above.
    for i = 1, #remember_currentcolor do
        styles[remember_currentcolor[i]] = styles.color
    end

    -- line-height post-processing: lengths and percentages are resolved
    -- here and inherited as an absolute value. Plain numbers and "normal"
    -- depend on the font size of each element (see html.fonts.lineheight).
    local lh = attributes["line-height"]
    if lh and lh ~= "normal" and not tonumber(lh) then
        local percent = string.match(lh, "^([%d.]+)%%$")
        if percent then
            styles.lineheight_sp = math.round(styles.fontsize_sp * tonumber(percent) / 100)
        else
            styles.lineheight_sp = units.getsize(styles, lh, styles.fontsize_sp)
        end
    end
end

return M
