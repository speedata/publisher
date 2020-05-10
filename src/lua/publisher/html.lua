--
--  html.lua
--  speedata publisher
--  new HTML parser
--
--  for a list of authors see `git blame'
--  see file copying in the root directory for license info.

-- This is for the new HTML parser

module(...,package.seeall)
require("Box")
local fontfamilies = {}

local stylesstackmetatable = {
    __newindex = function(tbl, idx, value)
        rawset(tbl, idx, value)
        value.pos = #tbl
    end
}

inherited = {
    width = false,
    fontsize_sp = true,
    calculated_width = true,
    ollevel = true,
    ullevel = true,
    ["border-collapse"] = true,
    ["border-spacing"] = true,
    ["caption-side"] = true,
    ["color"] = true,
    ["direction"] = true,
    ["empty-cells"] = true,
    ["font-family"] = true,
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
    ["text-indent"] = true,
    ["text-transform"] = true,
    ["visibility"] = true,
    ["white-space"] = true,
    ["widows"] = true,
    ["word-spacing"] = true
}

local stylesstack = setmetatable({}, stylesstackmetatable)
local levelmt = {
    __index = function(tbl, idx)
        if tbl.pos == 1 then
            return nil
        end
        if inherited[idx] then
            -- w("idx %q",tostring(idx))
            return stylesstack[tbl.pos - 1][idx]
        else
            return nil
        end
    end
}
local styles = setmetatable({}, levelmt)
stylesstack[#stylesstack + 1] = styles

local function familyname( fontfamily )
    if fontfamilies[fontfamily] then
        return fontfamilies[fontfamily]
    elseif publisher.fontgroup[fontfamily] then
        return publisher.fontgroup[fontfamily]
    else
        return publisher.fontgroup["sans-serif"]
    end
end

local function get_fontfamily( family, size_sp , name )
    local fontname = family .. "/" .. name
    local predefined_fam = publisher.fonts.lookup_fontfamily_name_number[fontname]
    if predefined_fam then
        return predefined_fam
    end
    family = familyname(family)
    local regular,bold,italic,bolditalic
    for weightstyle,name in pairs(family) do
        local fontname = publisher.fonts.get_fontname(name["local"],name["url"])
        if weightstyle == "regular" then regular = fontname end
        if weightstyle == "bold" then bold = fontname end
        if weightstyle == "italic" then italic = fontname end
        if weightstyle == "bolditalic" then bolditalic = fontname end
    end
    local fam = publisher.define_fontfamily(regular,bold,italic,bolditalic,fontname,size_sp,size_sp * 1.12)
    return fam
end

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

function parse_html_inner( elt )
    local lasthorizontal
    local delete = {}
    for i=1, #elt do
        local thiselt = elt[i]
        local typ = type(thiselt)
        if typ == "table" and thiselt.direction == "↓" then
            parse_html_inner(thiselt)
            lasthorizontal = nil
        end
        if typ == "string" or ( typ == "table" and thiselt.direction == "→" ) then
            if lasthorizontal then
                local lasthorizontalelt = elt[lasthorizontal]
                lasthorizontalelt[#lasthorizontalelt + 1] = thiselt
                delete[#delete + 1] = i
            else
                elt[i] = {mode = "horizontal",thiselt}
                lasthorizontal = i
            end
        end
    end
    for i=#delete,1,-1 do
        table.remove(elt,delete[i])
    end
end

function calculate_height( attribute_height, original_size )
    if string.match(attribute_height, "%d+%%$") then
        -- xx percent
        local amount = string.match(attribute_height, "(%d+)%%$")
        original_size = math.round(original_size * tonumber(amount) / 100, 0)
        return original_size
    else
        err("not implemented yet, calculate_height")
        return original_size
    end

end

function set_calculated_width(styles)
    if type(styles.calculated_width) == "number" then
    end
    local sw = styles.width or "auto"
    local cw = styles.calculated_width
    if string.match(sw, "%d+%%$") then
        -- xx percent
        local amount = string.match(sw, "(%d+)%%$")
        cw = math.round(cw * tonumber(amount) / 100, 0)
    elseif sw == "auto" then
        cw = styles.calculated_width
        if styles.height and styles.height ~= "auto" then
            styles.height = tex.sp(styles.height)
        else
            styles.height = nil
        end
        local padding_left = styles["padding-left"]
        local padding_right = styles["padding-right"]
        local margin_left = styles["margin-left"]
        local margin_right = styles["margin-right"]
        local border_left = styles["border-left-width"]
        local border_right = styles["border-right-width"]
        if padding_left then
            cw = cw - tex.sp(padding_left)
        end
        if padding_right then
            cw = cw - tex.sp(padding_right)
        end
        if margin_left then
            cw = cw - tex.sp(margin_left)
        end
        if margin_right then
            cw = cw - tex.sp(margin_right)
        end
        if border_left then
            cw = cw - tex.sp(border_left)
        end
        if border_right then
            cw = cw - tex.sp(border_right)
        end
    elseif tex.sp(sw) then
        -- a length
        cw = tex.sp(sw)
    end
    styles.calculated_width = cw
end

function copy_attributes( styles,attributes )
    for k, v in pairs(attributes) do
        if k == "font-size" then
            local fontsize
            if string.match(v, "em$") then
                local amount = string.gsub(v, "^(.*)r?em$", "%1")
                local fontsize = math.round(styles.fontsize_sp * amount)
                styles.fontsize_sp = fontsize
            else
                styles.fontsize_sp = tex.sp(v)
            end
        elseif k == "width" then
            styles.width = v
            set_calculated_width(styles)
        end
        styles[k] = v
    end
end

function collect_horizontal_nodes( elt,parameter )
    parameter = parameter or {}

    local ret = {}
    for i=1,#elt do
        local styles = setmetatable({}, levelmt)
        stylesstack[#stylesstack + 1] = styles

        local options = {}
        for k,v in pairs(parameter) do
            options[k] = v
        end
        local thiselt = elt[i]
        local typ = type(thiselt)

        local attributes = thiselt.attributes or {}
        copy_attributes(styles,attributes)
        local fontfamily = styles["font-family"]
        local fontsize = styles["font-size"]
        local fontname = fontsize
        options.fontfamily = get_fontfamily(fontfamily,styles.fontsize_sp, fontname)
        local fontstyle = styles["font-style"]
        local fontweight = styles["font-weight"]
        local fg_colorindex, bg_colorindex
        local backgroundcolor = styles["background-color"]
        if styles.color then
            fg_colorindex = publisher.colors[styles.color].index
            options.add_attributes = { { publisher.att_fgcolor, fg_colorindex }}
        end
        if backgroundcolor then
            bg_colorindex = publisher.colors[backgroundcolor].index
            options.backgroundcolor = bg_colorindex
        end

        local textdecoration = styles["text-decoration"]
        local verticalalign = styles["vertical-align"]
        local whitespace = styles["white-space"]

        if fontweight == "bold" then options.bold = 1 end
        if fontstyle == "italic" then options.italic = 1 end
        if whitespace == "pre" then options.whitespace = "pre" end
        if textdecoration == "underline" then options.underline = 1 end
        if verticalalign == "super" then
            options.script = 2
        elseif verticalalign == "sub" then
            options.script = 1
        end

        if typ == "string" then
            ret[#ret + 1] = publisher.mknodes(thiselt,options.fontfamily,options)
        elseif typ == "table" then
            local attributes = thiselt.attributes or {}
            local eltname = thiselt.elementname
            if eltname == "a" then
                local href = attributes["href"]
                publisher.hyperlinks[#publisher.hyperlinks + 1] = string.format("/Subtype/Link/A<</Type/Action/S/URI/URI(%s)>>",href)
                options.add_attributes = { { publisher.att_hyperlink, #publisher.hyperlinks } }
            elseif eltname == "img" then
                local source = attributes.src
                local it = publisher.new_image(source,1,nil,nil)
                -- if we don#t copy the image, the changed size settings would
                -- affect future images with the same name
                it = img.copy(it.img)
                local orig_imagewidth, orig_imageheight = it.width, it.height
                local imagewidth, imageheight = orig_imagewidth, orig_imageheight
                -- Todo: check if width _and_ height are set
                local factor = 1
                if attributes.width then
                    imagewidth = tex.sp(styles.calculated_width)
                    factor = orig_imagewidth / imagewidth
                end
                if attributes.height then
                    imageheight = tex.sp(imageheight)
                    imageheight = calculate_height(attributes.height,orig_imageheight)
                    factor = orig_imageheight / imageheight
                end
                if factor ~= 1 then
                    imagewidth = orig_imagewidth / factor
                    imageheight = orig_imageheight / factor
                end

                local maxwd = xpath.get_variable("__maxwidth")
                local maxht = xpath.get_variable("__maxheight")
                maxht = maxht - styles.fontsize_sp * 0.25
                local calc_width, calc_height = publisher.calculate_image_width_height(it,imagewidth,imageheight,0,0,maxwd,maxht)
                it.width = calc_width
                it.height = calc_height
                local box = publisher.box(calc_width,calc_height,"-")
                node.set_attribute(box,publisher.att_dontadjustlineheight,1)
                node.set_attribute(box,publisher.att_ignore_orphan_widowsetting,1)
                box.head = node.insert_before(box.head,box.head,img.node(it))
                ret[#ret + 1] = box
            end
            local n = collect_horizontal_nodes(thiselt,options)
            for i=1,#n do
                ret[#ret + 1] = n[i]
            end
        end
        table.remove(stylesstack)
    end
    return ret
end

function trim_space_end( nodelist )
    local t = node.tail(nodelist)
    if t.id == publisher.glue_node then
        if t.prev then t.prev.next = nil end
    end
    return nodelist
end

function trim_space_beginning( nodelist )
    if nodelist.id == publisher.glue_node then
        nodelist=nodelist.next
    end
    return nodelist
end

function build_html_table_tbody(elt)
    local trtab = {}
    for i=1,#elt do
        local tdtab = {}
        local tr = elt[i]
        local typtr = type(tr)
        if typtr=="table" then
            for j=1,#tr do
                local td = tr[j]
                local r = collect_horizontal_nodes(td)
                local a = paragraph:new()
                a:append(r)
                local newtd = { elementname = "Paragraph" , contents = a }
                tdtab[#tdtab + 1] = { elementname = "Td", contents = { newtd } }
            end
            trtab[#trtab + 1] = { elementname = "Tr", contents =  tdtab  }
        else
            -- ignore
        end
    end
    local tabular = publisher.tabular:new()
    tabular.width = xpath.get_variable("__maxwidth")

    tabular.tab = trtab
    local fontname = "text"
    local fontfamily = publisher.fonts.lookup_fontfamily_name_number[fontname]
    local save_fontfamily = publisher.current_fontfamily
    publisher.current_fontfamily = fontfamily

    if fontfamily == nil then
        err("Fontfamily %q not found.",fontname or "???")
        fontfamily = 1
    end

    tabular.fontfamily = fontfamily
    tabular.options ={ ht_max=99999*2^16 }
    tabular.padding_left   = 0
    tabular.padding_top    = 0
    tabular.padding_right  = 0
    tabular.padding_bottom = 0
    tabular.colsep         = tex.sp("2pt")
    tabular.rowsep         = 0

    local n = tabular:make_table()
    return n[1]
end

function build_html_table( elt )
    local tablecontents = elt[1]
    for i=1,#tablecontents do
        local thiselt = tablecontents[i]
        local typ = type(thiselt)
        if typ == "table" and thiselt.elementname == "tbody" then
            local ret = build_html_table_tbody(thiselt)
            return ret
        else
            -- err("Unknown element in HTML table %q",tostring(thiselt.elementname))
        end
    end
end

local function getsize(size,fontsize)
    if size == nil then return 0 end
    size = size or 0
    local ret
    if string.match(size, "em$") then
        local amount = string.gsub(size, "^(.*)r?em$", "%1")
        ret = math.round(fontsize * amount)
    else
        ret = tex.sp(size)
    end
    return ret
end

local olcounter = {}
function build_nodelist( elt )
    local ret = {}
    for i=1,#elt do
        local thiselt = elt[i]
        local thiseltname = thiselt.elementname
        local typ = type(thiselt)

        local styles = setmetatable({}, levelmt)
        stylesstack[#stylesstack + 1] = styles
        if thiseltname == "body" then
            styles.ollevel = 0
            styles.ullevel = 0
        end

        local attributes = thiselt.attributes or {}
        copy_attributes(styles,attributes)

        local fontfamily = styles["font-family"]
        local fontsize = styles["font-size"]
        local fontname = fontsize
        local fam = get_fontfamily(fontfamily,styles.fontsize_sp,fontname)


        local margintop = getsize(styles["margin-top"],styles.fontsize_sp)

        local textalign = styles["text-align"]
        local textformat = "left"
        if textalign == "right" then
            textformat = "right"
        elseif textalign == "center" then
            textformat = "centered"
        elseif textalign == "justify" then
            textformat = "justified"
        end
        if thiselt.mode == "horizontal" then
            local n = collect_horizontal_nodes(thiselt)
            local a = paragraph:new(textformat)

            for i=1,#n do
                local thisn = n[i]
                if i == 1 then
                    thisn = trim_space_beginning(thisn)
                elseif i == #n then
                    thisn = trim_space_end(thisn)
                end

                if thisn then
                    a:append(thisn)
                end
            end
            if a.nodelist then
                ret[#ret + 1] = a
            end
        else
            if thiseltname == "table" then
                local nl = build_html_table(thiselt)
                local box = Box:new()
                local tabpar = paragraph:new()
                box[#box + 1] = tabpar
                node.set_attribute(nl,publisher.att_lineheight,nl.height)
                tabpar:append(nl)
                box.margintop = margintop
                ret[#ret + 1] = box
            elseif thiseltname == "ol" or thiseltname == "ul" then
                if thiseltname == "ol" then
                    styles.ollevel = styles.ollevel + 1
                else
                    styles.ullevel = styles.ullevel + 1
                end
                olcounter[styles.ollevel] = 0
                local n = build_nodelist(thiselt)
                if thiseltname == "ol" then
                    styles.ollevel = styles.ollevel - 1
                else
                    styles.ullevel = styles.ullevel - 1
                end
                local box = Box:new()
                for i=1,#n do
                    box[#box + 1] = n[i]
                end
                box.indent = tex.sp("20pt")
                ret[#ret + 1] = box
            elseif thiseltname == "li" then
                olcounter[styles.ollevel] = olcounter[styles.ollevel] + 1
                local str = resolve_list_style_type(styles,olcounter)
                local n = build_nodelist(thiselt)
                for i=1,#n do
                    local a = n[i]
                    if i == 1 then
                        local x = publisher.whatever_hbox(str,tex.sp("20pt"),fam)
                        a:prepend(x)
                    end
                    ret[#ret + 1] = a
                end
            else
                local n = build_nodelist(thiselt)
                local box = Box:new()
                for i=1,#n do
                    box[#box + 1] = n[i]
                end

                box.margintop = margintop
                ret[#ret + 1] = box
            end
        end
        table.remove(stylesstack)
    end
    return ret
end

function resolve_list_style_type(styles, olcounter)
    local liststyletype = styles["list-style-type"]
    local counter  = olcounter[styles.ollevel]
    local ullevel = styles.ullevel
    local str
    if liststyletype == "decimal" then
        str = tostring(counter) .. "."
    elseif liststyletype == "lower-roman" then
        str = tex.romannumeral(counter) .. "."
    elseif liststyletype == "upper-roman" then
        str = string.upper( tex.romannumeral(counter) ) .. "."
    else
        if ullevel == 1 then
            str = "•"
        elseif ullevel == 2 then
            str = "◦"
        else
            str = ""
        end
    end
    return str
end

function clearattributes( elt )
    elt.attributes = nil
    for i=1,#elt do
        if type(elt[i]) == "table" then
            clearattributes(elt[i])
        end
    end
end

function handle_pages( pages )
    -- defaults:
    xpath.set_variable("__maxwidth",tex.pagewidth)
    xpath.set_variable("__maxheight",tex.pageheight)

    local masterpage = pages["*"]
    if masterpage then
        if masterpage.width then
            local wd = tex.sp(masterpage.width)
            xpath.set_variable("_pagewidth",masterpage.width)
            if masterpage.height then
                xpath.set_variable("_pageheight",masterpage.height)
                local ht = tex.sp(masterpage.height)
                publisher.set_pageformat(wd,ht)
                xpath.set_variable("__maxwidth",wd)
                xpath.set_variable("__maxheight",ht)
            end
        end
        local margin_left, margin_right, margin_bottom, margin_top = publisher.tenmm_sp, publisher.tenmm_sp, publisher.tenmm_sp, publisher.tenmm_sp
        local mt, mr, mb, ml = masterpage["margin-top"], masterpage["margin-right"], masterpage["margin-bottom"], masterpage["margin-left"]
        if mt then margin_top = tex.sp(mt) end
        if mr then margin_right = tex.sp(mr) end
        if mb then margin_bottom = tex.sp(mb) end
        if ml then margin_left = tex.sp(ml) end
        publisher.masterpages[1] = { is_pagetype = "true()", res = { {elementname = "Margin", contents = function(_page) _page.grid:set_margin(margin_left,margin_top,margin_right,margin_bottom) end }}, name = "Default Page",ns={[""] = "urn:speedata.de:2009/publisher/en" } }

    end
end

function parse_html_new( elt )
    handle_pages(elt.pages)
    fontfamilies = elt.fontfamilies
    elt.fontfamilies = nil
    elt[1].attributes.calculated_width = xpath.get_variable("__maxwidth")
    parse_html_inner(elt[1])
    local block = build_nodelist(elt)
    return block
end
