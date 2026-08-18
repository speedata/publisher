-- Node creation, paragraph layout, line breaking and related helpers.
--
--  nodes.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("nodes.lua")

local publisher = require("publisher")

---@class nodes_module
local M = {}

local fonts = require("publisher.fonts")
local colors_module = require("publisher.colors")
local links_module = require("publisher.links")
require("par")

local html = require("html")

-- node.direct API locals for hot loops
local d = node.direct
local d_todirect = d.todirect
local d_tonode = d.tonode
local d_getnext = d.getnext
local d_getid = d.getid
local d_new = d.new
local d_setkern = d.setkern
local d_insert_before = d.insert_before
local d_has_attribute = d.has_attribute
local d_set_attribute = d.set_attribute
local d_getproperty = d.getproperty
local d_setproperty = d.setproperty
local d_setfield = d.setfield
local d_getfield = d.getfield
local d_setlink = d.setlink
local d_getlist = d.getlist
local d_dimensions = d.dimensions

-- Hot-path locals to avoid repeated global lookups
local attribute_name_number_map = publisher.attribute_name_number
local attributes_map = publisher.attributes

-- Pre-resolved attribute numbers for hot loops
local att_fontfamily = attribute_name_number_map["fontfamily"]
local att_color = attribute_name_number_map["color"]
local att_bgcolor = attribute_name_number_map["background-color"]
local att_bgpadtop = attribute_name_number_map["bgpaddingtop"]
local att_bgpadbot = attribute_name_number_map["bgpaddingbottom"]
local att_hyperlink = attribute_name_number_map["hyperlink"]
local att_spaceglue = attribute_name_number_map["spaceglue"]
local att_newline = attribute_name_number_map["newline"]
local att_fontstyle = attribute_name_number_map["font-style"]
local att_fontweight = attribute_name_number_map["font-weight"]
local att_td_line = attribute_name_number_map["text-decoration-line"]
local att_td_style = attribute_name_number_map["text-decoration-style"]
local att_td_color = attribute_name_number_map["text-decoration-color"]
local att_verticalalign = attribute_name_number_map["vertical-align"]

-- Pre-resolved table-valued attribute indices (reverse lookup: string -> index)
---@param attname string Name of an array-valued attribute in `publisher.attributes`.
---@return table<string, integer> lookup
local function attribute_value_indices(attname)
    local values = attributes_map[attname]
    assert(type(values) == "table")
    local t = {}
    for i, v in ipairs(values) do
        t[v] = i
    end
    return t
end
local attval_fontstyle = attribute_value_indices("font-style")
local attval_fontweight = attribute_value_indices("font-weight")
local attval_td_line = attribute_value_indices("text-decoration-line")
local attval_td_style = attribute_value_indices("text-decoration-style")
local attval_verticalalign = attribute_value_indices("vertical-align")

-- Dispatches a parsed CSS+HTML tree (`elt.typ == "csshtmltree"`) to
-- `html.parse_html_new`, providing the runtime environment.
---@param elt table HTML element with `typ` field.
---@param parameter? table Per-call parameters forwarded to the parser.
---@param data table Data XML context.
---@return any rendered The result of `html.parse_html_new`.
function M.parse_html(elt, parameter, data)
    parameter = parameter or {}

    if elt.typ == "csshtmltree" then
        return html.parse_html_new(elt, parameter, data)
    else
        main.log("error", "This should not happen (parse_html)")
    end
end

