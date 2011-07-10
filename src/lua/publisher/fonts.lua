-- publisher/fonts

require("fonts.fontloader")
module(...,package.seeall)

local lookup_fontname_dateiname={}
local schriftinstanzen={}
-- Ersatz für fonts
local benutzte_fonts={}


local att_schriftfamilie = 1
local att_kursiv         = 2
local att_fett           = 3
local att_script         = 4

-- Liste der Schriftfamilien. Schlüssel ist ein Wert wie `Überschrift`, die
-- Einträge sind Tabellen mit den Schlüsseln `normal`, `kursiv`, `fett`, `baselineksip` und `size`.
--schriftfamilien = {}

-- Jede Schriftart ("text", "Überschrift"), die per DefiniereSchriftfamilie definiert wird, erhält
-- eine interne Nummer. Diese Nummer kann über die folgende Tabelle abgefragt werden.
lookup_schriftfamilie_name_nummer={}

-- Jede Schriftfamilie (als Nummer) hat verschiedene Varianten, z.B. Kursiv, Fett, etc.
-- Diese werden als eine Tabelle in dieser Tabelle gespeichert.
-- Folgende Einträge sind in der Tabelle definiert:
--   normal
--   fettkursiv
--   kursiv
--   fett
--   zeilenabstand
--   size
lookup_schriftfamilie_nummer_instanzen={}


function lade_schriftdatei( name, dateiname,parameter_tab)
  assert(dateiname)
  assert(name)
  -- w("Lade Schriftdatei '%s' mit dem Dateinamen '%s'",name,dateiname)
  lookup_fontname_dateiname[name]={dateiname,parameter_tab}
  return true
end

function table.find(tab,schluessel)
  assert(tab)
  assert(schluessel)
  -- w("table.find")
  local gefunden
  for k_tab,v_tab in pairs(tab) do
    if type(schluessel)=="table" then
      gefunden = true
      -- w("gehe durch die Schlüsseltabelle")
      for k_schluessel,v_schluessel in pairs(schluessel) do
        -- w("vergleiche '%s' mit '%s'",k_tab[k_schluessel],v_schluessel)
        if k_tab[k_schluessel]~= v_schluessel then gefunden = false end
      end
      if gefunden==true then
        return v_tab
      end
    end
  end
  return nil
end

-- Rückgabe: true/false, num/Nachricht. num ist die interne Fontnummer. Nach erzeuge_fontinstanz kann
-- der Font intern benutzt werden.
-- Instanzschlüssel: {dateiname,groesse}
function erzeuge_fontinstanz( name,groesse )
  assert(name)
  assert(groesse)
  -- w(tostring(type(groesse)=="number"))
  assert(    type(groesse)=="number" )
  -- w("Erzeuge Instanz '%s' in %dbp",name,groesse)
  if not lookup_fontname_dateiname[name] then
    local msg = string.format("Instanz '%s' ist nicht definiert!", name)
    fehler(msg)
    return false, msg
  end
  local dateiname,parameter = unpack(lookup_fontname_dateiname[name])
  assert(dateiname)
  -- w("fontparameter=%s", tostring(parameter))
  -- w("Fontname=%s",dateiname)
  -- lookup für die schriftinstanzen Tabelle
  local k = {dateiname = dateiname, groesse = groesse}
  local fontnummer = table.find(schriftinstanzen,k)
  
  if fontnummer then
    return true,fontnummer
  else
    local ok,f = fonts.fontloader.define_font(dateiname,groesse,parameter)
    if ok then
      local num = font.define(f)
      schriftinstanzen[k]=num
      benutzte_fonts[num]=f
      -- w("Fontid = %d",num)
      return true, num
    else
      return false, string.format("Schriftart '%s' konnte nicht geladen werden!",dateiname)
    end
  end
  return false, "Interner Fehler"
end


