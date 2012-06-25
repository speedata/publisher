--
--  publisher.lua
--  speedata publisher
--
--  Copyright 2010-2012 Patrick Gundlach.
--  See file COPYING in the root directory for license info.

file_start("publisher.lua")

local commands     = require("publisher.commands")
local seite        = require("publisher.page")
local translations = require("translations")
local fontloader   = require("fonts.fontloader")

sd_xpath_funktionen      = require("publisher.layout_functions")
orig_xpath_funktionen    = require("publisher.xpath_functions")

local xmlparser = require("xmlparser")


module(...,package.seeall)

--- One big point (DTP point, PostScript point) is approx. 65781 scaled points.
factor = 65781 

--- We use a lot of attributes to delay the processing of font shapes, ... to
--- a later time. These attributes have have any number, they just need to be
--- constant across the whole source.
att_fontfamily     = 1
att_italic         = 2
att_bold           = 3
att_script         = 4
att_underline      = 5

--- These attributes are for image shifting. The amount of shift up/left can
--- be negative and is counted in scaled points.
att_shift_left     = 100
att_shift_up       = 101

--- A tie glue (U+00A0) is a non-breaking space
att_tie_glue       = 201

--- These attributes are used in tabular material
att_space_prio     = 300
att_space_amount   = 301

att_break_below    = 400
att_break_above    = 401

--- `att_is_table_row` is used in `tabular.lua` and if set to 1, it denotes
--- a regular table row, and not a spacer. Spacers must not appear
--- at the top or the bottom of a table, unless forced to.
att_is_table_row   = 500

glue_spec_node = node.id("glue_spec")
glue_node      = node.id("glue")
glyph_node     = node.id("glyph")
rule_node      = node.id("rule")
penalty_node   = node.id("penalty")
whatsit_node   = node.id("whatsit")
hlist_node     = node.id("hlist")

pdf_literal_node = node.subtype("pdf_literal")

default_areaname = "__seite"

-- the language of the layout instructions ('en' or 'de')
current_layoutlanguage = nil

seiten   = {}

-- The defaults (set in the layout instructions file)
options = {
  gridwidth = tex.sp("10mm"),
  gridheight = tex.sp("10mm"),
}

-- List of virtual areas. Key is the group name and value is
-- a hash with keys contents (a nodelist) and raster (grid).
groups   = {}

variablen = {}
colors    = { Schwarz = { modell="grau", g = "0", pdfstring = " 0 G 0 g " } }
colortable = {}
data_dispatcher = {}
user_defined_funktionen = { last = 0}

-- die aktuelle Gruppe
current_group = nil
current_grid = nil


-- The array 'masterpages' has tables similar to these:
-- { ist_seitentyp = test, res = tab, name = pagetypename }
-- where `ist_seitentyp` is an xpath expression to be evaluated,
-- `res` is a table with layoutxml instructions 
-- `name` is a string.
masterpages = {}


--- Text formats is a hash with arbitrary names as keys and the values
--- are tables with alignment and indent. indent is the amount of 
--- indentation in sp. alignment is one of "leftaligned", "rightaligned", 
--- "centered" and "justified"
textformats = {
  text           = { indent = 0, alignment="justified",   rows = 1},
  __centered     = { indent = 0, alignment="centered",    rows = 1},
  __leftaligned  = { indent = 0, alignment="leftaligned", rows = 1},
  __rightaligned = { indent = 0, alignment="rightaligned",rows = 1}
}

-- Liste der Schriftarten und deren Synonyme. Beispielsweise könnte ein Schlüssel `Helvetica` sein,
-- der Eintrag dann `texgyreheros-regular.otf`
-- schrifttabelle = {}

--- We map from sybolic names to (part of) file names. The hyphenation pattern files are 
--- in the format `hyph-XXX.pat.txt` and we need to find out that `XXX` part.
language_mapping = {
     ["German"]                       = "de-1996",
     ["Englisch (Great Britan)"]      = "en-gb",
     ["French"]                       = "fr",
}

--- Once a hyphenation pattern file is loaded, we only need the _id_ of it. This is stored in the
--- `languages` table. Key is the filename part (such as `de-1996`) and the value is the internal
--- language id.
languages = {}

--- The bookmarks table has the format
---     bookmarks = {
---       { --- first bookmark
---         name = "outline 1" destination = "..." open = true,
---          { name = "outline 1.1", destination = "..." },
---          { name = "outline 1.2", destination = "..." }
---       },
---       { -- second bookmark
---         name = "outline 2" destination = "..." open = false,
---          { name = "outline 2.1", destination = "..." },
---          { name = "outline 2.2", destination = "..." }
---    
---       }
---     }
bookmarks = {}

--- A table with key namespace prefix (`de` or `en`) and value namespace
namespaces_layout = nil

local dispatch_table = {
  Paragraph               = commands.absatz,
  Action                  = commands.aktion,
  Attribute               = commands.attribut,
  B                       = commands.fett,
  ProcessNode             = commands.bearbeite_knoten,
  ProcessRecord           = commands.bearbeite_datensatz,
  AtPageShipout           = commands.beiseitenausgabe,
  AtPageCreation          = commands.beiseitenerzeugung,
  Image                   = commands.bild,
  Box                     = commands.box,
  Bookmark                = commands.bookmark,
  Record                  = commands.datensatz,
  DefineColor             = commands.definiere_farbe,
  DefineFontfamily        = commands.definiere_schriftfamilie,
  DefineTextformat        = commands.definiere_textformat,
  Element                 = commands.element,
  Switch                  = commands.fallunterscheidung,
  Group                   = commands.gruppe,
  I                       = commands.kursiv,
  Include                 = commands.include,
  ["Copy-of"]             = commands.kopie_von,
  LoadDataset             = commands.lade_datensatzdatei,
  LoadFontfile            = commands.lade_schriftdatei,
  EmptyLine               = commands.leerzeile,
  Rule                    = commands.linie,
  Message                 = commands.nachricht,
  NextFrame               = commands.naechster_rahmen,
  NewPage                 = commands.neue_seite,
  NextRow                 = commands.neue_zeile,
  Options                 = commands.optionen,
  PlaceObject             = commands.objekt_ausgeben,
  PositioningArea         = commands.platzierungsbereich,
  PositioningFrame        = commands.platzierungsrahmen,
  Margin                  = commands.rand,
  Grid                    = commands.raster,
  Fontface                = commands.schriftart,
  Pagetype                = commands.seitentyp,
  Pageformat              = commands.seitenformat,
  SetGrid                 = commands.setze_raster,
  Sequence                = commands.sequenz,
  While                   = commands.solange,
  SortSequence            = commands.sortiere_sequenz,
  SaveDataset             = commands.speichere_datensatzdatei,
  Column                  = commands.spalte,
  Columns                 = commands.spalten,
  Sub                     = commands.sub,
  Sup                     = commands.sup,
  Table                   = commands.tabelle,
  Tablefoot               = commands.tabellenfuss,
  Tablehead               = commands.tabellenkopf,
  Textblock               = commands.textblock,
  Hyphenation             = commands.trennvorschlag,
  Tablerule               = commands.tlinie,
  Tr                      = commands.tr,
  Td                      = commands.td,
  U                       = commands.underline,
  URL                     = commands.url,
  Variable                = commands.variable,
  Value                   = commands.wert,
  SetVariable             = commands.zuweisung,
  AddToList               = commands.zur_liste_hinzufuegen,
}

