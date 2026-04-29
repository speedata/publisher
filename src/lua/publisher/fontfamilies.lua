--- Font family definitions.
--
--  fontfamilies.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("fontfamilies.lua")

local M = {}

local fonts = require("publisher.fonts")

-- resolve all font aliases
function M.get_fontname(fontname)
    if not fontname then return nil end
    local result = fontname
    while true do
        if publisher.fontaliases[result] then
            result = publisher.fontaliases[result]
        else
            break
        end
    end
    return result
end

function M.define_fontfamily( regular, bold, italic, bolditalic, name, size, baselineskip, scriptsize, supershift, subshift)
    if not size then
        main.log("error","DefineFontfamily needs size value")
        return
    end
    if not scriptsize then
        scriptsize = math.round(size * 0.8, 0)
    end
    if not supershift then
        supershift = math.round(size * 0.3, 0)
    end
    if not subshift then
        subshift = math.round(size * 0.3, 0)
    end
    if not tonumber(size) then
        main.log("error","DefineFontfamily needs size value")
        return
    end
    local fam = {
        size         = size,
        baselineskip = baselineskip,
        scriptsize   = scriptsize,
        supershift   = supershift,
        subshift     = subshift,
        name = name,
    }
    local ok, tmp
    if regular then
        ok, tmp = fonts.make_font_instance(regular, fam.size)
        if not ok then return false, tmp end
        fam.normal = tmp
        fam.fontfaceregular = regular
        ok, tmp = fonts.make_font_instance(regular, fam.scriptsize)
        if not ok then return false, tmp end
        fam.normalscript = tmp
    end

    if bold then
        ok, tmp = fonts.make_font_instance(bold, fam.size)
        if not ok then return false, tmp end
        fam.bold = tmp
        fam.fontfacebold = bold
        ok, tmp = fonts.make_font_instance(bold, fam.scriptsize)
        if not ok then return false, tmp end
        fam.boldscript = tmp
    end

    if italic then
        ok, tmp = fonts.make_font_instance(italic, fam.size)
        if not ok then return false, tmp end
        fam.italic = tmp
        fam.fontfaceitalic = italic
        ok, tmp = fonts.make_font_instance(italic, fam.scriptsize)
        if not ok then return false, tmp end
        fam.italicscript = tmp
    end

    if bolditalic then
        ok, tmp = fonts.make_font_instance(bolditalic, fam.size)
        if not ok then return false, tmp end
        fam.bolditalic = tmp
        fam.fontfacebolditalic = bolditalic
        ok, tmp = fonts.make_font_instance(bolditalic, fam.scriptsize)
        if not ok then return false, tmp end
        fam.bolditalicscript = tmp
    end

    fonts.lookup_fontfamily_number_instance[#fonts.lookup_fontfamily_number_instance + 1] = fam
    local fontnumber = #fonts.lookup_fontfamily_number_instance
    fonts.lookup_fontfamily_name_number[name] = fontnumber
    main.log("info","Define font family","name",name,"size",math.round(size / publisher.factor, 3),"leading",math.round(baselineskip / publisher.factor, 3), "id",fontnumber)
    if regular then main.log("debug", "Instance created", "instance", "regular", "name", regular,"id",fam.normal) end
    if bold then main.log("debug", "Instance created", "instance", "bold", "name", bold,"id",fam.bold) end
    if italic then main.log("debug", "Instance created", "instance", "italic", "name", italic,"id",fam.italic) end
    if bolditalic then main.log("debug", "Instance created", "instance", "bolditalic", "name", bolditalic,"id",fam.bolditalic) end
    return fontnumber
end

--- Called once from `dothings()` during startup. Defines a family
--- with regular, bold, italic and bolditalic font with size 10pt
--- (we always measure font size in DTP points).
function M.define_default_fontfamily()
    M.define_fontfamily(
        "TeXGyreHeros-Regular",
        "TeXGyreHeros-Bold",
        "TeXGyreHeros-Italic",
        "TeXGyreHeros-BoldItalic",
        "text",
        publisher.tenpoint_sp,
        publisher.twelvepoint_sp
    )

    publisher.fontaliases["sans"] = "TeXGyreHeros-Regular"
    publisher.fontaliases["sans-bold"] = "TeXGyreHeros-Bold"
    publisher.fontaliases["sans-italic"] = "TeXGyreHeros-Italic"
    publisher.fontaliases["sans-bolditalic"] = "TeXGyreHeros-BoldItalic"

    publisher.fontaliases["serif"] = "CrimsonPro-Regular"
    publisher.fontaliases["serif-bold"] = "CrimsonPro-Bold"
    publisher.fontaliases["serif-italic"] = "CrimsonPro-Italic"
    publisher.fontaliases["serif-bolditalic"] = "CrimsonPro-BoldItalic"

    publisher.fontaliases["monospace"] = "CamingoCode-Regular"
    publisher.fontaliases["monospace-bold"] = "CamingoCode-Bold"
    publisher.fontaliases["monospace-italic"] = "CamingoCode-Italic"
    publisher.fontaliases["monospace-bolditalic"] = "CamingoCode-BoldItalic"
end

file_end("fontfamilies.lua")

return M
