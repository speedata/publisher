-- The fontloader uses HarfBuzz to inspect an OpenType or a TrueType
-- font and converts it to a font structure TeX uses internally.
--
--  fontloader.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("fontloader.lua")

local publisher = require("publisher")

local M = {}

-- Return `truetype`, `opentype` or `type1` depending on the string
-- `filename`. If not recognized form  the file name, return _nil_.
-- This function simply looks at the last three letters.
function M.guess_fonttype(filename)
    local f = filename:lower()
    if f:match(".*%.ttf$") then
        return "truetype"
    elseif f:match(".*%.otf$") then
        return "opentype"
    elseif f:match(".*%.pfb$") then
        return "type1"
    else
        return nil
    end
end

---@param name string Font file name (without path).
---@param size number Font size in scaled points.
---@param extra_parameter table Additional font settings such as `space` or `otfeatures`.
---@return table f A not yet loaded font instance descriptor.
function M.preload_font(name, size, extra_parameter)
    local f = {
        loaded = false,
        requested_name = name,
        requested_size = size,
        requested_extra_parameter = extra_parameter,
    }
    return f
end

-- The harfbuzz version of the fontloader.
---@param name string Font file name (without path).
---@param size number Font size in scaled points.
---@param extra_parameter table Additional font settings such as `space` or `otfeatures`.
---@return boolean ok
---@return table|string fnt_or_msg A TeX usable font table on success, an error message otherwise.
function M.define_font_hb(name, size, extra_parameter)
    local glyphname_uni = {}
    if not publisher.hasharfbuzz then
        return false, "The harfbuzz library is not available, cannot load fonts."
    end
    if M.guess_fonttype(name) == "type1" then
        return false,
            string.format(
                "Type 1 font '%s' is not supported (support was removed in version 6.0). Please convert the font to OpenType.",
                name
            )
    end
    local filename_with_path = kpse.find_file(name)
    if not filename_with_path then
        return false, string.format("Fontfile '%s' not found.", name)
    end
    local face = publisher.harfbuzz.Face.new(filename_with_path)
    local fnt = publisher.harfbuzz.Font.new(face)

    if size < 0 then
        size = -655.36 * size
    end

    -- Some fonts have `units_per_em` set to 0. I am not sure if setting this to
    -- 1000 in that case has any drawbacks.
    local upem = face:get_upem()
    local mag = size / upem
    local backmap = {}
    local f = {}
    f.mag = mag
    f.mode = "harfbuzz"
    f.units_per_em = upem
    f.face = face
    f.font = fnt
    f.characters = {}
    f.otfeatures = {}
    f.name = face:get_name(6)
    f.fullname = face:get_name(6)
    f.designsize = size
    f.size = size
    f.direction = 0
    f.filename = filename_with_path
    f.type = "real"
    f.encodingbytes = 2
    f.tounicode = 1
    f.stretch = publisher.options.fontstretch or extra_parameter.stretch or 40
    f.shrink = publisher.options.fontshrink or extra_parameter.shrink or 30
    f.step = publisher.options.fontstep or extra_parameter.step or 10
    f.auto_expand = true
    f.embedding = "subset"
    f.format = M.guess_fonttype(name)
    f.parameters = {
        slant = 0,
        space = (extra_parameter.space or 25) / 100 * size,
        space_stretch = 0.3 * size,
        space_shrink = 0.1 * size,
        x_height = 0.4 * size,
        quad = 1.0 * size,
        emspace = size,
        enspace = size / 2,
        thirdspace = size / 3,
        quarterspace = size / 4,
        sixthspace = size / 6,
        thinspace = size / 8,
        hairspace = size / 24,
        extra_space = 0,
    }
    local features = {}
    if extra_parameter.otfeatures then
        for fea, enabled in pairs(extra_parameter.otfeatures) do
            local firstletter
            if enabled then
                firstletter = "+"
            else
                firstletter = "-"
            end
            table.insert(features, publisher.harfbuzz.Feature.new(firstletter .. fea))
        end
    end
    f.otfeatures = features
    local unicodes = face:collect_unicodes()
    local glyph_uni = {} -- gid -> primary unicode (lowest codepoint)
    local glyph_all_uni = {} -- gid -> { [uni1]=true, [uni2]=true, ... }
    for _, uni in next, unicodes do
        local gid = fnt:get_nominal_glyph(uni)
        if not glyph_all_uni[gid] then
            glyph_all_uni[gid] = {}
        end
        glyph_all_uni[gid][uni] = true
        local prev = glyph_uni[gid]
        if
            not prev
            or (prev < 32 and uni >= 32)
            or (uni >= 32 and uni < prev)
            or (uni < 32 and prev < 32 and uni < prev)
        then
            glyph_uni[gid] = uni
        end
    end

    for gid = 0, face:get_glyph_count() - 1 do
        local touni = glyph_uni[gid]
        local uni = touni or (publisher.puastart + gid)
        local ge = fnt:get_glyph_extents(gid)
        local hadvance = fnt:get_glyph_h_advance(gid)
        if uni == 160 then -- U+00A0 NO-BREAK SPACE
            uni = 32
        elseif uni == 48 then
            f.zerowidth = hadvance * mag
        end
        local glyphname = fnt:get_glyph_name(gid)

        if glyphname then
            glyphname_uni[glyphname] = uni
        end

        f.characters[uni] = {
            index = gid,
            width = hadvance * mag,
            hadvance = hadvance,
            name = glyphname,
            expansion_factor = 1000,
        }
        -- Margin protrusion is enabled in `spinit.lua`.
        if (uni == 44 or uni == 45 or uni == 46) and extra_parameter and tonumber(extra_parameter.marginprotrusion) then
            f.characters[uni]["right_protruding"] = extra_parameter.marginprotrusion
        end

        local thischar = f.characters[uni]
        backmap[gid] = uni
        if touni then
            thischar.tounicode = touni
        end
        if ge then
            thischar.height = ge.y_bearing * mag
            thischar.depth = (ge.height + ge.y_bearing) * -1 * mag
        end

        -- Create separate entries for all other unicodes sharing this glyph
        if glyph_all_uni[gid] then
            for other_uni, _ in pairs(glyph_all_uni[gid]) do
                if other_uni ~= uni and not f.characters[other_uni] then
                    f.characters[other_uni] = {
                        index = gid,
                        width = hadvance * mag,
                        hadvance = hadvance,
                        name = glyphname,
                        expansion_factor = 1000,
                        tounicode = other_uni,
                    }
                    if
                        (other_uni == 44 or other_uni == 45 or other_uni == 46)
                        and extra_parameter
                        and tonumber(extra_parameter.marginprotrusion)
                    then
                        f.characters[other_uni]["right_protruding"] = extra_parameter.marginprotrusion
                    end
                    if ge then
                        f.characters[other_uni].height = ge.y_bearing * mag
                        f.characters[other_uni].depth = (ge.height + ge.y_bearing) * -1 * mag
                    end
                end
            end
        end
    end

    for gid = 0, face:get_glyph_count() - 1 do
        local touni = glyph_uni[gid]
        local uni = touni or (publisher.puastart + gid)
        local glyphname = fnt:get_glyph_name(gid)
        if glyphname and string.find(glyphname, ".", 1, true) then
            local basename = string.match(glyphname, "^(.*)%.")
            local thischar = f.characters[uni]
            if thischar then
                thischar.tounicode = glyphname_uni[basename]
            end
        end
    end
    f.backmap = backmap

    local fallback_fontdefinitions = {}
    if extra_parameter.fallbacks then
        for i = #extra_parameter.fallbacks, 1, -1 do
            local fallbackname = extra_parameter.fallbacks[i]
            main.log(
                "info",
                "Create font metrics for fallback font",
                "name",
                fallbackname,
                "size",
                math.round(size / publisher.factor, 3)
            )
            local tmp, newfont_or_msg = M.define_font_hb(fallbackname, size, {})
            if not tmp then
                return false, newfont_or_msg
            end
            ---@cast newfont_or_msg -string
            local num = font.define(newfont_or_msg)
            newfont_or_msg.fontnum = num
            fallback_fontdefinitions[#fallback_fontdefinitions + 1] = newfont_or_msg
        end
    end

    f.fallback_fontdefinitions = fallback_fontdefinitions

    return true, f
end

file_end("fontloader.lua")

return M
-- End of file
