--
--  raster.lua
--  speedata publisher
--
--  Copyright 2010-2011 Patrick Gundlach.
--  See file COPYING in the root directory for license details.

file_start("grid.lua")

module(...,package.seeall)

_M.__index = _M

local function to_sp(arg)
  tex.dimen[0] = arg
  return tex.dimen[0]
end

do
  local auto, assign

  function auto(tab, key)
    return setmetatable({}, {
            __index = auto,
            __newindex = assign,
            parent = tab,
            key = key
    })
  end

  local meta = {__index = auto}

  function assign(tab, key, val)
    local oldmt = getmetatable(tab)
    oldmt.parent[oldmt.key] = tab
    setmetatable(tab, meta)
    tab[key] = val
  end

  function AutomagicTable()
    return setmetatable({}, meta)
  end
end
-- http://lua-users.org/wiki/AutomagicTables


function new( self )
  assert(self)
  local r = {
    belegung_x=AutomagicTable(),
    seitengroesse_bekannt = false,
    belegung_pdf      = {}, -- wird vor der Seitenausgabe (output-Routine) abgefragt
    extra_rand        = 0,  -- für Beschnittmarken, in sp
    beschnittzugabe   = 0,  -- bleed, in sp
    platzierungsbereiche = { [publisher.default_areaname] = { { zeile = 1, spalte = 1} } },  -- Platzierungsrahmen
  }
	setmetatable(r, self)
	return r
end

function current_row( self,areaname )
  assert(self)
  local areaname = areaname or publisher.default_areaname
  bereich = self.platzierungsbereiche[areaname]
  assert(bereich,string.format("Area %q not known",tostring(areaname)))
  return bereich.current_row or 1
end

function aktuelle_spalte( self,bereich )
  assert(self)
  local bereich = bereich or publisher.default_areaname
  assert(self.platzierungsbereiche[bereich],string.format("Area %q not known",tostring(bereich)))
  return self.platzierungsbereiche[bereich].aktuelle_spalte or 1
end

function set_current_row( self,zeile,areaname )
  assert(self)
  local areaname = areaname or publisher.default_areaname
  local bereich = self.platzierungsbereiche[areaname]
  assert(bereich,string.format("Area %q not known",tostring(areaname)))
  bereich.current_row = zeile
end

function setze_aktuelle_spalte( self,spalte,areaname )
  assert(self)
  local areaname = areaname or publisher.default_areaname
  local bereich = self.platzierungsbereiche[areaname]
  assert(bereich,string.format("Area %q not known",tostring(areaname)))
  bereich.aktuelle_spalte = spalte
end

function anzahl_zeilen(self,areaname)
  assert(self)
  local areaname = areaname or publisher.default_areaname
  local aktueller_rahmen = self:rahmennummer(areaname)
  local bereich = self.platzierungsbereiche[areaname]
  assert(bereich,string.format("Area %q not known",tostring(areaname)))
  local hoehe = bereich[aktueller_rahmen].hoehe
  return hoehe
end

function anzahl_spalten(self,areaname)
  assert(self)
  local areaname = areaname or publisher.default_areaname
  local aktueller_rahmen = self:rahmennummer(areaname)
  local bereich = self.platzierungsbereiche[areaname]
  assert(bereich,string.format("Area %q not known",tostring(areaname)))
  local breite = bereich[aktueller_rahmen].breite
  return breite
end

function setze_anzahl_zeilen( self,zeilen )
  assert(self)
  local areaname = publisher.default_areaname
  local bereich = self.platzierungsbereiche[areaname]
  assert(bereich,string.format("Area %q not known",tostring(areaname)))
  local aktueller_rahmen = self:rahmennummer(areaname)
  bereich[aktueller_rahmen].hoehe = zeilen
end

function setze_anzahl_spalten(self,spalten)
  assert(self)
  local bereich = publisher.default_areaname
  assert(self.platzierungsbereiche[bereich],string.format("Area %q not known",tostring(bereich)))
  for i,v in ipairs(self.platzierungsbereiche[bereich]) do
    v.breite = spalten
  end
end

