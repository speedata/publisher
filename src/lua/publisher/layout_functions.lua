--
--  layout_funktionen.lua
--  speedata publisher
--
--  Copyright 2010-2011 Patrick Gundlach.
--  See file COPYING in the root directory for license info.


file_start("layout_functions.lua")

module(...,package.seeall)

local function aktuelle_seite(  )
  publisher.setup_page()
  return  tex.count[0]
end

local function current_row(dataxml,...)
  publisher.setup_page()
  return publisher.current_grid:current_row(select(1,...))
end


local function current_column(dataxml,...)
  publisher.setup_page()
  return publisher.current_grid:aktuelle_spalte(select(1,...))
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
  publisher.setup_page()
  return publisher.current_grid:anzahl_spalten(select(1,...))
end

local function anzahl_zeilen(dataxml,...)
  publisher.setup_page()
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
  publisher.setup_page()
  return publisher.current_grid:breite_in_rasterzellen_sp(img.width)
end

local function datei_vorhanden(dataxml, ... )
  local dateiname=select(1,...)
  if kpse.find_file(dateiname) then
    return true
  end
  return false
end

function format_number( dataxml,arg1,arg2 )
  return string.format(arg2,arg1)
end


local function gerade(dataxml, arg )
  return math.fmod(arg,2) == 0
end

local function gruppenbreite(dataxml, ... )
  -- printtable("Gruppenbreite",{...})
  publisher.setup_page()
  local groupname=select(1,...)
  local gruppeninhalt=publisher.groups[groupname].contents
  local raster = publisher.current_grid
  local breite = raster:breite_in_rasterzellen_sp(gruppeninhalt.width)
  return breite
end

local function gruppenhoehe(dataxml, ... )
  -- printtable("Gruppenhöhe",{...})
  publisher.setup_page()
  local groupname=select(1,...)
  local gruppeninhalt=publisher.groups[groupname].contents
  local raster = publisher.current_grid
  local height = raster:hoehe_in_rasterzellen_sp(gruppeninhalt.height)
  return height
end

local function ungerade(dataxml, arg )
  return math.fmod(arg,2) ~= 0
end

local function variable(dataxml, arg )
  return publisher.variablen[arg]
end

file_end("layout_functions.lua")

return {
  de = {
    aktuelle_seite     = aktuelle_seite,
    aktuelle_zeile     = current_row,
    aktuelle_spalte    = current_column,
    alternierend       = alternierend,
    anzahl_datensaetze = anzahl_datensaetze,
    ["anzahl_datensätze"] = anzahl_datensaetze,
    anzahl_seiten      = anzahl_seiten,
    anzahl_spalten     = anzahl_spalten,
    anzahl_zeilen      = anzahl_zeilen,
    bildbreite         = bildbreite,
    datei_vorhanden    = datei_vorhanden,
    formatiere_zahl    = format_number,
    gerade             = gerade,
    gruppenbreite      = gruppenbreite,
    ["gruppenhöhe"]    = gruppenhoehe,
    variable           = variable,
    ungerade           = ungerade,
  },
  en = {
    alternating        = alternierend,
    current_page       = aktuelle_seite,
    current_row        = current_row,
    current_column     = current_column,
    even               = gerade,
    file_exists        = datei_vorhanden,
    groupheight        = gruppenhoehe,
    groupwidth         = gruppenbreite,
    format_number      = format_number,
    imagewidth         = bildbreite,
    number_of_columns  = anzahl_spalten,
    number_of_datasets = anzahl_datensaetze,
    number_of_pages    = anzahl_seiten,
    number_of_rows     = anzahl_zeilen,
    odd                = ungerade,
    variable           = variable,
  }
}
