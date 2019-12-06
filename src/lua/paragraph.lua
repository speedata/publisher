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

-- Add italic/bold/underline/... attribtes to node
function Paragraph:add_italic_bold( nodelist,parameter )
    -- FIXME(?): recurse, node.traverse() stops at hlists
    for i in node.traverse_id(publisher.glyph_node,nodelist) do
        if parameter.bold == 1 then
            node.set_attribute(i,publisher.att_bold,1)
        end
        if parameter.italic == 1 then
            node.set_attribute(i,publisher.att_italic,1)
        end
        if parameter.underline then
            node.set_attribute(i,publisher.att_underline,parameter.underline)
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
    -- todo: why not use publisher.set_color_if_necessary??
    if not self.nodelist then return end
    local colorname
    if color == -1 then
        colorname = "black"
    else
        colorname = publisher.colortable[color]
    end
    local colstart = node.new("whatsit","pdf_colorstack")
    colstart.data  = publisher.colors[colorname].pdfstring
    colstart.command = 1
    colstart.stack = 0
    colstart.next = self.nodelist
    self.nodelist.prev = colstart
    local dontformat = node.has_attribute(self.nodelist,publisher.att_dont_format)
    if dontformat then
        node.set_attribute(colstart,publisher.att_dont_format,dontformat)
    end

    self.nodelist = colstart

    local colstop  = node.new("whatsit","pdf_colorstack")
    colstop.data  = ""
    colstop.command = 2
    colstop.stack = 0
    node.set_attribute(colstart,publisher.att_origin,publisher.origin_setcolor)
    node.set_attribute(colstop,publisher.att_origin,publisher.origin_setcolor)
    local last = node.tail(self.nodelist)
    last.next = colstop
    colstop.prev = last
end

-- Return the width of the longest word (breakable part)
function Paragraph:min_width(textfomat_name)
    local nl = node.copy_list(self.nodelist)
    local box = self:format(1,textfomat_name)
    local head = box.head
    -- See bug #46: a text format margin-top has a glue as its first item in the vlist
    while head.id ~= publisher.hlist_node do
        head = head.next
    end
    local _w,_h,_d
    local max = 0
    while head do
        -- there are some situations, where a list has no head (a bullet point)
        -- we should not bother checking them.
        -- LuaTeX 0.71 needs the extra 'node.has_field(head,"head")' check.
        if node.has_field(head,"head") and head.head ~= nil then
            _w,_h,_d = node.dimensions(box.glue_set, box.glue_sign, box.glue_order,head.head)
            max = math.max(max,_w)
        end
        head = head.next
    end

    node.flush_list(self.nodelist)
    self.nodelist = nl
    return max
end

-- To get the maximum width of a paragraph we format the nodelist
-- with the maximum paragraph width (maxdimen) and find out how large
-- the resulting nodelist is.
--
-- Before that we just used node.dimensions, which seems to be inaccurate.
function Paragraph:max_width()
    local cp_nodelist = node.copy_list(self.nodelist)
    local cp_textformat = self.textformat
    self.textformat = "__leftaligned"
    local nl = self:format(publisher.maxdimen)
    self.textformat = cp_textformat
    self.nodelist = cp_nodelist
    local maxwd = 0
    local hlist = nl.head
    while hlist do
        wd,_,_ = node.dimensions(hlist.head, node.tail(hlist.head))
        maxwd = math.max(maxwd,wd)
        hlist = hlist.next
    end
    return maxwd
end

function Paragraph:script( whatever,scr,parameter )
    local nl
    if type(whatever)=="string" or type(whatever)=="number" or type(whatever) == "table" then
        nl = publisher.mknodes(table_textvalue(whatever),parameter.fontfamily,parameter)
    else
        assert(false,string.format("superscript, type()=%s",type(whatever)))
    end
    publisher.set_sub_supscript(nl,scr)
    nl = node.hpack(nl)
    -- Beware! This width is still incorrect (it is the width of the normal glyphs)
    -- Therefore we have to correct the width in pre_linebreak
    node.set_attribute(nl,publisher.att_script,scr)
    self:add_to_nodelist(nl)
end

