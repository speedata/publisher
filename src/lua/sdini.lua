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
else
  libname = "libsplib.dylib"
end

local ok, msg = package.loadlib(libname,"*")
if not ok then
   print(msg)
   os.exit(0)
end

local luaglue = require("luaglue")

texio.write("Loading file sdini.lua ...")
callback.register('start_run',function() return true end)


texconfig.kpse_init=false
texconfig.max_print_line=99999
texconfig.formatname="sd-format"
texconfig.trace_file_names = false

luaglue.buildfilelist()
kpse = {}


function file_start( filename )
  if log then
    log("Load file: %q ...",filename)
  end
end
function file_end( filename )
  if log then
    log("Load file: %q ... done",filename)
  end
end

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

texio.write(" done\n")
