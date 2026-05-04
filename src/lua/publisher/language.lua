-- Language and locale handling.
--
--  language.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("language.lua")

local publisher = require("publisher")

---@class language_module
local M = {}

---@class LanguageEntry
---@field id integer LuaTeX-internal language id (`l:id()`).
---@field l userdata The `lang` object created via `lang.new()`.
---@field locale string Lower-cased locale string used to look the entry up.

-- We map from symbolic names to (part of) file names. The hyphenation pattern files are
-- in the format `hyph-XYZ.pat.txt` and we need to find out that `XYZ` part.
---@type table<string, string>
local language_mapping = {
    ["Ancient Greek"]                = "grc",
    ["Armenian"]                     = "hy",
    ["Bahasa Indonesia"]             = "id",
    ["Basque"]                       = "eu",
    ["Bulgarian"]                    = "bg",
    ["Catalan"]                      = "ca",
    ["Chinese"]                      = "zh",
    ["Croatian"]                     = "hr",
    ["Czech"]                        = "cs",
    ["Danish"]                       = "da",
    ["Dutch"]                        = "nl",
    ["English"]                      = "en_GB",
    ["English (Great Britain)"]      = "en_GB",
    ["English (USA)"]                = "en_US",
    ["Esperanto"]                    = "eo",
    ["Estonian"]                     = "et",
    ["Finnish"]                      = "fi",
    ["French"]                       = "fr",
    ["Galician"]                     = "gl",
    ["German"]                       = "de",
    ["Greek"]                        = "el",
    ["Gujarati"]                     = "gu",
    ["Hindi"]                        = "hi",
    ["Hungarian"]                    = "hu",
    ["Icelandic"]                    = "is",
    ["Irish"]                        = "ga",
    ["Italian"]                      = "it",
    ["Kannada"]                      = "kn",
    ["Kurmanji"]                     = "ku",
    ["Latvian"]                      = "lv",
    ["Lithuanian"]                   = "lt",
    ["Malayalam"]                    = "ml",
    ["Norwegian Bokmål"]             = "nb",
    ["Norwegian Nynorsk"]            = "nn",
    ["Other"]                        = "--",
    ["Polish"]                       = "pl",
    ["Portuguese"]                   = "pt",
    ["Romanian"]                     = "ro",
    ["Russian"]                      = "ru",
    ["Sanskrit"]                     = "sa",
    ["Serbian"]                      = "sr",
    ["Serbian (cyrillic)"]           = "sc",
    ["Slovak"]                       = "sk",
    ["Slovenian"]                    = "sl",
    ["Spanish"]                      = "es",
    ["Swedish"]                      = "sv",
    ["Turkish"]                      = "tr",
    ["Ukrainian"]                    = "uk",
    ["Welsh"]                        = "cy",
}


---@type table<string, string>
local language_filename = {
    ["bg"]    = "bg",
    ["ca"]    = "ca",
    ["cs"]    = "cs",
    ["cy"]    = "cy",
    ["da"]    = "da",
    ["de"]    = "de-1996",
    ["el"]    = "el-monoton",
    ["en"]    = "en-gb",
    ["en_gb"] = "en-gb",
    ["en_us"] = "en-us",
    ["eo"]    = "eo",
    ["es"]    = "es",
    ["et"]    = "et",
    ["eu"]    = "eu",
    ["fi"]    = "fi",
    ["fr"]    = "fr",
    ["ga"]    = "ga",
    ["gl"]    = "gl",
    ["grc"]   = "grc",
    ["gu"]    = "gu",
    ["hi"]    = "hi",
    ["hr"]    = "hr",
    ["hu"]    = "hu",
    ["hy"]    = "hy",
    ["id"]    = "id",
    ["is"]    = "is",
    ["it"]    = "it",
    ["ku"]    = "kmr",
    ["kn"]    = "kn",
    ["lt"]    = "lt",
    ["ml"]    = "ml",
    ["lv"]    = "lv",
    ["nb"]    = "nb",
    ["nl"]    = "nl",
    ["nn"]    = "nn",
    ["no"]    = "nb",
    ["pl"]    = "pl",
    ["pt"]    = "pt",
    ["ro"]    = "ro",
    ["ru"]    = "ru",
    ["sa"]    = "sa",
    ["sk"]    = "sk",
    ["sl"]    = "sl",
    ["sr"]    = "sr",
    ["sc"]    = "sr-cyrl",
    ["sv"]    = "sv",
    ["tr"]    = "tr",
    ["uk"]    = "uk",
    ["zh"]    = "",
    ["--"]    = "",
}

