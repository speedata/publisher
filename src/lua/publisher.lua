--
--  publisher/src/lua/publisher.lua
--  speedata publisher
--
--  Created by Patrick Gundlach on 2010-03-10.
--  Copyright 2010 Patrick Gundlach. All rights reserved.
--

datei_start("publisher.lua")

local element = require("publisher.element")
local seite   = require("publisher.seite")
sd_xpath_funktionen      = require("publisher.layout_funktionen")
orig_xpath_funktionen    = require("publisher.xpath_funktionen")

local xmlparser = require("xmlparser")


att_schriftfamilie = 1
att_kursiv         = 2
att_fett           = 3
att_script         = 4
att_unterstreichen = 5

-- Für die Ausrichtung der Bilder
att_shift_left     = 100
att_shift_up       = 101

-- tie glue (U+00A0)
att_tie_glue       = 201

require("viznodelist")

module(...,package.seeall)

glue_spec_node = node.id("glue_spec")
glue_node      = node.id("glue")
glyph_node     = node.id("glyph")
rule_node      = node.id("rule")
penalty_node   = node.id("penalty")
whatsit_node   = node.id("whatsit")
hlist_node     = node.id("hlist")

pdf_literal_node = node.subtype("pdf_literal")

default_bereichname = "__seite"

seiten   = {}
optionen = {}

-- Liste der Gruppen. Schlüssel sind inhalt (Nodeliste) und raster 
gruppen   = {}

variablen = {}
farben    = { Schwarz = { modell="grau", g = "0", pdfstring = " 0 G 0 g " } }
farbindex = {}
datensatz_verteiler = {}
user_defined_funktionen = { last = 0}

-- die aktuelle Gruppe
aktuelle_gruppe = nil
aktuelles_raster = nil

-- Die Tabelle Seitentypen enthält als Schlüssel den Seitentypnamen und
-- als Wert eine Tabelle mit den Schlüsseln `ist_seitentyp` und `res`, wobei
-- ersteres eine Funktion ist, die wenn sie aufgerufen wird und "wahr" zurückgibt
-- diesen Seitentyp festlegt und `res` ist das Ergebnis des Dispatchers ohne dem 
-- Element Bedingung.
seitentypen = {}


textformate = {} -- tmp. Textformate. Tabelle mit Schlüsseln: indent, ausrichtung

-- Liste der Schriftarten und deren Synonyme. Beispielsweise könnte ein Schlüssel `Helvetica` sein,
-- der Eintrag dann `texgyreheros-regular.otf`
-- schrifttabelle = {}


sprachen = {}


local dispatch_table = {
  Absatz                  = element.absatz,
  Aktion                  = element.aktion,
  Attribut                = element.attribut,
  B                       = element.fett,
  BearbeiteKnoten         = element.bearbeite_knoten,
  BearbeiteDatensatz      = element.bearbeite_datensatz,
  BeiSeitenAusgabe        = element.beiseitenausgabe,
  BeiSeitenErzeugung      = element.beiseitenerzeugung,
  Bild                    = element.bild,
  Box                     = element.box,
  Datensatz               = element.datensatz,
  DefiniereFarbe          = element.definiere_farbe,
  DefiniereSchriftfamilie = element.definiere_schriftfamilie,
  DefiniereTextformat     = element.definiere_textformat,
  Element                 = element.element,
  Fallunterscheidung      = element.fallunterscheidung,
  Gruppe                  = element.gruppe,
  I                       = element.kursiv,
  Include                 = element.include,
  ["Kopie-von"]           = element.kopie_von,
  LadeDatensatzdatei      = element.lade_datensatzdatei,
  LadeSchriftdatei        = element.lade_schriftdatei,
  Leerzeile               = element.leerzeile,
  Linie                   = element.linie,
  Nachricht               = element.nachricht,
  ["NächsterRahmen"]      = element.naechster_rahmen,
  NeueSeite               = element.neue_seite,
  NeueZeile               = element.neue_zeile,
  Optionen                = element.optionen,
  ObjektAusgeben          = element.objekt_ausgeben,
  Platzierungsbereich     = element.platzierungsbereich,
  Platzierungsrahmen      = element.platzierungsrahmen,
  Rand                    = element.rand,
  Raster                  = element.raster,
  Schriftart              = element.schriftart,
  Seitentyp               = element.seitentyp,
  Seitenformat            = element.seitenformat,
  SetzeRaster             = element.setze_raster,
  Sequenz                 = element.sequenz,
  Solange                 = element.solange,
  SortiereSequenz         = element.sortiere_sequenz,
  SpeichereDatensatzdatei = element.speichere_datensatzdatei,
  Spalte                  = element.spalte,
  Spalten                 = element.spalten,
  Sub                     = element.sub,
  Sup                     = element.sup,
  Tabelle                 = element.tabelle,
  ["Tabellenfuß"]         = element.tabellenfuss,
  Tabellenkopf            = element.tabellenkopf,
  Textblock               = element.textblock,
  Trennvorschlag          = element.trennvorschlag,
  Tlinie                  = element.tlinie,
  Tr                      = element.tr,
  Td                      = element.td,
  U                       = element.unterstreichen,
  URL                     = element.url,
  Variable                = element.variable,
  Wert                    = element.wert,
  Zuweisung               = element.zuweisung,
  ["ZurListeHinzufügen"] = element.zur_liste_hinzufuegen,
}

