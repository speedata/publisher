--
--  viznodelist.lua
--  speedata publisher
--
--  Copyright 2010-2011 Patrick Gundlach.
--  See file COPYING in the root directory for license info.

--
-- visualizes nodelists using graphviz

-- usage example:

-- \setbox0\hbox{\vbox{\hbox{abc}}\vbox{x}}
-- \directlua{
--   require("viznodelist")
--   viznodelist.nodelist_visualize(0,"mybox.gv")
-- }
-- 
-- \bye

-- and then open "mybox.gv" with graphviz

--
-- nodelist_visualize takes three arguments:
-- 1: the number of the box or the box itself (when called from Lua)
-- 2: the filename of the dot-file to create
-- 3: the options table (optional). Known keywords:
--    - showdisc = <boolean> (defaults to false)

-- 2010-08-29, Patrick Gundlach, gundlach@speedata.de
-- Status: experimental/usable, including debug info
-- Newest file is at http://gist.github.com/556247


local io,string,table = io,string,table
local assert,tostring,type = assert,tostring,type
local tex,texio,node,unicode,font=tex,texio,node,unicode,font

module(...)

local function w( ... )
  texio.write_nl(string.format(...))
end

-- tostring(a_node) looks like "<node    nil <    172 >    nil : hlist 2>", so we can
-- grab the number in the middle (172 here) as a unique id. So the node
-- is named "node172"
local function get_nodename(n)
  return "\"n" .. string.gsub(tostring(n), "^<node%s+%S+%s+<%s+(%d+).*","%1") .. "\""
end

local function link_to( n,nodename,label )
  if n then
    local t = node.type(n.id)
    local nodename_n = get_nodename(n)
    if t=="temp" or t=="nested_list" then return end
    
    local ret
    if label=="prev" then
      -- ignore nodes where node.prev.next does not exist. 
      -- TODO: this should be more clever: ignore prev pointers of the first nodes in a list.
      if not n.next then return end
      ret = string.format("%s:%s:w -> %s:title\n",nodename,label,get_nodename(n))
    elseif label=="list" then
      ret = string.format("%s:%s:s -> %s:title\n",nodename,label,get_nodename(n))
    else
      ret = string.format("%s:%s -> %s:title\n",nodename,label,get_nodename(n)) 
    end
    return ret
  end
end

local function get_subtype( n )
  typ = node.type(n.id)
  local subtypes = {
    hlist = {
      [0] = "unknown origin",
      "created by linebreaking",
      "explicit box command",
      "parindent",
      "alignment column or row",
      "alignment cell",
    },
    glyph = {
      [0] = "character",
      "glyph",
      "ligature",
    },
    disc  = {
      [0] = "\\discretionary",
      "\\-",
      "- (auto)",
      "h&j (simple)",
      "h&j (hard, first item)",
      "h&j (hard, second item)",
    },
    glue = {
      [0]   = "skip",
      [1]   = "lineskip",
      [2]   = "baselineskip",
      [3]   = "parskip",
      [4]   = "abovedisplayskip",
      [5]   = "belowdisplayskip",
      [6]   = "abovedisplayshortskip",
      [7]   = "belowdisplayshortskip",
      [8]   = "leftskip",
      [9]   = "rightskip",
      [10]  = "topskip",
      [11]  = "splittopskip",
      [12]  = "tabskip",
      [13]  = "spaceskip",
      [14]  = "xspaceskip",
      [15]  = "parfillskip",
      [16]  = "thinmuskip",
      [17]  = "medmuskip",
      [18]  = "thickmuskip",
      [100] = "leaders",
      [101] = "cleaders",
      [102] = "xleaders",
      [103] = "gleaders"
    },
  }
  subtypes.whatsit = node.whatsits()
  if subtypes[typ] then
    return subtypes[typ][n.subtype] or tostring(n.subtype)
  else
    return tostring(n.subtype)
  end
  assert(false)
end

local function label(n,tab )
  local typ = node.type(n.id)
  local nodename = get_nodename(n)
  local subtype = get_subtype(n)
  local ret = string.format("%s [ label = \"<title> name: %s | <sub> type: %s  |  { <prev> prev |<next> next }",nodename or "??",typ or "??",subtype or "?")
  if tab then
    for i=1,#tab do
      if tab[i][1] then
        ret = ret .. string.format("|<%s> %s",tab[i][1],tab[i][2])
      end
    end
  end
  return ret .. "\"]\n"
