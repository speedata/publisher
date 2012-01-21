--
--  layout_funktionen.lua
--  speedata publisher
--
--  Copyright 2010-2011 Patrick Gundlach.
--  See file COPYING in the root directory for license info.


file_start("layout_functions.lua")

module(...,package.seeall)

local function aktuelle_seite(  )
  publisher.seite_einrichten()
  return  tex.count[0]
end

local function current_row(dataxml,...)
  publisher.seite_einrichten()
  return publisher.current_grid:current_row(select(1,...))
end

local function alternierend(dataxml, ... )
  if not publisher.alternierend then
    publisher.alternierend = 1
  else
    publisher.alternierend = math.fmod( publisher.alternierend, select("#",...) ) + 1
  end
  return select(publisher.alternierend,...)
end

local function anzahl_datensaetze(dataxml,d)
  local count = 0
  for i=1,#d do
    if type(d[i]) == 'table' then
      count = count + 1
    end
  end
  return count
end

local function anzahl_spalten(dataxml,...)
  publisher.seite_einrichten()
  return publisher.current_grid:anzahl_spalten(select(1,...))
end

local function anzahl_zeilen(dataxml,...)
  publisher.seite_einrichten()
  return publisher.current_grid:anzahl_zeilen(select(1,...))
end

local function anzahl_seiten( dataxml,... )
  dateiname=select(1,...)
  local img = publisher.imageinfo(dateiname)
  return img.pages
end

local function bildbreite(dataxml, ... )
  dateiname=select(1,...)
  local img = publisher.imageinfo(dateiname)
  publisher.seite_einrichten()
  return publisher.current_grid:breite_in_rasterzellen_sp(img.width)
end

local function datei_vorhanden(dataxml, ... )
  local dateiname=select(1,...)
  if kpse.find_file(dateiname) then
    return true
  end
  return false
end


local function gerade(dataxml, arg )
  return math.fmod(arg,2) == 0
end

local function gruppenbreite(dataxml, ... )
  -- printtable("Gruppenbreite",{...})
  publisher.seite_einrichten()
  local groupname=select(1,...)
  local gruppeninhalt=publisher.gruppen[groupname].inhalt
  local raster = publisher.current_grid
  local breite = raster:breite_in_rasterzellen_sp(gruppeninhalt.width)
  return breite
end

local function gruppenhoehe(dataxml, ... )
  -- printtable("Gruppenhöhe",{...})
  publisher.seite_einrichten()
  local groupname=select(1,...)
  -- FIXME: Fehlermeldung, wenn Gruppe nicht gefunden
  -- printtable("publisher.gruppen[groupname]",publisher.gruppen[groupname])
  local _raster = publisher.gruppen[groupname].raster
  local _inhalt = publisher.gruppen[groupname].inhalt
  local hoehe = _raster:hoehe_in_rasterzellen_sp(_inhalt.height)
  return hoehe
end

local function ungerade(dataxml, arg )
  return math.fmod(arg,2) ~= 0
end

local function variable(dataxml, arg )
  return publisher.variablen[arg]
end

file_end("layout_functions.lua")

return {
  aktuelle_seite     = aktuelle_seite,
  current_row     = current_row,
  alternierend       = alternierend,
  anzahl_datensaetze = anzahl_datensaetze,
  ["anzahl_datensätze"] = anzahl_datensaetze,
  anzahl_seiten      = anzahl_seiten,
  anzahl_spalten     = anzahl_spalten,
  anzahl_zeilen      = anzahl_zeilen,
  bildbreite         = bildbreite,
  datei_vorhanden    = datei_vorhanden,
  gerade             = gerade,
  gruppenbreite      = gruppenbreite,
  ["gruppenhöhe"]    = gruppenhoehe,
  variable           = variable,
  ungerade           = ungerade,
}
