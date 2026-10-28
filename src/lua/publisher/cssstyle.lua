--
--  cssstyle.lua
--  speedata publisher
--
--  Turns the CSS properties of Paragraph, Textblock and tables (see css.lua,
--  `style`) into textformats, font families and paragraph options.
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("publisher/cssstyle.lua")

local publisher = require("publisher")
local colors_module = require("publisher.colors")

---@class cssstyle_module
local M = {}

local alignments = {
    center = "centered",
    ["end"] = "end",
    justify = "justified",
    left = "leftaligned",
    right = "rightaligned",
    start = "start",
}

-- Textformat properties that the elements inside a text block inherit.
local inherited_textformat_properties = {
    "hyphens",
    "letter-spacing",
    "orphans",
    "text-align",
    "text-indent",
    "widows",
}

-- Converts a CSS length to scaled points. `em` and `%` are relative to
-- `fontsize`, a plain 0 is allowed.
---@param value string
---@param fontsize integer Font size in sp.
---@return integer?
local function length_sp(value, fontsize)
    local num, unit = string.match(value, "^([-+]?%d*%.?%d+)(%a*%%?)$")
    num = tonumber(num)
    if not num then
        return nil
    end
    if unit == "em" then
        return math.round(num * fontsize)
    elseif unit == "%" then
        return math.round(num * fontsize / 100)
    elseif unit == "" then
        if num == 0 then
            return 0
        end
        return nil
    end
    local ok, sp = pcall(tex.sp, value)
    if ok then
        return sp
    end
    return nil
end

-- Logs an error about a CSS value that cannot be used.
---@param property string
---@param value string
local function invalid(property, value)
    main.log("error", "CSS: invalid value", "property", property, "value", value)
end

-- Returns the size of a font family in sp.
---@param fontfamily integer?
---@return integer
local function fontsize_of(fontfamily)
    local fam = publisher.fonts.lookup_fontfamily_number_instance[fontfamily or publisher.current_fontfamily]
    return fam and fam.size or tex.sp("10pt")
end

-- Returns the textformat fields for the CSS properties or nil, if there are
-- no textformat properties. With `inherited_only`, only the properties
-- that are inherited by the paragraphs of a text block are used.
---@param props table<string, string>
---@param fontsize integer Font size in sp for `em` values.
---@param inherited_only? boolean
---@return table?
function M.textformat_fields(props, fontsize, inherited_only)
    local fields = {}
    local found = false
    local function get(property)
        local value = props[property]
        if value and inherited_only then
            for _, p in ipairs(inherited_textformat_properties) do
                if p == property then
                    return value
                end
            end
            return nil
        end
        return value
    end
    local value = get("text-align")
    if value then
        if alignments[value] then
            fields.alignment = alignments[value]
            found = true
        else
            invalid("text-align", value)
        end
    end
    value = get("text-indent")
    if value then
        local sp = length_sp(value, fontsize)
        if sp then
            fields.indent = sp
            found = true
        else
            invalid("text-indent", value)
        end
    end
    value = get("hyphens")
    if value then
        fields.disable_hyphenation = value == "none"
        found = true
    end
    value = get("letter-spacing")
    if value then
        local sp = value == "normal" and 0 or length_sp(value, fontsize)
        if sp then
            fields.letterspacing = sp
            found = true
        else
            invalid("letter-spacing", value)
        end
    end
    for _, property in ipairs({ "orphans", "widows" }) do
        value = get(property)
        if value then
            if tonumber(value) then
                fields[property == "orphans" and "orphan" or "widow"] = tonumber(value)
                found = true
            else
                invalid(property, value)
            end
        end
    end
    for _, property in ipairs({ "margin-top", "margin-bottom" }) do
        value = get(property)
        if value then
            local sp = length_sp(value, fontsize)
            if sp then
                if property == "margin-top" then
                    fields.margintop = sp
                    fields.margintopboxstart = sp
                else
                    fields.marginbottom = sp
                end
                found = true
            else
                invalid(property, value)
            end
        end
    end
    value = get("break-before")
    if value then
        fields.break_before = (value == "page" or value == "always") and "page" or ""
        found = true
    end
    value = get("break-after")
    if value then
        fields.breakbelow = value ~= "avoid"
        found = true
    end
    if found then
        return fields
    end
    return nil