-- Walks a node list and inserts the non-moving whatsits (color stacks,
-- hyperlink starts/stops, struct destinations, MetaPost graphics)
-- needed to render attributes that were attached to nodes earlier.
-- Recurses into hlists/vlists.
---@param head Node Head of the node list.
---@param parent Node? Parent hlist/vlist (nil at the top).
---@param blockinline "horizontal"|"vertical" Layout direction of the list.
---@param curx integer Cursor X in sp (used for absolute placement).
---@param cury integer Cursor Y in sp.
---@param pagewidth integer
---@param pageheight integer
---@return table[] rules Each entry is `{x_sp, y_sp, pdf_instructions}`.
function M.insert_nonmoving_whatsits(head, parent, blockinline, curx, cury, pagewidth, pageheight)
    local insert_nm = M.insert_nonmoving_whatsits
    local setp = publisher.attribute_helpers.setprop
    local set_attrs = publisher.attribute_helpers.set_attributes
    local default_stack = publisher.defaultcolorstack
    local opt_format = publisher.options.format
    local links_get = links_module.get
    local node_new = node.new
    local node_insert_before = node.insert_before
    local node_insert_after = node.insert_after
    local node_set_attr = node.set_attribute
    local attr_num_color = attribute_name_number_map["color"]
    local attr_num_hyperlink = attribute_name_number_map["hyperlink"]
    local roles_lookup = publisher.roles_a
    local pdf_reserveobj = pdf.reserveobj
    local attr_table_reuse = {}
    local borderattrs = publisher.borderattributes
    local colors = colors_module.colors
    local colorname_table = colors_module.colortable
    local attr_num_bordernumber = attribute_name_number_map["bordernumber"]
    local attr_num_borderwd = attribute_name_number_map["borderwd"]
    local attr_num_borderht = attribute_name_number_map["borderht"]
    local node_has_attribute = node.has_attribute
    local node_getproperty = node.getproperty
    if not head then
        return {}
    end
    local fun
    local prev_hyperlink, prev_fgcolor, prev_role
    local nonextnode = false
    local linklevel = 0
    local currentfont = 1
    local rules = {}
    while head do
        local head_props = node_getproperty(head)
        local head_props_t = head_props and type(head_props) == "table" and head_props or nil
        -- what is subtype 1?
        if head.id == publisher.hlist_node and head.subtype == 1 then
            local r = insert_nm(head.list, head, "horizontal", curx, cury, pagewidth, pageheight)
            for _, rule in ipairs(r) do
                rules[#rules + 1] = rule
            end
            local bordernumber = node_has_attribute(head, attr_num_bordernumber)
            if bordernumber then
                -- bordered nodes always sit inside a box, so parent is set here
                ---@cast parent Node
                local ba = borderattrs[bordernumber]
                local wd = node_has_attribute(head, attr_num_borderwd)
                local ht = node_has_attribute(head, attr_num_borderht)
                wd = wd - ba.border_left_width - ba.margin_right + ba.padding_left
                setp(head, "border_bottom_color", ba.border_bottom_color)
                setp(head, "border_bottom_left_radius", ba.border_bottom_left_radius)
                setp(head, "border_bottom_right_radius", ba.border_bottom_right_radius)
                setp(head, "border_bottom_style", ba.border_bottom_style)
                setp(head, "border_bottom_width", ba.border_bottom_width)
                setp(head, "border_left_color", ba.border_left_color)
                setp(head, "border_left_style", ba.border_left_style)
                setp(head, "border_left_width", ba.border_left_width)
                setp(head, "border_right_color", ba.border_right_color)
                setp(head, "border_right_style", ba.border_right_style)
                setp(head, "border_right_width", ba.border_right_width)
                setp(head, "border_top_color", ba.border_top_color)
                setp(head, "border_top_left_radius", ba.border_top_left_radius)
                setp(head, "border_top_right_radius", ba.border_top_right_radius)
                setp(head, "border_top_style", ba.border_top_style)
                setp(head, "border_top_width", ba.border_top_width)
                setp(head, "borderstart", "true")
                setp(head, "debug", "false")
                setp(head, "margin_bottom", ba.margin_bottom)
                setp(head, "margin_left", ba.margin_left)
                setp(head, "margin_right", ba.margin_right)
                setp(head, "margin_top", ba.margin_top)
                setp(head, "padding_bottom", ba.padding_bottom)
                setp(head, "padding_left", ba.padding_left)
                setp(head, "padding_right", ba.padding_right)
                setp(head, "padding_top", ba.padding_top)
                setp(head, "lineheight", ht)
                setp(head, "depth", parent.depth)
                local boxnode = assert(publisher.htmlbox("horizontal", head, wd, parent.height, parent.depth))
                local hbox = node.hpack(boxnode)
                local g
                g = set_glue(nil, { width = ba.border_left_width + ba.margin_left + ba.padding_left })
                hbox.head = node.insert_before(hbox.head, boxnode, g)
                g = set_glue(nil, { width = parent.height })
                local vl = node.vpack(g)
                node.insert_after(vl, g, hbox)
                g = set_glue(nil, { width = -parent.height })
                node.insert_after(vl, hbox, g)
                vl.height = 0
                parent.head = node.insert_before(parent.head, head, vl)
            end
            if blockinline == "vertical" then
                cury = cury + head.height + head.depth
            else
                curx = curx + head.width
            end
        elseif head.id == publisher.hlist_node or head.id == publisher.vlist_node then
            -- Check if this is a paragraph vlist from par:format with no features that need processing
            local skip_descent = false
            if head.id == publisher.vlist_node then
                if
                    head_props_t
                    and head_props_t.origin == "par:format"
                    and not head_props_t.has_color
                    and not head_props_t.has_hyperlink
                    and not head_props_t.has_role
                    and not head_props_t.has_special_nodes
                then
                    skip_descent = true
                end
            end
            if not skip_descent then
                local bordernumber = node_has_attribute(head, attr_num_bordernumber)
                if bordernumber then
                    -- bordered nodes always sit inside a box, so parent is set here
                    ---@cast parent Node
                    local boxnode =
                        assert(publisher.drawing.mpbox(borderattrs[bordernumber], head.width, head.height + head.depth))
                    parent.head = node_insert_before(parent.head, head, boxnode)
                end
                if head.id == publisher.hlist_node then
                    local r = insert_nm(head.list, head, "horizontal", curx, cury, pagewidth, pageheight)
                    for _, rule in ipairs(r) do
                        rules[#rules + 1] = rule
                    end
                else
                    local r = insert_nm(head.list, head, "vertical", curx, cury, pagewidth, pageheight)
                    for _, rule in ipairs(r) do
                        rules[#rules + 1] = rule
                    end
                end
            end
            if blockinline == "vertical" then
                cury = cury + head.height + head.depth
            else
                curx = curx + head.width
            end
        else
            if head.id == publisher.glue_node then
                local eff = head.width
                if parent then
                    if parent.glue_sign == 1 and head.stretch_order == parent.glue_order then
                        eff = eff + parent.glue_set * head.stretch
                    elseif parent.glue_sign == 2 and head.shrink_order == parent.glue_order then
                        eff = eff - parent.glue_set * head.shrink
                    end
                end
                if blockinline == "horizontal" then
                    curx = curx + eff
                else
                    cury = cury + eff
                end
            elseif head.id == publisher.rule_node then
                if head.subtype == 2 then
                    local left = curx
                    local bot = pageheight - cury - head.height
                    local right = head.width + curx
                    local top = pageheight - cury
                    setp(head, "bbox", { sp_to_bp(left), sp_to_bp(bot), sp_to_bp(right), sp_to_bp(top) })
                end
                if blockinline == "vertical" then
                    cury = cury + head.height + head.depth
                else
                    curx = curx + head.width
                end
            end

            local fgcolor = node_has_attribute(head, attr_num_color)
            local bordernumber = node_has_attribute(head, attr_num_bordernumber)

            if bordernumber then
                -- bordered nodes always sit inside a box, so parent is set here
                ---@cast parent Node
                local ba = borderattrs[bordernumber]
                local wd, ht
                wd = node_has_attribute(head, attr_num_borderwd)
                ht = node_has_attribute(head, attr_num_borderht)
                setp(head, "border_bottom_color", ba.border_bottom_color)
                setp(head, "border_bottom_left_radius", ba.border_bottom_left_radius)
                setp(head, "border_bottom_right_radius", ba.border_bottom_right_radius)
                setp(head, "border_bottom_style", ba.border_bottom_style)
                setp(head, "border_bottom_width", ba.border_bottom_width)
                setp(head, "border_left_color", ba.border_left_color)
                setp(head, "border_left_style", ba.border_left_style)
                setp(head, "border_left_width", ba.border_left_width)
                setp(head, "border_right_color", ba.border_right_color)
                setp(head, "border_right_style", ba.border_right_style)
                setp(head, "border_right_width", ba.border_right_width)
                setp(head, "border_top_color", ba.border_top_color)
                setp(head, "border_top_left_radius", ba.border_top_left_radius)
                setp(head, "border_top_right_radius", ba.border_top_right_radius)
                setp(head, "border_top_style", ba.border_top_style)
                setp(head, "border_top_width", ba.border_top_width)
                setp(head, "borderstart", "true")
                setp(head, "debug", "false")
                setp(head, "margin_bottom", ba.margin_bottom)
                setp(head, "margin_left", ba.margin_left)
                setp(head, "margin_right", ba.margin_right)
                setp(head, "margin_top", ba.margin_top)
                setp(head, "padding_bottom", ba.padding_bottom)
                setp(head, "padding_left", ba.padding_left)
                setp(head, "padding_right", ba.padding_right)
                setp(head, "padding_top", ba.padding_top)
                setp(head, "lineheight", ht)
                if blockinline == "vertical" then
                    wd = wd - ba.border_left_width - ba.margin_left - ba.padding_left - ba.margin_right
                    setp(head, "shiftdown", ht + ba.padding_top + ba.border_top_width + ba.margin_top)
                    setp(head, "shiftright", ba.border_left_width + ba.margin_left + ba.padding_left)
                else
                    ht = parent.height + parent.depth
                    setp(head, "lineheight", ht)
                    wd = parent.width - ba.border_left_width - ba.margin_left - ba.border_right_width - ba.margin_right
                end

                local boxnode = assert(publisher.htmlbox(blockinline, head, wd, parent.height, parent.depth))
                parent.head = node_insert_before(parent.head, head, boxnode)
                setp(head, "borderstart", false)
            end
            -- Re-read properties if border/rule code may have created them
            if not head_props_t then
                head_props = node_getproperty(head)
                head_props_t = head_props and type(head_props) == "table" and head_props or nil
            end
            local transparency = head_props_t and head_props_t.opacity
            local bbox = head_props_t and head_props_t.bbox
            local hl = node_has_attribute(head, attr_num_hyperlink) or (head_props_t and head_props_t.hyperlink)
            local role, structelemobjnum, id, parentid, rc, actualtext, alttext
            if opt_format == "PDF/UA" and head_props_t then
                actualtext = head_props_t.actualtext
                alttext = head_props_t.alttext
                role = head_props_t.role
                structelemobjnum = head_props_t.structelemobjnum
                id = head_props_t.id
                parentid = head_props_t.parent
                rc = head_props_t.rolecounter
            end
            if head.id == publisher.glyph_node then
                currentfont = head.font
                if role and head.next and head.next.id == publisher.disc_node then
                    publisher.attribute_helpers.setprop(head.next, "role", role)
                    publisher.attribute_helpers.setprop(head.next, "parent", parentid)
                    publisher.attribute_helpers.setprop(head.next, "rolecounter", rc)
                end
            end

            -- Fast path: skip annotation work when no colors/links/roles/opacity are present
            local needs_annotations = fgcolor
                or prev_fgcolor
                or hl
                or prev_hyperlink
                or role
                or prev_role
                or transparency
            if needs_annotations then
                -- annotated (colored/linked/role-tagged) nodes always sit
                -- inside a box, so parent is set here
                ---@cast parent Node
                local insert_startlink = false
                local insert_endlink = false
                local endlink_after = false
                local insert_startcolor = false
                local insert_endcolor = false
                local insert_startrole = false
                local insert_endrole = false

                if fgcolor and head.next == nil then
                    -- at end insert endcolor if in color mode
                    if prev_fgcolor == nil then
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

                if
                    role
                    and (
                        head.next == nil
                        or head.next.id == publisher.vlist_node
                        or head.next.id == publisher.hlist_node
                    )
                then
                    -- at end insert endrole if in role mode
                    if prev_role == nil then
                        insert_startrole = true
                    end
                    insert_endrole = true
                    nonextnode = true
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
                end
                -- case 1: link ends at the end of the list
                --         this is due to a (line-) broken link
                --         => end link
                --  case 2: hyperlink value of the node changes
                --         either insert a start link or an end link marker
                if hl and head.next == nil and linklevel > 0 then
                    -- The link reaches the last node of this list, so head is
                    -- still part of the link. Close the link *after* head (like
                    -- the endcolor case below) instead of before it, otherwise
                    -- the last glyph drops out of the link area. This happens
                    -- for links packed tightly into a box (e.g. NoBreak), where
                    -- no trailing glue follows the final glyph.
                    insert_endlink = true
                    endlink_after = true
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
                    local enl = node_new("whatsit", "pdf_end_link")
                    if endlink_after then
                        parent.head = node_insert_after(parent.head, head, enl)
                    else
                        parent.head = node_insert_before(parent.head, head, enl)
                    end
                    if insert_endrole then
                        local emc = node_new("whatsit", "pdf_literal")
                        emc.data = "EMC"
                        emc.mode = 1
                        setp(emc, "origin", "insert_endrole")
                        node_insert_after(parent.head, enl, emc)
                        insert_endrole = false
                    end
                end
                if insert_startlink then
                    linklevel = linklevel + 1
                    -- 3 = user
                    local ai = publisher.structure_tree.get_action_node(3)
                    ai.data = tostring(links_get(assert(hl)))
                    local stl = node_new("whatsit", "pdf_start_link")
                    stl.action = ai
                    stl.width = -1073741824
                    stl.height = -1073741824
                    stl.depth = -1073741824
                    stl.objnum = pdf_reserveobj()
                    parent.head = node_insert_before(parent.head, head, stl)
                    if insert_endrole then
                        local emc = node_new("whatsit", "pdf_literal")
                        emc.data = "EMC"
                        emc.mode = 1
                        setp(emc, "origin", "insert_endrole")
                        parent.head = node_insert_before(parent.head, stl, emc)
                        insert_endrole = false
                    end

                    if insert_startrole then
                        local bdc = node_new("whatsit", "pdf_literal")
                        node_set_attr(bdc, publisher.att_role, role)
                        setp(bdc, "parentid", parentid)
                        setp(bdc, "rolecounter", rc)
                        setp(bdc, "id", id)
                        setp(bdc, "bbox", bbox)
                        setp(bdc, "actualtext", actualtext)
                        setp(bdc, "origin", "insert_startrole")
                        setp(bdc, "structelemobjnum", structelemobjnum)
                        setp(bdc, "linkobjnum", stl.objnum)
                        bdc.data = ""
                        bdc.mode = 1
                        parent.head = node_insert_before(parent.head, stl, bdc)
                        head = assert(head.next)
                        insert_startrole = false
                    end
                end

                -- Lazy: only read full attribute table when color stacks need it
                local attr_table
                if insert_endcolor or insert_startcolor then
                    attr_table = publisher.attribute_helpers.get_attributes(head, attr_table_reuse)
                    attr_table_reuse = attr_table
                end
                -- Save original head for startcolor insertion, because
                -- endcolor processing may advance head past the colored node.
                local startcolor_before = head
                if insert_endcolor then
                    local colstop = node_new("whatsit", "pdf_colorstack")
                    set_attrs(colstop, attr_table)
                    colstop.data = ""
                    colstop.command = 2
                    colstop.stack = default_stack
                    setp(colstop, "origin", "setcolor")
                    if fgcolor and not prev_fgcolor then
                        parent.head = node_insert_after(parent.head, head, colstop)
                        head = assert(head.next)
                    else
                        parent.head = node_insert_before(parent.head, head, colstop)
                    end
                end
                if insert_startcolor then
                    local colstart = node_new("whatsit", "pdf_colorstack")
                    set_attrs(colstart, attr_table)
                    local colorname = colorname_table[fgcolor]
                    local colorentry = colors[colorname]
                    local col = colorentry.pdfstring
                    local alpha = colorentry.alpha
                    if alpha then
                        local thispage = publisher.pages[publisher.current_pagenumber]
                        thispage.transparenttext = thispage.transparenttext or {}
                        thispage.transparenttext[alpha] = true
                        col = col .. string.format("/TRP%d gs", alpha)
                    end
                    colstart.data = col
                    colstart.command = 1
                    colstart.stack = default_stack

                    setp(colstart, "origin", "setcolor")
                    parent.head = node_insert_before(parent.head, startcolor_before, colstart)
                end
                if insert_endrole then
                    local emc = node_new("whatsit", "pdf_literal")
                    emc.data = "EMC"
                    emc.mode = 1
                    setp(emc, "origin", "insert_endrole")
                    if nonextnode and prev_role then
                        parent.head = node_insert_after(parent.head, head, emc)
                        head = assert(head.next)
                    elseif prev_role then
                        parent.head = node_insert_before(parent.head, head, emc)
                    else
                        -- single item?
                        local bdc = node_new("whatsit", "pdf_literal")
                        node_set_attr(bdc, publisher.att_role, role)
                        setp(bdc, "parentid", parentid)
                        setp(bdc, "rolecounter", rc)
                        setp(bdc, "bbox", bbox)
                        setp(bdc, "id", id)
                        setp(bdc, "actualtext", actualtext)
                        setp(bdc, "alttext", alttext)
                        setp(bdc, "rolename", tostring(roles_lookup[role]))
                        setp(bdc, "origin", "insert_startrole")
                        bdc.data = ""
                        bdc.mode = 1
                        parent.head = node_insert_before(parent.head, head, bdc)

                        parent.head = node_insert_after(parent.head, head, emc)
                        head = emc
                        insert_startrole = false
                    end
                end
                if insert_startrole then
                    local bdc = node_new("whatsit", "pdf_literal")
                    node_set_attr(bdc, publisher.att_role, role)
                    setp(bdc, "parentid", parentid)
                    setp(bdc, "rolecounter", rc)
                    setp(bdc, "bbox", bbox)
                    setp(bdc, "id", id)
                    setp(bdc, "actualtext", actualtext)
                    setp(bdc, "alttext", alttext)
                    setp(bdc, "rolename", tostring(roles_lookup[role]))
                    setp(bdc, "origin", "insert_startrole")
                    bdc.data = ""
                    bdc.mode = 1
                    parent.head = node_insert_before(parent.head, head, bdc)
                end
                prev_role = role

                if transparency then
                    local colstart = node_new("whatsit", "pdf_colorstack")
                    colstart.data = string.format("/TRP%d gs", transparency)
                    colstart.command = 1
                    colstart.stack = default_stack
                    publisher.current_page.transparenttext[transparency] = true

                    local colend = node_new("whatsit", "pdf_colorstack")
                    colend.command = 2
                    colend.stack = default_stack
                    parent.head = node_insert_before(parent.head, head, colstart)
                    node_insert_after(parent.head, head, colend)
                    head = assert(head.next)
                end
            end

            -- HTML inline border
            if head_props_t then
                if head_props_t.borderstart then
                    -- bordered nodes always sit inside a box, so parent is set here
                    ---@cast parent Node
                    local cur = head
                    while cur do
                        local cur_properties = node.getproperty(cur)
                        if cur_properties and cur_properties.borderend then
                            if cur.next then
                                cur = cur.next
                            end
                            break
                        end
                        cur = cur.next
                    end
                    local wd, ht, dp
                    if cur then
                        wd, ht, dp = node.dimensions(head, cur)
                    else
                        wd, ht, dp = node.dimensions(head)
                    end
                    local boxnode = assert(publisher.htmlbox(blockinline, head, wd, ht, dp))
                    parent.head = node.insert_before(parent.head, head, boxnode)
                end
            end
            -- Now let's look at user defined whatsits, that are ment
            -- for markers, bookmarks etc.
            if head.id == publisher.whatsit_node then
                if head.subtype == publisher.user_defined_whatsit then
                    -- action
                    if head.user_id == publisher.user_defined_addtolist then
                        -- this part is obsolete (2.9.3)
                        -- the value is the index of the hash of user_defined_functions
                        fun = publisher.user_defined_functions[head.value]
                        fun()
                        -- use and forget
                        publisher.user_defined_functions[head.value] = nil
                    -- bookmark
                    elseif head.user_id == publisher.user_defined_bookmark then
                        local level, openclose, dest, str = string.match(head.value, "([^+]*)+([^+]*)+([^+]*)+(.*)")
                        level = tonumber(level)
                        local open_p
                        if openclose == "1" then
                            open_p = true
                        else
                            open_p = false
                        end
                        local i = 1
                        local current_bookmark_table = publisher.bookmarks -- level 1 == top level
                        -- create levels if necessary
                        while i < level do
                            if #current_bookmark_table == 0 then
                                current_bookmark_table[1] = { name = "", destination = "" }
                                main.log("error", string.format("No bookmark given for this level (%d)!", level))
                            end
                            current_bookmark_table = current_bookmark_table[#current_bookmark_table]
                            i = i + 1
                        end
                        current_bookmark_table[#current_bookmark_table + 1] =
                            { name = str, destination = dest, open = open_p }
                    elseif head.user_id == publisher.user_defined_mark then
                        local marker = head.value
                        publisher.markercount = publisher.markercount + 1
                        publisher.markers[marker] =
                            { page = publisher.current_pagenumber, count = publisher.markercount }
                    elseif head.user_id == publisher.user_defined_mark_append then
                        local marker = head.value
                        if publisher.markers[marker] == nil then
                            publisher.markers[marker] = { page = tostring(publisher.current_pagenumber) }
                        else
                            publisher.markers[marker]["page"] = tostring(publisher.markers[marker]["page"])
                                .. ","
                                .. tostring(publisher.current_pagenumber)
                        end
                    end
                elseif head.subtype == publisher.pdf_literal_whatsit then
                    local data = publisher.attribute_helpers.getprop(head, "data")
                    if data then
                        head.data = ""
                        rules[#rules + 1] = { curx, cury, data }
                    end
                end
            elseif
                publisher.options.format == "PDF/UA"
                and head.id == publisher.glue_node
                and node.has_attribute(head, att_spaceglue) == 1
            then
                -- a space in PDF/UA should be a real glyph
                -- subtype >= 1000 is assigend to glue for arranging pages
                -- space glues always sit inside a box, so parent is set here
                ---@cast parent Node
                local g = node.new("glyph")
                g.subtype = 1
                g.font = currentfont
                g.char = 32
                g.width = head.width
                parent.head = node.insert_before(parent.head, head, g)
                head.width = 0
            end
        end
        head = head.next
    end
    return rules
end

-- Returns the larger of two glue spec nodes by total natural width.
---@param a Node Glue spec.
---@param b Node Glue spec.
---@return Node larger
function M.bigger_glue_spec(a, b)
    if a.stretch_order > b.stretch_order then
        return a
    end
    if b.stretch_order > a.stretch_order then
        return b
    end
    if a.stretch > b.stretch then
        return a
    end
    if b.stretch > a.stretch then
        return b
    end
    if a.width > b.width then
        return a
    else
        return b
    end
end

-- TODO: this function is partially broken / unfinished. Compare with
-- M.newline below: that one initialises `list, cur = dummypenalty,
-- dummypenalty` and then builds a real chain (penalty → strut → glue →
-- penalty). short_newline creates a dummypenalty but never uses it; the
-- M.add_rule(nil, "tail", ...) call discards its return value and has
-- no observable effect; node.insert_after(nil, nil, g) effectively
-- returns just `g`. So this function currently degenerates to "return
-- a single glue". QA passes today, so the simple-glue behaviour is what
-- callers (html.lua's <br> in horizontal mode) expect — but the dead
-- bookkeeping should be cleaned up or the function should be
-- reimplemented properly.
-- Returns a glue node tagged with `att_newline` that breaks the line
-- without adding the full baseline skip.
---@param fam integer Font family number.
---@return Node head
---@return Node tail
function M.short_newline(fam)
    local strutheight = fonts.lookup_fontfamily_number_instance[fam].baselineskip
    local dummypenalty
    dummypenalty = node.new("penalty")
    dummypenalty.penalty = 10000
    node.set_attribute(dummypenalty, att_newline, 1)

    -- luacheck: push ignore 321
    local list, cur
    M.add_rule(list, "tail", { height = 0.75 * strutheight, depth = 0.25 * strutheight, width = 0 }, "short_newline")
    local g = set_glue(nil, {}, "short_newline")
    list, cur = node.insert_after(list, node.tail(list), g)
    -- luacheck: pop
    return list, cur
end

-- Returns a penalty/strut/glue chain that forces a line break and applies
-- the family's baseline skip on the next line.
---@param fam integer Font family number.
---@return Node head
---@return Node tail
function M.newline(fam)
    local strutheight = fonts.lookup_fontfamily_number_instance[fam].baselineskip
    local dummypenalty
    dummypenalty = node.new("penalty")
    dummypenalty.penalty = 10000
    node.set_attribute(dummypenalty, att_newline, 1)

    local list, cur
    list, cur = dummypenalty, dummypenalty

    local strut = node.new(publisher.rule_node)
    -- set to 60000 for example for debugging
    strut.width = 0
    strut.height = strutheight * 0.75
    strut.depth = strutheight * 0.25
    list, cur = node.insert_after(list, cur, strut)

    local p1, g, p2
    p1 = node.new("penalty")
    p1.penalty = 10000
    g = set_glue(nil, { stretch = 2 ^ 16, stretch_order = 2 })
    p2 = node.new("penalty")
    p2.penalty = -10000
    node.set_attribute(p1, att_newline, 1)
    node.set_attribute(p2, att_newline, 1)
    node.set_attribute(g, att_newline, 1)
    -- important for empty lines (adjustlineheight)
    node.set_attribute(p1, att_fontfamily, fam)
    list, cur = node.insert_after(list, cur, p1)
    list, cur = node.insert_after(list, cur, g)
    list, cur = node.insert_after(list, cur, p2)
    -- add glue so next word can hyphenate (#274)
    g = set_glue(nil, {})
    list, cur = node.insert_after(list, cur, g)
    return list, cur
end

-- Remove the first \n in a paragraph value table. See #132
-- Removes leading whitespace-only entries from a paragraph table.
---@param tbl table Paragraph table (array of segments).
---@return boolean? done True when a segment was cleaned.
function M.remove_first_whitespace(tbl)
    if publisher.newxpath and publisher.xpath.is_attribute(tbl) then
        tbl.value = string.gsub(tbl.value, "^[\n\t]*(.-)$", "%1")
        return true
    end
    for i = 1, #tbl do
        if type(tbl[i]) == "string" then
            tbl[i] = string.gsub(tbl[i], "^[\n\t]*(.-)$", "%1")
            return true
        end
        if type(tbl[i]) == "table" then
            local ret
            if tbl[i].contents and type(tbl[i].contents) == "table" then
                ret = M.remove_first_whitespace(tbl[i].contents)
            else
                ret = M.remove_first_whitespace(tbl[i])
            end
            if ret then
                return true
            end
        end
    end
end

-- Remove the final \n in a paragraph value table. See #132
-- Removes trailing whitespace-only entries from a paragraph table.
---@param tbl table Paragraph table.
---@return boolean? done True when a segment was cleaned.
function M.remove_last_whitespace(tbl)
    for i = #tbl, 1, -1 do
        if type(tbl[i]) == "string" then
            if string.match(tbl[i], "^%s*$") then
                table.remove(tbl, i)
            else
                tbl[i] = string.gsub(tbl[i], "^(.-)[\n\t]*$", "%1")
            end
            return true
        end
        if type(tbl[i]) == "table" then
            local ret
            if tbl[i].contents and type(tbl[i].contents) == "table" then
                ret = M.remove_last_whitespace(tbl[i].contents)
            else
                local tic = tbl[i].contents
                -- the last contents could be an image for example. See #342
                if type(tic) == "userdata" then
                    ret = true
                else
                    ret = M.remove_last_whitespace(tbl[i])
                end
            end
            return ret
        end
    end
end

-- Inserts a strut (zero-width box of font-height) at the head of the
-- node list to set its vertical extent.
---@param nodelist Node
---@param _where "head"|"tail" Unused; the strut is always added at the head.
---@param origin? string Origin tag for `setprop` (debugging).
---@return Node nodelist
function M.addstrut(nodelist, _where, origin)
    local strutheight = 0
    local head = nodelist
    while head do
        if head.id == publisher.hlist_node then
            strutheight = head.height
            if node.has_attribute(head, publisher.att_dont_format) then
                -- 0.25 is the depth of the line, and hopefully
                -- this is the highest thing in the line
                head.shift = 0.25 * head.height
            end
        end
        head = head.next
    end
    head = nodelist
    while head do
        if node.has_attribute(head, att_fontfamily) then
            break
        end
        head = head.next
    end
    local fontfamily

    if head == nil then
        fontfamily = nil
    else
        fontfamily = node.has_attribute(head, att_fontfamily)
    end
    if fontfamily == nil or fontfamily == 0 then
        fontfamily = fonts.lookup_fontfamily_name_number["text"]
    end

    local fi = fonts.lookup_fontfamily_number_instance[fontfamily]
    strutheight = math.max(fi.baselineskip, strutheight)
    -- for debugging purposes set width to 20000:
    local strut = M.add_rule(
        nodelist,
        "head",
        { height = 0.75 * strutheight, depth = 0.25 * strutheight, width = 0 },
        origin or "addstrut"
    )
    return strut
end

-- Resolves missing glyphs in a HarfBuzz cluster by trying each fallback
-- font definition in turn.
---@param cluster table HarfBuzz shaping cluster.
---@param glyphslist table List of glyph entries to fill in.
---@param fallback_fontdefinitions table[] Fallback fonts to try.
---@return table[] fallbacks Replacement entries (`pos`, `fonttable`, `fontnumber`, `remove_len`, glyphs).
function M.getfallbacks(cluster, glyphslist, fallback_fontdefinitions)
    local fontnum
    local ret = {}
    local fallback = fallback_fontdefinitions[1]
    fontnum = fallback.fontnum
    local tbl = fallback
    local i = 1

    while i <= #glyphslist do
        local buf = publisher.harfbuzz.Buffer.new()
        local pos = glyphslist[i][1]
        local thisglyph = glyphslist[i][2]
        ret[#ret + 1] = {
            pos = pos,
            fonttable = tbl,
            fontnumber = fontnum,
        }
        local curret = ret[#ret]
        -- the cluster may have more than one unicode character, so I
        -- create a list
        local uclist = {}
        local uc = cluster[thisglyph.cluster]
        uclist[#uclist + 1] = uc
        buf:add_utf8(unicode.utf8.char(uc))
        while #glyphslist > i and glyphslist[i + 1][1] == pos + 1 do
            i = i + 1
            pos = pos + 1
            thisglyph = glyphslist[i][2]
            uc = cluster[thisglyph.cluster]
            uclist[#uclist + 1] = uc
            buf:add_utf8(unicode.utf8.char(uc))
        end
        buf:set_cluster_level(buf.CLUSTER_LEVEL_MONOTONE_CHARACTERS)
        buf:set_flags(publisher.harfbuzz.Buffer.FLAG_REMOVE_DEFAULT_IGNORABLES)
        buf:guess_segment_properties()
        publisher.shape(tbl, buf)
        local nglyphs = buf:get_glyphs()
        curret.remove_len = #uclist
        for j = 1, #nglyphs do
            curret[#curret + 1] = {
                glyph = nglyphs[j],
                codepoint = nglyphs[j].codepoint,
            }
            local jcp = nglyphs[j].codepoint
            if jcp == 0 then
                curret[#curret].uc = uclist[j]
            else
                curret[#curret].uc = tbl.backmap[jcp]
            end
        end
        i = i + 1
    end
    return ret
end

-- Builds a glyph node list from a string using HarfBuzz shaping.
-- Handles ligatures, kerning, fallback fonts, font features and the
-- color/decoration attributes encoded in `arguments`.
---@param arguments table Shaping arguments (text, font, parameters, ...).
---@return Node head Head of the resulting glyph node list.
function M.hbglyphlist(arguments)
    local tbl = arguments.tbl
    local glyphs = arguments.glyphs
    local cluster = arguments.cluster
    local parameter = arguments.parameter
    local allowbreak = arguments.allowbreak
    local newlines_at = arguments.newlines_at
    local fontfamily = parameter.fontfamily
    local direction = arguments.direction
    local thislang = arguments.thislang
    local fontnumber = arguments.fontnumber
    local is_cjk = arguments.is_cjk
    local decoration_active = parameter.textdecorationline ~= nil
    local background_active = parameter.backgroundcolor ~= nil

    local thisfont = fonts.used_fonts[fontnumber]
    local reportmissingglyphs = publisher.options.reportmissingglyphs
    local lastitemwasglyph
    local space = tbl.parameters.space
    local shrink = tbl.parameters.space_shrink
    local stretch = tbl.parameters.space_stretch
    local list, cur
    local n
    local preserve_whitespace = parameter.whitespace == "pre"
    local zeroglyphs = {}

    for i = 1, #glyphs do
        local thisglyph = glyphs[i]
        if thisglyph.codepoint == 0 then
            zeroglyphs[#zeroglyphs + 1] = { i, thisglyph }
        end
    end

    local fallbacks
    -- fallacks: remove all glyph entries that are covered by fallbacks, then
    -- re-insert a more complex table at these positions.
    -- detect the other table type in the loop below (for i=1,#glyphs do .. end)
    if #zeroglyphs > 0 and #tbl.fallback_fontdefinitions > 0 then
        fallbacks = M.getfallbacks(cluster, zeroglyphs, tbl.fallback_fontdefinitions)
        for i = #fallbacks, 1, -1 do
            local fb = fallbacks[i]
            for _ = 1, fb.remove_len do
                table.remove(glyphs, fb.pos)
            end
            for j = #fb, 1, -1 do
                table.insert(glyphs, fb.pos, {
                    pos = fb.pos,
                    fonttable = fb.fonttable,
                    fontnumber = fb.fontnumber,
                    glyph = fb[j].glyph,
                    codepoint = fb[j].codepoint,
                    uc = fb[j].uc,
                })
            end
        end
    end

    local thistbl

    -- Pre-compute style attributes (parameter is constant throughout the loop)
    local style_attrs = {}
    local style_attrs_len = 0
    local style_props_tmpl = nil
    local style_langcode = parameter.languagecode
    local node_set_attribute = node.set_attribute

    if parameter.bold == 1 then
        style_attrs_len = style_attrs_len + 2
        style_attrs[style_attrs_len - 1] = att_fontweight
        style_attrs[style_attrs_len] = attval_fontweight["bold"]
        style_props_tmpl = {}
        style_props_tmpl["font-weight"] = "bold"
    end
    if parameter.italic == 1 then
        style_attrs_len = style_attrs_len + 2
        style_attrs[style_attrs_len - 1] = att_fontstyle
        style_attrs[style_attrs_len] = attval_fontstyle["italic"]
    end
    if parameter.textdecorationline then
        style_attrs_len = style_attrs_len + 2
        style_attrs[style_attrs_len - 1] = att_td_line
        style_attrs[style_attrs_len] = attval_td_line[parameter.textdecorationline]
        style_attrs_len = style_attrs_len + 2
        style_attrs[style_attrs_len - 1] = att_td_style
        style_attrs[style_attrs_len] = attval_td_style[parameter.textdecorationstyle]
        style_attrs_len = style_attrs_len + 2
        style_attrs[style_attrs_len - 1] = att_td_color
        style_attrs[style_attrs_len] = publisher.current_fgcolor
    end
    if parameter.color and parameter.color ~= 1 then
        style_attrs_len = style_attrs_len + 2
        style_attrs[style_attrs_len - 1] = att_td_color
        style_attrs[style_attrs_len] = parameter.color
        style_attrs_len = style_attrs_len + 2
        style_attrs[style_attrs_len - 1] = att_color
        style_attrs[style_attrs_len] = parameter.color
    end
    if parameter.hyperlink then
        style_attrs_len = style_attrs_len + 2
        style_attrs[style_attrs_len - 1] = att_hyperlink
        style_attrs[style_attrs_len] = parameter.hyperlink
    end
    if parameter.backgroundcolor then
        style_attrs_len = style_attrs_len + 2
        style_attrs[style_attrs_len - 1] = att_bgcolor
        style_attrs[style_attrs_len] = parameter.backgroundcolor
        style_attrs_len = style_attrs_len + 2
        style_attrs[style_attrs_len - 1] = att_bgpadtop
        style_attrs[style_attrs_len] = tex.sp(parameter.bg_padding_top or 0)
        style_attrs_len = style_attrs_len + 2
        style_attrs[style_attrs_len - 1] = att_bgpadbot
        style_attrs[style_attrs_len] = tex.sp(parameter.bg_padding_bottom or 0)
    end
    if parameter.verticalalign then
        style_attrs_len = style_attrs_len + 2
        style_attrs[style_attrs_len - 1] = att_verticalalign
        style_attrs[style_attrs_len] = attval_verticalalign[parameter.verticalalign]
    end
    if parameter.indent then
        style_props_tmpl = style_props_tmpl or {}
        style_props_tmpl["indent"] = parameter.indent
    end
    if parameter.role then
        style_props_tmpl = style_props_tmpl or {}
        style_props_tmpl["role"] = parameter.role
    end
    if parameter.structelemobjnum then
        style_props_tmpl = style_props_tmpl or {}
        style_props_tmpl["structelemobjnum"] = parameter.structelemobjnum
    end
    if parameter.actualtext then
        style_props_tmpl = style_props_tmpl or {}
        style_props_tmpl["actualtext"] = parameter.actualtext
    end
    if parameter.alttext then
        style_props_tmpl = style_props_tmpl or {}
        style_props_tmpl["alttext"] = parameter.alttext
    end
    if parameter.parent and parameter.parent ~= "" then
        style_props_tmpl = style_props_tmpl or {}
        style_props_tmpl["parent"] = parameter.parent
    end
    if parameter.id then
        style_props_tmpl = style_props_tmpl or {}
        style_props_tmpl["id"] = parameter.id
    end
    if parameter.rolecounter then
        style_props_tmpl = style_props_tmpl or {}
        style_props_tmpl["rolecounter"] = parameter.rolecounter
    end

    -- Pre-compute glyph creation values
    local glyph_left = parameter.left or tex.lefthyphenmin
    local glyph_right = parameter.right or tex.righthyphenmin
    local famtab = fonts.lookup_fontfamily_number_instance[fontfamily]
    local glyph_yoffset_base = 0
    if parameter.verticalalign == "sub" then
        glyph_yoffset_base = -famtab.subshift
    elseif parameter.verticalalign == "super" then
        glyph_yoffset_base = famtab.supershift
    end
    local xoffset_dir = 1
    if direction == "rtl" then
        xoffset_dir = -1
    end

    -- Pre-build allowbreak lookup set
    local allowbreak_set = {}
    for _, c in utf8.codes(allowbreak) do
        allowbreak_set[c] = true
    end

    -- Apply pre-computed styles to a node
    local function apply_styles(nd)
        for j = 1, style_attrs_len, 2 do
            node_set_attribute(nd, style_attrs[j], style_attrs[j + 1])
        end
        if style_langcode and nd.id == publisher.glyph_node then
            nd.lang = style_langcode
        end
        if style_props_tmpl then
            local p = node.getproperty(nd)
            if not p then
                p = {}
                node.setproperty(nd, p)
            end
            for k, v in next, style_props_tmpl do
                p[k] = v
            end
        end
    end

    for i = 1, #glyphs do
        local thisfontnumber = fontnumber
        local thisglyph = glyphs[i]
        local cp = thisglyph.codepoint
        -- HarfBuzz emits a sentinel codepoint 0xFFFF with x_advance = 0 for
        -- glyphs that have been removed during complex shaping (e.g. Khmer
        -- reordering). These are invisible and have no entry in the font's
        -- characters table, so skip them to avoid producing dead glyph nodes
        -- and triggering thousands of bogus "missing glyph" warnings later.
        if cp == 65535 and (thisglyph.x_advance == 0 or thisglyph.x_advance == nil) then
            goto continue
        end
        local cpcluster = cluster[thisglyph.cluster]
        if cpcluster and cp == 0 and cpcluster > publisher.puastart then
            cp = cpcluster - publisher.puastart
        end
        local uc
        if thisglyph.pos then
            -- a special table from fallback
            thisfontnumber = thisglyph.fontnumber
            thistbl = thisglyph.fonttable
            uc = thisglyph.uc
            cp = thisglyph.codepoint
            thisglyph = thisglyph.glyph
        else
            thistbl = tbl
            uc = thistbl.backmap[cp] or cp
        end

        -- FIXME cp == 0 doesn't look right
        local tabregularspace = (cp == 0 and cluster[thisglyph.cluster] == 9 and parameter.tab ~= "hspace")
        -- skip double space
        if
            i > 1
            and (uc == 32 or tabregularspace)
            and cp == glyphs[i - 1].codepoint
            and cluster[thisglyph.cluster] ~= 160
            and not preserve_whitespace
        then
            goto continue
        end
        if false then
            -- just for simple adding at the beginning
        elseif uc == 127 then
            -- ignore DEL
        elseif uc == 160 and #glyphs == 1 then
            -- ignore
        elseif uc == 32 or tabregularspace then
            local thiscluster = thisglyph.cluster
            local thisclustervalue = cluster[thiscluster]
            if thisclustervalue == 160 then -- no break space
                n = node.new(publisher.penalty_node)
                n.penalty = 10000
                list, cur = node.insert_after(list, cur, n)
                n = set_glue(nil, { width = space, shrink = shrink, stretch = stretch }, "uc=32,160")
                node_set_attribute(n, publisher.att_tie_glue, 1)
                list, cur = node.insert_after(list, cur, n)
            elseif thisclustervalue == 8194 then -- en space
                n = set_glue(nil, { width = thistbl.parameters.enspace }, "uc=8194")
                -- prevent from stretching with ragged shape
                n.subtype = 1
                list, cur = node.insert_after(list, cur, n)
            elseif thisclustervalue == 8195 then -- em space
                n = set_glue(nil, { width = thistbl.parameters.emspace }, "uc=8195")
                -- prevent from stretching with ragged shape
                n.subtype = 1
                list, cur = node.insert_after(list, cur, n)
            elseif thisclustervalue == 8196 then -- three per em space
                n = set_glue(nil, { width = thistbl.parameters.thirdspace }, "uc=8196")
                -- prevent from stretching with ragged shape
                n.subtype = 1
                list, cur = node.insert_after(list, cur, n)
            elseif thisclustervalue == 8197 then -- four per em space
                n = set_glue(nil, { width = thistbl.parameters.quarterspace }, "uc=8197")
                -- prevent from stretching with ragged shape
                n.subtype = 1
                list, cur = node.insert_after(list, cur, n)
            elseif thisclustervalue == 8198 then -- six per em space
                n = set_glue(nil, { width = thistbl.parameters.sixthspace }, "uc=8198")
                -- prevent from stretching with ragged shape
                n.subtype = 1
                list, cur = node.insert_after(list, cur, n)
            elseif thisclustervalue == 8201 then -- thin space
                n = set_glue(nil, { width = thistbl.parameters.thinspace }, "uc=8201")
                -- prevent from stretching with ragged shape
                n.subtype = 1
                list, cur = node.insert_after(list, cur, n)
            elseif thisclustervalue == 8202 then -- hair space
                n = set_glue(nil, { width = thistbl.parameters.hairspace }, "uc=8202")
                -- prevent from stretching with ragged shape
                n.subtype = 1
                list, cur = node.insert_after(list, cur, n)
            elseif thisclustervalue == 8203 then
                -- U+200B ZERO WIDTH SPACE
                local p = node.new(publisher.penalty_node)
                p.penalty = -10
                list, cur = node.insert_after(list, cur, p)
            elseif thisclustervalue == 8205 then
                -- U+200D ZERO WIDTH JOINER
                -- ignore
            elseif preserve_whitespace then
                local ws = M.add_rule(
                    nil,
                    "head",
                    { height = 0 * publisher.factor, depth = 0, width = thistbl.zerowidth },
                    "preserve_whitespace"
                )
                list, cur = node.insert_after(list, cur, ws)
            else
                n = set_glue(nil, { width = space, shrink = shrink, stretch = stretch }, "uc=32")
                apply_styles(n)
                node_set_attribute(n, att_spaceglue, 1)
                list, cur = node.insert_after(list, cur, n)
                if parameter.letterspacing then
                    n.width = n.width + parameter.letterspacing
                end
            end
            if decoration_active then
                node_set_attribute(n, att_td_line, attval_td_line[parameter.textdecorationline])
                node_set_attribute(n, att_td_style, attval_td_style[parameter.textdecorationstyle])
                node_set_attribute(n, att_td_color, publisher.current_fgcolor)
            end

            if background_active then
                node_set_attribute(n, att_bgcolor, parameter.backgroundcolor)
                if parameter.bg_padding_top then
                    node_set_attribute(n, att_bgpadtop, parameter.bg_padding_top)
                end
                if parameter.bg_pading_bottom then
                    node_set_attribute(n, att_bgpadbot, parameter.bg_padding_bottom)
                end
            end
            if n then
                node_set_attribute(n, att_fontfamily, fontfamily)
            end
        elseif (cp == 0 or uc == 10) and newlines_at[thisglyph.cluster] then
            local dummypenalty
            dummypenalty = node.new(publisher.penalty_node)
            dummypenalty.penalty = 10000
            node_set_attribute(dummypenalty, att_newline, 1)
            list, cur = node.insert_after(list, cur, dummypenalty)

            local ht = famtab.size
            local strut = M.add_rule(nil, "head", { height = ht * 0.75, depth = 0.25 * ht, width = 0 }, "newline")
            node_set_attribute(strut, att_newline, 1)
            publisher.attribute_helpers.setprop(strut, "origin", "strut newline hb")
            list, cur = node.insert_after(list, cur, strut)

            local p1, g, p2
            p1 = node.new(publisher.penalty_node)
            p1.penalty = 10000

            g = set_glue(nil, { stretch = 2 ^ 16, stretch_order = 2 })

            p2 = node.new(publisher.penalty_node)
            p2.penalty = -10000
            node_set_attribute(p1, att_newline, 1)
            node_set_attribute(p2, att_newline, 1)
            node_set_attribute(g, att_newline, 1)

            -- important for empty lines (adjustlineheight)
            node_set_attribute(p1, att_fontfamily, fontfamily)

            list, cur = node.insert_after(list, cur, p1)
            list, cur = node.insert_after(list, cur, g)
            list, cur = node.insert_after(list, cur, p2)

            -- add glue so next word can hyphenate (#274)
            g = set_glue(nil, {})
            list, cur = node.insert_after(list, cur, g)
        elseif cp == 0 then
            local code = cluster[thisglyph.cluster]
            if code == 9 then
                if parameter.tab == "hspace" then
                    local tabglue = set_glue(nil, { width = 0, stretch = 2 ^ 16, stretch_order = 3 })
                    list, cur = node.insert_after(list, cur, tabglue)
                else
                    -- a regular space, handled above (tabregularspace)
                end
            elseif code == 131 then
                -- U+0083 NO BREAK HERE (also U+2060 WORD JOINER, mapped to
                -- U+0083 in mknodes): forbid a line break at this position (#695).
                local pen = node.new(publisher.penalty_node)
                pen.penalty = 10000
                list, cur = node.insert_after(list, cur, pen)
            else
                if reportmissingglyphs then
                    local lvl = reportmissingglyphs == "warning" and "warn" or "error"
                    fonts.report_missing_glyph(lvl, thisfont.name, code, "loc", "hbglyphlist")
                end
            end
        else
            n = node.new(publisher.glyph_node, 1)
            n.font = thisfontnumber
            n.char = uc
            n.uchyph = 1
            n.left = glyph_left
            n.right = glyph_right
            if glyph_yoffset_base ~= 0 then
                n.yoffset = glyph_yoffset_base
            end

            if thisglyph.x_offset ~= 0 then
                n.xoffset = xoffset_dir * thisglyph.x_offset * thistbl.mag
            end
            if thisglyph.y_offset ~= 0 then
                n.yoffset = thisglyph.y_offset * thistbl.mag
            end
            node_set_attribute(n, att_fontfamily, fontfamily)
            apply_styles(n)
            list, cur = node.insert_after(list, cur, n)

            if cur and cur.prev and cur.prev.id == publisher.glyph_node then
                lastitemwasglyph = true
            end

            -- CJK
            if is_cjk and i < #glyphs and uc > 12032 then
                -- don't break within non-cjk words
                if publisher.prohibited_at_end[thislang][unicode.utf8.char(uc)] then
                    -- ignore
                else
                    -- add breaking point between this glyph and next glyph unless prohibited
                    if i < #glyphs then
                        local nextchar = glyphs[i + 1].codepoint
                        local nextuc = thistbl.backmap[nextchar] or nextchar
                        if not publisher.prohibited_at_beginning[thislang][unicode.utf8.char(nextuc)] then
                            local pen = node.new(publisher.penalty_node)
                            pen.penalty = 0
                            if parameter.textformat.alignment == "justified" then
                                local g = set_glue(nil, { stretch = 2 ^ 16, stretch_order = 0 })
                                list, cur = node.insert_after(list, cur, g)
                            end
                            list, cur = node.insert_after(list, cur, pen)
                        end
                    end
                end
            end
            -- simplified chinese
            -- characters that must not appear at the beginning of a line
            -- !%),.:;?]}¢°·'""†‡›℃∶、。〃〆〕〗〞﹚﹜！＂％＇），．：；？！］｝～
            -- characters that must not appear at the end of a line
            -- $(£¥·'"〈《「『【〔〖〝﹙﹛＄（．［｛￡￥

            -- glyph ids inserted by sd:symbol()
            local thischar = thistbl.characters[uc]
            if uc > publisher.puastart and thisglyph.codepoint == 0 and thischar then
                thisglyph.x_advance = thischar.hadvance
            end

            -- thischar can be nil for glyphs produced by complex shaping (e.g. Khmer
            -- subscript consonant stacks) whose backmapped codepoint has no entry in
            -- the font's characters table. In that case there is no font-defined
            -- advance to compare against, so skip the kerning correction.
            local diff = thischar and (thisglyph.x_advance - thischar.hadvance) or 0
            local kernvalue = diff * tbl.mag
            if parameter.letterspacing then
                kernvalue = kernvalue + parameter.letterspacing
            end
            if kernvalue ~= 0 then
                local property = "kernafter"
                if direction == "rtl" then
                    property = "kernbefore"
                end
                publisher.attribute_helpers.setprop(cur, property, kernvalue)
            end
            if uc == -1 then
            elseif uc > publisher.puastart then
                -- ignore
            elseif (uc == 45 or uc == 8211) and lastitemwasglyph and allowbreak_set[45] then
                -- only break if allowbreak contains the hyphen char
                local pen = node.new(publisher.penalty_node)
                pen.penalty = 10000
                list = node.insert_before(list, cur, pen)
                local disc = node.new(publisher.disc_node)
                list, cur = node.insert_after(list, cur, disc)
                local g = set_glue(nil)
                apply_styles(pen)
                apply_styles(disc)
                apply_styles(g)
                list, cur = node.insert_after(list, cur, g)
            elseif allowbreak_set[uc] then
                -- allowbreak lists characters where the publisher may break lines
                local pen = node.new(publisher.penalty_node)
                pen.penalty = 0
                list, cur = node.insert_after(list, cur, pen)
            end
        end
        ::continue::
    end

    if not list then
        -- This should never happen.
        main.log("warn", "No head found")
        return node.new("hlist")
    end
    local aa = parameter.add_attributes or {}
    for i = 1, #aa do
        publisher.attribute_helpers.set_attribute_recurse(list, aa[i][1], aa[i][2])
    end
    return list
end

-- Builds a deterministic instance key for `parameter` so font instances can
-- be cached and reused.
---@param parameter table Font parameters (family, style, weight, ...).
---@return string key
function M.getinstancename(parameter)
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

-- Top-level entry point: turns a string `str` plus `parameter` (font,
-- color, decoration, ...) into a node list shaped with HarfBuzz.
---@param str string Text segment.
---@param parameter? table Style/font parameters.
---@param _origin? string Origin tag (debugging).
---@return Node head Head of the glyph node list.
---@return string? maindirection Paragraph direction (`"ltr"`/`"rtl"`) when known.
function M.mknodes(str, parameter, _origin)
    parameter = parameter or {}
    -- if it's an empty string, we make a zero-width rule
    if not str or string.len(str) == 0 then
        -- a space char can have a width, so we return a zero width something
        local strut = M.add_rule(nil, "head", { height = 1 * publisher.factor, depth = 0, width = 0 }, "pardir")
        publisher.attribute_helpers.setprop(strut, "pardir", parameter.direction)
        return strut, parameter.direction
    end
    local languagecode = parameter.languagecode or publisher.defaultlanguage

    local fontfamily = parameter.fontfamily
    if parameter.monospace then
        fontfamily = fonts.lookup_fontfamily_name_number.monospace
    end
    local fontnumber = fonts.get_fontinstance(fontfamily, M.getinstancename(parameter))
    local tbl = fonts.used_fonts[fontnumber]

    -- Convert letterspacing_em (in 1/1000 em) to absolute letterspacing based on font size
    if parameter.letterspacing_em and not parameter.letterspacing then
        local fam_instance = fonts.lookup_fontfamily_number_instance[fontfamily]
        if fam_instance and fam_instance.size then
            parameter.letterspacing = parameter.letterspacing_em * fam_instance.size / 1000
        end
    end

    ---@type string?
    local maindirection
    ---@type [integer?, string][]
    local segments
    if parameter.bidi and str ~= "\n" then
        local dir = 0
        if parameter.direction == "ltr" then
            dir = 1
        elseif parameter.direction == "rtl" then
            dir = 2
        end
        segments = assert(splib.segmentize_text(str, dir))
        if segments[1][1] == 0 then
            maindirection = "ltr"
        else
            maindirection = "rtl"
        end
    else
        -- bidi disabled: let HarfBuzz auto-detect the segment direction from
        -- the script, so Latin text isn't reversed when the paragraph is rtl.
        -- The paragraph-level maindirection still drives line layout.
        local dir = nil
        segments = {}
        if parameter.direction == "rtl" then
            -- A bare newline (from <Br/>) is script-neutral, so HarfBuzz would
            -- auto-detect it as ltr and wrap it in an opposite-direction
            -- segment, nudging the following centered line off-center. Keep it
            -- aligned to the rtl paragraph direction instead.
            if str == "\n" then
                dir = 1
            end
            maindirection = "rtl"
        elseif parameter.direction == "ltr" then
            maindirection = "ltr"
        end
        segments[1] = { dir, str }
    end
    maindirection = parameter.direction or maindirection
    local nodelistsegments

    for i = 1, #segments do
        str = segments[i][2]
        ---@type 0|1|string|nil 0/"ltr" or 1/"rtl"; later the shape() result.
        local direction = segments[i][1]
        ---@type string?
        local thislang = "en"
        if languagecode and publisher.languages_id_lang[languagecode].locale then
            thislang = publisher.languages_id_lang[languagecode].locale
        end
        local thissegment
        local script = nil
        if thislang == "--" then
            thislang = nil
            script = nil
        elseif thislang == "zh" then
            script = "Hans"
        end

        -- U+2060 WORD JOINER is a default ignorable and gets removed by
        -- HarfBuzz (FLAG_REMOVE_DEFAULT_IGNORABLES) before it reaches the
        -- glyph list. Map it to U+0083 (NO BREAK HERE), which survives
        -- shaping as a .notdef glyph and is turned into a no-break
        -- penalty in hbglyphlist (#695).
        str = string.gsub(str, "\226\129\160", "\194\131")

        local newlines_at = {}

        local cluster = {}
        local pos = 0
        for c in unicode.utf8.gmatch(str, ".") do
            cluster[pos] = unicode.utf8.byte(c)
            if c == "\n" then
                newlines_at[pos] = true
            end
            pos = pos + #c
        end
        local buf = publisher.harfbuzz.Buffer.new()
        buf:add_utf8(str)
        if direction == 0 then
            direction = "ltr"
        elseif direction == 1 then
            direction = "rtl"
        end
        -- the numeric bidi directions are converted to strings above
        ---@cast direction string?
        -- shape returns the guessed script and direction from the buffer
        script, direction = publisher.shape(tbl, buf, { language = thislang, script = script, direction = direction })
        local is_cjk = false
        if script == "Hans" or script == "Hira" or script == "Hant" or script == "Hani" then
            is_cjk = true
            -- script can be guessed from buffer and thislang could be empty, so
            -- lang must be set again.
            thislang = "zh"
        elseif script == "Kana" then
            is_cjk = true
            thislang = "ja"
        end

        local glyphs = buf:get_glyphs()
        if #glyphs == 0 then
            goto nextsegment
        end
        thissegment = M.hbglyphlist({
            glyphs = glyphs,
            tbl = tbl,
            cluster = cluster,
            parameter = parameter,
            allowbreak = parameter.allowbreak or " -",
            newlines_at = newlines_at,
            script = script,
            direction = direction or maindirection,
            thislang = thislang,
            fontnumber = fontnumber,
            is_cjk = is_cjk,
        })
        direction = direction or 0
        thissegment = M.setsegmentdir(thissegment, direction, maindirection)

        if nodelistsegments then
            local tail = node.tail(nodelistsegments)
            tail.next = thissegment
            thissegment.prev = tail
        else
            nodelistsegments = thissegment
        end
        ::nextsegment::
    end
    if maindirection then
        publisher.attribute_helpers.setprop(nodelistsegments, "pardir", maindirection)
    end
    if not nodelistsegments then
        local strut = M.add_rule(nil, "head", { height = 1 * publisher.factor, depth = 0, width = 0 }, "pardir")
        return strut, parameter.direction
    end
    return nodelistsegments, maindirection
end

-- Wraps `nodelist` in `dir` whatsits so it is treated as a bidi segment
-- with the given direction inside the surrounding `maindirection`.
---@param nodelist Node
---@param direction integer|string Segment direction (0/`"ltr"` or 1/`"rtl"`).
---@param maindirection? string Surrounding paragraph direction (`"ltr"`/`"rtl"`).
---@return Node head
function M.setsegmentdir(nodelist, direction, maindirection)
    local dirstring
    if direction == 0 or direction == "ltr" then
        dirstring = "TLT"
    elseif direction == 1 or direction == "rtl" then
        dirstring = "TRT"
    end

    -- don't do anything if this segment goes in the paragraph direction
    if (maindirection == nil or maindirection == "ltr") and dirstring == "TLT" then
        return nodelist
    elseif maindirection == "rtl" and dirstring == "TRT" then
        return nodelist
    end

    local dirstart = node.new(publisher.dir_node)
    local dirend = node.new(publisher.dir_node)
    dirstart.dir = "+" .. dirstring
    dirend.dir = "-" .. dirstring
    node.setproperty(dirstart, node.getproperty(nodelist))
    local ff = publisher.attribute_helpers.get_attribute(nodelist, "fontfamily")
    publisher.attribute_helpers.set_attribute(dirstart, "fontfamily", ff)
    nodelist = node.insert_before(nodelist, nodelist, dirstart)

    local tail = node.tail(nodelist)
    local tailff = publisher.attribute_helpers.get_attribute(tail, "fontfamily")
    publisher.attribute_helpers.set_attribute(dirend, "fontfamily", tailff)
    node.setproperty(dirend, node.getproperty(tail))
    node.insert_after(nodelist, tail, dirend)
    return nodelist
end

-- Inserts an hrule at the head or tail of `nodelist`. With a `nil`
-- nodelist the bare rule node is returned.
---@param nodelist Node?
---@param head_or_tail "head"|"tail"
---@param parameter table Rule parameters (`width`, `height`, `depth`, `color`, ...).
---@param origin? string Origin tag (debugging).
---@return Node nodelist
---@return Node? rule The rule node (only in the "tail" case).
function M.add_rule(nodelist, head_or_tail, parameter, origin)
    parameter = parameter or {}

    local n = node.new(publisher.rule_node)
    n.width = parameter.width
    n.height = parameter.height
    n.depth = parameter.depth
    if origin then
        publisher.attribute_helpers.setprop(n, "origin", origin)
    end
    if not nodelist then
        return n
    end

    if head_or_tail == "head" then
        nodelist = node.insert_before(nodelist, nodelist, n)
        return nodelist
    else
        local last = node.slide(nodelist)
        last.next = n
        n.prev = last
        return nodelist, n
    end
    ---@diagnostic disable-next-line: unreachable-code
    assert(false, "never reached") -- luacheck: ignore 511
end

-- Returns an hbox containing a bullet glyph, sized to fill `labelwidth`.
---@param labelwidth integer Target width in sp.
---@param parameter table Style parameters (font, color, ...).
---@return Node hbox
function M.bullet_hbox(labelwidth, parameter)
    local bullet, pre_glue, post_glue
    bullet = M.mknodes("•", parameter)
    pre_glue = set_glue(nil, { stretch = 2 ^ 16, stretch_order = 3 })
    pre_glue.next = bullet

    post_glue = set_glue(nil, { width = 4 * 2 ^ 16 })
    post_glue.prev = bullet
    bullet.next = post_glue
    local bullet_hbox = node.hpack(pre_glue, labelwidth, "exactly")

    if publisher.options.showobjects then
        publisher.drawing.boxit(bullet_hbox)
    end
    publisher.attribute_helpers.set_attribute(bullet_hbox, "indent", labelwidth)
    node.set_attribute(bullet_hbox, publisher.att_rows, -1)
    return bullet_hbox
end

-- Returns an hbox containing a numeric label (`num.`), sized to fill
-- `labelwidth`.
---@param num integer Label number.
---@param labelwidth integer Target width in sp.
---@param parameter table Style parameters.
---@return Node hbox
function M.number_hbox(num, labelwidth, parameter)
    local pre_glue, post_glue
    local digits = M.mknodes(tostring(num) .. ".", parameter)
    pre_glue = set_glue(nil, { stretch = 2 ^ 16, stretch_order = 3 })
    pre_glue.next = digits

    post_glue = set_glue(nil, { width = 4 * 2 ^ 16 })
    post_glue.prev = node.tail(digits)
    node.tail(digits).next = post_glue
    local digit_hbox = node.hpack(pre_glue, labelwidth, "exactly")

    if publisher.options.showobjects then
        publisher.drawing.boxit(digit_hbox)
    end
    publisher.attribute_helpers.set_attribute(digit_hbox, "indent", labelwidth)
    node.set_attribute(digit_hbox, publisher.att_rows, -1)
    return digit_hbox
end

-- Returns an hbox containing a custom label string, sized to `labelwidth`
-- and aligned according to `labelalign`.
---@param label Node Label contents as a node list.
---@param labelwidth integer Target width in sp.
---@param options table Style options.
---@param labelsep_wd integer Separator width in sp.
---@param labelalign "left"|"center"|"right"
---@return Node hbox
function M.whatever_hbox(label, labelwidth, options, labelsep_wd, labelalign)
    local fam = options.fontfamily
    labelsep_wd = labelsep_wd or fonts.lookup_fontfamily_number_instance[fam].size / 2
    labelalign = labelalign or "right"
    local shrink_glue = set_glue(nil, { shrink = 2 ^ 16, shrink_order = 3, width = labelwidth })
    local label_sep = set_glue(nil, { width = labelsep_wd })

    local label_hbox
    if labelalign == "right" then
        shrink_glue.next = label
        local t = node.slide(label)
        t.next = label_sep
        label_hbox = node.hpack(shrink_glue, labelwidth, "exactly")
    else
        local t = node.slide(label)
        t.next = label_sep
        label_sep.next = shrink_glue
        label_hbox = node.hpack(label, labelwidth, "exactly")
    end
    publisher.attribute_helpers.set_attribute(label_hbox.head, "fontfamily", fam)
    label_hbox.head = M.addstrut(label_hbox.head, "head", "whatever_hbox/strut")

    return label_hbox
end

-- Returns the natural width of a glue node, falling back to the spec when
-- the node has no inline width.
---@param n Node Glue node.
---@return integer width Width in sp.
function M.get_glue_size(n)
    local spec

    if node.has_field(n, "spec") then
        spec = assert(n.spec)
    else
        spec = n
    end
    return spec.width
end

-- Inserts a glue node at the head or tail of `nodelist`.
---@param nodelist Node?
---@param head_or_tail "head"|"tail"
---@param parameter table Glue parameters (`width`, `stretch`, `shrink`, ...).
---@param origin? string Origin tag (debugging).
---@return Node nodelist
---@return Node glue The inserted glue node.
function M.add_glue(nodelist, head_or_tail, parameter, origin)
    parameter = parameter or {}

    local n = set_glue(nil, parameter)
    n.subtype = parameter.subtype or 0
    if origin then
        publisher.attribute_helpers.setprop(n, "origin", origin)
    end
    if nodelist == nil then
        return n, n
    end

    if head_or_tail == "head" then
        n.next = nodelist
        nodelist.prev = n
        return n, n
    else
        local last = node.slide(nodelist)
        last.next = n
        n.prev = last
        return nodelist, n
    end
    ---@diagnostic disable-next-line: unreachable-code
    assert(false, "never reached") -- luacheck: ignore 511
end

-- Returns a glue node that stretches and shrinks like TeX's `\hss`.
---@return Node glue
function M.hss_glue()
    return M.make_glue({ stretch = 2 ^ 16, stretch_order = 2, shrink = 2 ^ 16, shrink_order = 2 })
end

-- Creates a fresh glue node from a parameter table.
---@param parameter table Glue parameters (`width`, `stretch`, `shrink`, ...).
---@return Node glue
function M.make_glue(parameter)
    return set_glue(nil, parameter)
end

-- Walks `head` and propagates the surrounding glyph properties onto the
-- replacement glyphs of each disc (hyphenation) node so they pick up the
-- correct font/color when chosen.
---@param head Node
---@return nil
local function add_properties_to_discnodes(head)
    while head do
        if head.id == publisher.glyph_node and head.next and head.next.id == publisher.disc_node then
            local role = publisher.attribute_helpers.getprop(head, "role")
            local parent = publisher.attribute_helpers.getprop(head, "parent")
            local rolecounter = publisher.attribute_helpers.getprop(head, "rolecounter")
            local id = publisher.attribute_helpers.getprop(head, "id")
            if head.next.pre then
                publisher.attribute_helpers.setprop(head.next.pre, "role", role)
                publisher.attribute_helpers.setprop(head.next.pre, "parent", parent)
                publisher.attribute_helpers.setprop(head.next.pre, "rolecounter", rolecounter)
                publisher.attribute_helpers.setprop(head.next.pre, "id", id)
            end
            if head.next.post then
                publisher.attribute_helpers.setprop(head.next.post, "role", role)
                publisher.attribute_helpers.setprop(head.next.post, "parent", parent)
                publisher.attribute_helpers.setprop(head.next.post, "rolecounter", rolecounter)
                publisher.attribute_helpers.setprop(head.next.post, "id", id)
            end
            if head.next.replace then
                publisher.attribute_helpers.setprop(head.next.replace, "role", role)
                publisher.attribute_helpers.setprop(head.next.replace, "parent", parent)
                publisher.attribute_helpers.setprop(head.next.replace, "rolecounter", rolecounter)
                publisher.attribute_helpers.setprop(head.next.replace, "id", id)
            end
        end
        head = head.next
    end
end

-- Closes a paragraph node list: adds the par-end glue, applies
-- justification settings and triggers line breaking via `do_linebreak`.
---@param nodelist Node
---@param _hsize integer? Unused; the line width is applied in `do_linebreak`.
---@param parameters table Paragraph parameters (alignment, indent, ...).
---@return nil
function M.finish_par(nodelist, _hsize, parameters)
    assert(nodelist)
    node.slide(nodelist)

    if not parameters.disable_hyphenation then
        lang.hyphenate(nodelist)

        if publisher.options.format == "PDF/UA" then
            add_properties_to_discnodes(nodelist)
        end
    end

    local n = node.new("penalty")
    publisher.attribute_helpers.setprop(n, "origin", "finishpar")
    n.penalty = 10000
    local last = node.slide(nodelist)

    last.next = n
    n.prev = last

    -- mode harfbuzz sets haskerns, different kind of kerning
    n = node.kerning(nodelist)
    n = M.hbkern(n)
    -- 15 is a parfillskip
    M.add_glue(n, "tail", { subtype = 15, width = 0, stretch = 2 ^ 16, stretch_order = 2 })
end

-- Inserts kern nodes between glyphs for HarfBuzz-shaped runs (font kerning
-- is applied here rather than in TeX itself).
---@param nodelist Node
---@return Node nodelist
function M.hbkern(nodelist)
    ---@type integer?
    local head = d_todirect(nodelist)
    local start = assert(head)
    local curkern = 0
    while head do
        local id = d_getid(head)
        if id == publisher.glyph_node then
            local props = d_getproperty(head)
            if props then
                local k = props.kernbefore
                if k then
                    props.kernbefore = nil
                    if k ~= 0 then
                        curkern = k
                    end
                end
            end

            if curkern ~= 0 then
                local kern = d_new(publisher.kern_node)
                d_setkern(kern, curkern)
                start = d_insert_before(start, head, kern)
                local ul = d_has_attribute(head, att_td_line)
                if ul then
                    d_set_attribute(kern, att_td_line, ul)
                end
                local uccolor = d_has_attribute(head, att_td_color)
                if uccolor then
                    d_set_attribute(kern, att_td_color, uccolor)
                end
                local bgcolor = d_has_attribute(head, att_bgcolor)
                if bgcolor then
                    d_set_attribute(kern, att_bgcolor, bgcolor)
                end
                d_setproperty(kern, d_getproperty(head))
                local hl = d_has_attribute(head, att_hyperlink)
                if hl then
                    d_set_attribute(kern, att_hyperlink, hl)
                end
                curkern = 0
            end
            if props then
                local k = props.kernafter
                if k and k ~= 0 then
                    curkern = k
                end
            end
        elseif id == publisher.disc_node then
            if curkern ~= 0 then
                local kern = d_new(publisher.kern_node)
                d_setkern(kern, curkern)
                -- Prepend the kern to the disc's existing replace list instead of
                -- overwriting it. lang.hyphenate turns an explicit hyphen into an
                -- automatic discretionary whose replace text holds the hyphen glyph;
                -- a blind d_setfield(head, "replace", kern) would discard that glyph
                -- and the hyphen would vanish whenever HarfBuzz kerned in front of it.
                local oldreplace = d_getfield(head, "replace")
                d_setfield(head, "replace", kern)
                if oldreplace then
                    d_setlink(kern, oldreplace)
                end
                local ul = d_has_attribute(head, att_td_line)
                local uccolor = d_has_attribute(head, att_td_color)
                local bgcolor = d_has_attribute(head, att_bgcolor)
                local hyperlink = d_has_attribute(head, att_hyperlink)
                if ul then
                    d_set_attribute(kern, att_td_line, ul)
                end
                if uccolor then
                    d_set_attribute(kern, att_td_color, uccolor)
                end
                if bgcolor then
                    d_set_attribute(kern, att_bgcolor, bgcolor)
                end
                if hyperlink then
                    d_set_attribute(kern, att_hyperlink, hyperlink)
                end
                d_setproperty(kern, d_getproperty(head))
                curkern = 0
            end
        else
            curkern = 0
        end
        head = d_getnext(head)
    end
    return d_tonode(start)
end

-- Adjusts a linebroken paragraph for a given alignment by re-glueing
-- the line ends and replacing parfillskip with the appropriate spec.
---@param nodelist Node Linebroken paragraph (head).
---@param alignment TextformatAlignment
---@param _parent? Node Unused.
---@param direction? string Paragraph direction (`"ltr"`/`"rtl"`).
---@return Node nodelist
function M.fix_justification(nodelist, alignment, _parent, direction)
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

            for n in node.traverse(head.head) do
                if n.id == publisher.glyph_node then
                    font_before_glue = n.font
                elseif n.id == publisher.glue_node then
                    if
                        n.subtype == 0
                        and font_before_glue
                        and get_glue_value(n, "width") > 0
                        and head.glue_sign == 1
                        and not publisher.attribute_helpers.getprop(n, "hspace_fixed")
                    then
                        local fonttable = font.fonts[font_before_glue]
                        if not fonttable then
                            fonttable = font.fonts[1]
                            main.log("error", "Some font not found")
                        end
                        set_glue_values(n, {
                            width = fonttable.parameters.space,
                            shrink_order = head.glue_order,
                            stretch = 0,
                            stretch_order = 0,
                        })
                    end
                end
            end

            if curalignment == "rightaligned" or curalignment == "centered" then
                local rightskip_node = node.tail(head.head)

                -- first we remove everything between the rightskip and the
                -- last non-glue/non-penalty item
                -- the glues might contain "plus 1 fill" and the penalties are not
                -- useful
                local tmp = rightskip_node.prev
                while
                    tmp
                    and (
                        tmp.id == publisher.glue_node
                        or tmp.id == publisher.penalty_node
                        or tmp.id == publisher.dir_node
                    )
                do
                    tmp = tmp.prev
                    if tmp == nil then
                        break
                    end
                    head.head = node.remove(head.head, tmp.next)
                end

                local wd = node.dimensions(head.glue_set, head.glue_sign, head.glue_order, head.head)

                local leftskip_node
                if curalignment == "rightaligned" then
                    leftskip_node = set_glue(nil, { width = goal - wd })
                else
                    leftskip_node = set_glue(nil, { width = (goal - wd) / 2 })
                end
                head.head = node.insert_before(head.head, head.head, leftskip_node)
            end
        elseif head.id == 1 then -- vlist
            M.fix_justification(head.head, alignment, head, direction)
        end
        head = head.next
    end
    return nodelist
end

-- Returns `true` if any line in `nodelist` exceeds `wd` after line breaking.
---@param nodelist Node Vbox of lines.
---@param wd integer Target line width in sp.
---@return boolean
local function check_if_a_line_exeeds(nodelist, wd)
    local head = nodelist
    while head do
        if head.id == publisher.vlist_node then
            return check_if_a_line_exeeds(head.head, wd)
        elseif head.id == publisher.hlist_node then
            local width = node.dimensions(head.glue_set, head.glue_sign, head.glue_order, head.head)
            if width > wd + 400 then
                return true
            end
        end
        head = head.next
    end
    return false
end

-- Performs Knuth-Plass line breaking on the paragraph `nodelist` to fit
-- `hsize`. Honors `parameters` such as `tolerance`, `parshape`, hyphen
-- character overrides, language settings, etc.
---@param nodelist Node Paragraph node list (head).
---@param hsize integer Target line width in sp.
---@param parameters table Line-break parameters.
---@return Node head Linebroken vbox.
function M.do_linebreak(nodelist, hsize, parameters)
    if nodelist == nil then
        main.log("error", "No nodelist found for line breaking.")
        return publisher.drawing.box(publisher.tenmm_sp, publisher.tenmm_sp, "black")
    end

    parameters = parameters or {}
    M.finish_par(nodelist, hsize, parameters)

    local pdfignoreddimen
    pdfignoreddimen = -65536000

    local default_parameters = {
        hsize = hsize,
        emergencystretch = 0.1 * hsize,
        hyphenpenalty = 0,
        linepenalty = 10,
        pretolerance = 0,
        tolerance = 2000,
        doublehyphendemerits = 1000,
        pdfeachlineheight = pdfignoreddimen,
        pdfeachlinedepth = pdfignoreddimen,
        pdflastlinedepth = pdfignoreddimen,
        pdfignoreddimen = pdfignoreddimen,
    }

    -- This could be done with a meta table, but somehow LuaTeX 104 doesn't like it
    for k, v in pairs(parameters) do
        default_parameters[k] = v
    end

    -- Try to break the paragraph until there is no line
    -- longer than expected
    local j
    local c = 0
    local line_exceeds_right_margin = true
    while true do
        j = tex.linebreak(node.copy_list(nodelist), default_parameters)
        if not check_if_a_line_exeeds(j, hsize) then
            line_exceeds_right_margin = false
            break
        end
        default_parameters.emergencystretch = default_parameters.emergencystretch + 0.1 * hsize
        c = c + 1
        if c > 9 then
            break
        end
        node.flush_list(j)
    end

    if line_exceeds_right_margin and publisher.options.overfulllineerror ~= nil then
        if publisher.options.overfulllineerror then
            main.log("error", "Overfull line found", "page", publisher.current_pagenumber, publisher.lineinfo())
        else
            main.log("warn", "Overfull line found", "page", publisher.current_pagenumber, publisher.lineinfo())
        end
    end
    node.flush_list(nodelist)

    -- Adjust line heights. Always take the largest font in a row.
    -- Use direct node API for speed in this tight loop.
    local dhead = d_todirect(j)
    local maxlineheight
    local fam
    local _h, _d
    local lookup_fam = fonts.lookup_fontfamily_number_instance
    ---@type integer?
    local cur = dhead
    while cur do
        if d_getid(cur) == publisher.hlist_node then
            local lineheight
            maxlineheight = 0
            local head_list = d_getlist(cur)
            local adjustlineheight = true
            while head_list do
                if not lineheight then
                    lineheight = d_has_attribute(head_list, publisher.att_lineheight)
                end
                if d_has_attribute(head_list, publisher.att_dontadjustlineheight) then
                    adjustlineheight = false
                end
                local hlid = d_getid(head_list)
                if hlid == publisher.hlist_node or hlid == publisher.vlist_node then
                    local sublist = d_getlist(head_list)
                    if sublist then
                        _, _h, _d = d_dimensions(sublist)
                        local total = _h + _d
                        if total > maxlineheight then
                            maxlineheight = total
                        end
                    end
                else
                    fam = d_has_attribute(head_list, att_fontfamily)
                    if fam and fam > 0 then
                        local bls = lookup_fam[fam].baselineskip
                        if bls > maxlineheight then
                            maxlineheight = bls
                        end
                    end
                end
                head_list = d_getnext(head_list)
            end
            if adjustlineheight then
                if lineheight and lineheight > 0.75 * maxlineheight then
                    d_setfield(cur, "height", lineheight)
                    d_setfield(cur, "depth", 0.25 * maxlineheight)
                else
                    d_setfield(cur, "height", 0.75 * maxlineheight)
                    d_setfield(cur, "depth", 0.25 * maxlineheight)
                end
            end
        end
        cur = d_getnext(cur)
    end
    local ret = node.vpack(j)
    publisher.attribute_helpers.setprop(ret, "origin", "do_linebreak")
    return ret
end

-- Creates an empty vbox of the given dimensions.
---@param wd integer Width in sp.
---@param ht integer Height in sp.
---@return Node vbox
function M.create_empty_vbox_width_width_height(wd, ht)
    local hb = M.create_empty_hbox_with_width(wd)
    local n = set_glue(nil, { width = 0, stretch = 2 ^ 16, stretch_order = 3 })
    node.insert_after(hb, hb, n)
    n = node.vpack(n, ht, "exactly")
    node.set_attribute(n, publisher.att_dontadjustlineheight, 1)
    return n
end

-- Creates an empty hbox of the given width.
---@param wd integer Width in sp.
---@return Node hbox
function M.create_empty_hbox_with_width(wd)
    local n = set_glue(nil, { width = 0, stretch = 2 ^ 16, stretch_order = 3 })
    n = node.hpack(n, wd, "exactly")
    return n
end

-- Wraps `nodelist` in color-stack literals if `color` differs from the
-- surrounding default; passes the list through unchanged otherwise.
---@param nodelist Node
---@param color integer Color index from `colortable`.
---@return Node nodelist
function M.set_color_if_necessary(nodelist, color)
    local dontformat = node.has_attribute(nodelist, publisher.att_dont_format)

    if not color then
        return nodelist
    end

    local colorname
    if color == -1 then
        colorname = "black"
    else
        colorname = colors_module.colortable[color]
    end
    -- When we uncomment the if .. end here, the typesetting
    -- process is much slower. See #143
    if colorname == "black" then
        return nodelist
    end
    local colstart, colstop
    colstart = node.new("whatsit", "pdf_colorstack")
    colstop = node.new("whatsit", "pdf_colorstack")
    colstart.data = colors_module.colors[colorname].pdfstring
    colstop.data = ""
    colstart.command = 1
    colstop.command = 2
    colstart.stack = publisher.defaultcolorstack
    colstop.stack = publisher.defaultcolorstack

    if dontformat then
        node.set_attribute(colstart, publisher.att_dont_format, dontformat)
    end

    nodelist = node.insert_before(nodelist, nodelist, colstart)
    local last = node.tail(nodelist)
    nodelist = node.insert_after(nodelist, last, colstop)

    publisher.attribute_helpers.setprop(colstart, "origin", "setcolorifnecessary")
    publisher.attribute_helpers.setprop(colstop, "origin", "setcolorifnecessary")
    return nodelist
end

-- Sets the font family attribute on every glyph in `nodelist` that does
-- not already carry one.
---@param nodelist Node
---@param fontfamily integer Font family number.
---@return nil
function M.set_fontfamily_if_necessary(nodelist, fontfamily)
    local fam
    while nodelist do
        if nodelist.id == publisher.vlist_node or nodelist.id == publisher.hlist_node then
            fam = M.set_fontfamily_if_necessary(nodelist.list, fontfamily)
        elseif nodelist.id == publisher.glue_node and nodelist.subtype == 100 then
            fam = M.set_fontfamily_if_necessary(nodelist.leader, fontfamily)
        else
            fam = publisher.attribute_helpers.get_attribute(nodelist, "fontfamily")
            -- See #242, #235 and referenced bugs (and change 5af208f)
            if
                fam == 0
                or (
                    fam == nil
                    and nodelist.id == publisher.rule_node
                    and publisher.attribute_helpers.get_attribute(nodelist, "publisher") == 1
                )
            then
                publisher.attribute_helpers.set_attribute(nodelist, "fontfamily", fontfamily)
                fam = fontfamily
            end
        end
        nodelist = nodelist.next
    end
    return fam
end

-- Inserts hyphenation hints into a URL node list so it can break at
-- structural characters (`/`, `.`, `?`, `&`, ...).
---@param nodelist Node
---@return Node nodelist
function M.break_url(nodelist)
    local p

    local slash = string.byte("/")
    for n in node.traverse_id(publisher.glyph_node, nodelist) do
        p = node.new("penalty")

        if n.char == slash then
            p.penalty = -10
        else
            p.penalty = -5
        end
        publisher.attribute_helpers.set_attribute(
            p,
            "hyperlink",
            publisher.attribute_helpers.get_attribute(n, "hyperlink")
        )
        p.next = n.next
        if n.next and n.next.prev then
            n.next.prev = p
        end
        n.next = p
        p.prev = n
    end
    return nodelist
end

file_end("nodes.lua")

return M
