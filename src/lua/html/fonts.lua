--- Font resolution helpers for the HTML parser.
--- Provides get_fontfamily(), which maps CSS family + size to a Publisher family number.

local strings = require("html.strings")

local M = {}

---Pick first known family from a list; fall back to "sans-serif".
---@param fontfamilies table<string, any>   -- map of known families (from elt.fontfamilies)
---@param fontgroup table<string, any>      -- publisher.fontgroup
---@param family_table string[]             -- candidates (possibly quoted)
---@return string chosen_name               -- the original (possibly quoted) family name
---@return table  chosen_def                -- the matching definition table
local function familyname(fontfamilies, fontgroup, family_table)
    for _, fontfamily in ipairs(family_table) do
        local ff = strings.has_quotes(fontfamily) and strings.remove_quotes(fontfamily) or string.lower(fontfamily)
        if fontfamilies[ff] then
            return fontfamily, fontfamilies[ff]
        elseif fontgroup[ff] then
            return fontfamily, fontgroup[ff]
        end
    end
    return "sans-serif", fontgroup["sans-serif"]
end

-- Returns the distance between two baselines for the CSS line-height in
-- `styles`. A plain number is a factor of the current font size (and inherited
-- as such), lengths and percentages are resolved where they are declared
-- (`styles.lineheight_sp`). `normal` keeps the traditional factor 1.12.
---@param styles table
---@param size_sp number Font size in sp.
---@return integer
function M.lineheight(styles, size_sp)
    local lh = styles["line-height"]
    if lh == nil or lh == "normal" then
        return math.round(size_sp * 1.12)
    end
    local factor = tonumber(lh)
    if factor then
        return math.round(size_sp * factor)
    end
    return styles.lineheight_sp or math.round(size_sp * 1.12)
end

-- Returns a font family with the faces of family `fontfamilynumber` at the
-- size `size_sp`. That is the family itself if it already has this size.
-- Without a line-height of its own the new family keeps the ratio of line
-- height and size of the original family.
---@param fontfamilynumber integer
---@param size_sp number? Font size in sp.
---@param styles table
---@param publisher any
---@return integer
function M.resize_fontfamily(fontfamilynumber, size_sp, styles, publisher)
    local fam = publisher.fonts.lookup_fontfamily_number_instance[fontfamilynumber]
    if not fam or not size_sp or math.abs(fam.size - size_sp) < 2 then
        return fontfamilynumber
    end
    size_sp = math.round(size_sp)
    local lh = styles["line-height"]
    local baselineskip
    if lh == nil or lh == "normal" then
        baselineskip = math.round(fam.baselineskip * size_sp / fam.size)
    else
        baselineskip = M.lineheight(styles, size_sp)
    end
    local famname = string.format("%s/%d/%d", fam.name or tostring(fontfamilynumber), size_sp, baselineskip)
    local predefined = publisher.fonts.lookup_fontfamily_name_number[famname]
    if predefined then
        return predefined
    end
    local newfam = publisher.fontfamilies.define_fontfamily(
        fam.fontfaceregular,
        fam.fontfacebold,
        fam.fontfaceitalic,
        fam.fontfacebolditalic,
        famname,
        size_sp,
        baselineskip
    )
    if not newfam then
        return fontfamilynumber
    end
    return newfam
end

---Resolve a CSS font-family + size to a Publisher font family number.
---@param families string                   -- CSS "font-family" value, comma-separated
---@param size_sp number                    -- font size in sp
---@param name string                       -- font name suffix used by Publisher (e.g., "12pt")
---@param styles table                      -- styles table (checked for "font-family-number")
---@param publisher any                     -- publisher env
---@param fontfamilies table<string, any>   -- global families table from the HTML tree
---@return integer                          -- Publisher font family number
function M.get_fontfamily(families, size_sp, name, styles, publisher, fontfamilies)
    local fontfamilynumber = tonumber(styles["font-family-number"])
    if fontfamilynumber and fontfamilynumber > 0 then
        -- Number already set (HTML from <Paragraph> etc.). Use it, at the
        -- requested size if a font-size changed it.
        local resized = M.resize_fontfamily(fontfamilynumber, size_sp, styles, publisher)
        if resized ~= fontfamilynumber then
            -- Children and em lengths refer to the resized family.
            styles["font-family-number"] = resized
        end
        return resized
    end

    local family_table = strings.split_string_quote(families)

    -- Direct predefined font family "family/name"?
    if #family_table == 1 then
        local fontname = families .. "/" .. name
        local predefined = publisher.fonts.lookup_fontfamily_name_number[fontname]
        if predefined then
            return predefined
        end
    end

    -- Pick first known family. The line height is part of the name, so a
    -- family is defined once for each combination of size and line height.
    local chosen, def = familyname(fontfamilies, publisher.fontgroup, family_table)
    local baselineskip = M.lineheight(styles, size_sp)
    local singlefont = string.format("%s/%d/%d", chosen, math.round(size_sp), baselineskip)

    -- Already defined at this size?
    local predefined = publisher.fonts.lookup_fontfamily_name_number[singlefont]
    if predefined then
        return predefined
    end

    -- Collect style variants
    local regular, bold, italic, bolditalic
    for weightstyle, rec in pairs(def) do
        local resolved = publisher.fonts.get_fontname(rec["local"], rec["url"])
        if weightstyle == "regular" then
            regular = resolved
        end
        if weightstyle == "bold" then
            bold = resolved
        end
        if weightstyle == "italic" then
            italic = resolved
        end
        if weightstyle == "bolditalic" then
            bolditalic = resolved
        end
    end

    -- A family declared only with other faces (for example an icon font
    -- with font-weight: 900) uses one of them as regular face, as a
    -- browser picks the nearest face.
    regular = regular or bold or italic or bolditalic

    -- Define family at the given size
    local fam =
        publisher.fontfamilies.define_fontfamily(regular, bold, italic, bolditalic, singlefont, size_sp, baselineskip)
    return fam
end

return M