function anzahl_rahmen( self,areaname )
  local areaname = areaname or publisher.default_areaname
  local bereich = self.platzierungsbereiche[areaname]
  assert(bereich,string.format("Area %q not known",tostring(bereichame)))
  local anzahl_rahmen = #bereich
  return anzahl_rahmen
end

function rahmennummer( self,areaname )
  local areaname = areaname or publisher.default_areaname
  local bereich = self.platzierungsbereiche[areaname]
  assert(bereich,string.format("Area %q not known",tostring(bereichame)))
  local anzahl_rahmen = #bereich
  return bereich.aktueller_rahmen or 1
end

function setze_rahmennummer( self,areaname, nummer )
  local areaname = areaname or publisher.default_areaname
  local bereich = self.platzierungsbereiche[areaname]
  assert(bereich,string.format("Area %q not known",tostring(bereichame)))
  local anzahl_rahmen = #bereich
  bereich.aktueller_rahmen = nummer
end

-- Setzt die gridwidth und Rasterhöhe auf die Werte @b@ und @h@. 
function setze_breite_hoehe(self, b,h )
  assert(b)
  assert(h)
  self.gridwidth = b
  self.gridheight  = h
  berechne_anzahl_rasterzellen(self)
end

-- Markiert (intern) den rechteckigen Bereich durch `x`, `y` (linke obere Ecke)
-- und der Breite `b` und Höhe `h` als belegt.
function belege_zellen(self,x,y,b,h,allocate_matrix,zeichne_markierung_p,areaname)
  if not x then return false end
  -- printtable("grid/allocate_matrix",allocate_matrix)
  areaname = areaname or publisher.default_areaname
  self:setze_aktuelle_spalte(x + b,areaname)
  -- Todo: neuer Bereich, wenn der herunter rausragt
  self:set_current_row(y,areaname)
  local rasterkonflikt = false
  if  x + b - 1 > self:anzahl_spalten(areaname) then
    warning("Object protrudes into the right margin")
    rasterkonflikt = true
  end
  if y + h - 1 > self:anzahl_zeilen(areaname) then
    warning("Object protrudes below the last line of the page")
    rasterkonflikt = true
  end
  local rahmen_rand_links, rahmen_rand_oben
  if areaname == publisher.default_areaname then
    rahmen_rand_links, rahmen_rand_oben = 0,0
  else
    local bereich = self.platzierungsbereiche[areaname]
    assert(bereich,string.format("Area %q not known",tostring(areaname)))
    local current_row = self:current_row(areaname)
    local block = bereich[self:rahmennummer(areaname)]
    rahmen_rand_links = block.spalte - 1
    rahmen_rand_oben = block.zeile - 1
  end
  if allocate_matrix then
    -- special handling for the non rectangular shape
    local grid_step_x = math.floor(100 * b / allocate_matrix.max_x) / 100
    local grid_step_y = math.floor(100 * h / allocate_matrix.max_y) / 100
    w("mini-zelle x = %g, y = %g",grid_step_x,grid_step_y)
    local cur_x, cur_y

    for _y=1,allocate_matrix.max_y do
      cur_y = math.ceil(_y * grid_step_y)
      for _x=1,allocate_matrix.max_x do
        cur_x = math.ceil(_x * grid_step_x)
        if allocate_matrix[_y][_x] == 1 then
          self.belegung_x[cur_x + x - 1][cur_y  + y - 1] = true
        end
      end
    end
  else
    for _x = x + rahmen_rand_links,x + rahmen_rand_links + b - 1 do
      for _y = y + rahmen_rand_oben, y + rahmen_rand_oben + h - 1 do
        if self.belegung_x[_x][_y] == true then
          rasterkonflikt = true
        else
          self.belegung_x[_x][_y] = true
        end
      end
    end
  end
  if rasterkonflikt then
    err("Conflict in grid")
  end
end

-- Gibt den Wahrheitswert zurück, ob ein Objekt der Breite @breite@ in die Zeile @zeile@ ab der Spalte @spalte@ 
-- passt.
function passt_x_in_zeile(self,spalte,breite,zeile)
  if not spalte then return false end
  -- printtable("passt_x_in_zeile",{spalte=spalte,breite=breite,zeile=zeile})
  for x = spalte, spalte + breite - 1 do
    if self.belegung_x[x][zeile] == true then return false end
  end
  return true
