--
--  helper.lua
--  speedata publisher
--
--  Created by Patrick Gundlach on 2010-03-27.
--  Copyright 2010 Patrick Gundlach. All rights reserved.
--
file_start("helper.lua")


-- Hilfsfunktionen, die irgendwo im Publisher verwendet werden können.
module(...,package.seeall)


-- Gibt Anzahl der PostScript Punkt zurück. Eingabe: sp (scaled points)
function sp_to_bp( sp )
  return math.round(sp / 65782 , 3)
end

function to_bp(arg)
  tex.dimen[0] = arg
  return math.round(tex.dimen[0] / 65782 , 3)
end


file_end("helper.lua")
