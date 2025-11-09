--- Unit conversion helpers (em/rem/px/sp/percent) for HTML parser.
--- Relies on global `tex`, `math`, `err` like the legacy code.
local M = {}

---@class HtmlStyles
---@field rootfontsize_sp number
---@field fontsize_sp number

---Convert a CSS-like size to TeX scaled points (sp).
---Accepts: "Nrem", "Nem", number-as-string => px, TeX length string (e.g. "12pt", "1pc").
---@param styles HtmlStyles
---@param size any
---@param fontsize_sp number
---@return number sp
function M.getsize(styles, size, fontsize_sp)
  if size == nil then return 0 end
  if type(size) == "string" then
    if string.match(size, "rem$") then
      local amount = string.gsub(size, "^(.*)rem$", "%1")
      ---@diagnostic disable-next-line: cast-local-type
      return math.round(styles.rootfontsize_sp * amount)
    elseif string.match(size, "em$") then
      local amount = string.gsub(size, "^(.*)r?em$", "%1")
      ---@diagnostic disable-next-line: cast-local-type
      return math.round(fontsize_sp * amount)
    elseif tonumber(size) then
      return tex.sp(size .. "px")
    else
      return tex.sp(size)
    end
  elseif type(size) == "number" then
    -- Interpret bare numbers as px, for backward compatibility
    return tex.sp(tostring(size) .. "px")
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
    err("not implemented yet, calculate_height")
    return original_size
  end
end

return M