end

local function draw_node( n,tab )
  local ret = {}
  if not tab then
    tab = {}
  end
  local nodename = get_nodename(n)
  local attlist = n.attr
  if attlist then
    attlist = attlist.next
    while attlist do
      tab[#tab + 1] = { "", string.format("attr%d=%d",attlist.number, attlist.value) }
      attlist = attlist.next
    end
  end
  ret[#ret + 1] = label(n,tab)
  ret[#ret + 1] = link_to(n.next,nodename,"next")
  ret[#ret + 1] = link_to(n.prev,nodename,"prev")
  return table.concat(ret)
end

local function dot_analyze_nodelist( head, options )
  local ret = {}
  local typ,nodename
	while head do
	  typ = node.type(head.id)
	  nodename = get_nodename(head)
    
  	if typ == "hlist" then
      local tmp = {}
      if head.width ~= 0 then
        local width = string.format("width %gpt",head.width / 2^16)
        tmp[#tmp + 1] = {"width",width}
      end
      if head.height ~= 0 then
        local height= string.format("height %gpt",head.height / 2^16)
        tmp[#tmp + 1] = {"height",height}
      end
      if head.depth ~= 0 then
        local depth = string.format("depth %gpt",head.depth / 2^16)
        tmp[#tmp + 1] = {"depth",depth}
      end
      if head.glue_set ~= 0 then
        local glue_set = string.format("glue_set %d",head.glue_set)
        tmp[#tmp + 1] =  {"glue_set",glue_set}
      end
      if head.glue_sign ~= 0 then
        local glue_sign = string.format("glue_sign %d",head.glue_sign)
        tmp[#tmp + 1] ={"glue_sign",glue_sign}
      end
      if head.glue_order ~= 0 then
        local glue_order = string.format("glue_order %d",head.glue_order)
        tmp[#tmp + 1] = {"glue_order",glue_order}
      end
      if head.shift ~= 0 then
  	    local shift = string.format("shift %gpt",head.shift / 2^16)
        tmp[#tmp + 1] = {"shift",shift }
      end
      tmp[#tmp + 1] = {"list", "list"}
      ret[#ret + 1] = draw_node(head, tmp)
  	  if head.list then
	      ret[#ret + 1] = link_to(head.list,nodename,"list")
  	    ret[#ret + 1] = dot_analyze_nodelist(head.list,options)
  	  end
  	elseif typ == "vlist" then
      local tmp = {}
      if head.width ~= 0 then
        local width = string.format("width %gpt",head.width / 2^16)
        tmp[#tmp + 1] = {"width",width}
      end
      if head.height ~= 0 then
        local height= string.format("height %gpt",head.height / 2^16)
        tmp[#tmp + 1] = {"height",height}
      end
      if head.depth ~= 0 then
        local depth = string.format("depth %gpt",head.depth / 2^16)
        tmp[#tmp + 1] = {"depth",depth}
      end
      if head.glue_set ~= 0 then
        local glue_set = string.format("glue_set %d",head.glue_set)
        tmp[#tmp + 1] =  {"glue_set",glue_set}
      end
      if head.glue_sign ~= 0 then
        local glue_sign = string.format("glue_sign %d",head.glue_sign)
        tmp[#tmp + 1] ={"glue_sign",glue_sign}
      end
      if head.glue_order ~= 0 then
        local glue_order = string.format("glue_order %d",head.glue_order)
        tmp[#tmp + 1] = {"glue_order",glue_order}
      end
      if head.shift ~= 0 then
  	    local shift = string.format("shift %gpt",head.shift / 2^16)
        tmp[#tmp + 1] = {"shift",shift }
      end
      tmp[#tmp + 1] = {"list", "list"}
      ret[#ret + 1] = draw_node(head, tmp)
  	  if head.list then
	      ret[#ret + 1] = link_to(head.list,nodename,"list")
  	    ret[#ret + 1] = dot_analyze_nodelist(head.list,options)
  	  end
  	elseif typ == "glue" then
  	  local subtype = get_subtype(head)
  	  local spec = string.format("%gpt", head.spec.width / 2^16)
  	  if head.spec.stretch ~= 0 then
  	    local stretch_order, shrink_order
  	    if head.spec.stretch_order == 0 then
  	      stretch_order = string.format(" + %gpt",head.spec.stretch / 2^16)
  	    else
  	      stretch_order = string.format(" + %g fi%s", head.spec.stretch  / 2^16, string.rep("l",head.spec.stretch_order - 1))
  	    end

  	    spec = spec .. stretch_order

  	  end
  	  if head.spec.shrink ~= 0 then
  	    if head.spec.shrink_order == 0 then
  	      shrink_order = string.format(" - %gpt",head.spec.shrink / 2^16)
  	    else
  	      shrink_order = string.format(" - %g fi%s", head.spec.shrink  / 2^16, string.rep("l",head.spec.shrink_order - 1))
  	    end

  	    spec = spec .. shrink_order
  	  end
      ret[#ret + 1] = draw_node(head,{ {"subtype", subtype},{"spec",spec} })
  	elseif typ == "kern" then
      ret[#ret + 1] = draw_node(head,{ {"kern", string.format("kern: %gpt",head.kern / 2^16) } })
  	elseif typ == "rule" then
  	  local wd,ht,dp
  	  if head.width  == -1073741824 then wd = "width: flexible"  else wd = string.format("width: %gpt", head.width  / 2^16) end
  	  if head.height == -1073741824 then ht = "height: flexible" else ht = string.format("height: %gpt", head.height / 2^16) end
  	  if head.depth  == -1073741824 then dp = "depth: flexible"  else dp = string.format("depth: %gpt", head.depth  / 2^16) end
      ret[#ret + 1] = draw_node(head,{ {"wd", wd  },{"ht", ht },{"dp", dp }  })
  	elseif typ == "penalty" then
      ret[#ret + 1] = draw_node(head,{ {"penalty", string.format("%d",head.penalty) } })
  	elseif typ == "disc" then
  	  if options.showdisc then
  	    ret[#ret + 1] = draw_node(head, { {"pre","pre"},{"post","post"},{"replace","replace"} })
  	    if head.pre then
  	      ret[#ret + 1] = dot_analyze_nodelist(head.pre,options)
	        ret[#ret + 1] = link_to(head.pre,nodename,"pre")
  	    end
  	    if head.post then
  	      ret[#ret + 1] = dot_analyze_nodelist(head.post,options)
	        ret[#ret + 1] = link_to(head.post,nodename,"post")
  	    end
  	    if head.replace then
  	      ret[#ret + 1] = dot_analyze_nodelist(head.replace,options)
	        ret[#ret + 1] = link_to(head.replace,nodename,"replace")
  	    end
      else
	      ret[#ret + 1] = draw_node(head, { } )
      end
  	elseif typ == "glyph" then
  	  local ch = string.format("%d",head.char)
      local ch = string.format("char: %q",unicode.utf8.char(head.char)):gsub("\"","\\\"")
  	  local lng = string.format("lang: %d",head.lang)
  	  local fnt = string.format("font: %d",head.font)
  	  local wd  = string.format("width: %gpt", head.width / 2^16)
  	  local comp
  	  if options.showdisc then
  	    comp = {"comp","components"}
  	  else
  	    comp = {}
  	  end
      ret[#ret + 1] = draw_node(head,{ {"char", ch} ,{"lang",lng },{"font",fnt},{"width", wd}, comp })
      if head.components and options.showdisc then
        ret[#ret + 1] = dot_analyze_nodelist(head.components,options)
	      ret[#ret + 1] = link_to(head.components,nodename,"comp")
      end
    elseif typ == "whatsit" and head.subtype == 39 then
      local stack,cmd,data
      stack = string.format("stack: %d",head.stack)
      cmd   = string.format("cmd: %d", head.cmd)
      data  = string.format("data: %s", head.data)
      ret[#ret + 1] = draw_node(head,{ {"subtype", "colorstack"},{"stack",stack},{"cmd",cmd},{"data",data} })
	  else
      ret[#ret + 1] = draw_node(head)
    end
    
    head = head.next
	end
  return table.concat(ret)
end


function nodelist_visualize( box,filename,options )
  assert(box,"No box given")
  assert(filename,"No filename given")
  local box_to_analyze
  if type(box)=="number" then
    box_to_analyze = tex.box[box]
  else
    box_to_analyze = box
  end
  local gv = dot_analyze_nodelist(box_to_analyze,options or {})
  local outfile = io.open(filename,"w")
  outfile:write([[
digraph g {
graph [
rankdir = "LR"
];
node [ shape = "record"]
]])
  outfile:write(gv)
  outfile:write("}\n")
  outfile:close()
end

