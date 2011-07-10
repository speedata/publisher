--
--  helper.lua
--  speedata publisher
--
--  Created by Patrick Gundlach on 2010-03-27.
--  Copyright 2010 Patrick Gundlach. All rights reserved.
--
datei_start("helper.lua")


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


-- local erzeugte_fontnamen={}

-- Gibt einen zufälligen String zurück, der nur aus Kleinbuchstaben besteht.
-- function generiere_fontname()
--   local tmp
--   tmp = ""
--   for i = 1,10 do
--     tmp = tmp .. string.char(math.random(0,25) + string.byte("a"))
--   end
--   assert(not erzeugte_fontnamen[tmp])
--   erzeugte_fontnamen[tmp]=true
--   return tmp
-- end

-- Gibt den TeX-Fontnamen zurück. `schriftname` kann ein Eintrag aus <DefiniereSchrift> sein.
-- function echter_fontname(schriftname)
--   if publisher.fontliste[schriftname] then
--     return publisher.fontliste[schriftname]
--   end
--   local ende_erreicht = false
--   local lookup=schriftname
--   local tmp,ret
--   -- löse den Kunstnamen soweit auf, bis ein echter Dateiname übrigbleibt.
--   repeat
--     tmp = publisher.schrifttabelle[lookup]
--     if publisher.schrifttabelle[tmp] then
--       lookup = tmp
--     else
--       ende_erreicht = true
--     end
--   until ende_erreicht
--   if not tmp then
--     -- texkom.fehler("Dateiname für Font '" .. schriftname .. "' konnte nicht ermittelt werden.")
--     tmp = lookup
--   end
--   -- fontname ist der interne TeX-Name
--   local fontname = generiere_fontname()
--   if texkom.erzeuge_font(fontname,tmp) == false then  fontname = "tenrm" end -- fallback
--   publisher.fontliste[schriftname] = fontname
--   return fontname
-- end

-- Gibt eine ID zurück, unter der der Font ansprechbar ist (Attribut selectfont muss auf diesen
-- Wert gesetzt werden).
-- function erzeuge_fontinstanz( schriftname )
--   if publisher.fontliste[schriftname] then
--     return publisher.fontliste[schriftname]
--   end
--   local ende_erreicht = false
--   local lookup=schriftname
--   local tmp,ret
--   -- löse den Kunstnamen soweit auf, bis ein echter Dateiname übrigbleibt.
--   repeat
--     tmp = publisher.schrifttabelle[lookup]
--     if publisher.schrifttabelle[tmp] then
--       lookup = tmp
--     else
--       ende_erreicht = true
--     end
--   until ende_erreicht
-- end

-- Umbruch darf nach jedem Zeichen passieren, ohne dass ein
-- zusätzlicher Trennstrich eingefügt wird.
-- function umbreche_url( url )
--   return url:gsub("(.)","¬penalty-20¬¬%1")
-- end
-- 
-- function verbinde_inhalte( ret_von_dispatch,datenxml )
--   local text = ""
--   for i,j in ipairs(ret_von_dispatch) do
--     if type(j.inhalt) == "function" then
--       text = text .. tostring(j.inhalt({},datenxml))
--     elseif type(j.inhalt) == "string" then
--       text = text .. j.inhalt
--     end
--   end
--   return text
-- end

datei_ende("helper.lua")
