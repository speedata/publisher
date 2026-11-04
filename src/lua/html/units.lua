-- Unit conversion helpers (em/rem/px/sp/percent) for HTML parser.
-- Relies on global `tex`, `math`, `err` like the legacy code.
-- The `HtmlStyles` class is defined in `html/inherit.lua`.

local publisher = require("publisher")
local csscalc = require("csscalc")

local M = {}

-- Returns the size of 1em in sp: the size of the font family if the font
-- family number is fixed, otherwise `fontsize_sp`.
---@param styles HtmlStyles
---@param fontsize_sp number?
---@return number
function M.em_size(styles, fontsize_sp)
    local fn = tonumber(styles["font-family-number"])
    if fn then
        local fam = publisher.fonts.lookup_fontfamily_number_instance[fn]
        if fam then
            return fam.size
        end
    end
    return fontsize_sp or styles.fontsize_sp or 0
end

---Convert a CSS-like size to TeX scaled points (sp).
---Accepts: "Nrem", "Nem", number-as-string => px, TeX length string (e.g. "12pt", "1pc").
---@param styles HtmlStyles
---@param size any
---@param fontsize_sp number?
---@return number sp
function M.getsize(styles, size, fontsize_sp)
    if size == nil then
        return 0
    end
    if type(size) == "string" then
        if csscalc.is_calc(size) then
            return csscalc.length(size, {
                em = M.em_size(styles, fontsize_sp),
                rem = styles.rootfontsize_sp,
            }) or 0
        elseif string.match(size, "rem$") then
            local amount = string.gsub(size, "^(.*)rem$", "%1")
            ---@diagnostic disable-next-line: cast-local-type
            return math.round(styles.rootfontsize_sp * amount)
        elseif string.match(size, "em$") then
            local amount = string.gsub(size, "^(.*)r?em$", "%1")
            ---@diagnostic disable-next-line: cast-local-type
            return math.round(M.em_size(styles, fontsize_sp) * amount)
        elseif tonumber(size) then
            return tex.sp(size .. "px") or 0
        else
            return tex.sp(size) or 0
        end
    elseif type(size) == "number" then
        -- Interpret bare numbers as px, for backward compatibility
        return tex.sp(tostring(size) .. "px") or 0
    else
        return 0
    end
end

---Calculate a height from an attribute value.
---Supports percentages of original size, absolute numbers, or errors for unsupported forms.
---@param attribute_height any
---@param original_size number
---@return number height
function M.calculate_height(attribute_height, original_size)
    if type(attribute_height) == "string" and string.match(attribute_height, "%%$") then
        local amount = string.match(attribute_height, "(%d+)%%$")
        return math.round(original_size * tonumber(amount) / 100, 0)
    elseif tonumber(attribute_height) then
        ---@cast attribute_height number
        return attribute_height
    else
        main.log("error", "not implemented yet, calculate_height")
        return original_size
    end
end

return M
