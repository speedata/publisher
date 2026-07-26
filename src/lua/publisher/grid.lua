--
--  grid.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("grid.lua")

local publisher = require("publisher")

---@class PositioningFrame
---@field row integer 1-based row of the top-left corner.
---@field column integer 1-based column of the top-left corner.
---@field width? integer Width in grid cells.
---@field height? integer Height in grid cells.
---@field draw? table Debug overlay settings (color, width).

-- One entry of `positioning_frames`: the array of frames of an area plus
-- the cursor state for that area.
---@class Area
---@field [integer] PositioningFrame
---@field current_row? integer
---@field current_column? integer
---@field current_frame? integer
---@field advance_rows? integer
---@field advance_frame? integer
---@field colorname? string Debug overlay color.

---@class Grid
---@field pagenumber integer? Logical page number (debugging only).
---@field pageheight_known boolean
---@field extra_margin integer Cut-mark margin in sp.
---@field trim integer Bleed in sp.
---@field dimensions { [1]: integer, [2]: integer, [3]: integer, [4]: integer } `{min_x, min_y, max_x, max_y}` in sp.
---@field positioning_frames table<string, Area>
---@field allocation_x_y table Occupancy matrix, indexed `[x][y]`.
---@field grid_nx? integer Number of columns requested by the layout.
---@field grid_ny? integer Number of rows requested by the layout.
---@field gridwidth? integer Cell width in sp.
---@field gridheight? integer Cell height in sp.
---@field grid_dx? integer Horizontal gap between cells in sp.
---@field grid_dy? integer Vertical gap between cells in sp.
---@field margin_left? integer
---@field margin_top? integer
---@field margin_right? integer
---@field margin_bottom? integer
local M = {}

local colors_module = require("publisher.colors")

M.__index = M

-- Constructs a fresh `Grid` instance. `pagenumber` is recorded for
-- diagnostics only.
---@param self Grid
---@param pagenumber integer?
---@return Grid
function M.new(self, pagenumber)
    assert(self)
    local r = {
        pagenumber = pagenumber,
        pageheight_known = false,
        extra_margin = 0, -- for cut marks, in sp
        trim = 0, -- bleed, in sp
        dimensions = {}, -- min-x, min-y, max-x, max-y
        positioning_frames = { [publisher.default_areaname] = { { row = 1, column = 1 } } }, -- Positioning frame
    }
    setmetatable(r, self)
    return r
end

