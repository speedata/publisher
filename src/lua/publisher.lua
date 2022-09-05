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

xpath = do_luafile("xpath.lua")

hasharfbuzz, harfbuzz = pcall(require,'luaharfbuzz')
if not hasharfbuzz then
    warning("harfbuzz library not found")
end


local commands     = require("publisher.commands")
local page         = require("publisher.page")
local fontloader   = require("fonts.fontloader")
local html         = require("publisher.html")
local fonts        = require("publisher.fonts")
local uuid         = require("uuid")

par        = require("par")
uuid.randomseed(tex.randomseed)

splib        = require("luaglue")

local env_publisherversion = os.getenv("PUBLISHERVERSION")

module(...,package.seeall)


do_luafile("layout_functions.lua")

processmode = "XML"

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
    for k, _ in pairs(attributes) do
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
        -- for action/mark command
        user_defined_whatsit = k
    elseif v == "pdf_refximage" then
        pdf_refximage_whatsit = k
    elseif v == "pdf_action" then
        pdf_action_whatsit = k
    elseif v == "pdf_dest" then
        pdf_dest_whatsit = k
    end
end

-- sd:alternating
alternating = {}
alternating_value = {}

-- sp --mode foo sets modes.foo = true
modes = {}

-- page numbers go from 1 to n. If reordering is necessary, we insert
-- a different index into the pagenum_tbl.
-- The value of a key is usually the successor of the previous entry
-- 1,2,3,4 but can be changed by setting a single entry. E.g. setting
-- entry 3 to 5 gives the array 1,2,5,6,7,8...
pagenum_tbl = setmetatable({1}, {
    __index=function(tbl, idx)
        local max = 0
        for k, v in next, tbl do
          if k <= idx then max = v - k end
        end
        return idx + max
      end })

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
    fontloader = os.getenv("SP_FONTLOADER") or "fontforge",
    xmlparser = os.getenv("SP_XMLPARSER") or "lua",
}

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

viewerpreferences = {}

-- All hyperlinks from HTML data are stored here in this array
-- to be inserted later on in pre shipout filter
hyperlinks = {}

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

-- The spot colors used in the document (even when discarded)
used_spotcolors = {}

-- The current foreground color (used in underline)
current_fgcolor = nil

-- The predefined colors. index = 1 because we "know" that black will be the first registered color.
colors  = {
  black = { model="gray", g = "0", pdfstring = " 0 G 0 g ", index = 1 },
  aliceblue = { model="rgb", r="0.941" , g="0.973" , b="1" , pdfstring = "0.941 0.973 1 rg 0.941 0.973 1 RG", index = 2},
  orange = { model="rgb", r="1" , g="0.647" , b="0" , pdfstring = "1 0.647 0 rg 1 0.647 0 RG", index = 3},
  rebeccapurple = { model="rgb", r="0.4" , g="0.2" , b="0.6" , pdfstring = "0.4 0.2 0.6 rg 0.4 0.2 0.6 RG", index = 4},
  antiquewhite = { model="rgb", r="0.98" , g="0.922" , b="0.843" , pdfstring = "0.98 0.922 0.843 rg 0.98 0.922 0.843 RG", index = 5},
  aqua = { model="rgb", r="0" , g="1" , b="1" , pdfstring = "0 1 1 rg 0 1 1 RG", index = 6},
  aquamarine = { model="rgb", r="0.498" , g="1" , b="0.831" , pdfstring = "0.498 1 0.831 rg 0.498 1 0.831 RG", index = 7},
  azure = { model="rgb", r="0.941" , g="1" , b="1" , pdfstring = "0.941 1 1 rg 0.941 1 1 RG", index = 8},
  beige = { model="rgb", r="0.961" , g="0.961" , b="0.863" , pdfstring = "0.961 0.961 0.863 rg 0.961 0.961 0.863 RG", index = 9},
  bisque = { model="rgb", r="1" , g="0.894" , b="0.769" , pdfstring = "1 0.894 0.769 rg 1 0.894 0.769 RG", index = 10},
  blanchedalmond = { model="rgb", r="1" , g="0.894" , b="0.769" , pdfstring = "1 0.894 0.769 rg 1 0.894 0.769 RG", index = 11},
  blue = { model="rgb", r="0" , g="0" , b="1" , pdfstring = "0 0 1 rg 0 0 1 RG", index = 12},
  blueviolet = { model="rgb", r="0.541" , g="0.169" , b="0.886" , pdfstring = "0.541 0.169 0.886 rg 0.541 0.169 0.886 RG", index = 13},
  brown = { model="rgb", r="0.647" , g="0.165" , b="0.165" , pdfstring = "0.647 0.165 0.165 rg 0.647 0.165 0.165 RG", index = 14},
  burlywood = { model="rgb", r="0.871" , g="0.722" , b="0.529" , pdfstring = "0.871 0.722 0.529 rg 0.871 0.722 0.529 RG", index = 15},
  cadetblue = { model="rgb", r="0.373" , g="0.62" , b="0.627" , pdfstring = "0.373 0.62 0.627 rg 0.373 0.62 0.627 RG", index = 16},
  chartreuse = { model="rgb", r="0.498" , g="1" , b="0" , pdfstring = "0.498 1 0 rg 0.498 1 0 RG", index = 17},
  chocolate = { model="rgb", r="0.824" , g="0.412" , b="0.118" , pdfstring = "0.824 0.412 0.118 rg 0.824 0.412 0.118 RG", index = 18},
  coral = { model="rgb", r="1" , g="0.498" , b="0.314" , pdfstring = "1 0.498 0.314 rg 1 0.498 0.314 RG", index = 19},
  cornflowerblue = { model="rgb", r="0.392" , g="0.584" , b="0.929" , pdfstring = "0.392 0.584 0.929 rg 0.392 0.584 0.929 RG", index = 20},
  cornsilk = { model="rgb", r="1" , g="0.973" , b="0.863" , pdfstring = "1 0.973 0.863 rg 1 0.973 0.863 RG", index = 21},
  crimson = { model="rgb", r="0.863" , g="0.078" , b="0.235" , pdfstring = "0.863 0.078 0.235 rg 0.863 0.078 0.235 RG", index = 22},
  darkblue = { model="rgb", r="0" , g="0" , b="0.545" , pdfstring = "0 0 0.545 rg 0 0 0.545 RG", index = 23},
  darkcyan = { model="rgb", r="0" , g="0.545" , b="0.545" , pdfstring = "0 0.545 0.545 rg 0 0.545 0.545 RG", index = 24},
  darkgoldenrod = { model="rgb", r="0.722" , g="0.525" , b="0.043" , pdfstring = "0.722 0.525 0.043 rg 0.722 0.525 0.043 RG", index = 25},
  darkgray = { model="rgb", r="0.663" , g="0.663" , b="0.663" , pdfstring = "0.663 0.663 0.663 rg 0.663 0.663 0.663 RG", index = 26},
  darkgreen = { model="rgb", r="0" , g="0.392" , b="0" , pdfstring = "0 0.392 0 rg 0 0.392 0 RG", index = 27},
  darkgrey = { model="rgb", r="0.663" , g="0.663" , b="0.663" , pdfstring = "0.663 0.663 0.663 rg 0.663 0.663 0.663 RG", index = 28},
  darkkhaki = { model="rgb", r="0.741" , g="0.718" , b="0.42" , pdfstring = "0.741 0.718 0.42 rg 0.741 0.718 0.42 RG", index = 29},
  darkmagenta = { model="rgb", r="0.545" , g="0" , b="0.545" , pdfstring = "0.545 0 0.545 rg 0.545 0 0.545 RG", index = 30},
  darkolivegreen = { model="rgb", r="0.333" , g="0.42" , b="0.184" , pdfstring = "0.333 0.42 0.184 rg 0.333 0.42 0.184 RG", index = 31},
  darkorange = { model="rgb", r="1" , g="0.549" , b="0" , pdfstring = "1 0.549 0 rg 1 0.549 0 RG", index = 32},
  darkorchid = { model="rgb", r="0.6" , g="0.196" , b="0.8" , pdfstring = "0.6 0.196 0.8 rg 0.6 0.196 0.8 RG", index = 33},
  darkred = { model="rgb", r="0.545" , g="0" , b="0" , pdfstring = "0.545 0 0 rg 0.545 0 0 RG", index = 34},
  darksalmon = { model="rgb", r="0.914" , g="0.588" , b="0.478" , pdfstring = "0.914 0.588 0.478 rg 0.914 0.588 0.478 RG", index = 35},
  darkseagreen = { model="rgb", r="0.561" , g="0.737" , b="0.561" , pdfstring = "0.561 0.737 0.561 rg 0.561 0.737 0.561 RG", index = 36},
  darkslateblue = { model="rgb", r="0.282" , g="0.239" , b="0.545" , pdfstring = "0.282 0.239 0.545 rg 0.282 0.239 0.545 RG", index = 37},
  darkslategray = { model="rgb", r="0.184" , g="0.31" , b="0.31" , pdfstring = "0.184 0.31 0.31 rg 0.184 0.31 0.31 RG", index = 38},
  darkslategrey = { model="rgb", r="0.184" , g="0.31" , b="0.31" , pdfstring = "0.184 0.31 0.31 rg 0.184 0.31 0.31 RG", index = 39},
  darkturquoise = { model="rgb", r="0" , g="0.808" , b="0.82" , pdfstring = "0 0.808 0.82 rg 0 0.808 0.82 RG", index = 40},
  darkviolet = { model="rgb", r="0.58" , g="0" , b="0.827" , pdfstring = "0.58 0 0.827 rg 0.58 0 0.827 RG", index = 41},
  deeppink = { model="rgb", r="1" , g="0.078" , b="0.576" , pdfstring = "1 0.078 0.576 rg 1 0.078 0.576 RG", index = 42},
  deepskyblue = { model="rgb", r="0" , g="0.749" , b="1" , pdfstring = "0 0.749 1 rg 0 0.749 1 RG", index = 43},
  dimgray = { model="rgb", r="0.412" , g="0.412" , b="0.412" , pdfstring = "0.412 0.412 0.412 rg 0.412 0.412 0.412 RG", index = 44},
  dimgrey = { model="rgb", r="0.412" , g="0.412" , b="0.412" , pdfstring = "0.412 0.412 0.412 rg 0.412 0.412 0.412 RG", index = 45},
  dodgerblue = { model="rgb", r="0.118" , g="0.565" , b="1" , pdfstring = "0.118 0.565 1 rg 0.118 0.565 1 RG", index = 46},
  firebrick = { model="rgb", r="0.698" , g="0.133" , b="0.133" , pdfstring = "0.698 0.133 0.133 rg 0.698 0.133 0.133 RG", index = 47},
  floralwhite = { model="rgb", r="1" , g="0.98" , b="0.941" , pdfstring = "1 0.98 0.941 rg 1 0.98 0.941 RG", index = 48},
  forestgreen = { model="rgb", r="0.133" , g="0.545" , b="0.133" , pdfstring = "0.133 0.545 0.133 rg 0.133 0.545 0.133 RG", index = 49},
  fuchsia = { model="rgb", r="1" , g="0" , b="1" , pdfstring = "1 0 1 rg 1 0 1 RG", index = 50},
  gainsboro = { model="rgb", r="0.863" , g="0.863" , b="0.863" , pdfstring = "0.863 0.863 0.863 rg 0.863 0.863 0.863 RG", index = 51},
  ghostwhite = { model="rgb", r="0.973" , g="0.973" , b="1" , pdfstring = "0.973 0.973 1 rg 0.973 0.973 1 RG", index = 52},
  gold = { model="rgb", r="1" , g="0.843" , b="0" , pdfstring = "1 0.843 0 rg 1 0.843 0 RG", index = 53},
  goldenrod = { model="rgb", r="0.855" , g="0.647" , b="0.125" , pdfstring = "0.855 0.647 0.125 rg 0.855 0.647 0.125 RG", index = 54},
  gray = { model="rgb", r="0.502" , g="0.502" , b="0.502" , pdfstring = "0.502 0.502 0.502 rg 0.502 0.502 0.502 RG", index = 55},
  green = { model="rgb", r="0" , g="0.502" , b="0" , pdfstring = "0 0.502 0 rg 0 0.502 0 RG", index = 56},
  greenyellow = { model="rgb", r="0.678" , g="1" , b="0.184" , pdfstring = "0.678 1 0.184 rg 0.678 1 0.184 RG", index = 57},
  grey = { model="rgb", r="0.502" , g="0.502" , b="0.502" , pdfstring = "0.502 0.502 0.502 rg 0.502 0.502 0.502 RG", index = 58},
  honeydew = { model="rgb", r="0.941" , g="1" , b="0.941" , pdfstring = "0.941 1 0.941 rg 0.941 1 0.941 RG", index = 59},
  hotpink = { model="rgb", r="1" , g="0.412" , b="0.706" , pdfstring = "1 0.412 0.706 rg 1 0.412 0.706 RG", index = 60},
  indianred = { model="rgb", r="0.804" , g="0.361" , b="0.361" , pdfstring = "0.804 0.361 0.361 rg 0.804 0.361 0.361 RG", index = 61},
  indigo = { model="rgb", r="0.294" , g="0" , b="0.51" , pdfstring = "0.294 0 0.51 rg 0.294 0 0.51 RG", index = 62},
  ivory = { model="rgb", r="1" , g="1" , b="0.941" , pdfstring = "1 1 0.941 rg 1 1 0.941 RG", index = 63},
  khaki = { model="rgb", r="0.941" , g="0.902" , b="0.549" , pdfstring = "0.941 0.902 0.549 rg 0.941 0.902 0.549 RG", index = 64},
  lavender = { model="rgb", r="0.902" , g="0.902" , b="0.98" , pdfstring = "0.902 0.902 0.98 rg 0.902 0.902 0.98 RG", index = 65},
  lavenderblush = { model="rgb", r="1" , g="0.941" , b="0.961" , pdfstring = "1 0.941 0.961 rg 1 0.941 0.961 RG", index = 66},
  lawngreen = { model="rgb", r="0.486" , g="0.988" , b="0" , pdfstring = "0.486 0.988 0 rg 0.486 0.988 0 RG", index = 67},
  lemonchiffon = { model="rgb", r="1" , g="0.98" , b="0.804" , pdfstring = "1 0.98 0.804 rg 1 0.98 0.804 RG", index = 68},
  lightblue = { model="rgb", r="0.678" , g="0.847" , b="0.902" , pdfstring = "0.678 0.847 0.902 rg 0.678 0.847 0.902 RG", index = 69},
  lightcoral = { model="rgb", r="0.941" , g="0.502" , b="0.502" , pdfstring = "0.941 0.502 0.502 rg 0.941 0.502 0.502 RG", index = 70},
  lightcyan = { model="rgb", r="0.878" , g="1" , b="1" , pdfstring = "0.878 1 1 rg 0.878 1 1 RG", index = 71},
  lightgoldenrodyellow = { model="rgb", r="0.98" , g="0.98" , b="0.824" , pdfstring = "0.98 0.98 0.824 rg 0.98 0.98 0.824 RG", index = 72},
  lightgray = { model="rgb", r="0.827" , g="0.827" , b="0.827" , pdfstring = "0.827 0.827 0.827 rg 0.827 0.827 0.827 RG", index = 73},
  lightgreen = { model="rgb", r="0.565" , g="0.933" , b="0.565" , pdfstring = "0.565 0.933 0.565 rg 0.565 0.933 0.565 RG", index = 74},
  lightgrey = { model="rgb", r="0.827" , g="0.827" , b="0.827" , pdfstring = "0.827 0.827 0.827 rg 0.827 0.827 0.827 RG", index = 75},
  lightpink = { model="rgb", r="1" , g="0.714" , b="0.757" , pdfstring = "1 0.714 0.757 rg 1 0.714 0.757 RG", index = 76},
  lightsalmon = { model="rgb", r="1" , g="0.627" , b="0.478" , pdfstring = "1 0.627 0.478 rg 1 0.627 0.478 RG", index = 77},
  lightseagreen = { model="rgb", r="0.125" , g="0.698" , b="0.667" , pdfstring = "0.125 0.698 0.667 rg 0.125 0.698 0.667 RG", index = 78},
  lightskyblue = { model="rgb", r="0.529" , g="0.808" , b="0.98" , pdfstring = "0.529 0.808 0.98 rg 0.529 0.808 0.98 RG", index = 79},
  lightslategray = { model="rgb", r="0.467" , g="0.533" , b="0.6" , pdfstring = "0.467 0.533 0.6 rg 0.467 0.533 0.6 RG", index = 80},
  lightslategrey = { model="rgb", r="0.467" , g="0.533" , b="0.6" , pdfstring = "0.467 0.533 0.6 rg 0.467 0.533 0.6 RG", index = 81},
  lightsteelblue = { model="rgb", r="0.69" , g="0.769" , b="0.871" , pdfstring = "0.69 0.769 0.871 rg 0.69 0.769 0.871 RG", index = 82},
  lightyellow = { model="rgb", r="1" , g="1" , b="0.878" , pdfstring = "1 1 0.878 rg 1 1 0.878 RG", index = 83},
  lime = { model="rgb", r="0" , g="1" , b="0" , pdfstring = "0 1 0 rg 0 1 0 RG", index = 84},
  limegreen = { model="rgb", r="0.196" , g="0.804" , b="0.196" , pdfstring = "0.196 0.804 0.196 rg 0.196 0.804 0.196 RG", index = 85},
  linen = { model="rgb", r="0.98" , g="0.941" , b="0.902" , pdfstring = "0.98 0.941 0.902 rg 0.98 0.941 0.902 RG", index = 86},
  maroon = { model="rgb", r="0.502" , g="0" , b="0" , pdfstring = "0.502 0 0 rg 0.502 0 0 RG", index = 87},
  mediumaquamarine = { model="rgb", r="0.4" , g="0.804" , b="0.667" , pdfstring = "0.4 0.804 0.667 rg 0.4 0.804 0.667 RG", index = 88},
  mediumblue = { model="rgb", r="0" , g="0" , b="0.804" , pdfstring = "0 0 0.804 rg 0 0 0.804 RG", index = 89},
  mediumorchid = { model="rgb", r="0.729" , g="0.333" , b="0.827" , pdfstring = "0.729 0.333 0.827 rg 0.729 0.333 0.827 RG", index = 90},
  mediumpurple = { model="rgb", r="0.576" , g="0.439" , b="0.859" , pdfstring = "0.576 0.439 0.859 rg 0.576 0.439 0.859 RG", index = 91},
  mediumseagreen = { model="rgb", r="0.235" , g="0.702" , b="0.443" , pdfstring = "0.235 0.702 0.443 rg 0.235 0.702 0.443 RG", index = 92},
  mediumslateblue = { model="rgb", r="0.482" , g="0.408" , b="0.933" , pdfstring = "0.482 0.408 0.933 rg 0.482 0.408 0.933 RG", index = 93},
  mediumspringgreen = { model="rgb", r="0" , g="0.98" , b="0.604" , pdfstring = "0 0.98 0.604 rg 0 0.98 0.604 RG", index = 94},
  mediumturquoise = { model="rgb", r="0.282" , g="0.82" , b="0.8" , pdfstring = "0.282 0.82 0.8 rg 0.282 0.82 0.8 RG", index = 95},
  mediumvioletred = { model="rgb", r="0.78" , g="0.082" , b="0.522" , pdfstring = "0.78 0.082 0.522 rg 0.78 0.082 0.522 RG", index = 96},
  midnightblue = { model="rgb", r="0.098" , g="0.098" , b="0.439" , pdfstring = "0.098 0.098 0.439 rg 0.098 0.098 0.439 RG", index = 97},
  mintcream = { model="rgb", r="0.961" , g="1" , b="0.98" , pdfstring = "0.961 1 0.98 rg 0.961 1 0.98 RG", index = 98},
  mistyrose = { model="rgb", r="1" , g="0.894" , b="0.882" , pdfstring = "1 0.894 0.882 rg 1 0.894 0.882 RG", index = 99},
  moccasin = { model="rgb", r="1" , g="0.894" , b="0.71" , pdfstring = "1 0.894 0.71 rg 1 0.894 0.71 RG", index = 100},
  navajowhite = { model="rgb", r="1" , g="0.871" , b="0.678" , pdfstring = "1 0.871 0.678 rg 1 0.871 0.678 RG", index = 101},
  navy = { model="rgb", r="0" , g="0" , b="0.502" , pdfstring = "0 0 0.502 rg 0 0 0.502 RG", index = 102},
  oldlace = { model="rgb", r="0.992" , g="0.961" , b="0.902" , pdfstring = "0.992 0.961 0.902 rg 0.992 0.961 0.902 RG", index = 103},
  olive = { model="rgb", r="0.502" , g="0.502" , b="0" , pdfstring = "0.502 0.502 0 rg 0.502 0.502 0 RG", index = 104},
  olivedrab = { model="rgb", r="0.42" , g="0.557" , b="0.137" , pdfstring = "0.42 0.557 0.137 rg 0.42 0.557 0.137 RG", index = 105},
  orangered = { model="rgb", r="1" , g="0.271" , b="0" , pdfstring = "1 0.271 0 rg 1 0.271 0 RG", index = 106},
  orchid = { model="rgb", r="0.855" , g="0.439" , b="0.839" , pdfstring = "0.855 0.439 0.839 rg 0.855 0.439 0.839 RG", index = 107},
  palegoldenrod = { model="rgb", r="0.933" , g="0.91" , b="0.667" , pdfstring = "0.933 0.91 0.667 rg 0.933 0.91 0.667 RG", index = 108},
  palegreen = { model="rgb", r="0.596" , g="0.984" , b="0.596" , pdfstring = "0.596 0.984 0.596 rg 0.596 0.984 0.596 RG", index = 109},
  paleturquoise = { model="rgb", r="0.686" , g="0.933" , b="0.933" , pdfstring = "0.686 0.933 0.933 rg 0.686 0.933 0.933 RG", index = 110},
  palevioletred = { model="rgb", r="0.859" , g="0.439" , b="0.576" , pdfstring = "0.859 0.439 0.576 rg 0.859 0.439 0.576 RG", index = 111},
  papayawhip = { model="rgb", r="1" , g="0.937" , b="0.835" , pdfstring = "1 0.937 0.835 rg 1 0.937 0.835 RG", index = 112},
  peachpuff = { model="rgb", r="1" , g="0.855" , b="0.725" , pdfstring = "1 0.855 0.725 rg 1 0.855 0.725 RG", index = 113},
  peru = { model="rgb", r="0.804" , g="0.522" , b="0.247" , pdfstring = "0.804 0.522 0.247 rg 0.804 0.522 0.247 RG", index = 114},
  pink = { model="rgb", r="1" , g="0.753" , b="0.796" , pdfstring = "1 0.753 0.796 rg 1 0.753 0.796 RG", index = 115},
  plum = { model="rgb", r="0.867" , g="0.627" , b="0.867" , pdfstring = "0.867 0.627 0.867 rg 0.867 0.627 0.867 RG", index = 116},
  powderblue = { model="rgb", r="0.69" , g="0.878" , b="0.902" , pdfstring = "0.69 0.878 0.902 rg 0.69 0.878 0.902 RG", index = 117},
  purple = { model="rgb", r="0.502" , g="0" , b="0.502" , pdfstring = "0.502 0 0.502 rg 0.502 0 0.502 RG", index = 118},
  red = { model="rgb", r="1" , g="0" , b="0" , pdfstring = "1 0 0 rg 1 0 0 RG", index = 119},
  rosybrown = { model="rgb", r="0.737" , g="0.561" , b="0.561" , pdfstring = "0.737 0.561 0.561 rg 0.737 0.561 0.561 RG", index = 120},
  royalblue = { model="rgb", r="0.255" , g="0.412" , b="0.882" , pdfstring = "0.255 0.412 0.882 rg 0.255 0.412 0.882 RG", index = 121},
  saddlebrown = { model="rgb", r="0.545" , g="0.271" , b="0.075" , pdfstring = "0.545 0.271 0.075 rg 0.545 0.271 0.075 RG", index = 122},
  salmon = { model="rgb", r="0.98" , g="0.502" , b="0.447" , pdfstring = "0.98 0.502 0.447 rg 0.98 0.502 0.447 RG", index = 123},
  sandybrown = { model="rgb", r="0.957" , g="0.643" , b="0.376" , pdfstring = "0.957 0.643 0.376 rg 0.957 0.643 0.376 RG", index = 124},
  seagreen = { model="rgb", r="0.18" , g="0.545" , b="0.341" , pdfstring = "0.18 0.545 0.341 rg 0.18 0.545 0.341 RG", index = 125},
  seashell = { model="rgb", r="1" , g="0.961" , b="0.933" , pdfstring = "1 0.961 0.933 rg 1 0.961 0.933 RG", index = 126},
  sienna = { model="rgb", r="0.627" , g="0.322" , b="0.176" , pdfstring = "0.627 0.322 0.176 rg 0.627 0.322 0.176 RG", index = 127},
  silver = { model="rgb", r="0.753" , g="0.753" , b="0.753" , pdfstring = "0.753 0.753 0.753 rg 0.753 0.753 0.753 RG", index = 128},
  skyblue = { model="rgb", r="0.529" , g="0.808" , b="0.922" , pdfstring = "0.529 0.808 0.922 rg 0.529 0.808 0.922 RG", index = 129},
  slateblue = { model="rgb", r="0.416" , g="0.353" , b="0.804" , pdfstring = "0.416 0.353 0.804 rg 0.416 0.353 0.804 RG", index = 130},
  slategray = { model="rgb", r="0.439" , g="0.502" , b="0.565" , pdfstring = "0.439 0.502 0.565 rg 0.439 0.502 0.565 RG", index = 131},
  slategrey = { model="rgb", r="0.439" , g="0.502" , b="0.565" , pdfstring = "0.439 0.502 0.565 rg 0.439 0.502 0.565 RG", index = 132},
  snow = { model="rgb", r="1" , g="0.98" , b="0.98" , pdfstring = "1 0.98 0.98 rg 1 0.98 0.98 RG", index = 133},
  springgreen = { model="rgb", r="0" , g="1" , b="0.498" , pdfstring = "0 1 0.498 rg 0 1 0.498 RG", index = 134},
  steelblue = { model="rgb", r="0.275" , g="0.51" , b="0.706" , pdfstring = "0.275 0.51 0.706 rg 0.275 0.51 0.706 RG", index = 135},
  tan = { model="rgb", r="0.824" , g="0.706" , b="0.549" , pdfstring = "0.824 0.706 0.549 rg 0.824 0.706 0.549 RG", index = 136},
  teal = { model="rgb", r="0" , g="0.502" , b="0.502" , pdfstring = "0 0.502 0.502 rg 0 0.502 0.502 RG", index = 137},
  thistle = { model="rgb", r="0.847" , g="0.749" , b="0.847" , pdfstring = "0.847 0.749 0.847 rg 0.847 0.749 0.847 RG", index = 138},
  tomato = { model="rgb", r="1" , g="0.388" , b="0.278" , pdfstring = "1 0.388 0.278 rg 1 0.388 0.278 RG", index = 139},
  turquoise = { model="rgb", r="0.251" , g="0.878" , b="0.816" , pdfstring = "0.251 0.878 0.816 rg 0.251 0.878 0.816 RG", index = 140},
  violet = { model="rgb", r="0.933" , g="0.51" , b="0.933" , pdfstring = "0.933 0.51 0.933 rg 0.933 0.51 0.933 RG", index = 141},
  wheat = { model="rgb", r="0.961" , g="0.871" , b="0.702" , pdfstring = "0.961 0.871 0.702 rg 0.961 0.871 0.702 RG", index = 142},
  white = { model="gray", g="1" , pdfstring = "1 G 1 g", index = 143},
  whitesmoke = { model="rgb", r="0.961" , g="0.961" , b="0.961" , pdfstring = "0.961 0.961 0.961 rg 0.961 0.961 0.961 RG", index = 144},
  yellow = { model="rgb", r="1" , g="1" , b="0" , pdfstring = "1 1 0 rg 1 1 0 RG", index = 145},
  yellowgreen = { model="rgb", r="0.604" , g="0.804" , b="0.196" , pdfstring = "0.604 0.804 0.196 rg 0.604 0.804 0.196 RG", index = 146}
}

