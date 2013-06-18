--- Building and formatting a paragraph
--
--  paragraph.lua
--  speedata publisher
--
--  Copyright 2012 Patrick Gundlach.
--  See file COPYING in the root directory for license info.

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
        if languagecodeuagecode then
            i.lang = languagecodeuagecode
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
    local colstart = node.new(8,39)
    colstart.data  = publisher.colors[colorname].pdfstring
    colstart.cmd   = 1
    colstart.stack = 1
    colstart.next = self.nodelist
    self.nodelist.prev = colstart
    self.nodelist = colstart
    local colstop  = node.new(8,39)
    colstop.data  = ""
    colstop.cmd   = 2
    colstop.stack = 1
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
    elseif type(whatever)=="function" then
        self:add_to_nodelist(publisher.mknodes(whatever(),parameter.fontfamily,parameter))
    elseif type(whatever)=="userdata" then -- node.is_node in einer späteren Version
        self:add_to_nodelist(whatever)
    elseif type(whatever)=="table" and not whatever.nodelist then
        self:add_to_nodelist(publisher.mknodes("",parameter.fontfamily,parameter))
    else
        if type(whatever)=="table" then printtable("Paragraph:append",whatever) end
        assert(false,string.format("Interner Fehler bei Paragraph:append, type(arg)=%s",type(whatever)))
    end
end

--- Turn a node list into a shaped block of text.
-- FIXME: document why splitting is needed (ul/li in data)
function Paragraph:format(width_sp, default_textformat_name)
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

        local parameter = {}

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
        publisher.fonts.post_linebreak(nodelist)
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

return Paragraph