-- Return the localized eltname as an english string.
function translate_element( eltname )
  return translations[current_layoutlanguage].elements[eltname]
end

-- return the localized value as an english string-
function translate_value( value )
  local tmp = translations[current_layoutlanguage].values[value]
  return tmp
end

-- Return the localized attribute name as an english string.
function translate_attribute( attname )
  return translations.attributes[attname][current_layoutlanguage]
end


function dispatch(layoutxml,dataxml,optionen)
  local ret = {}
  local tmp
  for _,j in ipairs(layoutxml) do
    -- j a table, if it is an element in layoutxml
    if type(j)=="table" then
      local eltname = translate_element(j[".__name"])
      if dispatch_table[eltname] ~= nil then
        tmp = dispatch_table[eltname](j,dataxml,optionen)

        -- Copy-of-elements can be resolveld immediately 
        if eltname == "Copy-of" or eltname == "Switch" then
          if type(tmp)=="table" then
            for i=1,#tmp do
              if tmp[i].contents then
                ret[#ret + 1] = { elementname = tmp[i].elementname, contents = tmp[i].contents }
              else
                ret[#ret + 1] = { elementname = "elementstructure" , contents = { tmp[i] } }
              end
            end
          end
        else
          ret[#ret + 1] =   { elementname = eltname, contents = tmp }
        end
      else
        err("Unknown element found in layoutfile: %q", eltname or "???")
        printtable("j",j)
      end
    end
  end
  return ret
end

function utf8_to_utf16_string_pdf( str )
  local ret = {}
  for s in string.utfvalues(str) do
    ret[#ret + 1] = fontloader.to_utf16(s)
  end
  local utf16str = "<feff" .. table.concat(ret) .. ">"
  return utf16str
end

--- Bookmarks are collected and later processed. This function (recursively)
--- creates TeX code from the generated tables.
function bookmarkstotex( tbl )
  local countstring
  local open_string
  if #tbl == 0 then
    countstring = ""
  else
    if tbl.open == "true" then
      open_string = ""
        else
      open_string = "-"
    end
    countstring = string.format("count %s%d",open_string,#tbl)
  end
  if tbl.destination then
    tex.sprint(string.format("\\pdfoutline goto num %s %s {%s}",tbl.destination, countstring ,utf8_to_utf16_string_pdf(tbl.name) ))
  end
  for i,v in ipairs(tbl) do
    bookmarkstotex(v)
  end
end

--- Start function. 
function dothings()
  page_initialized=false

  -- defaults
  set_pageformat(tex.sp("210mm"),tex.sp("297mm"))

  fonts.load_fontfile("TeXGyreHeros-Regular",   "texgyreheros-regular.otf")
  fonts.load_fontfile("TeXGyreHeros-Bold",      "texgyreheros-bold.otf")
  fonts.load_fontfile("TeXGyreHeros-Italic",    "texgyreheros-italic.otf")
  fonts.load_fontfile("TeXGyreHeros-BoldItalic","texgyreheros-bolditalic.otf")

  define_default_fontfamily()
  local onecm=tex.sp("1cm")
  masterpages[1] = { ist_seitentyp = "true()", res = { {elementname = "Margin", contents = function(_seite) _seite.raster:setze_rand(onecm,onecm,onecm,onecm) end }}, name = "Seite" }

  local layoutxml = load_xml(arg[2],"layout instructions")
  local dataxml  = load_xml(arg[3],"data file")

  local vars = loadfile("publisher.vars")()
  for k,v in pairs(vars) do
    variablen[k]=v
  end

  namespaces_layout = layoutxml["__namespace"]
  local nsprefix = string.match(layoutxml[".__name"],"^(.*):") or ""
  local ns = layoutxml["__namespace"][nsprefix]


  current_layoutlanguage = string.gsub(ns,"urn:speedata.de:2009/publisher/","")
  if not (current_layoutlanguage=='de' or current_layoutlanguage=='en') then
    err("Cannot determine the language of the layout file.")
    exit()
  end

  dispatch(layoutxml)

  -- override options set in the <Options> element
  for _,extopt in ipairs(string.explode(arg[4],",")) do
    if string.len(extopt) > 0 then
      local k,v = extopt:match("^(.+)=(.+)$")
      v = v:gsub("^\"(.*)\"$","%1")
      options[k]=v
    end
  end
  if options.showgrid == "false" then
    options.showgrid = false
  elseif options.showgrid == "true" then
    options.showgrid = true
  end

  -- do things with options
  if options.startpage then
    local num = options.startpage
    if num then
      tex.count[0] = num - 1
      log("Set page number to %d",num)
    else
      err("Can't recognize starting page number %q",options.startpage)
    end
  end

  -- start data processing
  local tmp
  local name = dataxml[".__name"]
  tmp = data_dispatcher[""][name] -- default-Modus
  if tmp then publisher.dispatch(tmp,dataxml) end


  -- emit last page if necessary
  if page_initialized then
    dothingsbeforeoutput()
    local n = node.vpack(publisher.global_pagebox)

    tex.box[666] = n
    tex.shipout(666)
  end
  -- at this point, all pages are in the PDF


  -- printtable("Am Ende (inhalt)",variablen.inhalt)
  pdf.catalog = [[ /PageMode /UseOutlines ]]
  pdf.info    = [[ /Creator	(speedata Publisher) /Producer(speedata Publisher, www.speedata.de) ]]

  -- Now put the bookmarks in the pdf
  -- tex.sprint([[\pdfoutline...]])
  for i,v in ipairs(bookmarks) do
    bookmarkstotex(v)
  end

end

-- Load an XML file from the harddrive. filename is without path but including extension,
-- filetype is a string representing the type of file read, such as "layout" or "data".
-- The return value is a lua table representing the XML file.
--
-- The XML file
--
--     <?xml version="1.0" encoding="UTF-8"?>
--     <data>
--       <element attribute="whatever">
--         <subelement>text in subelement</subelement>
--       </element>
--     </data>
--
-- is represented by this Lua table:
--     XML = {
--       [1] = " "
--       [2] = {
--         [1] = " "
--         [2] = {
--           [1] = "text in subelement"
--           [".__parent"] = (pointer to the "element" tree, which is the second entry in the top level)
--           [".__name"] = "subelement"
--         },
--         [3] = " "
--         [".__parent"] = (pointer to the root element)
--         [".__name"] = "element"
--         ["attribute"] = "whatever"
--       },
--       [3] = " "
--       [".__name"] = "data"
--     },
function load_xml(filename,filetype)
  local path = kpse.find_file(filename)
  if not path then
    err("Can't find XML file %q. Abort.\n",filename or "?")
    os.exit(-1)
  end
  log("Loading %s %q",filetype or "file",path)

  local layoutfile = io.open(path,"r")
  if not layoutfile then
    err("Can't open XML file. Abort.")
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

-- Put the nodelist on grid cell (x,y). If allocate==true then mark cells as occupied.
function ausgabe_bei( nodelist, x,y,belegen,bereich,valign,allocate_matrix)

  bereich = bereich or default_areaname
  local r = current_grid
  local wd = nodelist.width
  local ht = nodelist.height + nodelist.depth
  local breite_in_rasterzellen = r:breite_in_rasterzellen_sp(wd)
  local hoehe_in_rasterzellen  = r:hoehe_in_rasterzellen_sp (ht)

  local delta_x, delta_y = r:position_rasterzelle_mass_tex(x,y,bereich,wd,ht,valign)
  if not delta_x then
    err(delta_y)
    exit()
  end

  if node.has_attribute(nodelist,att_shift_left) then
    delta_x = delta_x - node.has_attribute(nodelist,att_shift_left)
    delta_y = delta_y - node.has_attribute(nodelist,att_shift_up)
  end


  if current_group then
    -- Put the contents of the nodelist into the current group
    local group = groups[current_group]
    assert(group)

    local n = add_glue( nodelist ,"head",{ width = delta_x })
    n = node.hpack(n)
    n = add_glue(n, "head", {width = delta_y})
    n = node.vpack(n)

    if group.contents then
      -- Die Gruppe hat schon einen contents, wir müssen die neue Nodeliste dazufügen
      -- Maß der neuen Gruppe: maximum(Maß der alten Gruppe, Maß der Nodeliste)
      local neue_breite, neue_hoehe
      neue_breite = math.max(n.width, group.contents.width)
      neue_hoehe  = math.max(n.height + n.depth, group.contents.height + group.contents.depth)

      group.contents.width  = 0
      group.contents.height = 0
      group.contents.depth  = 0

      local tail = node.tail(group.contents)
      tail.next = n
      n.prev = tail

      group.contents = node.vpack(group.contents)
      group.contents.width  = neue_breite
      group.contents.height = neue_hoehe
      group.contents.depth  = 0
    else
      -- group is empty
      group.contents = n
    end
    if belegen then
      r:belege_zellen(x,y,breite_in_rasterzellen,hoehe_in_rasterzellen,allocate_matrix,options.showgridallocation)
    end
  else
    -- Put it on the current page
    if belegen then
      r:belege_zellen(x,y,breite_in_rasterzellen,hoehe_in_rasterzellen,allocate_matrix,options.showgridallocation,bereich)
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

-- Return the XML structure taht is stored at <pagetype>. For every pagetype
-- in the table "masterpages" the function ist_seitentyp() gets called

function detect_pagetype()
  local ret = nil
  for i=#masterpages,1,-1 do
    local seitentyp = masterpages[i]
    if xpath.parse(nil,seitentyp.ist_seitentyp) == true then
      log("Page of type %q created",seitentyp.name or "<detect_pagetype>")
      ret = seitentyp.res
      return ret
    end
  end
  err("Can't find correct page type!")
  return false
end

-- Muss aufgerufen werden, bevor auf eine neue Seite etwas ausgegeben wird.
function setup_page()
  if page_initialized then return end
  page_initialized=true
  publisher.global_pagebox = node.new("vlist")
  local trim_amount = tex.sp(options.trim or 0)
  local extra_margin
  if options.cutmarks then
    extra_margin = tex.sp("1cm") + trim_amount
  elseif trim_amount > 0 then
    extra_margin = trim_amount
  end
  local errorstring

  current_page, errorstring = seite:new(options.pagewidth,options.seitenhoehe, extra_margin, trim_amount)
  if not current_page then
    err("Can't create a new page. Is the page type (»Seitentyp«) defined? %s",errorstring)
    exit()
  end
  current_grid = current_page.raster
  seiten[tex.count[0]] = nil
  tex.count[0] = tex.count[0] + 1
  seiten[tex.count[0]] = current_page

  local gridwidth = options.gridwidth
  local gridheight  = options.gridheight


  local pagetype = detect_pagetype()
  if pagetype == false then return false end

  for _,j in ipairs(pagetype) do
    local eltname = elementname(j,true)
    if type(element_contents(j))=="function" and eltname=="Margin" then
      element_contents(j)(current_page)
    elseif eltname=="Grid" then
      gridwidth = element_contents(j).breite
      gridheight  = element_contents(j).hoehe
    end
  end

  if not gridwidth then
    err("Grid is not set!")
    exit()
  end
  assert(gridwidth)
  assert(gridheight,"Gridheight!")
  current_page.raster:setze_breite_hoehe(gridwidth,gridheight)

  for _,j in ipairs(pagetype) do
    local eltname = elementname(j,true)
    if type(element_contents(j))=="function" and eltname=="Margin" then
      -- do nothing, done before
    elseif eltname=="Grid" then
      -- do nothing, done before
    elseif eltname=="AtPageCreation" then
      current_page.atpagecreation = element_contents(j)
    elseif eltname=="AtPageShipout" then
      current_page.AtPageShipout = element_contents(j)
    elseif eltname=="PositioningArea" then
      local name = element_contents(j).name
      current_grid.platzierungsbereiche[name] = {}
      local aktueller_platzierungsbereich = current_grid.platzierungsbereiche[name]
      -- we eveluate now, because the attributes in PositioningFrame can be page dependent.
      local tab  = publisher.dispatch(element_contents(j).layoutxml,dataxml)
      for i,k in ipairs(tab) do
        aktueller_platzierungsbereich[#aktueller_platzierungsbereich + 1] = element_contents(k)
      end
    else
      err("Element name %q unknown (setup_page())",eltname or "<create_page>")
    end
  end


  if current_page.atpagecreation then
    publisher.dispatch(current_page.atpagecreation,nil)
  end
end

function next_area( areaname )
  local aktuelle_nummer = current_grid:rahmennummer(areaname)
  if aktuelle_nummer >= current_grid:anzahl_rahmen(areaname) then
    neue_seite()
  else
    current_grid:setze_rahmennummer(areaname, aktuelle_nummer + 1)
  end
  current_grid:set_current_row(1,areaname)
end

function neue_seite()
  if seitenumbruch_unmoeglich then
    return
  end
  if not current_page then
    -- es wurde neue_seite() aufgerufen, ohne, dass was ausgegeben wurde bisher
    page_initialized=false
    setup_page()
  end
  if current_page.AtPageShipout then
    seitenumbruch_unmoeglich = true
    dispatch(current_page.AtPageShipout)
    seitenumbruch_unmoeglich = false
  end
  page_initialized=false
  dothingsbeforeoutput()
  current_page = nil

  local n = node.vpack(publisher.global_pagebox)
  tex.box[666] = n
  tex.shipout(666)
end

-- Zeichnet einen farbigen Hintergrund hinter ein rechteckickges Objekt (box)
function hintergrund( box, farbname )
  if not colors[farbname] then
    warning("Background: Color %q is not defined",farbname)
    return box
  end
  local pdffarbstring = colors[farbname].pdfstring
  local wd, ht, dp = sp_to_bp(box.width),sp_to_bp(box.height),sp_to_bp(box.depth)
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
  local pdffarbstring = colors[farbname].pdfstring
  local wd, ht, dp = sp_to_bp(box.width),sp_to_bp(box.height),sp_to_bp(box.depth)
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
  n.data = string.format("q %s 1 0 0 1 0 0 cm 0 0 %g -%g re f Q",colors[farbname].pdfstring,breite,hoehe)
  n.mode = 0
  return n
end

function dothingsbeforeoutput(  )
  local r = current_page.raster
  local str
  finde_user_defined_whatsits(publisher.global_pagebox)
  local firstbox

  -- White background on page. Todo: Make color customizable and background optional.
  local wd = sp_to_bp(current_page.width)
  local ht = sp_to_bp(current_page.height)

  local x = 0 + current_page.raster.extra_rand
  local y = 0 + current_page.raster.extra_rand + current_page.raster.rand_oben

  if options.trim then
    local trim_bp = sp_to_bp(options.trim)
    wd = wd + trim_bp * 2
    ht = ht + trim_bp * 2
    x = x - options.trim
    y = y - options.trim
  end

  firstbox = node.new("whatsit","pdf_literal")
  firstbox.data = string.format("q 0 0 0 0 k  1 0 0 1 0 0 cm %g %g %g %g re f Q",sp_to_bp(x), sp_to_bp(y),wd ,ht)
  firstbox.mode = 1

  if options.showgridallocation then
    local lit = node.new("whatsit","pdf_literal")
    lit.mode = 1
    lit.data = r:draw_gridallocation()

    if firstbox then
      local tail = node.tail(firstbox)
      tail.next = lit
      lit.prev = tail
    else
      firstbox = lit
    end
  end
  -- if #current_page.raster.belegung_pdf > 0 then
  --   local lit = node.new("whatsit","pdf_literal")
  --   lit.mode = 1
  --   lit.data = string.format("%s",table.concat(current_page.raster.belegung_pdf,"\n"))
  -- end

  if options.showgrid then
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
  if options.cutmarks then
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

-- Read the contents of the attribute attname_englisch. type is one of
-- "string", "number", "length" and "boolean".
-- Default provides, well, a default.
function read_attribute( layoutxml,dataxml,attname_english,typ,default)
  local attname = translate_attribute(attname_english)
  if layoutxml[attname] == nil then
    if default then
      layoutxml[attname] = default
    else
      return nil
    end
  end

  local val
  local xpathstring = string.match(layoutxml[attname],"{(.-)}")
  if xpathstring then
    val = xpath.textvalue(xpath.parse(dataxml,xpathstring))
  else
    val = layoutxml[attname]
  end
  local val_english = translate_value(val)
  if val_english then
    val = val_english
  end

  if typ=="xpath" then
    return xpath.textvalue(xpath.parse(dataxml,val))
  elseif typ=="string" then
    return tostring(val)
  elseif typ=="number" then
    return tonumber(val)
  elseif typ=="length" then
    return val
  elseif typ=="boolean" then
    if val=="yes" then
      return true
    elseif val=="no" then
      return false
    end
    return nil
  else
    warning("read_attribut (2): unknown type: %s",type(val))
  end
  return val
end

-- Return the element name of the given element (elt) and translate it
-- into english, unless raw_p is true.
function elementname( elt ,raw_p)
  trace("elementname = %q",elt.elementname or "?")
  if raw_p then return elt.elementname end
  trace("translated = %q",translate_element(elt.elementname) or "?")
  return translate_element(elt.elementname)
end

function element_contents( elt )
  return elt.contents
end

-- <b>, <u> and <i> in text
function parse_html( elt )
  local a = Paragraph:new()
  local fett,kursiv,underline
  if elt[".__name"] then
    if elt[".__name"] == "b" or elt[".__name"] == "B" then
      fett = 1
    elseif elt[".__name"] == "i" or elt[".__name"] == "I" then
      kursiv = 1
    elseif elt[".__name"] == "u" or elt[".__name"] == "U" then
      underline = 1
    end
  end

  for i=1,#elt do
    if type(elt[i]) == "string" then
      a:append(elt[i],{schriftfamilie = 0, fett = fett, kursiv = kursiv, underline = underline })
    elseif type(elt[i]) == "table" then
      a:append(parse_html(elt[i]),{schriftfamilie = 0, fett = fett, kursiv = kursiv, underline = underline})
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
        -- action
        if head.user_id == 1 then
          -- der Wert ist der Index für die Funktion unter user_defined_funktionen.
          fun = user_defined_funktionen[head.value]
          fun()
          -- use and forget
          user_defined_funktionen[head.value] = nil
        -- bookmark
        elseif head.user_id == 2 then
          local level,openclose,dest,str =  string.match(head.value,"([^+]*)+([^+]*)+([^+]*)+(.*)")
          level = tonumber(level)
          local open_p
          if openclose == "1" then
            open_p = true
          else
            open_p = false
          end
          local i = 1
          local current_bookmark_table = bookmarks -- level 1 == top level
          -- create levels if necessary
          while i < level do
            if #current_bookmark_table == 0 then
              current_bookmark_table[1] = {}
              err("No bookmark given for this level (%d)!",level)
            end
            current_bookmark_table = current_bookmark_table[#current_bookmark_table]
            i = i + 1
          end
          current_bookmark_table[#current_bookmark_table + 1] = {name = str, destination = dest, open = open_p}
        end
      end
    end
    head = head.next
  end
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
  local languagecode = parameter.languagecode
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
    instanz = fonts.lookup_fontfamily_number_instance[fontfamilie][instanzname]
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

  -- if it's an empty string, we make it a space character (experimental)
  if string.len(str) == 0 then
    n = node.new(glyph_node)
    n.char = 32
    n.font = instanz
    n.subtype = 1
    n.char = s
    if languagecode then
      n.lang = languagecode
    else
      if n.lang == 0 then
        err("Language code is not set and lang==0")
      end
    end

    node.set_attribute(n,att_fontfamily,fontfamilie)
    return n
  end
  for s in string.utfvalues(str) do
    local char = unicode.utf8.char(s)
    if s == 10 then
      local p1,g,p2
      p1 = node.new(penalty_node)
      p1.penalty = 10000

      g = node.new(glue_node)
      g.spec = node.new(glue_spec_node)
      g.spec.stretch = 2^16
      g.spec.stretch_order = 2

      p2 = node.new(penalty_node)
      p2.penalty = -10000

      -- rs = node.new(glue_node)
      -- rs.spec = node.new(glue_spec_node)

      p1.next = g
      g.next  = p2
      p2.next = rs

      if head then
        last.next = p1
      else
        head = p1
      end
      last = p2

    elseif match(char,"%s") and last and last.id == glue_node and not node.has_attribute(last,att_tie_glue,1) then
      -- double space, don't do anything
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

      if parameter.underline == 1 then
        node.set_attribute(n,att_underline,1)
      end
      node.set_attribute(n,att_fontfamily,fontfamilie)


    elseif match(char,"%s") then -- Leerzeichen
      n = node.new(glue_node)
      n.spec = node.new(glue_spec_node)
      n.spec.width   = space
      n.spec.shrink  = shrink 
      n.spec.stretch = stretch

      if parameter.underline == 1 then
        node.set_attribute(n,att_underline,1)
      end
      node.set_attribute(n,att_fontfamily,fontfamilie)

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
      n.lang = languagecode
      n.uchyph = 1
      n.left = tex.lefthyphenmin
      n.right = tex.righthyphenmin
      node.set_attribute(n,att_fontfamily,fontfamilie)
      if parameter.fett == 1 then
        node.set_attribute(n,att_bold,1)
      end
      if parameter.kursiv == 1 then
        node.set_attribute(n,att_italic,1)
      end
      if parameter.underline == 1 then
        node.set_attribute(n,att_underline,1)
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

function make_glue( parameter )
  local n = node.new("glue")
  n.spec = node.new("glue_spec")
  n.spec.width         = parameter.width
  n.spec.stretch       = parameter.stretch
  n.spec.stretch_order = parameter.stretch_order
  return n
end

function finish_par( nodelist,hsize )
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

function fix_justification( nodelist,textformat,parent)
  local head = nodelist
  while head do
    if head.id == 0 then -- hlist
      -- we are on a line now. We assume that the spacing needs correction.
      -- The goal depends on the current line (parshape!)
      local goal,_,_ = node.dimensions(head.glue_set, head.glue_sign, head.glue_order, head.head)
      local font_before_glue

      -- The following code is problematic, in tabular material. This is my older comment
      -- There was code here (39826d4c5 and before) that changed
      -- the glue depending on the font before that glue. That
      -- was problematic, because LuaTeX does not copy the 
      -- altered glue_spec node on copy_list (in Paragraph:format())
      -- which, when reformatted, gets a complaint by LuaTeX about
      -- infinite shrinkage in a paragraph

      -- a new glue spec node - we must not(!) alter the current glue spec
      -- because this list is copied in paragraph:format()
      local spec_new

      for n in node.traverse_id(10,head.head) do
        -- calculate the font before this id.
        if n.prev and n.prev.id == 37 then -- glyph
          font_before_glue = n.prev.font
        elseif n.prev and n.prev.id == 7 then -- disc
          local font_node = n.prev
          while font_node.id ~= 37 do
            font_node = font_node.prev
          end
          font_before_glue = nil
        else
          font_before_glue = nil
        end

        -- n.spec.width > 0 because we insert a glue after a hyphen in
        -- compund words mailing-[glue]list and that glue's width is 0pt
        if n.subtype==0 and font_before_glue and n.spec.width > 0 then
          spec_new = node.new("glue_spec")
          spec_new.width = font.fonts[font_before_glue].parameters.space
          spec_new.shrink_order = head.glue_order
          n.spec = spec_new
        end
      end

      if textformat == "rightaligned" then
        local wd = node.dimensions(head.glue_set, head.glue_sign, head.glue_order,head.head)
        local list_start = head.head
        local leftskip_node = node.new("glue")
        leftskip_node.spec = node.new("glue_spec")
        leftskip_node.spec.width = goal - wd
        leftskip_node.next = list_start
        list_start.prev = leftskip_node
        head.head = leftskip_node
        local tail = node.tail(head.head)

        if tail.prev.id == 10 and tail.prev.subtype==15 then -- parfillskip
          local parfillskip = tail.prev
          tail.prev = parfillskip.prev
          parfillskip.prev.next = tail
          parfillskip.next = head.head
          head.head = parfillskip
        end
      end

      if textformat == "centered" then
        local list_start = head.head
        local rightskip = node.tail(head.head)
        local leftskip_node = node.new("glue")
        leftskip_node.spec = node.new("glue_spec")
        local wd

        if rightskip.prev.id == 10 and rightskip.prev.subtype==15 then -- parfillskip
          local parfillskip = rightskip.prev

          wd = node.dimensions(head.glue_set, head.glue_sign, head.glue_order,head.head,parfillskip.prev)

          -- remove parfillksip and insert half width in rightskip
          parfillskip.prev.next = rightskip
          rightskip.prev = parfillskip.prev
          rightskip.spec = node.new("glue_spec")
          rightskip.spec.width = (goal - wd) / 2
          node.free(parfillskip)
        else
          wd = node.dimensions(head.glue_set, head.glue_sign, head.glue_order,head.head)
        end
        -- insert half width in front of the row
        leftskip_node.spec.width = ( goal - wd ) / 2
        leftskip_node.next = list_start
        list_start.prev = leftskip_node
        head.head = leftskip_node
      end

    elseif head.id == 1 then -- vlist
      fix_justification(head.head,textformat,head)
    end
    head = head.next
  end
  return nodelist
end

function do_linebreak( nodelist,hsize,parameters )
  assert(nodelist,"Keine nodeliste für einen Absatzumbruch gefunden.")
  parameters = parameters or {}
  finish_par(nodelist,hsize)

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
        local fam = node.has_attribute(glyf,att_fontfamily)
        maxskip = math.max(fonts.lookup_fontfamily_number_instance[fam].baselineskip,maxskip)
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

do
  local destcounter = 0
  -- Create a pdf anchor (dest object). It returns a whatsit node and the 
  -- number of the anchor, so it can be used in a pdf link or an outline.
  function mkdest()
    destcounter = destcounter + 1
    local d = node.new("whatsit","pdf_dest")
    d.named_id = 0
    d.dest_id = destcounter
    d.dest_type = 3
    return d, destcounter
  end
end

-- Generate a hlist with necessary nodes for the bookmarks. To be inserted into a vlist that gets shipped out
function mkbookmarknodes(level,open_p,title)
  -- The bookmarks need three values, the level, the name and if it is 
  -- open or closed
  local openclosed 
  if open_p then openclosed = 1 else openclosed = 2 end
  level = level or 1
  title = title or "no title for bookmark given"

  n,counter = mkdest()
  local udw = node.new("whatsit","user_defined")
  udw.user_id = 2
  udw.type = 115 -- a string
  udw.value = string.format("%d+%d+%d+%s",level,openclosed,counter,title)
  n.next = udw
  udw.prev = n
  local hlist = node.hpack(n)
  return hlist
end

function boxit( box )
  local box = node.hpack(box)

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
function new_image( filename, page, box)
  return imageinfo(filename,page,box)
end

-- Box is none, media, crop, bleed, trim, art
function imageinfo( filename,page,box )
  page = page or 1
  box = box or "crop"
  local new_name = filename .. tostring(page) .. tostring(box)

  if images[new_name] then
    return images[new_name]
  end

  if not kpse.filelist[filename] then
    err("Image %q not found!",filename or "???")
    filename = "filenotfound.pdf"
    page = 1
  end

  -- <?xml version="1.0" ?>
  -- <imageinfo>
  --    <cells_x>30</cells_x>
  --    <cells_y>21</cells_y>
  --    <segment x1='13' y1='0' x2='16' y2='0' />
  --    <segment x1='13' y1='1' x2='16' y2='1' />
  --    <segment x1='11' y1='2' x2='18' y2='2' />
  --    <segment x1='10' y1='3' x2='18' y2='3' />
  --    <segment x1='10' y1='4' x2='18' y2='4' />
  --    <segment x1='9' y1='5' x2='20' y2='5' />
  --    <segment x1='8' y1='6' x2='20' y2='6' />
  --    <segment x1='8' y1='7' x2='20' y2='7' />
  --    <segment x1='7' y1='8' x2='21' y2='8' />
  --    <segment x1='6' y1='9' x2='21' y2='9' />
  --    <segment x1='5' y1='10' x2='24' y2='10' />
  --    <segment x1='5' y1='11' x2='24' y2='11' />
  --    <segment x1='4' y1='12' x2='25' y2='12' />
  --    <segment x1='3' y1='13' x2='25' y2='13' />
  --    <segment x1='3' y1='14' x2='27' y2='14' />
  --    <segment x1='2' y1='15' x2='27' y2='15' />
  --    <segment x1='1' y1='16' x2='28' y2='16' />
  --  </imageinfo>
  local xmlfilename = string.gsub(filename,"(%..*)$",".xml")
  local mt
  if kpse.filelist[xmlfilename] then
    mt = {}
    local xmltab = load_xml(xmlfilename,"Imageinfo")
    local segments = {}
    local cells_x,cells_y
    for _,v in ipairs(xmltab) do
      if v[".__name"] == "cells_x" then
        cells_x = v[1]
      elseif v[".__name"] == "cells_y" then
        cells_y = v[1]
      elseif v[".__name"] == "segment" then
        -- 0 based segments
        segments[#segments + 1] = {v.x1 + 1,v.y1 + 1,v.x2 + 1,v.y2 + 1}
      end
    end
    -- we have parsed the file, let's build a beautiful 2dim array
    mt.max_x = cells_x
    mt.max_y = cells_y
    for i=1,cells_y do
      mt[i] = {}
      for j=1,cells_x do
        mt[i][j] = 0
      end
    end
    for i,v in ipairs(segments) do
      for x=v[1],v[3] do
        for y=v[2],v[4] do
          mt[y][x] = 1
        end
      end
    end
  end

  if not images[new_name] then
    local image_info = img.scan{filename = filename, pagebox = box, page=page }
    images[new_name] = { img = image_info, allocate = mt }
  end
  return images[new_name]
end

function set_color_if_necessary( nodelist,farbe )
  if not farbe then return nodelist end

  local farbname
  if farbe == -1 then
    farbname = "Schwarz"
  else
    farbname = colortable[farbe]
  end

  local colstart = node.new(8,39)
  colstart.data  = colors[farbname].pdfstring
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

function set_fontfamily_if_necessary(nodelist,fontfamilie)
  local fam
  while nodelist do
    if nodelist.id==0 or nodelist.id==1 then
      set_fontfamily_if_necessary(nodelist.list,fontfamilie)
    else
      fam = node.has_attribute(nodelist,att_fontfamily)
      if fam == 0 then
        node.set_attribute(nodelist,att_fontfamily,fontfamilie)
      end
    end
    nodelist=nodelist.next
  end
end

function set_sub_supscript( nodelist,script )
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

function colorbar( wd,ht,dp,farbe )
  local farbname = farbe or "Schwarz"
  if not colors[farbname] then
    err("Color %q not found",farbe)
    farbname = "Schwarz"
  end
  local rule_start = node.new("whatsit","pdf_colorstack")
  rule_start.stack = 1
  rule_start.data = colors[farbname].pdfstring
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

function rotate( nodelist,angle )
  local wd,ht = nodelist.width, nodelist.height + nodelist.depth
  nodelist.width = 0
  nodelist.height = 0
  nodelist.depth = 0
  local angle_rad = math.rad(angle)
  local sin = math.round(math.sin(angle_rad),3)
  local cos = math.round(math.cos(angle_rad),3)
  local q = node.new("whatsit","pdf_literal")
  q.mode = 0
  local shift_x = math.round(math.min(0,math.sin(angle_rad) * sp_to_bp(ht)) + math.min(0,     math.cos(angle_rad) * sp_to_bp(wd)),3)
  local shift_y = math.round(math.max(0,math.sin(angle_rad) * sp_to_bp(wd)) + math.max(0,-1 * math.cos(angle_rad) * sp_to_bp(ht)),3)
  q.data = string.format("q %g %g %g %g %g %g cm",cos,sin, -1 * sin,cos, -1 * shift_x ,-1 * shift_y )
  q.next = nodelist
  local tail = node.tail(nodelist)
  local Q = node.new("whatsit","pdf_literal")
  Q.data = "Q"
  tail.next = Q
  local tmp = node.vpack(q)
  tmp.width  = math.abs(wd * cos) + math.abs(ht * math.cos(math.rad(90 - angle)))
  tmp.height = math.abs(ht * math.sin(math.rad(90 - angle))) + math.abs(wd * sin)
  tmp.depth = 0
  return tmp
end

-- FIXME: document the data structure that is expected
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

--- The language name is something like `German` and needs to be mapped to an internal name.
--- 
function get_languagecode( language_name )
  local language_internal = language_mapping[language_name]
  if publisher.languages[language_internal] then
    return publisher.languages[language_internal]
  end
  local filename = string.format("hyph-%s.pat.txt",language_internal)
  log("Loading hyphenation patterns %q.",filename)
  local path = kpse.find_file(filename)
  local pattern_file = io.open(path)
  local pattern = pattern_file:read("*all")

  local l = lang.new()
  l:patterns(pattern)
  local id = l:id()
  log("Language id: %d",id)
  pattern_file:close()
  publisher.languages[language_internal] = id
  return id
end

function set_pageformat( wd,ht )
  options.pagewidth    = wd
  options.seitenhoehe  = ht
  tex.pdfpagewidth =  wd
  tex.pdfpageheight = ht
  -- why the + 2cm? is this for the trim-/art-/bleedbox? FIXME: document
  tex.pdfpagewidth  = tex.pdfpagewidth   + tex.sp("2cm")
  tex.pdfpageheight = tex.pdfpageheight  + tex.sp("2cm")

  -- necessary? FIXME: check if necessary.
  tex.hsize = wd
  tex.vsize = ht
end

function define_default_fontfamily()
  -- we assume that TeXGyreHeros is available. If not, !?!?
  local fam={
    size         = 10 * factor,
    baselineskip = 12 * factor,
    scriptsize   = 10 * factor * 0.8,
    scriptshift  = 10 * factor * 0.3,
  }
  local ok,tmp
  ok,tmp = fonts.erzeuge_fontinstanz("TeXGyreHeros-Regular",fam.size)
  fam.normal = tmp
  ok,tmp = fonts.erzeuge_fontinstanz("TeXGyreHeros-Regular",fam.scriptsize)
  fam.normalscript = tmp

  ok,tmp = fonts.erzeuge_fontinstanz("TeXGyreHeros-Bold",fam.size)
  fam.fett = tmp
  ok,tmp = fonts.erzeuge_fontinstanz("TeXGyreHeros-Bold",fam.scriptsize)
  fam.fettscript = tmp

  ok,tmp = fonts.erzeuge_fontinstanz("TeXGyreHeros-Italic",fam.size)
  fam.kursiv = tmp
  ok,tmp = fonts.erzeuge_fontinstanz("TeXGyreHeros-Italic",fam.scriptsize)
  fam.kursivscript = tmp

  ok,tmp = fonts.erzeuge_fontinstanz("TeXGyreHeros-BoldItalic",fam.size)
  fam.fettkursiv = tmp
  ok,tmp = fonts.erzeuge_fontinstanz("TeXGyreHeros-BoldItalic",fam.scriptsize)
  fam.fettkursivscript = tmp
  fonts.lookup_fontfamily_number_instance[#fonts.lookup_fontfamily_number_instance + 1] = fam
  fonts.lookup_fontfamily_name_number["text"]=#fonts.lookup_fontfamily_number_instance
end


------------------------------------------------------------------------------

Paragraph = {}
function Paragraph:new( textformat  )
  local instance = {
    nodelist,
    textformat = textformat,
  }
  -- if textformat and textformats[textformat] and textformats[textformat].indent then
  --   instance.nodelist = add_glue(nil,"head",{ width = textformats[textformat].indent })
  -- end
  setmetatable(instance, self)
  self.__index = self
  return instance
end

function Paragraph:add_italic_bold( nodelist,parameter )
  -- FIXME: rekursiv durchgehen, traverse bleibt an hlists hängen
  for i in node.traverse_id(glyph_node,nodelist) do
    if parameter.fett == 1 then
      node.set_attribute(i,att_bold,1)
    end
    if parameter.kursiv == 1 then
      node.set_attribute(i,att_italic,1)
    end
    if parameter.underline == 1 then
      node.set_attribute(i,att_underline,1)
    end
    if languagecodeuagecode then
      i.lang = languagecodeuagecode
    end
  end
end

function Paragraph:add_to_nodelist( new_nodes )
  if self.nodelist == nil then
    self.nodelist = new_nodes
  else
    local tail = node.tail(self.nodelist)
    tail.next = new_nodes
    new_nodes.prev = tail
  end
end

function Paragraph:set_color( farbe )
  if not farbe then return end

  local farbname
  if farbe == -1 then
    farbname = "Schwarz" 
  else
    farbname = colortable[farbe]
  end
  local colstart = node.new(8,39)
  colstart.data  = colors[farbname].pdfstring
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
-- function Paragraph:apply_textformat( textformat )
--   if not textformat or self.textformat then return self.nodelist end
--   if textformats[textformat] and textformats[textformat].indent then
--     self.nodelist = add_glue(self.nodelist,"head",{ width = textformats[textformat].indent })
--   end
--   return self.nodelist
-- end

-- Return the width of the longest word. FIXME: check for hypenation
function Paragraph:min_width()
  assert(self)
  local wd = 0
  local last_glue = self.nodelist
  local dimen
  -- Just measure the distance between two glue nodes and take the maximum of that
  for n in node.traverse_id(glue_node,self.nodelist) do
    dimen = node.dimensions(last_glue,n)
    wd = math.max(wd,dimen)
    last_glue = n
  end
  -- There are two cases here, either there is only one word (= no glue), then last_glue is at the beginning of the
  -- node list. Or we are at the last glue, then there is a word after that glue. last_glue is the last glue element.
  dimen = node.dimensions(last_glue,node.tail(n))
  wd = math.max(wd,dimen)
  return wd
end

function Paragraph:max_width()
  assert(self)
  local wd = node.dimensions(self.nodelist)
  return wd
end

function Paragraph:script( whatever,scr,parameter )
  local nl
  if type(whatever)=="string" or type(whatever)=="number" then
    nl = mknodes(whatever,parameter.schriftfamilie,parameter)
  else
    assert(false,string.format("superscript, type()=%s",type(whatever)))
  end
  set_sub_supscript(nl,scr)
  nl = node.hpack(nl)
  -- Beware! This width is still incorrect (it is the width of the mormal characters)
  -- Therefore we have to correct the width in pre_linebreak
  node.set_attribute(nl,att_script,scr)
  self:add_to_nodelist(nl)
end

function Paragraph:append( whatever,parameter )
  if type(whatever)=="string" or type(whatever)=="number" then
    self:add_to_nodelist(mknodes(whatever,parameter.schriftfamilie,parameter))
  elseif type(whatever)=="table" and whatever.nodelist then
    self:add_italic_bold(whatever.nodelist,parameter)
    self:add_to_nodelist(whatever.nodelist)
    set_fontfamily_if_necessary(whatever.nodelist,parameter.schriftfamilie)
  elseif type(whatever)=="function" then
    self:add_to_nodelist(mknodes(whatever(),parameter.schriftfamilie,parameter))
  elseif type(whatever)=="userdata" then -- node.is_node in einer späteren Version
    self:add_to_nodelist(whatever)
  elseif type(whatever)=="table" and not whatever.nodelist then
    self:add_to_nodelist(mknodes("",parameter.schriftfamilie,parameter))
  else
    if type(whatever)=="table" then printtable("Paragraph:append",whatever) end
    assert(false,string.format("Interner Fehler bei Paragraph:append, type(arg)=%s",type(whatever)))
  end
end

--- Turn a node list into a shaped block of text
function Paragraph:format(width_sp, default_textformat_name)
  local nodelist = node.copy_list(self.nodelist)
  local current_textformat_name,current_textformat
  if self.textformat then
    current_textformat_name = self.textformat
  else
    current_textformat_name = default_textformat_name
  end

  if textformats[current_textformat_name] then
    current_textformat = textformats[current_textformat_name]
  else
    current_textformat = textformats["text"]
  end

  fonts.pre_linebreak(nodelist)

  local parameter = {}

  if current_textformat.indent then
    parameter.hangindent = current_textformat.indent
    parameter.hangafter  = -current_textformat.rows
  end

  local ragged_shape
  if current_textformat then
    if current_textformat.alignment == "leftaligned" or current_textformat.alignment == "rightaligned" or current_textformat.alignment == "centered" then
      ragged_shape = true
    else
      ragged_shape = false
    end
  end

  -- If there is ragged shape (i.e. not a rectangle of text) then we should turn off
  -- font expansion. This is done by setting tex.pdfadjustspacing to 0 temporarily
  if ragged_shape then
    parameter.tolerance     = 5000
    parameter.hyphenpenalty = 200

    local adjspace = tex.pdfadjustspacing
    tex.pdfadjustspacing = 0
    nodelist = do_linebreak(nodelist,width_sp,parameter)
    tex.pdfadjustspacing = adjspace
    fix_justification(nodelist,current_textformat.alignment)
  else
    nodelist = do_linebreak(nodelist,width_sp,parameter)
  end
  return nodelist
end


file_end("publisher.lua")
