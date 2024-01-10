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

local function cmpkeys( a,b )
  if type(a) == type(b) then
      if a == "elementname" then return true end
      if b == "elementname" then return false end
      return a < b
  end
  if type(a) == "number" then return false end
  return true
end

do
  local function indent(level)
    return string.rep( "    ", level )
  end
  function printtable (ind,tbl_to_print,level,depth)
    if depth and depth <= level then return end
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
    log(indent(level) .. tostring(key) .. " = {")
    level=level+1
    local keys = {}
    for k,_ in pairs(tbl_to_print) do
      keys[#keys + 1] = k
    end
    table.sort(keys,cmpkeys)
    for i=1,#keys do
        local k = keys[i]
        local l = tbl_to_print[k]
        if type(l) == "userdata" and node.is_node(l) then
            l = "⬖".. nodelist_tostring(l) .. "⬗"
        end
      if type(l)=="table" then
        if k ~= ".__parent" and k ~= ".__context" then
          printtable(k,l,level,depth)
        else
          if k == ".__parent" then
            log("%s[\".__parent\"] = <%s>", indent(level),l[".__local_name"])
          end
        end
      else
        if type(k) == "number" then
          key = string.format("[%d]",k)
        else
          key = string.format("[%q]",tostring(k))
        end
        log("%s%s = %q", indent(level), key,tostring(l))
      end
    end
    log(indent(level-1) .. "},")
  end
end


-- function trace( ... )
--   if publisher.options.trace then
--     texio.write_nl("   |" .. string.format(...))
--     io.stdout:flush()
--   end
-- end
function tracetable( name,tbl )
  if publisher.options and publisher.options.trace and type(tbl)=="table" then
    printtable(name,tbl)
  end
end


function nodelist_tostring( head )
    local ret = {}
    while head do
        if head.id == publisher.hlist_node or head.id == publisher.vlist_node then
            if head.id == publisher.hlist_node then
                ret[#ret + 1] = " → "
              else
                ret[#ret + 1] = " ↳ "
            end
            ret[#ret + 1] = nodelist_tostring(head.head)
        elseif head.id == publisher.glyph_node then
            local c = head.char
            if c > 0x110000 then c = c - 0x110000 end
            ret[#ret + 1] = unicode.utf8.char(c)
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
          elseif head.id == publisher.kern_node then
            ret[#ret + 1] = "◊"
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

local function xml_escape( str )
    if type(str) == "table" then
        str = table.concat(str)
    end
    if not str then return "" end
    local replace = {
        [">"] = "&gt;",
        ["<"] = "&lt;",
        ["\""] = "&quot;",
        ["&"] = "&amp;",
    }
    -- FIXME, str can be bool
    local ret = string.gsub(str,".",replace)
    return ret
end

function showattributes(n, name)
  local attribs = publisher.get_attributes(n)
  w("----------")
  if name then w("Attributes %s",name) end
  for i, v in ipairs(attribs) do
    w("attr %s = %s",publisher.attribute_number_name[i],tostring(v))
  end
  w("----------")
end


--- Debugging (end)
