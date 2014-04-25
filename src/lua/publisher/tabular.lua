--
--  publisher/src/lua/tabular.lua
--  speedata publisher
--
--  Copyright 2010-2013 Patrick Gundlach.
--  See file COPYING in the root directory for license details.


file_start("tabular.lua")

module(...,package.seeall)

local dynamic_data = {}

function new( self )
    assert(self)
    local t = {
        rowheights     = {},
        colwidths      = {},
        align          = {},
        valign         = {},
        skip           = {},
        tablefoot_last_contents,
        tablefoot_contents,
        tablewidth_target,
        columncolors  = {},
        -- The distance between column i and i+1, currently not used
        column_distances = {},
    }

    setmetatable(t, self)
    self.__index = self
    return t
end

function attach_objects_row( tab )
    local td_elementname
    local td_contents
    for _,td in ipairs(tab) do
        td_elementname = publisher.elementname(td,true)
        td_contents    = publisher.element_contents(td)
        if td_elementname == "Td" then
            local objects = {}
            for i,j in ipairs(td_contents) do
                local eltname     = publisher.elementname(j,true)
                local eltcontents = publisher.element_contents(j)
                if eltname == "Paragraph" then
                    objects[#objects + 1] = eltcontents
                elseif eltname == "Image" then
                    -- FIXME: Image should be an object
                    objects[#objects + 1] = eltcontents[1]
                elseif eltname == "Table" then
                    objects[#objects + 1] = eltcontents[1]
                elseif eltname == "Barcode" then
                    objects[#objects + 1] = eltcontents
                elseif eltname == "Box" then
                    objects[#objects + 1] = eltcontents
                else
                    warning("Object not recognized: %s",eltname or "???")
                end
            end
            td_contents.objects = objects
        elseif td_elementname == "Tr" then -- probably from tablefoot/head
            attach_objects_row(td_contents)
        elseif td_elementname == "Column" then
            -- ignore, they don't have objects
        else
            -- w("unknown element name %s",td_elementname)
        end
    end
end

function attach_objects( tab )
    for _,tr in ipairs(tab) do
        attach_objects_row(publisher.element_contents(tr))
    end
end

--- Width calculation
--- =================

--- First we check for adjacent columns for collapsing border:
--- ![maximum width](img/bordercollapse.svg)
---
--- The resulting width for each border (left and right) is
---
--- \\(\frac{max(border-left,border-right)}{2}\\)
---
--- even if one
--- side didn't have a border. In that case we need to adjust the border colors. Beware: the result is slightly undefined
--- if both sides have different colors.
-- Calculate the width for each column in the row.
function calculate_columnwidths_for_row(self, tr_contents,current_row,colspans,colmin,colmax )
    local current_column = 0
    local max_wd, min_wd -- maximum and minimum width of a table cell (Td)
    -- first we go through all rows/cells and look, how wide the columns
    -- are supposed to be. If there are colspans, they have to be treated specially
    if self.bordercollapse_horizontal then
        for i=1,#tr_contents do
            if i ~= #tr_contents then
                local thiscell,nextcell,nextcell_borderleft,thiscell_borderright,new_borderwidth,new_borderwidth

                thiscell = publisher.element_contents(tr_contents[i])
                nextcell = publisher.element_contents(tr_contents[i + 1])

                thiscell_borderright = tex.sp(thiscell["border-right"] or 0)
                nextcell_borderleft  = tex.sp(nextcell["border-left"]  or 0)

                new_borderwidth = math.abs( math.max(thiscell_borderright,nextcell_borderleft) / 2 )

                nextcell["border-left"]  = new_borderwidth
                thiscell["border-right"] = new_borderwidth

                if thiscell_borderright == 0 then
                    thiscell["border-right-color"] = nextcell["border-left-color"]
                end
                if nextcell_borderleft == 0 then
                    nextcell["border-left-color"] = thiscell["border-right-color"]
                end
            end
        end
    end

    --- We calculate the widths in two passes:
    ---
    ---  1. Calculate the width of each table cell in a row
    ---  1. Calculate the row height
    ---
    --- The minimum width (min\_wd) is calculated as follows. Calculate the length of the longest item in the row:
    ---
    --- ![minimum width](img/calculate_longtext2.svg)
    ---
    --- The maximum width (max\_wd) is calculated by typesetting the text and taking total size of the hbox into account:
    ---
    --- ![maximum width](img/calculate_longtext.svg)
    ---
    for _,td in ipairs(tr_contents) do
        local td_contents = publisher.element_contents(td)
        -- all columms (table cells)
        -- fill skip, colspan and colmax-tables for this cell
        current_column = current_column + 1
        min_wd,max_wd = nil,nil
        local rowspan = tonumber(td_contents.rowspan) or 1
        local colspan = tonumber(td_contents.colspan) or 1

        -- When I am on a skip column (because of a row span), we jump over to the next column
        while self.skip[current_row] and self.skip[current_row][current_column] do current_column = current_column + 1 end
        -- rowspan?
        for z = current_row + 1, current_row + rowspan - 1 do
            for y = current_column, current_column + colspan - 1 do
                self.skip[z] = self.skip[z] or {}  self.skip[z][y] = true
            end
        end

        local td_borderleft  = tex.sp(td_contents["border-left"]  or 0)
        local td_borderright = tex.sp(td_contents["border-right"] or 0)
        local padding_left   = td_contents.padding_left  or self.padding_left
        local padding_right  = td_contents.padding_right or self.padding_right

        for _,object in ipairs(td_contents.objects) do
            if type(object)=="table" then
                trace("table: check for nodelist (%s)",tostring(object.nodelist ~= nil))

                if object.nodelist then
                    publisher.set_fontfamily_if_necessary(object.nodelist,self.fontfamily)
                    publisher.fonts.pre_linebreak(object.nodelist)
                end

                if object.min_width then
                    min_wd = math.max(object:min_width() + padding_left  + padding_right + td_borderleft + td_borderright, min_wd or 0)
                end
                if object.max_width then
                    max_wd = math.max(object:max_width() + padding_left  + padding_right + td_borderleft + td_borderright, max_wd or 0)
                end
                trace("table: min_wd, max_wd set (%gpt,%gpt)",min_wd / 2^16, max_wd / 2^16)
            end
            if not ( min_wd and max_wd) then
                trace("min_wd and max_wd not set yet. Type(object)==%s",type(object))
                if object.width then
                    min_wd = object.width + padding_left  + padding_right + td_borderleft + td_borderright
                    max_wd = object.width + padding_left  + padding_right + td_borderleft + td_borderright
                    trace("table: width (image) = %gpt",min_wd / 2^16)
                else
                    warning("Could not determine min_wd and max_wd")
                    assert(false)
                end
            end
        end
        trace("table: Colspan=%d",colspan)
        -- colspan?
        min_wd = min_wd or 0
        max_wd = max_wd or 0
        if colspan > 1 then
            colspans[#colspans + 1] = { start = current_column, stop = current_column + colspan - 1, max_wd = max_wd, min_wd = min_wd }
            current_column = current_column + colspan - 1
        else
            colmax[current_column] = math.max(colmax[current_column] or 0,max_wd)
            colmin[current_column] = math.max(colmin[current_column] or 0,min_wd)
        end
    end  -- ∀ columns
end


--- Calculate the widths of the columns for the table.
--- -------------------------------------------------
function calculate_columnwidth( self )
    trace("table: calculate columnwidth")
    local colspans = {}
    local colmax,colmin = {},{}

    local current_row = 0
    self.tablewidth_target = self.breite
    local columnwidths_given = false

    for _,tr in ipairs(self.tab) do
        local tr_contents      = publisher.element_contents(tr)
        local tr_elementname = publisher.elementname(tr,true)

        --- When the user gives us column widths, we use them for calculation. There are two ways to
        --- determine the column widths: with \\(n\\)* (where \\(n\\) is an integer number) or with absolute
        --- lengths such as `4` (in grid cells) or `2.5cm`. For example:
        ---
        ---     <Columns>
        ---       <Column width="3cm"/>
        ---       <Column width="1*"/>
        ---       <Column width="3*"/>
        ---     </Columns>
        --- When we typeset a table with a requested with of 11cm, the first column would get 3cm,
        --- the second column 1/4 of the rest (2cm) and the third 3/4 of the rest (6cm).
        --- ![Table calculation](img/table313.svg)
        if tr_elementname == "Columns" then
            local wd
            local i = 0
            local count_stars = 0
            local sum_real_widths = 0
            local count_columns = 0
            local pattern = "([0-9]+)%*"
            for _,spalte in ipairs(tr_contents) do
                if publisher.elementname(spalte,true)=="Column" then
                    local column_contents = publisher.element_contents(spalte)
                    i = i + 1
                    self.align[i] =  column_contents.align
                    self.valign[i] = column_contents.valign
                    if column_contents.width then
                        -- if I have something written in <column> I don't need to calculate column width:
                        columnwidths_given = true
                        local width_stars = string.match(column_contents.width,pattern)
                        if width_stars then
                            count_stars = count_stars + width_stars
                        else
                            if tonumber(column_contents.width) then
                                self.colwidths[i] = publisher.current_grid.gridwidth * column_contents.width
                            else
                                self.colwidths[i] = tex.sp(column_contents.width)
                            end
                            sum_real_widths = sum_real_widths + self.colwidths[i]
                        end
                    end
                    if column_contents.backgroundcolor then
                        self.columncolors[i] = column_contents.backgroundcolor
                    end
                end
                count_columns = i
            end

            if columnwidths_given and count_stars == 0 then return end

            if count_stars > 0 then
                trace("table: distribute space in *-columns (sum = %d)",count_stars)

                -- now we know the number of *-columns and the sum of the fix colums, so that
                -- we can distribute the remaining space
                local to_distribute =  self.tablewidth_target - sum_real_widths - table.sum(self.column_distances,1,count_columns - 1)

                i = 0
                for _,column in ipairs(tr_contents) do
                    if publisher.elementname(column,true)=="Column" then
                        local column_contents = publisher.element_contents(column)
                        i = i + 1
                        local width_stars = string.match(column_contents.width,pattern)
                        if width_stars then
                            self.colwidths[i] = math.round( to_distribute *  width_stars / count_stars ,0)
                        end
                    end
                end
            end -- sum_* > 0
        end
    end

    if columnwidths_given then return end

    --- Phase I
    --- -------
    --- Calculate max\_wd, min\_wd. We do this in a separate function for each row.
    for _,tr in ipairs(self.tab) do
        local tr_contents      = publisher.element_contents(tr)
        local tr_elementname = publisher.elementname(tr,true)

        if tr_elementname == "Tr" then
            current_row = current_row + 1
            self:calculate_columnwidths_for_row(tr_contents,current_row,colspans,colmin,colmax)
        elseif tr_elementname == "Tablerule" then
            -- ignore
        elseif tr_elementname == "Tablehead" then
            for _,row in ipairs(tr_contents) do
                local row_contents    = publisher.element_contents(row)
                local row_elementname = publisher.elementname(row,true)
                if row_elementname == "Tr" then
                    current_row = current_row + 1
                    self:calculate_columnwidths_for_row(row_contents,current_row,colspans,colmin,colmax)
                end
            end
        elseif tr_elementname == "Tablefoot" then
            for _,row in ipairs(tr_contents) do
                local row_contents    = publisher.element_contents(row)
                local row_elementname = publisher.elementname(row,true)
                if row_elementname == "Tr" then
                    current_row = current_row + 1
                    self:calculate_columnwidths_for_row(row_contents,current_row,colspans,colmin,colmax)
                end
            end
        else
            warning("Unknown Element: %q",tr_elementname or "?")
        end -- if it's really a row
    end -- ∀ rows / rules


    --- Now we are finished with all cells in all rows. If there are colospans, we might have
    --- to increase some column widths
    ---
    --- Example (fake):
    ---     <Table width="30">
    ---       <Tr><Td>A</Td><Td>A</Td></Tr>
    ---       <Tr><Td colspan="2">A very very very long text</Td></Tr>
    ---     </Table>
    ---     ----------------------------
    ---     |A           |A            |
    ---     |A very very very long text|
    ---     ----------------------------
    ---
    --- In this case sum(min) is approx. the width of the word "very" and sum(max) is the width of the text.
    --- colmax[i] is the width of "A", colmin[i] also
    ---
    --- Phase II: include colspan
    --- -------------------------
    trace("table: adjust colmin/colmax")
    for i,colspan in pairs(colspans) do
        trace("table: colspan #%d",i)
        local sum_min,sum_max = 0,0
        local r -- stretch factor = wd(colspan)/wd(sum_start_end)

        --- First we calculate how wide the columns are that are covered by colspan, but without
        --- colspan itself

        if #colmax < colspan.stop then
            err("Not enough columns found for colspan")
            return -1
        end
        sum_max = table.sum(colmax,colspan.start,colspan.stop)
        sum_min = table.sum(colmin,colspan.start,colspan.stop)

        --- If the colspan requires more room than the rest of the table, we have to increase
        --- the width of all columns in the table accordingly. We stretch the columns by
        --- a factor r. r is calculated by the contents.
        ---
        --- We do that once for the maximum width and once for the minimum width
        local width_of_colsep = table.sum(self.column_distances,colspan.start,colspan.start)

        if colspan.max_wd > sum_max + width_of_colsep then
            r = ( colspan.max_wd - width_of_colsep ) / sum_max
            for j=colspan.start,colspan.stop do
                colmax[j] = colmax[j] * r
            end
        end -- colspan.max_wd > sum_max?

        if colspan.min_wd > sum_min + width_of_colsep then
            r = ( colspan.min_wd - width_of_colsep ) / sum_min
            for j=colspan.start,colspan.stop do
                colmin[j] = colmin[j] * r
            end
        end -- colspan.min_wd > sum_min?
    end -- ∀ colspans

    -- Now colmin and colmax are calculated for all columns. colspans are included.


    --- Phase III: Stretch or shrink table
    --- ----------------------------------

    -- Here comes the main width calculation
    -- ---------------------------------------------
    -- FIXME: we should use column_distances[i] instead of self.colsep
    local colsep = (#colmax - 1) * self.colsep
    local tablewidth_is = table.sum(colmax) + colsep

    --- 1. calculate natural (max) width / total width for each column.
    ---
    --- If stretch="no" is set, we can encounter the case that the table is too wide. Then it
    --- must be shrunk.

    -- highly unlikely that the table matches the size exactly
    if tablewidth_is == self.tablewidth_target then
        for i=1,#colmax do
            self.colwidths[i] = colmax[i]
        end
        return
    end

    -- if the table is too wide, we need to shrink some columns
    if tablewidth_is > self.tablewidth_target then
        local col_r = {} -- temporary column width after shrinking
        local shrink_factor = {}
        local sum_shrinkfactor = 0
        local excess = 0
        local r = ( self.tablewidth_target - colsep )  / ( tablewidth_is - colsep)
        for i=1,#colmax do
            -- actually:
            -- r[i] = colmax[i] / tablewidth_is
            -- to get to the row width we need to multiply with tablewidth_target
            col_r[i] = colmax[i] * r

            -- if the calculated width is less than the minimal width, the cell needs to be wider
            -- and the total width must be reduced by the excess.
            if col_r[i] < colmin[i] then
                excess = excess + colmin[i] - col_r[i]
                self.colwidths[i] = colmin[i]
            end
            if col_r[i] > colmin[i] then
                -- this column can be shrunk if necessary. The factor is col_r[i] / colmin[i]
                shrink_factor[i] = col_r[i] / colmin[i]
                sum_shrinkfactor = sum_shrinkfactor + shrink_factor[i]
            end
        end
        -- the excess must be subtracted partly from the columns that are to wide
        for i=1,#colmax do
            if shrink_factor[i] then
                self.colwidths[i] = col_r[i] -  shrink_factor[i] / sum_shrinkfactor * excess
            end
        end
        return
    end

    -- if stretch="no", we don't need to stretch/shrink anything
    if self.autostretch ~= "max" then
        self.tablewidth_target = tablewidth_is
        for i=1,#colmax do
            self.colwidths[i] = colmax[i]
        end
        return
    end


    -- if the table is too narrow, we must make it wider
    if tablewidth_is < self.tablewidth_target then
        -- table must get wider
        local r = ( self.tablewidth_target - colsep ) / ( tablewidth_is - colsep )
        for i=1,#colmax do
            self.colwidths[i] = colmax[i] * r
        end
    end
end

--- last\_shiftup is for vertical border-collapse.
function calculate_rowheight( self,tr_contents, current_row,last_shiftup )
    last_shiftup = last_shiftup or 0
    local rowheight
    local rowspan,colspan
    local wd,parameter
    local rowspans = {}
    local shiftup = 0

    local fam = publisher.fonts.lookup_fontfamily_number_instance[self.fontfamily]
    local min_lineheight = fam.baselineskip

    if tr_contents.minheight then
        rowheight = math.max(publisher.current_grid.gridheight * tr_contents.minheight, min_lineheight)
    else
        rowheight = min_lineheight
    end

    current_column = 0

    for _,td in ipairs(tr_contents) do
        local default_textformat_name
        local td_contents = publisher.element_contents(td)
        current_column = current_column + 1


        local td_borderleft   = tex.sp(td_contents["border-left"]   or 0)
        local td_borderright  = tex.sp(td_contents["border-right"]  or 0)
        local td_bordertop    = tex.sp(td_contents["border-top"]    or 0)
        local td_borderbottom = tex.sp(td_contents["border-bottom"] or 0)

        local padding_left   = td_contents.padding_left   or self.padding_left
        local padding_right  = td_contents.padding_right  or self.padding_right
        local padding_top    = td_contents.padding_top    or self.padding_top
        local padding_bottom = td_contents.padding_bottom or self.padding_bottom

        rowspan = tonumber(td_contents.rowspan) or 1
        colspan = tonumber(td_contents.colspan) or 1

        wd = 0
        for s = current_column,current_column + colspan - 1 do
            if self.colwidths[s] == nil then
                err("Something went wrong with the number of columns in the table")
            else
                wd = wd + self.colwidths[s]
            end
        end
        current_column = current_column + colspan - 1

        -- FIXME: use column_distances[i] instead of self.colsep
        wd = wd + ( colspan - 1 ) * self.colsep
        -- FIXME: take border-left and border-right into account
        --        in the height calculation also border-top and border-bottom
        local cell

        for _,object in ipairs(td_contents.objects) do
            if type(object)=="table" then
                -- Its a regular paragraph!?!?

                if not (object.nodelist) then
                    err("No nodelist found!")
                end

                local align = td_contents.align or tr_contents.align or self.align[current_column]
                if align=="center" then
                    default_textformat_name = "__centered"
                elseif align=="left" then
                    default_textformat_name = "__leftaligned"
                elseif align=="right" then
                    default_textformat_name = "__rightaligned"
                elseif align=="justify" then
                    default_textformat_name = "__justified"
                end
                if not default_textformat_name then
                    if object.textformat then
                        default_textformat_name = object.textformat
                    elseif self.textformat then
                        default_textformat_name = self.textformat
                    else
                        default_textformat_name = "__leftaligned"
                    end
                end
                publisher.set_fontfamily_if_necessary(object.nodelist,self.fontfamily)

                local v = object:format(wd - padding_left - padding_right - td_borderleft - td_borderright,default_textformat_name)
                if cell then
                    node.tail(cell).next = v
                else
                    cell = v
                end
            elseif (type(object)=="userdata" and node.has_field(object,"width")) then
                -- an image or a box
                -- FIXME:
                -- The following code leads to an error if two images
                -- are included in a table cell.
                -- Also check QA tables/columnspread for an example why
                -- this is necessary
                if cell then
                    node.tail(cell).next = object
                else
                    cell = object
                end
            end
        end

        -- if there are no objects in a row, we create a dummy object
        -- so the row can be created and vpack does not fall over a nil
        if not cell then
            cell = node.new("hlist")
        end
        v=node.vpack(cell)

        tmp = v.height + v.depth +  padding_top + padding_bottom + td_borderbottom + td_bordertop
        if rowspan > 1 then
            rowspans[#rowspans + 1] =  { start = current_row, stop = current_row + rowspan - 1, ht = tmp }
            td_contents.rowspan_internal = rowspans[#rowspans]
        else
            rowheight = math.max(rowheight,tmp)
        end
        if self.bordercollapse_vertical then
            shiftup = math.max(shiftup,td_borderbottom)
        end
    end
    tr_contents.shiftup = last_shiftup
    return rowheight,rowspans,shiftup
end


function calculate_rowheights(self)
    trace("table: calculate row height")
    local current_row = 0
    local rowspans = {}
    local _rowspans

    local last_shiftup = 0

    for _,tr in ipairs(self.tab) do
        local tr_contents = publisher.element_contents(tr)
        local eltname = publisher.elementname(tr,true)

        if eltname == "Tablerule" or eltname == "Columns" then
            -- ignorieren

        elseif eltname == "Tablehead" then
            local last_shiftup_head = 0
            for _,row in ipairs(tr_contents) do
                local cellcontents  = publisher.element_contents(row)
                local cell_elementname = publisher.elementname(row,true)
                if cell_elementname == "Tr" then
                    current_row = current_row + 1
                    rowheight, _rowspans,last_shiftup_head = self:calculate_rowheight(cellcontents,current_row,last_shiftup_head)
                    self.rowheights[current_row] = rowheight
                    rowspans = table.__concat(rowspans,_rowspans)
                end
            end
        elseif eltname == "Tablefoot" then
            local last_shiftup_foot = 0
            for _,row in ipairs(tr_contents) do
                local cellcontents  = publisher.element_contents(row)
                local cell_elementname = publisher.elementname(row,true)
                if cell_elementname == "Tr" then
                    current_row = current_row + 1
                    rowheight, _rowspans,last_shiftup_foot = self:calculate_rowheight(cellcontents,current_row,last_shiftup_foot)
                    self.rowheights[current_row] = rowheight
                    rowspans = table.__concat(rowspans,_rowspans)
                end
            end

        elseif eltname == "Tr" then
            current_row = current_row + 1
            rowheight, _rowspans,last_shiftup = self:calculate_rowheight(tr_contents,current_row,last_shiftup)
            self.rowheights[current_row] = rowheight
            rowspans = table.__concat(rowspans,_rowspans)
        else
            warning("Unknown contents in »Table« %s",eltname or "?")
        end -- if it's not a <Tablerule>
    end -- for all rows

    -- Adjust row heights. We have to do calculations on all row heights, before the rows can get their
    -- final heights
    for i,rowspan in pairs(rowspans) do
        trace("table: adjust row heights")
        local sum_ht = 0
        trace("table: rowspan.start = %d, rowspan.stop = %d. self.rowsep = %gpt",rowspan.start,rowspan.stop,self.rowsep)
        for j=rowspan.start,rowspan.stop do
            trace("table: add %gpt (row %d)",self.rowheights[j] / 2^16,j)
            sum_ht = sum_ht + self.rowheights[j]
        end
        sum_ht = sum_ht + self.rowsep * ( rowspan.stop - rowspan.start )
        trace("table: Rowspan (%d) > row heights %gpt > %gpt?",rowspan.stop - rowspan.start + 1 ,rowspan.ht / 2^16 ,sum_ht / 2^16)
        if rowspan.ht > sum_ht then
            local excess_per_row = (rowspan.ht - sum_ht) / (rowspan.stop - rowspan.start + 1)
            trace("table: excess per row = %gpt",excess_per_row / 2^16)
            for j=rowspan.start,rowspan.stop do
                self.rowheights[j] = self.rowheights[j] + excess_per_row
            end
        end
    end

    -- We have now calculated all row heights. So we can adjust the rowspans now.
    for i,rowspan in pairs(rowspans) do
        rowspan.sum_ht = table.sum(self.rowheights,rowspan.start, rowspan.stop) + self.rowsep * ( rowspan.stop - rowspan.start )
    end
end

--- ![Table cell](img/cell.svg)

--- Width calculation is now finished, we can typeset the table
--- Typesetting the table
--- ---------------------
--- First, we create a complete table with all rows. Splitting into pages is done later on
-- Return one row (an hlist)
function typeset_row(self, tr_contents, current_row )
    trace("table: typeset row")
    local current_column
    local current_column_width, ht
    local row = {}
    local rowspan, colspan
    local v,vlist,hlist
    local fill = { width = 0, stretch = 2^16, stretch_order = 3}

    current_column = 0
    for _,td in ipairs(tr_contents) do
        local default_textformat_name

        current_column = current_column + 1

        td_contents = publisher.element_contents(td)
        rowspan = tonumber(td_contents.rowspan) or 1
        colspan = tonumber(td_contents.colspan) or 1

        -- FIXME: am I sure that I am in the corerct column?  (colspan...)?
        local td_borderleft   = tex.sp(td_contents["border-left"]   or 0)
        local td_borderright  = tex.sp(td_contents["border-right"]  or 0)
        local td_bordertop    = tex.sp(td_contents["border-top"]    or 0)
        local td_borderbottom = tex.sp(td_contents["border-bottom"] or 0)

        local padding_left    = td_contents.padding_left   or self.padding_left
        local padding_right   = td_contents.padding_right  or self.padding_right
        local padding_top     = td_contents.padding_top    or self.padding_top
        local padding_bottom  = td_contents.padding_bottom or self.padding_bottom

        -- when we are on a skip-cell (because of a rowspan), we need to create an empty hbox
        while self.skip[current_row] and self.skip[current_row][current_column] do
            v = publisher.create_empty_hbox_with_width(self.colwidths[current_column])
            v = publisher.add_glue(v,"head",fill) -- otherwise we'd get an underfull box
            row[current_column] = node.vpack(v,self.rowheights[current_row],"exactly")
            current_column = current_column + 1
        end

        -- rowspan? - this is not DRY: we did the same already in calculate_columnwidth
        for z = current_row + 1, current_row + rowspan - 1 do
            for y = current_column, current_column + colspan - 1 do
                self.skip[z] = self.skip[z] or {}  self.skip[z][y] = true
            end
        end

        current_column_width = 0
        for s = current_column,current_column + colspan - 1 do
            if self.colwidths[s] == nil then
                err("Something went wrong with the number of columns in the table")
            else
                current_column_width = current_column_width + self.colwidths[s]
            end
        end

        -- FIXME: use column_distances[i] instead of self.colsep
        current_column_width = current_column_width + ( colspan - 1 ) * self.colsep
        current_column = current_column + colspan - 1

        if rowspan > 1 then
            ht = td_contents.rowspan_internal.sum_ht
        else
            ht = self.rowheights[current_row]
        end

        -- FIXME: do I really have to do that over and over again! This is crap. I did the same
        -- calculate rowheights (put text into a paragraph)
        local g = node.new("glue")
        g.spec = node.new("glue_spec")
        g.spec.width = padding_top

        local valign = td_contents.valign or tr_contents.valign or self.valign[current_column]
        if valign ~= "top" then
            g.spec.stretch = 2^16
            g.spec.stretch_order = 2
        end

        local cell_start = g

        local current = node.tail(cell_start)

        --- Let's combine every object in the cell by setting the next pointer at the end
        --- to the following object and vpack it for the cell
        for _,object in ipairs(td_contents.objects) do
            if type(object) == "table" then
                if not (object and object.nodelist) then
                    warning("No nodelist found!")
                end
                -- Unsure why I copied the list. It seems
                -- to work when I just assign it
                -- v = node.copy_list(object.nodelist)
                v = object.nodelist
            elseif type(object) == "userdata" then
                -- Same here. Why did I copy the list?
                -- v = node.copy_list(object)
                v = object
            end

            if type(object) == "table" then
                -- Paragraph with a node list
                local align = td_contents.align or tr_contents.align or self.align[current_column]
                if align=="center" then
                    default_textformat_name = "__centered"
                elseif align=="left" then
                    default_textformat_name = "__leftaligned"
                elseif align=="right" then
                    default_textformat_name = "__rightaligned"
                elseif align=="justify" then
                    default_textformat_name = "__justified"
                end
                if not default_textformat_name then
                    if object.textformat then
                        default_textformat_name = object.textformat
                    elseif self.textformat then
                        default_textformat_name = self.textformat
                    else
                        default_textformat_name = "__leftaligned"
                    end
                end
                v = object:format(current_column_width - padding_left - padding_right - td_borderleft - td_borderright, default_textformat_name)
                if publisher.options.trace then
                    v = publisher.boxit(v)
                end
            elseif type(object) == "userdata" then
                v = node.hpack(v)
            else
                assert(false)
            end
            current.next = v
            current = v
        end

        g = node.new("glue")
        g.spec = node.new("glue_spec")
        g.spec.width = padding_bottom

        local valign = td_contents.valign or tr_contents.valign or self.valign[current_column]
        if valign ~= "bottom" then
            g.spec.stretch = 2^16
            g.spec.stretch_order = 2
        end


        current.next = g

        vlist = node.vpack(cell_start,ht - td_bordertop - td_borderbottom,"exactly")
        --- The table cell now looks like this
        ---
        --- ![Table cell vertical](img/tablecell1.svg)
        ---
        --- Now we need to add the left and the right glue

        g = node.new("glue")
        g.spec = node.new("glue_spec")
        g.spec.width = padding_left


        local align = td_contents.align or tr_contents.align or self.align[current_column]
        if align ~= "left" then
            g.spec.stretch = 2^16
            g.spec.stretch_order = 2
        end

        cell_start = g
        local ht_border = 0
        local rowspan = td_contents.rowspan or 1
        for i=1,rowspan do
            ht_border = ht_border + self.rowheights[current_row + i - 1] + self.rowsep
        end
        ht_border = ht_border - td_bordertop - td_borderbottom - self.rowsep

        if td_borderleft ~= 0 then
            local start = publisher.colorbar(td_borderleft,ht_border,0,td_contents["border-left-color"])
            local stop = node.tail(start)
            stop.next = g
            cell_start = start
        end

        current = node.tail(cell_start)
        current.next = vlist
        current = vlist

        g = node.new("glue")
        g.spec = node.new("glue_spec")
        g.spec.width = padding_right

        local align = td_contents.align or tr_contents.align or self.align[current_column]
        if align ~= "right" then
            g.spec.stretch = 2^16
            g.spec.stretch_order = 2
        end

        current.next = g
        current = g
        if td_borderright ~= 0 then
            local rule = publisher.colorbar(td_borderright,ht_border,0,td_contents["border-right-color"])
            g.next = rule
        end

        hlist = node.hpack(cell_start,current_column_width,"exactly")
        --- The cell is now almost complete. We can set the background color and add the top and bottom rule.
        ---
        --- ![Table cell vertical](img/tablecell2.svg)
        if tr_contents.backgroundcolor or td_contents.backgroundcolor or self.columncolors[current_column] then
            -- prio: Td.backgroundcolor, then Tr.backgroundcolor, then Column.backgroundcolor
            local color = self.columncolors[current_column]
            color = tr_contents.backgroundcolor or color
            color = td_contents.backgroundcolor or color
            hlist = publisher.background(hlist,color)
        end

        local head = hlist
        if td_bordertop > 0 then
            local rule = publisher.colorbar(current_column_width,td_bordertop,0,td_contents["border-top-color"])
            -- rule is: whatsit, rule, whatsit
            node.tail(rule).next = hlist
            head = rule
        end

        if td_borderbottom > 0 then
            local rule = publisher.colorbar(current_column_width,td_borderbottom,0,td_contents["border-bottom-color"])
            hlist.next = rule
        end

        -- What is this for?
        local gl = node.new("glue")
        gl.spec = node.new("glue_spec")
        gl.spec.width = 0
        gl.spec.shrink = 2^16
        gl.spec.shrink_order = 2
        node.slide(head).next = gl

        --- This is our table cell now:
        ---
        --- ![Table cell vertical](img/tablecell3.svg)
        hlist = node.vpack(head,self.rowheights[current_row],"exactly")


        if publisher.options.trace then
            publisher.boxit(hlist)
        end

        row[#row + 1] = hlist

    end -- stop td

    if current_column == 0 then
        trace("table: no td-cells found in this column")
        v = publisher.create_empty_hbox_with_width(self.tablewidth_target)
        trace("table: create empty hbox")
        v = publisher.add_glue(v,"head",fill) -- sonst gäb's ne underfull vbox
        row[1] = node.vpack(v,self.rowheights[current_row],"exactly")
    end

    local cell_start,current
    cell_start = row[1]
    current = cell_start

    --- We now add colsep and connect the cells so we have a list of vboxes and
    --- pack them in a hbox.
    --- ![a row](img/tablerow.svg)
    -- FIXME: use column_distances[i] instead of self.colsep
    if row[1] then
        for z=2,#row do
            _,current = publisher.add_glue(current,"tail",{ width = self.colsep })
            current.next = row[z]
            current = row[z]
        end
        row = node.hpack(cell_start)
    else
        err("(Internal error) Table is not complete.")
    end
    node.set_attribute(row,publisher.att_tr_shift_up,tr_contents.shiftup)
    return row
end

-- Gets called for each <Tablehead> element
local function make_tablehead(self,tr_contents,tablehead_first,tablehead,current_row,second_run)
    trace("make_tablehead, page = %s",tr_contents.page or "not defined")

    local current_tablehead_type

    if tr_contents.page == "first" then
        current_tablehead_type = tablehead_first
        if second_run ~= true then
            self.tablehead_first_contents = {tr_contents,current_row}
        end
    else
        current_tablehead_type = tablehead
        if second_run ~= true then
            self.tablehead_contents = {tr_contents,current_row}
        end
    end

    for _,row in ipairs(tr_contents) do
        row_contents = publisher.element_contents(row)
        row_elementname = publisher.elementname(row,true)
        if row_elementname == "Tr" then
            current_row = current_row + 1
            current_tablehead_type[#current_tablehead_type + 1] = self:typeset_row(row_contents,current_row)
        elseif row_elementname == "Tablerule" then
            tmp = publisher.colorbar(self.tablewidth_target,tex.sp(row_contents.rulewidth or "0.25pt"),0,row_contents.farbe)
            current_tablehead_type[#current_tablehead_type + 1] = node.hpack(tmp)
        end
    end
    if self.rowsep ~= 0 then
        publisher.add_glue(current_tablehead_type[#current_tablehead_type], "tail", {width=self.rowsep})
    end

    return current_row
end

local function make_tablefoot(self,tr_contents,tablefoot_last,tablefoot,current_row,second_run)
    local current_tablefoot_type
    if tr_contents.page == "last" then
        current_tablefoot_type = tablefoot_last
        if second_run ~= true then
            self.tablefoot_last_contents = {tr_contents,current_row}
        end
    else
        current_tablefoot_type = tablefoot
        if second_run ~= true then
            self.tablefoot_contents = {tr_contents,current_row}
        end
    end
    for _,row in ipairs(tr_contents) do
        row_contents = publisher.element_contents(row)
        row_elementname = publisher.elementname(row,true)
        if row_elementname == "Tr" then
            current_row = current_row + 1
            current_tablefoot_type[#current_tablefoot_type + 1] = self:typeset_row(row_contents,current_row)
        elseif row_elementname == "Tablerule" then
            tmp = publisher.colorbar(self.tablewidth_target,tex.sp(row_contents.rulewidth or "0.25pt"),0,row_contents.farbe)
            current_tablefoot_type[#current_tablefoot_type + 1] = node.hpack(tmp)
        end
    end
    return current_row
end
--------------------------------------------------------------------------
local function calculate_height_and_connect_tablehead(self,tablehead_first,tablehead)
    local ht_header, ht_first_header = 0, 0
    -- We connect all but the last row with the next row and remember the height in ht_header
    for z = 1,#tablehead_first - 1 do
        ht_first_header = ht_first_header + tablehead_first[z].height  -- Tr oder Tablerule
        _,tmp = publisher.add_glue(tablehead_first[z],"tail",{ width = self.rowsep })
        tmp.next = tablehead_first[z+1]
        tablehead_first[z+1].prev = tmp
    end

    for z = 1,#tablehead - 1 do
        ht_header = ht_header + tablehead[z].height  -- Tr or Tablerule
        _,tmp = publisher.add_glue(tablehead[z],"tail",{ width = self.rowsep })
        tmp.next = tablehead[z+1]
        tablehead[z+1].prev = tmp
    end

    -- perhaps there is a last row, that is connected but its height is not
    -- taken into account yet.
    if #tablehead > 0 then
        ht_header = ht_header + tablehead[#tablehead].height + self.rowsep  * ( #tablehead )
    end

    if #tablehead_first > 0 then
        ht_first_header = ht_first_header + tablehead_first[#tablehead_first].height + self.rowsep * (#tablehead_first)
    else
        ht_first_header = ht_header
    end

    return ht_first_header,ht_header
end

local function calculate_height_and_connect_tablefoot(self,tablefoot,tablefoot_last)
    local ht_footer, ht_footer_last = 0, 0
    for z = 1,#tablefoot - 1 do
        ht_footer = ht_footer + tablefoot[z].height  -- Tr or Tablerule
        -- if we have a rowsep then add glue. Todo: make a if/then/else conditional
        _,tmp = publisher.add_glue(tablefoot[z],"tail",{ width = self.rowsep })
        tmp.next = tablefoot[z+1]
        tablefoot[z+1].prev = tmp
    end

    for z = 1,#tablefoot_last - 1 do
        ht_footer_last = ht_footer_last + tablefoot_last[z].height  -- Tr or Tablerule
        -- if we have a rowsep then add glue. Todo: make a if/then/else conditional
        _,tmp = publisher.add_glue(tablefoot_last[z],"tail",{ width = self.rowsep })
        tmp.next = tablefoot_last[z+1]
        tablefoot_last[z+1].prev = tmp
    end

    if #tablefoot > 0 then
        ht_footer = ht_footer + tablefoot[#tablefoot].height + ( #tablefoot - 1 ) * self.rowsep
    end

    if #tablefoot_last > 0 then
        ht_footer_last = ht_footer_last + tablefoot_last[#tablefoot_last].height + ( #tablefoot_last - 1 ) * self.rowsep
    else
        ht_footer_last = ht_footer
    end
    return ht_footer, ht_footer_last
end

--------

function typeset_table(self)
    trace("table: typeset table")
    local current_row
    local tablehead_first = {}
    local tablehead = {}
    local tablefoot_last = {}
    local tablefoot = {}
    local rows = {}
    local break_above = true
    local filter = {}
    local startpage = publisher.current_pagenumber
    local tablepart_absolute = 1

    current_row = 0
    for _,tr in ipairs(self.tab) do
        trace("table: Tr")
        local tr_contents = publisher.element_contents(tr)
        local eltname   = publisher.elementname(tr,true)
        local tmp
        -- If this row is allowed to break above
        -- Will be set to false if break_below is "no"

        if eltname == "Columns" then
            -- ignorieren
        elseif eltname == "Tablerule" then
            local offset = 0
            if tr_contents.start and tr_contents.start ~= 1 then
                local sum = 0
                for i=1,tr_contents.start - 1 do
                    sum = sum + self.colwidths[i]
                end
                offset = sum
            end
            tmp = publisher.colorbar(self.tablewidth_target - offset,tex.sp(tr_contents.rulewidth or "0.25pt"),0,tr_contents.farbe)
            tmp = publisher.add_glue(tmp,"head",{width = offset})
            rows[#rows + 1] = node.hpack(tmp)

        elseif eltname == "Tablehead" then
            current_row = make_tablehead(self,tr_contents,tablehead_first,tablehead,current_row)
            if tr_contents.page == "first" then
                filter.tablehead_force_first = true
            elseif tr_contents.page == "odd" or tr_contents.page == "even" then
                filter.tablehead = tr_contents.page
            end

        elseif eltname == "Tablefoot" then
            current_row = make_tablefoot(self,tr_contents,tablefoot_last,tablefoot,current_row)

        elseif eltname == "Tr" then
            trace("table: found Tr")
            current_row = current_row + 1
            rows[#rows + 1] = self:typeset_row(tr_contents,current_row)
            -- We allow data to be attached to a table row.
            if tr_contents.data then
                dynamic_data[#dynamic_data + 1] = tr_contents.data
                node.set_attribute(rows[#rows],publisher.att_tr_dynamic_data,#dynamic_data)
            end
            node.set_attribute(rows[#rows],publisher.att_is_table_row,1)

            if break_above == false then
                node.set_attribute(rows[#rows],publisher.att_break_above,1)
                break_above = true
            end

            if tr_contents["top-distance"] ~= 0 then
                node.set_attribute(rows[#rows],publisher.att_space_amount,tr_contents["top-distance"])
            end
            if tr_contents["break-below"] == "no" then
                node.set_attribute(rows[#rows],publisher.att_break_below_forbidden,1)
                break_above = false
            end

        else
            warning("Unknown contents in »Table« %s",eltname or "?" )
        end -- if it's a table cell
    end

    if #rows == 0 then
        -- WTF? No contents in the table
        err("table without contents")
        return publisher.emergency_block()
    end


    local ht_first_header, ht_header = calculate_height_and_connect_tablehead(self,tablehead_first,tablehead)
    local ht_footer,  ht_footer_last = calculate_height_and_connect_tablefoot(self,tablefoot,tablefoot_last)

    if not tablehead[1] then
        tablehead[1] = node.new("hlist") -- empty tablehead
    end
    if not tablehead_first[1] then
        tablehead_first[1] = node.copy_list(tablehead[1])
    end
    if not tablefoot[1] then
        tablefoot[1] = node.new("hlist") -- empty tablefoot
    end
    if not tablefoot_last[1] then
        tablefoot_last[1] = node.copy_list(tablefoot[1])
    end

    local ht_current = self.optionen.current_height or self.optionen.ht_max
    local ht_max     = self.optionen.ht_max
    -- The maximum heights are saved here for each table. Currently all tables must have the same height (see the metatable)
    local pagegoals = {}
    local function showheader( tablepart )
        if tablepart_absolute == 1 and filter.tablehead_force_first then return true end
        if not filter.tablehead then return true end
        if math.fmod(tablepart_absolute,2) == math.fmod(startpage,2) then
            if filter.tablehead == "odd" then
                return true
            else
                return false
            end
        else
            if filter.tablehead == "odd" then
                return false
            else
                return true
            end
        end
    end
    setmetatable(pagegoals, { __index = function(tbl,idx)
                if idx == 1 then
                    if showheader(idx) then
                        return ht_current - ht_first_header - ht_footer
                    else
                        return ht_current - ht_footer
                    end
                end
                if showheader(idx) then
                    return ht_max - ht_header - ht_footer
                else
                    return ht_max - ht_footer
                end
    end})
    pagegoals[-1] = ht_max - ht_header - ht_footer_last

    -- When we split the current table we return an array:
    local final_split_tables = {}
    local current_table
    local tmp
    local pagegoal = 0

    local ht_row,space_above,too_high
    local accumulated_height = 0
    local extra_height = 0
    local break_above
    --- splits is a table which includes the number of the rows each page has in a multi-page table
    ---
    ---     splits = {
    ---       [1] = "0"
    ---       [2] = "26"
    ---       [3] = "44"
    ---     }

    local splits = {0}
    -- We need to take into acccount:
    -- * the head
    -- * the foot
    -- * the row height
    -- * row sep
    -- * distance above
    -- * break_above?

    local last_possible_split_is_after_line = 0

    local current_page = 1

    for i=1,#rows do
        local shiftup = node.has_attribute(rows[i],publisher.att_tr_shift_up) or 0
        if shiftup > 0 then
            rows[i].height = rows[i].height - shiftup
        end
        pagegoal = pagegoals[current_page]
        ht_row = rows[i].height + rows[i].depth
        break_above = node.has_attribute(rows[i],publisher.att_break_above) or -1
        space_above = node.has_attribute(rows[i],publisher.att_space_amount) or 0

        local break_above_allowed = break_above ~= 1

        if break_above_allowed then
            last_possible_split_is_after_line = i - 1
            accumulated_height = accumulated_height + extra_height
            extra_height = self.rowsep
        end
        extra_height = extra_height + ht_row
        local fits_in_table = accumulated_height + extra_height + space_above < pagegoal
        if not fits_in_table then
            if shiftup > 0 then
                rows[i].height = rows[i].height + shiftup
            end
            -- ==0 can happen when there's not enough room for table head + first line
            if last_possible_split_is_after_line ~= 0 then
                splits[#splits + 1] = last_possible_split_is_after_line
                tablepart_absolute = tablepart_absolute + 1
            else
                startpage = startpage + 1
            end
            accumulated_height = ht_row
            extra_height = self.rowsep
            current_page = current_page + 1
        else
            -- if it is not the first row in a table,
            -- add space_above
            if i ~= splits[#splits] + 1 then
                extra_height = extra_height + space_above
            end
        end
    end
    splits[#splits + 1] = #rows

    local first_row_in_new_table

    local last_tr_data
    tablepart_absolute = 0
    for s=2,#splits do
        tablepart_absolute = tablepart_absolute + 1
        publisher.xpath.set_variable("_last_tr_data",nil)
        first_row_in_new_table = splits[s-1] + 1

        thissplittable = {}
        final_split_tables[#final_split_tables + 1] = thissplittable

        -- only reformat head when we have a head
        if last_tr_data and self.tablehead_contents then
            -- we have some data attached to table rows, so we re-format the header
            local val = dynamic_data[last_tr_data]
            publisher.xpath.set_variable("_last_tr_data",val)
            local tmp1,tmp2 = reformat_head(self,s - 1)
            if s == 2 then
                -- first page
                thissplittable[#thissplittable + 1] = node.copy_list(tmp1)
            else
                -- page > 1
                thissplittable[#thissplittable + 1] = node.copy_list(tmp2)
            end
        else
            if showheader(s-1) then
                if s == 2 then
                    -- first page
                    thissplittable[#thissplittable + 1] = tablehead_first[1]
                else
                    -- page > 1
                    thissplittable[#thissplittable + 1] = node.copy_list(tablehead[1])
                end
            end
        end
        for i = first_row_in_new_table ,splits[s]  do
            if i > first_row_in_new_table then
                space_above = node.has_attribute(rows[i],publisher.att_space_amount) or 0
            else
                space_above = 0
            end
            thissplittable[#thissplittable + 1] = publisher.make_glue({space_above})
            thissplittable[#thissplittable + 1] = rows[i]
            thissplittable[#thissplittable + 1] = publisher.make_glue({width = self.rowsep})
        end

        last_tr_data = node.has_attribute(thissplittable[#thissplittable - 1],publisher.att_tr_dynamic_data)

        -- only refomat the foot when we have dynamic data _and_ have a foot to reformat.
        if last_tr_data and self.tablefoot_contents then
            -- we have some data attached to table rows, so we re-format the footer
            local val = dynamic_data[last_tr_data]
            publisher.xpath.set_variable("_last_tr_data",val)
            local tmp1,tmp2 = reformat_foot(self,s - 1,#splits - 1)
            if s < #splits then
                thissplittable[#thissplittable + 1] = node.copy_list(tmp2)
            else
                thissplittable[#thissplittable + 1] = node.copy_list(tmp2)
            end
        else
            -- no dynamic data, no re-formatting
            if s < #splits then
                thissplittable[#thissplittable + 1] = node.copy_list(tablefoot[1])
            else
                thissplittable[#thissplittable + 1] = node.copy_list(tablefoot_last[1])
            end
        end
    end

    -- now connect the entries in the split_tables
    local tail
    for i=1,#final_split_tables do
        for j=1,#final_split_tables[i] - 1 do
            tail = node.tail(final_split_tables[i][j])
            tail.next = final_split_tables[i][j+1]
            final_split_tables[i][j+1].prev = tail
        end
        final_split_tables[i] = node.vpack(final_split_tables[i][1])
    end
    trace("table: done with typeset_table")
    return final_split_tables
end -- typeset table

function reformat_foot( self,pagenumber,max_splits)
    trace("reformat_foot")
    local rownumber,y
    if pagenumber == max_splits and self.tablefoot_last_contents then
        y         = self.tablefoot_last_contents[1]
        rownumber = self.tablefoot_last_contents[2]
    else
        y         = self.tablefoot_contents[1]
        rownumber = self.tablefoot_contents[2]
    end
    local x = publisher.dispatch(y._layoutxml,y._dataxml)
    attach_objects(x)
    local tmp1,tmp2 = {},{}
    make_tablefoot(self,x,tmp1,tmp2,rownumber,true)
    calculate_height_and_connect_tablefoot(self,tmp1,tmp2)
    return tmp1[1],tmp2[1]
end

function reformat_head( self,pagenumber)
    trace("reformat_head")
    local y = self.tablehead_contents[1]
    local rownumber = self.tablehead_contents[2]
    local x = publisher.dispatch(y._layoutxml,y._dataxml)
    attach_objects(x)
    local tmp1,tmp2 = {}, {}
    make_tablehead(self,x,tmp1,tmp2,rownumber,true)
    calculate_height_and_connect_tablehead(self,tmp1,tmp2)
    return tmp1[1],tmp2[1]
end


function make_table( self )
    setmetatable(self.column_distances,{ __index = function() return self.colsep or 0 end })
    attach_objects(self.tab)
    if calculate_columnwidth(self) ~= nil then
        err("Cannot print table")
        local x = node.new("vlist")
        return x
    end
    calculate_rowheights(self)
    publisher.xpath.set_variable("_last_tr_data","")
    return typeset_table(self)
end

file_end("tabular.lua")

