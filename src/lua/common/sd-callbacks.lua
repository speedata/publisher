--
--  sd-callbacks.lua
--  speedata publisher
--
--  Copyright 2010-2011 Patrick Gundlach.
--  See file COPYING in the root directory for license info.


-- necessary callbacks if we want to use LuaTeX without kpathsea

local verbosity = os.getenv("SP_VERBOSITY")
local url = require("socket_url")

local function reader( asked_name )
  local tab = { }
  tab.file = io.open(asked_name)
  tab.reader = function (t)
                  local f = t.file
                  return f:read('*l')
               end
  tab.close = function (t)
                  t.file:close()
              end
  return tab
end

local rewrite_tbl = {}
if os.getenv("SP_PATH_REWRITE") ~= "" then
    for _,v in ipairs(string.explode(os.getenv("SP_PATH_REWRITE"),",")) do
        a,b = unpack(string.explode(v,"="))
        rewrite_tbl[a]=b
    end
end


function find_file_location( filename_or_uri )
  if filename_or_uri == "" then return nil end
  local p = kpse.filelist[filename_or_uri]
  if p then return p end
  if filename_or_uri == "pdftex.map" then return nil end
  -- not in the search path or its subdirectories
  local url_table = url.parse(filename_or_uri)
  -- If we didn't find a file:// or something similar,
  -- we don't try to find the file.
  if not ( url_table or url_table.scheme ) then
    return nil
  end

  if url_table.scheme ~= "file" then
    err("Locating file -- scheme %q not supported. Requested file: %q",url_table.scheme or "(unable to parse scheme)",filename_or_uri or "(none)")
    return nil
  end
  local decoded_path = url.unescape(url_table.path)

  local path = decoded_path
  for k,v in pairs(rewrite_tbl) do
      path = string.gsub(path,k,v)
  end
  -- remove first slash if on windows (/c:/foo/bar.png -> c:/foo/bar.png)
  if path ~= decoded_path then
    if verbosity and tonumber(verbosity) > 0 then
      log("Path rewrite: %q -> %q", decoded_path,path)
    end
  end

  local _,_, windows_path = string.find(path,"^/(.:.*)$")
  if windows_path then
    path = windows_path
  end
  x = lfs.attributes(path)
  if not lfs.attributes(path) then
    return nil
  end
  return path
end

local function find_xxx_file( asked_name )
  local file = find_file_location(asked_name)
  return file
end
local function return_asked_name( asked_name )
  return asked_name
end
local function read_font_file( name )
  local f = io.open(name)
  local buf = f:read("*all")
  f:close()
  return true,buf,buf:len()
end
local function find_read_file( id_number,asked_name )
  local file = kpse.find_file(asked_name)
  return file
end
function find_write_file(id_number,asked_name)
  return asked_name
end
local function read_xxx_file(name)
  return nil,nil,0
end

callback.register('open_read_file',reader)

callback.register('find_opentype_file',return_asked_name)
callback.register('find_type1_file',   return_asked_name)
callback.register('find_output_file',  return_asked_name)

callback.register('read_opentype_file',read_font_file)
callback.register('read_type1_file',   read_font_file)

callback.register('find_write_file',find_write_file)

callback.register('find_read_file',find_read_file)

for _,t in ipairs({"find_font_file",'find_vf_file','find_format_file','find_map_file','find_enc_file','find_sfd_file','find_pk_file','find_data_file','find_image_file','find_truetype_file'}) do
  callback.register(t,find_xxx_file)
end
for _,t in ipairs({'read_vf_file','read_sdf_file','read_pk_file','read_data_file','read_font_file','read_map_file'}) do
  callback.register(t, read_xxx_file )
end


function print_page_number()
  texio.write_nl(string.format("> Shipout page %d",publisher.current_pagenumber))
end
callback.register("start_page_number",print_page_number)
callback.register("stop_page_number",false)