function dispatch(layoutxml,datenxml,optionen)
  local ret = {}
  local tmp
  for _,j in ipairs(layoutxml) do
    -- j ist genau dann eine Tabelle, wenn es ein Element im layoutxml ist.
    if type(j)=="table" then
      local eltname = j[".__name"]
      if dispatch_table[eltname] ~= nil then

        tmp = dispatch_table[eltname](j,datenxml,optionen)

        -- Kopie-von-Elemente können sofort aufgelöst werden
        if eltname == "Kopie-von" or eltname == "Fallunterscheidung" then
          if type(tmp)=="table" then
            for i=1,#tmp do
              if tmp[i].inhalt then
                ret[#ret + 1] = { elementname = tmp[i].elementname, inhalt = tmp[i].inhalt }
              else
                ret[#ret + 1] = { elementname = "Elementstruktur" , inhalt = { tmp[i] } }
              end
            end
          end
        else
          ret[#ret + 1] =   { elementname = eltname, inhalt = tmp }
        end
      else
        fehler("Unbekanntes Element in Layoutdatei gefunden: '%s'", eltname or "???")
        printtable("j",j)
      end
    end
  end
  return ret
end

function dothings()
  seite_initialisiert=false

  local layoutxml = lade_xml(arg[2],"Layoutregelwerk")
  local datenxml  = lade_xml(arg[3],"Datendatei")

  dispatch(layoutxml)

  local externe_optionen = {}

  for _,extopt in ipairs(string.explode(arg[4],",")) do
    if string.len(extopt) > 0 then
      local k,v = extopt:match("^(.+)=(.+)$")
      v = v:gsub("^\"(.*)\"$","%1")
      optionen[k]=v
    end
  end

  -- Optionen verarbeiten
  if optionen.startseite then
    local num = tonumber(optionen.startseite)
    if num then
      tex.count[0] = num - 1
      log("Setze Seitennummer auf %d",num)
    else
      fehler("Konnte Startseitenzahl %q nicht erkennen",optionen.startseite)
    end
  end

  -- Die Anzahl der Läufe in eine extra Datei schreiben, damit die Steuerdatei
  -- darauf reagieren kann.
  -- FIXME. tex.jobname auch in sprun ändern
  local runs = optionen["läufe"]
  if runs then
    -- erstelle Datei mit dieser Zahl
    local datei = io.open(string.format("%s.runs",tex.jobname),"w")
    datei:write("runs = " .. runs)
    datei:write("\n")
    datei:close()
  end


  element.datenverarbeitung(datenxml)

  -- printtable("Am Ende (inhalt)",variablen.inhalt)
  pdf.info    = [[ /Creator	(speedata Publisher) /Producer(speedata Publisher, www.speedata.de) ]]

  -- letzte Seite ausgeben, wenn notwendig
  if seite_initialisiert then
    dothingsbeforeoutput()
    local n = node.vpack(publisher.global_pagebox)

    tex.box[666] = n
    tex.shipout(666)
  end

end

function lade_xml(dateiname,dateityp)
  local pfad = kpse.find_file(dateiname)
  if not pfad then
    fehler("Konnte XML Datei %q nicht finden. Abbruch.\n",dateiname or "?")
    os.exit(-1)
  end
  log("Lade %s %q",dateityp or "Datei",pfad)

  local layoutfile = io.open(pfad,"r")
  if not layoutfile then
    fehler("Konnte XML Datei nicht öffnen. Abbruch.")
    os.exit(-1)
  end
  local text = layoutfile:read("*all")
  layoutfile:close()
  local xmltab = xmlparser.parse_xml(text)
  -- printtable("XML",xmltab)
  return xmltab
end

function ausgabe_bei_absolut( nodelist,x,y,belegen,bereich )

  if node.has_attribute(nodelist,att_shift_left) then
    x = x - node.has_attribute(nodelist,att_shift_left)
    y = y - node.has_attribute(nodelist,att_shift_up)
  end

  local n = add_glue( nodelist ,"head",{ width = x })
  n = node.hpack(n)
  n = add_glue(n, "head", {width = y})
  n = node.vpack(n)
  n.width  = 0
  n.height = 0
  n.depth  = 0
  local tail = node.tail(publisher.global_pagebox)
  tail.next = n
  n.prev = tail
end

-- Gibt die nodelist bei Rasterzelle (x,y) aus. Wenn belegen==true dann die Zellen als belegt markieren.
function ausgabe_bei( nodelist, x,y,belegen,bereich )
  bereich = bereich or default_bereichname
  local r = aktuelles_raster
  local delta_x, delta_y = r:position_rasterzelle_mass_tex(x,y,bereich)
  if not delta_x then
    fehler(delta_y)
    exit()
  end
  if aktuelle_gruppe then
    -- Den Inhalt der Nodeliste in die aktuelle Gruppe ausgeben. 
    local gruppe = gruppen[aktuelle_gruppe]
    assert(gruppe)


    local n = add_glue( nodelist ,"head",{ width = delta_x })
    n = node.hpack(n)
    n = add_glue(n, "head", {width = delta_y})
    n = node.vpack(n)

    if gruppe.inhalt then
      -- Die Gruppe hat schon einen Inhalt, wir müssen die neue Nodeliste dazufügen
      -- Maß der neuen Gruppe: maximum(Maß der alten Gruppe, Maß der Nodeliste)
      local neue_breite, neue_hoehe
      neue_breite = math.max(n.width, gruppe.inhalt.width)
      neue_hoehe  = math.max(n.height + n.depth, gruppe.inhalt.height + gruppe.inhalt.depth)

      gruppe.inhalt.width  = 0
      gruppe.inhalt.height = 0
      gruppe.inhalt.depth  = 0

      local tail = node.tail(gruppe.inhalt)
      tail.next = n
      n.prev = tail

      gruppe.inhalt = node.vpack(gruppe.inhalt)
      gruppe.inhalt.width  = neue_breite
      gruppe.inhalt.height = neue_hoehe
      gruppe.inhalt.depth  = 0
    else
      -- Die Gruppe ist noch leer
      gruppe.inhalt = n
    end
    if belegen then
      local breite_in_rasterzellen = r:breite_in_rasterzellen_sp(nodelist.width)
      local hoehe_in_rasterzellen  = r:hoehe_in_rasterzellen_sp (nodelist.height + nodelist.depth)
      r:belege_zellen(x,y,breite_in_rasterzellen,hoehe_in_rasterzellen,optionen.zeige_rasterbelegung=="ja")
    end
  else
    -- auf der aktuellen Seite einfügen
    if belegen then
      local breite_in_rasterzellen = r:breite_in_rasterzellen_sp(nodelist.width)
      local hoehe_in_rasterzellen  = r:hoehe_in_rasterzellen_sp(nodelist.height + nodelist.depth)
      r:belege_zellen(x,y,breite_in_rasterzellen,hoehe_in_rasterzellen,optionen.zeige_rasterbelegung=="ja",bereich)
    end

    local n = add_glue( nodelist ,"head",{ width = delta_x })
    n = node.hpack(n)
    n = add_glue(n, "head", {width = delta_y})
    n = node.vpack(n)
    n.width  = 0
    n.height = 0
    n.depth  = 0
    local tail = node.tail(publisher.global_pagebox)
    tail.next = n
    n.prev = tail

  end
end

-- Gibt das Layoutxml zurück, das unter <Seitentyp> deklariert wurde. Für jeden
-- Seitentyp in der Tabelle `seitentypen` wird die Funktion
-- `ist_seitentyp()` der Tabelle aufgerufen. Für jede neue Seite
-- wird diese Funktion aufgerufen.
function ermittle_seitentyp()
  local ret = nil
  for i=#seitentypen,1,-1 do
    local seitentyp = seitentypen[i]
    if xpath.parse(nil,seitentyp.ist_seitentyp) == true then
      log("Seite vom Typ %q wird erzeugt",seitentyp.name or "")
      ret = seitentyp.res
      return ret
    end
  end
  fehler("Seitentyp konnte nicht ermittelt werden!")
  return false
end

-- Muss aufgerufen werden, bevor auf eine neue Seite etwas ausgegeben wird.
function seite_einrichten()
  if seite_initialisiert then return end
  seite_initialisiert=true
  publisher.global_pagebox = node.new("vlist")
  local beschnittzugabe = tex.sp(optionen.beschnittzugabe or 0)
  local extra_rand
  if optionen.beschnittmarken=="ja" then
    extra_rand = tex.sp("1cm") + beschnittzugabe
  elseif beschnittzugabe > 0 then
    extra_rand = beschnittzugabe
  end
  local err
  -- aktuelle_seite ist eine globale Variable
  aktuelle_seite, err = seite:new(optionen.seitenbreite,optionen.seitenhoehe, extra_rand, beschnittzugabe)
  if not aktuelle_seite then
    fehler("Konnte keine Seite anlegen. Ist ein entsprechender Seitentyp definiert?")
    exit()
  end
  aktuelles_raster = aktuelle_seite.raster
  seiten[tex.count[0]] = nil
  tex.count[0] = tex.count[0] + 1
  seiten[tex.count[0]] = aktuelle_seite

  local rasterbreite = optionen.rasterbreite
  local rasterhoehe  = optionen.rasterhoehe


  local ret_tbl = ermittle_seitentyp()
  if ret_tbl == false then return false end

  for _,j in ipairs(ret_tbl) do
    if type(inhalt(j))=="function" and elementname(j)=="Rand" then
      inhalt(j)(aktuelle_seite)
    elseif elementname(j)=="Raster" then
      rasterbreite = inhalt(j).breite
      rasterhoehe  = inhalt(j).hoehe
    elseif elementname(j)=="BeiSeitenErzeugung" then
      aktuelle_seite.beiseitenerzeugung = inhalt(j)
    elseif elementname(j)=="BeiSeitenAusgabe" then
      aktuelle_seite.beiseitenausgabe = inhalt(j)
    elseif elementname(j)=="Platzierungsbereich" then
      local name = inhalt(j).name
      aktuelles_raster.platzierungsbereiche[name] = {}
      local aktueller_platzierungsbereich = aktuelles_raster.platzierungsbereiche[name]
      for _,k in ipairs(inhalt(j)) do
        aktueller_platzierungsbereich[#aktueller_platzierungsbereich + 1] = inhalt(k)
      end
    else
      fehler("Elementname %q unbekannt (seite_einrichten())",elementname(j))
    end
  end

  if not rasterbreite then
    fehler("Raster nicht gesetzt!")
    exit()
  end
  assert(rasterbreite)
  assert(rasterhoehe,"Rasterhöhe")


  aktuelle_seite.raster:setze_breite_hoehe(tex.sp(rasterbreite),tex.sp(rasterhoehe))


  if aktuelle_seite.beiseitenerzeugung then
    publisher.dispatch(aktuelle_seite.beiseitenerzeugung,nil)
  end
end

function naechster_rahmen( bereichname )
  local aktuelle_nummer = aktuelles_raster:rahmennummer(bereichname)
  if aktuelle_nummer >= aktuelles_raster:anzahl_rahmen(bereichname) then
    neue_seite()
  else
    aktuelles_raster:setze_rahmennummer(bereichname, aktuelle_nummer + 1)
  end
  aktuelles_raster:setze_aktuelle_zeile(1,bereichname)
end

function neue_seite()
  if seitenumbruch_unmoeglich then
    return
  end
  if not aktuelle_seite then
    -- es wurde neue_seite() aufgerufen, ohne, dass was ausgegeben wurde bisher
    seite_initialisiert=false
    seite_einrichten()
  end
  if aktuelle_seite.beiseitenausgabe then
    seitenumbruch_unmoeglich = true
    dispatch(aktuelle_seite.beiseitenausgabe)
    seitenumbruch_unmoeglich = false
  end
  seite_initialisiert=false
  dothingsbeforeoutput()

  local n = node.vpack(publisher.global_pagebox)
  tex.box[666] = n
  tex.shipout(666)
end

-- Zeichnet einen farbigen Hintergrund hinter ein rechteckickges Objekt (box)
function hintergrund( box, farbname )
  if not farben[farbname] then
    warnung("Hintergrund: Farbe %q nicht definiert",farbname)
    return box
  end
  local pdffarbstring = farben[farbname].pdfstring
  local wd, ht, dp = helper.sp_to_bp(box.width),helper.sp_to_bp(box.height),helper.sp_to_bp(box.depth)
  n = node.new(whatsit_node,pdf_literal_node)
  n.data = string.format("q %s 0 -%g %g %g re f Q",pdffarbstring,dp,wd,ht + dp)
  n.mode = 0
  if node.type(box.id) == "hlist" then
    -- Da das pdfliteral keinen Platz verbraucht, können wir die in die schon gepackte Box hinzufügen
    n.next = box.list
    box.list.prev = n
    box.list = n
    return box
  else
    n.next = box
    box.prev = n
    n = node.hpack(n)
    return n
  end
end

function rahmen( box, farbname )
  local pdffarbstring = farben[farbname].pdfstring
  local wd, ht, dp = helper.sp_to_bp(box.width),helper.sp_to_bp(box.height),helper.sp_to_bp(box.depth)
  local w = 3 -- Strichbreite 
  local hw = 0.5 * w -- halbe Strichbreite
  n = node.new(whatsit_node,pdf_literal_node)
  n.data = string.format("q %s %g w -%g -%g %g %g re S Q",pdffarbstring, w , hw ,dp + hw ,wd + w,ht + dp + w)
  n.mode = 0
  n.next = box
  box.prev = n
  n = node.hpack(n)
  return n
end

-- Erzeugt eine farbige Fläche. Die Maße breite und hoehe sind in BP!
function box( breite,hoehe,farbname )
  local n = node.new(whatsit_node,pdf_literal_node)
  n.data = string.format("q %s 1 0 0 1 0 0 cm 0 0 %g -%g re f Q",farben[farbname].pdfstring,breite,hoehe)
  n.mode = 0
  return n
end

function dothingsbeforeoutput(  )
  local r = aktuelle_seite.raster
  local str
  -- finde_user_defined_whatsits(publisher.global_pagebox)
  local firstbox
  if #aktuelle_seite.raster.belegung_pdf > 0 then
    local lit = node.new("whatsit","pdf_literal")
    lit.mode = 1
    lit.data = string.format("%s",table.concat(aktuelle_seite.raster.belegung_pdf,"\n"))
    firstbox = lit
  end

  if optionen.zeichne_raster=="ja" then
    local lit = node.new("whatsit","pdf_literal")
    lit.mode = 1
    lit.data = r:zeichne_raster()
    if firstbox then
      local tail = node.tail(firstbox)
      tail.next = lit
      lit.prev = tail
    else
      firstbox = lit
    end
  end
  r:trimbox()
  if optionen.beschnittmarken == "ja" then
    local lit = node.new("whatsit","pdf_literal")
    lit.mode = 1
    lit.data = r:beschnittmarken()
    if firstbox then
      local tail = node.tail(firstbox)
      tail.next = lit
      lit.prev = tail
    else
      firstbox = lit
    end
  end
  if firstbox then
    local list_start = publisher.global_pagebox
    publisher.global_pagebox = firstbox
    node.tail(firstbox).next = list_start
    list_start.prev = node.tail(firstbox)
  end
end

function dostats(  )
  print(string.format("\nnode_mem_usage=%s",status.node_mem_usage))
  print(string.format("luastate_bytes=%d",status.luastate_bytes / 1024))
end

function lese_attribut_jit( layoutxml,datenxml,attname,typ )
  local funcname = ".__func" .. attname
  if layoutxml[funcname] then return layoutxml[funcname](datenxml) end
  if layoutxml[attname] == nil then
    layoutxml[funcname] = function() return nil end
    return nil
  end
  local str = string.match(layoutxml[attname],"{(.-)}")
  local func
  if str then
    func = function(d)
      local val = xpath.textvalue(xpath.parse(d,str))
      if typ=="string" then
        return tostring(val)
      elseif typ=="number" then
        return tonumber(val)
      elseif typ=="length" then
        return val
      else
        warnung("lese_attribut: unbekannter typ: %s",type(val))
      end
      return val
    end
  else
    func = function()
      local val = layoutxml[attname]
      if typ=="string" then
        return tostring(val)
      elseif typ=="number" then
        return tonumber(val)
      elseif typ=="length" then
        return val
      else
        warnung("lese_attribut (2): unbekannter typ: %s",type(val))
      end
      return val
    end
  end
  layoutxml[funcname] = func
  return func(datenxml)
end

function elementname( elt )
  return elt.elementname
end

function inhalt( elt )
  return elt.inhalt
end

-- <b> und <i> in Text
function parse_html( elt )
  local a = Absatz:new()
  local fett,kursiv,unterstreichen
  if elt[".__name"] then
    if elt[".__name"] == "b" then
      fett = 1
    elseif elt[".__name"] == "i" then
      kursiv = 1
    elseif elt[".__name"] == "u" then
      unterstreichen = 1
    end
  end

  for i=1,#elt do
    if type(elt[i]) == "string" then
      a:anhaengen(elt[i],{schriftfamilie = 0, fett = fett, kursiv = kursiv, unterstreichen = unterstreichen })
    elseif type(elt[i]) == "table" then
      a:anhaengen(parse_html(elt[i]),{schriftfamilie = 0, fett = fett, kursiv = kursiv, unterstreichen = unterstreichen})
    end
  end

  return a
end
-- sucht am Ende der Seite (shipout) nach den user_defined whatsits und führt die
-- Aktionen dadrin aus.
function finde_user_defined_whatsits( head )
  local typ,fun
  while head do
    typ = node.type(head.id)
    if typ == "vlist" or typ=="hlist" then
      finde_user_defined_whatsits(head.list) 
    elseif typ == "whatsit" then
      if head.subtype == 44 then
        -- der Wert ist der Index für die Funktion unter user_defined_funktionen.
        fun = user_defined_funktionen[head.value]
        fun()
        -- use and forget
        user_defined_funktionen[head.value] = nil
      end
    end
    head = head.next
  end
  -- for n in node.traverse_id(8, head) do
  --   if n.subtype==44 then
  --   end
  -- end
  -- viznodelist.nodelist_visualize(head,"head.gv")
end

rightskip = node.new(glue_spec_node)
rightskip.width = 0
rightskip.stretch = 1 * 2^16
rightskip.stretch_order = 3

leftskip = node.new(glue_spec_node)
leftskip.width = 0
leftskip.stretch = 1 * 2^16
leftskip.stretch_order = 3

-- Erzeugt eine \hbox{}. Rückgabe ist eine gepackte Nodeliste, die an eine Box zugewiesen werden könnte.
-- Instanzname ist "normal", "fett" etc.
function mknodes(str,fontfamilie,parameter)
  -- instanz ist die interne Fontnummer
  local instanz
  local instanzname
  local sprachcode = parameter.sprachcode
  if parameter.fett == 1 then
    if parameter.kursiv == 1 then
      instanzname = "fettkursiv"
    else
      instanzname = "fett"
    end
  elseif parameter.kursiv == 1 then
    instanzname = "kursiv"
  else
    instanzname = "normal"
  end

  if fontfamilie and fontfamilie > 0 then
    instanz = fonts.lookup_schriftfamilie_nummer_instanzen[fontfamilie][instanzname]
  else
    instanz = 1
  end
  assert(instanz, string.format("Instanzname %q, keine Fontinstanz gefunden",instanzname or "nil"))

  local tbl = font.getfont(instanz)
  local space   = tbl.parameters.space
  local shrink  = tbl.parameters.space_shrink
  local stretch = tbl.parameters.space_stretch
  local match = unicode.utf8.match
    
  local head, last, n
  local char

  -- falls ein leerer String übergeben wurde, machen wir ein Leerzeichen daraus. Experimentell
  if string.len(str) == 0 then
    n = node.new(glyph_node)
    n.char = 32
    n.font = instanz
    n.subtype = 1
    n.char = s
    if sprachcode then
      n.lang = sprachcode
    else
      if n.lang == 0 then
        fehler("Sprachcode nicht gesetzt und lang==0")
      end
    end

    node.set_attribute(n,att_schriftfamilie,fontfamilie)
    return n
  end
  for s in string.utfvalues(str) do
    local char = unicode.utf8.char(s)
    if match(char,"%s") and last and last.id == glue_node and not node.has_attribute(last,att_tie_glue,1) then
      -- doppeltes Leerzeichen, nichts machen
    elseif s == 160 then -- non breaking space
      n = node.new(penalty_node)
      n.penalty = 10000
      if head then
        last.next = n
      else
        head = n
      end
      last = n

      n = node.new(glue_node)
      n.spec = node.new(glue_spec_node)
      n.spec.width   = space
      n.spec.shrink  = shrink
      n.spec.stretch = stretch

      node.set_attribute(n,att_tie_glue,1)

      last.next = n
      last = n

      if parameter.unterstreichen == 1 then
        node.set_attribute(n,att_unterstreichen,1)
      end
      node.set_attribute(n,att_schriftfamilie,fontfamilie)


    elseif match(char,"%s") then -- Leerzeichen
      n = node.new(glue_node)
      n.spec = node.new(glue_spec_node)
      n.spec.width   = space
      n.spec.shrink  = shrink 
      n.spec.stretch = stretch

      if parameter.unterstreichen == 1 then
        node.set_attribute(n,att_unterstreichen,1)
      end
      node.set_attribute(n,att_schriftfamilie,fontfamilie)

      if head then
        last.next = n
      else
        head = n
      end
      last = n

    else
      n = node.new(glyph_node)
      n.font = instanz
      n.subtype = 1
      n.char = s
      n.lang = sprachcode
      n.uchyph = 1
      n.left = tex.lefthyphenmin
      n.right = tex.righthyphenmin
      node.set_attribute(n,att_schriftfamilie,fontfamilie)
      if parameter.fett == 1 then
        node.set_attribute(n,att_fett,1)
      end
      if parameter.kursiv == 1 then
        node.set_attribute(n,att_kursiv,1)
      end
      if parameter.unterstreichen == 1 then
        node.set_attribute(n,att_unterstreichen,1)
      end

      if head then
        last.next = n
      else
        head = n
      end
      n.prev = last
      last = n

      if n.char == 45 then
        local pen = node.new("penalty")
        pen.penalty = 10000

        if n.prev then
          n.prev = pen
          pen.next = n
        end

        local glue = node.new("glue")
        glue.spec = node.new("glue_spec")
        glue.spec.width = 0

        n.next = glue
        last = glue
        glue.prev = n

        node.set_attribute(glue,att_tie_glue,1)
      end

      if match(char,"[;:]") then
        n = node.new(penalty_node)
        n.penalty = 0
        n.prev = last
        last.next = n
        last = n
      end

    end
  end

  if not head then
    return node.new("hlist")
  end
  return head
end

-- head_or_tail = "head" oder "tail" (default: tail). Return new head (perhaps same as nodelist)
function add_rule( nodelist,head_or_tail,parameters)
  parameters = parameters or {}
  -- if parameters.height == nil then parameters.height = -1073741824 end
  -- if parameters.width  == nil then parameters.width  = -1073741824 end
  -- if parameters.depth  == nil then parameters.depth  = -1073741824 end

  local n=node.new(rule_node)
  n.width  = parameters.width
  n.height = parameters.height
  n.depth  = parameters.depth
  if not nodelist then return n end

  if head_or_tail=="head" then
    n.next = nodelist
    nodelist.prev = n
    return n
  else
    local last=node.slide(nodelist)
    last.next = n
    n.prev = last
    return nodelist,n
  end
  assert(false,"never reached")
end

-- parameter sind width, stretch und stretch_order. Wenn nodelist noch nicht existiert, dann wird einfach ein
-- glue_node erzeugt.
function add_glue( nodelist,head_or_tail,parameter)
  parameter = parameter or {}

  local n=node.new(glue_node, parameter.subtype or 0)
  n.spec = node.new(glue_spec_node)
  n.spec.width         = parameter.width
  n.spec.stretch       = parameter.stretch
  n.spec.stretch_order = parameter.stretch_order
  
  if nodelist == nil then return n end
  
  if head_or_tail=="head" then
    n.next = nodelist
    nodelist.prev = n
    return n
  else
    local last=node.slide(nodelist)
    last.next = n
    n.prev = last
    return nodelist,n
  end
  assert(false,"never reached")
end

function finish_par( nodelist )
  assert(nodelist)
  node.slide(nodelist)
  lang.hyphenate(nodelist)
  local n = node.new(penalty_node)
  n.penalty = 10000
  local last = node.slide(nodelist)

  last.next = n
  n.prev = last
  last = n

  n = node.kerning(nodelist)
  n = node.ligaturing(n)

  n,last = add_glue(n,"tail",{ subtype = 15, width = 0, stretch = 2^16, stretch_order = 2})
end

function do_linebreak( nodelist,hsize,parameters )
  assert(nodelist,"Keine nodeliste für einen Absatzumbruch gefunden.")
  parameters = parameters or {}
  finish_par(nodelist)

  local pdfignoreddimen
  pdfignoreddimen    = -65536000

  local default_parameters = {
    hsize = hsize,
    emergencystretch = 0.1 * hsize,
    hyphenpenalty = 0,
    linepenalty = 10,
    pretolerance = 0,
    tolerance = 2000,
    doublehyphendemerits = 1000,
    pdfeachlineheight = pdfignoreddimen,
    pdfeachlinedepth  = pdfignoreddimen,
    pdflastlinedepth  = pdfignoreddimen,
    pdfignoreddimen   = pdfignoreddimen,
  }
  setmetatable(parameters,{__index=default_parameters})
  local j = tex.linebreak(nodelist,parameters)

  -- Zeilenhöhen anpassen. Immer die größte Schriftart in einer Zeile beachten
  local head = j
  local maxskip
  while head do
    if head.id == 0 then -- hlist
      maxskip = 0
      for glyf in node.traverse_id(glyph_node,head.list) do
        local fam = node.has_attribute(glyf,att_schriftfamilie)
        maxskip = math.max(fonts.lookup_schriftfamilie_nummer_instanzen[fam].zeilenabstand,maxskip)
      end
      head.height = 0.75 * maxskip
      head.depth  = 0.25 * maxskip
    end
    head = head.next
  end

  fonts.post_linebreak(j)
  -- Zeilenhöhen anpassen. Immer die größte Schriftart in einer Zeile beachten

  return node.vpack(j)
end

function erzeuge_leere_hbox_mit_breite( wd )
  local n=node.new(glue_node,0)
  n.spec = node.new(glue_spec_node)
  n.spec.width         = 0
  n.spec.stretch       = 2^16
  n.spec.stretch_order = 3
  n = node.hpack(n,wd,"exactly")
  return n
end


function boxit( box )
  local box = node.hpack(box)

  local factor = 65782  -- big points vs. TeX points

  local rule_width = 0.1
  local wd = box.width                 / factor - rule_width
  local ht = (box.height + box.depth)  / factor - rule_width
  local dp = box.depth                 / factor - rule_width / 2

  local wbox = node.new("whatsit","pdf_literal")
  wbox.data = string.format("q 0.1 G %g w %g %g %g %g re s Q", rule_width, rule_width / 2, -dp, -wd, ht)
  wbox.mode = 0
  -- die Box muss zum Schluss gezeichnet werden, sonst wird sie vom Inhalt überlappt
  local tmp = node.tail(box.list)
  tmp.next = wbox
  return box
end

local images = {}
function neues_bild( dateiname,seite,box)
  return img.copy(bildinfo(dateiname,seite,box))
end

-- Box ist none, media, crop, bleed, trim, art
function bildinfo( dateiname,seite,box )
  seite = seite or 1
  box = box or "crop"
  local neuer_name = dateiname .. tostring(seite) .. tostring(box)

  if images[neuer_name] then
    return images[neuer_name]
  end

  if not kpse.filelist[dateiname] then
    fehler("Bild %q nicht gefunden!",dateiname or "???")
    dateiname = "filenotfound.pdf"
    seite = 1
  end

  if not images[neuer_name] then
    images[neuer_name] = img.scan{filename = dateiname, pagebox = box, page=seite }
  end
  return images[neuer_name]
end

function setze_farbe_wenn_notwendig( nodelist,farbe )
  if not farbe then return nodelist end

  local farbname
  if farbe == -1 then
    farbname = "Schwarz"
  else
    farbname = farbindex[farbe]
  end

  local colstart = node.new(8,39)
  colstart.data  = farben[farbname].pdfstring
  colstart.cmd   = 1
  colstart.stack = 1
  colstart.next = nodelist
  nodelist.prev = colstart

  local colstop  = node.new(8,39)
  colstop.data  = ""
  colstop.cmd   = 2
  colstop.stack = 1
  local last = node.tail(nodelist)
  last.next = colstop
  colstop.prev = last

  return colstart
end

function setze_fontfamilie_wenn_notwendig(nodelist,fontfamilie)
  local fam
  while nodelist do
    if nodelist.id==0 or nodelist.id==1 then
      setze_fontfamilie_wenn_notwendig(nodelist.list,fontfamilie)
    else
      fam = node.has_attribute(nodelist,att_schriftfamilie)
      if fam == 0 then
        node.set_attribute(nodelist,att_schriftfamilie,fontfamilie)
      end
    end
    nodelist=nodelist.next
  end
end

function setze_script( nodelist,script )
  for glyf in node.traverse_id(glyph_node,nodelist) do
    node.set_attribute(glyf,att_script,script)
  end
end

function umbreche_url( nodelist )
  local p

  local slash = string.byte("/")
  for n in node.traverse_id(glyph_node,nodelist) do
    p = node.new(penalty_node)

    if n.char == slash then
      p.penalty=-50
    else
      p.penalty=-5
    end
    p.next = n.next
    n.next = p
    p.prev = n
  end
  return nodelist
end

function farbbalken( wd,ht,dp,farbe )
  local farbname = farbe or "Schwarz"
  if not farben[farbname] then
    fehler("Farbe %q nicht gefunden",farbe)
    farbname = "Schwarz"
  end
  local rule_start = node.new("whatsit","pdf_colorstack")
  rule_start.stack = 1
  rule_start.data = farben[farbname].pdfstring
  rule_start.cmd = 1

  local rule = node.new("rule")
  rule.height = ht
  rule.depth  = dp
  rule.width  = wd

  local rule_stop = node.new("whatsit","pdf_colorstack")
  rule_stop.stack = 1
  rule_stop.data = ""
  rule_stop.cmd = 2

  rule_start.next = rule
  rule.next = rule_stop
  rule_stop.prev = rule
  rule.prev = rule_start
  return rule_start, rule_stop
end

function rotiere( nodelist,winkel )
  local wd,ht = nodelist.width, nodelist.height + nodelist.depth
  nodelist.width = 0
  nodelist.height = 0
  nodelist.depth = 0
  local winkel_rad = math.rad(winkel)
  w("Winkel_rad = %g",winkel_rad)
  local sin = math.round(math.sin(winkel_rad),3)
  local cos = math.round(math.cos(winkel_rad),3)
  local q = node.new("whatsit","pdf_literal")
  q.mode = 0
  local shift_x = math.round(math.min(0,math.sin(winkel_rad) * helper.sp_to_bp(ht)) + math.min(0,     math.cos(winkel_rad) * helper.sp_to_bp(wd)),3)
  local shift_y = math.round(math.max(0,math.sin(winkel_rad) * helper.sp_to_bp(wd)) + math.max(0,-1 * math.cos(winkel_rad) * helper.sp_to_bp(ht)),3)
  q.data = string.format("q %g %g %g %g %g %g cm",cos,sin, -1 * sin,cos, -1 * shift_x ,-1 * shift_y )
  q.next = nodelist
  local tail = node.tail(nodelist)
  local Q = node.new("whatsit","pdf_literal")
  Q.data = "Q"
  tail.next = Q
  local tmp = node.vpack(q)
  tmp.width  = math.abs(wd * cos) + math.abs(ht * math.cos(math.rad(90 - winkel)))
  tmp.height = math.abs(ht * math.sin(math.rad(90 - winkel))) + math.abs(wd * sin)
  tmp.depth = 0
  return tmp
end

-- Wird aufgerufen von xml_to_string und soll ein gültiges XML erzeugen & < ' " ersetzen
function xml_attribut_bereinigen( str )
  -- FIXME: todo!
end

-- Welche Datenstruktur wird erwartet? FIXME
function xml_to_string( xml_element, level )
  level = level or 0
  local str = ""
  str = str .. string.rep(" ",level) .. "<" .. xml_element[".__name"]
  for k,v in pairs(xml_element) do
    if type(k) == "string" and not k:match("^%.") then
      str = str .. string.format(" %s=%q", k,v)
    end
  end
  str = str .. ">\n"
  for i,v in ipairs(xml_element) do
    str = str .. xml_to_string(v,level + 1)
  end
  str = str .. string.rep(" ",level) .. "</" .. xml_element[".__name"] .. ">\n"
  return str
end


function hole_sprachcode( sprache_intern )
  if publisher.sprachen[sprache_intern] then
    return publisher.sprachen[sprache_intern]
  end
  local filename = string.format("hyph-%s.pat.txt",sprache_intern)
  log("Lade Trennmuster %q.",filename)
  local pfad = kpse.find_file(filename)
  local trennmuster_datei = io.open(pfad)
  local muster = trennmuster_datei:read("*all")

  local l = lang.new()
  l:patterns(muster)
  local id = l:id()
  log("Sprach_id: %d",id)
  trennmuster_datei:close()
  publisher.sprachen[sprache_intern] = id
  return id
end
------------------------------------------------------------------------------

Absatz = {}
function Absatz:new( textformat  )
  local instance = {
    nodelist,
    textformat = textformat,
  }
  if textformat and textformate[textformat] and textformate[textformat].indent then
    instance.nodelist = add_glue(nil,"head",{ width = textformate[textformat].indent })
  end
  setmetatable(instance, self)
  self.__index = self
  return instance
end

function Absatz:fuege_kursiv_fett_hinzu( nodelist,parameter )
  -- FIXME: rekursiv durchgehen, traverse bleibt an hlists hängen
  for i in node.traverse_id(glyph_node,nodelist) do
    if parameter.fett == 1 then
      node.set_attribute(i,att_fett,1)
    end
    if parameter.kursiv == 1 then
      node.set_attribute(i,att_kursiv,1)
    end
    if parameter.unterstreichen == 1 then
      node.set_attribute(i,att_unterstreichen,1)
    end
    if parameter.sprachcode then
      i.lang = parameter.sprachcode
    end
  end
end

function Absatz:fuege_zur_nodelist_hinzu( neue_nodes )
  if self.nodelist == nil then
    self.nodelist = neue_nodes
  else
    local tail = node.tail(self.nodelist)
    tail.next = neue_nodes
    neue_nodes.prev = tail
  end
end

function Absatz:setze_farbe( farbe )
  if not farbe then return end

  local farbname
  if farbe == -1 then
    farbname = "Schwarz" 
  else
    farbname = farbindex[farbe]
  end
  local colstart = node.new(8,39)
  colstart.data  = farben[farbname].pdfstring
  colstart.cmd   = 1
  colstart.stack = 1
  colstart.next = self.nodelist
  self.nodelist.prev = colstart
  self.nodelist = colstart
  local colstop  = node.new(8,39)
  colstop.data  = ""
  colstop.cmd   = 2
  colstop.stack = 1
  local last = node.tail(self.nodelist)
  last.next = colstop
  colstop.prev = last
end

-- Textformat Name
function Absatz:textformat_anwenden( textformat )
  if not textformat or self.textformat then return self.nodelist end
  if textformate[textformat] and textformate[textformat].indent then
    self.nodelist = add_glue(self.nodelist,"head",{ width = textformate[textformat].indent })
  end
  return self.nodelist
end

-- Gibt die Breite des längsten Wortes zurück. FIXME: hier müsste eigentlich die Möglichkeit der Trennung berücksichtigt
-- werden.
function Absatz:min_breite()
  assert(self)
  local wd = 0
  local last_glue = self.nodelist
  local dimen
  -- Einfach den Abstand zwischen zwei Glue-Nodes messen, und das Maximum davon nehmen
  for n in node.traverse_id(glue_node,self.nodelist) do
    dimen = node.dimensions(last_glue,n)
    wd = math.max(wd,dimen)
    last_glue = n
  end
  -- Es gibt zwei Fälle, entweder gibt es nur ein Wort (= kein glue), dann ist last_glue auf dem Anfang der Nodeliste
  -- Oder wir sind am letzten glue, dann gibt es ja noch ein Wort nach dem glue. last_glue ist das letzte glue-Element.
  dimen = node.dimensions(last_glue,node.tail(n))
  wd = math.max(wd,dimen)
  return wd
end

function Absatz:max_breite()
  assert(self)
  local wd = node.dimensions(self.nodelist)
  return wd
end

function Absatz:script( whatever,scr,parameter )
  local nl
  if type(whatever)=="string" or type(whatever)=="number" then
    nl = mknodes(whatever,parameter.schriftfamilie,parameter)
  else
    assert(false,string.format("superscript, type()=%s",type(whatever)))
  end
  setze_script(nl,scr)
  nl = node.hpack(nl)
  -- Vorsicht! Diese Breite ist noch falsch (es ist die Breite der "normalen") Zeichen
  -- Daher muss die Breite in pre_linebreak noch korrigiert werden
  node.set_attribute(nl,att_script,scr)
  self:fuege_zur_nodelist_hinzu(nl)
end

function Absatz:anhaengen( whatever,parameter )
  if type(whatever)=="string" or type(whatever)=="number" then
    self:fuege_zur_nodelist_hinzu(mknodes(whatever,parameter.schriftfamilie,parameter))
  elseif type(whatever)=="table" and whatever.nodelist then
    self:fuege_kursiv_fett_hinzu(whatever.nodelist,parameter)
    self:fuege_zur_nodelist_hinzu(whatever.nodelist)
    setze_fontfamilie_wenn_notwendig(whatever.nodelist,parameter.schriftfamilie)
  elseif type(whatever)=="function" then
    self:fuege_zur_nodelist_hinzu(mknodes(whatever(),parameter.schriftfamilie,parameter))
  elseif type(whatever)=="userdata" then -- node.is_node in einer späteren Version
    self:fuege_zur_nodelist_hinzu(whatever)
  elseif type(whatever)=="table" and not whatever.nodelist then
    self:fuege_zur_nodelist_hinzu(mknodes("",parameter.schriftfamilie,parameter))
  else
    if type(whatever)=="table" then printtable("Absatz:anhaengen",whatever) end
    assert(false,string.format("Interner Fehler bei Absatz:anhaengen, type(arg)=%s",type(whatever)))
  end
end

datei_ende("publisher.lua")
