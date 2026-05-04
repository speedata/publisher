--- Here goes everything that does not belong anywhere else. Other parts are font handling, the command
--- list, page and grid setup, debugging and initialization. We start with the function publisher#dothings that
--- initializes some variables and starts processing (publisher#dispatch())
--
--  publisher.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.


file_start("publisher.lua")
barcodes = do_luafile("barcodes.lua")
local luxor = do_luafile("luxor.lua")
local spotcolors = require("spotcolors")

if os.getenv("SP_XMLPARSER") == "lxpath" then
    xpath = require("lxpath")
    xpath.stringmatch = unicode.utf8.match
    xpath.find_file = kpse.find_file
    xpath.parse_xml = splib.load_xmlfile
    xpath.ignoreNS = true
else
    xpath = do_luafile("xpath.lua")
end

hasharfbuzz, harfbuzz = pcall(require,'luaharfbuzz')
if not hasharfbuzz then
    warning("harfbuzz library not found")
end

hasharfbuzzsubset, harfbuzzsubset = pcall(require,'luaharfbuzzsubset')



require("publisher.commands")
local fonts         = require("publisher.fonts")
local uuid          = require("uuid")
local colors_module = require("publisher.colors")
local metadata      = require("publisher.metadata")
local links_module  = require("publisher.links")
par                 = require("par")
uuid.randomseed(tex.randomseed)

env_publisherversion = os.getenv("PUBLISHERVERSION")

local M = _G.publisher or {}
_G.publisher = M
local _ENV = setmetatable(M, {__index = _G}) -- luacheck: ignore _ENV

-- expose helpers from submodules
utf8_to_utf16_string_pdf = metadata.utf8_to_utf16_string_pdf


newxpath = false

if os.getenv("SP_XMLPARSER") == "lxpath" then
    newxpath = true
    do_luafile("layout_functions_lxpath.lua")
else
    do_luafile("layout_functions.lua")
end


-- so that node.copy_list copies the node properties
node.set_properties_mode(true)

--- One big point (DTP point, PostScript point) is approx. 65781 scaled points.
factor = 65781
-- factor = 65781.7

-- no more than this number of frames is allowed on a page
maxframes = 999

tenpoint_sp    = tex.sp("10pt")
twelvepoint_sp = tex.sp("12pt")
tenmm_sp       = tex.sp("10mm")
onemm_sp       = tex.sp("1mm")
onein_sp       = tex.sp("1in")
onept_sp       = tex.sp("1pt")
onepc_sp       = tex.sp("1pc")
onepp_sp       = tex.sp("1pp")
onedd_sp       = tex.sp("1dd")
onecc_sp       = tex.sp("1cc")
onecm_sp       = tenmm_sp

-- User has a pro plan
pro = false

has_pro_error = false

--- Attributes
--- ----------
--- Attributes are attached to nodes, so we can store information that are not present in the
--- nodes themselves or are evaluated later on (such as font selection - when generating glyph
--- nodes, we don't yet know what font the user will use).
---
--- Attributes may have any number, they just need to be constant across the whole source.
--- The attributes value must also be a number.

--- Instead of storing strings we store indexes to strings based on the attributes table.
--- Note: there are also properties in LuaTeX which are much more flexible, we use the old mechanism
--- because in disc nodes, the attributes are inherited (as far as I can see).
attributes = {
    ["background-color"] = true,
    ["bgpaddingbottom"] = true,
    ["bgpaddingtop"] = true,
    ["bordernumber"] = true,
    ["borderwd"] = true,
    ["borderht"] = true,
    ["borderdp"] = true,
    ["color"] = true,
    ["font-style"] = {"italic","oblique"},
    ["font-weight"] = {"normal","bold"},
    ["fontfamily"] = true,
    ["hyperlink"] = true,
    ["indent"] = true,
    ["margintop"] = true,
    ["marginbottom"] = true,
    ["newline"] = true,
    ["paddingtop"] = true,
    ["paddingbottom"] = true,
    ["rows"] = true,
    ["spaceglue"] = true,
    ["text-decoration-color"] = true,
    ["text-decoration-line"] = {"underline","overline","line-through"},
    ["text-decoration-style"] = {"solid","double","dotted","dashed","wavy"},
    ["transparency"] = true,
    ["underline_color"] = true,
    ["underline"] = true,
    ["vertical-align"] = {"baseline","top","middle","bottom","sub","super"},
}

attribute_name_number = {}
attribute_number_name = {}
do
    local c = 1
    local sorted_keys = {}
    -- attribute sorting is just for debugging purposes
    for k, _ in pairs(attributes) do
        sorted_keys[#sorted_keys + 1] = k
    end
    table.sort(sorted_keys)
    for _, k in ipairs(sorted_keys) do
        attribute_name_number[k] = c
        attribute_number_name[c] = k
        c = c + 1
    end
end

att_rows           = 98 -- see text formats for details

--- These attributes are for image shifting. The amount of shift up/left can
--- be negative and is counted in scaled points.
att_shift_left     = 100
att_shift_up       = 101

--- A tie glue (U+00A0) is a non-breaking space
att_tie_glue       = 201

--- These attributes are used in tabular material
att_space_prio     = 300
att_space_amount   = 301

att_break_below_forbidden = 400
att_break_above           = 401
att_omit_at_top           = 402
att_use_as_head           = 403
-- HTML tables should not be paragraph:format()ted
att_dont_format           = 404
att_margin_newcolumn      = 405
att_margin_top_boxstart   = 406
att_ignore_orphan_widowsetting = 407

att_margin_top = 450
att_margin_bottom = 451

att_break_before = 452

--- `att_is_table_row` is used in `tabular.lua` and if set to 1, it denotes
--- a regular table row, and not a spacer. Spacers must not appear
--- at the top or the bottom of a table, unless forced to.
att_is_table_row    = 500
att_tr_dynamic_data = 501

-- for border-collapse (vertical)
att_tr_shift_up     = 550

-- Force a hbox line height
att_lineheight = 600
att_dontadjustlineheight = 601

-- server-mode / line breaking (not used anymore?)
att_keep = 700

-- attributes for glue
att_leaderwd = 800
att_tablenewpage = 801

-- mknodes
att_newline = 900

-- PDF/UA - tagged PDF
att_role  = 1000


user_defined_addtolist = 1
user_defined_bookmark  = 2
user_defined_mark      = 3
user_defined_marker    = 4
user_defined_mark_append = 5


action_node    = node.id("action")
disc_node      = node.id("disc")
dir_node       = node.id("dir")
glue_node      = node.id("glue")
glue_spec_node = node.id("glue_spec")
glyph_node     = node.id("glyph")
hlist_node     = node.id("hlist")
kern_node      = node.id("kern")
penalty_node   = node.id("penalty")
rule_node      = node.id("rule")
vlist_node     = node.id("vlist")
whatsit_node   = node.id("whatsit")


for k,v in pairs(node.whatsits()) do
    if v == "user_defined" then
        -- for mark command
        user_defined_whatsit = k
    elseif v == "pdf_refximage" then
        pdf_refximage_whatsit = k
    elseif v == "pdf_action" then
        pdf_action_whatsit = k
    elseif v == "pdf_dest" then
        pdf_dest_whatsit = k
    elseif v == "pdf_start_link" then
        pdf_start_link_whatsit = k
    elseif v == "pdf_literal" then
        pdf_literal_whatsit = k
    end
end

-- sd:alternating
alternating = {}
alternating_value = {}


-- the return value for the LuaTeX process
errorcode = 0

-- sp --mode foo sets modes.foo = true
modes = {}

-- page numbers go from 1 to n. If reordering is necessary, we insert
-- a different index into the pagenum_tbl.
-- A value of {1,2,6,7,3,4,5} means place page 1 on position one, page 2 on
-- position two, page 6 on position three and so on
pagenum_tbl = {}
forward_pagestore = {}
total_inserted_pages = 0

-- pagelabel contains information about a page with the following structure (see shipout() and get_page_labels_str() )
-- pagelabels[pagenumber] = { pagenumber = pagenumber, matter = cp.matter }
pagelabels = {}

-- An array of strings - a mapping of real page numbers and user visible pagenumbers
visible_pagenumbers = {}


matters = { mainmatter = { label = "decimal", resetafter = false, resetbefore = true, prefix = "" },
            frontmatter = { label = "lowercase-romannumeral"}
}

default_areaname = "_page"
default_area     = "_page"

-- The name of the next requested page
nextpage = nil

-- The document language
defaultlanguage = 0

-- Start page
current_pagenumber = 1

-- Expected number of pages (from previous run's aux file), nil if unknown
expected_pages = nil

-- Previous run duration in seconds (from status file), nil if unknown
previous_duration = nil

pages = {}

-- page n shipped out to PDF?
pages_shippedout = {}


-- CSS properties. Use `:matches(tbl)` to find a matching rule. `tbl` has the following structure: `{element=..., id=..., class=... }`
css = do_luafile("css.lua"):new()

-- The defaults (set in the layout instructions file)
options = {
    resetmarks  = false,
    imagenotfounderror = true,
    gridwidth   = tenmm_sp,
    gridheight  = tenmm_sp,
    gridcells_x = 0,
    gridcells_y = 0,
    reportmissingglyphs = true,
    gridlocation = "background",
    fontloader = os.getenv("SP_FONTLOADER") or "harfbuzz",
    xmlparser = os.getenv("SP_XMLPARSER") or "lua",
    hyperlinkborderwidth = tex.sp("1pt"),
    namespaces = "lax",
    tablerulefix = false,
    markdownextensions = {},
}

current_layout_line = ""
current_layout_file = ""
current_data_line = ""

if newxpath then
    options.xmlparser = "go"
else
    options.xmlparser = "lua"
end

-- List of virtual areas. Key is the group name and value is
-- a hash with keys contents (a nodelist) and grid (grid).
groups    = {}

-- sometimes we want to save pages for later reuse. Keys are pagestore names
pagestore = {}

-- See commands.compatibility
compatibility = {
    movecursoronrightedge = true,
}

-- for external image conversion software
imagehandler = {}
resizehandler = {}

viewerpreferences = {}

-- Hyperlinks are stored in publisher.links (links_module) to be inserted later
-- in the pre shipout filter.
links_module.reset()

-- marker counter. Each mark will get its unique counter, so we can determine the
-- order in which markers appear.
markercount = 0
marker_min = {}
marker_max = {}
marker_id_value = {}

-- metapost graphics. Keys are name and values are "beginfig(1)...." texts.
metapostgraphics = {}
metapostcolors = {}
metapostvariables = {}
metapostcolorwarnings = {}

-- The current foreground color (used in underline)
current_fgcolor = nil

-- The color stack to use
defaultcolorstack = 0

data_dispatcher = {}
data_dispatcher_patterns = {}
user_defined_functions = { last = 0}

markers = {}

-- PDF/UA - the /S /Document StructElem
local ktree = pdf.reserveobj()

-- This is a sample data structure in the structElements table:
-- ["doc"] = {
    -- ["added_tables"] = {
        -- ["P_2"] = "true"
    -- },
    -- ["obj"] = "2"
    -- ["role"] = "Document"
    -- [1] = {
        -- ["bbox"] = {
            -- [1] = "28.346"
            -- [2] = "733.369"
            -- [3] = "141.732"
            -- [4] = "813.54"
        -- },
        -- ["obj"] = "7"
        -- ["page"] = "6"
        -- ["role"] = "Figure"
        -- ["text"] = "A figure"
        -- [1] = "0"
    -- },
    -- [2] = {
        -- ["obj"] = "8"
        -- ["page"] = "6"
        -- ["role"] = "P"
        -- [1] = "1"
    -- },
structElements = {}

-- We will have to remember the current group and grid
current_group = nil
current_grid = nil

-- paragraph, table and textblock should set them
current_fontfamily = 0

fontaliases = {}

-- for HTML / CSS fontfamilies
fontgroup = {
     ["sans-serif"] = { regular={["local"] = "sans"}, bold={["local"]="sans-bold"}, italic={["local"]="sans-italic"}, bolditalic={["local"]="sans-bolditalic"} },
     ["serif"] = { regular={["local"] = "serif"}, bold={["local"]="serif-bold"}, italic={["local"]="serif-italic"}, bolditalic={["local"]="serif-bolditalic"} },
     ["monospace"] = { regular={["local"] = "monospace"}, bold={["local"]="monospace-bold"}, italic={["local"]="monospace-italic"}, bolditalic={["local"]="monospace-bolditalic"} },
}

-- Used when bookmarks are inserted in a non-text context
intextblockcontext = 0

-- The array 'masterpages' has tables similar to these:
-- { is_pagetype = test, res = tab, name = name_of_page_type }
-- where `is_pagetype` is an xpath expression to be evaluated,
-- `res` is a table with layoutxml instructions
-- `name` is a string.
masterpages = {}


-- if true, look for lowercase files
lowercase = false

--- Text formats is a hash with arbitrary names as keys and the values
--- are tables with alignment and indent. indent is the amount of
--- indentation in sp. alignment is one of "leftaligned", "rightaligned",
--- "centered", "justified", "start" and "end".
textformats = {

    text           = { indent = 0, alignment="justified",   rows = 1, orphan = 2, widow = 2, name = "text"},
    __centered     = { indent = 0, alignment="centered",    rows = 1, orphan = 2, widow = 2, name = "__centered"},
    __leftaligned  = { indent = 0, alignment="leftaligned", rows = 1, orphan = 2, widow = 2, name = "__leftaligned"},
    __rightaligned = { indent = 0, alignment="rightaligned",rows = 1, orphan = 2, widow = 2, name = "__rightaligned"},
    __justified    = { indent = 0, alignment="justified",   rows = 1, orphan = 2, widow = 2, name = "__justified"},
    justified      = { indent = 0, alignment="justified",   rows = 1, orphan = 2, widow = 2, name = "justified"},
    centered       = { indent = 0, alignment="centered",    rows = 1, orphan = 2, widow = 2, name = "centered"},
    left           = { indent = 0, alignment="leftaligned", rows = 1, orphan = 2, widow = 2, name = "left"},
    right          = { indent = 0, alignment="rightaligned",rows = 1, orphan = 2, widow = 2, name = "right"},
    __fivemm       = { indent = tex.sp("5mm"), alignment="justified",   rows = 1, orphan = 2, widow = 2},
}


--- The bookmarks table has the format
---
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


--- We need the separator for writing files in a directory structure (image cache for now)
os_separator = "/"
if os.type == "windows" then
    os_separator = "\\"
end

-- A very large length
maxdimen = 1073741823


-- this should be 0x100000 (= 1048576), but this is easier to work with in the
-- layout. For example you want to insert a glyph id 467, then you can write
-- &#1100467; in the layout xml. Let me not make this public until I proof that
-- it works.
puastart = 1100000

-- It's convenient to just copy the stretching glue instead of writing
-- the stretch etc. over and over again.
glue_stretch2 = set_glue(nil, { stretch = 2^16, stretch_order = 2 })

-- For attached files. Each of this numbers should appear in the catalog
filespecnumbers = {}

function M.lineinfo()
    if newxpath then
        return "line_layout", current_layout_line, "file", current_layout_file, "line_data" , current_data_line
    else
        return nil
    end
end


roles_a = {
    "Art",
    "Artifact",
    "Div",
    "Document",
    "Figure",
    "H1",
    "H2",
    "H3",
    "H4",
    "H5",
    "H6",
    "Lbl",
    "Link",
    "P",
    "Part",
    "Sect",
    "Span",
    "Table",
    "TD",
    "TH",
    "TOC",
    "TOCI",
    "TR",
}
-- unique id for roles
rolecounter = 0


--- Start the processing (`dothings()`)
--- -------------------------------
--- This is the entry point of the processing. It is called from publisher.spinit#main_loop.
function dothings()
    log("Running LuaTeX version %s on %s",luatex_version,os.name)
    --- First we set some defaults.
    --- A4 paper is 210x297 mm
    local wd_sp = tex.sp("210mm")
    local ht_sp = tex.sp("297mm")
    set_pageformat(wd_sp,ht_sp)
    options.default_pagewidth = wd_sp
    options.default_pageheight = ht_sp

    get_languagecode(os.getenv("SP_MAINLANGUAGE") or "en_GB")

    lowercase = os.getenv("SP_IGNORECASE") == "1"
    local extra_parameter = { otfeatures = { kern = true, liga = false } }
    --- The free font family `TeXGyreHeros` is a Helvetica clone and is part of the
    --- [The TeX Gyre Collection of Fonts](http://www.gust.org.pl/projects/e-foundry/tex-gyre).
    --- We ship it in the distribution.
    fonts.load_fontfile("TeXGyreHeros-Regular",   "texgyreheros-regular.otf",extra_parameter)
    fonts.load_fontfile("TeXGyreHeros-Bold",      "texgyreheros-bold.otf",extra_parameter)
    fonts.load_fontfile("TeXGyreHeros-Italic",    "texgyreheros-italic.otf",extra_parameter)
    fonts.load_fontfile("TeXGyreHeros-BoldItalic","texgyreheros-bolditalic.otf",extra_parameter)

    -- These are used in HTML mode when the user switches to monospace or serif
    fonts.load_fontfile("CrimsonPro-Regular","CrimsonPro-Regular.ttf",extra_parameter)
    fonts.load_fontfile("CrimsonPro-Bold","CrimsonPro-Bold.ttf",extra_parameter)
    fonts.load_fontfile("CrimsonPro-Italic","CrimsonPro-Italic.ttf",extra_parameter)
    fonts.load_fontfile("CrimsonPro-BoldItalic","CrimsonPro-BoldItalic.ttf",extra_parameter)

    fonts.load_fontfile("CamingoCode-Regular","CamingoCode-Regular.ttf",extra_parameter)
    fonts.load_fontfile("CamingoCode-Bold","CamingoCode-Bold.ttf",extra_parameter)
    fonts.load_fontfile("CamingoCode-Italic","CamingoCode-Italic.ttf",extra_parameter)
    fonts.load_fontfile("CamingoCode-BoldItalic","CamingoCode-BoldItalic.ttf",extra_parameter)

    --- Define a basic font family with name `text`:
    define_default_fontfamily()

    local _sampler
    if os.getenv("SP_PROFILE") then
        _sampler = require "sampler"
        _sampler.start(tonumber(os.getenv("SP_PROFILE")) or 10000)
    end
    initialize_luatex_and_generate_pdf()
    if _sampler then
        _sampler.stop()
        _sampler.report("profile.txt")
    end
    -- The last thing is to put a stamp in the PDF
    if options.hidespinfo and options.hidespinfo == "true" or options.hidespinfo == "yes" then
        -- do nothing
        if not pro then
            err("Removing speedata info needs a pro plan")
            publisher.has_pro_error = true
            return nil
        end
    else
        pdf.obj({type="raw",string="(Created with the speedata Publisher - www.speedata.de)", immediate = true, objcompression = false})
    end
end

function get_extension(fn)
    return fn:match("^.+%.(.+)$")
end

function define_image_callback( extensionhandler )
    local extensions = {}
    local ext,handler
    if extensionhandler and extensionhandler ~= "" then
        for _,v in ipairs(string.explode(extensionhandler,";")) do
            _,_,ext,handler = string.find(v,"^(.*):(.*)$")
            extensions[ext] = handler
        end
    end

    local function find_image_file( asked_name )
        local file = kpse.find_file(asked_name)
        local ext = get_extension(asked_name)
        local handlername = extensions[ext]
        local handler = imagehandler[handlername or "*"]
        if handler then
            main.log("info","Convert image", "extension",ext, "handler",handlername or "*")
            file = splib.convertimage(file,handler)
        end
        return file
    end
    callback.register('find_image_file',find_image_file)
end

borderattributes = {}
do
    -- the idea of flatten_boxes is to return an array that only has
    -- par objects.
    -- The input of flatten_boxes is a mix of Box objects and Par objects.
    -- You can consider Box objects something similar to <div> blocks in HTML
    -- and Par objects like <p> that has acutal content in it (also: images and other stuff)
    -- Margin settings should go from <div> to the <p> (from Box to Par) so we can
    -- leave out the div stuff.
    local prependbox
    function flatten_boxes(box,parameter,ret)
        ret = ret or {}
        parameter = parameter or {}
        local indent = box.indent_amount or 0
        if indent and parameter.indent then
            indent = parameter.indent + indent
        end
        local new_parameter = {
            indent = indent
        }
        if box.prependbox and #box.prependbox > 0 then
            prependbox = prependbox or {}
            for i=1,#box.prependbox do
                table.insert(prependbox,box.prependbox[i])
            end
        end

        if box.padding_bottom and box.padding_bottom ~= 0 then
            box[1].padding_bottom = box.padding_bottom
        end
        if box.padding_top and box.padding_top ~= 0 then
            box[1].padding_top = box.padding_top
        end
        if box.draw_border then
            borderattributes[#borderattributes + 1] = box.border
            if #box > 1 then
                box[1].startborder = #borderattributes
            else
                box[1].startendborder = #borderattributes
            end
        end
        if box.startendborder then
            box[1].startendborder = box.startendborder
        end

        for i=1,#box do
            local thisbox = box[i]
            if not thisbox.min_width then
                -- a box with paragraphs inside
                -- Pass break_before to first child, break_after to last child
                if i == 1 and box.break_before then
                    thisbox.break_before = box.break_before
                end
                if i == #box and box.break_after then
                    thisbox.break_after = box.break_after
                end
                flatten_boxes(thisbox,new_parameter,ret)
                if thisbox.mode == "block" then ret.mode = "block" end
            else
                -- a regular paragraph
                if parameter.indent then
                    thisbox:indent(indent)
                end
                if box.width then
                    thisbox.width = box.width
                end
                if box.draw_border then
                    thisbox.draw_border = true
                    thisbox.border = box.border
                end
                if box.startborder then
                    thisbox.startborder = box.startborder
                end
                if prependbox then
                    for p=#prependbox,1,-1 do
                        thisbox:prepend(prependbox[p])
                    end
                    prependbox = nil
                end
                if i == 1 then
                    thisbox.firstbox = true
                    if box.border_top_width then
                        thisbox.border_top_width = box.border_top_width
                    end
                    if box.margintop then
                        thisbox.margin_top = box.margintop
                    end
                    if box.break_before then
                        thisbox.break_before = box.break_before
                    end
                end
                if i == #box then
                    thisbox.lastbox = true
                    if box.marginbottom then
                        thisbox.margin_bottom = box.marginbottom
                    end
                    if box.border_bottom_width then
                        thisbox.border_bottom_width = box.border_bottom_width
                    end
                    if box.break_after then
                        thisbox.break_after = box.break_after
                    end
                end

                ret[#ret + 1] = thisbox
            end
        end
        return ret
    end
end

-- When not in server mode, we initialize LuaTeX in such a way that
-- it has defaults, loads a layout file and a data file and
-- executes them both
function initialize_luatex_and_generate_pdf()
    if os.getenv("SP_VERBOSITY") == nil then
        options.verbosity = 0
    else
        options.verbosity = tonumber(os.getenv("SP_VERBOSITY"))
    end

    options.mpcolorwarning = true
    --- The default page type has 1cm margin
    masterpages[1] = { is_pagetype = "true()", res = { {elementname = "Margin", contents = function(page) page.grid:set_margin(tenmm_sp,tenmm_sp,tenmm_sp,tenmm_sp) end }}, name = "Default Page",ns={[""] = "urn:speedata.de:2009/publisher/en" } }

    --- The `vars` file hold a lua document holding table
    local vars
    local varsfun = loadfile(tex.jobname .. ".vars")
    if varsfun then vars = varsfun() else err("Could not load .vars file. Something strange is happening.") vars = {} end

    for i=4,#arg do
        local k,v = arg[i]:match("^(.+)=(.+)$")
        if k == "mode" then -- everything else handled after loading layout
            v = v:gsub("^\"(.*)\"$","%1")
            local _modes = string.explode(v,",")
            for _,m in ipairs(_modes) do
                modes[m] = true
            end
        elseif k == "pro" then
            pro = true
            main.log("info","speedata Publisher Pro")
        end
    end

    --- Both the data and the layout instructions are written in XML.
    local layoutxml = load_xml(arg[2],"layout instructions")
    if not layoutxml then
        err("Without a valid layout-XML file, I can't really do anything.")
        exit()
    end
    if newxpath then
        layoutxml = layoutxml[1] -- skip document
    end
    --- Used in `xpath.lua` to find out which language the function is in.
    local ns = layoutxml[".__namespace"]
    if not ns then
        err("Cannot find the namespace of the layout file. What should I do?")
        exit()
    end

    --- The currently active layout language. One of `de` or `en`.
    local current_layoutlanguage = string.gsub(ns,"urn:speedata.de:2009/publisher/","")
    if not (current_layoutlanguage=='de' or current_layoutlanguage=='en') then
        err("Cannot determine the language of the layout file.")
        exit()
    end
    if current_layoutlanguage == "de" then
        err("The German layout instructions have been removed\nin version 2.7 of the publisher.")
        exit()
    end
    local version
    local requirements
    if newxpath then
        local attr = layoutxml[".__attributes"]
        if attr and attr["version"] then
            version = attr["version"]
        end
        if attr and attr["require"] then
            requirements = attr["require"]
        end
    else
        version = layoutxml.version
        requirements = layoutxml.require
    end
    if version then
        local version_mismatch = false
        local publisher_version = string.explode(env_publisherversion,".")
        local requested_version = string.explode(version,".")

        if publisher_version[1] ~= requested_version[1] then
            if tonumber(publisher_version[1]) < tonumber(requested_version[1]) then
                version_mismatch = true
            end
        elseif tonumber(publisher_version[2]) < tonumber(requested_version[2]) then
            -- major number are same, minor are different
            version_mismatch = true
        elseif tonumber(requested_version[3]) and tonumber(publisher_version[3]) < tonumber(requested_version[3]) and tonumber(publisher_version[2]) == tonumber(requested_version[2]) then
            version_mismatch = true
        end
        if version_mismatch then
            err("Version mismatch. speedata Publisher is at version %s, requested version %s", env_publisherversion, version)
            exit()
        end
    end
    if requirements and type(requirements) == "string" then
        local r = string.explode(requirements,",")
        for _, req in ipairs(r) do
            if req == "lxpath" then
                if not newxpath then
                    main.log("error","failed to meet requirement", "requirement","lxpath","message","This layout requires the lxpath XML / XPath parser","help","see https://doc.speedata.de/publisher/en/lxpath/ how to activate")
                    exit(false)
                end
            elseif req == "luxor" then
                    if newxpath then
                        main.log("error","failed to meet requirement", "requirement","luxor","message","This layout requires the luxor XML / XPath parser","help","see https://doc.speedata.de/publisher/en/xpathfunctions/ how to activate")
                        exit(false)
                    end
            elseif req == "harfbuzz" then
                if options.fontloader ~= "harfbuzz" then
                    main.log("error","failed to meet requirement", "requirement","harfbuzz","message","This layout requires the harfbuzz font loader","help","see https://doc.speedata.de/publisher/en/configuration/ how to activate")
                    exit(false)
                end
            elseif req == "fontforge" then
                if options.fontloader ~= "fontforge" then
                    main.log("error","failed to meet requirement", "requirement","fontforge","message","This layout requires the fontforge font loader","help","see https://doc.speedata.de/publisher/en/configuration/ how to activate")
                    exit(false)
                end
            else
                err("This layout requires feature %q, but I don't know what it is.\nPerhaps I am too old?",req)
                exit(false)
            end
        end
    end
    if newxpath then
        local tmp = os.getenv("SP_PREPEND_XML")
        if tmp and tmp ~= "" then
            main.log("error","--prepend-xml is not supported with the new XPath mode. Use xinclude instead.")
        end
        tmp = os.getenv("SP_EXTRA_XML")
        if tmp and tmp ~= "" then
            main.log("error","--extra-xml is not supported with the new XPath mode. Use xinclude instead.")
        end
    else
        local tmp = os.getenv("SP_PREPEND_XML")
        if tmp and tmp ~= "" then
            for i,v in ipairs(string.explode(tmp,",")) do
                table.insert(layoutxml, i, luxor.parse_xml_file(v))
            end
        end
        tmp = os.getenv("SP_EXTRA_XML")
        if tmp and tmp ~= "" then
            for _,v in ipairs(string.explode(tmp,",")) do
                layoutxml[#layoutxml + 1] = luxor.parse_xml_file(v)
            end
        end
    end

    -- We allow the use of a dummy xml file for testing purpose
    local dataxml
    local datafilename = arg[3]
    if datafilename == "-dummy" then
        if newxpath then
            dataxml = splib.loadxmlstring("<data />")
        else
            dataxml = luxor.parse_xml("<data />")
        end
    elseif datafilename == "-" then
        log("Reading from stdin")
        dataxml = luxor.parse_xml(io.stdin:read("*a"),{htmlentities = true})
    else
        dataxml = load_xml(datafilename,"data file",{ htmlentities = true, ignoreeol = ( options.ignoreeol or false ) })
    end
    if not dataxml then
        main.log("error","Could not read data")
        exit()
    end
    if type(dataxml) ~= "table" then
        main.log("error","Something is wrong with the data: dataxml is not a table")
        exit()
    end

    if newxpath then
        local defaults = {
            _bleed = "0mm",
            _pageheight = "297mm",
            _pagewidth = "210mm",
            _jobname =  tex.jobname,
            _matter = "mainmatter",
            __maxwidth = tex.sp("190mm"),
            _lastpage = 1,
        }
        data = xpath.context:new()
        data.xmldoc = {dataxml}
        data.sequence = {dataxml}
        data.namespaces = layoutxml[".__ns"]

        for k, v in pairs(defaults) do
            data.vars[k] = v
        end

        -- from command line or publisher.cfg:
        for k, v in pairs(vars) do
            data.vars[k] = v
        end
        local mode_keys = {}
        for k, _ in pairs(modes) do
            mode_keys[#mode_keys+1] = k
        end
        table.sort(mode_keys)
        data.vars._mode = table.concat(mode_keys,",")

        local _, msg = data:execute("root()")
        if msg then
            main.log("error",msg)
        end
    else
        for k,v in pairs(vars) do
            xpath.set_variable(k,v)
        end
    end

    dispatch(layoutxml,data)
    if newxpath then
        -- for namespace mode == strict
        data.namespaces = dataxml[1][".__ns"]
    end

    -- options.ignoreeol is now set.
    -- In DataMode (newxpath), element metatables are already set during
    -- Go XML parsing, so fixup_xmlfile only needs to run if ignoreeol
    -- was set in the layout (after loading) and wasn't handled by Go.
    if newxpath then
        local needs_eol = (options.ignoreeol or false) and not dataxml.ignoreeol_done
        if needs_eol then
            fixup_xmlfile(dataxml, true)
        end
    end

    -- We define two graphic states for overprinting on and off.
    GS_State_OP_On  = pdf.immediateobj([[<< /Type/ExtGState /OP true /OPM 1 >>]])
    GS_State_OP_Off = pdf.immediateobj([[<< /Type/ExtGState /OP false >>]])

    --- override options set in the `<Options>` element
    for i=4,#arg do
        local k,v = arg[i]:match("^(.+)=(.+)$")
        if k ~= "mode" then -- mode handled before loading layout
            v = v:gsub("^\"(.*)\"$","%1")
            options[k]=v
        end
    end

    if options.interaction == "false" then
        options.interaction = false
    elseif options.interaction == "true" then
        options.interaction = true
    end

    if options.showgrid == "false" then
        options.showgrid = false
    elseif options.showgrid == "true" then
        options.showgrid = true
    end

    if options.cutmarks == "true" then
        options.cutmarks = true
    elseif options.cutmarks == "false" then
        options.cutmarks = false
    end

    if options.trimmarks == "true" then
        options.trimmarks = true
    elseif options.trimmarks == "false" then
        options.trimmarks = false
    end

    if options.showgridallocation == "false" then
        options.showgridallocation = false
    elseif options.showgridallocation == "true" then
        options.showgridallocation = true
    end

    if options.reportmissingglyphs == "false" or options.reportmissingglyphs == "no" then
        options.reportmissingglyphs = false
    elseif options.reportmissingglyphs == "true" or options.reportmissingglyphs == "yes" then
        options.reportmissingglyphs = true
    elseif options.reportmissingglyphs == "warning" then
        options.reportmissingglyphs = "warning"
    end

    if options.imagehandler then
        string.gsub(options.imagehandler,"([a-zA-Z*]+):%((.-)%);?", function( imagetype,cmdline )
            imagehandler[imagetype] = cmdline
        end)
    end

    if options.resizehandler then
        string.gsub(options.resizehandler,"([a-zA-Z*]+):%((.-)%);?", function( imagetype,cmdline )
            resizehandler[imagetype] = cmdline
        end)
    end

    define_image_callback(options.extensionhandler or "")

    --- Set the starting page (which must be a number)
    if options.startpage then
        local num = options.startpage
        if num then
            current_pagenumber = tonumber(num)
            log("Set page number to %d",num)
        else
            main.log("error","Can't recognize starting page number", "startpage", options.startpage or "(not set)")
        end
    end

    if options.colorprofile then
        spotcolors.set_colorprofile_filename(options.colorprofile)
        warning("Options / colorprofile is obsolete. Use DefineColorprofile and PDFOptions / colorprofile instead.")
    end

    if options.format == "PDF/UA" and not structElements[".root"] then
        structElements[".root"] = {
            role = "Document",
            obj = pdf.reserveobj(),
        }
        structElements["doc"] = structElements[".root"]
    end


    local auxfilename = tex.jobname .. "-aux.xml"
    -- load help file if it exists
    if kpse.find_file(auxfilename) and options.resetmarks == false then
        local mark_tab = load_xml(auxfilename,"aux file",{ htmlentities = true, ignoreeol = true })
        if newxpath and mark_tab then
            mark_tab = mark_tab[1]
        end
        mark_tab = mark_tab or {}
        for i=1,#mark_tab do
            local mt = mark_tab[i]
            if type(mt) == "table" then
                local attributes
                if newxpath then
                    attributes = mt[".__attributes"]
                else
                    attributes = mt
                end
                if mt[".__local_name"] == "mark" then
                    markers[attributes.name] = { page = attributes.page}
                    local id = tonumber(attributes.id)
                    if id then
                        marker_id_value[id] = { page = attributes.page, name = attributes.name}

                        local pagenumber = tonumber(attributes.page)
                        if not marker_min[pagenumber] then
                            marker_min[pagenumber] = id
                        elseif marker_min[pagenumber] > id then
                            marker_min[pagenumber] = id
                        end
                        if not marker_max[pagenumber] then
                            marker_max[pagenumber] = id
                        elseif marker_max[pagenumber] < id then
                            marker_max[pagenumber] = id
                        end
                    end
                elseif mt[".__local_name"] == "pagelabel" then
                    visible_pagenumbers[tonumber(attributes.pagenumber)] = attributes.visible
                elseif mt[".__local_name"] == "lastpage" then
                    if newxpath then
                        data.vars["_lastpage"] = attributes.page
                    else
                        xpath.set_variable("_lastpage", attributes.page )
                    end
                    expected_pages = tonumber(attributes.page)
                end
            end
        end
    end

    -- Read previous run duration from status file
    local statusfilename = tex.jobname .. ".status"
    local statusfile = io.open(statusfilename, "r")
    if statusfile then
        local content = statusfile:read("*all")
        statusfile:close()
        local dur = content:match("<DurationSeconds>([%d%.]+)</DurationSeconds>")
        if dur then
            previous_duration = tonumber(dur)
        end
    end

    if newxpath then
    else
        xpath.set_variable("_bleed", "0mm")
        xpath.set_variable("_pageheight", "297mm")
        xpath.set_variable("_pagewidth", "210mm")
        xpath.set_variable("_jobname", tex.jobname)
        xpath.set_variable("_matter","mainmatter")
        xpath.set_variable("__maxwidth", tex.sp("190mm"))
        if xpath.get_variable("_lastpage") == nil then
            xpath.set_variable("_lastpage", 1)
        end
    end

    -- The xml now looks like
    -- dataxml = {
    --     [1] = "\
    --       "
    --     [2] = {
    --       [1] = "mixed"
    --       [2] = {
    --         [".__ns"] = {
    --         },
    --         [".__parent"] = <foo>
    --         [".__name"] = "br"
    --         [".__type"] = "element"
    --         [".__local_name"] = "br"
    --       },
    --       [3] = "content"
    --       [".__ns"] = {
    --       },
    --       ["attr1"] = "value1"
    --       [".__parent"] = <data>
    --       [".__name"] = "foo"
    --       [".__type"] = "element"
    --       [".__local_name"] = "foo"
    --     },
    --     [3] = "\
    --   "
    --     [".__name"] = "data"
    --     [".__ns"] = {
    --     },
    --     [".__type"] = "element"
    --     [".__local_name"] = "data"
    --   },
    --
    -- That means the table entries are either strings or child elements.
    -- Attributes are table keys and metadata is stored as ".__" plus the metadata.

    --- Start data processing in the default mode (`""`)
    local name, tmp
    if newxpath then
        local seq, msg
        _, msg = data:execute("root()")
        if msg then
            main.log("error",msg)
        end
        if options.namespaces == "strict" then
            seq, msg = data:eval("local-name()")
            if msg then
                main.log("error",msg)
            end
            name = xpath.string_value(seq)
            seq, msg = data:eval("namespace-uri()")
            if msg then
                main.log("error",msg)
            end
            local namespace_element = xpath.string_value(seq)
            name = "{" .. namespace_element .. "}" .. name
        else
            seq, msg = data:eval("local-name()")
            if msg then
                main.log("error",msg)
            end
            name = xpath.string_value(seq)
        end
    else
        name = dataxml[".__local_name"]
        xpath.set_variable("__position", 1)
    end

    --- The rare case that the user has not any `Record` commands in the layout file:
    if not data_dispatcher[""] and not data_dispatcher_patterns[""] then
        main.log("error","Can't find any “Record” commands in the layout file.")
        exit()
    end

    tmp = data_dispatcher[""] and data_dispatcher[""][name]
    -- Pattern matching fallback for root element (newxpath only)
    if not tmp and newxpath then
        local rootnode = data.sequence and data.sequence[1]
        if rootnode then
            tmp = find_matching_pattern("", rootnode, data)
        end
    end
    if tmp then
        if newxpath then
            -- For data:eval, the namespaces must be set the layout namespaces
            data.namespaces = layoutxml[".__ns"]
            dispatch(tmp,data)
        else
            dispatch(tmp,dataxml)
        end
    else
        name = name or ""
        local elt_ns, elt_localname = string.match(name,"{(.*)}(.*)")
        if elt_ns then
            main.log("error","Can't find “Record” command for the root node","namespace",elt_ns,"elementname",elt_localname)
        else
            main.log("error","Can't find “Record” command for the root node","elementname",name)
        end
        exit()
    end


    --- emit last page if necessary
    -- current_pagestore_name is set when in SavePages and nil otherwise
    if page_initialized_p(current_pagenumber) and current_pagestore_name == nil then
        dothingsbeforeoutput(pages[current_pagenumber],data)
        local n = node.vpack(pages[current_pagenumber].pagebox)
        shipout(n,current_pagenumber,dataxml)
    end
    local lastpage = current_pagenumber
    while not(page_initialized_p(lastpage)) and lastpage > 0 and current_pagestore_name == nil do
        lastpage = lastpage - 1
    end

    --- At this point, all pages are in the PDF
    --- We are not at the end of the processing. Let's write the PDF information and status files.
    local pdfcatalog = {}
    if sp_suppressinfo then
        pdf.settrailerid(" [ <FA052949448907805BA83C1E78896398> <FA052949448907805BA83C1E78896398> ]")
    end
    -- file attachment
    if #filespecnumbers > 0 then
        local afstring = {}
        for i = 1, #filespecnumbers do
            local filespecnum = filespecnumbers[i][1]
            afstring[#afstring+1] = string.format("%d 0 R",filespecnum)
        end
        local af = "[" .. table.concat(afstring," ") .. "]"

        local names = {}
        for i = 1, #filespecnumbers do
            local filespecnum = filespecnumbers[i][1]
            local filename = filespecnumbers[i][3]
            names[#names+1] = string.format([[%s %d 0 R]],utf8_to_utf16_string_pdf(filename),filespecnum)
        end
        pdfcatalog[#pdfcatalog + 1] = string.format([[ /Names << /EmbeddedFiles <<  /Names [%s] >> >> ]],table.concat(names," "))
        pdfcatalog[#pdfcatalog + 1] = string.format([[ /AF %s ]],af)
    end

    local str = get_page_labels_str()
    if str then
        pdfcatalog[#pdfcatalog + 1] = str
    end
    local langtbl = get_language(defaultlanguage)

    if langtbl and langtbl.locale then
        pdfcatalog[#pdfcatalog+1] = string.format(" /Lang (%s)",string.gsub(langtbl.locale,"^(%a+).*","%1"))
    end

    local vp = {}
    if viewerpreferences.numcopies and viewerpreferences.numcopies > 1 and viewerpreferences.numcopies <= 5 then
        vp[#vp + 1] = string.format("/NumCopies %d", viewerpreferences.numcopies)
    end
    if viewerpreferences.printscaling and viewerpreferences.printscaling ~= ""  then
        vp[#vp + 1] = string.format("/PrintScaling /%s", viewerpreferences.printscaling)
    end
    if viewerpreferences.picktray ~= nil  then
        vp[#vp + 1] = string.format("/PickTrayByPDFSize %s", viewerpreferences.picktray)
    end

    if viewerpreferences.duplex ~= nil and viewerpreferences.duplex ~= "" then
        vp[#vp + 1] = string.format("/Duplex /%s", viewerpreferences.duplex)
    end

    if options.pagelayout then
        pdfcatalog[#pdfcatalog + 1] = string.format("/PageLayout /%s", options.pagelayout)
    end

    if options.displaymode then
        pdfcatalog[#pdfcatalog + 1] = string.format("/PageMode /%s", options.displaymode)
    else
        pdfcatalog[#pdfcatalog + 1] = "/PageMode /UseNone"
    end


    -- Title   The document’s title.
    -- Author  The name of the person who created the document.
    -- Subject  The subject of the document.
    -- Keywords  Keywords associated with the document.

    -- Nothing set:
    -- Creator:         speedata Publisher 4.19.2, www.speedata.de
    -- Producer:        LuaTeX 1.15.0 (build 7509)
    --
    -- Creator set:
    -- Creator:         CREATOR
    -- Producer:        speedata Publisher 4.19.2 using LuaTeX

    -- suppressinfo:
    -- Creator:         speedata Publisher
    -- Producer:        LuaTeX

    -- suppressinfo / Creator set:
    -- Creator:         CREATOR
    -- Producer:        speedata Publisher using LuaTeX
    local infos = { string.format("/Creator %s /Producer %s",utf8_to_utf16_string_pdf(metadata.getcreator(options)), utf8_to_utf16_string_pdf(metadata.getproducer(options))) }
    if not sp_suppressinfo then
        infos[#infos+1] = "/Trapped /False"
    end
    if options.documenttitle and options.documenttitle ~= "" then
        infos[#infos + 1] = string.format("/Title %s",utf8_to_utf16_string_pdf(options.documenttitle))
    end
    if options.documentauthor and options.documentauthor ~= "" then
        infos[#infos + 1] = string.format("/Author %s", utf8_to_utf16_string_pdf(options.documentauthor))
    end
    if options.documentsubject and options.documentsubject ~= "" then
        infos[#infos + 1] = string.format("/Subject %s", utf8_to_utf16_string_pdf(options.documentsubject))
    end
    if options.documentkeywords and options.documentkeywords ~= "" then
        infos[#infos + 1] = string.format("/Keywords %s", utf8_to_utf16_string_pdf(options.documentkeywords))
    end

    if options.format then
        local metadataobjnum
        if options.format == "PDF/X-3:2002" or options.format == "PDF/X-4" then
            infos[#infos + 1] = string.format("/GTS_PDFXVersion (%s)",options.format)
            metadataobjnum = pdf.obj({ type="stream", string = metadata.getmetadata(filespecnumbers,options), immediate = true, attr = [[  /Subtype /XML /Type /Metadata ]],compresslevel = 0})
            local colorprofileobjnum = spotcolors.write_colorprofile()
            local cp = spotcolors.get_colorprofile()
            local outputintentsobjnum = pdf.obj({type = "raw",  immediate = true , string = string.format([[<<  /DestOutputProfile %d 0 R /Info %s /OutputCondition %s    /OutputConditionIdentifier %s   /RegistryName %s    /S /GTS_PDFX   /Type /OutputIntent  >>]],colorprofileobjnum,
 utf8_to_utf16_string_pdf(cp.info),
 utf8_to_utf16_string_pdf(cp.condition),
 utf8_to_utf16_string_pdf(cp.identifier),
 utf8_to_utf16_string_pdf(cp.registry))})
            local outputintentsarrayobjnum = pdf.obj({type="raw", string = string.format("[ %d 0 R ]",outputintentsobjnum), immediate = true })
            pdfcatalog[#pdfcatalog + 1] = string.format("/OutputIntents %d 0 R",outputintentsarrayobjnum )
        end
        if options.format == "PDF/A-3" then
            metadataobjnum = pdf.obj({ type="stream", string = metadata.getmetadata(filespecnumbers,options), immediate = true, attr = [[  /Subtype /XML /Type /Metadata ]],compresslevel = 0})
            pdf.setomitcidset(1)
            local colorprofileobjnum = spotcolors.write_colorprofile()
            local cp = spotcolors.get_colorprofile()
            local outputintentsobjnum = pdf.obj({type = "raw",  immediate = true , string = string.format([[<<  /DestOutputProfile %d 0 R /Info %s /OutputCondition %s    /OutputConditionIdentifier %s   /RegistryName %s    /S /GTS_PDFA1   /Type /OutputIntent  >>]],colorprofileobjnum,
 utf8_to_utf16_string_pdf(cp.info),
 utf8_to_utf16_string_pdf(cp.condition),
 utf8_to_utf16_string_pdf(cp.identifier),
 utf8_to_utf16_string_pdf(cp.registry))})
            local outputintentsarrayobjnum = pdf.obj({type="raw", string = string.format("[ %d 0 R ]",outputintentsobjnum), immediate = true })
            pdfcatalog[#pdfcatalog + 1] = string.format("/OutputIntents %d 0 R",outputintentsarrayobjnum )
        end
        if options.format == "PDF/UA" then
            pdfcatalog[#pdfcatalog + 1] = string.format(" /MarkInfo <<  /Marked true >> ")
            metadataobjnum = pdf.obj({ type="stream", string = metadata.getmetadata(filespecnumbers, options), immediate = true, attr = [[  /Subtype /XML /Type /Metadata ]],compresslevel = 0,})
            vp[#vp + 1] = "/DisplayDocTitle true"

            local parenttree = pdf.reserveobj()
            local structTreeRootObjectNumber = pdf.reserveobj()
            -- Sort structure tree by reading order if pages were reordered (InsertPages/SavePages)
            local needs_reorder = false
            for i = 1, #pagenum_tbl do
                if pagenum_tbl[i] ~= i then
                    needs_reorder = true
                    break
                end
            end
            if needs_reorder then
                -- Map page object ref → output position (reading order).
                -- pagenum_tbl[k] = output position for internal page k (shipout order).
                local page_ref_to_num = {}
                for k = 1, #pagenum_tbl do
                    page_ref_to_num[pdf.getpageref(k)] = pagenum_tbl[k]
                end
                sort_struct_tree_by_page_order(structElements[".root"], page_ref_to_num)
            end
            if options.dumpstructtree then
                -- Build page object ref → logical page number mapping
                local pageref_to_num = {}
                for k = 1, #pagenum_tbl do
                    pageref_to_num[pdf.getpageref(k)] = pagenum_tbl[k]
                end
                local xmlstr = '<?xml version="1.0" encoding="UTF-8"?>\n' .. dump_struct_tree_xml(structElements[".root"], nil, pageref_to_num)
                local fn = tex.jobname .. "-struct.xml"
                local f = io.open(fn, "w")
                if f then
                    f:write(xmlstr)
                    f:write("\n")
                    f:close()
                    main.log("info","Structure tree written to " .. fn)
                else
                    main.log("error","Cannot open " .. fn .. " for writing")
                end
            end
            writeStructElements(structElements[".root"],structTreeRootObjectNumber)
            local strObjnum = pdf.obj({ type = "raw", objnum = structTreeRootObjectNumber,  string = string.format("<</Type /StructTreeRoot /K %d 0 R /ParentTree %d 0 R >>",structElements[".root"].obj,parenttree), immediate = true})
            local numentries = { "<< /Nums [" }
            for i = 1, #struct_root_numtree do
                numentries[#numentries+1] = tostring(i-1)
                numentries[#numentries+1] = tostring(struct_root_numtree[i])
            end
            numentries[#numentries + 1] = "] >>"
            pdf.obj({type = "raw", string = string.format(table.concat(numentries," ")), objnum = parenttree, immediate = true})

            pdfcatalog[#pdfcatalog + 1] = string.format("/StructTreeRoot %d 0 R",strObjnum)
        end

        if metadataobjnum then
            pdfcatalog[#pdfcatalog + 1] = string.format("/Metadata %d 0 R",metadataobjnum )
        end
    end

    if #vp > 0 then
        pdfcatalog[#pdfcatalog + 1] = "/ViewerPreferences <<" .. table.concat(vp," ") .. ">>"
    end

    local info = table.concat(infos, " ")

    local catalog = table.concat(pdfcatalog," ")

    if pdf.setinfo then
        pdf.setcatalog(catalog)
        pdf.setinfo(info)
    else
        pdf.catalog = catalog
        pdf.info = info
    end

    --- Now put the bookmarks in the pdf
    for _,v in ipairs(bookmarks) do
        bookmarkstotex(v)
    end
    local tab = {}
    for k,v in pairs(markers) do
        tab[#tab + 1] = string.format("  <mark name=%q page=%q id=%q />",xml_escape(tostring(k)),xml_escape(tostring(v.page)), tostring(v.count))
    end
    for i = 1,#visible_pagenumbers do
        tab[#tab + 1] = string.format("  <pagelabel pagenumber=%q visible=%q />",tostring(i),xml_escape(tostring(visible_pagenumbers[i])))
    end
    local file, errmsg = io.open(auxfilename,"wb")
    if file == nil then
        main.log("error","Could not open aux file for writing", "filename", auxfilename, "message", errmsg)
        return
    end
    file:write("<marker>\n")
    file:write(table.concat(tab,"\n"))
    file:write(string.format("\n <lastpage page='%d' />",lastpage))
    file:write("\n</marker>")
    file:close()
    if has_pro_error then
        log("*****************************************************")
        log("*                                                   *")
        log("* This layout uses features that require a Pro plan *")
        log("*                                                   *")
        log("* See                                               *")
        log("*  https://www.speedata.de/en/product/prices/       *")
        log("* for more information                              *")
        log("*                                                   *")
        log("*****************************************************")
    end
end

-- Create a PageLabels dictionary entry and update the visible_pagenumber
-- entry in the pagelabels table for referencing.
-- This is called at the end, when writing a dictionary

struct_root_numtree = {}

local ntmetafunctostring = function(tbl)
    local tmp = {}
    tmp[#tmp+1] = "["
    for i = 1, #tbl do
        local objnum = rawget(tbl,i)
        tmp[#tmp+1] = string.format("%d 0 R",objnum)
    end
    tmp[#tmp+1] = "]"
    return table.concat(tmp," ")
end

do
    local objcount
    local structelementobjects

    function find_role_attributes( nodelist,parenttree, page, curid )
        local head = nodelist
        while head do
            local entry
            if head.id == hlist_node or head.id == vlist_node then
                if head.list then
                    local r = node.has_attribute(head,att_role)
                    local parentid    = getprop(head,"parentid")

                    -- parentdid == "" is a maker for inheritance
                    if parentid == "" or parentid == nil then
                        parentid = curid
                    end
                    -- roleid is role, underscore, rolecounter, for example P_1
                    local roleid = getprop(head,"id")
                    if roleid then
                        local actualtext = getprop(head,"actualtext")
                        local alttext = getprop(head,"alttext")
                        local rolename = roles_a[r]
                        if rolename ~= "Artifact" then
                            local structpos = getprop(head,"structpos")
                            entry = {
                                obj = pdf.reserveobj(),
                                role = rolename,
                                page = page,
                                actualtext = actualtext,
                                alttext = alttext,
                            }
                            local parenttable = structElements[parentid]
                            if parenttable then
                                if structpos == "top" then
                                    table.insert(parenttable,1,entry)
                                elseif tonumber(structpos) then
                                    table.insert(parenttable,tonumber(structpos),entry)
                                else
                                    parenttable[#parenttable+1] = entry
                                end
                            end
                            structElements[roleid] = entry
                        end
                    end
                    find_role_attributes(head.list, parenttree, page, roleid or curid)
                end
            elseif node.has_attribute(head,att_role) then
                local r = node.has_attribute(head,att_role)
                local roleid      = getprop(head,"id")
                local parentid    = getprop(head,"parentid")
                if parentid == nil or parentid == "" or parentid == 0 or parentid == roleid then
                    parentid = curid
                end
                local actualtext  = getprop(head,"actualtext")
                local alttext     = getprop(head,"alttext")
                local bbox        = getprop(head,"bbox")
                -- role number to role name
                r = roles_a[r]

                local entry
                if structElements[roleid] then
                    entry = structElements[roleid]
                else
                    if r == "Link" then
                        local linkobjnum = getprop(head,"linkobjnum")
                        local structelemobjnum = getprop(head,"structelemobjnum")
                        local startlink = head.next
                        startlink.action.data = startlink.action.data .. "/F 2" .. string.format("/P %s 0 R ",page)
                        entry = {
                            obj = structelemobjnum,
                            role = r,
                            page = page,
                            actualtext = actualtext,
                            alttext = alttext,
                            bbox = bbox,
                            linkobjects = { linkobjnum }
                        }
                    else
                        entry = {
                                obj = pdf.reserveobj(),
                                role = r,
                                page = page,
                                actualtext = actualtext,
                                alttext = alttext,
                                bbox = bbox,
                            }
                    end
                    -- The parent needs links to the children, but only one for each. Therefore
                    -- the parent contains a table (added_tables) which records all roleids
                    -- that are already part of the structure.
                    -- Example:
                    -- Object 2 is: <</Type /StructElem /S /Document /P 16 0 R /K 8 0 R>>
                    -- Object 8 is: <</Type /StructElem /S /P /P 2 0 R /K [ 0 5 0 R ] /Pg 7 0 R>>
                    -- Object 7 is: << /Type /Page /Contents ... >>
                    -- Object 6 (not shown here): <</Type /StructElem /S /P /P 2 0 R /K 0 /Pg 5 0 R>>
                    -- Object 2 (the root) has one child: the P_1 (obj 6)
                    -- parentStructElem = {
                    --     ["added_tables"] = {
                    --         ["P_1"] = "true"
                    --     },
                    --     ["obj"] = "2"
                    --     ["role"] = "Document"
                    --     [1] = {
                    --          ["obj"] = "8"
                    --          ["page"] = "7"
                    --          ["role"] = "P"
                    --     },
                    -- },
                    if not parentid then
                        main.log("debug","Structure entry has no parent id","roleid",roleid or "(none)","role",r)
                    else
                        if r ~= "Artifact" then
                            local parenttable = structElements[parentid]
                            if parenttable then
                                parenttable[#parenttable+1] = entry
                            else
                                main.log("debug","Structure entry has no parent table","parentid",parentid or "(none)","role",r)
                            end
                        end
                    end
                end

                structelementobjects[#structelementobjects+1] = entry.obj
                local str
                if r == "Artifact" then
                    str = "/Artifact<<>>BDC"
                else
                    str = string.format("/%s<</MCID %d>>BDC", r,objcount)
                end
                head.data = str
                entry[#entry+1] = objcount
                objcount = objcount + 1
            end
            head = head.next
        end
    end

    -- called once for each page
    function insert_struct_elements( nodelist,page )
        -- structelementobjects contains struct tree object numbers for this page.
        structelementobjects = {}
        objcount = 0
        local parenttree = ktree
        -- Use shipout index (#pagenum_tbl) instead of logical page number,
        -- because pdf.getpageref uses internal page numbering (shipout order).
        local thispage = pdf.getpageref(#pagenum_tbl)
        find_role_attributes(nodelist,parenttree,thispage)

        page.structparents = #struct_root_numtree
        -- ntmetafunctostring returns object references in brackets for __tostring
        struct_root_numtree[#struct_root_numtree + 1] = setmetatable(structelementobjects,{__tostring = ntmetafunctostring })
     end
end



-- annotate_nodelist is used for tooltips when debugging text formats.
do
    local annotcount = 0
    function annotate_nodelist(nodelist,text)
        text = text:gsub(" ","\\040")
        local annot = node.new(whatsit_node,"pdf_annot")
        local str = string.format([[ /Subtype /Widget /TU (%s) /T (tooltip zref@%d) /C [] /FT/Btn /F 768 /Ff 65536 /H/N /BS << /W 0 >>]],text,annotcount)
        annotcount = annotcount + 1
        annot.data = str
        annot.width = nodelist.width
        annot.height = nodelist.height
        annot.depth = nodelist.depth
        nodelist = node.insert_before(nodelist.head,nodelist.head,annot)
        return nodelist
    end
end

-- skippages are set in commands.new_page if openon="..."
skippages = nil

-- Draw a box with HTML properties given at head
-- The `height_sp` parameter is recomputed from `properties.lineheight`
-- below; the caller's value is intentionally ignored.
-- luacheck: push ignore height_sp
function htmlbox(dirmode, head, width_sp, height_sp, depth_sp)
    local debug_htmlbox = 0
    local properties = node.getproperty(head)
    if not properties then
        err("Internal error: htmlbox() - no properties given")
        return
    end
    local rules = {}
    rules[#rules + 1] = "q"
    --- We start with 4 trapezoids (1 for each border). Later on clip paths are added.
    ---
    ---      4    4------------------------------3   3  y0
    ---      |\    \                            /   /|
    ---      | \    \                          /   / |
    ---      |  \    \                        /   /  |
    ---      |   \    \                      /   /   |
    ---      |    \    \                    /   /    |
    ---      |     3    1------------------2   4     |  y1
    ---      |     |                           |     |
    ---      |     |                           |     |
    ---      |     |                           |     |
    ---      |     |                           |     |
    ---      |     |                           |     |
    ---      |    2    4--------------------3   1    |  y2
    ---      |   /    /                      \   \   |
    ---      |  /    /                        \   \  |
    ---      | /    /                          \   \ |
    ---      |/    /                            \   \|
    ---      1    /                              \   2  y3
    ---          1--------------------------------2
    ---      x0      x1                       x2     x3
    ---
    --- Baseline is at 0
    --- depth is negative downwards
    --- height is positive upwards
    local colorstring

    local function get_rule(x1, y1, x2, y2, x3, y3, x4, y4)
        local _x1, _y1 = sp_to_bp(x1), sp_to_bp(y1)
        local _x2, _y2 = sp_to_bp(x2), sp_to_bp(y2)
        local _x3, _y3 = sp_to_bp(x3), sp_to_bp(y3)
        local _x4, _y4 = sp_to_bp(x4), sp_to_bp(y4)
        local ret = string.format("%s 0 w %g %g m %g %g l %g %g l %g %g l b", colorstring, _x1, _y1, _x2, _y2, _x3, _y3, _x4, _y4)
        return ret
    end

    local b_b_r_radius = properties.border_bottom_right_radius
    local b_b_l_radius = properties.border_bottom_left_radius
    local b_t_r_radius = properties.border_top_right_radius
    local b_t_l_radius = properties.border_top_left_radius

    local border_top_width    = properties.border_top_width
    local border_right_width  = properties.border_right_width
    local border_bottom_width = properties.border_bottom_width
    local border_left_width   = properties.border_left_width

    local padding_top    = properties.padding_top
    local padding_bottom = properties.padding_bottom
    local padding_left   = properties.padding_left

    local margin_left   = properties.margin_left or 0
    -- ht == y3, wd == x3
    depth_sp = math.max(depth_sp,properties.depth or 0)
    height_sp = properties.lineheight - depth_sp
    local sp_x0, sp_x1, sp_x2, wd
    local sp_y0, sp_y1, sp_y2, ht

    if dirmode == "horizontal" then
        local content_top    = height_sp  + (properties.shiftdown or 0)
        local content_bottom = -depth_sp  + (properties.shiftdown or 0)

        sp_y0 = content_top + padding_top + border_top_width
        sp_y1 = content_top + padding_top
        ht    = content_bottom - padding_bottom - border_bottom_width
        sp_y2 = content_bottom - padding_bottom

        sp_x0 = -1 * (padding_left + border_left_width)
        sp_x1 = sp_x0 + border_left_width
        sp_x2 = sp_x1 + width_sp
        wd    = sp_x2 + border_right_width
    else
        local content_top    = height_sp
        local content_bottom = -depth_sp

        -- vertical
        sp_y0 = content_top + padding_top + border_top_width
        sp_y1 = content_top + padding_top
        ht    = content_bottom - padding_bottom - border_bottom_width
        sp_y2 = content_bottom - padding_bottom

        -- horizontal
        local content_left  = properties.shiftright or 0
        local content_right = width_sp + (properties.shiftright or 0) + margin_left

        sp_x0 = content_left - padding_left - border_left_width
        sp_x1 = content_left - padding_left
        sp_x2 = content_right + padding_left
        wd    = sp_x2 + border_right_width
    end

    --- The trapezoids must extend closer to the center of the border, because if the border
    --- radius is larger than the border width, the border goes "into" the surrounding object.
    -- 3 might not be correct. TODO: what is the correct factor? Should depend on the radius
    local extend_top = 0
    local extend_right = 0
    local extend_bottom = 0
    local extend_left = 0
    if b_t_l_radius > 0 or b_t_r_radius > 0 then
        extend_top = 3
    end
    if b_t_r_radius > 0 or b_b_r_radius > 0 then
        extend_right = 3
    end
    if b_b_l_radius > 0 or b_b_r_radius > 0 then
        extend_bottom = 3
    end
    if b_t_l_radius > 0 or b_b_l_radius > 0 then
        extend_left = 3
    end
    local inner_top = sp_y1 - extend_top *  border_top_width
    local inner_right = sp_x2  - extend_right * border_right_width
    local inner_bottom = sp_y2 + extend_bottom * border_bottom_width
    local inner_left = sp_x1 + extend_left * border_left_width

    if properties.border_top_style ~= "none" and border_top_width > 0 then
        colorstring = colors_module.colors[properties.border_top_color].pdfstring
        rules[#rules + 1] = get_rule(inner_left,inner_top, inner_right, inner_top, wd, sp_y0, sp_x0, sp_y0)
    end
    if properties.border_right_style ~= "none" and border_right_width > 0 then
        colorstring = colors_module.colors[properties.border_right_color].pdfstring
        rules[#rules + 1] = get_rule(inner_right,inner_bottom, wd, ht, wd, sp_y0, inner_right,inner_top)
    end
    if properties.border_bottom_style ~= "none" and border_bottom_width > 0 then
        colorstring = colors_module.colors[properties.border_bottom_color].pdfstring
        rules[#rules + 1] = get_rule(sp_x0, ht, wd, ht,inner_right,inner_bottom , inner_left,inner_bottom)
    end
    if properties.border_left_style ~= "none" and border_left_width > 0 then
        colorstring = colors_module.colors[properties.border_left_color].pdfstring
        rules[#rules + 1] = get_rule(sp_x0, ht, inner_left, inner_bottom, inner_left, inner_top, sp_x0, sp_y0)
    end
    rules[#rules + 1] = "Q"

    -- Let's calculate the outer boundary first.
    local circle_bezier = 0.551915024494

    -- xn, yn = outer path, xin, yin = inner path used for clipping
    local x0, y0   = sp_x0                              , ht + b_b_l_radius -- luacheck: ignore y0
    local x1, y1   = sp_x0 + b_b_l_radius   , ht
    local x2, y2   = wd - b_b_r_radius                , y1
    local x3, y3   = x2 + circle_bezier * b_b_r_radius, y1
    local x5, y5   = wd                               , ht + b_b_r_radius
    local x4, y4   = wd                               , y5 - circle_bezier * b_b_r_radius
    local x6, y6   = wd                               , sp_y0 - b_t_r_radius
    local x7, y7   = wd                               , y6 + b_t_r_radius * circle_bezier
    local x9, y9   = wd - b_t_r_radius                , sp_y0
    local x8, y8   = x9 + circle_bezier * b_t_r_radius, y9
    local x10, y10 = sp_x0 + b_t_l_radius   , y9
    local x11, y11 = x10 - circle_bezier * b_t_l_radius, y9
    local x13, y13 = sp_x0                              ,y9 - b_t_l_radius
    local x12, y12 = sp_x0                             ,y13 + circle_bezier * b_t_l_radius
    local x14, y14 = sp_x0                             , y1 + b_b_l_radius
    local x15, y15 = sp_x0                             , y14 - b_b_l_radius * circle_bezier
    local x16, y16 = x1 - circle_bezier * b_b_l_radius, y1

    local b_b_r_inner_radius_x = math.max(0, b_b_r_radius - border_right_width )
    local b_b_r_inner_radius_y = math.max(0, b_b_r_radius - border_bottom_width )
    local b_b_l_inner_radius_x = math.max(0, b_b_l_radius - border_left_width )
    local b_b_l_inner_radius_y = math.max(0, b_b_l_radius - border_bottom_width )
    local b_t_r_inner_radius_x = math.max(0, b_t_r_radius - border_right_width )
    local b_t_r_inner_radius_y = math.max(0, b_t_r_radius - border_top_width )
    local b_t_l_inner_radius_x = math.max(0, b_t_l_radius - border_left_width)
    local b_t_l_inner_radius_y = math.max(0, b_t_l_radius - border_top_width)

    -- bottom left
    local xi14, yi14 = sp_x0 + border_left_width             ,math.max(ht + border_bottom_width, y14)
    local xi1, yi1   = math.max(x1,sp_x0 + border_left_width),ht + border_bottom_width

    -- bottom right
    local xi2, yi2   = math.min(x2,wd - border_right_width), yi1
    local xi5, yi5   = wd - border_right_width             ,  math.max(y5,ht + border_bottom_width)

    -- top right
    local xi6, yi6   = xi5,math.min(y6, sp_y0 - border_top_width)
    local xi9, yi9   = math.min(x9,wd - border_right_width), math.min(y9, sp_y0 - border_top_width)

    -- top left
    local xi10, yi10 = math.max(sp_x0 + border_left_width,x10),math.min(sp_y0 - border_top_width,y10)
    local xi13, yi13 = math.max(sp_x0 + border_left_width,x13),math.min(sp_y0 - border_top_width,y13 )

    -- control points
    -- bottom left
    local xi16, yi16 = xi1 - circle_bezier * b_b_l_inner_radius_x,yi1
    local xi15, yi15 = xi14, yi14 - circle_bezier * b_b_l_inner_radius_y

    -- bottom right
    local xi3, yi3   = xi2 + circle_bezier * b_b_r_inner_radius_x ,  yi2
    local xi4, yi4   = xi5, yi5 - circle_bezier * b_b_r_inner_radius_y

    -- top right
    local xi7, yi7   = xi6,yi6 + circle_bezier * b_t_r_inner_radius_y
    local xi8, yi8   = xi9 + circle_bezier * b_t_r_inner_radius_x ,yi9

    -- top left
    local xi11, yi11 = xi10 - circle_bezier * b_t_l_inner_radius_x ,yi10
    local xi12, yi12 = xi13 ,yi13 + circle_bezier *  b_t_l_inner_radius_y

    if debug_htmlbox > 1 then
        rules[#rules + 1] = circle_pdfstring(x1 ,y14,b_b_l_radius,b_b_l_radius,"0 G ","",1000 )
        rules[#rules + 1] = circle_pdfstring(x2 ,y5,b_b_r_radius,b_b_r_radius,"0 G ","",1000 )
        rules[#rules + 1] = circle_pdfstring(x9 ,y6,b_t_r_radius,b_t_r_radius,"0 G ","",1000 )
        rules[#rules + 1] = circle_pdfstring(x10 ,y13,b_t_l_radius,b_t_l_radius,"0 G ","",1000 )

        rules[#rules + 1] = circle_pdfstring(xi1 ,yi14,b_b_l_inner_radius_x,b_b_l_inner_radius_y,"0 G ","",1000 )
        rules[#rules + 1] = circle_pdfstring(xi2 ,yi5,b_b_r_inner_radius_x,b_b_r_inner_radius_y,"0 G ","",1000 )
        rules[#rules + 1] = circle_pdfstring(xi9 ,yi6,b_t_r_inner_radius_x,b_t_r_inner_radius_y,"0 G ","",1000 )
        rules[#rules + 1] = circle_pdfstring(xi10 ,yi13,b_t_l_inner_radius_x,b_t_l_inner_radius_y,"0 G ","",1000 )
    end


    local rules_clip = {}

    rules_clip[#rules_clip + 1] = pdf_moveto(x1,y1)
    rules_clip[#rules_clip + 1] = pdf_lineto(x2,y2)
    rules_clip[#rules_clip + 1] = pdf_curveto(x3,y3,x4,y4,x5,y5)
    rules_clip[#rules_clip + 1] = pdf_lineto(x6,y6)
    rules_clip[#rules_clip + 1] = pdf_curveto(x7,y7,x8,y8,x9,y9)
    rules_clip[#rules_clip + 1] = pdf_lineto(x10,y10)
    rules_clip[#rules_clip + 1] = pdf_curveto(x11,y11,x12,y12,x13,y13)
    rules_clip[#rules_clip + 1] = pdf_lineto(x14,y14)
    rules_clip[#rules_clip + 1] = pdf_curveto(x15,y15,x16,y16,x1,y1)

    rules_clip[#rules_clip + 1] = pdf_moveto(xi1,yi1)
    rules_clip[#rules_clip + 1] = pdf_lineto(xi2,yi2)
    rules_clip[#rules_clip + 1] = pdf_curveto(xi3,yi3,xi4,yi4,xi5,yi5)
    rules_clip[#rules_clip + 1] = pdf_lineto(xi6,yi6)
    rules_clip[#rules_clip + 1] = pdf_curveto(xi7,yi7,xi8,yi8,xi9,yi9)
    rules_clip[#rules_clip + 1] = pdf_lineto(xi10,yi10)
    rules_clip[#rules_clip + 1] = pdf_curveto(xi11,yi11,xi12,yi12,xi13,yi13)
    rules_clip[#rules_clip + 1] = pdf_lineto(xi14,yi14)
    rules_clip[#rules_clip + 1] = pdf_curveto(xi15,yi15,xi16,yi16,xi1,yi1)

    if debug_htmlbox > 0 then
        rules[#rules + 1] = "q 0.3 w"
        rules[#rules + 1] = pdf_moveto(x0,0)
        rules[#rules + 1] = pdf_lineto(wd,0)
        rules[#rules + 1] = "S"
        rules[#rules + 1] = pdf_moveto(x0,-depth_sp)
        rules[#rules + 1] = pdf_lineto(wd,-depth_sp)
        rules[#rules + 1] = "S"
        rules[#rules + 1] = pdf_moveto(x0,height_sp)
        rules[#rules + 1] = pdf_lineto(wd,height_sp)
        rules[#rules + 1] = "S"
        rules[#rules + 1] = "Q"
    end

    if debug_htmlbox > 1 then
        rules[#rules + 1] = "q 0.3 w"
        rules[#rules + 1] = pdf_moveto(x1,y1)
        rules[#rules + 1] = pdf_lineto(x2,y2)
        rules[#rules + 1] = pdf_curveto(x3,y3,x4,y4,x5,y5)
        rules[#rules + 1] = pdf_lineto(x6,y6)
        rules[#rules + 1] = pdf_curveto(x7,y7,x8,y8,x9,y9)
        rules[#rules + 1] = pdf_lineto(x10,y10)
        rules[#rules + 1] = pdf_curveto(x11,y11,x12,y12,x13,y13)
        rules[#rules + 1] = pdf_lineto(x14,y14)
        rules[#rules + 1] = pdf_curveto(x15,y15,x16,y16,x1,y1)
        rules[#rules + 1] = "S"

        rules[#rules + 1] = pdf_moveto(xi1,yi1)
        rules[#rules + 1] = pdf_lineto(xi2,yi2)
        rules[#rules + 1] = pdf_curveto(xi3,yi3,xi4,yi4,xi5,yi5)
        rules[#rules + 1] = pdf_lineto(xi6,yi6)
        rules[#rules + 1] = pdf_curveto(xi7,yi7,xi8,yi8,xi9,yi9)
        rules[#rules + 1] = pdf_lineto(xi10,yi10)
        rules[#rules + 1] = pdf_curveto(xi11,yi11,xi12,yi12,xi13,yi13)
        rules[#rules + 1] = pdf_lineto(xi14,yi14)
        rules[#rules + 1] = pdf_curveto(xi15,yi15,xi16,yi16,xi1,yi1)
        rules[#rules + 1] = "S Q"
    end

    rules_clip[#rules_clip + 1] = "h W* n"

    local n_clip = node.new("whatsit","pdf_literal")
    setprop(n_clip,"origin","htmlbox.clip")
    local n_clip_data = table.concat(rules_clip," ")
    local concat_rules = table.concat(rules, " ")
    n_clip_data = n_clip_data .. " " .. concat_rules
    n_clip.data = n_clip_data

    local pdf_save    = node.new("whatsit","pdf_save")
    local pdf_restore = node.new("whatsit","pdf_restore")

    node.insert_after(pdf_save,pdf_save,n_clip)

    local hvbox = node.hpack(pdf_save)
    hvbox.depth = 0
    node.insert_after(hvbox,node.tail(hvbox),pdf_restore)
    hvbox = node.vpack(hvbox)
    node.setproperty(hvbox,{origin="hvbox"})

    if dirmode == "horizontal" then
        return hvbox
    end
    local vbox = node.vpack(hvbox)
    local shiftdown = properties.shiftdown or 0
    local g = set_glue(nil, { width = shiftdown})
    vbox.head = node.insert_before(vbox.head,vbox.head,g)
    vbox.height = 0
    vbox.depth = 0
    return vbox
end
-- luacheck: pop

-- To split the textblock in pieces
local marker
marker = node.new("whatsit","user_defined")
marker.user_id = user_defined_marker
marker.type = 100  -- type 100: "value is a number"
marker.value = 1

--- Node(list) creation
--- -------------------


rightskip = node.new("glue_spec")
rightskip.width = 0
rightskip.stretch = 1 * 2^16
rightskip.stretch_order = 3

leftskip = node.new("glue_spec")
leftskip.width = 0
leftskip.stretch = 1 * 2^16
leftskip.stretch_order = 3


--- Hyphenation and language handling
--- ---------------------------------

--- We map from symbolic names to (part of) file names. The hyphenation pattern files are
--- in the format `hyph-XYZ.pat.txt` and we need to find out that `XYZ` part.
language_mapping = {
    ["Ancient Greek"]                = "grc",
    ["Armenian"]                     = "hy",
    ["Bahasa Indonesia"]             = "id",
    ["Basque"]                       = "eu",
    ["Bulgarian"]                    = "bg",
    ["Catalan"]                      = "ca",
    ["Chinese"]                      = "zh",
    ["Croatian"]                     = "hr",
    ["Czech"]                        = "cs",
    ["Danish"]                       = "da",
    ["Dutch"]                        = "nl",
    ["English"]                      = "en_GB",
    ["English (Great Britain)"]      = "en_GB",
    ["English (USA)"]                = "en_US",
    ["Esperanto"]                    = "eo",
    ["Estonian"]                     = "et",
    ["Finnish"]                      = "fi",
    ["French"]                       = "fr",
    ["Galician"]                     = "gl",
    ["German"]                       = "de",
    ["Greek"]                        = "el",
    ["Gujarati"]                     = "gu",
    ["Hindi"]                        = "hi",
    ["Hungarian"]                    = "hu",
    ["Icelandic"]                    = "is",
    ["Irish"]                        = "ga",
    ["Italian"]                      = "it",
    ["Kannada"]                      = "kn",
    ["Kurmanji"]                     = "ku",
    ["Latvian"]                      = "lv",
    ["Lithuanian"]                   = "lt",
    ["Malayalam"]                    = "ml",
    ["Norwegian Bokmål"]             = "nb",
    ["Norwegian Nynorsk"]            = "nn",
    ["Other"]                        = "--",
    ["Polish"]                       = "pl",
    ["Portuguese"]                   = "pt",
    ["Romanian"]                     = "ro",
    ["Russian"]                      = "ru",
    ["Sanskrit"]                     = "sa",
    ["Serbian"]                      = "sr",
    ["Serbian (cyrillic)"]           = "sc",
    ["Slovak"]                       = "sk",
    ["Slovenian"]                    = "sl",
    ["Spanish"]                      = "es",
    ["Swedish"]                      = "sv",
    ["Turkish"]                      = "tr",
    ["Ukrainian"]                    = "uk",
    ["Welsh"]                        = "cy",
}


language_filename = {
    ["bg"]    = "bg",
    ["ca"]    = "ca",
    ["cs"]    = "cs",
    ["cy"]    = "cy",
    ["da"]    = "da",
    ["de"]    = "de-1996",
    ["el"]    = "el-monoton",
    ["en"]    = "en-gb",
    ["en_gb"] = "en-gb",
    ["en_us"] = "en-us",
    ["eo"]    = "eo",
    ["es"]    = "es",
    ["et"]    = "et",
    ["eu"]    = "eu",
    ["fi"]    = "fi",
    ["fr"]    = "fr",
    ["ga"]    = "ga",
    ["gl"]    = "gl",
    ["grc"]   = "grc",
    ["gu"]    = "gu",
    ["hi"]    = "hi",
    ["hr"]    = "hr",
    ["hu"]    = "hu",
    ["hy"]    = "hy",
    ["id"]    = "id",
    ["is"]    = "is",
    ["it"]    = "it",
    ["ku"]    = "kmr",
    ["kn"]    = "kn",
    ["lt"]    = "lt",
    ["ml"]    = "ml",
    ["lv"]    = "lv",
    ["nb"]    = "nb",
    ["nl"]    = "nl",
    ["nn"]    = "nn",
    ["no"]    = "nb",
    ["pl"]    = "pl",
    ["pt"]    = "pt",
    ["ro"]    = "ro",
    ["ru"]    = "ru",
    ["sa"]    = "sa",
    ["sk"]    = "sk",
    ["sl"]    = "sl",
    ["sr"]    = "sr",
    ["sc"]    = "sr-cyrl",
    ["sv"]    = "sv",
    ["tr"]    = "tr",
    ["uk"]    = "uk",
    ["zh"]    = "",
    ["--"]    = "",
}

--- Once a hyphenation pattern file is loaded, we only need the _id_ of it. This is stored in the
--- `languages` table. Key is the filename part (such as `de-1996`) and the value is the internal
--- language id.
languages = {}
languages_id_lang = {}


shape = function(tbl, buf, options)
    local font = tbl.font
    options = options or { }
    local hblang, script, dir

    if options.language then
        hblang = harfbuzz.Language.new(options.language)
        buf:set_language(hblang)
    end
    if options.script then
        script = harfbuzz.Script.new(options.script)
        buf:set_script(script)
    end
    if options.direction then
        dir = harfbuzz.Direction.new(options.direction)
        buf:set_direction(dir)
    end
    buf:set_cluster_level(buf.CLUSTER_LEVEL_MONOTONE_CHARACTERS)
    buf:set_flags(harfbuzz.Buffer.FLAG_REMOVE_DEFAULT_IGNORABLES)
    buf:guess_segment_properties()

    local bufdir = tostring(buf:get_direction())
    local bufscript = tostring(buf:get_script())
    harfbuzz.shape_full(font, buf, tbl.otfeatures, {"ot","graphite2","fallback"})
    if bufdir == "rtl" then
        buf:reverse()
    end
    return bufscript,bufdir
end



file_end("publisher.lua")

-- Mirror each submodule's public functions onto M so that
-- publisher.foo continues to resolve to the same callable, regardless
-- of which file actually defines it.
for _, modname in ipairs({
    "publisher.utilities",
    "publisher.xml_helpers",
    "publisher.images",
    "publisher.language",
    "publisher.attributes",
    "publisher.structure_tree",
    "publisher.drawing",
    "publisher.fontfamilies",
    "publisher.dispatch",
    "publisher.pages",
    "publisher.nodes",
}) do
    for k, v in pairs(require(modname)) do
        M[k] = v
    end
end

return M
