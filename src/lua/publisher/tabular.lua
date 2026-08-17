--
--  tabular.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license details.

file_start("tabular.lua")

local publisher = require("publisher")

-- Table typesetting has six steps:
-- 1. set_skip_table()
-- This analyzes the table and stores rowspans and colspans, so the next steps can take these
-- into account.
-- 2. do_bordercollapse()
-- Re-calculate the border widths if bordercollapse is requested.
-- 2. collect_alignments()
-- This looks at the columns/column elements and stores the alignments and padding values
-- 3. attach_objects()
-- Here all objects are collected in horizontal and vertical lists assigned to a table cell.
-- 4. calculate_columnwidth()
-- Get all the column widths.
-- 5. calculate_rowheights()
-- Get the row heights
-- 6.typeset_table()
-- This typesets the table

local metapost = require("publisher.metapost")

-- A table instance is created by `tabular:new()`; the fields after `split`
-- are attached by the Table command in commands.lua before typesetting.
---@class tabular_module
---@field rowheights table Row heights, keyed by area ("body", "tablehead…").
---@field colwidths number[] Calculated column widths in sp.
---@field align table Per-column horizontal alignment.
---@field valign table Per-column vertical alignment.
---@field padding_left_col table Per-column left padding.
---@field padding_right_col table Per-column right padding.
---@field skip table
---@field backgroundcolumncolors table
---@field split integer Number of frames the table is split across.
---@field skiptables table Cells skipped because of row/colspans, per area.
---@field total_columns integer
---@field tab table Parsed contents of the Table element.
---@field layoutxml table
---@field dataxml table
---@field options table
---@field getheight function
---@field width number Table width in sp.
---@field fontfamily integer
---@field padding_left number
---@field padding_right number
---@field padding_top number
---@field padding_bottom number
---@field colsep number Distance between columns in sp.
---@field rowsep number Distance between rows in sp.
---@field autostretch? string Column stretching ("max" or "no").
---@field vexcess? string Vertical excess distribution.
---@field bordercollapse? boolean
---@field bordercollapse_horizontal? boolean
---@field bordercollapse_vertical? boolean
---@field eval_on_split_layoutxml? table
---@field eval_on_split_dataxml? table
---@field textformat? string
local tabular = {}

---@type table<string, any>
local dynamic_data = {}

-- Maps row/head/foot value tables to the (layoutxml, dataxml) under which
-- they were created. Kept off the value tables themselves so that
-- `flush_table` doesn't recurse into the layout/data XML trees when a
-- variable that holds such a structure is re-assigned.
local tr_origin = setmetatable({}, { __mode = "k" })

---@param t table
---@param layoutxml table
---@param dataxml table
function tabular.set_origin(t, layoutxml, dataxml)
    tr_origin[t] = { layoutxml = layoutxml, dataxml = dataxml }
end

---@param t table
---@return table? layoutxml
---@return table? dataxml
function tabular.get_origin(t)
    local o = tr_origin[t]
    if o then
        return o.layoutxml, o.dataxml
    end
end

-- Resolve a colspan value. Handles "*" (all remaining columns) and numeric values.
---@param value string|number The colspan attribute value
---@param current_column number The current column position (1-based)
---@param total_columns number The total number of columns in the table
---@return number The resolved colspan value
local function resolve_colspan(value, current_column, total_columns)
    if value == "*" then
        return total_columns - current_column + 1
    end
    return tonumber(value) or 1
end

-- Create a new tabular object.
---@return tabular_module tab New tabular object
function tabular:new()
    assert(self)
    local t = {
        rowheights = {},
        colwidths = {},
        align = {},
        valign = {},
        padding_left_col = {},
        padding_right_col = {},
        skip = {},
        backgroundcolumncolors = {},
        -- number of frames the table is split across, initialize to a sane default value
        split = 1,
    }

    setmetatable(t, self)
    self.__index = self
    return t
end

