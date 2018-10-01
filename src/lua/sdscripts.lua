--
--  sdscripts.lua
--  speedata publisher
--
--  Copyright 2010-2013 Patrick Gundlach.
--  See file COPYING in the root directory for license info.
--

splib        = require("splib")

dofile(arg[1])

function get_ps_name( filename )
  local info = fontloader.info(filename)
  return info.fontname
end

local cmd = arg[2]

local fontlist = {}


local shortname
for _,v in pairs(splib.listfonts()) do
    _,shortname,_ = string.match(v, "(.-)([^\\/]-%.?([^%.\\/]*))$")
    fontlist[shortname] = v
end

if cmd=="list-fonts" then
  local is_xml = arg[3]=="xml"
  texio.write_nl("\n")
  if is_xml then

  else
    texio.write_nl(string.format("%-40s %s","Filename","PostScript Name"))
    texio.write_nl(string.format("%-40s %s","-----------------------------------","---------------"))
  end
  local l
  local filenames_sorted = {}
  for filename,_ in pairs(fontlist) do
    l = filename:lower()
    if l:match("%.pfb$") or l:match("%.ttf$") or l:match("%.otf") then
      filenames_sorted[#filenames_sorted + 1] = filename
    end
  end
  table.sort(filenames_sorted)
  local psname
  for i,v in ipairs(filenames_sorted) do
    psname = get_ps_name(fontlist[v])
    if is_xml then
      print(string.format('<LoadFontfile name="%s" filename="%s" />',psname,v))
    else
      texio.write_nl(string.format("%-40s %s",v,psname))
    end
  end
  texio.write_nl("")
end