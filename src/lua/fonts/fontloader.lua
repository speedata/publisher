--- The fontloader uses the LuaTeX internal fontforge library (called
--- fontloader) to inspect an OpenType, a TrueType or a Type1 font. It
--- converts this font to a font structure  TeX uses internally.
--
--  fontloader.lua
--  speedata publisher
--
--  Copyright 2010-2011 Patrick Gundlach.
--  See file COPYING in the root directory for license info.


module(...,package.seeall)

--- Return `truetype`, `opentype` or `type1` depending on the string
--- `filename`. If not recognized form  the file name, return _nil_.
--- This function simply looks at the last three letters.
function guess_fonttype( filename )
    local f=filename:lower()
    if f:match(".*%.ttf$") then return "truetype"
    elseif f:match(".*%.otf$") then return "opentype"
    elseif f:match(".*%.pfb$") then return "type1"
    else return nil
    end
end

--- Return `true` if the this feature table `tab` has an entry for the
--- given `script` and `lang`. The table is something like:
---
---     [1] = {
---       ["langs"] = {
---         [1] = "AZE "
---         [2] = "CRT "
---         [3] = "TRK "
---       },
---       ["script"] = "latn"
---     },
function features_scripts_matches( tab,script,lang )
    local lang   = string.lower(lang)
    local script = string.lower(script)
    for i=1,#tab do
        local entry = tab[i]
        if string.lower(entry.script)==script then
            for j=1,#entry.langs do
                if string.lower(entry.langs[j])==lang then
                    return true
                end
            end
        end
    end
    return false
end

--- Convert codepoint to a UTF-16 string.
function to_utf16(codepoint)
    assert(codepoint)
    if codepoint < 65536 then
        return string.format("%04X",codepoint)
    else
        return string.format("%04X%04X",codepoint / 1024 + 0xD800 ,codepoint % 1024 + 0xDC00)
    end
end

