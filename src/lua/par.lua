-- experimental / testing

file_start("par.lua")

local Par = {}

function Par:new( textformat,origin )
    local instance = {
        nodelist,
        textformat = textformat,
        origin = origin,
        typ = "par"
    }
    setmetatable(instance, self)
    self.__index = self
    for i=1,#instance do
        instance[i] = nil
    end
    return instance
end

-- Used when padding right > 0
-- It is not enough to reduce the width of the lines, because
-- the outer object will be smaller than requested.
-- Therefore it is necessary to add the padding right width
-- to the right of each line.
local function widen_nodelist(nl,wd)
    local glue = publisher.make_glue({ width = wd })
    local hbox = nl.head

    while hbox do
        if hbox.id == publisher.hlist_node then
            local tail = node.tail(hbox)
            node.insert_after(tail,tail,node.copy(glue))
            hbox.width = hbox.width + wd
        end
        hbox = hbox.next
    end
    nl.width = nl.width + wd
    return nl
end

local function indent_nodelist(nl,wd)
    local glue = publisher.make_glue({ width = wd })
    local hbox = nl.head
    while hbox do
        if hbox.id == publisher.hlist_node then
            hbox.head = node.insert_before(hbox.head,hbox.head,node.copy(glue))
            hbox.width = hbox.width + wd
        end
        hbox = hbox.next
    end
    nl.width = nl.width + wd
    return nl
end

local void_elements = {area = true, base = true, br = true, col = true, hr = true, img = true, input = true, link = true, meta = true, param = true, command = true, keygen = true, source = true }

local function reconstruct_html_text(elt)
    local eltname = elt[".__local_name"]
    local ret = {}
    table.insert(ret,"<")
    table.insert(ret,eltname)
    local attributes = {}
    for key,value in next,elt,nil do
        if type(key) == "string" and not string.match( key,"^.__" ) then
            table.insert(ret,string.format(" %s=%q",key,value))
        end
    end
    if #elt == 0 and void_elements[eltname] then
        table.insert(ret,">")
    else
        table.insert(ret,">")
        for i=1,#elt do
            local thiselt = elt[i]
            local type_thiselt = type(thiselt)
            if type_thiselt == "string" then
                table.insert(ret,publisher.xml_escape(thiselt))
            elseif type_thiselt == "table" then
                table.insert(ret,reconstruct_html_text(thiselt))
            end
        end

        table.insert(ret,"</")
        table.insert(ret,eltname)
        table.insert(ret,">")
    end
    return table.concat( ret )
end

local function mktextnode(self,text,options)
    local nodes, newdir = publisher.mknodes(tostring(text),options,"par/mktextnode")
    self.direction = self.direction or newdir
    local tmp = node.getproperty(nodes)
    if options.fontfamily and publisher.fonts.lookup_fontfamily_number_instance[options.fontfamily] then
        local fontheight = publisher.fonts.lookup_fontfamily_number_instance[options.fontfamily].baselineskip
        local col = publisher.get_attribute(nodes,"color")
        nodes = publisher.add_rule(nodes,"head",{height = 0.75 * fontheight, depth = 0.25 * fontheight, width = 0 })
        node.setproperty(nodes,tmp)
        publisher.set_attribute(nodes,"fontfamily",options.fontfamily)
        if col then
            publisher.set_attribute(nodes,"color",col)
        end
    end
    if options.newline then
        publisher.setprop(nodes,"newline",true)
        if options.discardallowed then
            publisher.setprop(nodes,"discardallowed",true)
        end
    end
    return nodes
end

