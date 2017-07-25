--- This file contains the code for the CSS parser.
--
--  css.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

local explode = string.explode
local string = unicode.utf8


local function new(self)
  c = {
     rules = {},
     priorities = {},
  }
  setmetatable(c,self)
  self.__index = self
  return c
end

-- sanitize selector and calculate priority
local function get_priority( selector )
  prio = 0
  string.gsub(selector,"[%.#]?[^%s.]+",function ( x )
    if string.match(x,"^#") then
      prio = prio + 100
    elseif string.match(x,"^%.") then
      prio = prio + 10
    else
      prio = prio + 1
    end
  end)
  local sel = string.gsub(selector,"^%s*(.-)%s*$","%1")
  return sel,prio
end

local function parsetxt(self,csstext)
  csstext = string.gsub(csstext,"%s+"," ")
  -- remove comments:
  csstext = string.gsub(csstext,"/%*.-%*/"," ")
  local stop,selector,selectors,rules,rule,property,expr,rule_stop
  stop = 0
  while true do
    _,stop,selector = string.find(csstext,"^%s*([^{]+)",stop + 1)
    if not selector then break end
    _, stop,rules_text = string.find(csstext,"{([^}]+)}%s*",stop + 1)
    if not rules_text then
      return
    end
    rules = explode(rules_text,";")
    local rules_t = {}
    for i=1,#rules do
      rule = rules[i]
      -- if it's not only whitespace
      if not string.match(rule,"^%s*$") then
        _,rule_stop,property = string.find(rule,"%s*([^:]+):")
        _,_,expr = string.find(rule,"^%s*(.-)%s*$",rule_stop + 1)
        rules_t[property] = expr
      end
    end
    selectors = explode(selector,",")
    local sel
    for i=1,#selectors do
      sel, prio = get_priority(selectors[i])
      self.rules[prio] = self.rules[prio] or {}
      self.rules[prio][sel] = self.rules[prio][sel] or {}
      for k,v in pairs(rules_t) do
        self.rules[prio][sel][k] = v
      end
    end
  end
  local prio_found
  -- We remember the priority for later use.
  for prio,_ in pairs(self.rules) do
    prio_found = false
    for i=1,#self.priorities do
      if self.priorities[i] == prio then prio_found = true break end
    end
    if prio_found == false then self.priorities[#self.priorities + 1] = prio end
  end
  -- now sort the table with the priorities, so we can access the
  -- rules in the order of priorities (that's the whole point)
  table.sort( self.priorities,function ( a,b ) return a > b end )
end

local function parse( self,filename)
  local path = kpse.find_file(filename)
  if not path then
    err("CSS: cannot find filename %q.",filename or "--")
    return
  end
  log("Loading CSS %q",path)
  local cssio = io.open(path,"rb")
  local csstext = cssio:read("*all")
  cssio:close()
  return parsetxt(self,csstext)
end

--- tbl has these entries:
---
--- * `id`
--- * `class`
--- * `element`
--- * `parent`
---
local function matches_selector(tbl,selector )
  local element,class,id = tbl.element,tbl.class,tbl.id
  local id_found   ,class_found   ,element_found    = false,false,false
  local id_matches ,class_matches ,element_matches  = false,false,false
  local id_required,class_required,element_required = tbl.id ~= nil, tbl.class ~= nil, tbl.element ~= nil
  -- todo: element_required is probably never false since the publisher always presents an element name

  local return_false = false
  string.gsub(selector,"[%.#]?[^%s.#]+",function ( x )
    if string.match(x,"^#") then
      if not id_required then
        return_false = true
      end
      id_found = true
      if id and string.match(id,escape_lua_pattern(string.sub(x,2))) then
        id_matches = true
      end
    elseif string.match(x,"^%.") then
      if not class_required then
        return_false = true
      end
      class_found = true
      if class and string.match(class,escape_lua_pattern(string.sub(x,2)).. "$") then
        class_matches = true
      end
    else
      if not element_required then
        return_false = true
      end
      element_found = true
      if element and string.match(element,"^" .. escape_lua_pattern(x) .. "$") then
        element_matches = true
      end
    end
  end)
  if return_false then
    return false
  end
  -- We return true if we have found something that matches and if these elements, if found, match the requested ones from the tbl
  return element_found == element_matches and class_found == class_matches and id_found == id_matches and (class_found or element_found or id_found)
end

-- tbl = element, class, id
local function matches(self,tbl,level)
  level = level or 1
  local rules,interesting_part,parts
  for _,v in ipairs(self.priorities) do
    for selector,rule in pairs(self.rules[v]) do
      parts = explode(selector," ")
      -- the interesting part depends on the level:
      -- level 1: the last part, level 2, the second last part, ...
      interesting_part = parts[#parts + 1 - level]
      if matches_selector(tbl,interesting_part) == true then
        return rule
      end
    end
  end
  return nil
end


return {
  new       = new,
  parse     = parse,
  parsetxt  = parsetxt,
  matches   = matches,
}