function Paragraph:append( whatever,parameter )
    -- w("Paragraph:append, type(whatever) = %s",type(whatever))
    parameter = parameter or {}
    local tab
    tab = publisher.textformats[self.textformat or 'text']
    parameter.tab = ( tab and tab.tab ) or {}

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
    elseif node.is_node(whatever) then
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

    local current_textformat_name,current_textformat
    current_textformat_name = self.textformat or default_textformat_name

    if publisher.textformats[current_textformat_name] then
        current_textformat = publisher.textformats[current_textformat_name]
    else
        current_textformat = publisher.textformats["text"]
    end
    if options.allocate == "auto" then
        local get_lineheight = function( nodelist )
            local head = nodelist
            while head do
                if head.id == publisher.glyph_node  then
                    local ffnumber = node.has_attribute(head,publisher.att_fontfamily)
                    local fi = publisher.fonts.lookup_fontfamily_number_instance[ffnumber]
                    return fi.baselineskip
                end
                head = head.next
            end
            return 0
        end
        local indent = current_textformat.indent
        local indent_this_row = function(row)
            if not indent  or indent == 0 then return false end
            local r = current_textformat.rows
            if r == 0 then return false end
            if  r < 0 then
                return row > r * -1
            end
            return row <= r
        end
        local set_parshape = function(parshape,ps,rows)
            local psmin = {}
            for _,row in ipairs(rows) do
                if parshape[row] then
                    local tmp = parshape[row]
                    psmin[1] = math.max(ps[1] ,tmp[1])
                    psmin[2] = math.min(ps[2] ,tmp[2])
                    parshape[row] = psmin
                else
                    parshape[row] = {ps[1],ps[2]}
                end
            end
        end
        local is_equal = function(a,b)
            return math.abs(a - b) < 3000
        end
        -- First we need to get the starting page
        local current_pagenumber = publisher.current_pagenumber
        local areaname = options.area

        local frame, _ = publisher.pages[current_pagenumber].grid:get_advanced_cursor(areaname)
        if frame == publisher.maxframes then
            -- signal for "page is full"
            current_pagenumber = current_pagenumber + 1
        end
        if not publisher.pages[current_pagenumber] then
            -- it might be that the page is full and there is no next page
            -- then we set maxparshape to {0,maxwd} later on
            current_pagenumber = current_pagenumber - 1
        end
        -- Get the par shape
        local lineheight = get_lineheight(self.nodelist)
        if lineheight > 0 then
            local cg = publisher.pages[current_pagenumber].grid
            local max_width = cg:width_sp(cg:number_of_columns(areaname))
            local gridheight = cg.gridheight
            local parshape = {}
            local maxframes = cg:number_of_frames(areaname)

            -- this is to remove rounding errors
            local g_l = math.round(gridheight / lineheight,3)
            gridheight = lineheight * g_l

            local accumulated_height

            -- The row for the paragraph shape. Not identical to the grid row
            local current_row = 1
            local grid_row
            local lowest_grid_row = 0

            -- There might be material on one of the next pages. In this case,
            -- and only in this case, the next page is already allocated
            -- See bug #75 on github
            local maxparshape
            while publisher.pages[current_pagenumber] do
                cg = publisher.pages[current_pagenumber].grid
                local grid_lower = gridheight
                local framenumber, startrow_grid =  cg:get_advanced_cursor(areaname)
                -- Let's assume that the already typeset text ends at the next page
                -- This is not a real fix, but good enough for the moment.
                -- We need to fix the output/text collect routine
                -- and typeset the text directly. See #100
                if framenumber > maxframes then
                    -- w("framenumber %d > maxframes %d",framenumber,maxframes)
                    current_pagenumber = current_pagenumber + 1
                    maxparshape = {0,max_width}
                    framenumber = 1; startrow_grid = 1
                else
                    maxparshape = nil
                end
                while framenumber <= maxframes do
                    grid_row = startrow_grid
                    accumulated_height = lowest_grid_row
                    grid_lower = lowest_grid_row + gridheight
                    lowest_grid_row = lowest_grid_row + cg:number_of_rows(areaname) * gridheight
                    while grid_row <=  cg:number_of_rows(areaname,framenumber) do
                        local rows = {}
                        -- maxparshape is only "active" when placed on future, non-initialized pages
                        -- Hack!
                        local ps = maxparshape or cg:get_parshape(grid_row,areaname,framenumber)
                        -- ps is 0 when the line is completely allocated
                        if ps ~= 0 then
                            -- accumulated_height starts with 0
                            if accumulated_height <= grid_lower then
                                -- When this paragraph row is within the grid row,
                                -- it must be added to our list
                                rows[#rows + 1] = current_row
                            end

                            while accumulated_height <= grid_lower do
                                if is_equal(accumulated_height + lineheight,grid_lower) then
                                    -- if the current paragraph row ends "exactly" at the
                                    -- bottom of the grid line, we are done and can continue
                                    -- with the next paragraph row. The current paragraph row is
                                    -- already added to the list for this grid row (see above)
                                elseif accumulated_height + lineheight < grid_lower then
                                    -- if the current paragraph row ends above the lower
                                    -- grid line, we need to add the next row to the
                                    -- current grid line.
                                    rows[#rows + 1] = current_row + 1
                                else
                                    -- This is the case where the current paragraph row ends
                                    -- below the lower grid line. We don't need to increase
                                    -- the paragraph line number and the accumulated
                                    -- height, so we break out of the while loop
                                    break
                                end

                                current_row = current_row + 1
                                accumulated_height = accumulated_height + lineheight
                            end
                            -- w("rows %s",table.concat(rows,", "))
                            set_parshape(parshape,ps,rows)
                            grid_lower = grid_lower + gridheight
                        end -- if ps ~= 0
                        grid_row = grid_row + 1
                    end
                    startrow_grid = 1
                    framenumber = framenumber + 1
                end
                current_pagenumber = current_pagenumber + 1
            end
            -- This should be the last line in the parshape array, so the
            -- rest of the lines in the paragraph have the full width
            parshape[#parshape + 1] = {0,max_width}
            for i,ps in ipairs(parshape) do
                if indent_this_row(i) then
                    ps[1] = ps[1] + indent
                    ps[2] = ps[2] - indent
                end
            end
            parameter.parshape = parshape
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

        -- The first whatsit (type user_defined_marker) is not necessary
        -- for this. It indicates a new line and we have done this in
        -- the previous.
        if nodelist.id == publisher.whatsit_node and nodelist.subtype == publisher.user_defined_whatsit and nodelist.user_id == publisher.user_defined_marker then
            nodelist = node.remove(nodelist,nodelist)
        end
        if nodelist == nil then
            -- nothing after a <ul>/<ol>
            break
        end

        local langs_num,langs
        langs = {}
        if current_textformat.hyphenchar then
            langs_num = publisher.get_languages_used(nodelist)
            for i,v in ipairs(langs_num) do
                local l = publisher.get_language(v)
                langs[#langs + 1] = l
                l.prehyphenchar = lang.prehyphenchar(l.l)
                lang.prehyphenchar(l.l,unicode.utf8.byte(current_textformat.hyphenchar))
            end
        end
        if current_textformat.filllastline then
            local min_width_sp = current_textformat.filllastline / 100 * width_sp
            local head = nodelist
            while head do
                local _w,_h,_d = node.dimensions(head)
                -- glue subtype 15 == parfillskip
                if head.id == publisher.glue_node and head.subtype ~= 15 and (_w < min_width_sp) then
                    local prev = head.prev
                    prev.next = nil
                    head.prev = nil
                    head = node.hpack(head)
                    prev.next = head
                    head.prev = prev
                    break
                end

            head = head.next
            end
        end

        publisher.fonts.pre_linebreak(nodelist)

        -- both are set only for ul/ol lists
        local indent = node.has_attribute(nodelist,publisher.att_indent)
        local rows   = node.has_attribute(nodelist,publisher.att_rows)

        local initial_indent = 0
        local initial_row = 0

        parameter.hangindent =    indent or current_textformat.indent or 0
        parameter.hangafter  =  ( rows   or current_textformat.rows   or 0 )

        if self.initial then
            parameter.hangindent =  parameter.hangindent + self.initial.width
            local i_ht = self.initial.height + self.initial.depth
            local _w, _h, _d = node.dimensions(nodelist)
            local nl_ht = _h + _d
            local maxindent = 0
            -- get max indent
            if parameter.parshape then
                for i=1,math.round(i_ht / nl_ht,0) do
                    maxindent = math.max(parameter.parshape[i][1],maxindent)
                end
            end
            local curindent
            if parameter.parshape then
                for i=1,math.round(i_ht / nl_ht,0) do
                    curindent = maxindent - parameter.parshape[i][1]
                    parameter.parshape[i][1] = maxindent + self.initial.width
                    parameter.parshape[i][2] = parameter.parshape[i][2] - self.initial.width - curindent
                end
            else
                parameter.hangafter  =  math.max( parameter.hangafter, math.ceil(math.round(i_ht / nl_ht,1)))
            end
        end
        parameter.hangafter = parameter.hangafter * -1
        parameter.disable_hyphenation = current_textformat.disable_hyphenation

        local ragged_shape
        if current_textformat then
            if current_textformat.alignment == "leftaligned" or current_textformat.alignment == "rightaligned" or current_textformat.alignment == "centered" then
                ragged_shape = true
            else
                ragged_shape = false
            end
        end


        -- if the last items are newline nodes, clear them (see #142)
        local tail = node.slide(nodelist)
        while tail and node.has_attribute(tail,publisher.att_newline) do
            nodelist = node.remove(nodelist,tail)
            tail = node.tail(nodelist)
        end
        if nodelist == nil then return node.new("vlist") end


        -- If there is ragged shape (i.e. not a rectangle of text) then we should turn off
        -- font expansion. This is done by setting tex.(pdf)adjustspacing to 0 temporarily
        if ragged_shape then
            local save_tolerance     = parameter.tolerance
            local save_hyphenpenalty = parameter.hyphenpenalty
            parameter.tolerance     = 5000
            parameter.hyphenpenalty = 200

            local adjspace
            adjspace = tex.adjustspacing
            tex.pdfadjustspacing = 0
            tex.adjustspacing = 0
            nodelist = publisher.do_linebreak(nodelist,width_sp,parameter)

            parameter.tolerance     = save_tolerance
            parameter.hyphenpenalty = save_hyphenpenalty

            tex.pdfadjustspacing = adjspace
            tex.adjustspacing = adjspace
            publisher.fix_justification(nodelist,current_textformat.alignment)
        else
            nodelist = publisher.do_linebreak(nodelist,width_sp,parameter)
        end

        for _,v in ipairs(langs) do
            lang.prehyphenchar(v.l,v.prehyphenchar)
        end


        -- Remove glue between the lines
        -- it's always 0 anyway (hopefully!)
        local line = nodelist.head
        while line do
            if line.id == publisher.glue_node then
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
            if c < current_textformat.orphan and line.next then
                node.set_attribute(line,publisher.att_break_below_forbidden,1)
            end
            if less_or_equal_than_n_lines(line, current_textformat.widow) then
               node.set_attribute(line,publisher.att_break_below_forbidden,2)
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
        end

        node.set_attribute(nodelist.list,publisher.att_margin_newcolumn, current_textformat.colpaddingtop or 0)

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
    if publisher.options.showtextformat then
        local each_line = objects[1]
        while each_line do
            if node.has_field(each_line,"head") then
                each_line.head = publisher.annotate_nodelist(each_line,current_textformat_name or "text")
            end
            each_line = each_line.next
        end
    end

    nodelist = node.vpack(objects[1])
    if self.initial then
        local initial_hlist = self.initial
        local ht = initial_hlist.height


        initial_hlist.shift = -initial_hlist.width
        node.set_attribute(self.initial,publisher.att_origin,publisher.origin_initial)
        local i = publisher.martrix


        initial_hlist = node.vpack(initial_hlist)
        initial_hlist.shift = -ht / 2
        initial_hlist.width = 0
        initial_hlist.height = 0
        initial_hlist.depth  = 0

        nodelist.head.head = node.insert_before(nodelist.head.head,nodelist.head.head,initial_hlist)
    end

    return nodelist
end

-- Return true iff the paragraph has at lines ore less text
-- lines left over and is not at the last line.
function less_or_equal_than_n_lines( nodelist, lines )
    if lines == 0 then return false end
    local has_n_lines = false
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
function Paragraph.vsplit( objects_t, parameter )
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
                    local vbox = join_table_to_box(tmplist)
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
        local obj1 = join_table_to_box({table.unpack(hlist,1,splitpos)})
        if hlist[splitpos + 1] then
            local margin_newcolumn_obj2 = node.has_attribute(hlist[splitpos + 1], publisher.att_margin_newcolumn)
            if margin_newcolumn_obj2 and margin_newcolumn_obj2 > 0 then
                table.insert(hlist,splitpos + 1,publisher.add_glue(nil,"head",{width=margin_newcolumn_obj2}))
            end
            local obj2 = join_table_to_box({table.unpack(hlist,splitpos + 1)})
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

