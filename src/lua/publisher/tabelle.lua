--
--  publisher/src/lua/tabelle.lua
--  speedata publisher
--
--  Created by Patrick Gundlach on 2010-03-07.
--  Copyright 2010-2011 Patrick Gundlach. All rights reserved.
--

datei_start("tabelle.lua")
require("xpath")

module(...,package.seeall)


function new( self )
  assert(self)
  local t = {

   zeilenhoehen   = {},
   spaltenbreiten = {},
   align          = {},
   valign         = {},
   skip   = {},
   tabellenbreite_soll,
   spaltenfarben  = {},
   -- Der Abstand zwischen Spalte i und i+1, derzeit nicht benutzt
   spaltenabstaende = {},
   anzahl_zeilen_im_kopf = 0,
  }
  
	setmetatable(t, self)
	self.__index = self
	return t
end

--------------------------------------------------------------------------
function berechne_spaltenbreite_fuer_zeile(self, tr_inhalt,aktuelle_zeile,colspans,colmin,colmax )
  local aktuelle_spalte
  local max_wd, min_wd -- maximale Breite und minimale Breite einer Tabellenzelle (Td)
  -- als erstes die einzelnen Zeilen/Zellen durchgehen und schauen, wie breit die 
  -- Spalten sein müssen. Wenn es colspans gibt, müssen diese entsprechend
  -- berücksichtigt werden.
  aktuelle_spalte = 0

  for _,td in ipairs(tr_inhalt) do
    local td_inhalt = publisher.inhalt(td)
    -- alle Spalten durchgehen
    -- skip, colspan und colmax-Tabellen ausfüllen für diese Tabellenzelle:
    aktuelle_spalte = aktuelle_spalte + 1
    min_wd,max_wd = nil,nil
    local rowspan = tonumber(td_inhalt.rowspan) or 1
    local colspan = tonumber(td_inhalt.colspan) or 1

    -- Wenn ich auf einer Skip-Spalte bin (durch einen Rowspan), dann überspringe ich die Spalte einfach
    while self.skip[aktuelle_zeile] and self.skip[aktuelle_zeile][aktuelle_spalte] do aktuelle_spalte = aktuelle_spalte + 1 end
    -- rowspan?
    for z = aktuelle_zeile + 1, aktuelle_zeile + rowspan - 1 do
      for y = aktuelle_spalte, aktuelle_spalte + colspan - 1 do
        self.skip[z] = self.skip[z] or {}  self.skip[z][y] = true
      end
    end

    local objekte = {}

    for i,j in ipairs(td_inhalt) do
      if publisher.elementname(j) == "Absatz" then
        objekte[#objekte + 1] = publisher.inhalt(j)
      elseif publisher.elementname(j) == "Bild" then
        -- FIXME: Bild sollte auch ein "Objekt" sein
        objekte[#objekte + 1] = publisher.inhalt(j)
      elseif publisher.elementname(j) == "Tabelle" then
        -- FIXME: Bild sollte auch ein "Objekt" sein
        objekte[#objekte + 1] = publisher.inhalt(j)[1]
      else
        warning("Object not recognized: %s",publisher.elementname(j) or "???")
      end
    end
    td_inhalt.objekte = objekte

    local td_randlinks  = tex.sp(td_inhalt["border-left"]  or 0)
    local td_randrechts = tex.sp(td_inhalt["border-right"] or 0)

    local padding_left  = td_inhalt.padding_left  or self.padding_left
    local padding_right = td_inhalt.padding_right or self.padding_right

    for _,objekt in ipairs(objekte) do
      -- FIXME: (Default-)Textformate für Absätze
      if type(objekt)=="table" then
        trace("Tabelle: überprüfe auf Nodeliste (%s)",tostring(objekt.nodelist ~= nil))

        if objekt.nodelist then
          -- FIXME: dynamisches Textformat
          objekt:textformat_anwenden("text")
          publisher.setze_fontfamilie_wenn_notwendig(objekt.nodelist,self.schriftfamilie)
          publisher.fonts.pre_linebreak(objekt.nodelist)
        end

        if objekt.min_breite then
          min_wd = math.max(objekt:min_breite() + padding_left  + padding_right + td_randlinks + td_randrechts, min_wd or 0)
        end
        if objekt.max_breite then
          max_wd = math.max(objekt:max_breite() + padding_left  + padding_right + td_randlinks + td_randrechts, max_wd or 0)
        end
        trace("Tabelle: min_wd, max_wd gesetzt (%gpt,%gpt)",min_wd / 2^16, max_wd / 2^16)
      end
      if not ( min_wd and max_wd) then
        trace("min_wd und max_wd noch nicht gesetzt. Typ(objekt)==%s",type(objekt))
        if objekt.width then
          min_wd = objekt.width + padding_left  + padding_right + td_randlinks + td_randrechts
          max_wd = objekt.width + padding_left  + padding_right + td_randlinks + td_randrechts
          trace("Tabelle: Breite (Bild) = %gpt",min_wd / 2^16)
        else
          warning("Could not determine min_wd and max_wd")
          assert(false)
        end
      end
    end
    trace("Tabelle: Colspan=%d",colspan)
    -- colspan?
    if colspan > 1 then
      colspans[#colspans + 1] = { start = aktuelle_spalte, ende = aktuelle_spalte + colspan - 1, max_wd = max_wd, min_wd = min_wd }
      aktuelle_spalte = aktuelle_spalte + colspan - 1
    else
      colmax[aktuelle_spalte] = math.max(colmax[aktuelle_spalte] or 0,max_wd)
      colmin[aktuelle_spalte] = math.max(colmin[aktuelle_spalte] or 0,min_wd)
    end
  end  -- ∀ Spalten
end


function berechne_spaltenbreite( self )
  trace("Tabelle: berechne Spaltenbreiten")
  local colspans = {}
  local colmax,colmin = {},{}

  local aktuelle_zeile = 0
  self.tabellenbreite_soll = self.breite
  local spaltenbreiten_vorgegeben = false

  for _,tr in ipairs(self.tab) do
    local tr_inhalt      = publisher.inhalt(tr)
    local tr_elementname = publisher.elementname(tr)

    if tr_elementname == "Spalten" then
      local wd
      local i = 0
      local summe_sternchen = 0
      local summe_echte_breiten = 0
      local anzahl_spalten = 0
      local patt = "([0-9]+)\*"
      for _,spalte in ipairs(tr_inhalt) do
        if publisher.elementname(spalte)=="Spalte" then
          local spalte_inhalt = publisher.inhalt(spalte)
          i = i + 1
          self.align[i] =  spalte_inhalt.align
          self.valign[i] = spalte_inhalt.valign
          if spalte_inhalt.breite then
            -- wenn ich eine Angabe bei "Spalte" habe, dann brauche ich ja die Spaltenbreite nicht mehr zu berechnen:
            spaltenbreiten_vorgegeben = true
            local breite_sternchen = string.match(spalte_inhalt.breite,patt)
            if breite_sternchen then
              summe_sternchen = summe_sternchen + breite_sternchen
            else
              if tonumber(spalte_inhalt.breite) then
                self.spaltenbreiten[i] = publisher.aktuelles_raster.rasterbreite * spalte_inhalt.breite
              else
                self.spaltenbreiten[i] = tex.sp(spalte_inhalt.breite)
              end
              summe_echte_breiten = summe_echte_breiten + self.spaltenbreiten[i]
            end
          end
          if spalte_inhalt.hintergrundfarbe then
            self.spaltenfarben[i] = spalte_inhalt.hintergrundfarbe
          end
        end
        anzahl_spalten = i
      end

      if spaltenbreiten_vorgegeben and summe_sternchen == 0 then return end

      if summe_sternchen > 0 then
        trace("Tabelle: Platz bei *-Spalten verteilen (Summe = %d)",summe_sternchen)

        -- nun sind die *-Spalten bekannt und die Summe der fixen-Spalten, so dass ich
        -- den zu verteilenden Platz verteilen kann.
        local zu_verteilen =  self.tabellenbreite_soll - summe_echte_breiten - table.sum(self.spaltenabstaende,1,anzahl_spalten - 1)

        i = 0
        for _,spalte in ipairs(tr_inhalt) do
          if publisher.elementname(spalte)=="Spalte" then
            local spalte_inhalt = publisher.inhalt(spalte)
            i = i + 1
            local breite_sternchen = string.match(spalte_inhalt.breite,patt)
            if breite_sternchen then
              self.spaltenbreiten[i] = math.round( zu_verteilen *  breite_sternchen / summe_sternchen ,0)
            end
          end
        end
      end -- summe_* > 0
    end
  end

  if spaltenbreiten_vorgegeben then return end

  -- Phase I: max_wd, min_wd berechnen
  for _,tr in ipairs(self.tab) do
    local tr_inhalt      = publisher.inhalt(tr)
    local tr_elementname = publisher.elementname(tr)

    if tr_elementname == "Tr" then
      aktuelle_zeile = aktuelle_zeile + 1
      self:berechne_spaltenbreite_fuer_zeile(tr_inhalt,aktuelle_zeile,colspans,colmin,colmax)
    elseif tr_elementname == "Tlinie" then
      --ignorieren
    elseif tr_elementname == "Tabellenkopf" then
      for _,zeile in ipairs(tr_inhalt) do
        local zeile_inhalt  = publisher.inhalt(zeile)
        local zeile_eltname = publisher.elementname(zeile)
        if zeile_eltname == "Tr" then
          aktuelle_zeile = aktuelle_zeile + 1
          self:berechne_spaltenbreite_fuer_zeile(zeile_inhalt,aktuelle_zeile,colspans,colmin,colmax)
        end
      end
    elseif tr_elementname == "Tabellenfuß" then
      for _,zeile in ipairs(tr_inhalt) do
        local zeile_inhalt  = publisher.inhalt(zeile)
        local zeile_eltname = publisher.elementname(zeile)
        if zeile_eltname == "Tr" then
          aktuelle_zeile = aktuelle_zeile + 1
          self:berechne_spaltenbreite_fuer_zeile(zeile_inhalt,aktuelle_zeile,colspans,colmin,colmax)
        end
      end
    else
      w("unbekanntes Element: %q",tr_elementname)
    end -- wenn es auch wirklich eine Zeile ist
  end -- ∀ Zeilen / Linien


  -- Jetzt sind wir in allen Zeilen alle Zellen durchgegangen. Wenn es colspans gibt,
  -- dann kann sein, dass wir manche Spaltenbreiten erhöhen müssen!
  --
  -- Beispiel (fake):
  -- <Tabelle breite="30">
  --   <Tr><Td>A</Td><Td>A</Td></Tr>
  --   <Tr><Td colspan="2">Ein ganz schön langer Text</Td></Tr>
  -- </Tabelle>
  -- ----------------------------
  -- |A           |A            |
  -- |Ein ganz schön langer Text|
  -- ----------------------------
  --
  -- In diesem Fall ist sum_min in etwa die Läne von "langer" und sum_max ist die Länge des Textes.
  -- colmax[i] ist die Breite von "A", colmin[i] ebenfalls

  -- Phase II: Colspan einbeziehen

  trace("Tabelle: colmin/colmax anpassen")
  -- colmin/colmax anpassen (wenn wir colspans haben)
  for i,colspan in pairs(colspans) do
    trace("Tabelle: colspan #%d",i)
    local sum_min,sum_max = 0,0
    local r -- Streckfaktor = wd(colspan)/wd(Summe_start_ende)

    -- erst einmal berechnen, wie breit die Spalten sind, die mit dem colspan überdeckt werden,
    -- aber ohne den colspan eingerechnet.
    sum_max = table.sum(colmax,colspan.start,colspan.ende)
    sum_min = table.sum(colmin,colspan.start,colspan.ende)

    -- Wenn der colspan mehr Platz benötigt, als der Rest der Tabelle, dann müssen ja
    -- die Spaltenbreiten der Tabelle entsprechend erhöht werden. Dazu wird dann jede
    -- Spalte um einen Faktor r gestreckt. r wird aufgrund des Inhalts berechnet.

    -- Das machen wir einmal für die maximale Breite und einmal für die minimale Breite
    local breite_des_colseps = table.sum(self.spaltenabstaende,colspan.start,colspan.start)

    if colspan.max_wd > sum_max + breite_des_colseps then
      r = ( colspan.max_wd - breite_des_colseps ) / sum_max
      for j=colspan.start,colspan.ende do
        colmax[j] = colmax[j] * r
      end
    end -- colspan.max_wd > sum_max?

    if colspan.min_wd > sum_min + breite_des_colseps then
      r = ( colspan.min_wd - breite_des_colseps ) / sum_min
      for j=colspan.start,colspan.ende do
        colmin[j] = colmin[j] * r
      end
    end -- colspan.min_wd > sum_min?
  end -- ∀ colspans

  -- So, jetzt sind für alle Spalten colmin und colmax berechnet. Die colspans sind mit einbezogen worden.


  -- Phase III: Tabelle stauchen oder strecken

  -- Jetzt kommt die eigentliche Breitenberechnung
  -- ---------------------------------------------
  -- FIXME: hier statt self.colsep die spaltenabstaende[i] berücksichtigen
  local colsep = (#colmax - 1) * self.colsep
  local tabellenbreite_ist = table.sum(colmax) + colsep

  -- 1) natürliche (max) Breite / Gesamtbreite für jede Spalte berechnen

  -- Wenn dehnen="nein" ist, dann kann es immer noch sein, dass die Tabelle zu breit geworden ist.
  -- dann muss sie gestaucht werden.

  -- unwahrscheinlicher Fall, dass es exakt passt:
  if tabellenbreite_ist == self.tabellenbreite_soll then
    for i=1,#colmax do
      self.spaltenbreiten[i] = colmax[i]
    end
    return
  end

  -- Wenn die Tabelle zu breit ist, dann müssen manche Spalten verkleinert werden.
  if tabellenbreite_ist > self.tabellenbreite_soll then
    local col_r = {} -- temporäre Spaltenbreite nach der Stauchung
    local schrumpf_faktor = {}
    local summe_schrumpffaktor = 0
    local ueberschuss = 0
    local r = ( self.tabellenbreite_soll - colsep )  / ( tabellenbreite_ist - colsep)
    for i=1,#colmax do
      -- eigentlich:
      -- r[i] = colmax[i] / tabellenbreite_ist
      -- aber um auf die Zellenbreite zu kommen muss ich mit tabellenbreite_soll multiplizieren
      col_r[i] = colmax[i] * r

      -- Wenn nun die errechnete Breite kleiner ist als die minimale Breite, dann muss die 
      -- Zelle vergrößert werden und die Gesamtbreite um den Überschuss verringert werden
      if col_r[i] < colmin[i] then
        ueberschuss = ueberschuss + colmin[i] - col_r[i]
        self.spaltenbreiten[i] = colmin[i]
      end
      if col_r[i] > colmin[i] then
        -- diese Spalte kann wenn nötig verkleinert werden. Der Faktor ist col_r[i] / colmin[i]
        schrumpf_faktor[i] = col_r[i] / colmin[i]
        summe_schrumpffaktor = summe_schrumpffaktor + schrumpf_faktor[i]
      end
    end
    -- dieser Überschuss muss nun anteilig von den zu breiten Spalten abgezogen werden
    for i=1,#colmax do
      --
      if schrumpf_faktor[i] then
        self.spaltenbreiten[i] = col_r[i] -  schrumpf_faktor[i] / summe_schrumpffaktor * ueberschuss
      end
    end
    return
  end

  -- Wenn dehnen="nein" ist, dann brauchen wir nicht zu Strecken/stauchen
  if self.autostretch ~= "max" then
    self.tabellenbreite_soll = tabellenbreite_ist
    for i=1,#colmax do
      self.spaltenbreiten[i] = colmax[i]
    end
    return
  end


  -- Wenn die Tabelle zu schmal für den Text ist, dann muss sie breiter werden.
  if tabellenbreite_ist < self.tabellenbreite_soll then
    -- die Tabelle muss breiter werden
    local r = ( self.tabellenbreite_soll - colsep ) / ( tabellenbreite_ist - colsep )
    for i=1,#colmax do
      self.spaltenbreiten[i] = colmax[i] * r
    end
  end
end

function berechne_zeilenhoehe( self,tr_inhalt, aktuelle_zeile )
  local zeilenhoehe
  local rowspan,colspan
  local wd,parameter
  local rowspans = {}

  local fam = publisher.fonts.lookup_schriftfamilie_nummer_instanzen[self.schriftfamilie]
  local min_lineheight = fam.zeilenabstand

  if tr_inhalt.minhoehe then
    zeilenhoehe = math.max(publisher.aktuelles_raster.rasterhoehe * tr_inhalt.minhoehe, min_lineheight)
  else
    zeilenhoehe = min_lineheight
  end

  aktuelle_spalte = 0

  for _,td in ipairs(tr_inhalt) do
    local td_inhalt = publisher.inhalt(td)
    aktuelle_spalte = aktuelle_spalte + 1


    local td_randlinks  = tex.sp(td_inhalt["border-left"]   or 0)
    local td_randrechts = tex.sp(td_inhalt["border-right"]  or 0)
    local td_randoben   = tex.sp(td_inhalt["border-top"]    or 0)
    local td_randunten  = tex.sp(td_inhalt["border-bottom"] or 0)

    local padding_left   = td_inhalt.padding_left   or self.padding_left
    local padding_right  = td_inhalt.padding_right  or self.padding_right
    local padding_top    = td_inhalt.padding_top    or self.padding_top
    local padding_bottom = td_inhalt.padding_bottom or self.padding_bottom

    rowspan = tonumber(td_inhalt.rowspan) or 1
    colspan = tonumber(td_inhalt.colspan) or 1

    wd = 0
    for s = aktuelle_spalte,aktuelle_spalte + colspan - 1 do
      wd = wd + self.spaltenbreiten[s]
    end
    aktuelle_spalte = aktuelle_spalte + colspan - 1

    -- FIXME: hier statt self.colsep die spaltenabstaende[i] berücksichtigen
    wd = wd + ( colspan - 1 ) * self.colsep
    -- hier unbedingt(!!) border-left und border-right beachten FIXME
    -- in der Höhenberechnung auch border-top und border-bottom! FIXME
    local zelle

    -- Die Objekte wurden in der Spaltenbreitenbestimmung
    -- hinzugefügt. Falls die Spaltenbreiten vogegeben wurden,
    -- dann wurde die Spaltenbreitenbestimmung ja gar nicht aufgerufen
    -- und die Objekte müssen hier hinzugefügt werden (not DRY!)
    if not td_inhalt.objekte then
      local objekte = {}

      for i,j in ipairs(td_inhalt) do
        if publisher.elementname(j) == "Absatz" then
          objekte[#objekte + 1] = publisher.inhalt(j)
        elseif publisher.elementname(j) == "Bild" then
          -- FIXME: Bild sollte auch ein "Objekt" sein
          objekte[#objekte + 1] = publisher.inhalt(j)
        elseif publisher.elementname(j) == "Tabelle" then
          -- FIXME: Bild sollte auch ein "Objekt" sein
          objekte[#objekte + 1] = publisher.inhalt(j)[1]
        else
          warning("Object not recognized: %s",publisher.elementname(j) or "???")
        end
      end
      -- trace("Tabelle: Objekte für die Tabellenzelle eingelesen (berechne_zeilenhoehen)")
      td_inhalt.objekte = objekte
    end

    for _,objekt in ipairs(td_inhalt.objekte) do
      if type(objekt)=="table" then
        if not (objekt and objekt.nodelist) then
          w("Achtung, keine Nodeliste gefunden!")
        end

        if objekt.nodelist then
          -- FIXME: dynamisches Textformat
          -- objekt:textformat_anwenden("text")
          parameter = nil
          if objekt.textformat then
            if not publisher.textformate[objekt.textformat] then
              err("Textformat %q not defined!",objekt.textformat)
            else
              if publisher.textformate[objekt.textformat]["ausrichtung"] == "linksbündig" then
                parameter = { rightskip = publisher.rightskip }
              end
              if publisher.textformate[objekt.textformat]["ausrichtung"] == "rechtsbündig" then
                parameter = { leftskip = publisher.leftskip }
              end
              if publisher.textformate[objekt.textformat]["ausrichtung"] == "zentriert" then
                parameter = { leftskip = publisher.leftskip, rightskip = publisher.rightskip }
              end
            end
          else
            local align = td_inhalt.align or tr_inhalt.align or self.align[aktuelle_spalte]
            if align=="center" then
              parameter = { leftskip = publisher.leftskip, rightskip = publisher.rightskip }
            elseif align=="left" then
              parameter = { rightskip = publisher.rightskip }
            elseif align=="right" then
              parameter = { leftskip = publisher.leftskip }
            end
          end
          publisher.setze_fontfamilie_wenn_notwendig(objekt.nodelist,self.schriftfamilie)
          publisher.fonts.pre_linebreak(objekt.nodelist)
        end
        tmp = node.copy_list(objekt.nodelist)
        local align = td_inhalt.align or tr_inhalt.align or self.align[aktuelle_spalte]
        if align=="center" then
          tmp = publisher.add_glue(tmp,"head", fill)
          tmp = publisher.add_glue(tmp,"tail", fill)
        elseif align == "right" then
          tmp = publisher.add_glue(tmp,"head", fill)
        end

        local v = publisher.do_linebreak(tmp,wd - padding_left - padding_right - td_randlinks - td_randrechts, parameter)
        if zelle then
          node.tail(zelle).next = v
        else
          zelle = v
        end
      elseif (type(objekt)=="userdata" and node.has_field(objekt,"width")) then
        if zelle then
          node.tail(zelle).next = objekt
        else
          zelle = objekt
        end
      end
    end
    -- wenn keine Objekte in einer Zeile sind, dann erzeugen wir
    -- ein dummy-Objekt, damit die Zeile erzeugt werden kann (und vpack nicht)
    -- über ein nil stolpert.
    if not zelle then
      zelle = node.new("hlist")
    end
    v=node.vpack(zelle)

    tmp = v.height + v.depth +  padding_top + padding_bottom + td_randunten + td_randoben
    if rowspan > 1 then
      rowspans[#rowspans + 1] =  { start = aktuelle_zeile, ende = aktuelle_zeile + rowspan - 1, ht = tmp }
      td_inhalt.rowspan_internal = rowspans[#rowspans]
    else
      zeilenhoehe = math.max(zeilenhoehe,tmp)
    end
    -- FIXME: node.flushlist tmp ??
    -- node.flush_list(v)
    -- Attempt to double-free hlist node 387580, ignored.
  end
  return zeilenhoehe,rowspans
end


--------------------------------------------------------------------------
function berechne_zeilenhoehen(self)
  trace("Tabelle: berechne Zeilenhöhen")
  local aktuelle_zeile = 0
  local rowspans = {}
  local _rowspans


  for _,tr in ipairs(self.tab) do
    local tr_inhalt = publisher.inhalt(tr)
    local eltname = publisher.elementname(tr)

    if eltname == "Tlinie" or eltname == "Spalten" then
      -- ignorieren

    elseif eltname == "Tabellenkopf" then
      for _,zeile in ipairs(tr_inhalt) do
        local zeile_inhalt  = publisher.inhalt(zeile)
        local zeile_eltname = publisher.elementname(zeile)
        if zeile_eltname == "Tr" then
          aktuelle_zeile = aktuelle_zeile + 1
          zeilenhoehe, _rowspans = self:berechne_zeilenhoehe(zeile_inhalt,aktuelle_zeile)
          self.zeilenhoehen[aktuelle_zeile] = zeilenhoehe
          rowspans = table.__concat(rowspans,_rowspans)
        end
      end
    elseif eltname == "Tabellenfuß" then
      for _,zeile in ipairs(tr_inhalt) do
        local zeile_inhalt  = publisher.inhalt(zeile)
        local zeile_eltname = publisher.elementname(zeile)
        if zeile_eltname == "Tr" then
          aktuelle_zeile = aktuelle_zeile + 1
          zeilenhoehe, _rowspans = self:berechne_zeilenhoehe(zeile_inhalt,aktuelle_zeile)
          self.zeilenhoehen[aktuelle_zeile] = zeilenhoehe
          rowspans = table.__concat(rowspans,_rowspans)
        end
      end

    elseif eltname == "Tr" then
      aktuelle_zeile = aktuelle_zeile + 1
      zeilenhoehe, _rowspans = self:berechne_zeilenhoehe(tr_inhalt,aktuelle_zeile)
      self.zeilenhoehen[aktuelle_zeile] = zeilenhoehe
      rowspans = table.__concat(rowspans,_rowspans)
    else
      warning("Unknown contents in »Tabelle«")
    end -- wenn es nicht eine <Tlinie> ist
  end -- für alle Zeilen

  -- Zeilenhöhen anpassen. Erst müssen alle möglichen Verschiebungen in den Zeilenhöhen
  -- berechnet werden, bevor den eigentlichen rowspans ihre Höhen bekommen (aufgrund der Zeilenhöhen)
  for i,rowspan in pairs(rowspans) do
    trace("Tabelle: Zeilenhöhen anpassen")
    local sum_ht = 0
    trace("Tabelle: rowspan.start = %d, rowspan.ende = %d. self.rowsep = %gpt",rowspan.start,rowspan.ende,self.rowsep)
    for j=rowspan.start,rowspan.ende do
      trace("Tabelle: füge %gpt hinzu (Zeile %d)",self.zeilenhoehen[j] / 2^16,j)
      sum_ht = sum_ht + self.zeilenhoehen[j]
    end
    sum_ht = sum_ht + self.rowsep * ( rowspan.ende - rowspan.start )
    trace("Tabelle: Rowspan (%d) > Zeilenhöhen %gpt > %gpt?",rowspan.ende - rowspan.start + 1 ,rowspan.ht / 2^16 ,sum_ht / 2^16)
    if rowspan.ht > sum_ht then
      local ueberschuss_je_zeile = (rowspan.ht - sum_ht) / (rowspan.ende - rowspan.start + 1)
      trace("Tabelle: Überschuss je Zeile = %gpt",ueberschuss_je_zeile / 2^16)
      for j=rowspan.start,rowspan.ende do
        self.zeilenhoehen[j] = self.zeilenhoehen[j] + ueberschuss_je_zeile
      end
    end
  end

  -- erst jetzt sind alle Zeilenhöhen berechnet. Dadurch können die rowspans angepasst werden.
  for i,rowspan in pairs(rowspans) do
    rowspan.sum_ht = table.sum(self.zeilenhoehen,rowspan.start, rowspan.ende) + self.rowsep * ( rowspan.ende - rowspan.start )
  end
end

function setze_zeile(self, tr_inhalt, aktuelle_zeile )
  local aktuelle_spalte
  local aktuelle_spaltenbreite, ht
  local zeile = {}
  local rowspan, colspan
  local v,vlist,hlist
  local fill = { width = 0, stretch = 2^16, stretch_order = 3}

  aktuelle_spalte = 0
  for _,td in ipairs(tr_inhalt) do

    aktuelle_spalte = aktuelle_spalte + 1

    td_inhalt = publisher.inhalt(td)
    rowspan = tonumber(td_inhalt.rowspan) or 1
    colspan = tonumber(td_inhalt.colspan) or 1

    -- FIXME: bin ich sicher, das ich in der richtigen Spalte bin (colspan...)?
    local td_randlinks  = tex.sp(td_inhalt["border-left"]   or 0)
    local td_randrechts = tex.sp(td_inhalt["border-right"]  or 0)
    local td_randoben   = tex.sp(td_inhalt["border-top"]    or 0)
    local td_randunten  = tex.sp(td_inhalt["border-bottom"] or 0)

    local padding_left   = td_inhalt.padding_left   or self.padding_left
    local padding_right  = td_inhalt.padding_right  or self.padding_right
    local padding_top    = td_inhalt.padding_top    or self.padding_top
    local padding_bottom = td_inhalt.padding_bottom or self.padding_bottom


    -- Wenn ich auf einer Skip-Spalte bin (durch einen Rowspan), dann
    -- muss eine leere hbox erzeugt werden
    while self.skip[aktuelle_zeile] and self.skip[aktuelle_zeile][aktuelle_spalte] do
      v = publisher.erzeuge_leere_hbox_mit_breite(self.spaltenbreiten[aktuelle_spalte])
      v = publisher.add_glue(v,"head",fill) -- sonst gäb's ne underfull vbox
      zeile[aktuelle_spalte] = node.vpack(v,self.zeilenhoehen[aktuelle_zeile],"exactly")
      aktuelle_spalte = aktuelle_spalte + 1
    end

    -- rowspan? - nicht DRY: dasselbe wurde schon in berechne_spaltenbreite gemacht
    for z = aktuelle_zeile + 1, aktuelle_zeile + rowspan - 1 do
      for y = aktuelle_spalte, aktuelle_spalte + colspan - 1 do
        self.skip[z] = self.skip[z] or {}  self.skip[z][y] = true
      end
    end

    aktuelle_spaltenbreite = 0
    for s = aktuelle_spalte,aktuelle_spalte + colspan - 1 do
       aktuelle_spaltenbreite = aktuelle_spaltenbreite + self.spaltenbreiten[s]
    end
    -- FIXME: hier statt self.colsep die spaltenabstaende[i] berücksichtigen
    aktuelle_spaltenbreite = aktuelle_spaltenbreite + ( colspan - 1 ) * self.colsep
    aktuelle_spalte = aktuelle_spalte + colspan - 1

    if rowspan > 1 then
      ht = td_inhalt.rowspan_internal.sum_ht
    else
      ht = self.zeilenhoehen[aktuelle_zeile]
    end
    -- FIXME: muss ich wirklich hier noch einmal alles setzen? Ich habe doch schon im
    -- vorherigen Anlauf (Zeilenhöhe bestimmen) alles in einen absatz gepackt!?!?

    local g = node.new("glue")
    g.spec = node.new("glue_spec")
    g.spec.width = padding_top

    local valign = td_inhalt.valign or tr_inhalt.valign or self.valign[aktuelle_spalte]
    if valign ~= "top" then
      g.spec.stretch = 2^16
      g.spec.stretch_order = 2
    end

    local zelle_start = g

    local zelle
    local current = node.tail(zelle_start)


    for _,objekt in ipairs(td_inhalt.objekte) do
      if type(objekt) == "table" then
        if not (objekt and objekt.nodelist) then
          warning("No nodelist found!")
        end
        v = node.copy_list(objekt.nodelist)
      elseif type(objekt) == "userdata" then
        v = node.copy_list(objekt)
      end

      if type(objekt) == "table" then
        -- Absatz mit Nodeliste
        local parameter = nil
        if objekt.textformat then
          if not publisher.textformate[objekt.textformat] then
            err("Textformat %q not defined!",objekt.textformat)
          else
            if publisher.textformate[objekt.textformat]["ausrichtung"] == "linksbündig" then
              parameter = { rightskip = publisher.rightskip }
            end
            if publisher.textformate[objekt.textformat]["ausrichtung"] == "rechtsbündig" then
              parameter = { leftskip = publisher.leftskip }
            end
            if publisher.textformate[objekt.textformat]["ausrichtung"] == "zentriert" then
              parameter = { leftskip = publisher.leftskip, rightskip = publisher.rightskip }
            end
          end
        else
          local align = td_inhalt.align or tr_inhalt.align or self.align[aktuelle_spalte]
          if align=="center" then
            parameter = { leftskip = publisher.leftskip, rightskip = publisher.rightskip }
          elseif align=="left" then
            parameter = { rightskip = publisher.rightskip }
          elseif align=="right" then
            parameter = { leftskip = publisher.leftskip }
          end
        end
        v = publisher.do_linebreak(v, aktuelle_spaltenbreite - padding_left - padding_right - td_randlinks - td_randrechts, parameter)
        if publisher.optionen.trace == "ja" then
          v = publisher.boxit(v)
        end
      elseif type(objekt) == "userdata" then
        v = node.hpack(v)
      else
        assert(false)
      end
      current.next = v
      current = v
    end

    g = node.new("glue")
    g.spec = node.new("glue_spec")
    g.spec.width = padding_bottom

    local valign = td_inhalt.valign or tr_inhalt.valign or self.valign[aktuelle_spalte]
    if valign ~= "bottom" then
      g.spec.stretch = 2^16
      g.spec.stretch_order = 2
    end

    current.next = g

    vlist = node.vpack(zelle_start,ht - td_randoben - td_randunten,"exactly")

    -- vlist ist jetzt fertig mit der Zelle. Jetzt in eine hlist packen
    g = node.new("glue")
    g.spec = node.new("glue_spec")
    g.spec.width = padding_left


    local align = td_inhalt.align or tr_inhalt.align or self.align[aktuelle_spalte]
    if align ~= "left" then
      g.spec.stretch = 2^16
      g.spec.stretch_order = 2
    end

    zelle_start = g

    if td_inhalt["border-left"] then
      local start, stop = publisher.farbbalken(tex.sp(td_inhalt["border-left"]),-1073741824,-1073741824,td_inhalt["border-left-color"])
      stop.next = g
      zelle_start = start
    end

    current = node.tail(zelle_start)
    current.next = vlist
    current = vlist

    g = node.new("glue")
    g.spec = node.new("glue_spec")
    g.spec.width = padding_right

    local align = td_inhalt.align or tr_inhalt.align or self.align[aktuelle_spalte]
    if align ~= "right" then
      g.spec.stretch = 2^16
      g.spec.stretch_order = 2
    end

    current.next = g
    current = g

    if td_inhalt["border-right"] then
      local rule = publisher.farbbalken(tex.sp(td_inhalt["border-right"]),-1073741824,-1073741824,td_inhalt["border-right-color"])
      g.next = rule
    end

    hlist = node.hpack(zelle_start,aktuelle_spaltenbreite,"exactly")

    -- So, jetzt ist die Zelle vollständig (bis auf die top/bottom rule). Hier kann jetzt die Hintergrundfarbe gesetzt werden.
    if tr_inhalt.hintergrundfarbe or td_inhalt.hintergrundfarbe or self.spaltenfarben[aktuelle_spalte] then
      -- prio: Td.hintergrundfarbe, dann Tr.hintergrundfarbe, dann Spalte.hintergrundfarbe
      local farbe = self.spaltenfarben[aktuelle_spalte]
      farbe = tr_inhalt.hintergrundfarbe or farbe
      farbe = td_inhalt.hintergrundfarbe or farbe
      hlist = publisher.hintergrund(hlist,farbe)
    end

    local head = hlist
    if td_inhalt["border-top"] then
      local rule = publisher.farbbalken(-1073741824,tex.sp(td_inhalt["border-top"]),0,td_inhalt["border-top-color"])
      -- rule besteht aus whatsit, rule, whatsit
      node.tail(rule).next = hlist
      head = rule
    end

    if td_inhalt["border-bottom"] then
      local rule = publisher.farbbalken(-1073741824,tex.sp(td_inhalt["border-bottom"]),0,td_inhalt["border-bottom-color"])
      hlist.next = rule
    end


    -- vlist.height = self.zeilenhoehen[aktuelle_zeile]
    -- hlist.height = self.zeilenhoehen[aktuelle_zeile]
    local gl = node.new("glue")
    gl.spec = node.new("glue_spec")
    gl.spec.width = 0
    gl.spec.shrink = 2^16
    gl.spec.shrink_order = 2
    node.slide(head).next = gl

    hlist = node.vpack(head,self.zeilenhoehen[aktuelle_zeile],"exactly")

    if publisher.optionen.trace == "ja" then
      publisher.boxit(hlist)
    end

    zeile[#zeile + 1] = hlist

  end -- ende td

  if aktuelle_spalte == 0 then
    trace("Tabelle: keine Td-Zellen in dieser Spalte gefunden")
    v = publisher.erzeuge_leere_hbox_mit_breite(self.tabellenbreite_soll)
    trace("Tabelle: leere hbox erzeugt")
    v = publisher.add_glue(v,"head",fill) -- sonst gäb's ne underfull vbox
    zeile[1] = node.vpack(v,self.zeilenhoehen[aktuelle_zeile],"exactly")
  end

  local zelle, zelle_start,current
  zelle_start = zeile[1]
  current = zelle_start

  -- FIXME: hier statt self.colsep die spaltenabstaende[i] berücksichtigen
  if zeile[1] then
    for z=2,#zeile do
      _,current = publisher.add_glue(current,"tail",{ width = self.colsep })
      current.next = zeile[z]
      current = zeile[z]
    end
    zeile = node.hpack(zelle_start)
  else
    err("(Internal error) Table is not complete.")
  end
  return zeile
end

--------------------------------------------------------------------------

function setze_tabelle(self)
  trace("Tabelle: setze Tabelle")
  local aktuelle_zeile
  local kopfzeilen = {}
  local fusszeilen = {}
  local zeilen = {}

  aktuelle_zeile = 0
  for _,tr in ipairs(self.tab) do
    local tr_inhalt = publisher.inhalt(tr)
    local eltname   = publisher.elementname(tr)
    local tmp

    if eltname == "Spalten" then
      -- ignorieren
    elseif eltname == "Tlinie" then
      tmp = publisher.farbbalken(self.tabellenbreite_soll,tex.sp(tr_inhalt.linienstaerke or "0.25pt"),0,tr_inhalt.farbe)
      zeilen[#zeilen + 1] = node.hpack(tmp)

    elseif eltname == "Tabellenkopf" then
      for _,zeile in ipairs(tr_inhalt) do
        zeile_inhalt = publisher.inhalt(zeile)
        zeile_eltname = publisher.elementname(zeile)
        if zeile_eltname == "Tr" then
          aktuelle_zeile = aktuelle_zeile + 1
          kopfzeilen[#kopfzeilen + 1] = self:setze_zeile(zeile_inhalt,aktuelle_zeile)
        elseif zeile_eltname == "Tlinie" then
          tmp = publisher.farbbalken(self.tabellenbreite_soll,tex.sp(zeile_inhalt.linienstaerke or "0.25pt"),0,zeile_inhalt.farbe)
          kopfzeilen[#kopfzeilen + 1] = node.hpack(tmp)
        end
      end

    elseif eltname == "Tabellenfuß" then
      for _,zeile in ipairs(tr_inhalt) do
        zeile_inhalt = publisher.inhalt(zeile)
        zeile_eltname = publisher.elementname(zeile)
        if zeile_eltname == "Tr" then
          aktuelle_zeile = aktuelle_zeile + 1
          fusszeilen[#fusszeilen + 1] = self:setze_zeile(zeile_inhalt,aktuelle_zeile)
        elseif zeile_eltname == "Tlinie" then
          tmp = publisher.farbbalken(self.tabellenbreite_soll,tex.sp(zeile_inhalt.linienstaerke or "0.25pt"),0,zeile_inhalt.farbe)
          fusszeilen[#fusszeilen + 1] = node.hpack(tmp)
        end
      end

    elseif eltname == "Tr" then
      aktuelle_zeile = aktuelle_zeile + 1
      zeilen[#zeilen + 1] = self:setze_zeile(tr_inhalt,aktuelle_zeile)
    else
      warning("Unknown contents in »Tabelle«")
    end -- wenn es eine Tabellenzelle ist
  end

  local ht_kopfzeilen = 0
  for z = 1,#kopfzeilen - 1 do
    ht_kopfzeilen = ht_kopfzeilen + kopfzeilen[z].height  -- Tr oder TLinie
    _,tmp = publisher.add_glue(kopfzeilen[z],"tail",{ width = self.rowsep })
    tmp.next = kopfzeilen[z+1]
    kopfzeilen[z+1].prev = tmp
  end
  -- publisher.add_glue(kopfzeilen[#kopfzeilen],"tail",{ width = self.rowsep })

  ht_kopfzeilen = ht_kopfzeilen + ( self.rowsep - 1 ) * #kopfzeilen


  local ht_fusszeilen = 0
  for z = 1,#fusszeilen - 1 do
    ht_fusszeilen = ht_fusszeilen + fusszeilen[z].height  -- Tr oder TLinie
    _,tmp = publisher.add_glue(fusszeilen[z],"tail",{ width = self.rowsep })
    tmp.next = fusszeilen[z+1]
    fusszeilen[z+1].prev = tmp
  end
  ht_fusszeilen = ht_fusszeilen + ( self.rowsep - 1 ) * #fusszeilen

  -- Hier sind die maximalen Höhen gespeichert, [1] für die erste Tabelle, [2] für die zweite Tabelle, ...
  local pagegoals = { self.optionen.ht_aktuell - ht_kopfzeilen - ht_fusszeilen  }
  setmetatable(pagegoals, { __index = function() return self.optionen.ht_max - ht_kopfzeilen - ht_fusszeilen end})


  -- durch einen split werden mehrere Tabellen zurück gegeben
  local tabellen = {}
  local aktuelle_tabelle
  local anzahl_zeilen_in_der_aktuellen_tabelle = 0
  local tmp
  if not trace_objekt_counter then  trace_objekt_counter = 0 end

  if not kopfzeilen[1] then
    kopfzeilen[1] = node.new("hlist") -- dummy-Kopfzeile
  end
  if not fusszeilen[1] then
    fusszeilen[1] = node.new("hlist") -- dummy-Fußzeile
  end

  aktuelle_tabelle = node.copy_list(kopfzeilen[1]) -- später löschen
  tabellen[#tabellen + 1] = aktuelle_tabelle

  local pagegoal = pagegoals[1]

  for z = 1,#zeilen do
    local ht_zeile = zeilen[z].height + zeilen[z].depth

    if ht_zeile < pagegoal then
      _,tmp = publisher.add_glue(aktuelle_tabelle,"tail",{ width = self.rowsep })
      tmp.next = zeilen[z]
      anzahl_zeilen_in_der_aktuellen_tabelle = anzahl_zeilen_in_der_aktuellen_tabelle + 1
      pagegoal = pagegoal - ht_zeile
    else
      if anzahl_zeilen_in_der_aktuellen_tabelle > 0 then
        local last = node.tail(aktuelle_tabelle)
        local tmp_fuss = node.copy_list(fusszeilen[1])
        last.next = tmp_fuss
        tmp_fuss.prev = last

        aktuelle_tabelle = node.copy_list(kopfzeilen[1]) -- später löschen
        tabellen[#tabellen + 1] = aktuelle_tabelle
        anzahl_zeilen_in_der_aktuellen_tabelle = 0
        pagegoal = pagegoals[#tabellen]
        _,tmp = publisher.add_glue(aktuelle_tabelle,"tail",{ width = self.rowsep })
        tmp.next = zeilen[z]
        pagegoal = pagegoal - ht_zeile
      else
        -- keine Zeile eingefügt
        pagegoal = pagegoals[#tabellen + 1]
      end
    end
  end
  local last = node.tail(aktuelle_tabelle)
  local tmp_fuss = node.copy_list(fusszeilen[1])
  last.next = tmp_fuss
  tmp_fuss.prev = last

  -- Jetzt sind alle Zeilen zu einer Nodelist verbunden
  if not zeilen[1] then
    err("No row found in table")
    zeilen[1] = publisher.erzeuge_leere_hbox_mit_breite(100)
  end

  for i=1,#tabellen do
    tabellen[i] = node.vpack(tabellen[i])
  end
  return tabellen
end


function tabelle( self )
  setmetatable(self.spaltenabstaende,{ __index = function() return self.colsep or 0 end })
  berechne_spaltenbreite(self)
  berechne_zeilenhoehen(self)
  return setze_tabelle(self)
end

datei_ende("tabelle.lua")
