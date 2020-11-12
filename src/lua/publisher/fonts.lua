--- Fonthandling after fontloading.
--
--  fonts.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.
--
--- Loading a font is only one part of the story. Proper dealing with fonts
--- requires post processing at various stages.
file_start("fonts.lua")

require("fonts.fontloader")
module(...,package.seeall)

local lookup_fontname_filename={}
local font_instances={}

used_fonts={}


local att_fontfamily     = 1
local att_italic         = 2
local att_bold           = 3
local att_script         = 4

local glue_spec_node = node.id("glue_spec")
local glue_node      = node.id("glue")
local glyph_node     = node.id("glyph")
local disc_node      = node.id("disc")
local rule_node      = node.id("rule")
local dir_node       = node.id("dir")
local kern_node      = node.id("kern")
local penalty_node   = node.id("penalty")
local whatsit_node   = node.id("whatsit")
local hlist_node     = node.id("hlist")
local vlist_node     = node.id("vlist")


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


--- Every font family ("text", "Chapter"), that is defined by DefineFontfamily gets an internal
--- number. This number is stored here.
lookup_fontfamily_name_number={}

--- Every font family (given by number) has variants like italic, bold etc.
--- These are stored as a table in this table.
--- The following keys are stored
---
---  * normal
---  * bolditalic
---  * italic
---  * bold
---  * baselineskip
---  * size
lookup_fontfamily_number_instance={}


function load_fontfile(name, filename, parameter_tab)
    assert(filename)
    assert(name)
    lookup_fontname_filename[name]={filename,parameter_tab or {}}
    return true
end

function table.find(tab,key)
    assert(tab)
    assert(key)
    local found
    for k_tab,v_tab in pairs(tab) do
        if type(key)=="table" then
            found = true
            for k_key,v_key in pairs(key) do
                if k_tab[k_key]~= v_key then found = false end
            end
            if found==true then
                return v_tab
            end
        end
    end
    return nil
end

function get_fontname( localname, url )
    localname = publisher.get_fontname(localname)
    -- w("get_fontname, localname %q",tostring(localname))
    if localname and lookup_fontname_filename[localname] then
        return localname
    elseif url then
        load_fontfile(url,url)
        return url
    end
    return nil
end

local preloaded_fonts = {}


-- Return false, error message in case of failure, true, number otherwise. number
-- is the internal font number. After calling this method, the font can be used
-- with the key {filename,size}
function make_font_instance( name,size )
    -- Name is something like "TeXGyreHeros-Regular", the visible name of the font file
    assert(name)
    assert(tonumber(size))
    if not lookup_fontname_filename[name] then
        local msg = string.format("Font instance '%s' is not defined!", name)
        err(msg)
        return false, msg
    end
    local filename,parameter = unpack(lookup_fontname_filename[name])
    assert(filename)
    local k = {filename = filename, fontsize = size, space = parameter.space, mode = parameter.mode or publisher.options.fontloader}

    if parameter.otfeatures then
        for fea,enabled in pairs(parameter.otfeatures) do
            if enabled then
                k[fea] = true
            end
        end
    end
    local fontnumber = table.find(font_instances,k)
    if fontnumber then
        return true,fontnumber
    else
        local f
        local num = font.nextid(true)
        f = fonts.fontloader.preload_font(filename,size,parameter,parameter.mode or publisher.options.fontloader)
        f.reserved_num = num
        preloaded_fonts[num] = f
        log("Preload font %q at %.2gpt (id: %d)",filename,size / publisher.factor,num)
        font_instances[k]=num
        return true, num
    end
    return false, "Internal error"
end

-- Define font from preloaded font
function define_font(instance)
    local mode = instance.requested_mode
    local num = instance.reserved_num
    log("Create font metrics for %q at %.2gpt (id: %d) mode=%s",instance.requested_name,instance.requested_size / publisher.factor, tostring(num), tostring(mode))
    local f, ok
    if mode == "harfbuzz" then
        ok,f = fonts.fontloader.define_font_hb(instance.requested_name,instance.requested_size,instance.requested_extra_parameter)
    else
        ok,f = fonts.fontloader.define_font(instance.requested_name,instance.requested_size,instance.requested_extra_parameter)
    end
    if not ok then
        err("Failed to load font %s",instance.requested_name)
        return false
    end
    preloaded_fonts[num] = f
    used_fonts[num]=f
    font.define(num,f)
    return true
