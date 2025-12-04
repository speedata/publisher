--
--  links.lua
--  speedata publisher
--
--  Hyperlink helpers extracted from publisher.lua.
--

file_start("publisher/links.lua")

local colors = require("publisher.colors")
local metadata = require("publisher.metadata")

local M = {}
local hyperlinks = {}

--- Reset hyperlink storage.
function M.reset()
    hyperlinks = {}
end

--- Return the current hyperlink table (read-only use).
-- @return table
function M.get_all()
    return hyperlinks
end

--- Get a hyperlink entry by index.
-- @param index number
-- @return any
function M.get(index)
    return hyperlinks[index]
end

--- Get the most recently added hyperlink entry.
-- @return any
function M.last()
    return hyperlinks[#hyperlinks]
end

--- Get the number of stored hyperlinks.
-- @return number
function M.count()
    return #hyperlinks
end

--- Set fields on a hyperlink entry (no-op if index is invalid).
-- @param index number
-- @param fields table
function M.set_fields(index, fields)
    local entry = hyperlinks[index]
    if type(entry) ~= "table" then
        return
    end
    for key, value in pairs(fields) do
        entry[key] = value
    end
end

-- getBordercolor turns a color into a three RGB (0-1) value to be used for the /C array.
-- The PDF viewers only support RGB (three values in the /C array).
--- Convert a color name to an RGB string usable in PDF /C arrays.
-- @param colorname string|nil
-- @return string "r g b" values in [0,1]
local function getBordercolor(colorname)
    local entry = colors.get_colentry_from_name(colorname,"black")
    if entry == nil then
        return "0 0 0"
    end
    if entry.model == "rgb" then
        return string.format("%g %g %g",entry.r,entry.g,entry.b)
    elseif entry.model == "gray" then
        return string.format("%g %g %g",entry.g,entry.g,entry.g)
    elseif entry.model == "cmyk" then
        local hundredminusk = ( 100 - entry.k) / 100
        local r = (100 - entry.c) * hundredminusk / 100
        local g = (100 - entry.m) * hundredminusk / 100
        local b = (100 - entry.y) * hundredminusk / 100
        return string.format("%g %g %g",r,g,b)
    end
    return "0 0 0"
end

--- URL-encode a single character.
-- @param c string
-- @return string encoded
local function char_to_hex(c)
    return string.format("%%%02X", string.byte(c))
end

--- URL-encode a string (spaces -> +, escapes non-URL-safe chars).
-- @param url string|nil
-- @return string|nil encoded url or nil if input is nil
local function urlencode(url)
    if url == nil then
        return
    end
    url = url:gsub("\n", "\r\n")
    url = url:gsub("([^%w _%-%.~:/%%=%?&#])", char_to_hex)
    url = url:gsub(" ", "+")
    return url
end

--- Build PDF border string for a hyperlink.
-- @param options table publisher options
-- @param color string|nil border color name
-- @return string PDF border fragment
local function get_border_for_link(options, color)
    -- no border:
    local border = "/Border[0 0 0]"
    local border_thickness = options.hyperlinkborderwidth
    if options.showhyperlinks then
        local thickness = ""
        if border_thickness ~= 0 then
            thickness = string.format("/Border[0 0 %d]",sp_to_bp(border_thickness))
        end
        border = string.format("%s/C [%s]",thickness,getBordercolor(color or options.hyperlinkbordercolor))
    end
    return border
end

--- Build PDF border hash for hyperlink table variant.
-- @param options table publisher options
-- @param color string|nil border color name
-- @return table PDF border key/values
local function get_border_for_link_table(options, color)
    -- no border:
    local border = {["/Border"] = "[0 0 0]" }
    local border_thickness = options.hyperlinkborderwidth
    if options.showhyperlinks then
        if border_thickness ~= 0 then
            border["/Border"] = string.format("[0 0 %d]",sp_to_bp(border_thickness))
        end
        border["/C"] = string.format("[%s]",getBordercolor(color or options.hyperlinkbordercolor))
    end
    return border
end

--- Prepare parsed embed filename/target for GoToE link.
-- @param filename string
-- @param page number|nil destination page
-- @param link string|nil named destination
-- @return table parsed embed target
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

--- Get sorted keys of a table.
-- @param tab table
-- @return table array of sorted keys
local function sortedkeys(tab)
    local keys, s = { }, 0
    for key,_ in next, tab do
        s = s + 1
        keys[s] = key
    end
    table.sort(keys)
    return keys
end

-- get the key and values always in the same order to get reproducable PDFs
local marshal_ordered = {__tostring = function(tbl)
    local ret = {}
    for _, key in ipairs(sortedkeys(tbl)) do
        ret[#ret+1] = key .. tbl[key]
    end
    return table.concat(ret, "")
 end
}

-- hyperlinks/hyperlinksbuilder

--- Add an embedded-file link.
-- @param options table publisher options
-- @param filename string file name
-- @param page number|nil page number
-- @param link string|nil named destination
-- @param bordercolor string|nil border color
-- @return number index in hyperlinks
function M.hlembed(options, filename, page, link, bordercolor)
    local parsed_url = parse_embed_filename(filename, page, link)
    local str = string.format("/Subtype/Link%s/A<</Type/Action/S/GoToE/NewWindow true/D %s /T<</R/C/N%s >> >>", get_border_for_link(options, bordercolor), parsed_url.dest, parsed_url.fn)
    hyperlinks[#hyperlinks + 1] = str
    return #hyperlinks
end

--- Add a URI link.
-- @param options table publisher options
-- @param href string URL
-- @param bordercolor string|nil border color
-- @return number index in hyperlinks
function M.hlurl(options, href,bordercolor)
    href = urlencode(href)
    href = metadata.escape_pdfstring(href)
    local hl = {
        ["/Subtype" ] = "/Link",
        ["/A"] = string.format("<</Type/Action/S/URI/URI(%s)>>",href),
    }
    for key, value in pairs(get_border_for_link_table(options, bordercolor)) do
        hl[key] = value
    end
    local tab = setmetatable(hl,marshal_ordered)
    -- hyperlinks must be a table, PDF/UA adds entries to the table
    hyperlinks[#hyperlinks+1] = tab
    return #hyperlinks
end

--- Add a page link.
-- @param options table publisher options
-- @param pagenumber number page number
-- @param bordercolor string|nil border color
-- @return number index in hyperlinks
function M.hlpage(options, pagenumber,bordercolor)
    pagenumber = tonumber(pagenumber)
    local pageobjnum = pdf.getpageref(pagenumber)
    if pageobjnum == nil then
        return 0
    end
    local str = string.format("/Subtype/Link%s/A<</Type/Action/S/GoTo/D [ %d 0 R /Fit ] >>",get_border_for_link(options, bordercolor),pageobjnum)
    hyperlinks[#hyperlinks + 1] = str
    return #hyperlinks
end

--- Add a named destination link.
-- @param options table publisher options
-- @param link string destination name
-- @param bordercolor string|nil border color
-- @return number index in hyperlinks
function M.hllink(options, link,bordercolor)
    local formatted = string.format("mark%s",link)
    local hl = {
        ["/Subtype"] = "/Link",
        ["/A"] = string.format("<</Type/Action/S/GoTo/D %s>>",metadata.utf8_to_utf16_string_pdf(formatted))
    }
    for key, value in pairs(get_border_for_link_table(options, bordercolor)) do
        hl[key] = value
    end

    hyperlinks[#hyperlinks + 1] = setmetatable(hl,marshal_ordered)
    return #hyperlinks
end

file_end("publisher/links.lua")

return M
