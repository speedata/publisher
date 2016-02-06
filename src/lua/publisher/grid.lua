--
--  grid.lua
--  speedata publisher
--
--  Copyright 2010-2014 Patrick Gundlach.
--  See file COPYING in the root directory for license details.

file_start("grid.lua")

module(...,package.seeall)

_M.__index = _M

local function to_sp(arg)
    tex.dimen[0] = arg
    return tex.dimen[0]
end

-- pagenumber is only for debugging purpose
function new( self,pagenumber )
    assert(self)
    local r = {
        pagenumber        = pagenumber,
        pageheight_known  = false,
        extra_margin      = 0,  -- for cut marks, in sp
        trim              = 0,  -- bleed, in sp
        dimensions        = {}, -- min-x, min-y, max-x, max-y
        positioning_frames = { [publisher.default_areaname] = { { row = 1, column = 1} } },  -- Positioning frame
    }
    setmetatable(r, self)
    return r
end

-- Return the remaining height in the area in scaled points
function remaining_height_sp( self,row,areaname )
    if not self.positioning_frames[areaname] then
        err("Area %q unknown, using page",areaname)
        areaname = publisher.default_areaname
    end
    row = row or self:current_row(areaname)
    local thisframe = self.positioning_frames[areaname][self:framenumber(areaname)]
    local overshoot = math.max( (thisframe.height - thisframe["row"] + 1)  * self.gridheight - tex.pageheight ,0)
    local remaining_rows = self:number_of_rows(areaname) - row + 1
    return self.gridheight * remaining_rows - overshoot
end

function current_row( self,areaname )
    assert(self)
    local areaname = areaname or publisher.default_areaname
    area = self.positioning_frames[areaname]
    if not area then
        err("Area %q not known",tostring(areaname))
        return nil
    end
    return area.current_row or 1
end

function current_column( self,area )
    assert(self)
    local area = area or publisher.default_areaname
    assert(self.positioning_frames[area],string.format("Area %q not known",tostring(area)))
    return self.positioning_frames[area].current_column or 1
end

function set_current_row( self,row,areaname )
    assert(self)
    local areaname = areaname or publisher.default_areaname
    if not self.positioning_frames[areaname] then
        err("Area %q unknown, using page",areaname)
        areaname = publisher.default_areaname
    end
    local area = self.positioning_frames[areaname]
    area.current_row = row
end

function set_current_column( self,column,areaname )
    assert(self)
    local areaname = areaname or publisher.default_areaname
    if not self.positioning_frames[areaname] then
        err("Area %q unknown, using page",areaname)
        areaname = publisher.default_areaname
    end
    local area = self.positioning_frames[areaname]
    area.current_column = column
end

function get_parshape( self,row,areaname,framenumber )
    local frame_margin_left, frame_margin_top
    local area = self.positioning_frames[areaname]
    local block = area[framenumber]
    frame_margin_left = block.column - 1
    frame_margin_top = block.row - 1
    local first_free_column
    local last_free_column = block.width
    local y = frame_margin_top + row
    for i=1,block.width do
        local x = frame_margin_left + i
        if self.allocation_x_y[x][y] == nil then
            first_free_column = first_free_column or i
            last_free_column = i
        end
    end
    local x_start = ( first_free_column - 1) * self.gridwidth
    local x_end = ( last_free_column - first_free_column + 1 ) * self.gridwidth
    return {x_start,x_end}
end

function number_of_rows(self,areaname)
    assert(self)
    local areaname = areaname or publisher.default_areaname
    if not self.positioning_frames[areaname] then
        err("Area %q unknown, using page (number-of-rows)",areaname)
        areaname = publisher.default_areaname
    end
    local current_frame = self:framenumber(areaname)
    local area = self.positioning_frames[areaname]
    local height = area[current_frame].height
    return height
end

function number_of_columns(self,areaname)
    assert(self)
    local areaname = areaname or publisher.default_areaname
    if not self.positioning_frames[areaname] then
        err("Area %q unknown, using page (number-of-columns)",areaname)
        areaname = publisher.default_areaname
    end
    local current_frame = self:framenumber(areaname)
    local area = self.positioning_frames[areaname]
    local width = area[current_frame].width
    return width
