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

--- Get the page number of a marker
local function pagenumber(dataxml,...)
  local m = publisher.markers[select(1,...)]
  if m then
    return m.page
  else
    return nil
  end
end

local function current_column(dataxml,...)
  publisher.setup_page()
  return publisher.current_grid:current_column(select(1,...))
end

local function alternating(dataxml, ... )
  local alt_type = select(1,...)
  if not publisher.alternating[alt_type] then
    publisher.alternating[alt_type] = 1
  else
    publisher.alternating[alt_type] = math.fmod( publisher.alternating[alt_type], select("#",...) - 1 ) + 1
  end
  return select(publisher.alternating[alt_type] + 1 ,...)
end

local function reset_alternating( dataxml,... )
  local alt_type = select(1,...)
  publisher.alternating[alt_type] = 0
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

local function number_of_columns(dataxml,...)
  publisher.setup_page()
  return publisher.current_grid:number_of_columns(select(1,...))
end

--- Merge numbers like '1-5, 8, 9,10,11' into '1-5, 8-10'
-- Very simple implementation, not to be used in other cases than 1-3!
local function merge_pagenumbers(dataxml,arg )
  local a,b
  _,_, a, b = unicode.utf8.find(arg,"^(%d+).(%d+)$")
  if a == b then return a end
  return arg
end

local function anzahl_zeilen(dataxml,...)
  publisher.setup_page()
  return publisher.current_grid:number_of_rows(select(1,...))
end

local function anzahl_seiten( dataxml,... )
  dateiname=select(1,...)
  local img = publisher.imageinfo(dateiname)
  return img.img.pages
end

local function bildbreite(dataxml, ... )
  dateiname=select(1,...)
  local img = publisher.imageinfo(dateiname)
  publisher.setup_page()
  return publisher.current_grid:width_in_gridcells_sp(img.img.width)
end

local function datei_vorhanden(dataxml, ... )
  local dateiname=select(1,...)
  if find_file_location(dateiname) then
    return true
  end
  return false
end

--- Insert 1000's separator and comma separator
local function format_number(dataxml, num, thousandssep,commasep)
  local sign,digits,commadigits = string.match(tostring(num),"([%-%+]?)(%d*)%.?(%d*)")
  local first_digits = math.mod(#digits,3)
  local ret = {}
  if first_digits > 0 then
    ret[1] = string.sub(digits,0,first_digits)
  end
  for i=1, ( #digits - first_digits) / 3 do
    ret[#ret + 1] = string.sub(digits,first_digits + ( i - 1) * 3 + 1 ,first_digits + i * 3 )
  end
  ret = table.concat(ret, thousandssep)
  if commadigits and #commadigits > 0 then
    return  sign .. ret .. commasep .. commadigits
  else
    return sign .. ret
  end
end


local function format_string( dataxml,arg1,arg2 )
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
  local breite = raster:width_in_gridcells_sp(gruppeninhalt.width)
  return breite
end

local function gruppenhoehe(dataxml, ... )
  -- printtable("Gruppenhöhe",{...})
  publisher.setup_page()
  local groupname=select(1,...)
  local gruppeninhalt=publisher.groups[groupname].contents
  local raster = publisher.current_grid
  local height = raster:height_in_gridcells_sp(gruppeninhalt.height)
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
    alternierend       = alternating,
    ["alternierend_zurücksetzen"] = reset_alternating,
    anzahl_datensaetze = anzahl_datensaetze,
    ["anzahl_datensätze"] = anzahl_datensaetze,
    anzahl_seiten      = anzahl_seiten,
    anzahl_spalten     = number_of_columns,
    anzahl_zeilen      = anzahl_zeilen,
    bildbreite         = bildbreite,
    datei_vorhanden    = datei_vorhanden,
    formatiere_string  = format_string,
    formatiere_zahl    = format_number,
    gerade             = gerade,
    gruppenbreite      = gruppenbreite,
    ["gruppenhöhe"]    = gruppenhoehe,
    seitennummer       = pagenumber,
    seitenzahlen_zusammenfassen = merge_pagenumbers,
    variable           = variable,
    ungerade           = ungerade,
  },
  en = {
    alternating        = alternating,
    current_page       = aktuelle_seite,
    current_row        = current_row,
    current_column     = current_column,
    even               = gerade,
    file_exists        = datei_vorhanden,
    groupheight        = gruppenhoehe,
    groupwidth         = gruppenbreite,
    format_number      = format_number,
    format_string      = format_string,
    imagewidth         = bildbreite,
    number_of_columns  = number_of_columns,
    number_of_datasets = anzahl_datensaetze,
    number_of_pages    = anzahl_seiten,
    number_of_rows     = anzahl_zeilen,
    merge_pagenumbers  = merge_pagenumbers,
    odd                = ungerade,
    pagenumber         = pagenumber,
    reset_alternating  = reset_alternating,
    variable           = variable,
  }
}