--- Return the string that is responsible for the OpenType feature `featurename`.
--- Currently only gsub lookups are supported for script `latn` and language `dflt`.
function find_feature_string(f,featurename)
    local ret = {}
    if f.gsub==nil then
        return ret
    end
    for i=1,#f.gsub do
        local gsub_table=f.gsub[i]
        if gsub_table.features then
            for j = 1,#gsub_table.features do
                local gtf = gsub_table.features[j]
                if gtf.tag==featurename and features_scripts_matches(gtf.scripts,"latn","dflt") then
                    ret[#ret + 1] = gsub_table.subtables[1].name
                end
            end
        end
    end
    return ret
end

--- LuaTeX's fontloader (function `to_table()`) returns a rather complex table
--- with all kinds of information. Loading this table is expensive (_todo:
--- measure it_), so we  don't load it over and over agin if the user
--- requests the same font in a different size. We also cache  the `to_unicode` mapping.
--- Only the size dependent values are computed.
local lookup_fonttable_from_filename = {}


--- Return a TeX usable font table, or _nil_ plus an error message.
--- The parameter `name` is the filename (without path), `size` is
--- given in scaled points, `extra_parameter` is a table such as:
---     {
---       ["space"] = "25"
---       ["marginprotrusion"] = "100"
---       ["otfeatures"] = {
---         ["smcp"] = "true"
---       },
---     },
function define_font(name, size,extra_parameter)
    local extra_parameter = extra_parameter or {}
    local fonttable
    local missing_features = {}

    if lookup_fonttable_from_filename[name] then
        fonttable=lookup_fonttable_from_filename[name]
        assert(fonttable)
    else
        -- These are stored in the cached fonttable table
        local filename_with_path
        local lookup_codepoint_by_name   = {}
        local lookup_codepoint_by_number = {}

        filename_with_path = kpse.find_file(name)
        if not filename_with_path then return false, string.format("Fontfile '%s' not found.", name) end
        local font, err = fontloader.open(filename_with_path)
        if not font then
            if type(err) == "string" then
                return false, err
            else
                printtable("Font error",err)
            end
        end
        fonttable = fontloader.to_table(font)
        if fonttable == nil then return false, string.format("Problem while loading font '%s'",tostring(filename_with_path))  end

        -- Store the table for quicker lookup later.
        lookup_fonttable_from_filename[name]=fonttable

        fonttable.filename_with_path = filename_with_path
        local is_unicode = (fonttable.pfminfo.unicoderanges ~= nil)

        --- We require a mapping glyph number -> unicode codepoint.
        --- I used to have two different means of unicode -> glyph mapping.
        --- The type1 fonts got the unicode point with `g.unicode`, the
        --- The ttf/otf font got the point with `fonttable.map.backmap[i]`
        --- Somehow this worked a few years until Arial Narrow could not display
        --- a semicolon (see issue #152).
        --- Now I use g.unicode if present, otherwise map.backmap.
        --- See issue #154

        local glyphtable = {}
        if fonttable.subfonts and #fonttable.subfonts > 0 then
            -- this looks like a CID-keyed font such as Noto
            for _,subfont in pairs(fonttable.subfonts) do
                for glyphno,g in pairs(subfont.glyphs) do
                    -- hyphen
                    if g.unicode == 8209 then
                        g.unicode = 45
                    end
                    glyphtable[#glyphtable + 1] = g
                    glyphtable[#glyphtable].glyphno = glyphno
                end
            end
        else
            -- all regular
            for glyphno,g in pairs(fonttable.glyphs) do
                glyphtable[#glyphtable + 1] = g
                glyphtable[#glyphtable].glyphno = glyphno
            end
        end
            --- For kerning a mapping glyphname -> codepoint is needed.

        for i = 1,#glyphtable do
            local g=glyphtable[i]
            local cp = g.unicode
            if cp == -1 then cp = fonttable.map.backmap[i] end
            lookup_codepoint_by_name[g.name] = cp
            lookup_codepoint_by_number[g.glyphno]    = cp
        end
        fonttable.lookup_codepoint_by_name   = lookup_codepoint_by_name
        fonttable.lookup_codepoint_by_number = lookup_codepoint_by_number
        fonttable.glyphtable = glyphtable
    end

    --- A this point we have taken the `fonttable` from memory or from `fontloader#to_table()`. The next
    --- part is mostly size/features dependent.

    if (size < 0) then size = (- 655.36) * size end
    -- Some fonts have `units_per_em` set to 0. I am not sure if setting this to
    -- 1000 in that case has any drawbacks.
    if fonttable.units_per_em == 0 then fonttable.units_per_em = 1000 end
    local mag = size / fonttable.units_per_em

    --- The table `f` is the font structure that TeX can use, see chapter 7 of the LuaTeX manual for a detailed description. This is returned from
    --- the function. It is safe to store additional data here.
    local f = { }

    -- The index of the characters table must match the glyphs in the
    -- "document". It is wise to have everything in unicode, so we do keep that
    -- in mind when filling the characters subtable.
    f.characters    = { }
    f.fontloader    = fonttable
    f.otfeatures    = {}

    f.name          = fonttable.fontname
    f.fullname      = fonttable.fontname
    f.designsize    = size
    f.size          = size
    f.direction     = 0
    f.filename      = fonttable.filename_with_path
    f.type          = 'real'
    f.encodingbytes = 2
    f.tounicode     = 0
    f.stretch       = 40
    f.shrink        = 30
    f.step          = 10
    f.auto_expand   = true

    f.parameters    = {
        slant         = 0,
        space         = ( extra_parameter.space or 25 ) / 100  * size,
        space_stretch = 0.3  * size,
        space_shrink  = 0.1  * size,
        x_height      = 0.4  * size,
        quad          = 1.0  * size,
        extra_space   = 0
    }

    f.format = guess_fonttype(name)
    if f.format==nil then return false,"Could not determine the type of the font '".. fonttable.filename_with_path .."'." end

    f.embedding = "subset"
    f.cidinfo = fonttable.cidinfo


    for i=1,#fonttable.glyphtable do
        local glyph     = fonttable.glyphtable[i]
        local glyphno   = glyph.glyphno
        local codepoint = fonttable.lookup_codepoint_by_number[glyphno]

        -- TeX uses U+002D HYPHEN-MINUS for hyphen, correct would be U+2012 HYPHEN.
        -- Because font vendors all have different ideas of hyphen, we just map all
        -- occurrences of *HYPHEN* to 0x2D (decimal 45)
        if glyph.name:lower():match("^hyphen$") then codepoint=45  end
        if codepoint then
            f.characters[codepoint] = {
                index = glyphno,
                width = glyph.width * mag,
                name  = glyph.name,
                expansion_factor = 1000,
                lookups = glyph.lookups,
            }

            -- Height and depth of the glyph
            if glyph.boundingbox[4] then f.characters[codepoint].height = glyph.boundingbox[4] * mag  end
            if glyph.boundingbox[2] then f.characters[codepoint].depth = -glyph.boundingbox[2] * mag  end

            --- We change the `tounicode` entry for entries with a period. Sometimes fonts
            --- have entries like `a.sc` or `a.c2sc` for smallcaps letter a. We are
            --- only interested in the part before the period.
            --- _This solution might not be perfect_.
            if glyph.name:match("%.") then
                local destname = glyph.name:gsub("^([^%.]*)%..*$","%1")
                local cp = fonttable.lookup_codepoint_by_name[destname]
                if cp then
                    f.characters[codepoint].tounicode=to_utf16(cp)
                end
            end


            --- Margin protrusion is enabled in `spinit.lua`.
            if (glyph.name=="hyphen" or glyph.name=="period" or glyph.name=="comma") and extra_parameter and type(extra_parameter.marginprotrusion) == "number" then
                f.characters[codepoint]["right_protruding"] = glyph.width * extra_parameter.marginprotrusion / 100
            end

            --- We do kerning by default. In the future we could turn it off.
            local kerns={}
            if glyph.kerns then
                for _,kern in pairs(glyph.kerns) do
                    local dest = fonttable.lookup_codepoint_by_name[kern.char]
                    if dest and dest > 0 then
                        kerns[dest] = kern.off * mag
                    else
                    end
                end
            end
            f.characters[codepoint].kerns = kerns
        end
    end

    local fallback_fontdefinitions = {}
    if extra_parameter.fallbacks then
        for i=#extra_parameter.fallbacks,1,-1 do
            local fnt = extra_parameter.fallbacks[i]
            local tmp, newfont = define_font(fnt,size)
            if tmp then
                local num = font.define(newfont)
                newfont.fontnum = num
                fallback_fontdefinitions[#fallback_fontdefinitions + 1] = newfont
            else
                return nil, newfont
            end
        end
    end

    -- create a virtual font to fake a feature
    local needs_virtual_font = false
    local new_f
    if extra_parameter and extra_parameter.otfeatures then
        for of,enabled in pairs(extra_parameter.otfeatures) do
            if enabled then
                if of == "tnum" or of == "lnum" then
                    missing_features[#missing_features + 1] = of
                    needs_virtual_font = true
                else
                    local featuret = find_feature_string(fonttable,of)
                    if featuret and #featuret > 0 then
                        f.otfeatures[#f.otfeatures + 1] = featuret
                    else
                        missing_features[#missing_features + 1] = of
                    end
                end
            end
        end
    end

    for _,feature in ipairs(missing_features) do
        if feature == "tnum" then
            needs_virtual_font = true
            break
        end
    end

    if #fallback_fontdefinitions > 0 then
        needs_virtual_font = true
    end

    -- first define a virtual font
    if needs_virtual_font then
        local num = font.define(f)
        new_f = {
            fonts = {{ id = num }},
        }
        for _,fnt in ipairs(fallback_fontdefinitions) do
            new_f.fonts[#new_f.fonts + 1] = { id = fnt.fontnum }
        end
        new_f.name          = f.name
        new_f.fullname      = f.fullname
        new_f.designsize    = f.designsize
        new_f.size          = f.size
        new_f.direction     = f.direction
        new_f.filename      = f.filename
        new_f.encodingbytes = f.encodingbytes
        new_f.tounicode     = f.tounicode
        new_f.stretch       = f.stretch
        new_f.shrink        = f.shrink
        new_f.step          = f.step
        new_f.auto_expand   = f.auto_expand
        new_f.parameters    = f.parameters
        new_f.characters = {}
        new_f.otfeatures = f.otfeatures
        new_f.fontloader = f.fontloader

        for _fntnum,fnt in ipairs(fallback_fontdefinitions) do
            for i,v in pairs(fnt.characters) do
                new_f.characters[i] = {
                    index = v.index,
                    width = v.width,
                    height = v.height,
                    depth = v.depth,
                    commands =  { { 'font',_fntnum + 1 }, {'char',i} },
                    lookups = v.lookups,
                    kerns = v.kerns,
                }
            end
        end

        for i,v in pairs(f.characters) do
            new_f.characters[i] = {
                index = v.index,
                width = v.width,
                height = v.height,
                depth = v.depth,
                commands =  { {'char',i} },
                lookups = v.lookups,
                kerns = v.kerns,
            }
        end

        -- now we can add features to the font
        for _,feature in ipairs(missing_features) do
            if feature == "lnum" then
                local featuret = find_feature_string(fonttable,"lnum")
                if featuret and #featuret > 0 then
                    featuret = featuret[1]
                end
                for i=48,57 do
                    local lookups = new_f.characters[i].lookups
                    if lookups and lookups[featuret] then
                        destname = lookups[featuret][1].specification.variant
                        local dest = fonttable.lookup_codepoint_by_name[destname]
                        new_f.characters[i] = new_f.characters[dest]
                    end
                end
            end
        end

        for _,feature in ipairs(missing_features) do
            if feature == "tnum" then
                local maxfigurewidth = 0
                local glyphwd
                for i=48,57 do
                    maxfigurewidth = math.max(maxfigurewidth,new_f.characters[i].width)
                end
                for i=48,57 do
                    local thisglyph = new_f.characters[i]
                    glyphwd = thisglyph.width
                    if maxfigurewidth ~= glyphwd then
                        thisglyph.width = maxfigurewidth
                        thisglyph.commands = {
                           {'right', ( maxfigurewidth - glyphwd ) / 2 },
                           thisglyph.commands[1]
                        }
                    end
                end
            end
        end

        return true,new_f
    end

    return true,f
end

-- End of file
