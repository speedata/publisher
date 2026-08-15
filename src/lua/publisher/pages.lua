-- Page setup, output positioning and shipout.
--
--  pages.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("pages.lua")

local publisher = require("publisher")

---@class pages_module
local M = {}

local page = require("publisher.page")
local colors_module = require("publisher.colors")
local metapost = require("publisher.metapost")
local spotcolors = require("spotcolors")

-- Returns `true` when a page table has already been built for `pagenumber`.
---@param pagenumber integer
---@return boolean
function M.page_initialized_p(pagenumber)
    return publisher.pages[pagenumber] ~= nil
end

-- Ships out the given page node list as the next PDF page. Records
-- structure-tree information in PDF/UA mode and updates `pagelabels`,
-- `pagenum_tbl`, `pages_shippedout`.
---@param nodelist Node Page contents (typically a vbox).
---@param pagenumber integer Logical page number.
---@param dataxml? table Data XML context for matter resolution.
---@return nil
function M.shipout(nodelist, pagenumber, dataxml)
    publisher.pages_shippedout[pagenumber] = true
    publisher.pagenum_tbl[#publisher.pagenum_tbl + 1] = pagenumber

    local cp = publisher.pages[pagenumber]
    local colorname = cp.defaultcolor
    if not publisher.matters[cp.matter] then
        local defaultmatter
        if publisher.newxpath then
            defaultmatter = dataxml and publisher.xpath.string_value(dataxml.vars["_matter"]) or "mainmatter"
        else
            defaultmatter = publisher.xpath.get_variable("_matter")
        end
        main.log("error", string.format("matter %q unknown, revert to %s", cp.matter or "-", defaultmatter))
        cp.matter = defaultmatter
    end
    publisher.pagelabels[pagenumber] = {
        pagenumber = pagenumber,
        matter = cp.matter,
    }
    if colorname then
        if not colors_module.colors[colorname] then
            main.log("error", "Pagetype / defaultcolor: color is not defined yet.", "name", colorname)
        else
            local colorindex = colors_module.colors[colorname].index
            nodelist = publisher.nodes.set_color_if_necessary(nodelist, colorindex)
            nodelist = node.vpack(nodelist)
        end
    end
    if publisher.options.format == "PDF/UA" then
        publisher.insert_struct_elements(nodelist, cp)
        -- second argument is extra page attributes
        cp.grid:trimbox(publisher.options.crop, string.format("/StructParents %d", cp.structparents))
    else
        cp.grid:trimbox(publisher.options.crop)
    end

    if publisher.options.showdebug then
        local visdebug = require("lua-visual-debug")
        visdebug.show_page_elements(nodelist)
    end
    nodelist = M.dothingsafteroutput(cp, nodelist)
    tex.box[666] = nodelist
    tex.shipout(666)
end

---@class OutputAbsoluteParam
---@field nodelist Node The box to be placed.
---@field x integer Horizontal offset from the left edge (sp).
---@field y integer Vertical offset from the top edge (sp).
---@field clipatmargin? boolean Clip objects so they do not appear in the page margin.
---@field rotate? number Rotation in degrees, counter-clockwise (0–360).
---@field origin_x? number Rotation origin X percentage (0 = left, 100 = right).
---@field origin_y? number Rotation origin Y percentage (0 = top, 100 = bottom).
---@field allocate? boolean Mark touched cells as allocated.
---@field grid? table Override grid (defaults to `publisher.current_grid`).
---@field keepposition? boolean Force the object to stay at its absolute position.
---@field shift_left? integer Allocation shift to the left in grid cells.
---@field shift_up? integer Allocation shift upwards in grid cells.
---@field width_gridcells? integer Width of the allocated region.
---@field height_gridcells? integer Height of the allocated region.
---@field allocate_matrix? table Image-shape occupancy matrix.
---@field allocate_left? integer Extra allocation in sp.
---@field allocate_right? integer Extra allocation in sp.
---@field allocate_top? integer Extra allocation in sp.
---@field allocate_bottom? integer Extra allocation in sp.

-- Places an object at an absolute position given in scaled points.
---@param param OutputAbsoluteParam
---@return nil
function M.output_absolute_position(param)
    local x = param.x
    local y = param.y
    local nodelist = param.nodelist
    local keepposition = param.keepposition
    local r = assert(param.grid or publisher.current_grid)
    -- We don't necessarily output things on a page, we can output them in a virtual page, called _group_.
    if publisher.current_group then
        -- Put the contents of the nodelist into the current group
        local group = publisher.groups[publisher.current_group]
        assert(group)

        local n = publisher.nodes.add_glue(nodelist, "head", { width = x })
        n = node.hpack(n)
        n = publisher.nodes.add_glue(n, "head", { width = y })
        n = node.vpack(n)

        if group.contents then
            -- There is already something in the group, we must add the new nodelist.
            -- The size of the new group: max(size of old group, size of new nodelist)
            local new_width, new_height
            new_width = math.max(n.width, group.contents.width)
            new_height = math.max(n.height + n.depth, group.contents.height + group.contents.depth)

            group.contents.width = 0
            group.contents.height = 0
            group.contents.depth = 0

            local tail = node.tail(group.contents)
            tail.next = n
            n.prev = tail

            group.contents = node.vpack(group.contents)
            group.contents.width = new_width
            group.contents.height = new_height
            group.contents.depth = 0
        else
            -- group is empty
            group.contents = n
        end
        if param.allocate then
            r:allocate_cells({
                posx = x - (param.shift_left or 0),
                posy = y - (param.shift_up or 0),
                width_gridcells = param.width_gridcells,
                height_gridcells = param.height_gridcells,
                allocate_matrix = param.allocate_matrix,
            })
        end
    else
        if param.allocate then
            local additional_width, additional_height = 0, 0

            local startcol_sp = x - publisher.current_grid.margin_left
            local startrow_sp = y - publisher.current_grid.margin_top

            if param.allocate_left then
                startcol_sp = startcol_sp - param.allocate_left
                additional_width = additional_width + param.allocate_left
            end
            if param.allocate_right then
                additional_width = additional_width + param.allocate_right
            end
            if param.allocate_top then
                startrow_sp = startrow_sp - param.allocate_top
                additional_height = additional_height + param.allocate_top
            end
            if param.allocate_bottom then
                additional_height = additional_height + param.allocate_bottom
            end

            local startcol = math.floor(
                math.round((startcol_sp - publisher.current_grid.extra_margin) / publisher.current_grid.gridwidth, 3)
            ) + 1
            local delta_x = startcol_sp - publisher.current_grid:width_sp(startcol - 1)
            if delta_x < 100 then
                delta_x = 0
            end

            local wd_grid = publisher.current_grid:width_in_gridcells_sp(
                nodelist.width + delta_x + additional_width - publisher.current_grid.extra_margin
            )
            local startrow = math.floor(
                math.round((startrow_sp - publisher.current_grid.extra_margin) / publisher.current_grid.gridheight, 3)
            ) + 1
            local delta_y = startrow_sp - publisher.current_grid:height_sp(startrow - 1)
            if delta_y < 100 then
                delta_y = 0
            end
            local ht_grid = publisher.current_grid:height_in_gridcells_sp(
                nodelist.height + delta_y + additional_height - publisher.current_grid.extra_margin
            )
            local _x, _y, _wd, _ht = startcol, startrow, wd_grid, ht_grid
            if _x < 1 then
                _wd = _wd + _x - 1
                _x = 1
            end
            if _y < 1 then
                _ht = _ht + _y - 1
                _y = 1
            end

            publisher.current_grid:allocate_cells({
                posx = _x,
                posy = _y,
                width_gridcells = _wd,
                height_gridcells = _ht,
                keepposition = keepposition,
                allocate_matrix = param.allocate_matrix,
            })
        end

        if node.has_attribute(nodelist, publisher.att_shift_left) then
            x = x - (node.has_attribute(nodelist, publisher.att_shift_left) or 0)
            y = y - (node.has_attribute(nodelist, publisher.att_shift_up) or 0)
        end

        if param.rotate then
            nodelist = publisher.drawing.rotate(nodelist, param.rotate, param.origin_x or 0, param.origin_y or 0)
        end

        if param.clipatmargin then
            local wd = nodelist.width
            local ht = nodelist.height + nodelist.depth

            local clipleft = math.max(r.margin_left + r.extra_margin - x, 0)
            local cliptop = math.max(r.extra_margin + r.margin_top - y, 0)
            local clipright = math.max(-1 * (tex.pagewidth - r.extra_margin - r.margin_right - x - wd), 0)
            local pageframe = r.positioning_frames._page[1]
            local maxht = r.extra_margin
                + r.margin_top
                + pageframe.height * r.gridheight
                + (pageframe.height - 1) * r.grid_dy
            local clipbottom = math.max(-1 * (maxht - y - ht), 0)

            nodelist = publisher.drawing.clip({
                box = nodelist,
                clip_top_sp = cliptop,
                clip_bottom_sp = clipbottom,
                clip_left_sp = clipleft,
                clip_right_sp = clipright,
                clip_width_sp = 0,
                clip_height_sp = 0,
                method = "frame",
            })
        end

        local n = publisher.nodes.add_glue(nodelist, "head", { width = x })
        n = node.hpack(n)
        n = publisher.nodes.add_glue(n, "head", { width = y })
        n = node.vpack(n)
        n.width = 0
        n.height = 0
        n.depth = 0
        local tail = node.tail(publisher.pages[publisher.current_pagenumber].pagebox)
        tail.next = n
        n.prev = tail
    end
end

---@class OutputAtParam
---@field nodelist Node The box to be placed.
---@field x integer Horizontal distance from the left edge in grid cells.
---@field y integer Vertical distance from the top edge in grid cells.
---@field allocate? boolean Mark touched cells as occupied.
---@field area? string Target area name; defaults to the current page area.
---@field clipatmargin? boolean Clip objects so they do not appear in the page margin.
---@field valign? "top"|"middle"|"bottom"
---@field halign? "left"|"center"|"right"
---@field allocate_matrix? table Image-shape occupancy matrix.
---@field allocate_left? integer Extra allocation in sp.
---@field allocate_right? integer Extra allocation in sp.
---@field allocate_top? integer Extra allocation in sp.
---@field allocate_bottom? integer Extra allocation in sp.
---@field vreference? string Vertical reference ("bottom" shifts by box height).
---@field pagenumber? integer Target page number; defaults to current.
---@field keepposition? boolean Whether to move the local cursor after placement.
---@field grid? table Override grid object.
---@field rotate? number Rotation in degrees, counter-clockwise (0–360).
---@field origin_x? number Rotation origin X percentage (0 = left, 100 = right).
---@field origin_y? number Rotation origin Y percentage (0 = top, 100 = bottom).
---@field framewidth? integer Frame width in sp when `frame="solid"`.

-- Places an object at the given grid cell `(x, y)`. With `allocate=true`,
-- the touched cells are marked as occupied.
---@param param OutputAtParam
---@return nil
function M.output_at(param)
    local _wd, _ht, _dp = node.dimensions(param.nodelist)
    if param.framewidth then
        _wd = _wd + param.framewidth
        _ht = _ht + param.framewidth
    end

    -- current_grid is important here, because it can be a group
    local r = assert(param.grid or publisher.current_grid)

    local outputpage = publisher.current_pagenumber
    if param.pagenumber then
        outputpage = param.pagenumber
    end
    local nodelist = param.nodelist
    if publisher.options.showobjects then
        nodelist = publisher.drawing.boxit(nodelist)
    end
    local x = param.x
    local y = param.y

    local additional_width, additional_height = 0, 0
    local shift_left, shift_up = 0, 0

    if param.allocate_left and param.allocate_left > 100 then
        shift_left = r:width_in_gridcells_sp(param.allocate_left)
        additional_width = additional_width + r:width_in_gridcells_sp(param.allocate_left)
    end
    if param.allocate_right and param.allocate_right > 100 then
        additional_width = additional_width + r:width_in_gridcells_sp(param.allocate_right)
    end
    if param.allocate_top and param.allocate_top > 100 then
        shift_up = r:height_in_gridcells_sp(param.allocate_top)
        additional_height = additional_height + r:height_in_gridcells_sp(param.allocate_top)
    end
    if param.allocate_bottom and param.allocate_bottom > 100 then
        additional_height = additional_height + r:height_in_gridcells_sp(param.allocate_bottom)
    end

    local allocate = param.allocate
    local allocate_matrix = param.allocate_matrix
    local area = param.area or publisher.default_areaname
    local valign = param.valign
    local halign = param.halign
    local keepposition = param.keepposition

    local wd = nodelist.width
    local ht = nodelist.height + nodelist.depth

    -- For grid allocation
    local width_gridcells = r:width_in_gridcells_sp(wd)
    if additional_width > 0 then
        width_gridcells = width_gridcells + additional_width
    end
    local height_gridcells = r:height_in_gridcells_sp(ht, { floor = (param.vreference == "bottom") })
    if additional_height > 0 then
        height_gridcells = height_gridcells + additional_height
    end

    local delta_x, delta_y = r:position_grid_cell(x, y, area, wd, ht, valign, halign, width_gridcells, height_gridcells)

    if not delta_x then
        -- if delta_x is nil, delta_y has the error message
        main.log("error", tostring(delta_y))
        exit()
        return
    end
    ---@cast delta_y integer

    if node.has_attribute(nodelist, publisher.att_shift_left) then
        delta_x = delta_x - node.has_attribute(nodelist, publisher.att_shift_left)
        delta_y = delta_y - node.has_attribute(nodelist, publisher.att_shift_up)
    end
    if param.clipatmargin then
        local clipleft = math.max(r.margin_left + r.extra_margin - delta_x, 0)
        local cliptop = math.max(r.extra_margin + r.margin_top - delta_y, 0)
        local clipright = math.max(-1 * (tex.pagewidth - r.extra_margin - r.margin_right - delta_x - wd), 0)
        local pageframe = r.positioning_frames._page[1]
        local maxht = r.extra_margin
            + r.margin_top
            + pageframe.height * r.gridheight
            + (pageframe.height - 1) * r.grid_dy
        local clipbottom = math.max(-1 * (maxht - delta_y - ht), 0)

        nodelist = publisher.drawing.clip({
            box = nodelist,
            clip_top_sp = cliptop,
            clip_bottom_sp = clipbottom,
            clip_left_sp = clipleft,
            clip_right_sp = clipright,
            clip_width_sp = 0,
            clip_height_sp = 0,
            method = "frame",
        })
    end

    local extra_crop = 0
    if param.framewidth then
        extra_crop = param.framewidth
    end

    -- set the crop area
    r:setarea(delta_x - extra_crop, delta_y - extra_crop, _wd + extra_crop, _ht + extra_crop + _dp)

    -- We don't necessarily output things on a page, we can output them in a virtual page, called _group_.
    if publisher.current_group then
        -- Put the contents of the nodelist into the current group
        local group = publisher.groups[publisher.current_group]
        assert(group)

        local n = publisher.nodes.add_glue(nodelist, "head", { width = delta_x })
        n = node.hpack(n)
        n = publisher.nodes.add_glue(n, "head", { width = delta_y })
        n = node.vpack(n)

        if group.contents then
            -- There is already something in the group, we must add the new nodelist.
            -- The size of the new group: max(size of old group, size of new nodelist)
            local new_width, new_height
            new_width = math.max(n.width, group.contents.width)
            new_height = math.max(n.height + n.depth, group.contents.height + group.contents.depth)

            group.contents.width = 0
            group.contents.height = 0
            group.contents.depth = 0

            local tail = node.tail(group.contents)
            tail.next = n
            n.prev = tail

            group.contents = node.vpack(group.contents)
            group.contents.width = new_width
            group.contents.height = new_height
            group.contents.depth = 0
        else
            -- group is empty
            group.contents = n
        end
        if allocate then
            r:allocate_cells({
                posx = x - shift_left,
                posy = y - shift_up,
                width_gridcells = width_gridcells,
                height_gridcells = height_gridcells,
                allocate_matrix = allocate_matrix,
            })
        end
    else
        -- Put it on the current page
        if allocate then
            r:allocate_cells({
                posx = x - shift_left,
                posy = y - shift_up,
                width_gridcells = width_gridcells,
                height_gridcells = height_gridcells,
                allocate_matrix = allocate_matrix,
                area = area,
                keepposition = keepposition,
                objectwidth = _wd,
                objectheight = _ht + _dp,
            })
        end
        if param.rotate then
            nodelist = publisher.drawing.rotate(nodelist, param.rotate, param.origin_x or 0, param.origin_y or 0)
        end

        M.place_at(publisher.pages[outputpage].pagebox, nodelist, delta_x, delta_y)
    end
end

-- Appends `nodelist` to `pagebox` with absolute glue offsets so it lands
-- at `(x_sp, y_sp)` from the page's origin.
---@param pagebox Node Page node list (typically a vbox).
---@param nodelist Node Object to place.
---@param x_sp integer Horizontal offset in sp.
---@param y_sp integer Vertical offset in sp.
---@return nil
function M.place_at(pagebox, nodelist, x_sp, y_sp)
    local tail = node.tail(pagebox)
    local n = publisher.nodes.add_glue(nodelist, "head", { subtype = 1000, width = x_sp })
    n = node.hpack(n)
    n = publisher.nodes.add_glue(n, "head", { subtype = 1001, width = y_sp })
    n = node.vpack(n)
    n.width = 0
    n.height = 0
    n.depth = 0

    tail.next = n
    n.prev = tail
end

-- Walks `publisher.masterpages` in reverse order and returns the layout
-- XML body of the first masterpage whose `is_pagetype` predicate matches,
-- or whose name equals `publisher.nextpage`.
---@param pagenumber integer
---@param data table Data XML context for predicate evaluation.
---@return table|false layoutxml `false` if nothing matched.
function M.detect_pagetype(pagenumber, data)
    -- ugly hack. file global variables are a bad idea.
    if not publisher.newxpath then
        publisher.xpath.push_state()
    end
    local cp = publisher.current_pagenumber
    publisher.current_pagenumber = pagenumber
    local ret
    for i = #publisher.masterpages, 1, -1 do
        local pagetype = publisher.masterpages[i]
        if publisher.nextpage then
            if pagetype.name == publisher.nextpage then
                main.log("info", "Create page", "type", pagetype.name or "(detect_pagetype)", "pagenumber", pagenumber)
                publisher.nextpage = nil
                return pagetype.res
            end
        else
            if publisher.newxpath then
                assert(data, "detect_pagetype")
                local seq, msg = data:eval(pagetype.is_pagetype)
                if msg then
                    main.log("error", msg)
                end
                local ok
                ok, msg = publisher.xpath.boolean_value(seq)
                if msg then
                    main.log("error", msg)
                end
                if ok then
                    main.log(
                        "info",
                        "Create page",
                        "type",
                        pagetype.name or "(detect_pagetype)",
                        "pagenumber",
                        pagenumber
                    )
                    ret = pagetype.res
                    publisher.current_pagenumber = cp
                    return ret
                end
            else
                if publisher.xpath.parse(data, pagetype.is_pagetype, pagetype.ns) == true then
                    main.log(
                        "info",
                        "Create page",
                        "type",
                        pagetype.name or "(detect_pagetype)",
                        "pagenumber",
                        pagenumber
                    )
                    ret = pagetype.res
                    publisher.xpath.pop_state()
                    publisher.current_pagenumber = cp
                    return ret
                end
            end
        end
    end
    main.log("error", "Can't find correct page type!")
    publisher.current_pagenumber = cp
    if not publisher.newxpath then
        publisher.xpath.pop_state()
    end
    return false
end

-- Builds the page table for `pagenumber` (or for `current_pagenumber`),
-- runs the masterpage instructions, and sets `current_grid`.
---@param pagenumber integer? Page to initialize; defaults to `publisher.current_pagenumber`.
---@param data table Data XML context.
---@param _from? string Caller identifier.
---@return nil
function M.initialize_page(pagenumber, data, _from)
    local thispage

    if pagenumber then
        thispage = pagenumber
        if publisher.pages[pagenumber] ~= nil then
            publisher.current_grid = publisher.pages[pagenumber].grid
            return
        end
    else
        if M.page_initialized_p(publisher.current_pagenumber) then
            publisher.current_grid = publisher.pages[publisher.current_pagenumber].grid
            return
        end
    end

    if not pagenumber then
        thispage = publisher.current_pagenumber
    end

    local trim_amount = tex.sp(publisher.options.trim or 0)
    local extra_margin
    if publisher.options.cutmarks or publisher.options.trimmarks then
        if not publisher.pro then
            main.log("error", "cutmarks need a pro plan")
            publisher.has_pro_error = true
        else
            extra_margin = publisher.tenmm_sp + trim_amount
        end
    elseif trim_amount > 0 then
        if not publisher.pro then
            main.log("error", "page bleed needs a pro plan")
            publisher.has_pro_error = true
        else
            extra_margin = trim_amount
        end
    end
    local current_page, errorstring = page:new(
        publisher.options.default_pagewidth,
        publisher.options.default_pageheight,
        extra_margin,
        trim_amount,
        thispage
    )
    if not current_page then
        main.log(
            "error",
            string.format("Can't create a new page. Is the page type (“PageType”) defined? %s", errorstring)
        )
        exit()
        return
    end
    publisher.current_page = current_page
    publisher.current_grid = current_page.grid
    publisher.pages[thispage] = current_page

    local gridwidth, gridheight, nx, ny, dx, dy
    nx = publisher.options.gridcells_x
    ny = publisher.options.gridcells_y
    dx = publisher.options.gridcells_dx
    dy = publisher.options.gridcells_dy

    local pagetype = M.detect_pagetype(thispage, data)
    if not pagetype then
        return
    end
    if pagetype.width then
        current_page.width = tex.sp(pagetype.width) or current_page.width
    end
    if pagetype.height then
        current_page.height = tex.sp(pagetype.height) or current_page.height
    end
    if pagetype.width or pagetype.height then
        if publisher.newxpath then
            data.vars["_pagewidth"] = pagetype.width
            data.vars["_pageheight"] = pagetype.height
        else
            publisher.xpath.set_variable("_pagewidth", pagetype.width)
            publisher.xpath.set_variable("_pageheight", pagetype.height)
        end
        M.set_pageformat(current_page.width, current_page.height)
    else
        -- 186467sp = 1mm
        local pagewd = current_page.width / 186467
        local pageht = current_page.height / 186467
        if publisher.newxpath then
            data.vars["_pagewidth"] = tostring(math.round(pagewd, 0)) .. "mm"
            data.vars["_pageheight"] = tostring(math.round(pageht, 0)) .. "mm"
        else
            publisher.xpath.set_variable("_pagewidth", tostring(math.round(pagewd, 0)) .. "mm")
            publisher.xpath.set_variable("_pageheight", tostring(math.round(pageht, 0)) .. "mm")
        end
    end

    local mattername
    if publisher.newxpath then
        mattername = pagetype.part or publisher.xpath.string_value(data.vars["_matter"])
    else
        mattername = pagetype.part or publisher.xpath.get_variable("_matter")
    end
    current_page.matter = mattername

    for _, j in ipairs(pagetype) do
        local eltname = publisher.xml_helpers.elementname(j)
        local eltcontents = publisher.xml_helpers.element_contents(j)
        if type(publisher.xml_helpers.element_contents(j)) == "function" and eltname == "Margin" then
            eltcontents(current_page)
        elseif eltname == "Grid" then
            local layoutxml = eltcontents.layoutxml
            local dataxml = eltcontents.dataxml
            local width = publisher.attribute_helpers.read_attribute(layoutxml, dataxml, "width", "length_sp")
            local height = publisher.attribute_helpers.read_attribute(layoutxml, dataxml, "height", "length_sp") -- shouldn't this be height_sp??? --PG
            local _nx = publisher.attribute_helpers.read_attribute(layoutxml, dataxml, "nx", "number")
            local _ny = publisher.attribute_helpers.read_attribute(layoutxml, dataxml, "ny", "number")
            local _dx = publisher.attribute_helpers.read_attribute(layoutxml, dataxml, "dx", "length_sp")
            local _dy = publisher.attribute_helpers.read_attribute(layoutxml, dataxml, "dy", "length_sp")

            gridwidth = width
            gridheight = height
            nx = _nx
            ny = _ny
            dx = _dx
            dy = _dy
        end
    end

    if gridwidth == nil and publisher.options.gridwidth ~= 0 then
        gridwidth = publisher.options.gridwidth
    end

    if gridheight == nil and publisher.options.gridheight ~= 0 then
        gridheight = publisher.options.gridheight
    end

    current_page.grid:set_width_height({ wd = gridwidth, ht = gridheight, nx = nx, ny = ny, dx = dx, dy = dy })

    -- The default color is applied during ship-out
    if publisher.newxpath then
        if pagetype.layoutxml and pagetype.layoutxml[".__attributes"].defaultcolor then
            current_page.defaultcolor =
                publisher.attribute_helpers.read_attribute(pagetype.layoutxml, nil, "defaultcolor", "string")
        end
    else
        if pagetype.layoutxml and pagetype.layoutxml.defaultcolor then
            current_page.defaultcolor =
                publisher.attribute_helpers.read_attribute(pagetype.layoutxml, nil, "defaultcolor", "string")
        end
    end
    current_page.graphic = pagetype.graphic
    current_page.backgroundcolor = pagetype.backgroundcolor
    local columnordering = pagetype.columnordering
    for _, j in ipairs(pagetype) do
        local eltname = publisher.xml_helpers.elementname(j)
        if type(publisher.xml_helpers.element_contents(j)) == "function" and eltname == "Margin" then
            -- do nothing, done before
        elseif eltname == "Grid" then
            -- do nothing, done before
        elseif eltname == "AtPageCreation" then
            current_page.atpagecreation = publisher.xml_helpers.element_contents(j)
        elseif eltname == "AtPageShipout" then
            current_page.AtPageShipout = publisher.xml_helpers.element_contents(j)
        elseif eltname == "PositioningArea" then
            local name = publisher.xml_helpers.element_contents(j).name
            publisher.current_grid.positioning_frames[name] = {}
            local current_positioning_area = publisher.current_grid.positioning_frames[name]
            -- we evaluate now, because the attributes in PositioningFrame can be page dependent.
            local d = publisher.xml_helpers.element_contents(j).dataxml
            local l = publisher.xml_helpers.element_contents(j).layoutxml
            local tab = publisher.dispatch.dispatch(l, d) or {}
            local tmp = {}
            for i, k in ipairs(tab) do
                tmp[#tmp + 1] = publisher.xml_helpers.element_contents(k)
                tmp[#tmp].order = i
            end
            if columnordering == "rtl" then
                table.sort(tmp, function(a, b)
                    if a.column == b.column then
                        return a.order > b.order
                    end
                    return a.column > b.column
                end)
            end

            for i = 1, #tmp do
                table.insert(current_positioning_area, tmp[i])
            end
            local bgcolor = publisher.xml_helpers.element_contents(j).bgcolor
            if bgcolor then
                for _, tbl in ipairs(tmp) do
                    local x = publisher.current_grid:posx_sp(tbl.column - 1)
                        + publisher.current_grid.extra_margin
                        + publisher.current_grid.margin_left
                    local y = publisher.current_grid:posy_sp(tbl.row - 1)
                        + publisher.current_grid.extra_margin
                        + publisher.current_grid.margin_top
                    local wd = publisher.current_grid:posx_sp(tbl.width)
                    local ht = publisher.current_grid:posy_sp(tbl.height)

                    local nl = publisher.drawing.box(wd, ht, bgcolor)

                    M.output_absolute_position({
                        nodelist = nl,
                        x = x,
                        y = y,
                        allocate = false,
                    })
                end
            end
            current_positioning_area.colorname = publisher.xml_helpers.element_contents(j).colorname
        else
            main.log("error", string.format("Element name %q unknown (setup_page())", eltname or "<create_page>"))
        end
    end

    local cp = current_page
    publisher.current_page = publisher.pages[thispage]
    if current_page.atpagecreation then
        publisher.pagebreak_impossible = true
        local cpn = publisher.current_pagenumber
        publisher.current_pagenumber = thispage
        publisher.current_grid = publisher.pages[thispage].grid
        publisher.dispatch.dispatch(current_page.atpagecreation, data)
        publisher.current_pagenumber = cpn
        publisher.pagebreak_impossible = false
        local graphic
        if publisher.newxpath then
            local attrs = current_page.atpagecreation[".__attributes"]
            if attrs then
                graphic = attrs.graphic
            end
        else
            graphic = current_page.atpagecreation.graphic
        end
        if graphic then
            local _, whatsit, _ = metapost.prepareboxgraphic(
                current_page.width,
                current_page.height,
                graphic,
                metapost.extra_page_parameter(current_page)
            )
            if whatsit then
                M.place_at(
                    current_page.pagebox,
                    whatsit,
                    current_page.grid.extra_margin,
                    current_page.height + current_page.grid.extra_margin
                )
            end
        end
    end

    local css_rules
    local cg = current_page.grid

    for k, v in pairs(cg.positioning_frames) do
        css_rules = publisher.css:matches({ element = "area", class = nil, id = k }) or {}
        if css_rules["border-width"] then
            for _, frame in ipairs(v) do
                frame.draw = { color = "green", width = css_rules["border-width"] }
            end
        end
    end
    publisher.current_page = cp
end

-- Ensures the requested page exists. Must be called before anything is
-- placed on a page; runs the deferred `nextpage` / `skippages` logic.
---@param pagenumber integer? Page to set up; defaults to `publisher.current_pagenumber`.
---@param fromwhere string Caller identifier for log messages.
---@param dataxml table Data XML context.
---@return nil
function M.setup_page(pagenumber, fromwhere, dataxml)
    if publisher.current_group then
        return
    end
    local tmp = publisher.skippages
    if tmp then
        publisher.skippages = nil
        if tmp.doubleopen then
            M.new_page("setup_page - skippages doubleopen", dataxml)
            publisher.nextpage = tmp.skippagetype
        end
        M.new_page("setup_page - skippages 2", dataxml)
        publisher.nextpage = tmp.pagetype
    end

    M.initialize_page(pagenumber, dataxml, fromwhere)
end

-- Switches to the next frame in the given area, or starts a new page if
-- the area has no more frames.
---@param areaname string Area name (e.g. `"_page"`).
---@param grid? Grid Override grid; defaults to `publisher.current_grid`.
---@param dataxml table Data XML context.
---@param _origin? string Caller identifier.
---@return nil
function M.next_area(areaname, grid, dataxml, _origin)
    grid = assert(grid or publisher.current_grid)
    local current_framenumber = grid:framenumber(areaname)
    if not current_framenumber then
        main.log(
            "error",
            string.format("Cannot determine current area number (areaname=%q)", areaname or "(undefined)")
        )
        return
    end
    if current_framenumber >= grid:number_of_frames(areaname) then
        M.new_page("next_area", dataxml)
    else
        grid:set_framenumber(areaname, current_framenumber + 1)
    end
    grid:set_current_row(1, areaname, "next_area")
    grid:set_current_column(1, areaname, "next_area")
end

-- Ships out the current page (or stores it in the active pagestore) and
-- advances `publisher.current_pagenumber`. Does nothing while
-- `pagebreak_impossible` is set.
---@param _from? string Caller identifier for log messages.
---@param dataxml table Data XML context.
---@return nil
function M.new_page(_from, dataxml)
    -- w("new page from %s",_from or "-")
    if publisher.pagebreak_impossible then
        return
    end
    local thispage = publisher.pages[publisher.current_pagenumber]
    if not thispage then
        -- new_page() is called without anything on the page yet
        M.setup_page(nil, "new_page", dataxml)
        thispage = assert(publisher.current_page)
    end

    M.dothingsbeforeoutput(thispage, publisher.data)

    local n = node.vpack(publisher.pages[publisher.current_pagenumber].pagebox)
    if publisher.current_pagestore_name then
        local thispagestore = publisher.pagestore[publisher.current_pagestore_name]
        thispagestore[#thispagestore + 1] = n
        thispagestore.grids[#thispagestore] = thispage.grid
    else
        M.shipout(n, publisher.current_pagenumber, dataxml)
    end
    publisher.current_pagenumber = publisher.current_pagenumber + 1
end

-- Forces a page break and (when `options.openon` is set) inserts skip pages
-- so the next page lands on the requested side. With `options.force` true,
-- emits an empty page if none has been started yet.
---@param options { dataxml: table, openon?: "left"|"right", force?: boolean, skippagetype?: string, matter?: string, pagetype?: string }
---@return nil
function M.clearpage(options)
    local thispage = publisher.pages[publisher.current_pagenumber]

    if thispage then
        M.dothingsbeforeoutput(thispage, publisher.data)
        local n = node.vpack(publisher.pages[publisher.current_pagenumber].pagebox)
        if publisher.current_pagestore_name then
            local thispagestore = publisher.pagestore[publisher.current_pagestore_name]
            thispagestore[#thispagestore + 1] = n
            thispagestore.grids[#thispagestore] = thispage.grid
        else
            M.shipout(n, publisher.current_pagenumber, options.dataxml)
        end

        publisher.current_pagenumber = publisher.current_pagenumber + 1
    else
        if options.force then
            M.initialize_page(nil, options.dataxml)
            local tmp = publisher.pages[publisher.current_pagenumber]
            M.dothingsbeforeoutput(tmp, publisher.data)
            local n = node.vpack(publisher.pages[publisher.current_pagenumber].pagebox)
            M.shipout(n, publisher.current_pagenumber, options.dataxml)
            publisher.current_pagenumber = publisher.current_pagenumber + 1
        end
    end

    local doubleopen = false
    if
        (options.openon == "right" and math.fmod(publisher.current_pagenumber, 2) == 0)
        or (options.openon == "left" and math.fmod(publisher.current_pagenumber, 2) == 1)
    then
        doubleopen = true
    end

    if doubleopen then
        -- shipout dummy page
        if options.skippagetype then
            publisher.nextpage = options.skippagetype
        end
        M.initialize_page(nil, options.dataxml)
        local tmp = publisher.pages[publisher.current_pagenumber]
        M.dothingsbeforeoutput(tmp, publisher.data)
        local n = node.vpack(publisher.pages[publisher.current_pagenumber].pagebox)
        M.shipout(n, publisher.current_pagenumber, options.dataxml)
        publisher.current_pagenumber = publisher.current_pagenumber + 1
    end

    if options.matter then
        if publisher.newxpath then
            options.dataxml.vars["_matter"] = options.matter
        else
            publisher.xpath.set_variable("_matter", options.matter)
        end
    end
    if options.pagetype then
        publisher.nextpage = options.pagetype
    end
end

-- Builds the `/Resources` dictionary for the current page (color spaces,
-- transparency states, spot colors).
---@param thispage table Current page table; reads `transparenttext`.
---@return nil
function M.setpageresources(thispage)
    if next(thispage.transparenttext) ~= nil and publisher.defaultcolorstack == 0 then
        publisher.drawing.transparentcolorstack()
    end
    -- thispage.transparenttext is something like { 40 = true, 20 = true}
    -- but only if we use alpha values for color
    local transparenttextresources = ""
    if publisher.defaultcolorstack ~= 0 then
        local tmp = { "/TRP1 << /CA 1 /ca 1 >>" }
        for k, _ in pairs(thispage.transparenttext) do
            tmp[#tmp + 1] = string.format("/TRP%s << /CA %g /ca %g >>", k, k / 100, k / 100)
        end
        transparenttextresources = table.concat(tmp, "")
    end
    local gstateresource = string.format(
        " /ExtGState << %s/GS0 %d 0 R /GS1 %d 0 R >>",
        transparenttextresources,
        publisher.GS_State_OP_On,
        publisher.GS_State_OP_Off
    )
    if table.not_empty(colors_module.used_spotcolors) then
        pdf.setpageresources(
            "/ColorSpace << " .. spotcolors.getresource(colors_module.used_spotcolors) .. " >>" .. gstateresource
        )
    else
        pdf.setpageresources(gstateresource)
    end
end

-- After everything is ready for page ship-out, add debug output and
-- crop marks if necessary.
-- Runs all `at-page-shipout` hooks for `thispage`, fills in margins,
-- crop marks, headers/footers, watermarks etc. Called once per page before
-- the actual `tex.shipout`.
---@param thispage table Current page table.
---@param data table? Data XML context (`nil` with the legacy XPath parser).
---@return nil
function M.dothingsbeforeoutput(thispage, data)
    local cg = thispage.grid

    if thispage and thispage.AtPageShipout then
        publisher.pagebreak_impossible = true
        publisher.dispatch.dispatch(thispage.AtPageShipout, data)
        publisher.pagebreak_impossible = false
        local graphic = thispage.AtPageShipout.graphic
        if graphic then
            local _, whatsit = metapost.prepareboxgraphic(
                thispage.width,
                thispage.height,
                graphic,
                metapost.extra_page_parameter(thispage)
            )
            if whatsit then
                M.place_at(
                    thispage.pagebox,
                    whatsit,
                    thispage.grid.extra_margin,
                    thispage.height + thispage.grid.extra_margin
                )
            end
        end
    end

    local nodelist = thispage.pagebox
    local rules =
        publisher.nodes.insert_nonmoving_whatsits(nodelist, nil, "vertical", 0, 0, thispage.width, thispage.height)
    for _, rule in pairs(rules) do
        -- @class whatsit_node
        local wr = node.new("whatsit", "pdf_literal")
        wr.data = rule[3]
        wr.mode = 0
        publisher.attribute_helpers.setprop(wr, "origin", "tr-later")
        M.output_absolute_position({ x = rule[1], y = rule[2], nodelist = wr })
    end

    local firstbox

    -- for spot colors, if necessary
    M.setpageresources(thispage)

    -- White background on page. Todo: Make color customizable and background optional.
    local wd = sp_to_bp(publisher.current_page.width)
    local ht = sp_to_bp(publisher.current_page.height)

    local x = 0 + publisher.current_page.grid.extra_margin
    local y = 0 + publisher.current_page.grid.extra_margin

    if publisher.options.trim then
        local trim_bp = sp_to_bp(publisher.options.trim)
        wd = wd + trim_bp * 2
        ht = ht + trim_bp * 2
        x = x - publisher.options.trim
        y = y - publisher.options.trim
    end

    -- White background
    if
        (publisher.options.background and publisher.options.background ~= "-")
        or (thispage.backgroundcolor and thispage.backgroundcolor ~= "-")
    then
        local col = thispage.backgroundcolor or publisher.options.background
        if col == "-" then
            goto skipbgcolor
        end
        local colentry = colors_module.get_colentry_from_name(col, "white")
        if not colentry then
            main.log("error", "Color is not defined", "name", tostring(publisher.options.background))
            colentry = colors_module.colors["white"]
        end
        local pdfcolorstring = colentry.pdfstring

        firstbox = node.new("whatsit", "pdf_literal")
        firstbox.data =
            string.format("q %s 1 0 0 1 0 0 cm %g %g %g %g re f Q", pdfcolorstring, sp_to_bp(x), sp_to_bp(y), wd, ht)
        firstbox.mode = 1
    end
    ::skipbgcolor::

    if publisher.options.showgridallocation then
        local lit = node.new("whatsit", "pdf_literal")
        lit.mode = 1
        lit.data = cg:draw_gridallocation()

        if firstbox then
            local tail = node.tail(firstbox)
            tail.next = lit
            lit.prev = tail
        else
            firstbox = lit
        end
    end

    for _, v in pairs(cg.positioning_frames) do
        for _, frame in ipairs(v) do
            if frame.draw then
                local lit = node.new("whatsit", "pdf_literal")
                lit.mode = 1
                lit.data = cg:draw_frame(frame, tex.sp(frame.draw.width))
                if firstbox then
                    local tail = node.tail(firstbox)
                    tail.next = lit
                    lit.prev = tail
                else
                    firstbox = lit
                end
            end
        end
    end

    if publisher.options.showgrid and publisher.options.gridlocation == "background" then
        local lit = node.new("whatsit", "pdf_literal")
        lit.mode = 1
        lit.data = cg:draw_grid()
        if firstbox then
            local tail = node.tail(firstbox)
            tail.next = lit
            lit.prev = tail
        else
            firstbox = lit
        end
    end

    if publisher.options.cutmarks then
        if not publisher.pro then
            main.log("error", "cutmarks need a pro plan")
            publisher.has_pro_error = true
        else
            local lit = node.new("whatsit", "pdf_literal")
            lit.mode = 1
            lit.data = cg:cutmarks()
            if firstbox then
                local tail = node.tail(firstbox)
                tail.next = lit
                lit.prev = tail
            else
                firstbox = lit
            end
        end
    end

    if publisher.options.trimmarks then
        local lit = node.new("whatsit", "pdf_literal")
        lit.mode = 1
        lit.data = cg:trimmarks()
        if firstbox then
            local tail = node.tail(firstbox)
            tail.next = lit
            lit.prev = tail
        else
            firstbox = lit
        end
    end

    if firstbox then
        local list_start = nodelist
        thispage.pagebox = firstbox
        node.tail(firstbox).next = list_start
        list_start.prev = node.tail(firstbox)
    end
end

-- Wraps the page node list with the final `pdf_save`/`pdf_restore` and
-- color-stack literals required for transparent text and spot colors.
---@param thispage table
---@param nodelist Node Page node list.
---@return Node nodelist Wrapped node list ready for `tex.shipout`.
function M.dothingsafteroutput(thispage, nodelist)
    if publisher.options.showgrid and publisher.options.gridlocation == "foreground" then
        local cg = thispage.grid
        local lit = node.new("whatsit", "pdf_literal")
        lit.mode = 1
        lit.data = cg:draw_grid()
        node.insert_after(nodelist, nodelist, lit)
        nodelist = node.vpack(nodelist)
    end
    return nodelist
end

-- Sets `\pdfpagewidth` and `\pdfpageheight` and stores the dimensions in
-- `publisher.options.default_pagewidth/height` for later defaulting.
---@param wd integer Page width in sp.
---@param ht integer Page height in sp.
---@return nil
function M.set_pageformat(wd, ht)
    publisher.options.pagewidth = wd
    publisher.options.pageheight = ht
    tex.pagewidth = wd
    tex.pageheight = ht
end

-- Returns the remaining vertical space (in sp) on the current frame of
-- `area`, optionally accounting for an allocation matrix.
---@param area string Area name.
---@param allocate? "auto"|table Optional 2D occupancy matrix to subtract.
---@return integer remaining
---@return integer firstrow
---@return integer? lastrow
function M.get_remaining_height(area, allocate)
    local cols = publisher.current_grid:number_of_columns(area)
    local startcol = 1
    local firstrow, maxrows
    firstrow = publisher.current_grid:current_row(area)
    if not firstrow then
        main.log("error", "get remaining height: no current row")
        firstrow = 1
    end
    maxrows = publisher.current_grid:number_of_rows(area)
    if allocate == "auto" then
        while firstrow <= maxrows and (not publisher.current_grid:row_has_some_space(firstrow, area)) do
            firstrow = firstrow + 1
        end

        local row = firstrow + 1
        while row <= maxrows and publisher.current_grid:row_has_some_space(row, area) do
            row = row + 1
        end

        if row > maxrows then
            if not publisher.current_grid.pageheight_known then
                -- a group: the grid grows on demand, so there is no height limit
                return publisher.maxdimen, firstrow
            end
            return (row - firstrow) * publisher.current_grid.gridheight, firstrow
        end
        local lastrow = row
        while not publisher.current_grid:fits_in_row_area(startcol, cols, lastrow, area) and lastrow <= maxrows do
            lastrow = lastrow + 1
        end
        lastrow = lastrow - 1
        if lastrow == firstrow or lastrow >= maxrows then
            return (row - firstrow) * publisher.current_grid.gridheight, firstrow
        end
        return (row - firstrow) * publisher.current_grid.gridheight, firstrow, lastrow
    end
    if not tonumber(maxrows) then
        main.log("error", "maxrows not set, why?")
        return 0, firstrow
    end
    if not publisher.current_grid:fits_in_row_area(startcol, cols, firstrow, area) then
        while firstrow <= maxrows do
            if publisher.current_grid:fits_in_row_area(startcol, cols, firstrow, area) then
                break
            end
            firstrow = firstrow + 1
        end
    end

    local row = firstrow

    while publisher.current_grid:fits_in_row_area(startcol, cols, row, area) and row <= maxrows do
        row = row + 1
    end

    local lastrow = row

    while row <= maxrows do
        if publisher.current_grid:fits_in_row_area(startcol, cols, row, area) then
            return (lastrow - firstrow) * publisher.current_grid.gridheight, firstrow, firstrow
        end
        row = row + 1
    end
    if lastrow > maxrows and not publisher.current_grid.pageheight_known then
        -- a group: the grid grows on demand, so there is no height limit
        return publisher.maxdimen, firstrow, nil
    end
    return (lastrow - firstrow) * publisher.current_grid.gridheight, firstrow, nil
end

-- Advances the current row in `areaname` by `rows` rows, switching to the
-- next frame (and possibly a new page) if there is not enough space.
---@param rownumber integer? Target row number; `nil` for relative move.
---@param areaname string
---@param rows integer? Number of rows to advance (default 1).
---@param dataxml table Data XML context.
---@return nil
function M.next_row(rownumber, areaname, rows, dataxml)
    local grid = assert(publisher.current_grid)
    rows = rows or 1

    if rownumber then
        grid:set_current_row(rownumber, areaname, "next_row")
        return
    end

    local current_row
    local noc = grid:number_of_columns(areaname)
    if noc == 0 then
        main.log("error", "number of columns is not set for area", "area", areaname)
        return
    end
    current_row = grid:find_suitable_row(1, noc, rows, areaname, nil, dataxml)
    if not current_row then
        M.next_area(areaname, nil, dataxml, "next_row")
        M.setup_page(nil, "next_row", dataxml)
        grid = assert(publisher.current_page).grid
        grid:set_current_row(1, areaname, "cannot find suitable row")
    else
        -- Version 2.7.3 and before had the problem that the cursor is past the right
        -- edge. See bug #105 (https://github.com/speedata/publisher/issues/105) for
        -- a description.
        -- A <NextRow rows="1" /> would go to the next free row, which could be the current
        -- row.
        -- <NextRow rows="1" /> should instead go to the beginning of the next row. So a
        -- <NextRow rows="1" /> directly after <PlaceObject>...</PlaceObject> width the right
        -- edge at the right margin will leave one blank line.
        -- The old behavior is to decrease 1 from the movement, which makes no sense these days.
        local dec = 0
        if grid:current_column(areaname) > 1 then
            dec = 1
        end
        local grid_number_of_rows = grid:number_of_rows(areaname)
        if current_row + rows - dec > grid_number_of_rows then
            M.next_area(areaname, nil, dataxml, "next_row 2")
            M.setup_page(nil, "next_row", dataxml)
            grid = assert(publisher.current_page).grid
            grid:set_current_row(1, areaname, "next_row -> next_area")
            return
        end
        grid:set_current_row(current_row + rows - dec, areaname, "next_row has_current_row")
        grid:set_current_column(1, areaname)
    end
end

-- Returns a flag value indicating "no block to place"; used by callers
-- that build a list of blocks for `vsplit`.
---@return VlistNode sentinel Empty vbox.
function M.empty_block()
    local r = node.new("hlist")
    r.width = 0
    r.height = 0
    r.depth = 0
    local v = node.vpack(r)
    return v
end

-- Returns a sentinel block used to force a page break when nothing else fits.
---@return VlistNode sentinel Vbox with a visible rule.
function M.emergency_block()
    local r = node.new(publisher.rule_node)
    r.width = 5 * 2 ^ 16
    r.height = 5 * 2 ^ 16
    r.depth = 0
    local v = node.vpack(r)
    return v
end

-- Return the height of the page given by the relative page number
-- (starting from the current_pagenumber). Used in tables to get the
-- height of a page in a multi-page table. Called from tabular.lua /
-- set in commands.lua (#table).
-- Returns the height (in grid rows) of the current page's `relative_framenumber`-th
-- positioning frame.
---@param relative_framenumber integer
---@param dataxml table
---@return integer rows
function M.getheight(relative_framenumber, dataxml)
    local grid = assert(publisher.current_grid)
    local cp, cg, cpn, cfn -- current page, current grid, current page number, current frame number
    cp = publisher.current_page
    cg = publisher.current_grid
    cpn = publisher.current_pagenumber
    local areaname
    if publisher.newxpath then
        areaname = dataxml.vars["__currentarea"]
    else
        areaname = publisher.xpath.get_variable("__currentarea")
    end
    areaname = areaname or publisher.default_areaname
    local current_framenumber = grid:framenumber(areaname)
    cfn = current_framenumber

    local thispagenumber = publisher.current_pagenumber
    local thispage
    local c = 1
    while c < relative_framenumber do
        if grid:number_of_frames(areaname) == current_framenumber then
            thispagenumber = thispagenumber + 1
            thispage = publisher.pages[thispagenumber]
            -- be aware that setup_page(..,) calls setup_page() but without
            -- parameter. Therefore the current_pagenumber has to be set
            publisher.current_pagenumber = thispagenumber
            if not thispage then
                M.setup_page(thispagenumber, "getheight", dataxml)
            end
            current_framenumber = 1
        else
            current_framenumber = current_framenumber + 1
        end
        publisher.current_page = publisher.pages[thispagenumber]
        publisher.current_pagenumber = thispagenumber
        publisher.current_grid = publisher.current_page.grid
        c = c + 1
    end
    local firstrow = publisher.current_grid:first_free_row(areaname, current_framenumber, dataxml)
    local remaining_height = publisher.current_grid:remaining_height_sp(firstrow, areaname, current_framenumber)
    publisher.current_pagenumber = cpn
    publisher.current_grid = cg
    publisher.current_page = cp
    publisher.current_grid:set_framenumber(areaname, cfn)

    return remaining_height
end

-- Return true iff the paragraph has at most `lines` text lines left
-- over and is not at the last line.
-- Returns `true` when `nodelist` line-breaks into at most `lines` lines.
---@param nodelist Node
---@param lines integer
---@return boolean
function M.less_or_equal_than_n_lines(nodelist, lines)
    if lines == 0 then
        return false
    end
    for i = 1, lines - 1 do
        local nxt = nodelist.next
        if nodelist.id == publisher.hlist_node and nxt then
            nodelist = nxt
        else
            if i == 1 then
                return false
            end
        end
    end
    return nodelist.next == nil
end

-- Concatenates the given table objects vertically into a single vbox.
---@param objects table[] Table objects produced by `commands.table`.
---@param from? string Caller identifier for log messages.
---@return Node? vbox `nil` when `objects` is empty.
function M.join_table_to_box(objects, from)
    for i = 1, #objects - 1 do
        objects[i].next = objects[i + 1]
    end
    if objects[1] == nil then
        return nil
    end
    node.slide(objects[1])
    local vbox = node.vpack(objects[1])
    publisher.attribute_helpers.setprop(vbox, "origin", "join_table_hbox " .. (from or ""))
    return vbox
end

-- vsplit takes a long paragraph and breaks it into small pieces of
-- text, taking orphans, widows and the destination area size into
-- account.
--
-- Input
-- -----
-- The table `objects_t` is an array of vboxes containing material
-- for the current frame of height `frameheight`. If the height of
-- the vboxes exceeds the frame height, we dissect the paragraphs
-- and place them into one large hlist.
--
-- Output
-- ------
-- A vbox to place in the PDF, with height <= frameheight. If
-- material is left over, `objects_t` is mutated and vsplit is
-- called again. Empty `objects_t` signals the caller (commands/text)
-- that all text has been placed.
-- Splits a vertical list of objects into pages, honoring break attributes,
-- frame heights and orphan/widow constraints. Drives the main page loop.
---@param objects_t table[] Vertical list of paragraph/table/box objects.
---@param parameter table Layout parameters (area, allocate, break-* etc.).
---@return Node area_vbox Material for the current area/column (vbox).
---@return Node? balanced_second Second column when balancing splits the material.
function M.vsplit(objects_t, parameter)
    -- Step 1: collect all the objects in one big table.
    -- ------------------------------------------------
    -- The objects that are not allowed to break are temporarily
    -- collected in a special vertical list that gets vpacked to
    -- disallow an "area" break.
    --
    -- ![Step 1](img/vsplit2.png)
    -- (assuming that there is a `break-below="no"` for the text format of the header).
    local balance = parameter.balance
    local valignlast = parameter.valignlast
    local frameheight = parameter.maxheight
    local lastpaddingbottommax = parameter.lastpaddingbottommax

    local hlist = {}
    -- We need the height for the decision to balance the text
    local ht_hlist = 0

    -- a list for hboxes with break_below = true
    local tmplist = {}
    local count_lists = #objects_t
    local vlist = table.remove(objects_t, 1)
    local i = 1
    local margin_newcolumn
    while vlist do
        local head = vlist.head
        while head do
            local bordernumber = publisher.attribute_helpers.get_attribute(head, "bordernumber")
            if bordernumber then
                -- move bordernumber to vlist
                publisher.attribute_helpers.set_attribute(vlist, "bordernumber", bordernumber)
                publisher.attribute_helpers.clear_attribute(vlist, "bordernumber")
            end

            local tmp_margin_newcolumn = node.has_attribute(head, publisher.att_margin_newcolumn)

            if tmp_margin_newcolumn then
                margin_newcolumn = tmp_margin_newcolumn
            end
            node.set_attribute(head, publisher.att_margin_newcolumn, margin_newcolumn)

            if i == count_lists and head.next == nil then
                -- the last object must not be in the tmplist
                -- But don't reset extend_to_next_block - we need it to persist for break-after: avoid
                node.unset_attribute(head, publisher.att_break_below_forbidden)
            end
            head.prev = nil
            local break_below_forbidden = node.has_attribute(head, publisher.att_break_below_forbidden)
            local break_before = node.has_attribute(head, publisher.att_break_before)
            if break_below_forbidden and not break_before then
                node.unset_attribute(head, publisher.att_margin_newcolumn)
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
                    local vbox = assert(M.join_table_to_box(tmplist, "break allowed"))
                    node.set_attribute(vbox, publisher.att_margin_newcolumn, margin_newcolumn_tmplist)

                    hlist[#hlist + 1] = vbox
                    ht_hlist = ht_hlist + vbox.height + vbox.depth
                    tmplist = {}
                else
                    hlist[#hlist + 1] = head
                    if head.id == publisher.glue_node then
                        ht_hlist = publisher.nodes.get_glue_size(head)
                    else
                        ht_hlist = ht_hlist + (head.height or 0) + (head.depth or 0)
                    end
                    local tmp = head.next
                    head.next = nil
                    head = tmp
                end
            end
        end
        vlist = table.remove(objects_t, 1)
        i = i + 1
    end
    -- the hlist now has lot's of rows. Widows/orphans are packed together in a vbox with n hboxes.

    if balance > 1 and ht_hlist < balance * frameheight then
        -- TODO: splitpos should be based on the actual height
        local splitpos = math.ceil(#hlist / balance)

        local margin_newcolumn_obj1 = node.has_attribute(hlist[1], publisher.att_margin_newcolumn)
        if margin_newcolumn_obj1 and margin_newcolumn_obj1 > 0 then
            table.insert(hlist, 1, publisher.nodes.add_glue(nil, "head", { width = margin_newcolumn_obj1 }))
            splitpos = splitpos + 1
        end
        local obj1 = assert(M.join_table_to_box({ table.unpack(hlist, 1, splitpos) }, "balance > 1 obj1"))
        if hlist[splitpos + 1] then
            local margin_newcolumn_obj2 = node.has_attribute(hlist[splitpos + 1], publisher.att_margin_newcolumn)
            if margin_newcolumn_obj2 and margin_newcolumn_obj2 > 0 then
                table.insert(
                    hlist,
                    splitpos + 1,
                    publisher.nodes.add_glue(nil, "head", { width = margin_newcolumn_obj2 })
                )
            end
            local obj2 = assert(M.join_table_to_box({ table.unpack(hlist, splitpos + 1) }, "balance > 1 obj2"))
            if valignlast == "bottom" then
                local remaining_height = frameheight - math.max(obj1.height, obj2.height)

                if remaining_height > lastpaddingbottommax then
                    remaining_height = remaining_height - lastpaddingbottommax
                end
                obj1.head = publisher.nodes.add_glue(obj1.head, "head", { width = remaining_height })
                obj2.head = publisher.nodes.add_glue(obj2.head, "head", { width = remaining_height })
            end
            return obj1, obj2
        else
            if valignlast == "bottom" then
                local remaining_height = frameheight - obj1.height
                if remaining_height > lastpaddingbottommax then
                    remaining_height = remaining_height - lastpaddingbottommax
                end
                obj1.head = publisher.nodes.add_glue(obj1.head, "head", { width = remaining_height })
            end
            return obj1
        end
    end
    -- Step 2: Fill vbox (the return value)
    -- ------------------------------------
    -- Two cases: the objects have enough material to fill up the area (a)
    -- or we have no objects left for the area and return the final vbox for this area. (b)
    -- The task is to go though collection of h/vboxes (the hlist) and create one big vbox.
    -- This is done by filling the table `thisarea`.
    --
    -- ![final step for area](img/vsplit3.png)
    local goal = frameheight
    local accumulated_height = 0
    local thisarea = {}
    local remaining_objects = {}
    local area_filled = false
    local lineheight = 0
    while not area_filled do
        for _ = 1, #hlist do
            local hbox = table.remove(hlist, 1)
            local break_before = node.has_attribute(hbox, publisher.att_break_before)
            node.set_attribute(hbox, publisher.att_break_before, nil)
            if #thisarea == 0 then
                -- This is for a different margin-top at the beginning of a new column.
                if hbox.id == publisher.vlist_node then
                    local vbox = hbox
                    if vbox.list and vbox.list.id == publisher.glue_node then
                        local margin_top_boxstart = node.has_attribute(vbox.list, publisher.att_margin_top_boxstart)
                        vbox.list.width = margin_top_boxstart
                        hbox = node.vpack(vbox.list)
                    end
                end
            end

            if #thisarea == 0 and node.has_attribute(hbox, publisher.att_omit_at_top) then
                -- When the margin-below appears at the top of the new frame, we just ignore
                -- it. Too bad Lua doesn't have a 'next' in for-loops
            else
                local margin_newcolumn_hbox = node.has_attribute(hbox, publisher.att_margin_newcolumn)
                if margin_newcolumn_hbox and margin_newcolumn_hbox > 0 and #thisarea == 0 then
                    thisarea[#thisarea + 1] = publisher.nodes.add_glue(nil, "head", { width = margin_newcolumn_hbox })
                    lineheight = margin_newcolumn_hbox
                end

                if hbox.id == publisher.hlist_node or hbox.id == publisher.vlist_node then
                    lineheight = lineheight + hbox.height + hbox.depth
                elseif hbox.id == publisher.glue_node then
                    lineheight = lineheight + get_glue_value(hbox, "width")
                elseif hbox.id == publisher.rule_node then
                    lineheight = lineheight + hbox.height + hbox.depth
                elseif hbox.id == publisher.whatsit_node then
                    -- ignore
                else
                    w("unknown node 1: %d", hbox.id)
                end
                -- 20 is some rounding error
                -- break_before: 1 = "page" (only if not at top), 2 = "always" (force break)
                -- Use page_has_content from parameter if available, otherwise fall back to #thisarea
                local page_has_content = parameter.page_has_content or (#thisarea > 0)
                local force_break = (break_before == 2) or (break_before == 1 and page_has_content)
                if accumulated_height + lineheight <= goal + 20 and not force_break then
                    thisarea[#thisarea + 1] = hbox
                    accumulated_height = accumulated_height + lineheight
                    lineheight = 0
                else
                    -- objects > goal
                    -- This is case (a)
                    remaining_objects[1] = hbox
                    break
                end
            end
        end
        area_filled = true
    end

    if #hlist > 0 then
        for j = 1, #hlist do
            remaining_objects[#remaining_objects + 1] = hlist[j]
        end
    end
    -- Sometimes there is a single glue (margin-bottom) left, we should ignore it
    if #remaining_objects == 1 and node.has_attribute(remaining_objects[1], publisher.att_omit_at_top) then
        -- ignore!?
    else
        objects_t[1] = M.join_table_to_box(remaining_objects, "remaining objects != 1")
    end

    -- It's a common situation where there is a single free row but the next material is
    -- too high for the row. So we return an empty list and hope that the calling function
    -- is clever enough to detect this case. (Well, it's not too difficult to detect, as
    -- the `objects_t` table is not empty yet.)

    return M.join_table_to_box(thisarea, "return") or M.empty_block()
end

file_end("pages.lua")

return M