local function flatten(self,items,options)
    options = options or {}
    local ret = {}
    for i=1,#items do
        local thisself = items[i]
        local typ_thisself = type(thisself)
        local new_options = publisher.copy_table_from_defaults(options)
        new_options.direction = new_options.direction or self.direction
        if typ_thisself == "table" and thisself.contents then
            -- w("par/flatten: type: table with contents")
            if thisself.options then
                for key,value in next,thisself.options,nil do
                   new_options[key] = value
                end
            end
            if new_options.padding_left and not self.padding_left then self.padding_left = new_options.padding_left end
            if node.is_node(thisself.contents) then
                if thisself.contents.id == publisher.whatsit_node and thisself.contents.subtype == publisher.user_defined_whatsit then
                    if type(thisself.contents.value) == "function" then
                        -- leaders and break_url
                        table.insert(ret,thisself.contents.value(new_options))
                    else
                        table.insert(ret,thisself.contents)
                    end
                    -- action node for example
                else
                    table.insert(ret,thisself.contents)
                end
            elseif type(thisself.contents) == "table" and thisself.contents.flatten_callback then
                local f = thisself.contents.flatten_callback
                thisself.contents.flatten_callback = nil
                local tmp = f(thisself.contents,new_options)
                for i=1,#tmp do
                    table.insert(ret,tmp[i])
                end
            elseif type(thisself.contents) == "string" or type(thisself.contents) == "number" or type(thisself.contents) == "boolean" then
                table.insert(ret,mktextnode(self,thisself.contents,new_options))
            else
                local tmp = flatten(self,thisself.contents,new_options)
                for i=1,#tmp do
                    table.insert(ret,tmp[i])
                end
            end
        elseif typ_thisself == "string" or typ_thisself == "number" or typ_thisself == "boolean" then
            -- w("par/flatten: type: string or similar")
            table.insert(ret,mktextnode(self,thisself,new_options))
        elseif typ_thisself == "table" and thisself[".__type"] == "element" and new_options.html ~= "off" then
            -- w("par/flatten: type: HTML")
            -- Now this is a bit strange and I should explain. The XML parser (luxor.lua)
            -- creates a table structure from the XML text, but for HTML parsing, we need the
            -- original XML string. So I reconstruct the XML text (without comments etc.) and
            -- run this through Go's HTML parser and add CSS.
            -- This is basically the new HTML mode. The old HTML parser is not needed anymore.
            if new_options.html == "inner" then
                local c = 1
                while true do
                    if #thisself > c and type(thisself[1]) ~= "table" then
                        c = c + 1
                    else
                        break
                    end
                end
                thisself = thisself[c]
            end
            if type(thisself) == "string" then
                local text = thisself
                local tmp = flatten(self,{text},new_options)
                for j=1,#tmp do
                    table.insert(ret,tmp[j])
                end
            else
                local htmltext = reconstruct_html_text(thisself)
                local csstext = publisher.css:gettext()
                -- todo: add  white-space: pre; if publisher.options.ignoreeol == false
                -- csstext = string.format("body {font-family-number: %d ;} ",options.fontfamily)
                csstext = " a { text-decoration: none; color: black}" ..  csstext .. string.format(" body {font-family-number: %d ;}",options.fontfamily)
                local tab = splib.parse_html_text(htmltext,csstext)
                if type(tab) == "string" then
                    local a,b = load(tab)
                    if a then a() else err(b) return end
                end
                local startnewline = 0
                local body = csshtmltree[1]
                -- printtable("body",body)
                local firstelement = body[1]
                if firstelement then
                    if type(firstelement) == "string" and not string.match( firstelement ,"^%s*$")  then
                        startnewline = 1
                    elseif type(firstelement[1]) == "string" and not string.match( firstelement[1] ,"^%s*$")  then
                        startnewline = 1
                    elseif type(firstelement[1]) == "table" then
                        if firstelement[1].direction == "→" then
                            startnewline = 1
                        end
                    end
                    options.override_alignment = true
                    local blocks = publisher.parse_html(csshtmltree, options) or {}
                    blocks = publisher.flatten_boxes(blocks)
                    -- printtable("blocks",blocks)

                    -- block number width contents
                    local blocknumber = 1
                    for b=1,#blocks do
                        local thisblock = blocks[b]
                        local this_block_has_contents = false
                        for tb=1,#thisblock do
                            local tbc = thisblock[tb].contents
                            local dir = publisher.getprop(tbc,"direction")
                            local mode = thisblock.mode
                            local startblock = (tb == 1 and mode == "block" )
                            local is_newline = ( blocknumber > startnewline and ( this_block_has_contents == false ) and dir ~= "→" )
                            if tbc then
                                if startblock or is_newline then
                                    publisher.setprop(tbc,"split",true)
                                    publisher.setprop(tbc,"padding_left",thisblock.padding_left)
                                    publisher.setprop(tbc,"prependnodelist",thisblock.prependnodelist)
                                    publisher.setprop(tbc,"prependlist",thisblock.prependlist)
                                    publisher.setprop(tbc,"margin_top",thisblock.margin_top)
                                    publisher.setprop(tbc,"margin_bottom",thisblock.margin_bottom)
                                end
                                table.insert(ret,tbc)
                                this_block_has_contents = true
                            end
                        end
                        if this_block_has_contents then
                            blocknumber = blocknumber + 1
                        end
                    end
                end
            end
        elseif typ_thisself == "userdata" and node.is_node(thisself) then
            -- w("par/flatten: type: userdata")
            if thisself.id == publisher.whatsit_node and thisself.subtype == publisher.user_defined_whatsit then
                if type(thisself.value) == "function" then
                    -- leaders and break_url
                    table.insert(ret,thisself.value(new_options))
                else
                    table.insert(ret,thisself)
                end
            else
                 table.insert(ret,thisself)
            end
        elseif typ_thisself == "table" and thisself.elementname == "SetVariable" then
            -- w("par/flatten: type: setvariable - ignore")
            -- ignore
        elseif typ_thisself == "table" then
            -- w("par/flatten: type: table")
            local tmp = flatten(self,{table_textvalue(thisself)},new_options)
            for j=1,#tmp do
                table.insert(ret,tmp[j])
            end
        else
            -- w("par/flatten: type: unknown")
            -- w("typ_thisself %s",typ_thisself)
        end
    end
    for i=#items,1,-1 do
        items[i] = nil
    end
    for i=1,#ret do
        items[i] = ret[i]
    end
    return items
