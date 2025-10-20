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
local lib_to_use = os.getenv("SP_LIB")
local jobname = os.getenv("JOBNAME") or "publisher"
rlib = nil
splib = nil

if lib_to_use == "rust" then
    rlib = require("rlib")
    rlib.log.init{
      path    = jobname .. "-protocol.xml",
      level   = os.getenv("SD_LOGLEVEL") or "info",
      verbose = ( os.getenv("SP_VERBOSITY") == "1" ),
    }
else
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
    -- the library was formally named splib. luaglue is a layer (see #570).
    splib = require("luaglue")

end


function file_start( filename )
    if rlib then
        rlib.log.log("debug","Start file","filename",filename)
    else
        splib.log("debug","Start file","filename",filename)
    end
end

function file_end( filename )
    if rlib then
        rlib.log.log("debug","End file","filename",filename)
    else
        splib.log("debug","End file","filename",filename)
    end
end


file_start("sdini.lua")
callback.register('start_run',function() return true end)

main = {}

function main.log(...)
    if rlib then
        rlib.log.log(...)
    else
        splib.log(...)
    end
end


texconfig.kpse_init=false
texconfig.max_print_line=99999
texconfig.formatname="sd-format"
texconfig.trace_file_names = false

if rlib then
    rlib.aux.sdBuildFilelist()
else
    splib.buildfilelist()
end
kpse = {}

--- @param filename string The file name to look up
--- @return string|nil The full path of the file name or nil if the file is not found.
function kpse.find_file(filename)
  if rlib then
      return rlib.aux.lookup_file(filename)
  end
  return splib.lookupfile(filename)
end

function kpse.add_dir(dirname)
    if rlib then
        return rlib.aux.add_dir(dirname)
    end
    return splib.add_dir(dirname)
end

function do_luafile(filename)
  local a = kpse.find_file(filename)
  assert(a,string.format("Can't find file %q",filename))
  return dofile(a)
end

do_luafile("sd-debug.lua")
do_luafile("sd-callbacks.lua")


table.keys = function(tbl)
    local keyset={}
    for k,v in pairs(tbl) do
        keyset[#keyset+1]=k
    end
    return keyset
end


file_end("sdini.lua")