-- An array of defined colors
colortable = {"black","aliceblue", "orange", "rebeccapurple", "antiquewhite", "aqua", "aquamarine", "azure", "beige", "bisque", "blanchedalmond", "blue", "blueviolet", "brown", "burlywood", "cadetblue", "chartreuse", "chocolate", "coral", "cornflowerblue", "cornsilk", "crimson", "darkblue", "darkcyan", "darkgoldenrod", "darkgray", "darkgreen", "darkgrey", "darkkhaki", "darkmagenta", "darkolivegreen", "darkorange", "darkorchid", "darkred", "darksalmon", "darkseagreen", "darkslateblue", "darkslategray", "darkslategrey", "darkturquoise", "darkviolet", "deeppink", "deepskyblue", "dimgray", "dimgrey", "dodgerblue", "firebrick", "floralwhite", "forestgreen", "fuchsia", "gainsboro", "ghostwhite", "gold", "goldenrod", "gray", "green", "greenyellow", "grey", "honeydew", "hotpink", "indianred", "indigo", "ivory", "khaki", "lavender", "lavenderblush", "lawngreen", "lemonchiffon", "lightblue", "lightcoral", "lightcyan", "lightgoldenrodyellow", "lightgray", "lightgreen", "lightgrey", "lightpink", "lightsalmon", "lightseagreen", "lightskyblue", "lightslategray", "lightslategrey", "lightsteelblue", "lightyellow", "lime", "limegreen", "linen", "maroon", "mediumaquamarine", "mediumblue", "mediumorchid", "mediumpurple", "mediumseagreen", "mediumslateblue", "mediumspringgreen", "mediumturquoise", "mediumvioletred", "midnightblue", "mintcream", "mistyrose", "moccasin", "navajowhite", "navy", "oldlace", "olive", "olivedrab", "orangered", "orchid", "palegoldenrod", "palegreen", "paleturquoise", "palevioletred", "papayawhip", "peachpuff", "peru", "pink", "plum", "powderblue", "purple", "red", "rosybrown", "royalblue", "saddlebrown", "salmon", "sandybrown", "seagreen", "seashell", "sienna", "silver", "skyblue", "slateblue", "slategray", "slategrey", "snow", "springgreen", "steelblue", "tan", "teal", "thistle", "tomato", "turquoise", "violet", "wheat", "white", "whitesmoke", "yellow", "yellowgreen"}

-- The color stack to use
defaultcolorstack = 0

