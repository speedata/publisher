--- Building and formatting a paragraph
--
--  paragraph.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
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

-- Return the width of the longest word (breakable part)
function Paragraph:min_width(textfomat_name)
    -- Box of wd 1 will generate messages for all lines. We should ignore them as they
    -- are intentional and not to be seen by the user (hfuzz)
    local hfuzz = tex.hfuzz
    tex.hfuzz = publisher.maxdimen

    local nl = node.copy_list(self.nodelist)
    local box = self:format(1,textfomat_name)
    local head = box.head
    local _w,_h,_d
    local max = 0
    while head do
        _w,_h,_d = node.dimensions(box.glue_set, box.glue_sign, box.glue_order,head.head)
        max = math.max(max,_w)
        head = head.next
    end

    node.flush_list(self.nodelist)
    self.nodelist = nl
    tex.hfuzz = hfuzz
    return max
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
        local cg = options.current_grid
        local areaname = options.area
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

        if current_textformat.paddingtop and current_textformat.paddingtop ~= 0 then
            nodelist.list = publisher.add_glue(nodelist.list,"head",{width = current_textformat.paddingtop})
            node.set_attribute(nodelist.list,publisher.att_break_below_forbidden,3)
        end
        if current_textformat.bordertop and current_textformat.bordertop ~= 0 then
            nodelist.list = publisher.add_rule(nodelist.list,"head",{width = -1073741824, height = current_textformat.bordertop})
            node.set_attribute(nodelist.list,publisher.att_break_below_forbidden,4)
        end
        if current_textformat.margintop and current_textformat.margintop ~= 0 then
            nodelist.list = publisher.add_glue(nodelist.list,"head",{width = current_textformat.margintop})
            node.set_attribute(nodelist.list,publisher.att_break_below_forbidden,6)
        end
        if current_textformat.breakbelow == false then
            node.set_attribute(node.tail(nodelist.list),publisher.att_break_below_forbidden,5)
        end
        if current_textformat.borderbottom and current_textformat.borderbottom ~= 0 then
            nodelist.list = publisher.add_rule(nodelist.list,"tail",{width = -1073741824, height = current_textformat.borderbottom})
            node.set_attribute(node.tail(nodelist.list),publisher.att_break_below_forbidden,6)
        end
        if current_textformat.marginbottom and current_textformat.marginbottom ~= 0 then
            nodelist.list = publisher.add_glue(nodelist.list,"tail",{width = current_textformat.marginbottom})
            node.set_attribute(node.tail(nodelist.list),publisher.att_omit_at_top,1)
            -- node.set_attribute(node.tail(nodelist.list),publisher.att_break_below_forbidden,7)
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

function join_table_to_box(objects)
    for i=1,#objects - 1 do
        objects[i].next = objects[i+1]
    end
    if objects[1] == nil then
        return nil
    end
    node.slide(objects[1])

    local vbox = node.vpack(objects[1])
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
--- The return value is  a vbox that should be placed in the PDF and has a height <= frameheight. If there
--- is material left over for a next area, the `objects_t` table is changed and vsplit gets called again.
--- Making `objects_t` empty is a signal for the function calling vsplit (commands/text) that all
--- text has been put into the PDF.
function Paragraph.vsplit( objects_t,frameheight )
    trace("vsplit")

    --- Step 1: collect all the objects in one big table.
    --- ------------------------------------------------
    --- The objects that are not allowed to break are temporarily
    --- collected in a special vertical list that gets vpacked to
    --- disallow an "area" break.
    ---
    --- ![Step 1](img/vsplit2.png)
    --- (assuming that there is a `break-below="no"` for the text format of the header).
    local hlist = {}

    -- a list for hboxes with break_below = true
    local tmplist = {}
    local tmp
    local numlists = #objects_t
    local vlist = table.remove(objects_t,1)
    local i = 1
    while vlist do
        local head = vlist.head
        while head do
            if i == numlists and head.next == nil then
                -- the last object must not be in the tmplist
                node.unset_attribute(head,publisher.att_break_below_forbidden)
            end
            head.prev = nil
            local break_forbidden = node.has_attribute(head,publisher.att_break_below_forbidden)
            if break_forbidden then
                tmplist[#tmplist + 1] = head
                tmp = head.next
                head.next = nil
                head = tmp
            else
                -- break allowed
                -- if there is anything in the tmplist, we vpack it and add it to the current hlist.
                if #tmplist > 0 then
                    tmplist[#tmplist + 1] = head

                    tmp = head.next
                    head.next = nil
                    head = tmp

                    local vbox = join_table_to_box(tmplist)
                    hlist[#hlist + 1] = vbox
                    tmplist = {}
                else
                    hlist[#hlist + 1] = head
                    tmp = head.next
                    head.next = nil
                    head = tmp
                end
            end
        end
        vlist = table.remove(objects_t,1)
        i = i + 1
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
    local lineheight
    while not area_filled do
        for i=1,#hlist do
            local hbox = table.remove(hlist,1)

            if #thisarea == 0 and node.has_attribute(hbox, publisher.att_omit_at_top) then
                -- When the margin-below appears at the top of the new frame, we just ignore
                -- it. Too bad Lua doesn't have a 'next' in for-loops
            else
                if hbox.id == publisher.hlist_node or hbox.id == publisher.vlist_node then
                    lineheight = hbox.height + hbox.depth
                elseif hbox.id == publisher.glue_node then
                    lineheight = hbox.spec.width
                elseif hbox.id == publisher.rule_node then
                    lineheight = hbox.height + hbox.depth
                else
                    w("unknown node 1: %d",hbox.id)
                end
                if accumulated_height + lineheight <= goal then
                    thisarea[#thisarea + 1] = hbox
                    accumulated_height = accumulated_height + lineheight
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
        objects_t[1] = join_table_to_box(remaining_objects)
    end

    --- It's a common situation where there is a single free row but the next material is
    --- too high for the row. So we return an empty list and hope that the calling function
    --- is clever enough to detect this case. (Well, it's not too difficult to detect, as
    --- the `objects_t` table is not empty yet.)
    return join_table_to_box(thisarea) or publisher.empty_block()
end

file_end("paragraph.lua")

return Paragraph

