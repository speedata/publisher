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


local splib = require("libsplib")

function file_start( filename )
  splib.log("debug","Start file","filename",filename)
end
function file_end( filename )
splib.log("debug","End file","filename",filename)
end


file_start("sdini.lua")
callback.register('start_run',function() return true end)


texconfig.kpse_init=false
texconfig.max_print_line=99999
texconfig.formatname="sd-format"
texconfig.trace_file_names = false

splib.buildfilelist()
kpse = {}



--- @param filename string The file name to look up
--- @return string|nil The full path of the file name or nil if the file is not found.
function kpse.find_file(filename)
  return splib.lookupfile(filename)
end

function kpse.add_dir(dirname)
    return splib.add_dir(dirname)
end

function do_luafile(filename)
  local a = kpse.find_file(filename)
  assert(a,string.format("Can't find file %q",filename))
  return dofile(a)
end

do_luafile("sd-debug.lua")
do_luafile("sd-callbacks.lua")

file_end("sdini.lua")