end

-- Return instance number from fontfamily number and instance name
function get_fontinstance(fontfamily,instancename)
    local instance
    if fontfamily and fontfamily > 0 then
        instance = lookup_fontfamily_number_instance[fontfamily][instancename]
    else
        instance = 1
    end
    if not instance then
        err("font %s not found for family %s",instancename,fontfamily)
        -- let's try "regular"
        if fontfamily and fontfamily > 0 then
            parameter.bold = nil
            parameter.italic = nil
            instance = lookup_fontfamily_number_instance[fontfamily].normal
        end
        if not instance then
            instance = 1
        end
    end
    local pe = preloaded_fonts[instance]
    if pe.loaded == false then
        local ok = define_font(pe)
        if not ok then
            return get_fontinstance(1,"normal")
        end
    end
    return instance
end

--- At this time we must adjust the contents of the paragraph how we would
--- like it. For example the (sub/sup)script glyphs still have the width of
--- the regular characters and need
function pre_linebreak( head )
    local first_head = head

    while head do
        if head.id == hlist_node then -- hlist
            pre_linebreak(head.list)
        elseif head.id == vlist_node then -- vlist
            pre_linebreak(head.list)
        elseif head.id == rule_node then
            -- ignore
        elseif head.id == dir_node then
            -- ignore
        elseif head.id == disc_node then -- discretionary
            pre_linebreak(head.pre)
            pre_linebreak(head.post)
            pre_linebreak(head.replace)
        elseif head.id == whatsit_node then -- whatsit
            if head.subtype == pdf_dest_whatsit then
                local dest_fontfamily = node.has_attribute(head,publisher.att_fontfamily)
                if dest_fontfamily then
                    local tmpnext = head.next
                    local tmpprev = head.prev
                    head.next = nil
                    head.prev = nil
                    local instance = lookup_fontfamily_number_instance[dest_fontfamily]
                    local f = used_fonts[instance.normal]
                    local g = publisher.make_glue({width = f.size})

                    local h = node.insert_after(head,head,g)

                    h = node.vpack(h)

                    if tmpprev then
                        tmpprev.next = h
                        h.prev = tmpprev
                    end

                    if tmpnext then
                        tmpnext.prev = h
                        h.next = tmpnext
                    end
                end
            end
        elseif head.id == glue_node then -- glue
            if head.subtype == 100 then -- leader
                local l = head.leader
                local wd = node.has_attribute(l,publisher.att_leaderwd)

                -- Set the font for the leader
                pre_linebreak(l)

                local tmpbox
                if wd == -1 then
                    tmpbox = node.hpack(l)
                else
                    -- \hbox{ 1fil, text, 1fil }
                    local l1,l2
                    l1 = set_glue(nil,{width = 0, stretch = 2^16, stretch_order = 2, shrink = 2^16, shrink_order = 2})
                    l2 = set_glue(nil,{width = 0, stretch = 2^16, stretch_order = 2, shrink = 2^16, shrink_order = 2})
                    local newhead = node.insert_before(l,l,l1)

                    local endoftext = node.tail(l)
                    newhead = node.insert_after(newhead,endoftext,l2)
                    tmpbox = node.hpack(newhead,wd,"exactly")
                end
                node.set_attribute(tmpbox,publisher.att_leaderwd,wd)
                head.leader = tmpbox

            end
        elseif head.id == kern_node then -- kern
        elseif head.id == penalty_node then -- penalty
        elseif head.id == glyph_node then -- glyph
            if node.has_attribute(head,att_fontfamily) then
                -- not local, so that we can access fontfamily later
                fontfamily=node.has_attribute(head,att_fontfamily)

                -- Last resort
                if fontfamily == 0 then fontfamily = 1 warning("Undefined fontfamily, set fontfamily to 1") end

                local instance = lookup_fontfamily_number_instance[fontfamily]
                local italic = node.has_attribute(head,att_italic)
                local bold   = node.has_attribute(head,att_bold)

                local instancename = nil
                if italic == 1 and bold ~= 1 then
                    instancename = "italic"
                elseif italic == 1 and bold == 1 then
                    instancename = "bolditalic"
                elseif bold == 1 then
                    instancename = "bold"
                else
                    instancename = "normal"
                end

                if node.has_attribute(head,att_script) then
                    instancename = instancename .. "script"
                    local sub_sup = node.has_attribute(head,att_script)
                    local fam = lookup_fontfamily_number_instance[fontfamily]
                    if sub_sup == 1 then
                        head.yoffset = -fam.scriptshift
                    else
                        head.yoffset = fam.scriptshift
                    end
                end

                tmp_fontnum = get_fontinstance(fontfamily,instancename)

                if not tmp_fontnum then
                    head.font = publisher.options.defaultfontnumber
                else
                    head.font = tmp_fontnum
                end
                -- check for font features
                local f = used_fonts[tmp_fontnum]
                if f and f.mode == "fontforge" and f.otfeatures then
                    for _,featuretable in ipairs(f.otfeatures) do
                        local glyphno,lookups
                        local glyph_lookuptable
                        if f.characters[head.char] then
                            glyphno = f.characters[head.char].index
                            lookups = f.fontloader.glyphs[glyphno].lookups
                            for _,v in ipairs(featuretable) do
                                if lookups then
                                    glyph_lookuptable = lookups[v]
                                    if glyph_lookuptable then
                                        local glt1 = glyph_lookuptable[1]
                                        if glt1.type == "substitution" then
                                            head.char=f.fontloader.lookup_codepoint_by_name[glt1.specification.variant]
                                        elseif glt1.type == "multiple" then
                                            local lastnode
                                            for i,v in ipairs(string.explode(glt1.specification.components)) do
                                                if i==1 then
                                                    head.char=f.fontloader.lookup_codepoint_by_name[v]
                                                else
                                                    local n = node.new("glyph")
                                                    n.next = head.next
                                                    n.font = tmp_fontnum
                                                    n.lang = 0
                                                    n.char = f.fontloader.lookup_codepoint_by_name[v]
                                                    head.next = n
                                                    head = n
                                                end
                                            end
                                        end
                                    end
                                end
                            end -- if f.characters[head.char]
                        end
                    end -- for featuretable, enabled in pairs
                end -- if  f and otffeatures
            end -- fontfamily?
        else
            warning("Unknown node: %q",head.id)
        end
        head = head.next
    end

    return true
