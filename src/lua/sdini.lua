--
--  sdini.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.
--

-- BUG on windows: http://lua-users.org/lists/lua-l/2012-08/msg00052.html
-- ! in LUA_PATH gets replaced by $PWD
package.path=os.getenv("LUA_PATH")

local libname
if os.name == "windows" then
  libname = "libsplib.dll"
elseif os.name == "linux" then
  libname = "libsplib.so"
elseif os.name == "freebsd" then
  libname = "libsplib.so"
else
  libname = "libsplib.dylib"
end

local ok, msg = package.loadlib(libname,"*")
if not ok then
   print(msg)
   os.exit(0)
end
local luaglue = require("luaglue")

function file_start( filename )
  luaglue.log("debug","Start file","filename",filename)
end
function file_end( filename )
luaglue.log("debug","End file","filename",filename)
end


file_start("sdini.lua")
callback.register('start_run',function() return true end)


texconfig.kpse_init=false
texconfig.max_print_line=99999
texconfig.formatname="sd-format"
texconfig.trace_file_names = false

luaglue.buildfilelist()
kpse = {}



--- @param filename string The file name to look up
--- @return string|nil The full path of the file name or nil if the file is not found.
function kpse.find_file(filename)
  local ret = luaglue.lookupfile(filename)
  if ret == "" then return nil end
  return ret
end

function kpse.add_dir(dirname)
    return luaglue.add_dir(dirname)
end

function do_luafile(filename)
  local a = kpse.find_file(filename)
  assert(a,string.format("Can't find file %q",filename))
  return dofile(a)
end

do_luafile("sd-debug.lua")
do_luafile("sd-callbacks.lua")

file_end("sdini.lua")
