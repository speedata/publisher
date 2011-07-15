--
--  src/lua/publisher/raster.lua
--  speedata publisher
--
--  Created by Patrick Gundlach on 2010-03-26.
--  Copyright 2010-2011 Patrick Gundlach. All rights reserved.
--
--  See file COPYING in the root directory for license details.

file_start("raster.lua")

local helper = require("publisher.helper")

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
    platzierungsbereiche = { [publisher.default_bereichname] = { { zeile = 1, spalte = 1} } },  -- Platzierungsrahmen
  }
	setmetatable(r, self)
	return r
end

function aktuelle_zeile( self,bereichname )
  assert(self)
  local bereichname = bereichname or publisher.default_bereichname
  bereich = self.platzierungsbereiche[bereichname]
  assert(bereich,string.format("Area %q not known",tostring(bereichname)))
  return bereich.aktuelle_zeile or 1
end

function aktuelle_spalte( self,bereich )
  assert(self)
  local bereich = bereich or publisher.default_bereichname
  assert(self.platzierungsbereiche[bereich],string.format("Area %q not known",tostring(bereich)))
  return self.platzierungsbereiche[bereich].aktuelle_spalte or 1
end

function setze_aktuelle_zeile( self,zeile,bereichname )
  assert(self)
  local bereichname = bereichname or publisher.default_bereichname
  local bereich = self.platzierungsbereiche[bereichname]
  assert(bereich,string.format("Area %q not known",tostring(bereichname)))
  bereich.aktuelle_zeile = zeile
end

function setze_aktuelle_spalte( self,spalte,bereichname )
  assert(self)
  local bereichname = bereichname or publisher.default_bereichname
  local bereich = self.platzierungsbereiche[bereichname]
  assert(bereich,string.format("Area %q not known",tostring(bereichname)))
  bereich.aktuelle_spalte = spalte
end

function anzahl_zeilen(self,bereichname)
  assert(self)
  local bereichname = bereichname or publisher.default_bereichname
  local aktueller_rahmen = self:rahmennummer(bereichname)
  local bereich = self.platzierungsbereiche[bereichname]
  assert(bereich,string.format("Area %q not known",tostring(bereichname)))
  local hoehe = bereich[aktueller_rahmen].hoehe
  return hoehe
end

function anzahl_spalten(self,bereichname)
  assert(self)
  local bereichname = bereichname or publisher.default_bereichname
  local aktueller_rahmen = self:rahmennummer(bereichname)
  local bereich = self.platzierungsbereiche[bereichname]
  assert(bereich,string.format("Area %q not known",tostring(bereichname)))
  local breite = bereich[aktueller_rahmen].breite
  return breite
end

function setze_anzahl_zeilen( self,zeilen )
  assert(self)
  local bereichname = publisher.default_bereichname
  local bereich = self.platzierungsbereiche[bereichname]
  assert(bereich,string.format("Area %q not known",tostring(bereichname)))
  local aktueller_rahmen = self:rahmennummer(bereichname)
  bereich[aktueller_rahmen].hoehe = zeilen
end

function setze_anzahl_spalten(self,spalten)
  assert(self)
  local bereich = publisher.default_bereichname
  assert(self.platzierungsbereiche[bereich],string.format("Area %q not known",tostring(bereich)))
  for i,v in ipairs(self.platzierungsbereiche[bereich]) do
    v.breite = spalten
  end
end

function anzahl_rahmen( self,bereichname )
  local bereichname = bereichname or publisher.default_bereichname
  local bereich = self.platzierungsbereiche[bereichname]
  assert(bereich,string.format("Area %q not known",tostring(bereichame)))
  local anzahl_rahmen = #bereich
  return anzahl_rahmen
end

function rahmennummer( self,bereichname )
  local bereichname = bereichname or publisher.default_bereichname
  local bereich = self.platzierungsbereiche[bereichname]
  assert(bereich,string.format("Area %q not known",tostring(bereichame)))
  local anzahl_rahmen = #bereich
  return bereich.aktueller_rahmen or 1
