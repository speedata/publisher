-- Here goes everything that does not belong anywhere else. Other parts are font handling, the command
-- list, page and grid setup, debugging and initialization. We start with the function publisher#dothings that
-- initializes some variables and starts processing (publisher#dispatch())
--
--  publisher.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("publisher.lua")

---@class publisher
---@field current_pagestore_name? string
---@field current_group? string
---@field current_grid? Grid
---@field current_page? Page
---@field pagebreak_impossible? boolean
---@field skippages? SkipPages Pending page skip.
---@field minwidth? integer Image size constraints in sp (set per image).
---@field minheight? integer
---@field maxwidth? integer
---@field maxheight? integer
---@field prohibited_at_end table Characters not allowed at the end of a line.
---@field prohibited_at_beginning table Characters not allowed at the start of a line.
local M = {}
-- Publish M into package.loaded right away so that submodules required
-- below can `local publisher = require("publisher")` and get a usable
-- reference even though publisher.lua's main chunk has not finished yet
-- (Lua otherwise re-enters the loader on circular requires and recurses
-- to death).
package.loaded["publisher"] = M
-- splib is set up in sdini.lua and stays a plain _G global for the few
-- entry points (sdscripts.lua, sdini.lua) that don't go through the
-- publisher namespace.
M.splib = splib

M.barcodes = do_luafile("barcodes.lua")
local spotcolors = require("spotcolors")

M.xpath = require("lxpath")
M.xpath.stringmatch = unicode.utf8.match
M.xpath.find_file = kpse.find_file
M.xpath.parse_xml = splib.load_xmlfile
M.xpath.ignoreNS = true

M.hasharfbuzz, M.harfbuzz = pcall(require, "luaharfbuzz")
if not M.hasharfbuzz then
    main.log("warn", "harfbuzz library not found")
end

M.hasharfbuzzsubset, M.harfbuzzsubset = pcall(require, "luaharfbuzzsubset")

require("publisher.commands")
M.fonts = require("publisher.fonts")
local fonts = M.fonts
local uuid = require("uuid")
local colors_module = require("publisher.colors")
local metadata = require("publisher.metadata")
local links_module = require("publisher.links")
M.par = require("par")
uuid.randomseed(tex.randomseed)

M.env_publisherversion = os.getenv("PUBLISHERVERSION")

-- expose helpers from submodules
M.utf8_to_utf16_string_pdf = metadata.utf8_to_utf16_string_pdf

do_luafile("layout_functions.lua")

-- so that node.copy_list copies the node properties
node.set_properties_mode(true)

-- One big point (DTP point, PostScript point) is approx. 65781 scaled points.
---@type integer
M.factor = 65781
-- M.factor = 65781.7

-- no more than this number of frames is allowed on a page
---@type integer
M.maxframes = 999

---@type integer
M.tenpoint_sp = assert(tex.sp("10pt"))
---@type integer
M.twelvepoint_sp = assert(tex.sp("12pt"))
---@type integer
M.tenmm_sp = assert(tex.sp("10mm"))
---@type integer
M.onemm_sp = assert(tex.sp("1mm"))
---@type integer
M.onein_sp = assert(tex.sp("1in"))
---@type integer
M.onept_sp = assert(tex.sp("1pt"))
---@type integer
M.onepc_sp = assert(tex.sp("1pc"))
---@type integer
M.onepp_sp = assert(tex.sp("1pp"))
---@type integer
M.onedd_sp = assert(tex.sp("1dd"))
---@type integer
M.onecc_sp = assert(tex.sp("1cc"))
---@type integer
M.onecm_sp = M.tenmm_sp
---@type integer
M.fivemm_sp = assert(tex.sp("5mm"))

-- User has a pro plan
---@type boolean
M.pro = false

---@type boolean
M.has_pro_error = false

-- Attributes
-- ----------
-- Attributes are attached to nodes, so we can store information that are not present in the
-- nodes themselves or are evaluated later on (such as font selection - when generating glyph
-- nodes, we don't yet know what font the user will use).
--
-- Attributes may have any number, they just need to be constant across the whole source.
-- The attributes value must also be a number.

-- Instead of storing strings we store indexes to strings based on the attributes table.
-- Note: there are also properties in LuaTeX which are much more flexible, we use the old mechanism
-- because in disc nodes, the attributes are inherited (as far as I can see).
---
-- Maps an attribute name to either `true` (any value allowed) or to an
-- array of allowed string values (e.g. `{"italic","oblique"}`).
---@type table<string, true|string[]>
M.attributes = {
    ["background-color"] = true,
    ["bgpaddingbottom"] = true,
    ["bgpaddingtop"] = true,
    ["bordernumber"] = true,
    ["borderwd"] = true,
    ["borderht"] = true,
    ["borderdp"] = true,
    ["color"] = true,
    ["font-style"] = { "italic", "oblique" },
    ["font-weight"] = { "normal", "bold" },
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
    ["text-decoration-line"] = { "underline", "overline", "line-through" },
    ["text-decoration-style"] = { "solid", "double", "dotted", "dashed", "wavy" },
    ["transparency"] = true,
    ["underline_color"] = true,
    ["underline"] = true,
    ["vertical-align"] = { "baseline", "top", "middle", "bottom", "sub", "super" },
}

---@type table<string, integer>
M.attribute_name_number = {}
---@type table<integer, string>
M.attribute_number_name = {}
do
    local c = 1
    local sorted_keys = {}
    -- attribute sorting is just for debugging purposes
    for k, _ in pairs(M.attributes) do
        sorted_keys[#sorted_keys + 1] = k
    end
    table.sort(sorted_keys)
    for _, k in ipairs(sorted_keys) do
        M.attribute_name_number[k] = c
        M.attribute_number_name[c] = k
        c = c + 1
    end
end

M.att_rows = 98 -- see text formats for details

-- These attributes are for image shifting. The amount of shift up/left can
-- be negative and is counted in scaled points.
M.att_shift_left = 100
M.att_shift_up = 101

-- A tie glue (U+00A0) is a non-breaking space
M.att_tie_glue = 201

-- These attributes are used in tabular material
M.att_space_prio = 300
M.att_space_amount = 301

M.att_break_below_forbidden = 400
M.att_break_above = 401
M.att_omit_at_top = 402
M.att_use_as_head = 403
-- HTML tables should not be paragraph:format()ted
M.att_dont_format = 404
M.att_margin_newcolumn = 405
M.att_margin_top_boxstart = 406
M.att_ignore_orphan_widowsetting = 407

M.att_margin_top = 450
M.att_margin_bottom = 451

M.att_break_before = 452

-- `att_is_table_row` is used in `tabular.lua` and if set to 1, it denotes
-- a regular table row, and not a spacer. Spacers must not appear
-- at the top or the bottom of a table, unless forced to.
M.att_is_table_row = 500
M.att_tr_dynamic_data = 501

-- for border-collapse (vertical)
M.att_tr_shift_up = 550

-- Force a hbox line height
M.att_lineheight = 600
M.att_dontadjustlineheight = 601

-- server-mode / line breaking (not used anymore?)
M.att_keep = 700

-- attributes for glue
M.att_leaderwd = 800
M.att_tablenewpage = 801

-- mknodes
M.att_newline = 900

-- PDF/UA - tagged PDF
M.att_role = 1000

M.user_defined_addtolist = 1
M.user_defined_bookmark = 2
M.user_defined_mark = 3
M.user_defined_marker = 4
M.user_defined_mark_append = 5

M.disc_node = node.id("disc")
M.dir_node = node.id("dir")
M.glue_node = node.id("glue")
M.glue_spec_node = node.id("glue_spec")
M.glyph_node = node.id("glyph")
M.hlist_node = node.id("hlist")
M.kern_node = node.id("kern")
M.penalty_node = node.id("penalty")
M.rule_node = node.id("rule")
M.vlist_node = node.id("vlist")
M.whatsit_node = node.id("whatsit")

for k, v in pairs(node.whatsits()) do
    if v == "user_defined" then
        -- for mark command
        M.user_defined_whatsit = k
    elseif v == "pdf_refximage" then
        M.pdf_refximage_whatsit = k
    elseif v == "pdf_action" then
        M.pdf_action_whatsit = k
    elseif v == "pdf_dest" then
        M.pdf_dest_whatsit = k
    elseif v == "pdf_start_link" then
        M.pdf_start_link_whatsit = k
    elseif v == "pdf_literal" then
        M.pdf_literal_whatsit = k
    end
end

-- sd:alternating
-- Current position per alternating group.
---@type table<string, integer>
M.alternating = {}
-- Last returned value per alternating group (for sd:keep-alternating).
---@type table<string, string>
M.alternating_value = {}

-- the return value for the LuaTeX process
---@type integer
M.errorcode = 0

-- sp --mode foo sets modes.foo = true
---@type table<string, boolean>
M.modes = {}

-- page numbers go from 1 to n. If reordering is necessary, we insert
-- a different index into the pagenum_tbl.
-- A value of {1,2,6,7,3,4,5} means place page 1 on position one, page 2 on
-- position two, page 6 on position three and so on
---@type integer[]
M.pagenum_tbl = {}
---@type table<string, boolean>
M.forward_pagestore = {}
---@type integer
M.total_inserted_pages = 0

---@class Pagelabel
---@field pagenumber integer User-visible page number.
---@field matter string Name of the matter this page belongs to (key in `matters`).

-- pagelabel contains information about a page (see shipout() and get_page_labels_str() ).
-- Indexed by real page number.
---@type table<integer, Pagelabel>
M.pagelabels = {}

-- An array of strings - a mapping of real page numbers and user visible page numbers.
---@type string[]
M.visible_pagenumbers = {}

---@class Matter
---@field label string Numbering style, e.g. `"decimal"`, `"lowercase-romannumeral"`.
---@field resetafter? boolean Reset the page counter after this matter ends.
---@field resetbefore? boolean Reset the page counter before this matter starts.
---@field prefix? string String prepended to the formatted page number.

---@type table<string, Matter>
M.matters = {
    mainmatter = { label = "decimal", resetafter = false, resetbefore = true, prefix = "" },
    frontmatter = { label = "lowercase-romannumeral" },
}

---@type string
M.default_areaname = "_page"
---@type string
M.default_area = "_page"

-- The name of the next requested page
---@type string?
M.nextpage = nil

-- The document language
---@type integer
M.defaultlanguage = 0

-- Start page
---@type number
M.current_pagenumber = 1

-- Expected number of pages (from previous run's aux file), nil if unknown
---@type integer?
M.expected_pages = nil

-- Previous run duration in seconds (from status file), nil if unknown
---@type number?
M.previous_duration = nil

---@type table<integer, table>
M.pages = {}

-- page n shipped out to PDF?
---@type table<integer, boolean>
M.pages_shippedout = {}

-- CSS properties. Use `:matches(tbl)` to find a matching rule. `tbl` has the following structure: `{element=..., id=..., class=... }`
M.css = do_luafile("css.lua"):new()

---@class Options
---@field background string? Background color of the page.
---@field colorprofile string? Name of the color profile
---@field cutmarks boolean
---@field crop boolean | string | nil The amount of crop to be added to each side of a page
---@field default_pageheight? integer Default page height in scaled points.
---@field default_pagewidth? integer Default page width in scaled points.
---@field default_zugferdfile? string Default ZUGFeRD invoice file name.
---@field displaymode? "UseAttachments"|"UseOutlines"|"FullScreen"|"UseThumbs" PDF viewer display mode.
---@field documentauthor string
---@field documentcreator? string
---@field documentkeywords string
---@field documentproducer? string
---@field documentsubject string
---@field documenttitle string The document title.
---@field dpi? number Resolution for pixel to sp conversion.
---@field dumpstructtree boolean Writes the PDF/UA structure tree to a file (-struct.xml).
---@field extensionhandler string?
---@field fontshrink number?
---@field fontstep number?
---@field fontstretch number?
---@field format "PDF/UA"|"PDF/X-3"|"PDF/X-4"|"PDF/X-3:2002"|"PDF/A-3"|"" PDF output format ("PDF/X-3" is normalized to "PDF/X-3:2002" in commands.pdfoptions)
---@field gridcells_dx? integer Horizontal gap between grid cells in sp.
---@field gridcells_dy? integer Vertical gap between grid cells in sp.
---@field gridcells_x integer Number of grid cells horizontally (0 = auto).
---@field gridcells_y integer Number of grid cells vertically (0 = auto).
---@field gridheight integer Grid cell height in scaled points.
---@field gridlocation "background"|"foreground"|"none" Where the debug grid is drawn.
---@field gridwidth integer Grid cell width in scaled points.
---@field hidespinfo? string|boolean
---@field html? string HTML rendering mode.
---@field htmlignoreeol? boolean Ignore newlines in HTML mode (FontForge backend).
---@field hyperlinkbordercolor? string Border color for hyperlink annotations.
---@field hyperlinkborderwidth integer Border width for hyperlink annotations, in sp.
---@field ignoreeol boolean Ignore newlines in data.
---@field imagehandler string?
---@field imagenotfounderror boolean Raise an error when an image cannot be found.
---@field interaction boolean Disable interaction if set to false.
---@field markdownextensions table<string, any>
---@field mpcolorwarning boolean
---@field namespaces "lax"|"strict" XML namespace handling mode.
---@field overfulllineerror? boolean Treat overfull lines as errors (nil = ignore).
---@field pageheight? integer Page height in sp (set by Pageformat).
---@field pagelayout? "SinglePage"|"OneColumn"|"TwoColumnLeft"|"TwoColumnRight"|"TwoPageLeft"|"TwoPageRight" PDF viewer page layout.
---@field pagewidth? integer Page width in sp (set by Pageformat).
---@field reportmissingglyphs boolean|string
---@field resetmarks boolean
---@field resizehandler string?
---@field showassignments boolean Show all assignments.
---@field showdebug boolean Shows lots of markup.
---@field showgrid boolean Show grid.
---@field showgridallocation boolean Allocated grid cells are colored.
---@field showgroups boolean Show groups.
---@field showhyperlinks? boolean Draw a border around hyperlinks.
---@field showhyphenation boolean Show all possible hyphenation points.
---@field showkerning boolean Show kerning marks.
---@field showobjects boolean Draw a line around objects.
---@field showtextformat boolean Create tooltip that shows the current textformat.
---@field startpage number Start page (defaults to 1)
---@field tablerulefix boolean Fix table rules for better display in Adobe Acrobat.
---@field trace boolean
---@field trim? integer Bleed amount in sp.
---@field trimmarks boolean
---@field verbosity number
---
-- Further fields are populated from the layout instructions XML at runtime.

-- The defaults (set in the layout instructions file)
---@type Options
M.options = {
    cutmarks = false,
    documentauthor = "",
    documentkeywords = "",
    documentsubject = "",
    documenttitle = "",
    dumpstructtree = false,
    format = "",
    gridcells_x = 0,
    gridcells_y = 0,
    gridheight = M.tenmm_sp,
    gridlocation = "background",
    gridwidth = M.tenmm_sp,
    hyperlinkborderwidth = M.onept_sp,
    ignoreeol = false,
    imagenotfounderror = true,
    interaction = true,
    markdownextensions = {},
    mpcolorwarning = true,
    namespaces = "lax",
    reportmissingglyphs = "",
    resetmarks = false,
    showassignments = false,
    showdebug = false,
    showgrid = false,
    showgridallocation = false,
    showgroups = false,
    showhyphenation = false,
    showkerning = false,
    showobjects = false,
    showtextformat = false,
    startpage = 1,
    tablerulefix = false,
    trace = false,
    trimmarks = false,
    verbosity = 0,
}

---@type string
M.current_layout_line = ""
---@type string
M.current_layout_file = ""
---@type string
M.current_data_line = ""

---@class Group
---@field contents? Node Head of the node list that holds the group's content (nil until the group is filled).
---@field grid table Grid associated with the group.

-- List of virtual areas. Key is the group name and value is
-- a hash with keys contents (a nodelist) and grid (grid).
---@type table<string, Group>
M.groups = {}

-- sometimes we want to save pages for later reuse. Keys are pagestore names.
-- In backward mode the value is a list of vpacked pages with a `grids`
-- sub-table holding each page's grid (needed for TrimBox/BleedBox at
-- InsertPages time), in forward mode a table with insert metadata.
---@type table<string, table>
M.pagestore = {}

---@class Compatibility
---@field movecursoronrightedge boolean

-- See commands.compatibility
---@type Compatibility
M.compatibility = {
    movecursoronrightedge = true,
}

-- for external image conversion software. Key is the image type (or "*"),
-- value is the command line template of the external converter.
---@type table<string, string>
M.imagehandler = {}
---@type table<string, string>
M.resizehandler = {}

---@type table<string, any>
M.viewerpreferences = {}

-- Hyperlinks are stored in publisher.links (links_module) to be inserted later
-- in the pre shipout filter.
links_module.reset()

-- marker counter. Each mark will get its unique counter, so we can determine the
-- order in which markers appear.
---@type integer
M.markercount = 0
---@type table<string, integer>
M.marker_min = {}
---@type table<string, integer>
M.marker_max = {}
---@type table<string, any>
M.marker_id_value = {}

-- metapost graphics. Keys are name and values are "beginfig(1)...." texts.
---@type table<string, string>
M.metapostgraphics = {}

-- A color definition handed over to the MetaPost interpreter.
---@class MetapostColor
---@field model "rgb"|"cmyk"|"gray"
---@field r? number
---@field g? number
---@field b? number
---@field c? number
---@field m? number
---@field y? number
---@field k? number

---@type table<string, MetapostColor>
M.metapostcolors = {}

-- A typed variable declaration for MetaPost graphics (element `SetVariable`).
---@class MetapostVariable
---@field typ string MetaPost type (`numeric`, `string`, ...).
---@field [1] any Variable contents.

---@type table<string, MetapostVariable>
M.metapostvariables = {}

-- Pairs of {original color name, sanitized MetaPost color name}.
---@type [string, string][]
M.metapostcolorwarnings = {}

-- The current foreground color index (used in underline)
---@type integer?
M.current_fgcolor = nil

-- The color stack to use
---@type integer
M.defaultcolorstack = 0

-- Key is the processing mode, value maps an element name to the Record
-- layout XML element that handles it.
---@type table<string, table<string, table>>
M.data_dispatcher = {}
-- Key is the processing mode, value is a list of compiled match patterns
-- sorted by priority (see commands.record).
---@type table<string, {pattern: string, priority: number, layoutxml: table, matchfunc: function?}[]>
M.data_dispatcher_patterns = {}
---@type { last: integer, [string]: function }
M.user_defined_functions = { last = 0 }

---@type table<string, any>
M.markers = {}

-- PDF/UA - the /S /Document StructElem
local ktree = pdf.reserveobj()

---@class StructElement
---@field obj integer PDF object number of the structure element.
---@field role string PDF/UA role (e.g. `"Document"`, `"P"`, `"Figure"`).
---@field added_tables? table<string, string> Auxiliary lookup of already-added child tables.
---@field bbox? [string, string, string, string] Bounding box as `{llx, lly, urx, ury}` strings.
---@field page? integer PDF page object number the element appears on.
---@field actualtext? string Replacement text for the contents (PDF `/ActualText`).
---@field alttext? string Alternative description (PDF `/Alt`).
---@field linkobjects? integer[] PDF object numbers of associated link annotations.
---@field text? string Alternative text / contents.
---@field [integer] StructElement|integer Child structure elements or MCID numbers.

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
---@type table<string, StructElement>
M.structElements = {}

-- paragraph, table and textblock should set them
---@type integer
M.current_fontfamily = 0

---@type table<string, string>
M.fontaliases = {}

---@class FontGroupVariant
---@field regular table<string, string> Mapping of source kind (e.g. `"local"`) to font name.
---@field bold table<string, string>
---@field italic table<string, string>
---@field bolditalic table<string, string>

-- for HTML / CSS font families
---@type table<string, FontGroupVariant>
M.fontgroup = {
    ["sans-serif"] = {
        regular = { ["local"] = "sans" },
        bold = { ["local"] = "sans-bold" },
        italic = { ["local"] = "sans-italic" },
        bolditalic = { ["local"] = "sans-bolditalic" },
    },
    ["serif"] = {
        regular = { ["local"] = "serif" },
        bold = { ["local"] = "serif-bold" },
        italic = { ["local"] = "serif-italic" },
        bolditalic = { ["local"] = "serif-bolditalic" },
    },
    ["monospace"] = {
        regular = { ["local"] = "monospace" },
        bold = { ["local"] = "monospace-bold" },
        italic = { ["local"] = "monospace-italic" },
        bolditalic = { ["local"] = "monospace-bolditalic" },
    },
}

-- Used when bookmarks are inserted in a non-text context
---@type integer
M.intextblockcontext = 0

---@class Masterpage
---@field is_pagetype string XPath expression evaluated to decide if this masterpage applies.
---@field res table Layout XML instructions for this masterpage.
---@field name string Name of the masterpage.
---@field ns? table Namespace mapping (legacy XPath parser only).

---@type Masterpage[]
M.masterpages = {}

-- if true, look for lowercase files
---@type boolean
M.lowercase = false

---@alias TextformatAlignment
---| "leftaligned"
---| "rightaligned"
---| "centered"
---| "justified"
---| "start"
---| "end"

---@class Textformat
---@field indent integer Indentation in scaled points (sp).
---@field alignment TextformatAlignment
---@field rows? integer Number of rows that the format applies to.
---@field orphan integer Minimum lines kept at the bottom of a page when breaking.
---@field widow integer Minimum lines kept at the top of a page when breaking.
---@field name? string Name of the textformat (matches the table key).
---@field disable_hyphenation? boolean Suppress hyphenation for this format.
---@field break_before? "page" | "always" | "" allow break before this paragraph.
---@field break_after? string Break behaviour after this paragraph ("avoid").
---@field breakbelow? boolean allow break after this paragraph.
---@field paddingtop? number Padding above the paragraph in sp.
---@field colpaddingtop? number Padding above the paragraph in table cells, in sp.
---@field bordertop? number Width of the rule above the paragraph in sp.
---@field borderbottom? number Width of the rule below the paragraph in sp.
---@field border_top_width? number
---@field border_bottom_width? number
---@field margintop? number Vertical margin above the paragraph in sp.
---@field marginbottom? number Vertical margin below the paragraph in sp.
---@field margintopboxstart? number Margin above the paragraph at the top of a box, in sp.
---@field letterspacing? number Letter spacing in em.
---@field cssfontsize? boolean Use the CSS font size handling.
---@field hyphenchar? string Hyphenation character override.
---@field htmlverticalspacing? string Vertical spacing mode for HTML ("inner", ...).
---@field tab? any Tab handling configuration.

-- Text formats is a hash with arbitrary names as keys and the values
-- are tables with alignment and indent. indent is the amount of
-- indentation in sp.
---@type table<string, Textformat>
M.textformats = {

    text = { indent = 0, alignment = "justified", rows = 1, orphan = 2, widow = 2, name = "text" },
    __centered = { indent = 0, alignment = "centered", rows = 1, orphan = 2, widow = 2, name = "__centered" },
    __leftaligned = { indent = 0, alignment = "leftaligned", rows = 1, orphan = 2, widow = 2, name = "__leftaligned" },
    __rightaligned = {
        indent = 0,
        alignment = "rightaligned",
        rows = 1,
        orphan = 2,
        widow = 2,
        name = "__rightaligned",
    },
    __justified = { indent = 0, alignment = "justified", rows = 1, orphan = 2, widow = 2, name = "__justified" },
    justified = { indent = 0, alignment = "justified", rows = 1, orphan = 2, widow = 2, name = "justified" },
    centered = { indent = 0, alignment = "centered", rows = 1, orphan = 2, widow = 2, name = "centered" },
    left = { indent = 0, alignment = "leftaligned", rows = 1, orphan = 2, widow = 2, name = "left" },
    right = { indent = 0, alignment = "rightaligned", rows = 1, orphan = 2, widow = 2, name = "right" },
    __fivemm = { indent = M.fivemm_sp, alignment = "justified", rows = 1, orphan = 2, widow = 2 },
}

---@class Bookmark
---@field name string Title text of the bookmark.
---@field destination string Destination identifier (anchor name in the PDF).
---@field open? boolean Whether sub-bookmarks are visible by default.
---@field [integer] Bookmark Nested child bookmarks.

-- The bookmarks table has the format
--
--     bookmarks = {
--       { -- first bookmark
--         name = "outline 1" destination = "..." open = true,
--          { name = "outline 1.1", destination = "..." },
--          { name = "outline 1.2", destination = "..." }
--       },
--       { -- second bookmark
--         name = "outline 2" destination = "..." open = false,
--          { name = "outline 2.1", destination = "..." },
--          { name = "outline 2.2", destination = "..." }
--
--       }
--     }
---@type Bookmark[]
M.bookmarks = {}

-- We need the separator for writing files in a directory structure (image cache for now)
---@type string
M.os_separator = "/"
if os.type == "windows" then
    M.os_separator = "\\"
end

-- A very large length
---@type integer
M.maxdimen = 1073741823

-- this should be 0x100000 (= 1048576), but this is easier to work with in the
-- layout. For example you want to insert a glyph id 467, then you can write
-- &#1100467; in the layout xml. Let me not make this public until I proof that
-- it works.
---@type integer
M.puastart = 1100000

-- It's convenient to just copy the stretching glue instead of writing
-- the stretch etc. over and over again.
---@type Node
M.glue_stretch2 = set_glue(nil, { stretch = 2 ^ 16, stretch_order = 2 })

-- For attached files. Each of this numbers should appear in the catalog
---@type integer[]
M.filespecnumbers = {}

-- Returns six values (alternating key/value pairs) describing the current
-- layout/data location, or `nil` when the legacy xpath parser is active.
---@return string? line_layout_label
---@return string? line_layout_value
---@return string? file_label
---@return string? file_value
---@return string? line_data_label
---@return string? line_data_value
function M.lineinfo()
    return "line_layout", M.current_layout_line, "file", M.current_layout_file, "line_data", M.current_data_line
end

---@type string[]
M.roles_a = {
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
---@type integer
M.rolecounter = 0

-- Start the processing (`dothings()`)
-- -------------------------------
-- This is the entry point of the processing. It is called from publisher.spinit.
---@return nil
function M.dothings()
    main.log("info", string.format("Running LuaTeX version %s on %s", luatex_version, os.name))
    -- First we set some defaults.
    -- A4 paper is 210x297 mm
    local wd_sp = assert(tex.sp("210mm"))
    local ht_sp = assert(tex.sp("297mm"))
    M.page_helpers.set_pageformat(wd_sp, ht_sp)
    M.options.default_pagewidth = wd_sp
    M.options.default_pageheight = ht_sp

    M.language.get_languagecode(os.getenv("SP_MAINLANGUAGE") or "en_GB")

    M.lowercase = os.getenv("SP_IGNORECASE") == "1"
    local extra_parameter = { otfeatures = { kern = true, liga = false } }
    -- The free font family `TeXGyreHeros` is a Helvetica clone and is part of the
    -- [The TeX Gyre Collection of Fonts](http://www.gust.org.pl/projects/e-foundry/tex-gyre).
    -- We ship it in the distribution.
    fonts.load_fontfile("TeXGyreHeros-Regular", "texgyreheros-regular.otf", extra_parameter)
    fonts.load_fontfile("TeXGyreHeros-Bold", "texgyreheros-bold.otf", extra_parameter)
    fonts.load_fontfile("TeXGyreHeros-Italic", "texgyreheros-italic.otf", extra_parameter)
    fonts.load_fontfile("TeXGyreHeros-BoldItalic", "texgyreheros-bolditalic.otf", extra_parameter)

    -- These are used in HTML mode when the user switches to monospace or serif
    fonts.load_fontfile("CrimsonPro-Regular", "CrimsonPro-Regular.ttf", extra_parameter)
    fonts.load_fontfile("CrimsonPro-Bold", "CrimsonPro-Bold.ttf", extra_parameter)
    fonts.load_fontfile("CrimsonPro-Italic", "CrimsonPro-Italic.ttf", extra_parameter)
    fonts.load_fontfile("CrimsonPro-BoldItalic", "CrimsonPro-BoldItalic.ttf", extra_parameter)

    fonts.load_fontfile("CamingoCode-Regular", "CamingoCode-Regular.ttf", extra_parameter)
    fonts.load_fontfile("CamingoCode-Bold", "CamingoCode-Bold.ttf", extra_parameter)
    fonts.load_fontfile("CamingoCode-Italic", "CamingoCode-Italic.ttf", extra_parameter)
    fonts.load_fontfile("CamingoCode-BoldItalic", "CamingoCode-BoldItalic.ttf", extra_parameter)

    -- Define a basic font family with name `text`:
    M.fontfamilies.define_default_fontfamily()

    local _sampler
    if os.getenv("SP_PROFILE") then
        _sampler = require("sampler")
        _sampler.start(tonumber(os.getenv("SP_PROFILE")) or 10000)
    end
    M.initialize_luatex_and_generate_pdf()
    if _sampler then
        _sampler.stop()
        _sampler.report("profile.txt")
    end
    -- The last thing is to put a stamp in the PDF
    if M.options.hidespinfo and M.options.hidespinfo == "true" or M.options.hidespinfo == "yes" then
        -- do nothing
        if not M.pro then
            main.log("error", "Removing speedata info needs a pro plan")
            M.has_pro_error = true
            return nil
        end
    else
        pdf.obj({
            type = "raw",
            string = "(Created with the speedata Publisher - www.speedata.de)",
            immediate = true,
            objcompression = false,
        })
    end
end

-- Extracts the extension from a filename, e.g. `"foo.png"` → `"png"`.
-- Returns `nil` if there is no dot in the name.
---@param fn string
---@return string?
function M.get_extension(fn)
    return fn:match("^.+%.(.+)$")
end

-- Registers a `find_image_file` callback that maps `extension → handler` based
-- on a `;`-separated string, e.g. `"svg:rsvg;eps:gs"`.
---@param extensionhandler string? `ext1:handler1;ext2:handler2;...`
---@return nil
function M.define_image_callback(extensionhandler)
    local extensions = {}
    if extensionhandler and extensionhandler ~= "" then
        for _, v in ipairs(string.explode(extensionhandler, ";")) do
            local _, _, ext, handler = string.find(v, "^(.*):(.*)$")
            extensions[ext] = handler
        end
    end

    ---@param asked_name string
    ---@return string? file Resolved file path (after optional conversion), or `nil`.
    local function find_image_file(asked_name)
        local file = kpse.find_file(asked_name)
        local ext = M.get_extension(asked_name)
        local handlername = extensions[ext]
        local handler = M.imagehandler[handlername or "*"]
        if file and handler then
            main.log("info", "Convert image", "extension", ext, "handler", handlername or "*")
            file = splib.convertimage(file, handler)
        end
        return file
    end
    callback.register("find_image_file", find_image_file)
end

---@type table<integer, table>
M.borderattributes = {}
do
    -- the idea of flatten_boxes is to return an array that only has
    -- par objects.
    -- The input of flatten_boxes is a mix of Box objects and Par objects.
    -- You can consider Box objects something similar to <div> blocks in HTML
    -- and Par objects like <p> that has actual content in it (also: images and other stuff)
    -- Margin settings should go from <div> to the <p> (from Box to Par) so we can
    -- leave out the div stuff.
    local prependbox

    -- Recursively flattens a tree of Box objects (similar to HTML `<div>`s)
    -- and Par objects (similar to `<p>`s) into a flat array of Par objects,
    -- propagating margin/padding/border settings down to the actual paragraphs.
    ---@param box table Mixed tree of Box and Par objects.
    ---@param parameter? table Inherited parameters (currently `indent`).
    ---@param ret? table Accumulator for the flat result; created if absent.
    ---@return table ret Array of Par objects.
    function M.flatten_boxes(box, parameter, ret)
        ret = ret or {}
        parameter = parameter or {}
        local indent = box.indent_amount or 0
        if indent and parameter.indent then
            indent = parameter.indent + indent
        end
        local new_parameter = {
            indent = indent,
        }
        if box.prependbox and #box.prependbox > 0 then
            prependbox = prependbox or {}
            for i = 1, #box.prependbox do
                table.insert(prependbox, box.prependbox[i])
            end
        end

        if box.padding_bottom and box.padding_bottom ~= 0 then
            box[1].padding_bottom = box.padding_bottom
        end
        if box.padding_top and box.padding_top ~= 0 then
            box[1].padding_top = box.padding_top
        end
        if box.draw_border then
            M.borderattributes[#M.borderattributes + 1] = box.border
            if #box > 1 then
                box[1].startborder = #M.borderattributes
            else
                box[1].startendborder = #M.borderattributes
            end
        end
        if box.startendborder then
            box[1].startendborder = box.startendborder
        end

        for i = 1, #box do
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
                M.flatten_boxes(thisbox, new_parameter, ret)
                if thisbox.mode == "block" then
                    ret.mode = "block"
                end
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
                    for p = #prependbox, 1, -1 do
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
---@return nil
function M.initialize_luatex_and_generate_pdf()
    M.options.verbosity = tonumber(os.getenv("SP_VERBOSITY")) or 0

    -- The default page type has 1cm margin
    M.masterpages[1] = {
        is_pagetype = "true()",
        res = {
            {
                elementname = "Margin",
                contents = function(page)
                    page.grid:set_margin(M.tenmm_sp, M.tenmm_sp, M.tenmm_sp, M.tenmm_sp)
                end,
            },
        },
        name = "Default Page",
        ns = { [""] = "urn:speedata.de:2009/publisher/en" },
    }

    -- The `vars` file hold a lua document holding table
    local vars
    local varsfun = loadfile(tex.jobname .. ".vars")
    if varsfun then
        vars = varsfun()
    else
        main.log("error", "Could not load .vars file. Something strange is happening.")
        vars = {}
    end

    for i = 4, #arg do
        local k, v = arg[i]:match("^(.+)=(.+)$")
        if k == "mode" then -- everything else handled after loading layout
            v = v:gsub('^"(.*)"$', "%1")
            local _modes = string.explode(v, ",")
            for _, m in ipairs(_modes) do
                M.modes[m] = true
            end
        elseif k == "pro" then
            M.pro = true
            main.log("info", "speedata Publisher Pro")
        end
    end

    -- Both the data and the layout instructions are written in XML.
    local layoutxml = M.xml_helpers.load_xml(arg[2], "layout instructions")
    if not layoutxml then
        main.log("error", "Without a valid layout-XML file, I can't really do anything.")
        exit()
    end
    if type(layoutxml) == "table" then
        layoutxml = layoutxml[1] -- skip document
    else
        main.log("error", "Internal error: layout is not a table")
        return
    end
    if layoutxml == nil then
        main.log("error", "Internal error: layout is empty")
        return
    end
    if type(layoutxml) ~= "table" then
        main.log("error", "Internal error: layout is not a table")
        return
    end
    -- Used in `xpath.lua` to find out which language the function is in.
    local ns = layoutxml[".__namespace"]
    if not ns then
        main.log("error", "Cannot find the namespace of the layout file. What should I do?")
        exit()
    end

    -- The currently active layout language. One of `de` or `en`.
    local current_layoutlanguage = string.gsub(ns, "urn:speedata.de:2009/publisher/", "")
    if not (current_layoutlanguage == "de" or current_layoutlanguage == "en") then
        main.log("error", "Cannot determine the language of the layout file.")
        exit()
    end
    if current_layoutlanguage == "de" then
        main.log("error", "The German layout instructions have been removed\nin version 2.7 of the publisher.")
        exit()
    end
    local version
    local requirements
    local attr = layoutxml[".__attributes"]
    if attr and attr["version"] then
        version = attr["version"]
    end
    if attr and attr["require"] then
        requirements = attr["require"]
    end
    if version then
        local version_mismatch = false
        local publisher_version = string.explode(M.env_publisherversion, ".")
        local requested_version = string.explode(version, ".")

        if publisher_version[1] ~= requested_version[1] then
            if tonumber(publisher_version[1]) < tonumber(requested_version[1]) then
                version_mismatch = true
            end
        elseif tonumber(publisher_version[2]) < tonumber(requested_version[2]) then
            -- major number are same, minor are different
            version_mismatch = true
        elseif
            tonumber(requested_version[3])
            and tonumber(publisher_version[3]) < tonumber(requested_version[3])
            and tonumber(publisher_version[2]) == tonumber(requested_version[2])
        then
            version_mismatch = true
        end
        if version_mismatch then
            main.log(
                "error",
                string.format(
                    "Version mismatch. speedata Publisher is at version %s, requested version %s",
                    M.env_publisherversion,
                    version
                )
            )
            exit()
        end
    end
    if requirements and type(requirements) == "string" then
        local r = string.explode(requirements, ",")
        for _, req in ipairs(r) do
            if req == "lxpath" then
                -- always satisfied, lxpath is the only XML / XPath parser
            elseif req == "luxor" then
                main.log(
                    "error",
                    "failed to meet requirement",
                    "requirement",
                    "luxor",
                    "message",
                    "The luxor XML / XPath parser has been removed in version 6.0"
                )
                exit(false)
            elseif req == "harfbuzz" then
                -- always satisfied, harfbuzz is the only font loader
            elseif req == "fontforge" then
                main.log(
                    "error",
                    "failed to meet requirement",
                    "requirement",
                    "fontforge",
                    "message",
                    "The fontforge font loader has been removed in version 6.0"
                )
                exit(false)
            else
                main.log(
                    "error",
                    string.format(
                        "This layout requires feature %q, but I don't know what it is.\nPerhaps I am too old?",
                        req
                    )
                )
                exit(false)
            end
        end
    end
    -- We allow the use of a dummy xml file for testing purpose
    local dataxml
    local datafilename = arg[3]
    if datafilename == "-dummy" then
        dataxml = splib.loadxmlstring("<data />")
    elseif datafilename == "-" then
        main.log("info", "Reading from stdin")
        dataxml = splib.loadxmlstring(io.stdin:read("*a"))
    else
        dataxml = M.xml_helpers.load_xml(
            datafilename,
            "data file",
            { htmlentities = true, ignoreeol = (M.options.ignoreeol or false) }
        )
    end
    if not dataxml then
        main.log("error", "Could not read data")
        exit()
        return
    end
    if type(dataxml) ~= "table" then
        main.log("error", "Something is wrong with the data: dataxml is not a table")
        exit()
        return
    end

    local defaults = {
        _bleed = "0mm",
        _pageheight = "297mm",
        _pagewidth = "210mm",
        _jobname = tex.jobname,
        _matter = "mainmatter",
        __maxwidth = tex.sp("190mm"),
        _lastpage = 1,
    }
    M.data = M.xpath.context:new()
    M.data.xmldoc = { dataxml }
    M.data.sequence = { dataxml }
    M.data.namespaces = layoutxml[".__ns"]

    for k, v in pairs(defaults) do
        M.data.vars[k] = v
    end

    -- from command line or publisher.cfg:
    for k, v in pairs(vars) do
        M.data.vars[k] = v
    end
    local mode_keys = {}
    for k, _ in pairs(M.modes) do
        mode_keys[#mode_keys + 1] = k
    end
    table.sort(mode_keys)
    M.data.vars._mode = table.concat(mode_keys, ",")

    local _, msg = M.data:execute("root()")
    if msg then
        main.log("error", msg)
    end

    M.dispatch.dispatch(layoutxml, M.data)
    -- for namespace mode == strict
    M.data.namespaces = dataxml[1][".__ns"]

    -- options.ignoreeol is now set.
    -- In DataMode, element metatables are already set during
    -- Go XML parsing, so fixup_xmlfile only needs to run if ignoreeol
    -- was set in the layout (after loading) and wasn't handled by Go.
    local needs_eol = (M.options.ignoreeol or false) and not dataxml.ignoreeol_done
    if needs_eol then
        M.xml_helpers.fixup_xmlfile(dataxml, true)
    end

    -- We define two graphic states for overprinting on and off.
    M.GS_State_OP_On = pdf.immediateobj([[<< /Type/ExtGState /OP true /OPM 1 >>]])
    M.GS_State_OP_Off = pdf.immediateobj([[<< /Type/ExtGState /OP false >>]])

    -- override options set in the `<Options>` element
    for i = 4, #arg do
        local k, v = arg[i]:match("^(.+)=(.+)$")
        if k ~= "mode" then -- mode handled before loading layout
            v = v:gsub('^"(.*)"$', "%1")
            M.options[k] = v
        end
    end

    if M.options.interaction == "false" then
        M.options.interaction = false
    elseif M.options.interaction == "true" then
        M.options.interaction = true
    end

    if M.options.showgrid == "false" then
        M.options.showgrid = false
    elseif M.options.showgrid == "true" then
        M.options.showgrid = true
    end

    if M.options.cutmarks == "true" then
        M.options.cutmarks = true
    elseif M.options.cutmarks == "false" then
        M.options.cutmarks = false
    end

    if M.options.trimmarks == "true" then
        M.options.trimmarks = true
    elseif M.options.trimmarks == "false" then
        M.options.trimmarks = false
    end

    if M.options.showgridallocation == "false" then
        M.options.showgridallocation = false
    elseif M.options.showgridallocation == "true" then
        M.options.showgridallocation = true
    end

    if M.options.reportmissingglyphs == "false" or M.options.reportmissingglyphs == "no" then
        M.options.reportmissingglyphs = false
    elseif M.options.reportmissingglyphs == "true" or M.options.reportmissingglyphs == "yes" then
        M.options.reportmissingglyphs = true
    elseif M.options.reportmissingglyphs == "warning" then
        M.options.reportmissingglyphs = "warning"
    end

    if M.options.imagehandler then
        string.gsub(M.options.imagehandler, "([a-zA-Z*]+):%((.-)%);?", function(imagetype, cmdline)
            M.imagehandler[imagetype] = cmdline
        end)
    end

    if M.options.resizehandler then
        string.gsub(M.options.resizehandler, "([a-zA-Z*]+):%((.-)%);?", function(imagetype, cmdline)
            M.resizehandler[imagetype] = cmdline
        end)
    end

    M.define_image_callback(M.options.extensionhandler or "")

    -- Set the starting page (which must be a number)
    if M.options.startpage then
        local num = M.options.startpage
        if num then
            local tmp = tonumber(num)
            if tmp then
                M.current_pagenumber = tmp
                main.log("info", string.format("Set page number to %d", num))
            end
        else
            main.log("error", "Can't recognize starting page number", "startpage", M.options.startpage or "(not set)")
        end
    end

    if M.options.colorprofile then
        spotcolors.set_colorprofile_filename(M.options.colorprofile)
        main.log(
            "warn",
            "Options / colorprofile is obsolete. Use DefineColorprofile and PDFOptions / colorprofile instead."
        )
    end

    if M.options.format == "PDF/UA" and not M.structElements[".root"] then
        M.structElements[".root"] = {
            role = "Document",
            obj = pdf.reserveobj(),
        }
        M.structElements["doc"] = M.structElements[".root"]
    end

    local auxfilename = tex.jobname .. "-aux.xml"
    -- load help file if it exists
    if kpse.find_file(auxfilename) and M.options.resetmarks == false then
        local mark_tab = M.xml_helpers.load_xml(auxfilename, "aux file", { htmlentities = true, ignoreeol = true })
        if mark_tab then
            mark_tab = mark_tab[1]
        end
        mark_tab = mark_tab or {}
        for i = 1, #mark_tab do
            local mt = mark_tab[i]
            if type(mt) == "table" then
                local attributes
                attributes = mt[".__attributes"]
                if mt[".__local_name"] == "mark" then
                    M.markers[attributes.name] = { page = attributes.page }
                    local id = tonumber(attributes.id)
                    if id then
                        M.marker_id_value[id] = { page = attributes.page, name = attributes.name }

                        local pagenumber = tonumber(attributes.page)
                        if pagenumber then
                            if not M.marker_min[pagenumber] then
                                M.marker_min[pagenumber] = id
                            elseif M.marker_min[pagenumber] > id then
                                M.marker_min[pagenumber] = id
                            end
                            if not M.marker_max[pagenumber] then
                                M.marker_max[pagenumber] = id
                            elseif M.marker_max[pagenumber] < id then
                                M.marker_max[pagenumber] = id
                            end
                        end
                    end
                elseif mt[".__local_name"] == "pagelabel" then
                    M.visible_pagenumbers[tonumber(attributes.pagenumber)] = attributes.visible
                elseif mt[".__local_name"] == "lastpage" then
                    M.data.vars["_lastpage"] = attributes.page
                    M.expected_pages = tonumber(attributes.page)
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
            M.previous_duration = tonumber(dur)
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

    -- Start data processing in the default mode (`""`)
    local name, tmp
    local seq
    _, msg = M.data:execute("root()")
    if msg then
        main.log("error", msg)
    end
    if M.options.namespaces == "strict" then
        seq, msg = M.data:eval("local-name()")
        if msg then
            main.log("error", msg)
        end
        name = M.xpath.string_value(seq)
        seq, msg = M.data:eval("namespace-uri()")
        if msg then
            main.log("error", msg)
        end
        local namespace_element = M.xpath.string_value(seq)
        name = "{" .. namespace_element .. "}" .. name
    else
        seq, msg = M.data:eval("local-name()")
        if msg then
            main.log("error", msg)
        end
        name = M.xpath.string_value(seq)
    end

    -- The rare case that the user has not any `Record` commands in the layout file:
    if not M.data_dispatcher[""] and not M.data_dispatcher_patterns[""] then
        main.log("error", "Can't find any “Record” commands in the layout file.")
        exit()
    end

    tmp = M.data_dispatcher[""] and M.data_dispatcher[""][name]
    -- Pattern matching fallback for root element
    if not tmp then
        local rootnode = M.data.sequence and M.data.sequence[1]
        if rootnode then
            tmp = M.dispatch.find_matching_pattern("", rootnode, M.data)
        end
    end
    if tmp then
        -- For data:eval, the namespaces must be set the layout namespaces
        M.data.namespaces = layoutxml[".__ns"]
        M.dispatch.dispatch(tmp, M.data)
    else
        name = name or ""
        local elt_ns, elt_localname = string.match(name, "{(.*)}(.*)")
        if elt_ns then
            main.log(
                "error",
                "Can't find “Record” command for the root node",
                "namespace",
                elt_ns,
                "elementname",
                elt_localname
            )
        else
            main.log("error", "Can't find “Record” command for the root node", "elementname", name)
        end
        exit()
    end

    -- emit last page if necessary
    -- current_pagestore_name is set when in SavePages and nil otherwise
    if M.page_helpers.page_initialized_p(M.current_pagenumber) and M.current_pagestore_name == nil then
        M.page_helpers.dothingsbeforeoutput(M.pages[M.current_pagenumber], M.data)
        local n = node.vpack(M.pages[M.current_pagenumber].pagebox)
        M.page_helpers.shipout(n, M.current_pagenumber, dataxml)
    end
    local lastpage = M.current_pagenumber
    while not (M.page_helpers.page_initialized_p(lastpage)) and lastpage > 0 and M.current_pagestore_name == nil do
        lastpage = lastpage - 1
    end

    -- At this point, all pages are in the PDF
    -- We are not at the end of the processing. Let's write the PDF information and status files.
    local pdfcatalog = {}
    if sp_suppressinfo then
        pdf.settrailerid(" [ <FA052949448907805BA83C1E78896398> <FA052949448907805BA83C1E78896398> ]")
    end
    -- file attachment
    if #M.filespecnumbers > 0 then
        local afstring = {}
        for i = 1, #M.filespecnumbers do
            local filespecnum = M.filespecnumbers[i][1]
            afstring[#afstring + 1] = string.format("%d 0 R", filespecnum)
        end
        local af = "[" .. table.concat(afstring, " ") .. "]"

        local names = {}
        for i = 1, #M.filespecnumbers do
            local filespecnum = M.filespecnumbers[i][1]
            local filename = M.filespecnumbers[i][3]
            names[#names + 1] = string.format([[%s %d 0 R]], M.utf8_to_utf16_string_pdf(filename), filespecnum)
        end
        pdfcatalog[#pdfcatalog + 1] =
            string.format([[ /Names << /EmbeddedFiles <<  /Names [%s] >> >> ]], table.concat(names, " "))
        pdfcatalog[#pdfcatalog + 1] = string.format([[ /AF %s ]], af)
    end

    local str = M.structure_tree.get_page_labels_str()
    if str then
        pdfcatalog[#pdfcatalog + 1] = str
    end
    local langtbl = M.language.get_language(M.defaultlanguage)

    if langtbl and langtbl.locale then
        pdfcatalog[#pdfcatalog + 1] = string.format(" /Lang (%s)", string.gsub(langtbl.locale, "^(%a+).*", "%1"))
    end

    local vp = {}
    if M.viewerpreferences.numcopies and M.viewerpreferences.numcopies > 1 and M.viewerpreferences.numcopies <= 5 then
        vp[#vp + 1] = string.format("/NumCopies %d", M.viewerpreferences.numcopies)
    end
    if M.viewerpreferences.printscaling and M.viewerpreferences.printscaling ~= "" then
        vp[#vp + 1] = string.format("/PrintScaling /%s", M.viewerpreferences.printscaling)
    end
    if M.viewerpreferences.picktray ~= nil then
        vp[#vp + 1] = string.format("/PickTrayByPDFSize %s", M.viewerpreferences.picktray)
    end

    if M.viewerpreferences.duplex ~= nil and M.viewerpreferences.duplex ~= "" then
        vp[#vp + 1] = string.format("/Duplex /%s", M.viewerpreferences.duplex)
    end

    if M.options.pagelayout then
        pdfcatalog[#pdfcatalog + 1] = string.format("/PageLayout /%s", M.options.pagelayout)
    end

    if M.options.displaymode then
        pdfcatalog[#pdfcatalog + 1] = string.format("/PageMode /%s", M.options.displaymode)
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
    local infos = {
        string.format(
            "/Creator %s /Producer %s",
            M.utf8_to_utf16_string_pdf(metadata.getcreator(M.options)),
            M.utf8_to_utf16_string_pdf(metadata.getproducer(M.options))
        ),
    }
    if not sp_suppressinfo then
        infos[#infos + 1] = "/Trapped /False"
    end
    if M.options.documenttitle and M.options.documenttitle ~= "" then
        infos[#infos + 1] = string.format("/Title %s", M.utf8_to_utf16_string_pdf(M.options.documenttitle))
    end
    if M.options.documentauthor and M.options.documentauthor ~= "" then
        infos[#infos + 1] = string.format("/Author %s", M.utf8_to_utf16_string_pdf(M.options.documentauthor))
    end
    if M.options.documentsubject and M.options.documentsubject ~= "" then
        infos[#infos + 1] = string.format("/Subject %s", M.utf8_to_utf16_string_pdf(M.options.documentsubject))
    end
    if M.options.documentkeywords and M.options.documentkeywords ~= "" then
        infos[#infos + 1] = string.format("/Keywords %s", M.utf8_to_utf16_string_pdf(M.options.documentkeywords))
    end

    if M.options.format then
        local metadataobjnum
        if M.options.format == "PDF/X-3:2002" or M.options.format == "PDF/X-4" then
            infos[#infos + 1] = string.format("/GTS_PDFXVersion (%s)", M.options.format)
            metadataobjnum = pdf.obj({
                type = "stream",
                string = metadata.getmetadata(M.filespecnumbers, M.options),
                immediate = true,
                attr = [[  /Subtype /XML /Type /Metadata ]],
                compresslevel = 0,
            })
            local colorprofileobjnum = spotcolors.write_colorprofile()
            local cp = spotcolors.get_colorprofile()
            local outputintentsobjnum = pdf.obj({
                type = "raw",
                immediate = true,
                string = string.format(
                    [[<<  /DestOutputProfile %d 0 R /Info %s /OutputCondition %s    /OutputConditionIdentifier %s   /RegistryName %s    /S /GTS_PDFX   /Type /OutputIntent  >>]],
                    colorprofileobjnum,
                    M.utf8_to_utf16_string_pdf(cp.info),
                    M.utf8_to_utf16_string_pdf(cp.condition),
                    M.utf8_to_utf16_string_pdf(cp.identifier),
                    M.utf8_to_utf16_string_pdf(cp.registry)
                ),
            })
            local outputintentsarrayobjnum =
                pdf.obj({ type = "raw", string = string.format("[ %d 0 R ]", outputintentsobjnum), immediate = true })
            pdfcatalog[#pdfcatalog + 1] = string.format("/OutputIntents %d 0 R", outputintentsarrayobjnum)
        end
        if M.options.format == "PDF/A-3" then
            metadataobjnum = pdf.obj({
                type = "stream",
                string = metadata.getmetadata(M.filespecnumbers, M.options),
                immediate = true,
                attr = [[  /Subtype /XML /Type /Metadata ]],
                compresslevel = 0,
            })
            pdf.setomitcidset(1)
            local colorprofileobjnum = spotcolors.write_colorprofile()
            local cp = spotcolors.get_colorprofile()
            local outputintentsobjnum = pdf.obj({
                type = "raw",
                immediate = true,
                string = string.format(
                    [[<<  /DestOutputProfile %d 0 R /Info %s /OutputCondition %s    /OutputConditionIdentifier %s   /RegistryName %s    /S /GTS_PDFA1   /Type /OutputIntent  >>]],
                    colorprofileobjnum,
                    M.utf8_to_utf16_string_pdf(cp.info),
                    M.utf8_to_utf16_string_pdf(cp.condition),
                    M.utf8_to_utf16_string_pdf(cp.identifier),
                    M.utf8_to_utf16_string_pdf(cp.registry)
                ),
            })
            local outputintentsarrayobjnum =
                pdf.obj({ type = "raw", string = string.format("[ %d 0 R ]", outputintentsobjnum), immediate = true })
            pdfcatalog[#pdfcatalog + 1] = string.format("/OutputIntents %d 0 R", outputintentsarrayobjnum)
        end
        if M.options.format == "PDF/UA" then
            pdfcatalog[#pdfcatalog + 1] = string.format(" /MarkInfo <<  /Marked true >> ")
            metadataobjnum = pdf.obj({
                type = "stream",
                string = metadata.getmetadata(M.filespecnumbers, M.options),
                immediate = true,
                attr = [[  /Subtype /XML /Type /Metadata ]],
                compresslevel = 0,
            })
            vp[#vp + 1] = "/DisplayDocTitle true"

            local parenttree = pdf.reserveobj()
            local structTreeRootObjectNumber = pdf.reserveobj()
            -- Sort structure tree by reading order if pages were reordered (InsertPages/SavePages)
            local needs_reorder = false
            for i = 1, #M.pagenum_tbl do
                if M.pagenum_tbl[i] ~= i then
                    needs_reorder = true
                    break
                end
            end
            if needs_reorder then
                -- Map page object ref → output position (reading order).
                -- pagenum_tbl[k] = output position for internal page k (shipout order).
                local page_ref_to_num = {}
                for k = 1, #M.pagenum_tbl do
                    page_ref_to_num[pdf.getpageref(k)] = M.pagenum_tbl[k]
                end
                M.structure_tree.sort_struct_tree_by_page_order(M.structElements[".root"], page_ref_to_num)
            end
            if M.options.dumpstructtree then
                -- Build page object ref → logical page number mapping
                local pageref_to_num = {}
                for k = 1, #M.pagenum_tbl do
                    pageref_to_num[pdf.getpageref(k)] = M.pagenum_tbl[k]
                end
                local xmlstr = '<?xml version="1.0" encoding="UTF-8"?>\n'
                    .. M.structure_tree.dump_struct_tree_xml(M.structElements[".root"], nil, pageref_to_num)
                local fn = tex.jobname .. "-struct.xml"
                local f = io.open(fn, "w")
                if f then
                    f:write(xmlstr)
                    f:write("\n")
                    f:close()
                    main.log("info", "Structure tree written to " .. fn)
                else
                    main.log("error", "Cannot open " .. fn .. " for writing")
                end
            end
            M.structure_tree.writeStructElements(M.structElements[".root"], structTreeRootObjectNumber)
            local strObjnum = pdf.obj({
                type = "raw",
                objnum = structTreeRootObjectNumber,
                string = string.format(
                    "<</Type /StructTreeRoot /K %d 0 R /ParentTree %d 0 R >>",
                    M.structElements[".root"].obj,
                    parenttree
                ),
                immediate = true,
            })
            local numentries = { "<< /Nums [" }
            for i = 1, #M.struct_root_numtree do
                numentries[#numentries + 1] = tostring(i - 1)
                numentries[#numentries + 1] = tostring(M.struct_root_numtree[i])
            end
            numentries[#numentries + 1] = "] >>"
            pdf.obj({
                type = "raw",
                string = string.format(table.concat(numentries, " ")),
                objnum = parenttree,
                immediate = true,
            })

            pdfcatalog[#pdfcatalog + 1] = string.format("/StructTreeRoot %d 0 R", strObjnum)
        end

        if metadataobjnum then
            pdfcatalog[#pdfcatalog + 1] = string.format("/Metadata %d 0 R", metadataobjnum)
        end
    end

    if #vp > 0 then
        pdfcatalog[#pdfcatalog + 1] = "/ViewerPreferences <<" .. table.concat(vp, " ") .. ">>"
    end

    local info = table.concat(infos, " ")

    local catalog = table.concat(pdfcatalog, " ")

    if pdf.setinfo then
        pdf.setcatalog(catalog)
        pdf.setinfo(info)
    else
        pdf.catalog = catalog
        pdf.info = info
    end

    -- Now put the bookmarks in the pdf
    for _, v in ipairs(M.bookmarks) do
        M.structure_tree.bookmarkstotex(v)
    end
    local tab = {}
    for k, v in pairs(M.markers) do
        tab[#tab + 1] = string.format(
            "  <mark name=%q page=%q id=%q />",
            M.xml_helpers.xml_escape(tostring(k)),
            M.xml_helpers.xml_escape(tostring(v.page)),
            tostring(v.count)
        )
    end
    for i = 1, #M.visible_pagenumbers do
        tab[#tab + 1] = string.format(
            "  <pagelabel pagenumber=%q visible=%q />",
            tostring(i),
            M.xml_helpers.xml_escape(tostring(M.visible_pagenumbers[i]))
        )
    end
    local file, errmsg = io.open(auxfilename, "wb")
    if file == nil then
        main.log("error", "Could not open aux file for writing", "filename", auxfilename, "message", errmsg)
        return
    end
    file:write("<marker>\n")
    file:write(table.concat(tab, "\n"))
    file:write(string.format("\n <lastpage page='%d' />", lastpage))
    file:write("\n</marker>")
    file:close()
    if M.has_pro_error then
        main.log("info", "*****************************************************")
        main.log("info", "*                                                   *")
        main.log("info", "* This layout uses features that require a Pro plan *")
        main.log("info", "*                                                   *")
        main.log("info", "* See                                               *")
        main.log("info", "*  https://www.speedata.de/en/product/prices/       *")
        main.log("info", "* for more information                              *")
        main.log("info", "*                                                   *")
        main.log("info", "*****************************************************")
    end
end

-- Create a PageLabels dictionary entry and update the visible_pagenumber
-- entry in the pagelabels table for referencing.
-- This is called at the end, when writing a dictionary

-- Each entry is a table of PDF object numbers with a `__tostring`
-- metamethod that renders the object references for the number tree.
---@type table[]
M.struct_root_numtree = {}

local ntmetafunctostring = function(tbl)
    local tmp = {}
    tmp[#tmp + 1] = "["
    for i = 1, #tbl do
        local objnum = rawget(tbl, i)
        tmp[#tmp + 1] = string.format("%d 0 R", objnum)
    end
    tmp[#tmp + 1] = "]"
    return table.concat(tmp, " ")
end

do
    local objcount
    local structelementobjects

    -- Walks a node list, collects PDF/UA structure entries from `att_role`
    -- attributes and node properties, and links them into the `structElements`
    -- tree. Recurses into hlists/vlists.
    ---@param nodelist Node Head of the node list to scan.
    ---@param parenttree integer PDF object number of the parent tree.
    ---@param page integer PDF page object number for the current page.
    ---@param curid? string Current parent role id used when nodes don't carry one.
    function M.find_role_attributes(nodelist, parenttree, page, curid)
        local head = nodelist
        while head do
            if head.id == M.hlist_node or head.id == M.vlist_node then
                if head.list then
                    local r = node.has_attribute(head, M.att_role)
                    local parentid = M.attribute_helpers.getprop(head, "parentid")

                    -- parentid == "" is a maker for inheritance
                    if parentid == "" or parentid == nil then
                        parentid = curid
                    end
                    -- roleid is role, underscore, rolecounter, for example P_1
                    local roleid = M.attribute_helpers.getprop(head, "id")
                    if roleid then
                        local actualtext = M.attribute_helpers.getprop(head, "actualtext")
                        local alttext = M.attribute_helpers.getprop(head, "alttext")
                        local rolename = M.roles_a[r]
                        if rolename ~= "Artifact" then
                            local structpos = M.attribute_helpers.getprop(head, "structpos")
                            local structposnum = tonumber(structpos)
                            local entry = {
                                obj = pdf.reserveobj(),
                                role = rolename,
                                page = page,
                                actualtext = actualtext,
                                alttext = alttext,
                            }
                            local parenttable = M.structElements[parentid]
                            if parenttable then
                                if structpos == "top" then
                                    table.insert(parenttable, 1, entry)
                                elseif structposnum then
                                    table.insert(parenttable, math.floor(structposnum), entry)
                                else
                                    parenttable[#parenttable + 1] = entry
                                end
                            end
                            M.structElements[roleid] = entry
                        end
                    end
                    M.find_role_attributes(head.list, parenttree, page, roleid or curid)
                end
            elseif node.has_attribute(head, M.att_role) then
                local r = node.has_attribute(head, M.att_role)
                local roleid = M.attribute_helpers.getprop(head, "id")
                local parentid = M.attribute_helpers.getprop(head, "parentid")
                if parentid == nil or parentid == "" or parentid == 0 or parentid == roleid then
                    parentid = curid
                end
                local actualtext = M.attribute_helpers.getprop(head, "actualtext")
                local alttext = M.attribute_helpers.getprop(head, "alttext")
                local bbox = M.attribute_helpers.getprop(head, "bbox")
                -- role number to role name
                local rolename = M.roles_a[r]

                local entry
                if M.structElements[roleid] then
                    entry = M.structElements[roleid]
                else
                    if rolename == "Link" then
                        local linkobjnum = M.attribute_helpers.getprop(head, "linkobjnum")
                        local structelemobjnum = M.attribute_helpers.getprop(head, "structelemobjnum")
                        local startlink = assert(head.next)
                        local action = assert(startlink.action)
                        action.data = action.data .. "/F 2" .. string.format("/P %s 0 R ", page)
                        entry = {
                            obj = structelemobjnum,
                            role = rolename,
                            page = page,
                            actualtext = actualtext,
                            alttext = alttext,
                            bbox = bbox,
                            linkobjects = { linkobjnum },
                        }
                    else
                        entry = {
                            obj = pdf.reserveobj(),
                            role = rolename,
                            page = page,
                            actualtext = actualtext,
                            alttext = alttext,
                            bbox = bbox,
                        }
                    end
                    -- The parent needs links to the children, but only one for each. Therefore
                    -- the parent contains a table (added_tables) which records all role ids
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
                        main.log(
                            "debug",
                            "Structure entry has no parent id",
                            "roleid",
                            roleid or "(none)",
                            "role",
                            rolename
                        )
                    else
                        if rolename ~= "Artifact" then
                            local parenttable = M.structElements[parentid]
                            if parenttable then
                                parenttable[#parenttable + 1] = entry
                            else
                                main.log(
                                    "debug",
                                    "Structure entry has no parent table",
                                    "parentid",
                                    parentid or "(none)",
                                    "role",
                                    rolename
                                )
                            end
                        end
                    end
                end

                structelementobjects[#structelementobjects + 1] = entry.obj
                local str
                if rolename == "Artifact" then
                    str = "/Artifact<<>>BDC"
                else
                    str = string.format("/%s<</MCID %d>>BDC", rolename, objcount)
                end
                head.data = str
                entry[#entry + 1] = objcount
                objcount = objcount + 1
            end
            head = head.next
        end
    end

    -- called once for each page.
    -- Resets the per-page state, then scans the node list for role attributes
    -- and registers the resulting struct elements in the page's structparents.
    ---@param nodelist Node Head of the page's node list.
    ---@param page table Current page table; receives `structparents`.
    function M.insert_struct_elements(nodelist, page)
        -- structelementobjects contains struct tree object numbers for this page.
        structelementobjects = {}
        objcount = 0
        local parenttree = ktree
        -- Use shipout index (#pagenum_tbl) instead of logical page number,
        -- because pdf.getpageref uses internal page numbering (shipout order).
        local thispage = pdf.getpageref(#M.pagenum_tbl)
        M.find_role_attributes(nodelist, parenttree, thispage)

        page.structparents = #M.struct_root_numtree
        -- ntmetafunctostring returns object references in brackets for __tostring
        M.struct_root_numtree[#M.struct_root_numtree + 1] =
            setmetatable(structelementobjects, { __tostring = ntmetafunctostring })
    end
end

-- annotate_nodelist is used for tooltips when debugging text formats.
do
    local annotcount = 0

    -- Adds a `pdf_annot` whatsit at the head of the node list that shows a
    -- tooltip with the given text — used for debugging text formats.
    ---@param nodelist Node Head of the node list to attach the annotation to.
    ---@param text string Tooltip text.
    function M.annotate_nodelist(nodelist, text)
        text = text:gsub(" ", "\\040")
        local annot = node.new(M.whatsit_node, "pdf_annot") --[[@as PdfAnnotWhatsitNode ]]
        local str = string.format(
            [[ /Subtype /Widget /TU (%s) /T (tooltip zref@%d) /C [] /FT/Btn /F 768 /Ff 65536 /H/N /BS << /W 0 >>]],
            text,
            annotcount
        )
        annotcount = annotcount + 1
        annot.data = str
        annot.width = nodelist.width
        annot.height = nodelist.height
        annot.depth = nodelist.depth
        nodelist = node.insert_before(nodelist.head, nodelist.head, annot)
        return nodelist
    end
end

-- skippages are set in commands.new_page if openon="..."
---@class SkipPages
---@field pagetype? string Page type for the next regular page.
---@field skippagetype? string Page type for the inserted skip page.
---@field doubleopen? boolean Whether an extra page must be inserted.

M.skippages = nil

-- Draw a box with HTML properties given at head.
-- The `height_sp` parameter is recomputed from `properties.lineheight` below;
-- the caller's value is intentionally ignored.
---@param dirmode "horizontal"|"vertical" Layout direction of the surrounding context.
---@param head Node Head of the content node list; carries the box properties.
---@param width_sp integer Box width in scaled points.
---@param height_sp integer Box height in sp (recomputed inside, ignored).
---@param depth_sp integer Box depth in sp.
---@return Node? hbox_or_vbox Packaged hbox or vbox; `nil` on internal error.
-- luacheck: push ignore height_sp
function M.htmlbox(dirmode, head, width_sp, height_sp, depth_sp)
    local debug_htmlbox = 0
    local properties = node.getproperty(head)
    if not properties then
        main.log("error", "Internal error: htmlbox() - no properties given")
        return
    end
    local rules = {}
    rules[#rules + 1] = "q"
    -- We start with 4 trapezoids (1 for each border). Later on clip paths are added.
    --
    --      4    4------------------------------3   3  y0
    --      |\    \                            /   /|
    --      | \    \                          /   / |
    --      |  \    \                        /   /  |
    --      |   \    \                      /   /   |
    --      |    \    \                    /   /    |
    --      |     3    1------------------2   4     |  y1
    --      |     |                           |     |
    --      |     |                           |     |
    --      |     |                           |     |
    --      |     |                           |     |
    --      |     |                           |     |
    --      |    2    4--------------------3   1    |  y2
    --      |   /    /                      \   \   |
    --      |  /    /                        \   \  |
    --      | /    /                          \   \ |
    --      |/    /                            \   \|
    --      1    /                              \   2  y3
    --          1--------------------------------2
    --      x0      x1                       x2     x3
    --
    -- Baseline is at 0
    -- depth is negative downwards
    -- height is positive upwards
    local colorstring

    -- Builds a PDF content-stream fragment that strokes/fills a quadrilateral
    -- with corners (x1,y1)..(x4,y4). Coordinates are in scaled points and
    -- converted to bp internally.
    ---@param x1 integer
    ---@param y1 integer
    ---@param x2 integer
    ---@param y2 integer
    ---@param x3 integer
    ---@param y3 integer
    ---@param x4 integer
    ---@param y4 integer
    ---@return string
    local function get_rule(x1, y1, x2, y2, x3, y3, x4, y4)
        local _x1, _y1 = sp_to_bp(x1), sp_to_bp(y1)
        local _x2, _y2 = sp_to_bp(x2), sp_to_bp(y2)
        local _x3, _y3 = sp_to_bp(x3), sp_to_bp(y3)
        local _x4, _y4 = sp_to_bp(x4), sp_to_bp(y4)
        local ret = string.format(
            "%s 0 w %g %g m %g %g l %g %g l %g %g l b",
            colorstring,
            _x1,
            _y1,
            _x2,
            _y2,
            _x3,
            _y3,
            _x4,
            _y4
        )
        return ret
    end

    local b_b_r_radius = properties.border_bottom_right_radius
    local b_b_l_radius = properties.border_bottom_left_radius
    local b_t_r_radius = properties.border_top_right_radius
    local b_t_l_radius = properties.border_top_left_radius

    local border_top_width = properties.border_top_width
    local border_right_width = properties.border_right_width
    local border_bottom_width = properties.border_bottom_width
    local border_left_width = properties.border_left_width

    local padding_top = properties.padding_top
    local padding_bottom = properties.padding_bottom
    local padding_left = properties.padding_left

    local margin_left = properties.margin_left or 0
    -- ht == y3, wd == x3
    depth_sp = math.max(depth_sp, properties.depth or 0)
    height_sp = properties.lineheight - depth_sp
    local sp_x0, sp_x1, sp_x2, wd
    local sp_y0, sp_y1, sp_y2, ht

    if dirmode == "horizontal" then
        local content_top = height_sp + (properties.shiftdown or 0)
        local content_bottom = -depth_sp + (properties.shiftdown or 0)

        sp_y0 = content_top + padding_top + border_top_width
        sp_y1 = content_top + padding_top
        ht = content_bottom - padding_bottom - border_bottom_width
        sp_y2 = content_bottom - padding_bottom

        sp_x0 = -1 * (padding_left + border_left_width)
        sp_x1 = sp_x0 + border_left_width
        sp_x2 = sp_x1 + width_sp
        wd = sp_x2 + border_right_width
    else
        local content_top = height_sp
        local content_bottom = -depth_sp

        -- vertical
        sp_y0 = content_top + padding_top + border_top_width
        sp_y1 = content_top + padding_top
        ht = content_bottom - padding_bottom - border_bottom_width
        sp_y2 = content_bottom - padding_bottom

        -- horizontal
        local content_left = properties.shiftright or 0
        local content_right = width_sp + (properties.shiftright or 0) + margin_left

        sp_x0 = content_left - padding_left - border_left_width
        sp_x1 = content_left - padding_left
        sp_x2 = content_right + padding_left
        wd = sp_x2 + border_right_width
    end

    -- The trapezoids must extend closer to the center of the border, because if the border
    -- radius is larger than the border width, the border goes "into" the surrounding object.
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
    local inner_top = sp_y1 - extend_top * border_top_width
    local inner_right = sp_x2 - extend_right * border_right_width
    local inner_bottom = sp_y2 + extend_bottom * border_bottom_width
    local inner_left = sp_x1 + extend_left * border_left_width

    if properties.border_top_style ~= "none" and border_top_width > 0 then
        colorstring = colors_module.colors[properties.border_top_color].pdfstring
        rules[#rules + 1] = get_rule(inner_left, inner_top, inner_right, inner_top, wd, sp_y0, sp_x0, sp_y0)
    end
    if properties.border_right_style ~= "none" and border_right_width > 0 then
        colorstring = colors_module.colors[properties.border_right_color].pdfstring
        rules[#rules + 1] = get_rule(inner_right, inner_bottom, wd, ht, wd, sp_y0, inner_right, inner_top)
    end
    if properties.border_bottom_style ~= "none" and border_bottom_width > 0 then
        colorstring = colors_module.colors[properties.border_bottom_color].pdfstring
        rules[#rules + 1] = get_rule(sp_x0, ht, wd, ht, inner_right, inner_bottom, inner_left, inner_bottom)
    end
    if properties.border_left_style ~= "none" and border_left_width > 0 then
        colorstring = colors_module.colors[properties.border_left_color].pdfstring
        rules[#rules + 1] = get_rule(sp_x0, ht, inner_left, inner_bottom, inner_left, inner_top, sp_x0, sp_y0)
    end
    rules[#rules + 1] = "Q"

    -- Let's calculate the outer boundary first.
    local circle_bezier = 0.551915024494

    -- xn, yn = outer path, xin, yin = inner path used for clipping
    local x0, _y0 = sp_x0, ht + b_b_l_radius
    local x1, y1 = sp_x0 + b_b_l_radius, ht
    local x2, y2 = wd - b_b_r_radius, y1
    local x3, y3 = x2 + circle_bezier * b_b_r_radius, y1
    local x5, y5 = wd, ht + b_b_r_radius
    local x4, y4 = wd, y5 - circle_bezier * b_b_r_radius
    local x6, y6 = wd, sp_y0 - b_t_r_radius
    local x7, y7 = wd, y6 + b_t_r_radius * circle_bezier
    local x9, y9 = wd - b_t_r_radius, sp_y0
    local x8, y8 = x9 + circle_bezier * b_t_r_radius, y9
    local x10, y10 = sp_x0 + b_t_l_radius, y9
    local x11, y11 = x10 - circle_bezier * b_t_l_radius, y9
    local x13, y13 = sp_x0, y9 - b_t_l_radius
    local x12, y12 = sp_x0, y13 + circle_bezier * b_t_l_radius
    local x14, y14 = sp_x0, y1 + b_b_l_radius
    local x15, y15 = sp_x0, y14 - b_b_l_radius * circle_bezier
    local x16, y16 = x1 - circle_bezier * b_b_l_radius, y1

    local b_b_r_inner_radius_x = math.max(0, b_b_r_radius - border_right_width)
    local b_b_r_inner_radius_y = math.max(0, b_b_r_radius - border_bottom_width)
    local b_b_l_inner_radius_x = math.max(0, b_b_l_radius - border_left_width)
    local b_b_l_inner_radius_y = math.max(0, b_b_l_radius - border_bottom_width)
    local b_t_r_inner_radius_x = math.max(0, b_t_r_radius - border_right_width)
    local b_t_r_inner_radius_y = math.max(0, b_t_r_radius - border_top_width)
    local b_t_l_inner_radius_x = math.max(0, b_t_l_radius - border_left_width)
    local b_t_l_inner_radius_y = math.max(0, b_t_l_radius - border_top_width)

    -- bottom left
    local xi14, yi14 = sp_x0 + border_left_width, math.max(ht + border_bottom_width, y14)
    local xi1, yi1 = math.max(x1, sp_x0 + border_left_width), ht + border_bottom_width

    -- bottom right
    local xi2, yi2 = math.min(x2, wd - border_right_width), yi1
    local xi5, yi5 = wd - border_right_width, math.max(y5, ht + border_bottom_width)

    -- top right
    local xi6, yi6 = xi5, math.min(y6, sp_y0 - border_top_width)
    local xi9, yi9 = math.min(x9, wd - border_right_width), math.min(y9, sp_y0 - border_top_width)

    -- top left
    local xi10, yi10 = math.max(sp_x0 + border_left_width, x10), math.min(sp_y0 - border_top_width, y10)
    local xi13, yi13 = math.max(sp_x0 + border_left_width, x13), math.min(sp_y0 - border_top_width, y13)

    -- control points
    -- bottom left
    local xi16, yi16 = xi1 - circle_bezier * b_b_l_inner_radius_x, yi1
    local xi15, yi15 = xi14, yi14 - circle_bezier * b_b_l_inner_radius_y

    -- bottom right
    local xi3, yi3 = xi2 + circle_bezier * b_b_r_inner_radius_x, yi2
    local xi4, yi4 = xi5, yi5 - circle_bezier * b_b_r_inner_radius_y

    -- top right
    local xi7, yi7 = xi6, yi6 + circle_bezier * b_t_r_inner_radius_y
    local xi8, yi8 = xi9 + circle_bezier * b_t_r_inner_radius_x, yi9

    -- top left
    local xi11, yi11 = xi10 - circle_bezier * b_t_l_inner_radius_x, yi10
    local xi12, yi12 = xi13, yi13 + circle_bezier * b_t_l_inner_radius_y

    if debug_htmlbox > 1 then
        rules[#rules + 1] = M.drawing.circle_pdfstring(x1, y14, b_b_l_radius, b_b_l_radius, "0 G ", "", 1000)
        rules[#rules + 1] = M.drawing.circle_pdfstring(x2, y5, b_b_r_radius, b_b_r_radius, "0 G ", "", 1000)
        rules[#rules + 1] = M.drawing.circle_pdfstring(x9, y6, b_t_r_radius, b_t_r_radius, "0 G ", "", 1000)
        rules[#rules + 1] = M.drawing.circle_pdfstring(x10, y13, b_t_l_radius, b_t_l_radius, "0 G ", "", 1000)

        rules[#rules + 1] =
            M.drawing.circle_pdfstring(xi1, yi14, b_b_l_inner_radius_x, b_b_l_inner_radius_y, "0 G ", "", 1000)
        rules[#rules + 1] =
            M.drawing.circle_pdfstring(xi2, yi5, b_b_r_inner_radius_x, b_b_r_inner_radius_y, "0 G ", "", 1000)
        rules[#rules + 1] =
            M.drawing.circle_pdfstring(xi9, yi6, b_t_r_inner_radius_x, b_t_r_inner_radius_y, "0 G ", "", 1000)
        rules[#rules + 1] =
            M.drawing.circle_pdfstring(xi10, yi13, b_t_l_inner_radius_x, b_t_l_inner_radius_y, "0 G ", "", 1000)
    end

    local rules_clip = {}

    rules_clip[#rules_clip + 1] = M.drawing.pdf_moveto(x1, y1)
    rules_clip[#rules_clip + 1] = M.drawing.pdf_lineto(x2, y2)
    rules_clip[#rules_clip + 1] = M.drawing.pdf_curveto(x3, y3, x4, y4, x5, y5)
    rules_clip[#rules_clip + 1] = M.drawing.pdf_lineto(x6, y6)
    rules_clip[#rules_clip + 1] = M.drawing.pdf_curveto(x7, y7, x8, y8, x9, y9)
    rules_clip[#rules_clip + 1] = M.drawing.pdf_lineto(x10, y10)
    rules_clip[#rules_clip + 1] = M.drawing.pdf_curveto(x11, y11, x12, y12, x13, y13)
    rules_clip[#rules_clip + 1] = M.drawing.pdf_lineto(x14, y14)
    rules_clip[#rules_clip + 1] = M.drawing.pdf_curveto(x15, y15, x16, y16, x1, y1)

    rules_clip[#rules_clip + 1] = M.drawing.pdf_moveto(xi1, yi1)
    rules_clip[#rules_clip + 1] = M.drawing.pdf_lineto(xi2, yi2)
    rules_clip[#rules_clip + 1] = M.drawing.pdf_curveto(xi3, yi3, xi4, yi4, xi5, yi5)
    rules_clip[#rules_clip + 1] = M.drawing.pdf_lineto(xi6, yi6)
    rules_clip[#rules_clip + 1] = M.drawing.pdf_curveto(xi7, yi7, xi8, yi8, xi9, yi9)
    rules_clip[#rules_clip + 1] = M.drawing.pdf_lineto(xi10, yi10)
    rules_clip[#rules_clip + 1] = M.drawing.pdf_curveto(xi11, yi11, xi12, yi12, xi13, yi13)
    rules_clip[#rules_clip + 1] = M.drawing.pdf_lineto(xi14, yi14)
    rules_clip[#rules_clip + 1] = M.drawing.pdf_curveto(xi15, yi15, xi16, yi16, xi1, yi1)

    if debug_htmlbox > 0 then
        rules[#rules + 1] = "q 0.3 w"
        rules[#rules + 1] = M.drawing.pdf_moveto(x0, 0)
        rules[#rules + 1] = M.drawing.pdf_lineto(wd, 0)
        rules[#rules + 1] = "S"
        rules[#rules + 1] = M.drawing.pdf_moveto(x0, -depth_sp)
        rules[#rules + 1] = M.drawing.pdf_lineto(wd, -depth_sp)
        rules[#rules + 1] = "S"
        rules[#rules + 1] = M.drawing.pdf_moveto(x0, height_sp)
        rules[#rules + 1] = M.drawing.pdf_lineto(wd, height_sp)
        rules[#rules + 1] = "S"
        rules[#rules + 1] = "Q"
    end

    if debug_htmlbox > 1 then
        rules[#rules + 1] = "q 0.3 w"
        rules[#rules + 1] = M.drawing.pdf_moveto(x1, y1)
        rules[#rules + 1] = M.drawing.pdf_lineto(x2, y2)
        rules[#rules + 1] = M.drawing.pdf_curveto(x3, y3, x4, y4, x5, y5)
        rules[#rules + 1] = M.drawing.pdf_lineto(x6, y6)
        rules[#rules + 1] = M.drawing.pdf_curveto(x7, y7, x8, y8, x9, y9)
        rules[#rules + 1] = M.drawing.pdf_lineto(x10, y10)
        rules[#rules + 1] = M.drawing.pdf_curveto(x11, y11, x12, y12, x13, y13)
        rules[#rules + 1] = M.drawing.pdf_lineto(x14, y14)
        rules[#rules + 1] = M.drawing.pdf_curveto(x15, y15, x16, y16, x1, y1)
        rules[#rules + 1] = "S"

        rules[#rules + 1] = M.drawing.pdf_moveto(xi1, yi1)
        rules[#rules + 1] = M.drawing.pdf_lineto(xi2, yi2)
        rules[#rules + 1] = M.drawing.pdf_curveto(xi3, yi3, xi4, yi4, xi5, yi5)
        rules[#rules + 1] = M.drawing.pdf_lineto(xi6, yi6)
        rules[#rules + 1] = M.drawing.pdf_curveto(xi7, yi7, xi8, yi8, xi9, yi9)
        rules[#rules + 1] = M.drawing.pdf_lineto(xi10, yi10)
        rules[#rules + 1] = M.drawing.pdf_curveto(xi11, yi11, xi12, yi12, xi13, yi13)
        rules[#rules + 1] = M.drawing.pdf_lineto(xi14, yi14)
        rules[#rules + 1] = M.drawing.pdf_curveto(xi15, yi15, xi16, yi16, xi1, yi1)
        rules[#rules + 1] = "S Q"
    end

    rules_clip[#rules_clip + 1] = "h W* n"

    local n_clip = node.new("whatsit", "pdf_literal") --[[@as PdfLiteralWhatsitNode]]
    M.attribute_helpers.setprop(n_clip, "origin", "htmlbox.clip")
    local n_clip_data = table.concat(rules_clip, " ")
    local concat_rules = table.concat(rules, " ")
    n_clip_data = n_clip_data .. " " .. concat_rules
    n_clip.data = n_clip_data

    local pdf_save = node.new("whatsit", "pdf_save")
    local pdf_restore = node.new("whatsit", "pdf_restore")

    node.insert_after(pdf_save, pdf_save, n_clip)

    local hvbox = node.hpack(pdf_save) ---@type Node
    hvbox.depth = 0
    node.insert_after(hvbox, node.tail(hvbox), pdf_restore)
    hvbox = node.vpack(hvbox)
    node.setproperty(hvbox, { origin = "hvbox" })

    if dirmode == "horizontal" then
        return hvbox
    end
    local vbox = node.vpack(hvbox)
    local shiftdown = properties.shiftdown or 0
    local g = set_glue(nil, { width = shiftdown })
    vbox.head = node.insert_before(vbox.head, vbox.head, g)
    vbox.height = 0
    vbox.depth = 0
    return vbox
end
-- luacheck: pop

-- To split the textblock in pieces
local marker
marker = node.new("whatsit", "user_defined") --[[@as UserDefinedWhatsitNode]]
marker.user_id = M.user_defined_marker
marker.type = 100 -- type 100: "value is a number"
marker.value = 1

-- Node(list) creation
-- -------------------

M.rightskip = node.new("glue_spec") --[[@as GlueSpecNode]]
M.rightskip.width = 0
M.rightskip.stretch = 1 * 2 ^ 16
M.rightskip.stretch_order = 3

M.leftskip = node.new("glue_spec") --[[@as GlueSpecNode]]
M.leftskip.width = 0
M.leftskip.stretch = 1 * 2 ^ 16
M.leftskip.stretch_order = 3

-- Hyphenation and language handling
-- ---------------------------------

-- Loaded languages. Key is the lower-cased locale (such as `de-1996`), the
-- value is the language entry created in `language.lua#get_language()`.
---@type table<string, LanguageEntry>
M.languages = {}
---@type table<integer, LanguageEntry>
M.languages_id_lang = {}

---@class ShapeOptions
---@field language? string BCP-47 language tag.
---@field script? string ISO 15924 script tag.
---@field direction? string Direction override (`"ltr"`, `"rtl"`, `"ttb"` or `"btt"`).

-- Shapes a HarfBuzz buffer with the given font and OpenType features.
-- Reverses the buffer when shaping produced an RTL run.
---@param tbl { font: any, otfeatures: any } Font + OT-feature table.
---@param buf any HarfBuzz buffer instance.
---@param options? ShapeOptions Per-call shaping overrides.
---@return string script ISO 15924 script tag actually used.
---@return string direction `"ltr"`, `"rtl"`, `"ttb"` or `"btt"`.
M.shape = function(tbl, buf, options)
    local font = tbl.font
    options = options or {}
    local hblang, script, dir

    if options.language then
        hblang = M.harfbuzz.Language.new(options.language)
        buf:set_language(hblang)
    end
    if options.script then
        script = M.harfbuzz.Script.new(options.script)
        buf:set_script(script)
    end
    if options.direction then
        dir = M.harfbuzz.Direction.new(options.direction)
        buf:set_direction(dir)
    end
    buf:set_cluster_level(buf.CLUSTER_LEVEL_MONOTONE_CHARACTERS)
    buf:set_flags(M.harfbuzz.Buffer.FLAG_REMOVE_DEFAULT_IGNORABLES)
    buf:guess_segment_properties()

    local bufdir = tostring(buf:get_direction())
    local bufscript = tostring(buf:get_script())
    M.harfbuzz.shape_full(font, buf, tbl.otfeatures, { "ot", "graphite2", "fallback" })
    if bufdir == "rtl" then
        buf:reverse()
    end
    return bufscript, bufdir
end

file_end("publisher.lua")

-- Expose each submodule on M, so callers reach functions through their
-- actual module (publisher.pages.shipout, publisher.nodes.mknodes, …)
-- instead of through a flat mirror. The require()s also force the
-- submodules to load even if no other file pulls them in directly.
M.utilities = require("publisher.utilities")
M.xml_helpers = require("publisher.xml_helpers")
M.images = require("publisher.images")
M.language = require("publisher.language")
-- 'attributes' is already taken by the attribute-defs table at the top
-- of this file; 'pages' is the runtime page-state map. Expose the
-- corresponding helper modules under qualified names instead.
M.attribute_helpers = require("publisher.attributes")
M.page_helpers = require("publisher.pages")
M.structure_tree = require("publisher.structure_tree")
M.drawing = require("publisher.drawing")
M.fontfamilies = require("publisher.fontfamilies")
M.dispatch = require("publisher.dispatch")
M.nodes = require("publisher.nodes")

return M