end

-- Return the row in which the object of the width "breite" can be placed.
-- Starting column is @column@, If the page size is not know yet, the next free
-- row will be given. Is the page full (the object cannot be placed), the
-- function returns nil.
function finde_passende_zeile( self,column, breite,hoehe,areaname)
  if not column then return false end
  local rahmen_rand_links, rahmen_rand_oben
  if areaname == publisher.default_areaname then
    rahmen_rand_links, rahmen_rand_oben = 0,0
  else
    local bereich = self.platzierungsbereiche[areaname]
    assert(bereich,string.format("Area %q not known",tostring(areaname)))
    -- todo: den richtigen Block finden, da die Blöcke / Rahmen unterschiedlich breit/hoch sein können!
    local block = bereich[self:rahmennummer(areaname)]
    rahmen_rand_links = block.spalte - 1
    rahmen_rand_oben = block.zeile - 1
  end
  -- FIXME: überlegen, was hier sinnvoll ist!?! - noch ein ziemlich ineffizienter Algorithmus! sieht aus wie O(n^2)
  -- bei n Zeilen Höhe
  if self:anzahl_zeilen(areaname) < self:current_row(areaname) + hoehe - 1 then return nil end
  for z = self:current_row(areaname) + rahmen_rand_oben, self:anzahl_zeilen(areaname) do
    if self:passt_x_in_zeile(column + rahmen_rand_links,breite,z) then

      if self:anzahl_zeilen(areaname) < z - rahmen_rand_oben + hoehe then
        return nil
      else
        local passt = true
        for current_row = z, z + hoehe do
          if not self:passt_x_in_zeile(column + rahmen_rand_links,breite,current_row) then
            passt = false
          end
        end
        if passt then
          return z - rahmen_rand_oben
        end
      end
    end
  end
  if self.seitengroesse_bekannt == false then
    return self:anzahl_zeilen(areaname) + 1
  end
  return nil
end

-- Gibt die Anzahl der Rasterzellen zurück, die das Objekt belegt (x-Richtung).
function breite_in_rasterzellen_sp(self,breite_sp)
  assert(self)
  return math.ceil(breite_sp / self.gridwidth)
end

-- Gibt die Anzahl der Rasterzellen zurück, die das Objekt belegt (y-Richtung).
function hoehe_in_rasterzellen_sp(self,hoehe_sp)
  local ht =  hoehe_sp / self.gridheight
  -- Durch die Umwandlung von bp/sp gibt es Rundungsfehler. Die versuche ich hier
  -- zu vermeiden. Problem: wenn ich zwei Tabellenzeilen mit Höhe 9,5bp habe ist das
  -- um wenige sp größer als 4 Rasterzellen à 4,5bp.
  return math.ceil(math.round( ht,4))
end


