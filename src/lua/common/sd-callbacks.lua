--- This is the location for file related callbacks.
-- TeX uses the kpathsea library, which I disable right away (`texconfig.kpse_init=false` in sdini.lua).
-- We still use the namespace kpse.
--
--  sd-callbacks.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.


-- necessary callbacks if we want to use LuaTeX without kpathsea


local trace_callbacks = false

-- Lua 5.2 has table.unpack
unpack = unpack or table.unpack


local function reader( asked_name )
    if trace_callbacks then
        w("reader, asked_name = %q",tostring(asked_name))
    end
    return {
        file   = io.open(asked_name,"rb"),
        reader = function (t) local f = t.file return f:read('*l')  end,
        close  = function (t) t.file:close() end
    }
end

local rewrite_tbl = {}
if os.getenv("SP_PATH_REWRITE") ~= nil then
    for _,v in ipairs(string.explode(os.getenv("SP_PATH_REWRITE"),",")) do
        a,b = unpack(string.explode(v,"="))
        local str = string.gsub(a,"%-","%%-")
        str = string.gsub(str,"%(","%%(")
        str = string.gsub(str,"%)","%%)")
        rewrite_tbl[str]=b
    end
end

local function find_xxx_file( asked_name )
    if trace_callbacks then
        w("find_xxx_file, asked_name = %q",tostring(asked_name))
    end

    local file = kpse.find_file(asked_name)
    return file
end

local function return_asked_name( asked_name )
    if trace_callbacks then
        w("return_asked_name, asked_name = %q",tostring(asked_name))
    end
  return asked_name
end

local function read_font_file( name )
    if trace_callbacks then
        w("read_font_file, name = %q",tostring(name))
    end
  local f = io.open(name,"rb")
  local buf = f:read("*all")
  f:close()
  return true,buf,buf:len()
end
local function find_read_file( id_number,asked_name )
    if trace_callbacks then
        w("find_read_file, id_number %q asked_name = %q",tostring(id_number), tostring(asked_name))
    end
  local file = kpse.find_file(asked_name)
  return file
end
function find_write_file(id_number,asked_name)
    if trace_callbacks then
        w("find_write_file, id_number %q asked_name = %q",tostring(id_number), tostring(asked_name))
    end
  return asked_name
end
local function read_xxx_file(name)
    if trace_callbacks then
        w("read_xxx_file, name = %q",tostring(name))
    end
  return true,"",0
end

callback.register("page_order_index",function(pagenum)
    local ppt = publisher.pagenum_tbl
    return ppt[pagenum]
end)

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
  texio.write(string.format("> Shipout page %d\n",publisher.current_pagenumber))
end
callback.register("start_page_number",print_page_number)
callback.register("stop_page_number",false)
