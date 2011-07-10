local raster = require("publisher.raster")

local assert,setmetatable = assert,setmetatable
local tex = tex


module(...)

_M.__index = _M

function new( self,breite,hoehe,extra_rand,beschnittzugabe )
  assert(self)
  if not breite then return nil,"Keine Breiteninformation in der Seite gefunden. Wurde das Element <Seitenformat> angegeben?" end
  assert(breite)
  assert(hoehe)
  local extra_rand      = extra_rand or 0
  local beschnittzugabe = beschnittzugabe or 0
  local s = {
    raster = raster:new()
  }
  s.raster.extra_rand = extra_rand
  s.raster.beschnittzugabe = beschnittzugabe

  tex.pagewidth  = breite + extra_rand * 2
  tex.pageheight = hoehe  + extra_rand * 2

	setmetatable(s, self)
	return s
end