end

function set_number_of_rows( self,rows )
    assert(self)
    local areaname = publisher.default_areaname
    local area = self.positioning_frames[areaname]
    assert(area,string.format("Area %q not known",tostring(areaname)))
    local current_frame = self:framenumber(areaname)
    area[current_frame].height = rows
end

function set_number_of_columns(self,columns)
    assert(self)
    local area = publisher.default_areaname
    assert(self.positioning_frames[area],string.format("Area %q not known",tostring(area)))
    for i,v in ipairs(self.positioning_frames[area]) do
        v.width = columns
    end
end

function number_of_frames( self,areaname )
    local areaname = areaname or publisher.default_areaname
    local area = self.positioning_frames[areaname]
    if not area then
        err("Area %q is not known on this page. Using the default area (page)",areaname)
        area = self.positioning_frames[publisher.default_areaname]
    end
    return #area
end

function framenumber( self,areaname )
    local areaname = areaname or publisher.default_areaname
    local area = self.positioning_frames[areaname]
    if not area then
        err("Area %q is not known on this page.",areaname)
        return nil
    end
    return area.current_frame or 1
end

function set_framenumber( self,areaname, number )
    local areaname = areaname or publisher.default_areaname
    local area = self.positioning_frames[areaname]
    assert(area,string.format("Area %q not known",tostring(areaame)))
    area.current_frame = number
end

-- Set width and height of the given grid (self) to the values wd and ht
function set_width_height(self, options)
    self.gridwidth  = options.wd
    self.gridheight = options.ht
    self.grid_nx    = options.nx
    self.grid_ny    = options.ny
    self.grid_dx    = options.dx or 0
    self.grid_dy    = options.dy or 0
    calculate_number_gridcells(self)
    self.allocation_x_y = {}
    for i=1,self:number_of_columns() do
        self.allocation_x_y[i] = {}
    end
end

-- Mark the rectangular area given by x and y (top left corner)
-- and the width wd and height ht as "not free" (allocated)
function allocate_cells(self,x,y,wd,ht,allocate_matrix,areaname,keepposition)
    if not x then return false end
    local show_right  = false
    local show_bottom = false
    areaname = areaname or publisher.default_areaname

    -- when true, we don't want to move the cursor
    if not keepposition then
        self:set_current_column(math.ceil(x + wd),areaname)
        self:set_current_row(   math.ceil(y)     ,areaname)
    end

    local grid_conflict = false
    if  x + wd - 1 > self:number_of_columns(areaname) then
        warning("Object protrudes into the right margin")
        show_right = true
        grid_conflict = true
    end
    if y + ht - 1 > self:number_of_rows(areaname) then
        warning("Object protrudes below the last line of the page")
        show_bottom = true
        grid_conflict = true
    end
    local frame_margin_left, frame_margin_top
    if areaname == publisher.default_areaname then
        frame_margin_left, frame_margin_top = 0,0
    else
        local area = self.positioning_frames[areaname]
        if not area then
            err("Area %q not known, expect many errors",tostring(areaname))
            return
        end
        local current_row = self:current_row(areaname)
        local block = area[self:framenumber(areaname)]
        frame_margin_left = block.column - 1
        frame_margin_top = block.row - 1
    end
    if allocate_matrix then
        -- used in output/text when allocate="auto"
        -- special handling for the non rectangular shape
        local grid_step_x = math.floor(100 * wd / allocate_matrix.max_x) / 100
        local grid_step_y = math.floor(1000 * ht / allocate_matrix.max_y) / 1000
        local cur_x, cur_y
        for _y=1,ht do
            cur_y = math.ceil(_y / ht * allocate_matrix.max_y)
            for _x=1,wd do
                if _x < wd / 2 then
                    cur_x = math.ceil(_x / wd * allocate_matrix.max_x)
                else
                    -- we need to look into this again. Don't ask me why -1 works best.
                    cur_x = math.floor((_x - 1) / wd * allocate_matrix.max_x)
                end
                if allocate_matrix[cur_y][cur_x] == 1 then
                    self.allocation_x_y[_x + x - 1][_y + y - 1] = 1
                end
            end
        end
    else
        -- No allocate matrix (default)
        local max_x = frame_margin_left + math.min(self:number_of_columns(areaname), x + wd - 1)
        local max_y = frame_margin_top  + math.min(self:number_of_rows(areaname),    y + ht - 1)
        for _x = x + frame_margin_left, max_x do
            for _y = y + frame_margin_top, max_y do
                if self.allocation_x_y[_x] == nil then
                    grid_conflict = true
                else
                    if self.allocation_x_y[_x][_y] then
                        grid_conflict = true
                        self.allocation_x_y[_x][_y] = self.allocation_x_y[_x][_y] + 1
                    else
                        local color = 1
                        if _x == max_x and show_right then
                            color = 3
                        elseif _y == max_y and show_bottom then
                            color = 3
                        end
                        self.allocation_x_y[_x][_y] = color
                    end
                end
            end
        end
    end
    if grid_conflict then
        warning("Conflict in grid")
    end
