-- xml parser

local xmlreader = xmlreader
local w = w
local setmetatable,tostring = setmetatable,tostring
local table = table

module(...)

-- Liefert den Textwert eines Elements zurück (tostring(xml))
local function xml_to_string( self )
  local ret = {}
  for i=1,#self do
    ret[#ret + 1] = tostring(self[i])
  end
  return table.concat(ret)
end

local mt = {
  __tostring = xml_to_string
}

function read_element(r)
  local ret = {}
  setmetatable(ret,mt)
  ret[".__name"] = r:local_name()

  while (r:move_to_next_attribute()) do ret[r:name()] = r:value() end
  r:move_to_element()

  if r:is_empty_element() then
    return ret
  end
  
  while (r:read()) do
    if r:node_type() == 'element' then
      ret[#ret + 1] = read_element(r)
      ret[#ret][".__parent"] = ret
    elseif r:node_type() == 'end element' then
      return ret
    elseif r:node_type() == 'text' then
      ret[#ret + 1] = r:value()
    elseif r:node_type() == 'significant whitespace' then
      ret[#ret + 1] = ' '
    elseif r:node_type() == "comment" then
      -- ignorieren
    else
      w("xmlparser: unbekannter nodetyp gefunden: %s",r:node_type())
    end
  end
  return ret
end

function parse(r)
  local ret
  -- Kommentare etc. überspringen
  while r:read() do
    if (r:node_type() == 'element') then
      ret = read_element(r)
    end
  end
  if r:read_state() == "error" then
    print("Error!")
  end
  return ret
end

function parse_xml_file( filename )
  local r = xmlreader.from_file(filename,nil,{"nocdata","xinclude","nonet"})
  return parse(r)
end

function parse_xml(txt)
  local r = xmlreader.from_string(txt,nil,nil,{"nocdata","xinclude","nonet"})
  return parse(r)
end