function pre_linebreak( head )
	local first_head = head

	while head do
  -- w("head-id=%s",node.type(head.id))
	if head.id == 0 then -- hlist
		pre_linebreak(head.list)
	  if node.has_attribute(head,att_script) then
	    local sub_sup = node.has_attribute(head,att_script)
	    local fam = lookup_schriftfamilie_nummer_instanzen[fontfamilie]
	    if sub_sup == 1 then
	      head.shift = fam.scriptshift
      else
	      head.shift = -fam.scriptshift
      end
      -- die hbox hat aber noch die Breite der ursprünglichen Zeichen (von publisher/Absatz:script)
      local n = node.hpack(head.list)
      head.width = n.width
      n.list = nil
      node.free(n)
    end
	elseif head.id == 1 then -- vlist
		pre_linebreak(head.list)
	elseif head.id == 2 then -- rule
	  -- w("rule.width=%d,rule.height=%d,rule.depth=%d",head.width / 2^16,head.height / 2^16,head.depth / 2^16)
	elseif head.id == 7 then -- discretionary
	  -- printtable("disc",node.fields(7),0)
  	  pre_linebreak(head.pre)
  	  pre_linebreak(head.post)
  	  pre_linebreak(head.replace)
	elseif head.id == 8 then -- whatsit
	elseif head.id == 10 then -- glue
    local gluespec = head.spec
    -- w("gluespec: %s, subtype: %s",tostring(gluespec),tostring(head.subtype))
	  if gluespec then
      -- w("glue: g.width=%s",tostring(gluespec.width / 2^16))
      -- w("head.attribute=%s",tostring(node.has_attribute(head,1)))
	    if node.has_attribute(head,att_schriftfamilie) then
		    local fontfamilie=node.has_attribute(head,att_schriftfamilie)
		    -- w("Fontfamilie=%d",fontfamilie)
        local instanz = lookup_schriftfamilie_nummer_instanzen[fontfamilie]
        -- w("Instanz=%s",tostring(instanz.normal))
        local f
        -- w("Font=%s",tostring(f))
  		  local kursiv = node.has_attribute(head,att_kursiv)
  		  local fett   = node.has_attribute(head,att_fett)
  		  if kursiv == 1 and fett ~= 1 then
  		    f = benutzte_fonts[instanz.kursiv]
  		  elseif kursiv == 1 and fett == 1 then
  		    f = benutzte_fonts[instanz.fettkursiv]
  		  elseif fett == 1 then
  		    f = benutzte_fonts[instanz.fett]
  		  else
          f = benutzte_fonts[instanz.normal]
        end
        -- eigentlich: fallback auf defaultfont!
        -- assert(f,"Instanz nicht defniert!")
        if not f then f=publisher.optionen.defaultfont
          -- w("Fontinstanz nicht gefunden")
        end
        if gluespec.stretch_order == 0 and gluespec.writable then
          gluespec.width=f.parameters.space
          gluespec.stretch=f.parameters.space_stretch
          gluespec.shrink=f.parameters.space_shrink
        else
          w("gluespec: %s, subtype: %s",tostring(gluespec),tostring(head.subtype))
        end
        -- w("space=%d, stretch=%d, shrink=%d, stretch_order=%d",f.parameters.space / 2^16 ,f.parameters.space_stretch  / 2^16,f.parameters.space_shrink / 2^16,gluespec.stretch_order)
      end
    else
      -- FIXME: wie kann es sein, dass kein gluespec vorhanden ist???
      -- kein gluespec vorhanden.
      gluespec = node.new("glue_spec",0)
	    local fontfamilie=node.has_attribute(head,att_schriftfamilie)
	    -- w("Fontfamilie=%s",tostring(fontfamilie))
      local instanz = lookup_schriftfamilie_nummer_instanzen[fontfamilie]
      -- w("Instanz=%s",tostring(instanz.normal))
      local f = benutzte_fonts[instanz.normal]
      -- w("Font=%s",tostring(f))
      gluespec.width=f.parameters.space
      gluespec.stretch=f.parameters.space_stretch
      gluespec.shrink=f.parameters.space_shrink
      head.spec = gluespec
    end
	elseif head.id == 11 then -- kern
	  -- assert(false) -- test
	elseif head.id == 12 then -- penalty
	elseif head.id == 37 then  -- glyph
		if node.has_attribute(head,att_schriftfamilie) then
		  -- nicht local, damit ich auf fontfamilie zugreifen kann
		  fontfamilie=node.has_attribute(head,att_schriftfamilie)

		  -- Letzte Lösung.
		  if fontfamilie == 0 then fontfamilie = 1 end

		  local instanz = lookup_schriftfamilie_nummer_instanzen[fontfamilie]
		  local kursiv = node.has_attribute(head,att_kursiv)
		  local fett   = node.has_attribute(head,att_fett)

		  local instanzname = nil
		  if kursiv == 1 and fett ~= 1 then
		    instanzname = "kursiv"
		  elseif kursiv == 1 and fett == 1 then
		    instanzname = "fettkursiv"
		  elseif fett == 1 then
		    instanzname = "fett"
		  else
        instanzname = "normal"
      end

		  if node.has_attribute(head,att_script) then
		    instanzname = instanzname .. "script"
		  end

		  tmp_fontnum = instanz[instanzname]

      if not tmp_fontnum then
        head.font = publisher.optionen.defaultfontnumber
      else
        head.font = tmp_fontnum
      end
      -- prüfe Kapitälchen
      local f = benutzte_fonts[tmp_fontnum]
  
      if f and f.otfeatures and f.otfeatures.smcp == true then
        local glyphno,lookups
        -- local lookup_tables = f.ttffont.smcp
        local glyph_lookuptable
        if f.characters[head.char] then
          -- w("char: %d", head.char)
          glyphno = f.characters[head.char].index
          lookups = f.fontloader.glyphs[glyphno].lookups
          for _,v in ipairs(f.smcp) do
            if lookups then
              glyph_lookuptable = lookups[v]
              if glyph_lookuptable then
                -- w("glyph_lookuptable = %s",type(glyph_lookuptable))
                if glyph_lookuptable[1].type == "substitution" then
                  head.char=f.fontloader.lookup_codepoint_by_name[glyph_lookuptable[1].specification.variant]
                elseif glyph_lookuptable[1].type == "multiple" then
                  local lastnode 
                  w("multiple")
                  for i,v in ipairs(string.explode(glyph_lookuptable[1].specification.components)) do
                    if i==1 then
                      head.char=f.fontloader.lookup_codepoint_by_name[v]
                    else
                      local n = node.new("glyph",0)
                      n.next = head.next
                      n.font = tmp_fontnum
                      n.lang = 0
                      n.char = f.fontloader.lookup_codepoint_by_name[v]
                      head.next = n
                      head = n
                    end
                  end
                end
              end
            end
          end
        end -- if f.characters[head.char]
      end -- f.otffeatures.smcp == true
		end -- schriftfamilie?
	else
	  w("Achtung, unbekanntes Node: %s",head.id)
	end
	head = head.next
	end

	return true
