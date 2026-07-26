--
--  metapost.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

-- This file contains code from luamplib (https://www.ctan.org/pkg/luamplib) which
-- is released under the GPL 2.

---@class metapost_module

local publisher = require("publisher")

local M = {}

local colors_module = require("publisher.colors")

-- helper

-- Returns a table of MetaPost variables exposing the current page's
-- geometry (margins, width, height, trim) in big points.
---@param current_page table Current page table (with `grid`, `width`, `height`).
---@return table<string, number>
function M.extra_page_parameter(current_page)
    return {
        ["page.margin.top"] = sp_to_bp(current_page.grid.margin_top),
        ["page.margin.left"] = sp_to_bp(current_page.grid.margin_left),
        ["page.margin.right"] = sp_to_bp(current_page.grid.margin_right),
        ["page.margin.bottom"] = sp_to_bp(current_page.grid.margin_bottom),
        ["page.width"] = sp_to_bp(current_page.width),
        ["page.height"] = sp_to_bp(current_page.height),
        ["page.trim"] = sp_to_bp(current_page.grid.trim),
    }
end

-- File finder callback registered with the MetaPost runtime; uses kpse
-- for inputs and the working directory for outputs.
---@param name string
---@param mode "r"|"w"
---@param type string MetaPost file kind.
---@return string? path
local function finder(name, mode, type)
    local loc = kpse.find_file(name)
    if mode == "r" then
        return loc
    end
    return name
end

-- Buffers MetaPost-emitted TeX output to be flushed into the current PDF
-- content stream.
---@param whatever any
---@return nil
local function texsprint(whatever)
    -- w("texsprint %s", tostring(whatever))
end

local pdfcode
local pdfcodepointer
local nodelists = {}
local boundingbox

-- Compactly formats a number for PDF output: integers without a decimal
-- point, fractional values trimmed to 4 decimal places with trailing
-- zeros removed. PDF readers do not accept exponential notation, so we
-- never emit it.
---@param x any
---@return string
local function numfmt(x)
    if type(x) ~= "number" then
        return tostring(x)
    end
    if x == math.floor(x) and math.abs(x) < 1e15 then
        return string.format("%d", x)
    end
    local s = string.format("%.4f", x)
    s = s:gsub("0+$", ""):gsub("%.$", "")
    return s
end

-- Buffers a `pdf_literal` formatted with `string.format` for emission
-- into the current MetaPost figure. In addition to the standard
-- conversions, `%n` formats a number compactly via `numfmt` (used for
-- coordinates and dimensions in PDF graphics operators).
---@param fmt string
---@param ... any
---@return nil
local function pdf_literalcode(fmt, ...)
    local args = { ... }
    local new_args = {}
    local i = 0
    local new_fmt = fmt:gsub("%%[%-%+ #0]*%d*%.?%d*[diouxXfFeEgGsqn]", function(spec)
        i = i + 1
        if spec:sub(-1) == "n" then
            new_args[i] = numfmt(args[i])
            return "%s"
        end
        new_args[i] = args[i]
        return spec
    end)
    pdfcode[pdfcodepointer] = pdfcode[pdfcodepointer] or {}
    local instructions = pdfcode[pdfcodepointer]
    instructions[#instructions + 1] = string.format(new_fmt, table.unpack(new_args))
end

-- Inserts the buffered TeX output and accumulated PDF literal code as
-- a hbox/whatsit pair so MetaPost-generated content lands in the page.
---@param n integer Position index for the inserted run.
---@return nil
local function insert_text(n)
    table.insert(pdfcode, n)
    pdfcodepointer = pdfcodepointer + 2
end

local textext_fmt = [[image(addto currentpicture doublepath unitsquare ]]
    .. [[xscaled %f yscaled %f shifted (0,-%f) ]]
    .. [[withprescript "mplibtexboxid=%i:%f:%f")]]

local textext2_fmt = [[addto currentpicture doublepath unitsquare ]]
    .. [[xscaled %f yscaled %f shifted (0,-%f) ]]
    .. [[withprescript "mplibtexboxid=%i:%f:%f"]]

-- Renders a `btex ... etex` block by running `str` through TeX and
-- buffering the result for re-insertion at the current MetaPost position.
---@param str string TeX source.
---@param fmt? string Optional format wrapper.
---@return nil
local function process_tex_text(str, fmt)
    if str then
        local familyname, style, text = string.match(str, "^(.-):(.-):(.*)$")
        local fam = publisher.fonts.lookup_fontfamily_name_number[familyname]
        local param = { fontfamily = fam }
        if style == "bold" then
            param.bold = 1
        elseif style == "italic" then
            param.italic = 1
        elseif style == "bolditalic" then
            param.bold = 1
            param.italic = 1
        end
        local nodelist = publisher.nodes.mknodes(text, param)
        local hbox = node.hpack(nodelist)
        nodelists[#nodelists + 1] = hbox
        local box = #nodelists
        local wd = hbox.width / publisher.factor
        local ht = hbox.height / publisher.factor
        local dp = hbox.depth / publisher.factor
        local x = fmt:format(wd, ht + dp, dp, box, wd, ht + dp)
        return x
    end
end

-- Resolves a color reference encoded by MetaPost (`mpcolor:NAME`) to the
-- corresponding PDF color command.
---@param str string
---@return string pdf_command
local function process_color(str)
    if str then
        if not str:find("{.-}") then
            str = string.format("{%s}", str)
        end
        str = str:match("{(.*)}")
        local colentry = colors_module.get_colentry_from_name(str)
        local transparency = ""
        if colentry.alpha then
            transparency =
                string.format('withprescript "tr_alternative=1" withprescript "tr_transparency=%g"', colentry.alpha)
        end
        str = string.format('1 %s withprescript "MPlibOverrideColor=%s" ', transparency, colentry.pdfstring)
        return str
    end
    return ""
end

-- Executes a MetaPost `runscript` snippet inside a sandboxed Lua env
-- so figures can call back into the publisher.
---@param code string
---@return string? result
local function scriptrunner(code)
    local id, str = code:match("(.-){(.*)}")
    if id and str then
        if id == "sptext" then
            return process_tex_text(str, textext_fmt)
        elseif id == "drawtext" then
            return process_tex_text(str, textext2_fmt)
        elseif id == "spcolor" then
            return process_color(str)
        else
            print("**** unknown runner", code)
        end
    end
end

-- Places previously rendered `btex...etex` boxes at the proper MetaPost
-- positions, accounting for transformation and color commands.
---@param object table MetaPost figure object.
---@param prescript string Prescript instructions encoding placement.
---@return nil
local function put_tex_boxes(object, prescript)
    local box = prescript.mplibtexboxid
    local n, tw, th = tonumber(box[1]), tonumber(box[2]), tonumber(box[3])
    if n and tw and th then
        local op = object.path
        local first, second, fourth = op[1], op[2], op[4]
        local tx, ty = first.x_coord, first.y_coord
        local sx, rx, ry, sy = 1, 0, 0, 1
        if tw ~= 0 then
            sx = (second.x_coord - tx) / tw
            rx = (second.y_coord - ty) / tw
            if sx == 0 then
                sx = 0.00001
            end
        end
        if th ~= 0 then
            sy = (fourth.y_coord - ty) / th
            ry = (fourth.x_coord - tx) / th
            if sy == 0 then
                sy = 0.00001
            end
        end

        local x = node.new("whatsit", "pdf_literal")
        x.data = string.format(
            "q %g %g %g %g %g %g cm",
            math.round(sx, 3),
            math.round(rx, 3),
            math.round(ry, 3),
            math.round(sy, 3),
            math.round(tx, 3),
            math.round(ty, 3)
        )
        x = node.insert_before(nodelists[n].list, nodelists[n].list, x)
        nodelists[n].list = x
        local y = node.new("whatsit", "pdf_literal")
        y.data = " Q"
        node.insert_after(nodelists[n].list, node.tail(nodelists[n].list), y)
        insert_text(nodelists[n])
    end
end

-- Feeds `str` to the given MetaPost instance and returns the resulting
-- figure object.
---@param mpobj userdata MetaPost instance.
---@param str string MetaPost source.
---@return table? figure
function M.execute(mpobj, str)
    if not str then
        main.log("error", "Empty metapost string for execute")
        return false
    end
    local l = mpobj.mp:execute(str)
    if l and l.status > 0 then
        main.log("error", string.format("Executing %s: %s", str, l.term))
        return false
    end
    mpobj.l = l
    return true
end

-- Creates a new MetaPost instance pre-configured for the publisher's
-- canvas (width × height in sp), with the standard prelude loaded.
---@param width_sp integer
---@param height_sp integer
---@return userdata mpobj
function M.newbox(width_sp, height_sp)
    local mp = mplib.new({
        mem_name = "plain",
        find_file = finder,
        ini_version = true,
        math_mode = "double",
        random_seed = math.random(100),
        run_script = scriptrunner,
        extensions = 1,
    })
    local mpobj = {
        mp = mp,
        width = width_sp,
        height = height_sp,
    }
    for _, v in pairs({ "plain", "csscolors", "sp" }) do
        if not M.execute(mpobj, string.format("input %s;", v)) then
            main.log("error", "Cannot start metapost.")
            return nil
        end
    end
    if width_sp and width_sp ~= 0 then
        M.execute(mpobj, string.format("box.width = %fbp;", width_sp / 65782))
    else
        main.log("warn", "MetaPost: width is 0, setting to 1bp")
        M.execute(mpobj, "box.width = 1bp;")
    end
    if height_sp and height_sp ~= 0 then
        M.execute(mpobj, string.format("box.height = %fbp;", height_sp / 65782))
    end
    if height_sp and width_sp and height_sp ~= 0 and width_sp ~= 0 then
        M.execute(
            mpobj,
            [[path box; box = (0,0) -- (box.width,0) -- (box.width,box.height) -- (0,box.height) -- cycle ;]]
        )
    end

    local declarations = {}
    for name, v in pairs(publisher.metapostcolors) do
        if v.model == "cmyk" then
            local varname = string.gsub(name, "%d", "[]")
            local decl = string.format("cmykcolor colors.%s;", varname)
            if not declarations[decl] then
                declarations[decl] = true
                M.execute(mpobj, decl)
            end
            local mpstatement = string.format("colors.%s := (%g, %g, %g, %g);", name, v.c, v.m, v.y, v.k)

            M.execute(mpobj, mpstatement)
        elseif v.model == "rgb" then
            M.execute(mpobj, string.format("rgbcolor colors.%s; colors.%s := (%g, %g, %g);", name, name, v.r, v.g, v.b))
        elseif v.model == "gray" then
            M.execute(mpobj, string.format("rgbcolor colors.%s; colors.%s := (%g, %g, %g);", name, name, v.k, v.k, v.k))
        else
            main.log("error", string.format("metapost: model %q not supported", v.model))
        end
    end

    for name, v in pairs(publisher.metapostvariables) do
        local expr
        if v.typ == "string" then
            if publisher.newxpath then
                expr = string.format("%s %s ; %s := %q ;", v.typ, name, name, publisher.xpath.string_value(v[1]))
            else
                expr = string.format("%s %s ; %s := %q ;", v.typ, name, name, v[1])
            end
        else
            if publisher.newxpath then
                expr = string.format("%s %s ; %s := %s ;", v.typ, name, name, publisher.xpath.string_value(v))
            else
                expr = string.format("%s %s ; %s := %s ;", v.typ, name, name, v[1])
            end
        end
        M.execute(mpobj, expr)
    end
    return mpobj
end

local tex_code_pre_mplib = {}

-- Converts a MetaPost color tuple (`{r}`, `{r,g,b}`, `{c,m,y,k}`) into
-- the corresponding PDF stroke + fill operator pair.
---@param cr number[]
---@return string stroke
---@return string fill
local function colorconverter(cr)
    local n = #cr
    if n == 4 then
        local c, m, y, k = cr[1], cr[2], cr[3], cr[4]
        return string.format("%.3f %.3f %.3f %.3f k %.3f %.3f %.3f %.3f K", c, m, y, k, c, m, y, k), "0 g 0 G"
    elseif n == 3 then
        local r, g, b = cr[1], cr[2], cr[3]
        return string.format("%.3f %.3f %.3f rg %.3f %.3f %.3f RG", r, g, b, r, g, b), "0 g 0 G"
    else
        local s = cr[1]
        return string.format("%.3f g %.3f G", s, s), "0 g 0 G"
    end
end

-- Pen transformation state shared between pen_characteristics, concat, and
-- flushconcatpath (kept at file scope on purpose).
local rx, ry, sx, sy, tx, ty
local divider

-- Returns the pen characteristics (line width, stroke type) for a
-- MetaPost object so they can be re-emitted as PDF operators.
---@param object table MetaPost figure object.
---@return number wd Line width in bp.
---@return string lc Line cap operator.
local function pen_characteristics(object)
    local t = mplib.pen_info(object)
    rx, ry, sx, sy, tx, ty = t.rx, t.ry, t.sx, t.sy, t.tx, t.ty
    divider = sx * sy - rx * ry
    return not (sx == 1 and rx == 0 and ry == 0 and sy == 1 and tx == 0 and ty == 0), t.width
end

local bend_tolerance = 131 / 65536

-- Returns `true` when the path segment between `ith` and `pth` is curved
-- (rather than a straight line).
---@param ith table MetaPost path point.
---@param pth table Following MetaPost path point.
---@return boolean
local function curved(ith, pth)
    local d = pth.left_x - ith.right_x
    if
        math.abs(ith.right_x - ith.x_coord - d) <= bend_tolerance
        and math.abs(pth.x_coord - pth.left_x - d) <= bend_tolerance
    then
        d = pth.left_y - ith.right_y
        if
            math.abs(ith.right_y - ith.y_coord - d) <= bend_tolerance
            and math.abs(pth.y_coord - pth.left_y - d) <= bend_tolerance
        then
            return false
        end
    end
    return true
end

-- PDF `cm` operator from a 2x2 transformation; no translation here
-- because it is emitted separately.
---@param px number[] First column.
---@param py number[] Second column.
---@return string
local function concat(px, py) -- no tx, ty here
    return (sy * px - ry * py) / divider, (sx * py - rx * px) / divider
end

-- Emits a transformed MetaPost path as PDF operators.
---@param path table[] Sequence of MetaPost path points.
---@param open boolean Whether the path is open (no closing `h`).
---@return nil
local function flushconcatpath(path, open)
    pdf_literalcode("%n %n %n %n %n %n cm", sx, rx, ry, sy, tx, ty)
    local pth, ith
    for i = 1, #path do
        pth = path[i]
        if not ith then
            pdf_literalcode("%n %n m", concat(pth.x_coord, pth.y_coord))
        elseif curved(ith, pth) then
            local a, b = concat(ith.right_x, ith.right_y)
            local c, d = concat(pth.left_x, pth.left_y)
            pdf_literalcode("%n %n %n %n %n %n c", a, b, c, d, concat(pth.x_coord, pth.y_coord))
        else
            pdf_literalcode("%n %n l", concat(pth.x_coord, pth.y_coord))
        end
        ith = pth
    end
    if not open then
        local one = path[1]
        if curved(pth, one) then
            local a, b = concat(pth.right_x, pth.right_y)
            local c, d = concat(one.left_x, one.left_y)
            pdf_literalcode("%n %n %n %n %n %n c", a, b, c, d, concat(one.x_coord, one.y_coord))
        else
            pdf_literalcode("%n %n l", concat(one.x_coord, one.y_coord))
        end
    elseif #path == 1 then -- special case .. draw point
        local one = path[1]
        pdf_literalcode("%n %n l", concat(one.x_coord, one.y_coord))
    end
end

-- Emits an untransformed MetaPost path as PDF operators.
---@param path table[]
---@param open boolean
---@return nil
local function flushnormalpath(path, open)
    local pth, ith
    for i = 1, #path do
        pth = path[i]
        if not ith then
            pdf_literalcode("%n %n m", pth.x_coord, pth.y_coord)
        elseif curved(ith, pth) then
            pdf_literalcode(
                "%n %n %n %n %n %n c",
                ith.right_x,
                ith.right_y,
                pth.left_x,
                pth.left_y,
                pth.x_coord,
                pth.y_coord
            )
        else
            pdf_literalcode("%n %n l", pth.x_coord, pth.y_coord)
        end
        ith = pth
    end
    if not open then
        local one = path[1]
        if curved(pth, one) then
            pdf_literalcode(
                "%n %n %n %n %n %n c",
                pth.right_x,
                pth.right_y,
                one.left_x,
                one.left_y,
                one.x_coord,
                one.y_coord
            )
        else
            pdf_literalcode("%n %n l", one.x_coord, one.y_coord)
        end
    elseif #path == 1 then -- special case .. draw point
        local one = path[1]
        pdf_literalcode("%n %n l", one.x_coord, one.y_coord)
    end
end

-- Emits the closing color/transparency operators after a MetaPost
-- object has been drawn.
---@param tr integer? Transparency graphic state number.
---@param over string? Color override.
---@param sh integer? Shading number.
---@return nil
local function do_postobj_color(tr, over, sh)
    if sh then
        pdf_literalcode("W n /MPlibSh%s sh Q", sh)
    end
    if over then
        texsprint("\\special{color pop}")
    end
    if tr then
        pdf_literalcode("/MPlibTr%i gs", tr)
    end
end

local transparency_values

-- Emits the opening color/transparency/shading operators for a MetaPost
-- object based on its prescript instructions.
---@param object table
---@param prescript table|nil
---@return integer? transparent
---@return string? overprint
---@return integer? shading
local function do_preobj_color(object, prescript)
    local opaq = prescript and prescript.tr_transparency

    if opaq then
        -- tron_no, troff_no = tr_pdf_pageresources(prescript.tr_alternative or 1, opaq)
        local str_int_val = string.format("%d", opaq)
        transparency_values[str_int_val] = true
        pdf_literalcode("/TRP%s gs", str_int_val)
    end
    local override = prescript and prescript.MPlibOverrideColor
    if override and type(override) == "string" then
        pdf_literalcode(override)
        override = nil
    else
        local cs = object.color
        if cs and #cs > 0 then
            pdf_literalcode(colorconverter(cs))
        end
    end
    -- TODO: gradient/shading support (sh_type == "linear" / "circular") was
    -- partially adapted from luamplib but never finished — the helpers
    -- color_normalize and sh_pdfpageresources were not ported. The block
    -- has been removed; reinstate it together with those helpers when
    -- shading is needed again. The first return value (formerly troff_no)
    -- is always nil for the same reason — transparency_modes was never wired
    -- through tr_pdf_pageresources.
    return nil, override
end

local further_split_keys = {
    mplibtexboxid = true,
    sh_color_a = true,
    sh_color_b = true,
}

-- Parses a `key=value;key=value;...` pre/postscript string into a Lua
-- table.
---@param s string
---@return table<string, string>
local function script2table(s)
    local t = {}
    for _, i in ipairs(s:explode("\13+")) do
        local k, v = i:match("(.-)=(.*)") -- v may contain = or empty.
        if k and v and k ~= "" then
            if further_split_keys[k] then
                t[k] = v:explode(":")
            else
                t[k] = v
            end
        end
    end
    return t
end

-- Converts a MetaPost figure object by emitting the PDF content stream
-- and TeX code directly (via tex.sprint / pdf literals); returns nothing.
---@param result table MetaPost figure result.
---@return nil
local function convert(result)
    if result then
        local figures = result.fig
        if figures then
            for f = 1, #figures do
                local figure = figures[f]
                local objects = figure:objects()
                local miterlimit, linecap, linejoin, dashed = -1, -1, -1, false
                boundingbox = figure:boundingbox()
                local llx, lly, urx, ury = boundingbox[1], boundingbox[2], boundingbox[3], boundingbox[4] -- faster than unpack
                if urx < llx then
                    w("no figure")
                else
                    if tex_code_pre_mplib[f] then
                        texsprint(tex_code_pre_mplib[f])
                    end
                    local TeX_code_bot = {}
                    -- start figure
                    texsprint(string.format("\\mplibstarttoPDF{%f}{%f}{%f}{%f}", llx, lly, urx, ury))
                    pdf_literalcode("q")
                    if objects then
                        local savedpath = nil
                        local savedhtap = nil
                        for o = 1, #objects do
                            local object = objects[o]
                            local objecttype = object.type
                            local prescript = object.prescript

                            if prescript then
                                -- prescript is now a table
                                prescript = script2table(prescript)
                            end

                            local tr_opaq, cr_over, shade_no = do_preobj_color(object, prescript)
                            if prescript and prescript.mplibtexboxid then
                                put_tex_boxes(object, prescript)
                            elseif objecttype == "start_bounds" or objecttype == "stop_bounds" then --skip
                            elseif objecttype == "start_clip" then
                                local evenodd = not object.istext and object.postscript == "evenodd"
                                pdf_literalcode("q")
                                flushnormalpath(object.path, false)
                                pdf_literalcode(evenodd and "W* n" or "W n")
                            elseif objecttype == "stop_clip" then
                                pdf_literalcode("Q")
                                miterlimit, linecap, linejoin, dashed = -1, -1, -1, false
                            elseif objecttype == "special" then
                                if prescript and prescript.postmplibverbtex then
                                    TeX_code_bot[#TeX_code_bot + 1] = prescript.postmplibverbtex
                                end
                            elseif objecttype == "text" then
                                local ot = object.transform -- 3,4,5,6,1,2
                                pdf_literalcode("q")
                                pdf_literalcode("%n %n %n %n %n %n cm", ot[3], ot[4], ot[5], ot[6], ot[1], ot[2])
                                -- pdf_textfigure(object.font, object.dsize, object.text, object.width, object.height,
                                --     object.depth)
                                pdf_literalcode("Q")
                            else
                                local evenodd, collect, both = false, false, false
                                local postscript = object.postscript
                                if not object.istext then
                                    if postscript == "evenodd" then
                                        evenodd = true
                                    elseif postscript == "collect" then
                                        collect = true
                                    elseif postscript == "both" then
                                        both = true
                                    elseif postscript == "eoboth" then
                                        evenodd = true
                                        both = true
                                    end
                                end
                                if collect then
                                    if not savedpath then
                                        savedpath = { object.path or false }
                                        savedhtap = { object.htap or false }
                                    else
                                        savedpath[#savedpath + 1] = object.path or false
                                        savedhtap[#savedhtap + 1] = object.htap or false
                                    end
                                else
                                    local ml = object.miterlimit
                                    if ml and ml ~= miterlimit then
                                        miterlimit = ml
                                        pdf_literalcode("%n M", ml)
                                    end
                                    local lj = object.linejoin
                                    if lj and lj ~= linejoin then
                                        linejoin = lj
                                        pdf_literalcode("%i j", lj)
                                    end
                                    local lc = object.linecap
                                    if lc and lc ~= linecap then
                                        linecap = lc
                                        pdf_literalcode("%i J", lc)
                                    end
                                    local dl = object.dash
                                    if dl then
                                        local d =
                                            string.format("[%s] %f d", table.concat(dl.dashes or {}, " "), dl.offset)
                                        if d ~= dashed then
                                            dashed = d
                                            pdf_literalcode(dashed)
                                        end
                                    elseif dashed then
                                        pdf_literalcode("[] 0 d")
                                        dashed = false
                                    end
                                    local path = object.path
                                    local transformed, penwidth
                                    local open = path and path[1].left_type and path[#path].right_type
                                    local pen = object.pen
                                    if pen then
                                        if pen.type == "elliptical" then
                                            transformed, penwidth = pen_characteristics(object) -- boolean, value
                                            pdf_literalcode("%n w", penwidth)
                                            if objecttype == "fill" then
                                                objecttype = "both"
                                            end
                                        else -- calculated by mplib itself
                                            objecttype = "fill"
                                        end
                                    end
                                    if transformed then
                                        pdf_literalcode("q")
                                    end
                                    if path then
                                        if savedpath then
                                            for i = 1, #savedpath do
                                                local path = savedpath[i]
                                                if transformed then
                                                    flushconcatpath(path, open)
                                                else
                                                    flushnormalpath(path, open)
                                                end
                                            end
                                            savedpath = nil
                                        end
                                        if transformed then
                                            flushconcatpath(path, open)
                                        else
                                            flushnormalpath(path, open)
                                        end
                                        if not shade_no then -- conflict with shading
                                            if objecttype == "fill" then
                                                pdf_literalcode(evenodd and "h f*" or "h f")
                                            elseif objecttype == "outline" then
                                                if both then
                                                    pdf_literalcode(evenodd and "h B*" or "h B")
                                                else
                                                    pdf_literalcode(open and "S" or "h S")
                                                end
                                            elseif objecttype == "both" then
                                                pdf_literalcode(evenodd and "h B*" or "h B")
                                            end
                                        end
                                    end
                                    if transformed then
                                        pdf_literalcode("Q")
                                    end
                                    local path = object.htap
                                    if path then
                                        if transformed then
                                            pdf_literalcode("q")
                                        end
                                        if savedhtap then
                                            for i = 1, #savedhtap do
                                                local path = savedhtap[i]
                                                if transformed then
                                                    flushconcatpath(path, open)
                                                else
                                                    flushnormalpath(path, open)
                                                end
                                            end
                                            savedhtap = nil
                                            evenodd = true
                                        end
                                        if transformed then
                                            flushconcatpath(path, open)
                                        else
                                            flushnormalpath(path, open)
                                        end
                                        if objecttype == "fill" then
                                            pdf_literalcode(evenodd and "h f*" or "h f")
                                        elseif objecttype == "outline" then
                                            pdf_literalcode(open and "S" or "h S")
                                        elseif objecttype == "both" then
                                            pdf_literalcode(evenodd and "h B*" or "h B")
                                        end
                                        if transformed then
                                            pdf_literalcode("Q")
                                        end
                                    end
                                end
                            end
                            do_postobj_color(tr_opaq, cr_over, shade_no)
                        end
                    end
                    pdf_literalcode("Q")
                    texsprint("\\mplibstoptoPDF")
                    if #TeX_code_bot > 0 then
                        texsprint(TeX_code_bot)
                    end
                end
            end
        end
    end
end

-- Closes the MetaPost instance and returns the converted figure as a
-- PDF content-stream string with its bounding box.
---@param mpobj userdata
---@return string? pdf_stream
---@return number? width_bp
---@return number? height_bp
function M.finish(mpobj)
    pdfcode = {}
    pdfcodepointer = 1
    transparency_values = {}
    boundingbox = {}
    convert(mpobj.l)
    local head, tail
    for i = 1, #pdfcode do
        if type(pdfcode[i]) == "table" then
            local literal = node.new("whatsit", "pdf_literal")
            local str = table.concat(pdfcode[i], " ")
            literal.data = str
            head = node.insert_after(head, tail, literal)
            tail = literal
        else
            head = node.insert_after(head, tail, pdfcode[i])
            tail = node.tail(pdfcode[i])
        end
    end
    local tv = transparency_values
    mpobj.mp:finish()
    return head, tv, boundingbox
end

-- Return a pdf_whatsit node
-- Compiles a named MetaPost graphic from `publisher.metapostgraphics`
-- and returns a fresh MetaPost instance ready to render it. Used as the
-- first half of `boxgraphic` so callers can reuse the compiled figure.
---@param width_sp integer
---@param height_sp integer
---@param graphicname string Key in `publisher.metapostgraphics`.
---@param extra_parameter? table<string, any> Variable values.
---@return userdata mpobj
function M.prepareboxgraphic(width_sp, height_sp, graphicname, extra_parameter)
    local colorwarnings = publisher.metapostcolorwarnings
    if #colorwarnings > 0 then
        for i = 1, #colorwarnings do
            local str, mpcolorname = table.unpack(colorwarnings[i])
            if publisher.options.mpcolorwarning then
                main.log(
                    "warn",
                    "A color has characters in it that confuse the metapost interpreter, therefore I have renamed the color for metapost",
                    "color",
                    str,
                    "dest",
                    "colors." .. mpcolorname
                )
            end
        end
        publisher.metapostcolorwarnings = {}
    end
    if not publisher.metapostgraphics[graphicname] then
        main.log("error", string.format("MetaPost graphic %s not defined", graphicname))
        return nil
    end
    local mpobj = M.newbox(width_sp, height_sp)
    M.execute(mpobj, "beginfig(1);")
    for k, v in pairs(extra_parameter or {}) do
        if k == "colors" and type(v) == "table" then
            for col, val in pairs(v) do
                local fmt = string.format("color %s; %s = %s;", col, col, val)
                M.execute(mpobj, fmt)
            end
        elseif k == "strings" and type(v) == "table" then
            for col, val in pairs(v) do
                local fmt = string.format("string %s; %s = %q;", col, col, val)
                M.execute(mpobj, fmt)
            end
        elseif k == "boolean" and type(v) == "table" then
            for col, val in pairs(v) do
                local fmt = string.format("boolean %s; %s = %s;", col, col, tostring(val))
                M.execute(mpobj, fmt)
            end
        else
            local fmt = string.format("%s = %s ;", k, v)
            M.execute(mpobj, fmt)
        end
    end
    M.execute(mpobj, publisher.metapostgraphics[graphicname])
    M.execute(mpobj, "endfig;")
    local nl, tv, bbox = M.finish(mpobj)
    local thispage = publisher.pages[publisher.current_pagenumber]
    thispage.transparenttext = thispage.transparenttext or {}
    for key in pairs(tv) do
        thispage.transparenttext[tonumber(key)] = true
    end

    return mpobj, nl, bbox
end

-- Returns an hbox containing a named MetaPost graphic rendered at
-- (width × height) sp.
---@param width_sp integer
---@param height_sp integer
---@param graphicname string
---@param extra_parameter? table<string, any> Variable values.
---@param parameter? table Per-call parameters.
---@return Node? hbox
---@return table? bbox Bounding box.
function M.boxgraphic(width_sp, height_sp, graphicname, extra_parameter, parameter)
    local _, a, bbox = M.prepareboxgraphic(width_sp, height_sp, graphicname, extra_parameter)
    return a, bbox
end

return M