setmetatable(colors,{  __index = function (tbl,key)
    if not key then
        err("Empty color")
        return tbl["black"]
    end
    if string.sub(key,1,1) ~= "#" and string.sub(key,1,3) ~= "rgb" then
        return nil
    end
    log("Defining color %q",key)
    local color = {}
    color.r, color.g, color.b = getrgb(key)
    color.pdfstring = string.format("%g %g %g rg %g %g %g RG", color.r, color.g, color.b, color.r,color.g, color.b)
    color.overprint = false
    color.model = model
    colortable[#colortable + 1] = key
    color.index = #colortable
    rawset(tbl,key,color)
    return color
end
 })

data_dispatcher = {}
user_defined_functions = { last = 0}
markers = {}

-- PDF/UA - the /S /Document StructElem
local ktree = pdf.reserveobj()


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

function new_textformat(name, base,options )
    if name == "" then name = string_random(10) end
    local baseformat = textformats[base] or textformats.text
    options = options or {}
    local tf = {}
    for k,v in pairs(baseformat) do
        tf[k] = v
    end
    for k,v in pairs(options) do
        tf[k] = v
    end
    tf.name = name
    textformats[name] = tf
    return tf
end

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

-- It's convenient to just copy the stretching glue instead of writing
-- the stretch etc. over and over again.
glue_stretch2 = set_glue(nil, { stretch = 2^16, stretch_order = 2 })
messages = {}

-- For attached files. Each of this numbers should appear in the catalog
filespecnumbers = {}

--- The dispatch table maps every element in the layout xml to a command in the `commands.lua` file.
local dispatch_table = {
    A                       = commands.a,
    Action                  = commands.action,
    AddToList               = commands.add_to_list,
    AddSearchpath           = commands.add_searchpath,
    AtPageCreation          = commands.atpagecreation,
    AtPageShipout           = commands.atpageshipout,
    Attribute               = commands.attribute,
    AttachFile              = commands.attachfile,
    B                       = commands.bold,
    Barcode                 = commands.barcode,
    Bookmark                = commands.bookmark,
    Box                     = commands.box,
    Br                      = commands.br,
    Circle                  = commands.circle,
    ClearPage               = commands.clearpage,
    Clip                    = commands.clip,
    Color                   = commands.color,
    Column                  = commands.column,
    Columns                 = commands.columns,
    Compatibility           = commands.compatibility,
    ["Copy-of"]             = commands.copy_of,
    DefineColor             = commands.define_color,
    DefineColorprofile      = commands.define_colorprofile,
    DefineFontfamily        = commands.define_fontfamily,
    DefineFontalias         = commands.define_fontalias,
    DefineGraphic           = commands.define_graphic,
    DefineTextformat        = commands.define_textformat,
    DefineMatter            = commands.definematter,
    Element                 = commands.element,
    EmptyLine               = commands.emptyline,
    Fontface                = commands.fontface,
    ForAll                  = commands.forall,
    Frame                   = commands.frame,
    Grid                    = commands.grid,
    Group                   = commands.group,
    Groupcontents           = commands.groupcontents,
    HTML                    = commands.html,
    HSpace                  = commands.hspace,
    Hyphenation             = commands.hyphenation,
    I                       = commands.italic,
    Image                   = commands.image,
    Include                 = commands.include,
    Layout                  = commands.include,
    Initial                 = commands.initial,
    InsertPages             = commands.insert_pages,
    Li                      = commands.li,
    LoadDataset             = commands.load_dataset,
    LoadFontfile            = commands.load_fontfile,
    Loop                    = commands.loop,
    Makeindex               = commands.makeindex,
    Margin                  = commands.margin,
    Mark                    = commands.mark,
    Message                 = commands.message,
    NewPage                 = commands.new_page,
    NextFrame               = commands.next_frame,
    NextRow                 = commands.next_row,
    NoBreak                 = commands.nobreak,
    Ol                      = commands.ol,
    Options                 = commands.options,
    Output                  = commands.output,
    Overlay                 = commands.overlay,
    Pageformat              = commands.page_format,
    Pagetype                = commands.pagetype,
    Paragraph               = commands.paragraph,
    PDFOptions              = commands.pdfoptions,
    PlaceObject             = commands.place_object,
    Position                = commands.position,
    PositioningArea         = commands.positioning_area,
    PositioningFrame        = commands.positioning_frame,
    ProcessNode             = commands.process_node,
    ProcessRecord           = commands.process_node,
    Record                  = commands.record,
    Rule                    = commands.rule,
    SaveDataset             = commands.save_dataset,
    SavePages               = commands.save_pages,
    Sequence                = commands.sequence,
    SetGrid                 = commands.set_grid,
    SetVariable             = commands.setvariable,
    SortSequence            = commands.sort_sequence,
    Span                    = commands.span,
    Stylesheet              = commands.stylesheet,
    Sub                     = commands.sub,
    Sup                     = commands.sup,
    Switch                  = commands.switch,
    Table                   = commands.table,
    TableNewPage            = commands.talbenewpage,
    Tablefoot               = commands.tablefoot,
    Tablehead               = commands.tablehead,
    Tablerule               = commands.tablerule,
    Td                      = commands.td,
    Textblock               = commands.textblock,
    Text                    = commands.text,
    Tr                      = commands.tr,
    Trace                   = commands.trace,
    Transformation          = commands.transformation,
    U                       = commands.underline,
    Ul                      = commands.ul,
    Until                   = commands.until_do,
    URL                     = commands.url,
    Value                   = commands.value,
    VSpace                  = commands.vspace,
    While                   = commands.while_do,
}

--- The returned table is an array with hashes. The keys of these
--- hashes are `elementname` and `contents`. For example:
---
---     {
---       [1] = {
---         ["elementname"] = "Paragraph"
---         ["contents"] = {
---           ["nodelist"] = "<node    nil <  58515 >    nil : glyph 1>"
---         },
---       },
---     },
function dispatch(layoutxml,dataxml,opts)
    local ret = {}
    local tmp
    if not layoutxml then
        err("No elements for dispatch, why?")
        return
    end
    for _,j in ipairs(layoutxml) do
        -- j a table, if it is an element in layoutxml
        if type(j)=="table" then
            local eltname = j[".__local_name"]
            if dispatch_table[eltname] ~= nil then
                if options.verbosity > 0 then
                    log("Call %q from layout",eltname)
                end
                tmp = dispatch_table[eltname](j,dataxml,opts)

                -- Copy-of-elements can be resolved immediately
                if eltname == "Copy-of" or eltname == "Switch" or eltname == "ForAll" or eltname == "Loop" or eltname == "Transformation" or eltname == "Frame" or eltname == "Include" or eltname == "Layout" or eltname == "Clip" then
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
                    ret[#ret + 1] = { elementname = eltname, contents = tmp}
                end
            else
                local prefix, localname = table.unpack( string.explode(j[".__name"],":"))
                if localname == nil then
                    -- no prefix given, string.explode is wrong about the components
                    -- Therefore we need to swap the both
                    prefix, localname = "", prefix
                end
                if j[".__ns"][prefix] == "urn:speedata.de:2009/publisher/en" then
                    err("Unknown element found in layoutfile: %q", j[".__local_name"] or "???")
                end
            end
        end
    end
    return ret
end


local function pdf_draw_pos(x,y)
    x = sp_to_bp(x)
    y = sp_to_bp(y)
    local wd = 0.1
    return string.format("q 0 g 0.2 w %g %g m %g %g l %g %g l %g %g l h f Q ",x - wd,y - wd,x - wd,y + wd,x + wd,y + wd,x + wd,y - wd)
end
local function pdf_circle_pos(x,y)
    return circle_pdfstring(x,y,10000,10000,"0G 0g","0G 0g",0)
end
local function pdf_circle_pos_big(x,y)
    return circle_pdfstring(x,y,100000,100000,"0G 0g","0G 0g",0)
end
local function pdf_curveto(x1,y1,x2,y2,x3,y3)
    x1 = sp_to_bp(x1)
    y1 = sp_to_bp(y1)
    x2 = sp_to_bp(x2)
    y2 = sp_to_bp(y2)
    x3 = sp_to_bp(x3)
    y3 = sp_to_bp(y3)
    return string.format("%g %g %g %g %g %g c",x1,y1,x2,y2,x3,y3)
end
local function pdf_moveto( x,y )
    x = sp_to_bp(x)
    y = sp_to_bp(y)
    return string.format("%g %g m",x,y)
end
local function pdf_lineto( x,y )
    x = sp_to_bp(x)
    y = sp_to_bp(y)
    return string.format("%g %g l",x,y)
end

function pdfstring_from_color(colorname_or_number)
    local colno = tonumber(colorname_or_number)
    local colorname
    if colno then
        colorname = colortable[colno]
    end
    local colentry = get_colentry_from_name(colorname,"black")
    if colentry then return colentry.pdfstring else return nil end
end

function get_colentry_from_name(colorname, default)
    colorname = colorname or default
    local colentry
    if colorname then
        if not colors[colorname] then
            if default then
                err("Color %q is not defined yet.",colorname)
            else
                colentry = nil
            end
        else
            colentry = colors[colorname]
        end
    end
    return setmetatable(colentry, colormetatable)
end

function get_colorindex_from_name(colorname, default)
    if not colorname then return nil end
    if colorname == "nil" then return nil end
    local colentry = get_colentry_from_name(colorname,default)
    if colentry then return colentry.index else return nil end
end

function transparentcolorstack()
    if defaultcolorstack == 0 then
        defaultcolorstack = pdf.newcolorstack("0 g 0 G/TRP1 gs","direct",true)
    end
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

function page_initialized_p( pagenumber )
    return pages[pagenumber] ~= nil
end

-- action type is one of
-- 0 page
-- 1 goto
-- 2 thread
-- 3 user
-- return an action node or a whatsit with pdf_action subtype.
function get_action_node( action_type )
    local ai = node.new("whatsit",pdf_action_whatsit)
    ai.action_type = action_type
    return ai
end

local function getcreator()
    if sp_suppressinfo then
        return "speedata Publisher, www.speedata.de"
    elseif options.documentcreator and options.documentcreator ~= "" then
        return options.documentcreator
    else
        return string.format("speedata Publisher %s, www.speedata.de",env_publisherversion)
    end
end

local roles = { H1 = 1, H2 = 2, H3 = 3, H4 = 4, H5 = 5, H6 = 6, P = 7  }
local roles_a = {}
for k,v in pairs(roles) do
    roles_a[v] = k
end

function get_rolenum( rolestring )
    if not rolestring then return nil end
    local ret = roles[rolestring]
    if ret then
        return ret
    end
    err("Unknown role %q",tostring(rolestring))
end

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
    xpath.set_variable("_bleed", "0mm")
    xpath.set_variable("_pageheight", "297mm")
    xpath.set_variable("_pagewidth", "210mm")
    xpath.set_variable("_jobname", tex.jobname)
    xpath.set_variable("_matter","mainmatter")


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

    initialize_luatex_and_generate_pdf()
    -- The last thing is to put a stamp in the PDF
    pdf.obj({type="raw",string="(Created with the speedata Publisher - www.speedata.de)", immediate = true, objcompression = false})
end

function get_extension(fn)
    return fn:match("^.+%.(.+)$")
end

function define_image_callback( extensionhandler )
    local extensions = {}
    local ext,handler
    for _,v in ipairs(string.explode(extensionhandler,";")) do
        _,_,ext,handler = string.find(v,"^(.*):(.*)$")
        extensions[ext] = handler
    end
    local function find_image_file( asked_name )
        local file = kpse.find_file(asked_name)
        local ext = get_extension(asked_name)
        local handlername = extensions[ext]
        local handler = imagehandler[handlername]

        if handler then
            log("Convert image (extension: %q) with handler %s",ext,handlername)
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
                    thisbox.margin_top = box.margintop
                end
                if i == #box then
                    thisbox.margin_bottom = box.marginbottom
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

    --- The default page type has 1cm margin
    masterpages[1] = { is_pagetype = "true()", res = { {elementname = "Margin", contents = function(_page) _page.grid:set_margin(tenmm_sp,tenmm_sp,tenmm_sp,tenmm_sp) end }}, name = "Default Page",ns={[""] = "urn:speedata.de:2009/publisher/en" } }
    xpath.set_variable("__maxwidth", tex.sp("190mm"))
    --- The `vars` file hold a lua document holding table
    local vars
    local varsfun = loadfile(tex.jobname .. ".vars")
    if varsfun then vars = varsfun() else err("Could not load .vars file. Something strange is happening.") vars = {} end
    for k,v in pairs(vars) do
        xpath.set_variable(k,v)
    end
    for i=4,#arg do
        local k,v = arg[i]:match("^(.+)=(.+)$")
        if k == "mode" then -- everything else handled after loading layout
            v = v:gsub("^\"(.*)\"$","%1")
            local _modes = string.explode(v,",")
            for _,m in ipairs(_modes) do
                modes[m] = true
            end
        elseif k == "html" then
            htmlfilename = v
            htmlblocks = {}
            options.htmlignoreeol = false
            -- pdf.setcompresslevel(0)
            -- pdf.setobjcompresslevel(0)
            -- publisher.documenttitle = "document"
            -- publisher.options.format = "PDF/UA"
            local tmp = splib.parse_html(htmlfilename)
            if tmp == "" then
                err("Could not read HTML file %q",tostring(htmlfilename))
                exit(false)
            end
            if type(tmp) == "string" then
                local a,b = load(tmp)
                if a then a() else err(b) return end
                local f = io.open(htmlfilename .. ".lua","w")
                f:write(tmp)
                f:close()
                local blocks = parse_html(csshtmltree) or {}
                for b=1,#blocks do
                    local thisblock = blocks[b]
                    htmlblocks[#htmlblocks + 1] = thisblock
                end
            end
        end
    end

    --- Both the data and the layout instructions are written in XML.
    local layoutxml = load_xml(arg[2],"layout instructions")
    if not layoutxml then
        err("Without a valid layout-XML file, I can't really do anything.")
        exit()
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

    if layoutxml.version then
        local version_mismatch = false
        local publisher_version = string.explode(env_publisherversion,".")
        local requested_version = string.explode(layoutxml.version,".")

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
            err("Version mismatch. speedata Publisher is at version %s, requested version %s", env_publisherversion, layoutxml.version)
            exit()
        end
    end

    tmp = os.getenv("SD_PREPEND_XML")
    if tmp and tmp ~= "" then
        for i,v in ipairs(string.explode(tmp,",")) do
            table.insert(layoutxml, i, luxor.parse_xml_file(v))
        end
    end
    tmp = os.getenv("SD_EXTRA_XML")
    if tmp and tmp ~= "" then
        for _,v in ipairs(string.explode(tmp,",")) do
            layoutxml[#layoutxml + 1] = luxor.parse_xml_file(v)
        end
    end

    dispatch(layoutxml)

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
        string.gsub(options.imagehandler,"(%w+):%((.-)%);?", function( imagetype,cmdline )
            imagehandler[imagetype] = cmdline
        end)
    end

    if options.extensionhandler then
        define_image_callback(options.extensionhandler)
    end

    --- Set the starting page (which must be a number)
    if options.startpage then
        local num = options.startpage
        if num then
            current_pagenumber = tonumber(num)
            log("Set page number to %d",num)
        else
            err("Can't recognize starting page number %q",options.startpage)
        end
    end

    if options.colorprofile then
        spotcolors.set_colorprofile_filename(options.colorprofile)
        warning("Options / colorprofile is obsolete. Use DefineColorprofile and PDFOptions / colorprofile instead.")
    end

    local auxfilename = tex.jobname .. "-aux.xml"
    xpath.set_variable("_lastpage", 1)

    -- load help file if it exists
    if kpse.find_file(auxfilename) and options.resetmarks == false then
        local mark_tab = load_xml(auxfilename,"aux file",{ htmlentities = true, ignoreeol = true })
        for i=1,#mark_tab do
            local mt = mark_tab[i]
            if type(mt) == "table" then
                if mt[".__local_name"] == "mark" then
                    markers[mt.name] = { page = mt.page}
                    local id = tonumber(mt.id)
                    if id then
                        marker_id_value[id] = { page = mt.page, name = mt.name}

                        local pagenumber = tonumber(mt.page)
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
                    visible_pagenumbers[tonumber(mt.pagenumber)] = mt.visible
                elseif mt[".__local_name"] == "lastpage" then
                    xpath.set_variable("_lastpage", mt.page )
                end
            end
        end
    end

    -- We allow the use of a dummy xml file for testing purpose
    local dataxml
    local datafilename = arg[3]
    if datafilename == "-dummy" then
        dataxml = luxor.parse_xml("<data />")
    elseif datafilename == "-" then
        log("Reading from stdin")
        dataxml = luxor.parse_xml(io.stdin:read("*a"),{htmlentities = true})
    else
        dataxml = load_xml(datafilename,"data file",{ htmlentities = true, ignoreeol = ( options.ignoreeol or false ) })
    end
    if type(dataxml) ~= "table" then
        err("Something is wrong with the data: dataxml is not a table")
        exit()
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
    local tmp
    local name = dataxml[".__local_name"]
    xpath.set_variable("__position", 1)
    --- The rare case that the user has not any `Record` commands in the layout file:
    if not data_dispatcher[""] then
        err("Can't find any “Record” commands in the layout file.")
        exit()
    end
    tmp = data_dispatcher[""][name]
    if tmp then
        dispatch(tmp,dataxml)
    else
        err("Can't find “Record” command for the root node %q.",name or "")
        exit()
    end

    --- emit last page if necessary
    -- current_pagestore_name is set when in SavePages and nil otherwise
    if page_initialized_p(current_pagenumber) and current_pagestore_name == nil then
        dothingsbeforeoutput(pages[current_pagenumber])
        local n = node.vpack(pages[current_pagenumber].pagebox)
        shipout(n,current_pagenumber)
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
    -- For now only one file can be attached
    if #filespecnumbers > 0 then
      pdfcatalog[#pdfcatalog + 1] = string.format([[ /Names << /EmbeddedFiles <<  /Names [(ZUGFeRD-invoice.xml) %d 0 R ] >> >> /Metadata %d 0 R ]],filespecnumbers[1][1],filespecnumbers[1][2])
      pdfcatalog[#pdfcatalog + 1] = string.format([[ /AF %d 0 R ]],filespecnumbers[1][3])
    end
    local str = get_page_labels_str()
    if str then
        pdfcatalog[#pdfcatalog + 1] = str
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

    if options.displaymode then
        pdfcatalog[#pdfcatalog + 1] = string.format("/PageMode /%s", options.displaymode)
    end


    -- Title   The document’s title.
    -- Author  The name of the person who created the document.
    -- Subject  The subject of the document.
    -- Keywords  Keywords associated with the document.
    local creator = getcreator()
    local infos
    if sp_suppressinfo then
        infos = { "/Creator (speedata Publisher) /Producer (LuaTeX)"}
    elseif options.documentcreator and options.documentcreator ~= "" then
        infos = { string.format("/Creator %s /Producer (speedata Publisher %s using LuaTeX) ",utf8_to_utf16_string_pdf(creator),env_publisherversion) }
    else
        infos = { string.format("/Creator (%s) /Producer (LuaTeX %s (build %s))",creator, luatex_version, status.development_id or "-") }
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
            metadataobjnum = pdf.obj({ type="stream", string = getmetadata(), immediate = true, attr = [[  /Subtype /XML /Type /Metadata ]],compresslevel = 0,})
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
        if options.format == "PDF/UA" then
            pdfcatalog[#pdfcatalog + 1] = string.format("/Lang (de)  /MarkInfo <<  /Marked true >> ")
            metadataobjnum = pdf.obj({ type="stream", string = getuametadata(), immediate = true, attr = [[  /Subtype /XML /Type /Metadata ]],compresslevel = 0,})
            vp[#vp + 1] = "/DisplayDocTitle true"

            local parenttree = pdf.reserveobj()

            local structtreeroot = pdf.obj({ type = "raw", string = string.format("<</Type /StructTreeRoot /K %d 0 R /ParentTree %d 0 R >>",ktree,parenttree), immediate = true})
            local numentries = { "<< /Nums [" }
            for i,v in ipairs(pdfuapages) do
                numentries[#numentries + 1] = string.format("%d %d 0 R ",i-1, v.page_structelem_array)
            end
            numentries[#numentries + 1] = "] >>"
            pdf.obj({type = "raw", string = string.format(table.concat(numentries)), objnum = parenttree, immediate = true})

            -- ktree
            local ktreeentries = {"<< /K ["}

            for _,v in ipairs(pdfuapages) do
                for _,w in ipairs(v.structelementobjects) do
                    ktreeentries[#ktreeentries + 1] = string.format("%d 0 R", w)
                end
            end
            ktreeentries[#ktreeentries + 1] = "] /S /Document /Type /StructElem"
            ktreeentries[#ktreeentries + 1] = string.format("/P %d 0 R",structtreeroot)
            ktreeentries[#ktreeentries + 1] = ">>"
            pdf.obj({type = "raw", string = table.concat( ktreeentries," " ), objnum = ktree, immediate = true})

            pdfcatalog[#pdfcatalog + 1] = string.format("/StructTreeRoot %d 0 R",structtreeroot)
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
    local file = io.open(auxfilename,"wb")
    file:write("<marker>\n")
    file:write(table.concat(tab,"\n"))
    file:write(string.format("\n <lastpage page='%d' />",lastpage))
    file:write("\n</marker>")
    file:close()
end

-- Create a PageLabels dictionary entry and update the visible_pagenumber
-- entry in the pagelabels table for referencing.
-- This is called at the end, when writing a dictionary
function get_page_labels_str()
    local labeltypes = {
        ["lowercase-romannumeral"] = "/r",
        ["uppercase-romannumeral"] = "/R",
        decimal = "/D",
        ["lowercase-letter"] = "/a",
        ["uppercase-letter"] = "/A"
    }
    local labelfunc = function(label,pagenumber)
        if label == "lowercase-romannumeral" then
            return tex.romannumeral(pagenumber)
        elseif label == "uppercase-romannumeral" then
            return string.upper(tex.romannumeral(pagenumber))
        elseif label == "lowercase-letter" then
            return string.char(96 + pagenumber)
        elseif label == "uppercase-letter" then
            return string.char(64 + pagenumber)
        else
            return pagenumber
        end
    end

    local prevmatter

    local tmp = {}
    local c = 0
    -- reset, there might be more pages in the previous run.
    visible_pagenumbers = {}
    for i = 1,#pagelabels do
        c = c + 1
        local p = pagelabels[i]
        local mattername = pagelabels[i].matter
        local thismatter = matters[mattername]

        if prevmatter ~= mattername then
            local str = {}
            if thismatter.prefix and thismatter.prefix ~= "" then
                str[#str + 1] = "/P " .. utf8_to_utf16_string_pdf(thismatter.prefix)
            end
            if thismatter.label then
                str[#str + 1] = "/S " .. ( labeltypes[thismatter.label] or ("/D"))
            else
                str[#str + 1] = "/S /D"
            end
            if prevmatter and matters[prevmatter].resetafter then
                c = 1
            end
            if thismatter.resetbefore then
                c = 1
            end
            if c > 1 then
                str[#str + 1] = string.format("/St %d",c)
            end
            prevmatter = mattername
            tmp[#tmp + 1] = string.format("%d << %s >>", p.pagenumber - 1, table.concat(str," "))
        end
        visible_pagenumbers[i] = string.format("%s%s",thismatter.prefix or "",labelfunc(thismatter.label,c))
    end
    local tmpstring = table.concat(tmp," ")
    if tmpstring == "" or tmpstring == "0 << /S /D >>" then return nil end
    return string.format("/PageLabels << /Nums [ %s ] >> ",tmpstring)
end

-- format: { pagenumber = 1, page_structelem_array = objnum, structelementobjects = {}}
-- where objnum is an array such as [5 0 R 6 0 R]
-- which contains the references to all StructElemns used on the page
-- That is: objects 5 and 6 are /Type /StructElem
pdfuapages = {}

do
    local objcount
    local structelementobjects
    function find_role_attributes( nodelist,parenttree, page )
        local head = nodelist
        while head do
            entry = nil
            if head.id == hlist_node or head.id == vlist_node then
                find_role_attributes(head.list, parenttree, page)
            elseif node.has_attribute(head,att_role) then
                local r = node.has_attribute(head,att_role)
                r = roles_a[r]
                head.data = string.format("/%s<</MCID %d>>BDC", r,objcount)
                local structelement = pdf.obj({type = "raw",string = string.format("<< /Type/StructElem /K %d /P %d 0 R /Pg %d 0 R /S /%s >>", objcount, parenttree, page,r), immediate = true})
                structelementobjects[#structelementobjects + 1] = structelement
                objcount = objcount + 1
            end
            head = head.next
        end
    end

    -- called once for each page
    function insert_struct_elements( nodelist,pagenumber )
        structelementobjects = {}
        objcount = 0
        local parenttree = ktree
        local thispage = pdf.pageref(pagenumber)

        find_role_attributes(nodelist,parenttree,thispage)

        local thispageobj = pdf.reserveobj()
        pdf.obj({type = "raw", immediate = true, objnum = thispageobj, string = string.format("[%s 0 R]", table.concat(structelementobjects, " 0 R ") )  })
        pdfuapages[#pdfuapages + 1] = {pagenumber = pagenumber,page_structelem_array = thispageobj, structelementobjects = structelementobjects }
    end
end

function shipout(nodelist, pagenumber )
    pages_shippedout[pagenumber] = true
    local cp = pages[pagenumber]
    local colorname = cp.defaultcolor
    if not matters[cp.matter] then
        local defaultmatter = xpath.get_variable("_matter")
        err("matter %q unknown, revert to %s",cp.matter or "-", defaultmatter )
        cp.matter = defaultmatter
    end
    pagelabels[pagenumber] = {
        pagenumber = pagenumber,
        matter = cp.matter,
    }
    if colorname then
        if not colors[colorname] then
            err("Pagetype / defaultcolor: color %q is not defined yet.",colorname)
        else
            local colorindex = colors[colorname].index
            nodelist = set_color_if_necessary(nodelist,colorindex)
            nodelist = node.vpack(nodelist)
        end
    end
    if options.format == "PDF/UA" then
        insert_struct_elements(nodelist,pagenumber)
    end
    if options.showdebug then
        local visdebug = require("lua-visual-debug")
        visdebug.show_page_elements(nodelist)
    end
    tex.box[666] = nodelist
    tex.shipout(666)
end

-- adds index metatble for namespace lookup to layout xml
function fixup_layoutxml(tbl,ignoreeol,parent)
    setmetatable(tbl,xml_stringvalue_mt)
    if parent then
        setmetatable(tbl[".__ns"],{__index = parent[".__ns"]})
    end
    for i = 1, #tbl do
        if type(tbl[i]) == "table" then
            fixup_layoutxml(tbl[i],ignoreeol,tbl)
        elseif ignoreeol and type(tbl[i]) == "string" then
            tbl[i] = string.gsub(tbl[i],"\n"," ")
        end
    end
end

--- Load an XML file from the hard drive. filename is without path but including extension,
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
---
---     XML = {
---       [1] = " "
---       [2] = {
---         [1] = " "
---         [2] = {
---           [1] = "text in subelement"
---           [".__parent"] = (pointer to the "element" tree, which is
---                            the second entry in the top level)
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
function load_xml(filename,filetype,parameter)
    parameter = parameter or {}
    if filename == "_internallayouthtml.xml" then
        local src = [[<Layout xmlns="urn:speedata.de:2009/publisher/en"
        xmlns:sd="urn:speedata:2009/publisher/functions/en">
   <Record element="data">
      <Output>
         <Text>
            <HTML>
               <Value select="sd:html(.)"/>
            </HTML>
         </Text>
      </Output>
   </Record>
</Layout>]]
        log("Loading internal HTML layoutfile")
        return luxor.parse_xml(src,parameter)
    else
        if options.xmlparser == "go" then
            if options.verbosity > 0 then
                log("Using new Go based XML reader")
            end
            if options.verbosity > 0 then
                calculate_md5sum(filename)
            end

            local str = splib.loadxmlfile(filename)
            if not str then return {} end
            -- if options.verbosity > 0 and filetype == "layout instructions" then
            --     local f = io.open(filename .. ".lua","w")
            --     f:write(str)
            --     f:close()
            -- end
            local ok,msg = load(str)
            if ok then
                ok()
            else
                log("%s",str)
                err("%s",msg)
                return {}
            end
            local xmltable = tbl[1]
            fixup_layoutxml(xmltable,parameter.ignoreeol)
            return xmltable
        else
            if options.verbosity > 0 then
                log("Using old Lua based XML reader")
            end

            local path = kpse.find_file(filename)
            if not path then
                err("Can't find XML file %q. Abort.",filename or "?")
                return
            end
            if options.verbosity > 0 then
                calculate_md5sum(filename)
            end
            log("Loading %s %q",filetype or "file",path)
            local parsed_xml = luxor.parse_xml_file(path, parameter,kpse.find_file)
            -- if options.verbosity > 0 and filetype == "layout instructions" then
            --     printtable("parsed_xml",parsed_xml)
            -- end
            return parsed_xml
        end
    end
end

function calculate_md5sum(filename)
    local p = kpse.find_file(filename)
    if p then
        local f = io.open(p)
        local str = f:read("*a")
        local sum = md5.sumhexa(str)
        f:close()
        log("filename %q, md5sum: %s",filename,sum)
    end
end

--- Place an object at a position given in scaled points (_x_ and _y_).
---
--- Parameter       | Description
--- ----------------|----------------------------------------------
--- nodelist        | The box to be placed
--- x               | The horizontal distance from the left edge in grid cells
--- y               | The vertical distance form the top edge in grid cells
--- rotate          | Rotation counter clockwise in degrees (0-360).
--- origin_x        | Origin X for rotation. Left is 0 and right is 100
--- origin_y        | Origin Y for rotation. Top is 0 and bottom is 100
--- allocate        | Should the touched cells be allocated?
function output_absolute_position(param)
    local x = param.x
    local y = param.y
    local nodelist = param.nodelist
    local keepposition = param.keepposition

    if param.allocate then
        local additional_width,additional_height = 0,0

        local startcol_sp = x - current_grid.margin_left
        local startrow_sp = y - current_grid.margin_top

        if param.allocate_left then
          startcol_sp = startcol_sp - param.allocate_left
          additional_width = additional_width + param.allocate_left
        end
        if param.allocate_right then
          additional_width = additional_width + param.allocate_right
        end
        if param.allocate_top then
          startrow_sp = startrow_sp - param.allocate_top
          additional_height = additional_height + param.allocate_top
        end
        if param.allocate_bottom then
          additional_height = additional_height + param.allocate_bottom
        end

        local startcol  = math.floor(math.round( (startcol_sp - current_grid.extra_margin) / current_grid.gridwidth ,3)) + 1
        local delta_x = startcol_sp - current_grid:width_sp(startcol - 1)
        if delta_x < 100 then delta_x = 0 end

        local wd_grid = current_grid:width_in_gridcells_sp(nodelist.width + delta_x + additional_width - current_grid.extra_margin)
        local startrow  = math.floor(math.round( (startrow_sp - current_grid.extra_margin) / current_grid.gridheight ,3)) + 1
        local delta_y = startrow_sp - current_grid:height_sp(startrow - 1)
        if delta_y < 100 then delta_y = 0 end
        local ht_grid = current_grid:height_in_gridcells_sp(nodelist.height + delta_y + additional_height - current_grid.extra_margin)
        local _x,_y,_wd,_ht = startcol,startrow,wd_grid,ht_grid
        if _x < 1 then
            _wd = _wd + _x - 1
            _x = 1
        end
        if _y < 1 then
            _ht = _ht + _y - 1
            _y = 1
        end

        current_grid:allocate_cells({
            posx = _x,
            posy = _y,
            width_gridcells = _wd,
            height_gridcells = _ht,
            keepposition = keepposition,
            allocate_matrix = param.allocate_matrix})
    end


    if node.has_attribute(nodelist,att_shift_left) then
        x = x - ( node.has_attribute(nodelist,att_shift_left) or 0)
        y = y - ( node.has_attribute(nodelist,att_shift_up) or 0)
    end

    if param.rotate then
        nodelist = rotate(nodelist,param.rotate, param.origin_x or 0, param.origin_y or 0)
    end

    local n = add_glue( nodelist ,"head",{ width = x })
    n = node.hpack(n)
    n = add_glue(n, "head", {width = y})
    n = node.vpack(n)
    n.width  = 0
    n.height = 0
    n.depth  = 0
    local tail = node.tail(pages[current_pagenumber].pagebox)
    tail.next = n
    n.prev = tail
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

--- Put the object (nodelist) on grid cell (x,y). If `allocate`=`true` then
--- mark cells as occupied.
---
--- Parameter       | Description
--- ----------------|----------------------------------------------
--- nodelist        | The box to be placed
--- x               | The horizontal distance from the left edge in grid cells
--- y               | The vertical distance form the top edge in grid cells
--- allocate        | Mark these cells as 'occupied'
--- area            | The area on which the object should be placed. Defaults to the page area.
--- valign          |
--- halign          |
--- allocate_matrix | For image-shapes
--- pagenumber      | The page the object should be placed
--- keepposition    | Move the local cursor?
--- grid            | The grid object. If not present, we use the default grid object
--- rotate          | Rotation counter clockwise in degrees (0-360).
--- origin_x        | Origin X for rotation. Left is 0 and right is 100
--- origin_y        | Origin Y for rotation. Top is 0 and bottom is 100
--- framewidth      | When frame=solid then this has the frame width
function output_at( param )
    local _wd, _ht, _dp = node.dimensions(param.nodelist)
    if param.framewidth then
        _wd = _wd + param.framewidth
        _ht = _ht + param.framewidth
    end

    -- current_grid is important here, because it can be a group
    local r = param.grid or current_grid


    local outputpage = current_pagenumber
    if param.pagenumber then
        outputpage = param.pagenumber
    end
    local nodelist = param.nodelist
    if options.showobjects then
        nodelist = boxit(nodelist)
    end
    local x = param.x
    local y = param.y

    local additional_width,additional_height = 0,0
    local shift_left,shift_up = 0,0

    if param.allocate_left and param.allocate_left > 100 then
        shift_left = r:width_in_gridcells_sp(param.allocate_left)
        additional_width = additional_width + r:width_in_gridcells_sp(param.allocate_left)
    end
    if param.allocate_right and param.allocate_right > 100 then
        additional_width = additional_width + r:width_in_gridcells_sp(param.allocate_right)
    end
    if param.allocate_top and param.allocate_top > 100 then
        shift_up = r:height_in_gridcells_sp(param.allocate_top)
        additional_height = additional_height + r:height_in_gridcells_sp(param.allocate_top)
    end
    if param.allocate_bottom and param.allocate_bottom > 100 then
        additional_height = additional_height + r:height_in_gridcells_sp(param.allocate_bottom)
    end


    local allocate = param.allocate
    local allocate_matrix = param.allocate_matrix
    local area = param.area or default_areaname
    local valign = param.valign
    local halign = param.halign
    local keepposition = param.keepposition

    local wd = nodelist.width
    local ht = nodelist.height + nodelist.depth

    -- For grid allocation
    local width_gridcells   = r:width_in_gridcells_sp(wd)
    if additional_width > 0 then
        width_gridcells = width_gridcells + additional_width
    end
    local height_gridcells  = r:height_in_gridcells_sp(ht,{floor = (param.vreference == "bottom") })
    if additional_height > 0 then
        height_gridcells = height_gridcells + additional_height
    end

    local delta_x, delta_y = r:position_grid_cell(x,y,area,wd,ht,valign,halign)

    if not delta_x then
        -- if delta_x is nil, delta_y has the error message
        err(delta_y)
        exit()
    end

    if node.has_attribute(nodelist,att_shift_left) then
        delta_x = delta_x - node.has_attribute(nodelist,att_shift_left)
        delta_y = delta_y - node.has_attribute(nodelist,att_shift_up)
    end


    local extra_crop = 0
    if param.framewidth then
        extra_crop = param.framewidth
    end

    -- set the crop area
    r:setarea(delta_x - extra_crop,delta_y - extra_crop, _wd + extra_crop, _ht + extra_crop + _dp)

    --- We don't necessarily output things on a page, we can output them in a virtual page, called _group_.
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
            r:allocate_cells({
                posx = x - shift_left,
                posy = y - shift_up,
                width_gridcells = width_gridcells,
                height_gridcells = height_gridcells,
                allocate_matrix = allocate_matrix,
            })
        end
    else
        -- Put it on the current page
        if allocate then
            r:allocate_cells({
                posx = x - shift_left,
                posy = y - shift_up,
                width_gridcells = width_gridcells,
                height_gridcells = height_gridcells,
                allocate_matrix = allocate_matrix,
                area = area,
                keepposition = keepposition,
                objectwidth = _wd,
                objectheight = _ht + _dp
            })
        end
        if param.rotate then
            nodelist = rotate(nodelist,param.rotate, param.origin_x or 0, param.origin_y or 0)
        end

        place_at(pages[outputpage].pagebox,nodelist,delta_x,delta_y)
    end
end

function place_at(pagebox,nodelist,x_sp,y_sp)
    local tail = node.tail(pagebox)
    local n = add_glue( nodelist ,"head",{ width = x_sp })
    n = node.hpack(n)
    n = add_glue(n, "head", {width = y_sp})
    n = node.vpack(n)
    n.width  = 0
    n.height = 0
    n.depth  = 0

    tail.next = n
    n.prev = tail
end

--- Return the XML structure that is stored at &lt;pagetype>. For every pagetype
--- in the table "masterpages" the function is_pagetype() gets called.
-- pagenumber is for debugging purpose
function detect_pagetype(pagenumber)
    -- ugly hack. file global variables are a bad idea.
    xpath.push_state()
    local cp = current_pagenumber
    current_pagenumber = pagenumber
    local ret = nil
    for i=#masterpages,1,-1 do
        local pagetype = masterpages[i]
        if nextpage then
            if pagetype.name == nextpage then
                log("Page of type %q created (%d) - pagetype requested",pagetype.name or "<detect_pagetype>",pagenumber)
                nextpage = nil
                return pagetype.res
            end
        else
           if xpath.parse(nil,pagetype.is_pagetype,pagetype.ns) == true then
               log("Page of type %q created (%d)",pagetype.name or "<detect_pagetype>",pagenumber)
               ret = pagetype.res
               xpath.pop_state()
               current_pagenumber = cp
               return ret
           end
        end
    end
    err("Can't find correct page type!")
    current_pagenumber = cp
    xpath.pop_state()
    return false
end

function initialize_page(pagenumber)
    local thispage

    if pagenumber then
        thispage = pagenumber
        if pages[pagenumber] ~= nil then
            current_grid=pages[pagenumber].grid
            return
        end
    else
        if page_initialized_p(current_pagenumber) then
            current_grid=pages[current_pagenumber].grid
            return
        end

    end

    if not pagenumber then
        thispage = current_pagenumber
    end
    local trim_amount = tex.sp(options.trim or 0)
    local extra_margin
    if options.cutmarks or options.trimmarks then
        extra_margin = tenmm_sp + trim_amount
    elseif trim_amount > 0 then
        extra_margin = trim_amount
    end
    local errorstring

    current_page, errorstring = page:new(options.default_pagewidth,options.default_pageheight, extra_margin, trim_amount,thispage)
    if not current_page then
        err("Can't create a new page. Is the page type (“PageType”) defined? %s",errorstring)
        exit()
    end
    current_grid = current_page.grid
    -- pages[current_pagenumber] = nil
    pages[thispage] = current_page

    local gridwidth, gridheight, nx, ny, dx, dy
    nx = options.gridcells_x
    ny = options.gridcells_y
    dx = options.gridcells_dx
    dy = options.gridcells_dy

    local pagetype = detect_pagetype(thispage)
    if pagetype == false then return false end
    if pagetype.width then
        current_page.width = tex.sp(pagetype.width)
    end
    if pagetype.height then
        current_page.height = tex.sp(pagetype.height)
    end
    if pagetype.width or pagetype.height then
        xpath.set_variable("_pagewidth", pagetype.width)
        xpath.set_variable("_pageheight", pagetype.height)
        set_pageformat(current_page.width,current_page.height)
    else
        -- 186467sp = 1mm
        local pagewd = current_page.width / 186467
        local pageht = current_page.height / 186467

        xpath.set_variable("_pagewidth", tostring(math.round(pagewd,0)) .. "mm")
        xpath.set_variable("_pageheight", tostring(math.round(pageht,0)) .. "mm")
    end
    local mattername = pagetype.part or xpath.get_variable("_matter")
    local matter = matters[mattername]
    current_page.matter = mattername

    for _,j in ipairs(pagetype) do
        local eltname = elementname(j)
        local eltcontents = element_contents(j)
        if type(element_contents(j))=="function" and eltname=="Margin" then
            eltcontents(current_page)
        elseif eltname=="Grid" then
            local layoutxml = eltcontents.layoutxml
            local dataxml = eltcontents.dataxml
            local width  = read_attribute(layoutxml,dataxml,"width",  "length_sp")
            local height = read_attribute(layoutxml,dataxml,"height", "length_sp") -- shouldn't this be height_sp??? --PG
            local _nx     = read_attribute(layoutxml,dataxml,"nx",     "number")
            local _ny     = read_attribute(layoutxml,dataxml,"ny",     "number")
            local _dx     = read_attribute(layoutxml,dataxml,"dx",     "length_sp")
            local _dy     = read_attribute(layoutxml,dataxml,"dy",     "length_sp")

            gridwidth  = width
            gridheight = height
            nx = _nx
            ny = _ny
            dx = _dx
            dy = _dy
        end
    end

    if gridwidth == nil and options.gridwidth ~= 0 then
        gridwidth = options.gridwidth
    end

    if gridheight == nil and options.gridheight ~= 0 then
        gridheight = options.gridheight
    end

    current_page.grid:set_width_height({wd = gridwidth, ht = gridheight, nx = nx, ny = ny, dx = dx, dy = dy })

    -- The default color is applied during ship-out
    if pagetype.layoutxml and pagetype.layoutxml.defaultcolor then
        current_page.defaultcolor = read_attribute(pagetype.layoutxml,nil,"defaultcolor","string")
    end
    current_page.graphic = pagetype.graphic
    local columnordering = pagetype.columnordering
    for _,j in ipairs(pagetype) do
        local eltname = elementname(j)
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
            local tab  = dispatch(element_contents(j).layoutxml,element_contents(j).dataxml)
            local tmp = {}
            for i,k in ipairs(tab) do
                tmp[#tmp + 1] = element_contents(k)
                tmp[#tmp].order = i
            end
            if columnordering == "rtl" then
                table.sort(tmp,function(a,b)
                    if a.column == b.column then return a.order > b.order end
                    return a.column > b.column
                end)
            end

            for i=1,#tmp do
                table.insert(current_positioning_area,tmp[i])
            end
            -- current_positioning_area[#current_positioning_area + 1] =
            current_positioning_area.colorname = element_contents(j).colorname
        else
            err("Element name %q unknown (setup_page())",eltname or "<create_page>")
        end
    end

    local cp = current_page
    current_page = pages[thispage]
    if current_page.atpagecreation then
        pagebreak_impossible = true
        local cpn = current_pagenumber
        current_pagenumber = thispage
        current_grid = pages[thispage].grid
        dispatch(current_page.atpagecreation,nil)
        current_pagenumber = cpn
        pagebreak_impossible = false
        local graphic = current_page.atpagecreation.graphic
        if graphic then
            local _,whatsit = metapost.prepareboxgraphic(current_page.width,current_page.height,graphic,metapost.extra_page_parameter(current_page))
            place_at(current_page.pagebox,whatsit, current_page.grid.extra_margin,current_page.height+current_page.grid.extra_margin)
        end
    end

    local css_rules
    local cg = current_page.grid

    for k,v in pairs(cg.positioning_frames) do
        css_rules = css:matches({element = 'area', class=class,id=k}) or {}
        if css_rules["border-width"] then
            for i,frame in ipairs(v) do
                frame.draw = { color = "green", width = css_rules["border-width"] }
            end
        end
    end
    current_page = cp

end

-- skippages are set in commands.new_page if openon="..."
skippages = nil
--- _Must_ be called before something can be put on the page. Looks for hooks to be run before page creation.
function setup_page(pagenumber,fromwhere)
    if current_group then return end
    if skippages then
        local tmp = skippages
        skippages = nil
        if tmp.doubleopen then
            new_page("setup_page - skippages doubleopen")
            nextpage = tmp.skippagetype
        end
        new_page("setup_page - skippages 2")
        nextpage = tmp.pagetype
    end

     initialize_page(pagenumber)
end

--- Switch to the next frame in the given area.
function next_area( areaname, grid )
    grid = grid or current_grid
    local current_framenumber = grid:framenumber(areaname)
    if not current_framenumber then
        err("Cannot determine current area number (areaname=%q)",areaname or "(undefined)")
        return
    end
    if current_framenumber >= grid:number_of_frames(areaname) then
        new_page("next_area")
    else
        grid:set_framenumber(areaname, current_framenumber + 1)
    end
    grid:set_current_row(1,areaname)
    grid:set_current_column(1,areaname)
end

--- Switch to a new page and ship out the current page.
--- This new page is only created if something is typeset on it.
function new_page(from)
    -- w("new page from %s",from or "-")
    if pagebreak_impossible then
        return
    end
    local thispage = pages[current_pagenumber]
    if not thispage then
        -- new_page() is called without anything on the page yet
        setup_page(nil,"new_page")
        thispage = current_page
    end

    dothingsbeforeoutput(thispage)

    local n = node.vpack(pages[current_pagenumber].pagebox)
    if current_pagestore_name then
        local thispagestore = pagestore[current_pagestore_name]
        thispagestore[#thispagestore + 1] = n
    else
        shipout(n,current_pagenumber)
    end
    current_pagenumber = current_pagenumber + 1
end

function clearpage(options)
    local thispage = pages[current_pagenumber]

    if thispage then
        dothingsbeforeoutput(thispage)
        local n = node.vpack(pages[current_pagenumber].pagebox)
        shipout(n,current_pagenumber)
        current_pagenumber = current_pagenumber + 1
    else
        if options.force then
            initialize_page()
            local tmp = pages[current_pagenumber]
            dothingsbeforeoutput(tmp)
            local n = node.vpack(pages[current_pagenumber].pagebox)
            shipout(n,current_pagenumber)
            current_pagenumber = current_pagenumber + 1
        end
    end

    local doubleopen = false
    if ( options.openon == "right" and math.fmod(current_pagenumber,2) == 0 ) or ( options.openon == "left" and math.fmod(current_pagenumber,2) == 1 ) then
        doubleopen = true
    end

    if doubleopen then
        -- shipout dummy page
        if options.skippagetype then
            nextpage = options.skippagetype
        end
        initialize_page()
        local tmp = pages[current_pagenumber]
        dothingsbeforeoutput(tmp)
        local n = node.vpack(pages[current_pagenumber].pagebox)
        shipout(n,current_pagenumber)
        current_pagenumber = current_pagenumber + 1
    end

    if options.matter then
        xpath.set_variable("_matter",options.matter)
    end
    if options.pagetype then
        nextpage = options.pagetype
    end
end

-- a,b are both arrays of 6 numbers
function concat_transformation( a, b )
    local c = {}
    c[1] = a[1] * b[1] + a[2] * b[3]
    c[2] = a[1] * b[2] + a[2] * b[4]
    c[3] = a[3] * b[1] + a[4] * b[3]
    c[4] = a[3] * b[2] + a[4] * b[4]
    c[5] = a[5] * b[1] + a[6] * b[3] + b[5]
    c[6] = a[5] * b[2] + a[6] * b[4] + b[6]
    return c
end

-- Place a text in the background
function bgtext( box, textstring, angle, colorname, fontfamily, bgsize)
    local colorindex = colors[colorname].index
    local boxheight, boxwidth = box.height, box.width
    local angle_rad = -1 * math.rad(angle)
    local sin = math.sin(angle_rad)
    local cos = math.cos(angle_rad)

    a = par:new(nil,"bgtext")
    a:append(textstring, {fontfamily = fontfamily,color = colorindex})
    a:mknodelist()
    local textbox = node.hpack(a.objects[1])
    local rotated_height = sin * textbox.width  + cos * textbox.height
    local scale
    local shift_up = 0
    if bgsize == "contain" then
        scale = boxheight  / rotated_height
    else
        scale = 1
        shift_up = sp_to_bp((boxheight - rotated_height) / 2)
    end
    local rotated_width  = sin * textbox.height + cos * textbox.width
    local shift_right = sp_to_bp( (boxwidth - rotated_width * scale ) / 2)

    -- rotate: [cos θ sin θ −sin θ cos θ 0 0 ]
    local rotate_matrix = {   cos, sin, -1 * sin,   cos,           0, 0        }
    local scale_matrix  = { scale,   0,        0, scale,           0, 0        }
    local shift_matrix  = {     1,   0,        0,     1, shift_right, shift_up }
    local result_matrix
    result_matrix = concat_transformation(rotate_matrix,scale_matrix)
    result_matrix = concat_transformation(result_matrix,shift_matrix)
    local matrixstring = string.format("%g %g %g %g %d %g",math.round(result_matrix[1],3),math.round(result_matrix[2],3),math.round(result_matrix[3],3),math.round(result_matrix[4],3),math.round(result_matrix[5],3),math.round(result_matrix[6],3))
    local x = matrix( textbox, matrixstring,0,0 )
    x = node.hpack(x)
    x.width = 0
    x.height = 0
    box = node.insert_before(box,box,x)
    box = node.hpack(box)
    return box
end

--- Draw a background behind the rectangular (box) object.
function background( box, colorname )
    -- color '-' means 'no color'
    if colorname == "-" then return box end
    if not colors[colorname] then
        warning("Background: Color %q is not defined",colorname)
        return box
    end
    local pdfcolorstring = colors[colorname].pdfstring
    local wd, ht, dp = sp_to_bp(box.width),sp_to_bp(box.height),sp_to_bp(box.depth)
    n = node.new("whatsit","pdf_literal")
    setprop(n,"origin","background")
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

--- Draw a colored frame around a given TeX box
--- The control points of the frame are
--- ![control points](img/roundedcorners.svg)
-- obj is a table with the keys
--   box: the TeX box
--   colorname: the name of a color (defaults to "black")
--   width: the width of the border (defaults to 0)
--   clip: should the outside be clipped?
--   b_x_y_radius, where x = b or t and y = r or l: the radius of the corners
-- The function returns a hbox
function frame(obj)
    local  box, colorname, width
    box          = obj.box
    colorname    = obj.colorname or "black"
    width        = obj.rulewidth or 0
    local b_b_r_radius = sp_to_bp(obj.b_b_r_radius)
    local b_t_r_radius = sp_to_bp(obj.b_t_r_radius)
    local b_t_l_radius = sp_to_bp(obj.b_t_l_radius)
    local b_b_l_radius = sp_to_bp(obj.b_b_l_radius)

    local b_b_r_radius_inner = math.round(math.max(sp_to_bp(obj.b_b_r_radius) - width / factor,0),3)
    local b_t_r_radius_inner = math.round(math.max(sp_to_bp(obj.b_t_r_radius) - width / factor,0),3)
    local b_t_l_radius_inner = math.round(math.max(sp_to_bp(obj.b_t_l_radius) - width / factor,0),3)
    local b_b_l_radius_inner = math.round(math.max(sp_to_bp(obj.b_b_l_radius) - width / factor,0),3)

    -- See https://en.wikipedia.org/wiki/File:Circle_and_cubic_bezier.svg
    -- https://en.wikipedia.org/wiki/Composite_B%C3%A9zier_curve
    -- 0.5522847498
    -- http://spencermortensen.com/articles/bezier-circle/
    -- 0.551915024494
    local circle_bezier = 0.551915024494
    local color = colors[colorname]
    if not color then
        err("Color %q is not defined",tostring(colorname))
        color = colors["black"]
    end
    local pdfcolorstring = color.pdfstring
    local wd, ht, dp = sp_to_bp(box.width),sp_to_bp(box.height),sp_to_bp(box.depth)
    local rw = math.round(width / factor,3) -- width of stroke

    -- outer boundary
    local x1, y1   = -rw + b_b_l_radius                     , -rw - dp
    local x2, y2   =  rw + wd - b_b_r_radius                , -rw - dp
    local x3, y3   =  rw + wd - circle_bezier * b_b_r_radius, -rw - dp
    local x4, y4   =  rw + wd                               , -rw + circle_bezier * b_b_r_radius
    local x5, y5   =  rw + wd                               , -rw + b_b_r_radius
    local x6, y6   =  rw + wd                               ,  rw + ht - b_t_r_radius
    local x7, y7   =  rw + wd                               ,  rw + ht - circle_bezier * b_t_r_radius
    local x8, y8   =  rw + wd - circle_bezier * b_t_r_radius,  rw + ht
    local x9, y9   =  rw + wd - b_t_r_radius                ,  rw + ht
    local x10, y10 = -rw + b_t_l_radius                     ,  rw + ht
    local x11, y11 = -rw + circle_bezier * b_t_l_radius     ,  rw + ht
    local x12, y12 = -rw                                    ,  rw + ht - circle_bezier * b_t_l_radius
    local x13, y13 = -rw                                    ,  rw + ht - b_t_l_radius
    local x14, y14 = -rw                                    , -rw + b_b_l_radius
    local x15, y15 = -rw                                    , -rw + circle_bezier * b_b_l_radius
    local x16, y16 = -rw + circle_bezier * b_b_l_radius     , -rw

    x1,  y1  = math.round(x1,3),  math.round(y1,3)
    x2,  y2  = math.round(x2,3),  math.round(y2,3)
    x3,  y3  = math.round(x3,3),  math.round(y3,3)
    x4,  y4  = math.round(x4,3),  math.round(y4,3)
    x5,  y5  = math.round(x5,3),  math.round(y5,3)
    x6,  y6  = math.round(x6,3),  math.round(y6,3)
    x7,  y7  = math.round(x7,3),  math.round(y7,3)
    x8,  y8  = math.round(x8,3),  math.round(y8,3)
    x9,  y9  = math.round(x9,3),  math.round(y9,3)
    x10, y10 = math.round(x10,3), math.round(y10,3)
    x11, y11 = math.round(x11,3), math.round(y11,3)
    x12, y12 = math.round(x12,3), math.round(y12,3)
    x13, y13 = math.round(x13,3), math.round(y13,3)
    x14, y14 = math.round(x14,3), math.round(y14,3)
    x15, y15 = math.round(x15,3), math.round(y15,3)
    x16, y16 = math.round(x16,3), math.round(y16,3)


    -- inner boundary
    local xx1, yy1   =   b_b_l_radius_inner                      , -dp
    local xx2, yy2   =   wd - b_b_r_radius_inner                 , -dp
    local xx3, yy3   =   wd - circle_bezier * b_b_r_radius_inner , 0
    local xx4, yy4   =   wd                                      , circle_bezier * b_b_r_radius_inner
    local xx5, yy5   =   wd                                      , b_b_r_radius_inner
    local xx6, yy6   =   wd                                      , ht - b_t_r_radius_inner
    local xx7, yy7   =   wd                                      , ht - circle_bezier * b_t_r_radius_inner
    local xx8, yy8   =   wd - circle_bezier * b_t_r_radius_inner , ht
    local xx9, yy9   =   wd - b_t_r_radius_inner                 , ht
    local xx10, yy10 =   b_t_l_radius_inner                      , ht
    local xx11, yy11 =   circle_bezier * b_t_l_radius_inner      , ht
    local xx12, yy12 =   0                                       , ht - circle_bezier * b_t_l_radius_inner
    local xx13, yy13 =   0                                       , ht - b_t_l_radius_inner
    local xx14, yy14 =   0                                       , b_b_l_radius_inner
    local xx15, yy15 =   0                                       , circle_bezier * b_b_l_radius_inner
    local xx16, yy16 =   circle_bezier * b_b_l_radius_inner      , 0

    xx1,  yy1  = math.round(xx1,3),  math.round(yy1,3)
    xx2,  yy2  = math.round(xx2,3),  math.round(yy2,3)
    xx3,  yy3  = math.round(xx3,3),  math.round(yy3,3)
    xx4,  yy4  = math.round(xx4,3),  math.round(yy4,3)
    xx5,  yy5  = math.round(xx5,3),  math.round(yy5,3)
    xx6,  yy6  = math.round(xx6,3),  math.round(yy6,3)
    xx7,  yy7  = math.round(xx7,3),  math.round(yy7,3)
    xx8,  yy8  = math.round(xx8,3),  math.round(yy8,3)
    xx9,  yy9  = math.round(xx9,3),  math.round(yy9,3)
    xx10, yy10 = math.round(xx10,3), math.round(yy10,3)
    xx11, yy11 = math.round(xx11,3), math.round(yy11,3)
    xx12, yy12 = math.round(xx12,3), math.round(yy12,3)
    xx13, yy13 = math.round(xx13,3), math.round(yy13,3)
    xx14, yy14 = math.round(xx14,3), math.round(yy14,3)
    xx15, yy15 = math.round(xx15,3), math.round(yy15,3)
    xx16, yy16 = math.round(xx16,3), math.round(yy16,3)

    local n_clip, rule_clip

    if obj.clip then
        n_clip = node.new("whatsit","pdf_literal")
        setprop(n_clip,"origin","obj.clip")
        rule_clip = {}
        rule_clip[#rule_clip + 1] = string.format("%g %g m",xx1,yy1)
        rule_clip[#rule_clip + 1] = string.format("%g %g l",xx2,yy2)
        rule_clip[#rule_clip + 1] = string.format("%g %g %g %g %g %g c", xx3,yy3, xx4,yy4, xx5, yy5 )
        rule_clip[#rule_clip + 1] = string.format("%g %g l",xx6, yy6)
        rule_clip[#rule_clip + 1] = string.format("%g %g %g %g %g %g c", xx7,yy7,xx8,yy8, xx9,yy9  )
        rule_clip[#rule_clip + 1] = string.format("%g %g l",xx10, yy10)
        rule_clip[#rule_clip + 1] = string.format("%g %g %g %g %g %g c", xx11,yy11,xx12,yy12, xx13,yy13  )
        rule_clip[#rule_clip + 1] = string.format("%g %g l",xx14,yy14 )
        rule_clip[#rule_clip + 1] = string.format("%g %g %g %g %g %g c W n ", xx15,yy15,xx16,yy16, xx1,yy1  )
    end

    local n = node.new("whatsit","pdf_literal")
    setprop(n,"origin","publisher.frame")
    local rule = {}

    -- We need to add q .. Q because the color would leak into the inner objects (#55)
    rule[#rule + 1] = string.format("q %s",pdfcolorstring)
    rule[#rule + 1] = string.format("%g w",rw)           -- rule width

    rule[#rule + 1] = string.format("%g %g m",xx1,yy1)
    rule[#rule + 1] = string.format("%g %g l",xx2,yy2)
    rule[#rule + 1] = string.format("%g %g %g %g %g %g c", xx3,yy3, xx4,yy4, xx5, yy5 )
    rule[#rule + 1] = string.format("%g %g l",xx6, yy6)
    rule[#rule + 1] = string.format("%g %g %g %g %g %g c", xx7,yy7,xx8,yy8, xx9,yy9  )
    rule[#rule + 1] = string.format("%g %g l",xx10, yy10)
    rule[#rule + 1] = string.format("%g %g %g %g %g %g c", xx11,yy11,xx12,yy12, xx13,yy13  )
    rule[#rule + 1] = string.format("%g %g l",xx14,yy14 )
    rule[#rule + 1] = string.format("%g %g %g %g %g %g c ", xx15,yy15,xx16,yy16, xx1,yy1  )

    rule[#rule + 1] = string.format("%g %g m",x1,y1)
    rule[#rule + 1] = string.format("%g %g l",x2,y2)
    rule[#rule + 1] = string.format("%g %g %g %g %g %g c", x3,y3, x4,y4, x5, y5 )
    rule[#rule + 1] = string.format("%g %g l",x6, y6)
    rule[#rule + 1] = string.format("%g %g %g %g %g %g c", x7,y7,x8,y8, x9,y9  )
    rule[#rule + 1] = string.format("%g %g l",x10, y10)
    rule[#rule + 1] = string.format("%g %g %g %g %g %g c", x11,y11,x12,y12, x13,y13  )
    rule[#rule + 1] = string.format("%g %g l",x14,y14 )
    rule[#rule + 1] = string.format("%g %g %g %g %g %g c", x15,y15,x16,y16, x1,y1  )
    if rw == 0 then
        rule[#rule + 1] = "n"
    else
        rule[#rule + 1] = "f* s"
    end
    rule[#rule + 1] = "Q"

    n.data = table.concat(rule," ")
    if (obj.clip==true) then
        n_clip.data = table.concat(rule_clip, " ")
        node.setproperty(n_clip,{origin = "frame/clip"})
    end

    local pdf_save    = node.new("whatsit","pdf_save")
    local pdf_restore = node.new("whatsit","pdf_restore")

    node.insert_after(pdf_save,pdf_save,n)
    if (obj.clip==true) then
        node.insert_after(n,n,n_clip)
        node.insert_after(n_clip,n_clip,box)
    else
        node.insert_after(n,n,box)
    end

    local hvbox = node.hpack(pdf_save)
    local savedp = hvbox.depth
    hvbox.depth = 0
    node.insert_after(hvbox,node.tail(hvbox),pdf_restore)
    hvbox = node.vpack(hvbox)
    hvbox = node.vpack(hvbox)
    hvbox.depth = savedp
    return hvbox
end

function clip(obj)
    local box = obj.box
    local wd, ht, dp = sp_to_bp(box.width),sp_to_bp(box.height),sp_to_bp(box.depth)

    local kern_left = node.new("kern")
    local kern_top = node.new("kern")

    if obj.clip_width_sp ~= 0 then
        if obj.clip_left_sp ~= 0 or obj.clip_right_sp == 0 then
            obj.clip_right_sp = box.width - obj.clip_width_sp - obj.clip_left_sp
        else
            obj.clip_left_sp = box.width - obj.clip_width_sp - obj.clip_right_sp
        end
    end

    if obj.clip_height_sp ~= 0 then
        if obj.clip_top_sp ~= 0 or obj.clip_bottom_sp == 0  then
            obj.clip_bottom_sp = box.height - obj.clip_height_sp - obj.clip_top_sp
        else
            obj.clip_top_sp = box.height - obj.clip_height_sp - obj.clip_bottom_sp
        end
    end



    local clip_top_bp = sp_to_bp(obj.clip_top_sp)
    local clip_bottom_bp = sp_to_bp(obj.clip_bottom_sp)
    local clip_left_bp = sp_to_bp(obj.clip_left_sp)
    local clip_right_bp = sp_to_bp(obj.clip_right_sp)

    if obj.method == "clip" then
        kern_left.kern = -1 * obj.clip_left_sp
        kern_top.kern = -1 * obj.clip_top_sp
    end

    node.insert_after(kern_left,kern_left,box)
    box = node.hpack(kern_left)
    node.insert_after(kern_top,kern_top,box)
    box = node.vpack(kern_top)

    n_clip = node.new("whatsit","pdf_literal")
    setprop(n_clip,"origin","obj.clip")
    local n_clip, rule_clip
    rule_clip = {}
    if obj.method == "clip" then
        rule_clip[#rule_clip + 1] = string.format(" %g %g %g %g re W n ", 0,  -1 * dp + clip_bottom_bp, wd - clip_right_bp - clip_left_bp,ht+dp - clip_bottom_bp - clip_top_bp )
    elseif obj.method == "frame" then
        rule_clip[#rule_clip + 1] = string.format(" %g %g %g %g re W n ", clip_left_bp,  -1 * dp + clip_bottom_bp, wd - clip_right_bp - clip_left_bp,ht+dp - clip_bottom_bp - clip_top_bp )
    else
        err("Clip: method %s not implemented",obj.method)
    end

    n_clip = node.new("whatsit","pdf_literal")
    n_clip.data = table.concat(rule_clip, " ")
    node.setproperty(n_clip,{origin = "frame/clip"})

    local pdf_save    = node.new("whatsit","pdf_save")
    local pdf_restore = node.new("whatsit","pdf_restore")

    node.insert_after(pdf_save,pdf_save,n_clip)
    node.insert_after(n_clip,n_clip,box)

    local hvbox = node.hpack(pdf_save)
    local savedp = hvbox.depth
    hvbox.depth = 0
    node.insert_after(hvbox,node.tail(hvbox),pdf_restore)
    hvbox = node.vpack(hvbox)
    if obj.method == "clip" then
        hvbox.width = hvbox.width - obj.clip_right_sp
        hvbox.height = hvbox.height - obj.clip_bottom_sp
    end
    hvbox.depth = savedp

    return hvbox
end


-- collect all spot colors used so far to create proper page resources
function usespotcolor(num)
    used_spotcolors[num] = true
end

-- Set the PDF page-resources for the current page.
function setpageresources(thispage)
    -- thispage.transparenttext is something like { 40 = true, 20 = true}
    -- but only if we use alpha values for color
    local transparenttextresources = ""
    if defaultcolorstack ~= 0 then
        local tmp = {"/TRP1 << /CA 1 /ca 1 >>"}
        for k,_ in pairs(thispage.transparenttext) do
            tmp[#tmp + 1] = string.format("/TRP%s << /CA %g /ca %g >>",k,k/100,k/100)
        end
        transparenttextresources = table.concat(tmp,"")
    end
    local gstateresource = string.format(" /ExtGState << %s/GS0 %d 0 R /GS1 %d 0 R >>", transparenttextresources, GS_State_OP_On, GS_State_OP_Off)

    -- LuaTeX has setpageresources
    if #used_spotcolors > 0 then
        pdf.setpageresources("/ColorSpace << " .. spotcolors.getresource(used_spotcolors) .. " >>" .. gstateresource )
    else
        pdf.setpageresources(gstateresource)
    end
end

-- index metatable for colentry.pdfstring
function colentry_index_function(tbl,idx)
    local model = rawget(tbl,"model")
    if model == "spotcolor" then
        if idx == "pdfstring" then
            usespotcolor(tbl.colornum)
            local op
            if tbl.overprint then
                op = "/GS0 gs"
            else
                op = ""
            end
            return string.format("%s /CS%d CS /CS%d cs 1 scn ",op,tbl.colornum, tbl.colornum)
        elseif idx == "pdfstring_stroking" then
            usespotcolor(tbl.colornum)
            local op
            if tbl.overprint then
                op = "/GS0 gs"
            else
                op = ""
            end
            local ret = string.format("%s /CS%d CS 1 scn ",op,tbl.colornum)
            return ret
        elseif idx == "pdfstring_fill" then
            usespotcolor(tbl.colornum)
            local op
            if tbl.overprint then
                op = "/GS0 gs"
            else
                op = ""
            end
            local ret = string.format("%s /CS%d cs 1 scn ",op,tbl.colornum)
            return ret
        end
    elseif idx == "pdfstring_stroking" then
        local _,b = fill_stroke_color(rawget(tbl,"pdfstring"))
        return b
    elseif idx == "pdfstring_fill" then
        local a,_ = fill_stroke_color(rawget(tbl,"pdfstring"))
        return a
    -- elseif idx == "pdfstring" then
    --     return rawget(tbl,"pdfstring")
    end
end

-- used in DefineColor
colormetatable = {__index = colentry_index_function}

-- return the fill and stroke color of the given color string
function fill_stroke_color( pdfcolor )
    local a,b = string.match(pdfcolor,"^(.*rg)(.*RG)")
    if a ~= nil then
        return a,b
    end
    a,b = string.match(pdfcolor,"^(.*k)(.*K)")
    if a ~= nil then
        return a,b
    end
    a,b = string.match(pdfcolor,"^(.*G)(.*g)")
    return a,b
end

--- Get PDF string for circle
---
--- ![Control points in the circle](img/circlepoints.svg)
---
function circle_pdfstring(center_x, center_y, radiusx_sp, radiusy_sp, stroke_colorstring, fill_colorstring, rulewidth_sp )
    local circle_bezier = 0.551915024494

    local shift_dn, shift_rt = -radiusy_sp + center_y, -radiusx_sp + center_x
    local dx = radiusx_sp * (1 - circle_bezier)
    local dy = radiusy_sp * (1 - circle_bezier)

    local x1 = shift_rt
    local y1 = shift_dn + radiusy_sp
    local x2 = x1
    local y2 = shift_dn + radiusy_sp * 2 - dy
    local x3 = shift_rt + dx
    local y3 = shift_dn + radiusy_sp * 2
    local x4 = shift_rt + radiusx_sp
    local y4 = shift_dn + radiusy_sp * 2
    local x5 = shift_rt + radiusx_sp * 2 - dx
    local y5 = y3
    local x6 = shift_rt + radiusx_sp * 2
    local y6 = y2
    local x7 = x6
    local y7 = y1
    local x8 = x6
    local y8 = shift_dn + dy
    local x9 = x5
    local y9 = shift_dn
    local x10 = x4
    local y10 = y9
    local x11 = x3
    local y11 = y9
    local x12 = x1
    local y12 = y8
    local circle = {}
    circle[#circle + 1] = "q"
    circle[#circle + 1] = string.format("%g w %s %s", sp_to_bp(rulewidth_sp), stroke_colorstring, fill_colorstring)
    circle[#circle + 1] = pdf_moveto(x1,y1)
    circle[#circle + 1] = pdf_curveto(x2,y2,x3,y3,x4,y4)
    circle[#circle + 1] = pdf_curveto(x5,y5,x6,y6,x7,y7)
    circle[#circle + 1] = pdf_curveto(x8,y8,x9,y9,x10,y10)
    circle[#circle + 1] = pdf_curveto(x11,y11,x12,y12,x1,y1)
    if fill_colorstring == "" then
        circle[#circle + 1] = "s"
    else
        circle[#circle + 1] = "b"
    end
    circle[#circle + 1] = "Q"
    return table.concat(circle, " ")
end

--- Draw a circle
function circle( radiusx_sp, radiusy_sp, colorname,framecolorname,rulewidth_sp)
    if rulewidth_sp < 5 then
        framecolorname = colorname
    end
    local colentry = get_colentry_from_name(colorname)
    if not colentry then
        err("Color %q unknown, reverting to black",colorname or "(no color name given)")
        colentry = colors["black"]
    end
    local framecolentry = get_colentry_from_name(framecolorname)

    if not framecolentry then
        err("Color %q unknown, reverting to black",framecolorname or "(no color name given)")
        framecolentry = colors["black"]
    end
    local fillcolor   = colentry.pdfstring_fill
    local bordercolor = framecolentry.pdfstring_stroking

    local paint = node.new("whatsit","pdf_literal")
    paint.data = circle_pdfstring(0,0,radiusx_sp, radiusy_sp, bordercolor, fillcolor, rulewidth_sp)
    local v = node.vpack(paint)
    return v
end

function mpbox(parameter,width,height)
    local width_sp = width
    local height_sp = height
    local extra_parameter = {}

    extra_parameter.bordertopwidth = sp_to_bp(parameter.border_top_width) .. "bp"
    extra_parameter.borderbottomwidth = sp_to_bp(parameter.border_bottom_width) .. "bp"
    extra_parameter.borderleftwidth = sp_to_bp(parameter.border_left_width) .. "bp"
    extra_parameter.borderrightwidth = sp_to_bp(parameter.border_right_width) .. "bp"
    extra_parameter.paddingtop = sp_to_bp(parameter.padding_top or 0) .. "bp"
    extra_parameter.paddingbottom = sp_to_bp(parameter.padding_bottom or 0) .. "bp"

    extra_parameter.colors = {
        bordertopcolor = parameter.border_top_color,
        borderbottomcolor = parameter.border_bottom_color,
        borderleftcolor = parameter.border_left_color,
        borderrightcolor = parameter.border_right_color
    }
    extra_parameter.strings = {
        bordertopstyle = parameter.border_top_style,
        borderbottomstyle = parameter.border_bottom_style,
        borderleftstyle = parameter.border_left_style,
        borderrightstyle = parameter.border_right_style
    }

    local mptext = [[
        linecap := butt;
        wd = box.width  ;
        ht = box.height - bordertopwidth - borderbottomwidth ;
        if ht < 0: ht := 0; fi;
        if wd < 0: wd := 0; fi;
        z1 = (0,0);
        x2 = borderleftwidth;
        x3 = x2 + wd;
        x4 = x3 + borderrightwidth;

        y2 = y1 + borderbottomwidth;
        y3 = y2 + ht;
        y4 = y3 + bordertopwidth;

        % draw z1 -- (x4,y1) -- z4 -- (x1,y4) -- cycle;
        % draw z2 -- (x3,y2) -- z3 -- (x2,y3) -- cycle;

        picture border; border = nullpicture;

        path clip_top, clip_bottom, clip_left, clip_right;
        clip_top = (x1,y4) -- (x2,y3) -- z3 -- z4 -- cycle;
        clip_bottom = (x1,y1) -- (x2,y2) -- (x3,y2) -- (x4,y1) -- cycle;
        clip_left = (x1,y1) -- (x2,y2) -- (x2,y3) -- (x1,y4) -- cycle;
        clip_right = (x4,y1) -- (x3,y2) -- (x3,y3) -- (x4,y4) -- cycle;
        def isdarkcolor(expr c) =
            (redpart c < 0.2) and (greenpart c < 0.2) and (bluepart c < 0.2 )
        enddef;

        def drawborder(expr bordercolor, bwd, style, a, b, clippath, pos) =
            color col; col = bordercolor;
            string str;
            str = "withcolor col withpen pencircle scaled " & decimal bwd ;
            if style == "dashed":
                str := str & " dashed dashpattern(on 4bp off 5bp)"
            elseif ( style == "inset" )  and  (  (pos == "top" )  or (pos == "left") ):
                if isdarkcolor(col):
                    str := str & " withcolor 0.2[col, white] ";
                else:
                    str := str & " withcolor 0.5[col, black] ";
                fi;
            elseif ( style == "inset" ) and isdarkcolor(col) and ( (pos == "bottom" ) or (pos == "right") ):
                str := str & " withcolor 0.5[col, white] ";
            elseif ( style == "outset" )  and  (  (pos == "right" ) or (pos == "bottom") ):
                str := str & " withcolor 0.5[col, black] ";
            fi;
            drawoptions(scantokens(str));

            draw a -- b ;
            clip currentpicture to clippath ;
            addto border also currentpicture ;
        enddef;

        y34 = 0.5[y3,y4];
        y12 = 0.5[y1,y2];
        x12 = 0.5[x1,x2];
        x34 = 0.5[x3,x4];

        drawborder(bordertopcolor,bordertopwidth, bordertopstyle, (x1,y34),(x4,y34), clip_top, "top" );
        drawborder(borderbottomcolor,borderbottomwidth,borderbottomstyle, (x1,y12),(x4,y12), clip_bottom, "bottom");
        drawborder(borderleftcolor,borderleftwidth, borderleftstyle,(x12,y1),(x12,y4), clip_left, "left" );
        drawborder(borderrightcolor,borderrightwidth, borderrightstyle,(x34,y1),(x34,y4), clip_right, "right" );

        currentpicture := border;

    ]]
    metapostgraphics.__htmlbox = mptext
    local ret = metapost.boxgraphic(width_sp,height_sp,"__htmlbox",extra_parameter,{shiftdown = parameter.shiftdown})
    node.set_attribute(ret,att_dontadjustlineheight,1)
    ret.height = 0
    ret.depth = 0
    ret.shift = parameter.margin_left
    return ret
end

--- Create a colored area. width and height are in scaled points.
function box( width_sp,height_sp,colorname )
    local h,v
    if colorname ~= "-" then
        local _width   = sp_to_bp(width_sp)
        local _height  = sp_to_bp(height_sp)
        local paint = node.new("whatsit","pdf_literal")
        local colentry = colors[colorname]
        if not colentry then
            err("Color %q unknown, reverting to black",colorname or "(no color name given)")
            colentry = colors["black"]
        end
        paint.data = string.format("q %s 1 0 0 1 0 0 cm 0 0 %g -%g re f Q",colentry.pdfstring,_width,_height)
        paint.mode = 0
        if colentry.alpha then
            set_attribute(paint,"color",get_colorindex_from_name(colorname))
        end
        local hglue = set_glue(nil,{width = 0, stretch = 2^16, stretch_order = 3 })
        h = node.insert_after(paint,paint,hglue)

        h = node.hpack(h,width_sp,"exactly")
    else
        h = create_empty_hbox_with_width(width_sp)
    end

    local vglue = set_glue(nil,{width = 0, stretch = 2^16, stretch_order = 3 })
    v = node.insert_after(h,h,vglue)
    v = node.vpack(h,height_sp,"exactly")
    return v
end


-- Draw a box with HTML properties given at head
function htmlbox( head, width_sp, height_sp, depth_sp)
    local debug_htmlbox = 0
    local properties = node.getproperty(head)
    if not properties then
        err("Internal error: htmlbox() - no properties given")
        return
    end
    local dirmode = "horizontal"
    if head.id == vlist_node then
        dirmode = "vertical"
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

    local border_top_width = properties.border_top_width
    local border_right_width = properties.border_right_width
    local border_bottom_width = properties.border_bottom_width
    local border_left_width = properties.border_left_width

    -- ht == y3, wd == x3

    depth_sp = math.max(depth_sp,properties.depth)
    height_sp = properties.lineheight - depth_sp
    local sp_x0, sp_x1, sp_x2, wd
    local sp_y0, sp_y1, sp_y2, ht

    local padding_top = properties.padding_top
    if dirmode == "horizontal" then
        local shift_down = border_bottom_width + depth_sp + properties.padding_bottom
        sp_y1 = height_sp + properties.padding_bottom + padding_top + properties.margin_bottom
        sp_y0 = sp_y1 + border_top_width
        ht = properties.margin_bottom - shift_down
        sp_y2 = ht + border_bottom_width
        sp_x0 = properties.margin_left
        sp_x1 = sp_x0 + border_left_width
        sp_x2 = width_sp + properties.padding_left
        wd = sp_x2 + border_right_width
    else
        local shift_down = properties.lineheight
        sp_y1 = properties.padding_bottom + padding_top + properties.margin_bottom
        sp_y0 = sp_y1 + border_top_width
        ht = properties.margin_bottom - shift_down
        sp_y2 = ht + border_bottom_width
        sp_x0 = properties.margin_left
        sp_x1 = sp_x0 + border_left_width
        sp_x2 = width_sp + properties.padding_left
        wd = sp_x2 + border_right_width
    end
    --- The trapezoids must extend closer to the center of the border, because if the border
    --- radius is larger than the border width, the border goes "into" the surrounding object.
    -- 3 might not be correct. TODO: what is the correct factor? Should depend on the radius
    local extend_top = 0
    local extend_right = 0
    local extend_bottom = 0
    local extend_left = 0
    if b_t_l_radius > 0 or b_t_r_radius > 0 then
        local extend_top = 3
    end
    if b_t_r_radius > 0 or b_b_r_radius > 0 then
        local extend_right = 3
    end
    if b_b_l_radius > 0 or b_b_r_radius > 0 then
        local extend_bottom = 3
    end
    if b_t_l_radius > 0 or b_b_l_radius > 0 then
        local extend_left = 3
    end
    local inner_top = sp_y1 - extend_top *  border_top_width
    local inner_right = sp_x2  - extend_right * border_right_width
    local inner_bottom = sp_y2 + extend_bottom * border_bottom_width
    local inner_left = sp_x1 + extend_left * border_left_width

    if properties.border_top_style ~= "none" and border_top_width > 0 then
        colorstring = colors[properties.border_top_color].pdfstring
        rules[#rules + 1] = get_rule(inner_left,inner_top, inner_right, inner_top, wd, sp_y0, sp_x0, sp_y0)
    end
    if properties.border_right_style ~= "none" and border_right_width > 0 then
        colorstring = colors[properties.border_right_color].pdfstring
        rules[#rules + 1] = get_rule(inner_right,inner_bottom, wd, ht, wd, sp_y0, inner_right,inner_top)
    end
    if properties.border_bottom_style ~= "none" and border_bottom_width > 0 then
        colorstring = colors[properties.border_bottom_color].pdfstring
        rules[#rules + 1] = get_rule(sp_x0, ht, wd, ht,inner_right,inner_bottom , inner_left,inner_bottom)
    end
    if properties.border_left_style ~= "none" and border_left_width > 0 then
        colorstring = colors[properties.border_left_color].pdfstring
        rules[#rules + 1] = get_rule(sp_x0, ht, inner_left, inner_bottom, inner_left, inner_top, sp_x0, sp_y0)
    end
    rules[#rules + 1] = "Q"

    -- Let's calculate the outer boundary first.
    local circle_bezier = 0.551915024494

    -- xn, yn = outer path, xin, yin = inner path used for clipping
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
    local x13, y13 = 0                                 ,y9 - b_t_l_radius
    local x12, y12 = 0                                ,y13 + circle_bezier * b_t_l_radius
    local x14, y14 = 0                                , y1 + b_b_l_radius
    local x15, y15 = 0                                , y14 - b_b_l_radius * circle_bezier
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
    local xi14, yi14 = border_left_width                     ,math.max(ht + border_bottom_width, y14)
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

    if debug_htmlbox > 2 then
        rules[#rules + 1] = "q 0.3 w"
        rules[#rules + 1] = pdf_moveto(0,0)
        rules[#rules + 1] = pdf_lineto(wd,0)
        rules[#rules + 1] = "S"
        rules[#rules + 1] = pdf_moveto(0,-depth_sp)
        rules[#rules + 1] = pdf_lineto(wd,-depth_sp)
        rules[#rules + 1] = "S"
        rules[#rules + 1] = pdf_moveto(0,height_sp)
        rules[#rules + 1] = pdf_lineto(wd,height_sp)
        rules[#rules + 1] = "S"
        rules[#rules + 1] = "Q"
    end

    if debug_htmlbox > 2 then
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
    n_clip_data = n_clip_data .. " " .. table.concat(rules," ")
    n_clip.data = n_clip_data

    local pdf_save    = node.new("whatsit","pdf_save")
    local pdf_restore = node.new("whatsit","pdf_restore")

    node.insert_after(pdf_save,pdf_save,n_clip)

    local hvbox = node.hpack(pdf_save)
    hvbox.depth = 0
    node.insert_after(hvbox,node.tail(hvbox),pdf_restore)
    hvbox = node.vpack(hvbox)
    node.setproperty(hvbox,{origin="hvbox"})
    return hvbox
end

--- After everything is ready for page ship-out, we add debug output and crop marks if necessary
function dothingsbeforeoutput( thispage )
    local cg = thispage.grid

    if thispage and thispage.AtPageShipout then
        pagebreak_impossible = true
        dispatch(thispage.AtPageShipout)
        pagebreak_impossible = false
        local graphic = thispage.AtPageShipout.graphic
        if graphic then
            local _,whatsit = metapost.prepareboxgraphic(thispage.width,thispage.height,graphic,metapost.extra_page_parameter(thispage))
            place_at(thispage.pagebox,whatsit,thispage.grid.extra_margin,thispage.height+thispage.grid.extra_margin)
        end
    end

    local str
    local thispagebox = thispage.pagebox
    insert_nonmoving_whatsits(thispagebox)
    local firstbox

    -- for spot colors, if necessary
    setpageresources(thispage)

    -- White background on page. Todo: Make color customizable and background optional.
    local wd = sp_to_bp(current_page.width)
    local ht = sp_to_bp(current_page.height)

    local x = 0 + current_page.grid.extra_margin
    local y = 0 + current_page.grid.extra_margin

    if options.trim then
        local trim_bp = sp_to_bp(options.trim)
        wd = wd + trim_bp * 2
        ht = ht + trim_bp * 2
        x = x - options.trim
        y = y - options.trim
    end

    -- White background
    if options.format ~= "PDF/UA" then
        firstbox = node.new("whatsit","pdf_literal")
        firstbox.data = string.format("q 0 0 0 0 k  1 0 0 1 0 0 cm %g %g %g %g re f Q",sp_to_bp(x), sp_to_bp(y),wd ,ht)
        firstbox.mode = 1
    end

    if options.showgridallocation then
        local lit = node.new("whatsit","pdf_literal")
        lit.mode = 1
        lit.data = cg:draw_gridallocation()

        if firstbox then
            local tail = node.tail(firstbox)
            tail.next = lit
            lit.prev = tail
        else
            firstbox = lit
        end
    end

    for framename,v in pairs(cg.positioning_frames) do
        for _,frame in ipairs(v) do
            if frame.draw then
                local lit = node.new("whatsit","pdf_literal")
                lit.mode = 1
                lit.data = cg:draw_frame(frame,tex.sp(frame.draw.width))
                if firstbox then
                    local tail = node.tail(firstbox)
                    tail.next = lit
                    lit.prev = tail
                else
                    firstbox = lit
                end
            end
        end
    end

    if options.showgrid then
        local lit = node.new("whatsit","pdf_literal")
        lit.mode = 1
        lit.data = cg:draw_grid()
        if firstbox then
            local tail = node.tail(firstbox)
            tail.next = lit
            lit.prev = tail
        else
            firstbox = lit
        end
    end
    if options.format == "PDF/UA" then
        -- second argument is extra page attributes
        cg:trimbox(options.crop, string.format("/StructParents %d",#pdfuapages))
    else
        cg:trimbox(options.crop)
    end

    if options.cutmarks then
        local lit = node.new("whatsit","pdf_literal")
        lit.mode = 1
        lit.data = cg:cutmarks()
        if firstbox then
            local tail = node.tail(firstbox)
            tail.next = lit
            lit.prev = tail
        else
            firstbox = lit
        end
    end

    if options.trimmarks then
        local lit = node.new("whatsit","pdf_literal")
        lit.mode = 1
        lit.data = cg:trimmarks()
        if firstbox then
            local tail = node.tail(firstbox)
            tail.next = lit
            lit.prev = tail
        else
            firstbox = lit
        end
    end

    if firstbox then
        local list_start = thispagebox
        thispage.pagebox = firstbox
        node.tail(firstbox).next = list_start
        list_start.prev = node.tail(firstbox)
    end
end

--- Read the contents of the attribute `attname`. `typ` is one of
--- `string`, `number`, `length` and `boolean`.
--- `default` gives something that is to be returned if no attribute with this name is present.
function read_attribute( layoutxml,dataxml,attname,typ,default,context)
    local namespaces = layoutxml[".__ns"]
    if not layoutxml[attname] then
        return default -- can be nil
    end

    local val,num,ret
    if typ ~= "xpath" and typ ~= "xpathraw" then
        val = string.gsub(layoutxml[attname],"{(.-)}", function (x)
            local ok, xp = xpath.parse_raw(dataxml,x,namespaces)
            if not ok then
                err(xp)
                return nil
            end
            return xpath.textvalue(xp[1])
            end)
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
    elseif typ=="string" then
        return tostring(val or default)
    elseif typ=="number" then
        return tonumber(val)
        -- something like "3pt"
    elseif typ=="length" then
        return val
        -- same as before, just changed to scaled points
    elseif typ=="length_sp" then
        num = tonumber(val or default)
        if num then -- most likely really a number, we need to multiply with grid width
            ret = current_grid:width_sp(num)
        else
            ret = val
        end
        return tex.sp(ret)
    elseif typ=="height_sp" then
        num = tonumber(val or default)
        if num then -- most likely really a number, we need to multiply with grid height
            setup_page(nil,"read_attribute height_sp")
            ret = current_page.grid.gridheight * num
        else
            ret = val
        end
        return tex.sp(ret)
    elseif typ=="width_sp" then
        num = tonumber(val or default)
        if num then -- most likely really a number, we need to multiply with grid width
            setup_page(nil,"read_attribute width_sp")
            ret = current_page.grid:width_sp(num)
        else
            ret = val
        end
        return tex.sp(ret)
    elseif typ=="boolean" then
        val = val or default
        if val=="yes" then
            return true
        elseif val=="no" then
            return false
        end
        return nil
    elseif typ=="booleanornumber" then
        val = val or default
        if val=="yes" then
            return true
        elseif val=="no" then
            return false
        else
            return tonumber(val)
        end
    elseif typ=="booleanorlength" then
        val = val or default
        if val=="yes" then
            return true
        elseif val=="no" then
            return false
        else
            return tex.sp(val)
        end
    else
        warning("read_attribute (2): unknown type: %s",type(val))
    end
    return val
end

-- Return the element name of the given element (elt)
function elementname(elt)
    return elt.elementname
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
-- The 'new' HTML parse is in the file html.lua
function parse_html( elt, parameter )
    parameter = parameter or {}
    if elt.typ == "csshtmltree" then
        return html.parse_html_new(elt, parameter)
    else
        err("This should not happen (parse_html)")
    end
end

function get_attributes(nodelist)
    local attributes = {}
    local n = nodelist.attr
    while n do
        if n.number then
            attributes[n.number] = n.value
        end
        n = n.next
    end
    return attributes
end

-- Get an attribute value. If the attribute table entry has a table, return the
-- string value of the attribute
function get_attribute(nodelist,attribute_name)
    local a = get_attributes(nodelist) or {}
    local att_number = attribute_name_number[attribute_name]
    local entry = attributes[attribute_name]
    local val = a[att_number]
    if not val then return nil end
    if type(entry) == "table" then
        return entry[val]
    end
    return a[att_number]
end

-- set_attribute sets an attribute for this node. The attribute name must be
-- present in the global attribute list or a number from the list attribute_name_number.
-- The value must be a number or a string value
function set_attribute(nodelist,attribute_name,value)
    local att_number = attribute_name_number[attribute_name]
    if not att_number then err("Internal error: attribute %s unknown",attribute_name or "?") return end
    local entry = attributes[attribute_name]
    local att_value
    if type(entry) == "table" then
        for k,v in ipairs(entry) do
            if v == value then att_value = k break end
        end
    else
        att_value = value
    end
    node.set_attribute(nodelist,att_number,att_value)
end

function clear_attribute(nodelist,attribute_name)
    local att_number = attribute_name_number[attribute_name]
    if not att_number then err("Internal error: attribute %s unknown",attribute_name or "?") return end
    local entry = attribute_name_number[attribute_name]
    node.unset_attribute(nodelist,entry)
end


-- list of attributes { key = val, key = val }
function set_attributes(nodelist,att_tbl)
    for k, v in pairs(att_tbl) do
        if k and v then
            local num = k
            if type(k) == "number" then k = attribute_number_name[k] end
            if not k then w("attribute name %d not found",num) end
            set_attribute(nodelist,k,v)
        end
    end
end

--- Look for `user_defined` at end of page (ship-out) and runs actions encoded in them.
function insert_nonmoving_whatsits( head, parent, blockinline )
    if not head then return end
    blockinline = blockinline or "vertical"
    local fun
    local prev_hyperlink, prev_fgcolor,prev_role
    local linklevel = 0
    while head do
        if head.id==hlist_node and head.subtype == 1 then
            insert_nonmoving_whatsits(head.list,head,"horizontal")
            local bordernumber = get_attribute(head,"bordernumber")
            if bordernumber then
                local bordervbox = mpbox(borderattributes[bordernumber],head.width,head.height)
                parent.head = node.insert_before(parent.head,head,bordervbox)
            end
        elseif head.id==hlist_node or head.id == vlist_node then
            local bordernumber = get_attribute(head,"bordernumber")
            if bordernumber then
                local bordervbox = mpbox(borderattributes[bordernumber],head.width,head.height + head.depth)
                parent.head = node.insert_before(parent.head,head,bordervbox)
            end
            insert_nonmoving_whatsits(head.list,head,"vertical")
        else
            local props = node.getproperty(head)
            local attribs = get_attributes(head)
            local fgcolor = get_attribute(head,"color")
            local bordernumber = get_attribute(head,"bordernumber")
            if bordernumber then
                local wd,ht = get_attribute(head,"borderwd"),get_attribute(head,"borderht")
                local ba = borderattributes[bordernumber]
                wd = wd - ba.border_right_width - ba.margin_right + ba.padding_right
                local bordervbox = mpbox(ba,wd,ht)
                parent.head = node.insert_before(parent.head,head,bordervbox)
            end
            local transparency = getprop(head,"opacity")
            local role = getprop(head,"role")

            if head.id == glyph_node and role and head.next and head.next.id == disc_node then
                setprop(head.next,"role",role)
            end

            local insert_startcolor = false
            local insert_endcolor = false
            local insert_startrole = false
            local insert_endrole = false

            if fgcolor and head.next == nil then
                -- at end insert endcolor if in color mode
                if prev_fgcolor == nil  then
                    insert_startcolor = true
                end
                insert_endcolor = true
                prev_fgcolor = nil
            elseif fgcolor ~= prev_fgcolor then
                -- 1: fgcolor nil and prev_fgcolor != nil
                -- 2: fgcolor val and prev_fgcolor diff val
                -- 3: fgcolor val and prev_fgcolor nil
                if fgcolor == nil and prev_fgcolor then
                    -- 1
                    insert_endcolor = true
                elseif fgcolor and prev_fgcolor then
                    -- 2
                    insert_endcolor = true
                    insert_startcolor = true
                else
                    -- 3
                    insert_startcolor = true
                end
                prev_fgcolor = fgcolor
            end

            if role and head.next == nil then
                -- at end insert endrole if in role mode
                if prev_role == nil  then
                    insert_startrole = true
                end
                insert_endrole = true
                prev_role = nil
            elseif role ~= prev_role then
                -- 1: role nil and prev_role != nil
                -- 2: role val and prev_role diff val
                -- 3: role val and prev_role nil
                if role == nil and prev_role then
                    -- 1
                    insert_endrole = true
                elseif role and prev_role then
                    -- 2
                    insert_endrole = true
                    insert_startrole = true
                else
                    -- 3
                    insert_startrole = true
                end
                prev_role = role
            end
            if insert_endcolor then
                local colstop  = node.new("whatsit","pdf_colorstack")
                set_attributes(colstop,attribs)
                colstop.data  = ""
                colstop.command = 2
                colstop.stack = defaultcolorstack
                setprop(colstop,"origin","setcolor")
                if fgcolor and not prev_fgcolor then
                    parent.head = node.insert_after(parent.head,head,colstop)
                    head = head.next
                else
                    parent.head = node.insert_before(parent.head,head,colstop)
                end
            end
            if insert_startcolor then
                local colstart = node.new("whatsit","pdf_colorstack")
                set_attributes(colstart,attribs)
                local colorname = colortable[fgcolor]
                local colorentry = colors[colorname]
                local col = colorentry.pdfstring
                local alpha = colorentry.alpha
                if alpha then
                    local thispage = pages[current_pagenumber]
                    thispage.transparenttext = thispage.transparenttext or {}
                    thispage.transparenttext[alpha] = true
                    col = col .. string.format("/TRP%d gs",alpha )
                end
                colstart.data  = col
                colstart.command = 1
                colstart.stack = defaultcolorstack

                setprop(colstart,"origin","setcolor")
                parent.head = node.insert_before(parent.head,head,colstart)
            end
            if insert_endrole then

                local emc = node.new("whatsit","pdf_literal")
                emc.data = "EMC"
                emc.mode = 1

                if role then
                    parent.head = node.insert_after(parent.head,head,emc)
                    head = head.next
                else
                    parent.head = node.insert_before(parent.head,head,emc)
                end
            end
            if insert_startrole then
                local bdc = node.new("whatsit","pdf_literal")
                node.set_attribute(bdc,publisher.att_role, role)
                bdc.data = ""
                bdc.mode = 1
                parent.head = node.insert_before(parent.head,head,bdc)
            end

            if transparency then
                local colstart = node.new("whatsit","pdf_colorstack")
                colstart.data = string.format("/TRP%d gs",transparency )
                colstart.command = 1
                colstart.stack = defaultcolorstack
                current_page.transparenttext[transparency] = true

                local colend = node.new("whatsit","pdf_colorstack")
                colend.command = 2
                colend.stack = defaultcolorstack
                parent.head = node.insert_before(parent.head,head,colstart)
                node.insert_after(parent.head,head,colend)
                head = head.next
            end
            -- First, let's look at hyperlinks from HTML <a href="...">
            -- Hyperlinks are inserted as attributes
            local hl = get_attribute(head,"hyperlink") or getprop(head,"hyperlink")
            local insert_startlink = false
            local insert_endlink = false
            -- case 1: link ends at the end of the list
            --         this is due to a (line-) broken link
            --         => end link
            --  case 2: hyperlink value of the node changes
            --         either insert a start link or an end link marker
            if hl and head.next == nil and linklevel > 0 then
                insert_endlink = true
                prev_hyperlink = nil
            elseif hl ~= prev_hyperlink then
                if hl ~= nil then
                    insert_startlink = true
                    prev_hyperlink = hl
                else
                    insert_endlink = true
                    prev_hyperlink = nil
                end
            end
            if head.next == nil then
                insert_startlink = false
            end
            if insert_endlink then
                linklevel = linklevel - 1
                local enl = node.new("whatsit","pdf_end_link")
                parent.head = node.insert_before(parent.head,head,enl)
            end
            if insert_startlink then
                linklevel = linklevel + 1
                -- 3 = user
                local ai = get_action_node(3)
                ai.data = hyperlinks[hl]
                local stl = node.new("whatsit","pdf_start_link")
                stl.action = ai
                stl.width = -1073741824
                stl.height = -1073741824
                stl.depth = -1073741824
                parent.head = node.insert_before(parent.head,head,stl)
            end
            -- HTML inline border
            local properties = node.getproperty(head)
            if properties then
                if properties.borderstart then
                    local cur = head
                    while cur do
                        local cur_properties = node.getproperty(cur)
                        if cur_properties and cur_properties.borderend then
                            break
                        end
                        cur = cur.next
                    end
                    local wd,ht,dp = node.dimensions(head,cur)
                    local boxnode = htmlbox(head,wd,ht,dp)
                    parent.head = node.insert_before(parent.head,head,boxnode)
                end
            end
            -- Now let's look at user defined whatsits, that are ment
            -- for markers, bookmarks etc.
            if head.id==whatsit_node then
                if head.subtype == user_defined_whatsit then
                    -- action
                    if head.user_id == user_defined_addtolist then
                        -- this part is obsolete (2.9.3)
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
                        markercount = markercount + 1
                        markers[marker] = { page = current_pagenumber, count = markercount }
                    elseif head.user_id == user_defined_mark_append then
                        local marker = head.value
                        if markers[marker] == nil then
                            markers[marker] = { page = tostring(current_pagenumber) }
                        else
                            markers[marker]["page"] = tostring(markers[marker]["page"]) .. "," ..  tostring(current_pagenumber)
                        end
                    end
                end
            elseif head.id == glue_node and head.subtype == 0 and blockinline == "horizontal" and options.format == "PDF/UA" then
                local g = node.new("glyph")
                g.subtype = 1
                g.font = 1
                g.char = 32
                g.width = head.width
                parent.head = node.insert_before(parent.head,head,g)
                head.width = 0
            end
        end
        head = head.next
    end
    return
end

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

--- Return the larger glue(spec) values
function bigger_glue_spec( a,b )
    if a.stretch_order > b.stretch_order then return a end
    if b.stretch_order > a.stretch_order then return b end
    if a.stretch > b.stretch then return a end
    if b.stretch > a.stretch then return b end
    if a.width > b.width then return a else return b end
end


function short_newline(fam)
    local strutheight = fonts.lookup_fontfamily_number_instance[fam].baselineskip
    local dummypenalty
    dummypenalty = node.new("penalty")
    dummypenalty.penalty = 10000
    set_attribute(dummypenalty,"newline")

    local list, cur
    list, cur = dummypenalty,dummypenalty

    local strut = node.new("rule")
    -- set to 60000 for example for debugging
    strut.width=0
    strut.height = strutheight*0.75
    strut.depth = strutheight*0.25
    list,cur = node.insert_after(list,cur,strut)

    g = set_glue(nil,{})
    list,cur = node.insert_after(list,cur,g)
    return list, cur

end

-- newline returns a nodelist that behaves as a new line in TeX
function newline(fam)
    local strutheight = fonts.lookup_fontfamily_number_instance[fam].baselineskip
    local dummypenalty
    dummypenalty = node.new("penalty")
    dummypenalty.penalty = 10000
    set_attribute(dummypenalty,"newline")

    local list, cur
    list, cur = dummypenalty,dummypenalty

    local strut = node.new("rule")
    -- set to 60000 for example for debugging
    strut.width=0
    strut.height = strutheight*0.75
    strut.depth = strutheight*0.25
    list,cur = node.insert_after(list,cur,strut)

    local p1,g,p2
    p1 = node.new("penalty")
    p1.penalty = 10000
    g = set_glue(nil,{stretch = 2^16, stretch_order = 2})
    p2 = node.new("penalty")
    p2.penalty = -10000
    set_attribute(p1,"newline")
    set_attribute(p2,"newline")
    set_attribute(g,"newline")
    -- important for empty lines (adjustlineheight)
    set_attribute(p1,"fontfamily",fam)
    list,cur = node.insert_after(list,cur,p1)
    list,cur = node.insert_after(list,cur,g)
    list,cur = node.insert_after(list,cur,p2)
    -- add glue so next word can hyphenate (#274)
    g = set_glue(nil,{})
    list,cur = node.insert_after(list,cur,g)
    return list, cur
end

-- Used to set the line height within nobreak.
function addstrut(nodelist,where,origin)
    local strutheight = 0
    local head = nodelist
    while head do
        if head.id == hlist_node then
            strutheight = head.height
            if node.has_attribute(head,att_dont_format) then
                -- 0.25 is the depth of the line, and hopefully
                -- this is the highest thing in the line
                head.shift = 0.25 * head.height
            end
        end
        head = head.next

    end
    head = nodelist
    while head do
        if get_attribute(head,"fontfamily") then
            break
        end
        head = head.next
    end
    local fontfamily

    if head == nil then
        fontfamily = nil
    else
        fontfamily = get_attribute(head,"fontfamily")
    end
    if fontfamily == nil or fontfamily == 0 then
        fontfamily = fonts.lookup_fontfamily_name_number["text"]
    end

    local fi = fonts.lookup_fontfamily_number_instance[fontfamily]
    strutheight = math.max(fi.baselineskip, strutheight)
    -- for debugging purposes set width to 20000:
    local strut = add_rule(nodelist,"head",{height = 0.75 * strutheight, depth = 0.25 * strutheight, width = 0 })
    if origin then
        setprop(strut,"origin",origin)
    end
    return strut
end


-- Remove the first \n in a paragraph value table. See #132
function remove_first_whitespace ( tbl )
    for i=1,#tbl do
        if type(tbl[i]) == "string" then
            tbl[i] = string.gsub(tbl[i],"^[\n\t]*(.-)$","%1")
            return true
        end
        if type(tbl[i]) == "table" then
            local ret
            if tbl[i].contents and type(tbl[i].contents) == "table" then
                ret = remove_first_whitespace(tbl[i].contents)
            else
                ret = remove_first_whitespace(tbl[i])
            end
            if ret then return true end
        end
    end
end

-- Remove the final \n in a paragraph value table. See #132
function remove_last_whitespace ( tbl )
    for i=#tbl,1,-1 do
        if type(tbl[i]) == "string" then
            if string.match(tbl[i],"^%s*$") then
                table.remove( tbl,i )
            else
                tbl[i] = string.gsub(tbl[i],"^(.-)[\n\t]*$","%1")
            end
            return true
        end
        if type(tbl[i]) == "table" then
            local ret
            if tbl[i].contents and type(tbl[i].contents) == "table" then
                ret = remove_last_whitespace(tbl[i].contents)
            else
                local tic = tbl[i].contents
                -- the last contents could be an image for example. See #342
                if type(tic) == "userdata" then ret = true else
                    ret = remove_last_whitespace(tbl[i])
                end
            end
            return ret
        end
    end
end

function setprop(n, prop, value)
    local props = node.getproperty(n)
    if not props then
      props = {}
      node.setproperty(n, props)
    end
    props[prop] = value
end

function getprop( n, prop )
    local props = node.getproperty(n)
    if not props then return nil end
    if type(props) == "table" then return props[prop] end
    return nil
end

local function setstyles(n,parameter)
    if parameter.bold == 1 then
        set_attribute(n,"font-weight","bold")
        setprop(n,"font-weight","bold")
    end
    if parameter.italic == 1 then
        publisher.set_attribute(n,"font-style","italic")
    end
    if parameter.textdecorationline then
        set_attribute(n,"text-decoration-line",parameter.textdecorationline)
        set_attribute(n,"text-decoration-style",parameter.textdecorationstyle)
        set_attribute(n,"text-decoration-color",current_fgcolor)
    end
    if parameter.color and parameter.color ~= 1 then
        set_attribute(n,"text-decoration-color",parameter.color)
        set_attribute(n,"color",parameter.color)
    end
    if parameter.hyperlink then
        local hl = parameter.hyperlink
        set_attribute(n,"hyperlink",hl)
    end
    if parameter.languagecode and node.has_field(n,"lang") then
        local lc = parameter.languagecode
        n.lang = lc
    end
    if parameter.backgroundcolor then
        set_attribute(n,"background-color",parameter.backgroundcolor)
        local bg_padding_top = tex.sp(parameter.bg_padding_top or 0)
        local bg_padding_bottom = tex.sp(parameter.bg_padding_bottom or 0)
        set_attribute(n,"bgpaddingtop",bg_padding_top)
        set_attribute(n,"bgpaddingbottom",bg_padding_bottom)
    end
    if parameter.verticalalign then
        set_attribute(n,"vertical-align",parameter.verticalalign)
    end
    if parameter.indent then
        setprop(n,"indent",parameter.indent)
    end
    if parameter.role then
        setprop(n,"role",parameter.role)
    end
end

function hbglyphlist(arguments)
    local tbl = arguments.tbl
    local glyphs = arguments.glyphs
    local cluster = arguments.cluster
    local parameter = arguments.parameter
    local allowbreak = arguments.allowbreak
    local newlines_at = arguments.newlines_at
    local fontfamily = parameter.fontfamily
    local direction = arguments.direction
    local script = arguments.script
    local thislang = arguments.thislang
    local fontnumber = arguments.fontnumber
    local is_chinese = arguments.is_chinese

    local thisfont = fonts.used_fonts[fontnumber]
    local reportmissingglyphs = options.reportmissingglyphs
    local lastitemwasglyph
    local space   = tbl.parameters.space
    local shrink  = tbl.parameters.space_shrink
    local stretch = tbl.parameters.space_stretch
    local list, cur
    local n,k
    for i=1,#glyphs do
        local thisglyph = glyphs[i]
        local cp = thisglyph.codepoint
        local uc = tbl.backmap[cp] or cp
        if false then
            -- just for simple adding at the beginning
        elseif uc == 160 and #glyphs == 1 then
            -- ignore
        elseif uc == 32 then
            local thiscluster = thisglyph.cluster
            if cluster[thiscluster] == 160 then
                n = node.new("penalty")
                n.penalty = 10000
                list,cur = node.insert_after(list,cur,n)
                n = set_glue(nil,{width = space, shrink = shrink, stretch = stretch},"uc=32,160")
                node.set_attribute(n,att_tie_glue,1)
                list,cur = node.insert_after(list,cur,n)
            elseif cluster[thiscluster] == 8203 then
                -- U+200B ZERO WIDTH SPACE
                p = node.new("penalty")
                p.penalty = -10
                list,cur = node.insert_after(list,cur,p)
            elseif cluster[thiscluster] == 8205 then
                -- U+200D ZERO WIDTH JOINER
                -- ignore
            else
                n = set_glue(nil,{width = space,shrink = shrink, stretch = stretch},"uc=32")
                setstyles(n,parameter)
                list,cur = node.insert_after(list,cur,n)
            end
            if parameter.textdecorationline then
                set_attribute(n,"text-decoration-line",parameter.textdecorationline)
                set_attribute(n,"text-decoration-style",parameter.textdecorationstyle)
                set_attribute(n,"text-decoration-color",current_fgcolor)
            end

            if parameter.backgroundcolor then
                set_attribute(n,"background-color",parameter.backgroundcolor)
                set_attribute(n,"bgpaddingtop",parameter.bg_padding_top)
                set_attribute(n,"bgpaddingbottom",parameter.bg_padding_bottom)
            end
            set_attribute(n,"fontfamily",fontfamily)
        elseif cp == 0 and newlines_at[thisglyph.cluster] then
            local dummypenalty
            dummypenalty = node.new("penalty")
            dummypenalty.penalty = 10000
            set_attribute(dummypenalty,"newline")
            list,cur = node.insert_after(list,cur,dummypenalty)

            local ht = fonts.lookup_fontfamily_number_instance[fontfamily].size
            local strut = add_rule(nil,"head",{height = ht * 0.75, depth = 0.25 * ht, width = 0 })
            set_attribute(strut,"newline")
            setprop(strut,"origin","strut newline hb")
            list,cur = node.insert_after(list,cur,strut)

            local p1,g,p2
            p1 = node.new("penalty")
            p1.penalty = 10000

            g = set_glue(nil,{stretch = 2^16, stretch_order = 2})

            p2 = node.new("penalty")
            p2.penalty = -10000
            set_attribute(p1,"newline")
            set_attribute(p2,"newline")
            set_attribute(g,"newline")


            -- important for empty lines (adjustlineheight)
            set_attribute(p1,"fontfamily",fontfamily)

            list,cur = node.insert_after(list,cur,p1)
            list,cur = node.insert_after(list,cur,g)
            list,cur = node.insert_after(list,cur,p2)

            -- add glue so next word can hyphenate (#274)
            g = set_glue(nil,{})
            list,cur = node.insert_after(list,cur,g)
        elseif cp == 0 then
            if reportmissingglyphs then
                local missgingglyph = cluster[thisglyph.cluster]
                if reportmissingglyphs == "warning" then
                    warning("Glyph %04x (hex) is missing from the font %q",missgingglyph,thisfont.name)
                else
                    err("Glyph %04x (hex) is missing from the font %q",missgingglyph,thisfont.name)
                end
            end
        else
            n = node.new("glyph")
            n.font = fontnumber
            n.subtype = 1
            n.char = uc
            n.uchyph = 1
            n.left = parameter.left or tex.lefthyphenmin
            n.right = parameter.right or tex.righthyphenmin
            local famtab = fonts.lookup_fontfamily_number_instance[fontfamily]
            if parameter.verticalalign == "sub" then
                n.yoffset = -famtab.scriptshift
            elseif parameter.verticalalign == "super" then
                n.yoffset = famtab.scriptshift
            end

            if thisglyph.x_offset ~= 0 then
                local dir = 1
                if direction == "rtl" then dir = -1 end
                n.xoffset = dir * thisglyph.x_offset * tbl.mag
            end
            if thisglyph.y_offset ~= 0 then
                n.yoffset = thisglyph.y_offset * tbl.mag
            end
            set_attribute(n,"fontfamily",fontfamily)
            setstyles(n,parameter)
            list,cur = node.insert_after(list,cur,n)

            if parameter.letterspacing then
                local k = node.new("kern")
                setstyles(k,parameter)
                k.kern = parameter.letterspacing
                list,cur = node.insert_after(list,cur,k)
                lastitemwasglyph = true
            end
            if cur and cur.prev and cur.prev.id == glyph_node then
                lastitemwasglyph = true
            end

            -- CJK
            if is_chinese and i < #glyphs and uc > 12032 then
                -- don't break within non-cjk words
                if prohibited_at_end[thislang][unicode.utf8.char(uc)] then
                    -- ignore
                else
                    -- add breaking point between this glyph and next glyph unless prohibited
                    if i < #glyphs then
                        local nextchar = glyphs[i+1].codepoint
                        local nextuc = tbl.backmap[nextchar] or nextchar
                        if not prohibited_at_beginning[thislang][unicode.utf8.char(nextuc)] then
                            local pen = node.new("penalty")
                            pen.penalty = 0
                            if parameter.textformat.alignment == "justified" then
                                local g = set_glue(nil,{stretch = 2^16, stretch_order = 0})
                                list,cur = node.insert_after(list,cur,g)
                            end
                            list,cur = node.insert_after(list,cur,pen)
                        end
                    end
                end
            end
            -- simplified chinese
            -- characters that must not appear at the beginning of a line
            -- !%),.:;?]}¢°·'""†‡›℃∶、。〃〆〕〗〞﹚﹜！＂％＇），．：；？！］｝～
            -- characters that must not appear at the end of a line
            -- $(£¥·'"〈《「『【〔〖〝﹙﹛＄（．［｛￡￥

            local diff = thisglyph.x_advance - tbl.characters[uc].hadvance
            if diff ~= 0 then
                publisher.setprop(cur,"kern", diff * tbl.mag)
            end
            if uc == -1 then
            elseif uc > 0x110000 then
                -- ignore
            elseif ( uc == 45 or uc == 8211) and lastitemwasglyph and string.find(allowbreak, "-",1,true) then
                -- only break if allowbreak contains the hyphen char
                local pen = node.new("penalty")
                pen.penalty = 10000
                list = node.insert_before(list,cur,pen)
                local disc = node.new("disc")
                list,cur = node.insert_after(list,cur,disc)
                local g = set_glue(nil)
                setstyles(disc,parameter)
                setstyles(g,parameter)
                list,cur = node.insert_after(list,cur,g)
            elseif string.find(allowbreak,unicode.utf8.char(uc),1,true) then
                -- allowbreak lists characters where the publisher may break lines
                local pen = node.new("penalty")
                pen.penalty = 0
                list,cur = node.insert_after(list,cur,pen)
            end
        end
    end

    if not list then
        -- This should never happen.
        warning("No head found")
        return node.new("hlist")
    end
    local aa = parameter.add_attributes or {}
    for i=1,#aa do
        set_attribute_recurse(list,aa[i][1],aa[i][2])
    end
    list = hbkern(list)
    return list
end


local function ffglyphlist(arguments)
    local tbl = arguments.tbl
    local str = arguments.str

    local parameter = arguments.parameter
    local allowbreak = arguments.allowbreak
    local fontfamily = parameter.fontfamily
    local script = arguments.script
    local thislang = arguments.thislang
    local fontnumber = arguments.fontnumber
    local languagecode = arguments.languagecode

    local space   = tbl.parameters.space
    local shrink  = tbl.parameters.space_shrink
    local stretch = tbl.parameters.space_stretch

    local match = unicode.utf8.match
    local allow_newline = true
    if options.htmlignoreeol then
        allow_newline = false
    end

    local head, last, n
    local char

    local lastitemwasglyph
    local newline = 10
    local breakatspace = true
    if not string.find(allowbreak, " ") then
        breakatspace = false
    end
    local preserve_whitespace = parameter.whitespace == "pre"
    -- There is a string with UTF-8 chars
    for s in string.utfvalues(str) do
        local char = unicode.utf8.char(s)
        -- If the next char is a newline (&#x0A;) a \\ is inserted
        if s == newline and allow_newline then
            -- This is to enable hyphenation again. When we add a rule right after a word
            -- hyphenation is disabled. So we insert a penalty of 10k which should not do
            -- harm. Perhaps there is a better solution, but this seems to work OK.
            local dummypenalty
            dummypenalty = node.new("penalty")
            dummypenalty.penalty = 10000
            set_attribute(dummypenalty,"newline")
            head,last = node.insert_after(head,last,dummypenalty)

            local ht = fonts.lookup_fontfamily_number_instance[fontfamily].size
            local strut = add_rule(nil,"head",{height = ht * 0.75, depth = ht * 0.25, width = 0 })
            setprop(strut,"origin","strut newline ff")
            set_attribute(strut,"newline")
            head,last = node.insert_after(head,last,strut)

            local p1,g,p2
            p1 = node.new("penalty")
            p1.penalty = 10000

            g = set_glue(nil,{stretch = 2^16, stretch_order = 2})

            p2 = node.new("penalty")
            p2.penalty = -10000

            set_attribute(p1,"newline")
            set_attribute(p2,"newline")
            set_attribute(g,"newline")
            local attr = { fontfamily = fontfamily}
            set_attributes(p1,attr)
            set_attributes(p2,attr)
            set_attributes(g,attr)

            head,last = node.insert_after(head,last,p1)
            head,last = node.insert_after(head,last,g)
            head,last = node.insert_after(head,last,p2)

            -- add glue so next word can hyphenate (#274)
            g = set_glue(nil,{})
            head,last = node.insert_after(head,last,g)
        elseif preserve_whitespace and match(char,"^%s$") then
            local strut = add_rule(nil,"head",{height = 0 * factor, depth = 0, width = space })
            head,last = node.insert_after(head,last,strut)
        elseif match(char,"^%s$") and last and last.id == glue_node and not node.has_attribute(last,att_tie_glue,1) then
            -- double space, use the bigger glue
            local tmp = set_glue(nil, {width = space, shrink = shrink, stretch = stretch})
            local tmp2 = bigger_glue_spec(last,tmp)
            last.width = tmp2.width
            last.stretch = tmp2.stretch
            last.shrink = tmp2.shrink
            last.stretch_order = tmp2.stretch_order
            last.shrink_order = tmp2.shrink_order
        elseif s == 160 then -- non breaking space U+00A0
            n = node.new("penalty")
            n.penalty = 10000

            head,last = node.insert_after(head,last,n)
            n = set_glue(nil,{width = space, shrink = shrink, stretch = stretch})
            node.set_attribute(n,att_tie_glue,1)

            head,last = node.insert_after(head,last,n)

            if parameter.textdecorationline then
                set_attribute(n,"text-decoration-line",parameter.textdecorationline)
                set_attribute(n,"text-decoration-style",parameter.textdecorationstyle)
                set_attribute(n,"text-decoration-color",current_fgcolor)
            end

            if parameter.backgroundcolor then
                set_attribute(n,"background-color",parameter.backgroundcolor)
                set_attribute(n,"bgpaddingtop",parameter.bg_padding_top)
                set_attribute(n,"bgpaddingbottom",parameter.bg_padding_bottom)
            end
            set_attribute(n,"fontfamily",fontfamily)
        elseif s == 173 then -- soft hyphen
            -- The soft hyphen is used in server-mode /v0/format
            n = node.new(penalty_node)
            n.penalty = 10000
            head, last = node.insert_after(head,last,n)

            n = node.new(disc_node)
            node.set_attribute(n,att_keep,1)
            head, last = node.insert_after(head,last,n)

            n = node.new(penalty_node)
            n.penalty = 10000
            head, last = node.insert_after(head,last,n)

            n = set_glue(nil)
            head, last = node.insert_after(head,last,n)
        elseif s == 9 and parameter.tab == 'hspace' then
            local n = set_glue(nil,{width = 0, stretch = 2^16, stretch_order = 3})
            head, last = node.insert_after(head,last,n)
        elseif s == 8203 then
            -- U+200B ZERO WIDTH SPACE
            p = node.new("penalty")
            p.penalty = -10
            head = p
            last = node.tail(head)
        -- anchor is necessary. Otherwise à (C3A0) would match A0 - %s
        elseif match(char,"^%s$") then -- Space
            if breakatspace == false then
                n = node.new("penalty")
                n.penalty = 10000

                head,last = node.insert_after(head,last,n)

            end
            -- ; and : should have the possibility to break easily if a space follows
            if last and last.id == glyph_node and ( last.char == 58 or last.char == 59) then
                n = node.new("penalty")
                n.penalty = 0
                head,last = node.insert_after(head,last,n)
            end

            n = set_glue(nil,{width = space,shrink = shrink, stretch = stretch})
            setstyles(n,parameter)
            if breakatspace == false then
                node.set_attribute(n,att_tie_glue,1)
            end

            if parameter.textdecorationline then
                set_attribute(n,"text-decoration-line",parameter.textdecorationline)
                set_attribute(n,"text-decoration-color",current_fgcolor)
            end
            if parameter.backgroundcolor then
                set_attribute(n,"background-color",parameter.backgroundcolor)
                set_attribute(n,"bgpaddingtop",parameter.bg_padding_top)
                set_attribute(n,"bgpaddingbottom",parameter.bg_padding_bottom)

            end
            set_attribute(n,"fontfamily",fontfamily)
            head,last = node.insert_after(head,last,n)
        else
            -- A regular character?!?
            n = node.new("glyph")
            n.font = fontnumber
            n.subtype = 1
            n.char = s
            n.lang = languagecode
            n.uchyph = 1
            n.left = parameter.left or tex.lefthyphenmin
            n.right = parameter.right or tex.righthyphenmin
            setstyles(n,parameter)
            set_attribute(n,"fontfamily",fontfamily)

            local famtab = fonts.lookup_fontfamily_number_instance[fontfamily]
            if parameter.verticalalign == "sub" then
                n.yoffset = -famtab.scriptshift
            elseif parameter.verticalalign == "super" then
                n.yoffset = famtab.scriptshift
            end

            if parameter.letterspacing then
                local k = node.new("kern")
                k.kern = parameter.letterspacing
                setstyles(k,parameter)
                head,last = node.insert_after(head,last,k)
                lastitemwasglyph = true
            end
            if last and last.id == glyph_node then
                lastitemwasglyph = true
            end

            head,last = node.insert_after(head,last,n)
            -- CJK
            if s >= 12032 then
                local pen = node.new("penalty")
                pen.penalty = 0
                head,last = node.insert_after(head,last,pen)
            end

            -- Some characters must be treated in a special way.
            -- Hyphens must be separated from words:
            if n.char == 8209 then -- non breaking hyphen U+2011
                n.char = 45
                local pen = node.new("penalty")
                pen.penalty = 10000
                head,last = node.insert_after(head,last,pen)
            elseif ( n.char == 45 or n.char == 8211) and lastitemwasglyph and string.find(allowbreak, "-",1,true) then
                -- only break if allowbreak contains the hyphen char
                local pen = node.new("penalty")
                pen.penalty = 10000
                head = node.insert_before(head,last,pen)
                local disc = node.new("disc")
                head,last = node.insert_after(head,last,disc)
                local g = set_glue(nil)
                setstyles(disc,parameter)
                setstyles(g,parameter)
                head,last = node.insert_after(head,last,g)
            elseif string.find(allowbreak,char,1,true) then
                -- allowbreak lists characters where the publisher may break lines
                local pen = node.new("penalty")
                pen.penalty = 0
                head,last = node.insert_after(head,last,pen)
            end
        end
    end

    if not head then
        -- This should never happen.
        warning("No head found")
        return node.new("hlist")
    end
    local aa = parameter.add_attributes or {}
    for i=1,#aa do
        set_attribute_recurse(head,aa[i][1],aa[i][2])
    end
    return head
end

function getinstancename(parameter)
    local instancename
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
    if parameter.fontsize == "small" then
        instancename = instancename .. "script"
    end
    return instancename
end

-- Return a list of nodes
function mknodes(str,parameter,origin)
    -- if it's an empty string, we make a zero-width rule
    if not str or string.len(str) == 0 then
        -- a space char can have a width, so we return a zero width something
        local strut = add_rule(nil,"head",{height = 1 * factor, depth = 0, width = 0 })
        setprop(strut,"pardir",parameter.direction)
        return strut, parameter.direction
    end
    parameter = parameter or {}
    local languagecode = parameter.languagecode or defaultlanguage

    local fontfamily = parameter.fontfamily
    if parameter.monospace then
        fontfamily = fonts.lookup_fontfamily_name_number.monospace
    end
    local fontnumber = fonts.get_fontinstance(fontfamily,getinstancename(parameter))
    local tbl = fonts.used_fonts[fontnumber]

    local maindirection
    local segments
    if parameter.bidi and not ( str == "\n" ) then
        segments = splib.segmentize(str)
        if segments[1][1] == 0 then
            segments.maindirection = "ltr"
        else
            segments.maindirection = "rtl"
        end
    else
        local dir = 0
        segments = {}
        if parameter.direction == "rtl" then
            dir = 1
            segments.maindirection = "rtl"
        elseif parameter.direction == "ltr" then
            segments.maindirection = "ltr"
        end
        segments[1] = {dir,str}
    end
    maindirection = parameter.direction or segments.maindirection
    local nodelistsegments

    for i=1,#segments do
        str = segments[i][2]
        local direction = segments[i][1]
        local thislang = "en"
        if languagecode and languages_id_lang[languagecode].locale then
            thislang = languages_id_lang[languagecode].locale
        end
        local thissegment
        if tbl.face then
            -- w("hb mode")
            local script = nil
            if thislang == "--" then
                thislang = nil
                script = nil
            elseif thislang == "zh" then
                script = "Hans"
            end

            local newlines_at = {}

            local cluster = {}
            local pos = 0
            for c in unicode.utf8.gmatch(str,".") do
                cluster[pos] = unicode.utf8.byte(c)
                if c == "\n" then
                    newlines_at[pos] = true
                end
                pos = pos + #c
            end
            local buf = harfbuzz.Buffer.new()
            buf:add_utf8(str)
            -- shape returns the guessed script and direction from the buffer
            script, direction = shape(tbl,buf, { language = thislang, script = script, direction = direction } )

            local is_chinese = false
            if script == "Hans" or script == "Hant" or script == "Hani" then
                is_chinese = true
                -- script can be guessed from buffer and thislang could be empty, so
                -- lang must be set again.
                thislang = "zh"
            end

            local glyphs = buf:get_glyphs()

            thissegment = hbglyphlist({
                glyphs = glyphs,
                tbl = tbl,
                cluster = cluster,
                parameter = parameter,
                allowbreak = parameter.allowbreak or " -",
                newlines_at = newlines_at,
                script = script,
                direction = maindirection or direction,
                thislang = thislang,
                fontnumber = fontnumber,
                is_chinese = is_chinese,
            })


        else
            -- old fontforge code
            thissegment = ffglyphlist({
                str = str,
                tbl = tbl,
                parameter = parameter,
                allowbreak = parameter.allowbreak or " -",
                fontfamily = fontfamily,
                direction = maindirection,
                thislang = thislang,
                fontnumber = fontnumber,
                languagecode = languagecode,
            })
        end
        thissegment = setsegmentdir(thissegment,direction,maindirection)

        if nodelistsegments then
            local tail = node.tail(nodelistsegments)
            tail.next = thissegment
            thissegment.prev = tail
        else
            nodelistsegments = thissegment
        end
    end
    if maindirection then
        setprop(nodelistsegments,"pardir",maindirection)
    end
    return nodelistsegments, maindirection
end

-- direction is ltr or rtl or 0 or 1
function setsegmentdir(nodelist,direction, maindirection)
    local dirstring
    if direction == 0 or direction == "ltr" then
        dirstring = "TLT"
    elseif direction == 1 or direction == "rtl" then
        dirstring = "TRT"
    end

    -- don't do anything if this segment goes in the paragraph direction
    if ( maindirection == nil or maindirection == "ltr" ) and dirstring == "TLT" then
        return nodelist
    elseif maindirection == "rtl" and dirstring == "TRT" then
        return nodelist
    end

    local dirstart = node.new(dir_node)
    local dirend = node.new(dir_node)
    dirstart.dir = "+" .. dirstring
    dirend.dir = "-" .. dirstring
    node.setproperty(dirstart,node.getproperty(nodelist))
    local ff = get_attribute(nodelist,"fontfamily")
    set_attribute(dirstart,"fontfamily",ff)
    nodelist = node.insert_before(nodelist,nodelist,dirstart)

    local tail = node.tail(nodelist)
    local ff = get_attribute(tail,"fontfamily")
    set_attribute(dirend,"fontfamily",ff)
    node.setproperty(dirend,node.getproperty(tail))
    node.insert_after(nodelist,tail,dirend)
    return nodelist
end

-- head_or_tail = "head" oder "tail" (default: tail). Return new head (perhaps same as nodelist)
function add_rule( nodelist,head_or_tail,parameters)
    parameters = parameters or {}

    local n=node.new("rule")
    n.width  = parameters.width
    n.height = parameters.height
    n.depth  = parameters.depth
    if not nodelist then return n end

    if head_or_tail=="head" then
        nodelist = node.insert_before(nodelist,nodelist,n)
        return nodelist
    else
        local last=node.slide(nodelist)
        last.next = n
        n.prev = last
        return nodelist,n
    end
    assert(false,"never reached")
end

--- Return a hbox with width `labelwidth`
function bullet_hbox( labelwidth,parameter )
    local bullet, pre_glue, post_glue
    bullet = mknodes("•",parameter)
    pre_glue = set_glue(nil,{stretch = 2^16, stretch_order = 3})
    pre_glue.next = bullet

    post_glue = set_glue(nil,{width = 4 * 2^16})
    post_glue.prev = bullet
    bullet.next = post_glue
    local bullet_hbox = node.hpack(pre_glue,labelwidth,"exactly")

    if options.showobjects then
        boxit(bullet_hbox)
    end
    set_attribute(bullet_hbox,"indent",labelwidth)
    node.set_attribute(bullet_hbox,att_rows,-1)
    return bullet_hbox
end

--- Return a hbox with width `labelwidth`
function number_hbox( num, labelwidth,parameter )
    local pre_glue, post_glue
    local digits = mknodes( tostring(num) .. ".",parameter)
    pre_glue = set_glue(nil,{stretch = 2^16, stretch_order = 3})
    pre_glue.next = digits

    post_glue = set_glue(nil,{width = 4 * 2^16})
    post_glue.prev = node.tail(digits)
    node.tail(digits).next = post_glue
    local digit_hbox = node.hpack(pre_glue,labelwidth,"exactly")

    if options.showobjects then
        boxit(digit_hbox)
    end
    set_attribute(digit_hbox,"indent",labelwidth)
    node.set_attribute(digit_hbox,att_rows,-1)
    return digit_hbox
end

-- Create a hbox for a label
function whatever_hbox( label,labelwidth,options,labelsep_wd,labelalign )
    local fam = options.fontfamily
    labelsep_wd = labelsep_wd or fonts.lookup_fontfamily_number_instance[fam].size / 2
    labelalign = labelalign or "right"
    local shrink_glue = set_glue(nil,{shrink = 2^16, shrink_order = 3,width =  labelwidth})
    local label_sep = set_glue(nil,{width = labelsep_wd})

    local label_hbox
    if labelalign == "right" then
        shrink_glue.next = label
        local t = node.slide(label)
        t.next = label_sep
        label_hbox = node.hpack(shrink_glue,labelwidth,"exactly")
    else
        local t = node.slide(label)
        t.next = label_sep
        label_sep.next = shrink_glue
        label_hbox = node.hpack(label,labelwidth,"exactly")
    end
    set_attribute(label_hbox.head,"fontfamily",fam)
    label_hbox.head = addstrut(label_hbox.head,"head","whatever_hbox/strut")

    return label_hbox
end


-- just the plain size, not included the stretch or shrink
function get_glue_size( n )
    local spec

    if node.has_field(n,"spec") then
        spec = n.spec
    else
        spec = n
    end
    return spec.width
end


-- Add a glue to the front or tail of the given nodelist. `head_or_tail` is
-- either the string `head` or `tail`. `parameter` is a table with the keys
-- `width`, `stretch` and `stretch_order`. If the nodelist is nil, a simple
-- node list consisting of a glue will be created.
function add_glue( nodelist,head_or_tail,parameter,origin)
    parameter = parameter or {}

    local n = set_glue(nil, parameter)
    n.subtype = parameter.subtype or 0
    if origin then setprop(n,"origin",origin) end
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

-- 0pt plus 1fil minus 1fil
function hss_glue()
    return make_glue({stretch = 2^16, stretch_order = 2, shrink=2^16, shrink_order = 2})
end

function make_glue( parameter )
    return set_glue(nil, parameter)
end

function finish_par( nodelist,hsize,parameters )
    assert(nodelist)
    node.slide(nodelist)

    if not parameters.disable_hyphenation then
        lang.hyphenate(nodelist)
    end
    local n = node.new("penalty")
    setprop(n,"origin","finishpar")
    n.penalty = 10000
    local last = node.slide(nodelist)

    last.next = n
    n.prev = last
    last = n

    -- mode harfbuzz sets haskerns, different kind of kerning
    n = node.kerning(nodelist)

    -- 15 is a parfillskip
    n,last = add_glue(n,"tail",{ subtype = 15, width = 0, stretch = 2^16, stretch_order = 2})
end

function hbkern(nodelist)
    local head = nodelist
    local curkern = 0
    while head do
        if head.id == glyph_node then
            if curkern and curkern ~= 0 then
                local kern = node.new(kern_node)
                kern.kern = curkern
                nodelist = node.insert_before(nodelist,head,kern)
                local ul = get_attribute(head,"text-decoration-line")
                set_attribute(kern,"text-decoration-line",ul)
                local uccolor = get_attribute(head,"text-decoration-color")
                set_attribute(kern,"text-decoration-color",uccolor)
                local bgcolor = get_attribute(head,"background-color")
                set_attribute(kern,"background-color",bgcolor)
                node.setproperty(kern,node.getproperty(head))
                set_attribute(kern,"hyperlink",get_attribute(head,"hyperlink"))
                curkern = 0
            end
            local k = getprop(head,"kern")
            if k and k ~= 0 then
                curkern = k
            end
        elseif head.id == disc_node then
            if curkern and curkern ~= 0 then
                local kern = node.new(kern_node)
                kern.kern = curkern
                head.replace = kern
                local ul = get_attribute(head,"text-decoration-line")
                local uccolor = get_attribute(head,"text-decoration-color")
                local bgcolor = get_attribute(head,"background-color")
                local hyperlink = get_attribute(head,"hyperlink")
                set_attribute(head.replace,"text-decoration-line",ul)
                set_attribute(head.replace,"text-decoration-color",uccolor)
                set_attribute(head.replace,"background-color",bgcolor)
                set_attribute(head.replace,"hyperlink",hyperlink)
                node.setproperty(head.replace,node.getproperty(head))
                curkern = 0
            end
        else
            curkern = 0
        end
        head = head.next
    end
    return nodelist
end

function fix_justification(nodelist,alignment,parent,direction)
    if alignment == "start" then
        if direction == "rtl" then
            alignment = "rightaligned"
        else
            alignment = "leftaligned"
        end
    elseif alignment == "end" then
        if direction == "rtl" then
            alignment = "leftaligned"
        else
            alignment = "rightaligned"
        end
    end
    local curalignment = alignment
    if direction == "rtl" then
        if alignment == "rightaligned" then
            curalignment = "leftaligned"
        elseif alignment == "leftaligned" then
            curalignment = "rightaligned"
        end
    end

    local head = nodelist
    while head do
        if head.id == 0 then -- hlist

            -- we are on a line now. We assume that the spacing needs correction.
            -- The goal depends on the current line (par shape!)
            local goal
            if head.width == 1 then
                goal, _, _ = node.dimensions(head.glue_set, head.glue_sign, head.glue_order, head.head)
            else
                goal = head.width
            end
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

            for n in node.traverse(head.head) do
                if n.id == glyph_node then
                    font_before_glue = n.font
                elseif n.id == glue_node then
                    if n.subtype==0 and font_before_glue and get_glue_value(n,"width") > 0 and head.glue_sign == 1 then
                        local fonttable = font.fonts[font_before_glue]
                        if not fonttable then fonttable = font.fonts[1] err("Some font not found") end
                        set_glue_values(n,{width = fonttable.parameters.space, shrink_order = head.glue_order, stretch = 0, stretch_order = 0})
                    end
                end
            end

            if curalignment == "rightaligned" or curalignment == "centered" then

                local list_start = head.head
                local rightskip_node = node.tail(head.head)
                local parfillskip

                -- first we remove everything between the rightskip and the
                -- last non-glue/non-penalty item
                -- the glues might contain "plus 1 fill" and the penalties are not
                -- useful
                local tmp = rightskip_node.prev
                while tmp and ( tmp.id == glue_node or tmp.id == penalty_node or tmp.id == dir_node ) do
                    tmp = tmp.prev
                    if tmp == nil then break end
                    head.head = node.remove(head.head,tmp.next)
                end

                local wd = node.dimensions(head.glue_set, head.glue_sign, head.glue_order,head.head)

                local leftskip_node
                if curalignment == "rightaligned" then
                    leftskip_node = set_glue(nil,{width = goal - wd})
                else
                    leftskip_node = set_glue(nil,{width = ( goal - wd ) / 2 })
                end
                head.head = node.insert_before(head.head,head.head,leftskip_node)
            end
        elseif head.id == 1 then -- vlist
            fix_justification(head.head,alignment,head,direction)
        end
        head = head.next
    end
    return nodelist
end

local function check_if_a_line_exeeds(nodelist,wd,glue_set,glue_sign,glue_order)
    local head = nodelist
    while head do
        if head.id == vlist_node then
            return check_if_a_line_exeeds(head.head,wd,glue_set,glue_sign,glue_order)
        elseif head.id == hlist_node then
            local width = node.dimensions(glue_set,glue_sign,glue_order,head.head)
            if width > wd then
                return true
            end
        end
        head = head.next
    end
    return false
end

function do_linebreak( nodelist,hsize,parameters )
    if nodelist == nil then
        err("No nodelist found for line breaking.")
        return box(tenmm_sp,tenmm_sp,"black")
    end

    parameters = parameters or {}
    finish_par(nodelist,hsize,parameters)

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

    -- This could be done with a meta table, but somehow LuaTeX 104 doesn't like it
    for k,v in pairs(parameters) do
        default_parameters[k] = v
    end

    -- Try to break the paragraph until there is no line
    -- longer than expected
    local j
    local c = 0
    while true do
        j = tex.linebreak(node.copy_list(nodelist),default_parameters)
        if not check_if_a_line_exeeds(j,hsize,j.glue_set, j.glue_sign,j.glue_order) then
            break
        end
        default_parameters.emergencystretch = default_parameters.emergencystretch + 0.1 * hsize
        c = c + 1
        if c > 9 then
            break
        end
        node.flush_list(j)
    end
    node.flush_list(nodelist)

    -- Adjust line heights. Always take the largest font in a row.
    local head = j
    local maxlineheight
    local fam
    local _h
    while head do
        if head.id == hlist_node then -- hlist
            local lineheight
            maxlineheight = 0
            local head_list = head.list
            local adjustlineheight = true
            while head_list do
                lineheight = lineheight or node.has_attribute(head_list,att_lineheight)
                if node.has_attribute(head_list,att_dontadjustlineheight) then
                    adjustlineheight = false
                end
                -- There could be a hlist (HTML table for example) in the line
                if head_list.id == hlist_node or head_list.id == vlist_node then
                    if head_list.head then
                        _, _h, _d = node.dimensions(head_list.head)
                        maxlineheight = math.max(_h + _d,maxlineheight)
                    end
                else
                    fam = get_attribute(head_list,"fontfamily")
                    if fam and fam > 0 then
                        maxlineheight = math.max(fonts.lookup_fontfamily_number_instance[fam].baselineskip,maxlineheight)
                    end
                end
                head_list = head_list.next
            end
            if adjustlineheight then
                if lineheight and lineheight > 0.75 * maxlineheight then
                    head.height = lineheight
                    head.depth  = 0.25 * maxlineheight
                else
                    head.height = 0.75 * maxlineheight
                    head.depth  = 0.25 * maxlineheight
                end
            end
        end
        head = head.next
    end
    local ret = node.vpack(j)
    setprop(ret,"origin","do_linebreak")
    return ret
end

function create_empty_vbox_width_width_height(wd,ht)
    local hb = create_empty_hbox_with_width(wd)
    local n = set_glue(nil,{width = 0, stretch = 2^16, stretch_order = 3})
    node.insert_after(hb,hb,n)
    n = node.vpack(n,ht,"exactly")
    node.set_attribute(n,att_dontadjustlineheight,1)
    return n
end

function create_empty_hbox_with_width( wd )
    local n = set_glue(nil,{width = 0, stretch = 2^16, stretch_order = 3})
    n = node.hpack(n,wd,"exactly")
    return n
end

do
    local destcounter = 0
    -- Create a pdf anchor (dest object). It returns a whatsit node and the
    -- number of the anchor, so it can be used in a pdf link or an outline.
    function mknumdest()
        destcounter = destcounter + 1
        local d = node.new("whatsit","pdf_dest")
        d.named_id = 0
        d.dest_id = destcounter
        d.dest_type = 0
        return d, destcounter
    end
end

-- See PDF v1.7 spec 8.2 Document-Level Navigation
-- dest_type:
-- xyz   = 0  goto the current position
-- fit   = 1  fit the page in the window
-- fith  = 2  fit the width of the page
-- fitv  = 3  fit the height of the page
-- fitb  = 4  fit the ‘Bounding Box’ of the page
-- fitbh = 5  fit the width of ‘Bounding Box’ of the page
-- fitbv = 6  fit the height of ‘Bounding Box’ of the page
-- fitr  = 7 ?


function mkstringdest(name)
    local d = node.new("whatsit","pdf_dest")
    d.named_id = 1
    d.dest_id = utf8_to_utf16_string_pdf(name)
    d.dest_type = 0
    return d
end

-- Generate a hlist with necessary nodes for the bookmarks. To be inserted into a vlist that gets shipped out
function mkbookmarknodes(level,open_p,title)
    -- The bookmarks need three values, the level, the name and if it is
    -- open or closed
    setup_page(nil, "mkbookmarknodes")
    local openclosed
    if open_p then openclosed = 1 else openclosed = 2 end
    level = level or 1
    title = title or "no title for bookmark given"

    local n,counter = mknumdest()
    local udw = node.new("whatsit","user_defined")
    udw.user_id = user_defined_bookmark
    udw.type = 115 -- a string
    udw.value = string.format("%d+%d+%d+%s",level,openclosed,counter,title)
    n.next = udw
    udw.prev = n
    -- this hlist sometimes gets reused, for example with Td/sethead=yes.
    -- therefore we need to find it in tabular#remove_bookmark_nodes()
    -- and remove them.
    local hlist = node.hpack(n)
    return hlist
end


-- blue rule below the hbox for debugging purpose
function addhrule(hbox)
    local n = node.new("whatsit","pdf_literal")
    n.data = string.format("q 0.3 w [2 1] 0 d 0 0 1 RG 0 %g  m %g %g l S Q",  sp_to_bp(hbox.height),  -sp_to_bp(hbox.width) ,  sp_to_bp(hbox.height) )
    local tail = node.tail(hbox)
    hbox = node.insert_after(hbox,tail,n)
    hbox = node.hpack(hbox)
    return hbox
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

-- We have an array of color names to be used in attributes. Every color needs to get registered!
function register_color( name )
    if colors[name] ~= nil then
        return colors[name].index
    end
    colortable[#colortable + 1] = name
    return #colortable
end

-- Get r,g,b and alpha values (#f0f,#ff00ff,rgb(0,255,0) or rgb(0,255,0,1))
function getrgb( colorvalue )
    local r,g,b,a
    local model = "rgb"
    local rgbstr = "^rgba?%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*%)$"
    local rgbastr = "^rgba?%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d%.%d)%s*%)$"
    if string.sub(colorvalue,1,3) == "rgb" then
        if string.match(colorvalue, rgbstr) then
            r,g,b = string.match(colorvalue, rgbstr)
        elseif string.match(colorvalue, rgbastr) then
            r,g,b,a = string.match(colorvalue, rgbastr)
        else
            -- w("don't know")
        end
        if r == nil then
            err("Could not parse color %q",colorvalue)
            return 0,0,0
        end
        r = math.round(r / 255 , 3)
        g = math.round(g / 255 , 3)
        b = math.round(b / 255 , 3)
        if a then a = a * 100 end
    elseif #colorvalue == 7 then
        r,g,b = string.match(colorvalue,"#?(%x%x)(%x%x)(%x%x)")
        r = math.round(tonumber(r,16) / 255, 3)
        g = math.round(tonumber(g,16) / 255, 3)
        b = math.round(tonumber(b,16) / 255, 3)
    elseif #colorvalue == 4 then
        r,g,b = string.match(colorvalue,"#?(%x)(%x)(%x)")
        r = math.round(tonumber(r,16) / 15, 3)
        g = math.round(tonumber(g,16) / 15, 3)
        b = math.round(tonumber(b,16) / 15, 3)
    else
        err("Could not parse color %q",colorvalue)
        return 0,0,0
    end
    return r,g,b,a
end

-- color is an integer
function set_color_if_necessary( nodelist,color )
    local dontformat = node.has_attribute(nodelist,att_dont_format)

    if not color then return nodelist end

    local colorname
    if color == -1 then
        colorname = "black"
    else
        colorname = colortable[color]
    end
    -- When we uncomment the if .. end here, the typesetting
    -- process is much slower. See #143
    if colorname == "black" then return nodelist end
    local colstart, colstop
    colstart = node.new("whatsit","pdf_colorstack")
    colstop  = node.new("whatsit","pdf_colorstack")
    colstart.data = colors[colorname].pdfstring
    colstop.data  = ""
    colstart.command = 1
    colstop.command  = 2
    colstart.stack = defaultcolorstack
    colstop.stack = defaultcolorstack

    if dontformat then
        node.set_attribute(colstart,att_dont_format,dontformat)
    end

    nodelist = node.insert_before(nodelist,nodelist,colstart)
    local last = node.tail(nodelist)
    nodelist = node.insert_after(nodelist,tail,colstop)

    setprop(colstart,"origin","setcolorifnecessary")
    setprop(colstop,"origin","setcolorifnecessary")
    return nodelist
end

-- Set an attribute to the list and all sublists.
function set_attribute_recurse(nodelist,attribute,value)
    while nodelist do
        if nodelist.id==vlist_node or nodelist.id==hlist_node  then
            set_attribute_recurse(nodelist.list,attribute,value)
        else
            set_attribute(nodelist,attribute,value)
        end
        nodelist=nodelist.next
    end
end

function set_fontfamily_if_necessary(nodelist,fontfamily)
    local fam
    while nodelist do
        if nodelist.id==vlist_node or nodelist.id==hlist_node  then
            fam = set_fontfamily_if_necessary(nodelist.list,fontfamily)
        elseif nodelist.id == glue_node and nodelist.subtype == 100  then
            fam = set_fontfamily_if_necessary(nodelist.leader,fontfamily)
        else
            fam = get_attribute(nodelist,"fontfamily")
            -- See #242, #235 and referenced bugs (and change 5af208f)
            if fam == 0 or ( fam == nil and nodelist.id == rule_node and get_attribute(nodelist,"publisher") == 1 )  then
                set_attribute(nodelist,"fontfamily",fontfamily)
                fam = fontfamily
            end
        end
        nodelist=nodelist.next
    end
    return fam
end

function break_url( nodelist )
    local p

    local slash = string.byte("/")
    for n in node.traverse_id(glyph_node,nodelist) do
        p = node.new("penalty")

        if n.char == slash then
            p.penalty=-10
        else
            p.penalty=-5
        end
        set_attribute(p,"hyperlink",get_attribute(n,"hyperlink"))
        p.next = n.next
        if n.next and n.next.prev then
            n.next.prev = p
        end
        n.next = p
        p.prev = n
    end
    return nodelist
end

function colorbar( wd,ht,dp,color,origin )
    local colorname = color
    if color == "-" then
        -- ok, ignore
    else
        if not colorname or colorname == "" then
            colorname = "black"
        end
        if not colors[colorname] then
            err("Color %q not found",color)
            colorname = "black"
        end
    end

    local rule_start = node.new("whatsit","pdf_literal")
    setprop(rule_start,"origin","colorbar")
    if colorname ~= "-" then
        rule_start.mode = 0
        rule_start.data = "q "..colors[colorname].pdfstring .. string.format(" %g w 0 %g m  %g %g l s Q ",sp_to_bp(ht),sp_to_bp(ht / 2) , sp_to_bp(wd),sp_to_bp(ht / 2))
    end
    local h = node.hpack(rule_start)
    h.width = wd
    h.depth = dp
    h.height = ht
    origin = origin or "origin_colorbar"
    setprop(h,"origin",origin)
    return h
end

local explode = function(s,p)
   local t = { }
   for s in string.gmatch(s,p) do
       if s ~= "" then
           t[#t+1] = s
       end
   end
   return t
end

function montage( nodelist_background,nodelist_foreground, origin_x, origin_y )
    local wd_bg = nodelist_background.width
    local ht_bg = nodelist_background.height + nodelist_background.depth
    local wd_fg = nodelist_foreground.width
    local ht_fg = nodelist_foreground.height + nodelist_foreground.depth
    local wd = wd_bg - wd_fg
    local ht = ht_bg - ht_fg
    origin_x = 100 - origin_x
    origin_y = 100 - origin_y
    local x = math.round(  sp_to_bp(wd - (wd * origin_x) / 100  ), 3 )
    local y = math.round(  sp_to_bp(ht - (ht * origin_y) / 100  ), 3 )

    local pdf_literal_q = node.new("whatsit","pdf_literal")
    pdf_literal_q.data = string.format("1 0 0 1 %g %g cm ",x, y)

    local pdf_literal_Q = node.new("whatsit","pdf_literal")
    pdf_literal_Q.data = string.format("1 0 0 1 %g 0 cm ",-1 * math.round(sp_to_bp(wd_bg),3))

    local pdf_save    = node.new("whatsit","pdf_save")
    local pdf_restore = node.new("whatsit","pdf_restore")
    local hbox

    hbox = node.insert_before(nodelist_background,nodelist_background, pdf_save)
    hbox = node.insert_after(hbox,node.tail(hbox),pdf_literal_Q)
    hbox = node.insert_after(hbox,node.tail(hbox),pdf_literal_q)
    hbox = node.insert_after(hbox,node.tail(hbox),nodelist_foreground)

    hbox = node.hpack(hbox)
    hbox.depth = 0
    hbox = node.insert_after(hbox,node.tail(hbox),pdf_restore)

    hbox = node.vpack(hbox)
    hbox.width = wd_bg
    hbox.height = ht_bg
    return hbox
end

--- Apply transformation matrix to object given at _nodelist_. Called from commands#transformation.
function matrix( nodelist,matrix,origin_x,origin_y )
    local wd,ht = nodelist.width, nodelist.height + nodelist.depth
    local tbl = explode(matrix,"[^\t ]+")

    origin_x = 100 - origin_x
    origin_y = 100 - origin_y
    local x = math.round(  sp_to_bp(wd - (wd * origin_x) / 100  )  , 3 )
    local y = math.round(  sp_to_bp(ht - (ht * origin_y) / 100  )  , 3 )

    local pdf_literal_q = node.new("whatsit","pdf_literal")
    local pdf_literal_Q = node.new("whatsit","pdf_literal")

    pdf_literal_q.data   = string.format("q 1 0 0 1 %g -%g cm  q %g %g %g %g %g %g cm q 1 0 0 1 -%g %g cm ",x,y,tbl[1],tbl[2],tbl[3],tbl[4],tbl[5],tbl[6],x,y )
    pdf_literal_Q.data = "Q Q Q"

    local pdf_save    = node.new("whatsit","pdf_save")
    local pdf_restore = node.new("whatsit","pdf_restore")

    local hbox
    hbox = node.insert_before(nodelist,nodelist,pdf_literal_q)
    node.insert_after(nodelist,nodelist,pdf_literal_Q)
    hbox = node.insert_before(hbox,pdf_literal_q,pdf_save)
    hbox = node.hpack(hbox)

    hbox.depth = 0
    node.insert_after(hbox,node.tail(hbox),pdf_restore)

    local newbox = node.vpack(hbox)
    return newbox
end

--- Rotate an object clockwise with a given angle (in degrees).
---
--- First rotate the object at the top left corner (default)
--- If the origin is not top left, we need to shift the object
function rotate( nodelist,angle,origin_x,origin_y )
    local wd,ht = nodelist.width, nodelist.height + nodelist.depth
    nodelist.width = 0
    nodelist.height = 0
    nodelist.depth = 0

    -- positive would be counter clockwise, but CSS is clockwise. So we multiply by -1
    local angle_rad = -1 * math.rad(angle)
    local sin = math.round(math.sin(angle_rad),3)
    local cos = math.round(math.cos(angle_rad),3)
    local q = node.new("whatsit","pdf_literal")
    q.mode = 0

    origin_x = 100 - origin_x
    origin_y = 100 - origin_y
    local x = math.round(  sp_to_bp(wd - (wd * origin_x) / 100  )  , 3 )
    local y = math.round(  sp_to_bp(ht - (ht * origin_y) / 100  )  , 3 )
    q.data = string.format("q 1 0 0 1 %g -%g cm  q %g %g %g %g 0 0 cm q 1 0 0 1 -%g %g cm ",x,y,cos,sin, -1 * sin,cos,x,y )
    q.next = nodelist
    local tail = node.tail(nodelist)
    local Q = node.new("whatsit","pdf_literal")
    Q.data = "Q Q Q"
    tail.next = Q
    local tmp = node.vpack(q)
    tmp.width  = 0
    tmp.height = 0
    tmp.depth = 0
    return tmp
end

--- Rotate a table cell clockwise with a given angle (in degrees).
-- This is a simple and very basic implementation which needs to be extended in the future.
function rotateTd( nodelist,angle, width_sp)
    if angle % 360 == 0 then return nodelist end

    -- positive would be counter clockwise, but CSS is clockwise. So we multiply by -1
    local angle_rad = -1 * math.rad(angle)

    -- With multi paragraph table cells it is easier if we have only one node to deal with.
    if nodelist.next then
        nodelist = node.vpack(nodelist)
    end

    -- When text is rotated, it needs to get shifted to the right and to the bottom
    local _wd,_ht,_dp = nodelist.width, nodelist.height,nodelist.depth
    local ht = _ht + _dp

    nodelist.width = 0
    nodelist.height = 0
    nodelist.depth = 0

    local sin = math.round(math.sin(angle_rad),3)
    local cos = math.round(math.cos(angle_rad),3)

    local q = node.new("whatsit","pdf_literal")
    q.mode = 0

    local shift_x, shift_y

    local shift_x_wd = cos * _wd
    local shift_x_ht = sin * ht
    if shift_x_wd > 0 then shift_x_wd = 0 end
    if shift_x_ht > 0 then shift_x_ht = 0 end

    local shift_y_wd = -1 * sin * _wd
    local shift_y_ht = cos * ht
    if shift_y_wd > 0 then shift_y_wd = 0 end
    if shift_y_ht > 0 then shift_y_ht = 0 end

    shift_x =  sp_to_bp( shift_x_ht + shift_x_wd) * -1
    shift_y =  sp_to_bp( shift_y_ht + shift_y_wd)

    q.data = string.format("q %g %g %g %g %g %g cm ",cos,sin, -1 * sin,cos,shift_x,shift_y)
    local Q = node.new("whatsit","pdf_literal")
    Q.data = "Q"

    _,q = node.insert_before(nodelist,nodelist,q)
    _,Q = node.insert_after(q,nodelist,Q)
    q = node.vpack(q)

    q.width  = math.abs(_wd * cos) + math.abs(_ht * sin)
    q.height = math.abs(_ht * cos) + math.abs(_wd * sin)
    q.depth  = _dp

    return q
end

--- Rotate a text on a given angle (`angle` on textblock).
function rotate_textblock( nodelist,angle )
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
    if type(str) == "table" then
        str = table.concat(str)
    end
    if not str then return "" end
    local replace = {
        [">"] = "&gt;",
        ["<"] = "&lt;",
        ["\""] = "&quot;",
        ["&"] = "&amp;",
    }
    -- FIXME, str can be bool
    local ret = string.gsub(str,".",replace)
    return ret
end

--- See commands#save_dataset() for  documentation on the data structure for `xml_element`.
function xml_to_string( xml_element, level )
    local str = ""
    if type(xml_element) == "string" then
        return xml_escape(xml_element)
    end
    if type(xml_element) ~= "table" then
        err("xml_to_string is not a table, but a %s %q",type(xml_element),tostring(xml_element))
        return "error in publisher run"
    end
    level = level or 0
    local eltname = xml_element[".__name"] or xml_element[".__local_name"] or ""
    if level == 0 and eltname == "" then eltname = "xxx" end
    if eltname ~= "" then
        str = str ..  "<" .. eltname
        for k,v in pairs(xml_element) do
            if type(k) == "string" and not k:match("^%.") then
                str = str .. string.format(" %s=%q", k,xml_escape(v))
            end
        end
        if xml_element[".__ns"] then
            for k,v in pairs(xml_element[".__ns"]) do
                if type(k) == "string" then
                    if k == "" then
                        k = "xmlns"
                    else
                        k = "xmlns:" .. k
                    end
                    str = str .. string.format(" %s=%q", k,xml_escape(v))
                end
            end
        end
        str = str .. ">"
    end
    for i,v in ipairs(xml_element) do
        if type(v) == "string" and v == "" then
            -- ok, nothing do do
        else
            str = str .. xml_to_string(v,level + 1)
        end
    end
    if eltname ~= "" then
        str = str ..  "</" .. eltname .. ">"
    end
    return str
end

function xml_stringvalue( self )
    if type(self) == "string" then return self end
    local ret = {}
    for i=1,#self do
        local val = self[i]
        if type(val) == "table" then
            ret[#ret + 1] = xml_stringvalue(val)
        else
            ret[#ret + 1] = tostring(val)
        end
    end
    return table.concat(ret)
end

xml_stringvalue_mt = {
    __tostring = xml_stringvalue
}



--- Hyphenation and language handling
--- ---------------------------------

--- We map from symbolic names to (part of) file names. The hyphenation pattern files are
--- in the format `hyph-XXX.pat.txt` and we need to find out that `XXX` part.
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

--- Return a lang object
function get_language(id_or_locale_or_name)
    local orig_id_or_locale_or_name = id_or_locale_or_name
    local num = tonumber(id_or_locale_or_name)
    if num then
        return languages_id_lang[num]
    end
    local locale = string.lower(id_or_locale_or_name)

    if language_mapping[id_or_locale_or_name] then
        locale = language_mapping[id_or_locale_or_name]
    end
    locale = string.lower(locale)
    if languages[locale] then
        return languages[locale]
    end

    local filename_part
    if language_filename[locale] then
        filename_part = language_filename[locale]
    else
        local sep = "_"
        if string.match( locale ,"%-" ) then
            sep = "-"
        end
        local langcode, _ = table.unpack(string.explode(locale,sep))
        if language_filename[langcode] then
            filename_part = language_filename[langcode]
        end
    end

    local l = lang.new()

    if filename_part == "" then
        -- ignore this
        -- probably cjk or another language without hyphenation patterns
    elseif not filename_part then
        err("Can't find hyphenation patterns for language %s",tostring(orig_id_or_locale_or_name))
        return 0
    else
        local filename = string.format("hyph-%s.pat.txt",filename_part)
        log("Loading hyphenation patterns %q.",filename)
        local path = kpse.find_file(filename)
        local pattern_file = io.open(path)
        local pattern = pattern_file:read("*all")
        pattern_file:close()

        l:patterns(pattern)
    end

    local id = l:id()
    log("Language id: %d",id)
    local ret = { id = id, l = l, locale = locale }
    languages_id_lang[id] = ret
    languages[locale] = ret
    return ret
end

--- The language name is something like `German` or a locale.
function get_languagecode( locale_or_name )
    local tmp = get_language(locale_or_name)
    if type(tmp) ~= "table" then
        err("get_languagecode: return value should be a table. Something is wrong.")
        return 0
    end
    return tmp.id
end

function set_mainlanguage( mainlanguage )
    log("Setting default language to %q",mainlanguage or "?")
    defaultlanguage = get_languagecode(mainlanguage)
end


--- Return the language numbers used in this nodelist. Used before `do_linebreak()` to change pre-hyphenchar temporarily.
function get_languages_used( nodelist )
    local langs = {}
    for n in node.traverse_id(glyph_node,nodelist) do
        langs[n.lang] = true
    end
    local ret = {}
    for k,_ in pairs(langs) do
        ret[#ret + 1] = k
    end
    return ret
end


--- Misc
--- --------
function set_pageformat( wd,ht )
    options.pagewidth   = wd
    options.pageheight  = ht
    tex.pagewidth =  wd
    tex.pageheight = ht
end

-- Return remaining height (sp), first row, last row
function get_remaining_height(area,allocate)
    local cols = current_grid:number_of_columns(area)
    local startcol = 1
    local row,firstrow,lastrow,maxrows
    firstrow = current_grid:current_row(area)
    if not firstrow then
        err("get remaining height: no current row")
        firstrow = 1
    end
    maxrows  = current_grid:number_of_rows(area)
    if allocate == "auto" then
        while firstrow <= maxrows and (not current_grid:row_has_some_space(firstrow,area)) do
            firstrow = firstrow + 1
        end

        local row = firstrow + 1
        while row <= maxrows and current_grid:row_has_some_space(row,area) do
            row = row + 1
        end

        if row > maxrows then
            return ( row - firstrow ) * current_grid.gridheight, firstrow
        end
        local lastrow = row
        while not current_grid:fits_in_row_area(startcol,cols,lastrow,area) and lastrow <= maxrows do

            lastrow = lastrow + 1
        end
        lastrow = lastrow - 1
        if lastrow == firstrow then lastrow = nil end
        if lastrow >= maxrows then lastrow = nil end
        return (row - firstrow) * current_grid.gridheight, firstrow,lastrow
    end
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
            return ( lastrow - firstrow)  * current_grid.gridheight, firstrow, firstrow
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
        next_area(areaname)
        setup_page(nil,"next_row")
        grid = current_page.grid
        grid:set_current_row(1)
    else
        -- Version 2.7.3 and before had the problem that the cursor is past the right
        -- edge. See bug #105 (https://github.com/speedata/publisher/issues/105) for
        -- a description.
        -- A <NextRow rows="1" /> would go to the next free row, which could be the current
        -- row.
        -- <NextRow rows="1" /> should instead go to the beginning of the next row. So a
        -- <NextRow rows="1" /> directly after <PlaceObject>...</PlaceObject> width the right
        -- edge at the right margin will leave one blank line.
        -- The old behavior is to decrease 1 from the movement, which makes no sense these days.
        local dec = 0
        if grid:current_column(areaname) > 1 then
            dec = 1
        end
        grid:set_current_row(current_row + rows - dec,areaname)
        grid:set_current_column(1,areaname)
    end
end

function empty_block()
    local r = node.new("hlist")
    r.width = 0
    r.height = 0
    r.depth = 0
    local v = node.vpack(r)
    return v
end


function emergency_block()
    local r = node.new("rule")
    r.width = 5 * 2^16
    r.height = 5 * 2^16
    r.depth = 0
    local v = node.vpack(r)
    return v
end


-- resolve all font aliases
function get_fontname(fontname)
    if not fontname then return nil end
    local result = fontname
    while true do
        if fontaliases[result] then
            result = fontaliases[result]
        else
            break
        end
    end
    return result
end


--- Defaults
--- --------

--- This function is only called once from `dothings()` during startup phase. We define
--- a family with regular, bold, italic and bolditalic font with size 10pt (we always
--- measure font size in dtp points)
function define_default_fontfamily()
    define_fontfamily(
        "TeXGyreHeros-Regular",
        "TeXGyreHeros-Bold",
        "TeXGyreHeros-Italic",
        "TeXGyreHeros-BoldItalic",
        "text",
        tenpoint_sp,
        twelvepoint_sp
    )

    fontaliases["sans"] = "TeXGyreHeros-Regular"
    fontaliases["sans-bold"] = "TeXGyreHeros-Bold"
    fontaliases["sans-italic"] = "TeXGyreHeros-Italic"
    fontaliases["sans-bolditalic"] = "TeXGyreHeros-BoldItalic"

    fontaliases["serif"] = "CrimsonPro-Regular"
    fontaliases["serif-bold"] = "CrimsonPro-Bold"
    fontaliases["serif-italic"] = "CrimsonPro-Italic"
    fontaliases["serif-bolditalic"] = "CrimsonPro-BoldItalic"

    fontaliases["monospace"] = "CamingoCode-Regular"
    fontaliases["monospace-bold"] = "CamingoCode-Bold"
    fontaliases["monospace-italic"] = "CamingoCode-Italic"
    fontaliases["monospace-bolditalic"] = "CamingoCode-BoldItalic"
end

function define_fontfamily( regular,bold,italic,bolditalic, name, size, baselineskip )
    local fam={
        size         = size,
        baselineskip = baselineskip,
        scriptsize   = math.round(size * 0.8,0),
        scriptshift  = math.round(size * 0.3,0),
        name = name
    }
    local ok,tmp
    if regular then
        ok,tmp = fonts.make_font_instance(regular,fam.size)
        if not ok then return false, tmp end
        fam.normal = tmp
        fam.fontfaceregular = regular
        ok,tmp = fonts.make_font_instance(regular,fam.scriptsize)
        if not ok then return false, tmp end
        fam.normalscript = tmp
    end

    if bold then
        ok,tmp = fonts.make_font_instance(bold,fam.size)
        if not ok then return false, tmp end
        fam.bold = tmp
        ok,tmp = fonts.make_font_instance(bold,fam.scriptsize)
        if not ok then return false, tmp end
        fam.boldscript = tmp
    end

    if italic then
        ok,tmp = fonts.make_font_instance(italic,fam.size)
        if not ok then return false, tmp end
        fam.italic = tmp
        ok,tmp = fonts.make_font_instance(italic,fam.scriptsize)
        if not ok then return false, tmp end
        fam.italicscript = tmp
    end

    if bolditalic then
        ok,tmp = fonts.make_font_instance(bolditalic,fam.size)
        if not ok then return false, tmp end
        fam.bolditalic = tmp
        ok,tmp = fonts.make_font_instance(bolditalic,fam.scriptsize)
        if not ok then return false, tmp end
        fam.bolditalicscript = tmp
    end

    fonts.lookup_fontfamily_number_instance[#fonts.lookup_fontfamily_number_instance + 1] = fam
    local fontnumber = #fonts.lookup_fontfamily_number_instance
    fonts.lookup_fontfamily_name_number[name] = fontnumber
    log("DefineFontfamily %q size %.03gpt/%.03gpt id: %d",name,size / factor,baselineskip / factor,fontnumber)
    return fontnumber
end


-- deepcopy is for <Copy-of>
function deepcopy(t)
    local typ = type(t)
    if typ ~= 'table' then return t end
    local mt = getmetatable(t)
    local res = {}
    for k,v in pairs(t) do
        typ = type(v)
        if typ == 'table' then
            if k ~= ".__parent" and k ~= ".__context" then
                v = deepcopy(v)
            end
        else
            if node.is_node(v) then
                v = node.copy_list(v)
            end
        end
        res[k] = v
    end
    setmetatable(res,mt)
    return res
end


function copy_table_from_defaults( defaults )
    if type(defaults) ~= "table" then
        return defaults
    end
    local newtbl = {}
    for key,value in next,defaults,nil do
        newtbl[key] = value
    end
    return newtbl
end

-- Return the height of the page given by the relative page number
-- (starting from the current_pagenumber).
-- This is used in tables to get the height of a page in a multi
-- page table. Called from tabular.lua / set in commands.lua (#table)
function getheight( relative_framenumber )
    local grid = current_grid
    local cp, cg, cpn, cfn -- current page, current grid, current page number, current frame number
    cp = current_page
    cg = current_grid
    cpn = current_pagenumber

    local areaname = xpath.get_variable("__currentarea")
    local current_framenumber = grid:framenumber(areaname)
    cfn = current_framenumber

    local thispagenumber = current_pagenumber
    local thispage
    c = 1
    while c < relative_framenumber do
        if grid:number_of_frames(areaname) == current_framenumber then
            thispagenumber = thispagenumber + 1
            thispage = pages[thispagenumber]
            -- be aware that setup_page(..,) calls setup_page() but without
            -- parameter. Therefore the current_pagenumber has to be set
            current_pagenumber = thispagenumber
            if not thispage then
                setup_page(thispagenumber,"getheight")
            end
            current_framenumber = 1
        else
            current_framenumber = current_framenumber + 1
        end
        current_page = pages[thispagenumber]
        current_pagenumber = thispagenumber
        current_grid = current_page.grid
        c = c + 1
    end
    local firstrow = current_grid:first_free_row(areaname,current_framenumber)
    local remaining_height = current_grid:remaining_height_sp(firstrow,areaname,current_framenumber)
    current_pagenumber = cpn
    current_grid = cg
    current_page = cp
    current_grid:set_framenumber(areaname,cfn)

    return remaining_height
end


-- Return true iff the paragraph has at lines or less text
-- lines left over and is not at the last line.
function less_or_equal_than_n_lines( nodelist, lines )
    if lines == 0 then return false end
    for i=1,lines - 1 do
        if nodelist.id == publisher.hlist_node and nodelist.next then
            nodelist = nodelist.next
        else
            if i == 1 then
                return false
            end
        end
    end
    return nodelist.next == nil
end

function join_table_to_box(objects,from)
    for i=1,#objects - 1 do
        objects[i].next = objects[i+1]
    end
    if objects[1] == nil then
        return nil
    end
    node.slide(objects[1])
    local vbox = node.vpack(objects[1])
    setprop(vbox,"origin","join_table_hbox " .. (from or "") )
    return vbox
end


--- vsplit
--- ======
--- The idea of vsplit is to take a long paragraph and break it into small pieces of text
--- ![Idea of vsplit](img/vsplit.png)
--- Of course its not without things to take care of.
---
---  1. Orphans and widows
---  1. The size of the destination area
---
--- Input
--- -----
--- The table `objects_t` is an array of vboxes, containing material for the current frame of height
--- `frameheight`. It is not defined if the height of the vboxes is larger than the height of the frame.
--- Therefore we dissect all the paragraphs and place them into one large list, the `hlist`.
---
--- Output
--- ------
--- The return value is a vbox that should be placed in the PDF and has a height <= frameheight. If there
--- is material left over for a next area, the `objects_t` table is changed and vsplit gets called again.
--- Making `objects_t` empty is a signal for the function calling vsplit (commands/text) that all
--- text has been put into the PDF.
function vsplit( objects_t, parameter )
    --- Step 1: collect all the objects in one big table.
    --- ------------------------------------------------
    --- The objects that are not allowed to break are temporarily
    --- collected in a special vertical list that gets vpacked to
    --- disallow an "area" break.
    ---
    --- ![Step 1](img/vsplit2.png)
    --- (assuming that there is a `break-below="no"` for the text format of the header).
    local balance = parameter.balance
    local valignlast = parameter.valignlast
    local frameheight = parameter.maxheight
    local lastpaddingbottommax = parameter.lastpaddingbottommax


    local hlist = {}
    local ht_hlist = 0

    -- We need the height for the decision to balance the text
    local ht_hlist = 0


    -- a list for hboxes with break_below = true
    local tmplist = {}
    local count_lists = #objects_t
    local vlist = table.remove(objects_t,1)
    local i = 1
    local margin_newcolumn
    while vlist do
        local head = vlist.head
        while head do
            local bordernumber = get_attribute(head,"bordernumber")
            if bordernumber then
                -- move bordernumber to vlist
                set_attribute(vlist,"bordernumber",bordernumber)
                clear_attribute(vlist,"bordernumber")
            end

            local tmp_margin_newcolumn = node.has_attribute(head, publisher.att_margin_newcolumn)

            if tmp_margin_newcolumn then
                margin_newcolumn = tmp_margin_newcolumn
            end
            node.set_attribute(head,publisher.att_margin_newcolumn,margin_newcolumn)

            if i == count_lists and head.next == nil then
                -- the last object must not be in the tmplist
                node.unset_attribute(head,publisher.att_break_below_forbidden)
            end
            head.prev = nil
            local break_below_forbidden = node.has_attribute(head,publisher.att_break_below_forbidden)
            if break_below_forbidden then
                node.unset_attribute(head,publisher.att_margin_newcolumn)
                tmplist[#tmplist + 1] = head
                local tmp = head.next
                head.next = nil
                head = tmp
            else
                -- break allowed
                -- if there is anything in the tmplist, we vpack it and add it to the current hlist.
                if #tmplist > 0 then
                    tmplist[#tmplist + 1] = head

                    local tmp = head.next
                    head.next = nil
                    head = tmp

                    local margin_newcolumn_tmplist = node.has_attribute(tmplist[1], publisher.att_margin_newcolumn)
                    local vbox = join_table_to_box(tmplist,"break allowed")
                    node.set_attribute(vbox,publisher.att_margin_newcolumn,margin_newcolumn_tmplist)

                    hlist[#hlist + 1] = vbox
                    ht_hlist = ht_hlist + vbox.height + vbox.depth
                    tmplist = {}
                else
                    hlist[#hlist + 1] = head
                    if head.id == publisher.glue_node then
                        ht_hlist = publisher.get_glue_size(head)
                    else
                        ht_hlist = ht_hlist + ( head.height or 0 ) + ( head.depth or 0 )
                    end
                    local tmp = head.next
                    head.next = nil
                    head = tmp
                end
            end
        end
        vlist = table.remove(objects_t,1)
        i = i + 1
    end
    -- the hlist now has lot's of rows. Widows/orphans are packed together in a vbox with n hboxes.

    if balance > 1 and ht_hlist < balance * frameheight then
        -- TODO: splitpos should be based on the actual height
        local splitpos = math.ceil(#hlist / balance)

        local margin_newcolumn_obj1 = node.has_attribute(hlist[1], publisher.att_margin_newcolumn)
        if margin_newcolumn_obj1 and margin_newcolumn_obj1 > 0 then
            table.insert(hlist,1,publisher.add_glue(nil,"head",{width=margin_newcolumn_obj1}))
            splitpos = splitpos + 1
        end
        local obj1 = join_table_to_box({table.unpack(hlist,1,splitpos)},"balance > 1 obj1")
        if hlist[splitpos + 1] then
            local margin_newcolumn_obj2 = node.has_attribute(hlist[splitpos + 1], publisher.att_margin_newcolumn)
            if margin_newcolumn_obj2 and margin_newcolumn_obj2 > 0 then
                table.insert(hlist,splitpos + 1,publisher.add_glue(nil,"head",{width=margin_newcolumn_obj2}))
            end
            local obj2 = join_table_to_box({table.unpack(hlist,splitpos + 1)},"balance > 1 obj2")
            if valignlast == "bottom" then
                local remaining_height = frameheight - math.max(obj1.height, obj2.height)

                if remaining_height > lastpaddingbottommax then
                    remaining_height = remaining_height - lastpaddingbottommax
                end
                obj1.head = publisher.add_glue(obj1.head,"head",{width = remaining_height} )
                obj2.head = publisher.add_glue(obj2.head,"head",{width = remaining_height} )
            end
            return obj1, obj2
        else
            if valignlast == "bottom" then
                local remaining_height = frameheight - obj1.height
                if remaining_height > lastpaddingbottommax then
                    remaining_height = remaining_height - lastpaddingbottommax
                end
                obj1.head = publisher.add_glue(obj1.head,"head",{width = remaining_height} )
            end
            return obj1
        end
    end
    --- Step 2: Fill vbox (the return value)
    --- ------------------------------------
    --- Two cases: the objects have enough material to fill up the area (a)
    --- or we have no objects left for the area and return the final vbox for this area. (b)
    --- The task is to go though collection of h/vboxes (the hlist) and create one big vbox.
    --- This is done by filling the table `thisarea`.
    ---
    --- ![final step for area](img/vsplit3.png)
    local goal = frameheight
    local accumulated_height = 0
    local thisarea = {}
    local remaining_objects = {}
    local area_filled = false
    local lineheight = 0
    while not area_filled do
        for i=1,#hlist do
            local hbox = table.remove(hlist,1)
            if #thisarea == 0 then
                -- This is for a different margin-top at the beginning of a new column.
                if hbox.id == publisher.vlist_node then
                    local vbox = hbox
                    if vbox.list and vbox.list.id == publisher.glue_node then
                        local margin_top_boxstart = node.has_attribute(vbox.list, publisher.att_margin_top_boxstart)
                        vbox.list.width = margin_top_boxstart
                        hbox = node.vpack(vbox.list)
                    end
                end
            end

            if #thisarea == 0 and node.has_attribute(hbox, publisher.att_omit_at_top) then
                -- When the margin-below appears at the top of the new frame, we just ignore
                -- it. Too bad Lua doesn't have a 'next' in for-loops
            else
                local margin_newcolumn = node.has_attribute(hbox, publisher.att_margin_newcolumn)
                if margin_newcolumn and margin_newcolumn > 0 and #thisarea == 0 then
                    thisarea[#thisarea + 1] = publisher.add_glue(nil,"head",{width=margin_newcolumn})
                    lineheight = margin_newcolumn
                end

                if hbox.id == publisher.hlist_node or hbox.id == publisher.vlist_node then
                    lineheight = lineheight +  hbox.height + hbox.depth
                elseif hbox.id == publisher.glue_node then
                    lineheight = lineheight + get_glue_value(hbox,"width")
                elseif hbox.id == publisher.rule_node then
                    lineheight = lineheight + hbox.height + hbox.depth
                elseif hbox.id == publisher.whatsit_node then
                    -- ignore
                else
                    w("unknown node 1: %d",hbox.id)
                end
                -- 20 is some rounding error
                if accumulated_height + lineheight <= goal + 20 then
                    thisarea[#thisarea + 1] = hbox
                    accumulated_height = accumulated_height + lineheight
                    lineheight = 0
                else
                    -- objects > goal
                    -- This is case (a)
                    remaining_objects[1] = hbox
                    area_filled = true
                    break
                end
            end
        end
        area_filled = true
    end

    if #hlist > 0 then
        for i=1,#hlist do
            remaining_objects[#remaining_objects + 1] = hlist[i]
        end
    end
    -- Sometimes there is a single glue (margin-bottom) left, we should ignore it
    if #remaining_objects == 1 and node.has_attribute(remaining_objects[1], publisher.att_omit_at_top)  then
        -- ignore!?
    else
        objects_t[1] = join_table_to_box(remaining_objects,"remaining objects != 1")
    end

    --- It's a common situation where there is a single free row but the next material is
    --- too high for the row. So we return an empty list and hope that the calling function
    --- is clever enough to detect this case. (Well, it's not too difficult to detect, as
    --- the `objects_t` table is not empty yet.)
    return join_table_to_box(thisarea,"return") or publisher.empty_block()
end

--- Image handling
--- --------------

function set_image_length(len,width_or_height)
    if len == nil or len == "auto" then
        return nil
    elseif len == "100%" and width_or_height == "width" then
        return xpath.get_variable("__maxwidth")
    elseif tonumber(len) then
        if width_or_height == "width" then
            return current_grid:width_sp(len)
        else
            return len * current_grid.gridheight
        end
    else
        return tex.sp(len)
    end
end


-- Calculate the image width and height
-- stretch: grow to maxwidth,maxheight if needed
function calculate_image_width_height( image, width, height, minwidth, minheight, maxwidth, maxheight,stretch )
    -- from https://www.w3.org/TR/CSS2/visudet.html#min-max-widths:
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

    -- if stretch and max{height,width} then the image should grow as needed
    if stretch and maxheight < maxdimen and maxwidth < maxdimen then
        local stretchamount = math.min(maxwidth / image.xsize , maxheight / image.ysize )
        if stretchamount > 1 then
            return image.xsize * stretchamount, image.ysize * stretchamount
        end
    end

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
        height = math.max(minheight, maxwidth * height/width)
        width = maxwidth
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
        height = math.max(maxwidth * height / width, minheight )
        width = maxwidth
    elseif width < minwidth then
        -- w("3")
        height = math.min(minwidth * height / width, maxheight)
        width = minwidth
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


local images = {}
function new_image(filename,page,box,fallback,imageshape)
    return imageinfo(filename,page,box,fallback,imageshape)
end

function validimagetype(filename)
    local localfilename = kpse.find_file(filename)
    local f,errmsg = io.open(localfilename)
    if not f then
        err(errmsg)
        return nil
    end
    local whatever = f:read(5)
    if string.match(whatever,"<svg") then
        localfilename = splib.convert_svg_image(localfilename)
    end
    f:close()
    return localfilename
end

function get_fallback_image_name( filename, missingfilename )
    if filename then
        warning("Using fallback %q, missing file name is %q", filename or "<filename>", missingfilename or "<empty>")
        if not kpse.find_file(filename) then
            err("fallback image %q not found",filename or "<filename>")
            return "filenotfound.pdf"
        end
        return filename
    else
        return "filenotfound.pdf"
    end
end

-- Box is none, media, crop, bleed, trim, art
function imageinfo( filename,page,box,fallback,imageshape )
    page = page or 1
    box = box or "crop"
    -- there is no filename, we should fail or throw an error
    if not filename then
        err("No filename given for image")
        filename = get_fallback_image_name(fallback)
    end
    if type(filename) ~= "string" then
        err("something is wrong with the filename for the image, not a string")
        filename = get_fallback_image_name(fallback)
    end

    local new_name = filename .. tostring(page) .. tostring(box)

    if images[new_name] then
        return images[new_name]
    end

    log("Searching for image %q",tostring(filename))
    if not kpse.find_file(filename) then
        if options.imagenotfounderror then
            err("Image %q not found!",filename or "???")
        else
            warning("Image %q not found!",filename or "???")
        end
        filename = get_fallback_image_name(fallback,filename)
        page = 1
    end
    -- example is wrong: one based index
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
    local mt
    -- don't request XML shape file for http locations
    if imageshape and not string.match(filename, "^https?://") then
        local xmlfilename = string.gsub(filename,"(%..*)$","") .. ".xml"

        if kpse.find_file(xmlfilename) then
            local xmltab,msg = load_xml(xmlfilename,"Imageinfo")
            if not xmltab then
                err(msg)
            else
                mt = {}
                local segments = {}
                local cells_x,cells_y
                for _,v in ipairs(xmltab) do
                    if v[".__local_name"] == "cells_x" then
                        cells_x = v[1]
                    elseif v[".__local_name"] == "cells_y" then
                        cells_y = v[1]
                    elseif v[".__local_name"] == "segment" then
                        -- 0 based segments
                        segments[#segments + 1] = {v.x1,v.y1,v.x2,v.y2}
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
        end
    end

    if not images[new_name] then
        if string.match(filename, ".svg$") then
            filename = splib.convert_svg_image(filename)
            if filename == nil or filename == "" then filename = "filenotfound.pdf" else log("Using converted file %q instead",filename) end

        end
        filename = validimagetype(filename)
        local image_info = img.scan{filename = filename, pagebox = box, page=page,keepopen=true }
        images[new_name] = { img = image_info, allocate = mt }
    end
    return images[new_name]
end

function hlpage(pagenumber)
    pagenumber = tonumber(pagenumber)
    local pageobjnum = pdf.getpageref(pagenumber)
    local border = "/Border[0 0 0]"
    if options.showhyperlinks then
        border = string.format("/C [%s]",options.hyperlinksbordercolor or "0 0 0" )
    end
    local str = string.format("/Subtype/Link%s/A<</Type/Action/S/GoTo/D [ %d 0 R /Fit ] >>",border,pageobjnum)
    hyperlinks[#hyperlinks + 1] = str
    return #hyperlinks
end

local function char_to_hex(c)
    return string.format("%%%02X", string.byte(c))
end

local function urlencode(url)
    if url == nil then
        return
    end
    url = url:gsub("\n", "\r\n")
    url = url:gsub("([^%w _%-%.~:/%%=%?&])", char_to_hex)
    url = url:gsub(" ", "+")
    return url
end

function hlurl(href)
    local border = "/Border[0 0 0]"
    if options.showhyperlinks then
        border = string.format("/C [%s]",options.hyperlinksbordercolor or "0 0 0" )
    end
    href = urlencode(href)
    href = escape_pdfstring(href)
    local str = string.format("/Subtype/Link%s/A<</Type/Action/S/URI/URI (%s)>>",border,href)
    hyperlinks[#hyperlinks + 1] = str
    return #hyperlinks
end


--- Sorting
--- -------
--- The sorting code is currently used for index generation (commands#makeindex)

-- see http://lua.2524044.n2.nabble.com/A-stable-sort-td7648892.html
-- public domain or cc0

-- If you're using LuaJIT, change to 72.
local max_chunk_size = 12

function insertion_sort( array, first, last, goes_before )
  for i = first + 1, last do
    local k = first
    local v = array[i]
    for j = i, first + 1, -1 do
      if goes_before( v, array[j-1] ) then
        array[j] = array[j-1]
      else
        k = j
        break
      end
    end
    array[k] = v
  end
end

function merge( array, workspace, low, middle, high, goes_before )
  local i, j, k
  i = 1
  -- Copy first half of array to auxiliary array
  for j = low, middle do
    workspace[ i ] = array[ j ]
    i = i + 1
  end
  i = 1
  j = middle + 1
  k = low
  while true do
    if (k >= j) or (j > high) then
      break
    end
    if goes_before( array[ j ], workspace[ i ] )  then
      array[ k ] = array[ j ]
      j = j + 1
    else
      array[ k ] = workspace[ i ]
      i = i + 1
    end
    k = k + 1
  end
  -- Copy back any remaining elements of first half
  for k = k, j-1 do
    array[ k ] = workspace[ i ]
    i = i + 1
  end
end


function merge_sort( array, workspace, low, high, goes_before )
  if high - low < max_chunk_size then
    insertion_sort( array, low, high, goes_before )
  else
    local middle = math.floor((low + high)/2)
    merge_sort( array, workspace, low, middle, goes_before )
    merge_sort( array, workspace, middle + 1, high, goes_before )
    merge( array, workspace, low, middle, high, goes_before )
  end
end

function stable_sort( array, goes_before )
    local n = #array
    if n < 2 then return array end
    goes_before = goes_before or function (a, b)  return a < b  end
    local workspace = {}
    --  Allocate some room.
    workspace[ math.floor( (n+1)/2 ) ] = array[1]
    if goes_before(array[1],array[1]) then
        error"invalid order function for sorting"
    end
    merge_sort( array, workspace, 1, n, goes_before )
    return array
end
-- end of stable sorting function


--- Garbage Collection
--- -------------------
--- This is somewhat experimental. The idea is to remove all nodes from the
--- contents of the old value of that variable. Hopefully this has no
--- evil side effects. We'll find out....
function flush_table(tbl)
    for k,v in pairs(tbl) do
        if k == ".__context" or k == ".__parent" then
            -- nothing, to prevent infinite loops
        elseif type(v) == "table" then
            flush_table(v)
        elseif type(v) == "userdata" then
            node.flush_list(v)
        else
            k = nil
        end
    end
end

function flush_variable( varname )
    local x = xpath.get_variable(varname)
    if type(x) == "table" then
        flush_table(x)
    end
end


-- random string https://gist.github.com/haggen/2fd643ea9a261fea2094

local charset = {}

-- qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890
for i = 48,  57 do table.insert(charset, string.char(i)) end
for i = 65,  90 do table.insert(charset, string.char(i)) end
for i = 97, 122 do table.insert(charset, string.char(i)) end

function string_random(length)
  if length > 0 then
    return string_random(length - 1) .. charset[math.random(1, #charset)]
  else
    return ""
  end
end

function getuametadata()
    local docid = uuid()
    local instanceid = uuid()
    local now = pdf.getcreationdate()

    local isoformatted = string.format("%s-%s-%sT%s:%s:%s+%s:%s",string.sub(now,3,6),string.sub(now,7,8),string.sub(now,9,10),string.sub(now,11,12),string.sub(now,13,14),string.sub(now,15,16),string.sub(now,18,19),string.sub(now,21,22))

    md = string.format([[<?xpacket begin=%q id="W5M0MpCehiHzreSzNTczkc9d"?>
       <x:xmpmeta xmlns:x="adobe:ns:meta/">
      <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description rdf:about="" xmlns:xmpMM="http://ns.adobe.com/xap/1.0/mm/">
          <xmpMM:DocumentID>uuid:%s</xmpMM:DocumentID>
          <xmpMM:InstanceID>uuid:%s</xmpMM:InstanceID>
        </rdf:Description>
        <rdf:Description rdf:about="" xmlns:pdfuaid="http://www.aiim.org/pdfua/ns/id/">
          <pdfuaid:part>1</pdfuaid:part>
        </rdf:Description>
        <rdf:Description rdf:about="" xmlns:xmp="http://ns.adobe.com/xap/1.0/">
           <xmp:CreateDate>%s</xmp:CreateDate>
           <xmp:ModifyDate>%s</xmp:ModifyDate>
           <xmp:MetadataDate>%s</xmp:MetadataDate>
           <xmp:CreatorTool>%s</xmp:CreatorTool>
        </rdf:Description>
        <rdf:Description rdf:about="" xmlns:pdf="http://ns.adobe.com/pdf/1.3/">
          <pdf:Producer>speedata Publisher</pdf:Producer>
        </rdf:Description>
        <rdf:Description rdf:about="" xmlns:dc="http://purl.org/dc/elements/1.1/">
          <dc:title>
            <rdf:Alt>
              <rdf:li xml:lang="x-default">%s</rdf:li>
            </rdf:Alt>
          </dc:title>
        </rdf:Description>
      </rdf:RDF>
    </x:xmpmeta>
<?xpacket end="r"?>]],"\239\187\191",docid,instanceid, isoformatted,isoformatted,isoformatted,getcreator(),xml_escape(options.documenttitle))
    return md
end


function getmetadata()
    local now = pdf.getcreationdate()
    local isoformatted = string.format("%s-%s-%sT%s:%s:%s+%s:%s",string.sub(now,3,6),string.sub(now,7,8),string.sub(now,9,10),string.sub(now,11,12),string.sub(now,13,14),string.sub(now,15,16),string.sub(now,18,19),string.sub(now,21,22))
    local docid = uuid()
    local instanceid = uuid()
    local fmt = options.format
    local md = string.format([[<?xpacket begin=%q id="W5M0MpCehiHzreSzNTczkc9d"?>
<x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="Adobe XMP Core 5.6-c015 91.163280, 2018/06/22-11:31:03        ">
   <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
      <rdf:Description rdf:about=""
            xmlns:xmp="http://ns.adobe.com/xap/1.0/"
            xmlns:pdf="http://ns.adobe.com/pdf/1.3/"
            xmlns:dc="http://purl.org/dc/elements/1.1/"
            xmlns:xmpMM="http://ns.adobe.com/xap/1.0/mm/"
            xmlns:pdfxid="http://www.npes.org/pdfx/ns/id/"
            xmlns:pdfx="http://ns.adobe.com/pdfx/1.3/">
         <xmp:CreateDate>%s</xmp:CreateDate>
         <xmp:CreatorTool>%s</xmp:CreatorTool>
         <xmp:ModifyDate>%s</xmp:ModifyDate>
         <xmp:MetadataDate>%s</xmp:MetadataDate>
         <pdf:Trapped>False</pdf:Trapped>
         <dc:format>application/pdf</dc:format>
         <dc:title>
            <rdf:Alt>
               <rdf:li xml:lang="x-default">%s</rdf:li>
            </rdf:Alt>
         </dc:title>
         <xmpMM:DocumentID>uuid:%s</xmpMM:DocumentID>
         <xmpMM:InstanceID>uuid:%s</xmpMM:InstanceID>
         <xmpMM:RenditionClass>default</xmpMM:RenditionClass>
         <xmpMM:VersionID>1</xmpMM:VersionID>
         <pdfxid:GTS_PDFXVersion>%s</pdfxid:GTS_PDFXVersion>
         <pdfx:GTS_PDFXVersion>%s</pdfx:GTS_PDFXVersion>
      </rdf:Description>
   </rdf:RDF>
</x:xmpmeta>
]],"\239\187\191",isoformatted,getcreator(), isoformatted,isoformatted,xml_escape(options.documenttitle),docid,instanceid,fmt,fmt)
    return md
end

function getzugferdmetadata( conformancelevel, title, author )
    local metadata = string.format([[<?xpacket begin=%q id="W5M0MpCehiHzreSzNTczkc9d"?>
<x:xmpmeta xmlns:x="adobe:ns:meta/">
 <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <rdf:Description xmlns:pdfaid="http://www.aiim.org/pdfa/ns/id/" rdf:about="">
   <pdfaid:part>3</pdfaid:part>
   <pdfaid:conformance>B</pdfaid:conformance>
  </rdf:Description>
  <rdf:Description xmlns:dc="http://purl.org/dc/elements/1.1/" rdf:about="">
   <dc:title>
    <rdf:Alt>
     <rdf:li xml:lang="x-default">%s</rdf:li>
    </rdf:Alt>
   </dc:title>
   <dc:creator>
    <rdf:Seq>
    <rdf:li>%s</rdf:li>
</rdf:Seq>
   </dc:creator>
  <dc:description>
<rdf:Alt>
<rdf:li xml:lang="x-default"/>
</rdf:Alt>
</dc:description>
</rdf:Description>
  <rdf:Description xmlns:pdf="http://ns.adobe.com/pdf/1.3/" rdf:about="">
   <pdf:Producer>speedata Publisher</pdf:Producer>
  </rdf:Description>
  <rdf:Description xmlns:xmp="http://ns.adobe.com/xap/1.0/" rdf:about="">
   <xmp:CreatorTool>speedata invoicing platform</xmp:CreatorTool>
   <xmp:CreateDate>2014-06-24T14:01:21+02:00</xmp:CreateDate>
  <xmp:ModifyDate>2014-10-06T16:13:53+02:00</xmp:ModifyDate>
</rdf:Description>
 <rdf:Description xmlns:pdfaExtension="http://www.aiim.org/pdfa/ns/extension/" xmlns:pdfaField="http://www.aiim.org/pdfa/ns/field#" xmlns:pdfaProperty="http://www.aiim.org/pdfa/ns/property#" xmlns:pdfaSchema="http://www.aiim.org/pdfa/ns/schema#" xmlns:pdfaType="http://www.aiim.org/pdfa/ns/type#" rdf:about="">
<pdfaExtension:schemas>
<rdf:Bag>
<rdf:li rdf:parseType="Resource">
<pdfaSchema:schema>ZUGFeRD PDFA Extension Schema</pdfaSchema:schema>
<pdfaSchema:namespaceURI>urn:ferd:pdfa:CrossIndustryDocument:invoice:1p0#</pdfaSchema:namespaceURI>
<pdfaSchema:prefix>zf</pdfaSchema:prefix>
<pdfaSchema:property>
<rdf:Seq>
<rdf:li rdf:parseType="Resource">
<pdfaProperty:name>DocumentFileName</pdfaProperty:name>
<pdfaProperty:valueType>Text</pdfaProperty:valueType>
<pdfaProperty:category>external</pdfaProperty:category>
<pdfaProperty:description>name of the embedded XML invoice file</pdfaProperty:description>
</rdf:li>
<rdf:li rdf:parseType="Resource">
<pdfaProperty:name>DocumentType</pdfaProperty:name>
<pdfaProperty:valueType>Text</pdfaProperty:valueType>
<pdfaProperty:category>external</pdfaProperty:category>
<pdfaProperty:description>INVOICE</pdfaProperty:description>
</rdf:li>
<rdf:li rdf:parseType="Resource">
<pdfaProperty:name>Version</pdfaProperty:name>
<pdfaProperty:valueType>Text</pdfaProperty:valueType>
<pdfaProperty:category>external</pdfaProperty:category>
<pdfaProperty:description>The actual version of the ZUGFeRD data</pdfaProperty:description>
</rdf:li>
<rdf:li rdf:parseType="Resource">
<pdfaProperty:name>ConformanceLevel</pdfaProperty:name>
<pdfaProperty:valueType>Text</pdfaProperty:valueType>
<pdfaProperty:category>external</pdfaProperty:category>
<pdfaProperty:description>The conformance level of the ZUGFeRD data</pdfaProperty:description>
</rdf:li>
</rdf:Seq>
</pdfaSchema:property>
</rdf:li>
</rdf:Bag>
</pdfaExtension:schemas>
</rdf:Description>
<rdf:Description xmlns:zf="urn:ferd:pdfa:CrossIndustryDocument:invoice:1p0#"
  rdf:about="" zf:ConformanceLevel="%s" zf:DocumentFileName="ZUGFeRD-invoice.xml" zf:DocumentType="INVOICE" zf:Version="1.0"/>
</rdf:RDF>
</x:xmpmeta><?xpacket end="w"?>
]],"\239\187\191",title,author,conformancelevel)

    return metadata
end


function attach_file_pdf(zugferdcontents,description,mimetype,modificationtime,destfilename)

    local conformancelevel = string.match(zugferdcontents, "urn:ferd:CrossIndustryDocument:invoice:1p0:(.-)<")
    if not conformancelevel then
        err("No ZUGFeRD contents found")
        return
    else
        conformancelevel = string.upper(conformancelevel)
    end
    local fileobjectnum = pdf.immediateobj("stream",
        zugferdcontents,
        string.format([[/Params <</ModDate (%s)>> /Subtype /%s /Type /EmbeddedFile ]],
            pdfdate(modificationtime),
            escape_pdfname(mimetype)))

    local filespecnum = pdf.immediateobj(string.format([[<<
  /AFRelationship /Alternative
  /Desc %s
  /EF <<
    /F %d 0 R
    /UF %d 0 R
  >>
  /F (%s)
  /Type /Filespec
  /UF %s
>>]],utf8_to_utf16_string_pdf(description), fileobjectnum,fileobjectnum,destfilename,utf8_to_utf16_string_pdf(destfilename)))
        -- BASIC, COMFORT, EXTENDED
    local metadataobjnum = pdf.obj({type = "stream",
                 string = getzugferdmetadata(conformancelevel, options.documenttitle or "ZUGFeRD Rechnung",options.documentauthor or "The Author"),
                 immediate = true,
                 attr = [[  /Subtype /XML /Type /Metadata  ]],
                 compresslevel = 0,
                 })
    local afdatanum = pdf.immediateobj( string.format("[ %d 0 R ]",filespecnum))
    filespecnumbers[#filespecnumbers + 1] = {filespecnum,metadataobjnum,afdatanum}
end

-- %a  abbreviated weekday name (e.g., Wed)
-- %A  full weekday name (e.g., Wednesday)
-- %b  abbreviated month name (e.g., Sep)
-- %B  full month name (e.g., September)
-- %c  date and time (e.g., 09/16/98 23:48:10)
-- %d  day of the month (16) [01-31]
-- %H  hour, using a 24-hour clock (23) [00-23]
-- %I  hour, using a 12-hour clock (11) [01-12]
-- %M  minute (48) [00-59]
-- %m  month (09) [01-12]
-- %p  either "am" or "pm" (pm)
-- %S  second (10) [00-61]
-- %w  weekday (3) [0-6 = Sunday-Saturday]
-- %x  date (e.g., 09/16/98)
-- %X  time (e.g., 23:48:10)
-- %Y  full year (1998)
-- %y  two-digit year (98) [00-99]
-- %%  the character `%´

-- Return a string that is a valid PDF date entry such as "D:20170721195500+02'00'"
-- Input is an epoch number such as 1500645681
function pdfdate(num)
    local ret = os.date("D:%Y%m%d%H%M%S+00'00'",num)
    return ret
end

function escape_pdfstring( str )
    str = string.gsub(str,"%(","\\(")
    str = string.gsub(str,"%)","\\)")
    return str
end

function escape_pdfname( str )
    return string.gsub(str,'/','#2f')
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
    harfbuzz.shape_full(font, buf, tbl.otfeatures, {})
    if bufdir == "rtl" then
        buf:reverse()
    end
    return bufscript,bufdir
end



file_end("publisher.lua")

