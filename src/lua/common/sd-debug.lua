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
    texio.write_nl("-----> " .. fmt)
  end
end

if not log then
  log = function (...)
    texio.write_nl(string.format(...))
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
          log("%s[\".__parent\"] = <%s>", string.rep("  ",level),l[".__name"])
        end
      else
        if type(k) == "number" then
          key = string.format("[%d]",k)
        else
          key = string.format("[%q]",k)
        end
        log("%s%s = %q", string.rep("  ",level), key,tostring(l))
      end
    end
    log(string.rep("  ",level-1) .. "},")
  end
end

function nodelist_analyze(head)
  local whatsits = node.whatsits()

  for n in node.traverse(head) do
    if node.type(n.id) == "whatsit" then
      w("whatsit: type=%q",whatsits[n.subtype])
      if whatsits[n.subtype]=="local_par" then
        w("local_par: pen_inter=%s, pen_broken=%s",tostring(n.pen_inter),tostring(pen_broken))
      end
    elseif node.type(n.id) == "hlist" then
      w("hlist: subtype=%d, Breite=%gpt, list=%q",n.subtype,n.width / 2^16,tostring(n.list) )
      nodelist_analyze(n.list)
    elseif node.type(n.id) == "vlist" then
      w("vlist")
      nodelist_analyze(n.list)
    elseif node.type(n.id) == "glyph" then
      w("glyph: font=%s, Zeichennummer=%d, Zeichen=%q",n.font,n.char,string.char(n.char))
    elseif node.type(n.id) == "kern" then
      w("kern: subtype=%d, kern=%gpt",n.subtype,n.kern / 2^16)

    elseif node.type(n.id) == "glue" then
      local spec = n.spec
      w("glue: subtype=%d",n.subtype)
      w("gluespec: space=%d, stretch=%d, shrink=%d, stretch_order=%d, shrink_order=%d",n.spec.width,n.spec.stretch,n.spec.shrink, n.spec.stretch_order, n.spec.shrink_order)

    elseif node.type(n.id) == "penalty" then
      w("penalty: %d",n.penalty)
    elseif node.type(n.id) == "rule" then
      w("rule: width=%d, height=%d, depth=%d",n.width / 2^16, n.height, n.depth)
    else
      w("?? %s",node.type(n.id))
    end
  end
  texio.write("\n")
  return true
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
