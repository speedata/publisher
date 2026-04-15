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
    eltname = string.lower(eltname)
    local ret = {}
    table.insert(ret,"<")
    table.insert(ret,eltname)
    if publisher.newxpath and elt[".__attributes"]  then
        for key, value in pairs(elt[".__attributes"]) do
            table.insert(ret,string.format(" %s=%q",key,value))
        end
    else
        for key,value in next,elt,nil do
            if type(key) == "string" and not string.match( key,"^.__" ) then
                table.insert(ret,string.format(" %s=%q",key,value))
            end
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
    if options.fontoutlinewidth and options.fontoutlinewidth > 0 then
        local pw = node.new("whatsit","pdf_literal")
        pw.data = string.format(" 1 Tr %g w ",sp_to_bp(options.fontoutlinewidth))
        nodes = node.insert_before(nodes,nodes,pw)

        pw = node.new("whatsit","pdf_literal")
        pw.data = " 0 Tr "
        nodes = node.insert_after(nodes,node.tail(nodes),pw)
    end

    self.direction = self.direction or newdir
    if options.fontfamily and publisher.fonts.lookup_fontfamily_number_instance[options.fontfamily] then
        local node_properties = node.getproperty(nodes)
        local fontheight = publisher.fonts.lookup_fontfamily_number_instance[options.fontfamily].baselineskip
        local col = publisher.get_attribute(nodes,"color")
        local hl = publisher.get_attribute(nodes,"hyperlink")
        nodes = publisher.add_rule(nodes,"head",{height = 0.75 * fontheight, depth = 0.25 * fontheight, width = 0 },"mktextnode fontfamily")
        node.setproperty(nodes,node_properties)
        publisher.set_attribute(nodes,"fontfamily",options.fontfamily)
        if col then publisher.set_attribute(nodes,"color",col)   end
        if hl then publisher.set_attribute(nodes,"hyperlink",hl) end
    end
    if options.newline then
        publisher.setprop(nodes,"newline",true)
        if options.discardallowed then
            publisher.setprop(nodes,"discardallowed",true)
        end
    end
    return nodes
end

