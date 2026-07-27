--
--  sdscripts.lua
--  speedata publisher
--
--  Copyright 2010-2024 Patrick Gundlach.
--  See file COPYING in the root directory for license info.
--

-- libs are already loaded in sdini.lua
dofile(arg[1])

-- Returns the PostScript name for the given font file via `fontloader.info`.
---@param filename string Resolved font file path.
---@return string
function get_ps_name(filename)
    local info = assert(fontloader.info(filename), "cannot read font file " .. filename)
    return info.fontname
end

local cmd = arg[2]

local fontlist = {}
local shortname
for _, v in pairs(splib.listfonts()) do
    _, shortname, _ = string.match(v, "(.-)([^\\/]-%.?([^%.\\/]*))$")
    fontlist[shortname] = v
end

if cmd == "list-fonts" then
    local is_xml = arg[3] == "xml"
    texio.write_nl("\n")
    if is_xml then
    else
        texio.write_nl(string.format("%-40s %s", "Filename", "PostScript Name"))
        texio.write_nl(string.format("%-40s %s", "-----------------------------------", "---------------"))
    end
    local l
    local filenames_sorted = {}
    for filename, _ in pairs(fontlist) do
        l = filename:lower()
        if l:match("%.pfb$") or l:match("%.ttf$") or l:match("%.otf") then
            filenames_sorted[#filenames_sorted + 1] = filename
        end
    end
    table.sort(filenames_sorted)
    local psname
    for _, v in ipairs(filenames_sorted) do
        psname = get_ps_name(fontlist[v])
        if is_xml then
            print(string.format('<LoadFontfile name="%s" filename="%s" />', psname, v))
        else
            texio.write_nl(string.format("%-40s %s", v, psname))
        end
    end
    texio.write_nl("")
end