end

-- Returns a textformat that is `base` with the fields from
-- `textformat_fields`. Equal requests return the same textformat.
---@param base Textformat?
---@param fields table
---@return Textformat
function M.derive_textformat(base, fields)
    base = base or publisher.textformats.text
    local keys = {}
    for k in pairs(fields) do
        keys[#keys + 1] = k
    end
    table.sort(keys)
    local sig = {}
    for _, k in ipairs(keys) do
        sig[#sig + 1] = k .. "=" .. tostring(fields[k])
    end
    local name = "__css:" .. tostring(base.name) .. ":" .. table.concat(sig, ";")
    local tf = publisher.textformats[name]
    if tf then
        return tf
    end
    tf = publisher.dispatch.new_textformat(name, base, fields)
    if fields.letterspacing then
        tf.letterspacing_em = nil
    end
    return tf
end

-- Returns the definition of a font family name in the shape of
-- `publisher.fontgroup` (@font-face, generic families, LoadFontfile).
---@param name string
---@return table?
local function font_definition(name)
    local fontfaces = publisher.css:get_fontfaces()
    if fontfaces[name] then
        return fontfaces[name]
    end
    local generic = publisher.fontgroup[string.lower(name)]
    if generic then
        return generic
    end
    if publisher.fonts.is_registered(name) then
        return { regular = { ["local"] = name } }
    end
    return nil
end

-- Returns the font family for the CSS font properties (font-family,
-- font-size, line-height), based on the font family `base`. Returns `base`
-- if the properties do not change it.
---@param props table<string, string>
---@param base integer Font family number.
---@return integer
function M.fontfamily(props, base)
    local families, size, lineheight = props["font-family"], props["font-size"], props["line-height"]
    if not (families or size or lineheight) then
        return base
    end
    local lookup_number = publisher.fonts.lookup_fontfamily_name_number
    local definition, definitionname
    if families then
        local found = false
        for candidate in string.gmatch(families, "[^,]+") do
            candidate = string.gsub(string.gsub(candidate, "^%s*(.-)%s*$", "%1"), "^[\"'](.*)[\"']$", "%1")
            if lookup_number[candidate] then
                base = lookup_number[candidate]
                found = true
                break
            end
            definition = font_definition(candidate)
            if definition then
                definitionname = candidate
                found = true
                break
            end
        end
        if not found then
            main.log("error", "CSS: font family not found", "font-family", families)
        end
    end
    local basefam = publisher.fonts.lookup_fontfamily_number_instance[base]
    if not basefam then
        return base
    end
    local newsize = basefam.size
    if size then
        local sp = length_sp(size, basefam.size)
        if sp and sp > 0 then
            newsize = sp
        else
            invalid("font-size", size)
        end
    end
    local leading = math.round(basefam.baselineskip * newsize / basefam.size)
    if lineheight and lineheight ~= "normal" then
        local factor = tonumber(lineheight)
        local lh = factor and math.round(newsize * factor) or length_sp(lineheight, newsize)
        if lh and lh > 0 then
            leading = lh
        else
            invalid("line-height", lineheight)
        end
    end
    if not definition and newsize == basefam.size and leading == basefam.baselineskip then
        return base
    end
    local regular, bold, italic, bolditalic, name
    if definition then
        local function face(variant)
            local rec = definition[variant]
            if rec then
                return publisher.fonts.get_fontname(rec["local"], rec["url"])
            end
        end
        regular, bold, italic, bolditalic = face("regular"), face("bold"), face("italic"), face("bolditalic")
        name = string.format("__css:%s/%d/%d", definitionname, newsize, leading)
    else
        -- derive from the family the base was derived from, so that the
        -- same request returns the same family
        local root = basefam.cssroot or base
        local rootfam = publisher.fonts.lookup_fontfamily_number_instance[root]
        regular, bold = rootfam.fontfaceregular, rootfam.fontfacebold
        italic, bolditalic = rootfam.fontfaceitalic, rootfam.fontfacebolditalic
        name = string.format("__css:%s/%d/%d", rootfam.name, newsize, leading)
        base = root
    end
    if lookup_number[name] then
        return lookup_number[name]
    end
    local num, err = publisher.fontfamilies.define_fontfamily(regular, bold, italic, bolditalic, name, newsize, leading)
    if not num then
        main.log("error", "CSS: cannot define font family", "name", name, "msg", tostring(err))
        return base
    end
    if not definition then
        publisher.fonts.lookup_fontfamily_number_instance[num].cssroot = base
    end
    return num
end

-- Returns the absolute font size and line height of a font family as CSS
-- values, so that the elements inside inherit absolute values.
---@param fontfamily integer
---@return string? fontsize
---@return string? lineheight
function M.absolute_font_values(fontfamily)
    local fam = publisher.fonts.lookup_fontfamily_number_instance[fontfamily]
    if not fam then
        return nil, nil
    end
    return fam.size .. "sp", fam.baselineskip .. "sp"
end

-- Returns the font family of an element whose CSS properties the elements
-- inside inherit (Textblock, Table, Tr, Td), based on the font family
-- `base`. Relative values (`em`, `%`) are passed on as absolute values, so
-- that the elements inside do not apply them again.
---@param props table<string, string> Return value of `style`.
---@param base integer Font family number.
---@return integer
function M.inherit_fontfamily(props, base)
    if not next(props) then
        return base
    end
    local fontfamily = M.fontfamily(props, base)
    local relative_lineheight = props["line-height"] and not tonumber(props["line-height"])
    if props["font-size"] or relative_lineheight then
        local fs, lh = M.absolute_font_values(fontfamily)
        publisher.css:set_inherited("font-size", fs)
        if relative_lineheight then
            publisher.css:set_inherited("line-height", lh)
        end
    end
    local fontsize = fontsize_of(fontfamily)
    for _, property in ipairs({ "letter-spacing", "text-indent" }) do
        local sp = props[property] and length_sp(props[property], fontsize)
        if sp then
            publisher.css:set_inherited(property, sp .. "sp")
        end
    end
    return fontfamily
end

-- Splits the value of a CSS shorthand property with one to four values
-- (such as padding) into the values for the top, right, bottom and left
-- side.
---@param value string
---@return string top
---@return string right
---@return string bottom
---@return string left
function M.box_sides(value)
    local v = {}
    for part in string.gmatch(value, "%S+") do
        v[#v + 1] = part
    end
    local top = v[1] or value
    local right = v[2] or top
    local bottom = v[3] or top
    return top, right, bottom, v[4] or right
end

-- Sets the options for `Par:append` from the CSS properties of a paragraph:
-- color, bold, italic and background color.
---@param props table<string, string>
---@param params table
---@return nil
function M.paragraph_options(props, params)
    if props.color then
        params.color = colors_module.get_colorindex_from_name(props.color)
    end
    local weight = props["font-weight"]
    if weight then
        local num = tonumber(weight)
        params.bold = (weight == "bold" or weight == "bolder" or (num and num >= 600)) and 1 or nil
    end
    local fontstyle = props["font-style"]
    if fontstyle then
        params.italic = (fontstyle == "italic" or fontstyle == "oblique") and 1 or nil
    end
    if props["background-color"] then
        params.backgroundcolor = colors_module.get_colorindex_from_name(props["background-color"])
    end
end

M.length_sp = length_sp
M.fontsize_of = fontsize_of

file_end("publisher/cssstyle.lua")

return M
