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

local function reader( asked_name )
    return {
        file   = io.open(asked_name,"rb"),
        reader = function (t) local f = t.file return f:read('*l')  end,
        close  = function (t) t.file:close() end
    }
end


local function find_generic_file( asked_name )
    local file = kpse.find_file(asked_name)
    return file
end

local function return_asked_name( asked_name )
    return asked_name
end

local function read_font_file( name )
    local f = io.open(name,"rb")
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
  callback.register(t,find_generic_file)
end
for _,t in ipairs({'read_vf_file','read_sdf_file','read_pk_file','read_data_file','read_font_file','read_map_file'}) do
  callback.register(t, read_xxx_file )
end


function print_page_number()
  texio.write(string.format("> Shipout page %d\n",publisher.current_pagenumber))
end
callback.register("start_page_number",print_page_number)
callback.register("stop_page_number",false)
