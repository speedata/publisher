--
--  fonts.lua
--  publisher
--
--  Copyright 2011 Patrick Gundlach.
--  See file COPYING in the root directory for license details.


require("fonts.fontloader")
module(...,package.seeall)

local lookup_fontname_dateiname={}
local schriftinstanzen={}
-- Ersatz für fonts
local benutzte_fonts={}


local att_fontfamily     = 1
local att_italic         = 2
local att_bold           = 3
local att_script         = 4

-- Liste der Schriftfamilien. Schlüssel ist ein Wert wie `Überschrift`, die
-- Einträge sind Tabellen mit den Schlüsseln `normal`, `kursiv`, `fett`, `baselineksip` und `size`.
--schriftfamilien = {}

-- Every fontface ("text", "Chapter"), that is defined by DefineFontface gets an internal
-- number. This number is stored here.
lookup_schriftfamilie_name_nummer={}

-- Every fontface (given by number) has variants like italic, bold etc.
-- These are stored as a table in this table.
-- The following keys are stored
--   normal
--   fettkursiv
--   kursiv
--   fett
--   baselineskip
--   size
lookup_schriftfamilie_nummer_instanzen={}


function load_fontfile( name, dateiname,parameter_tab)
  assert(dateiname)
  assert(name)
  lookup_fontname_dateiname[name]={dateiname,parameter_tab}
  return true
end

function table.find(tab,key)
  assert(tab)
  assert(key)
  local found
  for k_tab,v_tab in pairs(tab) do
    if type(key)=="table" then
      gefunden = true
      for k_key,v_key in pairs(key) do
        if k_tab[k_key]~= v_key then found = false end
      end
      if found==true then
        return v_tab
      end
    end
  end
  return nil
end

-- Return false, errormessage in case of failure, true, number otherwise. number
-- is the internal font number. After calling this method, the font can be used
-- with the key { filename,size}
function erzeuge_fontinstanz( name,groesse )
  assert(name)
  assert(groesse)
  assert(    type(groesse)=="number" )
  if not lookup_fontname_dateiname[name] then
    local msg = string.format("Instanz '%s' ist nicht definiert!", name)
    err(msg)
    return false, msg
  end
  local dateiname,parameter = unpack(lookup_fontname_dateiname[name])
  assert(dateiname)
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
      if node.has_attribute(head,att_fontfamily) then
        local fontfamilie=node.has_attribute(head,att_fontfamily)
		    -- w("Fontfamilie=%d",fontfamilie)
        local instanz = lookup_schriftfamilie_nummer_instanzen[fontfamilie]
        -- w("Instanz=%s",tostring(instanz.normal))
        local f
        -- w("Font=%s",tostring(f))
        local kursiv = node.has_attribute(head,att_italic)
        local fett   = node.has_attribute(head,att_bold)
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
        if not f then f=publisher.options.defaultfont
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
      -- FIXME: how can it be that there is no glue_spec???
      -- no glue_spec found.
      gluespec = node.new("glue_spec",0)
      local fontfamilie=node.has_attribute(head,att_fontfamily)
      local instanz = lookup_schriftfamilie_nummer_instanzen[fontfamilie]
      local f = benutzte_fonts[instanz.normal]
      gluespec.width=f.parameters.space
      gluespec.stretch=f.parameters.space_stretch
      gluespec.shrink=f.parameters.space_shrink
      head.spec = gluespec
    end
	elseif head.id == 11 then -- kern
	  -- assert(false) -- test
	elseif head.id == 12 then -- penalty
	elseif head.id == 37 then  -- glyph
		if node.has_attribute(head,att_fontfamily) then
		  -- nicht local, damit ich auf fontfamilie zugreifen kann
      fontfamilie=node.has_attribute(head,att_fontfamily)

		  -- Letzte Lösung.
      if fontfamilie == 0 then fontfamilie = 1 end

      local instanz = lookup_schriftfamilie_nummer_instanzen[fontfamilie]
      local kursiv = node.has_attribute(head,att_italic)
      local fett   = node.has_attribute(head,att_bold)

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
        head.font = publisher.options.defaultfontnumber
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
    warning("Unknown node: %q",head.id)
	end
	head = head.next
	end

	return true
end

function insert_underline( list_head, head, start)
  local wd = node.dimensions(list_head.glue_set,list_head.glue_sign, list_head.glue_order,start,head)
	local ht = list_head.height
	local dp = list_head.depth

  wd = wd / 65782
  ht = ht / 65782
  dp = dp / 65782

  local rule = node.new("whatsit","pdf_literal")
  -- thickness: ht / ...
  -- downshift: dp/2
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

-- Underline and 'showhyphens'
function post_linebreak( head, list_head)
  start = nil
	while head do
    if head.id == 0 then -- hlist
      post_linebreak(head.list,head)
    elseif head.id == 1 then -- vlist
      post_linebreak(head.list,head)
		elseif head.id == 7 then -- disc
      if publisher.options.showhyphenation then
        local n = node.new("whatsit","pdf_literal")
        n.mode = 0
        n.data = "q 0.3 w 0 2 m 0 7 l S Q"
        n.next = head.next
        n.prev = head
        head.next = n
        head = n
      end
		elseif head.id == 10 then -- glue
      local att_underline = node.has_attribute(head, publisher.att_underline)
	    -- ati rightskip we must underline (if start exists)
      if att_underline ~= 1 or head.subtype == 9 then
        if start then
          insert_underline(list_head, head, start)
          start = nil
        end
      end
		elseif head.id == 37 then -- glyph
      local att_underline = node.has_attribute(head, publisher.att_underline)
      if att_underline == 1 then
        if not start then
          start = head
        end
      else
        if start then
          insert_underline(list_head, head, start)
          start = nil
        end
      end
		end
    head = head.next
  end
  return head
end
