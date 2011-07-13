-- 
--  src/lua/element.lua
--  speedata publisher
--  
--  Created by Patrick Gundlach on 2010-03-10.
--  Copyright 2010 Patrick Gundlach. All rights reserved.
-- 

datei_start("element.lua")
require("publisher.fonts")
require("publisher.tabelle")
require("xpath")
require("fileutils")
require("publisher.helper")

-- Dieses Modul enthält die Einstiegspunkte der Layout-Tags.
module(...,package.seeall)

-- Setzt den Text im XML-Element "Absatz".
function absatz( layoutxml,datenxml )
  local textformat = publisher.lese_attribut_jit(layoutxml,datenxml,"textformat","string")
  local schriftfamilie
  if layoutxml.schriftart then
    local schriftartname = publisher.lese_attribut_jit(layoutxml,datenxml,"schriftart","string")
    schriftfamilie = publisher.fonts.lookup_schriftfamilie_name_nummer[schriftartname]
    if schriftfamilie == nil then
      err("Fontfamily %q not found.",layoutxml.schriftart)
      schriftfamilie = 0
    end
  else
    schriftfamilie = 0
  end

  local sprachcode  = publisher.optionen.defaultsprache or 0
  local sprache_de  = publisher.lese_attribut_jit(layoutxml,datenxml,"sprache","string")
  sprache_de_internal = {
     ["Deutsch"]                        = "de-1996",
     ["Englisch (Großbritannien)"]      = "en-gb",
     ["Französisch"]                    = "fr",
     }
  if sprache_de then
    sprachcode = publisher.hole_sprachcode(sprache_de_internal[sprache_de])
  end

  local farbname = publisher.lese_attribut_jit(layoutxml,datenxml,"farbe","string")
  local farbindex
  if farbname then
    if not publisher.farben[farbname] then
      error("Farbe %q ist nicht defniert.",farbname)
    else
      farbindex = publisher.farben[farbname].index
    end
  end


  local a = publisher.Absatz:new(textformat)
  local objekte = {}
  local tab = publisher.dispatch(layoutxml,datenxml)

  for i,j in ipairs(tab) do
    trace("Absatz Elementname = %q",tostring(publisher.elementname(j)))
    if publisher.elementname(j) == "Wert" and type(publisher.inhalt(j)) == "table" then
      objekte[#objekte + 1] = publisher.parse_html(publisher.inhalt(j))
    else
      objekte[#objekte + 1] = publisher.inhalt(j)
    end
  end
  for _,j in ipairs(objekte) do
    a:anhaengen(j,{schriftfamilie = schriftfamilie, sprachcode = sprachcode})
  end
  if #objekte == 0 then
    -- irgendwie ist da nichts durchgekommen.
    warning("No contents found in paragraph.")
    a:anhaengen("",{schriftfamilie = schriftfamilie,sprachcode = sprachcode})
  end

  a:setze_farbe(farbindex)
  return a
end

-- Erzeugt ein 44er whatsit node (user_defined)
function aktion( layoutxml,datenxml)
  local tab = publisher.dispatch(layoutxml,datenxml)
  local ret = {}

  for _,j in ipairs(tab) do
    if publisher.elementname(j) == "ZurListeHinzufügen" then
      local n = node.new("whatsit","user_defined")
      n.type = 100 -- number
      n.value = publisher.inhalt(j) -- Zeiger auf die Funktion (int)
      ret[#ret + 1] = n
    end
  end
  return ret
end

-- Erzeugt ein Attribut für die XML-Struktur
function attribut( layoutxml,datenxml )
  local attname  = publisher.lese_attribut_jit(layoutxml,datenxml,"name","string")
  local attvalue = xpath.textvalue(xpath.parse(datenxml,layoutxml.auswahl))
  local ret = { [".__type"]="attribute", [attname] = attvalue }
  return ret
end

function bearbeite_datensatz( layoutxml,datenxml )
  trace("BearbeiteDatensatz")
  local datensatz = xpath.parse(datenxml,layoutxml.auswahl)
  local umfang
  if layoutxml.umfang then
    umfang = math.min(#datensatz,tonumber(layoutxml.umfang))
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
  local letzte_position = publisher.variablen.__position
  local modus = publisher.lese_attribut_jit(layoutxml,datenxml,"modus","string") or ""
  local layoutknoten = publisher.datensatz_verteiler[modus][layoutxml.auswahl]
  local pos = 1
  if type(layoutknoten)=="table" then
    for i,j in ipairs(datenxml) do
      if j[".__name"]==layoutxml.auswahl then
        log("Selecting node: %q, mode=%q, pos=%d",layoutxml.auswahl,modus, pos)
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
  local breite = publisher.lese_attribut_jit(layoutxml,datenxml,"breite","string")
  local hoehe  = publisher.lese_attribut_jit(layoutxml,datenxml,"höhe",  "string")

  local seite     = publisher.lese_attribut_jit(layoutxml,datenxml,"seite","number")
  local nat_box   = publisher.lese_attribut_jit(layoutxml,datenxml,"natürliche-größe","string")
  local max_box   = publisher.lese_attribut_jit(layoutxml,datenxml,"maximale-größe","string")
  local dateiname = publisher.lese_attribut_jit(layoutxml,datenxml,"datei","string")

  local nat_box_intern = box_lookup[nat_box] or "crop"
  local max_box_intern = box_lookup[max_box] or "crop"

  publisher.seite_einrichten()

  local breite_sp, hoehe_sp
  if breite and not tonumber(breite) then
    -- breite ist keine Zahl, sondern eine Maßangabe
    breite_sp = tex.sp(breite)
  else
    breite_sp = breite * publisher.aktuelles_raster.rasterbreite
  end

  if hoehe then
    if tonumber(hoehe) then
      hoehe_sp  = hoehe * publisher.aktuelles_raster.rasterhoehe
    else
      hoehe_sp = tex.sp(hoehe)
    end
  end

  local bild = publisher.neues_bild(dateiname,seite,max_box_intern)
  local skalierungsfaktor_wd = breite_sp / bild.width
  local skalierungsfaktor = skalierungsfaktor_wd
  if hoehe_sp then
    local skalierungsfaktor_ht = hoehe_sp / bild.height
    skalierungsfaktor = math.min(skalierungsfaktor_ht,skalierungsfaktor_wd)
  end

  local shift_left,shift_up

  if nat_box_intern ~= max_box_intern then
    -- Das Bild muss vergrößert und dann nach links und oben verschoben werden
    local img_min = publisher.bildinfo(dateiname,seite,nat_box_intern)
    shift_left = ( bild.width  - img_min.width )  / 2
    shift_up =   ( bild.height - img_min.height ) / 2
    skalierungsfaktor = skalierungsfaktor * ( bild.width / img_min.width )
  else
    shift_left,shift_up = 0,0
  end

  bild.width  = bild.width  * skalierungsfaktor
  bild.height = bild.height * skalierungsfaktor

  log("Load image %q with scaling %g",dateiname,skalierungsfaktor)
  local hbox = node.hpack(img.node(bild))
  node.set_attribute(hbox, publisher.att_shift_left, shift_left)
  node.set_attribute(hbox, publisher.att_shift_up  , shift_up  )
  return hbox
end

function box( layoutxml,datenxml )
  local breite = publisher.lese_attribut_jit(layoutxml,datenxml,"breite","number")
  local hoehe  = publisher.lese_attribut_jit(layoutxml,datenxml,"höhe","number")
  local hf_string = publisher.lese_attribut_jit(layoutxml,datenxml,"hintergrundfarbe","string")

  local aktuelles_raster = publisher.aktuelles_raster
  local _breite = publisher.helper.sp_to_bp(aktuelles_raster.rasterbreite * breite)
  local _hoehe  = publisher.helper.sp_to_bp(aktuelles_raster.rasterhoehe  * hoehe)
  local n = publisher.box(_breite,_hoehe,hf_string)
  n = node.hpack(n)
  return n
end

-- Anweisung im Layoutxml, dass für ein bestimmtes Element diese
-- Layoutregel aufgerufen werden soll.
function datensatz( layoutxml )
  local elementname = layoutxml.element
  local modus = layoutxml.modus
  modus = modus or ""
  publisher.datensatz_verteiler[modus] = publisher.datensatz_verteiler[modus] or {}
  publisher.datensatz_verteiler[modus][elementname] = layoutxml
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
  local name   = layoutxml.name
  log("Defining color %q",name)
  local modell = layoutxml.modell
  local farbe = { modell = modell }
  if modell=="cmyk" then
    farbe.c = tonumber(layoutxml.c)
    farbe.m = tonumber(layoutxml.m)
    farbe.y = tonumber(layoutxml.y)
    farbe.k = tonumber(layoutxml.k)
    farbe.pdfstring = string.format("%g %g %g %g k %g %g %g %g K", farbe.c/100, farbe.m/100, farbe.y/100, farbe.k/100,farbe.c/100, farbe.m/100, farbe.y/100, farbe.k/100)
  elseif modell=="rgb" then
    farbe.r = tonumber(layoutxml.r)
    farbe.g = tonumber(layoutxml.g)
    farbe.b = tonumber(layoutxml.b)
    farbe.pdfstring = string.format("%g %g %g rg %g %g %g RG", farbe.r/100, farbe.g/100, farbe.b/100, farbe.r/100,farbe.g/100, farbe.b/100)
  else
    err("Unknown color model: %s",modell or "?")
  end
  publisher.farbindex[#publisher.farbindex + 1] = name
  farbe.index = #publisher.farbindex
  publisher.farben[name]=farbe
end

-- Definiert ein Textformat
function definiere_textformat(layoutxml)
  local fmt = {}

  if layoutxml.ausrichtung=="linksbündig" then
    fmt.ausrichtung = "linksbündig"
  elseif layoutxml.ausrichtung=="rechtsbündig" then
    fmt.ausrichtung = "rechtsbündig"
  elseif layoutxml.ausrichtung=="zentriert" then
    fmt.ausrichtung = "zentriert"
  else
    fmt.ausrichtung = "blocksatz"
  end
  if layoutxml["einrückung"] then
    fmt.indent = tex.sp(layoutxml["einrückung"])
  end
  publisher.textformate[layoutxml.name] = fmt
end


-- Definiert eine Schriftfamilie
function definiere_schriftfamilie( layoutxml,datenxml )
  -- hier müssen die konkreten Instanzen erzeugt werden. Schriftgröße
  -- und Zeilenabstand sind bekannt.
  local fonts = publisher.fonts
  local fam={}
  -- Schriftgröße, Zeilenabstand sind in big points (1 bp ≈ 65782 sp)
  fam.size          = publisher.lese_attribut_jit(layoutxml,datenxml,"schriftgröße","number")  * 65782
  fam.zeilenabstand = publisher.lese_attribut_jit(layoutxml,datenxml,"zeilenabstand","number") * 65782
  fam.scriptsize    = fam.size * 0.8 -- subscript / superscript
  fam.scriptshift   = fam.size * 0.3

  if not fam.size then
    err("»DefiniereSchriftfamilie«: no size given.")
    return
  end
  local ok,tmp
  for i,v in ipairs(layoutxml) do
    if type(v) ~= "table" then
     -- ignorieren
    elseif v[".__name"]=="Normal" then
      ok,tmp=fonts.erzeuge_fontinstanz(v.schriftart,fam.size)
      if ok then
        fam.normal = tmp
      else
        fam.normal = 1
        err("Fontinstance 'normal' could not be created for %q.",tostring(v.schriftart))
      end
      ok,tmp=fonts.erzeuge_fontinstanz(v.schriftart,fam.scriptsize)
      if ok then
        fam.normalscript = tmp
      end
    elseif v[".__name"]=="Fett" then
      ok,tmp=fonts.erzeuge_fontinstanz(v.schriftart,fam.size)
      if ok then
        fam.fett = tmp
      end
      ok,tmp=fonts.erzeuge_fontinstanz(v.schriftart,fam.scriptsize)
      if ok then
        fam.fettscript = tmp
      end
    elseif v[".__name"] =="Kursiv" then
      ok,tmp=fonts.erzeuge_fontinstanz(v.schriftart,fam.size)
      if ok then
        fam.kursiv = tmp
      end
      ok,tmp=fonts.erzeuge_fontinstanz(v.schriftart,fam.scriptsize)
      if ok then
        fam.kursivscript = tmp
      end
    elseif v[".__name"] =="FettKursiv" then
      ok,tmp=fonts.erzeuge_fontinstanz(v.schriftart,fam.size)
      if ok then
        fam.fettkursiv = tmp
      end
      ok,tmp=fonts.erzeuge_fontinstanz(v.schriftart,fam.scriptsize)
      if ok then
        fam.fettkursivscript = tmp
      end
    end
    if type(v) == "table" and not ok then
      err("Error creating font instance %q: %s", v[".__name"] or "??", tmp or "??")
    end
  end
  fonts.lookup_schriftfamilie_nummer_instanzen[#fonts.lookup_schriftfamilie_nummer_instanzen + 1] = fam
  fonts.lookup_schriftfamilie_name_nummer[layoutxml.name]=#fonts.lookup_schriftfamilie_nummer_instanzen
  log("»DefiniereSchriftfamilie«, family=%d, name=%q",#fonts.lookup_schriftfamilie_nummer_instanzen,layoutxml.name)
end

-- Erzeugt ein Element für die XML-Struktur
function element( layoutxml,datenxml )
  local elementname = publisher.lese_attribut_jit(layoutxml,datenxml,"name","string")
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
  local sonst,ret
  for i,v in ipairs(layoutxml) do
    if type(v)=="table" and v[".__name"]=="Fall" and fall_ausgefuehrt ~= true then
      local fall = v
      assert(fall.bedingung)
      if xpath.parse(datenxml,fall.bedingung) then
        fall_ausgefuehrt = true
        ret = publisher.dispatch(fall,datenxml)
      end
    elseif type(v)=="table" and v[".__name"]=="Sonst" then
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
  local a = publisher.Absatz:new()

  local objekte = {}
  local tab = publisher.dispatch(layoutxml,datenxml)

  for i,j in ipairs(tab) do
    if publisher.elementname(j) == "Wert" and type(publisher.inhalt(j)) == "table" then
      objekte[#objekte + 1] = publisher.parse_html(publisher.inhalt(j))
    else
      objekte[#objekte + 1] = publisher.inhalt(j)
    end
  end
  for _,j in ipairs(objekte) do
    a:anhaengen(j,{schriftfamilie = 0, fett = 1})
  end

  return a
end

function gruppe( layoutxml,datenxml )
  publisher.seite_einrichten()
  local gruppenname = layoutxml.name

  if publisher.gruppen[gruppenname] == nil then
    log("Create »Gruppe« %s an.",gruppenname)
  else
    node.flush_list(publisher.gruppen[gruppenname].inhalt)
    publisher.gruppen[gruppenname] = nil
  end
  
  local r = publisher.raster:new()
  r:setze_rand(0,0,0,0)
  r:setze_breite_hoehe(publisher.aktuelle_seite.raster.rasterbreite,publisher.aktuelle_seite.raster.rasterhoehe)
  publisher.gruppen[gruppenname] = { 
    inhalt = inhalt,
    raster  = r,
  }
  
  local merke_raster      = publisher.aktuelles_raster
  local merke_gruppenname = publisher.aktuelle_gruppe

  publisher.aktuelle_gruppe=gruppenname
  publisher.aktuelles_raster = r

  for _,v in ipairs(layoutxml) do
    if type(v)=="table" and v[".__name"]=="Inhalt" then
      publisher.dispatch(v,datenxml)
    end
  end

  publisher.aktuelle_gruppe  = merke_gruppenname
  publisher.aktuelles_raster = merke_raster
end

-- Dummy-Element fürs Einbinden von xi:include-Dateien
function include( layoutxml,datenxml )
  return publisher.dispatch(layoutxml,datenxml)
end

-- Text in kursiver Schrift
function kursiv( layoutxml,datenxml )
  local a = publisher.Absatz:new()
  local objekte = {}
  local tab = publisher.dispatch(layoutxml,datenxml)

  for i,j in ipairs(tab) do
    if publisher.elementname(j) == "Wert" and type(publisher.inhalt(j)) == "table" then
      objekte[#objekte + 1] = publisher.parse_html(publisher.inhalt(j))
    else
      objekte[#objekte + 1] = publisher.inhalt(j)
    end
  end
  for _,j in ipairs(objekte) do
    a:anhaengen(j,{schriftfamilie = 0, kursiv = 1})
  end
  return a
end

-- XPath Ausdruck um einen Wert aus den Daten zu extrahieren. Gibt eine Sequenz zurück
function kopie_von( layoutxml,datenxml )
  if layoutxml[1] and #layoutxml[1] > 0 then
    return table.concat(layoutxml)
  else
    local auswahl = xpath.parse(datenxml,layoutxml.auswahl)
    trace("Kopie-von: type(auswahl)=%q",type(auswahl))
    return auswahl
  end
end

-- Lädt eine Schriftdatei
function lade_schriftdatei( layoutxml,datenxml )
  local randausgleich = publisher.lese_attribut_jit(layoutxml,datenxml,"randausgleich","number")
  local leerraum      = publisher.lese_attribut_jit(layoutxml,datenxml,"leerraum","number")
  local smcp          = publisher.lese_attribut_jit(layoutxml,datenxml,"kapitälchen","string")

  local extra_parameter = {
    leerraum      = leerraum      or 25,
    randausgleich = randausgleich or 0,
    otfeatures    = {
      smcp = smcp == "ja",
    },
  }

  publisher.fonts.lade_schriftdatei(layoutxml.name,layoutxml.dateiname,extra_parameter)
end

-- Lädt eine Datensatzdatei (XML) und startet die Verarbeitung 
function lade_datensatzdatei( layoutxml,datenxml )
  local name = layoutxml.name
  local tmp_daten
  assert(name)
  local dateiname = "datensatzdatei." .. name

  if fileutils.test("x",dateiname)==false then
    -- Beim ersten Lauf gibt es die Datei nicht. Das ist nicht schlimm.
    return
  end
  
  local tmp_daten = publisher.lade_xml(dateiname)
  local root_name = tmp_daten[".__name"]

  log("»Bearbeite Knoten«: %q, modus=%q",root_name,"")
  publisher.dispatch(publisher.datensatz_verteiler[""][root_name],tmp_daten)
end

function leerzeile( layoutxml,datenxml )
  trace("Leerzeile, aktuelle Zeile = %d",publisher.aktuelles_raster:aktuelle_zeile())
  local bereichname = publisher.lese_attribut_jit(layoutxml,datenxml,"bereich","string")
  local bereichname = bereichname or publisher.default_bereichname
  local aktuelles_raster = publisher.aktuelles_raster
  local aktuelle_zeile = aktuelles_raster:finde_passende_zeile(1,aktuelles_raster:anzahl_spalten(),1,bereichname)
  if not aktuelle_zeile then
    aktuelles_raster:setze_aktuelle_zeile(1)
  else
    aktuelles_raster:setze_aktuelle_zeile(aktuelle_zeile + 1)
  end
end

function linie( layoutxml,datenxml )
  local richtung      = publisher.lese_attribut_jit(layoutxml,datenxml,"richtung",    "string")
  local laenge        = publisher.lese_attribut_jit(layoutxml,datenxml,"länge",       "string")
  local linienstaerke = publisher.lese_attribut_jit(layoutxml,datenxml,"linienstärke","string")

  if tonumber(laenge) then
    if richtung == "horizontal" then
      laenge = publisher.aktuelles_raster.rasterbreite * laenge
    elseif richtung == "vertikal" then
      laenge = publisher.aktuelles_raster.rasterhoehe * laenge
    else
      err("Attribute »richtung« with »Linie«: unknown direction: %q",richtung)
    end
  else
    laenge = tex.sp(laenge)
  end
  laenge = publisher.helper.sp_to_bp(laenge)

  linienstaerke = linienstaerke or "1pt"
  if tonumber(linienstaerke) then
    if richtung == "horizontal" then
      linienstaerke = publisher.aktuelles_raster.rasterbreite * linienstaerke
    elseif richtung == "vertikal" then
      linienstaerke = publisher.aktuelles_raster.rasterhoehe * linienstaerke
    end
  else
    linienstaerke = tex.sp(linienstaerke)
  end
  linienstaerke = publisher.helper.sp_to_bp(linienstaerke)

  local farbname = "Schwarz"

  local n = node.new("whatsit","pdf_literal")
  n.mode = 0
  if richtung == "horizontal" then
    n.data = string.format("q %d w %s 0 0 m %g 0 l S Q",linienstaerke,publisher.farben[farbname].pdfstring,laenge)
  elseif richtung == "vertikal" then
    n.data = string.format("q %d w %s 0 0 m 0 %g l S Q",linienstaerke,publisher.farben[farbname].pdfstring,-laenge)
  else
    --
  end
  n = node.hpack(n)
  return n
end

-- Schreibt eine Meldung in Terminal
function nachricht( layoutxml, datenxml )
  local inhalt
  if layoutxml.auswahl then
    inhalt = xpath.parse(datenxml,layoutxml.auswahl)
  else
    local tab = publisher.dispatch(layoutxml,datenxml)
    inhalt = tab
  end
  if type(inhalt)=="table" then
    local ret
    for i=1,#inhalt do
      local eltname = publisher.elementname(inhalt[i])
      local contents = publisher.inhalt(inhalt[i])

      if eltname == "Sequenz" or eltname == "Wert" then
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
  local bereichname = publisher.lese_attribut_jit(layoutxml,datenxml,"bereich","string")
  publisher.naechster_rahmen(bereichname)
end

function neue_zeile( layoutxml,datenxml )
  publisher.seite_einrichten()
  local bereichname = publisher.lese_attribut_jit(layoutxml,datenxml,"bereich","string")
  local bereichname = bereichname or publisher.default_bereichname
  local raster = publisher.aktuelles_raster
  local aktuelle_zeile = raster:finde_passende_zeile(1,raster:anzahl_spalten(),1,bereichname)
  if not aktuelle_zeile then
    neue_seite()
    publisher.seite_einrichten()
    raster = publisher.aktuelle_seite.raster
    raster:setze_aktuelle_zeile(1)
  else
    raster:setze_aktuelle_zeile(aktuelle_zeile)
  end
end

-- Erzeugt eine neue Seite
function neue_seite( )
  publisher.neue_seite()
end

-- Formatiert die angegebene URL etwas besser für den Satz.
function url(layoutxml,datenxml)
  local a = publisher.Absatz:new()
  local tab = publisher.dispatch(layoutxml,datenxml)
  for i,j in ipairs(tab) do
    a:anhaengen(xpath.textvalue(publisher.inhalt(j)),{})
    a.nodelist = publisher.umbreche_url(a.nodelist)
  end
  return a
end

-- Gibt ein rechteckiges Objekt (derzeit nur Bild) aus
function objekt_ausgeben( layoutxml,datenxml )
  local absolute_positionierung = false
  local spalte           = publisher.lese_attribut_jit(layoutxml,datenxml,"spalte",          "string")
  local zeile            = publisher.lese_attribut_jit(layoutxml,datenxml,"zeile",           "string")
  local bereich          = publisher.lese_attribut_jit(layoutxml,datenxml,"bereich",         "string")
  local belegen          = publisher.lese_attribut_jit(layoutxml,datenxml,"belegen",         "string")
  local rahmenfarbe      = publisher.lese_attribut_jit(layoutxml,datenxml,"rahmenfarbe",     "string")
  local hintergrundfarbe = publisher.lese_attribut_jit(layoutxml,datenxml,"hintergrundfarbe","string")
  local maxhoehe         = publisher.lese_attribut_jit(layoutxml,datenxml,"maxhöhe",         "number")
  local rahmen           = layoutxml.rahmen
  local hintergrund      = layoutxml.hintergrund
  bereich = bereich or publisher.default_bereichname

  if spalte and not tonumber(spalte) then
    -- spalte scheint ein String zu sein
    absolute_positionierung = true
    spalte = tex.sp(spalte)
  end

  if zeile and not tonumber(zeile) then
    -- zeile scheint ein String zu sein
    absolute_positionierung = true
    zeile = tex.sp(zeile)
  end

  if absolute_positionierung then
    if not ( zeile and spalte ) then
      err("»Spalte« and »Zeile« must be given with absolute positioning (»ObjektAusgeben«).")
      return
    end
  end

  publisher.seite_einrichten()

  trace("Spalte = %q",tostring(spalte))
  trace("Zeile = %q",tostring(zeile))

  local aktuelle_zeile_start  = publisher.aktuelles_raster:aktuelle_zeile(bereich)
  local aktuelle_spalte_start = spalte or publisher.aktuelles_raster:aktuelle_spalte(bereich)

  -- Die Höhe auf dieser Seite ist entweder das Minimum von verbleibende Platz oder maxhöhe
  local max_ht_aktuell =  math.min(publisher.aktuelles_raster:anzahl_zeilen(bereich) - ( zeile or publisher.aktuelles_raster:aktuelle_zeile(bereich) ) + 1, maxhoehe or publisher.aktuelles_raster:anzahl_zeilen(bereich))
  local optionen = {
    ht_aktuell = publisher.aktuelles_raster.rasterhoehe * max_ht_aktuell,
    ht_max     = publisher.aktuelles_raster.rasterhoehe * ( maxhoehe or publisher.aktuelles_raster:anzahl_zeilen(bereich) ),
  }

  local raster = publisher.aktuelles_raster
  local tab    = publisher.dispatch(layoutxml,datenxml,optionen)

  local objekte = {}
  local objekt, objekttyp

  if layoutxml.gruppenname then
    local gruppenname = layoutxml.gruppenname
    objekte[1] = { objekt = node.copy(publisher.gruppen[gruppenname].inhalt), 
      objekttyp = string.format("Gruppe (%s)", gruppenname)}
  else
    for i,j in ipairs(tab) do
      objekt = publisher.inhalt(j)
      objekttyp = publisher.elementname(j)
      if type(objekt)=="table" then
        for i=1,#objekt do
          objekte[#objekte + 1] = {objekt = objekt[i], objekttyp = objekttyp }
        end
      else
        objekte[#objekte + 1] = {objekt = objekt, objekttyp = objekttyp }
      end
    end
  end
  for i=1,#objekte do
    raster = publisher.aktuelles_raster
    objekt    = objekte[i].objekt
    objekttyp = objekte[i].objekttyp

    if hintergrund == "vollständig" then
      objekt = publisher.hintergrund(objekt,hintergrundfarbe)
    end
    if rahmen == "durchgezogen" then
      objekt = publisher.rahmen(objekt,rahmenfarbe)
    end

    if publisher.optionen.trace=="ja" then
      publisher.boxit(objekt)
    end

    if absolute_positionierung then
      publisher.ausgabe_bei_absolut(objekt,spalte + raster.extra_rand,zeile + raster.extra_rand,belegen ~= "nein")
    else
      -- Platz muss gesucht werden
      -- local aktuelle_zeile = raster:aktuelle_zeile(bereich)
      trace("ObjektAusgeben: Breitenberechnung")
      if not node.has_field(objekt,"width") then
        warning("Can't calculate with object's width!")
      end
      local breite_in_rasterzellen = raster:breite_in_rasterzellen_sp(objekt.width)
      local hoehe_in_rasterzellen  = raster:hoehe_in_rasterzellen_sp (objekt.height + objekt.depth)
      trace("ObjektAusgeben: Breitenberechnung abgeschlossen: wd=%d,ht=%d",breite_in_rasterzellen,hoehe_in_rasterzellen)

      trace("ObjektAusgeben: finde passende Zeile für das Objekt, aktuelle_zeile = %d",zeile or raster:aktuelle_zeile(bereich) or "-1")
      if zeile then
        aktuelle_zeile = zeile
      else
        aktuelle_zeile = nil
      end

      -- Solange auf den nächsten Rahmen schalten, bis eine freie Fläche gefunden werden kann.
      while aktuelle_zeile == nil do
        if not spalte then
          -- Keine Zeile und keine Spalte angegeben. Dann suche ich mir doch die richtigen Werte selbst.
          if aktuelle_spalte_start + breite_in_rasterzellen - 1 > raster:anzahl_spalten() then
            aktuelle_spalte_start = 1
          end
        end
        aktuelle_zeile = raster:finde_passende_zeile(aktuelle_spalte_start,breite_in_rasterzellen,hoehe_in_rasterzellen,bereich)
        if not aktuelle_zeile then
          warning("No suitable row found for object")
          publisher.naechster_rahmen(bereich)
          publisher.seite_einrichten()
          raster = publisher.aktuelles_raster
        end
      end

      log("»ObjektAusgeben«: %s in row %d and column %d, width=%d, height=%d", objekttyp, aktuelle_zeile, aktuelle_spalte_start,breite_in_rasterzellen,hoehe_in_rasterzellen)
      trace("»ObjektAusgeben«: objekt placed at (%d,%d)",aktuelle_spalte_start,aktuelle_zeile)
      publisher.ausgabe_bei(objekt,aktuelle_spalte_start,aktuelle_zeile,belegen ~= "nein",bereich)
      trace("Objekt ausgegeben.")
      zeile = nil -- die Zeile ist nicht mehr gültig, da schon ein Objekt ausgegeben wurde
      if i < #objekte then
        neue_zeile(layoutxml,datenxml)
      end
    end -- keine absolute Positionierung
  end
  if belegen=="nein" then
    publisher.aktuelles_raster:setze_aktuelle_zeile(aktuelle_zeile_start)
  end
  trace("Objekte ausgegeben.")
end

    -- if not trace_objekt_counter then  trace_objekt_counter = 0 end
    --   trace_objekt_counter = trace_objekt_counter + 1
    --   viznodelist.nodelist_visualize(objekt,string.format("viz%d.gv",trace_objekt_counter))


-- Speichert Optionen ab
function optionen( layoutxml )
  for k,v in pairs(layoutxml) do
    publisher.optionen[k]=v
  end
end

function platzierungsrahmen( layoutxml, datenxml )
  local spalte = publisher.lese_attribut_jit(layoutxml,datenxml,"spalte","number")
  local zeile  = publisher.lese_attribut_jit(layoutxml,datenxml,"zeile" ,"number")
  local breite = publisher.lese_attribut_jit(layoutxml,datenxml,"breite","number")
  local hoehe  = publisher.lese_attribut_jit(layoutxml,datenxml,"höhe"  ,"number")
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
  local name = publisher.lese_attribut_jit(layoutxml,datenxml,"name","string")
  tab.name = name
  return tab
end

-- Setzt das Papierformat.
function seitenformat(layoutxml)
  publisher.optionen.seitenbreite = tex.sp(layoutxml["breite"])
  publisher.optionen.seitenhoehe  = tex.sp(layoutxml["höhe"])
  tex.pdfpagewidth =  publisher.optionen.seitenbreite
  tex.pdfpageheight = publisher.optionen.seitenhoehe
  tex.pdfpagewidth  = tex.pdfpagewidth   + tex.sp("2cm")
  tex.pdfpageheight = tex.pdfpageheight  + tex.sp("2cm")

  tex.hsize = publisher.optionen.seitenbreite
  tex.vsize = publisher.optionen.seitenhoehe
end

-- Setzt den Rand für diese Seite
function rand( layoutxml,datenxml )
  return function(_seite) _seite.raster:setze_rand(layoutxml.links,layoutxml.oben,layoutxml.rechts,layoutxml.unten) end
end

function raster( layoutxml,datenxml )
  local breite = publisher.lese_attribut_jit(layoutxml,datenxml,"breite","length")
  local hoehe  = publisher.lese_attribut_jit(layoutxml,datenxml,"höhe"  ,"length")
  return { breite = breite, hoehe = hoehe }
end

function schriftart( layoutxml,datenxml )
  local schriftfamilie = publisher.lese_attribut_jit(layoutxml,datenxml,"schriftfamilie","string")
  local familiennummer = publisher.fonts.lookup_schriftfamilie_name_nummer[schriftfamilie]
  if not familiennummer then
    err("font: family %q unknown",schriftfamilie)
  else
    local a = publisher.Absatz:new()
    local tab = publisher.dispatch(layoutxml,datenxml)
    for i,j in ipairs(tab) do
      a:anhaengen(publisher.inhalt(j),{schriftfamilie = familiennummer})
    end
    return a
  end
end

-- Speichert intern die Rasterweite (`breite` und `höhe` im Layoutxml).
function setze_raster(layoutxml)
  publisher.optionen.rasterbreite = layoutxml["breite"]
  publisher.optionen.rasterhoehe  = layoutxml["höhe"]
end

-- Erstellt eine Liste der Seitentypen
function seitentyp(layoutxml,datenxml)
  local tmp_tab = {}
  local bedingung = layoutxml.bedingung
  local tab = publisher.dispatch(layoutxml,datenxml)

  for i,j in ipairs(tab) do
    local eltname = publisher.elementname(j)
    if eltname=="Rand" or eltname == "BeiSeitenAusgabe" or eltname == "BeiSeitenErzeugung" or eltname=="Raster" or eltname=="Platzierungsbereich" then
      tmp_tab [#tmp_tab + 1] = j
    else
      err("Element %q in »Seitentyp« unknown",eltname)
      tmp_tab [#tmp_tab + 1] = j
    end
  end
  -- assert(type(bedingung())=="boolean")
  publisher.seitentypen[#publisher.seitentypen + 1] = { ist_seitentyp = bedingung, res = tmp_tab, name = layoutxml.name }
end

function sequenz( layoutxml,datenxml )
  trace("Sequenz: %s, auswahl = %s",layoutxml[".__name"], layoutxml.auswahl )
  local auswahl = publisher.lese_attribut_jit(layoutxml,datenxml,"auswahl","string")
  local ret = {}
  for i,v in ipairs(datenxml) do
    if type(v)=="table" and v[".__name"] == auswahl then
      ret[#ret + 1] = v
    end
  end
  return ret
end

function solange( layoutxml,datenxml )
  assert(layoutxml.bedingung)
  while xpath.parse(datenxml,layoutxml.bedingung) do
    publisher.dispatch(layoutxml,datenxml)
  end
end

-- Verändert die Reihenfolge in der Variable!
function sortiere_sequenz( layoutxml,datenxml )
  local sequenz = xpath.parse(datenxml,layoutxml.auswahl)
  local duplikate_entfernen = publisher.lese_attribut_jit(layoutxml,datenxml,"duplikatelöschen","string")
  trace("SortiereSequenz: Datensatz = %q, Kriterium = %q",layoutxml.auswahl,layoutxml.kriterium or "???")
  local sortkey = layoutxml.kriterium
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
      -- rückwärts, da sonst die Indizes verschoben werden
      table.remove(tmp,deleteme[i])
    end
  end
  return tmp
end

function spalte( layoutxml,datenxml )
  local ret = {}
  ret.breite           = publisher.lese_attribut_jit(layoutxml,datenxml,"breite","string")
  ret.hintergrundfarbe = publisher.lese_attribut_jit(layoutxml,datenxml,"hintergrundfarbe","string")
  ret.align            = publisher.lese_attribut_jit(layoutxml,datenxml,"align","string")
  ret.valign           = publisher.lese_attribut_jit(layoutxml,datenxml,"valign","string")

  return ret
end

function spalten( layoutxml,datenxml )
  local tab = publisher.dispatch(layoutxml,datenxml)
  return tab
end

function speichere_datensatzdatei( layoutxml,datenxml )
  local towrite, tmp,tab
  local dateiname   = publisher.lese_attribut_jit(layoutxml,datenxml,"dateiname",  "string")
  local elementname = publisher.lese_attribut_jit(layoutxml,datenxml,"elementname","string")

  assert(dateiname)
  assert(elementname)

  if layoutxml.auswahl then
    tab = xpath.parse(datenxml,layoutxml.auswahl)
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
  local datei = io.open(string.format("datensatzdatei.%s",dateiname),"w")
  towrite = publisher.xml_to_string(tmp)
  datei:write(towrite)
  datei:close()
end

function sub( layoutxml,datenxml )
  local a = publisher.Absatz:new()
  local tab = publisher.dispatch(layoutxml,datenxml)
  for i,j in ipairs(tab) do
    a:script(publisher.inhalt(j),1,{schriftfamilie = 0})
  end
  return a
end

function sup( layoutxml,datenxml )
  local a = publisher.Absatz:new()
  local tab = publisher.dispatch(layoutxml,datenxml)
  for i,j in ipairs(tab) do
    a:script(publisher.inhalt(j),2,{schriftfamilie = 0})
  end
  return a
end


function tabelle( layoutxml,datenxml,optionen )
  local breite         = publisher.lese_attribut_jit(layoutxml,datenxml,"breite",        "number")
  local hoehe          = publisher.lese_attribut_jit(layoutxml,datenxml,"höhe",          "number")
  local padding        = publisher.lese_attribut_jit(layoutxml,datenxml,"padding",       "length")
  local spaltenabstand = publisher.lese_attribut_jit(layoutxml,datenxml,"spaltenabstand","length")
  local zeilenabstand  = publisher.lese_attribut_jit(layoutxml,datenxml,"zeilenabstand", "length")
  local schriftartname = publisher.lese_attribut_jit(layoutxml,datenxml,"schriftart",    "string")

  padding        = tex.sp(padding        or "0pt")
  spaltenabstand = tex.sp(spaltenabstand or "0pt")
  zeilenabstand  = tex.sp(zeilenabstand  or "0pt")
  breite = publisher.aktuelles_raster.rasterbreite * breite


  if not schriftartname then schriftartname = "text" end
  schriftfamilie = publisher.fonts.lookup_schriftfamilie_name_nummer[schriftartname]

  if schriftfamilie == nil then
    err("Fontfamily %q not found.",schriftartname or "???")
    schriftfamilie = 1
  end

  local tab = publisher.dispatch(layoutxml,datenxml)

  local tabelle = publisher.tabelle:new()

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
  tabelle.colsep = spaltenabstand
  tabelle.rowsep = zeilenabstand
  tabelle.autostretch = layoutxml.dehnen


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
  local linienstaerke = publisher.lese_attribut_jit(layoutxml,datenxml,"linienstärke","length")
  local farbe = publisher.lese_attribut_jit(layoutxml,datenxml,"farbe","string")
  return { linienstaerke = linienstaerke, farbe = farbe }
end

function tr( layoutxml,datenxml )
  local tab = publisher.dispatch(layoutxml,datenxml)

  local attribute = {
    ["align"]   = "string",
    ["valign"]  = "string",
    ["hintergrundfarbe"] = "string",
    ["minhöhe"] = "number",
  }

  for attname,atttyp in pairs(attribute) do
    tab[attname] = publisher.lese_attribut_jit(layoutxml,datenxml,attname,atttyp)
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
    ["hintergrundfarbe"] = "string",
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
    tab[attname] = publisher.lese_attribut_jit(layoutxml,datenxml,attname,atttyp)
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
  local schriftartname = publisher.lese_attribut_jit(layoutxml,datenxml,"schriftart","string")
  local farbname       = publisher.lese_attribut_jit(layoutxml,datenxml,"farbe","string")
  local breite         = publisher.lese_attribut_jit(layoutxml,datenxml,"breite","number")
  local winkel         = publisher.lese_attribut_jit(layoutxml,datenxml,"winkel","number")
  local spalten        = publisher.lese_attribut_jit(layoutxml,datenxml,"spalten","number")
  local spaltenabstand = publisher.lese_attribut_jit(layoutxml,datenxml,"spaltenabstand","string")
  spalten = spalten or 1
  if not spaltenabstand then spaltenabstand = "3mm" end
  if tonumber(spaltenabstand) then
    spaltenabstand = publisher.aktuelles_raster.rasterbreite * spaltenabstand
  else
    spaltenabstand = tex.sp(spaltenabstand)
  end

  if not schriftartname then schriftartname = "text" end
  schriftfamilie = publisher.fonts.lookup_schriftfamilie_name_nummer[schriftartname]
  if schriftfamilie == nil then
    err("Fontfamily %q not found.",schriftartname or "???")
    schriftfamilie = 1
  end

  local textformat = layoutxml.textformat or "text"
  if not textformat then
    err("»Textblock« textformat %q unknown!",tmp or "??")
  end

  local farbindex
  if farbname then
    if not publisher.farben[farbname] then
      -- Farbe ist nicht definiert
      err("Color %q is not defined.",farbname)
    else
      farbindex = publisher.farben[farbname].index
    end
  end

  if type(breite)=="table" then
    breite = xpath.get_number_value(breite)
  end

  local breite_rasterzellen = breite

  local breite_sp           = breite_rasterzellen * publisher.aktuelles_raster.rasterbreite

  local objekte, nodes = {},{}
  local nodelist,parameter

  local aktuelles_textformat

  local tab = publisher.dispatch(layoutxml,datenxml)

  for i,j in ipairs(tab) do
    trace("Textblock: Element = %q",tostring(publisher.elementname(j)))
    if publisher.elementname(j) == "Absatz" then
      objekte[#objekte + 1] = publisher.inhalt(j)
    elseif publisher.elementname(j) == "Text" then
      -- assert(false)
    elseif publisher.elementname(j) == "Aktion" then
      objekte[#objekte + 1] = publisher.inhalt(j)
    end
  end
  trace("Textblock: #objekte=%d",#objekte)
  if spalten > 1 then
    breite_sp = math.floor(  (breite_sp - spaltenabstand * ( spalten - 1 ) )   / spalten)
  end
  for i,j in ipairs(objekte) do
    -- jeden <Absatz>, <Bild> oder so durchgehen, jetzt nur <Absatz>
    if j.id == 8 then -- whatsit
      nodes[#nodes + 1] = j
    else
      nodelist = j.nodelist
      assert(nodelist)
      publisher.setze_fontfamilie_wenn_notwendig(nodelist,schriftfamilie)
      j.nodelist = publisher.setze_farbe_wenn_notwendig(nodelist,farbindex)
      nodelist = j:textformat_anwenden(textformat)
      node.slide(nodelist)
      publisher.fonts.pre_linebreak(nodelist)
      if j.textformat and publisher.textformate[j.textformat] then
        aktuelles_textformat = publisher.textformate[j.textformat]
      else
        aktuelles_textformat = publisher.textformate[textformat]
      end
      if aktuelles_textformat then
        trace("Textblock: wende Textformate an")
        local ausrichtung = aktuelles_textformat.ausrichtung
        if ausrichtung == "linksbündig"  then parameter = { rightskip = publisher.rightskip } end
        if ausrichtung == "rechtsbündig" then parameter = { leftskip  = publisher.leftskip  } end
        if ausrichtung == "zentriert"    then parameter = { leftskip  = publisher.leftskip, rightskip = publisher.rightskip } end
        if ausrichtung == "linksbündig" or ausrichtung == "rechtsbündig" or ausrichtung == "zentriert" then
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
      -- hier könnte ich ein Absatz:textformat_anwenden einfügen
    end -- wenn's wirklich ein node ist
  end -- alle Objekte
  -- debug
  if #objekte == 0 then
    warning("Textblock: no objects found!")
    local vrule = {  width = 10 * 2^16, height = -1073741824}
    nodes[1] = publisher.add_rule(nil,"head",vrule)
  end

  if spalten > 1 then
    local zeilen = {}
    local zeilenanzahl = 0
    local neue_nodes = {}
    for i=1,#nodes do
      for n in node.traverse_id(0,nodes[i].list) do
        zeilenanzahl = zeilenanzahl + 1
        zeilen[zeilenanzahl] = n
      end
    end

    local zeilenanzahl_mehrspaltiger_satz = math.ceil(zeilenanzahl / spalten)
    for i=1,zeilenanzahl_mehrspaltiger_satz do
      local aktuelle_zeile,hbox_aktuelle_zeile
      hbox_aktuelle_zeile = zeilen[i] -- erste Spalte
      local tail = hbox_aktuelle_zeile
      for j=2,spalten do -- zweite und folgende Spalten
        local g1 = node.new("glue")
        g1.spec = node.new("glue_spec")
        g1.spec.width = spaltenabstand
        tail.next = g1
        g1.prev = tail
        aktuelle_zeile = (j - 1) * zeilenanzahl_mehrspaltiger_satz + i
        if aktuelle_zeile <= zeilenanzahl then
          tail = zeilen[aktuelle_zeile]
          g1.next = tail
          tail.prev = g1
        end
      end
      tail.next = nil
      neue_nodes[#neue_nodes + 1] = node.hpack(hbox_aktuelle_zeile)
    end
    nodes=neue_nodes
  end

  trace("Textbock: nodes verbinden")
  -- nodes[i] verbinden
  local tail
  for i=2,#nodes do
    tail = node.tail(nodes[i-1])
    tail.next = nodes[i]
    nodes[i].prev = tail
  end

  trace("Textbock: vpack()")
  nodelist = node.vpack(nodes[1])
  if winkel then
    nodelist = publisher.rotiere(nodelist,winkel)
  end
  trace("Textbock: Ende")
  return nodelist
end

function trennvorschlag( layoutxml,datenxml )
  lang.hyphenation(publisher.languages.de,layoutxml[1])
end
-- Text unterstreichen
function unterstreichen( layoutxml,datenxml )
  local a = publisher.Absatz:new()
  local objekte = {}
  local tab = publisher.dispatch(layoutxml,datenxml)

  for i,j in ipairs(tab) do
    if publisher.elementname(j) == "Wert" and type(publisher.inhalt(j)) == "table" then
      objekte[#objekte + 1] = publisher.parse_html(publisher.inhalt(j))
    else
      objekte[#objekte + 1] = publisher.inhalt(j)
    end
  end
  for _,j in ipairs(objekte) do
    a:anhaengen(j,{schriftfamilie = 0, unterstreichen = 1})
  end
  return a
end

-- Weist einer Variablen einen Wert zu
function zuweisung( layoutxml,datenxml )
  -- FIXME: wenn in der Variablen schon nodelisten sind, dann müssen diese gefreed werden!
  local varname = publisher.lese_attribut_jit(layoutxml,datenxml,"variable","string")

  trace("Zuweisung, Variable = %q",varname or "???")
  if not varname then
    err("Variable name in »Zuweisung« not recognized")
    return
  end
  local inhalt

  if layoutxml.auswahl then
    inhalt = xpath.parse(datenxml,layoutxml.auswahl)
  else
    local tab = publisher.dispatch(layoutxml,datenxml)
    inhalt = tab
  end
  -- printtable("Zuweisung",inhalt)

  if type(inhalt)=="table" then
    local ret
    for i=1,#inhalt do
      local eltname = publisher.elementname(inhalt[i])
      local contents = publisher.inhalt(inhalt[i])
      if eltname == "Sequenz" or eltname == "Wert" or eltname == "SortiereSequenz" then
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
  if layoutxml.trace=="ja" then
    log("»Zuweisung«, variable name = %q, value = %q",varname or "???", tostring(inhalt))
    printtable("Zuweisung",inhalt)
  end

  publisher.variablen[varname] = inhalt
end

function wert( layoutxml,datenxml )
  local tab,inhalt
  if layoutxml.auswahl then
    tab = xpath.parse(datenxml,layoutxml.auswahl)
  else
    tab = table.concat(layoutxml)
  end
  return tab
end

-- Gibt eine Nummer zurück. Unter dieser Nummer ist in der Tabelle @publisher.user_defined_funktionen@
-- eine Funktion gespeichert, die zu einer Tabelle eine Schlüssel/Wert-Kombination hinzufügt.
function zur_liste_hinzufuegen( layoutxml,datenxml )
  local schluessel = publisher.lese_attribut_jit(layoutxml,datenxml,"schlüssel","string")
  local listenname = publisher.lese_attribut_jit(layoutxml,datenxml,"liste","string")
  local wert = xpath.parse(datenxml,layoutxml.auswahl)
  if not publisher.variablen[listenname] then
    publisher.variablen[listenname] = {}
  end
  local udef = publisher.user_defined_funktionen
  local var  = publisher.variablen[listenname]
  udef[udef.last + 1] = function() var[#var + 1] = { schluessel , wert } end
  udef.last = udef.last + 1
  return udef.last
end

datei_ende("element.lua")
