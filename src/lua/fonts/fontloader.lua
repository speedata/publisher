trace = trace or 3

module(...,package.seeall)


-- Gibt `truetype`, `opentype` oder `type1` zurück, je nach `dateiname`. Wenn der Typ nicht
-- erkannt wurde, wird ''nil'' zurückgegeben.
function guess_fonttype( dateiname )
  local f=dateiname:lower()
  if f:match(".*%.ttf") then return "truetype"
  elseif f:match(".*%.otf") then return "opentype"
  elseif f:match(".*%.pfb") then return "type1"
  else return nil
  end
end

-- Gibt `true` zurück, wenn diese Featuretabelle (Untertabelle scripts) 
-- einen passenden Eintrag für `script` und `lang` hat.
-- Beispielaufruf: 
-- <pre>
-- if features_scripts_matches(gsub[i].features.script,"latn","dflt") then...
-- end
-- </pre>
function features_scripts_matches( tab,script,lang )
  local lang   = string.lower(lang)
  local script = string.lower(script)
    for i=1,#tab do
      local entry = tab[i]
      if string.lower(entry.script)==script then
        for j=1,#entry.langs do
          if string.lower(entry.langs[j])==lang then
            return true
          end
        end
      end
    end
  return false
end


function to_utf16(codepoint)
  assert(codepoint)
  if codepoint < 65536 then
    return string.format("%04X",codepoint)
  else
    return string.format("%04X%04X",codepoint / 1024 + 0xD800 ,codepoint % 1024 + 0xDC00)
  end
end

