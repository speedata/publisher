--
--  sdini.lua
--  speedata publisher
--
--  Copyright 2010-2011 Patrick Gundlach.
--  See file COPYING in the root directory for license info.
--

-- BUG on windows: http://lua-users.org/lists/lua-l/2012-08/msg00052.html
-- ! in LUA_PATH gets replaced by $PWD
package.path=os.getenv("LUA_PATH")

texio.write_nl("Loading file sdini.lua ...")

callback.register('start_run',function() return true end)


texconfig.kpse_init=false
texconfig.max_print_line=99999
texconfig.formatname="sd-format"
texconfig.trace_file_names = false

local basedir=os.getenv("PUBLISHER_BASE_PATH")
local extra_dirs = os.getenv("SD_EXTRA_DIRS")
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

function dirtree(dir)
  assert(dir and dir ~= "", "directory parameter is missing or empty")
  if string.sub(dir, -1) == "/" then
    dir=string.sub(dir, 1, -2)
  end

  local function yieldtree(dir)
    for entry in lfs.dir(dir) do
      if not entry:match("^%.") then
        entry=dir.."/"..entry
     	  local attr=lfs.attributes(entry)
        if attr then
     	      if attr.mode ~= "directory" then
     	        coroutine.yield(entry,attr)
     	      end
     	      if attr.mode == "directory" then
     	        yieldtree(entry)
     	      end
        end
      end
    end
  end

  return coroutine.wrap(function() yieldtree(dir) end)
end

kpse.filelist = {}

local function add_dir( dir )
  for i in dirtree(dir) do
    local filename = i:gsub(".*/([^/]+)$","%1")
    kpse.filelist[filename] = i
  end
end

add_dir(basedir)
if os.type == "windows" then
  path_separator = ";"
else
  path_separator = ":"
end

if extra_dirs then
  for _,d in ipairs(string.explode(extra_dirs,path_separator)) do
    if lfs.attributes(d,"mode")=="directory" then
      add_dir(d)
    end
  end
end


function kpse.find_file(filename,what)
  if not filename then return nil end
  return kpse.filelist[filename] or kpse.filelist[filename .. ".tex"]
end

function do_luafile(filename)
  local a = kpse.find_file(filename)
  assert(a,string.format("Can't find file %q",filename))
  return dofile(a)
end

do_luafile("sd-debug.lua")
do_luafile("sd-callbacks.lua")

texio.write_nl("Loading file sdini.lua ... done\n")
