--
--  html.lua
--  speedata publisher
--  new HTML parser
--
--  for a list of authors see `git blame'
--  see file copying in the root directory for license info.

-- This is for the new HTML parser

module(...,package.seeall)
require("box")


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

local function getsize(size,fontsize)
    if size == nil then return 0 end
    size = size or 0
    local ret
    if string.match(size, "em$") then
        local amount = string.gsub(size, "^(.*)r?em$", "%1")
        ret = math.round(fontsize * amount)
    elseif tonumber(size) then
        ret = tex.sp(size .. "px")
    else
        ret = tex.sp(size)
    end
    return ret
end

local function familyname( fontfamily )
    if fontfamilies[fontfamily] then
        return fontfamilies[fontfamily]
    elseif publisher.fontgroup[fontfamily] then
        return publisher.fontgroup[fontfamily]
    else
        return publisher.fontgroup["sans-serif"]
    end
end

local function get_fontfamily( family, size_sp , name, styles )
    local fontfamilynumber = tonumber(styles["font-family-number"])
    if fontfamilynumber and fontfamilynumber > 0 then return fontfamilynumber end

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
    elseif tonumber(attribute_height) then
        return attribute_height
    else
        err("not implemented yet, calculate_height")
        return original_size
    end
end

-- function draw_border(nodelists, attributes,styles)
--     if not attributes then
--         return nodelists
--     end
--     if not attributes.has_border then return nodelists end
--     local ret = {}

--     lineheight = styles.lineheight_sp
--     local factor = publisher.factor

--     local padding_top = attributes["padding-top"] or 0
--     local padding_right = attributes["padding-right"] or 0
--     local padding_bottom = attributes["padding-bottom"] or 0
--     local padding_left = attributes["padding-left"] or 0

--     local margin_top = attributes["margin-top"] or 0
--     local margin_right = attributes["margin-right"] or 0
--     local margin_bottom = attributes["margin-bottom"] or 0
--     local margin_left = attributes["margin-left"] or 0

--     padding_top = tex.sp(padding_top)
--     padding_right = tex.sp(padding_right)
--     padding_bottom = tex.sp(padding_bottom)
--     padding_left = tex.sp(padding_left)

--     margin_top = tex.sp(margin_top)
--     margin_right = tex.sp(margin_right)
--     margin_bottom = tex.sp(margin_bottom)
--     margin_left = tex.sp(margin_left)

--     local border_top_style = attributes["border-top-style"] or "none"
--     local border_right_style = attributes["border-right-style"] or "none"
--     local border_bottom_style = attributes["border-bottom-style"] or "none"
--     local border_left_style = attributes["border-left-style"] or "none"

--     local border_top_width = attributes["border-top-width"] or 0
--     local border_right_width = attributes["border-right-width"] or 0
--     local border_bottom_width = attributes["border-bottom-width"] or 0
--     local border_left_width = attributes["border-left-width"] or 0

--     local border_top_color = styles["border-top-color"]
--     local border_right_color = styles["border-right-color"]
--     local border_bottom_color = styles["border-bottom-color"]
--     local border_left_color = styles["border-left-color"]

--     local border_bottom_right_radius = attributes["border-bottom-right-radius"] or 0
--     local border_bottom_left_radius = attributes["border-bottom-left-radius"] or 0
--     local border_top_right_radius = attributes["border-top-right-radius"] or 0
--     local border_top_left_radius = attributes["border-top-left-radius"] or 0


--     local border_top_width, border_right_width, border_bottom_width, border_left_width = 0, 0, 0, 0
--     if border_top_style ~= "none" then
--         border_top_width = tex.sp(border_top_width)
--     end
--     if border_right_style ~= "none" then
--         border_right_width = tex.sp(border_right_width)
--     end
--     if border_left_style ~= "none" then
--         border_left_width = tex.sp(border_left_width)
--     end
--     if border_bottom_style ~= "none" then
--         border_bottom_width = tex.sp(border_bottom_width)
--     end
--     local firstlist = nodelists[1]
--     local lastlist = nodelists[#nodelists]
--     local wd, wd_bp = firstlist.width, firstlist.width / factor
--     local ht, ht_bp = firstlist.height, ( firstlist.height or 0 ) / factor
--     local dp, dp_bp = firstlist.depth, ( firstlist.depth or 0 ) / factor

--     local kernleft = node.new(publisher.kern_node)
--     local kernright = node.new(publisher.kern_node)
--     kernleft.kern = border_left_width + padding_left + margin_left
--     kernright.kern = border_right_width + padding_right + margin_right + padding_left

--     firstlist = node.insert_before(firstlist,firstlist,kernleft)
--     local tail = node.tail(lastlist)
--     node.insert_after(lastlist,tail,kernright)

--     node.setproperty(firstlist,{
--         borderstart = true,
--         border_top_style = border_top_style,
--         border_right_style = border_right_style,
--         border_bottom_style = border_bottom_style,
--         border_left_style = border_left_style,
--         padding_top = padding_top,
--         padding_right = padding_right,
--         padding_bottom = padding_bottom,
--         padding_left = padding_left,
--         border_top_width = border_top_width,
--         border_right_width = border_right_width,
--         border_bottom_width = border_bottom_width,
--         border_left_width = border_left_width,
--         border_top_color = border_top_color,
--         border_right_color = border_right_color,
--         border_bottom_color = border_bottom_color,
--         border_left_color = border_left_color,
--         border_bottom_right_radius = tex.sp(border_bottom_right_radius),
--         border_bottom_left_radius = tex.sp(border_bottom_left_radius),
--         border_top_right_radius = tex.sp(border_top_right_radius),
--         border_top_left_radius = tex.sp(border_top_left_radius),
--         margin_top = margin_top,
--         margin_right = margin_right,
--         margin_bottom = margin_bottom,
--         margin_left = margin_left,
--         height = lineheight * 0.75,
--         depth = lineheight * 0.25,
--         lineheight = lineheight,
--     })

--     node.setproperty(kernright,{
--         borderend = true,
--     })
--     nodelists[1] = firstlist
--     if #nodelists > 1 then
--         nodelists[#nodelists] = lastlist
--     end
--     return nodelists
-- end


function set_calculated_width(styles)
    if type(styles.calculated_width) == "number" then
    end
    local sw = styles.width or "auto"
    local cw = styles.calculated_width
    if string.match(sw, "%d+%%$") then
        -- xx percent
        local amount = string.match(sw, "(%d+)%%$")
        cw = math.round(cw * tonumber(amount) / 100, 0)
    elseif string.match(sw,"em$") then
        local amount = string.match(sw,"(%d+)em$")
        cw = math.round(styles.fontsize_sp * tonumber(amount), 0)
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
    elseif tonumber(sw) then
        cw = tex.sp(string.format("%spx",sw))
    elseif tex.sp(sw) then
        -- a length
        cw = tex.sp(sw)
    end
    styles.calculated_width = cw
end

function copy_attributes( styles,attributes )
    local remember_currentcolor = {}
    for k, v in pairs(attributes) do
        if type(v) == "string" then
            v = string.lower( tostring(v))
        end
        if k == "font-size" then
            local fontsize
            if string.match(v, "em$") then
                local amount = string.gsub(v, "^(.*)r?em$", "%1")
                local fontsize = math.round(styles.fontsize_sp * amount)
                styles.fontsize_sp = fontsize
            elseif string.match(v,"%d+%%$") then
                local amount = string.match(v, "(%d+)%%$")
                styles.fontsize_sp = math.round(styles.fontsize_sp * tonumber(amount) / 100, 0)
            elseif v == "small" then
                local fontsize = math.round(styles.fontsize_sp * 0.8)
                styles.fontsize_sp = fontsize
            else
                styles.fontsize_sp = tex.sp(v)
            end
        elseif k == "width" then
            styles.width = v
            set_calculated_width(styles)
        end
        if v == "currentcolor" then
            remember_currentcolor[#remember_currentcolor + 1] = k
        end
        styles[k] = v
    end

    for i=1,#remember_currentcolor do
        styles[remember_currentcolor[i]] = styles.color
    end

    if attributes["line-height"] then
        lineheight = attributes["line-height"]
        if lineheight == "normal" then
            styles.lineheight_sp = 1.2 * styles.fontsize_sp
        elseif tonumber(lineheight) then
            styles.lineheight_sp = styles.fontsize_sp * tonumber(lineheight)
        else
            styles.lineheight_sp = tex.sp(lineheight)
        end
    end
end

-- return an option table for mknodes
function set_options_for_mknodes(styles,options)
    options = options or {}
    local fontfamily = styles["font-family"]
    local fontsize = styles["font-size"]
    local hasff = options.fontfamily ~= nil
    options.fontfamily = get_fontfamily(fontfamily,styles.fontsize_sp, fontsize,styles)
    local fontstyle = styles["font-style"]
    local fontweight = styles["font-weight"]
    local fg_colorindex, bg_colorindex
    local backgroundcolor = styles["background-color"]
    if styles.color then
        fg_colorindex = publisher.colors[styles.color].index
        options.textdecorationcolor = fg_colorindex
        options.color = fg_colorindex
        styles.currentcolor = styles.color
    end
    if backgroundcolor then
        bg_colorindex = publisher.colors[backgroundcolor].index
        options.backgroundcolor = bg_colorindex
    end

    local bg_padding_top = styles["background-padding-top"]
    if bg_padding_top then
        options.bg_padding_top = bg_padding_top
    end
    local bg_padding_bottom = styles["background-padding-bottom"]
    if bg_padding_bottom then
        options.bg_padding_bottom = bg_padding_bottom
    end

    local textdecorationline = styles["text-decoration-line"]
    local textdecorationstyle = styles["text-decoration-style"]
    local textdecorationcolor = styles["text-decoration-color"]
    if textdecorationcolor and textdecorationcolor ~= "currentcolor" then
        options.textdecorationcolor = textdecorationcolor
    end
    local whitespace = styles["white-space"]
    if fontweight == "bold" then options.bold = 1 end
    if fontstyle == "italic" then options.italic = 1 end
    if whitespace == "pre" then options.whitespace = "pre" end
    if textdecorationline == "underline" then
        options.textdecorationline = "underline"
        options.textdecorationstyle = textdecorationstyle
    elseif textdecorationline == "line-through" then
        options.textdecorationline = "line-through"
        options.textdecorationstyle = textdecorationstyle
    end

    local verticalalign = styles["vertical-align"]
    local fontfamilynumber = tonumber(styles["font-family-number"])
    if verticalalign == "super" or verticalalign == "sub" then
        options.verticalalign = verticalalign
        -- in case of HTML coming from <Paragraph>, the font family number is already set
        -- and font sizes usually don't change (unlike HTML mode)
        -- therefore on "sub" or "super" the font size changes
        -- this should be done in a proper way without fixed "script" fonts
        if fontfamilynumber and fontfamilynumber > 0 then
            options.fontsize = "small"
        end
    end


end

function set_image_dimensions(image,styles,width_sp,height_sp)
    local orig_imagewidth, orig_imageheight = image.width, image.height
    local imagewidth, imageheight = orig_imagewidth, orig_imageheight
    -- Todo: check if width _and_ height are set
    local factor = 1
    if width_sp ~= 0 then
        imagewidth = width_sp
        factor = orig_imagewidth / imagewidth
    end
    if height_sp ~= 0 then
        imageheight = tex.sp(imageheight)
        imageheight = calculate_height(height_sp,orig_imageheight)
        factor = orig_imageheight / imageheight
    end
    if factor ~= 1 then
        imagewidth = orig_imagewidth / factor
        imageheight = orig_imageheight / factor
    end

    local maxwd = xpath.get_variable("__maxwidth")
    local maxht = xpath.get_variable("__maxheight")
    maxht = maxht - styles.fontsize_sp * 0.25
    local calc_width, calc_height = publisher.calculate_image_width_height(image,imagewidth,imageheight,0,0,maxwd,maxht)
    image.width = calc_width
    image.height = calc_height
    return calc_width,calc_height
end


-- collect horizontal nodes returns a table with nodelists (glyphs for example)
function collect_horizontal_nodes( elt,parameter,before_box,origin )
    -- w("collect_horizontal_nodes %s",origin or "?")
    parameter = parameter or {}
    if elt.elementname == "br" then
        local nodes = publisher.mknodes("\n",parameter)
        return {nodes}
    end
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
        local thiselt_styles = thiselt.styles or {}
        copy_attributes(styles,thiselt_styles)

        set_options_for_mknodes(styles,options)

        local thisret = {}
        if typ == "string" then
            local nodes = publisher.mknodes(thiselt,options)
            if before_box then
                nodes = node.insert_before(nodes,nodes,before_box)
            end
            before_box = nil
            publisher.setprop(nodes,"direction",elt.direction)
            thisret[#thisret + 1] = nodes
        elseif typ == "table" then
            local attributes = thiselt.attributes or {}
            local eltname = thiselt.elementname
            if eltname == "a" then
                local href = attributes["href"]
                options.add_attributes = { { "hyperlink", publisher.hlurl(href) } }
            elseif eltname == "img" then
                local source = attributes.src
                local it = publisher.new_image(source,1,nil,nil)
                -- if we don't copy the image, the changed size settings would
                -- affect future images with the same name
                it = img.copy(it.img)
                local wd = 0
                if attributes.width then
                     wd = styles.calculated_width
                end
                local height = getsize(attributes.height)
                local calc_width, calc_height = set_image_dimensions(it,styles,wd,height or 0)
                local box = publisher.box(calc_width,calc_height,"-")
                node.set_attribute(box,publisher.att_dontadjustlineheight,1)
                node.set_attribute(box,publisher.att_ignore_orphan_widowsetting,1)
                box.head = node.insert_before(box.head,box.head,img.node(it))
                thisret[#thisret + 1] = box
            elseif eltname == "wbr" then
                thisret[#thisret + 1] = "\xE2\x80\x8B"
            end
            local n = collect_horizontal_nodes(thiselt,options,before_box,string.format("collect horizontal mode element %s",eltname))
            for i=1,#n do
                thisret[#thisret + 1] = n[i]
            end
        end
        if attributes.has_border then
            local tmp = draw_border(thisret,attributes,styles)
            thisret = {}
            for i=1,#tmp do
                thisret[#thisret + 1] = tmp[i]
            end
        end
        for i=1,#thisret do
            ret[#ret + 1] = thisret[i]
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
    local dir = publisher.getprop(nodelist,"direction")
    if dir == "→" then return nodelist end
    if nodelist.id == publisher.glue_node then
        local tmp = node.getproperty(nodelist)
        nodelist=nodelist.next
        if nodelist then
            node.setproperty(nodelist,tmp)
        end
    end
    return nodelist
end

function build_html_table_tbody(tbody)
    local trtab = {}
    for row=1,#tbody do
            local tr = tbody[row]
            local tdtab = {}
            if type(tr) == "table" and tr.elementname then
                for cell=1,#tr do
                    local td = tr[cell]
                    if type(td) == "table" and td.elementname then
                        local styles = setmetatable({}, levelmt)
                        stylesstack[#stylesstack + 1] = styles
                        local attributes = td.attributes or {}
                        local td_styles = td.styles or {}
                        copy_attributes(styles,td_styles)
                        local r = build_nodelist(td,{},nil,"build_html_table_tbody/td")
                        r = publisher.flatten_boxes(r)
                        table.remove(stylesstack)
                        local newcontents = {}
                        for i=1,#r do
                            local newtd = { elementname = "Paragraph" , contents = r[i] }
                            table.insert(newcontents,newtd)
                        end
                        local att = td.attributes
                        if att then
                            local bbw = att["border-bottom-width"]
                            local btw = att["border-top-width"]
                            local brw = att["border-right-width"]
                            local blw = att["border-left-width"]
                            if bbw then newcontents["border-bottom"] = bbw end
                            if btw then newcontents["border-top"] = btw end
                            if blw then newcontents["border-left"] = blw end
                            if brw then newcontents["border-right"] = brw end
                        end
                        tdtab[#tdtab + 1] = { elementname = "Td", contents = newcontents }
                    end
                end
                local att = tr.attributes
                if att then
                    local valign = att["vertical-align"]
                    if valign == "top" or valign == "bottom" or valign == "middle" then
                        tdtab.valign = valign
                    end
                end
                trtab[#trtab + 1] = { elementname = "Tr", contents =  tdtab  }
            end
        end
    return trtab
end

function build_html_table( elt, dataxml )
    assert(dataxml,"build_html_table")
    local tablecontents = elt
    local head, foot, body = {},{},{}
    local styles = setmetatable({}, levelmt)
    for i=1,#tablecontents do
        stylesstack[#stylesstack + 1] = styles

        local thiselt = tablecontents[i]
        local typ = type(thiselt)
        if typ == "table" then
            local eltname = thiselt.elementname
            if eltname == "tbody" then
                body = build_html_table_tbody(thiselt)
            elseif eltname == "tfoot" then
                foot = build_html_table_tbody(thiselt)
            elseif eltname == "thead" then
                head = build_html_table_tbody(thiselt)
            else
                -- err("Unknown element in HTML table %q",tostring(thiselt.elementname))
            end
        end
        table.remove(stylesstack)
    end

    local tabular = publisher.tabular:new()
    tabular.width = styles.calculated_width
    if elt.attributes.width then
        tabular.autostretch = "max"
    end
    local tab = {}
    for i=1,#head do
        tab[#tab + 1] = head[i]
    end
    for i=1,#body do
        tab[#tab + 1] = body[i]
    end
    for i=1,#foot do
        tab[#tab + 1] = foot[i]
    end
    tabular.tab = tab
    local fontname = "text"
    local fontfamily = publisher.fonts.lookup_fontfamily_name_number[fontname]
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
    tabular.colsep         = 0
    tabular.rowsep         = 0
    tabular.bordercollapse_horizontal = true
    tabular.bordercollapse_vertical = true
    tabular.dataxml = dataxml

    local n = tabular:make_table(dataxml)
    return n[1]
end

local olcounter = {}
function build_nodelist(elt,options,before_box,caller, prevdir,dataxml )
    -- w("html: build nodelist from %s, prevdir = %s", caller or "?",prevdir or "?")
    options = options or {}
    -- ret is a nested table of boxes and paragraphs
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
            styles.listlevel = 0
        end

        local attributes = thiselt.attributes or {}
        local thiselt_styles = thiselt.styles or {}

        local before_styles = {}
        local has_before_styles = false
        for k,v in pairs(thiselt_styles) do
            if string.match(k,"^before::") then
                local rawstyle = string.gsub(k,"^before::(.*)","%1")
                before_styles[rawstyle] = v
                thiselt_styles[k] = nil
                has_before_styles = true
            end
        end

        if has_before_styles then
            local styles = setmetatable({}, levelmt)
            stylesstack[#stylesstack + 1] = styles
            copy_attributes(styles,before_styles)

            local before_options = {}
            set_options_for_mknodes(styles,before_options)
            local nl = publisher.mknodes(styles.content,before_options)
            local margin_left = getsize(styles["margin-left"],styles.fontsize_sp)

            local hss = publisher.hss_glue()
            local ml_box = node.hpack(hss,margin_left,"exactly")

            if styles.width then
                node.insert_after(nl,nl,publisher.hss_glue())
                nl = node.hpack(nl,styles.calculated_width,"exactly")
            end

            before_box = node.insert_after(ml_box,ml_box,nl)
            before_box = node.hpack(before_box)

            table.remove(stylesstack)
        end
        copy_attributes(styles,thiselt_styles)
        local styles_fontsize_sp = styles.fontsize_sp
        local margin_top = getsize(styles["margin-top"],styles_fontsize_sp)
        local margin_right = getsize(styles["margin-right"],styles_fontsize_sp)
        local margin_bottom = getsize(styles["margin-bottom"],styles_fontsize_sp)
        local margin_left = getsize(styles["margin-left"],styles_fontsize_sp)

        local padding_top = getsize(styles["padding-top"],styles_fontsize_sp)
        local padding_right = getsize(styles["padding-right"],styles_fontsize_sp)
        local padding_bottom = getsize(styles["padding-bottom"],styles_fontsize_sp)
        local padding_left = getsize(styles["padding-left"],styles_fontsize_sp)

        local border_top_style = thiselt_styles["border-top-style"] or "none"
        local border_right_style = thiselt_styles["border-right-style"] or "none"
        local border_bottom_style = thiselt_styles["border-bottom-style"] or "none"
        local border_left_style = thiselt_styles["border-left-style"] or "none"

        local border_top_width = getsize(styles["border-top-width"],styles_fontsize_sp)
        local border_right_width = getsize(styles["border-right-width"],styles_fontsize_sp)
        local border_bottom_width = getsize(styles["border-bottom-width"],styles_fontsize_sp)
        local border_left_width = getsize(styles["border-left-width"],styles_fontsize_sp)

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


        -- local border_top_width, border_right_width, border_bottom_width, border_left_width = 0, 0, 0, 0
        -- if border_top_style ~= "none" then
        --     border_top_width = tex.sp(border_top_width)
        -- end
        -- if border_right_style ~= "none" then
        --     border_right_width = tex.sp(border_right_width)
        -- end
        -- if border_left_style ~= "none" then
        --     border_left_width = tex.sp(border_left_width)
        -- end
        -- if border_bottom_style ~= "none" then
        --     border_bottom_width = tex.sp(border_bottom_width)
        -- end

        local fontfamily = styles["font-family"]
        local fontsize = styles["font-size"]
        local fontname = fontsize
        local fam = get_fontfamily(fontfamily,styles.fontsize_sp,fontname, styles)

        local textalign = styles["text-align"]
        local hyphens = styles.hyphens
        local alignment = "leftaligned"
        if textalign == "right" then
            alignment = "rightaligned"
        elseif textalign == "center" then
            alignment = "centered"
        elseif textalign == "justify" then
            alignment = "justified"
        end

        if thiselt.mode == "horizontal" then
            -- when called from Paragraph, we use that textformat
            local tf
            if options.override_alignment then
                tf = options.textformat
            else
                tf = publisher.new_textformat("","text",{alignment = alignment})
            end
            if hyphens == "none" or hyphens == "manual" then
                tf.disable_hyphenation = true
            end
            options.textformat = tf
            local n = collect_horizontal_nodes(thiselt,options,before_box,"build nodelist horizontal mode")

            local a = par:new(tf,"html.lua (horizontal)")
            local appended = false
            for i=1,#n do
                local thisn = n[i]
                if i == 1 then
                    thisn = trim_space_beginning(thisn)
                elseif i == #n then
                    thisn = trim_space_end(thisn)
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
            box.indent_amount = margin_left + padding_left
            styles.calculated_width = styles.calculated_width - margin_left - padding_left - border_left_width - border_right_width
            box.width = styles.calculated_width
            box.draw_border = thiselt_styles.has_border
            box.padding_top = padding_top
            box.padding_bottom = padding_bottom
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
                }
            end
            if thiseltname == "table" then
                prevdir = "vertical"
                -- w("html/table")
                local nl = build_html_table(thiselt,dataxml)
                local tabpar = par:new(nil,"html table (a)")
                tabpar.margin_top = margin_top
                node.set_attribute(nl,publisher.att_lineheight,nl.height)
                publisher.setprop(nl,"origin","html table")
                tabpar:append(nl,{dontformat=true})
                box[#box + 1] = tabpar
                ret[#ret + 1] = box
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
                if attribs and attribs.start then
                    olcounter[styles.listlevel] = attribs.start - 1
                else
                    olcounter[styles.listlevel] = 0
                end
                local n
                n, prevdir = build_nodelist(thiselt,options,before_box,"build_nodelist/ ol/ul",prevdir,dataxml)
                before_box = nil
                if thiseltname == "ol" then
                    styles.ollevel = styles.ollevel - 1
                else
                    styles.ullevel = styles.ullevel - 1
                end
                styles.listlevel = styles.listlevel - 1
                for i=1,#n do
                    box[#box + 1] = n[i]
                    box[#box].mode = "block"
                end
                ret[#ret + 1] = box
            elseif thiseltname == "li" then
                prevdir = "vertical"
                olcounter[styles.listlevel] = olcounter[styles.listlevel] or 0
                olcounter[styles.listlevel] = olcounter[styles.listlevel] + 1
                local n
                n, prevdir = build_nodelist(thiselt,options,before_box,"build_nodelist/ li",prevdir,dataxml)
                before_box = nil
                -- n is a table of box and / or par
                local str = resolve_list_style_type(styles,olcounter)
                for i=1,#n do
                    local a = n[i]
                    local wd = styles.listindent
                    local x = { str,wd,{fontfamily=fam} }
                    a:prepend(x)
                    -- label only for the first
                    str = ""
                    ret[#ret + 1] = a
                end
            elseif thiseltname == "br" then
                local a = par:new(tf,"html.lua (br)")
                local list
                if prevdir == "vertical" then
                    list = publisher.newline(fam)
                else
                    list = publisher.short_newline(fam)
                end
                publisher.setprop(list,"br",true)
                a:append(list)
                ret[#ret + 1] = a
            prevdir = "vertical"
            elseif thiseltname == "hr" then
                local ht = getsize(styles.height,styles.fontsize_sp)
                ht = ht + border_top_width + border_bottom_width
                local bx = publisher.create_empty_vbox_width_width_height(styles.calculated_width,ht)
                local a = par:new(tf,"html.lua (hr)")
                a:append(bx)
                box[#box + 1] = a
                ret[#ret + 1] = box
            else
                local n
                local nloptions = publisher.copy_table_from_defaults(options)
                if thiseltname == "h1" then
                    nloptions.role = publisher.get_rolenum("H1")
                elseif thiseltname == "p" then
                    nloptions.role = publisher.get_rolenum("P")
                end
                n, prevdir = build_nodelist(thiselt,options,before_box,string.format("build_nodelist/ any element name %q",thiseltname),prevdir,dataxml)
                if thiselt.block then prevdir = "vertical" end
                before_box = nil
                local mode
                if thiselt.block then mode = "block" end
                if thiselt.block and #n == 0 then
                    local list = publisher.newline(fam)
                    local a = par:new(tf,"html.lua (p)")
                    a:append(list)
                    box[#box + 1] = a
                end
                for i = 1,#n do
                    box[#box + 1] = n[i]
                    box[#box].mode = mode
                end
                ret[#ret + 1] = box
            end
        end
        table.remove(stylesstack)
    end
    -- two adjacent box elements collapse their margin
    -- https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Box_Model/Mastering_margin_collapsing
    -- This simple implementation is not enough, but a start
    for i=1,#ret - 1 do
        local max = math.max(ret[i].marginbottom or 0,ret[i + 1].margintop or 0)
        ret[i].marginbottom = max / 2
        ret[i + 1].margintop = max / 2
    end

    return ret, prevdir
end

function resolve_list_style_type(styles, olcounter)
    local liststyletype = styles["list-style-type"]
    local liststyleimage = styles["list-style-image"]
    if liststyleimage then
        local filename = string.match(liststyleimage,"url%((.*)%)")
        local it = publisher.new_image(filename,1,nil,nil)
        it = img.copy(it.img)
        set_image_dimensions(it,styles,0,styles.fontsize_sp * 0.9)
        return img.node(it)
    end
    local counter  = olcounter[styles.ollevel]
    local ullevel = styles.ullevel
    local str = ""
    if liststyletype == "decimal" then
        str = tostring(counter) .. "."
    elseif liststyletype == "none" then
        -- ignore
    elseif liststyletype == "decimal-leading-zero" then
        str = string.format("%02d.",counter)
    elseif liststyletype == "lower-roman" then
        str = tex.romannumeral(counter) .. "."
    elseif liststyletype == "upper-roman" then
        str = string.upper( tex.romannumeral(counter) ) .. "."
    elseif liststyletype == "disc" then
        str = "•"
    elseif liststyletype == "circle" then
        str = "◦"
    elseif liststyletype == "square" then
        str = "□"
    else
        str = liststyletype
    end
    return str
end

function handle_pages( pages,maxwidth_sp,data )
    -- defaults:
    local pagewd = tex.pagewidth
    if publisher.newxpath then

    else
        xpath.set_variable("__maxwidth",pagewd)
        xpath.set_variable("__maxheight",tex.pageheight)
    end

    local masterpage = pages["*"]
    if masterpage then
        local wd,ht
        if masterpage.width then
            wd = tex.sp(masterpage.width)
            if publisher.newxpath then
                data.vars["_pagewidth"] = masterpage.width
            else
                xpath.set_variable("_pagewidth",masterpage.width)
            end

            pagewd = wd
            if masterpage.height then
                xpath.set_variable("_pageheight",masterpage.height)
                ht = tex.sp(masterpage.height)
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
        pagewd = pagewd - margin_left - margin_right
        if publisher.newxpath then
            data.vars["__maxwidth"] = pagewd
        else
            xpath.set_variable("__maxwidth",pagewd)
        end
        publisher.set_pageformat(wd,ht)
        publisher.masterpages[1] = { is_pagetype = "true()", res = { width = wd, height = ht, { elementname = "Margin", contents = function(_page) _page.grid:set_margin(margin_left,margin_top,margin_right,margin_bottom) end }}, name = "Default HTML page",ns={[""] = "urn:speedata.de:2009/publisher/en" } }
    else
        if maxwidth_sp then
            pagewd = maxwidth_sp
        else
            local margin_right = publisher.tenmm_sp
            local margin_left = publisher.tenmm_sp
            pagewd = pagewd - margin_left - margin_right
        end
        if publisher.newxpath then
            data.vars["__maxwidth"] = pagewd
        else
            xpath.set_variable("__maxwidth",pagewd)
        end
    end
end

-- Only used for debugging. Remove all attributes.
function clearattributes( elt )
    elt.attributes = nil
    for i=1,#elt do
        if type(elt[i]) == "table" then
            clearattributes(elt[i])
        end
    end
end

-- Entry point for HTML parsing
function parse_html_new( elt, options, data )
    options = options or {}
    local maxwidth_sp = options.maxwidth_sp
    handle_pages(elt.pages,maxwidth_sp, data)
    fontfamilies = elt.fontfamilies
    elt.fontfamilies = nil
    local att = elt[1].styles
    if att and type(att) == "table" then
        local trace = att["-sp-trace"] or ""
        if string.match(trace,"objects") then publisher.options.showobjects = true end
        if string.match(trace,"grid") then publisher.options.showgrid = true end
        if string.match(trace,"gridallocation") then publisher.options.showgridallocation = true end
        if string.match(trace,"hyphenation") then publisher.options.showhyphenation = true end
        if string.match(trace,"textformat") then publisher.options.showtextformat = true end
    end
    if publisher.newxpath then
        elt[1].styles.calculated_width = data.vars["__maxwidth"]
    else
        elt[1].styles.calculated_width = xpath.get_variable("__maxwidth")
    end
    local lang = elt.lang
    if lang then
        publisher.set_mainlanguage(lang)
    end
    parse_html_inner(elt[1])
    local block = build_nodelist(elt,options,nil,"parse_html_new","vertical",data)
    return block
end
