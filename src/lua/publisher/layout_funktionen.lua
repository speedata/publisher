--
--  layout_funktionen.lua
--  speedata publisher
--
--  Created by Patrick Gundlach on 2010-03-27.
--  Copyright 2010 Patrick Gundlach. All rights reserved.
--
file_start("layout_funktionen.lua")

module(...,package.seeall)

local function aktuelle_seite(  )
  publisher.seite_einrichten()
  return  tex.count[0]
end

local function aktuelle_zeile(dataxml,...)
  publisher.seite_einrichten()
  return publisher.aktuelles_raster:aktuelle_zeile(select(1,...))
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
  return publisher.aktuelles_raster:anzahl_spalten(select(1,...))
end

local function anzahl_zeilen(dataxml,...)
  publisher.seite_einrichten()
  return publisher.aktuelles_raster:anzahl_zeilen(select(1,...))
end

local function anzahl_seiten( dataxml,... )
  dateiname=select(1,...)
  local img = publisher.bildinfo(dateiname)
  return img.pages
end

local function bildbreite(dataxml, ... )
  dateiname=select(1,...)
  local img = publisher.bildinfo(dateiname)
  publisher.seite_einrichten()
  return publisher.aktuelles_raster:breite_in_rasterzellen_sp(img.width)
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
  local gruppenname=select(1,...)
  local gruppeninhalt=publisher.gruppen[gruppenname].inhalt
  local raster = publisher.aktuelles_raster
  local breite = raster:breite_in_rasterzellen_sp(gruppeninhalt.width)
  return breite
end

local function gruppenhoehe(dataxml, ... )
  -- printtable("Gruppenhöhe",{...})
  publisher.seite_einrichten()
  local gruppenname=select(1,...)
  -- FIXME: Fehlermeldung, wenn Gruppe nicht gefunden
  -- printtable("publisher.gruppen[gruppenname]",publisher.gruppen[gruppenname])
  local _raster = publisher.gruppen[gruppenname].raster
  local _inhalt = publisher.gruppen[gruppenname].inhalt
  local hoehe = _raster:hoehe_in_rasterzellen_sp(_inhalt.height)
  return hoehe
end

local function ungerade(dataxml, arg )
  return math.fmod(arg,2) ~= 0
end

local function variable(dataxml, arg )
  return publisher.variablen[arg]
end

file_end("layout_funktionen.lua")

return {
  aktuelle_seite     = aktuelle_seite,
  aktuelle_zeile     = aktuelle_zeile,
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