end

function insert_backgroundcolor( parent, head, start, bgcolorindex, bg_padding_top, bg_padding_bottom, reverse )
    reverse = reverse or false
    bg_padding_top    = bg_padding_top or 0
    bg_padding_bottom = bg_padding_bottom or 0
    local wd = node.dimensions(parent.glue_set,parent.glue_sign, parent.glue_order,start,head)
    local ht = parent.height
    local dp = parent.depth

    local colorname = publisher.colortable[bgcolorindex]
    local pdfstring = publisher.colors[colorname].pdfstring

    -- wd, ht and dp are now in pdf points
    wd = wd / publisher.factor
    ht = ht / publisher.factor
    dp = dp / publisher.factor
    bg_padding_top    = bg_padding_top    / publisher.factor
    bg_padding_bottom = bg_padding_bottom / publisher.factor
    local rule = node.new("whatsit","pdf_literal")
    if reverse then wd = wd * -1 end
    rule.data = string.format("q %s 0 %g %g %g re f Q", pdfstring, -dp - bg_padding_bottom ,  wd, ht + dp + bg_padding_top + bg_padding_bottom )
    rule.mode = 0
    parent.head = node.insert_before(parent.head,start,rule)
    return rule
end

--- Insert a horizontal rule in the nodelist that is used for underlining. typ is 1 (solid) or 2 (dashed)
function insert_underline( parent, head, start, typ, colornumber)
    colornumber = colornumber or 1
    if colornumber == 0 then colornumber = 1 end
    local wd = node.dimensions(parent.glue_set,parent.glue_sign, parent.glue_order,start,head)
    local ht = parent.height
    local dp = parent.depth
    local dashpattern = ""
    local pdfstring = publisher.pdfstring_from_color(colornumber)

    -- wd, ht and dp are now in pdf points
    wd = wd / publisher.factor
    ht = ht / publisher.factor
    dp = dp / publisher.factor
    local rule = node.new("whatsit","pdf_literal")
    publisher.setprop(rule,"origin","insert_underline")
    -- thickness: ht / ...
    -- downshift: dp/2
    local rule_width = math.round(ht / 13,3)

    if typ == 2 then
        -- dashed
        dashpattern = string.format("[%g] 0 d", 3 * rule_width)
    end

    local shift_down = ( dp - rule_width ) / 1.5
    if typ == 3 then
        -- line-through
        shift_down = - 1.6 * shift_down
    end
    rule.data = string.format("q %s %g w %s  0 %g m %g %g l S Q", pdfstring, rule_width, dashpattern, -1 * shift_down, -wd, -1 * shift_down )
    rule.mode = 0
    parent.head = node.insert_before(parent.head,head,rule)
    return rule
