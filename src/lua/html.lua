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

-- Collects the horizontal node lists for an inline element subtree.
-- Returns an array of node lists (one per inline run) so the caller can
-- pack them into a paragraph.
---@param elt table HTML element subtree (with `elementname`, children).
---@param parameter? table Inherited style parameters.
---@param before_box? Node Whether the run starts a fresh line.
---@param _origin? string Caller identifier (debugging).
---@param dataxml table Data XML context.
---@return table[] runs Array of inline node lists.
function M.collect_horizontal_nodes(elt, parameter, before_box, _origin, dataxml)
    -- w("collect_horizontal_nodes %s",_origin or "?")
    parameter = parameter or {}
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

        local thiselt_styles = thiselt.styles or {}
        styles_mod.copy_attributes(styles, thiselt_styles, thiselt.elementname or "(string)")

        inline_options.set_options_for_mknodes(styles, options, publisher, fontfamilies)

        local thisret = {}
        if typ == "string" then
            local nodes = publisher.nodes.mknodes(thiselt, options)
            if before_box then
                nodes = node.insert_before(nodes, nodes, before_box)
            end
            before_box = nil
            publisher.attribute_helpers.setprop(nodes, "direction", elt.direction)
            thisret[#thisret + 1] = nodes
        elseif typ == "table" then
            local attributes = thiselt.attributes or {}
            local eltname = thiselt.elementname
            if eltname == "a" then
                local href = attributes["href"]
                options.add_attributes = { { "hyperlink", links_module.hlurl(publisher.options, href) } }
            elseif eltname == "img" then
                local box = inline_images.build_image_box(styles, attributes, dataxml)
                thisret[#thisret + 1] = box
            elseif eltname == "wbr" then
                thisret[#thisret + 1] = "\xE2\x80\x8B"
            end
            local n = M.collect_horizontal_nodes(
                thiselt,
                options,
                before_box,
                string.format("collect horizontal mode element %s", eltname),
                dataxml
            )
            for j = 1, #n do
                thisret[#thisret + 1] = n[j]
            end
        end

        if styles.has_border then
            publisher.attribute_helpers.setprop(thisret[1], "borderstart", 1)
            local ff = options.fontfamily
            local ht = publisher.fonts.lookup_fontfamily_number_instance[ff].size

            publisher.attribute_helpers.setprop(thisret[1], "lineheight", ht)
            for index, value in pairs(options.border) do
                publisher.attribute_helpers.setprop(thisret[1], index, value)
            end
            publisher.attribute_helpers.setprop(node.tail(thisret[1]), "borderend", 1)
        end

        for j = 1, #thisret do
            ret[#ret + 1] = thisret[j]
        end
        inherit.pop(stylesstack)
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

        local thiselt_styles = thiselt.styles or {}

        local before_styles = {}
        local has_before_styles = false
        local marker_styles = {}
        local has_marker_styles = false
        for k, v in pairs(thiselt_styles) do
            if string.match(k, "^before::") then
                local rawstyle = string.gsub(k, "^before::(.*)", "%1")
                before_styles[rawstyle] = v
                thiselt_styles[k] = nil
                has_before_styles = true
            elseif string.match(k, "^marker::") then
                local rawstyle = string.gsub(k, "^marker::(.*)", "%1")
                marker_styles[rawstyle] = v
                thiselt_styles[k] = nil
                has_marker_styles = true
            end
        end

        if has_before_styles then
            local bstyles = inherit.push(stylesstack)
            styles_mod.copy_attributes(bstyles, before_styles, thiseltname .. "::before")

            local before_options = {}
            inline_options.set_options_for_mknodes(bstyles, before_options, publisher, fontfamilies)
            local content = bstyles.content
            -- a ::before rule without content generates no pseudo-element
            if content then
                local nl = publisher.nodes.mknodes(content, before_options)
                local margin_left = units.getsize(bstyles, bstyles["margin-left"], bstyles.fontsize_sp)

                local hss = publisher.nodes.hss_glue()
                local ml_box = node.hpack(hss, margin_left, "exactly")

                if bstyles.width then
                    node.insert_after(nl, nl, publisher.nodes.hss_glue())
                    nl = node.hpack(nl, bstyles.calculated_width, "exactly")
                end

                before_box = node.insert_after(ml_box, ml_box, nl)
                before_box = node.hpack(before_box)
            end
            inherit.pop(stylesstack)
        end
        styles_mod.copy_attributes(styles, thiselt_styles, thiseltname)
        local styles_fontsize_sp = styles.fontsize_sp
        if thiseltname == "html" then
            styles.rootfontsize_sp = styles.fontsize_sp
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
            box.border_top_width = border_top_width
            box.border_bottom_width = border_bottom_width
            box.indent_amount = margin_left + padding_left
            styles.calculated_width = styles.calculated_width
                - margin_left
                - padding_left
                - border_left_width
                - border_right_width
            box.width = styles.calculated_width
            box.draw_border = thiselt_styles.has_border
            box.padding_top = padding_top
            box.padding_bottom = padding_bottom
            if break_before == "page" or break_before == "always" then
                box.break_before = break_before
            end
            if break_after == "avoid" then
                box.break_after = "avoid"
            end
            if thiselt_styles.has_border then
                box.border = {
                    borderstart = true,
                    border_top_style = border_top_style,
                    border_right_style = border_right_style,
                    border_bottom_style = border_bottom_style,
                    border_left_style = border_left_style,
                    padding_top = padding_top,
                    padding_right = padding_right,
                    padding_bottom = padding_bottom,
                    padding_left = padding_left,
                    border_top_width = border_top_width,
                    border_right_width = border_right_width,
                    border_bottom_width = border_bottom_width,
                    border_left_width = border_left_width,
                    border_top_color = border_top_color,
                    border_right_color = border_right_color,
                    border_bottom_color = border_bottom_color,
                    border_left_color = border_left_color,
                    border_bottom_right_radius = tex.sp(border_bottom_right_radius),
                    border_bottom_left_radius = tex.sp(border_bottom_left_radius),
                    border_top_right_radius = tex.sp(border_top_right_radius),
                    border_top_left_radius = tex.sp(border_top_left_radius),
                    margin_top = margin_top,
                    margin_right = margin_right,
                    margin_bottom = margin_bottom,
                    margin_left = margin_left,
                    debug = (styles["sp-debugbox"] == "border") or false,
                }
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
                        local inherited_fam = styles["font-family-number"]
                        styles_mod.copy_attributes(ms, marker_styles, "li::marker")
                        if marker_styles["font-size"] and inherited_fam and tonumber(inherited_fam) > 0 then
                            -- Re-define the inherited font family at the new marker size
                            local fam_inst = publisher.fonts.lookup_fontfamily_number_instance[tonumber(inherited_fam)]
                            if fam_inst then
                                local marker_name = (fam_inst.name or "marker") .. "/marker"
                                local cached = publisher.fonts.lookup_fontfamily_name_number[marker_name]
                                if cached then
                                    ms["font-family-number"] = cached
                                else
                                    local new_fam = publisher.fontfamilies.define_fontfamily(
                                        fam_inst.fontfaceregular,
                                        fam_inst.fontfacebold,
                                        fam_inst.fontfaceitalic,
                                        fam_inst.fontfacebolditalic,
                                        marker_name,
                                        ms.fontsize_sp,
                                        ms.fontsize_sp * 1.12
                                    )
                                    ms["font-family-number"] = new_fam
                                end
                            end
                        elseif marker_styles["font-family"] then
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
                local ht = units.getsize(styles, styles.height, styles.fontsize_sp)
                ht = ht + border_top_width + border_bottom_width
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
                before_box = nil
                local mode
                if thiselt.block then
                    mode = "block"
                end
                if thiselt.block and #n == 0 then
                    local list = publisher.nodes.newline(fam)
                    local a = publisher.par:new(nil, "html.lua (p)")
                    a:append(list)
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
    -- two adjacent box elements collapse their margin
    -- https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Box_Model/Mastering_margin_collapsing
    -- This simple implementation is not enough, but a start
    for i = 1, #ret - 1 do
        local max = math.max(ret[i].marginbottom or 0, ret[i + 1].margintop or 0)
        ret[i].marginbottom = max / 2
        ret[i + 1].margintop = max / 2
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
    if publisher.newxpath then
        elt[1].styles.calculated_width = data.vars["__maxwidth"]
    else
        elt[1].styles.calculated_width = publisher.xpath.get_variable("__maxwidth")
    end
    local lang = elt.lang
    if lang then
        publisher.language.set_mainlanguage(lang)
    end
    tree.normalize_html_tree(elt[1])
    local block = M.build_nodelist(elt, options, nil, "parse_html_new", "vertical", data)
    return block
end

return M