end

function setze_rahmennummer( self,bereichname, nummer )
  local bereichname = bereichname or publisher.default_bereichname
  local bereich = self.platzierungsbereiche[bereichname]
  assert(bereich,string.format("Area %q not known",tostring(bereichame)))
  local anzahl_rahmen = #bereich
  bereich.aktueller_rahmen = nummer
end

-- Setzt die Rasterbreite und Rasterhöhe auf die Werte @b@ und @h@. 
function setze_breite_hoehe(self, b,h )
  assert(b)
  assert(h)
  self.rasterbreite = b
  self.rasterhoehe  = h
  berechne_anzahl_rasterzellen(self)
end

-- Markiert (intern) den rechteckigen Bereich durch `x`, `y` (linke obere Ecke)
-- und der Breite `b` und Höhe `h` als belegt. 
function belege_zellen(self,x,y,b,h,zeichne_markierung_p,bereichname)
  if not x then return false end
  bereichname = bereichname or publisher.default_bereichname
  self:setze_aktuelle_spalte(x + b,bereichname)
  -- Todo: neuer Bereich, wenn der herunter rausragt
  self:setze_aktuelle_zeile(y,bereichname)
  local rasterkonflikt = false
  if  x + b - 1 > self:anzahl_spalten(bereichname) then
    warning("Object protrudes into the right margin")
    rasterkonflikt = true
  end
  if y + h - 1 > self:anzahl_zeilen(bereichname) then
    warning("Object protrudes below the last line of the page")
    rasterkonflikt = true
  end
  local rahmen_rand_links, rahmen_rand_oben
  if bereichname == publisher.default_bereichname then
    rahmen_rand_links, rahmen_rand_oben = 0,0
  else
    local bereich = self.platzierungsbereiche[bereichname]
    assert(bereich,string.format("Area %q not known",tostring(bereichname)))
    local aktuelle_zeile = self:aktuelle_zeile(bereichname)
    local block = bereich[self:rahmennummer(bereichname)]
    rahmen_rand_links = block.spalte - 1
    rahmen_rand_oben = block.zeile - 1
  end
  for _x = x + rahmen_rand_links,x + rahmen_rand_links + b - 1 do
    for _y = y + rahmen_rand_oben, y + rahmen_rand_oben + h - 1 do
      if self.belegung_x[_x][_y] == true then
        rasterkonflikt = true
      else
        self.belegung_x[_x][_y] = true
      end
    end
  end
  if rasterkonflikt then
    err("Conflict in grid")
  end
  if zeichne_markierung_p then
    local px,py
    -- in bp:
    px = helper.sp_to_bp((x + rahmen_rand_links - 1) * self.rasterbreite + self.rand_links + self.extra_rand )
    py = helper.sp_to_bp(tex.pageheight - (y + rahmen_rand_oben - 1) * self.rasterhoehe - self.rand_oben - self.extra_rand)
    local breite, hoehe = helper.sp_to_bp(self.rasterbreite * b), helper.sp_to_bp(self.rasterhoehe * h)
    self.belegung_pdf[#self.belegung_pdf + 1] = string.format(" q 0 0 1 0 k 0 0 1 0 K  1 0 0 1 %g %g cm 0 0 %g %g re f Q ",px ,py - hoehe,breite,hoehe)
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

-- Gibt die Zeile zurück, in die das Objekt der Breite @breite@ hinein passt.
-- Anfangsspalte ist @spalte@. Wenn die Seitengröße noch nicht gesetzt wurde
-- (z.B. durch @setze_rand()@), dann wird die nächste freie Zeile ausgegeben.
-- Ist die Seite voll, dann ist der Rückgabewert nil.
function finde_passende_zeile( self,spalte,breite,hoehe,bereichname)
  if not spalte then return false end
  local rahmen_rand_links, rahmen_rand_oben
  if bereichname == publisher.default_bereichname then
    rahmen_rand_links, rahmen_rand_oben = 0,0
  else
    local bereich = self.platzierungsbereiche[bereichname]
    assert(bereich,string.format("Area %q not known",tostring(bereichname)))
    -- todo: den richtigen Block finden, da die Blöcke / Rahmen unterschiedlich breit/hoch sein können!
    local block = bereich[self:rahmennummer(bereichname)]
    rahmen_rand_links = block.spalte - 1
    rahmen_rand_oben = block.zeile - 1
  end

  -- FIXME: überlegen, was hier sinnvoll ist!?! - noch ein ziemlich ineffizienter Algorithmus! sieht aus wie O(n^2)
  -- bei n Zeilen Höhe
  if self:anzahl_zeilen(bereichname) < self:aktuelle_zeile(bereichname) + hoehe - 1 then return nil end
  for z = self:aktuelle_zeile(bereichname) + rahmen_rand_oben, self:anzahl_zeilen(bereichname) do
    if self:passt_x_in_zeile(spalte + rahmen_rand_links,breite,z) then

      if self:anzahl_zeilen(bereichname) < z - rahmen_rand_oben + hoehe then
        return nil
      else
        local passt = true
        for aktuelle_zeile = z, z + hoehe do
          if not self:passt_x_in_zeile(spalte + rahmen_rand_links,breite,aktuelle_zeile) then
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
    return self:anzahl_zeilen(bereichname) + 1
  end
  return nil
end

-- Gibt die Anzahl der Rasterzellen zurück, die das Objekt belegt (x-Richtung).
function breite_in_rasterzellen_sp(self,breite_sp)
  assert(self)
  return math.ceil(breite_sp / self.rasterbreite)
end

-- Gibt die Anzahl der Rasterzellen zurück, die das Objekt belegt (y-Richtung).
function hoehe_in_rasterzellen_sp(self,hoehe_sp)
  local ht =  hoehe_sp / self.rasterhoehe
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
  local papierhoehe  = helper.sp_to_bp(tex.pageheight)
  local papierbreite = helper.sp_to_bp(tex.pagewidth  - self.extra_rand)
  local x, y, breite, hoehe
  for i=0,self:anzahl_spalten() do
    x = helper.sp_to_bp(i * self.rasterbreite + self.rand_links + self.extra_rand)
    y = helper.sp_to_bp ( self.extra_rand )
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
    y = helper.sp_to_bp( i * self.rasterhoehe  + self.rand_oben + self.extra_rand)
    x = helper.sp_to_bp(self.extra_rand)
    ret[#ret + 1] = string.format("%g G %g %g m %g %g l S", farbe, math.round(x,2), math.round(papierhoehe - y,2), math.round(papierbreite,2), math.round(papierhoehe - y,2))
  end
  ret[#ret + 1] = "Q"
  for name,bereich in pairs(self.platzierungsbereiche) do
    for i,rahmen in ipairs(bereich) do
      x      = helper.sp_to_bp(( rahmen.spalte - 1) * self.rasterbreite + self.extra_rand + self.rand_links)
      y      = helper.sp_to_bp( (rahmen.zeile - 1)  * self.rasterhoehe  + self.extra_rand + self.rand_oben )
      breite = helper.sp_to_bp(rahmen.breite * self.rasterbreite)
      hoehe  = helper.sp_to_bp(rahmen.hoehe  * self.rasterhoehe )
      ret[#ret + 1] = string.format("q %s %g w %g %g %g %g re S Q", "1 0 0  RG",0.5, x,math.round(papierhoehe - y,2),breite,-hoehe)
    end
  end
  return table.concat(ret,"\n")
end

-- Gibt die Position der Rasterzelle in sp vom linken und oberen Rand.
function position_rasterzelle_mass_tex(self,x,y,bereichname)
  local x_sp, y_sp
  if not self.rand_links then return nil, "Linker Rand nicht definiert. Fehlt das <Rand> Tag in Seitenformat?" end
  local rahmen_rand_links, rahmen_rand_oben
  if bereichname == publisher.default_bereichname then
    rahmen_rand_links, rahmen_rand_oben = 0,0
  else
    local bereich = self.platzierungsbereiche[bereichname]
    assert(bereich,string.format("Area %q not known",tostring(bereichname)))
    local aktueller_rahmen = bereich.aktueller_rahmen or 1
    local aktuelle_zeile = self:aktuelle_zeile(bereichname)
    -- todo: den richtigen Block finden, da die Blöcke / Rahmen unterschiedlich breit/hoch sein können!
    local block = bereich[aktueller_rahmen]
    rahmen_rand_links = block.spalte - 1
    rahmen_rand_oben = block.zeile - 1
  end
  x_sp = (rahmen_rand_links + x - 1) * self.rasterbreite + self.rand_links + self.extra_rand
  y_sp = (rahmen_rand_oben  + y - 1) * self.rasterhoehe  + self.rand_oben  + self.extra_rand
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
  assert(self.rasterbreite,"Rasterbreite noch nicht gesetzt!")
  self.seitengroesse_bekannt = true
  self:setze_anzahl_spalten(math.ceil(math.round( (tex.pagewidth  - self.rand_links - self.rand_rechts - 2 * self.extra_rand) / self.rasterbreite,4)))
  self:setze_anzahl_zeilen(math.ceil(math.round( (tex.pageheight - self.rand_oben  - self.rand_unten  - 2 * self.extra_rand) /  self.rasterhoehe ,4)))
  log("Number of rows: %d, number of columns = %d",self:anzahl_zeilen(), self:anzahl_spalten())
end

function trimbox( self )
  assert(self)
  local x,y,wd,ht =  helper.sp_to_bp(self.extra_rand), helper.sp_to_bp(self.extra_rand) , helper.sp_to_bp(tex.pagewidth - self.extra_rand), helper.sp_to_bp(tex.pageheight - self.extra_rand)
  local b_x,b_y,b_wd,b_ht = helper.sp_to_bp(self.extra_rand - self.beschnittzugabe), helper.sp_to_bp(self.extra_rand - self.beschnittzugabe) , helper.sp_to_bp(tex.pagewidth - self.extra_rand + self.beschnittzugabe), helper.sp_to_bp(tex.pageheight - self.extra_rand + self.beschnittzugabe)
  -- log("Trimbox = %g %g %g %g, bleedbox =  %g %g %g %g", x,y,wd,ht,b_x,b_y,b_wd,b_ht)
  pdf.pageattributes = string.format("/TrimBox [ %g %g %g %g] /BleedBox [%g %g %g %g]",x,y,wd,ht,b_x,b_y,b_wd,b_ht)
end

function beschnittmarken( self, laenge, abstand, dicke )
  local x,y,wd,ht =  helper.sp_to_bp(self.extra_rand), helper.sp_to_bp(self.extra_rand) , helper.sp_to_bp(tex.pagewidth - self.extra_rand), helper.sp_to_bp(tex.pageheight - self.extra_rand)
  local ret = {}
  local abstand_bp, laenge_bp, dicke_bp
  if not abstand then
    abstand_bp = helper.sp_to_bp(self.beschnittzugabe)
  else
    abstand_bp = helper.sp_to_bp(abstand)
  end
  if abstand_bp < 5 then abstand_bp = 5 end
  if not laenge then
    laenge_bp = 20
  else
    laenge_bp = helper.sp_to_bp(laenge)
  end
  if not dicke then
    dicke_bp = 0.5
  else
    dicke_bp = helper.sp_to_bp(dicke)
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

file_end("raster.lua")
