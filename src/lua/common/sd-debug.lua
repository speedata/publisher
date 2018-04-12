--- This file contains some debugging aids
--
--  sd-debug.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

function w( ... )
  local ok,fmt = pcall(string.format,...)
  if ok == false then
    texio.write_nl("-(e)-> " .. fmt)
    texio.write_nl(debug.traceback())
  else
    texio.write("-----> " .. fmt .. "\n")
    if errorlog then
        errorlog:write("-----> " .. fmt .. "\n")
    end
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
      log("printtable: %q is not a table, it is a %s (%q)",tostring(ind),type(tbl_to_print),tostring(tbl_to_print))
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
        if type(l) == "userdata" and node.is_node(l) then
            l = nodelist_tostring(l)
        end
      if type(l)=="table" then
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
    io.stdout:flush()
  end
end
function tracetable( name,tbl )
  if publisher.options and publisher.options.trace and type(tbl)=="table" then
    printtable(name,tbl)
  end
end


function nodelist_tostring( head )
    local ret = {}
    while head do
        if head.id == publisher.hlist_node or head.id == publisher.vlist_node then
            ret[#ret + 1] = nodelist_tostring(head.head)
        elseif head.id == publisher.glyph_node then
            ret[#ret + 1] = unicode.utf8.char(head.char)
        elseif head.id == publisher.rule_node then
            if  head.width > 0 then
                ret[#ret + 1] = "|"
            end
        elseif head.id == publisher.penalty_node then
            if head.next and head.next.id == publisher.glue_node and head.next.next and head.next.next.id == publisher.penalty_node then
                ret[#ret + 1] = "↩"
                head = head.next
                head = head.next
            end
        elseif head.id == publisher.glue_node then
            ret[#ret + 1] = "·"
        elseif head.id == publisher.whatsit_node then
            if head.subtype == publisher.pdf_refximage_whatsit then
                ret[#ret + 1] = string.format("⊡")
            else
                ret[#ret + 1] = "¿"
            end
        else
            -- w(head.id)
        end

        head = head.next
    end
    return table.concat(ret,"")
end


--- Debugging (end)
