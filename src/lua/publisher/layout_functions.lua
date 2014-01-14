--
--  layout_funktionen.lua
--  speedata publisher
--
--  Copyright 2010-2013 Patrick Gundlach.
--  See file COPYING in the root directory for license info.


file_start("layout_functions.lua")

local luxor = do_luafile("luxor.lua")

local function aktuelle_seite(  )
  publisher.setup_page()
  return publisher.current_pagenumber
end

local function current_row(dataxml,arg)
  publisher.setup_page()
  return publisher.current_grid:current_row(arg and arg[1])
end

--- Get the page number of a marker
local function pagenumber(dataxml,arg)
  local m = publisher.markers[arg[1]]
  if m then
    return m.page
  else
    return nil
  end
end

local function current_column(dataxml,arg)
  publisher.setup_page()
  return publisher.current_grid:current_column(arg and arg[1])
end

local function alternating(dataxml, arg )
  local alt_type = arg[1]
  if not publisher.alternating[alt_type] then
    publisher.alternating[alt_type] = 1
  else
    publisher.alternating[alt_type] = math.fmod( publisher.alternating[alt_type], #arg - 1 ) + 1
  end
  return arg[publisher.alternating[alt_type] + 1]
end

local function reset_alternating( dataxml,arg )
  local alt_type = arg[1]
  publisher.alternating[alt_type] = 0
end

local function anzahl_datensaetze(dataxml,d)
  if not d then return 0 end
  local count = 0
  for i=1,#d do
    if type(d[i]) == 'table' then
      count = count + 1
    end
  end
  return count
end

local function number_of_columns(dataxml,arg)
  publisher.setup_page()
  return publisher.current_grid:number_of_columns(arg and arg[1])
end

--- Merge numbers like '1-5, 8, 9,10,11' into '1-5, 8-10'
-- Very simple implementation, not to be used in other cases than 1-3!
local function merge_pagenumbers(dataxml,arg )
  local a,b
  _,_, a, b = unicode.utf8.find(arg[1],"^(%d+).(%d+)$")
  local ret
  if a == b then
      ret = a
  else
      ret = arg[1]
  end
  return ret
end

local function anzahl_zeilen(dataxml,arg)
  publisher.setup_page()
  return publisher.current_grid:number_of_rows(arg and arg[1])
end

local function anzahl_seiten(dataxml,arg )
  local filename = arg[1]
  local img = publisher.imageinfo(filename)
  return img.img.pages
end

local function bildbreite(dataxml, arg )
  local filename = arg[1]
  local img = publisher.imageinfo(filename)
  publisher.setup_page()
  return publisher.current_grid:width_in_gridcells_sp(img.img.width)
end

local function datei_vorhanden(dataxml, arg )
  local filename = arg[1]
  if not filename then return false end
  if filename == "" then return false end
  if find_file_location(filename) then
    return true
  end
  return false
end

--- Insert 1000's separator and comma separator
local function format_number(dataxml,arg)
  local num, thousandssep,commasep = arg[1], arg[2], arg[3]
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


local function format_string( dataxml,arg )
  return string.format(arg[2],arg[1])
end


local function gerade(dataxml, arg )
  return math.fmod(arg[1],2) == 0
end

local function gruppenbreite(dataxml, arg )
  publisher.setup_page()
  local groupname=arg[1]
  local gruppeninhalt=publisher.groups[groupname].contents
  local raster = publisher.current_grid
  local breite = raster:width_in_gridcells_sp(gruppeninhalt.width)
  return breite
end

local function gruppenhoehe(dataxml, arg )
  publisher.setup_page()
  local groupname=arg[1]
  local gruppeninhalt=publisher.groups[groupname].contents
  local raster = publisher.current_grid
  local height = raster:height_in_gridcells_sp(gruppeninhalt.height)
  return height
end

local function ungerade(dataxml, arg )
  return math.fmod(arg[1],2) ~= 0
end

local function variable(dataxml, arg )
  local varname = table.concat(arg)
  local var = publisher.xpath.get_variable(varname)
  return var
end

local function variable_exists(dataxml,arg)
  local var = publisher.xpath.get_variable(arg[1])
  return var ~= nil
end


local function decode_html( dataxml, arg )
    arg = arg[1]
    local ok
    if type(arg) == "string" then
        ok,ret = pcall(luxor.parse_xml,"<dummy>" .. arg .. "</dummy>")
        if ok then
          return ret
        else
          err("decode-html failed for input string %q (1)",arg)
        end
        return arg
    end
  for i=1,#arg do
    for j=1,#arg[i] do
      local txt = arg[i][j]
      if type(txt) == "string" then
        if string.find(txt,"<") then
          local x = luxor.parse_xml(txt)
          arg[i][j] = x
        end
      end
    end
  end
  return arg
end

local function count_saved_paged(dataxml,arg)
    return #publisher.pagestore[arg[1]]
end

local register = publisher.xpath.register_function
register("urn:speedata:2009/publisher/functions/en","number-of-rows",anzahl_zeilen)
register("urn:speedata:2009/publisher/functions/de","anzahl-zeilen",anzahl_zeilen)

register("urn:speedata:2009/publisher/functions/en","number-of-columns",number_of_columns)
register("urn:speedata:2009/publisher/functions/de","anzahl-spalten",number_of_columns)

register("urn:speedata:2009/publisher/functions/en","number-of-pages",anzahl_seiten)
register("urn:speedata:2009/publisher/functions/de","anzahl-seiten",anzahl_seiten)

register("urn:speedata:2009/publisher/functions/en","current-page",aktuelle_seite)
register("urn:speedata:2009/publisher/functions/de","aktuelle-seite",aktuelle_seite)

register("urn:speedata:2009/publisher/functions/en","current-column",current_column)
register("urn:speedata:2009/publisher/functions/de","aktuelle-spalte",current_column)

register("urn:speedata:2009/publisher/functions/en","decode-html",decode_html)
register("urn:speedata:2009/publisher/functions/de","html-dekodieren",decode_html)

register("urn:speedata:2009/publisher/functions/en","file-exists",datei_vorhanden)
register("urn:speedata:2009/publisher/functions/de","datei-vorhanden",datei_vorhanden)

register("urn:speedata:2009/publisher/functions/en","number-of-datasets",anzahl_datensaetze)
register("urn:speedata:2009/publisher/functions/de","anzahl-datensätze",anzahl_datensaetze)
register("urn:speedata:2009/publisher/functions/de","anzahl-datensaetze",anzahl_datensaetze)

register("urn:speedata:2009/publisher/functions/en","even",gerade)
register("urn:speedata:2009/publisher/functions/de","gerade",gerade)

register("urn:speedata:2009/publisher/functions/en","odd",ungerade)
register("urn:speedata:2009/publisher/functions/de","ungerade",ungerade)

register("urn:speedata:2009/publisher/functions/en","pagenumber",pagenumber)
register("urn:speedata:2009/publisher/functions/de","seitennummer",pagenumber)

register("urn:speedata:2009/publisher/functions/en","variable",variable)
register("urn:speedata:2009/publisher/functions/de","variable",variable)

register("urn:speedata:2009/publisher/functions/en","variable-exists",variable_exists)
register("urn:speedata:2009/publisher/functions/de","variable-vorhanden",variable_exists)

register("urn:speedata:2009/publisher/functions/en","merge-pagenumbers",merge_pagenumbers)
register("urn:speedata:2009/publisher/functions/de","seitenzahlen-zusammenfassen",merge_pagenumbers)

register("urn:speedata:2009/publisher/functions/en","current-row",current_row)
register("urn:speedata:2009/publisher/functions/de","aktuelle-zeile",current_row)

register("urn:speedata:2009/publisher/functions/en","alternating",alternating)
register("urn:speedata:2009/publisher/functions/de","alternierend",alternating)

register("urn:speedata:2009/publisher/functions/en","group-height",gruppenhoehe)
register("urn:speedata:2009/publisher/functions/en","groupheight",gruppenhoehe)
register("urn:speedata:2009/publisher/functions/de","gruppenhöhe",gruppenhoehe)

register("urn:speedata:2009/publisher/functions/en","group-width",gruppenbreite)
register("urn:speedata:2009/publisher/functions/en","groupwidth",gruppenbreite)
register("urn:speedata:2009/publisher/functions/de","gruppenbreite",gruppenbreite)

register("urn:speedata:2009/publisher/functions/en","format-number",format_number)
register("urn:speedata:2009/publisher/functions/de","formatiere-zahl",format_number)

register("urn:speedata:2009/publisher/functions/en","format-string",format_string)
register("urn:speedata:2009/publisher/functions/de","formatiere-string",format_string)

register("urn:speedata:2009/publisher/functions/en","imagewidth",bildbreite)
register("urn:speedata:2009/publisher/functions/de","bildbreite",bildbreite)

register("urn:speedata:2009/publisher/functions/en","reset_alternating",reset_alternating)
register("urn:speedata:2009/publisher/functions/de","alternierend_zurücksetzen",reset_alternating)

register("urn:speedata:2009/publisher/functions/en","count-saved-pages",count_saved_paged)
register("urn:speedata:2009/publisher/functions/de","anzahl-gespeicherte-seiten",count_saved_paged)


file_end("layout_functions.lua")