-- Resolves a language reference to a LanguageEntry, loading hyphenation
-- patterns on first use and caching the result in `publisher.languages` and
-- `publisher.languages_id_lang`. Numeric input is treated as an existing id.
---@param id_or_locale_or_name integer|string LuaTeX language id, locale (`"de"`, `"en_GB"`, ...) or name (`"German"`).
---@return LanguageEntry|integer entry Cached entry, or `0` when no patterns can be loaded.
function M.get_language(id_or_locale_or_name)
    local orig_id_or_locale_or_name = id_or_locale_or_name
    local num = tonumber(id_or_locale_or_name)
    if num then
        return publisher.languages_id_lang[num]
    end
    local locale = string.lower(id_or_locale_or_name)

    if language_mapping[id_or_locale_or_name] then
        locale = language_mapping[id_or_locale_or_name]
    end
    locale = string.lower(locale)
    if publisher.languages[locale] then
        return publisher.languages[locale]
    end

    local filename_part
    if language_filename[locale] then
        filename_part = language_filename[locale]
    else
        local sep = "_"
        if string.match( locale ,"%-" ) then
            sep = "-"
        end
        local langcode, _ = table.unpack(string.explode(locale,sep))
        if language_filename[langcode] then
            filename_part = language_filename[langcode]
        end
    end

    local l = lang.new()

    if filename_part == "" then
        -- ignore this; probably cjk or another language without hyphenation patterns
    elseif not filename_part then
        main.log("warn", string.format("Can't find hyphenation patterns for language %s", tostring(orig_id_or_locale_or_name)))
        return 0
    else
        local filename = string.format("hyph-%s.pat.txt",filename_part)
        main.log("debug","Loading hyphenation pattern","filename",filename)
        local path = kpse.find_file(filename)
        local pattern_file = io.open(path)
        local pattern = pattern_file:read("*all")
        pattern_file:close()
        l:patterns(pattern)
    end

    local id = l:id()
    main.log("debug","Language ID","id",id)
    local ret = { id = id, l = l, locale = locale }
    publisher.languages_id_lang[id] = ret
    publisher.languages[locale] = ret
    return ret
end

-- Returns the LuaTeX language id for a locale or language name. Returns `0`
-- if the language cannot be resolved.
---@param locale_or_name integer|string
---@return integer id
function M.get_languagecode( locale_or_name )
    local tmp = M.get_language(locale_or_name)
    if type(tmp) ~= "table" then
        return 0
    end
    return tmp.id
end

-- Sets `publisher.defaultlanguage` to the id resolved from `mainlanguage`.
---@param mainlanguage integer|string
---@return nil
function M.set_mainlanguage( mainlanguage )
    main.log("info","Setting default language","lang",mainlanguage or "?")
    publisher.defaultlanguage = M.get_languagecode(mainlanguage)
end

-- Returns the unique LuaTeX language ids used by glyph nodes in `nodelist`.
-- Called before `do_linebreak()` so the pre-hyphen char can be swapped.
---@param nodelist node Head of the node list to scan.
---@return integer[] ids
function M.get_languages_used( nodelist )
    local langs = {}
    for n in node.traverse_id(publisher.glyph_node, nodelist) do
        langs[n.lang] = true
    end
    local ret = {}
    for k,_ in pairs(langs) do
        ret[#ret + 1] = k
    end
    return ret
end

file_end("language.lua")

return M
