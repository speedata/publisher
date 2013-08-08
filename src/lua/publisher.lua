--- Here goes everything that does not belong anywhere else. Other parts are font handling, the command
--- list, page and gridsetup, debugging and initialization. We start with the function `dothings()` that
--- initializes some variables and starts processing (`dispatch())
--
--  publisher.lua
--  speedata publisher
--
--  Copyright 2010-2013 Patrick Gundlach.
--  See file COPYING in the root directory for license info.

file_start("publisher.lua")

barcodes = do_luafile("barcodes.lua")
local luxor = do_luafile("luxor.lua")
xpath = do_luafile("xpath.lua")

local commands     = require("publisher.commands")
local seite        = require("publisher.page")
local translations = require("translations")
local fontloader   = require("fonts.fontloader")
local paragraph    = require("paragraph")
local fonts        = require("publisher.fonts")



module(...,package.seeall)


do_luafile("layout_functions.lua")


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
att_indent         = 6 -- see textformats for details
att_rows           = 7 -- see textformats for details

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
att_is_table_row    = 500
att_tr_dynamic_data = 501


user_defined_addtolist = 1
user_defined_bookmark  = 2
user_defined_mark      = 3
user_defined_marker    = 4


glue_spec_node = node.id("glue_spec")
glue_node      = node.id("glue")
glyph_node     = node.id("glyph")
rule_node      = node.id("rule")
penalty_node   = node.id("penalty")
whatsit_node   = node.id("whatsit")
hlist_node     = node.id("hlist")
vlist_node     = node.id("vlist")

local t = node.whatsits()
for k,v in pairs(node.whatsits()) do
    if v == "user_defined" then
        user_defined_whatsit = k
    end
end

pdf_literal_node = node.subtype("pdf_literal")

publisher.alternating = {}

default_areaname = "__seite"

-- the language of the layout instructions ('en' or 'de')
current_layoutlanguage = nil

seiten   = {}

-- CSS properties. Use `:matches(tbl)` to find a matching rule. `tbl` has the following structure: `{element=..., id=..., class=... }`
css = do_luafile("css.lua"):new()

-- The defaults (set in the layout instructions file)
options = {
    gridwidth = tex.sp("10mm"),
    gridheight = tex.sp("10mm"),
}

-- List of virtual areas. Key is the group name and value is
-- a hash with keys contents (a nodelist) and raster (grid).
groups    = {}

-- sometimes we want to save pages for later reuse. Keys are pagestore names
pagestore = {}

colors    = { Schwarz = { model="grau", g = "0", pdfstring = " 0 G 0 g " }, black = { model="grau", g = "0", pdfstring = " 0 G 0 g " } }
colortable = {}
data_dispatcher = {}
user_defined_functions = { last = 0}
markers = {}

-- We will have to remember the current group and grid
current_group = nil
current_grid = nil


-- The array 'masterpages' has tables similar to these:
-- { is_pagetype = test, res = tab, name = pagetypename }
-- where `is_pagetype` is an xpath expression to be evaluated,
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

--- A table with key namespace prefix (`de` or `en`) and value namespace. Example:
---
---    {
---      [""] = "urn:speedata.de:2009/publisher/de"
---      sd = "urn:speedata:2009/publisher/functions/de"
---    }
namespaces_layout = nil

-- A very large length
maxdimen = 1073741823
--- The dispatch table maps every element in the layout xml to a command in the `commands.lua` file.
local dispatch_table = {
    A                       = commands.a,
    Action                  = commands.action,
    AddToList               = commands.add_to_list,
    AtPageCreation          = commands.atpagecreation,
    AtPageShipout           = commands.atpageshipout,
    Attribute               = commands.attribute,
    B                       = commands.bold,
    Barcode                 = commands.barcode,
    Bookmark                = commands.bookmark,
    Box                     = commands.box,
    Br                      = commands.br,
    Column                  = commands.column,
    Columns                 = commands.columns,
    ["Copy-of"]             = commands.copy_of,
    DefineColor             = commands.define_color,
    DefineFontfamily        = commands.define_fontfamily,
    DefineTextformat        = commands.define_textformat,
    Element                 = commands.element,
    EmptyLine               = commands.emptyline,
    Fontface                = commands.fontface,
    ForAll                  = commands.forall,
    Grid                    = commands.grid,
    Group                   = commands.group,
    HSpace                  = commands.hspace,
    Hyphenation             = commands.hyphenation,
    I                       = commands.italic,
    Image                   = commands.image,
    Include                 = commands.include,
    InsertPages             = commands.insert_pages,
    Li                      = commands.li,
    LoadDataset             = commands.load_dataset,
    LoadFontfile            = commands.load_fontfile,
    Loop                    = commands.loop,
    Margin                  = commands.margin,
    Mark                    = commands.mark,
    Message                 = commands.message,
    NewPage                 = commands.new_page,
    NextFrame               = commands.next_frame,
    NextRow                 = commands.next_row,
    Ol                      = commands.ol,
    Options                 = commands.options,
    Output                  = commands.output,
    Pageformat              = commands.page_format,
    Pagetype                = commands.pagetype,
    Paragraph               = commands.paragraph,
    PlaceObject             = commands.place_object,
    PositioningArea         = commands.positioning_area,
    PositioningFrame        = commands.positioning_frame,
    ProcessNode             = commands.process_node,
    ProcessRecord           = commands.process_record,
    Record                  = commands.record,
    Rule                    = commands.rule,
    SaveDataset             = commands.save_dataset,
    SavePages               = commands.save_pages,
    Sequence                = commands.sequence,
    SetGrid                 = commands.set_grid,
    SetVariable             = commands.setvariable,
    SortSequence            = commands.sort_sequence,
    Stylesheet              = commands.stylesheet,
    Sub                     = commands.sub,
    Sup                     = commands.sup,
    Switch                  = commands.switch,
    Table                   = commands.table,
    Tablefoot               = commands.tablefoot,
    Tablehead               = commands.tablehead,
    Tablerule               = commands.tablerule,
    Td                      = commands.td,
    Textblock               = commands.textblock,
    Text                    = commands.text,
    Tr                      = commands.tr,
    U                       = commands.underline,
    Ul                      = commands.ul,
    URL                     = commands.url,
    Value                   = commands.value,
    Variable                = commands.variable,
    While                   = commands.while_do,
}

--- Return the element name as an english string. The argument is in the
--- current language of the layout file (currently English and German).
function translate_element( eltname )
    return translations[current_layoutlanguage].elements[eltname]
end

--- Return the value as an english string. The argument is in the
--- current language of the layout file (currently English and German).
--- All translations are only valid in a context which defaults to the
--- _global_ context.
function translate_value( value,context )
    context = context or "*"
    local tmp = translations[current_layoutlanguage].values[context][value]
    return tmp
end

--- Return the attribute name as an english string. The argument is in the
--- current language of the layout file (currently English and German).
function translate_attribute( attname )
    return translations.attributes[attname][current_layoutlanguage]
end

--- The returned table is an array with hashes. The keys of these
--- hashes are `elementname` and `contents`. For example:
---    {
---      [1] = {
---        ["elementname"] = "Paragraph"
---        ["contents"] = {
---          ["nodelist"] = "<node    nil <  58515 >    nil : glyph 1>"
---        },
---      },
---    },
function dispatch(layoutxml,dataxml,optionen)
    local ret = {}
    local tmp
    for _,j in ipairs(layoutxml) do
        -- j a table, if it is an element in layoutxml
        if type(j)=="table" then
            local eltname = translate_element(j[".__local_name"])
            if dispatch_table[eltname] ~= nil then
                tmp = dispatch_table[eltname](j,dataxml,optionen)

                -- Copy-of-elements can be resolveld immediately
                if eltname == "Copy-of" or eltname == "Switch" or eltname == "ForAll" or eltname == "Loop" then
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

--- Convert the argument `str` (in UTF-8) to a string suitable for writing into the PDF file. The returned string starts with `<feff` and ends with `>`
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

--- Start the processing (`dothings()`)
--- -------------------------------
--- This is the entry point of the processing. It is called from `spinit.lua`/`main_loop()`.
function dothings()
    page_initialized=false

    --- First we set some defaults.
    --- A4 paper is 210x297 mm
    set_pageformat(tex.sp("210mm"),tex.sp("297mm"))

    --- The free font family `TeXGyreHeros` is a Helvetica clone and is part of the
    --- [The TeX Gyre Collection of Fonts](http://www.gust.org.pl/projects/e-foundry/tex-gyre).
    --- We ship it in the distribution.
    fonts.load_fontfile("TeXGyreHeros-Regular",   "texgyreheros-regular.otf")
    fonts.load_fontfile("TeXGyreHeros-Bold",      "texgyreheros-bold.otf")
    fonts.load_fontfile("TeXGyreHeros-Italic",    "texgyreheros-italic.otf")
    fonts.load_fontfile("TeXGyreHeros-BoldItalic","texgyreheros-bolditalic.otf")
    --- Define a basic font family with name `text`:
    define_default_fontfamily()

    --- The default page type has 1cm margin
    local onecm=tex.sp("1cm")
    masterpages[1] = { is_pagetype = "true()", res = { {elementname = "Margin", contents = function(_page) _page.grid:set_margin(onecm,onecm,onecm,onecm) end }}, name = "Seite",ns={[""] = "urn:speedata.de:2009/publisher/en" } }

    --- Both the data and the layout instructions are written in XML.
    local layoutxml = load_xml(arg[2],"layout instructions")
    if not layoutxml then
        err("Without a valid layout-XML file, I can't really do anything.")
        exit()
    end
    -- We allow the use of a dummy xml file for testing purpose
    local dataxml
    if arg[3] == "-dummy" then
        dataxml = luxor.parse_xml("<data />")
    elseif arg[3] == "-" then
        log("Reading from stdin")
        dataxml = luxor.parse_xml(io.stdin:read("*a"),{htmlentities = true})
    else
        dataxml = load_xml(arg[3],"data file")
    end
    if type(dataxml) ~= "table" then
        err("Something is wrong with the data: dataxml is not a table")
        exit()
    end

    --- The `vars` file hold a lua document holding table
    local vars = loadfile(tex.jobname .. ".vars")()
    for k,v in pairs(vars) do
        xpath.set_variable(k,v)
    end

    --- Used in `xpath.lua` to find out which language the function is in.
    local ns = layoutxml[".__namespace"]

    --- The currently active layout language. One of `de` or `en`.
    current_layoutlanguage = string.gsub(ns,"urn:speedata.de:2009/publisher/","")
    if not (current_layoutlanguage=='de' or current_layoutlanguage=='en') then
        err("Cannot determine the language of the layout file.")
        exit()
    end

    if layoutxml.version then
        local version_mismatch = false
        local publisher_version = string.explode(os.getenv("PUBLISHERVERSION"),".")
        local requested_version = string.explode(layoutxml.version,".")
        if publisher_version[1] ~= requested_version[1] then
            version_mismatch = true
        elseif publisher_version[2] ~= requested_version[2] then
            version_mismatch = true
        elseif requested_version[3] and publisher_version[3] < requested_version[3] then
            version_mismatch = true
        end
        if version_mismatch then
            err("Version mismatch. speedata Publisher is at version %s, requested version %s", os.getenv("PUBLISHERVERSION"), layoutxml.version)
            exit()
        end
    end
    dispatch(layoutxml)

    --- override options set in the `<Options>` element
    if arg[4] then
        for _,extopt in ipairs(string.explode(arg[4],",")) do
            if string.len(extopt) > 0 then
                local k,v = extopt:match("^(.+)=(.+)$")
                v = v:gsub("^\"(.*)\"$","%1")
                options[k]=v
            end
        end
    end
    if options.showgrid == "false" then
        options.showgrid = false
    elseif options.showgrid == "true" then
        options.showgrid = true
    end

    if options.showgridallocation == "false" then
        options.showgridallocation = false
    elseif options.showgridallocation == "true" then
        options.showgridallocation = true
    end

    --- Set the starting page (which must be a number)
    if options.startpage then
        local num = options.startpage
        if num then
            tex.count[0] = num - 1
            log("Set page number to %d",num)
        else
            err("Can't recognize starting page number %q",options.startpage)
        end
    end

    --- Start data processing in the default mode (`""`)
    local tmp
    local name = dataxml[".__local_name"]
    --- The rare case that the user has not any `Record` commands in the layout file:
    if not data_dispatcher[""] then
        err("Can't find »Record« command for the root node.")
        exit()
    end
    tmp = data_dispatcher[""][name]
    if tmp then publisher.dispatch(tmp,dataxml) end


    --- emit last page if necessary
    -- current_pagestore_name is set when in SavePages and nil otherwise
    if page_initialized and current_pagestore_name == nil then
        dothingsbeforeoutput()
        local n = node.vpack(publisher.global_pagebox)

        tex.box[666] = n
        tex.shipout(666)
    end

    --- At this point, all pages are in the PDF
    pdf.catalog = [[ /PageMode /UseOutlines ]]
    pdf.info    = [[ /Creator	(speedata Publisher) /Producer(speedata Publisher, www.speedata.de) ]]

    --- Now put the bookmarks in the pdf
    for _,v in ipairs(bookmarks) do
        bookmarkstotex(v)
    end

end

--- Load an XML file from the harddrive. filename is without path but including extension,
--- filetype is a string representing the type of file read, such as "layout" or "data".
--- The return value is a lua table representing the XML file.
---
--- The XML file
---
---     <?xml version="1.0" encoding="UTF-8"?>
---     <data>
---       <element attribute="whatever">
---         <subelement>text in subelement</subelement>
---       </element>
---     </data>
---
--- is represented by this Lua table:
---     XML = {
---       [1] = " "
---       [2] = {
---         [1] = " "
---         [2] = {
---           [1] = "text in subelement"
---           [".__parent"] = (pointer to the "element" tree, which is the second entry in the top level)
---           [".__local_name"] = "subelement"
---         },
---         [3] = " "
---         [".__parent"] = (pointer to the root element)
---         [".__local_name"] = "element"
---         ["attribute"] = "whatever"
---       },
---       [3] = " "
---       [".__local_name"] = "data"
---     },
function load_xml(filename,filetype)
    local path = kpse.find_file(filename)
    if not path then
        err("Can't find XML file %q. Abort.\n",filename or "?")
        os.exit(-1)
    end
    log("Loading %s %q",filetype or "file",path)
    return luxor.parse_xml_file(path, { htmlentities = true })
end

--- Place an object at a position given in scaled points (_x_ and _y_). `allocate` is ignored at at the moment.
function output_absolute_position( nodelist,x,y,allocate,area )

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

--- Put the object (nodelist) on grid cell (x,y). If `allocate`=`true` then
--- mark cells as occupied.
function output_at( nodelist, x,y,allocate,area,valign,allocate_matrix)
    area = area or default_areaname
    local r = current_grid
    local wd = nodelist.width
    local ht = nodelist.height + nodelist.depth
    local width_gridcells = r:width_in_gridcells_sp(wd)
    local height_gridcells  = r:height_in_gridcells_sp (ht)

    local delta_x, delta_y = r:position_grid_cell(x,y,area,wd,ht,valign)
    if not delta_x then
        err(delta_y)
        exit()
    end

    if node.has_attribute(nodelist,att_shift_left) then
        delta_x = delta_x - node.has_attribute(nodelist,att_shift_left)
        delta_y = delta_y - node.has_attribute(nodelist,att_shift_up)
    end

    --- We don't necessarily ouput things on a page, we can output them in a virtual page, called _group_.
    if current_group then
        -- Put the contents of the nodelist into the current group
        local group = groups[current_group]
        assert(group)

        local n = add_glue( nodelist ,"head",{ width = delta_x })
        n = node.hpack(n)
        n = add_glue(n, "head", {width = delta_y})
        n = node.vpack(n)

        if group.contents then
            -- There is already something in the group, we must add the new nodelist.
            -- The size of the new group: max(size of old group, size of new nodelist)
            local new_width, new_height
            new_width  = math.max(n.width, group.contents.width)
            new_height = math.max(n.height + n.depth, group.contents.height + group.contents.depth)

            group.contents.width  = 0
            group.contents.height = 0
            group.contents.depth  = 0

            local tail = node.tail(group.contents)
            tail.next = n
            n.prev = tail

            group.contents = node.vpack(group.contents)
            group.contents.width  = new_width
            group.contents.height = new_height
            group.contents.depth  = 0
        else
            -- group is empty
            group.contents = n
        end
        if allocate then
            r:allocate_cells(x,y,width_gridcells,height_gridcells,allocate_matrix)
        end
    else
        -- Put it on the current page
        if allocate then
            r:allocate_cells(x,y,width_gridcells,height_gridcells,allocate_matrix,area)
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

--- Return the XML structure that is stored at &lt;pagetype>. For every pagetype
--- in the table "masterpages" the function is_pagetype() gets called-
function detect_pagetype()
    local ret = nil
    for i=#masterpages,1,-1 do
        local seitentyp = masterpages[i]
        if xpath.parse(nil,seitentyp.is_pagetype,seitentyp.ns) == true then
            log("Page of type %q created",seitentyp.name or "<detect_pagetype>")
            ret = seitentyp.res
            return ret
        end
    end
    err("Can't find correct page type!")
    return false
end

--- _Must_ be called before something can be put on the page. Looks for hooks to be run before page creation.
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
        err("Can't create a new page. Is the page type (»PageType«) defined? %s",errorstring)
        exit()
    end
    current_grid = current_page.grid
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
    current_page.grid:set_width_height(gridwidth,gridheight)

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
            current_grid.positioning_frames[name] = {}
            local current_positioning_area = current_grid.positioning_frames[name]
            -- we evaluate now, because the attributes in PositioningFrame can be page dependent.
            local tab  = publisher.dispatch(element_contents(j).layoutxml,dataxml)
            for i,k in ipairs(tab) do
                current_positioning_area[#current_positioning_area + 1] = element_contents(k)
            end
        else
            err("Element name %q unknown (setup_page())",eltname or "<create_page>")
        end
    end


    if current_page.atpagecreation then
        publisher.dispatch(current_page.atpagecreation,nil)
    end
end

--- Switch to the next frame in the given are.
function next_area( areaname )
    local current_framenumber = current_grid:framenumber(areaname)
    if not current_framenumber then
        err("Cannot determine current area number (areaname=%q)",areaname or "(undefined)")
        return
    end
    if current_framenumber >= current_grid:number_of_frames(areaname) then
        new_page()
    else
        current_grid:set_framenumber(areaname, current_framenumber + 1)
    end
    current_grid:set_current_row(1,areaname)
end

--- Switch to a new page and shipout the current page.
--- This new page is only created if something is typeset on it.
function new_page()
    if pagebreak_impossible then
        return
    end
    if not current_page then
        -- new_page() is called without anything on the page yet
        page_initialized=false
        setup_page()
    end
    if current_page.AtPageShipout then
        pagebreak_impossible = true
        dispatch(current_page.AtPageShipout)
        pagebreak_impossible = false
    end
    page_initialized=false
    dothingsbeforeoutput()
    current_page = nil

    local n = node.vpack(publisher.global_pagebox)
    if current_pagestore_name then
        local thispagestore = pagestore[current_pagestore_name]
        thispagestore[#thispagestore + 1] = n
    else
        tex.box[666] = n
        tex.shipout(666)
    end
end

--- Draw a background behind the rectangular (box) object.
function background( box, colorname )
    if not colors[colorname] then
        warning("Background: Color %q is not defined",colorname)
        return box
    end
    local pdfcolorstring = colors[colorname].pdfstring
    local wd, ht, dp = sp_to_bp(box.width),sp_to_bp(box.height),sp_to_bp(box.depth)
    n = node.new(whatsit_node,pdf_literal_node)
    n.data = string.format("q %s 0 -%g %g %g re f Q",pdfcolorstring,dp,wd,ht + dp)
    n.mode = 0
    if node.type(box.id) == "hlist" then
        -- pdfliteral does not use up any space, so we can add it to the already packed box.
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

--- Draw a frame around the given TeX box with color `colorname`.
function frame( box, colorname, width )
    local pdfcolorstring = colors[colorname].pdfstring
    local wd, ht, dp = sp_to_bp(box.width),sp_to_bp(box.height),sp_to_bp(box.depth)
    local w = width / factor -- width of stroke
    local hw = 0.5 * w -- half width of stroke
    n = node.new(whatsit_node,pdf_literal_node)
    n.data = string.format("q %s %g w -%g -%g %g %g re S Q",pdfcolorstring, w , hw ,dp + hw ,wd + w,ht + dp + w)
    n.mode = 0
    n.next = box
    box.prev = n
    n = node.hpack(n)
    return n
end

--- Create a colored area. width and height are in dtp points.
function box( width,height,colorname )
    local n = node.new(whatsit_node,pdf_literal_node)
    n.data = string.format("q %s 1 0 0 1 0 0 cm 0 0 %g -%g re f Q",colors[colorname].pdfstring,width,height)
    n.mode = 0
    return n
end

--- After everything is ready for page shipout, we add debug output and crop marks if necessary
function dothingsbeforeoutput(  )
    local r = current_page.grid
    local str
    find_user_defined_whatsits(publisher.global_pagebox)
    local firstbox

    -- White background on page. Todo: Make color customizable and background optional.
    local wd = sp_to_bp(current_page.width)
    local ht = sp_to_bp(current_page.height)

    local x = 0 + current_page.grid.extra_margin
    local y = 0 + current_page.grid.extra_margin + current_page.grid.margin_top

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

    if options.showgrid then
        local lit = node.new("whatsit","pdf_literal")
        lit.mode = 1
        lit.data = r:draw_grid()
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
        lit.data = r:cutmarks()
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

--- Read the contents of the attribute `attname_english.` `typ` is one of
--- `string`, `number`, `length` and `boolean`.
--- `default` gives something that is to be returned if no attribute with this name is present.
function read_attribute( layoutxml,dataxml,attname_english,typ,default,context)
    local namespaces = layoutxml[".__ns"]
    local attname = translate_attribute(attname_english)

    if not layoutxml[attname] then
        return default -- can be nil
    end

    local val,num,ret
    local xpathstring = string.match(layoutxml[attname],"{(.-)}")
    if xpathstring then
        local ok, xp = xpath.parse_raw(dataxml,xpathstring,namespaces)
        if not ok then
            err(xp)
            return nil
        end
        val = xpath.textvalue(xp[1])
    else
        val = layoutxml[attname]
    end

    if typ=="xpath" then
        return xpath.textvalue(xpath.parse(dataxml,val,namespaces))
    elseif typ=="xpathraw" then
        local ok,tmp = xpath.parse_raw(dataxml,val,namespaces)
        if not ok then err(tmp)
            return nil
        else
            return tmp
        end
    elseif typ=="rawstring" then
        return tostring(val)
    elseif typ=="string" then
        return tostring(translate_value(val,context) or default)
    elseif typ=="number" then
        return tonumber(val)
        -- something like "3pt"
    elseif typ=="length" then
        return val
        -- same as before, just changed to scaled points
    elseif typ=="length_sp" then
        num = tonumber(val or default)
        if num then -- most likely really a number, we need to multiply with grid width
            ret = current_grid.gridwidth * num
        else
            ret = val
        end
        return tex.sp(ret)
    elseif typ=="height_sp" then
        num = tonumber(val or default)
        if num then -- most likely really a number, we need to multiply with grid height
            ret = current_page.grid.gridheight * num
        else
            ret = val
        end
        return tex.sp(ret)
    elseif typ=="boolean" then
        if val then
            val = translate_value(val,context)
        else
            val = default
        end
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

--- Return the contents of an entry from the `dispatch()` function call.
function element_contents( elt )
    return elt.contents
end

-- To split the textblock in pieces
local marker
marker = node.new("whatsit","user_defined")
marker.user_id = user_defined_marker
marker.type = 100  -- type 100: "value is a number"
marker.value = 1

--- Convert `<b>`, `<u>` and `<i>` in text to publisher recognized elements.
function parse_html( elt, parameter )
    local a = paragraph:new()
    local bold,italic,underline
    if parameter then
        if parameter.underline then
            underline = 1
        end
        if parameter.bold then
            bold = 1
        end
        if parameter.italic then
            italic = 1
        end
    end

    if elt[".__local_name"] then
        local eltname = string.lower(elt[".__local_name"])
        if eltname == "b" then
            bold = 1
        elseif eltname == "i" then
            italic = 1
        elseif eltname == "u" then
            underline = 1
        elseif eltname == "ul" then
            for i=1,#elt do
                if type(elt[i]) == "string" then
                    -- ignore
                elseif type(elt[i]) == "table" then
                    a:append(node.copy(marker))
                    local bul = bullet_hbox(tex.sp("5mm"))
                    a:append(bul)
                    a:append(parse_html(elt[i]),{fontfamily = 0, bold = bold, italic = italic, underline = underline})
                    a:append("\n",{})
                end
            end
            a:append(node.copy(marker))
            return a
        elseif eltname == "ol" then
            local counter = 0
            for i=1,#elt do
                if type(elt[i]) == "string" then
                    -- ignore
                elseif type(elt[i]) == "table" then
                    counter = counter + 1
                    a:append(node.copy(marker))
                    local num = number_hbox(counter,tex.sp("5mm"))
                    a:append(num)
                    a:append(parse_html(elt[i]),{fontfamily = 0, bold = bold, italic = italic, underline = underline})
                    a:append("\n",{})
                end
            end
            a:append(node.copy(marker))
            return a
        elseif eltname == "a" then
            local ai = node.new("action")
            ai.action_type = 3
            ai.data = string.format("/Subtype/Link/A<</Type/Action/S/URI/URI(%s)>>",elt.href)
            local stl = node.new("whatsit","pdf_start_link")
            stl.action = ai
            stl.width = -1073741824
            stl.height = -1073741824
            stl.depth = -1073741824
            a:append(stl)
            for i=1,#elt do
                if type(elt[i]) == "string" then
                    a:append(elt[i],{fontfamily = 0, bold = bold, italic = italic, underline = underline })
                elseif type(elt[i]) == "table" then
                    a:append(parse_html(elt[i]),{fontfamily = 0, bold = bold, italic = italic, underline = underline})
                end
            end
            local enl = node.new("whatsit","pdf_end_link")
            a:append(enl)
            return a
        elseif string.match(eltname,"^[bB][rR]$") then
            a:append("\n",{})
        end
    end

    for i=1,#elt do
        local typ = type(elt[i])
        if  typ == "string" or typ == "number" or typ == "boolean" then
            a:append(elt[i],{fontfamily = 0, bold = bold, italic = italic, underline = underline })
        elseif typ == "table" then
            a:append(parse_html(elt[i]),{fontfamily = 0, bold = bold, italic = italic, underline = underline})
        end
    end

    return a
end


--- Look for `user_defined` at end of page (shipout) and runs actions encoded in them.
function find_user_defined_whatsits( head )
    local fun
    while head do
        if head.id == vlist_node or head.id==hlist_node then
            find_user_defined_whatsits(head.list)
        elseif head.id==whatsit_node then
            if head.subtype == user_defined_whatsit then
                -- action
                if head.user_id == user_defined_addtolist then
                    -- the value is the index of the hash of user_defined_functions
                    fun = user_defined_functions[head.value]
                    fun()
                    -- use and forget
                    user_defined_functions[head.value] = nil
                    -- bookmark
                elseif head.user_id == user_defined_bookmark then
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
                elseif head.user_id == user_defined_mark then
                    local marker = head.value
                    publisher.markers[marker] = { page = tex.count[0] }
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

--- Create a `\hbox`. Return a nodelist. Parameter is one of
---
--- * languagecode
--- * bold (bold)
--- * italic (italic)
--- * underline
function mknodes(str,fontfamily,parameter)
    -- instance is the internal fontnumber
    local instance
    local instancename
    local languagecode = parameter.languagecode or 0
    if parameter.bold == 1 then
        if parameter.italic == 1 then
            instancename = "bolditalic"
        else
            instancename = "bold"
        end
    elseif parameter.italic == 1 then
        instancename = "italic"
    else
        instancename = "normal"
    end

    if fontfamily and fontfamily > 0 then
        instance = fonts.lookup_fontfamily_number_instance[fontfamily][instancename]
    else
        instance = 1
    end

    local tbl = font.getfont(instance)
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
        n.font = instance
        n.subtype = 1
        n.char = s
        if languagecode then
            n.lang = languagecode
        else
            n.lang = 0
        end

        node.set_attribute(n,att_fontfamily,fontfamily)
        return n
    end
    -- There is a string with utf8 chars
    for s in string.utfvalues(str) do
        local char = unicode.utf8.char(s)
        -- If the next char is a newline (&amp;#x0A;) a \\ is inserted
        if s == 10 then
            local strut
            strut = add_rule(nil,"head",{height = 8 * publisher.factor, depth = 3 * publisher.factor, width = 0 })
            head,last = node.insert_after(head,last,strut)

            local p1,g,p2
            p1 = node.new(penalty_node)
            p1.penalty = 10000

            g = node.new(glue_node)
            g.spec = node.new(glue_spec_node)
            g.spec.stretch = 2^16
            g.spec.stretch_order = 2

            p2 = node.new(penalty_node)
            p2.penalty = -10000

            head,last = node.insert_after(head,last,p1)
            head,last = node.insert_after(head,last,g)
            head,last = node.insert_after(head,last,p2)

        elseif match(char,"%s") and last and last.id == glue_node and not node.has_attribute(last,att_tie_glue,1) then
            -- double space, don't do anything
        elseif s == 160 then -- non breaking space U+00A0
            n = node.new(penalty_node)
            n.penalty = 10000

            head,last = node.insert_after(head,last,n)

            n = node.new(glue_node)
            n.spec = node.new(glue_spec_node)
            n.spec.width   = space
            n.spec.shrink  = shrink
            n.spec.stretch = stretch

            node.set_attribute(n,att_tie_glue,1)

            head,last = node.insert_after(head,last,n)

            if parameter.underline == 1 then
                node.set_attribute(n,att_underline,1)
            end
            node.set_attribute(n,att_fontfamily,fontfamily)


        elseif match(char,"%s") then -- Space
            -- ; and : should have the posibility to break easily if a space follows
            if last and last.id == 37 and ( last.char == 58 or last.char == 59) then
                n = node.new(penalty_node)
                n.penalty = 0
                head,last = node.insert_after(head,last,n)
            end
            n = node.new(glue_node)
            n.spec = node.new(glue_spec_node)
            n.spec.width   = space
            n.spec.shrink  = shrink
            n.spec.stretch = stretch

            if parameter.underline == 1 then
                node.set_attribute(n,att_underline,1)
            end
            node.set_attribute(n,att_fontfamily,fontfamily)

            head,last = node.insert_after(head,last,n)
        else
            -- A regular character?!?
            n = node.new(glyph_node)
            n.font = instance
            n.subtype = 1
            n.char = s
            n.lang = languagecode
            n.uchyph = 1
            n.left = tex.lefthyphenmin
            n.right = tex.righthyphenmin
            node.set_attribute(n,att_fontfamily,fontfamily)
            if parameter.bold == 1 then
                node.set_attribute(n,att_bold,1)
            end
            if parameter.italic == 1 then
                node.set_attribute(n,att_italic,1)
            end
            if parameter.underline == 1 then
                node.set_attribute(n,att_underline,1)
            end
            local lastitemwasglyph
            if last and last.id == 37 then
                lastitemwasglyph = true
            end
            head,last = node.insert_after(head,last,n)
            -- We have a character but some characters must be treated in a special
            -- way.
            -- Hyphens must be sepearated from words:
            if n.char == 45 and lastitemwasglyph then
                local pen = node.new("penalty")
                pen.penalty = 10000

                head = node.insert_before(head,last,pen)

                local glue = node.new("glue")
                glue.spec = node.new("glue_spec")
                glue.spec.width = 0
                if parameter.underline == 1 then
                    node.set_attribute(glue,att_underline,1)
                end
                head,last = node.insert_after(head,last,glue)
                node.set_attribute(glue,att_tie_glue,1)
            end
        end
    end

    if not head then
        -- This should never happen.
        warning("No head found")
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

--- Return a hbox with width `labelwidth`
function bullet_hbox( labelwidth )
    local bullet, pre_glue, post_glue
    bullet = mknodes("•",nil,{})

    pre_glue = node.new("glue")
    pre_glue.spec = node.new("glue_spec")
    pre_glue.spec.stretch = 65536
    pre_glue.spec.stretch_order = 3
    pre_glue.next = bullet

    post_glue = node.new("glue")
    post_glue.spec = node.new("glue_spec")
    post_glue.spec.width = 4 * 2^16
    post_glue.prev = bullet
    bullet.next = post_glue
    local bullet_hbox = node.hpack(pre_glue,labelwidth,"exactly")

    if options.trace then
        boxit(bullet_hbox)
    end
    node.set_attribute(bullet_hbox,att_indent,labelwidth)
    node.set_attribute(bullet_hbox,att_rows,-1)
    return bullet_hbox
end

--- Return a hbox with width `labelwidth`
function number_hbox( num, labelwidth )
    local pre_glue, post_glue
    local digits = mknodes( tostring(num) .. ".",nil,{})
    pre_glue = node.new("glue")
    pre_glue.spec = node.new("glue_spec")
    pre_glue.spec.stretch = 65536
    pre_glue.spec.stretch_order = 3
    pre_glue.next = digits

    post_glue = node.new("glue")
    post_glue.spec = node.new("glue_spec")
    post_glue.spec.width = 4 * 2^16
    post_glue.prev = node.tail(digits)
    node.tail(digits).next = post_glue
    local digit_hbox = node.hpack(pre_glue,labelwidth,"exactly")

    if options.trace then
        boxit(digit_hbox)
    end
    node.set_attribute(digit_hbox,att_indent,labelwidth)
    node.set_attribute(digit_hbox,att_rows,-1)
    return digit_hbox
end


-- Add a glue to the front or tail of the given nodelist. `head_or_tail` is
-- either the string `head` or `tail`. `parameter` is a table with the keys
-- `width`, `stretch` and `stretch_order`. If the nodelist is nil, a simple
-- node list consisting of a glue will be created.
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
            -- altered glue_spec node on copy_list (in paragraph:format())
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
                -- compound words such as "mailing-[glue]list" and that glue's width is 0pt
                if n.subtype==0 and font_before_glue and n.spec.width > 0 and head.glue_sign == 1 then
                    local fonttable = font.fonts[font_before_glue]
                    if not fonttable then fonttable = font.fonts[1] err("Some font not found") end
                    spec_new = node.new("glue_spec")
                    spec_new.width = fonttable.parameters.space
                    spec_new.shrink_order = head.glue_order
                    n.spec = spec_new
                end
            end

            if textformat == "rightaligned" then

                local list_start = head.head
                local rightskip_node = node.tail(head.head)
                local parfillskip

                -- first we remove everything between the rightskip and the
                -- last non-glue/non-penalty item
                -- the glues might contain "plus 1 fill" and the penalties are not
                -- useful
                local tmp = rightskip_node.prev
                while tmp and ( tmp.id == glue_node or tmp.id == penalty_node ) do
                    tmp = tmp.prev
                    head.head = node.remove(head.head,tmp.next)
                end

                local wd = node.dimensions(head.glue_set, head.glue_sign, head.glue_order,head.head)

                local leftskip_node = node.new("glue")
                leftskip_node.spec = node.new("glue_spec")
                leftskip_node.spec.width = goal - wd
                head.head = node.insert_before(head.head,head.head,leftskip_node)
            end

            if textformat == "centered" then
                local list_start = head.head
                local rightskip_node = node.tail(head.head)
                local parfillskip

                -- first we remove everything between the rightskip and the
                -- last non-glue/non-penalty item
                -- the glues might contain "plus 1 fill" and the penalties are not
                -- useful
                local tmp = rightskip_node.prev
                while tmp and ( tmp.id == glue_node or tmp.id == penalty_node ) do
                    tmp = tmp.prev
                    head.head = node.remove(head.head,tmp.next)
                end

                local wd = node.dimensions(head.glue_set, head.glue_sign, head.glue_order,head.head)

                local leftskip_node = node.new("glue")
                leftskip_node.spec = node.new("glue_spec")
                leftskip_node.spec.width = ( goal - wd ) / 2
                head.head = node.insert_before(head.head,head.head,leftskip_node)
            end
        elseif head.id == 1 then -- vlist
            fix_justification(head.head,textformat,head)
        end
        head = head.next
    end
    return nodelist
end

function do_linebreak( nodelist,hsize,parameters )
    assert(nodelist,"No nodelist found for line breaking.")
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

    -- Adjust line heights. Always take the largest font in a row.
    local head = j
    local maxskip
    while head do
        if head.id == 0 then -- hlist
            maxskip = 0
            local head_list = head.list
            while head_list do
                local fam = node.has_attribute(head_list,att_fontfamily)
                if fam then
                    -- Is this necessary anymore? FIXME
                    if fam == 0 then fam = 1 end
                    maxskip = math.max(fonts.lookup_fontfamily_number_instance[fam].baselineskip,maxskip)
                end
                head_list = head_list.next
            end
            head.height = 0.75 * maxskip
            head.depth  = 0.25 * maxskip
        end
        head = head.next
    end

    return node.vpack(j)
end

function create_empty_hbox_with_width( wd )
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
    udw.user_id = user_defined_bookmark
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
    -- Draw box at the end so its contents gets "below" it.
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

    if not find_file_location(filename) then
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
            if v[".__local_name"] == "cells_x" then
                cells_x = v[1]
            elseif v[".__local_name"] == "cells_y" then
                cells_y = v[1]
            elseif v[".__local_name"] == "segment" then
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

function set_color_if_necessary( nodelist,color )
    if not color then return nodelist end

    local colorname
    if color == -1 then
        colorname = "Schwarz"
    else
        colorname = colortable[color]
    end

    local colstart = node.new(8,39)
    colstart.data  = colors[colorname].pdfstring
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

function set_fontfamily_if_necessary(nodelist,fontfamily)
    -- todo: test this FIXME
    -- if fontfamily == 0 then return end
    local fam
    while nodelist do
        if nodelist.id==0 or nodelist.id==1 then
            set_fontfamily_if_necessary(nodelist.list,fontfamily)
        else
            fam = node.has_attribute(nodelist,att_fontfamily)
            if fam == 0 or ( fam == nil and nodelist.id == 2) then
                node.set_attribute(nodelist,att_fontfamily,fontfamily)
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

function break_url( nodelist )
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
    local colorname = farbe
    if not colorname or colorname == "" then
        colorname = "Schwarz"
    end
    if not colors[colorname] then
        err("Color %q not found",farbe)
        colorname = "Schwarz"
    end

    local rule_start = node.new("whatsit","pdf_literal")
    rule_start.mode = 1
    rule_start.data = "q "..colors[colorname].pdfstring

    local rule = node.new("rule")
    rule.height = ht
    rule.depth  = dp
    rule.width  = wd

    local rule_stop = node.new("whatsit","pdf_literal")
    rule_stop.mode = 1
    rule_stop.data = "Q"

    rule_start.next = rule
    rule.next = rule_stop
    rule_stop.prev = rule
    rule.prev = rule_start
    return rule_start, rule_stop
end

--- Rotate a text on a given angle.
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

--- Make a string XML safe
function xml_escape( str )
    local replace = {
        [">"] = "&gt;",
        ["<"] = "&lt;",
        ["\""] = "&quot;",
        ["&"] = "&amp;",
    }
    local ret = str.gsub(str,".",replace)
    return ret
end

--- See `commands#save_dataset()` for  documentation on the data structure for `xml_element`.
function xml_to_string( xml_element, level )
    level = level or 0
    local str = ""
    str = str .. string.rep(" ",level) .. "<" .. xml_element[".__local_name"]
    for k,v in pairs(xml_element) do
        if type(k) == "string" and not k:match("^%.") then
            str = str .. string.format(" %s=%q", k,v)
        end
    end
    str = str .. ">\n"
    for i,v in ipairs(xml_element) do
        str = str .. xml_to_string(v,level + 1)
    end
    str = str .. string.rep(" ",level) .. "</" .. xml_element[".__local_name"] .. ">\n"
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

--- This function is only called once from `dothings()` during startup phase. We define
--- a family with regular, bold, italic and bolditalic font with size 10pt (we always
--- measure font size in dtp points)
function define_default_fontfamily()
    local fam={
        size         = 10 * factor,
        baselineskip = 12 * factor,
        scriptsize   = 10 * factor * 0.8,
        scriptshift  = 10 * factor * 0.3,
    }
    local ok,tmp
    ok,tmp = fonts.make_font_instance("TeXGyreHeros-Regular",fam.size)
    fam.normal = tmp
    ok,tmp = fonts.make_font_instance("TeXGyreHeros-Regular",fam.scriptsize)
    fam.normalscript = tmp

    ok,tmp = fonts.make_font_instance("TeXGyreHeros-Bold",fam.size)
    fam.bold = tmp
    ok,tmp = fonts.make_font_instance("TeXGyreHeros-Bold",fam.scriptsize)
    fam.boldscript = tmp

    ok,tmp = fonts.make_font_instance("TeXGyreHeros-Italic",fam.size)
    fam.italic = tmp
    ok,tmp = fonts.make_font_instance("TeXGyreHeros-Italic",fam.scriptsize)
    fam.italicscript = tmp

    ok,tmp = fonts.make_font_instance("TeXGyreHeros-BoldItalic",fam.size)
    fam.bolditalic = tmp
    ok,tmp = fonts.make_font_instance("TeXGyreHeros-BoldItalic",fam.scriptsize)
    fam.bolditalicscript = tmp
    fonts.lookup_fontfamily_number_instance[#fonts.lookup_fontfamily_number_instance + 1] = fam
    fonts.lookup_fontfamily_name_number["text"]=#fonts.lookup_fontfamily_number_instance
end


function get_remaining_height(area)
    local cols = current_grid:number_of_columns(area)
    local startcol = 1
    local row,firstrow,lastrow,maxrows
    firstrow = current_grid:current_row(area)
    maxrows  = current_grid:number_of_rows(area)

    if not current_grid:fits_in_row_area(startcol,cols,firstrow,area) then
        while firstrow <= maxrows do
            if current_grid:fits_in_row_area(startcol,cols,firstrow,area) then
                break
            end
            firstrow = firstrow + 1
        end
    end

    row = firstrow

    while current_grid:fits_in_row_area(startcol,cols,row,area) and row <= maxrows do
        row = row + 1
    end

    lastrow = row

    while row <= maxrows do
        if current_grid:fits_in_row_area(startcol,cols,row,area) then
            return ( lastrow - firstrow)  * current_grid.gridheight, firstrow, row
        end
        row = row + 1
    end
    return ( lastrow - firstrow)  * current_grid.gridheight, firstrow, nil

end

function next_row(rownumber,areaname,rows)
    local grid = current_grid

    if rownumber then
        grid:set_current_row(rownumber,areaname)
        return
    end

    local current_row
    current_row = grid:find_suitable_row(1,grid:number_of_columns(areaname),rows,areaname)
    if not current_row then
        publisher.next_area(areaname)
        publisher.setup_page()
        grid = publisher.current_page.grid
        grid:set_current_row(1)
    else
        grid:set_current_row(current_row + rows - 1,areaname)
        grid:set_current_column(1,areaname)
    end
end

function set_image_length(len,width_or_height)
    if len == nil or len == "auto" then
        return nil
    elseif len == "100%" and width_or_height == "width" then
        return xpath.get_variable("__maxwidth") * current_grid.gridwidth
    elseif tonumber(len) then
        if width_or_height == "width" then
            return len * current_grid.gridwidth
        else
            return len * current_grid.gridheight
        end
    else
        return tex.sp(len)
    end
end

function calculate_image_width_height( image, width,height,minwidth,minheight,maxwidth, maxheight )
    -- from http://www.w3.org/TR/CSS2/visudet.html#min-max-widths:
    --
    -- Constraint Violation                                                           Resolved Width                      Resolved Height
    -- ===================================================================================================================================================
    --  1 none                                                                        w                                   h
    --  2 w > max-width                                                               max-width                           max(max-width * h/w, min-height)
    --  3 w < min-width                                                               min-width                           min(min-width * h/w, max-height)
    --  4 h > max-height                                                              max(max-height * w/h, min-width)    max-height
    --  5 h < min-height                                                              min(min-height * w/h, max-width)    min-height
    --  6 (w > max-width) and (h > max-height), where (max-width/w ≤ max-height/h)    max-width                           max(min-height, max-width * h/w)
    --  7 (w > max-width) and (h > max-height), where (max-width/w > max-height/h)    max(min-width, max-height * w/h)    max-height
    --  8 (w < min-width) and (h < min-height), where (min-width/w ≤ min-height/h)    min(max-width, min-height * w/h)    min-height
    --  9 (w < min-width) and (h < min-height), where (min-width/w > min-height/h)    min-width                           min(max-height, min-width * h/w)
    -- 10 (w < min-width) and (h > max-height)                                        min-width                           max-height
    -- 11 (w > max-width) and (h < min-height)                                        max-width                           min-height

    if width < minwidth and height > maxheight then
        -- w("10")
        width = minwidth
        height = maxheight
    elseif width > maxwidth and height < minheight then
        -- w("11")
        width = maxwidth
        height = minheight
    elseif width > maxwidth and height > maxheight and maxwidth / width <= maxheight / height then
        -- w("6")
        width = maxwidth
        height = math.max(minheight, maxwidth * height/width)
    elseif width > maxwidth and height > maxheight and maxwidth / width > maxheight / height then
        -- w("7")
        width = math.max(minwidth,maxheight * width / height)
        height = maxheight
    elseif width < minwidth and height < minheight and minwidth / width <= minheight / height then
        -- w("8")
        width  = math.min(maxwidth,minheight * width / height)
        height = minheight
    elseif width < minwidth and height < minheight and minwidth / width > minheight / height then
        -- w("9")
        width = minwidth
        height = math.min(maxheight,minwidth * height / width)
    elseif width > maxwidth then
        -- w("2")
        width = maxwidth
        height = math.max(maxwidth * height / width, minheight )
    elseif width < minwidth then
        -- w("3")
        width = minwidth
        height = math.min(minwidth * height / width, maxheight)
    elseif height > maxheight then
        -- w("4")
        width = math.max(maxheight * width / height, minwidth)
        height = maxheight
    elseif height < minheight then
        -- w("5")
        width = math.min(minheight * width / height, maxwidth)
        height = minheight
    end

    -- If one of height or width is given, the other one should
    -- be adjusted to keep the aspect ratio
    if height == image.height then
        if width ~= image.width then
            height = height * width / image.width
        end
    elseif width == image.width then
        if height ~= image.height then
            width = width *  height / image.height
        end
    end
    return width, height
end


file_end("publisher.lua")

