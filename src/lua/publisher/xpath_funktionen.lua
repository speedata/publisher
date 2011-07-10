--
--  layout_funktionen.lua
--  speedata publisher
--
--  Created by Patrick Gundlach on 2010-03-27.
--  Copyright 2010 Patrick Gundlach. All rights reserved.
--
datei_start("xpath_funktionen.lua")

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
    warnung("Unbekannter Typ in XPath-Funktion 'string()': %s",type(arg))
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

datei_ende("xpath_funktionen.lua")


return {
  ["true"]       =  _true,
  ["false"]      =  _false,
  ["string"]     = _string,
  concat         = concat,
  last           = last,
  node           = node,
  position       = position,
}
