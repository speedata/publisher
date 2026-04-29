--- Language and locale handling.
--
--  language.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("language.lua")

local M = {}

function M.get_language(id_or_locale_or_name)
    local orig_id_or_locale_or_name = id_or_locale_or_name
    local num = tonumber(id_or_locale_or_name)
    if num then
        return publisher.languages_id_lang[num]
    end
    local locale = string.lower(id_or_locale_or_name)

    if publisher.language_mapping[id_or_locale_or_name] then
        locale = publisher.language_mapping[id_or_locale_or_name]
    end
    locale = string.lower(locale)
    if publisher.languages[locale] then
        return publisher.languages[locale]
    end

    local filename_part
    if publisher.language_filename[locale] then
        filename_part = publisher.language_filename[locale]
    else
        local sep = "_"
        if string.match( locale ,"%-" ) then
            sep = "-"
        end
        local langcode, _ = table.unpack(string.explode(locale,sep))
        if publisher.language_filename[langcode] then
            filename_part = publisher.language_filename[langcode]
        end
    end

    local l = lang.new()

    if filename_part == "" then
        -- ignore this; probably cjk or another language without hyphenation patterns
    elseif not filename_part then
        warning("Can't find hyphenation patterns for language %s",tostring(orig_id_or_locale_or_name))
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

--- The language name is something like `German` or a locale.
function M.get_languagecode( locale_or_name )
    local tmp = M.get_language(locale_or_name)
    if type(tmp) ~= "table" then
        return 0
    end
    return tmp.id
end

function M.set_mainlanguage( mainlanguage )
    main.log("info","Setting default language","lang",mainlanguage or "?")
    publisher.defaultlanguage = M.get_languagecode(mainlanguage)
end

--- Return the language numbers used in this nodelist.
--- Used before `do_linebreak()` to change pre-hyphenchar temporarily.
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