-- The objects in a table cell can be block objects or inline objects.
-- See the list of [html block objects](https://developer.mozilla.org/en-US/docs/Web/HTML/Block-level_elements)
-- for a rule of thumb how objects are arranged in a table cell. I am not sure if we should fully follow
-- the HTML way.
--
-- The inner arrays contain the objects to be stacked from left to right (“inline”)
-- and the outer array is a list of block objects that are to be stacked from top to bottom:
--     { { img      },
--       { par      },
--       { img, img },
--       { table    }  }
--
-- ![Objects in a table](../img/objectsintable.svg)
-- The table is stored in the objects
-- Attach objects to a single table row, organizing block and inline objects.
---@param tab table Table row data
---@param current_row integer Current row index
---@param skiptable table Table of skipped cells (rowspans/colspans)
function tabular:attach_objects_row(tab, current_row, skiptable)
    -- For each block object (container) there is one row in block
    local td_elementname
    local td_contents
    local current_column = 0
    for _, td in ipairs(tab) do
        current_column = current_column + 1
        td_elementname = publisher.xml_helpers.elementname(td)
        td_contents = publisher.xml_helpers.element_contents(td)
        if td_elementname == "Td" then
            local block = {}
            local inline = {}
            local colspan = resolve_colspan(td_contents.colspan, current_column, self.total_columns)
            local thiscolumn = current_column
            current_column = current_column + colspan - 1
            while skiptable[current_row] and skiptable[current_row][current_column] do
                thiscolumn = thiscolumn + 1
                current_column = current_column + 1
            end
            for _, j in ipairs(td_contents) do
                local eltname = publisher.xml_helpers.elementname(j)
                local eltcontents = publisher.xml_helpers.element_contents(j)
                if eltname == "Image" then
                    -- inline
                    inline[#inline + 1] = eltcontents[1]
                elseif eltname == "Barcode" then
                    -- inline
                    inline[#inline + 1] = eltcontents
                elseif eltname == "Overlay" then
                    -- inline
                    inline[#inline + 1] = eltcontents
                elseif eltname == "VSpace" then
                    if #inline > 0 then
                        -- add current inline to the list of blocks
                        block[#block + 1] = inline
                        inline = {}
                    end
                    block[#block + 1] = { eltcontents }
                elseif eltname == "Paragraph" or eltname == "Box" then
                    -- the text format for the whole table
                    local default_textformat_name = self.textformat
                    -- td align=..., tr align=... and columns align=...
                    local alignment = td_contents.align or tab.align or self.align[thiscolumn]
                    if alignment == "center" then
                        default_textformat_name = "__centered"
                    elseif alignment == "left" then
                        default_textformat_name = "__leftaligned"
                    elseif alignment == "right" then
                        default_textformat_name = "__rightaligned"
                    elseif alignment == "justify" then
                        default_textformat_name = "__justified"
                    end
                    -- box doesn't have field textformat
                    if type(eltcontents) == "table" then
                        -- if <Paragraph> has its own text format then use this, instead of the td... one above
                        local tfname = (eltcontents.textformat and eltcontents.textformat.name)
                            or default_textformat_name
                            or "__leftaligned"
                        eltcontents.textformat = publisher.textformats[tfname]
                        eltcontents.rotate = eltcontents.rotate
                    end
                    -- block
                    if #inline > 0 then
                        -- add current inline to the list of blocks
                        block[#block + 1] = inline
                        inline = {}
                    end
                    block[#block + 1] = { eltcontents }
                elseif eltname == "Textblock" then
                    -- block (pre-formatted to its own width)
                    if #inline > 0 then
                        block[#block + 1] = inline
                        inline = {}
                    end
                    block[#block + 1] = { eltcontents }
                elseif eltname == "Table" or eltname == "Groupcontents" then
                    -- block
                    if #inline > 0 then
                        -- add current inline to the list of blocks
                        block[#block + 1] = inline
                        inline = {}
                    end
                    block[#block + 1] = eltcontents
                elseif eltname == "Action" then
                    -- inline (contains mark whatsit nodes)
                    inline[#inline + 1] = eltcontents
                elseif eltname == "Mark" then
                    -- Mark as direct child of Td (without Action wrapper)
                    inline[#inline + 1] = commands.mark_to_par(eltcontents)
                elseif eltname == "Message" or eltname == "Bookmark" then
                    -- ignore
                else
                    -- warning("Unknown object in table: %s",eltname or "???")
                end
            end
            if #inline > 0 then
                -- add current inline to the list of blocks
                block[#block + 1] = inline
            end
            td_contents.objects = block
            td_contents.objects.rotate = td_contents.rotate
        elseif td_elementname == "Tr" then -- probably from tablefoot/head
            self:attach_objects_row(td_contents, current_row, skiptable)
        elseif td_elementname == "Column" or td_elementname == "Tablerule" or td_elementname == "TableNewPage" then
            -- ignore, they don't have objects
        else
            -- w("unknown element name %s",td_elementname)
        end
    end
end

-- Attach objects to all rows in the table, including table head and foot.
---@param tab table Table data
---@param row? integer Row index (optional)
function tabular:attach_objects(tab, row)
    row = row or 1
    for _, tr in ipairs(tab) do
        local eltname = publisher.xml_helpers.elementname(tr)
        local tr_contents = publisher.xml_helpers.element_contents(tr)
        if eltname == "Tr" then
            local skiptable = self.skiptables.body
            self:attach_objects_row(publisher.xml_helpers.element_contents(tr), row, skiptable)
            row = row + 1
        elseif eltname == "Tablehead" or eltname == "Tablefoot" then
            local area
            if eltname == "Tablehead" then
                area = "tablehead"
            else
                area = "tablefoot"
            end
            area = area .. (tr_contents.page or "")
            local skiptable = self.skiptables[area] or {}
            self:attach_objects_row(publisher.xml_helpers.element_contents(tr), row, skiptable)
        end
    end
end

-- Width calculation
-- =================

-- First we check for adjacent columns for collapsing border:
-- ![maximum width](../img/bordercollapse.svg)
--
-- The resulting width for each border (left and right) is
--
-- \\(\frac{max(border-left,border-right)}{2}\\)
--
-- even if one
-- side didn't have a border. In that case we need to adjust the border colors. Beware: the result is slightly undefined
-- if both sides have different colors.
-- Calculate the width for each column in the row.
-- Calculate the minimum and maximum column widths for a single row.
---@param tr_contents table Row contents
---@param current_row integer Current row index
---@param colspans table Table to store colspan info
---@param colmin table Table to store minimum column widths
---@param colmax table Table to store maximum column widths
---@param skiptable table Table of skipped cells
function tabular:calculate_columnwidths_for_row(tr_contents, current_row, colspans, colmin, colmax, skiptable)
    local current_column = 0
    local max_wd, min_wd -- maximum and minimum width of a table cell (Td)
    -- first we go through all rows/cells and look, how wide the columns
    -- are supposed to be. If there are colspans, they have to be treated specially

    -- We calculate the widths in two passes:
    --
    --  1. Calculate the width of each table cell in a row
    --  1. Calculate the row height
    --
    -- The minimum width (min\_wd) is calculated as follows. Calculate the length of the longest item in the row:
    --
    -- ![minimum width](../img/calculate_longtext2.svg)
    --
    -- The maximum width (max\_wd) is calculated by typesetting the text and taking total size of the hbox into account:
    --
    -- ![maximum width](../img/calculate_longtext.svg)
    --
    for _, td in ipairs(tr_contents) do
        local td_contents = publisher.xml_helpers.element_contents(td)
        -- all columms (table cells)
        -- fill skip, colspan and colmax-tables for this cell
        current_column = current_column + 1
        min_wd, max_wd = nil, nil
        local colspan = resolve_colspan(td_contents.colspan, current_column, self.total_columns)

        -- When I am on a skip column (because of a row span), we jump over to the next column
        while skiptable[current_row] and skiptable[current_row][current_column] do
            current_column = current_column + 1
        end

        local td_borderleft = td_contents.td_borderleft_calculated or tex.sp(td_contents["border-left"] or 0)
        local td_borderright = td_contents.td_borderright_calculated or tex.sp(td_contents["border-right"] or 0)
        local padding_left = td_contents.padding_left or self.padding_left_col[current_column] or self.padding_left
        local padding_right = td_contents.padding_right or self.padding_right_col[current_column] or self.padding_right
        local cellheight = 0
        for _, blockobject in ipairs(td_contents.objects) do
            if type(blockobject) ~= "table" then
                main.log("error", "internal error: blockobject is not a table")
            else
                for i = 1, #blockobject do
                    local inlineobject = blockobject[i]
                    if type(inlineobject) == "table" then
                        if inlineobject.min_width then
                            local mw = inlineobject:min_width(
                                inlineobject.alignment,
                                { fontfamily = inlineobject.fontfamily or self.fontfamily },
                                self.dataxml
                            )
                            min_wd = math.max(
                                mw + padding_left + padding_right + td_borderleft + td_borderright,
                                min_wd or 0
                            )
                        end
                        if inlineobject.max_width_and_lineheight then
                            local mw, _ = inlineobject:max_width_and_lineheight(
                                { fontfamily = inlineobject.fontfamily or self.fontfamily },
                                self.dataxml
                            )
                            max_wd = math.max(
                                mw + padding_left + padding_right + td_borderleft + td_borderright,
                                max_wd or 0
                            )
                        end
                    elseif node.is_node(inlineobject) and node.has_field(inlineobject, "width") then
                        min_wd = math.max(
                            inlineobject.width + padding_left + padding_right + td_borderleft + td_borderright,
                            min_wd or 0
                        )
                        max_wd = math.max(
                            inlineobject.width + padding_left + padding_right + td_borderleft + td_borderright,
                            max_wd or 0
                        )
                        if node.has_field(inlineobject, "height") then
                            cellheight = cellheight + inlineobject.height
                        end
                        if node.has_field(inlineobject, "depth") then
                            cellheight = cellheight + inlineobject.depth
                        end
                    end
                end
            end
            if min_wd == nil then
                min_wd = 0
            end
            if max_wd == nil then
                max_wd = 0
            end
        end
        -- colspan?
        min_wd = min_wd or 0
        max_wd = max_wd or 0
        local angle_rad = -1 * math.rad(td_contents.rotate or 0)
        max_wd = math.abs(max_wd * math.cos(angle_rad)) + math.abs(cellheight * math.sin(angle_rad))
        if colspan > 1 then
            colspans[#colspans + 1] =
                { start = current_column, stop = current_column + colspan - 1, max_wd = max_wd, min_wd = min_wd }
            current_column = current_column + colspan - 1
        elseif self.colwidths[current_column] then
            -- a predefined width
            colmax[current_column] = self.colwidths[current_column]
            colmin[current_column] = self.colwidths[current_column]
        else
            colmax[current_column] = math.max(colmax[current_column] or 0, max_wd)
            colmin[current_column] = math.max(colmin[current_column] or 0, min_wd)
        end
    end -- ∀ columns
end

-- Collects alignment and padding information from `<Columns>`/`<Column>`
-- elements and stores it on `self.align`, `self.valign`,
-- `self.padding_left_col` and `self.padding_right_col`.
---@return nil
function tabular:collect_alignments()
    for _, tr in ipairs(self.tab) do
        local tr_contents = publisher.xml_helpers.element_contents(tr)
        local tr_elementname = publisher.xml_helpers.elementname(tr)
        if tr_elementname == "Columns" then
            local i = 0
            for _, column in ipairs(tr_contents) do
                if publisher.xml_helpers.elementname(column) == "Column" then
                    local column_contents = publisher.xml_helpers.element_contents(column)
                    i = i + 1
                    self.align[i] = column_contents.align
                    self.valign[i] = column_contents.valign
                    self.padding_left_col[i] = column_contents.padding_left
                    self.padding_right_col[i] = column_contents.padding_right
                end
            end
        end
    end
end

-- Calculates the final widths for every column in the table. Honors
-- explicit widths, `*` (proportional), `min-width`/`max-width`, colspans
-- and shrink/grow when the table has a fixed total width target.
---@return nil
function tabular:calculate_columnwidth()
    local colspans = {}
    local minwidths, col_shrink, starcols, colmax, colmin = {}, {}, {}, {}, {}
    local has_min_or_max_width = false
    self.tablewidth_target = self.width
    local columnwidths_given = nil

    for _, tr in ipairs(self.tab) do
        local tr_contents = publisher.xml_helpers.element_contents(tr)
        local tr_elementname = publisher.xml_helpers.elementname(tr)

        -- When the user gives us column widths, we use them for calculation. There are two ways to
        -- determine the column widths: with \\(n\\)* (where \\(n\\) is an integer number) or with absolute
        -- lengths such as `4` (in grid cells) or `2.5cm`. For example:
        --
        --     <Columns>
        --       <Column width="3cm"/>
        --       <Column width="1*"/>
        --       <Column width="3*"/>
        --     </Columns>
        --
        -- When we typeset a table with a requested with of 11cm, the first column would get 3cm,
        -- the second column 1/4 of the rest (2cm) and the third 3/4 of the rest (6cm).
        -- ![Table calculation](../img/table313.svg)
        if tr_elementname == "Columns" then
            local i = 0
            local count_stars = 0
            local sum_real_widths = 0
            local count_columns = 0
            local starpattern = "([0-9]+)%*"
            local has_width = false
            for _, column in ipairs(tr_contents) do
                if publisher.xml_helpers.elementname(column) == "Column" then
                    local column_contents = publisher.xml_helpers.element_contents(column)
                    i = i + 1
                    minwidths[i] = 0
                    if column_contents.minwidth then
                        minwidths[i] = column_contents.minwidth
                    end
                    if column_contents.width then
                        has_width = true
                        -- if I have something written in <column> I don't need
                        -- to calculate column width:
                        if column_contents.width == "max" then
                            col_shrink[i] = 1
                            has_min_or_max_width = true
                        elseif column_contents.width == "min" then
                            col_shrink[i] = 2
                            has_min_or_max_width = true
                        elseif column_contents.width == "?" then
                            columnwidths_given = false
                        else
                            -- columnwidths_given can be false with a "?" width. This must
                            -- not be set to true again
                            if columnwidths_given == nil then
                                columnwidths_given = true
                            end
                            local width_stars = string.match(column_contents.width, starpattern)
                            if width_stars then
                                local n = tonumber(width_stars, 10)
                                starcols[i] = n
                                count_stars = count_stars + n
                            else
                                if tonumber(column_contents.width) then
                                    self.colwidths[i] = publisher.current_grid:width_sp(column_contents.width)
                                else
                                    self.colwidths[i] = tex.sp(column_contents.width)
                                end
                                sum_real_widths = sum_real_widths + (self.colwidths[i] or 0)
                            end
                        end
                    end
                    if column_contents.backgroundcolor then
                        self.backgroundcolumncolors[i] = column_contents.backgroundcolor
                    end
                end
                count_columns = i
            end

            -- if stretch="no", we don't need to stretch/shrink anything
            -- count_stars == 0 if there are only fixed width columns
            -- given in the <Column width="..."/>  setting.
            if self.autostretch ~= "max" and count_stars == 0 and has_width then
                self.tablewidth_target = sum_real_widths
            end
            if has_min_or_max_width then
                columnwidths_given = false
                break
            end

            if columnwidths_given and count_stars == 0 then
                return
            end

            if count_stars > 0 then
                -- now we know the number of *-columns and the sum of the fix columns, so that
                -- we can distribute the remaining space
                local to_distribute = self.tablewidth_target - sum_real_widths - (count_columns - 1) * self.colsep
                i = 0
                for _, column in ipairs(tr_contents) do
                    if publisher.xml_helpers.elementname(column) == "Column" then
                        local column_contents = publisher.xml_helpers.element_contents(column)
                        i = i + 1
                        local width_stars = string.match(column_contents.width, starpattern)
                        if width_stars then
                            local n = tonumber(width_stars, 10)
                            if n and count_stars > 0 then
                                self.colwidths[i] = math.floor((to_distribute * n / count_stars) + 0.5)
                            end
                        end
                    end
                end
            end -- sum_* > 0
        end
    end

    if columnwidths_given then
        return
    end

    -- Phase I
    -- -------
    -- Calculate max\_wd, min\_wd. We do this in a separate function for each row.
    -- Use separate row counters for body and each head/foot area to match the
    -- numbering used in set_skip_table().
    local current_row_body = 0
    local rowcounter_areas = {}
    for _, tr in ipairs(self.tab) do
        local tr_contents = publisher.xml_helpers.element_contents(tr)
        local tr_elementname = publisher.xml_helpers.elementname(tr)
        if tr_elementname == "Tr" then
            current_row_body = current_row_body + 1
            self:calculate_columnwidths_for_row(
                tr_contents,
                current_row_body,
                colspans,
                colmin,
                colmax,
                self.skiptables.body
            )
        elseif tr_elementname == "Tablerule" then
            -- ignore
        elseif tr_elementname == "Tablehead" or tr_elementname == "Tablefoot" then
            local area
            if tr_elementname == "Tablehead" then
                area = "tablehead"
            else
                area = "tablefoot"
            end
            area = area .. (tr_contents.page or "")
            rowcounter_areas[area] = rowcounter_areas[area] or 0
            for _, row in ipairs(tr_contents) do
                local row_contents = publisher.xml_helpers.element_contents(row)
                local row_elementname = publisher.xml_helpers.elementname(row)
                if row_elementname == "Tr" then
                    rowcounter_areas[area] = rowcounter_areas[area] + 1
                    self:calculate_columnwidths_for_row(
                        row_contents,
                        rowcounter_areas[area],
                        colspans,
                        colmin,
                        colmax,
                        self.skiptables[area]
                    )
                end
            end
        elseif tr_elementname == "Columns" or tr_elementname == "TableNewPage" then
            -- ignore
        else
            main.log("warn", string.format("Unknown Element: %q", tr_elementname or "?"))
        end -- if it's really a row
    end -- ∀ rows / rules

    if has_min_or_max_width then
        local stretch = {}
        local sum_stretch = 0
        local total_stars_width = self.width
        local count_stars = 0
        for i = 1, #colmin do
            stretch[i] = 0
            if col_shrink[i] then
                -- this column has min or max
                if col_shrink[i] == 1 then
                    -- width="max"
                    if colmax[i] > minwidths[i] then
                        stretch[i] = colmax[i] - minwidths[i]
                        sum_stretch = sum_stretch + stretch[i]
                    end
                else
                    -- width="min"
                end
                self.colwidths[i] = minwidths[i]
                total_stars_width = total_stars_width - self.colwidths[i]
            elseif starcols[i] then
                count_stars = count_stars + starcols[i]
            else
                if i > #self.colwidths then
                    main.log("error", "Something is wrong with the number of coumns in the table")
                    return
                end
                total_stars_width = total_stars_width - self.colwidths[i]
            end
        end
        local sum_star_minwd = 0
        for i in pairs(starcols) do
            sum_star_minwd = sum_star_minwd + colmin[i]
        end
        local overshoot
        local r = 1
        if total_stars_width - sum_star_minwd < sum_stretch then
            overshoot = total_stars_width - sum_star_minwd
            total_stars_width = sum_star_minwd
            r = overshoot / sum_stretch
        else
            total_stars_width = total_stars_width - sum_stretch
        end
        for i = 1, #stretch do
            if stretch[i] > 0 then
                self.colwidths[i] = self.colwidths[i] + stretch[i] * r
            end
        end
        total_stars_width = total_stars_width / count_stars
        for i = 1, #colmin do
            if starcols[i] then
                self.colwidths[i] = total_stars_width * starcols[i]
            end
        end
        return
    end

    -- Now we are finished with all cells in all rows. If there are colospans, we might have
    -- to increase some column widths
    --
    -- Example (fake):
    --
    --     <Table width="30">
    --       <Tr><Td>A</Td><Td>A</Td></Tr>
    --       <Tr><Td colspan="2">A very very very long text</Td></Tr>
    --     </Table>
    --     ----------------------------
    --     |A           |A            |
    --     |A very very very long text|
    --     ----------------------------
    --
    -- In this case sum(min) is approx. the width of the word "very" and sum(max) is the width of the text.
    -- colmax[i] is the width of "A", colmin[i] also
    --
    -- Phase II: include colspan
    -- -------------------------
    for _, colspan in pairs(colspans) do
        local sum_min, sum_max = 0, 0
        local r -- stretch factor = wd(colspan)/wd(sum_start_end)

        -- First we calculate how wide the columns are that are covered by colspan, but without
        -- colspan itself

        if #colmax < colspan.stop then
            main.log("error", "Not enough columns found for colspan")
            return -1
        end

        for i = colspan.start, colspan.stop do
            if not self.colwidths[i] then
                sum_max = sum_max + colmax[i]
            else
                colspan.max_wd = colspan.max_wd - self.colwidths[i]
            end
        end
        for i = colspan.start, colspan.stop do
            if not self.colwidths[i] then
                sum_min = sum_min + colmin[i]
            else
                colspan.min_wd = colspan.min_wd - self.colwidths[i]
            end
        end

        -- If the colspan requires more room than the rest of the table, we have to increase
        -- the width of all columns in the table accordingly. We stretch the columns by
        -- a factor r. r is calculated by the contents.
        --
        -- We do that once for the maximum width and once for the minimum width
        local width_of_colsep = (colspan.stop - colspan.start) * self.colsep

        if colspan.max_wd > sum_max + width_of_colsep then
            r = (colspan.max_wd - width_of_colsep) / sum_max
            for j = colspan.start, colspan.stop do
                if not self.colwidths[j] then
                    colmax[j] = colmax[j] * r
                end
            end
        end -- colspan.max_wd > sum_max?

        if colspan.min_wd > sum_min + width_of_colsep then
            r = (colspan.min_wd - width_of_colsep) / sum_min
            for j = colspan.start, colspan.stop do
                if not self.colwidths[j] then
                    colmin[j] = colmin[j] * r
                end
            end
        end -- colspan.min_wd > sum_min?
    end -- ∀ colspans

    -- Now colmin and colmax are calculated for all columns. colspans are included.

    -- Phase III: Stretch or shrink table
    -- ----------------------------------

    -- Here comes the main width calculation
    local colsep = (#colmax - 1) * self.colsep
    local tablewidth_is = table.sum(colmax) + colsep
    -- 1. calculate natural (max) width / total width for each column.
    --
    -- If stretch="no" is set, we can encounter the case that the table is too wide. Then it
    -- must be shrunk.

    -- highly unlikely that the table matches the size exactly
    if tablewidth_is == self.tablewidth_target then
        for i = 1, #colmax do
            self.colwidths[i] = colmax[i]
        end
        return
    end

    -- if the table is too wide, we need to shrink some columns
    if tablewidth_is > self.tablewidth_target then
        local tablewidth_target = self.tablewidth_target
        for i = 1, #colmax do
            local cwi = self.colwidths[i]
            if cwi then
                tablewidth_target = tablewidth_target - cwi
                tablewidth_is = tablewidth_is - cwi
            end
        end

        -- Iterative shrink: distribute available width proportionally,
        -- respecting colmin. Columns that hit colmin are fixed and the
        -- remaining width is redistributed among the other columns.
        local fixed = {}
        local available = tablewidth_target - colsep
        local remaining_natural = tablewidth_is - colsep

        for _iteration = 1, #colmax do
            local changed = false
            for i = 1, #colmax do
                if not self.colwidths[i] and not fixed[i] then
                    local proportional = colmax[i] / remaining_natural * available
                    if proportional < colmin[i] then
                        self.colwidths[i] = colmin[i]
                        fixed[i] = true
                        available = available - colmin[i]
                        remaining_natural = remaining_natural - colmax[i]
                        changed = true
                    end
                end
            end
            if not changed then
                break
            end
        end

        -- Assign remaining columns their proportional share
        for i = 1, #colmax do
            if not self.colwidths[i] and not fixed[i] then
                if remaining_natural > 0 then
                    self.colwidths[i] = colmax[i] / remaining_natural * available
                else
                    self.colwidths[i] = colmin[i]
                end
            elseif colmax[i] == 0 and not self.colwidths[i] then
                self.colwidths[i] = 0
            end
        end
        return
    end
    -- if stretch="no", we don't need to stretch/shrink anything
    if self.autostretch ~= "max" then
        self.tablewidth_target = tablewidth_is
        for i = 1, #colmax do
            self.colwidths[i] = colmax[i]
        end

        return
    end

    -- if the table is too narrow, we must make it wider
    if tablewidth_is < self.tablewidth_target then
        -- table must get wider

        local tablewidth_target = self.tablewidth_target
        for i = 1, #colmax do
            local cwi = self.colwidths[i]
            if cwi then
                tablewidth_target = tablewidth_target - cwi
                tablewidth_is = tablewidth_is - cwi
            end
        end
        local r = (tablewidth_target - colsep) / (tablewidth_is - colsep)

        for i = 1, #colmax do
            if not self.colwidths[i] then
                self.colwidths[i] = colmax[i] * r
            end
        end
    end
end

-- Typeset a table cell. Return a vlist, tightly packed (i.e. all vspace are 0).
-- Pack block and inline objects into a table cell, applying width and alignment.
---@param blockobjects table List of block objects
---@param width number Target cell width
---@param horizontal_alignment string Alignment for cell content
function tabular:pack_cell(blockobjects, width, horizontal_alignment)
    local cell
    if not blockobjects then
        splib.log("warning", "no objects found in table cell")
        return
    end
    for _, blockobject in ipairs(blockobjects) do
        local cellrow = nil
        local current_width = 0
        if node.is_node(blockobject) then
            cellrow = node.insert_after(cellrow, node.tail(cellrow), blockobject)
        else
            for i = 1, #blockobject do
                local inlineobject = blockobject[i]
                if type(inlineobject) == "table" then
                    if width then
                        local save_width
                        if publisher.newxpath then
                            save_width = self.dataxml.vars["__maxwidth"]
                            self.dataxml.vars["__maxwidth"] = width
                        else
                            save_width = publisher.xpath.get_variable("__maxwidth")
                            publisher.xpath.set_variable("__maxwidth", width)
                        end

                        local angle_rad = -1 * math.rad(blockobjects.rotate or 0)
                        local sin_angle = math.sin(angle_rad)
                        local format_width = width
                        if sin_angle ~= 0 then
                            -- The width is not 100% accurate yet. Multi-line paragraphs for example
                            -- are not yet taken into account.
                            local mw = inlineobject:max_width_and_lineheight({
                                fontfamily = inlineobject.fontfamily or self.fontfamily,
                            })
                            format_width = math.max(format_width, mw * sin_angle)
                        end

                        local v = inlineobject:format(format_width, {
                            textformat = inlineobject.textformat,
                            fontfamily = inlineobject.fontfamily or self.fontfamily,
                        }, self.dataxml)
                        if publisher.options.format == "PDF/UA" then
                            publisher.attribute_helpers.setprop(v, "role", inlineobject.role)
                            publisher.attribute_helpers.setprop(v, "parentid", inlineobject.parent)
                            publisher.attribute_helpers.setprop(v, "rolecounter", inlineobject.rolecounter)
                            publisher.attribute_helpers.setprop(v, "structpos", inlineobject.structpos)
                            publisher.attribute_helpers.setprop(v, "actualtext", inlineobject.actualtext)
                            publisher.attribute_helpers.setprop(v, "alttext", inlineobject.alttext)
                            publisher.attribute_helpers.setprop(v, "id", inlineobject.id)
                            node.set_attribute(v, publisher.att_role, inlineobject.role)
                        end

                        cell = node.insert_after(cell, node.tail(cell), v)
                        if publisher.newxpath then
                            self.dataxml.vars["__maxwidth"] = save_width
                        else
                            publisher.xpath.set_variable("__maxwidth", save_width)
                        end
                    else
                        w("no width given in paragraph")
                    end
                elseif node.is_node(inlineobject) then
                    -- an image for example
                    local rotate_deg = tonumber(blockobjects.rotate) or 0
                    if rotate_deg % 360 ~= 0 and node.has_field(inlineobject, "height") and inlineobject.height > 0 then
                        -- Pivot rotation around the content's top instead of
                        -- its bottom by wrapping in a save/restore that
                        -- pre-shifts down by the content height. Required for
                        -- images, harmless for text (Tm overrides CTM).
                        local pre = node.new("whatsit", "pdf_literal")
                        pre.mode = 0
                        pre.data = string.format("q 1 0 0 1 0 %g cm ", -inlineobject.height / publisher.factor)
                        local post = node.new("whatsit", "pdf_literal")
                        post.mode = 0
                        post.data = "Q "
                        cellrow = node.insert_after(cellrow, node.tail(cellrow), pre)
                        cellrow = node.insert_after(cellrow, node.tail(cellrow), inlineobject)
                        cellrow = node.insert_after(cellrow, node.tail(cellrow), post)
                        current_width = current_width + inlineobject.width
                    elseif node.has_field(inlineobject, "width") then
                        -- insert a line break if the row is too wide
                        if current_width + inlineobject.width > width then
                            local tmp
                            if cellrow then
                                if cellrow.next then
                                    tmp = node.hpack(cellrow)
                                    publisher.attribute_helpers.setprop(tmp, "origin", "attach objects")
                                else
                                    tmp = cellrow
                                end
                            end
                            cell = node.insert_after(cell, node.tail(cell), tmp)
                            cellrow = inlineobject
                            current_width = inlineobject.width
                        else
                            current_width = current_width + inlineobject.width
                            cellrow = node.insert_after(cellrow, node.tail(cellrow), inlineobject)
                        end
                    else
                        cellrow = node.insert_after(cellrow, node.tail(cellrow), inlineobject)
                    end
                else
                    w("unknown %s", type(inlineobject))
                end
            end
        end

        -- cellrow can be nil if there is a paragraph for example
        if cellrow then
            local tmp
            if cellrow.next then
                tmp = node.hpack(cellrow)
                publisher.attribute_helpers.setprop(tmp, "origin", "cellrow")
            else
                tmp = cellrow
            end
            cell = node.insert_after(cell, node.tail(cell), tmp)
        end
    end

    -- if there are no objects in a row, we create a dummy object
    -- so the row can be created and vpack does not fall over a nil
    cell = cell or node.new("hlist")
    cell = publisher.drawing.rotateTd(cell, blockobjects.rotate or 0, width)

    local n = cell
    while n do
        if n.id == publisher.hlist_node or n.id == publisher.vlist_node then
            local n_prev = n.prev
            local n_next = n.next
            local tmp = n
            n.next = nil
            local glue_left, glue_right

            if horizontal_alignment == "center" or horizontal_alignment == "justify" then
                glue_left = node.copy(publisher.glue_stretch2)
                glue_right = node.copy(publisher.glue_stretch2)
            elseif horizontal_alignment == "left" or horizontal_alignment == nil then
                glue_left = nil
                glue_right = node.copy(publisher.glue_stretch2)
            elseif horizontal_alignment == "right" then
                glue_left = node.copy(publisher.glue_stretch2)
                glue_right = nil
            end

            if glue_left then
                publisher.attribute_helpers.setprop(glue_left, "origin", "align_left")
                tmp = node.insert_before(tmp, n, glue_left)
            end
            if glue_right then
                publisher.attribute_helpers.setprop(glue_right, "origin", "align_right")
                tmp = node.insert_after(tmp, n, glue_right)
            end
            tmp = node.hpack(tmp, width, "exactly")

            if n_prev then
                n_prev.next = tmp
            end
            if n_next then
                n_next.prev = tmp
            end
            tmp.prev = n_prev
            tmp.next = n_next
            if n == cell then
                cell = tmp
            end
            n = tmp
        end
        n = n.next
    end
    local ret
    ret = node.vpack(cell)
    return ret
end

-- last\_shiftup is for vertical border-collapse.
-- Calculate the height of a table row, considering rowspans and minimum height.
---@param tr_contents table Row contents
---@param current_row integer Current row index
---@param last_shiftup? number Last shift-up value
---@param skiptable table Table of skipped cells
---@return number? rowheight Row height (nil if no cell could be packed).
---@return table? rowspans
---@return number? shiftup
function tabular:calculate_rowheight(tr_contents, current_row, last_shiftup, skiptable)
    last_shiftup = last_shiftup or 0
    local rowheight
    local rowspan, colspan
    local wd
    local rowspans = {}
    local shiftup = 0

    local fam = publisher.fonts.lookup_fontfamily_number_instance[self.fontfamily]
    local min_lineheight = fam.baselineskip

    if tr_contents.minheight then
        ---@type number
        local minht
        if tonumber(tr_contents.minheight) then
            minht = publisher.current_grid:height_sp(tr_contents.minheight)
        else
            local ht = tex.sp(tr_contents.minheight)
            if ht == nil then
                main.log("error", "Cannot parse minheight", "ht", tr_contents.minheight or "?")
                ht = 0
            end
            minht = ht
        end
        minht = minht or 0
        rowheight = math.max(minht, min_lineheight)
    else
        rowheight = min_lineheight
    end

    -- its not trivial to find out in which column I am in.
    -- See the example in qa/tables/columnspread. Line three:
    -- The first cell is in column 1, the second cell is in column 4
    local current_column = 0

    for _, td in ipairs(tr_contents) do
        local td_contents = publisher.xml_helpers.element_contents(td)
        if td_contents == nil then
            main.log("error", "No contents in Td")
            return rowheight, rowspans, shiftup
        end
        current_column = current_column + 1

        local td_borderleft = td_contents.td_borderleft_calculated or tex.sp(td_contents["border-left"] or 0)
        local td_borderright = td_contents.td_borderright_calculated or tex.sp(td_contents["border-right"] or 0)
        local td_bordertop = td_contents.td_bordertop_calculated or tex.sp(td_contents["border-top"] or 0) or 0
        local td_borderbottom = td_contents.td_borderbottom_calculated or tex.sp(td_contents["border-bottom"] or 0) or 0
        local padding_left = td_contents.padding_left or self.padding_left_col[current_column] or self.padding_left
        local padding_right = td_contents.padding_right or self.padding_right_col[current_column] or self.padding_right
        local padding_top = td_contents.padding_top or self.padding_top
        local padding_bottom = td_contents.padding_bottom or self.padding_bottom

        rowspan = tonumber(td_contents.rowspan) or 1
        colspan = resolve_colspan(td_contents.colspan, current_column, self.total_columns)
        wd = 0

        -- There might be a rowspan in the row above, so we need to find the correct
        -- column width

        while skiptable[current_row] and skiptable[current_row][current_column] do
            current_column = current_column + 1
        end
        -- alignments of a colspan cell come from its first column
        local thiscolumn = current_column
        for s = current_column, current_column + colspan - 1 do
            if self.colwidths[s] == nil then
                main.log("error", "Something went wrong with the number of columns in the table (calculate_rowheight)")
            else
                wd = wd + self.colwidths[s]
            end
        end
        current_column = current_column + colspan - 1
        wd = wd + (colspan - 1) * self.colsep

        -- FIXME: take border-left and border-right into account
        --        in the height calculation also border-top and border-bottom
        local alignment = td_contents.align or tr_contents.align or self.align[thiscolumn]
        local cell = self:pack_cell(
            td_contents.objects,
            wd - padding_left - padding_right - td_borderleft - td_borderright,
            alignment
        )
        if not cell then
            splib.log("warning", "no table cell found")
            return
        end
        td_contents.cell = cell
        local tmp = cell.height + cell.depth

        tmp = tmp + padding_top + padding_bottom + td_borderbottom + td_bordertop
        if rowspan > 1 then
            rowspans[#rowspans + 1] = { start = current_row, stop = current_row + rowspan - 1, ht = tmp }
            td_contents.rowspan_internal = rowspans[#rowspans]
        else
            rowheight = math.max(rowheight, tmp)
        end
    end
    tr_contents.shiftup = last_shiftup
    return rowheight, rowspans, shiftup
end

-- Calculates row heights for every row in the body, head and foot,
-- delegating per-row work to `calculate_rowheight` and accumulating
-- rowspan information for `adjust_row_heights_for_rowspans`.
---@return nil
function tabular:calculate_rowheights()
    -- rowspans is the concatenation of each rowspan for a table row
    local rowspans = {}
    local _rowspans
    local rowheight
    local rowheightarea
    local tablearea
    local rowcounter = {}
    local current_row

    ---@type number?
    local last_shiftup = 0

    for _, tr in ipairs(self.tab) do
        local tr_contents = publisher.xml_helpers.element_contents(tr)
        local eltname = publisher.xml_helpers.elementname(tr)
        if eltname == "Tablerule" or eltname == "Columns" or eltname == "TableNewPage" then
            -- ignore
        elseif eltname == "Tablehead" then
            tablearea = "tablehead" .. (tr_contents.page or "")
        elseif eltname == "Tablefoot" then
            tablearea = "tablefoot" .. (tr_contents.page or "")
        else
            tablearea = "body"
        end
        if tablearea then
            self.rowheights[tablearea] = self.rowheights[tablearea] or {}
            rowheightarea = self.rowheights[tablearea]
            rowspans[tablearea] = rowspans[tablearea] or {}
            rowcounter[tablearea] = rowcounter[tablearea] or 0
        end

        if eltname == "Tablerule" or eltname == "Columns" or eltname == "TableNewPage" then
            -- ignore
        elseif eltname == "Tablehead" or eltname == "Tablefoot" then
            ---@type number?
            local hf_last_shiftup = 0
            for _, row in ipairs(tr_contents) do
                local cellcontents = publisher.xml_helpers.element_contents(row)
                local cell_elementname = publisher.xml_helpers.elementname(row)
                if cell_elementname == "Tr" then
                    rowcounter[tablearea] = rowcounter[tablearea] + 1
                    current_row = rowcounter[tablearea]
                    rowheight, _rowspans, hf_last_shiftup =
                        self:calculate_rowheight(cellcontents, current_row, hf_last_shiftup, self.skiptables[tablearea])
                    if not rowheight then
                        return
                    end
                    rowheightarea[current_row] = rowheight
                    rowspans[tablearea] = table.__concat(rowspans[tablearea], _rowspans)
                end
            end
        elseif eltname == "Tr" then
            rowcounter[tablearea] = rowcounter[tablearea] + 1
            current_row = rowcounter[tablearea]
            rowheight, _rowspans, last_shiftup =
                self:calculate_rowheight(tr_contents, current_row, last_shiftup, self.skiptables.body)
            rowheightarea[current_row] = rowheight
            rowspans[tablearea] = table.__concat(rowspans[tablearea], _rowspans)
        else
            main.log("warn", string.format("Unknown contents in “Table” %s", eltname or "?"))
        end -- if it's not a <Tablerule>
    end -- for all rows

    for k, v in pairs(self.rowheights) do
        local thisrowspan = rowspans[k]
        self:adjust_row_heights_for_rowspans(thisrowspan, v)
    end
end

-- Adjust row heights to account for rowspans.
---@param rowspans table Table of rowspans
---@param area table Table of row heights
function tabular:adjust_row_heights_for_rowspans(rowspans, area)
    -- Adjust row heights. We have to do calculations on all row heights, before the rows can get their
    -- final heights
    for _, rowspan in pairs(rowspans) do
        local sum_ht = 0
        for j = rowspan.start, rowspan.stop do
            if not area[j] then
                main.log("error", "Rowspan exceeds the number of rows in the table")
            else
                sum_ht = sum_ht + area[j]
            end
        end
        sum_ht = sum_ht + self.rowsep * (rowspan.stop - rowspan.start)
        if rowspan.ht > sum_ht then
            if self.vexcess == "bottom" then
                area[rowspan.stop] = area[rowspan.stop] + rowspan.ht - sum_ht
            else
                local excess_per_row = (rowspan.ht - sum_ht) / (rowspan.stop - rowspan.start + 1)
                for j = rowspan.start, rowspan.stop do
                    area[j] = area[j] + excess_per_row
                end
            end
        end
    end

    -- We have now calculated all row heights. So we can adjust the rowspans now.
    for _, rowspan in pairs(rowspans) do
        rowspan.sum_ht = table.sum(area, rowspan.start, rowspan.stop) + self.rowsep * (rowspan.stop - rowspan.start)
    end
end

-- ![Table cell](../img/cell.svg)

-- Width calculation is now finished, we can typeset the table
-- Typesetting the table
-- ---------------------
-- First, we create a complete table with all rows. Splitting into pages is done later on.
-- Background colors are NOT applied during row creation. Instead, the resolved color
-- names are stored in `deferred_bgcolors` (a table mapping cell index to color name)
-- on the row hbox via node properties. The actual pdf_literal background nodes are
-- inserted later by `apply_deferred_backgrounds()`, after split points are known.
-- This allows `eval-on-split` to re-evaluate row colors at page breaks.
--
-- Typeset a single table row and return a horizontal list (hlist).
---@param tr_contents table Row contents
---@param current_row integer Current row index
---@param skiptable table Table of skipped cells
---@param rowheightarea table Table of row heights
---@return Node? row Horizontal list for the row (nil if no cell could be packed).
function tabular:typeset_row(tr_contents, current_row, skiptable, rowheightarea)
    local current_column
    local current_column_width, ht
    local row = {}
    -- Collects background colors per cell (indexed by cell position).
    -- Stored on the row hbox after packing, applied later by apply_deferred_backgrounds().
    local deferred_bgcolors = {}
    -- Set to false if any cell has colspan > 1 or rowspan > 1, which
    -- prevents row-level background optimization.
    local row_bg_simple = true
    local rowspan, colspan
    local v, vlist, hlist
    local fill = { width = 0, stretch = 2 ^ 16, stretch_order = 3 }
    local td_contents
    current_column = 0
    for _, td in ipairs(tr_contents) do
        current_column = current_column + 1

        td_contents = publisher.xml_helpers.element_contents(td)
        if td_contents == nil then
            main.log("error", "td_contents is empty (nil)")
            return publisher.page_helpers.emergency_block()
        end
        rowspan = tonumber(td_contents.rowspan) or 1
        colspan = resolve_colspan(td_contents.colspan, current_column, self.total_columns)
        if rowspan > 1 or colspan > 1 then
            row_bg_simple = false
        end

        -- FIXME: am I sure that I am in the corerct column?  (colspan...)?
        local td_borderleft = td_contents.td_borderleft_calculated or tex.sp(td_contents["border-left"] or 0)
        local td_borderright = td_contents.td_borderright_calculated or tex.sp(td_contents["border-right"] or 0)
        local td_bordertop = td_contents.td_bordertop_calculated or tex.sp(td_contents["border-top"] or 0) or 0
        local td_borderbottom = td_contents.td_borderbottom_calculated or tex.sp(td_contents["border-bottom"] or 0) or 0
        local padding_left = td_contents.padding_left or self.padding_left_col[current_column] or self.padding_left
        local padding_right = td_contents.padding_right or self.padding_right_col[current_column] or self.padding_right
        local padding_top = td_contents.padding_top or self.padding_top
        local padding_bottom = td_contents.padding_bottom or self.padding_bottom

        -- when we are on a skip-cell (because of a rowspan), we need to create an empty hbox
        while skiptable[current_row] and skiptable[current_row][current_column] do
            v = publisher.nodes.create_empty_hbox_with_width(self.colwidths[current_column])
            v = publisher.nodes.add_glue(v, "head", fill) -- otherwise we'd get an underfull box
            row[current_column] = node.vpack(v, rowheightarea[current_row], "exactly")
            current_column = current_column + 1
        end
        -- alignments of a colspan cell come from its first column
        local thiscolumn = current_column

        current_column_width = 0
        for s = current_column, current_column + colspan - 1 do
            if self.colwidths[s] == nil then
                main.log("error", "Something went wrong with the number of columns in the table (typeset_row)")
            else
                current_column_width = current_column_width + self.colwidths[s]
            end
        end

        current_column_width = current_column_width + (colspan - 1) * self.colsep
        current_column = current_column + colspan - 1
        if rowspan > 1 then
            ht = td_contents.rowspan_internal.sum_ht
        else
            ht = rowheightarea[current_row]
        end

        local g = set_glue(nil, { width = padding_top })
        publisher.attribute_helpers.setprop(g, "origin", "padding_top")

        local valign = td_contents.valign or tr_contents.valign or self.valign[thiscolumn]
        if valign ~= "top" then
            set_glue_values(g, { stretch = 2 ^ 16, stretch_order = 2 })
        end

        local cell_start = g
        local current

        local cell
        -- td_contents.cell can be nil if we have dynamic table head and foot
        if td_contents.cell then
            cell = td_contents.cell.head
            td_contents.cell.head = nil
            node.free(td_contents.cell)
        else
            local alignment = td_contents.align or tr_contents.align or self.align[thiscolumn]
            cell = self:pack_cell(
                td_contents.objects,
                current_column_width - padding_left - padding_right - td_borderleft - td_borderright,
                alignment
            )
            if not cell then
                return
            end
        end

        -- PDF/UA role for Td is set below on the outermost vpack (after borders/padding)
        local td_role_num, td_role_id
        if publisher.options.format == "PDF/UA" then
            if td_contents.role then
                td_role_num = publisher.structure_tree.get_rolenum(td_contents.role)
                td_role_id = td_contents.role .. "_" .. tostring(publisher.rolecounter)
                publisher.rolecounter = publisher.rolecounter + 1
            end
        end
        -- The cell is a vlist with minimum height. We need to repack the contents of the
        -- cell in order to use the aligns and VSpaces in the table cell

        local tail = node.tail(cell_start)
        tail.next = cell
        cell.prev = tail

        g = set_glue(nil, { width = padding_bottom })
        publisher.attribute_helpers.setprop(g, "origin", "align_padding")

        valign = td_contents.valign or tr_contents.valign or self.valign[thiscolumn]
        if valign ~= "bottom" then
            set_glue_values(g, { stretch = 2 ^ 16, stretch_order = 2 })
        end

        node.insert_after(cell_start, node.tail(cell_start), g)

        vlist = node.vpack(cell_start, ht - td_bordertop - td_borderbottom, "exactly")
        -- The table cell now looks like this
        --
        -- ![Table cell vertical](../img/tablecell1.svg)
        --
        -- Now we need to add the left and the right glue
        g = set_glue(nil, { width = padding_left })
        publisher.attribute_helpers.setprop(g, "origin", "padding_left")

        cell_start = g
        local ht_border = 0
        rowspan = td_contents.rowspan or 1
        for i = 1, rowspan do
            ht_border = ht_border + rowheightarea[current_row + i - 1] + self.rowsep
        end
        ht_border = ht_border - td_bordertop - td_borderbottom - self.rowsep

        if td_borderleft ~= 0 then
            local start = publisher.drawing.colorbar(
                td_borderleft,
                ht_border,
                0,
                td_contents["border-left-color"],
                "borderleft",
                "vertical"
            )
            local stop = node.tail(start)
            stop.next = g
            cell_start = start
        end

        current = node.tail(cell_start)
        current.next = vlist
        current = vlist

        g = set_glue(nil, { width = padding_right })
        publisher.attribute_helpers.setprop(g, "origin", "padding_right")

        current.next = g
        if td_borderright ~= 0 then
            local rule = publisher.drawing.colorbar(
                td_borderright,
                ht_border,
                0,
                td_contents["border-right-color"],
                "borderright",
                "vertical"
            )
            g.next = rule
        end

        hlist = node.hpack(cell_start, current_column_width, "exactly")
        -- The cell is now almost complete. Resolve the background color but do NOT
        -- apply it yet — store it in deferred_bg_color for later application.
        --
        -- ![Table cell vertical](../img/tablecell2.svg)
        local deferred_bg_color
        if
            tr_contents.backgroundcolor
            or td_contents.backgroundcolor
            or self.backgroundcolumncolors[current_column]
        then
            -- prio: Td.backgroundcolor, then Tr.backgroundcolor, then Column.backgroundcolor
            local color = self.backgroundcolumncolors[current_column]
            if tr_contents.backgroundcolor and tr_contents.backgroundcolor ~= "-" then
                color = tr_contents.backgroundcolor
            end
            if tr_contents.backgroundcolor == "-" then
                color = nil
            end
            if td_contents.backgroundcolor and td_contents.backgroundcolor ~= "-" then
                color = td_contents.backgroundcolor
            end
            if td_contents.backgroundcolor == "-" then
                color = nil
            end
            if color and color ~= "-" then
                deferred_bg_color = color
            end
        end

        local bg = td_contents["background-text"]
        if bg then
            local bgcolor = td_contents["background-textcolor"] or "black"
            local angle = td_contents["background-angle"] or 0
            local bgsize = td_contents["background-size"] or "contain"
            local fontname = td_contents["background-font-family"]
            local ff = publisher.fonts.lookup_fontfamily_name_number[fontname]
            hlist = publisher.drawing.bgtext(hlist, bg, angle, bgcolor, ff or self.fontfamily, bgsize)
        end

        if td_contents.graphic then
            local _, gfx = metapost.prepareboxgraphic(hlist.width, hlist.height, td_contents.graphic)
            if gfx then
                local x = node.hpack(gfx)
                x.width = 0
                x.height = 0
                hlist = node.insert_before(hlist, hlist, x)
                hlist = node.hpack(hlist)
            end
        end

        -- Store the resolved color indexed by cell position. The background will
        -- be materialized as a pdf_literal by apply_deferred_backgrounds() after
        -- page-split points have been determined. Using #row + 1 because the cell
        -- vbox hasn't been appended to row[] yet at this point.
        if deferred_bg_color then
            deferred_bgcolors[#row + 1] = deferred_bg_color
        end

        ---@type Node
        local head = hlist
        if td_bordertop > 0 then
            local rule = publisher.drawing.colorbar(
                current_column_width,
                td_bordertop,
                0,
                td_contents["border-top-color"],
                "border top",
                "horizontal"
            )
            -- rule is: whatsit, rule, whatsit
            node.tail(rule).next = hlist
            head = rule
        end

        if td_borderbottom > 0 then
            local rule = publisher.drawing.colorbar(
                current_column_width,
                td_borderbottom,
                0,
                td_contents["border-bottom-color"],
                "border bottom",
                "horizontal"
            )
            hlist.next = rule
        end

        -- What is this for?
        local gl = set_glue(nil, { width = 0, shrink = 2 ^ 16, shrink_order = 2 })
        publisher.attribute_helpers.setprop(gl, "origin", "unknown")
        node.slide(head).next = gl

        -- This is our table cell now:
        --
        -- ![Table cell vertical](../img/tablecell3.svg)
        hlist = node.vpack(head, rowheightarea[current_row], "exactly")

        if publisher.options.showobjects then
            publisher.drawing.boxit(hlist)
        end

        if td_role_num then
            node.set_attribute(hlist, publisher.att_role, td_role_num)
            publisher.attribute_helpers.setprop(hlist, "role", td_role_num)
            publisher.attribute_helpers.setprop(hlist, "id", td_role_id)
            publisher.attribute_helpers.setprop(hlist, "parentid", td_contents.parent)
        end

        row[#row + 1] = hlist
    end -- stop td

    if current_column == 0 then
        v = publisher.nodes.create_empty_hbox_with_width(self.tablewidth_target)
        v = publisher.nodes.add_glue(v, "head", fill, "empty") -- otherwise we get an underfull vbox
        row[1] = node.vpack(v, rowheightarea[current_row], "exactly")
    end

    -- We now add colsep and connect the cells so we have a list of vboxes and
    -- pack them in a hbox.
    -- ![a row](../img/tablerow.svg)
    local cell_start, current
    cell_start = row[1]
    current = cell_start
    if row[1] then
        for z = 2, #row do
            _, current = publisher.nodes.add_glue(current, "tail", { width = self.colsep }, "colsep")
            if row[z] then
                current.next = row[z]
                current = row[z]
            end
        end
        row = node.hpack(cell_start)
        publisher.attribute_helpers.setprop(row, "origin", "row")
        -- Attach deferred background colors to the row hbox. Stored here (top-level
        -- node) rather than on inner cell hlists because node.copy_list() only
        -- preserves properties on directly copied nodes, not on deeply nested children.
        if next(deferred_bgcolors) then
            publisher.attribute_helpers.setprop(row, "deferred_bgcolors", deferred_bgcolors)
            -- Row-level background is only safe when there is no column distance
            -- and no colspan/rowspan in this row.
            if row_bg_simple and self.colsep == 0 then
                publisher.attribute_helpers.setprop(row, "row_bg_simple", true)
            end
        end
    else
        main.log("error", "(Internal error) Table is not complete.")
    end
    node.set_attribute(row, publisher.att_tr_shift_up, tr_contents.shiftup)
    node.set_attribute(row, publisher.att_use_as_head, tr_contents.sethead)
    return row
end

-- Gets called for each <Tablehead> element. second_run is for dynamic table head
-- Build the table head structure for typesetting.
---@param tr_contents table Table head contents
---@param tablehead_first table Table for first page head
---@param tablehead table Table for subsequent page heads
---@param current_row integer Current row index
---@param second_run? boolean True if this is the second run
function tabular:make_tablehead(tr_contents, tablehead_first, tablehead, current_row, second_run)
    local current_tablehead_type
    if tr_contents.page == "first" then
        current_tablehead_type = tablehead_first
        if second_run ~= true then
            self.tablehead_first_contents = { tr_contents, current_row }
        end
    else
        current_tablehead_type = tablehead
        if second_run ~= true then
            self.tablehead_contents = { tr_contents, current_row }
        end
    end

    local tablearea = "tablehead" .. (tr_contents.page or "")

    for _, row in ipairs(tr_contents) do
        local row_contents = publisher.xml_helpers.element_contents(row)
        local row_elementname = publisher.xml_helpers.elementname(row)
        if row_elementname == "Tr" then
            current_row = current_row + 1
            current_tablehead_type[#current_tablehead_type + 1] = self:typeset_row(
                row_contents,
                current_row,
                self.skiptables[tablearea] or {},
                self.rowheights[tablearea]
            )
        elseif row_elementname == "Tablerule" then
            local tmp = publisher.drawing.colorbar(
                self.tablewidth_target,
                tex.sp(row_contents.rulewidth or "0.25pt") or 0,
                0,
                row_contents.color,
                "tablerule",
                "horizontal"
            )
            tmp = node.hpack(tmp)
            publisher.attribute_helpers.setprop(tmp, "origin", "tablerule tablehead")
            current_tablehead_type[#current_tablehead_type + 1] = tmp
        end
    end
    if #current_tablehead_type == 0 then
        table.insert(current_tablehead_type, node.new("hlist"))
    end
    if self.rowsep ~= 0 then
        publisher.nodes.add_glue(
            current_tablehead_type[#current_tablehead_type],
            "tail",
            { width = self.rowsep },
            "rowsep"
        )
    end

    return current_row
end

-- second run is for dynamic table foot
-- Build the table foot structure for typesetting.
---@param tr_contents table Table foot contents
---@param tablefoot_last table Table for last page foot
---@param tablefoot table Table for other page foots
---@param current_row integer Current row index
---@param second_run? boolean True if this is the second run
function tabular:make_tablefoot(tr_contents, tablefoot_last, tablefoot, current_row, second_run)
    local current_tablefoot_type
    if tr_contents.page == "last" then
        current_tablefoot_type = tablefoot_last
        if second_run ~= true then
            self.tablefoot_last_contents = { tr_contents, current_row }
        end
    else
        current_tablefoot_type = tablefoot
        if second_run ~= true then
            self.tablefoot_contents = { tr_contents, current_row }
        end
    end
    for _, row in ipairs(tr_contents) do
        local row_contents = publisher.xml_helpers.element_contents(row)
        local row_elementname = publisher.xml_helpers.elementname(row)

        local tablearea = "tablefoot" .. (tr_contents.page or "")
        if row_elementname == "Tr" then
            current_row = current_row + 1
            current_tablefoot_type[#current_tablefoot_type + 1] = self:typeset_row(
                row_contents,
                current_row,
                self.skiptables[tablearea] or {},
                self.rowheights[tablearea]
            )
        elseif row_elementname == "Tablerule" then
            local tmp = publisher.drawing.colorbar(
                self.tablewidth_target,
                tex.sp(row_contents.rulewidth or "0.25pt") or 0,
                0,
                row_contents.color,
                "tablerule",
                "horizontal"
            )
            tmp = node.hpack(tmp)
            publisher.attribute_helpers.setprop(tmp, "origin", "tablerule_make_tablefoot")
            current_tablefoot_type[#current_tablefoot_type + 1] = tmp
        end
    end
    if #current_tablefoot_type == 0 then
        table.insert(current_tablefoot_type, node.new("hlist"))
    end

    return current_row
end
--------------------------------------------------------------------------

-- Calculate height and connect table head rows.
---@param tablehead_first table Table for first page head
---@param tablehead table Table for subsequent page heads
function tabular:connect_tablehead_first_all(tablehead_first, tablehead)
    -- We connect all but the last row with the next row and remember the height in ht_header
    for z = 1, #tablehead_first - 1 do
        local _, tmp = publisher.nodes.add_glue(tablehead_first[z], "tail", { width = self.rowsep }, "rowsep tablehead")
        tmp.next = tablehead_first[z + 1]
        tablehead_first[z + 1].prev = tmp
    end

    for z = 1, #tablehead - 1 do
        local _, tmp = publisher.nodes.add_glue(tablehead[z], "tail", { width = self.rowsep }, "rowsep tablehead (2)")
        tmp.next = tablehead[z + 1]
        tablehead[z + 1].prev = tmp
    end
end

-- Calculate height and connect table foot rows.
---@param tablefoot table Table for other page foots
---@param tablefoot_last table Table for last page foot
---@return number Height of table foot for other pages
---@return number Height of table foot for last page
function tabular:calculate_height_and_connect_tablefoot(tablefoot, tablefoot_last)
    local ht_footer, ht_footer_last = 0, 0
    for z = 1, #tablefoot - 1 do
        ht_footer = ht_footer + tablefoot[z].height -- Tr or Tablerule
        -- if we have a rowsep then add glue. Todo: make a if/then/else conditional
        local _, tmp = publisher.nodes.add_glue(tablefoot[z], "tail", { width = self.rowsep }, "rowsep tablefoot (1)")
        tmp.next = tablefoot[z + 1]
        tablefoot[z + 1].prev = tmp
    end

    for z = 1, #tablefoot_last - 1 do
        ht_footer_last = ht_footer_last + tablefoot_last[z].height -- Tr or Tablerule
        -- if we have a rowsep then add glue. Todo: make a if/then/else conditional
        local _, tmp =
            publisher.nodes.add_glue(tablefoot_last[z], "tail", { width = self.rowsep }, "rowsep tablefoot (2)")
        tmp.next = tablefoot_last[z + 1]
        tablefoot_last[z + 1].prev = tmp
    end

    if #tablefoot > 0 then
        ht_footer = ht_footer + tablefoot[#tablefoot].height + #tablefoot * self.rowsep
    end

    if #tablefoot_last > 0 then
        ht_footer_last = ht_footer_last + tablefoot_last[#tablefoot_last].height + #tablefoot_last * self.rowsep
    else
        ht_footer_last = ht_footer
    end
    return ht_footer, ht_footer_last
end

-- This is called for Td/sethead=yes for the copies
-- of the first head. It removes the pdf_dest nodes for bookmark destinations.
-- Recursively removes `pdf_dest` whatsit nodes from a node list. Used
-- before re-typesetting head/foot rows so destinations are not duplicated.
---@param nodelist Node
---@return Node? nodelist The (possibly trimmed) node list, or `nil` when fully removed.
local function remove_bookmark_nodes(nodelist)
    local head = nodelist
    while head do
        if head.id == publisher.hlist_node or head.id == publisher.vlist_node then
            head.list = remove_bookmark_nodes(head.list)
        elseif head.id == publisher.whatsit_node and head.subtype == publisher.pdf_dest_whatsit then
            node.flush_list(head)
            return nil
        end
        head = head.next
    end
    return nodelist
end

-- Apply deferred background colors to all cells in a linked node list.
-- Called after split points are known and all entries (head, body rows, foot)
-- have been connected into a single linked list.
--
-- The node structure at this point:
--
--     linked list (head → glue → row_hbox → glue → row_hbox → ... → foot)
--                                  │
--                            row_hbox.list
--                       ┌────────┼────────────┐
--                    vbox(cell1) glue(colsep) vbox(cell2) ...
--                       │
--                  cell vbox.list
--            ┌──────────┼───────────┐
--     hlist(border-top) hlist(content) hlist(border-bottom)
--       origin="border top"  origin=nil   origin="border bottom"
--
-- For each row hbox with a "deferred_bgcolors" property, we apply the
-- background colors. When all cells share the same color AND the row
-- is simple (no columndistance, no colspan/rowspan), a single background
-- rectangle is drawn on the row hbox — this avoids hairline rendering
-- artifacts between adjacent cells in some PDF viewers. Otherwise,
-- each cell gets its own background on its content hlist (identified
-- by having no "origin" property).
---@param head Node Linked list of typeset row hboxes.
---@return nil
local function apply_deferred_backgrounds(head)
    local n = head
    while n do
        if node.type(n.id) == "hlist" then
            local bgcolors = publisher.attribute_helpers.getprop(n, "deferred_bgcolors")
            if bgcolors then
                local use_row_bg = false

                -- Row-level background: only for simple rows (no colsep,
                -- no colspan/rowspan) where all cells share the same color
                if publisher.attribute_helpers.getprop(n, "row_bg_simple") then
                    local cell_count = 0
                    local uniform_color = nil
                    local all_same = true
                    local cell = n.list
                    while cell do
                        if node.type(cell.id) == "vlist" then
                            cell_count = cell_count + 1
                            local c = bgcolors[cell_count]
                            if c == nil then
                                all_same = false
                            elseif uniform_color == nil then
                                uniform_color = c
                            elseif c ~= uniform_color then
                                all_same = false
                            end
                        end
                        cell = cell.next
                    end
                    if all_same and uniform_color and cell_count > 0 then
                        publisher.drawing.background(n, uniform_color)
                        use_row_bg = true
                    end
                end

                if not use_row_bg then
                    -- Per-cell backgrounds
                    local cell = n.list
                    local cell_idx = 0
                    while cell do
                        if node.type(cell.id) == "vlist" then
                            cell_idx = cell_idx + 1
                            local bgcolor = bgcolors[cell_idx]
                            if bgcolor then
                                local inner = cell.list
                                while inner do
                                    if node.type(inner.id) == "hlist" then
                                        local origin = publisher.attribute_helpers.getprop(inner, "origin")
                                        if origin == nil then
                                            publisher.drawing.background(inner, bgcolor)
                                            break
                                        end
                                    end
                                    inner = inner.next
                                end
                            end
                        end
                        cell = cell.next
                    end
                end
            end
        end
        n = n.next
    end
end

---@class SplitTableResult: VlistNode[] One vlist per part of a split table.
---@field balance? boolean Balance the parts over all frames (set in commands.table).
---@field break_pagetype? string Page type for the extra page between two parts (set in commands.table).

-- Typeset the entire table, including head, body, and foot.
---@param dataxml table XML data for the table
---@return Node|SplitTableResult
function tabular:typeset_table(dataxml)
    local current_row
    local tablehead_first = {}
    local tablehead = {}
    local tablefoot_last = {}
    local tablefoot = {}
    -- omit_head_on_pages is for dynamic headers (2)
    local omit_head_on_pages = {}
    local rows = {}
    local break_above = true
    local filter = {}
    ---@type number
    local startpage = publisher.current_pagenumber
    local tablepart_absolute = 1

    -- Track which rows-array indices are inside an active rowspan (from above).
    -- Used in calculate_splits() to prevent page breaks inside rowspans.
    local row_in_rowspan = {}

    current_row = 0
    for _, tr in ipairs(self.tab) do
        local tr_contents = publisher.xml_helpers.element_contents(tr)
        local eltname = publisher.xml_helpers.elementname(tr)
        local tmp
        -- If this row is allowed to break above
        -- Will be set to false if break_below is "no"

        if eltname == "Columns" then
            -- ignore
        elseif eltname == "Tablerule" then
            local offset = 0
            if tr_contents.start and tr_contents.start ~= 1 then
                local sum = 0
                for i = 1, tr_contents.start - 1 do
                    sum = sum + self.colwidths[i]
                end
                offset = sum
            end
            tmp = publisher.drawing.colorbar(
                self.tablewidth_target - offset,
                tex.sp(tr_contents.rulewidth or "0.25pt") or 0,
                0,
                tr_contents.color,
                "tablerule",
                "horizontal"
            )
            tmp = publisher.nodes.add_glue(tmp, "head", { width = offset }, "offset tablerule")
            tmp = node.hpack(tmp)
            publisher.attribute_helpers.setprop(tmp, "origin", "tablerule")
            rows[#rows + 1] = tmp
            if break_above == false then
                if publisher.options.showobjects then
                    rows[#rows] = publisher.drawing.addhrule(rows[#rows])
                end
                node.set_attribute(rows[#rows], publisher.att_break_above, 1)
                break_above = true
            end
            if tr_contents.breakbelow == false then
                break_above = false
            end
        elseif eltname == "Tablehead" then
            self:make_tablehead(tr_contents, tablehead_first, tablehead, current_row)
            if tr_contents.page == "first" then
                filter.tablehead_force_first = true
            elseif tr_contents.page == "odd" or tr_contents.page == "even" then
                filter.tablehead = tr_contents.page
            elseif tr_contents.page == "all" then
                filter.tablehead = "none"
            end
        elseif eltname == "Tablefoot" then
            self:make_tablefoot(tr_contents, tablefoot_last, tablefoot, 0)
        elseif eltname == "Tr" then
            current_row = current_row + 1
            rows[#rows + 1] = self:typeset_row(tr_contents, current_row, self.skiptables.body, self.rowheights.body)
            -- Mark if this row is inside a rowspan from a previous row
            local skip_row = self.skiptables.body[current_row]
            if skip_row then
                for _, v in pairs(skip_row) do
                    if v then
                        row_in_rowspan[#rows] = true
                        break
                    end
                end
            end
            -- We allow data to be attached to a table row.
            local thisrow = rows[#rows]
            publisher.attribute_helpers.setprop(thisrow, "origin", "tr")
            local tr_layoutxml_origin, tr_dataxml_origin = tabular.get_origin(tr_contents)
            if tr_layoutxml_origin then
                publisher.attribute_helpers.setprop(thisrow, "tr_layoutxml", tr_layoutxml_origin)
                publisher.attribute_helpers.setprop(thisrow, "tr_dataxml", tr_dataxml_origin)
            end
            if publisher.options.format == "PDF/UA" and tr_contents.role then
                local rn = publisher.structure_tree.get_rolenum(tr_contents.role)
                local id = tr_contents.role .. "_" .. tostring(publisher.rolecounter)
                node.set_attribute(thisrow, publisher.att_role, rn)
                publisher.attribute_helpers.setprop(thisrow, "role", rn)
                publisher.attribute_helpers.setprop(thisrow, "id", id)
                publisher.attribute_helpers.setprop(thisrow, "rolecounter", publisher.rolecounter)
                publisher.rolecounter = publisher.rolecounter + 1
                publisher.attribute_helpers.setprop(thisrow, "parentid", tr_contents.parent)
                publisher.attribute_helpers.setprop(thisrow, "actualtext", tr_contents.actualtext)
                publisher.attribute_helpers.setprop(thisrow, "alttext", tr_contents.alttext)
            end
            if tr_contents.data then
                dynamic_data[#dynamic_data + 1] = tr_contents.data
                node.set_attribute(rows[#rows], publisher.att_tr_dynamic_data, #dynamic_data)
            end
            node.set_attribute(rows[#rows], publisher.att_is_table_row, 1)

            if break_above == false then
                if publisher.options.showobjects then
                    rows[#rows] = publisher.drawing.addhrule(rows[#rows])
                end
                node.set_attribute(rows[#rows], publisher.att_break_above, 1)
                break_above = true
            end

            if tr_contents["top-distance"] ~= 0 then
                node.set_attribute(rows[#rows], publisher.att_space_amount, tr_contents["top-distance"])
            end
            if tr_contents["break-below"] == "no" then
                node.set_attribute(rows[#rows], publisher.att_break_below_forbidden, 1)
                break_above = false
            end
        elseif eltname == "TableNewPage" then
            if publisher.current_group == nil then
                local tf = node.new("hlist")
                node.set_attribute(tf, publisher.att_tablenewpage, 1)
                rows[#rows + 1] = tf
            else
                main.log("warn", "TableNewPage does not work in Group")
            end
        else
            main.log("warn", string.format("Unknown contents in “Table” %s", eltname or "?"))
        end -- if it's a table cell
    end

    if #rows == 0 and not tablehead[1] and not tablefoot[1] then
        main.log("warn", "table without contents")
        return publisher.page_helpers.empty_block()
    end

    -- I used to have a metatable with __index here, but this gives a stack overflow
    -- for large indexes
    local tableheads_extra = {
        largest_index = 0,
    }
    local function get_tableheads_extra(idx, maxrow)
        idx = idx - 1
        if idx < 1 then
            return nil
        end
        local maxidx = tableheads_extra.largest_index
        local id = math.min(idx, maxidx)
        if tableheads_extra[id] ~= nil then
            local subidx = #tableheads_extra[id]
            if maxrow == nil then
                return tableheads_extra[id][subidx].nodelist
            end
            local entry
            while subidx > 0 do
                entry = tableheads_extra[id][subidx]
                if entry.rownumber <= maxrow then
                    return entry.nodelist
                end
                subidx = subidx - 1
            end
            return get_tableheads_extra(id, maxrow)
        end
        if idx == 1 then
            return nil
        end
        return get_tableheads_extra(idx)
    end

    local function set_tableheads_extra(idx, nodelist, rownumber)
        -- nodelist is a copied list, but the pdf_dest whatsits must not
        -- go into the output.
        remove_bookmark_nodes(nodelist)
        tableheads_extra.largest_index = math.max(tableheads_extra.largest_index, idx)
        tableheads_extra[idx] = tableheads_extra[idx] or {}
        tableheads_extra[idx][#tableheads_extra[idx] + 1] = { nodelist = nodelist, rownumber = rownumber }
    end

    self:connect_tablehead_first_all(tablehead_first, tablehead)
    local ht_footer, ht_footer_last = self:calculate_height_and_connect_tablefoot(tablefoot, tablefoot_last)

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

    local ht_current = self.options.current_height or self.options.ht_max
    local ht_max = self.options.ht_max
    -- The maximum heights are saved here for each table. Currently all tables must have the same height (see the metatable)
    local pagegoals = {}

    -- Return a boolean if we need to show the static header on this page
    local function showheader_static()
        if tablepart_absolute == 1 and filter.tablehead_force_first then
            return true
        end
        if filter.tablehead == nil then
            return false
        end
        if filter.tablehead == "none" then
            return true
        end
        if math.fmod(tablepart_absolute, 2) == math.fmod(startpage, 2) then
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

    -- Return a boolean if we need to show the dynamic header on this page
    local function showheader(tablepart, rowmax)
        -- We can skip the dynamic header on pages where the first line is the next dynamic header
        if omit_head_on_pages[tablepart] then
            return false
        end

        if get_tableheads_extra(tablepart_absolute, rowmax) ~= nil then
            return true
        end
        return false
    end

    -- Table splitting
    -- ===============
    -- Table splitting is done in several steps and we need helper functions to generate the dynamic headers
    -- and to get the height of these headers
    local function get_height_header(i)
        local ht = 0
        if showheader_static() then
            if i == 1 then
                local x = node.vpack(tablehead_first[1])
                ht = x.height
            else
                local x = node.vpack(tablehead[1])
                ht = x.height
            end
        end
        if showheader(i) then
            ht = ht + get_tableheads_extra(i).height + self.rowsep
        end
        return ht
    end

    local maxpages = 0

    setmetatable(pagegoals, {
        __index = function(_, idx)
            local footerheight = ht_footer
            if idx == maxpages then
                footerheight = ht_footer_last
            end
            local ht_head = get_height_header(idx)
            local val
            if idx == 1 then
                val = ht_current - ht_head - footerheight
                return val
            elseif idx == -1 then
                val = ht_current - ht_head - footerheight
                return val
            else
                if self.getheight then
                    -- self.getheight is a function which expects a relative
                    -- page number (1 = first page of table, 2 = second page of table...)
                    -- The function might return nil, if it doesn't have enough information
                    -- to obtain the max height
                    local ht = self.getheight(idx, self.dataxml)
                    if ht then
                        val = ht - ht_head - footerheight
                        return val
                    end
                end
                val = ht_max - ht_head - footerheight
            end
            return val
        end,
    })

    local function get_tablehead(page, maxrow)
        local nl = get_tableheads_extra(page, maxrow)
        if nl then
            return node.copy_list(nl)
        end
        local tmp = node.new("hlist")
        return tmp
    end

    local function get_tablehead_static(page)
        if page == 1 then
            return tablehead_first[1]
        end
        return node.copy_list(tablehead[1])
    end

    -- When we split the current table we return an array:
    local final_split_tables = {}
    local pagegoal = 0

    local ht_row, space_above
    -- splits is a table which includes the number of the rows each page has in a multi-page table
    --
    --     splits = {
    --       [1] = "0"
    --       [2] = "26"
    --       [3] = "44"
    --     }

    local splits

    local function calculate_splits()
        local current_page = 1
        local last_possible_split_is_after_line = 0
        local accumulated_height = 0
        local extra_height = 0

        local att_break_above

        splits = { 0 }
        for i = 1, #rows do
            -- We can mark a row as "use_as_head" to turn the row into a dynamic head
            local use_as_head = node.has_attribute(rows[i], publisher.att_use_as_head)
            if use_as_head == 1 then
                set_tableheads_extra(#splits, node.copy(rows[i]), i)
            elseif use_as_head == 2 then
                set_tableheads_extra(#splits, publisher.nodes.create_empty_hbox_with_width(1), i)
            end
            local shiftup = node.has_attribute(rows[i], publisher.att_tr_shift_up) or 0
            if shiftup > 0 then
                rows[i].height = rows[i].height - shiftup
            end
            pagegoal = pagegoals[current_page]
            ht_row = rows[i].height + rows[i].depth
            att_break_above = node.has_attribute(rows[i], publisher.att_break_above) or -1
            space_above = node.has_attribute(rows[i], publisher.att_space_amount) or 0

            local break_above_allowed = att_break_above ~= 1

            -- Do not allow page breaks inside active rowspans
            if break_above_allowed and row_in_rowspan[i] then
                break_above_allowed = false
            end

            if break_above_allowed then
                last_possible_split_is_after_line = i - 1
                accumulated_height = accumulated_height + extra_height
                extra_height = 0
            end
            extra_height = extra_height + ht_row

            -- This should be turned on with a separate switch in trace
            -- if publisher.options.showobjects then
            --     local ht = tostring(sp_to_pt(ht_row)) .. "|" .. tostring(sp_to_pt(accumulated_height)) .. "|" .. tostring(sp_to_pt(extra_height))
            --     rows[i] = publisher.showtextatright(rows[i],ht)
            -- end
            local tablenewpage = node.has_attribute(rows[i], publisher.att_tablenewpage)

            local fits_in_table = accumulated_height + extra_height + space_above <= pagegoal
            if tablenewpage or not fits_in_table then
                if node.has_attribute(rows[i], publisher.att_use_as_head) == 1 then
                    -- the next line would be used as a header, so let's skip the
                    -- header on this page
                    omit_head_on_pages[#splits + 1] = true
                end

                if shiftup > 0 then
                    rows[i].height = rows[i].height + shiftup
                end
                -- ==0 can happen when there's not enough room for table head + first line
                if last_possible_split_is_after_line ~= 0 then
                    if
                        node.has_attribute(rows[last_possible_split_is_after_line + 1], publisher.att_use_as_head) == 1
                    then
                        omit_head_on_pages[#splits + 1] = true
                    end
                    splits[#splits + 1] = last_possible_split_is_after_line
                    tablepart_absolute = tablepart_absolute + 1
                else
                    startpage = startpage + 1
                end
                accumulated_height = ht_row
                extra_height = self.rowsep + extra_height - ht_row
                current_page = current_page + 1
            else
                -- if it is not the first row in a table,
                -- add space_above
                if i ~= splits[#splits] + 1 then
                    extra_height = extra_height + space_above
                end
            end
            extra_height = extra_height + self.rowsep
        end
    end

    calculate_splits()
    -- If there is a longer last footer than the other footers, we need to re-calculate
    -- the splitting. The last table foot can be too high. See #268.
    if ht_footer_last > 0 and ht_footer_last > ht_footer then
        maxpages = #splits
        tablepart_absolute = 1
        startpage = publisher.current_pagenumber
        calculate_splits()
    end

    -- This is the last split
    splits[#splits + 1] = #rows

    -- Table balancing
    -- ===============
    -- When the user has requested table balancing, we need to find out how many frames
    -- the table spans. If there is only one frame, no balancing has to be done.
    -- If there are more frames, we need to find out the “empty” frames.

    -- tosplit is the total number of frames on the last page (used or unused)
    local tosplit = self.split

    -- tosplit > 1 ==> needs balancing (otherwise only one frame or no splitting)
    if tosplit > 1 then
        -- used_frames is the number of frames used by the table w/o split.
        local used_frames = (#splits - 1) % tosplit
        -- This can be 0 (all columns used).
        -- So the number is set to the amount of tosplit in order to balance all columns.
        if used_frames == 0 then
            used_frames = tosplit
        end

        -- Now that we know the #frames to be split, we can count the lines.
        -- Remember: the split table looks like this:
        --     splits = {
        --       [1] = "0"
        --       [2] = "26"
        --       [3] = "44"
        --     }
        -- Where 44 is the total number of rows. This has to be the last entry in the splits table.
        -- Each entry means that there is a split after that line. So in the example above,
        -- line 26 is in the first frame, 27 to 44 in the last frame.
        local last_possible_split_is_after_line_t = {}
        -- first, we remove the split marks for the used frames.
        -- (If we omitted the rest of the balance routine, the resulting table would be empty for that page.)
        for _ = 1, used_frames do
            -- the entry in omit_head_on_pages for this split is not valid anymore
            omit_head_on_pages[#splits] = nil
            table.remove(splits)
        end

        -- first row is needed for height calculation
        local first_row_in_new_table = splits[#splits] + 1

        -- The dynamic header which gets repeated at the top of a frame takes
        -- room from the rows, so its height must be part of the balancing
        -- calculation. See #715.
        -- Return the height of the repeated dynamic header for a frame
        -- (framenumber) that starts with the row firstrow. The height is zero
        -- when there is no dynamic header or when the frame starts with a
        -- header row, because then the repetition is omitted (see “Table
        -- cleanup” below).
        local function get_dynhead_height(framenumber, firstrow)
            if rows[firstrow] and node.has_attribute(rows[firstrow], publisher.att_use_as_head) == 1 then
                return 0
            end
            local nl = get_tableheads_extra(framenumber, firstrow - 1)
            if nl then
                return nl.height + nl.depth
            end
            return 0
        end

        -- Now this is the total height of the remaining rows.
        local sum_ht = 0
        for i = first_row_in_new_table, #rows do
            sum_ht = sum_ht + rows[i].height + rows[i].depth
        end
        -- The height of the rows that are not distributed to a frame yet,
        -- gets decreased row by row in the loop below.
        local rows_remaining = sum_ht

        -- Add the heights of the repeated dynamic headers to the total
        -- height. The header of the first frame is known. The headers of the
        -- following frames depend on the split positions which are not known
        -- yet, so we estimate their height: the first header row within the
        -- remaining rows is the best guess, the header which is active at the
        -- beginning of the remaining rows the second best.
        local ht_dynhead_first = get_dynhead_height(#splits, first_row_in_new_table)
        local ht_dynhead_following = 0
        local nl_active = get_tableheads_extra(#splits + 1, first_row_in_new_table)
        if nl_active then
            ht_dynhead_following = nl_active.height + nl_active.depth
        end
        for i = first_row_in_new_table, #rows do
            local use_as_head = node.has_attribute(rows[i], publisher.att_use_as_head)
            if use_as_head == 1 then
                ht_dynhead_following = rows[i].height + rows[i].depth
                break
            elseif use_as_head == 2 then
                ht_dynhead_following = 0
                break
            end
        end
        sum_ht = sum_ht + ht_dynhead_first + (tosplit - 1) * ht_dynhead_following

        -- percolumn_goal is the optimum height for each column
        local percolumn_goal = math.ceil(sum_ht / tosplit)
        local sum_frame = ht_dynhead_first
        local break_below_allowed
        local maxht = ht_current
        for i = first_row_in_new_table, #rows do
            break_below_allowed = (node.has_attribute(rows[i], publisher.att_break_below_forbidden) ~= 1)
            if break_below_allowed then
                last_possible_split_is_after_line_t[#last_possible_split_is_after_line_t + 1] = i
            end
            local ht_this_row = rows[i].height + rows[i].depth
            sum_frame = sum_frame + ht_this_row
            rows_remaining = rows_remaining - ht_this_row

            if #splits > tosplit then
                -- ht_current must be replaced with ht_max on following pages
                maxht = ht_max
            end
            if sum_frame > maxht then
                splits[#splits + 1] = last_possible_split_is_after_line_t[#last_possible_split_is_after_line_t - 1]
                tosplit = tosplit - 1

                -- When there is more than one column left, we should adjust the percolumn_goal. (should we?)
                if tosplit > 0 then
                    percolumn_goal = percolumn_goal - math.ceil((sum_frame - percolumn_goal) / tosplit)
                end
                sum_frame = get_dynhead_height(#splits, splits[#splits] + 1)
            -- When stepped over the goal, move this line to the next frame.
            -- See #232 for a situation where the second test is necessary.
            elseif
                sum_frame >= percolumn_goal
                and last_possible_split_is_after_line_t[#last_possible_split_is_after_line_t] ~= splits[#splits]
            then
                local lp = last_possible_split_is_after_line_t
                local splitafter = lp[#lp]
                -- carry_ht is the height of the current row when it gets
                -- moved to the next frame.
                local carry_ht = 0
                local do_split = true
                local move = false
                local move_possible = splitafter == i and lp[#lp - 1] == i - 1 and lp[#lp - 1] ~= splits[#splits]
                if tosplit == 2 and splitafter == i and i < #rows then
                    -- The next frame is the last one, so its height is known:
                    -- the remaining rows plus the repeated dynamic header.
                    -- The last frame must not be higher than the frame before
                    -- it. Differences below half a row don't count, they are
                    -- not visible because both frames show the same number of
                    -- rows.
                    local ht_last_keep = get_dynhead_height(#splits + 1, i + 1) + rows_remaining
                    if ht_last_keep > sum_frame + ht_this_row / 2 then
                        -- The last frame would be higher than this one, so we
                        -- keep adding rows.
                        do_split = false
                    elseif move_possible then
                        -- Move the current row to the last frame when this
                        -- gives a more even result.
                        local ht_last_move = get_dynhead_height(#splits + 1, i) + ht_this_row + rows_remaining
                        move = math.abs(ht_last_move - (sum_frame - ht_this_row)) < math.abs(ht_last_keep - sum_frame)
                            and ht_last_move <= sum_frame - ht_this_row / 2
                    end
                elseif move_possible and (sum_frame - percolumn_goal) * 2 > ht_this_row then
                    -- Keeping the current row in this frame overshoots the
                    -- goal by sum_frame - percolumn_goal. Moving the row to
                    -- the next frame gives a more even result here.
                    move = true
                end
                if do_split then
                    if move then
                        splitafter = i - 1
                        carry_ht = ht_this_row
                    end
                    splits[#splits + 1] = splitafter
                    tosplit = tosplit - 1
                    sum_frame = sum_frame - carry_ht

                    -- When there is more than one column left, we should adjust the percolumn_goal. (should we?)
                    if tosplit > 0 then
                        percolumn_goal = percolumn_goal - math.ceil((sum_frame - percolumn_goal) / tosplit)
                    end
                    sum_frame = get_dynhead_height(#splits, splits[#splits] + 1) + carry_ht
                end
            end
        end

        -- Add the last row to the splits table, unless by coincidence the
        -- split has already done that.
        if splits[#splits] ~= #rows then
            splits[#splits + 1] = #rows
        end

        -- When the last column has exacly one table rule, this rule
        -- gets moved to the previous column
        if #splits > 1 and splits[#splits] - splits[#splits - 1] == 1 then
            local istablerule = publisher.attribute_helpers.getprop(rows[#rows], "origin") == "tablerule"
            if istablerule then
                splits[#splits - 1] = splits[#splits]
                table.remove(splits)
            end
        end
    end

    -- Table cleanup. This is for dynamic headers which get repeated on the top of
    -- each split. We omit the repetition, if the top entry in a frame is already
    -- a dynamic head.
    for i = 2, #splits - 1 do
        local r = splits[i]
        if rows[r + 1] then
            if node.has_attribute(rows[r + 1], publisher.att_use_as_head) == 1 then
                omit_head_on_pages[i] = true
            end
        else
            -- no head in last column
            omit_head_on_pages[i] = true
        end
    end

    local first_row_in_new_table
    local last_tr_data
    tablepart_absolute = 0
    for s = 2, #splits do
        tablepart_absolute = tablepart_absolute + 1
        if publisher.newxpath then
            dataxml["_last_tr_data"] = nil
        else
            publisher.xpath.set_variable("_last_tr_data", nil)
        end
        first_row_in_new_table = splits[s - 1] + 1

        local thissplittable = {}
        final_split_tables[#final_split_tables + 1] = thissplittable

        -- only reformat head when we have a head
        if last_tr_data and self.tablehead_contents then
            -- we have some data attached to table rows, so we re-format the header
            local val = dynamic_data[last_tr_data]
            if publisher.newxpath then
                dataxml["_last_tr_data"] = val
            else
                publisher.xpath.set_variable("_last_tr_data", val)
            end
            local tmp1, tmp2 = self:reformat_head()
            if s == 2 then
                -- first page
                thissplittable[#thissplittable + 1] = node.copy_list(tmp1)
            else
                -- page > 1
                thissplittable[#thissplittable + 1] = node.copy_list(tmp2)
            end
        else
            if showheader_static() then
                thissplittable[#thissplittable + 1] = get_tablehead_static(s - 1)
            end
            if showheader(s - 1, splits[s]) then
                thissplittable[#thissplittable + 1] = get_tablehead(s - 1, splits[s - 1])
            end
        end

        -- eval-on-split: re-evaluate background colors for page breaks
        -- ─────────────────────────────────────────────────────────────
        -- When the Table attribute eval-on-split is set and this is not the first
        -- split (s > 2), we:
        --   1. Evaluate the eval-on-split XPath expression. This typically calls
        --      sd:reset-alternating() to restart the color cycle.
        --   2. For each body row, re-read the Tr's background-color attribute from
        --      the original layoutxml. Because the alternating counter was just
        --      reset, sd:alternating() now returns the correct color for this
        --      row's position within the new page.
        --   3. Override deferred_bgcolors on the row with the new color, so that
        --      apply_deferred_backgrounds() will use the updated value.
        --
        -- Note: only Tr-level background-color is re-evaluated, not Td-level.
        -- To use eval-on-split with alternating colors, the alternating expression
        -- must be in the Tr background-color attribute (not in Td or SetVariable).
        if s > 2 and self.eval_on_split_layoutxml then
            publisher.attribute_helpers.read_attribute(
                self.eval_on_split_layoutxml,
                self.eval_on_split_dataxml,
                "eval-on-split",
                "xpath"
            )
        end

        for i = first_row_in_new_table, splits[s] do
            if i > first_row_in_new_table then
                space_above = node.has_attribute(rows[i], publisher.att_space_amount) or 0
            else
                space_above = 0
            end
            thissplittable[#thissplittable + 1] = publisher.nodes.make_glue({ width = space_above })
            thissplittable[#thissplittable + 1] = rows[i]

            if s > 2 and self.eval_on_split_layoutxml and node.has_attribute(rows[i], publisher.att_is_table_row) then
                local tr_layoutxml = publisher.attribute_helpers.getprop(rows[i], "tr_layoutxml")
                local tr_dataxml = publisher.attribute_helpers.getprop(rows[i], "tr_dataxml")
                if tr_layoutxml then
                    local new_bgcolor = publisher.attribute_helpers.read_attribute(
                        tr_layoutxml,
                        tr_dataxml,
                        "background-color",
                        "string"
                    ) or publisher.attribute_helpers.read_attribute(
                        tr_layoutxml,
                        tr_dataxml,
                        "backgroundcolor",
                        "string"
                    )
                    if new_bgcolor and new_bgcolor ~= "-" then
                        local bgcolors = {}
                        local cell_idx = 0
                        local cell = rows[i].list
                        while cell do
                            if node.type(cell.id) == "vlist" then
                                cell_idx = cell_idx + 1
                                bgcolors[cell_idx] = new_bgcolor
                            end
                            cell = cell.next
                        end
                        publisher.attribute_helpers.setprop(rows[i], "deferred_bgcolors", bgcolors)
                    end
                end
            end

            -- the last rowsep at the end of a split should be omitted.
            if (i < #rows and i < splits[s]) or self.tablefoot_contents then
                thissplittable[#thissplittable + 1] = publisher.nodes.make_glue({ width = self.rowsep })
            end
        end

        last_tr_data = thissplittable[#thissplittable - 1]
            and node.has_attribute(thissplittable[#thissplittable - 1], publisher.att_tr_dynamic_data)

        -- only reformat the foot when we have dynamic data _and_ have a foot to reformat.
        if last_tr_data and self.tablefoot_contents then
            -- we have some data attached to table rows, so we re-format the footer
            local val = dynamic_data[last_tr_data]
            if publisher.newxpath then
                dataxml.vars["_last_tr_data"] = val
            else
                publisher.xpath.set_variable("_last_tr_data", val)
            end

            local tmp_tablefoot_last, tmp_tablefoot_all = self:reformat_foot(s - 1, #splits - 1)
            if s < #splits then
                thissplittable[#thissplittable + 1] = node.copy_list(tmp_tablefoot_all)
            else
                thissplittable[#thissplittable + 1] = node.copy_list(tmp_tablefoot_last or tmp_tablefoot_all)
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

    -- Final assembly: connect entries and apply deferred backgrounds
    -- ─────────────────────────────────────────────────────────────
    -- Each split table is an array of disconnected nodes (head rows, glue,
    -- body rows, foot rows). We connect them into a single linked list,
    -- then call apply_deferred_backgrounds() to insert the pdf_literal
    -- background rectangles, and finally vpack everything into a vbox.
    local tail
    for i = 1, #final_split_tables do
        for j = 1, #final_split_tables[i] - 1 do
            tail = node.tail(final_split_tables[i][j])
            tail.next = final_split_tables[i][j + 1]
            final_split_tables[i][j + 1].prev = tail
        end
        apply_deferred_backgrounds(final_split_tables[i][1])
        final_split_tables[i] = node.vpack(final_split_tables[i][1])
    end
    for i = 1, #final_split_tables do
        local thissplittable = final_split_tables[i]
        node.set_attribute(thissplittable, publisher.att_dont_format, 1)
    end
    return final_split_tables
end -- typeset table

-- Reformat the table foot for a given page, handling splits.
---@param pagenumber integer Current page number
---@param max_splits integer Maximum number of splits
---@return table Table foot nodes for the first page
---@return table Table foot nodes for other pages
function tabular:reformat_foot(pagenumber, max_splits)
    local rownumber, y
    if pagenumber == max_splits and self.tablefoot_last_contents then
        y = self.tablefoot_last_contents[1]
        rownumber = self.tablefoot_last_contents[2]
    else
        y = self.tablefoot_contents[1]
        rownumber = self.tablefoot_contents[2]
    end
    local y_layoutxml, y_dataxml = tabular.get_origin(y)
    assert(y_layoutxml, "no layout XML origin registered for the table foot")
    assert(y_dataxml, "no data XML origin registered for the table foot")
    local x = publisher.dispatch.dispatch(y_layoutxml, y_dataxml)
    ---@cast x TableheadFootContents
    local page = publisher.attribute_helpers.read_attribute(y_layoutxml, y_dataxml, "page", "string", "all")
    x.page = page
    self:attach_objects(x)
    local tmp_tablefoot_last, tmp_tablefoot_all = {}, {}
    self:make_tablefoot(x, tmp_tablefoot_last, tmp_tablefoot_all, rownumber, true)
    self:calculate_height_and_connect_tablefoot(tmp_tablefoot_last, tmp_tablefoot_all)
    return tmp_tablefoot_last[1], tmp_tablefoot_all[1]
end

-- Reformat the table head for a given page.
---@return table Table head nodes for first page
---@return table Table head nodes for other pages
function tabular:reformat_head()
    local y = self.tablehead_contents[1]
    local rownumber = self.tablehead_contents[2]
    local y_layoutxml, y_dataxml = tabular.get_origin(y)
    assert(y_layoutxml, "no layout XML origin registered for the table head")
    assert(y_dataxml, "no data XML origin registered for the table head")
    local x = publisher.dispatch.dispatch(y_layoutxml, y_dataxml)
    ---@cast x TableheadFootContents
    self:attach_objects(x)
    local tmp1, tmp2 = {}, {}
    local page = publisher.attribute_helpers.read_attribute(y_layoutxml, y_dataxml, "page", "string", "all")
    x.page = page
    self:make_tablehead(x, tmp1, tmp2, rownumber, true)
    self:connect_tablehead_first_all(tmp1, tmp2)
    return tmp1[1], tmp2[1]
end

-- Resolves border conflicts for `border-collapse="collapse"` by setting
-- the heavier border on each shared edge and zeroing the loser.
---@param tbl table[][] 2D table of cell descriptors.
---@return nil
local function adjust_border(tbl)
    for _, row in ipairs(tbl) do
        for _, col in ipairs(row) do
            for _, nxt in ipairs(col.nextcol) do
                local td_borderright = tex.sp(col["border-right"] or 0)
                local td_borderleft = tex.sp(nxt["border-left"] or 0) or 0
                local new_borderwidth = math.max(td_borderleft, td_borderright) / 2
                col.td_borderright_calculated = math.max(col.td_borderright_calculated or 0, new_borderwidth)
                nxt.td_borderleft_calculated = math.max(nxt.td_borderleft_calculated or 0, new_borderwidth)
                if td_borderleft == 0 then
                    nxt["border-left-color"] = col["border-right-color"]
                end
                if td_borderright == 0 then
                    col["border-right-color"] = nxt["border-left-color"]
                end
            end
            for _, nxt in ipairs(col.nextrow) do
                local td_borderbottom = tex.sp(col["border-bottom"] or 0) or 0
                local td_bordertop = tex.sp(nxt["border-top"] or 0) or 0
                local new_borderwidth = math.max(td_borderbottom, td_bordertop) / 2
                nxt.td_bordertop_calculated = math.max(nxt.td_bordertop_calculated or 0, new_borderwidth)
                col.td_borderbottom_calculated = math.max(col.td_borderbottom_calculated or 0, new_borderwidth)
                if td_bordertop == 0 then
                    nxt["border-top-color"] = col["border-bottom-color"]
                end
                if td_borderbottom == 0 then
                    col["border-bottom-color"] = nxt["border-top-color"]
                end
            end
        end
    end
end

-- Perform border collapsing for the table, recalculating border widths.
---@param tab table Table data
---@param area? string Table area (e.g., 'body', 'tablehead')
function tabular:do_bordercollapse(tab, area)
    area = area or "body"
    local tablematrix = {}
    local current_row = 1
    local current_column
    local maxcol = 0 -- needed?
    for _, tr in ipairs(tab) do
        local tr_eltname = publisher.xml_helpers.elementname(tr)
        if tr_eltname == "Tablehead" then
            local tr_contents = publisher.xml_helpers.element_contents(tr)
            self:do_bordercollapse(tr_contents, "tablehead" .. tr_contents.page)
        elseif tr_eltname == "Tablefoot" then
            local tr_contents = publisher.xml_helpers.element_contents(tr)
            self:do_bordercollapse(tr_contents, "tablefoot" .. tr_contents.page)
        elseif tr_eltname == "Tr" then
            current_column = 1
            local tr_contents = publisher.xml_helpers.element_contents(tr)
            tablematrix[current_row] = {}
            for _, td in ipairs(tr_contents) do
                local td_eltname = publisher.xml_helpers.elementname(td)
                if td_eltname == "Td" then
                    while self.skiptables[area][current_row] and self.skiptables[area][current_row][current_column] do
                        tablematrix[current_row][current_column] = tablematrix[current_row - 1][current_column]
                        current_column = current_column + 1
                    end
                    local td_contents = publisher.xml_helpers.element_contents(td)
                    tablematrix[current_row][current_column] = td_contents
                    td_contents.name = string.format([[%2d / %2d]], current_row, current_column)
                    local colspan = td_contents.colspan
                    for _ = 1, (colspan or 1) - 1 do
                        current_column = current_column + 1
                        tablematrix[current_row][current_column] = td_contents
                    end
                    current_column = current_column + 1
                    if current_column > maxcol then
                        maxcol = current_column
                    end
                end
            end
            if self.skiptables.body[current_row] and self.skiptables.body[current_row][current_column] then
                tablematrix[current_row][current_column] = tablematrix[current_row - 1][current_column]
            end
            current_row = current_row + 1
        end
    end
    for i = 1, #tablematrix do
        local row = tablematrix[i]
        for j = 1, #row do
            local col = row[j]
            local next_j = j + 1
            col.nextcol = col.nextcol or {}
            while row[next_j] == col do
                next_j = next_j + 1
            end
            local has_entry = false
            for _, n in ipairs(col.nextcol) do
                if n == row[next_j] then
                    has_entry = true
                end
            end
            if not has_entry then
                col.nextcol[#col.nextcol + 1] = row[next_j]
            end
        end
    end

    for i = 1, #tablematrix do
        local row = tablematrix[i]
        for j = 1, #row do
            local col = row[j]
            col.nextrow = col.nextrow or {}
            local next_row = i + 1
            while tablematrix[next_row] and tablematrix[next_row][j] == col do
                next_row = next_row + 1
            end
            local has_entry = false
            for _, n in ipairs(col.nextrow) do
                if n == tablematrix[next_row][j] then
                    has_entry = true
                end
            end
            if tablematrix[next_row] and not has_entry then
                col.nextrow[#col.nextrow + 1] = tablematrix[next_row][j]
            end
        end
    end

    adjust_border(tablematrix)
end

-- Mark cells as skipped in the skiptable for rowspans and colspans.
---@param tr_contents table Row contents
---@param curskiptable table Current skiptable
---@param current_row integer Current row index
local function set_skip_table_elt(tr_contents, curskiptable, current_row, total_columns)
    local rowspan
    local colspan
    local current_column = 0

    for _, td in ipairs(tr_contents) do
        current_column = current_column + 1

        -- There might be a rowspan from the row above, so we need to find the correct column
        while curskiptable[current_row] and curskiptable[current_row][current_column] do
            current_column = current_column + 1
        end

        local td_contents = publisher.xml_helpers.element_contents(td)
        rowspan = tonumber(td_contents.rowspan) or 1
        colspan = resolve_colspan(td_contents.colspan, current_column, total_columns)

        for z = current_row + 1, current_row + rowspan - 1 do
            for y = current_column, current_column + colspan - 1 do
                curskiptable[z] = curskiptable[z] or {}
                curskiptable[z][y] = true
            end
        end
        while curskiptable[current_row] and curskiptable[current_row][current_column] do
            current_column = current_column + 1
        end
        current_column = current_column + colspan - 1
    end
end

-- Builds the skiptables for the body, head and foot. Marks every cell
-- covered by a colspan or rowspan so later layout passes can skip them.
---@return nil
function tabular:set_skip_table()
    self.skiptables =
        { body = { name = "body" }, tablehead = { name = "tablehead" }, tablefoot = { name = "tablefoot" } }
    local rowcounter = {}
    local current_row_body = 0
    for _, tr in ipairs(self.tab) do
        local tr_contents = publisher.xml_helpers.element_contents(tr)
        local eltname = publisher.xml_helpers.elementname(tr)
        if eltname == "Tr" then
            current_row_body = current_row_body + 1
            set_skip_table_elt(tr_contents, self.skiptables.body, current_row_body, self.total_columns)
        elseif eltname == "Tablehead" or eltname == "Tablefoot" then
            local tablearea
            if eltname == "Tablehead" then
                tablearea = "tablehead"
            else
                tablearea = "tablefoot"
            end
            tablearea = tablearea .. (tr_contents.page or "")
            rowcounter[tablearea] = 0
            self.skiptables[tablearea] = self.skiptables[tablearea] or { name = self.skiptables[tablearea] }
            for _, tr_inner in ipairs(tr_contents) do
                local inner_eltname = publisher.xml_helpers.elementname(tr_inner)
                local inner_contents = publisher.xml_helpers.element_contents(tr_inner)
                if inner_eltname == "Tr" then
                    rowcounter[tablearea] = rowcounter[tablearea] + 1
                    set_skip_table_elt(
                        inner_contents,
                        self.skiptables[tablearea],
                        rowcounter[tablearea],
                        self.total_columns
                    )
                end
            end
        end
    end
end

-- Main entry point to create and typeset the table.
---@param dataxml table XML data for the table
---@return Node|SplitTableResult
function tabular:make_table(dataxml)
    -- Determine total number of columns from <Columns> or max cells per row
    self.total_columns = 0
    for _, tr in ipairs(self.tab) do
        local tr_elementname = publisher.xml_helpers.elementname(tr)
        if tr_elementname == "Columns" then
            local tr_contents = publisher.xml_helpers.element_contents(tr)
            for _, column in ipairs(tr_contents) do
                if publisher.xml_helpers.elementname(column) == "Column" then
                    self.total_columns = self.total_columns + 1
                end
            end
            break
        end
    end
    if self.total_columns == 0 then
        -- No <Columns> found, count max cells per row
        for _, tr in ipairs(self.tab) do
            local tr_elementname = publisher.xml_helpers.elementname(tr)
            if tr_elementname == "Tr" then
                local tr_contents = publisher.xml_helpers.element_contents(tr)
                local count = 0
                for _, td in ipairs(tr_contents) do
                    if publisher.xml_helpers.elementname(td) == "Td" then
                        count = count + 1
                    end
                end
                if count > self.total_columns then
                    self.total_columns = count
                end
            end
        end
    end

    self:set_skip_table()
    if self.bordercollapse then
        self:do_bordercollapse(self.tab, "body")
    end

    self:collect_alignments()
    self:attach_objects(self.tab)
    if self:calculate_columnwidth() ~= nil then
        main.log("error", "Cannot print table")
        local x = node.new("vlist")
        return x
    end

    self:calculate_rowheights()
    if publisher.newxpath then
        dataxml.vars["_last_tr_data"] = ""
    else
        publisher.xpath.set_variable("_last_tr_data", "")
    end

    return self:typeset_table(dataxml)
end

file_end("tabular.lua")

return tabular