-- Zeichnet das interne Raster (liefert PDF-Strings zurück)
function zeichne_raster(self)
  assert(self)
  local farbe
  local ret = {}
  ret[#ret + 1] = "q 0.2 w [2] 1 d "
  local papierhoehe  = sp_to_bp(tex.pageheight)
  local papierbreite = sp_to_bp(tex.pagewidth  - self.extra_rand)
  local x, y, breite, hoehe
  for i=0,self:anzahl_spalten() do
    x = sp_to_bp(i * self.gridwidth + self.rand_links + self.extra_rand)
    y = sp_to_bp ( self.extra_rand )
    -- alle 5 Rasterkästchen einen dunkleren Strich machen
    if (i % 5 == 0) then farbe = "0.6" else farbe = "0.8" end
    -- alle 10 Rasterkästchen einen schwarzen Strich machen
    if (i % 10 == 0) then farbe = "0.2" end
    ret[#ret + 1] = string.format("%g G %g %g m %g %g l S", farbe, math.round(x,1), math.round(y,1), math.round(x,1), math.round(papierhoehe - y,1))
  end
  for i=0,self:anzahl_zeilen() do
    -- alle 5 Rasterkästchen einen dunkleren Strich machen
    if (i % 5 == 0) then farbe = "0.6" else farbe = "0.8" end
    -- alle 10 Rasterkästchen einen schwarzen Strich machen
    if (i % 10 == 0) then farbe = "0.2" end
    y = sp_to_bp( i * self.gridheight  + self.rand_oben + self.extra_rand)
    x = sp_to_bp(self.extra_rand)
    ret[#ret + 1] = string.format("%g G %g %g m %g %g l S", farbe, math.round(x,2), math.round(papierhoehe - y,2), math.round(papierbreite,2), math.round(papierhoehe - y,2))
  end
  ret[#ret + 1] = "Q"
  for name,bereich in pairs(self.platzierungsbereiche) do
    for i,rahmen in ipairs(bereich) do
      x      = sp_to_bp(( rahmen.spalte - 1) * self.gridwidth + self.extra_rand + self.rand_links)
      y      = sp_to_bp( (rahmen.zeile - 1)  * self.gridheight  + self.extra_rand + self.rand_oben )
      breite = sp_to_bp(rahmen.breite * self.gridwidth)
      hoehe  = sp_to_bp(rahmen.hoehe  * self.gridheight )
      ret[#ret + 1] = string.format("q %s %g w %g %g %g %g re S Q", "1 0 0  RG",0.5, x,math.round(papierhoehe - y,2),breite,-hoehe)
    end
  end
  return table.concat(ret,"\n")
end

function draw_gridallocation(self)
  local pdf_literals = {}
  local paperheight  = sp_to_bp(tex.pageheight)
  -- where the yellow rectangle should be drawn
  local re_wd, re_ht, re_x, re_y
  re_ht = sp_to_bp(self.gridheight)
  for y=1,self:anzahl_zeilen() do
    local alloc_found = nil
    for x=1,self:anzahl_spalten() do
      if self.belegung_x[x][y] == true  then
        alloc_found = alloc_found or x
      else
        if alloc_found then
          local last_cell = x - 1
          for i=alloc_found,last_cell do
            -- OK, let's draw a rectangle. Height is 1 grid cell, width is x - alloc_found + 1
            re_wd = sp_to_bp( (last_cell - alloc_found + 1) * self.gridwidth  )
            re_x = sp_to_bp (self.rand_links) +  (alloc_found - 1) * sp_to_bp(self.gridwidth)
            re_y = paperheight - sp_to_bp(self.rand_oben) - y * sp_to_bp(self.gridheight)
          end
          pdf_literals[#pdf_literals + 1]  = string.format("q 0 0 1 0 k 0 0 1 0 K 1 0 0 1 %g %g cm 0 0 %g %g re f Q ",re_x, re_y, re_wd,re_ht)
          alloc_found = false
        else
        end
      end
    end
    alloc_found=nil
  end
  return table.concat(pdf_literals,"\n")
end

-- Gibt die Position der Rasterzelle in sp vom linken und oberen Rand.
function position_rasterzelle_mass_tex(self,x,y,areaname,wd,ht,valign)
  local x_sp, y_sp
  if not self.rand_links then return nil, "Linker Rand nicht definiert. Fehlt das <Rand> Tag in Seitenformat?" end
  local rahmen_rand_links, rahmen_rand_oben

  if areaname == publisher.default_areaname then
    rahmen_rand_links, rahmen_rand_oben = 0,0
  else
    local bereich = self.platzierungsbereiche[areaname]
    assert(bereich,string.format("Area %q not known",tostring(areaname)))
    local aktueller_rahmen = bereich.aktueller_rahmen or 1
    local current_row = self:current_row(areaname)
    -- todo: den richtigen Block finden, da die Blöcke / Rahmen unterschiedlich breit/hoch sein können!
    local block = bereich[aktueller_rahmen]
    rahmen_rand_links = block.spalte - 1
    rahmen_rand_oben = block.zeile - 1
  end
  x_sp = (rahmen_rand_links + x - 1) * self.gridwidth + self.rand_links + self.extra_rand
  y_sp = (rahmen_rand_oben  + y - 1) * self.gridheight  + self.rand_oben  + self.extra_rand
  if valign then
    -- height mod cellheight = "overshoot"
    local overshoot = ht % self.gridheight
    if valign == "bottom" then
      -- cellheight - "overshoot" = shift_down
      y_sp = y_sp + self.gridheight - overshoot
    elseif valign == "middle" then
      -- ( cellheight - "overshoot") / 2 = shift_down
      y_sp = y_sp + ( self.gridheight - overshoot ) / 2
    end
  end
  return x_sp,y_sp
end


-- Nachfolgende Funktionen benötigen eine feste Breite der Seite

-- Erwartet die Angaben in sp (''scaled points'') oder in Maßangaben.
function setze_rand(self,l,o,r,u)
  assert(u,"Four arguments must be given.")
  self.rand_links  = to_sp(l)
  self.rand_rechts = to_sp(r)
  self.rand_oben   = to_sp(o)
  self.rand_unten  = to_sp(u)
end

function berechne_anzahl_rasterzellen(self)
  assert(self)
  assert(self.rand_links,  "Rand noch nicht gesetzt!")
  assert(self.gridwidth,"gridwidth noch nicht gesetzt!")
  self.seitengroesse_bekannt = true
  self:setze_anzahl_spalten(math.ceil(math.round( (tex.pagewidth  - self.rand_links - self.rand_rechts - 2 * self.extra_rand) / self.gridwidth,4)))
  self:setze_anzahl_zeilen(math.ceil(math.round( (tex.pageheight - self.rand_oben  - self.rand_unten  - 2 * self.extra_rand) /  self.gridheight ,4)))
  log("Number of rows: %d, number of columns = %d",self:anzahl_zeilen(), self:anzahl_spalten())
end

function trimbox( self )
  assert(self)
  local x,y,wd,ht =  sp_to_bp(self.extra_rand), sp_to_bp(self.extra_rand) , sp_to_bp(tex.pagewidth - self.extra_rand), sp_to_bp(tex.pageheight - self.extra_rand)
  local b_x,b_y,b_wd,b_ht = sp_to_bp(self.extra_rand - self.beschnittzugabe), sp_to_bp(self.extra_rand - self.beschnittzugabe) , sp_to_bp(tex.pagewidth - self.extra_rand + self.beschnittzugabe), sp_to_bp(tex.pageheight - self.extra_rand + self.beschnittzugabe)
  -- log("Trimbox = %g %g %g %g, bleedbox =  %g %g %g %g", x,y,wd,ht,b_x,b_y,b_wd,b_ht)
  pdf.pageattributes = string.format("/TrimBox [ %g %g %g %g] /BleedBox [%g %g %g %g]",x,y,wd,ht,b_x,b_y,b_wd,b_ht)
end

function beschnittmarken( self, laenge, abstand, dicke )
  local x,y,wd,ht =  sp_to_bp(self.extra_rand), sp_to_bp(self.extra_rand) , sp_to_bp(tex.pagewidth - self.extra_rand), sp_to_bp(tex.pageheight - self.extra_rand)
  local ret = {}
  local abstand_bp, laenge_bp, dicke_bp
  if not abstand then
    abstand_bp = sp_to_bp(self.beschnittzugabe)
  else
    abstand_bp = sp_to_bp(abstand)
  end
  if abstand_bp < 5 then abstand_bp = 5 end
  if not laenge then
    laenge_bp = 20
  else
    laenge_bp = sp_to_bp(laenge)
  end
  if not dicke then
    dicke_bp = 0.5
  else
    dicke_bp = sp_to_bp(dicke)
  end

  -- unten links
  ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",dicke_bp, x, y - abstand_bp, x, y - laenge_bp - abstand_bp)  -- v
  ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",dicke_bp, x - abstand_bp, y, x - laenge_bp - abstand_bp, y)  -- h
  -- unten rechts
  ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",dicke_bp, wd, y - abstand_bp, wd, y - laenge_bp - abstand_bp)
  ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",dicke_bp, wd + abstand_bp, y, wd + abstand_bp + laenge_bp, y)
  -- oben rechts
  ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",dicke_bp, wd, ht + abstand_bp, wd, ht + abstand_bp + laenge_bp)
  ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",dicke_bp, wd + abstand_bp, ht, wd + abstand_bp + laenge_bp, ht)
  -- oben links
  ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",dicke_bp, x, ht + abstand_bp, x, ht + abstand_bp + laenge_bp)
  ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",dicke_bp, x - abstand_bp, ht, x - laenge_bp - abstand_bp, ht)


  return table.concat(ret,"\n")
end

file_end("grid.lua")
