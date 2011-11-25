--
--  fileutils.lua
--  speedata publisher
--
--  Copyright 2011 Patrick Gundlach.
--  See file COPYING in the root directory for license info.

local lfs,os,io=lfs,os,io
local type = type
local w,printtable = w,printtable
local mdfive = md5

module(...)


function cd( dir, func )
  local oldwd = lfs.currentdir()
  if func and type(func)=="function" then
    lfs.chdir(dir)
    func(lfs.currentdir())
    lfs.chdir(oldwd)
  else
    lfs.chdir(dir)
  end
end

function pwd()
  return lfs.currentdir()
end

function mkdir( dir )
  return lfs.mkdir(dir)
end

function mkdir_p( dir )
  -- body
end

function rmdir( dir )
  return lfs.rmdir(dir)
end

function cp( src,dest )
  local src_io,dest_io
  
  src_io  = io.open(src,"r")
  
  if lfs.isdir(dest) then
    dest_io = io.open(dest .. "/" .. src,"w+")
  else
    dest_io = io.open(dest,"w+")
  end
  
  local j
  while true do
    j = src_io:read(2^13)
    if not j then break end
    dest_io:write(j)
  end
  src_io:close()
  dest_io:close()
end
-- mkdir_p(dir, options)
-- mkdir_p(list, options)
-- rmdir(dir, options)
-- rmdir(list, options)
-- ln(old, new, options)
-- ln(list, destdir, options)
-- ln_s(old, new, options)
-- ln_s(list, destdir, options)
-- ln_sf(src, dest, options)
-- cp(src, dest, options)
-- cp(list, dir, options)
-- cp_r(src, dest, options)
-- cp_r(list, dir, options)
-- mv(src, dest, options)
-- mv(list, dir, options)

function rm( filename )
  return os.remove( filename )
end

function rm_r( entry , dir )
  if lfs.isfile(entry) then
    rm(entry) 
  elseif lfs.isdir(entry) then
    for e in lfs.dir(entry) do
      if e ~= ".." and e ~= "." then
        rm_r(entry .. "/" .. e)
      end
    end
   rmdir(entry)
  end
end

-- rm_rf(list, options)
-- install(src, dest, mode = <src's>, options)
-- chmod(mode, list, options)
-- chmod_R(mode, list, options)
-- chown(user, group, list, options)
-- chown_R(user, group, list, options)

function touch( filename )
  if not test("x",filename) then
    io.open(filename,"w"):close()
  end
  return lfs.touch(filename)
end

function test( letter,path )
  ok,msg = lfs.attributes(path)
  if letter=="x" then
    if ok==nil then return false end
    return true
  end
end

function md5( filename )
  src_io  = io.open(filename,"r")
  buf = src_io:read("*a")
  src_io:close()
  return mdfive.sumhexa(buf)
end
