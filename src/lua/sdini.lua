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
splib = nil

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


-- Logs a "start file" debug entry. Called at the top of every Lua source
-- to give per-file load timing.
---@param filename string
---@return nil
function file_start( filename )
    splib.log("debug","Start file","filename",filename)
end

-- Logs an "end file" debug entry, the counterpart to `file_start`.
---@param filename string
---@return nil
function file_end( filename )
    splib.log("debug","End file","filename",filename)
end


file_start("sdini.lua")
callback.register('start_run',function() return true end)

main = {}

-- Forwards to `splib.log`, automatically appending the current page
-- number (and, with the new XPath parser, layout/data line numbers) as
-- structured key/value fields, so warn/error log entries carry that
-- context without callers having to assemble it themselves.
---@param level string Log level: `"debug"`, `"info"`, `"warn"`, `"error"`, …
---@param msg string Primary message.
---@param ... any Additional key/value pairs forwarded to `splib.log`.
---@return nil
function main.log(level, msg, ...)
    local publisher = package.loaded.publisher
    if not (publisher and publisher.current_pagenumber) then
        return splib.log(level, msg, ...)
    end
    -- Capture `...` first; in Lua, `f(..., "x")` only forwards the first
    -- value of `...` (the rest is dropped before "x" is appended), so the
    -- existing key/value pairs from the caller would shift onto the wrong
    -- positions if we tried to inline this.
    local extras = {...}
    -- Don't overwrite keys the caller passed in already; e.g. PlaceObject
    -- intentionally logs a `page` value distinct from current_pagenumber.
    local has_page, has_layout, has_data = false, false, false
    for i = 1, #extras - 1, 2 do
        local k = extras[i]
        if     k == "page"        then has_page   = true
        elseif k == "line_layout" then has_layout = true
        elseif k == "line_data"   then has_data   = true
        end
    end
    if not has_page then
        extras[#extras+1] = "page"
        extras[#extras+1] = tostring(publisher.current_pagenumber)
    end
    if publisher.newxpath then
        if not has_layout then
            extras[#extras+1] = "line_layout"
            extras[#extras+1] = tostring(publisher.current_layout_line)
        end
        if not has_data then
            extras[#extras+1] = "line_data"
            extras[#extras+1] = tostring(publisher.current_data_line)
        end
    end
    return splib.log(level, msg, table.unpack(extras))
end


texconfig.kpse_init=false
texconfig.max_print_line=99999
texconfig.formatname="sd-format"
texconfig.trace_file_names = false

splib.buildfilelist()
kpse = {}

-- Looks up `filename` in the publisher's built-in file list. Replaces the
-- traditional kpse-based finder.
---@param filename string
---@return string? path Full path, or `nil` if not found.
function kpse.find_file(filename)
  return splib.lookupfile(filename)
end

-- Adds `dirname` to the publisher's file lookup search path.
---@param dirname string
---@return any
function kpse.add_dir(dirname)
    return splib.add_dir(dirname)
end

-- Resolves and `dofile`s a Lua source by file name.
---@param filename string
---@return any
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
