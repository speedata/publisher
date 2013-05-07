--
--  publisher/src/lua/tabular.lua
--  speedata publisher
--
--  Copyright 2010-2012 Patrick Gundlach.
--  See file COPYING in the root directory for license details.


file_start("table.lua")
-- require("xpath")

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
        -- Der Abstand zwischen Spalte i und i+1, derzeit nicht benutzt
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
            w("unknown element name %s",td_elementname)
        end
    end
end

function attach_objects( tab )
    for _,tr in ipairs(tab) do
        attach_objects_row(publisher.element_contents(tr))
    end
end

--------------------------------------------------------------------------
function calculate_columnwidth_for_row(self, tr_contents,current_row,colspans,colmin,colmax )
    local current_column
    local max_wd, min_wd -- maximale Breite und minimale Breite einer Tabellenzelle (Td)
    -- als erstes die einzelnen rows/Zellen durchgehen und schauen, wie breit die
    -- Spalten sein müssen. Wenn es colspans gibt, müssen diese entsprechend
    -- berücksichtigt werden.
    current_column = 0

    for _,td in ipairs(tr_contents) do
        local td_contents = publisher.element_contents(td)
        -- alle Spalten durchgehen
        -- skip, colspan und colmax-Tabellen ausfüllen für diese Tabellenzelle:
        current_column = current_column + 1
        min_wd,max_wd = nil,nil
        local rowspan = tonumber(td_contents.rowspan) or 1
        local colspan = tonumber(td_contents.colspan) or 1

        -- Wenn ich auf einer Skip-Spalte bin (durch einen Rowspan), dann überspringe ich die Spalte einfach
        while self.skip[current_row] and self.skip[current_row][current_column] do current_column = current_column + 1 end
        -- rowspan?
        for z = current_row + 1, current_row + rowspan - 1 do
            for y = current_column, current_column + colspan - 1 do
                self.skip[z] = self.skip[z] or {}  self.skip[z][y] = true
            end
        end

        local td_randlinks  = tex.sp(td_contents["border-left"]  or 0)
        local td_randrechts = tex.sp(td_contents["border-right"] or 0)

        local padding_left  = td_contents.padding_left  or self.padding_left
        local padding_right = td_contents.padding_right or self.padding_right

        for _,object in ipairs(td_contents.objects) do
            if type(object)=="table" then
                trace("tabular: check for nodelist (%s)",tostring(object.nodelist ~= nil))

                if object.nodelist then
                    publisher.set_fontfamily_if_necessary(object.nodelist,self.fontfamily)
                    publisher.fonts.pre_linebreak(object.nodelist)
                end

                if object.min_width then
                    min_wd = math.max(object:min_width() + padding_left  + padding_right + td_randlinks + td_randrechts, min_wd or 0)
                end
                if object.max_width then
                    max_wd = math.max(object:max_width() + padding_left  + padding_right + td_randlinks + td_randrechts, max_wd or 0)
                end
                trace("tabular: min_wd, max_wd set (%gpt,%gpt)",min_wd / 2^16, max_wd / 2^16)
            end
            if not ( min_wd and max_wd) then
                trace("min_wd and max_wd not set yet. Typ(object)==%s",type(object))
                if object.width then
                    min_wd = object.width + padding_left  + padding_right + td_randlinks + td_randrechts
                    max_wd = object.width + padding_left  + padding_right + td_randlinks + td_randrechts
                    trace("tabular: width (image) = %gpt",min_wd / 2^16)
                else
                    warning("Could not determine min_wd and max_wd")
                    assert(false)
                end
            end
        end
        trace("tabular: Colspan=%d",colspan)
        -- colspan?
        min_wd = min_wd or 0
        max_wd = max_wd or 0
        if colspan > 1 then
            colspans[#colspans + 1] = { start = current_column, ende = current_column + colspan - 1, max_wd = max_wd, min_wd = min_wd }
            current_column = current_column + colspan - 1
        else
            colmax[current_column] = math.max(colmax[current_column] or 0,max_wd)
            colmin[current_column] = math.max(colmin[current_column] or 0,min_wd)
        end
    end  -- ∀ columns
end


function calculate_spaltenbreite( self )
    trace("tabular: calculate columnwidth")
    local colspans = {}
    local colmax,colmin = {},{}

    local current_row = 0
    self.tablewidth_target = self.breite
    local columnwidths_given = false

    for _,tr in ipairs(self.tab) do
        local tr_contents      = publisher.element_contents(tr)
        local tr_elementname = publisher.elementname(tr,true)

        if tr_elementname == "Columns" then
            local wd
            local i = 0
            local count_stars = 0
            local summe_echte_breiten = 0
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
                            summe_echte_breiten = summe_echte_breiten + self.colwidths[i]
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
                trace("tabular: Platz bei *-Spalten verteilen (Summe = %d)",count_stars)

                -- nun sind die *-Spalten bekannt und die Summe der fixen-Spalten, so dass ich
                -- den zu verteilenden Platz verteilen kann.
                local to_distribute =  self.tablewidth_target - summe_echte_breiten - table.sum(self.column_distances,1,count_columns - 1)

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
            end -- summe_* > 0
        end
    end

    if columnwidths_given then return end

    -- Phase I: max_wd, min_wd berechnen
    for _,tr in ipairs(self.tab) do
        local tr_contents      = publisher.element_contents(tr)
        local tr_elementname = publisher.elementname(tr,true)

        if tr_elementname == "Tr" then
            current_row = current_row + 1
            self:calculate_columnwidth_for_row(tr_contents,current_row,colspans,colmin,colmax)
        elseif tr_elementname == "Tablerule" then
            --ignorieren
        elseif tr_elementname == "Tablehead" then
            for _,row in ipairs(tr_contents) do
                local row_contents    = publisher.element_contents(row)
                local row_elementname = publisher.elementname(row,true)
                if row_elementname == "Tr" then
                    current_row = current_row + 1
                    self:calculate_columnwidth_for_row(row_contents,current_row,colspans,colmin,colmax)
                end
            end
        elseif tr_elementname == "Tablefoot" then
            for _,row in ipairs(tr_contents) do
                local row_contents  = publisher.element_contents(row)
                local row_elementname = publisher.elementname(row,true)
                if row_elementname == "Tr" then
                    current_row = current_row + 1
                    self:calculate_columnwidth_for_row(row_contents,current_row,colspans,colmin,colmax)
                end
            end
        else
            warning("Unknown Element: %q",tr_elementname or "?")
        end -- if it's really a row
    end -- ∀ rows / rules


    -- Jetzt sind wir in allen Zeilen alle Zellen durchgegangen. Wenn es colspans gibt,
    -- dann kann sein, dass wir manche Spaltenbreiten erhöhen müssen!
    --
    -- Beispiel (fake):
    --     <Tabelle breite="30">
    --       <Tr><Td>A</Td><Td>A</Td></Tr>
    --       <Tr><Td colspan="2">Ein ganz schön langer Text</Td></Tr>
    --     </Tabelle>
    --     ----------------------------
    --     |A           |A            |
    --     |Ein ganz schön langer Text|
    --     ----------------------------
    --
    -- In diesem Fall ist sum<sub>min</sub> in etwa die Läne von "langer" und sum<sub>max</sub> ist die Länge des Textes.
    -- colmax[i] ist die Breite von "A", colmin[i] ebenfalls
    --
    -- Phase II: Colspan einbeziehen
    --
    trace("tabular: colmin/colmax anpassen")
    -- colmin/colmax anpassen (wenn wir colspans haben)
    for i,colspan in pairs(colspans) do
        trace("tabular: colspan #%d",i)
        local sum_min,sum_max = 0,0
        local r -- Streckfaktor = wd(colspan)/wd(Summe_start_ende)

        -- erst einmal berechnen, wie breit die Spalten sind, die mit dem colspan überdeckt werden,
        -- aber ohne den colspan eingerechnet.
        if #colmax < colspan.ende then
            err("Not enough columns found for colspan")
            return -1
        end
        sum_max = table.sum(colmax,colspan.start,colspan.ende)
        sum_min = table.sum(colmin,colspan.start,colspan.ende)

        -- Wenn der colspan mehr Platz benötigt, als der Rest der Tabelle, dann müssen ja
        -- die Spaltenbreiten der Tabelle entsprechend erhöht werden. Dazu wird dann jede
        -- Spalte um einen Faktor r gestreckt. r wird aufgrund des Inhalts berechnet.

        -- Das machen wir einmal für die maximale Breite und einmal für die minimale Breite
        local breite_des_colseps = table.sum(self.column_distances,colspan.start,colspan.start)

        if colspan.max_wd > sum_max + breite_des_colseps then
            r = ( colspan.max_wd - breite_des_colseps ) / sum_max
            for j=colspan.start,colspan.ende do
                colmax[j] = colmax[j] * r
            end
        end -- colspan.max_wd > sum_max?

        if colspan.min_wd > sum_min + breite_des_colseps then
            r = ( colspan.min_wd - breite_des_colseps ) / sum_min
            for j=colspan.start,colspan.ende do
                colmin[j] = colmin[j] * r
            end
        end -- colspan.min_wd > sum_min?
    end -- ∀ colspans

    -- So, jetzt sind für alle Spalten colmin und colmax berechnet. Die colspans sind mit einbezogen worden.


    -- Phase III: Tabelle stauchen oder strecken

    -- Jetzt kommt die eigentliche Breitenberechnung
    -- ---------------------------------------------
    -- FIXME: hier statt self.colsep die column_distances[i] berücksichtigen
    local colsep = (#colmax - 1) * self.colsep
    local tablewidth_is = table.sum(colmax) + colsep

    -- 1) natürliche (max) Breite / Gesamtbreite für jede Spalte berechnen

    -- Wenn dehnen="nein" ist, dann kann es immer noch sein, dass die Tabelle zu breit geworden ist.
    -- dann muss sie gestaucht werden.

    -- unwahrscheinlicher Fall, dass es exakt passt:
    if tablewidth_is == self.tablewidth_target then
        for i=1,#colmax do
            self.colwidths[i] = colmax[i]
        end
        return
    end

    -- Wenn die Tabelle zu breit ist, dann müssen manche Spalten verkleinert werden.
    if tablewidth_is > self.tablewidth_target then
        local col_r = {} -- temporäre Spaltenbreite nach der Stauchung
        local schrumpf_faktor = {}
        local summe_schrumpffaktor = 0
        local ueberschuss = 0
        local r = ( self.tablewidth_target - colsep )  / ( tablewidth_is - colsep)
        for i=1,#colmax do
            -- eigentlich:
            -- r[i] = colmax[i] / tablewidth_is
            -- aber um auf die Zellenbreite zu kommen muss ich mit tablewidth_target multiplizieren
            col_r[i] = colmax[i] * r

            -- Wenn nun die errechnete Breite kleiner ist als die minimale Breite, dann muss die
            -- Zelle vergrößert werden und die Gesamtbreite um den Überschuss verringert werden
            if col_r[i] < colmin[i] then
                ueberschuss = ueberschuss + colmin[i] - col_r[i]
                self.colwidths[i] = colmin[i]
            end
            if col_r[i] > colmin[i] then
                -- diese Spalte kann wenn nötig verkleinert werden. Der Faktor ist col_r[i] / colmin[i]
                schrumpf_faktor[i] = col_r[i] / colmin[i]
                summe_schrumpffaktor = summe_schrumpffaktor + schrumpf_faktor[i]
            end
        end
        -- dieser Überschuss muss nun anteilig von den zu breiten Spalten abgezogen werden
        for i=1,#colmax do
            --
            if schrumpf_faktor[i] then
                self.colwidths[i] = col_r[i] -  schrumpf_faktor[i] / summe_schrumpffaktor * ueberschuss
            end
        end
        return
    end

    -- Wenn dehnen="nein" ist, dann brauchen wir nicht zu Strecken/stauchen
    if self.autostretch ~= "max" then
        self.tablewidth_target = tablewidth_is
        for i=1,#colmax do
            self.colwidths[i] = colmax[i]
        end
        return
    end


    -- Wenn die Tabelle zu schmal für den Text ist, dann muss sie breiter werden.
    if tablewidth_is < self.tablewidth_target then
        -- die Tabelle muss breiter werden
        local r = ( self.tablewidth_target - colsep ) / ( tablewidth_is - colsep )
        for i=1,#colmax do
            self.colwidths[i] = colmax[i] * r
        end
    end
end

function calculate_zeilenhoehe( self,tr_contents, current_row )
    local zeilenhoehe
    local rowspan,colspan
    local wd,parameter
    local rowspans = {}

    local fam = publisher.fonts.lookup_fontfamily_number_instance[self.fontfamily]
    local min_lineheight = fam.baselineskip

    if tr_contents.minheight then
        zeilenhoehe = math.max(publisher.current_grid.gridheight * tr_contents.minheight, min_lineheight)
    else
        zeilenhoehe = min_lineheight
    end

    current_column = 0

    for _,td in ipairs(tr_contents) do
        local td_contents = publisher.element_contents(td)
        current_column = current_column + 1


        local td_randlinks  = tex.sp(td_contents["border-left"]   or 0)
        local td_randrechts = tex.sp(td_contents["border-right"]  or 0)
        local td_randoben   = tex.sp(td_contents["border-top"]    or 0)
        local td_randunten  = tex.sp(td_contents["border-bottom"] or 0)

        local padding_left   = td_contents.padding_left   or self.padding_left
        local padding_right  = td_contents.padding_right  or self.padding_right
        local padding_top    = td_contents.padding_top    or self.padding_top
        local padding_bottom = td_contents.padding_bottom or self.padding_bottom

        rowspan = tonumber(td_contents.rowspan) or 1
        colspan = tonumber(td_contents.colspan) or 1

        wd = 0
        for s = current_column,current_column + colspan - 1 do
            wd = wd + self.colwidths[s]
        end
        current_column = current_column + colspan - 1

        -- FIXME: hier statt self.colsep die column_distances[i] berücksichtigen
        wd = wd + ( colspan - 1 ) * self.colsep
        -- hier unbedingt(!!) border-left und border-right beachten FIXME
        -- in der Höhenberechnung auch border-top und border-bottom! FIXME
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
                end
                if not default_textformat_name then
                    if object.textformat then
                        default_textformat_name = object.textformat
                    elseif self.textformat then
                        default_textformat_name = self.textformat
                    end
                end
                publisher.set_fontfamily_if_necessary(object.nodelist,self.fontfamily)

                local v = object:format(wd - padding_left - padding_right - td_randlinks - td_randrechts,default_textformat_name)
                if cell then
                    node.tail(cell).next = v
                else
                    cell = v
                end
            elseif (type(object)=="userdata" and node.has_field(object,"width")) then
                -- an image or a box!?!
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

        tmp = v.height + v.depth +  padding_top + padding_bottom + td_randunten + td_randoben
        if rowspan > 1 then
            rowspans[#rowspans + 1] =  { start = current_row, ende = current_row + rowspan - 1, ht = tmp }
            td_contents.rowspan_internal = rowspans[#rowspans]
        else
            zeilenhoehe = math.max(zeilenhoehe,tmp)
        end
        -- FIXME: node.flushlist tmp ??
        -- node.flush_list(v)
        -- Attempt to double-free hlist node 387580, ignored.
    end
    return zeilenhoehe,rowspans
end


--------------------------------------------------------------------------
function calculate_rowheights(self)
    trace("tabular: berechne Zeilenhöhen")
    local current_row = 0
    local rowspans = {}
    local _rowspans


    for _,tr in ipairs(self.tab) do
        local tr_contents = publisher.element_contents(tr)
        local eltname = publisher.elementname(tr,true)

        if eltname == "Tablerule" or eltname == "Columns" then
            -- ignorieren

        elseif eltname == "Tablehead" then
            for _,zeile in ipairs(tr_contents) do
                local zeile_inhalt  = publisher.element_contents(zeile)
                local zeile_eltname = publisher.elementname(zeile,true)
                if zeile_eltname == "Tr" then
                    current_row = current_row + 1
                    zeilenhoehe, _rowspans = self:calculate_zeilenhoehe(zeile_inhalt,current_row)
                    self.rowheights[current_row] = zeilenhoehe
                    rowspans = table.__concat(rowspans,_rowspans)
                end
            end
        elseif eltname == "Tablefoot" then
            for _,zeile in ipairs(tr_contents) do
                local zeile_inhalt  = publisher.element_contents(zeile)
                local zeile_eltname = publisher.elementname(zeile,true)
                if zeile_eltname == "Tr" then
                    current_row = current_row + 1
                    zeilenhoehe, _rowspans = self:calculate_zeilenhoehe(zeile_inhalt,current_row)
                    self.rowheights[current_row] = zeilenhoehe
                    rowspans = table.__concat(rowspans,_rowspans)
                end
            end

        elseif eltname == "Tr" then
            current_row = current_row + 1
            zeilenhoehe, _rowspans = self:calculate_zeilenhoehe(tr_contents,current_row)
            self.rowheights[current_row] = zeilenhoehe
            rowspans = table.__concat(rowspans,_rowspans)
        else
            warning("Unknown contents in »Table« %s",eltname or "?")
        end -- wenn es nicht eine <Tablerule> ist
    end -- für alle Zeilen

    -- Zeilenhöhen anpassen. Erst müssen alle möglichen Verschiebungen in den Zeilenhöhen
    -- berechnet werden, bevor den eigentlichen rowspans ihre Höhen bekommen (aufgrund der Zeilenhöhen)
    for i,rowspan in pairs(rowspans) do
        trace("tabular: Zeilenhöhen anpassen")
        local sum_ht = 0
        trace("tabular: rowspan.start = %d, rowspan.ende = %d. self.rowsep = %gpt",rowspan.start,rowspan.ende,self.rowsep)
        for j=rowspan.start,rowspan.ende do
            trace("tabular: füge %gpt hinzu (Zeile %d)",self.rowheights[j] / 2^16,j)
            sum_ht = sum_ht + self.rowheights[j]
        end
        sum_ht = sum_ht + self.rowsep * ( rowspan.ende - rowspan.start )
        trace("tabular: Rowspan (%d) > Zeilenhöhen %gpt > %gpt?",rowspan.ende - rowspan.start + 1 ,rowspan.ht / 2^16 ,sum_ht / 2^16)
        if rowspan.ht > sum_ht then
            local ueberschuss_je_zeile = (rowspan.ht - sum_ht) / (rowspan.ende - rowspan.start + 1)
            trace("tabular: Überschuss je Zeile = %gpt",ueberschuss_je_zeile / 2^16)
            for j=rowspan.start,rowspan.ende do
                self.rowheights[j] = self.rowheights[j] + ueberschuss_je_zeile
            end
        end
    end

    -- erst jetzt sind alle Zeilenhöhen berechnet. Dadurch können die rowspans angepasst werden.
    for i,rowspan in pairs(rowspans) do
        rowspan.sum_ht = table.sum(self.rowheights,rowspan.start, rowspan.ende) + self.rowsep * ( rowspan.ende - rowspan.start )
    end
end

function setze_zeile(self, tr_contents, current_row )
    local current_column
    local current_columnnbreite, ht
    local zeile = {}
    local rowspan, colspan
    local v,vlist,hlist
    local fill = { width = 0, stretch = 2^16, stretch_order = 3}

    current_column = 0
    for _,td in ipairs(tr_contents) do

        current_column = current_column + 1

        td_contents = publisher.element_contents(td)
        rowspan = tonumber(td_contents.rowspan) or 1
        colspan = tonumber(td_contents.colspan) or 1

        -- FIXME: bin ich sicher, das ich in der richtigen Spalte bin (colspan...)?
        local td_randlinks  = tex.sp(td_contents["border-left"]   or 0)
        local td_randrechts = tex.sp(td_contents["border-right"]  or 0)
        local td_randoben   = tex.sp(td_contents["border-top"]    or 0)
        local td_randunten  = tex.sp(td_contents["border-bottom"] or 0)

        local padding_left   = td_contents.padding_left   or self.padding_left
        local padding_right  = td_contents.padding_right  or self.padding_right
        local padding_top    = td_contents.padding_top    or self.padding_top
        local padding_bottom = td_contents.padding_bottom or self.padding_bottom


        -- Wenn ich auf einer Skip-Spalte bin (durch einen Rowspan), dann
        -- muss eine leere hbox erzeugt werden
        while self.skip[current_row] and self.skip[current_row][current_column] do
            v = publisher.create_empty_hbox_with_width(self.colwidths[current_column])
            v = publisher.add_glue(v,"head",fill) -- sonst gäb's ne underfull vbox
            zeile[current_column] = node.vpack(v,self.rowheights[current_row],"exactly")
            current_column = current_column + 1
        end

        -- rowspan? - nicht DRY: dasselbe wurde schon in calculate_spaltenbreite gemacht
        for z = current_row + 1, current_row + rowspan - 1 do
            for y = current_column, current_column + colspan - 1 do
                self.skip[z] = self.skip[z] or {}  self.skip[z][y] = true
            end
        end

        current_columnnbreite = 0
        for s = current_column,current_column + colspan - 1 do
            current_columnnbreite = current_columnnbreite + self.colwidths[s]
        end
        -- FIXME: hier statt self.colsep die column_distances[i] berücksichtigen
        current_columnnbreite = current_columnnbreite + ( colspan - 1 ) * self.colsep
        current_column = current_column + colspan - 1

        if rowspan > 1 then
            ht = td_contents.rowspan_internal.sum_ht
        else
            ht = self.rowheights[current_row]
        end
        -- FIXME: muss ich wirklich hier noch einmal alles setzen? Ich habe doch schon im
        -- vorherigen Anlauf (Zeilenhöhe bestimmen) alles in einen absatz gepackt!?!?

        local g = node.new("glue")
        g.spec = node.new("glue_spec")
        g.spec.width = padding_top

        local valign = td_contents.valign or tr_contents.valign or self.valign[current_column]
        if valign ~= "top" then
            g.spec.stretch = 2^16
            g.spec.stretch_order = 2
        end

        local zelle_start = g

        local zelle
        local current = node.tail(zelle_start)


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
                end
                if not default_textformat_name then
                    if object.textformat then
                        default_textformat_name = object.textformat
                    elseif self.textformat then
                        default_textformat_name = self.textformat
                    end
                end
                v = object:format(current_columnnbreite - padding_left - padding_right - td_randlinks - td_randrechts, default_textformat_name)
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

        vlist = node.vpack(zelle_start,ht - td_randoben - td_randunten,"exactly")

        -- vlist ist jetzt fertig mit der Zelle. Jetzt in eine hlist packen
        g = node.new("glue")
        g.spec = node.new("glue_spec")
        g.spec.width = padding_left


        local align = td_contents.align or tr_contents.align or self.align[current_column]
        if align ~= "left" then
            g.spec.stretch = 2^16
            g.spec.stretch_order = 2
        end

        zelle_start = g

        if td_contents["border-left"] then
            local start, stop = publisher.colorbar(tex.sp(td_contents["border-left"]),-1073741824,-1073741824,td_contents["border-left-color"])
            stop.next = g
            zelle_start = start
        end

        current = node.tail(zelle_start)
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

        if td_contents["border-right"] then
            local rule = publisher.colorbar(tex.sp(td_contents["border-right"]),-1073741824,-1073741824,td_contents["border-right-color"])
            g.next = rule
        end

        hlist = node.hpack(zelle_start,current_columnnbreite,"exactly")

        -- So, jetzt ist die Zelle vollständig (bis auf die top/bottom rule). Hier kann jetzt die Hintergrundfarbe gesetzt werden.
        if tr_contents.backgroundcolor or td_contents.backgroundcolor or self.columncolors[current_column] then
            -- prio: Td.backgroundcolor, dann Tr.backgroundcolor, dann Spalte.backgroundcolor
            local farbe = self.columncolors[current_column]
            farbe = tr_contents.backgroundcolor or farbe
            farbe = td_contents.backgroundcolor or farbe
            hlist = publisher.background(hlist,farbe)
        end

        local head = hlist
        if td_contents["border-top"] then
            local rule = publisher.colorbar(-1073741824,tex.sp(td_contents["border-top"]),0,td_contents["border-top-color"])
            -- rule besteht aus whatsit, rule, whatsit
            node.tail(rule).next = hlist
            head = rule
        end

        if td_contents["border-bottom"] then
            local rule = publisher.colorbar(-1073741824,tex.sp(td_contents["border-bottom"]),0,td_contents["border-bottom-color"])
            hlist.next = rule
        end


        -- vlist.height = self.rowheights[current_row]
        -- hlist.height = self.rowheights[current_row]
        local gl = node.new("glue")
        gl.spec = node.new("glue_spec")
        gl.spec.width = 0
        gl.spec.shrink = 2^16
        gl.spec.shrink_order = 2
        node.slide(head).next = gl

        hlist = node.vpack(head,self.rowheights[current_row],"exactly")

        if publisher.options.trace then
            publisher.boxit(hlist)
        end

        zeile[#zeile + 1] = hlist

    end -- ende td

    if current_column == 0 then
        trace("tabular: keine Td-Zellen in dieser Spalte gefunden")
        v = publisher.create_empty_hbox_with_width(self.tablewidth_target)
        trace("tabular: leere hbox erzeugt")
        v = publisher.add_glue(v,"head",fill) -- sonst gäb's ne underfull vbox
        zeile[1] = node.vpack(v,self.rowheights[current_row],"exactly")
    end

    local zelle, zelle_start,current
    zelle_start = zeile[1]
    current = zelle_start

    -- FIXME: hier statt self.colsep die column_distances[i] berücksichtigen
    if zeile[1] then
        for z=2,#zeile do
            _,current = publisher.add_glue(current,"tail",{ width = self.colsep })
            current.next = zeile[z]
            current = zeile[z]
        end
        zeile = node.hpack(zelle_start)
    else
        err("(Internal error) Table is not complete.")
    end
    return zeile
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
            current_tablehead_type[#current_tablehead_type + 1] = self:setze_zeile(row_contents,current_row)
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
            current_tablefoot_type[#current_tablefoot_type + 1] = self:setze_zeile(row_contents,current_row)
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

function setze_tabelle(self)
    trace("tabular: setze Tabelle")
    local current_row
    local tablehead_first = {}
    local tablehead = {}
    local tablefoot_last = {}
    local tablefoot = {}
    local rows = {}
    local break_above = true
    local filter = {}
    local startpage = tex.count[0]
    local tablepart_absolute = 1

    current_row = 0
    for _,tr in ipairs(self.tab) do
        local tr_contents = publisher.element_contents(tr)
        local eltname   = publisher.elementname(tr,true)
        local tmp
        -- If this row is allowed to break above
        -- Will be set to false if break_below is "no"

        if eltname == "Columns" then
            -- ignorieren
        elseif eltname == "Tablerule" then
            tmp = publisher.colorbar(self.tablewidth_target,tex.sp(tr_contents.rulewidth or "0.25pt"),0,tr_contents.farbe)
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
            current_row = current_row + 1
            rows[#rows + 1] = self:setze_zeile(tr_contents,current_row)
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
                node.set_attribute(rows[#rows],publisher.att_break_below,1)
                break_above = false
            end

        else
            warning("Unknown contents in »Table« %s",eltname or "?" )
        end -- wenn es eine Tabellenzelle ist
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

    local ht_current = self.optionen.ht_aktuell or self.optionen.ht_max
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
                if not filter.tablehead then return ht_max - ht_header - ht_footer end
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
        publisher.variablen["_last_tr_data"] = nil
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
            publisher.variablen["_last_tr_data"] = val
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
    return final_split_tables
end

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


function tabelle( self )
    setmetatable(self.column_distances,{ __index = function() return self.colsep or 0 end })
    attach_objects(self.tab)
    if calculate_spaltenbreite(self) ~= nil then
        err("Cannot print table")
        local x = node.new("vlist")
        return x
    end
    calculate_rowheights(self)
    publisher.xpath.set_variable("_last_tr_data","")
    return setze_tabelle(self)
end

file_end("table.lua")