end

--- In the post_linebreak function we manipulate the paragraph that doesn't
--- affect it's typesetting. Underline and 'showhyphens' is done here. The
--- overall appearance of the paragraph is fixed at this time, we can only add
--- decoration now.
do
    local curdir = {}, pardir
    function post_linebreak( head, list_head)
        local underlinetype = nil
        local start_underline = nil
        local underline_color = nil
        local bgcolorindex = nil
        local start_bgcolor = nil
        local bgcolor_reverse = false
        local bg_padding_top = 0
        local bg_padding_bottom = 0
        local reportmissingglyphs = publisher.options.reportmissingglyphs
        while head do
            local pd = publisher.getprop(head,"pardir")
            if pd and #curdir == 0 then
                curdir = {pd}
            end
            if head.id == hlist_node then -- hlist
                post_linebreak(head.list,head)
            elseif head.id == vlist_node then -- vlist
                post_linebreak(head.list,head)
            elseif head.id == dir_node then
                local mode = string.sub(head.dir,1,1)
                local texdir = string.sub(head.dir,2,4)
                local ldir
                if texdir == "TLT" then ldir = "ltr" else ldir = "rtl" end
                if mode == "+" then
                    table.insert(curdir,ldir)
                elseif mode == "-" then
                    local x = table.remove(curdir)
                    if x ~= ldir then
                        warning("paragraph direction incorrect, found %s, expected %s",ldir,x)
                    end
                end
                if att_bgcolor == nil then
                    if start_bgcolor then
                        insert_backgroundcolor(list_head, head, start_bgcolor,bgcolorindex,bg_padding_top,bg_padding_bottom,bgcolor_reverse)
                        start_bgcolor = nil
                    end
                end
            elseif head.id == disc_node then -- disc
                if publisher.options.showhyphenation then
                    -- Insert a small tick where the disc node is
                    local n = node.new("whatsit","pdf_literal")
                    n.mode = 0
                    n.data = "q 0.3 w 0 2 m 0 7 l S Q"
                    -- We don't assign back the list head as we assume(!?!) that
                    -- hyphenation does not start right at the beginning of the list...
                    node.insert_before(list_head,head,n)
                end
            elseif head.id == kern_node then
                local att_underline = node.has_attribute(head, publisher.att_underline)
                local att_bgcolor   = node.has_attribute(head, publisher.att_bgcolor)
                -- at rightskip we must underline (if start exists)
                if att_underline == nil then
                    if start_underline then
                        insert_underline(list_head, head, start_underline,underlinetype,underline_color)
                        start_underline = nil
                    end
                end
                if att_bgcolor == nil then
                    if start_bgcolor then
                        insert_backgroundcolor(list_head, head, start_bgcolor,bgcolorindex,bg_padding_top,bg_padding_bottom,bgcolor_reverse)
                        start_bgcolor = nil
                    end
                end
                if publisher.options.showkerning  then
                    -- Insert a small tick where the disc node is
                    local n = node.new("whatsit","pdf_literal")
                    n.mode = 0
                    n.data = "q .4 G 0.3 w 0 2 m 0 7 l S Q"
                    node.insert_before(list_head,head,n)
                end
            elseif head.id == glue_node then -- glue
                local att_underline = node.has_attribute(head, publisher.att_underline)
                local att_bgcolor   = node.has_attribute(head, publisher.att_bgcolor)
                -- at rightskip we must underline (if start exists)
                if att_underline == nil or head.subtype == 9 then
                    if start_underline then
                        insert_underline(list_head, head, start_underline,underlinetype,underline_color)
                        start_underline = nil
                    end
                end
                if att_bgcolor == nil or head.subtype == 9 then
                    if start_bgcolor then
                        insert_backgroundcolor(list_head, head, start_bgcolor,bgcolorindex,bg_padding_top,bg_padding_bottom,bgcolor_reverse)
                        start_bgcolor = nil
                    end
                end
            elseif head.id == glyph_node then -- glyph
                if reportmissingglyphs then
                    local thisfont = used_fonts[head.font]
                    if thisfont and not thisfont.characters[head.char] then
                        if reportmissingglyphs == "warning" then
                            warning("Glyph %x (hex) is missing from the font %q",head.char,thisfont.name)
                        else
                            err("Glyph %x (hex) is missing from the font %q",head.char,thisfont.name)
                        end
                    end
                end
                local att_underline = node.has_attribute(head, publisher.att_underline)
                local att_bgcolor   = node.has_attribute(head, publisher.att_bgcolor)
                local att_underline_color   = node.has_attribute(head, publisher.att_underline_color)
                local att_bgpaddingtop    = node.has_attribute(head, publisher.att_bgpaddingtop)
                local att_bgpaddingbottom = node.has_attribute(head, publisher.att_bgpaddingbottom)
                if att_underline and att_underline > 0 then
                    if not start_underline then
                        underlinetype = att_underline
                        start_underline = head
                        underline_color = att_underline_color
                    end
                else
                    if start_underline then
                        insert_underline(list_head, head, start_underline, underlinetype,underline_color)
                        start_underline = nil
                    end
                end
                if att_bgcolor and att_bgcolor > 0 then
                    if not start_bgcolor then
                        bgcolorindex = att_bgcolor
                        bg_padding_top    = att_bgpaddingtop
                        bg_padding_bottom = att_bgpaddingbottom
                        start_bgcolor = head
                        bgcolor_reverse = ( curdir[#curdir] == "rtl" )
                    end
                else
                    if start_bgcolor then
                        insert_backgroundcolor(list_head, head, start_bgcolor, bgcolorindex,bg_padding_top,bg_padding_bottom,bgcolor_reverse)
                        start_bgcolor = nil
                    end
                end
            end
            head = head.next
        end
        return head
    end
end

-- fam is a number
function clone_family( fam, params )
    -- fam_tbl = {
    --   ["baselineskip"] = "789372"
    --   ["name"] = "text"
    --   ["normalscript"] = "10"
    --   ["scriptshift"] = "197343"
    --   ["scriptsize"] = "526248"
    --   ["normal"] = "9"
    --   ["size"] = "657810"
    -- },

    local fam_tbl = lookup_fontfamily_number_instance[fam]
    local newfam = {}
    for k,v in pairs(fam_tbl) do
        newfam[k] = v
    end
    newfam.name = "cloned"
    local normal = used_fonts[fam_tbl.normal]

    local ok,b = make_font_instance(newfam.fontfaceregular, params.size * newfam.size )
    if not ok then
        err(b)
        return fam
    else
        newfam.normal = b
        newfam.size = math.floor(params.size * newfam.size)
        lookup_fontfamily_number_instance[#lookup_fontfamily_number_instance + 1] = newfam
        return #lookup_fontfamily_number_instance
    end
end

file_end("fonts.lua")
