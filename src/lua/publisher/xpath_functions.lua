--
--  layout_funktionen.lua
--  speedata publisher
--
--  Copyright 2010-2011 Patrick Gundlach.
--
--  See file COPYING in the root directory for license details.
file_start("xpath_functions.lua")

module(...,package.seeall)

local function position()
  return publisher.variablen.__position
end

local function concat(dataxml, ... )
  local ret = ""
  for i=1,select("#",...) do
    ret = ret .. select(i,...)
  end
  return ret
end

function count(dataxml, ... )
  local tocount = select(1,...)
  return #tocount
end

local function empty( dataxml,arg )
  if arg then
    return false
  end
  return true
end

local function last( dataxml )
  local datensatzname = dataxml[".__name"]
  local elternelement = dataxml[".__parent"]
  if not elternelement then
    return 1
  end
  local count = 0
  for i=1,#elternelement do
    if type(elternelement[i]) == 'table' and elternelement[i][".__name"] == datensatzname then
      count = count + 1
    end
  end
  return count
end

local function normalize_space(dataxml, str )
  if type(str) == "string" then
    return str:gsub("^%s*(.-)%s*$","%1"):gsub("%s+"," ")
  end
end

local function node(dataxml)
  local tab={}
  for i=1,#dataxml do
    tab[#tab + 1] = dataxml[i]
  end
  return tab
end

local function _string(dataxml, arg  )
  local ret
  if type(arg)=="table" then
    ret = {}
    for i=1,#arg do
      ret[#ret + 1] = tostring(arg[i])
    end
    ret = table.concat(ret)
  elseif type(arg) == "string" then
    ret = arg
  elseif type(arg) == "boolean" then
    ret = tostring(arg)
  elseif arg == nil then
    ret = 'nil'
  else
    warning("Unknown type in XPath-function 'string()': %s",type(arg))
    ret = tostring(arg)
  end
  return ret
end

local function _true()
  return true
end

local function _false()
  return false
end

file_end("xpath_functions.lua")


return {
  ["true"]   =  _true,
  ["false"]  =  _false,
  ["string"] = _string,
  concat     = concat,
  count      = count,
  empty      = empty,
  last       = last,
  node       = node,
  normalize_space = normalize_space,
  position   = position,
}
