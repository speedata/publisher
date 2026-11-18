--
--  html.lua
--  speedata publisher
--  new HTML parser
--
--  for a list of authors see `git blame'
--  see file copying in the root directory for license info.

-- This is for the new HTML parser

local publisher = require("publisher")

local links_module = require("publisher.links")

local fonts = require("html.fonts")
require("html.images")
local inherit = require("html.inherit")
local inline_images = require("html.inline_images")
local inline_options = require("html.inline_options")
local inline_utils = require("html.inline_utils")
local lists = require("html.lists")
require("html.pages")
require("html.strings")
local styles_mod = require("html.styles")
local tables_mod = require("html.tables")
local tree = require("html.tree")
local units = require("html.units")

---@class html_module
local M = {}
require("box")

---@type table<string, integer>
local fontfamilies = {}

local inherited = {
    width = false,
    fontsize_sp = true,
    rootfontsize_sp = true,
    lineheight_sp = true,
    calculated_width = true,
    ollevel = true,
    ullevel = true,
    listlevel = true,
    listindent = true,
    olullisttype = true,
    hyphens = true,
    currentcolor = true,
    ["border-collapse"] = true,
    ["border-spacing"] = true,
    ["caption-side"] = true,
    ["color"] = true,
    ["direction"] = true,
    ["empty-cells"] = true,
    ["font-family"] = true,
    ["font-family-number"] = true, -- for internal html mode
    ["font-size"] = true,
    ["font-style"] = true,
    ["font-variant"] = true,
    ["font-weight"] = true,
    ["font"] = true,
    ["letter-spacing"] = true,
    ["line-height"] = true,
    ["list-style-image"] = true,
    ["list-style-position"] = true,
    ["list-style-type"] = true,
    ["list-style"] = true,
    ["orphans"] = true,
    ["quotes"] = true,
    ["richness"] = true,
    ["text-align"] = true,
    ["text-decoration-line"] = true,
    ["text-decoration-style"] = true,
    ["text-decoration-color"] = true,
    ["text-indent"] = true,
    ["text-transform"] = true,
    ["visibility"] = true,
    ["white-space"] = true,
    ["widows"] = true,
    ["word-spacing"] = true,
}

local stylesstack = inherit.new_stack(inherited)

-- <h1>  Header 1</h1>
-- atext<em>in em</em>texttext<b><i>bolditalic</i> justbold </b>
-- <h2>Header 2</h2>

-- is transformed into

-- elt = {
--     ["direction"] = "↓",
--     ["elementname"] = "body",
--     [1] = {
--         ["direction"] = "↓",
--         ["elementname"] = "h1",
--         [1] = {
--             mode = horizontal,
--             [1] = " Header 1"
--         }
--     },
--     [2] = {
--         mode = horizontal,
--         [1] = " atext",
--         [2] = {
--             ["direction"] = "→",
--             ["elementname"] = "em",
--             [1] = "in em"
--         },
--         [3] = "texttext",
--         [4] = {
--             ["direction"] = "→",
--             ["elementname"] = "b",
--             [1] = {
--                 ["direction"] = "→",
--                 ["elementname"] = "i",
--                 [1] = "bolditalic"
--             },
--             [2] = " justbold "
--         },
--         [5] = " "
--     },
--     [3] = {
--         ["direction"] = "↓",
--         ["elementname"] = "h2",
--         [1] = {
--             mode = horizontal,
--             [1] = " Header 2"
--         }
--     }
-- }
-- (attributes not shown)

-- Splits the styles of an element into its own styles and the styles of
-- its pseudo-elements (keys like "before::content"). The element is not
-- changed, so its tree can be rendered more than once.
---@param eltstyles table<string, any> Computed styles of the element.
---@return table<string, any> own Styles of the element itself.
---@return table<string, table<string, any>> pseudo Styles per pseudo-element ("before", "after", "marker").
local function split_pseudo_styles(eltstyles)
    local own, pseudo = {}, {}
    for k, v in pairs(eltstyles) do
        local pseudoname, rawstyle = string.match(k, "^(%a+)::(.*)$")
        if pseudoname then
            pseudo[pseudoname] = pseudo[pseudoname] or {}
            pseudo[pseudoname][rawstyle] = v
        else
            own[k] = v
        end
    end
    return own, pseudo
end

-- Pushes the styles of a ::before or ::after pseudo-element onto the
-- styles stack and builds its nodes. The styles of the element must be
-- on top of the stack, the pseudo-element inherits from them. The caller
-- pops the styles again.
---@param pseudo_styles table<string, any> Declarations of the pseudo-element.
---@param name string Element and pseudo-element, e.g. "i::before" (for messages).
---@param options table Options of the element (copied, not changed).
---@return Node? nodes Nodes of the content, nil if there is no content (then there is no pseudo-element).
---@return HtmlStyles pstyles Styles of the pseudo-element.
local function push_pseudo_element(pseudo_styles, name, options)
    local pstyles = inherit.push(stylesstack)
    styles_mod.copy_attributes(pstyles, pseudo_styles, name)
    -- A font-family of its own must be resolved again, otherwise the font
    -- family number inherited from the element wins.
    if pseudo_styles["font-family"] and not pseudo_styles["font-family-number"] then
        pstyles["font-family-number"] = 0
    end
    local pseudo_options = {}
    for k, v in pairs(options) do
        pseudo_options[k] = v
    end
    inline_options.set_options_for_mknodes(pstyles, pseudo_options, publisher, fontfamilies)
    local content = pstyles.content
    if not content or content == "" then
        return nil, pstyles
    end
    return publisher.nodes.mknodes(content, pseudo_options), pstyles
end

local inline_box_counter = 0

-- Returns a rule of width `wd` without height and depth. Unlike a kern, it
-- is not discarded at the beginning of a line. It gets the background
-- color of `opts`, so that the background covers it.
---@param wd integer
---@param origin string
---@param opts table Options with backgroundcolor and bg_padding_top/bottom (from inline_options).
---@return Node
local function spacer(wd, origin, opts)
    local r = node.new(publisher.rule_node)
    r.width = wd
    r.height = 0
    r.depth = 0
    publisher.attribute_helpers.setprop(r, "origin", origin)
    if opts.backgroundcolor then
        local attnum = publisher.attribute_name_number
        node.set_attribute(r, attnum["background-color"], opts.backgroundcolor)
        node.set_attribute(r, attnum["bgpaddingtop"], tex.sp(opts.bg_padding_top or 0))
        node.set_attribute(r, attnum["bgpaddingbottom"], tex.sp(opts.bg_padding_bottom or 0))
    end
    return r
end

-- The font of the text of an element (the variant for bold and italic).
---@param options table Options from inline_options.set_options_for_mknodes.
---@return table? font The font table (see fonts/fontloader.lua).
local function font_of(options)
    if not options.fontfamily then
        return nil
    end
    local variant = "normal"
    if options.bold and options.italic then
        variant = "bolditalic"
    elseif options.bold then
        variant = "bold"
    elseif options.italic then
        variant = "italic"
    end
    local instance = publisher.fonts.get_fontinstance(options.fontfamily, variant)
    return publisher.fonts.used_fonts[instance]
end

-- The depth of a line box with the line height `lineheight` for the font
-- of the element. As in the browser the line box is centered on the area
-- between the descender and the ascender of the font, so it does not
-- depend on the letters inside.
---@param options table
---@param lineheight integer
---@return integer?
local function linebox_depth(options, lineheight)
    local f = font_of(options)
    if f and f.ascender and f.descender then
        local halfleading = (f.ascender + f.descender - lineheight) / 2
        return math.round(f.descender - halfleading)
    end
    return nil
end

-- The rules in front of and after the content of an inline element: they
-- have the width of the horizontal border and padding. For an element
-- with border or background (see inline_options.is_boxed), the first rule
-- carries the border properties (borderstart) and the second ends the
-- border (borderend with the same id). The border and the background are
-- drawn at shipout, see nodes.insert_nonmoving_whatsits and
-- publisher.htmlbox; they are `lineheight` high plus the vertical padding
-- and border.
---@param styles HtmlStyles
---@param options table The options of the element (with options.border if it is boxed).
---@param lineheight integer
---@return Node? startrule nil if the element has no border and no horizontal padding.
---@return Node? endrule
local function inline_box_rules(styles, options, lineheight)
    local fs = styles.fontsize_sp
    local border = inline_options.is_boxed(styles) and options.border or nil
    local left, right
    if border then
        left = border.border_left_width + border.padding_left
        right = border.border_right_width + border.padding_right
    else
        left = units.getsize(styles, styles["padding-left"], fs)
        right = units.getsize(styles, styles["padding-right"], fs)
    end
    if not border and left == 0 and right == 0 then
        return nil, nil
    end
    -- the background covers the padding, not the margin
    local startrule = spacer(left, "inline border start", options)
    local endrule = spacer(right, "inline border end", options)
    if border then
        inline_box_counter = inline_box_counter + 1
        local setprop = publisher.attribute_helpers.setprop
        setprop(startrule, "borderstart", inline_box_counter)
        setprop(startrule, "lineheight", lineheight)
        local depth = linebox_depth(options, lineheight)
        if depth then
            setprop(startrule, "depth", depth)
        end
        for index, value in pairs(border) do
            if index ~= "borderstart" then
                setprop(startrule, index, value)
            end
        end
        setprop(endrule, "borderend", inline_box_counter)
    end
    return startrule, endrule
end

-- Adds the horizontal margin, border and padding of an inline element
-- around its runs, as in the browser: they take space in the line, the
-- vertical ones do not. The border is split at line breaks, see
-- split_inline_borders. The border box is one font size high (as with
-- line-height 1).
---@param runs table[] The runs of the element, changed in place.
---@param styles HtmlStyles
---@param options table The options of the element (with options.border if it has a border).
---@param parent_options table The options of the parent, for the background of the margin.
local function add_inline_box(runs, styles, options, parent_options)
    local fs = styles.fontsize_sp
    local margin_left = units.getsize(styles, styles["margin-left"], fs)
    local margin_right = units.getsize(styles, styles["margin-right"], fs)
    local fam = publisher.fonts.lookup_fontfamily_number_instance[options.fontfamily]
    local startrule, endrule = inline_box_rules(styles, options, fam and fam.size or fs)
    if not startrule and margin_left == 0 and margin_right == 0 then
        return
    end
    local first, last = {}, {}
    if margin_left ~= 0 then
        first[#first + 1] = spacer(margin_left, "inline margin-left", parent_options)
    end
    if startrule then
        first[#first + 1] = startrule
        last[#last + 1] = endrule
    end
    if margin_right ~= 0 then
        last[#last + 1] = spacer(margin_right, "inline margin-right", parent_options)
    end
    if #first > 0 then
        local head = first[1]
        for i = 2, #first do
            node.insert_after(head, node.tail(head), first[i])
        end
        table.insert(runs, 1, head)
    end
    if #last > 0 then
        local head = last[1]
        for i = 2, #last do
            node.insert_after(head, node.tail(head), last[i])
        end
        runs[#runs + 1] = head
    end
end

-- The x-height (height of the letter x) at the font size `size`, taken
-- from the font of `options` (for vertical-align: middle).
---@param options table
---@param size integer
---@return integer
local function x_height(options, size)
    local f = font_of(options)
    if f and f.characters and f.size > 0 then
        local x = f.characters[120]
        if x and x.height then
            return math.round(x.height / f.size * size)
        end
    end
    return math.round(size / 2)
end

-- Turns the runs of an element with display: inline-block into one box
-- that does not break across lines (as in the browser for a single line
-- of contents). The box gets the vertical padding and border as height,
-- so the line makes room for it. Its content is line-height high and at
-- least min-width (or width) wide; text-align places narrower contents.
-- vertical-align: middle centers the box on the middle of the x-height of
-- the parent.
---@param runs table[] The runs of the element.
---@param styles HtmlStyles
---@param options table The options of the element.
---@param parent_options table The options of the parent.
---@return table[] runs The new runs: margins and the box.
local function make_inline_block(runs, styles, options, parent_options)
    local fs = styles.fontsize_sp or 0
    local head
    for i = 1, #runs do
        local r = runs[i]
        if type(r) == "string" then
            r = publisher.nodes.mknodes(r, options)
        end
        if r then
            if head then
                node.insert_after(head, node.tail(head), r)
            else
                head = r
            end
        end
    end
    if head then
        head = inline_utils.trim_space_beginning(head)
    end
    if head then
        head = inline_utils.trim_space_end(head)
    end
    -- load the fonts before measuring
    if head then
        publisher.fonts.pre_linebreak(head)
    end

    local lineheight = fonts.lineheight(styles, fs)
    local depth = linebox_depth(options, lineheight) or math.round(lineheight / 4)

    -- width of the content: at least width and min-width
    local natural = head and node.dimensions(head) or 0
    local target = 0
    local width = styles.width
    if width and width ~= "auto" then
        target = units.getsize(styles, width, fs)
    end
    local min_width = styles["min-width"]
    if min_width and min_width ~= "auto" then
        target = math.max(target, units.getsize(styles, min_width, fs))
    end
    local extra = math.max(0, target - natural)
    local before, after = 0, extra
    local align = styles["text-align"]
    if align == "center" then
        before = math.floor(extra / 2)
        after = extra - before
    elseif align == "right" or align == "end" then
        before, after = extra, 0
    end
    if before > 0 then
        head = node.insert_before(head, head, spacer(before, "inline-block align", options))
    end
    if after > 0 then
        local s = spacer(after, "inline-block align", options)
        if head then
            node.insert_after(head, node.tail(head), s)
        else
            head = s
        end
    end

    -- vertical padding and border
    local border = inline_options.is_boxed(styles) and options.border or nil
    local top, bottom
    if border then
        top = border.border_top_width + border.padding_top
        bottom = border.border_bottom_width + border.padding_bottom
    else
        top = units.getsize(styles, styles["padding-top"], fs)
        bottom = units.getsize(styles, styles["padding-bottom"], fs)
    end
    local strut = node.new(publisher.rule_node)
    strut.width = 0
    strut.height = lineheight - depth + top
    strut.depth = depth + bottom
    publisher.attribute_helpers.setprop(strut, "origin", "inline-block strut")
    if head then
        head = node.insert_before(head, head, strut)
    else
        head = strut
    end

    local startrule, endrule = inline_box_rules(styles, options, lineheight)
    if startrule and endrule then
        head = node.insert_before(head, head, startrule)
        node.insert_after(head, assert(node.tail(head)), endrule)
    end
    local box = node.hpack(head)
    publisher.attribute_helpers.setprop(box, "origin", "inline-block")
    -- the line takes the height and depth of the box (see do_linebreak)
    publisher.attribute_helpers.setprop(box, "inlineblock", true)
    node.set_attribute(box, publisher.att_ignore_orphan_widowsetting, 1)

    if styles["vertical-align"] == "middle" then
        -- the parent font: the font of the element at the size of the parent
        local parent_styles = stylesstack._stack[styles.pos - 1]
        local parent_size = parent_styles and parent_styles.fontsize_sp or fs
        box.shift = math.round((box.height - box.depth) / 2 - x_height(options, parent_size) / 2)
    end

    local ret = {}
    local margin_left = units.getsize(styles, styles["margin-left"], fs)
    local margin_right = units.getsize(styles, styles["margin-right"], fs)
    if margin_left ~= 0 then
        ret[#ret + 1] = spacer(margin_left, "inline margin-left", parent_options)
    end
    ret[#ret + 1] = box
    if margin_right ~= 0 then
        ret[#ret + 1] = spacer(margin_right, "inline margin-right", parent_options)
    end
    return ret
end

-- Recursive part of collect_horizontal_nodes. pending.box is the
-- ::before box of the enclosing block. It goes in front of the first
-- run that is created and is then removed from pending.
---@param elt table HTML element subtree.
---@param parameter table Inherited style parameters.
---@param pending { box: Node? } The ::before box not yet placed.
---@param dataxml table Data XML context.
---@return table[] runs Array of inline node lists.
local function collect_runs(elt, parameter, pending, dataxml)
    if elt.elementname == "br" then
        local nodes = publisher.nodes.mknodes("\n", parameter)
        return { nodes }
    end
    local ret = {}
    for i = 1, #elt do
        local styles = inherit.push(stylesstack)

        local options = {}
        for k, v in pairs(parameter) do
            options[k] = v
        end
        local thiselt = elt[i]
        local typ = type(thiselt)

        local thiselt_styles, pseudo = split_pseudo_styles(thiselt.styles or {})
        styles_mod.copy_attributes(styles, thiselt_styles, thiselt.elementname or "(string)")

        inline_options.set_options_for_mknodes(styles, options, publisher, fontfamilies)

        local thisret = {}
        if typ == "string" then
            local nodes = publisher.nodes.mknodes(thiselt, options)
            if pending.box then
                nodes = node.insert_before(nodes, nodes, pending.box)
                pending.box = nil
            end
            publisher.attribute_helpers.setprop(nodes, "direction", elt.direction)
            thisret[#thisret + 1] = nodes
        elseif typ == "table" then
            local attributes = thiselt.attributes or {}
            local eltname = thiselt.elementname
            if eltname == "a" then
                local href = attributes["href"]
                options.add_attributes = { { "hyperlink", links_module.hlurl(publisher.options, href) } }
            end
            if pseudo.before and eltname ~= "img" then
                local nodes = push_pseudo_element(pseudo.before, eltname .. "::before", options)
                inherit.pop(stylesstack)
                if nodes then
                    if pending.box then
                        nodes = node.insert_before(nodes, nodes, pending.box)
                        pending.box = nil
                    end
                    publisher.attribute_helpers.setprop(nodes, "direction", thiselt.direction)
                    thisret[#thisret + 1] = nodes
                end
            end
            if eltname == "img" then
                local box = inline_images.build_image_box(styles, attributes, dataxml)
                thisret[#thisret + 1] = box
            elseif eltname == "wbr" then
                thisret[#thisret + 1] = "\xE2\x80\x8B"
            end
            local n = collect_runs(thiselt, options, pending, dataxml)
            for j = 1, #n do
                thisret[#thisret + 1] = n[j]
            end
            if pseudo.after and eltname ~= "img" then
                local nodes = push_pseudo_element(pseudo.after, eltname .. "::after", options)
                inherit.pop(stylesstack)
                if nodes then
                    publisher.attribute_helpers.setprop(nodes, "direction", thiselt.direction)
                    thisret[#thisret + 1] = nodes
                end
            end
        end

        if typ == "table" then
            if styles.display == "inline-block" and thiselt.elementname ~= "img" then
                thisret = make_inline_block(thisret, styles, options, parameter)
            else
                add_inline_box(thisret, styles, options, parameter)
            end
        end

        for j = 1, #thisret do
            ret[#ret + 1] = thisret[j]
        end
        inherit.pop(stylesstack)
    end
    return ret
end

-- Collects the horizontal node lists for an inline element subtree.
-- Returns an array of node lists (one per inline run) so the caller can
-- pack them into a paragraph.
---@param elt table HTML element subtree (with `elementname`, children).
---@param parameter? table Inherited style parameters.
---@param before_box? Node The ::before box of the enclosing block, placed in front of the first run.
---@param _origin? string Caller identifier (debugging).
---@param dataxml table Data XML context.
---@return table[] runs Array of inline node lists.
function M.collect_horizontal_nodes(elt, parameter, before_box, _origin, dataxml)
    -- w("collect_horizontal_nodes %s",_origin or "?")
    local pending = { box = before_box }
    local ret = collect_runs(elt, parameter or {}, pending, dataxml)
    -- no text in the block (for example only an image): the box is a run of its own
    if pending.box then
        table.insert(ret, 1, pending.box)
    end
    return ret
end

local olcounter = {}
local oltype = {}

-- Recursively builds the node list for a (block-level) HTML element
-- subtree. Dispatches to inline collection, table layout, list rendering
-- or image embedding based on the element kind.
---@param elt table HTML element subtree.
---@param options? table Inherited style options.
---@param before_box? Node Whether the element starts a fresh box.
---@param _caller? string Caller identifier (debugging).
---@param prevdir? "horizontal"|"vertical" Previous run's direction.
---@param dataxml table Data XML context.
---@return any[] ret Nested array of boxes and paragraphs.
---@return ("horizontal"|"vertical")? prevdir Direction after the last processed element.
function M.build_nodelist(elt, options, before_box, _caller, prevdir, dataxml)
    -- w("html: build nodelist from %s, prevdir = %s", _caller or "?",prevdir or "?")
    options = options or {}
    -- ret is a nested table of boxes and paragraphs
    local ret = {}
    for i = 1, #elt do
        local thiselt = elt[i]
        local thiseltname = thiselt.elementname
        local styles = inherit.push(stylesstack)
        if thiseltname == "body" then
            styles.ollevel = 0
            styles.ullevel = 0
            styles.listlevel = 0
        end

        local thiselt_styles, pseudo = split_pseudo_styles(thiselt.styles or {})
        local marker_styles = pseudo.marker or {}
        local has_marker_styles = pseudo.marker ~= nil

        styles_mod.copy_attributes(styles, thiselt_styles, thiseltname)
        local styles_fontsize_sp = styles.fontsize_sp
        if thiseltname == "html" then
            styles.rootfontsize_sp = styles.fontsize_sp
        end

        if pseudo.before then
            local nl, bstyles = push_pseudo_element(pseudo.before, thiseltname .. "::before", {})
            if nl then
                local margin_left = units.getsize(bstyles, bstyles["margin-left"], bstyles.fontsize_sp)

                local hss = publisher.nodes.hss_glue()
                local ml_box = node.hpack(hss, margin_left, "exactly")

                if bstyles.width then
                    local tail = node.tail(nl)
                    node.insert_after(nl, tail, publisher.nodes.hss_glue())
                    nl = node.hpack(nl, bstyles.calculated_width, "exactly")
                end

                -- nl can be a list (for example glyph and space), so link
                -- it instead of node.insert_after, which inserts one node
                ml_box.next = nl
                nl.prev = ml_box
                before_box = node.hpack(ml_box)
            end
            inherit.pop(stylesstack)
        end
        local margin_top = units.getsize(styles, styles["margin-top"], styles_fontsize_sp)
        local margin_right = units.getsize(styles, styles["margin-right"], styles_fontsize_sp)
        local margin_bottom = units.getsize(styles, styles["margin-bottom"], styles_fontsize_sp)
        local margin_left = units.getsize(styles, styles["margin-left"], styles_fontsize_sp)

        local padding_top = units.getsize(styles, styles["padding-top"], styles_fontsize_sp)
        local padding_right = units.getsize(styles, styles["padding-right"], styles_fontsize_sp)
        local padding_bottom = units.getsize(styles, styles["padding-bottom"], styles_fontsize_sp)
        local padding_left = units.getsize(styles, styles["padding-left"], styles_fontsize_sp)

        local border_top_style = thiselt_styles["border-top-style"] or "none"
        local border_right_style = thiselt_styles["border-right-style"] or "none"
        local border_bottom_style = thiselt_styles["border-bottom-style"] or "none"
        local border_left_style = thiselt_styles["border-left-style"] or "none"

        local border_top_width = units.getsize(styles, styles["border-top-width"], styles_fontsize_sp)
        local border_right_width = units.getsize(styles, styles["border-right-width"], styles_fontsize_sp)
        local border_bottom_width = units.getsize(styles, styles["border-bottom-width"], styles_fontsize_sp)
        local border_left_width = units.getsize(styles, styles["border-left-width"], styles_fontsize_sp)

        local border_top_color = styles["border-top-color"]
        local border_right_color = styles["border-right-color"]
        local border_bottom_color = styles["border-bottom-color"]
        local border_left_color = styles["border-left-color"]

        border_top_color = border_top_color or styles.color or "black"
        border_right_color = border_right_color or styles.color or "black"
        border_bottom_color = border_bottom_color or styles.color or "black"
        border_left_color = border_left_color or styles.color or "black"

        local border_bottom_right_radius = thiselt_styles["border-bottom-right-radius"] or 0
        local border_bottom_left_radius = thiselt_styles["border-bottom-left-radius"] or 0
        local border_top_right_radius = thiselt_styles["border-top-right-radius"] or 0
        local border_top_left_radius = thiselt_styles["border-top-left-radius"] or 0

        local fontfamily = styles["font-family"]
        local fontsize = styles["font-size"]
        local fontname = fontsize
        local fam = fonts.get_fontfamily(fontfamily, styles.fontsize_sp, fontname, styles, publisher, fontfamilies)

        local textalign = styles["text-align"]
        local hyphens = styles.hyphens
        local break_before = styles["break-before"]
        local break_after = styles["break-after"]
        local alignment = "leftaligned"
        if textalign == "right" then
            alignment = "rightaligned"
        elseif textalign == "center" then
            alignment = "centered"
        elseif textalign == "justify" then
            alignment = "justified"
        end

        if thiselt.mode == "horizontal" then
            ---@type Textformat
            local tf
            -- when called from Paragraph, we use that textformat
            if options.override_alignment then
                tf = options.textformat
            else
                tf = publisher.dispatch.new_textformat("", "text", { alignment = alignment })
            end
            if hyphens == "none" or hyphens == "manual" then
                tf.disable_hyphenation = true
            end
            if break_before == "page" or break_before == "always" then
                tf.break_before = break_before
            end
            if break_after == "avoid" then
                tf.breakbelow = false
            end
            options.textformat = tf
            local n =
                M.collect_horizontal_nodes(thiselt, options, before_box, "build nodelist horizontal mode", dataxml)
            before_box = nil

            local a = publisher.par:new(tf, "html.lua (horizontal)")
            local appended = false
            for j = 1, #n do
                local thisn = n[j]
                if j == 1 then
                    thisn = inline_utils.trim_space_beginning(thisn)
                elseif j == #n then
                    thisn = inline_utils.trim_space_end(thisn)
                end
                if thisn then
                    appended = true
                    a:append(thisn)
                end
            end
            if appended then
                prevdir = "horizontal"
                ret[#ret + 1] = a
            end
        else
            local box = Box:new()
            box.eltname = thiseltname
            box.margintop = margin_top or 0
            box.marginbottom = margin_bottom or 0
            -- a border without style has no width
            if border_top_style == "none" or border_top_style == "hidden" then
                border_top_width = 0
            end
            if border_right_style == "none" or border_right_style == "hidden" then
                border_right_width = 0
            end
            if border_bottom_style == "none" or border_bottom_style == "hidden" then
                border_bottom_width = 0
            end
            if border_left_style == "none" or border_left_style == "hidden" then
                border_left_width = 0
            end
            -- styles.calculated_width is the content width of the parent
            -- unless the element has a width of its own.
            local content_width = styles.calculated_width
            if not thiselt_styles.width or thiselt_styles.width == "auto" then
                content_width = styles.calculated_width
                    - margin_left
                    - border_left_width
                    - padding_left
                    - padding_right
                    - border_right_width
                    - margin_right
            end
            styles.calculated_width = content_width
            box.width = content_width
            box.indent_amount = margin_left + border_left_width + padding_left
            if break_before == "page" or break_before == "always" then
                box.break_before = break_before
            end
            if break_after == "avoid" then
                box.break_after = "avoid"
            end
            if thiseltname ~= "table" then
                local background = thiselt_styles["background-color"]
                if background == "transparent" then
                    background = nil
                end
                local content_height
                if thiselt_styles.height and thiselt_styles.height ~= "auto" then
                    content_height = units.getsize(styles, thiselt_styles.height, styles_fontsize_sp)
                end
                ---@type CSSBlock
                box.css = {
                    x = margin_left,
                    width = border_left_width + padding_left + content_width + padding_right + border_right_width,
                    border_top_width = border_top_width,
                    border_bottom_width = border_bottom_width,
                    padding_top = padding_top,
                    padding_bottom = padding_bottom,
                    height = content_height,
                }
                if background or thiselt_styles.has_border then
                    box.css.decoration = {
                        top = { width = border_top_width, style = border_top_style, color = border_top_color },
                        right = { width = border_right_width, style = border_right_style, color = border_right_color },
                        bottom = {
                            width = border_bottom_width,
                            style = border_bottom_style,
                            color = border_bottom_color,
                        },
                        left = { width = border_left_width, style = border_left_style, color = border_left_color },
                        radius_tl = units.getsize(styles, border_top_left_radius, styles_fontsize_sp),
                        radius_tr = units.getsize(styles, border_top_right_radius, styles_fontsize_sp),
                        radius_br = units.getsize(styles, border_bottom_right_radius, styles_fontsize_sp),
                        radius_bl = units.getsize(styles, border_bottom_left_radius, styles_fontsize_sp),
                        background = background,
                    }
                end
            end

            if thiseltname == "table" then
                prevdir = "vertical"
                -- w("html/table")
                local wd = styles.calculated_width
                local nl_array = tables_mod.build_html_table(thiselt, wd, {
                    -- callback which uses the existing build_nodelist
                    build_nodelist = function(...)
                        return M.build_nodelist(...)
                    end,
                }, dataxml, stylesstack)

                -- Handle case where table has no content (returns single node)
                if type(nl_array) == "userdata" then
                    -- Single node (e.g., empty table) - skip adding to box
                    -- The table warning is already issued by tabular.lua
                elseif type(nl_array) == "table" then
                    -- Process all table parts (for multi-page tables)
                    for part = 1, #nl_array do
                        local nl = nl_array[part]
                        local tabpar = publisher.par:new(nil, "html table (a)")
                        -- Only apply margin_top to the first table part
                        if part == 1 then
                            tabpar.margin_top = margin_top
                        end
                        node.set_attribute(nl, publisher.att_lineheight, nl.height)
                        publisher.attribute_helpers.setprop(nl, "origin", "html table")
                        tabpar:append(nl, { dontformat = true })
                        box[#box + 1] = tabpar
                    end
                    ret[#ret + 1] = box
                end
            elseif thiseltname == "ol" or thiseltname == "ul" then
                prevdir = "vertical"
                styles.olullisttype = thiseltname
                styles.listindent = padding_left
                styles.listlevel = styles.listlevel + 1
                if thiseltname == "ol" then
                    styles.ollevel = styles.ollevel + 1
                else
                    styles.ullevel = styles.ullevel + 1
                end
                local attribs = thiselt.attributes
                oltype[styles.listlevel] = nil
                olcounter[styles.listlevel] = 0
                if attribs then
                    if attribs.start then
                        local j = math.tointeger(attribs.start - 1)
                        olcounter[styles.listlevel] = j
                    else
                        olcounter[styles.listlevel] = 0
                    end
                    if attribs.type then
                        oltype[styles.listlevel] = attribs.type
                    end
                end
                local n
                n, prevdir = M.build_nodelist(thiselt, options, before_box, "build_nodelist/ ol/ul", prevdir, dataxml)
                before_box = nil
                if thiseltname == "ol" then
                    styles.ollevel = styles.ollevel - 1
                else
                    styles.ullevel = styles.ullevel - 1
                end
                styles.listlevel = styles.listlevel - 1
                for j = 1, #n do
                    box[#box + 1] = n[j]
                    box[#box].mode = "block"
                end
                ret[#ret + 1] = box
            elseif thiseltname == "li" then
                prevdir = "vertical"
                olcounter[styles.listlevel] = olcounter[styles.listlevel] or 0
                olcounter[styles.listlevel] = olcounter[styles.listlevel] + 1
                local n
                n, prevdir = M.build_nodelist(thiselt, options, before_box, "build_nodelist/ li", prevdir, dataxml)
                before_box = nil
                -- n is a table of box and / or par
                -- ::marker content overrides list-style-type
                local str
                if has_marker_styles and marker_styles.content then
                    str = marker_styles.content
                else
                    str = lists.resolve_list_style_type(styles, olcounter, oltype[styles.listlevel], dataxml)
                end
                local pos = styles["list-style-position"] or "outside"
                for j = 1, #n do
                    local a = n[j]
                    -- Apply ::marker styles to the marker options
                    local marker_opt
                    if has_marker_styles then
                        local ms = inherit.push(stylesstack)
                        styles_mod.copy_attributes(ms, marker_styles, "li::marker")
                        -- An inherited font family number gets the marker
                        -- size in get_fontfamily.
                        if marker_styles["font-family"] then
                            ms["font-family-number"] = 0
                        end
                        marker_opt = inline_options.set_options_for_mknodes(ms, {}, publisher, fontfamilies)
                        if marker_styles["padding-bottom"] then
                            marker_opt.marker_shift =
                                -units.getsize(ms, marker_styles["padding-bottom"], ms.fontsize_sp)
                        end
                        inherit.pop(stylesstack)
                    else
                        marker_opt = inline_options.set_options_for_mknodes(styles, {}, publisher, fontfamilies)
                    end
                    if pos == "inside" then
                        local nl = publisher.nodes.mknodes(str .. " ", marker_opt)
                        nl = node.hpack(nl)
                        local a_head = a[1].contents
                        a_head = node.insert_before(a_head, a_head, nl)
                        a[1].contents = a_head
                    else
                        local wd = styles.listindent
                        local labeldistance
                        if has_marker_styles and marker_styles["padding-right"] then
                            labeldistance = units.getsize(styles, marker_styles["padding-right"], styles.fontsize_sp)
                        end
                        local x = { str, wd, marker_opt, labeldistance }
                        a:prepend(x)
                    end
                    -- label only for the first
                    str = ""
                    ret[#ret + 1] = a
                end
            elseif thiseltname == "br" then
                local a = publisher.par:new(nil, "html.lua (br)")
                local list
                if prevdir == "vertical" then
                    list = publisher.nodes.newline(fam)
                else
                    list = publisher.nodes.short_newline(fam)
                end
                publisher.attribute_helpers.setprop(list, "br", true)
                a:append(list)
                ret[#ret + 1] = a
                prevdir = "vertical"
            elseif thiseltname == "hr" then
                -- the border is drawn around the (usually empty) content
                local ht = units.getsize(styles, styles.height, styles.fontsize_sp)
                local bx = publisher.nodes.create_empty_vbox_width_width_height(styles.calculated_width, ht)
                local a = publisher.par:new(nil, "html.lua (hr)")
                a:append(bx)
                box[#box + 1] = a
                ret[#ret + 1] = box
            else
                local n
                local nloptions = publisher.utilities.copy_table_from_defaults(options)
                if thiseltname == "h1" then
                    nloptions.role = publisher.structure_tree.get_rolenum("H1")
                elseif thiseltname == "p" then
                    nloptions.role = publisher.structure_tree.get_rolenum("P")
                end
                n, prevdir = M.build_nodelist(
                    thiselt,
                    options,
                    before_box,
                    string.format("build_nodelist/ any element name %q", thiseltname),
                    prevdir,
                    dataxml
                )
                if thiselt.block then
                    prevdir = "vertical"
                end
                -- without content nothing has placed the ::before box yet
                local unplaced_before = #thiselt == 0 and before_box or nil
                before_box = nil
                if pseudo.after then
                    local nl = push_pseudo_element(pseudo.after, thiseltname .. "::after", {})
                    inherit.pop(stylesstack)
                    if nl then
                        -- at the end of the last paragraph, or in a paragraph
                        -- of its own if the element ends with a block
                        local last = n[#n]
                        if not (last and last.typ == "par") then
                            local tf = publisher.dispatch.new_textformat("", "text", { alignment = alignment })
                            last = publisher.par:new(tf, "html.lua (::after)")
                            n[#n + 1] = last
                        end
                        if unplaced_before then
                            last:append(unplaced_before)
                            unplaced_before = nil
                        end
                        last:append(nl)
                    end
                end
                local mode
                if thiselt.block then
                    mode = "block"
                end
                if thiselt.block and #n == 0 then
                    local a = publisher.par:new(nil, "html.lua (p)")
                    if unplaced_before then
                        -- the strut gives the line the height of the font, as for text
                        local bs = publisher.fonts.lookup_fontfamily_number_instance[fam].baselineskip
                        local strut = { height = 0.75 * bs, depth = 0.25 * bs, width = 0 }
                        local nl = publisher.nodes.add_rule(unplaced_before, "head", strut, "html.lua (::before)")
                        publisher.attribute_helpers.set_attribute(nl, "fontfamily", fam)
                        a:append(nl)
                    else
                        a:append(publisher.nodes.newline(fam))
                    end
                    box[#box + 1] = a
                end
                for j = 1, #n do
                    box[#box + 1] = n[j]
                    box[#box].mode = mode
                end
                ret[#ret + 1] = box
            end
        end
        inherit.pop(stylesstack)
    end
    -- two adjacent box elements collapse their margin, the larger one wins
    -- https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Box_Model/Mastering_margin_collapsing
    -- Margins of parent and child don't collapse yet.
    for i = 1, #ret - 1 do
        local max = math.max(ret[i].marginbottom or 0, ret[i + 1].margintop or 0)
        ret[i].marginbottom = max
        ret[i + 1].margintop = 0
    end

    return ret, prevdir
end

-- Entry point for HTML parsing
-- Top-level entry point for the HTML parser. Resolves CSS, dispatches
-- to `build_nodelist` and returns the resulting box.
---@param elt table Parsed CSS+HTML tree (from `<HTML>`).
---@param options? table Per-call options.
---@param data table Data XML context.
---@return Node|table result Final box or paragraph object.
function M.parse_html_new(elt, options, data)
    options = options or {}
    -- local maxwidth_sp = options.maxwidth_sp
    -- pages_mod.handle_pages(elt.pages,maxwidth_sp, data)
    -- global fontfamilies
    fontfamilies = elt.fontfamilies
    elt.fontfamilies = nil
    local att = elt[1].styles
    if att and type(att) == "table" then
        local trace = att["-sp-trace"] or ""
        if string.match(trace, "objects") then
            publisher.options.showobjects = true
        end
        if string.match(trace, "grid") then
            publisher.options.showgrid = true
        end
        if string.match(trace, "gridallocation") then
            publisher.options.showgridallocation = true
        end
        if string.match(trace, "hyphenation") then
            publisher.options.showhyphenation = true
        end
        if string.match(trace, "textformat") then
            publisher.options.showtextformat = true
        end
    end
    elt[1].styles.calculated_width = data.vars["__maxwidth"]
    local lang = elt.lang
    if lang then
        publisher.language.set_mainlanguage(lang)
    end
    tree.normalize_html_tree(elt[1])
    local block = M.build_nodelist(elt, options, nil, "parse_html_new", "vertical", data)
    return block
end

return M
