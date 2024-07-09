--
--  sdscripts.lua
--  speedata publisher
--
--  Copyright 2010-2024 Patrick Gundlach.
--  See file COPYING in the root directory for license info.
--


local libname
if os.name == "windows" then
  libname = "libsplib.dll"
elseif os.name == "linux" then
  libname = "libsplib.so"
elseif os.name == "freebsd" then
  libname = "libsplib.so"
else
  libname = "libsplib.so"
end

local ok, msg = package.loadlib(libname,"*")
if not ok then
   print(msg)
   os.exit(0)
end

local splib = require("luaglue")

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