local function flatten(self,items,options,data)
    options = options or {}
    local ret = {}
    local ret_len = 0
    local opts_pool = {}
    local function take_options(src)
        local opts = table.remove(opts_pool) or {}
        for k in pairs(opts) do opts[k] = nil end
        for k,v in next,src,nil do opts[k] = v end
        return opts
    end
    local function release_options(opts)
        for k in pairs(opts) do opts[k] = nil end
        opts_pool[#opts_pool + 1] = opts
    end
    local function append(v)
        ret_len = ret_len + 1
        ret[ret_len] = v
    end
    local copy_defaults = publisher.copy_table_from_defaults
    local roles_a = publisher.roles_a
    local pdf_ua = publisher.options.format == "PDF/UA"
    local text_options_shared
    local items_len = #items
    -- Cache type strings to avoid repeated string comparisons
    local type_string = "string"
    local type_number = "number"
    local type_boolean = "boolean"
    local type_table = "table"
    local type_userdata = "userdata"
    local type_function = "function"
    local default_css_text = publisher.css:gettext()
    -- Feature flag tracking: detect which features are used so that
    -- insert_nonmoving_whatsits can skip clean paragraphs
    local function mark_color() self.has_color = true end
    local function mark_hyperlink() self.has_hyperlink = true end
    local function mark_role() self.has_role = true end
    local function mark_special() self.has_special_nodes = true end

    for i=1,items_len do
        local thisself = items[i]
        local typ_thisself = type(thisself)
        local reuse_text_opts = (typ_thisself == type_string or typ_thisself == type_number or typ_thisself == type_boolean)
        local new_options
        if reuse_text_opts and text_options_shared then
            new_options = text_options_shared
        else
            new_options = take_options(options)
            if pdf_ua then
                if options.role == 0 then
                    new_options.role = options.parentrole
                    new_options.id = roles_a[options.parentrole] .. "_" .. tostring(options.rolecounter)
                elseif options.role then
                    new_options.id = roles_a[options.role] .. "_" .. tostring(options.rolecounter)
                    new_options.parent = options.parent
                else
                    new_options.id = self.id
                end
                new_options.parentrole = options.role
                new_options.parentid = options.id
            end
            new_options.direction = new_options.direction or self.direction
            local effective_textformat = self.textformat or options.textformat
            if not new_options.letterspacing and effective_textformat and effective_textformat.letterspacing then
                new_options.letterspacing_em = effective_textformat.letterspacing
            end
            if reuse_text_opts then
                text_options_shared = new_options
            end
        end
        if typ_thisself == type_table and thisself.contents then
            -- w("par/flatten: type: table with contents")
            if thisself.options then
                for key,value in next,thisself.options,nil do
                   new_options[key] = value
                end
            end
            if new_options.padding_left and not self.padding_left then self.padding_left = new_options.padding_left end
            if node.is_node(thisself.contents) then
                if thisself.contents.id == publisher.whatsit_node and thisself.contents.subtype == publisher.user_defined_whatsit then
                    mark_special()
                    if type(thisself.contents.value) == "function" then
                        -- leaders and break_url
                        append(thisself.contents.value(new_options))
                    else
                        append(thisself.contents)
                    end
                    -- action node for example
                else
                    -- Direct node with potentially pre-set attributes (e.g. from HTML/CSS)
                    mark_special()
                    append(thisself.contents)
                end
            elseif type(thisself.contents) == type_table and thisself.contents.flatten_callback then
                mark_special()
                local f = thisself.contents.flatten_callback
                thisself.contents.flatten_callback = nil
                local tmp = f(thisself.contents,new_options)
                for i=1,#tmp.objects do
                    append(tmp.objects[i])
                end
            elseif type(thisself.contents) == type_string or type(thisself.contents) == type_number or type(thisself.contents) == type_boolean then
                if new_options.color and new_options.color ~= 1 then mark_color() end
                if new_options.hyperlink then mark_hyperlink() end
                if new_options.role then mark_role() end
                append(mktextnode(self,thisself.contents,new_options))
            else
                local tmp = flatten(self,thisself.contents,new_options,data)
                for i=1,#tmp do
                    append(tmp[i])
                end
            end
        elseif typ_thisself == type_string or typ_thisself == type_number or typ_thisself == type_boolean then
            -- w("par/flatten: type: string or similar")
            if new_options.color and new_options.color ~= 1 then mark_color() end
            if new_options.hyperlink then mark_hyperlink() end
            if new_options.role then mark_role() end
            append(mktextnode(self,thisself,new_options))
        elseif typ_thisself == type_table and thisself[".__type"] == "element" and new_options.html ~= "off" then
            -- HTML content can have any features, mark conservatively
            mark_color() mark_hyperlink() mark_role() mark_special()
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
            if type(thisself) == type_string then
                local text = thisself
                local tmp = flatten(self,{text},new_options,data)
                for j=1,#tmp do
                    append(tmp[j])
                end
            else
                local htmltext = reconstruct_html_text(thisself)
                local csstext = " a { text-decoration: none; color: black}" ..  default_css_text

                if self.textformat and self.textformat.cssfontsize == true then
                    -- ignore
                else
                    csstext = csstext .. string.format(" body {font-family-number: %d ;}",options.fontfamily)
                end
                local body
                local htmltree = splib.parse_html_text(htmltext,csstext)
                body = htmltree[1][2]
                body.block = nil
                local startnewline = 0
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
                    local blocks = publisher.parse_html(htmltree, new_options, data) or {}
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
                                    local padding_left = thisblock.padding_left or 0
                                    local margin_top = thisblock.margin_top or 0
                                    publisher.setprop(tbc,"prependnodelist",thisblock.prependnodelist)
                                    publisher.setprop(tbc,"prependlist",thisblock.prependlist)
                                    publisher.setprop(tbc,"margin_bottom",thisblock.margin_bottom)
                                    if thisblock.startendborder then
                                        local border_attributes = publisher.borderattributes[thisblock.startendborder]
                                        publisher.set_attribute(tbc,"bordernumber",thisblock.startendborder)
                                        local wd, ht, dp = node.dimensions(tbc)
                                        publisher.set_attribute(tbc,"borderwd",wd)
                                        publisher.set_attribute(tbc,"borderht",ht + dp)
                                        if border_attributes then
                                            padding_left = padding_left + border_attributes.border_left_width
                                            margin_top = margin_top + border_attributes.border_top_width + border_attributes.padding_top
                                        end

                                    end
                                    publisher.setprop(tbc,"margin_top",margin_top)
                                    publisher.setprop(tbc,"padding_left",padding_left)
                                end
                                append(tbc)
                                this_block_has_contents = true
                            end
                        end
                        if this_block_has_contents then
                            blocknumber = blocknumber + 1
                        end
                    end
                end
            end
        elseif typ_thisself == type_userdata and node.is_node(thisself) then
            -- w("par/flatten: type: userdata")
            if thisself.id == publisher.whatsit_node and thisself.subtype == publisher.user_defined_whatsit then
                mark_special()
                if type(thisself.value) == type_function then
                    -- leaders and break_url
                    append(thisself.value(new_options))
                else
                    append(thisself)
                end
            else
                 -- Direct node with potentially pre-set attributes (e.g. from HTML/CSS)
                 mark_special()
                 append(thisself)
            end
        elseif typ_thisself == type_table and thisself.elementname == "SetVariable" then
            -- w("par/flatten: type: setvariable - ignore")
            -- ignore
        elseif typ_thisself == type_table then
            -- w("par/flatten: type: table")
            local tmp
            if publisher.newxpath then
                local x, msg = xpath.string_value(thisself)
                if msg then err(msg) end
                tmp = flatten(self,{x},new_options, data)
            else
                tmp = flatten(self,{table_textvalue(thisself)},new_options, data)
            end
            for j=1,#tmp do
                append(tmp[j])
            end
        else
            -- w("par/flatten: type: unknown")
            -- w("typ_thisself %s",typ_thisself)
        end
        if not (reuse_text_opts and new_options == text_options_shared) then
            release_options(new_options)
        end
    end
    -- Optimized: directly overwrite items, then clear extras
    for i=1,ret_len do
        items[i] = ret[i]
    end
    -- Only clear items beyond ret_len
    for i=ret_len+1,items_len do
        items[i] = nil
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

function Par:min_width( textformat_name, options,data )
    options = options or {}
    local newpar = publisher.deepcopy(self)
    newpar.origin = "min_width"
    options = options or {}
    local new_options = publisher.copy_table_from_defaults(options)
    new_options.textformat = textformat_name

    local formatted = newpar:format(1,new_options,data)
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

function Par:max_width_and_lineheight(options,data)
    local newpar = publisher.deepcopy(self)
    newpar.origin = "max_width_and_lineheight"
    local orig_letterspacing = newpar.textformat and newpar.textformat.letterspacing
    newpar.textformat = nil
    options = options or {}
    local new_options = publisher.copy_table_from_defaults(options)
    new_options.textformat = publisher.textformats["__leftaligned"]
    if orig_letterspacing then
        new_options.letterspacing_em = orig_letterspacing
    end
    local nl = newpar:format(publisher.maxdimen,new_options,data)
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

function Par:mknodelist( options, data )
    flatten(self,self,options, data)
    local nodelist
    local objects = {}
    for i=1,#self do
        local thisself = self[i]
        if nodelist == nil then
            -- the beginning of a new line (perhaps the first new line)
            nodelist = thisself
        elseif (thisself.id == publisher.vlist_node and publisher.getprop(thisself,"origin") ~= "image" and not publisher.getprop(thisself,"inline")) or publisher.getprop(thisself,"split") then
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
            -- Remove strut rule between two glues inline at join points
            -- (strut rules from mktextnode are always at the fragment head).
            if self.html == "off" and thisself.id == publisher.rule_node
               and tail.id == publisher.glue_node
               and thisself.next and thisself.next.id == publisher.glue_node then
                local after_rule = thisself.next
                after_rule.prev = nil
                thisself.next = nil
                node.free(thisself)
                thisself = after_rule
            end
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
            -- Remove strut rule between two glues at final join point
            if self.html == "off" and nodelist.id == publisher.rule_node
               and tail.id == publisher.glue_node
               and nodelist.next and nodelist.next.id == publisher.glue_node then
                local after_rule = nodelist.next
                after_rule.prev = nil
                nodelist.next = nil
                node.free(nodelist)
                nodelist = after_rule
            end
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


function Par:format( width_sp, options,data )
    -- w("call format %s",self.origin)
    options = options or {}
    options.maxwidth_sp = width_sp

    -- If this par contains a single preformatted node (e.g., HTML table),
    -- return it directly without wrapping in another vpack
    if #self == 1 and self[1].options and self[1].options.dontformat then
        local content = self[1].contents
        if node.is_node(content) then
            return content
        end
    end

    publisher.remove_first_whitespace(self)
    publisher.remove_last_whitespace(self)

    local current_textformat = self.textformat or options.textformat
    if not current_textformat then
        if self.textformat or options.textformat then
            err("textformat undefined, using text instead")
        end
        current_textformat = publisher.textformats.text
    end
    options.tab = current_textformat.tab

    self:mknodelist(options,data)

    -- Check if the only object has att_dont_format attribute (e.g., split HTML table)
    -- In this case, return it directly without further formatting
    if #self.objects == 1 then
        local obj = self.objects[1]
        if node.is_node(obj) and node.has_attribute(obj, publisher.att_dont_format) then
            return obj
        end
    end

    local parameter = {}
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
    -- w("self.padding_right %s %gpt",self.origin, self.padding_right / publisher.factor)
    -- w("self.padding_left %s %gpt",self.origin, self.padding_left / publisher.factor)
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
            local cg = publisher.current_grid
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
                if publisher.current_group then
                    cg = publisher.current_grid
                else
                    cg = publisher.pages[current_pagenumber].grid
                end
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
                        local ps = maxparshape or cg:get_parshape(grid_row,areaname,framenumber,width_sp)
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
    local objects_len = #objects
    if objects_len == 0 then return node.new("vlist") end
    local objectrow = 0

    -- Cache frequently accessed self fields
    local self_padding_left = self.padding_left
    local self_padding_right = self.padding_right
    local self_prependlist = self.prependlist
    local self_initial = self.initial
    local self_startendborder = self.startendborder
    local self_startborder = self.startborder
    local self_margin_top = self.margin_top
    local self_border_top_width = self.border_top_width
    local self_padding_top = self.padding_top

    -- Cache publisher node/attribute IDs
    local penalty_node_id = publisher.penalty_node
    local hlist_node_id = publisher.hlist_node
    local glue_node_id = publisher.glue_node
    local att_rows = publisher.att_rows
    local att_ignore_orphan = publisher.att_ignore_orphan_widowsetting
    local att_break_below = publisher.att_break_below_forbidden
    local att_margin_top_boxstart = publisher.att_margin_top_boxstart

    local tf = current_textformat
    for i=1,objects_len do
        nodelist = objects[i]
        if publisher.getprop(nodelist, "br") == true then
            tf = publisher.new_textformat("",current_textformat)
            tf.rows = 9999
            tf.margintop = current_textformat.margintop
            tf.indent = current_textformat.indent
        else
            objectrow = objectrow + 1
        end
        -- Cache property accesses at loop start
        local prop_pardir = publisher.getprop(nodelist,"pardir")
        local prop_margin_top, prop_margin_bottom, prop_padding_left
        local tf_htmlvspace = tf.htmlverticalspacing
        if tf_htmlvspace == "inner" and i > 1 or tf_htmlvspace == "all" then
            prop_margin_top = publisher.getprop(nodelist,"margin_top")
        end
        if tf_htmlvspace == "inner" and i < objects_len or tf_htmlvspace == "all" then
            prop_margin_bottom = publisher.getprop(nodelist,"margin_bottom")
        end
        prop_padding_left = publisher.getprop(nodelist,"padding_left")
        local prop_prependlist = publisher.getprop(nodelist,"prependlist")

        if prop_pardir == "rtl" then
            tex.shapemode = 1
            parameter.pardir = "TRT"
        else
            tex.shapemode = 0
        end
        local has_margin_top = prop_margin_top
        local has_margin_bottom = prop_margin_bottom
        width_sp = orig_width_sp
        local thispaddingleft = self_padding_left
        local thispaddingright = self_padding_right
        local this_object_padding_left = prop_padding_left
        if this_object_padding_left then
            thispaddingleft = thispaddingleft + this_object_padding_left
            width_sp = width_sp - this_object_padding_left
        end
        local langs_num,langs
        langs = {}
        if tf.hyphenchar then
            langs_num = publisher.get_languages_used(nodelist)
            for i,v in ipairs(langs_num) do
                local l = publisher.get_language(v)
                langs[#langs + 1] = l
                l.prehyphenchar = lang.prehyphenchar(l.l)
                lang.prehyphenchar(l.l,unicode.utf8.byte(tf.hyphenchar))
            end
        end

        -- see #338 - penalty - hlist - penalty gives an error "Assertion ``varmem[(o)].hh.v.RH == cur_p`` failed"
        if nodelist.id == penalty_node_id and nodelist.next and nodelist.next.id == hlist_node_id and nodelist.next.next and nodelist.next.next.id == penalty_node_id and nodelist.next.next.next then
            nodelist = nodelist.next
        end
        publisher.fonts.pre_linebreak(nodelist)

        -- both are set only for ul/ol lists
        local indent = publisher.get_attribute(nodelist,"indent") or 0
        local rows   = node.has_attribute(nodelist,att_rows)
        parameter.hangindent = indent

        -- indent and rows
        if tf.indent and tf.rows then
            if objectrow <= tf.rows or tf.rows < 0 then
                parameter.hangindent = parameter.hangindent + tf.indent
            end
        end
        parameter.hangafter = rows or tf.rows or 0
        if self_startendborder or self_startborder then
            local ba = publisher.borderattributes[self.borderstart or self_startendborder]
            thispaddingleft = thispaddingleft + ba.border_left_width
        end

        if self_initial then
            parameter.hangindent =  parameter.hangindent + self_initial.width
            local i_ht = self_initial.height + self_initial.depth
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
                    parameter.parshape[i][1] = maxindent + self_initial.width
                    parameter.parshape[i][2] = parameter.parshape[i][2] - self_initial.width - curindent
                end
            else
                parameter.hangafter = math.max( parameter.hangafter, math.ceil(math.round(i_ht / ht_nodelist,1)))
            end
        end

        parameter.hangafter = parameter.hangafter * -1
        parameter.disable_hyphenation = tf.disable_hyphenation
        local prepend = prop_prependlist or self_prependlist
        -- Cache alignment check
        local tf_alignment = tf.alignment
        local ragged_shape = (tf_alignment == "leftaligned" or tf_alignment == "rightaligned" or tf_alignment == "centered" or tf_alignment == "start" or tf_alignment == "end")

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
                publisher.fix_justification(nodelist,tf_alignment,nil,prop_pardir)
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
                if line.id == glue_node_id then
                    line.prev.next = line.next
                    if line.next then
                        line.next.prev = line.prev
                    end
                end
                line = line.next
            end

            -- Cache tf fields for orphan/widow control
            local tf_orphan = tf.orphan
            local tf_widow = tf.widow
            line = nodelist.head
            local c = 0
            while line do
                c = c + 1
                if c < tf_orphan and line.next then
                    if line.head and not node.has_attribute(line.head,att_ignore_orphan) then
                        node.set_attribute(line,att_break_below,1)
                    end
                end
                if publisher.less_or_equal_than_n_lines(line, tf_widow) then
                    if line.head and not node.has_attribute(line.head,att_ignore_orphan) then
                        node.set_attribute(line,att_break_below,2)
                    end
                end
                line = line.next
            end

            publisher.fonts.post_linebreak(nodelist)
            if self_margin_top then
                nodelist.list = publisher.add_glue(nodelist.list,"head",{width = self_margin_top},"par.lua/if self.margin_top")
                publisher.set_attribute(nodelist.list,"margintop",1)
            end
            if self_border_top_width and self_border_top_width > 0 then
                nodelist.list = publisher.add_glue(nodelist.list,"head",{width = self_border_top_width},"par.lua/if self.border_top_width")
                publisher.set_attribute(nodelist.list,"margintop",1)
            end
            if has_margin_top then
                nodelist.list = publisher.add_glue(nodelist.list,"head",{width = has_margin_top},"par.lua/if has_margin_top")
                publisher.set_attribute(nodelist.list,"margintop",1)
            end
            if self_padding_top and self_padding_top > 0 then
                nodelist.list = publisher.add_glue(nodelist.list,"head",{width = self_padding_top, attributes},"par.lua/self.padding_top" )
                publisher.set_attribute(nodelist.list,"margintop",1)
            end
            if tf.paddingtop and tf.paddingtop ~= 0 then
                nodelist.list = publisher.add_glue(nodelist.list,"head",{width = tf.paddingtop})
                node.set_attribute(nodelist.list,att_break_below,3)
            end
            if tf.bordertop and tf.bordertop ~= 0 then
                nodelist.list = publisher.add_rule(nodelist.list,"head",{width = -1073741824, height = tf.bordertop},"par.lua/tf.bordertop")
                node.set_attribute(nodelist.list,att_break_below,4)
            end
            if tf.margintop and tf.margintop ~= 0 then
                nodelist.list = publisher.add_glue(nodelist.list,"head",{width = tf.margintop})
                node.set_attribute(nodelist.list,att_margin_top_boxstart,tf.margintopboxstart)
                node.set_attribute(nodelist.list,att_break_below,6)
            end
            if tf.breakbelow == false or self.break_after == "avoid" then
                node.set_attribute(node.tail(nodelist.list),att_break_below,5)
            end

            local break_before = tf.break_before or self.break_before
            if break_before == "page" then
                node.set_attribute(nodelist.list,publisher.att_break_before,1)
            elseif break_before == "always" then
                node.set_attribute(nodelist.list,publisher.att_break_before,2)
            end

            if self.padding_bottom and self.padding_bottom > 0 then
                local glue
                nodelist.list, glue = publisher.add_glue(nodelist.list,"tail",{width = self.padding_bottom, attributes},"par.lua/self.padding_bottom" )
                publisher.set_attribute(glue,"paddingbottom",1)
            end

            if tf.borderbottom and tf.borderbottom ~= 0 then
                nodelist.list = publisher.add_rule(nodelist.list,"tail",{width = width_sp, height = tf.borderbottom},"par.lua/tf.borderbottom")
                node.set_attribute(node.tail(nodelist.list),publisher.att_break_below_forbidden,6)
            end
            if tf.marginbottom and tf.marginbottom ~= 0 then
                nodelist.list = publisher.add_glue(nodelist.list,"tail",{width = tf.marginbottom},"par.lua/tf.marginbottom")
                node.set_attribute(node.tail(nodelist.list),publisher.att_omit_at_top,1)
            end
            if self.border_bottom_width and self.border_bottom_width > 0 then
                nodelist.list = publisher.add_glue(nodelist.list,"tail",{width = self.border_bottom_width},"par.lua/if self.border_bottom_width")
            end
            if self.margin_bottom then
                nodelist.list = publisher.add_glue(nodelist.list,"tail",{width = self.margin_bottom},"par.lua/self.margin_bottom")
                node.set_attribute(node.tail(nodelist.list),publisher.att_omit_at_top,1)
            end
            if has_margin_bottom then
                nodelist.list = publisher.add_glue(nodelist.list,"tail",{width = has_margin_bottom})
                node.set_attribute(node.tail(nodelist.list),publisher.att_omit_at_top,1)
            end

            node.set_attribute(nodelist.list,publisher.att_margin_newcolumn, tf.colpaddingtop or 0)
            if tf.breakbelow == false or self.break_after == "avoid" then
                node.set_attribute(node.tail(nodelist.list),publisher.att_break_below_forbidden,7)
            end
            objects[i] = nodelist.list
            if prepend then
                local prependnodelist = nil
                for j=1,#prepend do
                    local thisprepend = prepend[j]
                    local options = thisprepend[3] or options
                    local str = thisprepend[1]
                    if options.color and options.color ~= 1 then self.has_color = true end
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
        local ba = publisher.borderattributes[bordernumber]
        ba.shiftdown = margintop

        publisher.set_attribute(nodelist.list,"bordernumber",bordernumber)
        publisher.set_attribute(nodelist.list,"borderwd",wd)
        publisher.set_attribute(nodelist.list,"borderht",ht)
    end
    publisher.setprop(nodelist,"origin","par:format")
    -- Transfer feature flags from Par to the vlist so insert_nonmoving_whatsits can skip clean paragraphs
    if self.has_color then publisher.setprop(nodelist,"has_color",true) end
    if self.has_hyperlink then publisher.setprop(nodelist,"has_hyperlink",true) end
    if self.has_role then publisher.setprop(nodelist,"has_role",true) end
    if self.has_special_nodes then publisher.setprop(nodelist,"has_special_nodes",true) end
    -- Transfer PDF/UA structure properties to the vlist
    if publisher.options.format == "PDF/UA" and self.role then
        publisher.setprop(nodelist,"role", self.role)
        publisher.setprop(nodelist,"parentid", self.parent or "doc")
        publisher.setprop(nodelist,"rolecounter", self.rolecounter)
        publisher.setprop(nodelist,"id", self.id)
        publisher.setprop(nodelist,"structpos", self.structpos)
        publisher.setprop(nodelist,"actualtext", self.actualtext)
        node.set_attribute(nodelist,publisher.att_role,self.role)
    end

    if self.initial then
        local ht_nodelist = get_lineheight(nodelist)
        local initial_hlist = self.initial

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
    -- Mark vbox if it should be kept with the next block (for break-after: avoid)
    if self.break_after == "avoid" then
        publisher.setprop(nodelist, "keep_with_next", true)
    end
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
