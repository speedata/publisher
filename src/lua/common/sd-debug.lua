--- For debugging help
--
--  sd-debug.lua
--  publisher
--
--  Copyright 2010 Patrick Gundlach.
--  See file COPYING in the root directory for license info.

function w( ... )
  local ok,fmt = pcall(string.format,...)
  if ok == false then
    texio.write_nl("-(e)-> " .. fmt)
    texio.write_nl(debug.traceback())
  else
    texio.write("-----> " .. fmt .. "\n")
    errorlog:write("-----> " .. fmt .. "\n")
  end
  io.stdout:flush()
end

-- xpath.lua
function nexttok(src,str,pos)
    pos = pos or M.nextpos
    w(string.format("%.10s|",src)..string.sub(str,pos,pos + 10) .. "|")
end


if not log then
  log = function (...)
    texio.write(string.format(...) .. "\n")
  end
end


do
  tables_printed = {}
  function printtable (ind,tbl_to_print,level)
    if type(tbl_to_print) ~= "table" then
      log("printtable: %q ist keine Tabelle, es ist ein %s (%q)",tostring(ind),type(tbl_to_print),tostring(tbl_to_print))
      return
    end
    level = level or 0
    local k,l
    local key
    if level > 0 then
      if type(ind) == "number" then
        key = string.format("[%d]",ind)
      else
        key = string.format("[%q]",ind)
      end
    else
      key = ind
    end
    log(string.rep("  ",level) .. tostring(key) .. " = {")
    level=level+1

    for k,l in pairs(tbl_to_print) do
      if (type(l)=="table") then
        if k ~= ".__parent" then
          printtable(k,l,level)
        else
          log("%s[\".__parent\"] = <%s>", string.rep("  ",level),l[".__local_name"])
        end
      else
        if type(k) == "number" then
          key = string.format("[%d]",k)
        else
          key = string.format("[%q]",tostring(k))
        end
        log("%s%s = %q", string.rep("  ",level), key,tostring(l))
      end
    end
    log(string.rep("  ",level-1) .. "},")
  end
end


function trace( ... )
  if publisher.options.trace then
    texio.write_nl("   |" .. string.format(...))
  end
end
function tracetable( name,tbl )
  if publisher.options and publisher.options.trace and type(tbl)=="table" then
    printtable(name,tbl)
  end
end

--- Debugging (Ende)
