--
--  html.lua
--  speedata publisher
--  new HTML parser
--
--  for a list of authors see `git blame'
--  see file copying in the root directory for license info.

-- This is for the new HTML parser

module(...,package.seeall)

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
styles.color = "black"
styles["font-family"] = "text"
styles["font-size"] = "10pt"
styles["fontsize_sp"] = tex.sp("10pt")
styles["font-weight"] = "normal"
styles["font-style"] = "normal"
styles["line-height"] = "normal"

stylesstack[#stylesstack + 1] = styles


-- function set_calculated_width(styles)
--     if type(styles.calculated_width) == "number" then
--     end
--     local sw = styles.width or "auto"
--     local cw = styles.calculated_width
--     w("cw %q",tostring(cw))
--     if string.match(sw, "%d+%%$") then
--         -- xx percent
--         local amount = string.match(sw, "(%d+)%%$")
--         cw = math.round(cw * tonumber(amount) / 100, 0)
--     elseif sw == "auto" then
--         cw = styles.calculated_width
--         if styles.height and styles.height ~= "auto" then
--             styles.height = tex.sp(styles.height)
--         else
--             styles.height = nil
--         end
--         local padding_left = styles["padding-left"]
--         local padding_right = styles["padding-right"]
--         local margin_left = styles["margin-left"]
--         local margin_right = styles["margin-right"]
--         local border_left = styles["border-left-width"]
--         local border_right = styles["border-right-width"]
--         if padding_left then
--             cw = cw - tex.sp(padding_left)
--         end
--         if padding_right then
--             cw = cw - tex.sp(padding_right)
--         end
--         if margin_left then
--             cw = cw - tex.sp(margin_left)
--         end
--         if margin_right then
--             cw = cw - tex.sp(margin_right)
--         end
--         if border_left then
--             cw = cw - tex.sp(border_left)
--         end
--         if border_right then
--             cw = cw - tex.sp(border_right)
--         end
--     elseif tex.sp(sw) then
--         -- a length
--         cw = tex.sp(sw)
--     end
--     styles.calculated_width = cw
-- end


-- function flatten_nodelist(tbl)
--     for i = 1, #tbl - 1 do
--         local tail = node.tail(tbl[i])
--         tail.next = tbl[i + 1]
--         tbl[i + 1].prev = tail
--     end
--     return tbl[1]
-- end

-- function create_horizontal_nodelists(elt)
--     local styles = setmetatable({}, levelmt)
--     stylesstack[#stylesstack + 1] = styles

--     if type(elt) == "string" then
--         local nodes = publisher.mknodes(elt, 1)
--         -- local nodes = publisher.mknodes(elt, styles)
--         table.remove(stylesstack)
--         return nodes
--     end

--     if elt.attributes then
--         for k, v in pairs(elt.attributes) do
--             if k == "font-size" and string.match(v, "em$") then
--                 local amount = string.gsub(v, "^(.*)r?em$", "%1")
--                 local fontsize = tex.sp(styles["font-size"])
--                 v = fontsize * amount
--             end
--             styles[k] = v
--         end
--     end

--     -- set_calculated_width(styles)

--     if elt.elementname == "img" then
--         local rule = node.new(rule_node)
--         rule = img.node({width = styles.calculated_width, filename = styles.src})
--         table.remove(stylesstack)
--         return rule
--     end

--     elt.nodelist = {}

--     -- we collect all the nodes in the horizontal list
--     for _, v in ipairs(elt) do
--         elt.nodelist[#elt.nodelist + 1] = create_horizontal_nodelists(v)
--     end
--     elt.nodelist = flatten_nodelist(elt.nodelist)
--     if elt.direction == "↓" then
--         elt.nodes = elt.nodelist
--         elt.nodelist = nil
--     end
--     for i = 1, #elt do
--         if type(elt[i]) == "table" then
--             elt[i].nodelist = nil
--         end
--     end

--     table.remove(stylesstack)
--     return elt.nodelist
-- end


-- function do_output(elt)
--     local styles = setmetatable({}, levelmt)
--     stylesstack[#stylesstack + 1] = styles

--     if elt.attributes then
--         for i, v in pairs(elt.attributes) do
--             styles[i] = v
--         end
--     end
--     set_calculated_width(styles)
--     if type(elt) == "table" then
--         if elt.nodes then
--             output_block(elt, styles.calculated_width, styles.height)
--             table.remove(stylesstack)
--             return
--         end
--     end

--     local curelement
--     for i = 1, #elt do
--         curelement = elt[i]
--         if curelement then
--             do_output(curelement)
--         end
--     end
--     table.remove(stylesstack)
-- end


-- -- --------------------------------------------------------------------------------
-- -- --------------------------------------------------------------------------------


-- local function html_to_elt(element)
--     local dataxml = {}
--     for i=1,#element do
--         local elt = element[i]
--         if type(elt) == "string" then
--             dataxml[#dataxml + 1] = elt
--         elseif type(elt) == "table" then
--             dataxml[#dataxml + 1] = html_to_elt(elt)
--             local data = dataxml[#dataxml]
--             data[".__type"] = "element"
--             data[".__name"] = elt.elementname
--             data[".__local_name"] = elt.elementname
--             data[".__parent"] = dataxml
--             for i,v in pairs(elt.attributes) do
--                 data[i] = v
--             end
--         end
--     end
--     return dataxml
-- end

-- function html_to_speedata()



--     dataxml = {}
--     local body = csshtmltree

--     create_horizontal_nodelists(body)
--     printtable("body",body)
--     dataxml = html_to_elt(csshtmltree)
--     local body = dataxml[1]
--     body[".__parent"] = nil
--     printtable("dataxml",dataxml)
--     return body
-- end

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

local function parse_html_inner( elt , parameter )
    parameter = parameter or {}
    local elementname = elt.elementname and string.lower( elt.elementname )
    local a = paragraph:new()
    for i=1,#elt do
        local thiselt = elt[i]

        local styles = setmetatable({}, levelmt)
        stylesstack[#stylesstack + 1] = styles

        local options = {}
        for k,v in pairs(parameter) do
            options[k] = v
        end
        if type(thiselt) == "string" then
            a:append(thiselt,options)
        elseif type(thiselt) == "table" then
            local elementname = thiselt.elementname
            -- w("elementname %s",elementname)
            local attributes = thiselt.attributes or {}
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
                end
                styles[k] = v
            end
            local b = paragraph:new()

            local backgroundcolor = styles["background-color"]
            local fontfamily = styles["font-family"]
            local fontsize = styles["font-size"]
            local fontstyle = styles["font-style"]
            local fontweight = styles["font-weight"]
            local textalign = styles["text-align"]
            local textdecoration = styles["text-decoration"]
            local verticalalign = styles["vertical-align"]
            local whitespace = styles["white-space"]

            if elementname == "a" then
                local href = attributes["href"]
                publisher.hyperlinks[#publisher.hyperlinks + 1] = string.format("/Subtype/Link/A<</Type/Action/S/URI/URI(%s)>>",href)
                options.add_attributes = { publisher.att_hyperlink, #publisher.hyperlinks }
            elseif elementname == "img" then
                local source = attributes.src
                local it = publisher.new_image(source,1,nil,nil)
                if attributes.width then
                    it.img.width = tex.sp(attributes.width)
                end
                if attributes.height then
                    it.img.height = tex.sp(attributes.height)
                end
                b:append(it.img)
            end
            local fontname = fontsize
            if elementname == "body" then
                -- otherwise the font name would be "12pt" or something like that
                fontname = "1em"
            end
            options.fontfamily = get_fontfamily(fontfamily,styles.fontsize_sp, fontname)
            if fontstyle == "italic" then
                options.italic = 1
            end
            if fontweight == "bold" then
                options.bold = 1
            end
            if textdecoration == "underline" then
                options.underline = 1
            end
            if whitespace == "pre" then
                options.whitespace = "pre"
            end
            local fg_colorindex, bg_colorindex
            if attributes.color then
                fg_colorindex = publisher.colors[attributes.color].index
            end
            if backgroundcolor then
                bg_colorindex = publisher.colors[backgroundcolor].index
                options.backgroundcolor = bg_colorindex
            end
            -- does nothing yet
            if verticalalign == "super" then
                options.script = 2
            elseif verticalalign == "sub" then
                options.script = 1
            end

            local tmp = parse_html_inner(elt[i],options)
            b:append(tmp,options)
            b:set_color(fg_colorindex)
            a:append(b,options)
            if thiselt.direction == "↓" then
                a:append("\n")
            end
        else
            w("unknown type %s",type(thiselt))
        end
        table.remove(stylesstack)
    end
    return a
end

function parse_html_new( elt )
    fontfamilies = elt.fontfamilies
    -- printtable("elt",elt)
    return parse_html_inner(elt)
end