end

function unterstreichung_einfuegen( list_head, head, start)
  local wd = node.dimensions(list_head.glue_set,list_head.glue_sign, list_head.glue_order,start,head)
	local ht = list_head.height
	local dp = list_head.depth

  wd = wd / 65782
  ht = ht / 65782
  dp = dp / 65782

  local rule = node.new("whatsit","pdf_literal")
  -- Dicke: ht / ...
  -- Verschiebung nach unten: dp/2
  local rule_width = ht / 10
  local shift_down = ( dp - rule_width ) / 2
  rule.data = string.format("q 0 g 0 G 0 -%g %g -%g re f Q", shift_down, -wd, rule_width )
  rule.mode = 0
  head = head.prev
  rule.next = head.next
  head.next.prev = rule
  rule.prev = head
  head.next = rule
  return rule
end

function post_linebreak( head, list_head)
  start = nil
	while head do
	  if head.id == 0 then -- hlist
		  post_linebreak(head.list,head)
	  elseif head.id == 1 then -- vlist
		  post_linebreak(head.list,head)
		elseif head.id == 7 then -- disc
      if publisher.optionen.zeige_silbentrennung=="ja" then
        local n = node.new("whatsit","pdf_literal")
        n.mode = 0
        n.data = "q 0.3 w 0 2 m 0 7 l S Q"
        n.next = head.next
        n.prev = head
        head.next = n
        head = n
      end
		elseif head.id == 10 then -- glue
	    local att_underline = node.has_attribute(head, publisher.att_unterstreichen)
	    -- bei rightskip muss auf jeden Fall unterstrichen werden (sofern start existiert)
      if att_underline ~= 1 or head.subtype == 9 then
        if start then
	        unterstreichung_einfuegen(list_head, head, start)
	        start = nil
	      end
	    end
		elseif head.id == 37 then -- glyph
		  local att_underline = node.has_attribute(head, publisher.att_unterstreichen)
		  if att_underline == 1 then
        if not start then
          start = head
        end
      else
        if start then
		      unterstreichung_einfuegen(list_head, head, start)
		      start = nil
        end
		  end
		end
  	head = head.next
  end
  return head
end
