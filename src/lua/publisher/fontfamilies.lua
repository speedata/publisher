-- Font family definitions.
--
--  fontfamilies.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("fontfamilies.lua")

local publisher = require("publisher")

---@class fontfamilies_module
local M = {}

local fonts = require("publisher.fonts")

---@class FontFamily
---@field size integer Font size in scaled points.
---@field baselineskip integer Baseline skip in scaled points.
---@field scriptsize integer Subscript/superscript size in sp.
---@field supershift integer Superscript baseline shift in sp.
---@field subshift integer Subscript baseline shift in sp.
---@field name string Family name.
---@field normal? integer LuaTeX font instance id for the regular face.
---@field normalscript? integer Font instance id for the regular face at script size.
---@field bold? integer
---@field boldscript? integer
---@field italic? integer
---@field italicscript? integer
---@field bolditalic? integer
---@field bolditalicscript? integer
---@field fontfaceregular? string Source font name for the regular face.
---@field fontfacebold? string
---@field fontfaceitalic? string
---@field fontfacebolditalic? string

-- Resolves a font name through `publisher.fontaliases` until it points at a
-- concrete font face (or hits a name that is not aliased).
---@param fontname string?
---@return string? resolved
function M.get_fontname(fontname)
    if not fontname then
        return nil
    end
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

-- Defines a new font family with the four standard faces and registers it
-- in `fonts.lookup_fontfamily_*`. Missing faces are simply omitted from the
-- resulting `FontFamily`. Each provided face additionally gets a script-size
-- instance for sub/superscripts.
---@param regular string? Regular face source name.
---@param bold string? Bold face source name.
---@param italic string? Italic face source name.
---@param bolditalic string? Bold italic face source name.
---@param name string Family name (key for lookup).
---@param size integer Font size in scaled points.
---@param baselineskip integer Baseline skip in scaled points.
---@param scriptsize? integer Defaults to `round(size * 0.8)`.
---@param supershift? integer Defaults to `round(size * 0.3)`.
---@param subshift? integer Defaults to `round(size * 0.3)`.
---@return integer|false fontnumber Family number on success; `false` on failure.
---@return string? errmsg Error message when a face cannot be instantiated.
function M.define_fontfamily(
    regular,
    bold,
    italic,
    bolditalic,
    name,
    size,
    baselineskip,
    scriptsize,
    supershift,
    subshift
)
    if not size then
        main.log("error", "DefineFontfamily needs size value")
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
        main.log("error", "DefineFontfamily needs size value")
        return
    end
    local fam = {
        size = size,
        baselineskip = baselineskip,
        scriptsize = scriptsize,
        supershift = supershift,
        subshift = subshift,
        name = name,
    }
    local ok, tmp
    if regular then
        ok, tmp = fonts.make_font_instance(regular, fam.size)
        if not ok then
            return false, tmp
        end
        fam.normal = tmp
        fam.fontfaceregular = regular
        ok, tmp = fonts.make_font_instance(regular, fam.scriptsize)
        if not ok then
            return false, tmp
        end
        fam.normalscript = tmp
    end

    if bold then
        ok, tmp = fonts.make_font_instance(bold, fam.size)
        if not ok then
            return false, tmp
        end
        fam.bold = tmp
        fam.fontfacebold = bold
        ok, tmp = fonts.make_font_instance(bold, fam.scriptsize)
        if not ok then
            return false, tmp
        end
        fam.boldscript = tmp
    end

    if italic then
        ok, tmp = fonts.make_font_instance(italic, fam.size)
        if not ok then
            return false, tmp
        end
        fam.italic = tmp
        fam.fontfaceitalic = italic
        ok, tmp = fonts.make_font_instance(italic, fam.scriptsize)
        if not ok then
            return false, tmp
        end
        fam.italicscript = tmp
    end

    if bolditalic then
        ok, tmp = fonts.make_font_instance(bolditalic, fam.size)
        if not ok then
            return false, tmp
        end
        fam.bolditalic = tmp
        fam.fontfacebolditalic = bolditalic
        ok, tmp = fonts.make_font_instance(bolditalic, fam.scriptsize)
        if not ok then
            return false, tmp
        end
        fam.bolditalicscript = tmp
    end

    fonts.lookup_fontfamily_number_instance[#fonts.lookup_fontfamily_number_instance + 1] = fam
    local fontnumber = #fonts.lookup_fontfamily_number_instance
    fonts.lookup_fontfamily_name_number[name] = fontnumber
    main.log(
        "info",
        "Define font family",
        "name",
        name,
        "size",
        math.round(size / publisher.factor, 3),
        "leading",
        math.round(baselineskip / publisher.factor, 3),
        "id",
        fontnumber
    )
    if regular then
        main.log("debug", "Instance created", "instance", "regular", "name", regular, "id", fam.normal)
    end
    if bold then
        main.log("debug", "Instance created", "instance", "bold", "name", bold, "id", fam.bold)
    end
    if italic then
        main.log("debug", "Instance created", "instance", "italic", "name", italic, "id", fam.italic)
    end
    if bolditalic then
        main.log("debug", "Instance created", "instance", "bolditalic", "name", bolditalic, "id", fam.bolditalic)
    end
    return fontnumber
end

-- Called once from `dothings()` during startup. Defines the default `text`
-- family at 10pt (TeX Gyre Heros) and registers the standard sans/serif/
-- monospace aliases used by HTML/CSS rendering.
---@return nil
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