end

-- Return true if the object of width wd fits in the given row
-- at the column.
function fits_in_row(self,column,width,row)
    column = math.ceil(column)
    if not column then return false end
    if column + width - 1 > self:number_of_columns() then return false end
    local max_x = column + width - 1
    for x = column, max_x  do
        if self.allocation_x_y[x][row] then return false end
    end
    return true
end

-- Same as fits in row, but take area into account (offset)
function fits_in_row_area(self,column,width,row,areaname)
    if not column then return false end

    local frame_margin_left, frame_margin_top
    if areaname == publisher.default_areaname then
        frame_margin_left, frame_margin_top = 0,0
    else
        local area = self.positioning_frames[areaname]
        if not self.positioning_frames[areaname] then
            err("Area %q unknown, using page",areaname)
            areaname = publisher.default_areaname
            frame_margin_left, frame_margin_top = 0,0
        else
            -- Todo: find the correct block because they can be of different width/height
            local block = area[self:framenumber(areaname)]
            frame_margin_left = block.column - 1
            frame_margin_top = block.row - 1
        end
    end
    return self:fits_in_row(column + frame_margin_left, width, row + frame_margin_top )
end

-- Return the row in which the object of the given width can be placed.
-- Starting column is @column@, If the page size is not know yet, the next free
-- row will be given. Is the page full (the object cannot be placed), the
-- function returns nil.
function find_suitable_row( self,column, width,height,areaname)
    if not column then return false end
    local frame_margin_left, frame_margin_top
    if areaname == publisher.default_areaname then
        frame_margin_left, frame_margin_top = 0,0
    else
        local area = self.positioning_frames[areaname]
        if not self.positioning_frames[areaname] then
            err("Area %q unknown, using page",areaname)
            areaname = publisher.default_areaname
            frame_margin_left, frame_margin_top = 0,0
        else
            -- Todo: find the correct block becuse they can be of different width/height
            local block = area[self:framenumber(areaname)]
            frame_margin_left = block.column - 1
            frame_margin_top = block.row - 1
        end
    end
    -- FIXME: inefficient algorithm
    if self:number_of_rows(areaname) < self:current_row(areaname) + height - 1 then return nil end
    for z = self:current_row(areaname) + frame_margin_top, self:number_of_rows(areaname) + frame_margin_top do
        if self:fits_in_row(column + frame_margin_left,width,z) then

            if self:number_of_rows(areaname) < z - frame_margin_top + height  - 1 then
                return nil
            else
                local passt = true
                for current_row = z, z + height do
                    if not self:fits_in_row(column + frame_margin_left,width,current_row) then
                        passt = false
                    end
                end
                if passt then
                    return z - frame_margin_top
                end
            end
        end
    end
    if self.pageheight_known == false then
        return self:number_of_rows(areaname) + 1
    end
    return nil
end

function width_sp(self, gridcells )
    if not tonumber(gridcells) then
        return tex.sp(gridcells)
    end
    local wd = self.gridwidth * gridcells + (gridcells - 1 ) * self.grid_dx
    return math.ceil(math.round(wd,3))
end

function height_sp(self, gridcells )
    if not tonumber(gridcells) then
        return tex.sp(gridcells)
    end
    local ht = self.gridheight * gridcells + (gridcells - 1 ) * self.grid_dy
    return math.ceil(math.round(ht,3))
end