end

function Par:prepend(whatever)
    self.prependlist = self.prependlist or {}
    table.insert(self.prependlist,1, whatever)
end

function Par:indent(width_sp)
    -- w("indent %s wd %gpt",self.origin or "?", width_sp / publisher.factor)
    self.padding_left = self.padding_left or 0
    self.padding_left = self.padding_left + width_sp
end

function Par:min_width( textformat_name, options )
    options = options or {}
    local newpar = publisher.deepcopy(self)
    newpar.origin = "min_width"
    options = options or {}
    local new_options = publisher.copy_table_from_defaults(options)
    new_options.textformat = textformat_name

    local formatted = newpar:format(1,new_options)
    local nl = formatted
    local head = formatted.head
    if not head then return 0 end
    -- See bug #46: a text format margin-top has a glue as its first item in the vlist
    while head.id ~= publisher.hlist_node do
        head = head.next
    end
    local _w,_h,_d
    local max = 0
    while head do
        if head.head then
            _w,_h,_d = node.dimensions(formatted.glue_set, formatted.glue_sign, formatted.glue_order,head.head)
            max = math.max(max,_w)
        end
        head = head.next
    end

    node.flush_list(formatted)
    return max
end

function Par:max_width_and_lineheight(options)
    local newpar = publisher.deepcopy(self)
    newpar.origin = "max_width_and_lineheight"
    newpar.textformat = nil
    options = options or {}
    local new_options = publisher.copy_table_from_defaults(options)
    new_options.textformat = publisher.textformats["__leftaligned"]
    local nl = newpar:format(publisher.maxdimen,new_options)
    local maxwd = 0
    local hlist = nl.head
    while hlist do
        if hlist.id == publisher.hlist_node then
            -- could also be a glue node
            wd,_,_ = node.dimensions(hlist.head, node.tail(hlist.head))
            maxwd = math.max(maxwd,wd)
        end
        hlist = hlist.next
    end
    return maxwd, nl.height + nl.depth
end

