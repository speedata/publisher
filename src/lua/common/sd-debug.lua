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
  tables_printed = {}
  local function indent(level)
    return string.rep( "    ", level )
  end
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
            l = nodelist_tostring(l)
        end
      if type(l)=="table" then
        if k ~= ".__parent" then
          printtable(k,l,level)
        else
          log("%s[\".__parent\"] = <%s>", indent(level),l[".__local_name"])
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

-- function show_table_internalx( tbl,lvl )
--     local i = 0
--     local other_tables = {}
--     local ret = { string.format([=[struct%s [label=< <Table BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="4">]=],lvl) }
--     ret[#ret + 1] = "\n"
--     local tblcollect = {}
--     for k,v in pairs(tbl) do
--         i = i + 1
--         local portname = k
--         if i == 1 then portname = "first" end
--         local port = string.format([=[ PORT="%s"]=],portname)
--         if type(v) == "table" then
--             local nexttable = string.format( "%s%d",lvl,i )
--             local othertable = show_table_internal(v,nexttable)
--             if othertable == "" then
--                 tblcollect[#tblcollect +1] = string.format([=[<Tr><Td align="left"%s>%s</Td><Td align="right">{ }</Td></Tr>]=],port,tostring(k))
--             else
--                 tblcollect[#tblcollect +1] = string.format([=[<Tr><Td align="left"%s>%s</Td></Tr>]=],port,tostring(k))
--                 other_tables[#other_tables + 1] = othertable
--                 other_tables[#other_tables + 1] = string.format("struct%s:%s:e -> struct%s:first",lvl,portname,nexttable)
--             end
--         else
--             tblcollect[#tblcollect +1] = string.format([=[<Tr><Td align="left"%s>%s</Td><Td align="left">%q</Td></Tr>]=],port,tostring(k),xml_escape(v))
--         end
--         tblcollect[#tblcollect + 1] = "\n"
--     end
--     if #tblcollect > 0 then
--         ret[#ret + 1] = table.concat(tblcollect,"")
--         ret[#ret +1] = "</Table> >]\n\n"
--         ret[#ret + 1] = table.concat(other_tables,"\n\n")
--         return table.concat(ret,"")
--     end
--     -- empty table
--      return ""
-- end

-- local function cmp( a,b )
--     if type(a) == type(b) then
--         if a == "elementname" then return true end
--         if b == "elementname" then return false end
--         return a < b
--     end
--     if type(a) == "number" then return false end
--     return true
-- end

-- function show_table_as_table( tbl,lvl )
--     local i = 0
--     local other_tables = {}
--     local ret = { [=[<Table BORDER="0" CELLBORDER="0" CELLSPACING="0" CELLPADDING="0">]=] }
--     ret[#ret + 1] = "\n"
--     local tblcollect = {}
--     local keys = {}
--     for k,_ in pairs(tbl) do
--         keys[#keys + 1] = k
--     end
--     table.sort(keys,cmp)
--     for i=1,#keys do
--         local k = keys[i]
--         local v = tbl[k]
--         i = i + 1
--         local toprint = "{}"
--         local bgcolor=""
--         if k=="elementname" then bgcolor=" bgcolor=\"lightgreen\"" end
--         if type(v) == "table" then
--             local nexttable = string.format( "%s%d",lvl,i )
--             local othertable = show_table_as_table(v,nexttable)
--             if othertable ~= "" then
--                 toprint = othertable
--             end
--         else
--             toprint = xml_escape(v)
--         end
--         tblcollect[#tblcollect +1] = string.format([=[<Tr><Td valign="top" align="left"%s>%s</Td><Td align="left"%s>%s</Td></Tr>]=],bgcolor,tostring(k),bgcolor,toprint)
--         tblcollect[#tblcollect + 1] = "<HR />\n"
--     end
--     table.remove(tblcollect)
--     if #tblcollect > 0 then
--         ret[#ret + 1] = table.concat(tblcollect,"")
--         ret[#ret +1] = "</Table>\n\n"
--         return table.concat(ret,"")
--     end
--     -- empty table
--      return ""
-- end

-- -- # http://www.graphviz.org/content/cluster
-- --
-- -- digraph G {
-- --   rankdir=LR
-- 	-- subgraph cluster_1 {
-- 		-- style=filled;
-- 		-- color=gray40;
-- 		-- node [style=filled,color=white];
-- 		-- label = "body";
-- --
--     --   subgraph cluster_9 { header -> a1 -> a2 -> a3;  label = ""; }
-- --
-- --
-- --
-- 	-- subgraph cluster_2 {
-- 		-- node [style=filled];
-- 		-- color=gray60
-- 		-- label = "h1";
-- 		-- subgraph cluster_22 { 		bla -> em -> b2 -> b3; label=""; }
-- --
-- 	-- subgraph cluster_3 {
-- 		-- node [style=filled];
-- 		-- x0 -> x1 -> x2 -> x3;
-- 		-- label = "process #3";
-- 		-- color=gray80 	}
-- --
-- 	-- }
-- 		-- subgraph cluster_4 {
-- 		-- z0 -> z1 ;
-- 		-- label = "process #4";
-- 		-- color=gray60 ; }
-- -- }
-- -- }


-- function show_htmltable( tbl,lvl )
--     local ret = {}
--     if tbl.elementname then
--         ret[#ret + 1] = tbl.elementname
--     end
--     for i=1,#tbl do
--         local thiselt = tbl[i]
--         w("type %s",type(thiselt))
--         if type(thiselt) == "table" then
--             ret[#ret + 1] = "{ "
--             ret[#ret + 1] = show_htmltable(thiselt,string.format( "%s%d",lvl,i ))
--             ret[#ret + 1] = " } "
--         elseif type(thiselt) == "string" then
--             ret[#ret + 1] = thiselt
--         else
--             w("?? %s",type(thiselt))
--         end
--         ret[#ret + 1] = "\n"
--     end
--     return table.concat(ret,"")
-- end

-- function showtable(filename,tblname,tbl)
--   local outfile = io.open(filename,"wb")
--   local gv = [=[digraph structs {
--     rankdir=LR
--     graph [ label="%s" labelloc="t" ]
--     node [shape=record]
--   ]=]
--   outfile:write(string.format(gv,tblname or "-"))
--   local b = show_htmltable(tbl,"1")
--   outfile:write(b)
--   outfile:write(" }\n")
--   outfile:close()
-- end



--- Debugging (end)
