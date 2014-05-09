--- Building and formatting a paragraph
--
--  paragraph.lua
--  speedata publisher
--
--  Copyright 2012-2013 Patrick Gundlach.
--  See file COPYING in the root directory for license info.

file_start("paragraph.lua")

require("publisher.fonts")

local Paragraph = {}

function Paragraph:new( textformat  )
    local instance = {
        nodelist,
        textformat = textformat,
    }
    setmetatable(instance, self)
    self.__index = self
    return instance
end

function Paragraph:add_italic_bold( nodelist,parameter )
    -- FIXME(?): recurse, node.traverse() stops at hlists
    for i in node.traverse_id(37,nodelist) do
        if parameter.bold == 1 then
            node.set_attribute(i,att_bold,1)
        end
        if parameter.italic == 1 then
            node.set_attribute(i,att_italic,1)
        end
        if parameter.underline == 1 then
            node.set_attribute(i,att_underline,1)
        end
    end
end

function Paragraph:add_to_nodelist( new_nodes )
    if self.nodelist == nil then
        self.nodelist = new_nodes
    else
        local tail = node.tail(self.nodelist)
        tail.next = new_nodes
        new_nodes.prev = tail
    end
end

function Paragraph:set_color( color )
    if not color then return end

    local colorname
    if color == -1 then
        colorname = "Schwarz"
    else
        colorname = publisher.colortable[color]
    end
    local colstart = node.new("whatsit","pdf_colorstack")
    colstart.data  = publisher.colors[colorname].pdfstring
    if status.luatex_version < 79 then
        colstart.cmd = 1
    else
        colstart.command = 1
    end
    colstart.stack = 0
    colstart.next = self.nodelist
    self.nodelist.prev = colstart
    self.nodelist = colstart
    local colstop  = node.new("whatsit","pdf_colorstack")
    colstop.data  = ""
    if status.luatex_version < 79 then
        colstop.cmd = 2
    else
        colstop.command = 2
    end
    colstop.stack = 0
    local last = node.tail(self.nodelist)
    last.next = colstop
    colstop.prev = last
end

-- Textformat Name
-- function Paragraph:apply_textformat( textformat )
--   if not textformat or self.textformat then return self.nodelist end
--   if publisher.textformats[textformat] and publisher.textformats[textformat].indent then
--     self.nodelist = add_glue(self.nodelist,"head",{ width = publisher.textformats[textformat].indent })
--   end
--   return self.nodelist
-- end

-- Return the width of the longest word. FIXME: check for hypenation
function Paragraph:min_width()
    assert(self)
    local wd = 0
    local last_glue = self.nodelist
    local dimen
    -- Just measure the distance between two glue nodes and take the maximum of that
    local head = self.nodelist
    while head do
        if head.id == publisher.glue_node then
            dimen = node.dimensions(last_glue,head)
            wd = math.max(wd,dimen)
            last_glue = head
        end
        head = head.next
    end
    -- There are two cases here, either there is only one word (= no glue), then last_glue is at the beginning of the
    -- node list. Or we are at the last glue, then there is a word after that glue. last_glue is the last glue element.
    dimen = node.dimensions(last_glue,node.tail(n))
    wd = math.max(wd,dimen)
    return wd
end

function Paragraph:max_width()
    assert(self)
    local wd = node.dimensions(self.nodelist)
    return wd
end

function Paragraph:script( whatever,scr,parameter )
    local nl
    if type(whatever)=="string" or type(whatever)=="number" then
        nl = publisher.mknodes(whatever,parameter.fontfamily,parameter)
    else
        assert(false,string.format("superscript, type()=%s",type(whatever)))
    end
    publisher.set_sub_supscript(nl,scr)
    nl = node.hpack(nl)
    -- Beware! This width is still incorrect (it is the width of the normal glyphs)
    -- Therefore we have to correct the width in pre_linebreak
    node.set_attribute(nl,att_script,scr)
    self:add_to_nodelist(nl)
end

function Paragraph:append( whatever,parameter )
    if type(whatever)=="string" or type(whatever)=="number" then
        self:add_to_nodelist(publisher.mknodes(whatever,parameter.fontfamily,parameter))
    elseif type(whatever)=="table" and whatever.nodelist then
        self:add_italic_bold(whatever.nodelist,parameter)
        self:add_to_nodelist(whatever.nodelist)
        publisher.set_fontfamily_if_necessary(whatever.nodelist,parameter.fontfamily)
    elseif type(whatever)=="boolean" then
        self:add_to_nodelist(publisher.mknodes(tostring(whatever),parameter.fontfamily,parameter))
    elseif type(whatever)=="function" then
        self:add_to_nodelist(publisher.mknodes(whatever(),parameter.fontfamily,parameter))
    elseif type(whatever)=="userdata" then -- node.is_node in einer späteren Version
        self:add_to_nodelist(whatever)
    elseif type(whatever)=="table" and #whatever == 0 then
        self:add_to_nodelist(publisher.mknodes("",parameter.fontfamily,parameter))
    elseif type(whatever)=="table" then
        for i=1,#whatever do
            if type(whatever[i]) == "userdata" then
                self:add_to_nodelist(whatever[i])
            end
        end
    else
        if type(whatever)=="table" then printtable("Paragraph:append",whatever) end
        assert(false,string.format("Interner Fehler bei Paragraph:append, type(arg)=%s",type(whatever)))
    end
