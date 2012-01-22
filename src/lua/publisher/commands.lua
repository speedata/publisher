--
--  element.lua
--  speedata publisher
--
--  Copyright 2010-2011 Patrick Gundlach.
--  See file COPYING in the root directory for license info.

file_start("commands.lua")
require("publisher.fonts")
require("publisher.table")
require("xpath")
require("fileutils")

-- Dieses Modul enthält die Einstiegspunkte der Layout-Tags.
module(...,package.seeall)

-- Setzt den Text im XML-Element "Absatz".
function absatz( layoutxml,datenxml )
  local textformat = publisher.read_attribute(layoutxml,datenxml,"textformat","string")
  local schriftart = publisher.read_attribute(layoutxml,datenxml,"fontface","string")

  local schriftfamilie
  if schriftart then
    schriftfamilie = publisher.fonts.lookup_schriftfamilie_name_nummer[schriftart]
    if schriftfamilie == nil then
      err("Fontfamily %q not found.",schriftart)
      schriftfamilie = 0
    end
  else
    schriftfamilie = 0
  end

  -- local languagecode  = publisher.options.defaultlanguage or 0 -- not there yet
  local languagecode  = 0

  local sprache_de  = publisher.read_attribute(layoutxml,datenxml,"language","string")
  sprache_de_internal = {
     ["Deutsch"]                        = "de-1996",
     ["Englisch (Großbritannien)"]      = "en-gb",
     ["Französisch"]                    = "fr",
     }
  if sprache_de then
    languagecode = publisher.get_languagecode(sprache_de_internal[sprache_de])
  end

  local colorname = publisher.read_attribute(layoutxml,datenxml,"color","string")
  local farbindex
  if colorname then
    if not publisher.farben[colorname] then
      error("Farbe %q ist nicht defniert.",colorname)
    else
      farbindex = publisher.farben[colorname].index
    end
  end


  local a = publisher.Paragraph:new(textformat)
  local objects = {}
  local tab = publisher.dispatch(layoutxml,datenxml)

  for i,j in ipairs(tab) do
    trace("Paragraph Elementname = %q",tostring(publisher.elementname(j,true)))
    if publisher.elementname(j,true) == "Value" and type(publisher.inhalt(j)) == "table" then
      objects[#objects + 1] = publisher.parse_html(publisher.inhalt(j))
    else
      objects[#objects + 1] = publisher.inhalt(j)
    end
  end
  for _,j in ipairs(objects) do
    a:append(j,{schriftfamilie = schriftfamilie, languagecode = languagecode})
  end
  if #objects == 0 then
    -- nothing got through, why?? check
    warning("No contents found in paragraph.")
    a:append("",{schriftfamilie = schriftfamilie,languagecode = languagecode})
  end

  a:set_color(farbindex)
  return a
end

-- Erzeugt ein 44er whatsit node (user_defined)
function aktion( layoutxml,datenxml)
  local tab = publisher.dispatch(layoutxml,datenxml)
  local ret = {}

  for _,j in ipairs(tab) do
    if publisher.elementname(j,true) == "AddToList" then
      local n = node.new("whatsit","user_defined")
      n.user_id = 1 -- a magic number
      n.type = 100 -- type 100: "value is a number"
      n.value = publisher.inhalt(j) -- Zeiger auf die Funktion (int)
      ret[#ret + 1] = n
    end
  end
  return ret
end

-- Erzeugt ein Attribut für die XML-Struktur
function attribut( layoutxml,datenxml )
  local auswahl = publisher.read_attribute(layoutxml,datenxml,"select","string")
  local attname  = publisher.read_attribute(layoutxml,datenxml,"name","string")
  local attvalue = xpath.textvalue(xpath.parse(datenxml,auswahl))
  local ret = { [".__type"]="attribute", [attname] = attvalue }
  return ret
end

function bearbeite_datensatz( layoutxml,datenxml )
  trace("BearbeiteDatensatz")
  local auswahl = publisher.read_attribute(layoutxml,datenxml,"select","string")
  local umfang  = publisher.read_attribute(layoutxml,datenxml,"limit","string")

  local datensatz = xpath.parse(datenxml,auswahl)
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
    layoutknoten=publisher.datensatz_verteiler[""][eltname]
    log("Selecting node: %q",eltname or "???")
    publisher.variablen.__position = i
    publisher.dispatch(layoutknoten,publisher.inhalt(datensatz[i]))
  end
end

-- Ruft das Layoutxml für einen bestimmten Unterdatensatz (Element) auf.
function bearbeite_knoten(layoutxml,datenxml)
  local auswahl = publisher.read_attribute(layoutxml,datenxml,"select","string")

  local letzte_position = publisher.variablen.__position
  local modus = publisher.read_attribute(layoutxml,datenxml,"mode","string") or ""
  local layoutknoten = publisher.datensatz_verteiler[modus][auswahl]
  local pos = 1
  if type(layoutknoten)=="table" then
    for i,j in ipairs(datenxml) do
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

function beiseitenausgabe( layoutxml,datenxml )
  return layoutxml
end

function beiseitenerzeugung( layoutxml,datenxml )
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
function bild( layoutxml,datenxml )
  local breite = publisher.read_attribute(layoutxml,datenxml,"width","string")
  local hoehe  = publisher.read_attribute(layoutxml,datenxml,"height",  "string")

  local seite     = publisher.read_attribute(layoutxml,datenxml,"page","number")
  local nat_box   = publisher.read_attribute(layoutxml,datenxml,"naturalsize","string")
  local max_box   = publisher.read_attribute(layoutxml,datenxml,"maxsize","string")
  local filename = publisher.read_attribute(layoutxml,datenxml,"file","string")

  local nat_box_intern = box_lookup[nat_box] or "crop"
  local max_box_intern = box_lookup[max_box] or "crop"

  publisher.seite_einrichten()

  local breite_sp, hoehe_sp
  if breite and not tonumber(breite) then
    -- breite ist keine Zahl, sondern eine Maßangabe
    breite_sp = tex.sp(breite)
  else
    breite_sp = breite * publisher.current_grid.gridwidth
  end

  if hoehe then
    if tonumber(hoehe) then
      hoehe_sp  = hoehe * publisher.current_grid.gridheight
    else
      hoehe_sp = tex.sp(hoehe)
    end
  end

  local bild = publisher.new_image(filename,seite,max_box_intern)
  local skalierungsfaktor_wd = breite_sp / bild.width
  local skalierungsfaktor = skalierungsfaktor_wd
  if hoehe_sp then
    local skalierungsfaktor_ht = hoehe_sp / bild.height
    skalierungsfaktor = math.min(skalierungsfaktor_ht,skalierungsfaktor_wd)
  end

  local shift_left,shift_up

  if nat_box_intern ~= max_box_intern then
    -- Das Bild muss vergrößert und dann nach links und oben verschoben werden
    local img_min = publisher.imageinfo(filename,seite,nat_box_intern)
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
  return hbox
end

function box( layoutxml,datenxml )
  local width     = publisher.read_attribute(layoutxml,datenxml,"width","number")
  local height    = publisher.read_attribute(layoutxml,datenxml,"height","number")
  local hf_string = publisher.read_attribute(layoutxml,datenxml,"backgroundcolor","string")

  local current_grid = publisher.current_grid
  local _width   = sp_to_bp(current_grid.gridwidth  * width)
  local _height  = sp_to_bp(current_grid.gridheight * height)
  local n = publisher.box(_width,_height,hf_string)
  n = node.hpack(n)
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
  local elementname = publisher.read_attribute(layoutxml,datenxml,"element","string")
  local mode        = publisher.read_attribute(layoutxml,datenxml,"mode","string")

  mode = mode or ""
  publisher.datensatz_verteiler[mode] = publisher.datensatz_verteiler[mode] or {}
  publisher.datensatz_verteiler[mode][elementname] = layoutxml
end

-- Einsprungpunkt in der Datenverarbeitung.
function datenverarbeitung(datenxml)
  local tmp
  local name = datenxml[".__name"]
  tmp = publisher.datensatz_verteiler[""][name] -- default-Modus
  if tmp then publisher.dispatch(tmp,datenxml) end
end

-- Definiert eine Farbe
function definiere_farbe( layoutxml,datenxml )
  local name  = publisher.read_attribute(layoutxml,datenxml,"name","string")
  local model = publisher.read_attribute(layoutxml,datenxml,"model","string")

  log("Defining color %q",name)
  local color = { modell = model }

  if model=="cmyk" then
    color.c = publisher.read_attribute(layoutxml,datenxml,"c","number")
    color.m = publisher.read_attribute(layoutxml,datenxml,"m","number")
    color.y = publisher.read_attribute(layoutxml,datenxml,"y","number")
    color.k = publisher.read_attribute(layoutxml,datenxml,"k","number")
    color.pdfstring = string.format("%g %g %g %g k %g %g %g %g K", color.c/100, color.m/100, color.y/100, color.k/100,color.c/100, color.m/100, color.y/100, color.k/100)
  elseif model=="rgb" then
    color.r = publisher.read_attribute(layoutxml,datenxml,"r","number")
    color.g = publisher.read_attribute(layoutxml,datenxml,"g","number")
    color.b = publisher.read_attribute(layoutxml,datenxml,"b","number")
    color.pdfstring = string.format("%g %g %g rg %g %g %g RG", color.r/100, color.g/100, color.b/100, color.r/100,color.g/100, color.b/100)
  else
    err("Unknown color model: %s",model or "?")
  end
  publisher.farbindex[#publisher.farbindex + 1] = name
  color.index = #publisher.farbindex
  publisher.farben[name]=color
end

-- Definiert ein Textformat
function definiere_textformat(layoutxml)
  trace("Command: DefineTextformat")
  local alignment   = publisher.read_attribute(layoutxml,datenxml,"alignment",   "string")
  local indentation = publisher.read_attribute(layoutxml,datenxml,"indentation", "length")
  local name        = publisher.read_attribute(layoutxml,datenxml,"name",        "string")

  local fmt = {}

  if alignment=="linksbündig" or alignment == "leftaligned" then
    fmt.alignment = "linksbündig"
  elseif alignment=="rechtsbündig" or alignment == "rightaligned"then
    fmt.alignment = "rechtsbündig"
  elseif alignment=="zentriert" or alignment == "centered" then
    fmt.alignment = "zentriert"
  else
    fmt.alignment = "blocksatz"
  end
  if indentation then
    fmt.indent = tex.sp(indentation)
  end
  publisher.textformate[name] = fmt
end


-- Definiert eine Schriftfamilie
function definiere_schriftfamilie( layoutxml,datenxml )
  -- hier müssen die konkreten Instanzen erzeugt werden. Schriftgröße
  -- und baselineskip sind bekannt.
  local name        = publisher.read_attribute(layoutxml,datenxml,"name",       "string")

  local fonts = publisher.fonts
  local fam={}
  -- Schriftgröße, baselineskip sind in big points (1 bp ≈ 65782 sp)
  fam.size          = publisher.read_attribute(layoutxml,datenxml,"fontsize","number")  * 65782
  fam.baselineskip = publisher.read_attribute(layoutxml,datenxml,"leading","number") * 65782
  fam.scriptsize    = fam.size * 0.8 -- subscript / superscript
  fam.scriptshift   = fam.size * 0.3

  if not fam.size then
    err("»DefiniereSchriftfamilie«: no size given.")
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
  fonts.lookup_schriftfamilie_nummer_instanzen[#fonts.lookup_schriftfamilie_nummer_instanzen + 1] = fam
  fonts.lookup_schriftfamilie_name_nummer[name]=#fonts.lookup_schriftfamilie_nummer_instanzen
  log("»DefiniereSchriftfamilie«, family=%d, name=%q",#fonts.lookup_schriftfamilie_nummer_instanzen,name)
end

-- Erzeugt ein Element für die XML-Struktur
function element( layoutxml,datenxml )
  local elementname = publisher.read_attribute(layoutxml,datenxml,"name","string")
  local ret = { [".__name"] = elementname }

  local tab = publisher.dispatch(layoutxml,datenxml)
  for i,v in ipairs(tab) do
    local inhalt = publisher.inhalt(v)
    if inhalt[".__type"]=="attribute" then
      -- Attribut
      for _k,_v in pairs(inhalt) do
        if _k ~= ".__type" then
          ret[_k] = _v
        end
      end
    else
      ret[#ret + 1] = inhalt
    end
  end

  return ret
end

-- Fallunterscheidung
function fallunterscheidung( layoutxml,datenxml )
  local fall_ausgefuehrt = false
  local sonst,ret,elementname
  for i,v in ipairs(layoutxml) do
    elementname = publisher.translate_element(v[".__name"])
    if type(v)=="table" and elementname=="Case" and fall_ausgefuehrt ~= true then
      local fall = v
      assert(fall.bedingung)
      if xpath.parse(datenxml,fall.bedingung) then
        fall_ausgefuehrt = true
        ret = publisher.dispatch(fall,datenxml)
      end
    elseif type(v)=="table" and elementname=="Otherwise" then
      sonst = v
    end -- fall/sonst
  end
  if sonst and fall_ausgefuehrt==false then
    ret = publisher.dispatch(sonst,datenxml)
  end
  if not ret then return {} end
  return ret
end

-- Text in fetter Schrift
function fett( layoutxml,datenxml )
  local a = publisher.Paragraph:new()

  local objects = {}
  local tab = publisher.dispatch(layoutxml,datenxml)

  for i,j in ipairs(tab) do
    if publisher.elementname(j,true) == "Value" and type(publisher.inhalt(j)) == "table" then
      objects[#objects + 1] = publisher.parse_html(publisher.inhalt(j))
    else
      objects[#objects + 1] = publisher.inhalt(j)
    end
  end
  for _,j in ipairs(objects) do
    a:append(j,{schriftfamilie = 0, fett = 1})
  end

  return a
end

function gruppe( layoutxml,datenxml )
  publisher.seite_einrichten()
  local name        = publisher.read_attribute(layoutxml,datenxml,"name",       "string")

  local groupname = name

  if publisher.gruppen[groupname] == nil then
    log("Create »Gruppe« %q.",groupname)
  else
    node.flush_list(publisher.gruppen[groupname].inhalt)
    publisher.gruppen[groupname] = nil
  end

  local r = publisher.raster:new()
  r:setze_rand(0,0,0,0)
  r:setze_breite_hoehe(publisher.aktuelle_seite.raster.gridwidth,publisher.aktuelle_seite.raster.gridheight)
  publisher.gruppen[groupname] = {
    inhalt = inhalt,
    raster  = r,
  }

  local save_grid      = publisher.current_grid
  local save_groupname = publisher.current_group

  publisher.current_group = groupname
  publisher.current_grid  = r
  local elementname

  for _,v in ipairs(layoutxml) do
    elementname=publisher.translate_element(v[".__name"])
    if type(v)=="table" and elementname=="Contents" then
      publisher.dispatch(v,datenxml)
    end
  end

  publisher.current_group  = save_groupname
  publisher.current_grid = save_grid
end

-- Dummy-Element fürs Einbinden von xi:include-Dateien
function include( layoutxml,datenxml )
  return publisher.dispatch(layoutxml,datenxml)
end

-- Italic text
function kursiv( layoutxml,datenxml )
  trace("Italic")
  local a = publisher.Paragraph:new()
  local objects = {}
  local tab = publisher.dispatch(layoutxml,datenxml)
  for i,j in ipairs(tab) do
    if publisher.elementname(j,true) == "Value" and type(publisher.inhalt(j)) == "table" then
      objects[#objects + 1] = publisher.parse_html(publisher.inhalt(j))
    else
      objects[#objects + 1] = publisher.inhalt(j)
    end
  end
  for _,j in ipairs(objects) do
    a:append(j,{schriftfamilie = 0, kursiv = 1})
  end
  return a
end

-- XPath Ausdruck um einen Wert aus den Daten zu extrahieren. Gibt eine Sequenz zurück
function kopie_von( layoutxml,datenxml )
  local auswahl = publisher.read_attribute(layoutxml,datenxml,"select", "string")

  if layoutxml[1] and #layoutxml[1] > 0 then
    return table.concat(layoutxml)
  else
    auswahl = xpath.parse(datenxml,auswahl)
    trace("Kopie-von: type(auswahl)=%q",type(auswahl))
    return auswahl
  end
end

-- Lädt eine Schriftdatei
function lade_schriftdatei( layoutxml,datenxml )
  local randausgleich = publisher.read_attribute(layoutxml,datenxml,"marginprotrusion","number")
  local leerraum      = publisher.read_attribute(layoutxml,datenxml,"space","number")
  local smcp          = publisher.read_attribute(layoutxml,datenxml,"smallcaps","string")
  local filename = publisher.read_attribute(layoutxml,datenxml,"filename","string")
  local name     = publisher.read_attribute(layoutxml,datenxml,"name","string")

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
function lade_datensatzdatei( layoutxml,datenxml )
  local name = publisher.read_attribute(layoutxml,datenxml,"name", "string")
  assert(name)
  local filename = "datensatzdatei." .. name

  if fileutils.test("x",filename)==false then
    -- at the first run, the file does not exist. That's ok
    return
  end

  local tmp_data = publisher.load_xml(filename)
  local root_name = tmp_data[".__name"]

  log("Selecting node: %q, mode=%q",root_name,"")
  publisher.dispatch(publisher.datensatz_verteiler[""][root_name],tmp_data)
end

function leerzeile( layoutxml,datenxml )
  trace("Leerzeile, aktuelle Zeile = %d",publisher.current_grid:current_row())
  local areaname = publisher.read_attribute(layoutxml,datenxml,"area","string")
  local areaname = areaname or publisher.default_areaname
  local current_grid = publisher.current_grid
  local current_row = current_grid:finde_passende_zeile(1,current_grid:anzahl_spalten(),1,areaname)
  if not current_row then
    current_grid:set_current_row(1)
  else
    current_grid:set_current_row(current_row + 1)
  end
end

function linie( layoutxml,datenxml )
  local direction     = publisher.read_attribute(layoutxml,datenxml,"direction",  "string")
  local length        = publisher.read_attribute(layoutxml,datenxml,"length",     "string")
  local rulewidth     = publisher.read_attribute(layoutxml,datenxml,"rulewidth",  "string")

  w("direction = %s",direction)
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

  local colorname = "Schwarz"

  local n = node.new("whatsit","pdf_literal")
  n.mode = 0
  if direction == "horizontal" then
    n.data = string.format("q %d w %s 0 0 m %g 0 l S Q",rulewidth,publisher.farben[colorname].pdfstring,length)
  elseif direction == "vertikal" or direction == "vertikal" then
    n.data = string.format("q %d w %s 0 0 m 0 %g l S Q",rulewidth,publisher.farben[colorname].pdfstring,-length)
  else
    --
  end
  n = node.hpack(n)
  return n
end

-- Schreibt eine Meldung in Terminal
function nachricht( layoutxml, datenxml )
  local inhalt
  local auswahl = publisher.read_attribute(layoutxml,datenxml,"select","string")

  if auswahl then
    inhalt = xpath.parse(datenxml,auswahl)
  else
    local tab = publisher.dispatch(layoutxml,datenxml)
    inhalt = tab
  end
  if type(inhalt)=="table" then
    local ret
    for i=1,#inhalt do
      local eltname = publisher.elementname(inhalt[i],true)
      local contents = publisher.inhalt(inhalt[i])

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
      inhalt = ret
    end
  end
  log("Message: %q", tostring(inhalt) or "?")
end

function naechster_rahmen( layoutxml,datenxml )
  local areaname = publisher.read_attribute(layoutxml,datenxml,"area","string")
  publisher.naechster_rahmen(areaname)
end

function neue_zeile( layoutxml,datenxml )
  publisher.seite_einrichten()
  local areaname = publisher.read_attribute(layoutxml,datenxml,"area","string")
  local areaname = areaname or publisher.default_areaname
  local raster = publisher.current_grid
  local current_row = raster:finde_passende_zeile(1,raster:anzahl_spalten(),1,areaname)
  if not current_row then
    neue_seite()
    publisher.seite_einrichten()
    raster = publisher.aktuelle_seite.raster
    raster:set_current_row(1)
  else
    raster:set_current_row(current_row)
  end
end

-- Erzeugt eine neue Seite
function neue_seite( )
  publisher.neue_seite()
end

-- Formatiert die angegebene URL etwas besser für den Satz.
function url(layoutxml,datenxml)
  local a = publisher.Paragraph:new()
  local tab = publisher.dispatch(layoutxml,datenxml)
  for i,j in ipairs(tab) do
    a:append(xpath.textvalue(publisher.inhalt(j)),{})
    a.nodelist = publisher.umbreche_url(a.nodelist)
  end
  return a
end

-- Gibt ein rechteckiges Objekt (derzeit nur Bild) aus
function objekt_ausgeben( layoutxml,datenxml )
  trace("Command: PlaceObject")
  local absolute_positioning = false
  local spalte           = publisher.read_attribute(layoutxml,datenxml,"column",         "string")
  local zeile            = publisher.read_attribute(layoutxml,datenxml,"row",            "string")
  local bereich          = publisher.read_attribute(layoutxml,datenxml,"area",           "string")
  local belegen          = publisher.read_attribute(layoutxml,datenxml,"allocate",       "boolean")
  local rahmenfarbe      = publisher.read_attribute(layoutxml,datenxml,"framecolor",     "string")
  local hintergrundfarbe = publisher.read_attribute(layoutxml,datenxml,"backgroundcolor","string")
  local maxhoehe         = publisher.read_attribute(layoutxml,datenxml,"maxheight",      "number")
  local rahmen           = publisher.read_attribute(layoutxml,datenxml,"frame",          "string")
  local hintergrund      = publisher.read_attribute(layoutxml,datenxml,"background",     "string")
  local groupname      = publisher.read_attribute(layoutxml,datenxml,"groupname",      "number")
  local valign           = publisher.read_attribute(layoutxml,datenxml,"valign",         "string")

  bereich = bereich or publisher.default_areaname
  belegen = belegen or true

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

  publisher.seite_einrichten()

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
  local tab    = publisher.dispatch(layoutxml,datenxml,optionen)

  local objects = {}
  local object, objecttype

  if groupname then
    objects[1] = { object = node.copy(publisher.gruppen[groupname].inhalt),
      objecttype = string.format("Gruppe (%s)", groupname)}
  else
    for i,j in ipairs(tab) do
      object = publisher.inhalt(j)
      objecttype = publisher.elementname(j,true)
      if type(object)=="table" then
        for i=1,#object do
          objects[#objects + 1] = {object = object[i], objecttype = objecttype }
        end
      else
        objects[#objects + 1] = {object = object, objecttype = objecttype }
      end
    end
  end
  for i=1,#objects do
    raster = publisher.current_grid
    object    = objects[i].object
    objecttype = objects[i].objecttype

    if hintergrund == "vollständig" then
      object = publisher.hintergrund(object,hintergrundfarbe)
    end
    if rahmen == "durchgezogen" then
      object = publisher.rahmen(object,rahmenfarbe)
    end

    if publisher.options.trace then
      publisher.boxit(object)
    end

    if absolute_positioning then
      publisher.ausgabe_bei_absolut(object,spalte + raster.extra_rand,zeile + raster.extra_rand,belegen)
    else
      -- Platz muss gesucht werden
      -- local current_row = raster:current_row(bereich)
      trace("objectAusgeben: Breitenberechnung")
      if not node.has_field(object,"width") then
        warning("Can't calculate with object's width!")
      end
      local breite_in_rasterzellen = raster:breite_in_rasterzellen_sp(object.width)
      local hoehe_in_rasterzellen  = raster:hoehe_in_rasterzellen_sp (object.height + object.depth)
      trace("objectAusgeben: Breitenberechnung abgeschlossen: wd=%d,ht=%d",breite_in_rasterzellen,hoehe_in_rasterzellen)

      trace("objectAusgeben: finde passende Zeile für das object, current_row = %d",zeile or raster:current_row(bereich) or "-1")
      if zeile then
        current_row = zeile
      else
        current_row = nil
      end

      -- Solange auf den nächsten Rahmen schalten, bis eine freie Fläche gefunden werden kann.
      while current_row == nil do
        if not spalte then
          -- Keine Zeile und keine Spalte angegeben. Dann suche ich mir doch die richtigen Werte selbst.
          if aktuelle_spalte_start + breite_in_rasterzellen - 1 > raster:anzahl_spalten() then
            aktuelle_spalte_start = 1
          end
        end
        current_row = raster:finde_passende_zeile(aktuelle_spalte_start,breite_in_rasterzellen,hoehe_in_rasterzellen,bereich)
        if not current_row then
          warning("No suitable row found for object")
          publisher.naechster_rahmen(bereich)
          publisher.seite_einrichten()
          raster = publisher.current_grid
        end
      end

      log("»objectAusgeben«: %s in row %d and column %d, width=%d, height=%d", objecttype, current_row, aktuelle_spalte_start,breite_in_rasterzellen,hoehe_in_rasterzellen)
      trace("»objectAusgeben«: object placed at (%d,%d)",aktuelle_spalte_start,current_row)
      publisher.ausgabe_bei(object,aktuelle_spalte_start,current_row,belegen,bereich,valign)
      trace("object ausgegeben.")
      zeile = nil -- die Zeile ist nicht mehr gültig, da schon ein object ausgegeben wurde
      if i < #objects then
        neue_zeile(layoutxml,datenxml)
      end
    end -- keine absolute Positionierung
  end
  if not belegen then
    publisher.current_grid:set_current_row(current_row_start)
  end
  trace("objects ausgegeben.")
end

-- Saves the options given in the layout file
function optionen( layoutxml,datenxml )
  publisher.options.cutmarks           = publisher.read_attribute(layoutxml,datenxml,"cutmarks",    "boolean")
  publisher.options.runs               = publisher.read_attribute(layoutxml,datenxml,"runs",        "number")
  publisher.options.showgrid           = publisher.read_attribute(layoutxml,datenxml,"show-grid",   "boolean")
  publisher.options.showgridallocation = publisher.read_attribute(layoutxml,datenxml,"show-gridallocation","boolean")
  publisher.options.showhyphenation    = publisher.read_attribute(layoutxml,datenxml,"show-hyphenation","boolean")
  publisher.options.startpage          = publisher.read_attribute(layoutxml,datenxml,"startpage",   "number")
  publisher.options.trace              = publisher.read_attribute(layoutxml,datenxml,"trace",       "boolean")
  publisher.options.trim               = publisher.read_attribute(layoutxml,datenxml,"trim",        "length")
end

function platzierungsrahmen( layoutxml, datenxml )
  local spalte = publisher.read_attribute(layoutxml,datenxml,"column","number")
  local zeile  = publisher.read_attribute(layoutxml,datenxml,"row" ,"number")
  local breite = publisher.read_attribute(layoutxml,datenxml,"width","number")
  local hoehe  = publisher.read_attribute(layoutxml,datenxml,"height"  ,"number")
  return {
    spalte = spalte,
    zeile = zeile,
    breite = breite,
    hoehe = hoehe
    }
end

-- enthält einen oder mehrere Platzierungsrahmen
function platzierungsbereich( layoutxml,datenxml )
  local tab = publisher.dispatch(layoutxml,datenxml)
  local name = publisher.read_attribute(layoutxml,datenxml,"name","string")
  tab.name = name
  return tab
end

-- Setzt das Papierformat.
function seitenformat(layoutxml)
  trace("Pageformat")
  local width  = publisher.read_attribute(layoutxml,datenxml,"width","length")
  local height = publisher.read_attribute(layoutxml,datenxml,"height","length")
  publisher.set_pageformat(tex.sp(width),tex.sp(height))
end

-- Setzt den Rand für diese Seite
function rand( layoutxml,datenxml )
  local left   = publisher.read_attribute(layoutxml,datenxml,"left", "length")
  local right  = publisher.read_attribute(layoutxml,datenxml,"right","length")
  local top    = publisher.read_attribute(layoutxml,datenxml,"top",  "length")
  local bottom = publisher.read_attribute(layoutxml,datenxml,"bottom", "length")

  return function(_seite) _seite.raster:setze_rand(left,top,right,bottom) end
end

function raster( layoutxml,datenxml )
  local breite = publisher.read_attribute(layoutxml,datenxml,"width","length")
  local hoehe  = publisher.read_attribute(layoutxml,datenxml,"height"  ,"length")
  return { breite = tex.sp(breite), hoehe = tex.sp(hoehe) }
end

function schriftart( layoutxml,datenxml )
  local schriftfamilie = publisher.read_attribute(layoutxml,datenxml,"fontfamily","string")
  local familiennummer = publisher.fonts.lookup_schriftfamilie_name_nummer[schriftfamilie]
  if not familiennummer then
    err("font: family %q unknown",schriftfamilie)
  else
    local a = publisher.Paragraph:new()
    local tab = publisher.dispatch(layoutxml,datenxml)
    for i,j in ipairs(tab) do
      a:append(publisher.inhalt(j),{schriftfamilie = familiennummer})
    end
    return a
  end
end

-- Remember (internally) the grid size (`width` und `height` in layout xml).
function setze_raster(layoutxml)
  trace("Command: SetGrid")
  publisher.options.gridwidth = tex.sp(publisher.read_attribute(layoutxml,datenxml,"width","length"))
  publisher.options.gridheight  = tex.sp(publisher.read_attribute(layoutxml,datenxml,"height","length"))
end

-- Create a list of page types in publisher.seitentypen
function seitentyp(layoutxml,datenxml)
  trace("Command: Pagetype")
  local tmp_tab = {}
  local test         = publisher.read_attribute(layoutxml,datenxml,"test","string")
  local pagetypename = publisher.read_attribute(layoutxml,datenxml,"name","string")
  local tab = publisher.dispatch(layoutxml,datenxml)

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
  publisher.seitentypen[#publisher.seitentypen + 1] = { ist_seitentyp = test, res = tmp_tab, name = pagetypename }
end

function sequenz( layoutxml,datenxml )
  local auswahl = publisher.read_attribute(layoutxml,datenxml,"select","string")
  trace("Command: Sequence: %s, auswahl = %s",layoutxml[".__name"], auswahl )
  local ret = {}
  for i,v in ipairs(datenxml) do
    if type(v)=="table" and v[".__name"] == auswahl then
      ret[#ret + 1] = v
    end
  end
  return ret
end

function solange( layoutxml,datenxml )
  local test = publisher.read_attribute(layoutxml,datenxml,"test","string")
  assert(test)

  while xpath.parse(datenxml,test) do
    publisher.dispatch(layoutxml,datenxml)
  end
end

-- Verändert die Reihenfolge in der Variable!
function sortiere_sequenz( layoutxml,datenxml )
  local auswahl             = publisher.read_attribute(layoutxml,datenxml,"select","string")
  local duplikate_entfernen = publisher.read_attribute(layoutxml,datenxml,"removeduplicates","string")
  local criterium           = publisher.read_attribute(layoutxml,datenxml,"criterium","string")

  local sequenz = xpath.parse(datenxml,auswahl)
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
      local inhalt = publisher.inhalt(v)
      if inhalt[duplikate_entfernen] == letzter_eintrag[duplikate_entfernen] then
        deleteme[#deleteme + 1] = i
      end
      letzter_eintrag = inhalt
    end

    for i=#deleteme,1,-1 do
      -- backwards, otherwise the indexes would be mangled
      table.remove(tmp,deleteme[i])
    end
  end
  return tmp
end

function spalte( layoutxml,datenxml )
  local ret = {}
  ret.breite           = publisher.read_attribute(layoutxml,datenxml,"width","string")
  ret.hintergrundfarbe = publisher.read_attribute(layoutxml,datenxml,"backgroundcolor","string")
  ret.align            = publisher.read_attribute(layoutxml,datenxml,"align","string")
  ret.valign           = publisher.read_attribute(layoutxml,datenxml,"valign","string")

  return ret
end

function spalten( layoutxml,datenxml )
  local tab = publisher.dispatch(layoutxml,datenxml)
  return tab
end

function speichere_datensatzdatei( layoutxml,datenxml )
  local towrite, tmp,tab
  local filename   = publisher.read_attribute(layoutxml,datenxml,"filename",  "string")
  local elementname = publisher.read_attribute(layoutxml,datenxml,"elementname","string")
  local auswahl     = publisher.read_attribute(layoutxml,datenxml,"select","string")

  assert(filename)
  assert(elementname)

  if auswahl then
    tab = xpath.parse(datenxml,auswahl)
  else
    tab = publisher.dispatch(layoutxml,datenxml)
  end
  tmp = {}
  for i=1,#tab do
    if tab[i].elementname=="Element" then
      tmp[#tmp + 1] = publisher.inhalt(tab[i])
    elseif tab[i].elementname=="SortiereSequenz" or tab[i].elementname=="Sequenz" or tab[i].elementname=="Elementstruktur" then
      for j=1,#publisher.inhalt(tab[i]) do
        tmp[#tmp + 1] = publisher.inhalt(tab[i])[j]
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

function sub( layoutxml,datenxml )
  local a = publisher.Paragraph:new()
  local tab = publisher.dispatch(layoutxml,datenxml)
  for i,j in ipairs(tab) do
    a:script(publisher.inhalt(j),1,{schriftfamilie = 0})
  end
  return a
end

function sup( layoutxml,datenxml )
  local a = publisher.Paragraph:new()
  local tab = publisher.dispatch(layoutxml,datenxml)
  for i,j in ipairs(tab) do
    a:script(publisher.inhalt(j),2,{schriftfamilie = 0})
  end
  return a
end


-- FIXME: leading -> rowdistance or so
function tabelle( layoutxml,datenxml,optionen )
  local breite         = publisher.read_attribute(layoutxml,datenxml,"width",         "number")
  local hoehe          = publisher.read_attribute(layoutxml,datenxml,"height",        "number")
  local padding        = publisher.read_attribute(layoutxml,datenxml,"padding",       "length")
  local columndistance = publisher.read_attribute(layoutxml,datenxml,"columndistance","length")
  local rowdistance    = publisher.read_attribute(layoutxml,datenxml,"leading",       "length")
  local schriftartname = publisher.read_attribute(layoutxml,datenxml,"fontface",      "string")
  local autostretch    = publisher.read_attribute(layoutxml,datenxml,"stretch",       "string")

  padding        = tex.sp(padding        or "0pt")
  columndistance = tex.sp(columndistance or "0pt")
  rowdistance    = tex.sp(rowdistance    or "0pt")
  breite = publisher.current_grid.gridwidth * breite


  if not schriftartname then schriftartname = "text" end
  schriftfamilie = publisher.fonts.lookup_schriftfamilie_name_nummer[schriftartname]

  if schriftfamilie == nil then
    err("Fontfamily %q not found.",schriftartname or "???")
    schriftfamilie = 1
  end

  local tab = publisher.dispatch(layoutxml,datenxml)

  local tabelle = publisher.table:new()

  tabelle.tab = tab
  tabelle.optionen = optionen or { ht_aktuell=100*2^16 } -- FIXME! Test - das ist für Tabelle in Tabelle
  tabelle.layoutxml = layoutxml
  tabelle.datenxml  = datenxml
  tabelle.breite = breite
  tabelle.schriftfamilie = schriftfamilie
  tabelle.padding_left   = padding
  tabelle.padding_top    = padding
  tabelle.padding_right  = padding
  tabelle.padding_bottom = padding
  tabelle.colsep = columndistance
  tabelle.rowsep = rowdistance
  tabelle.autostretch = autostretch


  local n = tabelle:tabelle()
  return n
end

function tabellenfuss( layoutxml,datenxml )
  local tab = publisher.dispatch(layoutxml,datenxml)
  return tab
end

function tabellenkopf( layoutxml,datenxml )
  local tab = publisher.dispatch(layoutxml,datenxml)
  return tab
end

function tlinie( layoutxml,datenxml )
  local rulewidth = publisher.read_attribute(layoutxml,datenxml,"rulewidth","length")
  local farbe = publisher.read_attribute(layoutxml,datenxml,"color","string")
  return { rulewidth = rulewidth, farbe = farbe }
end

function tr( layoutxml,datenxml )
  local tab = publisher.dispatch(layoutxml,datenxml)

  local attribute = {
    ["align"]   = "string",
    ["valign"]  = "string",
    ["backgroundcolor"] = "string",
    ["minheight"] = "number",
  }

  for attname,atttyp in pairs(attribute) do
    tab[attname] = publisher.read_attribute(layoutxml,datenxml,attname,atttyp)
  end

  tab.minhoehe = tab["minhöhe"]

  return tab
end

function td( layoutxml,datenxml )
  local tab = publisher.dispatch(layoutxml,datenxml)

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
    tab[attname] = publisher.read_attribute(layoutxml,datenxml,attname,atttyp)
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
function textblock( layoutxml,datenxml )
  trace("Textblock")
  local schriftfamilie
  local schriftartname = publisher.read_attribute(layoutxml,datenxml,"fontface","string")
  local colorname       = publisher.read_attribute(layoutxml,datenxml,"color","string")
  local breite         = publisher.read_attribute(layoutxml,datenxml,"width","number")
  local angle          = publisher.read_attribute(layoutxml,datenxml,"angle","number")
  local columns        = publisher.read_attribute(layoutxml,datenxml,"columns","number")
  local columndistance = publisher.read_attribute(layoutxml,datenxml,"columndistance","string")
  local textformat     = publisher.read_attribute(layoutxml,datenxml,"textformat","string")

  columns = columns or 1
  if not columndistance then columndistance = "3mm" end
  if tonumber(columndistance) then
    columndistance = publisher.current_grid.gridwidth * columndistance
  else
    columndistance = tex.sp(columndistance)
  end

  if not schriftartname then schriftartname = "text" end
  schriftfamilie = publisher.fonts.lookup_schriftfamilie_name_nummer[schriftartname]
  if schriftfamilie == nil then
    err("Fontfamily %q not found.",schriftartname or "???")
    schriftfamilie = 1
  end

  local textformat = textformat or "text"
  if not textformat then
    err("»Textblock« textformat %q unknown!",tmp or "??")
  end

  local farbindex
  if colorname then
    if not publisher.farben[colorname] then
      -- Farbe ist nicht definiert
      err("Color %q is not defined.",colorname)
    else
      farbindex = publisher.farben[colorname].index
    end
  end

  if type(breite)=="table" then
    breite = xpath.get_number_value(breite)
  end

  local width_gridcells = breite

  local breite_sp           = width_gridcells * publisher.current_grid.gridwidth

  local objects, nodes = {},{}
  local nodelist,parameter

  local current_textformat

  local tab = publisher.dispatch(layoutxml,datenxml)

  for i,j in ipairs(tab) do
    local eltname = publisher.elementname(j,true)
    trace("Textblock: Element = %q",tostring(eltname))
    if eltname == "Paragraph" then
      objects[#objects + 1] = publisher.inhalt(j)
    elseif eltname == "Text" then
      assert(false)
    elseif eltname == "Action" then
      objects[#objects + 1] = publisher.inhalt(j)
    elseif eltname == "Bookmark" then
      objects[#objects + 1] = publisher.inhalt(j)
    end
  end
  trace("Textblock: #objects=%d",#objects)
  if columns > 1 then
    breite_sp = math.floor(  (breite_sp - columndistance * ( columns - 1 ) )   / columns)
  end
  for i,j in ipairs(objects) do
    -- jeden <Absatz>, <Bild> oder so durchgehen, jetzt nur <Absatz>
    if j.id == 8 then -- whatsit
      nodes[#nodes + 1] = j
    else
      nodelist = j.nodelist
      assert(nodelist)
      publisher.setze_fontfamilie_wenn_notwendig(nodelist,schriftfamilie)
      j.nodelist = publisher.set_color_if_necessary(nodelist,farbindex)
      nodelist = j:apply_textformat(textformat)
      node.slide(nodelist)
      publisher.fonts.pre_linebreak(nodelist)
      if j.textformat and publisher.textformate[j.textformat] then
        current_textformat = publisher.textformate[j.textformat]
      else
        current_textformat = publisher.textformate[textformat]
      end
      if current_textformat then
        trace("Textblock: wende Textformate an")
        local alignment = current_textformat.alignment
        if alignment == "linksbündig"  then parameter = { rightskip = publisher.rightskip } end
        if alignment == "rechtsbündig" then parameter = { leftskip  = publisher.leftskip  } end
        if alignment == "zentriert"    then parameter = { leftskip  = publisher.leftskip, rightskip = publisher.rightskip } end
        if alignment == "linksbündig" or alignment == "rechtsbündig" or alignment == "zentriert" then
          for i in node.traverse_id(publisher.glue_node,nodelist) do
            spec = i.spec
            if not spec.stretch_order or spec.stretch_order == 0 then
              spec.shrink = nil
              spec.stretch = nil
            end
          end
        end
      end
      nodelist = publisher.do_linebreak(nodelist,breite_sp,parameter)
      nodes[#nodes + 1] = nodelist
      -- hier könnte ich ein Paragraph:apply_textformat einfügen
    end -- wenn's wirklich ein node ist
  end -- alle objects
  -- debug
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
    nodelist = publisher.rotiere(nodelist,angle)
  end
  trace("Textbock: end")
  return nodelist
end

function trennvorschlag( layoutxml,datenxml )
  lang.hyphenation(publisher.languages.de,layoutxml[1])
end

-- Underline text
function underline( layoutxml,datenxml )
  trace("Underline")

  local a = publisher.Paragraph:new()
  local objects = {}
  local tab = publisher.dispatch(layoutxml,datenxml)

  for i,j in ipairs(tab) do
    if publisher.elementname(j,true) == "Value" and type(publisher.inhalt(j)) == "table" then
      objects[#objects + 1] = publisher.parse_html(publisher.inhalt(j))
    else
      objects[#objects + 1] = publisher.inhalt(j)
    end
  end
  for _,j in ipairs(objects) do
    a:append(j,{schriftfamilie = 0, underline = 1})
  end
  return a
end

-- Weist einer Variablen einen Wert zu
function zuweisung( layoutxml,datenxml )
  local trace_p = publisher.read_attribute(layoutxml,datenxml,"trace","boolean")
  local auswahl = publisher.read_attribute(layoutxml,datenxml,"select","string")

  -- FIXME: wenn in der Variablen schon nodelisten sind, dann müssen diese gefreed werden!
  local varname = publisher.read_attribute(layoutxml,datenxml,"variable","string")

  trace("Zuweisung, Variable = %q",varname or "???")
  if not varname then
    err("Variable name in »Zuweisung« not recognized")
    return
  end
  local inhalt

  if auswahl then
    inhalt = xpath.parse(datenxml,auswahl)
  else
    local tab = publisher.dispatch(layoutxml,datenxml)
    inhalt = tab
  end

  if type(inhalt)=="table" then
    local ret
    for i=1,#inhalt do
      local eltname = publisher.elementname(inhalt[i],true)
      local contents = publisher.inhalt(inhalt[i])
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
      elseif eltname == "Elementstruktur" then
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
      inhalt = ret
    end
  end
  if trace_p then
    log("»Zuweisung«, variable name = %q, value = %q",varname or "???", tostring(inhalt))
    printtable("Zuweisung",inhalt)
  end

  publisher.variablen[varname] = inhalt
end

function wert( layoutxml,datenxml )
  local auswahl = publisher.read_attribute(layoutxml,datenxml,"select","string")

  local tab,inhalt
  if auswahl then
    tab = xpath.parse(datenxml,auswahl)
  else
    tab = table.concat(layoutxml)
  end
  return tab
end

-- Gibt eine Nummer zurück. Unter dieser Nummer ist in der Tabelle @publisher.user_defined_funktionen@
-- eine Funktion gespeichert, die zu einer Tabelle eine Schlüssel/Wert-Kombination hinzufügt.
function zur_liste_hinzufuegen( layoutxml,datenxml )
  local schluessel = publisher.read_attribute(layoutxml,datenxml,"key","string")
  local listenname = publisher.read_attribute(layoutxml,datenxml,"liste","string")
  local auswahl    = publisher.read_attribute(layoutxml,datenxml,"select","string")

  local wert = xpath.parse(datenxml,auswahl)
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