-- Gibt den String zurück, der für das OT-Feature `featurename` zuständig ist.
function finde_feature_string(f,featurename)
  local ret = {}
  if f.gsub==nil then
    return ret
  end
  for i=1,#f.gsub do
    local gsub_tabelle=f.gsub[i]
    if gsub_tabelle.features then
      for j = 1,#gsub_tabelle.features do
        local gtf = gsub_tabelle.features[j]
        if gtf.tag==featurename and features_scripts_matches(gtf.scripts,"latn","dflt") then
          if #gsub_tabelle.subtables ~= 1 then
            w("Achtung: #subtalbes in gpos != 1")
          end
          ret[#ret + 1] = gsub_tabelle.subtables[1].name
        end
      end
    end
  end
  return ret
end


-- Hier werden die Fontstrukturen aus dem fontloader gespeichert, damit sie später bei demselben Font
-- (in einer anderen Größe) nicht erneut von Festplatte geladen werden müssen (und auch die Unicode
-- Mappings müssen nicht erneut erstellt werden).
local lookup_dateiname_ttffont = {}

-- `name` ist der Dateiname, `size` ist eine Zahl in sp, `...` sind OpenType Features
-- Rückkabe sind zwei Werte. Wenn der erste Wert `false` ist, dann ist im zweiten Wert
-- eine Fehlermeldung, wenn der erste Wert `true` ist, dann ist im zweiten Wert eine
-- TeX-Tabelle mit dem Font.
function define_font(name, size,extra_parameter)
  local extra_parameter = extra_parameter or {}
  local ttffont

  if lookup_dateiname_ttffont[name] then
    ttffont=lookup_dateiname_ttffont[name]
    assert(ttffont)
  else
    -- diese werden in ttffonts gespeichert
    local dateiname_mit_pfad
    local lookup_codepoint_by_name   = {}
    local lookup_codepoint_by_number = {}

    dateiname_mit_pfad = kpse.find_file(name)
    if not dateiname_mit_pfad then return false, string.format("Fontdatei '%s' nicht gefunden.",dateiname_mit_pfad or name) end

    ttffont = fontloader.to_table(fontloader.open(dateiname_mit_pfad))
    if ttffont == nil then return false, string.format("Problem beim Laden des Fonts '%s'",tostring(dateiname_mit_pfad))  end

    lookup_dateiname_ttffont[name]=ttffont

    ttffont.dateiname_mit_pfad = dateiname_mit_pfad
    local is_unicode = (ttffont.pfminfo.unicoderanges ~= nil)
    
    -- Es wird ein Mapping Zeichennummer -> codepoint benötigt, damit wir beim Durchgehen der 
    -- Zeichen die direkt an die richtige Stelle (codepoint) geben können. 
    -- Das Problem ist, dass TTF/OTF und Type1 unterschiedlich behandelt werden müssen.
    -- TTF/OTF haben ein Unicode Mapping, das mit map.backmap (key: glyph, value: Codepoint)
    -- durchgegangen werden kann. Type1 benötigt die Information aus glyph.unicode.
    
    -- Ebenso wird fürs Kerning ein Mapping Zeichenname -> codepoint benötigt.
    if is_unicode then
      -- TTF/OTF, benutze map.backmap
      for i = 1,#ttffont.glyphs do
        local g=ttffont.glyphs[i]
        -- w("Name: %s, codepoint=%d, glyph#=%d",g.name,ttffont.map.backmap[i],i)
        lookup_codepoint_by_name[g.name] = ttffont.map.backmap[i]
        lookup_codepoint_by_number[i]    = ttffont.map.backmap[i]
      end
    else
      -- Type1, benutze glyph.unicode
      for i = 1,#ttffont.glyphs do
        local g=ttffont.glyphs[i]
        -- w("Name: %s, codepoint=%d, glyph#=%d",g.name,g.unicode,i)
        lookup_codepoint_by_name[g.name] = g.unicode
        lookup_codepoint_by_number[i]    = g.unicode
      end
    end -- is unicode
    ttffont.lookup_codepoint_by_name   = lookup_codepoint_by_name
    ttffont.lookup_codepoint_by_number = lookup_codepoint_by_number
  end -- initialisiere ttffont Struktur

  if (size < 0) then size = (- 655.36) * size end
  if ttffont.units_per_em == 0 then ttffont.units_per_em = 1000 end  -- manche type1 fonts haben u_p_em=0
  local mag = size / ttffont.units_per_em                  -- magnification


  local f = { }                                            -- Fontstruktur für TeX (Kap. 7 LuaTeX)
  f.characters    = { }                                    -- alle Zeichen für TeX, Index ist der Unicode Codepoint
  f.fontloader    = ttffont
  if extra_parameter and extra_parameter.otfeatures and extra_parameter.otfeatures.smcp then
    f.smcp = finde_feature_string(ttffont,"smcp")
  end
  f.otfeatures    = extra_parameter.otfeatures             -- OpenType Features (smcp,...)
  f.name          = ttffont.fontname
  f.fullname      = ttffont.fontname
  f.designsize    = size
  f.size          = size
  f.direction     = 0
  f.filename      = ttffont.dateiname_mit_pfad
  f.type          = 'real'
  f.encodingbytes = 2
  f.tounicode     = 1
  f.stretch       = 40
  f.shrink        = 30
  f.step          = 10
  f.auto_expand   = true

  f.parameters    = {
    slant         = 0,
    space         = ( extra_parameter.leerraum or 25 ) / 100  * size,
    space_stretch = 0.3  * size,
    space_shrink  = 0.1  * size,
    x_height      = 0.4  * size,
    quad          = 1.0  * size,
    extra_space   = 0
  }

  f.format = guess_fonttype(name)
  if f.format==nil then return false,"Konnte Fontformat der Datei '".. ttffont.dateiname_mit_pfad .."' nicht bestimmen." end

  f.embedding = "subset"
  f.cidinfo = ttffont.cidinfo


  for i=1,#ttffont.glyphs do
    local glyph     = ttffont.glyphs[i]
    local codepoint = ttffont.lookup_codepoint_by_number[i]
    -- w("Aktueller glyph=%s,codepoint=%d, Breite=%d",glyph.name,codepoint or -1,glyph.width or -1 )

    -- TeX benutzt U+002D HYPHEN-MINUS als Trennstrich, korrekt wäre U+2010 HYPHEN. Da
    -- aber die Fonthersteller alles Taugenichtse sind, mappen wir alle HYPHEN auf 0x2D (dez. 45)
    if glyph.name:lower():match("^hyphen$") then codepoint=45  end

    f.characters[codepoint] = {
        index = i,
        width = glyph.width * mag,
        name  = glyph.name,
        expansion_factor = 1000,
      }

    -- Höhe und Tiefe des Zeichens
    if glyph.boundingbox[4] then f.characters[codepoint].height = glyph.boundingbox[4] * mag  end
    if glyph.boundingbox[2] then f.characters[codepoint].depth = -glyph.boundingbox[2] * mag  end

    -- tounicode setzen. Damit bei Kapitälchen etc. auch copy und paste funktioniert.
    if glyph.name:match("%.") then
      -- Bsp: Kapitälchen a hat a.sc oder a.c2sc als Name. Wir interessieren uns nur für den Teil vor dem Punkt.
      -- ziemlich billig, sollte mal sorgfältiger mit Tabelle gemacht werden
      local destname = glyph.name:gsub("^([^%.]*)%..*$","%1")
      local cp = ttffont.lookup_codepoint_by_name[destname]
      if cp then
        f.characters[codepoint].tounicode=to_utf16(cp)
      end
    end


    -- optischer Randausgleich
    -- \pdfprotrudechars=2
    if (glyph.name=="hyphen" or glyph.name=="period" or glyph.name=="comma") and extra_parameter and type(extra_parameter.randausgleich) == "number" then
      f.characters[codepoint]["right_protruding"] = glyph.width * extra_parameter.randausgleich / 100
    end
    -- Kerning machen wir erstmal grundsätzlich. Wer will das schon abschalten? Das wäre was für später
    local kerns={}
    if glyph.kerns then
      for _,kern in pairs(glyph.kerns) do
        local ziel = ttffont.lookup_codepoint_by_name[kern.char]
        if ziel and ziel > 0 then
          kerns[ziel] = kern.off * mag
        else
        end
      end
    end
    f.characters[codepoint].kerns = kerns
  end

  return true,f
end

