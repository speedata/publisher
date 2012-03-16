--
--  seite.lua
--  speedata publisher
--
--  Copyright 2010-2011 Patrick Gundlach.
--  See file COPYING in the root directory for license info.


local raster = require("publisher.grid")

local assert,setmetatable = assert,setmetatable
local tex = tex


module(...)

_M.__index = _M

function new( self,width,height,additional_margin, trim )
  assert(self)
  if not width then return nil,"No information about page width found. Did you give the command <Pageformat>?" end
  assert(height)

  additional_margin = additional_margin or 0
  trim              = trim              or 0

  local s = {
    raster = raster:new(),
    width  = width,
    height = height,
  }

  s.raster.extra_rand      = additional_margin
  s.raster.beschnittzugabe = trim

  tex.pagewidth  = width   + additional_margin * 2
  tex.pageheight = height  + additional_margin * 2

	setmetatable(s, self)
	return s
end