end

--- Turn a node list into a shaped block of text.
-- FIXME: document why splitting is needed (ul/li in data)
function Paragraph:format(width_sp, default_textformat_name,options)
    options = options or {}
    local parameter = {}

    if options.allocate == "auto" then
        w("try to make a parshape")
        w("area %s",options.area)
        local cg = options.current_grid
        local areaname = options.area
        w("current row %d",cg:current_row(areaname))
        local current_row    = cg:current_row(areaname)
        local number_of_rows = cg:number_of_rows(areaname)
        -- printtable("cg:allocation_x_y",cg.allocation_x_y)
        parameter.parshape = {}
        local framenumber = cg:framenumber(areaname)
        local maxframes = cg:number_of_frames(areaname)
        while framenumber <= maxframes do
            for i = current_row,number_of_rows do
                parameter.parshape[#parameter.parshape + 1] = cg:get_parshape(i,areaname,framenumber)
            end
            framenumber = framenumber + 1
            current_row = 1
        end
    end
    local nodelist = node.copy_list(self.nodelist)
    local objects = {nodelist}
    local head = nodelist
    local whatsit_id = publisher.whatsit_node
    local user_defined_whatsit_id = publisher.user_defined_whatsit
    while head do
        if head.id == whatsit_id and head.subtype == user_defined_whatsit_id and head.user_id == publisher.user_defined_marker and head.prev then
            -- We are at a <li> item. This needs special treatment
            head.prev.next = nil
            head.prev = nil
            objects[#objects + 1] = head
        end
        head = head.next
    end

    for i=1,#objects do
        nodelist = objects[i]

        -- The first whatist (type user_defined_marker) is not necessary
        -- for this. It indicates a new line and we have done this in
        -- the previous.
        if nodelist.id == publisher.whatsit_node and nodelist.subtype == publisher.user_defined_whatsit and nodelist.user_id == publisher.user_defined_marker then
            nodelist = node.remove(nodelist,nodelist)
        end
        if nodelist == nil then
            -- nothing after a <ul>/<ol>
            break
        end

        local current_textformat_name,current_textformat
        if self.textformat then
            current_textformat_name = self.textformat
        else
            current_textformat_name = default_textformat_name
        end

        if publisher.textformats[current_textformat_name] then
            current_textformat = publisher.textformats[current_textformat_name]
        else
            current_textformat = publisher.textformats["text"]
        end

        publisher.fonts.pre_linebreak(nodelist)


        if current_textformat.indent then
            parameter.hangindent = current_textformat.indent
            parameter.hangafter  = -current_textformat.rows
        end
        local rows,indent
        indent = node.has_attribute(nodelist,publisher.att_indent)
        rows   = node.has_attribute(nodelist,publisher.att_rows)

        if indent then
            parameter.hangindent = indent
        end
        if rows then
            parameter.hangafter = -1 * rows
        end

        local ragged_shape
        if current_textformat then
            if current_textformat.alignment == "leftaligned" or current_textformat.alignment == "rightaligned" or current_textformat.alignment == "centered" then
                ragged_shape = true
            else
                ragged_shape = false
            end
        end

        -- If there is ragged shape (i.e. not a rectangle of text) then we should turn off
        -- font expansion. This is done by setting tex.pdfadjustspacing to 0 temporarily
        if ragged_shape then
            parameter.tolerance     = 5000
            parameter.hyphenpenalty = 200

            local adjspace = tex.pdfadjustspacing
            tex.pdfadjustspacing = 0
            nodelist = publisher.do_linebreak(nodelist,width_sp,parameter)
            tex.pdfadjustspacing = adjspace
            publisher.fix_justification(nodelist,current_textformat.alignment)
        else
            nodelist = publisher.do_linebreak(nodelist,width_sp,parameter)
        end

        -- Remove glue between the lines
        -- it's always 0 anyway (hopefully!)
        local line = nodelist.head
        while line do
            if line.id == 10 then
                line.prev.next = line.next
                if line.next then
                    line.next.prev = line.prev
                end
            end
            line = line.next
        end

        line = nodelist.head
        local c = 0
        while line do
            c = c + 1
            if c == 1 then
                -- orphan, but ignore on one-line texts
                if current_textformat.orphan == false and line.next then
                    node.set_attribute(line,publisher.att_break_below_forbidden,1)
                end
            end
            if line.id == 0 and line.next ~= nil and line.next.next == nil then
                -- widow
                if current_textformat.widow == false then
                    node.set_attribute(line,publisher.att_break_below_forbidden,2)
                end
            end
            line = line.next
        end


        publisher.fonts.post_linebreak(nodelist)

        if current_textformat.paddingtop then
            nodelist.list = publisher.add_glue(nodelist.list,"head",{width = current_textformat.paddingtop})
            node.set_attribute(nodelist.list,publisher.att_break_below_forbidden,3)
        end
        if current_textformat.bordertop then
            nodelist.list = publisher.add_rule(nodelist.list,"head",{width = -1073741824, height = current_textformat.bordertop})
            node.set_attribute(nodelist.list,publisher.att_break_below_forbidden,4)
        end
        if current_textformat.margintop then
            nodelist.list = publisher.add_glue(nodelist.list,"head",{width = current_textformat.margintop})
        end
        if current_textformat.breakbelow == false then
            node.set_attribute(node.tail(nodelist.list),publisher.att_break_below_forbidden,5)
        end
        if current_textformat.borderbottom then
            nodelist.list = publisher.add_rule(nodelist.list,"tail",{width = -1073741824, height = current_textformat.borderbottom})
            node.set_attribute(node.tail(nodelist.list),publisher.att_break_below_forbidden,6)
        end
        if current_textformat.marginbottom then
            nodelist.list = publisher.add_glue(nodelist.list,"tail",{width = current_textformat.marginbottom})
            node.set_attribute(node.tail(nodelist.list),publisher.att_omit_at_top,1)
        end
        if current_textformat.breakbelow == false then
            node.set_attribute(node.tail(nodelist.list),publisher.att_break_below_forbidden,7)
        end

        objects[i] = nodelist.list
        nodelist.list = nil
        node.free(nodelist)
    end

    for i=1,#objects - 1 do
        local last = node.tail(objects[i])
        last.next = objects[i+1]
        objects[i+1].prev = last
    end
    nodelist = node.vpack(objects[1])

    return nodelist
end


-- We get a lot of objects (paragraphs) of different heights.
-- We need to find _one_ breakpoint such that the new objects
function Paragraph.vsplit( objects_t,frameheight,totalobjectsheight )
    trace("vsplit")
    local goal = frameheight
    local totalheight = 0
    local area_filled = false
    local ht = 0

    local toplist
    -- This is the list that gets all the lines (hboxes) for
    -- the area. All other lines stay in the objects_t table

    local vlist = table.remove(objects_t,1)

    local hbox = vlist.head
    local templist
    while not area_filled do
        while hbox do
            local lineheight = 0
            if hbox.id == publisher.hlist_node then
                lineheight = hbox.height + hbox.depth
            elseif hbox.id == publisher.glue_node then
                lineheight = hbox.spec.width
                -- local x = node.has_attribute(hbox,publisher.att_omit_at_top)
                -- if x == 1 and templist == nil and toplist == nil then
                --     hbox.spec.width = 0
                --     lineheight = 0
                -- end
            elseif hbox.id == publisher.rule_node then
                lineheight = hbox.height + hbox.depth
            else
                w("unknown node 1: %d",hbox.id)
            end
            if ht + lineheight >= goal then
                -- There is enough material for the area
                local x = node.has_attribute(hbox,publisher.att_omit_at_top)
                if x == 1 then
                    -- We are at the bottom of the area and the next
                    -- item would be omitted at the top, so we can
                    -- safely remove this item
                    vlist.head = node.remove(vlist.head,hbox)
                end

                if vlist.head then
                    -- but when we remove it, the vlist
                    -- might be empty
                    -- if it's not empty (there are items that go onto the next area)
                    -- we will re-insert the rest of the list in the list of objects.
                    table.insert(objects_t,1,vlist)
                end
                if templist then
                    vlist = node.vpack(templist)
                    table.insert(objects_t,1,vlist)
                end
                if toplist then
                    v = node.vpack(toplist)
                    return v
                else
                    return publisher.empty_block()
                end
            else
                local newhead
                vlist.head,newhead = node.remove(vlist.head,hbox)
                -- if break is not allowed, we store this in a temporary list
                local break_forbidden = node.has_attribute(hbox,publisher.att_break_below_forbidden)

                -- don't disallow breaks on the last line. This "7" needs closer inspection, it looks
                -- wrong. Had a document where a ruled heading with break-below="no" went into an endless loop
                if newhead == nil and break_forbidden ~= 7 then
                    break_forbidden = false
                end
                if break_forbidden then
                    templist = node.insert_after(templist,node.tail(templist),hbox)
                else
                    if templist then
                        local head = templist
                        repeat
                            head = templist
                            templist = head.next
                            if templist then
                                templist.prev = nil
                                head.next = nil
                            end
                            toplist = node.insert_after(toplist,node.tail(toplist),head)
                        until templist == nil
                    end
                    toplist = node.insert_after(toplist,node.tail(toplist),hbox)
                end
                hbox = newhead
                ht = ht + lineheight
            end
        end
        if #objects_t == 0 then
            area_filled = true
        else
            -- todo: remove old vlist
            vlist = table.remove(objects_t,1)
            hbox = vlist.head
        end
    end
    if toplist then
        return node.vpack(toplist)
    else
        return publisher.empty_block()
    end
end

file_end("paragraph.lua")

return Paragraph

