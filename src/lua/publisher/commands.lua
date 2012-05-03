--
--  commands.lua
--  speedata publisher
--
--  Copyright 2010-2012 Patrick Gundlach.
--  See file COPYING in the root directory for license info.

file_start("commands.lua")
require("publisher.fonts")
require("publisher.tabular")
require("xpath")
require("fileutils")

-- Dieses Modul enthält die Einstiegspunkte der Layout-Tags.
module(...,package.seeall)

-- Setzt den Text im XML-Element "Absatz".
function absatz( layoutxml,dataxml )
  local textformat = publisher.read_attribute(layoutxml,dataxml,"textformat","string")
  local fontname   = publisher.read_attribute(layoutxml,dataxml,"fontface","string")

  local fontfamily
  if fontname then
    fontfamily = publisher.fonts.lookup_fontfamily_name_number[fontname]
    if fontfamily == nil then
      err("Fontfamily %q not found.",fontname)
      fontfamily = 0
    end
  else
    fontfamily = 0
  end

  -- local languagecode  = publisher.options.defaultlanguage or 0 -- not there yet
  local languagecode  = 0

  local sprache_de  = publisher.read_attribute(layoutxml,dataxml,"language","string")

  sprache_de_internal = {
     ["German"]                       = "de-1996",
     ["Englisch (Great Britan)"]      = "en-gb",
     ["French"]                       = "fr",
     }
  if sprache_de then
    languagecode = publisher.get_languagecode(sprache_de_internal[sprache_de])
  end

  local colorname = publisher.read_attribute(layoutxml,dataxml,"color","string")
  local colortable
  if colorname then
    if not publisher.colors[colorname] then
      error("Farbe %q ist nicht defniert.",colorname)
    else
      colortable = publisher.colors[colorname].index
    end
  end


  local a = publisher.Paragraph:new(textformat)
  local objects = {}
  local tab = publisher.dispatch(layoutxml,dataxml)

  for i,j in ipairs(tab) do
    trace("Paragraph Elementname = %q",tostring(publisher.elementname(j,true)))
    if publisher.elementname(j,true) == "Value" and type(publisher.element_contents(j)) == "table" then
      objects[#objects + 1] = publisher.parse_html(publisher.element_contents(j))
    else
      objects[#objects + 1] = publisher.element_contents(j)
    end
  end
  for _,j in ipairs(objects) do
    a:append(j,{schriftfamilie = fontfamily, languagecode = languagecode})
  end
  if #objects == 0 then
    -- nothing got through, why?? check
    warning("No contents found in paragraph.")
    a:append("",{schriftfamilie = fontfamily,languagecode = languagecode})
  end

  a:set_color(colortable)
  return a
end

-- Erzeugt ein 44er whatsit node (user_defined)
function aktion( layoutxml,dataxml)
  local tab = publisher.dispatch(layoutxml,dataxml)
  local ret = {}

  for _,j in ipairs(tab) do
    if publisher.elementname(j,true) == "AddToList" then
      local n = node.new("whatsit","user_defined")
      n.user_id = 1 -- a magic number
      n.type = 100 -- type 100: "value is a number"
      n.value = publisher.element_contents(j) -- Zeiger auf die Funktion (int)
      ret[#ret + 1] = n
    end
  end
  return ret
end

-- Erzeugt ein Attribut für die XML-Struktur
function attribut( layoutxml,dataxml )
  local auswahl = publisher.read_attribute(layoutxml,dataxml,"select","string")
  local attname  = publisher.read_attribute(layoutxml,dataxml,"name","string")
  local attvalue = xpath.textvalue(xpath.parse(dataxml,auswahl))
  local ret = { [".__type"]="attribute", [attname] = attvalue }
  return ret
end

function bearbeite_datensatz( layoutxml,dataxml )
  trace("BearbeiteDatensatz")
  local auswahl = publisher.read_attribute(layoutxml,dataxml,"select","string")
  local umfang  = publisher.read_attribute(layoutxml,dataxml,"limit","string")

  local datensatz = xpath.parse(dataxml,auswahl)
  local umfang
  if umfang then
    umfang = math.min(#datensatz,tonumber(umfang))
  else
    if datensatz then
      umfang = #datensatz or 0
    else
      umfang = 0
    end
  end

  for i=1,umfang do
    local eltname = datensatz[i]["inhalt"][".__name"]
    layoutknoten=publisher.data_dispatcher[""][eltname]
    log("Selecting node: %q",eltname or "???")
    publisher.variablen.__position = i
    publisher.dispatch(layoutknoten,publisher.element_contents(datensatz[i]))
  end
end

-- Ruft das Layoutxml für einen bestimmten Unterdatensatz (Element) auf.
function bearbeite_knoten(layoutxml,dataxml)
  local auswahl = publisher.read_attribute(layoutxml,dataxml,"select","string")

  local letzte_position = publisher.variablen.__position
  local modus = publisher.read_attribute(layoutxml,dataxml,"mode","string") or ""
  local layoutknoten = publisher.data_dispatcher[modus][auswahl]
  local pos = 1
  if type(layoutknoten)=="table" then
    for i,j in ipairs(dataxml) do
      if j[".__name"]==auswahl then
        log("Selecting node: %q, mode=%q, pos=%d",auswahl,modus, pos)
        publisher.variablen.__position = pos
        publisher.dispatch(layoutknoten,j)
        pos = pos + 1
      end
    end
  end
  publisher.variablen.__position = letzte_position
end

function beiseitenausgabe( layoutxml,dataxml )
  return layoutxml
end

function beiseitenerzeugung( layoutxml,dataxml )
  return layoutxml
end

local box_lookup = {
  ["artbox"]   = "art",
  ["cropbox"]  = "crop",
  ["trimbox"]  = "trim",
  ["mediabox"] = "media",
  ["bleedbox"] =  "bleed",
}

-- Erzeugt eine hbox mit einem Bild
function bild( layoutxml,dataxml )
  local width = publisher.read_attribute(layoutxml,dataxml,"width","string")
  local height  = publisher.read_attribute(layoutxml,dataxml,"height",  "string")

  local seite     = publisher.read_attribute(layoutxml,dataxml,"page","number")
  local nat_box   = publisher.read_attribute(layoutxml,dataxml,"naturalsize","string")
  local max_box   = publisher.read_attribute(layoutxml,dataxml,"maxsize","string")
  local filename = publisher.read_attribute(layoutxml,dataxml,"file","string")

  local nat_box_intern = box_lookup[nat_box] or "crop"
  local max_box_intern = box_lookup[max_box] or "crop"

  publisher.setup_page()

  local width_sp, height_sp
  if width and not tonumber(width) then
    -- width ist keine Zahl, sondern eine Maßangabe
    width_sp = tex.sp(width)
  else
    width_sp = width * publisher.current_grid.gridwidth
  end

  if height then
    if tonumber(height) then
      height_sp  = height * publisher.current_grid.gridheight
    else
      height_sp = tex.sp(height)
    end
  end
  local imageinfo = publisher.new_image(filename,seite,max_box_intern)
  local bild = img.copy(imageinfo.img)
  local allocate = imageinfo.allocate
  local skalierungsfaktor_wd = width_sp / bild.width
  local skalierungsfaktor = skalierungsfaktor_wd
  if height_sp then
    local skalierungsfaktor_ht = height_sp / bild.height
    skalierungsfaktor = math.min(skalierungsfaktor_ht,skalierungsfaktor_wd)
  end

  local shift_left,shift_up

  if nat_box_intern ~= max_box_intern then
    -- Das Bild muss vergrößert und dann nach links und oben verschoben werden
    local img_min = publisher.imageinfo(filename,seite,nat_box_intern).img
    shift_left = ( bild.width  - img_min.width )  / 2
    shift_up =   ( bild.height - img_min.height ) / 2
    skalierungsfaktor = skalierungsfaktor * ( bild.width / img_min.width )
  else
    shift_left,shift_up = 0,0
  end

  bild.width  = bild.width  * skalierungsfaktor
  bild.height = bild.height * skalierungsfaktor

  log("Load image %q with scaling %g",filename,skalierungsfaktor)
  local hbox = node.hpack(img.node(bild))
  node.set_attribute(hbox, publisher.att_shift_left, shift_left)
  node.set_attribute(hbox, publisher.att_shift_up  , shift_up  )
  return {hbox,allocate}
end

function box( layoutxml,dataxml )
  local width     = publisher.read_attribute(layoutxml,dataxml,"width","number")
  local height    = publisher.read_attribute(layoutxml,dataxml,"height","number")
  local hf_string = publisher.read_attribute(layoutxml,dataxml,"backgroundcolor","string")
  local bleed     = publisher.read_attribute(layoutxml,dataxml,"bleed","string")

  local current_grid = publisher.current_grid

  width  = current_grid.gridwidth  * width
  height = current_grid.gridheight * height

  local shift_left,shift_up = 0,0

  if bleed then
    local trim = publisher.options.trim
    local positions = string.explode(bleed,",")
    for i,v in ipairs(positions) do
      if v == "top" then
        height = height + trim
        shift_up = trim
      elseif v == "right" then
        width = width + trim
      elseif v == "bottom" then
        height = height + trim
      end
    end
  end

  local _width   = sp_to_bp(width)
  local _height  = sp_to_bp(height)
  local n = publisher.box(_width,_height,hf_string)
  n = node.hpack(n)
  node.set_attribute(n, publisher.att_shift_left, shift_left)
  node.set_attribute(n, publisher.att_shift_up  , shift_up )
  return n
end

-- create a PDF bookmark. Currently does not work
-- if in multi column text
function bookmark( layoutxml,dataxml )
  trace("Command: Bookmark")
  -- For bookmarks, we need two things: 1) a destination and
  -- 2) the bookmark itself that points to the destination. So
  -- we can safely insert the destination in our text flow but save
  -- the destination code (a number) for later. There is a slight problem
  -- now: as the text flow is asynchronous, we evaluate the bookmark
  -- during page shipout. Then we have the correct order (hopefully)
  local title  = publisher.read_attribute(layoutxml,dataxml,"select","xpath")
  local level  = publisher.read_attribute(layoutxml,dataxml,"level", "number")
  local open_p = publisher.read_attribute(layoutxml,dataxml,"open",  "boolean")

  local hlist = publisher.mkbookmarknodes(level,open_p,title)
  local p = publisher.Paragraph:new()
  p:append(hlist)
  return p
end

-- Anweisung im Layoutxml, dass für ein bestimmtes Element diese
-- Layoutregel aufgerufen werden soll.
function datensatz( layoutxml )
  local elementname = publisher.read_attribute(layoutxml,dataxml,"element","string")
  local mode        = publisher.read_attribute(layoutxml,dataxml,"mode","string")

  mode = mode or ""
  publisher.data_dispatcher[mode] = publisher.data_dispatcher[mode] or {}
  publisher.data_dispatcher[mode][elementname] = layoutxml
end

-- First function to be called when starting the data processing
function start_data_processing(dataxml)
  local tmp
  local name = dataxml[".__name"]
  tmp = publisher.data_dispatcher[""][name] -- default-Modus
  if tmp then publisher.dispatch(tmp,dataxml) end
end

-- Definiert eine Farbe
function definiere_farbe( layoutxml,dataxml )
  local name  = publisher.read_attribute(layoutxml,dataxml,"name","string")
  local model = publisher.read_attribute(layoutxml,dataxml,"model","string")

  log("Defining color %q",name)
  local color = { modell = model }

  if model=="cmyk" then
    color.c = publisher.read_attribute(layoutxml,dataxml,"c","number")
    color.m = publisher.read_attribute(layoutxml,dataxml,"m","number")
    color.y = publisher.read_attribute(layoutxml,dataxml,"y","number")
    color.k = publisher.read_attribute(layoutxml,dataxml,"k","number")
    color.pdfstring = string.format("%g %g %g %g k %g %g %g %g K", color.c/100, color.m/100, color.y/100, color.k/100,color.c/100, color.m/100, color.y/100, color.k/100)
  elseif model=="rgb" then
    color.r = publisher.read_attribute(layoutxml,dataxml,"r","number")
    color.g = publisher.read_attribute(layoutxml,dataxml,"g","number")
    color.b = publisher.read_attribute(layoutxml,dataxml,"b","number")
    color.pdfstring = string.format("%g %g %g rg %g %g %g RG", color.r/100, color.g/100, color.b/100, color.r/100,color.g/100, color.b/100)
  else
    err("Unknown color model: %s",model or "?")
  end
  publisher.colortable[#publisher.colortable + 1] = name
  color.index = #publisher.colortable
  publisher.colors[name]=color
end

-- Define a textformat
function definiere_textformat(layoutxml)
  trace("Command: DefineTextformat")
  local alignment   = publisher.read_attribute(layoutxml,dataxml,"alignment",   "string")
  local indentation = publisher.read_attribute(layoutxml,dataxml,"indentation", "length")
  local name        = publisher.read_attribute(layoutxml,dataxml,"name",        "string")
  local rows        = publisher.read_attribute(layoutxml,dataxml,"rows",        "number")

  local fmt = {}

  if alignment == "leftaligned" or alignment == "rightaligned" or alignment == "centered" then
    fmt.alignment = alignment
  else
    fmt.alignment = "justified"
  end

  if indentation then
    fmt.indent = tex.sp(indentation)
  end
  if rows then
    fmt.rows = rows
  else
    fmt.rows = 1
  end

  publisher.textformats[name] = fmt
end

-- Definiert eine Schriftfamilie
function definiere_schriftfamilie( layoutxml,dataxml )
  local fonts = publisher.fonts
  local fam={}
  -- fontsize and baselineskip are in dtp points (bp, 1 bp ≈ 65782 sp)
  -- Concrete font instances are created here. fontsize and baselineskip are known
  local name        = publisher.read_attribute(layoutxml,dataxml,"name",   "string" )
  fam.size          = publisher.read_attribute(layoutxml,dataxml,"fontsize","number")  * 65782
  fam.baselineskip  = publisher.read_attribute(layoutxml,dataxml,"leading", "number") * 65782
  fam.scriptsize    = fam.size * 0.8 -- subscript / superscript
  fam.scriptshift   = fam.size * 0.3

  if not fam.size then
    err("DefineFontfamily: no size given.")
    return
  end
  local ok,tmp,elementname,fontface
  for i,v in ipairs(layoutxml) do
    elementname = publisher.translate_element(v[".__name"])
    fontface    = publisher.read_attribute(v,dataxml,"fontface","string")
    if type(v) ~= "table" then
     -- ignorieren
    elseif elementname=="Regular" then
      ok,tmp=fonts.erzeuge_fontinstanz(fontface,fam.size)
      if ok then
        fam.normal = tmp
      else
        fam.normal = 1
        err("Fontinstance 'normal' could not be created for %q.",tostring(v.schriftart))
      end
      ok,tmp=fonts.erzeuge_fontinstanz(fontface,fam.scriptsize)
      if ok then
        fam.normalscript = tmp
      end
    elseif elementname=="Bold" then
      ok,tmp=fonts.erzeuge_fontinstanz(fontface,fam.size)
      if ok then
        fam.fett = tmp
      end
      ok,tmp=fonts.erzeuge_fontinstanz(fontface,fam.scriptsize)
      if ok then
        fam.fettscript = tmp
      end
    elseif elementname =="Italic" then
      ok,tmp=fonts.erzeuge_fontinstanz(fontface,fam.size)
      if ok then
        fam.kursiv = tmp
      end
      ok,tmp=fonts.erzeuge_fontinstanz(fontface,fam.scriptsize)
      if ok then
        fam.kursivscript = tmp
      end
    elseif elementname =="BoldItalic" then
      ok,tmp=fonts.erzeuge_fontinstanz(fontface,fam.size)
      if ok then
        fam.fettkursiv = tmp
      end
      ok,tmp=fonts.erzeuge_fontinstanz(fontface,fam.scriptsize)
      if ok then
        fam.fettkursivscript = tmp
      end
    end
    if type(v) == "table" and not ok then
      err("Error creating font instance %q: %s", elementname or "??", tmp or "??")
    end
  end
  fonts.lookup_fontfamily_number_instance[#fonts.lookup_fontfamily_number_instance + 1] = fam
  fonts.lookup_fontfamily_name_number[name]=#fonts.lookup_fontfamily_number_instance
  log("DefineFontfamily, family=%d, name=%q",#fonts.lookup_fontfamily_number_instance,name)
end

-- Create an element for use with attribute and savedataset
function element( layoutxml,dataxml )
  local elementname = publisher.read_attribute(layoutxml,dataxml,"name","string")

  local ret = { [".__name"] = elementname }

  local tab = publisher.dispatch(layoutxml,dataxml)
  for i,v in ipairs(tab) do
    local contents = publisher.element_contents(v)
    if contents[".__type"]=="attribute" then
      -- Attribut
      for _k,_v in pairs(contents) do
        if _k ~= ".__type" then
          ret[_k] = _v
        end
      end
    else
      ret[#ret + 1] = contents
    end
  end

  return ret
end

-- case / switch
function fallunterscheidung( layoutxml,dataxml )
  local case_matched = false
  local otherwise,ret,elementname
  for i,v in ipairs(layoutxml) do
    elementname = publisher.translate_element(v[".__name"])
    if type(v)=="table" and elementname=="Case" and case_matched ~= true then
      local fall = v
      assert(fall.bedingung)
      if xpath.parse(dataxml,fall.bedingung) then
        case_matched = true
        ret = publisher.dispatch(fall,dataxml)
      end
    elseif type(v)=="table" and elementname=="Otherwise" then
      otherwise = v
    end -- fall/otherwise
  end
  if otherwise and case_matched==false then
    ret = publisher.dispatch(otherwise,dataxml)
  end
  if not ret then return {} end
  return ret
end

-- Bold text
function fett( layoutxml,dataxml )
  local a = publisher.Paragraph:new()

  local objects = {}
  local tab = publisher.dispatch(layoutxml,dataxml)

  for i,j in ipairs(tab) do
    if publisher.elementname(j,true) == "Value" and type(publisher.element_contents(j)) == "table" then
      objects[#objects + 1] = publisher.parse_html(publisher.element_contents(j))
    else
      objects[#objects + 1] = publisher.element_contents(j)
    end
  end
  for _,j in ipairs(objects) do
    a:append(j,{schriftfamilie = 0, fett = 1})
  end

  return a
end

-- Create a virtual area
function gruppe( layoutxml,dataxml )
  publisher.setup_page()
  local groupname = publisher.read_attribute(layoutxml,dataxml,"name", "string")

  if publisher.groups[groupname] == nil then
    log("Create »Gruppe« %q.",groupname)
  else
    node.flush_list(publisher.groups[groupname].contents)
    publisher.groups[groupname] = nil
  end

  local r = publisher.grid:new()
  r:setze_rand(0,0,0,0)
  r:setze_breite_hoehe(publisher.current_page.raster.gridwidth,publisher.current_page.raster.gridheight)
  publisher.groups[groupname] = {
    contents = contents,
    grid     = r,
  }

  local save_grid      = publisher.current_grid
  local save_groupname = publisher.current_group

  publisher.current_group = groupname
  publisher.current_grid  = r
  local elementname

  for _,v in ipairs(layoutxml) do
    elementname=publisher.translate_element(v[".__name"])
    if type(v)=="table" and elementname=="Contents" then
      publisher.dispatch(v,dataxml)
    end
  end

  publisher.current_group  = save_groupname
  publisher.current_grid = save_grid
end

-- Dummy-Element fürs Einbinden von xi:include-Dateien
function include( layoutxml,dataxml )
  return publisher.dispatch(layoutxml,dataxml)
end

-- Italic text
function kursiv( layoutxml,dataxml )
  trace("Italic")
  local a = publisher.Paragraph:new()
  local objects = {}
  local tab = publisher.dispatch(layoutxml,dataxml)
  for i,j in ipairs(tab) do
    if publisher.elementname(j,true) == "Value" and type(publisher.element_contents(j)) == "table" then
      objects[#objects + 1] = publisher.parse_html(publisher.element_contents(j))
    else
      objects[#objects + 1] = publisher.element_contents(j)
    end
  end
  for _,j in ipairs(objects) do
    a:append(j,{schriftfamilie = 0, kursiv = 1})
  end
  return a
end

-- XPath Ausdruck um einen Wert aus den Daten zu extrahieren. Gibt eine Sequenz zurück
function kopie_von( layoutxml,dataxml )
  local auswahl = publisher.read_attribute(layoutxml,dataxml,"select", "string")

  if layoutxml[1] and #layoutxml[1] > 0 then
    return table.concat(layoutxml)
  else
    auswahl = xpath.parse(dataxml,auswahl)
    trace("Kopie-von: type(auswahl)=%q",type(auswahl))
    return auswahl
  end
end

-- Lädt eine Schriftdatei
function lade_schriftdatei( layoutxml,dataxml )
  local randausgleich = publisher.read_attribute(layoutxml,dataxml,"marginprotrusion","number")
  local leerraum      = publisher.read_attribute(layoutxml,dataxml,"space","number")
  local smcp          = publisher.read_attribute(layoutxml,dataxml,"smallcaps","string")
  local filename = publisher.read_attribute(layoutxml,dataxml,"filename","string")
  local name     = publisher.read_attribute(layoutxml,dataxml,"name","string")

  local extra_parameter = {
    leerraum      = leerraum      or 25,
    randausgleich = randausgleich or 0,
    otfeatures    = {
      smcp = smcp == "ja",
    },
  }
  log("filename = %q",filename or "?")
  publisher.fonts.load_fontfile(name,filename,extra_parameter)
end

-- Lädt eine Datensatzdatei (XML) und startet die Verarbeitung
function lade_datensatzdatei( layoutxml,dataxml )
  local name = publisher.read_attribute(layoutxml,dataxml,"name", "string")
  assert(name)
  local filename = "datensatzdatei." .. name

  if fileutils.test("x",filename)==false then
    -- at the first run, the file does not exist. That's ok
    return
  end

  local tmp_data = publisher.load_xml(filename)
  local root_name = tmp_data[".__name"]

  log("Selecting node: %q, mode=%q",root_name,"")
  publisher.dispatch(publisher.data_dispatcher[""][root_name],tmp_data)
end

function leerzeile( layoutxml,dataxml )
  trace("Leerzeile, aktuelle Zeile = %d",publisher.current_grid:current_row())
  local areaname = publisher.read_attribute(layoutxml,dataxml,"area","string")
  local areaname = areaname or publisher.default_areaname
  local current_grid = publisher.current_grid
  local current_row = current_grid:finde_passende_zeile(1,current_grid:anzahl_spalten(),1,areaname)
  if not current_row then
    current_grid:set_current_row(1)
  else
    current_grid:set_current_row(current_row + 1)
  end
end

function linie( layoutxml,dataxml )
  local direction     = publisher.read_attribute(layoutxml,dataxml,"direction",  "string")
  local length        = publisher.read_attribute(layoutxml,dataxml,"length",     "string")
  local rulewidth     = publisher.read_attribute(layoutxml,dataxml,"rulewidth",  "string")
  local color         = publisher.read_attribute(layoutxml,dataxml,"color",  "string")

  local colorname = color or "Schwarz"

  if tonumber(length) then
    if direction == "horizontal" then
      length = publisher.current_grid.gridwidth * length
    -- FIXME: vertical / vertikal should be handled in publisher.read_attribute()
    elseif direction == "vertical" or direction == "vertikal" then
      length = publisher.current_grid.gridheight * length
    else
      err("Attribute »direction« with »Linie«: unknown direction: %q",direction)
    end
  else
    length = tex.sp(length)
  end
  length = sp_to_bp(length)

  rulewidth = rulewidth or "1pt"
  if tonumber(rulewidth) then
    if direction == "horizontal" then
      rulewidth = publisher.current_grid.gridwidth * rulewidth
    elseif direction == "vertical" or direction == "vertikal" then
      rulewidth = publisher.current_grid.gridheight * rulewidth
    end
  else
    rulewidth = tex.sp(rulewidth)
  end
  rulewidth = sp_to_bp(rulewidth)


  local n = node.new("whatsit","pdf_literal")
  n.mode = 0
  if direction == "horizontal" then
    n.data = string.format("q %d w %s 0 0 m %g 0 l S Q",rulewidth,publisher.colors[colorname].pdfstring,length)
  elseif direction == "vertikal" or direction == "vertikal" then
    n.data = string.format("q %d w %s 0 0 m 0 %g l S Q",rulewidth,publisher.colors[colorname].pdfstring,-length)
  else
    --
  end
  n = node.hpack(n)
  return n
end

-- Schreibt eine Meldung in Terminal
function nachricht( layoutxml, dataxml )
  local contents
  local auswahl = publisher.read_attribute(layoutxml,dataxml,"select","string")

  if auswahl then
    contents = xpath.parse(dataxml,auswahl)
  else
    local tab = publisher.dispatch(layoutxml,dataxml)
    contents = tab
  end
  if type(contents)=="table" then
    local ret
    for i=1,#contents do
      local eltname = publisher.elementname(contents[i],true)
      local contents = publisher.element_contents(contents[i])

      if eltname == "Sequence" or eltname == "Value" then
        if type(contents) == "table" then
          ret = ret or {}
          if getmetatable(ret) == nil then
            setmetatable(ret,{ __concat = table.__concat })
          end
          ret = ret .. contents
        elseif type(contents) == "string" then
          ret = ret or ""
          ret = ret .. contents
        elseif type(contents) == "number" then
          ret = ret or ""
          ret = ret .. tostring(contents)
        elseif type(contents) == "nil" then
          -- ignorieren
        else
          err("Unknown type: %q",type(contents))
          ret = nil
        end
      end
    end
    if ret then
      contents = ret
    end
  end
  log("Message: %q", tostring(contents) or "?")
end

function naechster_rahmen( layoutxml,dataxml )
  local areaname = publisher.read_attribute(layoutxml,dataxml,"area","string")
  publisher.next_area(areaname)
end

function neue_zeile( layoutxml,dataxml )
  publisher.setup_page()
  local rownumber = publisher.read_attribute(layoutxml,dataxml,"row", "number")
  local areaname  = publisher.read_attribute(layoutxml,dataxml,"area","string")
  local rows      = publisher.read_attribute(layoutxml,dataxml,"rows","number")
  rows = rows or 1
  local areaname = areaname or publisher.default_areaname
  local grid = publisher.current_grid

  if rownumber then
    grid:set_current_row(rownumber)
    return
  end

  local current_row
  current_row = grid:finde_passende_zeile(1,grid:anzahl_spalten(),rows,areaname)
  if not current_row then
    publisher.next_area(areaname)
    publisher.setup_page()
    grid = publisher.current_page.raster
    grid:set_current_row(1)
  else
    grid:set_current_row(current_row + rows - 1,areaname)
    grid:setze_aktuelle_spalte(1,areaname)
  end
end

-- Erzeugt eine neue Seite
function neue_seite( )
  publisher.neue_seite()
end

-- Formatiert die angegebene URL etwas besser für den Satz.
function url(layoutxml,dataxml)
  local a = publisher.Paragraph:new()
  local tab = publisher.dispatch(layoutxml,dataxml)
  for i,j in ipairs(tab) do
    a:append(xpath.textvalue(publisher.element_contents(j)),{})
    a.nodelist = publisher.umbreche_url(a.nodelist)
  end
  return a
end

-- Gibt ein rechteckiges Objekt (derzeit nur Bild) aus
function objekt_ausgeben( layoutxml,dataxml )
  trace("Command: PlaceObject")
  local absolute_positioning = false
  local spalte           = publisher.read_attribute(layoutxml,dataxml,"column",         "string")
  local zeile            = publisher.read_attribute(layoutxml,dataxml,"row",            "string")
  local bereich          = publisher.read_attribute(layoutxml,dataxml,"area",           "string")
  local belegen          = publisher.read_attribute(layoutxml,dataxml,"allocate",       "string", "yes")
  local rahmenfarbe      = publisher.read_attribute(layoutxml,dataxml,"framecolor",     "string")
  local hintergrundfarbe = publisher.read_attribute(layoutxml,dataxml,"backgroundcolor","string")
  local maxhoehe         = publisher.read_attribute(layoutxml,dataxml,"maxheight",      "number")
  local rahmen           = publisher.read_attribute(layoutxml,dataxml,"frame",          "string")
  local hintergrund      = publisher.read_attribute(layoutxml,dataxml,"background",     "string")
  local groupname        = publisher.read_attribute(layoutxml,dataxml,"groupname",      "string")
  local valign           = publisher.read_attribute(layoutxml,dataxml,"valign",         "string")
  local hreference       = publisher.read_attribute(layoutxml,dataxml,"hreference",     "string")

  bereich = bereich or publisher.default_areaname

  if spalte and not tonumber(spalte) then
    -- spalte scheint ein String zu sein
    absolute_positioning = true
    spalte = tex.sp(spalte)
  end
  if zeile and not tonumber(zeile) then
    -- zeile scheint ein String zu sein
    absolute_positioning = true
    zeile = tex.sp(zeile)
  end

  if absolute_positioning then
    if not ( zeile and spalte ) then
      err("»Spalte« and »Zeile« must be given with absolute positioning (»ObjektAusgeben«).")
      return
    end
  end

  publisher.setup_page()

  trace("Spalte = %q",tostring(spalte))
  trace("Zeile = %q",tostring(zeile))

  local current_row_start  = publisher.current_grid:current_row(bereich)
  local aktuelle_spalte_start = spalte or publisher.current_grid:aktuelle_spalte(bereich)

  -- Die Höhe auf dieser Seite ist entweder das Minimum von verbleibende Platz oder maxhöhe
  local max_ht_aktuell =  math.min(publisher.current_grid:anzahl_zeilen(bereich) - ( zeile or publisher.current_grid:current_row(bereich) ) + 1, maxhoehe or publisher.current_grid:anzahl_zeilen(bereich))
  local optionen = {
    ht_aktuell = publisher.current_grid.gridheight * max_ht_aktuell,
    ht_max     = publisher.current_grid.gridheight * ( maxhoehe or publisher.current_grid:anzahl_zeilen(bereich) ),
  }

  local raster = publisher.current_grid
  local tab    = publisher.dispatch(layoutxml,dataxml,optionen)

  local objects = {}
  local object, objecttype

  if groupname then
    objects[1] = { object = node.copy(publisher.groups[groupname].contents),
      objecttype = string.format("Gruppe (%s)", groupname)}
  else
    for i,j in ipairs(tab) do
      object = publisher.element_contents(j)
      objecttype = publisher.elementname(j,true)
      if objecttype == "Image" then
        -- return value is a table, #1 is the image, #2 is the allocation grid
        objects[#objects + 1] = {object = object[1], objecttype = objecttype, allocate_matrix = object[2] }
      else
        if type(object)=="table" then
          for i=1,#object do
            objects[#objects + 1] = {object = object[i], objecttype = objecttype }
          end
        else
          objects[#objects + 1] = {object = object, objecttype = objecttype }
        end
      end
    end
  end
  for i=1,#objects do
    raster = publisher.current_grid
    object    = objects[i].object
    objecttype = objects[i].objecttype

    if hintergrund == "full" then
      object = publisher.hintergrund(object,hintergrundfarbe)
    end
    if rahmen == "solid" then
      object = publisher.rahmen(object,rahmenfarbe)
    end

    if publisher.options.trace then
      publisher.boxit(object)
    end

    local breite_in_rasterzellen = raster:breite_in_rasterzellen_sp(object.width)
    local hoehe_in_rasterzellen  = raster:hoehe_in_rasterzellen_sp (object.height + object.depth)


    if absolute_positioning then
      if hreference == "right" then
        spalte = spalte - breite_in_rasterzellen + 1
      end
      publisher.ausgabe_bei_absolut(object,spalte + raster.extra_rand,zeile + raster.extra_rand,belegen,objects[i].allocate_matrix)
    else
      -- Look for a place for the object
      -- local current_row = raster:current_row(bereich)
      trace("PlaceObject: Breitenberechnung")
      if not node.has_field(object,"width") then
        warning("Can't calculate with object's width!")
      end
      trace("PlaceObject: Breitenberechnung abgeschlossen: wd=%d,ht=%d",breite_in_rasterzellen,hoehe_in_rasterzellen)

      trace("PlaceObject: finde passende Zeile für das object, current_row = %d",zeile or raster:current_row(bereich) or "-1")
      if zeile then
        current_row = zeile
      else
        current_row = nil
      end

      -- While (not found a free area) switch to next frame
      while current_row == nil do
        if not spalte then
          -- Keine Zeile und keine Spalte angegeben. Dann suche ich mir doch die richtigen Werte selbst.
          if aktuelle_spalte_start + breite_in_rasterzellen - 1 > raster:anzahl_spalten() then
            aktuelle_spalte_start = 1
          end
        end
        -- This is not correct! Todo: fixme!
        if publisher.current_group then
          current_row = 1
        else
          -- the current grid is different when in a group
          current_row = raster:finde_passende_zeile(aktuelle_spalte_start,breite_in_rasterzellen,hoehe_in_rasterzellen,bereich)
          if not current_row then
            warning("No suitable row found for object")
            publisher.next_area(bereich)
            publisher.setup_page()
            raster = publisher.current_grid
            current_row = publisher.current_grid:current_row(bereich)
          end
        end
      end

      log("PlaceObject: %s in row %d and column %d, width=%d, height=%d", objecttype, current_row, aktuelle_spalte_start,breite_in_rasterzellen,hoehe_in_rasterzellen)
      trace("PlaceObject: object placed at (%d,%d)",aktuelle_spalte_start,current_row)
      if hreference == "right" then
        aktuelle_spalte_start = aktuelle_spalte_start - breite_in_rasterzellen + 1
      end
      publisher.ausgabe_bei(object,aktuelle_spalte_start,current_row,belegen,bereich,valign,objects[i].allocate_matrix)
      trace("object ausgegeben.")
      zeile = nil -- die Zeile ist nicht mehr gültig, da schon ein object ausgegeben wurde
      if i < #objects then
        neue_zeile(layoutxml,dataxml)
      end
    end -- keine absolute Positionierung
  end
  if not belegen then
    publisher.current_grid:set_current_row(current_row_start)
  end
  trace("objects ausgegeben.")
end

-- Saves the options given in the layout file
function optionen( layoutxml,dataxml )
  publisher.options.cutmarks           = publisher.read_attribute(layoutxml,dataxml,"cutmarks",    "boolean")
  publisher.options.runs               = publisher.read_attribute(layoutxml,dataxml,"runs",        "number")
  publisher.options.showgrid           = publisher.read_attribute(layoutxml,dataxml,"show-grid",   "boolean")
  publisher.options.showgridallocation = publisher.read_attribute(layoutxml,dataxml,"show-gridallocation","boolean")
  publisher.options.showhyphenation    = publisher.read_attribute(layoutxml,dataxml,"show-hyphenation","boolean")
  publisher.options.startpage          = publisher.read_attribute(layoutxml,dataxml,"startpage",   "number")
  publisher.options.trace              = publisher.read_attribute(layoutxml,dataxml,"trace",       "boolean")
  publisher.options.trim               = publisher.read_attribute(layoutxml,dataxml,"trim",        "length")
  if publisher.options.trim then
    publisher.options.trim = tex.sp(publisher.options.trim)
  end
end

function platzierungsrahmen( layoutxml, dataxml )
  local column = publisher.read_attribute(layoutxml,dataxml,"column","number")
  local row    = publisher.read_attribute(layoutxml,dataxml,"row" ,"number")
  local width  = publisher.read_attribute(layoutxml,dataxml,"width","number")
  local height = publisher.read_attribute(layoutxml,dataxml,"height"  ,"number")
  return {
    spalte = column,
    zeile  = row,
    breite = width,
    hoehe  = height
    }
end

-- Contains one or more positioning frames
function platzierungsbereich( layoutxml,dataxml )
  -- Warning: if we call publisher.dispatch now, the xpath functions might depend on values on the _current_ page, which is not set!
  local tab = {}
  tab.layoutxml = layoutxml
  local name = publisher.read_attribute(layoutxml,dataxml,"name","string")
  tab.name = name
  return tab
end

-- Setzt das Papierformat.
function seitenformat(layoutxml)
  trace("Pageformat")
  local width  = publisher.read_attribute(layoutxml,dataxml,"width","length")
  local height = publisher.read_attribute(layoutxml,dataxml,"height","length")
  publisher.set_pageformat(tex.sp(width),tex.sp(height))
end

-- Setzt den Rand für diese Seite
function rand( layoutxml,dataxml )
  local left   = publisher.read_attribute(layoutxml,dataxml,"left", "length")
  local right  = publisher.read_attribute(layoutxml,dataxml,"right","length")
  local top    = publisher.read_attribute(layoutxml,dataxml,"top",  "length")
  local bottom = publisher.read_attribute(layoutxml,dataxml,"bottom", "length")

  return function(_seite) _seite.raster:setze_rand(left,top,right,bottom) end
end

function raster( layoutxml,dataxml )
  local breite = publisher.read_attribute(layoutxml,dataxml,"width","length")
  local hoehe  = publisher.read_attribute(layoutxml,dataxml,"height"  ,"length")
  return { breite = tex.sp(breite), hoehe = tex.sp(hoehe) }
end

function schriftart( layoutxml,dataxml )
  local fontfamily   = publisher.read_attribute(layoutxml,dataxml,"fontfamily","string")
  local familynumber = publisher.fonts.lookup_fontfamily_name_number[fontfamily]
  if not familynumber then
    err("font: family %q unknown",fontfamily)
  else
    local a = publisher.Paragraph:new()
    local tab = publisher.dispatch(layoutxml,dataxml)
    for i,j in ipairs(tab) do
      a:append(publisher.element_contents(j),{schriftfamilie = familynumber})
    end
    return a
  end
end

-- Remember (internally) the grid size (`width` und `height` in layout xml).
function setze_raster(layoutxml)
  trace("Command: SetGrid")
  publisher.options.gridwidth   = tex.sp(publisher.read_attribute(layoutxml,dataxml,"width","length"))
  publisher.options.gridheight  = tex.sp(publisher.read_attribute(layoutxml,dataxml,"height","length"))
end

-- Create a list of page types in publisher.masterpages
function seitentyp(layoutxml,dataxml)
  trace("Command: Pagetype")
  local tmp_tab = {}
  local test         = publisher.read_attribute(layoutxml,dataxml,"test","string")
  local pagetypename = publisher.read_attribute(layoutxml,dataxml,"name","string")
  local tab = publisher.dispatch(layoutxml,dataxml)

  for i,j in ipairs(tab) do
    local eltname = publisher.elementname(j,true)
    if eltname=="Margin" or eltname == "AtPageShipout" or eltname == "AtPageCreation" or eltname=="Grid" or eltname=="PositioningArea" then
      tmp_tab [#tmp_tab + 1] = j
    else
      err("Element %q in »Seitentyp« unknown",tostring(eltname))
      tmp_tab [#tmp_tab + 1] = j
    end
  end
  -- assert(type(test())=="boolean")
  publisher.masterpages[#publisher.masterpages + 1] = { ist_seitentyp = test, res = tmp_tab, name = pagetypename }
end

function sequenz( layoutxml,dataxml )
  local auswahl = publisher.read_attribute(layoutxml,dataxml,"select","string")
  trace("Command: Sequence: %s, auswahl = %s",layoutxml[".__name"], auswahl )
  local ret = {}
  for i,v in ipairs(dataxml) do
    if type(v)=="table" and v[".__name"] == auswahl then
      ret[#ret + 1] = v
    end
  end
  return ret
end

function solange( layoutxml,dataxml )
  local test = publisher.read_attribute(layoutxml,dataxml,"test","string")
  assert(test)

  while xpath.parse(dataxml,test) do
    publisher.dispatch(layoutxml,dataxml)
  end
end

-- Verändert die Reihenfolge in der Variable!
function sortiere_sequenz( layoutxml,dataxml )
  local auswahl             = publisher.read_attribute(layoutxml,dataxml,"select","string")
  local duplikate_entfernen = publisher.read_attribute(layoutxml,dataxml,"removeduplicates","string")
  local criterium           = publisher.read_attribute(layoutxml,dataxml,"criterium","string")

  local sequenz = xpath.parse(dataxml,auswahl)
  trace("SortiereSequenz: Datensatz = %q, Kriterium = %q",auswahl,criterium or "???")
  local sortkey = criterium
  local tmp = {}
  for i,v in ipairs(sequenz) do
    tmp[i] = sequenz[i]
  end

  table.sort(tmp, function(a,b) return a[sortkey]  < b[sortkey] end)
  if duplikate_entfernen then
    local ret = {}
    local deleteme = {}
    local letzter_eintrag = {}
    for i,v in ipairs(tmp) do
      local contents = publisher.element_contents(v)
      if contents[duplikate_entfernen] == letzter_eintrag[duplikate_entfernen] then
        deleteme[#deleteme + 1] = i
      end
      letzter_eintrag = contents
    end

    for i=#deleteme,1,-1 do
      -- backwards, otherwise the indexes would be mangled
      table.remove(tmp,deleteme[i])
    end
  end
  return tmp
end

function spalte( layoutxml,dataxml )
  local ret = {}
  ret.breite           = publisher.read_attribute(layoutxml,dataxml,"width","string")
  ret.hintergrundfarbe = publisher.read_attribute(layoutxml,dataxml,"backgroundcolor","string")
  ret.align            = publisher.read_attribute(layoutxml,dataxml,"align","string")
  ret.valign           = publisher.read_attribute(layoutxml,dataxml,"valign","string")

  return ret
end

function spalten( layoutxml,dataxml )
  local tab = publisher.dispatch(layoutxml,dataxml)
  return tab
end

function speichere_datensatzdatei( layoutxml,dataxml )
  local towrite, tmp,tab
  local filename   = publisher.read_attribute(layoutxml,dataxml,"filename",  "string")
  local elementname = publisher.read_attribute(layoutxml,dataxml,"elementname","string")
  local auswahl     = publisher.read_attribute(layoutxml,dataxml,"select","string")

  assert(filename)
  assert(elementname)

  if auswahl then
    tab = xpath.parse(dataxml,auswahl)
  else
    tab = publisher.dispatch(layoutxml,dataxml)
  end
  tmp = {}
  for i=1,#tab do
    if tab[i].elementname=="Element" then
      tmp[#tmp + 1] = publisher.element_contents(tab[i])
    elseif tab[i].elementname=="SortiereSequenz" or tab[i].elementname=="Sequenz" or tab[i].elementname=="elementstructure" then
      for j=1,#publisher.element_contents(tab[i]) do
        tmp[#tmp + 1] = publisher.element_contents(tab[i])[j]
      end
    else
      tmp[#tmp + 1] = tab[i]
    end
  end

  -- tmp hat nun die Struktur:
  -- tmp = {
  --   [1] = {
  --     [".__parent"] =
  --     [".__name"] = "bar"
  --     ["att1"] = "1"
  --   },
  --   [2] = {
  --     [".__parent"] =
  --     [".__name"] = "bar"
  --     ["att2"] = "2"
  --   },
  --   [3] = {
  --     [".__parent"] =
  --     [".__name"] = "bar"
  --     ["att3"] = "3"
  --   },
  -- },

  tmp[".__name"] = elementname
  local datei = io.open(string.format("datensatzdatei.%s",filename),"w")
  towrite = publisher.xml_to_string(tmp)
  datei:write(towrite)
  datei:close()
end

function sub( layoutxml,dataxml )
  local a = publisher.Paragraph:new()
  local tab = publisher.dispatch(layoutxml,dataxml)
  for i,j in ipairs(tab) do
    a:script(publisher.element_contents(j),1,{schriftfamilie = 0})
  end
  return a
end

function sup( layoutxml,dataxml )
  local a = publisher.Paragraph:new()
  local tab = publisher.dispatch(layoutxml,dataxml)
  for i,j in ipairs(tab) do
    a:script(publisher.element_contents(j),2,{schriftfamilie = 0})
  end
  return a
end


-- FIXME: leading -> rowdistance or so
function tabelle( layoutxml,dataxml,optionen )
  local width          = publisher.read_attribute(layoutxml,dataxml,"width",         "number")
  local hoehe          = publisher.read_attribute(layoutxml,dataxml,"height",        "number")
  local padding        = publisher.read_attribute(layoutxml,dataxml,"padding",       "length")
  local columndistance = publisher.read_attribute(layoutxml,dataxml,"columndistance","length")
  local rowdistance    = publisher.read_attribute(layoutxml,dataxml,"leading",       "length")
  local fontname       = publisher.read_attribute(layoutxml,dataxml,"fontface",      "string")
  local autostretch    = publisher.read_attribute(layoutxml,dataxml,"stretch",       "string")

  padding        = tex.sp(padding        or "0pt")
  columndistance = tex.sp(columndistance or "0pt")
  rowdistance    = tex.sp(rowdistance    or "0pt")
  width = publisher.current_grid.gridwidth * width


  if not fontname then fontname = "text" end
  fontfamily = publisher.fonts.lookup_fontfamily_name_number[fontname]

  if fontfamily == nil then
    err("Fontfamily %q not found.",fontname or "???")
    fontfamily = 1
  end

  local tab = publisher.dispatch(layoutxml,dataxml)

  local tabular = publisher.tabular:new()

  tabular.tab = tab
  tabular.optionen       = optionen or { ht_aktuell=100*2^16 } -- FIXME! Test - das ist für tabular in tabular
  tabular.layoutxml      = layoutxml
  tabular.dataxml       = dataxml
  tabular.breite         = width
  tabular.fontfamily     = fontfamily
  tabular.padding_left   = padding
  tabular.padding_top    = padding
  tabular.padding_right  = padding
  tabular.padding_bottom = padding
  tabular.colsep         = columndistance
  tabular.rowsep         = rowdistance
  tabular.autostretch    = autostretch


  local n = tabular:tabelle()
  return n
end

function tabellenfuss( layoutxml,dataxml )
  local tab = publisher.dispatch(layoutxml,dataxml)
  return tab
end

function tabellenkopf( layoutxml,dataxml )
  local tab = publisher.dispatch(layoutxml,dataxml)
  return tab
end

function tlinie( layoutxml,dataxml )
  local rulewidth = publisher.read_attribute(layoutxml,dataxml,"rulewidth","length")
  local farbe = publisher.read_attribute(layoutxml,dataxml,"color","string")
  return { rulewidth = rulewidth, farbe = farbe }
end

function tr( layoutxml,dataxml )
  local tab = publisher.dispatch(layoutxml,dataxml)

  local attribute = {
    ["align"]   = "string",
    ["valign"]  = "string",
    ["backgroundcolor"] = "string",
    ["minheight"] = "number",
  }

  for attname,atttyp in pairs(attribute) do
    tab[attname] = publisher.read_attribute(layoutxml,dataxml,attname,atttyp)
  end

  tab.minhoehe = tab["minhöhe"]

  return tab
end

function td( layoutxml,dataxml )
  local tab = publisher.dispatch(layoutxml,dataxml)

  local attribute = {
    ["colspan"]          = "number",
    ["rowspan"]          = "number",
    ["align"]            = "string",
    ["padding"]          = "length",
    ["padding-top"]      = "length",
    ["padding-right"]    = "length",
    ["padding-bottom"]   = "length",
    ["padding-left"]     = "length",
    ["backgroundcolor"] = "string",
    ["valign"]           = "string",
    ["border-left"]      = "length",
    ["border-right"]     = "length",
    ["border-top"]       = "length",
    ["border-bottom"]    = "length",
    ["border-left-color"]      = "string",
    ["border-right-color"]     = "string",
    ["border-top-color"]       = "string",
    ["border-bottom-color"]    = "string",
  }

  for attname,atttyp in pairs(attribute) do
    tab[attname] = publisher.read_attribute(layoutxml,dataxml,attname,atttyp)
  end

  if tab.padding then
    tab.padding_left   = tex.sp(tab.padding)
    tab.padding_right  = tex.sp(tab.padding)
    tab.padding_top    = tex.sp(tab.padding)
    tab.padding_bottom = tex.sp(tab.padding)
  end
  if tab["padding-top"]    then tab.padding_top    = tex.sp(tab["padding-top"])    end
  if tab["padding-bottom"] then tab.padding_bottom = tex.sp(tab["padding-bottom"]) end
  if tab["padding-left"]   then tab.padding_left   = tex.sp(tab["padding-left"])   end
  if tab["padding-right"]  then tab.padding_right  = tex.sp(tab["padding-right"])  end

  return tab
end

-- Erzeugt einen rechteckigen Textblock. Rückgabe ist eine vlist.
function textblock( layoutxml,dataxml )
  trace("Textblock")
  local fontfamily
  local fontname       = publisher.read_attribute(layoutxml,dataxml,"fontface","string")
  local colorname      = publisher.read_attribute(layoutxml,dataxml,"color","string")
  local width          = publisher.read_attribute(layoutxml,dataxml,"width","number")
  local angle          = publisher.read_attribute(layoutxml,dataxml,"angle","number")
  local columns        = publisher.read_attribute(layoutxml,dataxml,"columns","number")
  local columndistance = publisher.read_attribute(layoutxml,dataxml,"columndistance","string")
  local textformat     = publisher.read_attribute(layoutxml,dataxml,"textformat","string")

  -- The rules for textformat: 
  --  * if the paragraph has a textformat then use it, end
  --  * if the textblock has a textformat then use it, end
  --  * use the textformat "text" end

  columns = columns or 1
  if not columndistance then columndistance = "3mm" end
  if tonumber(columndistance) then
    columndistance = publisher.current_grid.gridwidth * columndistance
  else
    columndistance = tex.sp(columndistance)
  end

  if not fontname then fontname = "text" end
  fontfamily = publisher.fonts.lookup_fontfamily_name_number[fontname]
  if fontfamily == nil then
    err("Fontfamily %q not found.",fontname or "???")
    fontfamily = 1
  end

  local colortable
  if colorname then
    if not publisher.colors[colorname] then
      -- Farbe ist nicht definiert
      err("Color %q is not defined.",colorname)
    else
      colortable = publisher.colors[colorname].index
    end
  end

  local width_sp = width * publisher.current_grid.gridwidth

  local objects, nodes = {},{}
  local nodelist,parameter

  local tab = publisher.dispatch(layoutxml,dataxml)

  for i,j in ipairs(tab) do
    local eltname = publisher.elementname(j,true)
    trace("Textblock: Element = %q",tostring(eltname))
    if eltname == "Paragraph" then
      objects[#objects + 1] = publisher.element_contents(j)
    elseif eltname == "Text" then
      assert(false)
    elseif eltname == "Action" then
      objects[#objects + 1] = publisher.element_contents(j)
    elseif eltname == "Bookmark" then
      objects[#objects + 1] = publisher.element_contents(j)
    end
  end
  trace("Textblock: #objects=%d",#objects)

  if columns > 1 then
    width_sp = math.floor(  (width_sp - columndistance * ( columns - 1 ) )   / columns)
  end

  for _,paragraph in ipairs(objects) do
    if paragraph.id == 8 then -- whatsit
      -- todo: document how this can be!
      nodes[#nodes + 1] = paragraph
    else
      nodelist = paragraph.nodelist
      assert(nodelist)
      publisher.set_fontfamily_if_necessary(nodelist,fontfamily)
      paragraph.nodelist = publisher.set_color_if_necessary(nodelist,colortable)
      node.slide(nodelist)
      nodelist = paragraph:format(width_sp,textformat)

      nodes[#nodes + 1] = nodelist
    end
  end

  if #objects == 0 then
    warning("Textblock: no objects found!")
    local vrule = {  width = 10 * 2^16, height = -1073741824}
    nodes[1] = publisher.add_rule(nil,"head",vrule)
  end

  if columns > 1 then
    local zeilen = {}
    local zeilenanzahl = 0
    local neue_nodes = {}
    for i=1,#nodes do
      for n in node.traverse_id(0,nodes[i].list) do
        zeilenanzahl = zeilenanzahl + 1
        zeilen[zeilenanzahl] = n
      end
    end

    local zeilenanzahl_mehrspaltiger_satz = math.ceil(zeilenanzahl / columns)
    for i=1,zeilenanzahl_mehrspaltiger_satz do
      local current_row,hbox_current_row
      hbox_current_row = zeilen[i] -- erste Spalte
      local tail = hbox_current_row
      for j=2,columns do -- zweite und folgende columns
        local g1 = node.new("glue")
        g1.spec = node.new("glue_spec")
        g1.spec.width = columndistance
        tail.next = g1
        g1.prev = tail
        current_row = (j - 1) * zeilenanzahl_mehrspaltiger_satz + i
        if current_row <= zeilenanzahl then
          tail = zeilen[current_row]
          g1.next = tail
          tail.prev = g1
        end
      end
      tail.next = nil
      neue_nodes[#neue_nodes + 1] = node.hpack(hbox_current_row)
    end
    nodes=neue_nodes
  end

  trace("Textbock: connect nodes")
  -- connect nodes[i]
  local tail
  for i=2,#nodes do
    tail = node.tail(nodes[i-1])
    tail.next = nodes[i]
    nodes[i].prev = tail
  end

  trace("Textbock: vpack()")
  nodelist = node.vpack(nodes[1])
  if angle then
    nodelist = publisher.rotate(nodelist,angle)
  end
  trace("Textbock: end")
  return nodelist
end

function trennvorschlag( layoutxml,dataxml )
  lang.hyphenation(publisher.languages.de,layoutxml[1])
end

-- Underline text
function underline( layoutxml,dataxml )
  trace("Underline")

  local a = publisher.Paragraph:new()
  local objects = {}
  local tab = publisher.dispatch(layoutxml,dataxml)

  for i,j in ipairs(tab) do
    if publisher.elementname(j,true) == "Value" and type(publisher.element_contents(j)) == "table" then
      objects[#objects + 1] = publisher.parse_html(publisher.element_contents(j))
    else
      objects[#objects + 1] = publisher.element_contents(j)
    end
  end
  for _,j in ipairs(objects) do
    a:append(j,{schriftfamilie = 0, underline = 1})
  end
  return a
end

-- Weist einer Variablen einen Wert zu
function zuweisung( layoutxml,dataxml )
  local trace_p = publisher.read_attribute(layoutxml,dataxml,"trace","boolean")
  local auswahl = publisher.read_attribute(layoutxml,dataxml,"select","string")

  -- FIXME: wenn in der Variablen schon nodelisten sind, dann müssen diese gefreed werden!
  local varname = publisher.read_attribute(layoutxml,dataxml,"variable","string")

  trace("Zuweisung, Variable = %q",varname or "???")
  if not varname then
    err("Variable name in »Zuweisung« not recognized")
    return
  end
  local contents

  if auswahl then
    contents = xpath.parse(dataxml,auswahl)
  else
    local tab = publisher.dispatch(layoutxml,dataxml)
    contents = tab
  end

  if type(contents)=="table" then
    local ret
    for i=1,#contents do
      local eltname = publisher.elementname(contents[i],true)
      local contents = publisher.element_contents(contents[i])
      if eltname == "Sequence" or eltname == "Value" or eltname == "SortSequence" then
        if type(contents) == "table" then
          ret = ret or {}
          if getmetatable(ret) == nil then
            setmetatable(ret,{ __concat = table.__concat })
          end
          ret = ret .. contents
        elseif type(contents) == "string" then
          ret = ret or ""
          ret = ret .. contents
        elseif type(contents) == "number" then
          ret = ret or ""
          ret = ret .. tostring(contents)
        elseif type(contents) == "nil" then
          -- ignorieren
        else
          err("Unknown type: %q",type(contents))
          ret = nil
        end
      elseif eltname == "elementstructure" then
        for j=1,#contents do
          ret = ret or {}
          ret[#ret + 1] = contents[j]
        end
      elseif eltname == "Element" then
        ret = ret or {}
        ret[#ret + 1] = contents
      end
    end
    if ret then
      contents = ret
    end
  end
  if trace_p then
    log("»Zuweisung«, variable name = %q, value = %q",varname or "???", tostring(contents))
    printtable("Zuweisung",contents)
  end

  publisher.variablen[varname] = contents
end

function wert( layoutxml,dataxml )
  local auswahl = publisher.read_attribute(layoutxml,dataxml,"select","string")

  local tab
  if auswahl then
    tab = xpath.parse(dataxml,auswahl)
  else
    tab = table.concat(layoutxml)
  end
  return tab
end

-- Gibt eine Nummer zurück. Unter dieser Nummer ist in der Tabelle @publisher.user_defined_funktionen@
-- eine Funktion gespeichert, die zu einer Tabelle eine Schlüssel/Wert-Kombination hinzufügt.
function zur_liste_hinzufuegen( layoutxml,dataxml )
  local schluessel = publisher.read_attribute(layoutxml,dataxml,"key","string")
  local listenname = publisher.read_attribute(layoutxml,dataxml,"liste","string")
  local auswahl    = publisher.read_attribute(layoutxml,dataxml,"select","string")

  local wert = xpath.parse(dataxml,auswahl)
  if not publisher.variablen[listenname] then
    publisher.variablen[listenname] = {}
  end
  local udef = publisher.user_defined_funktionen
  local var  = publisher.variablen[listenname]
  udef[udef.last + 1] = function() var[#var + 1] = { schluessel , wert } end
  udef.last = udef.last + 1
  return udef.last
end

file_end("commands.lua")