function Par:mknodelist( options )
    flatten(self,self,options)
    local nodelist
    local objects = {}
    for i=1,#self do
        local thisself = self[i]
        if nodelist == nil then
            -- the beginning of a new line (perhaps the first new line)
            nodelist = thisself
        elseif thisself.id == publisher.vlist_node or publisher.getprop(thisself,"split") then
            -- text right after a  newline, so push stuff that we have into the objects list and
            -- put what we have into the node list
            if nodelist.id == publisher.glue_node and nodelist.prev == nil and nodelist.next == nil then
                -- ignore, just glue
            else
                table.insert(objects,nodelist)
            end
            nodelist = thisself
        else
            -- just objects to be appended to the node list
            local tail = node.tail(nodelist)
            tail.next = thisself
            thisself.prev = tail
        end
    end
    -- insert the last fragment as an object of its own (new line)
    -- or add it to the last object of the table
    if nodelist then
        local split = publisher.getprop(nodelist,"split")
        if #objects > 0 and not split then
            local tail = node.tail(objects[#objects])
            tail.next = nodelist
            nodelist.prev = tail
        else
            table.insert(objects,nodelist)
        end
    end
    self.objects = objects
end

local get_lineheight
function get_lineheight( nodelist )
    local head = nodelist
    while head do
        if head.id == publisher.vlist_node or head.id == publisher.hlist_node then return get_lineheight(head.list) end
        if head.id == publisher.glyph_node then
            local ffnumber = publisher.get_attribute(head,"fontfamily")
            local fi = publisher.fonts.lookup_fontfamily_number_instance[ffnumber]
            if fi then
                return fi.baselineskip
            else
                err("allocate/auto cannot find font instance")
                return 0
            end
        end
        head = head.next
    end
    return 0
end

local function get_border_width_height_margintop(nodelist)
    local sum_ht = 0
    local sum_margin_top = 0
    local sum_margin_bottom = 0
    local head = nodelist.head
    while head do
        if head.id == publisher.glue_node then
            local margintop = publisher.get_attribute(head,"margintop")
            local paddingtop = publisher.get_attribute(head,"paddingtop")
            local paddingbottom = publisher.get_attribute(head,"paddingbottom")
            if margintop then
                sum_margin_top = sum_margin_top + head.width
            elseif paddingtop or paddingbottom then
                sum_ht = sum_ht + head.width
            end
        elseif node.has_field(head,"height") then
            sum_ht = sum_ht + head.height + head.depth
        end
        head = head.next
    end
    return nodelist.width,sum_ht,sum_margin_top
end


function Par:format( width_sp, options )
    -- w("call format %s",self.origin)
    options = options or {}
    options.maxwidth_sp = width_sp
    publisher.remove_first_whitespace(self)
    publisher.remove_last_whitespace(self)
    self:mknodelist(options)
    local parameter = {}
    local current_textformat = self.textformat or options.textformat
    if not current_textformat then
        if self.textformat or options.textformat then
            err("textformat undefined, using text instead")
        end
        current_textformat = publisher.textformats.text
    end
    if self.width then
        width_sp = self.width
    end
    self.padding_left = self.padding_left or 0

    self.padding_right = self.padding_right or 0
    if self.padding_left > 0 then
        width_sp = width_sp - self.padding_left
    end
    if self.padding_right > 0 then
        width_sp = width_sp - self.padding_right
    end
    -- w("self.padding_left %s %gpt",self.origin,self.padding_left / publisher.factor)
    for i=1,#self do
        self[i] = nil
    end

    if options.allocate == "auto" then
        local indent = current_textformat.indent
        local indent_this_row = function(row)
            if not indent or indent == 0 then return false end
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
                    parshape[row] = {ps[1],ps[2] - self.padding_left - self.padding_right}
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
        local lineheight = get_lineheight(self.objects[1])
        if lineheight > 0 then
            local cg = publisher.pages[current_pagenumber].grid
            local max_width = math.min(width_sp,cg:width_sp(cg:number_of_columns(areaname)))

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
    local objects = self.objects
    local orig_width_sp = width_sp
    if #objects == 0 then return node.new("vlist") end
    local objectrow = 0
    for i=1,#objects do
        nodelist = objects[i]
        if publisher.getprop(nodelist,"br") ~= true then
            objectrow = objectrow + 1
        end
        local pardir = publisher.getprop(nodelist,"pardir")
        if pardir == "rtl" then
            tex.shapemode = 1
            parameter.pardir = "TRT"
        else
            tex.shapemode = 0
        end
        local has_margin_top, has_margin_bottom
        if current_textformat.htmlverticalspacing == "inner" and i > 1 or current_textformat.htmlverticalspacing == "all" then
            has_margin_top = publisher.getprop(nodelist,"margin_top")
        end
        if current_textformat.htmlverticalspacing == "inner" and i < #objects or current_textformat.htmlverticalspacing == "all" then
            has_margin_bottom = publisher.getprop(nodelist,"margin_bottom")
        end
        width_sp = orig_width_sp
        local thispaddingleft = self.padding_left
        local thispaddingright = self.padding_right
        local this_object_padding_left = publisher.getprop(nodelist,"padding_left")
        if this_object_padding_left then
            thispaddingleft = thispaddingleft + this_object_padding_left
            width_sp = width_sp - this_object_padding_left
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

        -- see #338 - penalty - hlist - penalty gives an error “Assertion ``varmem[(o)].hh.v.RH == cur_p`` failed”
        if nodelist.id == publisher.penalty_node and nodelist.next and nodelist.next.id == publisher.hlist_node and nodelist.next.next and nodelist.next.next.id == publisher.penalty_node and nodelist.next.next.next then
            nodelist = nodelist.next
        end

        publisher.fonts.pre_linebreak(nodelist)

        -- both are set only for ul/ol lists
        local indent = publisher.get_attribute(nodelist,"indent") or 0
        local rows   = node.has_attribute(nodelist,publisher.att_rows)
        parameter.hangindent = indent

        -- indent and rows
        if current_textformat.indent and current_textformat.rows then
            if objectrow <= current_textformat.rows or current_textformat.rows < 0 then
                parameter.hangindent = parameter.hangindent + current_textformat.indent
            end
        end
        parameter.hangafter = rows  or current_textformat.rows  or 0
        if self.startendborder or self.startborder then
            local ba = publisher.borderattributes[self.borderstart or self.startendborder]
            thispaddingleft = thispaddingleft + ba.border_left_width
        end


        if self.initial then
            parameter.hangindent =  parameter.hangindent + self.initial.width
            local i_ht = self.initial.height + self.initial.depth
            local ht_nodelist = get_lineheight(nodelist)

            local maxindent = 0
            -- get max indent
            if parameter.parshape then
                for i=1,math.round(i_ht / ht_nodelist,0) do
                    maxindent = math.max(parameter.parshape[i][1],maxindent)
                end
            end
            local curindent
            if parameter.parshape then
                for i=1,math.round(i_ht / ht_nodelist,0) do
                    curindent = maxindent - parameter.parshape[i][1]
                    parameter.parshape[i][1] = maxindent + self.initial.width
                    parameter.parshape[i][2] = parameter.parshape[i][2] - self.initial.width - curindent
                end
            else
                parameter.hangafter = math.max( parameter.hangafter, math.ceil(math.round(i_ht / ht_nodelist,1)))
            end
        end

        parameter.hangafter = parameter.hangafter * -1
        parameter.disable_hyphenation = current_textformat.disable_hyphenation
        local prepend = publisher.getprop(nodelist,"prependlist") or self.prependlist
        local ragged_shape
        if current_textformat.alignment == "leftaligned" or current_textformat.alignment == "rightaligned" or current_textformat.alignment == "centered" or current_textformat.alignment == "start" or current_textformat.alignment == "end" then
            ragged_shape = true
        else
            ragged_shape = false
        end

        -- if the last items are newline nodes, clear them (see #142)
        local tail = node.slide(nodelist)
        while tail and publisher.get_attribute(tail,"newline") do
            nodelist = node.remove(nodelist,tail)
            tail = node.tail(nodelist)
        end

        if nodelist == nil then
            -- ignore
        else
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
                publisher.fix_justification(nodelist,current_textformat.alignment,nil,pardir)
            else
                nodelist = publisher.do_linebreak(nodelist,width_sp,parameter)
            end

            if thispaddingleft > 0 then
                indent_nodelist(nodelist,thispaddingleft)
            end
            if thispaddingright > 0 then
                widen_nodelist(nodelist,thispaddingright)
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
                    if line.head and not node.has_attribute(line.head,publisher.att_ignore_orphan_widowsetting) then
                        node.set_attribute(line,publisher.att_break_below_forbidden,1)
                    end
                end
                if publisher.less_or_equal_than_n_lines(line, current_textformat.widow) then
                    if line.head and not node.has_attribute(line.head,publisher.att_ignore_orphan_widowsetting) then
                        node.set_attribute(line,publisher.att_break_below_forbidden,2)
                    end
                end
                line = line.next
            end

            publisher.fonts.post_linebreak(nodelist)

            if self.margin_top then
                nodelist.list = publisher.add_glue(nodelist.list,"head",{width = self.margin_top},"par.lua/if self.margin_top")
                publisher.set_attribute(nodelist.list,"margintop",1)
            end
            if has_margin_top then
                nodelist.list = publisher.add_glue(nodelist.list,"head",{width = has_margin_top},"par.lua/if has_margin_top")
                publisher.set_attribute(nodelist.list,"margintop",1)
            end
            if self.padding_top and self.padding_top > 0 then
                nodelist.list = publisher.add_glue(nodelist.list,"head",{width = self.padding_top, attributes},"par.lua/self.padding_top" )
                publisher.set_attribute(nodelist.list,"paddingtop",1)
            end
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
                node.set_attribute(nodelist.list,publisher.att_margin_top_boxstart,current_textformat.margintopboxstart)
                node.set_attribute(nodelist.list,publisher.att_break_below_forbidden,6)
            end
            if current_textformat.breakbelow == false then
                node.set_attribute(node.tail(nodelist.list),publisher.att_break_below_forbidden,5)
            end

            if self.padding_bottom and self.padding_bottom > 0 then
                local glue
                nodelist.list, glue = publisher.add_glue(nodelist.list,"tail",{width = self.padding_bottom, attributes},"par.lua/self.padding_bottom" )
                publisher.set_attribute(glue,"paddingbottom",1)
            end

            if current_textformat.borderbottom and current_textformat.borderbottom ~= 0 then
                nodelist.list = publisher.add_rule(nodelist.list,"tail",{width = width_sp, height = current_textformat.borderbottom},"par.lua/tf.borderbottom")
                node.set_attribute(node.tail(nodelist.list),publisher.att_break_below_forbidden,6)
            end
            if current_textformat.marginbottom and current_textformat.marginbottom ~= 0 then
                nodelist.list = publisher.add_glue(nodelist.list,"tail",{width = current_textformat.marginbottom},"par.lua/tf.marginbottom")
                node.set_attribute(node.tail(nodelist.list),publisher.att_omit_at_top,1)
            end
            if self.margin_bottom and self.margin_bottom > 0 then
                nodelist.list = publisher.add_glue(nodelist.list,"tail",{width = self.margin_bottom},"par.lua/self.margin_bottom")
                node.set_attribute(node.tail(nodelist.list),publisher.att_omit_at_top,1)
            end
            if has_margin_bottom then
                nodelist.list = publisher.add_glue(nodelist.list,"tail",{width = has_margin_bottom})
                node.set_attribute(node.tail(nodelist.list),publisher.att_omit_at_top,1)
            end

            node.set_attribute(nodelist.list,publisher.att_margin_newcolumn, current_textformat.colpaddingtop or 0)

            if current_textformat.breakbelow == false then
                node.set_attribute(node.tail(nodelist.list),publisher.att_break_below_forbidden,7)
            end
            objects[i] = nodelist.list
            if prepend then
                local prependnodelist = nil
                for j=1,#prepend do
                    local thisprepend = prepend[j]
                    local options = thisprepend[3] or options
                    local str = thisprepend[1]
                    local label
                    if type(str) == "string" then
                        label = node.hpack(publisher.mknodes(str,options,"par prepend"))
                    elseif node.is_node(str) then
                        label = str
                    end
                    if label then
                        local wd = thisprepend[2] or node.dimensions(label)
                        local labeldistance = thisprepend[4] or tex.sp("5pt")
                        local labelalign = thisprepend[5] or "right"
                        local labelbox
                        labelbox = publisher.whatever_hbox(label,wd,options,labeldistance,labelalign)
                        prependnodelist = node.insert_after(prependnodelist,node.tail(prependnodelist),labelbox)
                    end
                end
                if prependnodelist then
                    prependnodelist = node.hpack(prependnodelist)
                    prependnodelist.head = publisher.add_glue(prependnodelist.head,"head",{width = - prependnodelist.width, shrink = 2^16, shrink_order = 3 })
                    prependnodelist.width = 0

                    local thisobject = objects[i]
                    while thisobject do
                        if thisobject.id == publisher.hlist_node then
                            break
                        end
                        thisobject = thisobject.next
                    end
                    local cur = thisobject.head
                    while cur do
                        if cur.id ~= publisher.glue_node then
                            cur = node.insert_before(thisobject.head,cur,prependnodelist)
                            break
                        end
                        cur = cur.next
                    end
                    thisobject.head = cur
                end
            end

            nodelist.list = nil
            node.free(nodelist)
        end
    end

    for i=1,#objects - 1 do
        local last = node.tail(objects[i])
        last.next = objects[i+1]
        objects[i+1].prev = last
    end

    nodelist = node.vpack(objects[1])

    if self.startendborder or self.startborder then
        local wd,ht,margintop = get_border_width_height_margintop(nodelist)
        local bordernumber = self.startendborder or self.startborder
        publisher.borderattributes[bordernumber].shiftdown = margintop
        publisher.set_attribute(nodelist.list,"bordernumber",bordernumber)
        publisher.set_attribute(nodelist.list,"borderwd",wd)
        publisher.set_attribute(nodelist.list,"borderht",ht)
    end
    publisher.setprop(nodelist,"origin","par:format")

    if self.initial then
        local ht_nodelist = get_lineheight(nodelist)
        local initial_hlist = self.initial
        local ht_initial = initial_hlist.height

        -- Node lists of width 0 stick to the right, which is
        -- good for rtl text, but not for ltr. So on non-rtl text
        -- the shift left must be equal to the width
        if self.direction ~= "rtl" then
            initial_hlist.shift = -initial_hlist.width
        end
        publisher.setprop(self.initial,"origin","initial")
        initial_hlist = node.vpack(initial_hlist)
        publisher.setprop(initial_hlist,"origin","initial")

        local shift_down =  ht_nodelist * 0.75 - initial_hlist.height
        initial_hlist.shift = -shift_down
        initial_hlist.width = 0
        nodelist.head.head = node.insert_before(nodelist.head.head,nodelist.head.head,initial_hlist)
    end
    self.objects = nil
    self.nodelist = nodelist
    return nodelist
end

function Par:append( whatever, options )
    options = options or {}
    if options.initial and not self.initial then self.initial = options.initial end
    self.direction = self.direction or options.direction
    if options.textformat and not self.textformat then self.textformat = options.textformat end
    if options.padding_right and not self.padding_right then self.padding_right = options.padding_right end
    if options.labelleft then
        self:prepend({options.labelleft,options.labelleftwidth,options,options.labelleftdistance,options.labelleftalign})
    end
    -- w("whatever %s type %s",tostring(whatever), type(whatever))
    if type(whatever) == "string" then whatever = {whatever} end
    table.insert(self,{ contents = whatever, options = options} )
end


file_end("par.lua")

return Par