-- Return the number of grid cells for the given width (in scaled points)
function width_in_gridcells_sp(self,width_sp)
    assert(self)
    local wd_sp = width_sp - self.gridwidth
    if wd_sp <= 0 then return 1 end

    local wd_gridcells = 1
    repeat
        wd_gridcells = wd_gridcells + 1
        wd_sp = wd_sp - self.gridwidth - self.grid_dx
    until wd_sp <= 500
    return wd_gridcells
end

-- Return the number of grid cells for the given height (in scaled points)
function height_in_gridcells_sp(self,height_sp)
    assert(self)
    if height_sp == 0 then return 0 end
    local ht_sp = height_sp - self.gridheight
    if ht_sp <= 0 then return 1 end

    local ht_gridcells = 1
    repeat
        ht_gridcells = ht_gridcells + 1
        ht_sp = ht_sp - self.gridheight - self.grid_dy
    until ht_sp <= 500
    return ht_gridcells
end


-- Draw internal grid (return PDF-strings)
function draw_grid(self)
    assert(self)
    local color
    local ret = {}
    ret[#ret + 1] = "q 0.2 w [2] 1 d "
    local paperheight_bp = sp_to_bp(tex.pageheight - self.extra_margin)
    local paperwidth_bp  = sp_to_bp(tex.pagewidth  - self.extra_margin)
    local x
    local top, right
    top = math.round(paperheight_bp + sp_to_bp(self.trim ),1)

    local y = math.round(sp_to_bp(self.extra_margin - self.trim),2)

    local count_col = self:number_of_columns()
    for i=0, count_col do
        -- every 5 grid cells draw a grey rule
        if (i % 5 == 0) then color = "0.6" else color = "0.8" end
        -- every 10 grid cells draw a black rule
        if (i % 10 == 0) then color = "0.2" end
        -- left boundary of each grid cell (horizontal)
        if i < count_col then
            x = math.round( sp_to_bp(i * ( self.gridwidth + self.grid_dx) + self.margin_left + self.extra_margin) , 1)
            ret[#ret + 1] = string.format("%g G %g %g m %g %g l S", color, x, y, x, top )
        end

        -- right boundary of each grid cell (horizontal)
        if i > 0 and self.grid_dx > 0  or i == count_col then
            x =  math.round( sp_to_bp(i * self.gridwidth +  ( i - 1 ) * self.grid_dx + self.margin_left + self.extra_margin) , 1)
            ret[#ret + 1] = string.format("%g G %g %g m %g %g l S", color, x, y, x, top)
        end
    end
    x = math.round(sp_to_bp(self.extra_margin - self.trim), 2)
    local count_row = self:number_of_rows()
    for i=0, count_row do
        -- every 5 grid cells draw a gray rule
        if (i % 5 == 0) then color = "0.6" else color = "0.8" end
        -- every 10 grid cells draw a black rule
        if (i % 10 == 0) then color = "0.2" end

        -- top boundary of each grid cell
        if i < count_row then
            y = sp_to_bp( i * self.gridheight +  (i) * self.grid_dy +  self.margin_top)
            y = math.round(  paperheight_bp - y  , 3)
            right = math.round(paperwidth_bp  + sp_to_bp(self.trim),1)
            ret[#ret + 1] = string.format("%s G %g %g m %g %g l S",color, x, y, right ,y)
        end

        -- bottom boundary of each grid cell
        if i > 0 and self.grid_dy > 0  or i == count_row then
            y = sp_to_bp( i * self.gridheight +  ( i - 1 ) * self.grid_dy +  self.margin_top)
            y = math.round(  paperheight_bp - y  , 3)
            right = math.round(paperwidth_bp,1)
            ret[#ret + 1] = string.format("%s G %g %g m %g %g l S", color,x, y, right, y)
        end
    end
    ret[#ret + 1] = "Q"
    ret[#ret + 1] = "q"
    local width,height
    for _,area in pairs(self.positioning_frames) do
        for _,frame in ipairs(area) do
            x      = sp_to_bp(( frame.column - 1) * ( self.gridwidth  + self.grid_dx) + self.extra_margin + self.margin_left)
            y      = sp_to_bp(( frame.row    - 1) * ( self.gridheight + self.grid_dy) + self.margin_top )
            width  = sp_to_bp(frame.width  * self.gridwidth  + (frame.width  - 1) * self.grid_dx)
            height = sp_to_bp(frame.height * self.gridheight + (frame.height - 1) * self.grid_dy)
            ret[#ret + 1] = string.format("q %s %g w %g %g %g %g re S Q", "1 0 0  RG",0.5, x,math.round(paperheight_bp - y,2),width,-height)
        end
    end
    ret[#ret + 1] = "Q"

    if self.extra_margin ~= 0 and self.trim ~= 0 then -- draw trimbox
        x = sp_to_bp(self.extra_margin - self.trim)
        y = sp_to_bp(self.extra_margin - self.trim)
        width  = paperwidth_bp  + sp_to_bp( 2 *  self.trim - self.extra_margin )
        height = sp_to_bp(tex.pageheight - 2 * self.extra_margin + 2 * self.trim)
        ret[#ret + 1] = string.format("q 0.4 w [3 5] 6 d 0.5 G %g %g %g %g re s Q", math.round(x,2), math.round(y ,2), math.round(width,2), math.round(height,2))
    end
    return table.concat(ret,"\n")
end

function draw_gridallocation(self)
    local pdf_literals = {}
    local paperheight  = sp_to_bp(tex.pageheight)
    -- where the yellow/red rectangle should be drawn
    local re_wd, re_ht, re_x, re_y, color
    re_ht = sp_to_bp(self.gridheight)
    for y=1,self:number_of_rows() do
        local alloc_found = nil

        for x=1, self:number_of_columns() do
            if self.allocation_x_y[x][y] then
                re_wd = sp_to_bp(self.gridwidth)
                re_x = sp_to_bp (self.margin_left + self.extra_margin) + ( x - 1 ) * sp_to_bp(self.gridwidth + self.grid_dx)
                re_y = paperheight - sp_to_bp(self.margin_top + self.extra_margin) - y * sp_to_bp(self.gridheight) - ( y - 1 ) * sp_to_bp(self.grid_dy)
                if self.allocation_x_y[x][y] == 1 then
                    color = " 0 0 1 0 k "
                elseif self.allocation_x_y[x][y] == 2 then
                    color = " 0 0.6 0.6 0 k "
                else
                    color = " 0 1 1 0 k "
                end
                pdf_literals[#pdf_literals + 1]  = string.format("q %s 1 0 0 1 %g %g cm 0 0 %g %g re f Q ",color,re_x, re_y, re_wd,re_ht)
            end
        end
        alloc_found=nil
    end
    return table.concat(pdf_literals,"\n")
end

-- Return the Position of the grid cell from the left and top border (in sp)
function position_grid_cell(self,x,y,areaname,wd,ht,valign)
    local x_sp, y_sp
    if not self.margin_left then return nil, "Left margin not defined. Perhaps the <Margin> command in Pagetype is missing?" end
    local frame_margin_left, frame_margin_top

    if areaname == publisher.default_areaname then
        frame_margin_left, frame_margin_top = 0,0
    else
        if not self.positioning_frames[areaname] then
            err("Area %q unknown, using page",areaname)
            areaname = publisher.default_areaname
            frame_margin_left, frame_margin_top = 0,0
        else
            local area = self.positioning_frames[areaname]
            local current_frame = area.current_frame or 1
            local current_row = self:current_row(areaname)
            -- todo: find the correct block, the blocks can be of different width / height
            local block = area[current_frame]
            frame_margin_left = block.column - 1
            frame_margin_top = block.row - 1
        end
    end
    local numgridcells = math.floor(wd / self.gridwidth)

    x_sp = (frame_margin_left + x - 1) * (self.gridwidth + self.grid_dx) + self.margin_left + self.extra_margin
    y_sp = (frame_margin_top  + y - 1) * (self.gridheight + self.grid_dy) + self.margin_top  + self.extra_margin
    if valign then
        -- height mod cellheight = "overshoot"
        local overshoot = ht % self.gridheight
        if valign == "bottom" then
            -- cellheight - "overshoot" = shift_down
            y_sp = y_sp + self.gridheight - overshoot
        elseif valign == "middle" then
            -- ( cellheight - "overshoot") / 2 = shift_down
            y_sp = y_sp + ( self.gridheight - overshoot ) / 2
        end
    end
    return x_sp,y_sp
end


-- Arguments must be in sp (''scaled points'')
function set_margin(self,left,top,right,bottom)
    assert(bottom,"Four arguments must be given.")
    self.margin_left  = to_sp(left)
    self.margin_right = to_sp(right)
    self.margin_top   = to_sp(top)
    self.margin_bottom  = to_sp(bottom)
end

--- ![width calculation](../img/gridnx.svg)
function calculate_number_gridcells(self)
    assert(self)
    assert(self.margin_left,  "Margin not set yet!")
    self.pageheight_known = true
    if self.pagenumber == -999 then
        -- a group
        -- This is an ugly workaround. We should not make the group height 10 times the current page height.
        -- FIXME!!
        self:set_number_of_columns(math.ceil(math.round( (tex.pagewidth  - self.margin_left - self.margin_right - 2 * self.extra_margin) / self.gridwidth,4)))
        self:set_number_of_rows(math.ceil(math.round( ( 10 * tex.pageheight - self.margin_top  - self.margin_bottom  - 2 * self.extra_margin) /  self.gridheight ,4)))
    else
        local pagearea_x, pagearea_y
        pagearea_x = tex.pagewidth  - self.margin_left - self.margin_right - 2 * self.extra_margin
        pagearea_y = tex.pageheight - self.margin_top  - self.margin_bottom  - 2 * self.extra_margin

        if self.grid_nx and self.grid_nx ~= 0 then
            -- See the image
            self:set_number_of_columns( self.grid_nx )
            local sum_distances = ( self.grid_nx - 1 )  * self.grid_dx
            self.gridwidth = math.floor( ( pagearea_x - sum_distances ) /  self.grid_nx, 0)
        else
            self:set_number_of_columns(self:width_in_gridcells_sp(pagearea_x))
        end

        if self.grid_ny and self.grid_ny ~= 0 then
            self:set_number_of_rows( self.grid_ny )
            local sum_distances = ( self.grid_ny - 1 )  * self.grid_dy
            self.gridheight = math.floor( ( pagearea_y - sum_distances ) /  self.grid_ny, 0)
        else
            self:set_number_of_rows(math.ceil(math.round( pagearea_y /  self.gridheight ,4)))
        end
    end

    log("Number of rows: %d, number of columns = %d",self:number_of_rows(), self:number_of_columns())
end

-- Sets the used area for the page (used by crop="yes")
function setarea( self, x, y, wd, ht)
    if self.dimensions[1] == nil then
        self.dimensions[1] = x
    else
        self.dimensions[1] = math.min(self.dimensions[1],x)
    end
    if self.dimensions[2] == nil then
        self.dimensions[2] = y
    else
        self.dimensions[2] = math.min(self.dimensions[2],y)
    end
    if self.dimensions[3] == nil then
        self.dimensions[3] = x + wd
    else
        self.dimensions[3] = math.max(self.dimensions[3], x + wd)
    end
    if self.dimensions[4] == nil then
        self.dimensions[4] = y + ht
    else
        self.dimensions[4] = math.max(self.dimensions[4],y + ht)
    end
end

function trimbox( self, crop )
    assert(self)
    local x,y,wd,ht =  sp_to_bp(self.extra_margin), sp_to_bp(self.extra_margin) , sp_to_bp(tex.pagewidth - self.extra_margin), sp_to_bp(tex.pageheight - self.extra_margin)
    local b_x,b_y,b_wd,b_ht = sp_to_bp(self.extra_margin - self.trim), sp_to_bp(self.extra_margin - self.trim) , sp_to_bp(tex.pagewidth - self.extra_margin + self.trim), sp_to_bp(tex.pageheight - self.extra_margin + self.trim)
    local attrstring = {}
    attrstring[#attrstring + 1] = string.format("/TrimBox [ %g %g %g %g]",x,y,wd,ht)
    attrstring[#attrstring + 1] = string.format("/BleedBox [%g %g %g %g]",b_x,b_y,b_wd,b_ht)
    if crop == true then
        attrstring[#attrstring + 1] = string.format("/CropBox [%g %g %g %g]", sp_to_bp(self.dimensions[1]), sp_to_bp(tex.pageheight - self.dimensions[2]), sp_to_bp(self.dimensions[3]), sp_to_bp(tex.pageheight - self.dimensions[4]))
    elseif tonumber(crop) then
        attrstring[#attrstring + 1] = string.format("/CropBox [%g %g %g %g]", sp_to_bp(self.dimensions[1] - 2*crop), sp_to_bp(tex.pageheight - self.dimensions[2] + 2* crop), sp_to_bp(self.dimensions[3] + 2*crop), sp_to_bp(tex.pageheight - self.dimensions[4] - 2*crop))
    end

    if status.luatex_version < 79 then
        pdf.pageattributes = table.concat(attrstring, " ")
    else
        pdf.setpageattributes(table.concat(attrstring, " "))
    end
end

function cutmarks( self, length, distance, width )
    local x,y,wd,ht =  sp_to_bp(self.extra_margin), sp_to_bp(self.extra_margin) , sp_to_bp(tex.pagewidth - self.extra_margin), sp_to_bp(tex.pageheight - self.extra_margin)
    local ret = {}
    local distance_bp, length_bp, width_bp
    if not distance then
        distance_bp = sp_to_bp(self.trim)
    else
        distance_bp = sp_to_bp(distance)
    end
    if distance_bp < 5 then distance_bp = 5 end
    if not length then
        length_bp = 20
    else
        length_bp = sp_to_bp(length)
    end
    if not width then
        width_bp = 0.5
    else
        width_bp = sp_to_bp(width)
    end

    -- bottom left
    ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",width_bp, x, y - distance_bp, x, y - length_bp - distance_bp)  -- v
    ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",width_bp, x - distance_bp, y, x - length_bp - distance_bp, y)  -- h
    -- bottom right
    ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",width_bp, wd, y - distance_bp, wd, y - length_bp - distance_bp)
    ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",width_bp, wd + distance_bp, y, wd + distance_bp + length_bp, y)
    -- top right
    ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",width_bp, wd, ht + distance_bp, wd, ht + distance_bp + length_bp)
    ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",width_bp, wd + distance_bp, ht, wd + distance_bp + length_bp, ht)
    -- top left
    ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",width_bp, x, ht + distance_bp, x, ht + distance_bp + length_bp)
    ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",width_bp, x - distance_bp, ht, x - length_bp - distance_bp, ht)


    return table.concat(ret,"\n")
end

function trimmarks( self, length, distance, width )
    local x,y,wd,ht = sp_to_bp(self.extra_margin - self.trim), sp_to_bp(self.extra_margin - self.trim) , sp_to_bp(tex.pagewidth - self.extra_margin + self.trim), sp_to_bp(tex.pageheight - self.extra_margin + self.trim)
    local ret = {}
    local distance_bp, length_bp, width_bp
    if not distance then
        distance_bp = sp_to_bp(self.trim)
    else
        distance_bp = sp_to_bp(distance)
    end
    if distance_bp < 5 then distance_bp = 5 end
    if not length then
        length_bp = 20
    else
        length_bp = sp_to_bp(length)
    end
    if not width then
        width_bp = 0.5
    else
        width_bp = sp_to_bp(width)
    end

    -- bottom left
    ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",width_bp, x, y - distance_bp, x, y - length_bp - distance_bp)  -- v
    ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",width_bp, x - distance_bp, y, x - length_bp - distance_bp, y)  -- h
    -- bottom right
    ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",width_bp, wd, y - distance_bp, wd, y - length_bp - distance_bp)
    ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",width_bp, wd + distance_bp, y, wd + distance_bp + length_bp, y)
    -- top right
    ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",width_bp, wd, ht + distance_bp, wd, ht + distance_bp + length_bp)
    ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",width_bp, wd + distance_bp, ht, wd + distance_bp + length_bp, ht)
    -- top left
    ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",width_bp, x, ht + distance_bp, x, ht + distance_bp + length_bp)
    ret[#ret + 1] = string.format("q 0 G %g w %g %g m %g %g l S Q",width_bp, x - distance_bp, ht, x - length_bp - distance_bp, ht)


    return table.concat(ret,"\n")
end
file_end("grid.lua")

