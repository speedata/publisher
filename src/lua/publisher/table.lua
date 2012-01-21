--
--  publisher/src/lua/tabelle.lua
--  speedata publisher
--
--  Copyright 2010-2012 Patrick Gundlach.
--  See file COPYING in the root directory for license details.


file_start("table.lua")
require("xpath")

module(...,package.seeall)


function new( self )
  assert(self)
  local t = {

   rowheights     = {},
   colwidths      = {},
   align          = {},
   valign         = {},
   skip           = {},
   tablewidth_target,
   columncolors  = {},
   -- Der Abstand zwischen Spalte i und i+1, derzeit nicht benutzt
   spaltenabstaende = {},
   anzahl_zeilen_im_kopf = 0,
  }

	setmetatable(t, self)
	self.__index = self
	return t
end

--------------------------------------------------------------------------
function calculate_spaltenbreite_fuer_zeile(self, tr_contents,current_row,colspans,colmin,colmax )
  local current_column
  local max_wd, min_wd -- maximale Breite und minimale Breite einer Tabellenzelle (Td)
  -- als erstes die einzelnen Zeilen/Zellen durchgehen und schauen, wie breit die 
  -- Spalten sein müssen. Wenn es colspans gibt, müssen diese entsprechend
  -- berücksichtigt werden.
  current_column = 0

  for _,td in ipairs(tr_contents) do
    local td_contents = publisher.inhalt(td)
    -- alle Spalten durchgehen
    -- skip, colspan und colmax-Tabellen ausfüllen für diese Tabellenzelle:
    current_column = current_column + 1
    min_wd,max_wd = nil,nil
    local rowspan = tonumber(td_contents.rowspan) or 1
    local colspan = tonumber(td_contents.colspan) or 1

    -- Wenn ich auf einer Skip-Spalte bin (durch einen Rowspan), dann überspringe ich die Spalte einfach
    while self.skip[current_row] and self.skip[current_row][current_column] do current_column = current_column + 1 end
    -- rowspan?
    for z = current_row + 1, current_row + rowspan - 1 do
      for y = current_column, current_column + colspan - 1 do
        self.skip[z] = self.skip[z] or {}  self.skip[z][y] = true
      end
    end

    local objects = {}

    for i,j in ipairs(td_contents) do
      if publisher.elementname(j,true) == "Paragraph" then
        objects[#objects + 1] = publisher.inhalt(j)
      elseif publisher.elementname(j,true) == "Image" then
        -- FIXME: Bild sollte auch ein "Objekt" sein
        objects[#objects + 1] = publisher.inhalt(j)
      elseif publisher.elementname(j,true) == "Table" then
        -- FIXME: Bild sollte auch ein "Objekt" sein
        objects[#objects + 1] = publisher.inhalt(j)[1]
      else
        warning("Object not recognized: %s",publisher.elementname(j) or "???")
      end
    end
    td_contents.objects = objects

    local td_randlinks  = tex.sp(td_contents["border-left"]  or 0)
    local td_randrechts = tex.sp(td_contents["border-right"] or 0)

    local padding_left  = td_contents.padding_left  or self.padding_left
    local padding_right = td_contents.padding_right or self.padding_right

    for _,object in ipairs(objects) do
      -- FIXME: (Default-)Textformate für Absätze
      if type(object)=="table" then
        trace("Tabelle: überprüfe auf Nodeliste (%s)",tostring(object.nodelist ~= nil))

        if object.nodelist then
          -- FIXME: dynamisches Textformat
          object:apply_textformat("text")
          publisher.setze_fontfamilie_wenn_notwendig(object.nodelist,self.schriftfamilie)
          publisher.fonts.pre_linebreak(object.nodelist)
        end

        if object.min_width then
          min_wd = math.max(object:min_width() + padding_left  + padding_right + td_randlinks + td_randrechts, min_wd or 0)
        end
        if object.max_width then
          max_wd = math.max(object:max_width() + padding_left  + padding_right + td_randlinks + td_randrechts, max_wd or 0)
        end
        trace("Tabelle: min_wd, max_wd gesetzt (%gpt,%gpt)",min_wd / 2^16, max_wd / 2^16)
      end
      if not ( min_wd and max_wd) then
        trace("min_wd und max_wd noch nicht gesetzt. Typ(object)==%s",type(object))
        if object.width then
          min_wd = object.width + padding_left  + padding_right + td_randlinks + td_randrechts
          max_wd = object.width + padding_left  + padding_right + td_randlinks + td_randrechts
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
      colspans[#colspans + 1] = { start = current_column, ende = current_column + colspan - 1, max_wd = max_wd, min_wd = min_wd }
      current_column = current_column + colspan - 1
    else
      colmax[current_column] = math.max(colmax[current_column] or 0,max_wd)
      colmin[current_column] = math.max(colmin[current_column] or 0,min_wd)
    end
  end  -- ∀ Spalten
end


function calculate_spaltenbreite( self )
  trace("Tabelle: berechne Spaltenbreiten")
  local colspans = {}
  local colmax,colmin = {},{}

  local current_row = 0
  self.tablewidth_target = self.breite
  local columnwidths_given = false

  for _,tr in ipairs(self.tab) do
    local tr_contents      = publisher.inhalt(tr)
    local tr_elementname = publisher.elementname(tr,true)

    if tr_elementname == "Columns" then
      local wd
      local i = 0
      local summe_sternchen = 0
      local summe_echte_breiten = 0
      local anzahl_spalten = 0
      local patt = "([0-9]+)\*"
      for _,spalte in ipairs(tr_contents) do
        if publisher.elementname(spalte,true)=="Column" then
          local spalte_inhalt = publisher.inhalt(spalte)
          i = i + 1
          self.align[i] =  spalte_inhalt.align
          self.valign[i] = spalte_inhalt.valign
          if spalte_inhalt.breite then
            -- wenn ich eine Angabe bei "Spalte" habe, dann brauche ich ja die Spaltenbreite nicht mehr zu berechnen:
            columnwidths_given = true
            local breite_sternchen = string.match(spalte_inhalt.breite,patt)
            if breite_sternchen then
              summe_sternchen = summe_sternchen + breite_sternchen
            else
              if tonumber(spalte_inhalt.breite) then
                self.colwidths[i] = publisher.current_grid.gridwidth * spalte_inhalt.breite
              else
                self.colwidths[i] = tex.sp(spalte_inhalt.breite)
              end
              summe_echte_breiten = summe_echte_breiten + self.colwidths[i]
            end
          end
          if spalte_inhalt.backgroundcolor then
            self.columncolors[i] = spalte_inhalt.backgroundcolor
          end
        end
        anzahl_spalten = i
      end

      if columnwidths_given and summe_sternchen == 0 then return end

      if summe_sternchen > 0 then
        trace("Tabelle: Platz bei *-Spalten verteilen (Summe = %d)",summe_sternchen)

        -- nun sind die *-Spalten bekannt und die Summe der fixen-Spalten, so dass ich
        -- den zu verteilenden Platz verteilen kann.
        local zu_verteilen =  self.tablewidth_target - summe_echte_breiten - table.sum(self.spaltenabstaende,1,anzahl_spalten - 1)

        i = 0
        for _,spalte in ipairs(tr_contents) do
          if publisher.elementname(spalte,true)=="Column" then
            local spalte_inhalt = publisher.inhalt(spalte)
            i = i + 1
            local breite_sternchen = string.match(spalte_inhalt.breite,patt)
            if breite_sternchen then
              self.colwidths[i] = math.round( zu_verteilen *  breite_sternchen / summe_sternchen ,0)
            end
          end
        end
      end -- summe_* > 0
    end
  end

  if columnwidths_given then return end

  -- Phase I: max_wd, min_wd berechnen
  for _,tr in ipairs(self.tab) do
    local tr_contents      = publisher.inhalt(tr)
    local tr_elementname = publisher.elementname(tr,true)

    if tr_elementname == "Tr" then
      current_row = current_row + 1
      self:calculate_spaltenbreite_fuer_zeile(tr_contents,current_row,colspans,colmin,colmax)
    elseif tr_elementname == "Tablerule" then
      --ignorieren
    elseif tr_elementname == "Tablehead" then
      for _,zeile in ipairs(tr_contents) do
        local zeile_inhalt  = publisher.inhalt(zeile)
        local zeile_eltname = publisher.elementname(zeile,true)
        if zeile_eltname == "Tr" then
          current_row = current_row + 1
          self:calculate_spaltenbreite_fuer_zeile(zeile_inhalt,current_row,colspans,colmin,colmax)
        end
      end
    elseif tr_elementname == "Tablefoot" then
      for _,zeile in ipairs(tr_contents) do
        local zeile_inhalt  = publisher.inhalt(zeile)
        local zeile_eltname = publisher.elementname(zeile,true)
        if zeile_eltname == "Tr" then
          current_row = current_row + 1
          self:calculate_spaltenbreite_fuer_zeile(zeile_inhalt,current_row,colspans,colmin,colmax)
        end
      end
    else
      warning("Unknown Element: %q",tr_elementname)
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
  local tablewidth_is = table.sum(colmax) + colsep

  -- 1) natürliche (max) Breite / Gesamtbreite für jede Spalte berechnen

  -- Wenn dehnen="nein" ist, dann kann es immer noch sein, dass die Tabelle zu breit geworden ist.
  -- dann muss sie gestaucht werden.

  -- unwahrscheinlicher Fall, dass es exakt passt:
  if tablewidth_is == self.tablewidth_target then
    for i=1,#colmax do
      self.colwidths[i] = colmax[i]
    end
    return
  end

  -- Wenn die Tabelle zu breit ist, dann müssen manche Spalten verkleinert werden.
  if tablewidth_is > self.tablewidth_target then
    local col_r = {} -- temporäre Spaltenbreite nach der Stauchung
    local schrumpf_faktor = {}
    local summe_schrumpffaktor = 0
    local ueberschuss = 0
    local r = ( self.tablewidth_target - colsep )  / ( tablewidth_is - colsep)
    for i=1,#colmax do
      -- eigentlich:
      -- r[i] = colmax[i] / tablewidth_is
      -- aber um auf die Zellenbreite zu kommen muss ich mit tablewidth_target multiplizieren
      col_r[i] = colmax[i] * r

      -- Wenn nun die errechnete Breite kleiner ist als die minimale Breite, dann muss die 
      -- Zelle vergrößert werden und die Gesamtbreite um den Überschuss verringert werden
      if col_r[i] < colmin[i] then
        ueberschuss = ueberschuss + colmin[i] - col_r[i]
        self.colwidths[i] = colmin[i]
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
        self.colwidths[i] = col_r[i] -  schrumpf_faktor[i] / summe_schrumpffaktor * ueberschuss
      end
    end
    return
  end

  -- Wenn dehnen="nein" ist, dann brauchen wir nicht zu Strecken/stauchen
  if self.autostretch ~= "max" then
    self.tablewidth_target = tablewidth_is
    for i=1,#colmax do
      self.colwidths[i] = colmax[i]
    end
    return
  end


  -- Wenn die Tabelle zu schmal für den Text ist, dann muss sie breiter werden.
  if tablewidth_is < self.tablewidth_target then
    -- die Tabelle muss breiter werden
    local r = ( self.tablewidth_target - colsep ) / ( tablewidth_is - colsep )
    for i=1,#colmax do
      self.colwidths[i] = colmax[i] * r
    end
  end
end

function calculate_zeilenhoehe( self,tr_contents, current_row )
  local zeilenhoehe
  local rowspan,colspan
  local wd,parameter
  local rowspans = {}

  local fam = publisher.fonts.lookup_schriftfamilie_nummer_instanzen[self.schriftfamilie]
  local min_lineheight = fam.baselineskip

  if tr_contents.minheight then
    zeilenhoehe = math.max(publisher.current_grid.gridheight * tr_contents.minheight, min_lineheight)
  else
    zeilenhoehe = min_lineheight
  end

  current_column = 0

  for _,td in ipairs(tr_contents) do
    local td_contents = publisher.inhalt(td)
    current_column = current_column + 1


    local td_randlinks  = tex.sp(td_contents["border-left"]   or 0)
    local td_randrechts = tex.sp(td_contents["border-right"]  or 0)
    local td_randoben   = tex.sp(td_contents["border-top"]    or 0)
    local td_randunten  = tex.sp(td_contents["border-bottom"] or 0)

    local padding_left   = td_contents.padding_left   or self.padding_left
    local padding_right  = td_contents.padding_right  or self.padding_right
    local padding_top    = td_contents.padding_top    or self.padding_top
    local padding_bottom = td_contents.padding_bottom or self.padding_bottom

    rowspan = tonumber(td_contents.rowspan) or 1
    colspan = tonumber(td_contents.colspan) or 1

    wd = 0
    for s = current_column,current_column + colspan - 1 do
      wd = wd + self.colwidths[s]
    end
    current_column = current_column + colspan - 1

    -- FIXME: hier statt self.colsep die spaltenabstaende[i] berücksichtigen
    wd = wd + ( colspan - 1 ) * self.colsep
    -- hier unbedingt(!!) border-left und border-right beachten FIXME
    -- in der Höhenberechnung auch border-top und border-bottom! FIXME
    local zelle

    -- Die objects wurden in der Spaltenbreitenbestimmung
    -- hinzugefügt. Falls die Spaltenbreiten vogegeben wurden,
    -- dann wurde die Spaltenbreitenbestimmung ja gar nicht aufgerufen
    -- und die objects müssen hier hinzugefügt werden (not DRY!)
    if not td_contents.objects then
      local objects = {}

      for i,j in ipairs(td_contents) do
        if publisher.elementname(j,true) == "Paragraph" then
          objects[#objects + 1] = publisher.inhalt(j)
        elseif publisher.elementname(j,true) == "Image" then
          -- FIXME: Bild sollte auch ein "object" sein
          objects[#objects + 1] = publisher.inhalt(j)
        elseif publisher.elementname(j,true) == "Table" then
          -- FIXME: Bild sollte auch ein "object" sein
          objects[#objects + 1] = publisher.inhalt(j)[1]
        else
          warning("Object not recognized: %s",publisher.elementname(j,true) or "???")
        end
      end
      -- trace("Tabelle: objects für die Tabellenzelle eingelesen (calculate_rowheights)")
      td_contents.objects = objects
    end

    for _,object in ipairs(td_contents.objects) do
      if type(object)=="table" then
        if not (object and object.nodelist) then
          w("Achtung, keine Nodeliste gefunden!")
        end

        if object.nodelist then
          -- FIXME: dynamisches Textformat
          -- object:apply_textformat("text")
          parameter = nil
          if object.textformat then
            if not publisher.textformate[object.textformat] then
              err("Textformat %q not defined!",object.textformat)
            else
              if publisher.textformate[object.textformat]["alignment"] == "linksbündig" then
                parameter = { rightskip = publisher.rightskip }
              end
              if publisher.textformate[object.textformat]["alignment"] == "rechtsbündig" then
                parameter = { leftskip = publisher.leftskip }
              end
              if publisher.textformate[object.textformat]["alignment"] == "zentriert" then
                parameter = { leftskip = publisher.leftskip, rightskip = publisher.rightskip }
              end
            end
          else
            local align = td_contents.align or tr_contents.align or self.align[current_column]
            if align=="center" then
              parameter = { leftskip = publisher.leftskip, rightskip = publisher.rightskip }
            elseif align=="left" then
              parameter = { rightskip = publisher.rightskip }
            elseif align=="right" then
              parameter = { leftskip = publisher.leftskip }
            end
          end
          publisher.setze_fontfamilie_wenn_notwendig(object.nodelist,self.schriftfamilie)
          publisher.fonts.pre_linebreak(object.nodelist)
        end
        tmp = node.copy_list(object.nodelist)
        local align = td_contents.align or tr_contents.align or self.align[current_column]
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
      elseif (type(object)=="userdata" and node.has_field(object,"width")) then
        if zelle then
          node.tail(zelle).next = object
        else
          zelle = object
        end
      end
    end
    -- wenn keine objects in einer Zeile sind, dann erzeugen wir
    -- ein dummy-object, damit die Zeile erzeugt werden kann (und vpack nicht)
    -- über ein nil stolpert.
    if not zelle then
      zelle = node.new("hlist")
    end
    v=node.vpack(zelle)

    tmp = v.height + v.depth +  padding_top + padding_bottom + td_randunten + td_randoben
    if rowspan > 1 then
      rowspans[#rowspans + 1] =  { start = current_row, ende = current_row + rowspan - 1, ht = tmp }
      td_contents.rowspan_internal = rowspans[#rowspans]
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
function calculate_rowheights(self)
  trace("Tabelle: berechne Zeilenhöhen")
  local current_row = 0
  local rowspans = {}
  local _rowspans


  for _,tr in ipairs(self.tab) do
    local tr_contents = publisher.inhalt(tr)
    local eltname = publisher.elementname(tr,true)

    if eltname == "Tablerule" or eltname == "Columns" then
      -- ignorieren

    elseif eltname == "Tablehead" then
      for _,zeile in ipairs(tr_contents) do
        local zeile_inhalt  = publisher.inhalt(zeile)
        local zeile_eltname = publisher.elementname(zeile,true)
        if zeile_eltname == "Tr" then
          current_row = current_row + 1
          zeilenhoehe, _rowspans = self:calculate_zeilenhoehe(zeile_inhalt,current_row)
          self.rowheights[current_row] = zeilenhoehe
          rowspans = table.__concat(rowspans,_rowspans)
        end
      end
    elseif eltname == "Tablefoot" then
      for _,zeile in ipairs(tr_contents) do
        local zeile_inhalt  = publisher.inhalt(zeile)
        local zeile_eltname = publisher.elementname(zeile,true)
        if zeile_eltname == "Tr" then
          current_row = current_row + 1
          zeilenhoehe, _rowspans = self:calculate_zeilenhoehe(zeile_inhalt,current_row)
          self.rowheights[current_row] = zeilenhoehe
          rowspans = table.__concat(rowspans,_rowspans)
        end
      end

    elseif eltname == "Tr" then
      current_row = current_row + 1
      zeilenhoehe, _rowspans = self:calculate_zeilenhoehe(tr_contents,current_row)
      self.rowheights[current_row] = zeilenhoehe
      rowspans = table.__concat(rowspans,_rowspans)
    else
      warning("Unknown contents in »Tabelle« %s",eltname)
    end -- wenn es nicht eine <Tablerule> ist
  end -- für alle Zeilen

  -- Zeilenhöhen anpassen. Erst müssen alle möglichen Verschiebungen in den Zeilenhöhen
  -- berechnet werden, bevor den eigentlichen rowspans ihre Höhen bekommen (aufgrund der Zeilenhöhen)
  for i,rowspan in pairs(rowspans) do
    trace("Tabelle: Zeilenhöhen anpassen")
    local sum_ht = 0
    trace("Tabelle: rowspan.start = %d, rowspan.ende = %d. self.rowsep = %gpt",rowspan.start,rowspan.ende,self.rowsep)
    for j=rowspan.start,rowspan.ende do
      trace("Tabelle: füge %gpt hinzu (Zeile %d)",self.rowheights[j] / 2^16,j)
      sum_ht = sum_ht + self.rowheights[j]
    end
    sum_ht = sum_ht + self.rowsep * ( rowspan.ende - rowspan.start )
    trace("Tabelle: Rowspan (%d) > Zeilenhöhen %gpt > %gpt?",rowspan.ende - rowspan.start + 1 ,rowspan.ht / 2^16 ,sum_ht / 2^16)
    if rowspan.ht > sum_ht then
      local ueberschuss_je_zeile = (rowspan.ht - sum_ht) / (rowspan.ende - rowspan.start + 1)
      trace("Tabelle: Überschuss je Zeile = %gpt",ueberschuss_je_zeile / 2^16)
      for j=rowspan.start,rowspan.ende do
        self.rowheights[j] = self.rowheights[j] + ueberschuss_je_zeile
      end
    end
  end

  -- erst jetzt sind alle Zeilenhöhen berechnet. Dadurch können die rowspans angepasst werden.
  for i,rowspan in pairs(rowspans) do
    rowspan.sum_ht = table.sum(self.rowheights,rowspan.start, rowspan.ende) + self.rowsep * ( rowspan.ende - rowspan.start )
  end
end

function setze_zeile(self, tr_contents, current_row )
  local current_column
  local current_columnnbreite, ht
  local zeile = {}
  local rowspan, colspan
  local v,vlist,hlist
  local fill = { width = 0, stretch = 2^16, stretch_order = 3}

  current_column = 0
  for _,td in ipairs(tr_contents) do

    current_column = current_column + 1

    td_contents = publisher.inhalt(td)
    rowspan = tonumber(td_contents.rowspan) or 1
    colspan = tonumber(td_contents.colspan) or 1

    -- FIXME: bin ich sicher, das ich in der richtigen Spalte bin (colspan...)?
    local td_randlinks  = tex.sp(td_contents["border-left"]   or 0)
    local td_randrechts = tex.sp(td_contents["border-right"]  or 0)
    local td_randoben   = tex.sp(td_contents["border-top"]    or 0)
    local td_randunten  = tex.sp(td_contents["border-bottom"] or 0)

    local padding_left   = td_contents.padding_left   or self.padding_left
    local padding_right  = td_contents.padding_right  or self.padding_right
    local padding_top    = td_contents.padding_top    or self.padding_top
    local padding_bottom = td_contents.padding_bottom or self.padding_bottom


    -- Wenn ich auf einer Skip-Spalte bin (durch einen Rowspan), dann
    -- muss eine leere hbox erzeugt werden
    while self.skip[current_row] and self.skip[current_row][current_column] do
      v = publisher.erzeuge_leere_hbox_mit_breite(self.colwidths[current_column])
      v = publisher.add_glue(v,"head",fill) -- sonst gäb's ne underfull vbox
      zeile[current_column] = node.vpack(v,self.rowheights[current_row],"exactly")
      current_column = current_column + 1
    end

    -- rowspan? - nicht DRY: dasselbe wurde schon in calculate_spaltenbreite gemacht
    for z = current_row + 1, current_row + rowspan - 1 do
      for y = current_column, current_column + colspan - 1 do
        self.skip[z] = self.skip[z] or {}  self.skip[z][y] = true
      end
    end

    current_columnnbreite = 0
    for s = current_column,current_column + colspan - 1 do
       current_columnnbreite = current_columnnbreite + self.colwidths[s]
    end
    -- FIXME: hier statt self.colsep die spaltenabstaende[i] berücksichtigen
    current_columnnbreite = current_columnnbreite + ( colspan - 1 ) * self.colsep
    current_column = current_column + colspan - 1

    if rowspan > 1 then
      ht = td_contents.rowspan_internal.sum_ht
    else
      ht = self.rowheights[current_row]
    end
    -- FIXME: muss ich wirklich hier noch einmal alles setzen? Ich habe doch schon im
    -- vorherigen Anlauf (Zeilenhöhe bestimmen) alles in einen absatz gepackt!?!?

    local g = node.new("glue")
    g.spec = node.new("glue_spec")
    g.spec.width = padding_top

    local valign = td_contents.valign or tr_contents.valign or self.valign[current_column]
    if valign ~= "top" then
      g.spec.stretch = 2^16
      g.spec.stretch_order = 2
    end

    local zelle_start = g

    local zelle
    local current = node.tail(zelle_start)


    for _,object in ipairs(td_contents.objects) do
      if type(object) == "table" then
        if not (object and object.nodelist) then
          warning("No nodelist found!")
        end
        v = node.copy_list(object.nodelist)
      elseif type(object) == "userdata" then
        v = node.copy_list(object)
      end

      if type(object) == "table" then
        -- Absatz mit Nodeliste
        local parameter = nil
        if object.textformat then
          if not publisher.textformate[object.textformat] then
            err("Textformat %q not defined!",object.textformat)
          else
            if publisher.textformate[object.textformat]["alignment"] == "linksbündig" then
              parameter = { rightskip = publisher.rightskip }
            end
            if publisher.textformate[object.textformat]["alignment"] == "rechtsbündig" then
              parameter = { leftskip = publisher.leftskip }
            end
            if publisher.textformate[object.textformat]["alignment"] == "zentriert" then
              parameter = { leftskip = publisher.leftskip, rightskip = publisher.rightskip }
            end
          end
        else
          local align = td_contents.align or tr_contents.align or self.align[current_column]
          if align=="center" then
            parameter = { leftskip = publisher.leftskip, rightskip = publisher.rightskip }
          elseif align=="left" then
            parameter = { rightskip = publisher.rightskip }
          elseif align=="right" then
            parameter = { leftskip = publisher.leftskip }
          end
        end
        v = publisher.do_linebreak(v, current_columnnbreite - padding_left - padding_right - td_randlinks - td_randrechts, parameter)
        if publisher.options.trace then
          v = publisher.boxit(v)
        end
      elseif type(object) == "userdata" then
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

    local valign = td_contents.valign or tr_contents.valign or self.valign[current_column]
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


    local align = td_contents.align or tr_contents.align or self.align[current_column]
    if align ~= "left" then
      g.spec.stretch = 2^16
      g.spec.stretch_order = 2
    end

    zelle_start = g

    if td_contents["border-left"] then
      local start, stop = publisher.farbbalken(tex.sp(td_contents["border-left"]),-1073741824,-1073741824,td_contents["border-left-color"])
      stop.next = g
      zelle_start = start
    end

    current = node.tail(zelle_start)
    current.next = vlist
    current = vlist

    g = node.new("glue")
    g.spec = node.new("glue_spec")
    g.spec.width = padding_right

    local align = td_contents.align or tr_contents.align or self.align[current_column]
    if align ~= "right" then
      g.spec.stretch = 2^16
      g.spec.stretch_order = 2
    end

    current.next = g
    current = g

    if td_contents["border-right"] then
      local rule = publisher.farbbalken(tex.sp(td_contents["border-right"]),-1073741824,-1073741824,td_contents["border-right-color"])
      g.next = rule
    end

    hlist = node.hpack(zelle_start,current_columnnbreite,"exactly")

    -- So, jetzt ist die Zelle vollständig (bis auf die top/bottom rule). Hier kann jetzt die Hintergrundfarbe gesetzt werden.
    if tr_contents.backgroundcolor or td_contents.backgroundcolor or self.columncolors[current_column] then
      -- prio: Td.backgroundcolor, dann Tr.backgroundcolor, dann Spalte.backgroundcolor
      local farbe = self.columncolors[current_column]
      farbe = tr_contents.backgroundcolor or farbe
      farbe = td_contents.backgroundcolor or farbe
      hlist = publisher.hintergrund(hlist,farbe)
    end

    local head = hlist
    if td_contents["border-top"] then
      local rule = publisher.farbbalken(-1073741824,tex.sp(td_contents["border-top"]),0,td_contents["border-top-color"])
      -- rule besteht aus whatsit, rule, whatsit
      node.tail(rule).next = hlist
      head = rule
    end

    if td_contents["border-bottom"] then
      local rule = publisher.farbbalken(-1073741824,tex.sp(td_contents["border-bottom"]),0,td_contents["border-bottom-color"])
      hlist.next = rule
    end


    -- vlist.height = self.rowheights[current_row]
    -- hlist.height = self.rowheights[current_row]
    local gl = node.new("glue")
    gl.spec = node.new("glue_spec")
    gl.spec.width = 0
    gl.spec.shrink = 2^16
    gl.spec.shrink_order = 2
    node.slide(head).next = gl

    hlist = node.vpack(head,self.rowheights[current_row],"exactly")

    if publisher.options.trace then
      publisher.boxit(hlist)
    end

    zeile[#zeile + 1] = hlist

  end -- ende td

  if current_column == 0 then
    trace("Tabelle: keine Td-Zellen in dieser Spalte gefunden")
    v = publisher.erzeuge_leere_hbox_mit_breite(self.tablewidth_target)
    trace("Tabelle: leere hbox erzeugt")
    v = publisher.add_glue(v,"head",fill) -- sonst gäb's ne underfull vbox
    zeile[1] = node.vpack(v,self.rowheights[current_row],"exactly")
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
  local current_row
  local kopfzeilen = {}
  local fusszeilen = {}
  local zeilen = {}

  current_row = 0
  for _,tr in ipairs(self.tab) do
    local tr_contents = publisher.inhalt(tr)
    local eltname   = publisher.elementname(tr,true)
    local tmp

    if eltname == "Columns" then
      -- ignorieren
    elseif eltname == "Tablerule" then
      tmp = publisher.farbbalken(self.tablewidth_target,tex.sp(tr_contents.rulewidth or "0.25pt"),0,tr_contents.farbe)
      zeilen[#zeilen + 1] = node.hpack(tmp)

    elseif eltname == "Tablehead" then
      for _,zeile in ipairs(tr_contents) do
        zeile_inhalt = publisher.inhalt(zeile)
        zeile_eltname = publisher.elementname(zeile,true)
        if zeile_eltname == "Tr" then
          current_row = current_row + 1
          kopfzeilen[#kopfzeilen + 1] = self:setze_zeile(zeile_inhalt,current_row)
        elseif zeile_eltname == "Tablerule" then
          tmp = publisher.farbbalken(self.tablewidth_target,tex.sp(zeile_inhalt.rulewidth or "0.25pt"),0,zeile_inhalt.farbe)
          kopfzeilen[#kopfzeilen + 1] = node.hpack(tmp)
        end
      end

    elseif eltname == "Tablefoot" then
      for _,zeile in ipairs(tr_contents) do
        zeile_inhalt = publisher.inhalt(zeile)
        zeile_eltname = publisher.elementname(zeile,true)
        if zeile_eltname == "Tr" then
          current_row = current_row + 1
          fusszeilen[#fusszeilen + 1] = self:setze_zeile(zeile_inhalt,current_row)
        elseif zeile_eltname == "Tablerule" then
          tmp = publisher.farbbalken(self.tablewidth_target,tex.sp(zeile_inhalt.rulewidth or "0.25pt"),0,zeile_inhalt.farbe)
          fusszeilen[#fusszeilen + 1] = node.hpack(tmp)
        end
      end

    elseif eltname == "Tr" then
      current_row = current_row + 1
      zeilen[#zeilen + 1] = self:setze_zeile(tr_contents,current_row)
    else
      warning("Unknown contents in »Table« %s",eltname )
    end -- wenn es eine Tabellenzelle ist
  end

  local ht_kopfzeilen = 0
  for z = 1,#kopfzeilen - 1 do
    ht_kopfzeilen = ht_kopfzeilen + kopfzeilen[z].height  -- Tr oder Tablerule
    _,tmp = publisher.add_glue(kopfzeilen[z],"tail",{ width = self.rowsep })
    tmp.next = kopfzeilen[z+1]
    kopfzeilen[z+1].prev = tmp
  end
  -- publisher.add_glue(kopfzeilen[#kopfzeilen],"tail",{ width = self.rowsep })

  ht_kopfzeilen = ht_kopfzeilen + ( self.rowsep - 1 ) * #kopfzeilen


  local ht_fusszeilen = 0
  for z = 1,#fusszeilen - 1 do
    ht_fusszeilen = ht_fusszeilen + fusszeilen[z].height  -- Tr oder Tablerule
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
  calculate_spaltenbreite(self)
  calculate_rowheights(self)
  return setze_tabelle(self)
end

file_end("table.lua")