-- `tostring(grid)` summarizes the grid's known areas and current rows.
---@param self Grid
---@return string
function M.__tostring(self)
    local ret = {}
    ret[#ret + 1] = string.format("Grid on page %s", tostring(self.pagenumber))
    local areas = {}
    for k, _ in pairs(self.positioning_frames) do
        areas[#areas + 1] = string.format("%s (%d)", k, self:current_row(k))
    end
    ret[#ret + 1] = string.format("Known areas: %s", table.concat(areas, ", "))
    return table.concat(ret, "\n")
end

-- Returns the first row in the given frame that has any free space.
---@param self Grid
---@param areaname string
---@param framenumber? integer
---@param dataxml table Data XML context, needed when the search advances to a new page.
---@return integer? row
function M.first_free_row(self, areaname, framenumber, dataxml)
    return self:find_suitable_row(1, self:number_of_columns(areaname), 1, areaname, framenumber, dataxml)
end

-- Returns the remaining vertical space in the area in scaled points.
---@param self Grid
---@param row? integer Starting row; defaults to current row.
---@param areaname string
---@param column? integer
---@param framenumber? integer
---@return integer remaining
function M.remaining_height_sp(self, row, areaname, column, framenumber)
    if not self.positioning_frames[areaname] then
        main.log("error", string.format("Area %q unknown, using page", areaname))
        areaname = publisher.default_areaname
    end
    row = row or self:current_row(areaname, framenumber)
    local cur_col = self:current_column(areaname)
    local thisframe = self.positioning_frames[areaname][self:framenumber(areaname)]
    local overshoot = math.max((thisframe.height - thisframe["row"] + 1) * self.gridheight - tex.pageheight, 0)
    local remaining_rows = self:number_of_rows(areaname) - row + 1
    if column and cur_col > column then
        remaining_rows = remaining_rows - 1
    end
    local remaining_height = self.gridheight * remaining_rows + self.grid_dy * (remaining_rows - 1) - overshoot
    return remaining_height
end

-- Returns the current row index of the given frame.
---@param self Grid
---@param areaname? string
---@param framenumber? integer
---@return integer row
function M.current_row(self, areaname, framenumber)
    assert(self)
    areaname = areaname or publisher.default_areaname
    local area = self.positioning_frames[areaname]
    if not area then
        main.log("error", string.format("Area %q not known, using page", tostring(areaname)))
        area = self.positioning_frames[publisher.default_areaname]
    end
    if framenumber and self:framenumber(areaname) < framenumber then
        return 1
    end
    return area.current_row or 1
end

-- Returns the current column of the given area.
---@param self Grid
---@param area string
---@return integer column
function M.current_column(self, area)
    assert(self)
    area = area or publisher.default_areaname
    assert(self.positioning_frames[area], string.format("Area %q not known", tostring(area)))
    return self.positioning_frames[area].current_column or 1
end

-- Sets the current row of an area.
---@param self Grid
---@param row integer
---@param areaname? string
---@param origin? string Caller identifier for log messages.
---@return nil
function M.set_current_row(self, row, areaname, origin)
    assert(self)
    areaname = areaname or publisher.default_areaname
    if not self.positioning_frames[areaname] then
        main.log("error", string.format("Area %q unknown, using page", areaname), "origin", origin or "?")
        areaname = publisher.default_areaname
    end
    local area = self.positioning_frames[areaname]
    area.advance_rows = 0
    area.current_row = row
end

-- Set column for the given area (or the default area, if none given).
-- Sets the current column of an area.
---@param self Grid
---@param column integer
---@param areaname? string
---@param origin? string Caller identifier for log messages.
---@return nil
function M.set_current_column(self, column, areaname, origin)
    assert(self)
    areaname = areaname or publisher.default_areaname
    if not self.positioning_frames[areaname] then
        main.log("error", string.format("Area %q unknown, using page", areaname), "origin", origin or "?")
        areaname = publisher.default_areaname
    end
    local area = self.positioning_frames[areaname]
    area.current_column = column
end

-- The advance_cursor helps in output/text to maintain the
-- current position of the start paragraph
-- Return the overshoot if the next page should start at
-- a row > 1
-- Advances the cursor (row + column) by `rows` rows in the given area,
-- wrapping into the next column / frame as needed.
---@param self Grid
---@param rows integer
---@param areaname string
---@return integer overshoot
function M.advance_cursor(self, rows, areaname)
    assert(self)
    areaname = areaname or publisher.default_areaname
    if not self.positioning_frames[areaname] then
        main.log("error", string.format("Area %q unknown, using page", areaname))
        areaname = publisher.default_areaname
    end
    local area = self.positioning_frames[areaname]
    area.advance_rows = (area.advance_rows or 0) + rows
    area.advance_frame = area.advance_frame or 1
    local current_frame = self:framenumber(areaname)
    local ht = area[current_frame].height
    if not tonumber(ht) then
        main.log("error", "area height not set, why?", "area", areaname or "(default)")
        return 0
    end
    if area.advance_rows >= ht then
        local overshoot = area.advance_rows - ht
        if current_frame + area.advance_frame - 1 < #area then
            area.advance_rows = overshoot
            area.advance_frame = area.advance_frame + 1
            overshoot = 0
        else
            area.advance_rows = ht
        end
        return overshoot
    end
    return 0
end

-- return framenumber,row
-- Returns the next-cell position (row, column) without modifying the grid.
---@param self Grid
---@param areaname string
---@return integer row
---@return integer column
function M.get_advanced_cursor(self, areaname)
    assert(self)
    areaname = areaname or publisher.default_areaname
    if not self.positioning_frames[areaname] then
        main.log("error", string.format("Area %q unknown, using page", areaname))
        areaname = publisher.default_areaname
    end
    local area = self.positioning_frames[areaname]
    area.advance_frame = area.advance_frame or 1
    local current_frame = self:framenumber(areaname)
    local ht = area[current_frame].height
    if not area.current_row then
        self:set_current_row(1, areaname, "get_advanced_cursor")
    end
    local nextframe = current_frame + 1
    if nextframe > #area then
        nextframe = publisher.maxframes
    end
    if area.current_row + area.advance_rows > ht then
        return nextframe, area.advance_rows
    else
        return current_frame + area.advance_frame - 1, area.current_row + area.advance_rows
    end
end

-- Return a table {a,b} where a is the first column
-- (distance in sp from the left edge)
-- and b is the width of the paragraph for the given row
-- Returns the `\parshape` data for paragraphs that flow around already-
-- allocated cells in the area: an array of `{indent, length}` pairs.
---@param self Grid
---@param row integer
---@param areaname string
---@param framenumber? integer
---@param maxwd_sp? integer Maximum line width to use.
---@return integer[]|integer parshape An `{indent, length}` pair, or `0` when the row is fully allocated.
function M.get_parshape(self, row, areaname, framenumber, maxwd_sp)
    local frame_margin_left, frame_margin_top
    local area = self.positioning_frames[areaname]
    local block = area[framenumber]
    frame_margin_left = block.column - 1
    frame_margin_top = block.row - 1
    local first_free_column
    local last_free_column = block.width
    local y = frame_margin_top + row
    for i = 1, block.width do
        local x = frame_margin_left + i
        if self.allocation_x_y[x] and self.allocation_x_y[x][y] == nil then
            first_free_column = first_free_column or i
            last_free_column = i
        end
    end
    if not first_free_column then
        -- w("get_parshape return 0")
        return 0
    end
    local x_start = (first_free_column - 1) * self.gridwidth
    local max_last_column_sp = math.min(last_free_column * self.gridwidth, maxwd_sp)
    local x_width = max_last_column_sp - (first_free_column - 1) * self.gridwidth
    return { x_start, x_width }
end

-- Returns the number of rows of the given frame.
---@param self Grid
---@param areaname? string
---@param framenumber? integer
---@return integer rows
function M.number_of_rows(self, areaname, framenumber)
    assert(self)
    areaname = areaname or publisher.default_areaname
    if not self.positioning_frames[areaname] then
        main.log("error", "Area unknown, using page", "area", areaname, "location", "number_of_rows")
        areaname = publisher.default_areaname
    end
    local current_frame = framenumber or self:framenumber(areaname)
    local area = self.positioning_frames[areaname]
    local height = area[current_frame].height
    if not height then
        main.log("error", "height is nil", "location", "number_of_rows", "area", areaname)
        return 0
    end
    return height
end

-- Returns the number of columns of the given area's current frame.
---@param self Grid
---@param areaname? string
---@return integer columns
function M.number_of_columns(self, areaname)
    assert(self)
    areaname = areaname or publisher.default_area
    if not self.positioning_frames[areaname] then
        main.log("error", "Area unknown, using page", "area", areaname, "location", "number_of_columns")
        areaname = publisher.default_areaname
    end
    local current_frame = self:framenumber(areaname)
    local area = self.positioning_frames[areaname]
    local width = area[current_frame].width
    if not width then
        main.log("error", "width is nil", "location", "number_of_columns", "area", areaname)
        return 0
    end
    return width
end

-- Checks whether grid cell `(x, y)` in the given frame is occupied.
---@param self Grid
---@param x number Column.
---@param y number Row.
---@param areaname? string
---@param framenumber? number
---@return boolean allocated
function M.isallocated(self, x, y, areaname, framenumber)
    assert(self)
    areaname = areaname or publisher.default_areaname
    local frame_margin_left, frame_margin_top
    if areaname == publisher.default_areaname then
        frame_margin_left, frame_margin_top = 0, 0
    else
        local area = self.positioning_frames[areaname]
        if not self.positioning_frames[areaname] then
            main.log("error", string.format("Area %q unknown, using page", areaname))
            areaname = publisher.default_areaname
            frame_margin_left, frame_margin_top = 0, 0
        else
            -- Todo: find the correct block because they can be of different width/height
            framenumber = framenumber or self:framenumber(areaname)
            local block = area[framenumber]
            frame_margin_left = block.column - 1
            frame_margin_top = block.row - 1
        end
    end

    if x > self:number_of_columns(areaname) then
        main.log(
            "error",
            string.format(
                "sd:allocated() out of bounds. x (%d) > #cols (%d) of the area %q.",
                x,
                self:number_of_columns(areaname),
                areaname
            )
        )
        return false
    end
    if y > self:number_of_rows(areaname) then
        main.log(
            "error",
            string.format(
                "sd:allocated() out of bounds. y (%d) > #rows (%d) of the area %q.",
                y,
                self:number_of_rows(areaname),
                areaname
            )
        )
        return false
    end

    x = x + frame_margin_left
    y = y + frame_margin_top

    return self.allocation_x_y[x][y] ~= nil
end

-- Records the total number of rows on the page (typically derived from
-- the page height and grid cell size).
---@param self Grid
---@param rows integer
---@return nil
function M.set_number_of_rows(self, rows)
    assert(self)
    local areaname = publisher.default_areaname
    local area = self.positioning_frames[areaname]
    assert(area, string.format("Area %q not known", tostring(areaname)))
    local current_frame = self:framenumber(areaname)
    area[current_frame].height = rows
end

-- Records the total number of columns on the page.
---@param self Grid
---@param columns integer
---@return nil
function M.set_number_of_columns(self, columns)
    assert(self)
    local area = publisher.default_areaname
    assert(self.positioning_frames[area], string.format("Area %q not known", tostring(area)))
    for _, v in ipairs(self.positioning_frames[area]) do
        v.width = columns
    end
end

-- Returns the number of positioning frames defined for the area.
---@param self Grid
---@param areaname string
---@return integer
function M.number_of_frames(self, areaname)
    areaname = areaname or publisher.default_areaname
    local area = self.positioning_frames[areaname]
    if not area then
        main.log("error", string.format("Area %q is not known on this page. Using the default area (page)", areaname))
        area = self.positioning_frames[publisher.default_areaname]
    end
    return #area
end

-- Return the current frame number for the given area
-- Returns the current frame number of the area.
---@param self Grid
---@param areaname string
---@return integer
function M.framenumber(self, areaname)
    areaname = areaname or publisher.default_areaname
    local area = self.positioning_frames[areaname]
    if not area then
        main.log("error", string.format("Area %q is not known on this page, using page", areaname))
        area = self.positioning_frames[publisher.default_areaname]
    end
    return area.current_frame or 1
end

-- Sets the current frame number of the area.
---@param self Grid
---@param areaname string
---@param number integer
---@return nil
function M.set_framenumber(self, areaname, number)
    areaname = areaname or publisher.default_areaname
    local area = self.positioning_frames[areaname]
    assert(area, string.format("Area %q not known", tostring(areaname)))
    area.current_frame = number
end

-- Set width and height of the given grid (self) to the values wd and ht
-- Stores the grid cell width/height (and optional gaps) on the grid
-- instance and updates the row/column counts to match the page.
---@param self Grid
---@param options { wd?: integer, ht?: integer, nx?: integer, ny?: integer, dx?: integer, dy?: integer }
---@return nil
function M.set_width_height(self, options)
    self.gridwidth = options.wd
    self.gridheight = options.ht
    self.grid_nx = options.nx
    self.grid_ny = options.ny
    self.grid_dx = options.dx or 0
    self.grid_dy = options.dy or 0
    M.calculate_number_gridcells(self)
    self.allocation_x_y = {}
    local noc = self:number_of_columns(publisher.default_areaname)
    if not noc then
        main.log("error", "number of columns not set, why?")
        return
    end
    for i = 1, noc do
        self.allocation_x_y[i] = {}
    end
end

-- Mark the rectangular area given by x and y (top left corner)
-- and the width wd and height ht as "not free" (allocated)
-- Marks a rectangular range of cells as occupied (or, with `keepposition`,
-- merely advances the cursor without occupying them).
---@param self Grid
---@param options table Allocation parameters (`x`, `y`, `width`, `height`, `area`, `keepposition`, `allocate_matrix`, ...).
---@return nil
function M.allocate_cells(self, options)
    local x = options.posx
    local y = options.posy
    local wd = options.width_gridcells
    local ht = options.height_gridcells
    local allocate_matrix = options.allocate_matrix
    local areaname = options.area
    local keepposition = options.keepposition

    if not x then
        return false
    end
    local show_right = false
    local show_bottom = false
    x = math.floor(x)
    y = math.floor(y)
    wd = math.ceil(wd)
    ht = math.ceil(ht)
    areaname = areaname or publisher.default_areaname

    -- when true, we don't want to move the cursor
    if not keepposition then
        local col = math.ceil(x + wd)
        -- Only move the cursor if the current column is past the right edge of the paper
        if col > self:number_of_columns(areaname) and publisher.compatibility.movecursoronrightedge then
            col = 1
            local c = math.ceil(y + 1 + ht - 1)
            self:set_current_row(c, areaname, "allocate_cells")
        else
            self:set_current_row(y, areaname, "allocate_cells 2")
        end
        self:set_current_column(col, areaname, "allocate_cells")
    end

    local grid_conflict = false
    if x + wd - 1 > self:number_of_columns(areaname) then
        main.log("debug", "Object protrudes into the right margin")
        show_right = true
        grid_conflict = true
    end
    if y + ht - 1 > self:number_of_rows(areaname) then
        main.log("debug", "Object protrudes below the last line of the page")
        show_bottom = true
        grid_conflict = true
    end
    local frame_margin_left, frame_margin_top
    if areaname == publisher.default_areaname then
        frame_margin_left, frame_margin_top = 0, 0
    else
        local area = self.positioning_frames[areaname]
        if not area then
            main.log("error", string.format("Area %q not known, expect many errors", tostring(areaname)))
            return
        end
        local block = area[self:framenumber(areaname)]
        frame_margin_left = block.column - 1
        frame_margin_top = block.row - 1
    end
    if allocate_matrix then
        -- We have to take into account the real dimensions of the object
        -- See bug #244 WIP
        -- local htobj = options.objectheight
        -- local wdobj = options.objectwidth
        -- used in output/text when allocate="auto"
        -- special handling for the non rectangular shape
        local cur_x, cur_y
        for _y = 1, ht do
            cur_y = math.ceil(_y / ht * allocate_matrix.max_y)
            for _x = 1, wd do
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
        local max_y = frame_margin_top + math.min(self:number_of_rows(areaname), y + ht - 1)
        local allocation = self.allocation_x_y
        for _x = x + frame_margin_left, max_x do
            local col = allocation[_x]
            if col == nil then
                grid_conflict = true
            else
                local right_edge = show_right and _x == max_x
                for _y = y + frame_margin_top, max_y do
                    local cell = col[_y]
                    if cell then
                        grid_conflict = true
                        col[_y] = cell + 1
                    else
                        col[_y] = (right_edge or (show_bottom and _y == max_y)) and 3 or 1
                    end
                end
            end
        end
    end
    if grid_conflict then
        main.log("debug", "Conflict in grid")
    end
end

-- Return true if the object of width wd fits in the given row
-- at the column.
-- Returns `true` when an object of `width` cells starting at `column` fits
-- in the given `row` (i.e. all involved cells are free).
---@param self Grid
---@param column integer
---@param width integer
---@param row integer
---@return boolean
function M.fits_in_row(self, column, width, row)
    column = math.ceil(column)
    if not column then
        return false
    end
    if column + width - 1 > self:number_of_columns(publisher.default_areaname) then
        return false
    end
    local max_x = column + width - 1
    local allocation = self.allocation_x_y
    for x = column, max_x do
        if allocation[x][row] then
            return false
        end
    end
    return true
end

-- Return true if the given row has some space left to
-- place objects (used for text wrapping around images)
-- Returns `true` when at least one cell in the given row of the area is free.
---@param self Grid
---@param row integer
---@param areaname string
---@return boolean
function M.row_has_some_space(self, row, areaname)
    local maxrows = self:number_of_rows(areaname)
    if row > maxrows then
        return false
    end
    local frame_margin_left, frame_margin_top
    if areaname == publisher.default_areaname then
        frame_margin_left, frame_margin_top = 0, 0
    else
        local area = self.positioning_frames[areaname]
        if not self.positioning_frames[areaname] then
            main.log("error", string.format("Area %q unknown, using page", areaname))
            areaname = publisher.default_areaname
            frame_margin_left, frame_margin_top = 0, 0
        else
            -- Todo: find the correct block because they can be of different width/height
            local block = area[self:framenumber(areaname)]
            frame_margin_left = block.column - 1
            frame_margin_top = block.row - 1
        end
    end

    local width = self:number_of_columns(areaname)
    local max_x = width
    for x = 1 + frame_margin_left, max_x + frame_margin_left do
        if not self.allocation_x_y[x][row + frame_margin_top] then
            return true
        end
    end
    return false
end

-- Same as fits in row, but take area into account (offset)
-- Like `fits_in_row` but constrained to the given area's frame.
---@param self Grid
---@param column integer
---@param width integer
---@param row integer
---@param areaname string
---@return boolean
function M.fits_in_row_area(self, column, width, row, areaname)
    if not column then
        return false
    end

    local frame_margin_left, frame_margin_top
    if areaname == publisher.default_areaname then
        frame_margin_left, frame_margin_top = 0, 0
    else
        local area = self.positioning_frames[areaname]
        if not self.positioning_frames[areaname] then
            main.log("error", string.format("Area %q unknown, using page", areaname))
            frame_margin_left, frame_margin_top = 0, 0
        else
            -- Todo: find the correct block because they can be of different width/height
            local block = area[self:framenumber(areaname)]
            if not tonumber(block.row) then
                main.log("error", "row not set, why? (1)", "area", areaname or "(default)")
                return false
            end
            frame_margin_left = block.column - 1
            frame_margin_top = block.row - 1
        end
    end
    return self:fits_in_row(column + frame_margin_left, width, row + frame_margin_top)
end

-- Return the row in which the object of the given width can be placed.
-- Starting column is @column@, If the page size is not known yet, the next free
-- row will be given. Is the page full (the object cannot be placed), the
-- function returns nil.
-- Finds the first row in the given frame where an object of `width × height`
-- cells fits starting at `column`. Returns `nil` if it does not fit at all.
---@param self Grid
---@param column integer
---@param width integer
---@param height integer
---@param areaname string
---@param framenumber? integer
---@param dataxml table Data XML context, needed when the search advances to a new page.
---@return integer? row
function M.find_suitable_row(self, column, width, height, areaname, framenumber, dataxml)
    -- w("find_suitable_row in grid page %q | areaname %q | column %d | width %d | height %d | framenumber %d",self.pagenumber,areaname,column,width, height,framenumber or -1)
    if not column then
        return nil
    end
    local frame_margin_left, frame_margin_top
    if areaname == publisher.default_areaname then
        frame_margin_left, frame_margin_top = 0, 0
    else
        local area = self.positioning_frames[areaname]
        if not self.positioning_frames[areaname] then
            main.log("error", string.format("Area %q unknown, using page", areaname or "-"))
            areaname = publisher.default_areaname
            frame_margin_left, frame_margin_top = 0, 0
        else
            framenumber = framenumber or self:framenumber(areaname)
            local block = area[framenumber]
            if not tonumber(block.row) then
                main.log("error", "row not set, why?", "area", areaname or "(default)")
                return
            end
            frame_margin_left = block.column - 1
            frame_margin_top = block.row - 1
        end
    end

    local maxrows = self:number_of_rows(areaname)
    if maxrows < self:current_row(areaname) + height - 1 then
        -- doesn't fit, so we try on the next area
        if self:number_of_frames(areaname) > self:framenumber(areaname) then
            publisher.page_helpers.next_area(areaname, self, dataxml, "find_suitable_row")
            return self:find_suitable_row(column, width, height, areaname, nil, dataxml)
        else
            return
        end
    end
    local col_adj = column + frame_margin_left
    local max_z = maxrows + frame_margin_top
    local allocation = self.allocation_x_y
    local max_col = col_adj + width - 1
    local grid_max_col = self:number_of_columns(areaname) + frame_margin_left
    if max_col > grid_max_col then
        main.log(
            "warn",
            "Object too wide for page grid",
            "requested columns",
            max_col,
            "available columns",
            grid_max_col
        )
        max_col = grid_max_col
    end
    local z = self:current_row(areaname, framenumber) + frame_margin_top
    while z <= max_z do
        local row = z - frame_margin_top - 1
        -- when the object is too high, it can't fit, even if the page is empty
        if maxrows - row - height < 0 then
            return nil
        end
        -- check all height rows, break and skip ahead on first conflict
        local fits = true
        for r = z, z + height - 1 do
            local blocked = false
            for x = col_adj, max_col do
                if not allocation[x] then
                    break
                end
                if allocation[x][r] then
                    blocked = true
                    break
                end
            end
            if blocked then
                fits = false
                z = r + 1
                break
            end
        end
        if fits then
            return z - frame_margin_top
        end
    end
    if self.pageheight_known == false then
        return self:number_of_rows(areaname) + 1
    end
    return nil
end

-- Converts a horizontal grid-cell count to scaled points. Strings with
-- explicit units (e.g. `"5mm"`) are converted via `tex.sp`.
---@param self Grid
---@param gridcells integer|string
---@return integer sp
function M.width_sp(self, gridcells)
    if not tonumber(gridcells) then
        return tex.sp(gridcells) or 0
    end
    local wd = self.gridwidth * gridcells + (gridcells - 1) * self.grid_dx
    return math.ceil(math.round(wd, 3))
end

-- Converts a vertical grid-cell count to scaled points.
---@param self Grid
---@param gridcells integer|string
---@return integer sp
function M.height_sp(self, gridcells)
    if not tonumber(gridcells) then
        return tex.sp(gridcells) or 0
    end
    local ht = self.gridheight * gridcells + (gridcells - 1) * self.grid_dy
    return math.ceil(math.round(ht, 3))
end

-- Converts a horizontal grid-cell count to the X coordinate (in sp) of
-- the corresponding cell origin, including the leading gap.
---@param self Grid
---@param gridcells integer|string
---@return integer sp
function M.posx_sp(self, gridcells)
    if not tonumber(gridcells) then
        return tex.sp(gridcells) or 0
    end
    local wd = self.gridwidth * gridcells + gridcells * self.grid_dx
    return math.ceil(math.round(wd, 3))
end

-- Converts a vertical grid-cell count to the Y coordinate of the
-- corresponding cell origin (sp).
---@param self Grid
---@param gridcells integer|string
---@return integer sp
function M.posy_sp(self, gridcells)
    if not tonumber(gridcells) then
        return tex.sp(gridcells) or 0
    end
    local ht = self.gridheight * gridcells + gridcells * self.grid_dy
    return math.ceil(math.round(ht, 3))
end

-- Returns the number of grid cells that fit into the given width (in sp).
---@param self Grid
---@param width_sp integer
---@return integer cells
function M.width_in_gridcells_sp(self, width_sp)
    assert(self)
    local wd_sp = width_sp - self.gridwidth
    if wd_sp <= 500 then
        return 1
    end

    local wd_gridcells = 1
    repeat
        wd_gridcells = wd_gridcells + 1
        wd_sp = wd_sp - self.gridwidth - self.grid_dx
    until wd_sp <= 500
    return wd_gridcells
end

-- Return the number of grid cells for the given height (in scaled points).
-- options: floor = true means we can round down the number of grid cells
--                       if it is not an integer height
-- Returns the number of grid rows that fit into the given height (in sp).
---@param self Grid
---@param height_sp integer
---@param options? table Optional rounding parameters.
---@return integer rows
---@return integer extra_sp Rest height within the last grid cell.
function M.height_in_gridcells_sp(self, height_sp, options)
    assert(self)
    local extra
    options = options or {}
    local threshold = 500
    if options.floor then
        threshold = 0
    end
    if height_sp == 0 then
        return 0, 0
    end
    if not self.gridheight then
        main.log("error", "grid height not set, why?")
        return 0, 0
    end
    local ht_sp = height_sp - self.gridheight
    if ht_sp <= 0 then
        return 1, self.gridheight + ht_sp
    end

    local ht_gridcells = 1
    repeat
        ht_gridcells = ht_gridcells + 1
        ht_sp = ht_sp - self.gridheight - self.grid_dy
        if options.extrathreshold and ht_sp <= options.extrathreshold then
            extra = self.gridheight + ht_sp
            return ht_gridcells - 1, extra
        end
    until ht_sp <= threshold
    extra = ht_sp
    return ht_gridcells, extra
end

-- Draw frame (return PDF-strings)
-- Draws the boundary of a positioning frame on the grid (debug overlay).
---@param self Grid
---@param frame PositioningFrame
---@param width_sp? integer Override frame width in sp.
---@return string pdfstring PDF literal code.
function M.draw_frame(self, frame, width_sp)
    assert(self)
    local ret = {}
    local wd = math.round(sp_to_bp(width_sp), 3)
    ret[#ret + 1] = string.format("q %g w ", wd)
    local paperheight_bp = sp_to_bp(tex.pageheight - self.extra_margin)
    local x, y
    local width, height
    local colorname = frame.draw.color
    local colentry = colors_module.colors[colorname]
    if not colentry then
        main.log("error", string.format("Color %q unknown, reverting to black", colorname or "(no color name given)"))
        colentry = colors_module.colors["black"]
    end

    x = sp_to_bp((frame.column - 1) * (self.gridwidth + self.grid_dx) + self.extra_margin + self.margin_left)
    y = sp_to_bp((frame.row - 1) * (self.gridheight + self.grid_dy) + self.margin_top)
    width = sp_to_bp(frame.width * self.gridwidth + (frame.width - 1) * self.grid_dx)
    height = sp_to_bp(frame.height * self.gridheight + (frame.height - 1) * self.grid_dy)
    ret[#ret + 1] = string.format(
        "q %s  %g %g %g %g re S Q",
        colentry.pdfstring,
        x,
        math.round(paperheight_bp - y, 2),
        width,
        -height
    )

    ret[#ret + 1] = "Q"

    return table.concat(ret, "\n")
end

-- Draws a grid debug overlay for a `Group` virtual area.
---@param group Group
---@return string pdfstring PDF literal code.
function M.draw_grid_group(group)
    main.log("debug", "draw_grid_group", "width", group.contents.width or -1, "height", group.contents.height or -1)
    local ht = group.contents.height
    local wd = group.contents.width
    local ret = { "q 0.4 w [2] 1 d " }
    local gray1 = "0.6"
    local gray2 = "0.8"
    local gray3 = "0.2"
    local color
    local g = group.grid
    local gridwidth = g.gridwidth
    local gridheight = g.gridheight
    local x = 0
    local y = 0
    local i = 0
    while x <= wd do
        -- every 5 grid cells draw a gray rule
        if i % 5 == 0 then
            color = gray1
        else
            color = gray2
        end
        -- every 10 grid cells draw a black rule
        if i % 10 == 0 then
            color = gray3
        end
        i = i + 1

        ret[#ret + 1] =
            string.format("%g G %g %g m %g %g l S", color, sp_to_bp(x), sp_to_bp(y), sp_to_bp(x), sp_to_bp(y - ht))
        x = x + gridwidth
    end
    y = 0
    i = 0
    while y <= ht do
        -- every 5 grid cells draw a gray rule
        if i % 5 == 0 then
            color = gray1
        else
            color = gray2
        end
        -- every 10 grid cells draw a black rule
        if i % 10 == 0 then
            color = gray3
        end
        i = i + 1

        ret[#ret + 1] =
            string.format("%g G %g %g m %g %g l S", color, 0, sp_to_bp(-1 * y), sp_to_bp(wd), sp_to_bp(-1 * y))
        y = y + gridheight
    end

    ret[#ret + 1] = string.format("Q q 0 0 %g %g re S", sp_to_bp(wd), -1 * sp_to_bp(ht))
    ret[#ret + 1] = "Q"
    return table.concat(ret, "\n")
end

-- Draw internal grid (return PDF-strings)
-- Draws the full debug grid (cell rules, row/column numbers, area frames).
---@param self Grid
---@return string? pdfstring PDF literal code.
function M.draw_grid(self)
    assert(self)
    local color
    local ret = {}
    ret[#ret + 1] = "q 0.2 w [2] 1 d "
    local paperheight_bp = sp_to_bp(tex.pageheight - self.extra_margin)
    local paperwidth_bp = sp_to_bp(tex.pagewidth - self.extra_margin)
    local x
    local top, right
    top = math.round(paperheight_bp + sp_to_bp(self.trim), 1)

    local y = math.round(sp_to_bp(self.extra_margin - self.trim), 2)

    local count_col = self:number_of_columns(publisher.default_areaname)
    local gray1 = "0.6"
    local gray2 = "0.8"
    local gray3 = "0.2"
    for i = 0, count_col do
        -- every 5 grid cells draw a grey rule
        if i % 5 == 0 then
            color = gray1
        else
            color = gray2
        end
        -- every 10 grid cells draw a black rule
        if i % 10 == 0 then
            color = gray3
        end
        -- left boundary of each grid cell (horizontal)
        if i < count_col then
            x = math.round(sp_to_bp(i * (self.gridwidth + self.grid_dx) + self.margin_left + self.extra_margin), 1)
            ret[#ret + 1] = string.format("%g G %g %g m %g %g l S", color, x, y, x, top)
        end

        -- right boundary of each grid cell (horizontal)
        if i > 0 and self.grid_dx > 0 or i == count_col then
            x = math.round(
                sp_to_bp(i * self.gridwidth + (i - 1) * self.grid_dx + self.margin_left + self.extra_margin),
                1
            )
            ret[#ret + 1] = string.format("%g G %g %g m %g %g l S", color, x, y, x, top)
        end
    end
    x = math.round(sp_to_bp(self.extra_margin - self.trim), 2)
    local count_row = self:number_of_rows()
    if not count_row then
        main.log("error", "number of rows not set, why?")
        return
    end
    for i = 0, count_row do
        -- every 5 grid cells draw a gray rule
        if i % 5 == 0 then
            color = gray1
        else
            color = gray2
        end
        -- every 10 grid cells draw a black rule
        if i % 10 == 0 then
            color = gray3
        end

        -- top boundary of each grid cell
        if i < count_row then
            y = sp_to_bp(i * self.gridheight + i * self.grid_dy + self.margin_top)
            y = math.round(paperheight_bp - y, 3)
            right = math.round(paperwidth_bp + sp_to_bp(self.trim), 1)
            ret[#ret + 1] = string.format("%s G %g %g m %g %g l S", color, x, y, right, y)
        end

        -- bottom boundary of each grid cell
        if i > 0 and self.grid_dy > 0 or i == count_row then
            y = sp_to_bp(i * self.gridheight + (i - 1) * self.grid_dy + self.margin_top)
            y = math.round(paperheight_bp - y, 3)
            right = math.round(paperwidth_bp, 1)
            ret[#ret + 1] = string.format("%s G %g %g m %g %g l S", color, x, y, right, y)
        end
    end
    ret[#ret + 1] = "Q"
    ret[#ret + 1] = "q"
    local pdfcolorstring
    local width, height
    for _, area in pairs(self.positioning_frames) do
        if area.colorname then
            pdfcolorstring = colors_module.colors[area.colorname].pdfstring
        else
            -- This is the default in the publisher
            pdfcolorstring = " 1 0 0 RG "
        end
        for _, frame in ipairs(area) do
            if frame.width and frame.height then
                x = sp_to_bp(
                    (frame.column - 1) * (self.gridwidth + self.grid_dx) + self.extra_margin + self.margin_left
                )
                y = sp_to_bp((frame.row - 1) * (self.gridheight + self.grid_dy) + self.margin_top)
                width = sp_to_bp(frame.width * self.gridwidth + (frame.width - 1) * self.grid_dx)
                height = sp_to_bp(frame.height * self.gridheight + (frame.height - 1) * self.grid_dy)
                ret[#ret + 1] = string.format(
                    "q %s %g w %g %g %g %g re S Q",
                    pdfcolorstring,
                    0.5,
                    x,
                    math.round(paperheight_bp - y, 2),
                    width,
                    -height
                )
            end
        end
    end
    ret[#ret + 1] = "Q"

    if self.extra_margin ~= 0 and self.trim ~= 0 then -- draw trimbox
        x = sp_to_bp(self.extra_margin - self.trim)
        y = sp_to_bp(self.extra_margin - self.trim)
        width = paperwidth_bp + sp_to_bp(2 * self.trim - self.extra_margin)
        height = sp_to_bp(tex.pageheight - 2 * self.extra_margin + 2 * self.trim)
        ret[#ret + 1] = string.format(
            "q 0.4 w [3 5] 6 d 0.5 G %g %g %g %g re s Q",
            math.round(x, 2),
            math.round(y, 2),
            math.round(width, 2),
            math.round(height, 2)
        )
    end
    return table.concat(ret, "\n")
end

-- Renders a debug heatmap of allocated grid cells.
---@param self Grid
---@return string pdfstring PDF literal code.
function M.draw_gridallocation(self)
    local pdf_literals = {}
    local paperheight = sp_to_bp(tex.pageheight)
    -- where the yellow/red rectangle should be drawn
    local re_wd, re_ht, re_x, re_y, color
    re_ht = sp_to_bp(self.gridheight)
    for y = 1, self:number_of_rows() do
        for x = 1, self:number_of_columns(publisher.default_areaname) do
            if self.allocation_x_y[x][y] then
                re_wd = sp_to_bp(self.gridwidth)
                re_x = sp_to_bp(self.margin_left + self.extra_margin)
                    + (x - 1) * sp_to_bp(self.gridwidth + self.grid_dx)
                re_y = paperheight
                    - sp_to_bp(self.margin_top + self.extra_margin)
                    - y * sp_to_bp(self.gridheight)
                    - (y - 1) * sp_to_bp(self.grid_dy)
                if self.allocation_x_y[x][y] == 1 then
                    color = " 0 0 1 0 k "
                elseif self.allocation_x_y[x][y] == 2 then
                    color = " 0 0.6 0.6 0 k "
                else
                    color = " 0 1 1 0 k "
                end
                pdf_literals[#pdf_literals + 1] =
                    string.format("q %s 1 0 0 1 %g %g cm 0 0 %g %g re f Q ", color, re_x, re_y, re_wd, re_ht)
            end
        end
    end
    return table.concat(pdf_literals, "\n")
end

-- Return the Position of the grid cell from the left and top border (in sp)
-- Computes the absolute (x, y) sp position for placing an object at
-- grid cell `(x, y)` of the given area, honoring valign/halign within
-- the cell rectangle.
---@param self Grid
---@param x integer Column.
---@param y integer Row.
---@param areaname string
---@param wd integer Object width in sp.
---@param ht integer Object height in sp.
---@param valign? "top"|"middle"|"bottom"
---@param halign? "left"|"center"|"right"
---@param width_gridcells integer
---@param height_gridcells integer
---@return integer|nil x_sp X position in sp; `nil` on error.
---@return integer|string y_sp Y position in sp, or an error message when `x_sp` is `nil`.
function M.position_grid_cell(self, x, y, areaname, wd, ht, valign, halign, width_gridcells, height_gridcells)
    local x_sp, y_sp
    if not self.margin_left then
        return nil, "Left margin not defined. Perhaps the <Margin> command in Pagetype is missing?"
    end
    local frame_margin_left, frame_margin_top

    if areaname == publisher.default_areaname then
        frame_margin_left, frame_margin_top = 0, 0
    else
        if not self.positioning_frames[areaname] then
            main.log("error", string.format("Area %q unknown, using page", areaname))
            frame_margin_left, frame_margin_top = 0, 0
        else
            local area = self.positioning_frames[areaname]
            local current_frame = area.current_frame or 1
            -- todo: find the correct block, the blocks can be of different width / height
            local block = area[current_frame]
            frame_margin_left = block.column - 1
            frame_margin_top = block.row - 1
        end
    end

    x_sp = (frame_margin_left + x - 1) * (self.gridwidth + self.grid_dx) + self.margin_left + self.extra_margin
    y_sp = (frame_margin_top + y - 1) * (self.gridheight + self.grid_dy) + self.margin_top + self.extra_margin
    if valign then
        local overshoot = ((height_gridcells - 1) * self.grid_dy + height_gridcells * self.gridheight) % ht
        if valign == "bottom" and overshoot > 0 then
            y_sp = y_sp + overshoot
        elseif valign == "middle" then
            y_sp = y_sp + overshoot / 2
        end
    end
    if halign then
        local overshoot = ((width_gridcells - 1) * self.grid_dx + width_gridcells * self.gridwidth) % wd
        if halign == "right" then
            x_sp = x_sp + overshoot
        elseif halign == "center" then
            x_sp = x_sp + overshoot / 2
        end
    end
    return x_sp, y_sp
end

-- Arguments must be in sp (''scaled points'')
-- Stores the page margins on the grid; recomputed cell counts follow.
---@param self Grid
---@param left integer sp
---@param top integer sp
---@param right integer sp
---@param bottom integer sp
---@return nil
function M.set_margin(self, left, top, right, bottom)
    if not tonumber(bottom) then
        main.log("error", "Set margin: four arguments must be given.")
        self.margin_left = publisher.onecm_sp
        self.margin_right = publisher.onecm_sp
        self.margin_top = publisher.onecm_sp
        self.margin_bottom = publisher.onecm_sp
        return
    end

    self.margin_left = left
    self.margin_right = right
    self.margin_top = top
    self.margin_bottom = bottom
end

-- ![width calculation](../img/gridnx.svg)
-- Recomputes the number of rows and columns from the page size, margins
-- and grid cell dimensions.
---@param self Grid
---@return nil
function M.calculate_number_gridcells(self)
    assert(self)
    assert(self.margin_left, "Margin not set yet!")
    self.pageheight_known = true
    if self.pagenumber == -999 then
        -- a group
        -- This is an ugly workaround. We should not make the group height 10 times the current page height.
        -- FIXME!!
        if not (self.gridwidth and self.gridheight) then
            main.log("error", "grid width or height not set, why?")
            return
        end
        local current_page = publisher.pages[publisher.current_pagenumber]
        local pagewidth = current_page.width
        local margin_left = current_page.grid.margin_left
        local margin_right = current_page.grid.margin_right
        local noc =
            math.floor(math.round((pagewidth - margin_left - margin_right - 2 * self.extra_margin) / self.gridwidth, 4))
        self:set_number_of_columns(noc)
        self:set_number_of_rows(
            math.ceil(
                math.round(
                    (10 * tex.pageheight - self.margin_top - self.margin_bottom - 2 * self.extra_margin)
                        / self.gridheight,
                    4
                )
            )
        )
    else
        local pagearea_x, pagearea_y
        pagearea_x = tex.pagewidth - self.margin_left - self.margin_right - 2 * self.extra_margin
        pagearea_y = tex.pageheight - self.margin_top - self.margin_bottom - 2 * self.extra_margin

        if self.grid_nx and self.grid_nx ~= 0 then
            -- See the image
            self:set_number_of_columns(self.grid_nx)
            local sum_distances = (self.grid_nx - 1) * self.grid_dx
            self.gridwidth = math.floor((pagearea_x - sum_distances) / self.grid_nx)
        else
            self:set_number_of_columns(self:width_in_gridcells_sp(pagearea_x))
        end

        if self.grid_ny and self.grid_ny ~= 0 then
            self:set_number_of_rows(self.grid_ny)
            local sum_distances = (self.grid_ny - 1) * self.grid_dy
            self.gridheight = math.floor((pagearea_y - sum_distances) / self.grid_ny)
        else
            if not self.gridheight then
                main.log("error", "grid height not set, why?")
            else
                self:set_number_of_rows(math.ceil(math.round(pagearea_y / self.gridheight, 2)))
            end
        end
    end

    main.log(
        "info",
        "Grid",
        "rows",
        tostring(self:number_of_rows()),
        "columns",
        self:number_of_columns(publisher.default_areaname)
    )
end

-- Sets the used area for the page (used by crop="yes")
-- Defines a positioning frame on the grid (one entry in
-- `positioning_frames`). Coordinates are in grid cells.
---@param self Grid
---@param x integer Column of the top-left corner.
---@param y integer Row of the top-left corner.
---@param wd integer Width in cells.
---@param ht integer Height in cells.
---@return nil
function M.setarea(self, x, y, wd, ht)
    if self.dimensions[1] == nil then
        self.dimensions[1] = x
    else
        self.dimensions[1] = math.min(self.dimensions[1], x)
    end
    if self.dimensions[2] == nil then
        self.dimensions[2] = y
    else
        self.dimensions[2] = math.min(self.dimensions[2], y)
    end
    if self.dimensions[3] == nil then
        self.dimensions[3] = x + wd
    else
        self.dimensions[3] = math.max(self.dimensions[3], x + wd)
    end
    if self.dimensions[4] == nil then
        self.dimensions[4] = y + ht
    else
        self.dimensions[4] = math.max(self.dimensions[4], y + ht)
    end
end

-- Sets the page's `/TrimBox` (and optionally extra page attributes such
-- as `/StructParents` for tagged PDFs) and adjusts the page size to
-- include cut/trim marks.
---@param self Grid
---@param crop integer? Crop in sp.
---@param extrapageattributes string? Additional PDF page-dict attributes.
---@return nil
function M.trimbox(self, crop, extrapageattributes)
    assert(self)
    local x, y, wd, ht =
        sp_to_bp(self.extra_margin),
        sp_to_bp(self.extra_margin),
        sp_to_bp(tex.pagewidth - self.extra_margin),
        sp_to_bp(tex.pageheight - self.extra_margin)
    local b_x, b_y, b_wd, b_ht =
        sp_to_bp(self.extra_margin - self.trim),
        sp_to_bp(self.extra_margin - self.trim),
        sp_to_bp(tex.pagewidth - self.extra_margin + self.trim),
        sp_to_bp(tex.pageheight - self.extra_margin + self.trim)
    local attrstring = { extrapageattributes }
    attrstring[#attrstring + 1] = string.format("/TrimBox [ %g %g %g %g]", x, y, wd, ht)
    attrstring[#attrstring + 1] = string.format("/BleedBox [%g %g %g %g]", b_x, b_y, b_wd, b_ht)
    if crop == true then
        attrstring[#attrstring + 1] = string.format(
            "/CropBox [%g %g %g %g]",
            sp_to_bp(self.dimensions[1]),
            sp_to_bp(tex.pageheight - self.dimensions[2]),
            sp_to_bp(self.dimensions[3]),
            sp_to_bp(tex.pageheight - self.dimensions[4])
        )
    elseif tonumber(crop) then
        attrstring[#attrstring + 1] = string.format(
            "/CropBox [%g %g %g %g]",
            sp_to_bp(self.dimensions[1] - 2 * crop),
            sp_to_bp(tex.pageheight - self.dimensions[2] + 2 * crop),
            sp_to_bp(self.dimensions[3] + 2 * crop),
            sp_to_bp(tex.pageheight - self.dimensions[4] - 2 * crop)
        )
    end
    if publisher.options.format == "PDF/UA" then
        attrstring[#attrstring + 1] = "/Tabs /S"
    end

    pdf.setpageattributes(table.concat(attrstring, " "))
end

-- Adds cut marks at the four corners of the trim box.
---@param self Grid
---@param length integer Mark length in sp.
---@param distance integer Distance from the trim box in sp.
---@param width integer Stroke width in sp.
---@return nil
function M.cutmarks(self, length, distance, width)
    local x, y, wd, ht =
        sp_to_bp(self.extra_margin),
        sp_to_bp(self.extra_margin),
        sp_to_bp(tex.pagewidth - self.extra_margin),
        sp_to_bp(tex.pageheight - self.extra_margin)
    local ret = {}
    local distance_bp, length_bp, width_bp
    if not distance then
        distance_bp = sp_to_bp(self.trim)
    else
        distance_bp = sp_to_bp(distance)
    end
    if distance_bp < 5 then
        distance_bp = 5
    end
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
    ret[#ret + 1] =
        string.format("q 0 G %g w %g %g m %g %g l S Q", width_bp, x, y - distance_bp, x, y - length_bp - distance_bp) -- v
    ret[#ret + 1] =
        string.format("q 0 G %g w %g %g m %g %g l S Q", width_bp, x - distance_bp, y, x - length_bp - distance_bp, y) -- h
    -- bottom right
    ret[#ret + 1] =
        string.format("q 0 G %g w %g %g m %g %g l S Q", width_bp, wd, y - distance_bp, wd, y - length_bp - distance_bp)
    ret[#ret + 1] =
        string.format("q 0 G %g w %g %g m %g %g l S Q", width_bp, wd + distance_bp, y, wd + distance_bp + length_bp, y)
    -- top right
    ret[#ret + 1] = string.format(
        "q 0 G %g w %g %g m %g %g l S Q",
        width_bp,
        wd,
        ht + distance_bp,
        wd,
        ht + distance_bp + length_bp
    )
    ret[#ret + 1] = string.format(
        "q 0 G %g w %g %g m %g %g l S Q",
        width_bp,
        wd + distance_bp,
        ht,
        wd + distance_bp + length_bp,
        ht
    )
    -- top left
    ret[#ret + 1] =
        string.format("q 0 G %g w %g %g m %g %g l S Q", width_bp, x, ht + distance_bp, x, ht + distance_bp + length_bp)
    ret[#ret + 1] =
        string.format("q 0 G %g w %g %g m %g %g l S Q", width_bp, x - distance_bp, ht, x - length_bp - distance_bp, ht)

    return table.concat(ret, "\n")
end

-- Adds trim marks (separate from cut marks) at the four corners.
---@param self Grid
---@param length integer Mark length in sp.
---@param distance integer Distance from the trim box in sp.
---@param width integer Stroke width in sp.
---@return nil
function M.trimmarks(self, length, distance, width)
    local x, y, wd, ht =
        sp_to_bp(self.extra_margin - self.trim),
        sp_to_bp(self.extra_margin - self.trim),
        sp_to_bp(tex.pagewidth - self.extra_margin + self.trim),
        sp_to_bp(tex.pageheight - self.extra_margin + self.trim)
    local ret = {}
    local distance_bp, length_bp, width_bp
    if not distance then
        distance_bp = sp_to_bp(self.trim)
    else
        distance_bp = sp_to_bp(distance)
    end
    if distance_bp < 5 then
        distance_bp = 5
    end
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
    ret[#ret + 1] =
        string.format("q 0 G %g w %g %g m %g %g l S Q", width_bp, x, y - distance_bp, x, y - length_bp - distance_bp) -- v
    ret[#ret + 1] =
        string.format("q 0 G %g w %g %g m %g %g l S Q", width_bp, x - distance_bp, y, x - length_bp - distance_bp, y) -- h
    -- bottom right
    ret[#ret + 1] =
        string.format("q 0 G %g w %g %g m %g %g l S Q", width_bp, wd, y - distance_bp, wd, y - length_bp - distance_bp)
    ret[#ret + 1] =
        string.format("q 0 G %g w %g %g m %g %g l S Q", width_bp, wd + distance_bp, y, wd + distance_bp + length_bp, y)
    -- top right
    ret[#ret + 1] = string.format(
        "q 0 G %g w %g %g m %g %g l S Q",
        width_bp,
        wd,
        ht + distance_bp,
        wd,
        ht + distance_bp + length_bp
    )
    ret[#ret + 1] = string.format(
        "q 0 G %g w %g %g m %g %g l S Q",
        width_bp,
        wd + distance_bp,
        ht,
        wd + distance_bp + length_bp,
        ht
    )
    -- top left
    ret[#ret + 1] =
        string.format("q 0 G %g w %g %g m %g %g l S Q", width_bp, x, ht + distance_bp, x, ht + distance_bp + length_bp)
    ret[#ret + 1] =
        string.format("q 0 G %g w %g %g m %g %g l S Q", width_bp, x - distance_bp, ht, x - length_bp - distance_bp, ht)

    return table.concat(ret, "\n")
end

file_end("grid.lua")

return M
