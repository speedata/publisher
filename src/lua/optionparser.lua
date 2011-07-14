--
--  optionparser.lua
--  speedata publisher
--
--  Copyright 2009-2011 Patrick Gundlach.
--  See file COPYING in the root directory for license info.

local setmetatable,ipairs,type,print,assert = setmetatable,ipairs,type,print,assert
local string,table,io,os = string,table,io,os
local tostring=tostring
local arg = arg

module(...)
_M.__index = _M


local w=function (...) print(string.format(...)) end



function new(self)
	local o = {
	  short       = {},
	  long        = {},
	  optionarray = {},   -- Reihenfolge der Optionen
  }

	setmetatable(o, self)
	o:on("-h","--help","Zeigt diese Hilfe", function() help(o) os.exit(0) end)
	return o
end

-- Teilt str in Argumentname und Parameter auf. Rückgabe ist Argumentname, Parameter, ist_optional? und ist_kurz?
function split_on( self, str )
  local argument,param,optional,kurz
  if str:match("^%-%-") then
    kurz = false
  elseif str:match("^%-[^-]") then
    kurz = true
  else
    assert(false)
  end
  local init = 3 -- position von Text nach '--'
  if kurz==true then init = 2 end
  local pos = str:find("[ =]",init)
  local len = str:len()
  if pos then
    argument = str:sub(init,pos - 1)
  else
    return str:sub(init),nil,false,kurz
  end
  pos = pos + 1
  if str:sub(pos,pos) == "[" then
    optional = true
    pos = pos + 1
    len = len - 1
  else
    optional = false
  end
  param = str:sub(pos, len)
  return  argument,param,optional,kurz
end


function on(self, ... )
  assert(type(self)=="table")
  local option={}
  self.optionarray[#self.optionarray + 1] = option
  option.counter = #self.optionarray -- um --help wieder zu löschen
  local i,j,k
  local argument,param,optional,kurz
  for _,v in ipairs({...}) do
    if type(v)=="string" and v:match("^%-%-?") then
      -- short or long option
      argument,param,optional,kurz = self:split_on(v)
      if kurz then
        if self.short[argument] then
          -- schon vorhanden. Aus dem optionarray löschen und auch die lange Version löschen
          local opt = self.short[argument]
          table.remove(self.optionarray,opt.counter)
          self.long[opt.lang] = nil
        end
        self.short[argument]=option
        option.kurz = argument
      else
        if self.long[argument] then
          -- schon vorhanden. Aus dem optionarray löschen und auch die kurze Version löschen
          local opt = self.long[argument]
          table.remove(self.optionarray,opt.counter)
          self.short[opt.kurz] = nil
        end
        self.long[argument]=option
        option.lang = argument
      end
      -- the other (short/long) option could have set this already
      option.optional = option.optional or optional
      option.param    = option.param    or param 
    elseif type(v)=="function" then
      option.func = v
    elseif type(v)=="string" then
      option.hilfetext = v
    end
  end
  assert(option.func)
end

function parse(self, _arg )
  local i = 1
  local argument,param,kurz
  local option
  while i <= #_arg do
    if _arg[i]:match("%-") then
      argument,param,_,kurz = self:split_on(_arg[i])
      if kurz then
        option = self.short[argument]
      else
        option = self.long[argument]
      end
      if not option then
        local minus
        if kurz then
          minus = "-"
        else
          minus = "--"
        end
        return false,"Unbekannte Option: " .. minus .. argument
      end
      if not param and  i < #_arg and not _arg[i+1]:match("^%-%-?") then
        param = table.remove(_arg,i+1)
      end

      if param then
        if option.param then
          -- alles gut, wir haben auch einen Parameter erwartet
          option.func(param)
        else
          -- wir haben keinen Parameter erwartet, ist ok, ignorieren
          option.func()
        end
      else
        -- es ist kein Parameter vorhanden
        if option.param and option.optional then
          -- ok, wir können ruhig weiter schlafen
          option.func()
        elseif option.param and not option.optional then
          -- fehler! Es ist kein Parameter angegeben, aber wir haben einen erwartet
          return false,"Parameter erwartet aber keinen gefunden."
        else
          option.func()
          -- ok, wir haben auch keinen erwartet
        end
      end
      table.remove(_arg,i)
    else
      i = i + 1
    end
  end
  return true, _arg
end

function help(self)
  assert(self)
  assert(type(self)=="table")
  local lang,kurz
  local usage = string.format("Benutzung: %s [Parameter] Kommandos",arg[1])
  io.write(self.banner or usage)
  io.write("\n")
  for _,v in ipairs(self.optionarray) do
    lang,kurz = (v.lang or ""),(v.kurz or "")
    if lang then
      if v.param and v.optional then
        lang = string.format("%s [=%s]",v.lang,v.param)
      elseif v.param then
        lang = string.format("%s=%s",v.lang,v.param)
      end
    else
      if v.param and v.optional then
        kurz = string.format("%s [=%s]",v.kurz,v.param)
      elseif v.param then
        kurz = string.format("%s=%s",v.kurz,v.param)
      end
    end
    local strich_kurz = "-"
    local komma = ","
    if kurz:len() == 0 then
      strich_kurz = ""
      komma = ""
    end
    local strich_lang = "--"
    if lang:len() == 0 then
      strich_lang = ""
      komma = ""
    end


    local start = self.start or 30
    local stop  = self.stop  or 79
    local wd = stop - start

    local lines = {}
    local current_line = nil
    local current_line_length = 0

    -- inefficient but OK
    for word in string.gmatch(v.hilfetext or "","%S+") do
      wd_word = string.len(word)
      if not current_line then
        current_line = word
        current_line_length = wd_word
      elseif wd_word + current_line_length + 1 < wd then
        current_line = current_line .. " " .. word
        current_line_length = current_line_length + wd_word + 1
      else
        lines[#lines + 1] = current_line
        current_line = word
        current_line_length = wd_word
      end
    end
    lines[#lines + 1] = current_line

    local formatstring = string.format("%%-1s%%-2s%%1s %%-2s%%-%d.%ds %%s\n",start - 8,start - 8)
    io.write(string.format(formatstring,strich_kurz,kurz, komma,strich_lang,lang,lines[1] or ""))

    local formatstring = string.format("%%%ds%%s\n",start)

    for i=2,#lines do
      io.write(string.format(formatstring," ", lines[i]))
    end

  end
end
