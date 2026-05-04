--
--  links.lua
--  speedata publisher
--
--  Hyperlink helpers.
--

file_start("publisher/links.lua")

local colors = require("publisher.colors")
local metadata = require("publisher.metadata")

---@class links_module
local M = {}

---@type (string|table)[]
local hyperlinks = {}

-- Resets the internal hyperlink storage.
---@return nil
function M.reset()
    hyperlinks = {}
end

-- Returns the current hyperlink table for read-only access.
---@return (string|table)[]
function M.get_all()
    return hyperlinks
end

-- Returns the hyperlink entry at the given 1-based index, or `nil`.
---@param index integer
---@return string|table|nil
function M.get(index)
    return hyperlinks[index]
end

-- Returns the most recently added hyperlink entry.
---@return string|table|nil
function M.last()
    return hyperlinks[#hyperlinks]
end

-- Returns the number of stored hyperlinks.
---@return integer
function M.count()
    return #hyperlinks
end

-- Patches an existing hyperlink entry with the given fields.
-- A no-op if the entry is missing or not a table.
---@param index integer
---@param fields table<string, any>
---@return nil
function M.set_fields(index, fields)
    local entry = hyperlinks[index]
    if type(entry) ~= "table" then
        return
    end
    for key, value in pairs(fields) do
        entry[key] = value
    end
end

-- Converts a color name to a `"r g b"` string for use in a PDF `/C` array.
-- Falls back to black on missing/unknown colors. PDF viewers only accept RGB
-- in `/C`, so cmyk and gray entries are converted accordingly.
---@param colorname string?
---@return string rgb Three values in [0,1] separated by spaces.
local function getBordercolor(colorname)
    local entry = colors.get_colentry_from_name(colorname, "black")
    if entry == nil then
        return "0 0 0"
    end
    if entry.model == "rgb" then
        return string.format("%g %g %g", entry.r, entry.g, entry.b)
    elseif entry.model == "gray" then
        return string.format("%g %g %g", entry.g, entry.g, entry.g)
    elseif entry.model == "cmyk" then
        local hundredminusk = (100 - entry.k) / 100
        local r = (100 - entry.c) * hundredminusk / 100
        local g = (100 - entry.m) * hundredminusk / 100
        local b = (100 - entry.y) * hundredminusk / 100
        return string.format("%g %g %g", r, g, b)
    end
    return "0 0 0"
end

-- URL-escapes a single character as `%XX`.
---@param c string Single byte.
---@return string
local function char_to_hex(c)
    return string.format("%%%02X", string.byte(c))
end

-- URL-encodes a string. Spaces become `+`, non-URL-safe bytes become `%XX`.
---@param url string?
---@return string? encoded `nil` if `url` was `nil`.
local function urlencode(url)
    if url == nil then
        return
    end
    url = url:gsub("\n", "\r\n")
    url = url:gsub("([^%w _%-%.~:/%%=%?&#])", char_to_hex)
    url = url:gsub(" ", "+")
    return url
end

-- Builds the `/Border` (and optional `/C`) PDF fragment for a hyperlink.
---@param options table Publisher options table.
---@param color string? Border color; falls back to `options.hyperlinkbordercolor`.
---@return string fragment
local function get_border_for_link(options, color)
    -- no border:
    local border = "/Border[0 0 0]"
    local border_thickness = options.hyperlinkborderwidth
    if options.showhyperlinks then
        local thickness = ""
        if border_thickness ~= 0 then
            thickness = string.format("/Border[0 0 %d]", sp_to_bp(border_thickness))
        end
        border = string.format("%s/C [%s]", thickness, getBordercolor(color or options.hyperlinkbordercolor))
    end
    return border
end

-- Same as `get_border_for_link`, but returns the fields as a table for callers
-- that build the link entry as a key/value table (e.g. `hlurl`, `hllink`).
---@param options table Publisher options table.
---@param color string?
---@return table<string, string> fields Maps PDF keys (`"/Border"`, `"/C"`) to their string values.
local function get_border_for_link_table(options, color)
    -- no border:
    local border = { ["/Border"] = "[0 0 0]" }
    local border_thickness = options.hyperlinkborderwidth
    if options.showhyperlinks then
        if border_thickness ~= 0 then
            border["/Border"] = string.format("[0 0 %d]", sp_to_bp(border_thickness))
        end
        border["/C"] = string.format("[%s]", getBordercolor(color or options.hyperlinkbordercolor))
    end
    return border
end

-- Prepares the filename + destination for a `GoToE` (embedded-file) link.
-- `page` (if given) wins over `link`; if neither is provided the link points
-- to page 0 with `/Fit`.
---@param filename string Embedded file name.
---@param page integer? 1-based page number.
---@param link string? Named destination.
---@return { fn: string, dest: string } target `fn` is a PDF UTF-16 string, `dest` is either a page array or a named destination.
local function parse_embed_filename(filename, page, link)
    local parsed_url = { fn = metadata.utf8_to_utf16_string_pdf(filename) }
    if page then
        parsed_url.dest = string.format("[%s /Fit]", tonumber(page) - 1)
    elseif link then
        parsed_url.dest = metadata.utf8_to_utf16_string_pdf(link)
    else
        parsed_url.dest = "[0 /Fit]"
    end
    return parsed_url
end

-- Returns the keys of `tab` as a sorted array.
---@param tab table
---@return any[] keys
local function sortedkeys(tab)
    local keys, s = {}, 0
    for key, _ in next, tab do
        s = s + 1
        keys[s] = key
    end
    table.sort(keys)
    return keys
end

-- get the key and values always in the same order to get reproducable PDFs
local marshal_ordered = {
    __tostring = function(tbl)
        local ret = {}
        for _, key in ipairs(sortedkeys(tbl)) do
            ret[#ret + 1] = key .. tbl[key]
        end
        return table.concat(ret, "")
    end,
}

-- hyperlinks/hyperlinksbuilder

-- Registers a link that opens an embedded file via `GoToE`.
---@param options table Publisher options.
---@param filename string Embedded file name.
---@param page integer? 1-based destination page.
---@param link string? Named destination (used when `page` is `nil`).
---@param bordercolor string?
---@return integer index Index into the internal hyperlinks list.
function M.hlembed(options, filename, page, link, bordercolor)
    local parsed_url = parse_embed_filename(filename, page, link)
    local str = string.format(
        "/Subtype/Link%s/A<</Type/Action/S/GoToE/NewWindow true/D %s /T<</R/C/N%s >> >>",
        get_border_for_link(options, bordercolor),
        parsed_url.dest,
        parsed_url.fn
    )
    hyperlinks[#hyperlinks + 1] = str
    return #hyperlinks
end

-- Registers an external URI link.
---@param options table Publisher options.
---@param href string Target URL.
---@param bordercolor string?
---@return integer index Index into the internal hyperlinks list.
function M.hlurl(options, href, bordercolor)
    href = urlencode(href)
    href = metadata.escape_pdfstring(href)
    local hl = {
        ["/Subtype"] = "/Link",
        ["/A"] = string.format("<</Type/Action/S/URI/URI(%s)>>", href),
    }
    for key, value in pairs(get_border_for_link_table(options, bordercolor)) do
        hl[key] = value
    end
    local tab = setmetatable(hl, marshal_ordered)
    -- hyperlinks must be a table, PDF/UA adds entries to the table
    hyperlinks[#hyperlinks + 1] = tab
    return #hyperlinks
end

-- Registers a link that jumps to a specific page in the same document.
-- Returns `0` if the page reference cannot be resolved.
---@param options table Publisher options.
---@param pagenumber integer|string 1-based page number.
---@param bordercolor string?
---@return integer index Index into the internal hyperlinks list, or `0` on failure.
function M.hlpage(options, pagenumber, bordercolor)
    pagenumber = tonumber(pagenumber)
    local pageobjnum = pdf.getpageref(pagenumber)
    if pageobjnum == nil then
        return 0
    end
    local str = string.format(
        "/Subtype/Link%s/A<</Type/Action/S/GoTo/D [ %d 0 R /Fit ] >>",
        get_border_for_link(options, bordercolor),
        pageobjnum
    )
    hyperlinks[#hyperlinks + 1] = str
    return #hyperlinks
end

-- Registers a link that jumps to a named destination (`mark<name>`) within
-- the same document.
---@param options table Publisher options.
---@param link string Destination name (without the `mark` prefix).
---@param bordercolor string?
---@return integer index Index into the internal hyperlinks list.
function M.hllink(options, link, bordercolor)
    local formatted = string.format("mark%s", link)
    local hl = {
        ["/Subtype"] = "/Link",
        ["/A"] = string.format("<</Type/Action/S/GoTo/D %s>>", metadata.utf8_to_utf16_string_pdf(formatted)),
    }
    for key, value in pairs(get_border_for_link_table(options, bordercolor)) do
        hl[key] = value
    end

    hyperlinks[#hyperlinks + 1] = setmetatable(hl, marshal_ordered)
    return #hyperlinks
end

file_end("publisher/links.lua")

return M
