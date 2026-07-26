-- Drawing primitives, frames, transformations and MetaPost bridge.
--
--  drawing.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("drawing.lua")

local publisher = require("publisher")

---@class drawing_module
local M = {}

local colors_module = require("publisher.colors")
local metapost = require("publisher.metapost")

---@alias TransformMatrix number[] Six-element affine matrix `{a, b, c, d, e, f}` (PDF order).

-- Returns a small filled square at `(x, y)` for visual debugging. sp input.
---@param x integer
---@param y integer
---@return string pdf_fragment
function M.pdf_draw_pos(x, y)
    x = sp_to_bp(x)
    y = sp_to_bp(y)
    local wd = 0.1
    return string.format(
        "q 0 g 0.2 w %g %g m %g %g l %g %g l %g %g l h f Q ",
        x - wd,
        y - wd,
        x - wd,
        y + wd,
        x + wd,
        y + wd,
        x + wd,
        y - wd
    )
end

-- Small filled circle marker at `(x, y)`. sp input.
---@param x integer
---@param y integer
---@return string pdf_fragment
function M.pdf_circle_pos(x, y)
    return M.circle_pdfstring(x, y, 10000, 10000, "0G 0g", "0G 0g", 0)
end

-- Larger filled circle marker at `(x, y)`. sp input.
---@param x integer
---@param y integer
---@return string pdf_fragment
function M.pdf_circle_pos_big(x, y)
    return M.circle_pdfstring(x, y, 100000, 100000, "0G 0g", "0G 0g", 0)
end

-- PDF `c` (cubic Bezier) operator. sp input.
---@param x1 integer
---@param y1 integer
---@param x2 integer
---@param y2 integer
---@param x3 integer
---@param y3 integer
---@return string
function M.pdf_curveto(x1, y1, x2, y2, x3, y3)
    x1 = sp_to_bp(x1)
    y1 = sp_to_bp(y1)
    x2 = sp_to_bp(x2)
    y2 = sp_to_bp(y2)
    x3 = sp_to_bp(x3)
    y3 = sp_to_bp(y3)
    return string.format("%g %g %g %g %g %g c", x1, y1, x2, y2, x3, y3)
end

-- PDF `m` (moveto) operator. sp input.
---@param x integer
---@param y integer
---@return string
function M.pdf_moveto(x, y)
    x = sp_to_bp(x)
    y = sp_to_bp(y)
    return string.format("%g %g m", x, y)
end

-- PDF `l` (lineto) operator. sp input.
---@param x integer
---@param y integer
---@return string
function M.pdf_lineto(x, y)
    x = sp_to_bp(x)
    y = sp_to_bp(y)
    return string.format("%g %g l", x, y)
end

-- Same as `pdf_draw_pos` but takes coordinates in big points (bp).
---@param x number
---@param y number
---@return string
function M.pdf_draw_pos_bp(x, y)
    local wd = 0.1
    return string.format(
        "q 0 g 0.2 w %g %g m %g %g l %g %g l %g %g l h f Q ",
        x - wd,
        y - wd,
        x - wd,
        y + wd,
        x + wd,
        y + wd,
        x + wd,
        y - wd
    )
end

-- Same as `pdf_circle_pos` but takes bp coordinates.
---@param x number
---@param y number
---@return string
function M.pdf_circle_pos_bp(x, y)
    return M.circle_pdfstring_bp(x, y, 0.5, 0.5, "0G 0g", "0G 0g", 0)
end

-- Same as `pdf_circle_pos_big` but takes bp coordinates.
---@param x number
---@param y number
---@return string
function M.pdf_circle_pos_big_bp(x, y)
    return M.circle_pdfstring_bp(x, y, 3, 3, "0G 0g", "0G 0g", 0)
end

-- PDF `c` operator with bp coordinates.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param x3 number
---@param y3 number
---@return string
function M.pdf_curveto_bp(x1, y1, x2, y2, x3, y3)
    return string.format("%g %g %g %g %g %g c", x1, y1, x2, y2, x3, y3)
end

-- PDF `m` operator with bp coordinates.
---@param x number
---@param y number
---@return string
function M.pdf_moveto_bp(x, y)
    return string.format("%g %g m", x, y)
end

-- PDF `l` operator with bp coordinates.
---@param x number
---@param y number
---@return string
function M.pdf_lineto_bp(x, y)
    return string.format("%g %g l", x, y)
end

-- Lazily creates the shared transparency color stack and stores its index
-- in `publisher.defaultcolorstack`.
---@return nil
function M.transparentcolorstack()
    if publisher.defaultcolorstack == 0 then
        publisher.defaultcolorstack = pdf.newcolorstack("0 g 0 G/TRP1 gs", "direct", true)
    end
end

-- Composes two affine transformation matrices (`a` then `b`).
---@param a TransformMatrix
---@param b TransformMatrix
---@return TransformMatrix
function M.concat_transformation(a, b)
    local c = {}
    c[1] = a[1] * b[1] + a[2] * b[3]
    c[2] = a[1] * b[2] + a[2] * b[4]
    c[3] = a[3] * b[1] + a[4] * b[3]
    c[4] = a[3] * b[2] + a[4] * b[4]
    c[5] = a[5] * b[1] + a[6] * b[3] + b[5]
    c[6] = a[5] * b[2] + a[6] * b[4] + b[6]
    return c
end

-- Places a rotated text watermark in the background of `box`.
---@param box HlistNode Hbox to decorate.
---@param textstring string Watermark text.
---@param angle number Rotation in degrees.
---@param colorname string Registered color name.
---@param fontfamily integer Font family number.
---@param bgsize? string Background sizing keyword; "contain" scales the text into the box.
---@return HlistNode box Repacked hbox with the background text prepended.
function M.bgtext(box, textstring, angle, colorname, fontfamily, bgsize)
    local colorindex = colors_module.colors[colorname].index
    local boxheight, boxdepth, boxwidth = box.height, box.depth or 0, box.width
    local angle_rad = -1 * math.rad(angle)
    local sin = math.sin(angle_rad)
    local cos = math.cos(angle_rad)

    local a = publisher.par:new(nil, "bgtext")
    a:append(textstring, { fontfamily = fontfamily, color = colorindex })
    a:mknodelist({}, publisher.data)
    local textbox = node.hpack(a.objects[1])

    -- Bounding box of the four rotated corners of the textbox. The
    -- textbox origin is at (0,0) (baseline-left); glyphs extend upward
    -- to textbox.height (ascender) and downward to -textbox.depth
    -- (descenders, e.g. on "(", ")", "g"). Rotating around the origin
    -- moves the BB asymmetrically, so compute the BB explicitly and
    -- re-center it inside the cell. The cell occupies y in
    -- [-boxdepth, +boxheight] relative to the same baseline-origin, so
    -- its vertical center sits at (boxheight - boxdepth) / 2.
    local function rot(x, y)
        return cos * x - sin * y, sin * x + cos * y
    end
    local txt_d = textbox.depth or 0
    local x1, y1 = rot(0, -txt_d)
    local x2, y2 = rot(textbox.width, -txt_d)
    local x3, y3 = rot(0, textbox.height)
    local x4, y4 = rot(textbox.width, textbox.height)
    local bb_xmin = math.min(x1, x2, x3, x4)
    local bb_xmax = math.max(x1, x2, x3, x4)
    local bb_ymin = math.min(y1, y2, y3, y4)
    local bb_ymax = math.max(y1, y2, y3, y4)
    local bb_w = bb_xmax - bb_xmin
    local bb_h = bb_ymax - bb_ymin

    local scale
    if bgsize == "contain" then
        scale = math.min(boxwidth / bb_w, (boxheight + boxdepth) / bb_h)
    else
        scale = 1
    end
    local shift_right = sp_to_bp(boxwidth / 2 - scale * (bb_xmin + bb_xmax) / 2)
    local shift_up = sp_to_bp((boxheight - boxdepth) / 2 - scale * (bb_ymin + bb_ymax) / 2)

    -- rotate: [cos θ sin θ −sin θ cos θ 0 0 ]
    local rotate_matrix = { cos, sin, -1 * sin, cos, 0, 0 }
    local scale_matrix = { scale, 0, 0, scale, 0, 0 }
    local shift_matrix = { 1, 0, 0, 1, shift_right, shift_up }
    local result_matrix
    result_matrix = M.concat_transformation(rotate_matrix, scale_matrix)
    result_matrix = M.concat_transformation(result_matrix, shift_matrix)
    local matrixstring = string.format(
        "%g %g %g %g %g %g",
        math.round(result_matrix[1], 3),
        math.round(result_matrix[2], 3),
        math.round(result_matrix[3], 3),
        math.round(result_matrix[4], 3),
        math.round(result_matrix[5], 3),
        math.round(result_matrix[6], 3)
    )
    local x = M.matrix(textbox, matrixstring, 0, 0)
    x = node.hpack(x)
    x.width = 0
    x.height = 0
    box = node.insert_before(box, box, x)
    box = node.hpack(box)
    return box
end

-- Draw a background behind the rectangular (box) object.
-- Adds a colored background rectangle behind the contents of `box`.
---@param box Node Hbox to modify in place.
---@param colorname string|integer Color name or index.
---@param origin? string Origin tag for `setprop` (debugging).
---@return Node box
function M.background(box, colorname, origin)
    -- color '-' means 'no color'
    if colorname == "-" then
        return box
    end
    if not colors_module.colors[colorname] then
        if origin then
            main.log("warn", "Background: color is not defined", "name", colorname, "from", origin)
        else
            main.log("warn", "Background: color is not defined", "name", colorname)
        end
        return box
    end
    local colentry = colors_module.colors[colorname]

    local pdfcolorstring = colentry.pdfstring
    local wd, ht, dp = sp_to_bp(box.width), sp_to_bp(box.height), sp_to_bp(box.depth)
    local n = node.new("whatsit", "pdf_literal")
    publisher.attribute_helpers.setprop(n, "origin", "background")
    publisher.attribute_helpers.setprop(n, "role", publisher.structure_tree.get_rolenum("Artifact"))
    n.data = string.format("q %s 0 -%g %g %g re f Q", pdfcolorstring, dp, wd, ht + dp)
    n.mode = 0
    if colentry.alpha then
        publisher.attribute_helpers.setprop(n, "opacity", colentry.alpha)
    end
    if node.type(box.id) == "hlist" then
        -- pdfliteral does not use up any space, so we can add it to the already packed box.
        n.next = box.list
        box.list.prev = n
        box.list = n
        return box
    else
        n.next = box
        box.prev = n
        n = node.hpack(n)
        return n
    end
end

-- Draw a colored frame around a given TeX box.
-- The control points of the frame are illustrated in
-- doc/img/roundedcorners.svg.
--
-- `obj` is a table with the keys:
--   box: the TeX box
--   colorname: the name of a color (defaults to "black")
--   width: the width of the border (defaults to 0)
--   clip: should the outside be clipped?
--   b_x_y_radius (x = b|t, y = r|l): the radius of the corners
--
-- Returns a hbox.
-- Wraps a frame around the contents of `obj`. Honors border colors,
-- widths, padding, corner radius and shadow attributes from `obj`.
---@param obj table Frame parameters with `width`, `height`, `border_*`, etc.
---@return Node hbox
function M.frame(obj)
    local box, width
    box = obj.box
    width = obj.rulewidth or 0
    local b_b_r_radius = sp_to_bp(obj.b_b_r_radius)
    local b_t_r_radius = sp_to_bp(obj.b_t_r_radius)
    local b_t_l_radius = sp_to_bp(obj.b_t_l_radius)
    local b_b_l_radius = sp_to_bp(obj.b_b_l_radius)

    local b_b_r_radius_inner = math.round(math.max(sp_to_bp(obj.b_b_r_radius) - width / publisher.factor, 0), 3)
    local b_t_r_radius_inner = math.round(math.max(sp_to_bp(obj.b_t_r_radius) - width / publisher.factor, 0), 3)
    local b_t_l_radius_inner = math.round(math.max(sp_to_bp(obj.b_t_l_radius) - width / publisher.factor, 0), 3)
    local b_b_l_radius_inner = math.round(math.max(sp_to_bp(obj.b_b_l_radius) - width / publisher.factor, 0), 3)

    -- See https://en.wikipedia.org/wiki/File:Circle_and_cubic_bezier.svg
    -- https://en.wikipedia.org/wiki/Composite_B%C3%A9zier_curve
    -- 0.5522847498
    -- http://spencermortensen.com/articles/bezier-circle/
    -- 0.551915024494
    local circle_bezier = 0.551915024494

    local colentry = colors_module.get_colentry_from_name(obj.colorname, "black")
    if not colentry then
        main.log("error", "Color is not defined", "name", tostring(obj.colorname))
        colentry = colors_module.colors["black"]
    end

    local pdfcolorstring = colentry.pdfstring
    local wd, ht, dp = sp_to_bp(box.width), sp_to_bp(box.height), sp_to_bp(box.depth)
    local rw = math.round(width / publisher.factor, 3) -- width of stroke
    if obj.colorname == "-" then
        rw = 0
    end

    -- outer boundary
    local x1, y1 = -rw + b_b_l_radius, -rw - dp
    local x2, y2 = rw + wd - b_b_r_radius, -rw - dp
    local x3, y3 = rw + wd - circle_bezier * b_b_r_radius, -rw - dp
    local x4, y4 = rw + wd, -rw - dp + circle_bezier * b_b_r_radius
    local x5, y5 = rw + wd, -rw + b_b_r_radius
    local x6, y6 = rw + wd, rw + ht - b_t_r_radius
    local x7, y7 = rw + wd, rw + ht - circle_bezier * b_t_r_radius
    local x8, y8 = rw + wd - circle_bezier * b_t_r_radius, rw + ht
    local x9, y9 = rw + wd - b_t_r_radius, rw + ht
    local x10, y10 = -rw + b_t_l_radius, rw + ht
    local x11, y11 = -rw + circle_bezier * b_t_l_radius, rw + ht
    local x12, y12 = -rw, rw + ht - circle_bezier * b_t_l_radius
    local x13, y13 = -rw, rw + ht - b_t_l_radius
    local x14, y14 = -rw, -rw - dp + b_b_l_radius
    local x15, y15 = -rw, -rw - dp + circle_bezier * b_b_l_radius
    local x16, y16 = -rw + circle_bezier * b_b_l_radius, -rw - dp

    x1, y1 = math.round(x1, 3), math.round(y1, 3)
    x2, y2 = math.round(x2, 3), math.round(y2, 3)
    x3, y3 = math.round(x3, 3), math.round(y3, 3)
    x4, y4 = math.round(x4, 3), math.round(y4, 3)
    x5, y5 = math.round(x5, 3), math.round(y5, 3)
    x6, y6 = math.round(x6, 3), math.round(y6, 3)
    x7, y7 = math.round(x7, 3), math.round(y7, 3)
    x8, y8 = math.round(x8, 3), math.round(y8, 3)
    x9, y9 = math.round(x9, 3), math.round(y9, 3)
    x10, y10 = math.round(x10, 3), math.round(y10, 3)
    x11, y11 = math.round(x11, 3), math.round(y11, 3)
    x12, y12 = math.round(x12, 3), math.round(y12, 3)
    x13, y13 = math.round(x13, 3), math.round(y13, 3)
    x14, y14 = math.round(x14, 3), math.round(y14, 3)
    x15, y15 = math.round(x15, 3), math.round(y15, 3)
    x16, y16 = math.round(x16, 3), math.round(y16, 3)

    -- inner boundary
    local xx1, yy1 = b_b_l_radius_inner, -dp
    local xx2, yy2 = wd - b_b_r_radius_inner, -dp
    local xx3, yy3 = wd - circle_bezier * b_b_r_radius_inner, -dp
    local xx4, yy4 = wd, -dp + circle_bezier * b_b_r_radius_inner
    local xx5, yy5 = wd, b_b_r_radius_inner
    local xx6, yy6 = wd, ht - b_t_r_radius_inner
    local xx7, yy7 = wd, ht - circle_bezier * b_t_r_radius_inner
    local xx8, yy8 = wd - circle_bezier * b_t_r_radius_inner, ht
    local xx9, yy9 = wd - b_t_r_radius_inner, ht
    local xx10, yy10 = b_t_l_radius_inner, ht
    local xx11, yy11 = circle_bezier * b_t_l_radius_inner, ht
    local xx12, yy12 = 0, ht - circle_bezier * b_t_l_radius_inner
    local xx13, yy13 = 0, ht - b_t_l_radius_inner
    local xx14, yy14 = 0, -dp + b_b_l_radius_inner
    local xx15, yy15 = 0, -dp + circle_bezier * b_b_l_radius_inner
    local xx16, yy16 = circle_bezier * b_b_l_radius_inner, -dp

    xx1, yy1 = math.round(xx1, 3), math.round(yy1, 3)
    xx2, yy2 = math.round(xx2, 3), math.round(yy2, 3)
    xx3, yy3 = math.round(xx3, 3), math.round(yy3, 3)
    xx4, yy4 = math.round(xx4, 3), math.round(yy4, 3)
    xx5, yy5 = math.round(xx5, 3), math.round(yy5, 3)
    xx6, yy6 = math.round(xx6, 3), math.round(yy6, 3)
    xx7, yy7 = math.round(xx7, 3), math.round(yy7, 3)
    xx8, yy8 = math.round(xx8, 3), math.round(yy8, 3)
    xx9, yy9 = math.round(xx9, 3), math.round(yy9, 3)
    xx10, yy10 = math.round(xx10, 3), math.round(yy10, 3)
    xx11, yy11 = math.round(xx11, 3), math.round(yy11, 3)
    xx12, yy12 = math.round(xx12, 3), math.round(yy12, 3)
    xx13, yy13 = math.round(xx13, 3), math.round(yy13, 3)
    xx14, yy14 = math.round(xx14, 3), math.round(yy14, 3)
    xx15, yy15 = math.round(xx15, 3), math.round(yy15, 3)
    xx16, yy16 = math.round(xx16, 3), math.round(yy16, 3)

    local n_clip, rule_clip

    if obj.clip then
        n_clip = node.new("whatsit", "pdf_literal")
        publisher.attribute_helpers.setprop(n_clip, "origin", "obj.clip")
        rule_clip = {}
        rule_clip[#rule_clip + 1] = string.format("%g %g m", xx1, yy1)
        rule_clip[#rule_clip + 1] = string.format("%g %g l", xx2, yy2)
        rule_clip[#rule_clip + 1] = string.format("%g %g %g %g %g %g c", xx3, yy3, xx4, yy4, xx5, yy5)
        rule_clip[#rule_clip + 1] = string.format("%g %g l", xx6, yy6)
        rule_clip[#rule_clip + 1] = string.format("%g %g %g %g %g %g c", xx7, yy7, xx8, yy8, xx9, yy9)
        rule_clip[#rule_clip + 1] = string.format("%g %g l", xx10, yy10)
        rule_clip[#rule_clip + 1] = string.format("%g %g %g %g %g %g c", xx11, yy11, xx12, yy12, xx13, yy13)
        rule_clip[#rule_clip + 1] = string.format("%g %g l", xx14, yy14)
        rule_clip[#rule_clip + 1] = string.format("%g %g %g %g %g %g c W n ", xx15, yy15, xx16, yy16, xx1, yy1)
    end

    local n = node.new("whatsit", "pdf_literal")
    publisher.attribute_helpers.setprop(n, "origin", "publisher.frame")
    local rule = {}

    -- We need to add q .. Q because the color would leak into the inner objects (#55)
    rule[#rule + 1] = string.format("q %s", pdfcolorstring)
    rule[#rule + 1] = string.format("%g w", rw) -- rule width

    rule[#rule + 1] = string.format("%g %g m", xx1, yy1)
    rule[#rule + 1] = string.format("%g %g l", xx2, yy2)
    rule[#rule + 1] = string.format("%g %g %g %g %g %g c", xx3, yy3, xx4, yy4, xx5, yy5)
    rule[#rule + 1] = string.format("%g %g l", xx6, yy6)
    rule[#rule + 1] = string.format("%g %g %g %g %g %g c", xx7, yy7, xx8, yy8, xx9, yy9)
    rule[#rule + 1] = string.format("%g %g l", xx10, yy10)
    rule[#rule + 1] = string.format("%g %g %g %g %g %g c", xx11, yy11, xx12, yy12, xx13, yy13)
    rule[#rule + 1] = string.format("%g %g l", xx14, yy14)
    rule[#rule + 1] = string.format("%g %g %g %g %g %g c ", xx15, yy15, xx16, yy16, xx1, yy1)

    rule[#rule + 1] = string.format("%g %g m", x1, y1)
    rule[#rule + 1] = string.format("%g %g l", x2, y2)
    rule[#rule + 1] = string.format("%g %g %g %g %g %g c", x3, y3, x4, y4, x5, y5)
    rule[#rule + 1] = string.format("%g %g l", x6, y6)
    rule[#rule + 1] = string.format("%g %g %g %g %g %g c", x7, y7, x8, y8, x9, y9)
    rule[#rule + 1] = string.format("%g %g l", x10, y10)
    rule[#rule + 1] = string.format("%g %g %g %g %g %g c", x11, y11, x12, y12, x13, y13)
    rule[#rule + 1] = string.format("%g %g l", x14, y14)
    rule[#rule + 1] = string.format("%g %g %g %g %g %g c", x15, y15, x16, y16, x1, y1)
    if rw == 0 then
        rule[#rule + 1] = "n"
    else
        rule[#rule + 1] = "f*"
    end
    rule[#rule + 1] = "Q"

    n.data = table.concat(rule, " ")
    if colentry.alpha then
        publisher.attribute_helpers.setprop(n, "opacity", colentry.alpha)
    end

    publisher.attribute_helpers.setprop(n, "origin", "frame")
    publisher.attribute_helpers.setprop(n, "role", publisher.structure_tree.get_rolenum("Artifact"))

    if obj.clip then
        n_clip.data = table.concat(rule_clip, " ")
        node.setproperty(n_clip, { origin = "frame/clip" })
    end

    if n_clip and node.is_node(n_clip) then
        publisher.attribute_helpers.setprop(n_clip, "origin", "frame")
        publisher.attribute_helpers.setprop(n_clip, "role", publisher.structure_tree.get_rolenum("Artifact"))
    end

    local pdf_save = node.new("whatsit", "pdf_save")
    local pdf_restore = node.new("whatsit", "pdf_restore")

    node.insert_after(pdf_save, pdf_save, n)
    if obj.clip then
        node.insert_after(n, n, n_clip)
        node.insert_after(n_clip, n_clip, box)
    else
        node.insert_after(n, n, box)
    end

    local hvbox = node.hpack(pdf_save)
    local savedp = hvbox.depth
    hvbox.depth = 0
    node.insert_after(hvbox, node.tail(hvbox), pdf_restore)
    hvbox = node.vpack(hvbox)
    hvbox = node.vpack(hvbox)
    hvbox.depth = savedp
    return hvbox
end

-- Wraps the children of `obj` in a clipping path defined by `obj.path`
-- (PDF operator string).
---@param obj table Clipping parameters with `width`, `height`, `path` etc.
---@return Node hbox
function M.clip(obj)
    local box = obj.box
    local wd, ht, dp = sp_to_bp(box.width), sp_to_bp(box.height), sp_to_bp(box.depth)

    local kern_left = node.new("kern")
    local kern_top = node.new("kern")

    if obj.clip_width_sp ~= 0 then
        if obj.clip_left_sp ~= 0 or obj.clip_right_sp == 0 then
            obj.clip_right_sp = box.width - obj.clip_width_sp - obj.clip_left_sp
        else
            obj.clip_left_sp = box.width - obj.clip_width_sp - obj.clip_right_sp
        end
    end

    if obj.clip_height_sp ~= 0 then
        if obj.clip_top_sp ~= 0 or obj.clip_bottom_sp == 0 then
            obj.clip_bottom_sp = box.height - obj.clip_height_sp - obj.clip_top_sp
        else
            obj.clip_top_sp = box.height - obj.clip_height_sp - obj.clip_bottom_sp
        end
    end

    local clip_top_bp = sp_to_bp(obj.clip_top_sp)
    local clip_bottom_bp = sp_to_bp(obj.clip_bottom_sp)
    local clip_left_bp = sp_to_bp(obj.clip_left_sp)
    local clip_right_bp = sp_to_bp(obj.clip_right_sp)

    if obj.method == "clip" then
        kern_left.kern = -1 * obj.clip_left_sp
        kern_top.kern = -1 * obj.clip_top_sp
    end

    node.insert_after(kern_left, kern_left, box)
    box = node.hpack(kern_left)
    node.insert_after(kern_top, kern_top, box)
    box = node.vpack(kern_top)

    local n_clip, rule_clip
    n_clip = node.new("whatsit", "pdf_literal")
    publisher.attribute_helpers.setprop(n_clip, "origin", "obj.clip")
    rule_clip = {}
    if obj.method == "clip" then
        rule_clip[#rule_clip + 1] = string.format(
            " %g %g %g %g re W n ",
            0,
            -1 * dp + clip_bottom_bp,
            wd - clip_right_bp - clip_left_bp,
            ht + dp - clip_bottom_bp - clip_top_bp
        )
    elseif obj.method == "frame" then
        rule_clip[#rule_clip + 1] = string.format(
            " %g %g %g %g re W n ",
            clip_left_bp,
            -1 * dp + clip_bottom_bp,
            wd - clip_right_bp - clip_left_bp,
            ht + dp - clip_bottom_bp - clip_top_bp
        )
    else
        main.log("error", string.format("Clip: method %s not implemented", obj.method))
    end

    n_clip = node.new("whatsit", "pdf_literal")
    n_clip.data = table.concat(rule_clip, " ")
    node.setproperty(n_clip, { origin = "frame/clip (2)" })

    local pdf_save = node.new("whatsit", "pdf_save")
    local pdf_restore = node.new("whatsit", "pdf_restore")

    node.insert_after(pdf_save, pdf_save, n_clip)
    node.insert_after(n_clip, n_clip, box)

    local hvbox = node.hpack(pdf_save)
    local savedp = hvbox.depth
    hvbox.depth = 0
    node.insert_after(hvbox, node.tail(hvbox), pdf_restore)
    hvbox = node.vpack(hvbox)
    if obj.method == "clip" then
        hvbox.width = hvbox.width - obj.clip_right_sp
        hvbox.height = hvbox.height - obj.clip_bottom_sp
    end
    hvbox.depth = savedp

    return hvbox
end

-- Get a PDF string for a circle. Control points are illustrated in
-- doc/img/circlepoints.svg.
-- Builds the PDF content-stream fragment for an ellipse, approximated by
-- four cubic Beziers. sp inputs.
---@param center_x integer
---@param center_y integer
---@param radiusx_sp integer
---@param radiusy_sp integer
---@param stroke_colorstring string PDF color command for the stroke (`/CS`/`G`/`RG`...).
---@param fill_colorstring string PDF color command for the fill.
---@param rulewidth_sp integer Stroke width in sp; `0` means no stroke.
---@return string
function M.circle_pdfstring(
    center_x,
    center_y,
    radiusx_sp,
    radiusy_sp,
    stroke_colorstring,
    fill_colorstring,
    rulewidth_sp
)
    local circle_bezier = 0.551915024494

    local shift_dn, shift_rt = -radiusy_sp + center_y, -radiusx_sp + center_x
    local dx = radiusx_sp * (1 - circle_bezier)
    local dy = radiusy_sp * (1 - circle_bezier)

    local x1 = shift_rt
    local y1 = shift_dn + radiusy_sp
    local x2 = x1
    local y2 = shift_dn + radiusy_sp * 2 - dy
    local x3 = shift_rt + dx
    local y3 = shift_dn + radiusy_sp * 2
    local x4 = shift_rt + radiusx_sp
    local y4 = shift_dn + radiusy_sp * 2
    local x5 = shift_rt + radiusx_sp * 2 - dx
    local y5 = y3
    local x6 = shift_rt + radiusx_sp * 2
    local y6 = y2
    local x7 = x6
    local y7 = y1
    local x8 = x6
    local y8 = shift_dn + dy
    local x9 = x5
    local y9 = shift_dn
    local x10 = x4
    local y10 = y9
    local x11 = x3
    local y11 = y9
    local x12 = x1
    local y12 = y8
    local circle = {}
    circle[#circle + 1] = "q"
    circle[#circle + 1] = string.format("%g w %s %s", sp_to_bp(rulewidth_sp), stroke_colorstring, fill_colorstring)
    circle[#circle + 1] = M.pdf_moveto(x1, y1)
    circle[#circle + 1] = M.pdf_curveto(x2, y2, x3, y3, x4, y4)
    circle[#circle + 1] = M.pdf_curveto(x5, y5, x6, y6, x7, y7)
    circle[#circle + 1] = M.pdf_curveto(x8, y8, x9, y9, x10, y10)
    circle[#circle + 1] = M.pdf_curveto(x11, y11, x12, y12, x1, y1)
    if fill_colorstring == "" then
        circle[#circle + 1] = "s"
    else
        circle[#circle + 1] = "b"
    end
    circle[#circle + 1] = "Q"
    return table.concat(circle, " ")
end

-- Same as `circle_pdfstring` but with all coordinates already in bp.
---@param center_x number
---@param center_y number
---@param radiusx_bp number
---@param radiusy_bp number
---@param stroke_colorstring string
---@param fill_colorstring string
---@param rulewidth_bp number
---@return string
function M.circle_pdfstring_bp(
    center_x,
    center_y,
    radiusx_bp,
    radiusy_bp,
    stroke_colorstring,
    fill_colorstring,
    rulewidth_bp
)
    local circle_bezier = 0.551915024494

    local shift_dn, shift_rt = -radiusy_bp + center_y, -radiusx_bp + center_x
    local dx = radiusx_bp * (1 - circle_bezier)
    local dy = radiusy_bp * (1 - circle_bezier)

    local x1 = shift_rt
    local y1 = shift_dn + radiusy_bp
    local x2 = x1
    local y2 = shift_dn + radiusy_bp * 2 - dy
    local x3 = shift_rt + dx
    local y3 = shift_dn + radiusy_bp * 2
    local x4 = shift_rt + radiusx_bp
    local y4 = shift_dn + radiusy_bp * 2
    local x5 = shift_rt + radiusx_bp * 2 - dx
    local y5 = y3
    local x6 = shift_rt + radiusx_bp * 2
    local y6 = y2
    local x7 = x6
    local y7 = y1
    local x8 = x6
    local y8 = shift_dn + dy
    local x9 = x5
    local y9 = shift_dn
    local x10 = x4
    local y10 = y9
    local x11 = x3
    local y11 = y9
    local x12 = x1
    local y12 = y8
    local circle = {}
    circle[#circle + 1] = "q"
    circle[#circle + 1] = string.format("%g w %s %s", rulewidth_bp, stroke_colorstring, fill_colorstring)
    circle[#circle + 1] = M.pdf_moveto_bp(x1, y1)
    circle[#circle + 1] = M.pdf_curveto_bp(x2, y2, x3, y3, x4, y4)
    circle[#circle + 1] = M.pdf_curveto_bp(x5, y5, x6, y6, x7, y7)
    circle[#circle + 1] = M.pdf_curveto_bp(x8, y8, x9, y9, x10, y10)
    circle[#circle + 1] = M.pdf_curveto_bp(x11, y11, x12, y12, x1, y1)
    if fill_colorstring == "" then
        circle[#circle + 1] = "s"
    else
        circle[#circle + 1] = "b"
    end
    circle[#circle + 1] = "Q"
    return table.concat(circle, " ")
end

-- Draw a circle
-- Returns an hbox containing a filled/stroked ellipse.
---@param radiusx_sp integer Horizontal radius in sp.
---@param radiusy_sp integer Vertical radius in sp.
---@param colorname string|nil Fill color name; `nil` means no fill.
---@param framecolorname string|nil Stroke color name; `nil` means no stroke.
---@param rulewidth_sp integer Stroke width in sp.
---@return Node hbox
function M.circle(radiusx_sp, radiusy_sp, colorname, framecolorname, rulewidth_sp)
    if rulewidth_sp < 5 then
        framecolorname = colorname
    end
    local colentry = colors_module.get_colentry_from_name(colorname)
    if not colentry then
        main.log("error", string.format("Color %q unknown, reverting to black", colorname or "(no color name given)"))
        colentry = colors_module.colors["black"]
    end
    local framecolentry = colors_module.get_colentry_from_name(framecolorname)

    if not framecolentry then
        main.log(
            "error",
            string.format("Color %q unknown, reverting to black", framecolorname or "(no color name given)")
        )
        framecolentry = colors_module.colors["black"]
    end
    local fillcolor = colentry.pdfstring_fill
    local bordercolor = framecolentry.pdfstring_stroking

    local paint = node.new("whatsit", "pdf_literal")
    paint.data = M.circle_pdfstring(0, 0, radiusx_sp, radiusy_sp, bordercolor, fillcolor, rulewidth_sp)
    if colentry.alpha then
        publisher.attribute_helpers.setprop(paint, "opacity", colentry.alpha)
    end
    local v = node.vpack(paint)
    return v
end

-- Builds MetaPost source for a `placeholder://WxH` image: a grey
-- rectangle with a diagonal cross and a border, sized so the bounding
-- box is exactly `w x h` bp. The natural dimensions then drive the
-- standard image scaling and aspect-ratio handling.
---@param w integer Width in bp.
---@param h integer Height in bp.
---@return string mpsrc
function M.placeholder_metapost(w, h)
    return string.format(
        [[
fill (0,0)--(%d,0)--(%d,%d)--(0,%d)--cycle withcolor 0.85white;
pickup pencircle scaled 0.4bp;
draw (0,0)--(%d,%d) withcolor 0.5white;
draw (0,%d)--(%d,0) withcolor 0.5white;
pickup pencircle scaled 0.6bp;
draw (0,0)--(%d,0)--(%d,%d)--(0,%d)--cycle withcolor 0.4white;
]],
        w,
        w,
        h,
        h,
        w,
        h,
        h,
        w,
        w,
        w,
        h,
        h
    )
end

-- Compiles a MetaPost figure source and returns the resulting drawing
-- as a node, optionally clipped to `(width, height)`.
---@param dataxml table Data XML context (used for variable substitution).
---@param txt string MetaPost source.
---@param width integer? Width in sp.
---@param height integer? Height in sp.
---@param clip boolean? Clip the output to the given dimensions.
---@return Node? hbox
function M.do_metapostimage(dataxml, txt, width, height, clip)
    publisher.metapostgraphics["_image"] = txt
    local cp = publisher.current_page
    local width_sp, height_sp
    if tonumber(width) then
        width_sp = cp.grid:width_sp(tonumber(width))
    else
        width_sp = tex.sp(width)
    end
    if tonumber(height) then
        height_sp = cp.grid:height_sp(tonumber(height))
    else
        height_sp = tex.sp(height)
    end

    local box, bbox = metapost.boxgraphic(width_sp, height_sp, "_image", {}, {})
    if not box or not bbox then
        main.log("error", "Could not create metapost image")
        return
    end
    local image = {
        xsize = bp_to_sp(bbox[3] - bbox[1]),
        ysize = bp_to_sp(bbox[4] - bbox[2]),
    }

    image.width = image.xsize
    image.height = image.ysize

    height = publisher.images.set_image_length(dataxml, height, "height") or image.height
    width = publisher.images.set_image_length(dataxml, width, "width") or image.width
    publisher.minheight = publisher.images.set_image_length(dataxml, publisher.minheight, "height") or 0
    publisher.minwidth = publisher.images.set_image_length(dataxml, publisher.minwidth, "width") or 0
    publisher.maxheight = publisher.images.set_image_length(dataxml, publisher.maxheight, "height")
        or publisher.maxdimen
    publisher.maxwidth = publisher.images.set_image_length(dataxml, publisher.maxwidth, "width") or publisher.maxdimen

    if not clip then
        width, height = publisher.images.calculate_image_width_height(
            image,
            width,
            height,
            publisher.minwidth,
            publisher.minheight,
            publisher.maxwidth,
            publisher.maxheight,
            publisher.stretch
        )

        box = node.hpack(box)
        box.width = width
        box.height = height
        box = node.vpack(box)

        local scaler = node.new("whatsit", "pdf_literal")
        local pdf_save = node.new("whatsit", "pdf_save")
        local pdf_restore = node.new("whatsit", "pdf_restore")

        local scaleX = math.round(width / image.xsize, 3)
        local scaleY = math.round(height / image.ysize, 3)
        local shiftX = -bbox[1] * scaleX
        local shiftY = -bbox[2] * scaleY + sp_to_bp(height) * (scaleY - 1)
        local scalerdata = string.format("%g 0 0 %g %g %g cm ", scaleX, scaleY, shiftX, shiftY)
        scaler.data = scalerdata

        box.head = node.insert_before(box.head, box.head, scaler)
        box.head = node.insert_before(box.head, box.head, pdf_save)
        box.height = 0
        box.depth = 0
        box = node.vpack(box)
        node.insert_after(box.head, box.head, pdf_restore)
        box.height = height
    end

    return { box, nil }
end

-- Wraps a MetaPost graphic in an hbox using the named template from
-- `publisher.metapostgraphics`.
---@param parameter table Per-call MetaPost parameters (variable values, name).
---@param width integer? Target width in sp.
---@param height integer? Target height in sp.
---@return Node? hbox
function M.mpbox(parameter, width, height)
    local width_sp = width
    local height_sp = height
    local extra_parameter = {}

    extra_parameter.bordertopwidth = sp_to_bp(parameter.border_top_width) .. "bp"
    extra_parameter.borderbottomwidth = sp_to_bp(parameter.border_bottom_width) .. "bp"
    extra_parameter.borderleftwidth = sp_to_bp(parameter.border_left_width) .. "bp"
    extra_parameter.borderrightwidth = sp_to_bp(parameter.border_right_width) .. "bp"
    -- no width if style is none
    if parameter.border_top_style == "none" then
        extra_parameter.bordertopwidth = "0bp"
    end
    if parameter.border_bottom_style == "none" then
        extra_parameter.borderbottomwidth = "0bp"
    end
    if parameter.border_left_style == "none" then
        extra_parameter.borderleftwidth = "0bp"
    end
    if parameter.border_right_style == "none" then
        extra_parameter.borderrightwidth = "0bp"
    end

    extra_parameter.paddingtop = sp_to_bp(parameter.padding_top or 0) .. "bp"
    extra_parameter.paddingbottom = sp_to_bp(parameter.padding_bottom or 0) .. "bp"
    extra_parameter.paddingleft = sp_to_bp(parameter.padding_left or 0) .. "bp"
    extra_parameter.paddingright = sp_to_bp(parameter.padding_right or 0) .. "bp"

    extra_parameter.colors = {
        bordertopcolor = parameter.border_top_color,
        borderbottomcolor = parameter.border_bottom_color,
        borderleftcolor = parameter.border_left_color,
        borderrightcolor = parameter.border_right_color,
    }
    extra_parameter.strings = {
        bordertopstyle = parameter.border_top_style,
        borderbottomstyle = parameter.border_bottom_style,
        borderleftstyle = parameter.border_left_style,
        borderrightstyle = parameter.border_right_style,
    }
    extra_parameter.boolean = {
        debug = parameter.debug == true,
    }

    local mptext = [[
        wd = box.width  ;
        ht = box.height - bordertopwidth - borderbottomwidth ;
        if ht < 0: ht := 0; fi;
        if wd < 0: wd := 0; fi;
        z1 = (0,-borderbottomwidth - paddingbottom);
        x2 = borderleftwidth;
        x3 = x2 + wd + paddingleft + paddingright;
        x4 = x3 + borderrightwidth;

        y2 = y1 + borderbottomwidth;
        y3 = y2 + ht + borderbottomwidth + paddingtop + paddingbottom;
        y4 = y3 + bordertopwidth;

        % draw z1 -- (x4,y1) -- z4 -- (x1,y4) -- cycle;
        % draw z2 -- (x3,y2) -- z3 -- (x2,y3) -- cycle;

        picture border; border = nullpicture;

        path clip_top, clip_bottom, clip_left, clip_right;
        clip_top = (x1,y4) -- (x2,y3) -- z3 -- z4 -- cycle;
        clip_bottom = (x1,y1) -- (x2,y2) -- (x3,y2) -- (x4,y1) -- cycle;
        clip_left = (x1,y1) -- (x2,y2) -- (x2,y3) -- (x1,y4) -- cycle;
        clip_right = (x4,y1) -- (x3,y2) -- (x3,y3) -- (x4,y4) -- cycle;
        def isdarkcolor(expr c) =
            (redpart c < 0.2) and (greenpart c < 0.2) and (bluepart c < 0.2 )
        enddef;

        def drawborder(expr bordercolor, bwd, style, a, b, clippath, pos) =
            begingroup;
            interim linecap := butt;

            color col; col = bordercolor;
            string str;
            str = "withcolor col withpen pencircle scaled " & decimal bwd ;
            if style = "dashed":
                str := str & " dashed dashpattern(on 4bp off 5bp)"
            elseif ( style = "inset" )  and  (  (pos = "top" )  or (pos = "left") ):
                if isdarkcolor(col):
                    str := str & " withcolor 0.2[col, white] ";
                else:
                    str := str & " withcolor 0.5[col, black] ";
                fi;
            elseif ( style = "inset" ) and isdarkcolor(col) and ( (pos = "bottom" ) or (pos = "right") ):
                str := str & " withcolor 0.5[col, white] ";
            elseif ( style = "outset" )  and  (  (pos = "right" ) or (pos = "bottom") ):
                str := str & " withcolor 0.5[col, black] ";
            fi;
            drawoptions(scantokens(str));

            draw a -- b ;
            clip currentpicture to clippath ;
            addto border also currentpicture ;
            endgroup;
        enddef;

        y34 = 0.5[y3,y4];
        y12 = 0.5[y1,y2];
        x12 = 0.5[x1,x2];
        x34 = 0.5[x3,x4];

        drawborder(bordertopcolor,bordertopwidth, bordertopstyle, (x1,y34),(x4,y34), clip_top, "top" );
        drawborder(borderbottomcolor,borderbottomwidth,borderbottomstyle, (x1,y12),(x4,y12), clip_bottom, "bottom");
        drawborder(borderleftcolor,borderleftwidth, borderleftstyle,(x12,y1),(x12,y4), clip_left, "left" );
        drawborder(borderrightcolor,borderrightwidth, borderrightstyle,(x34,y1),(x34,y4), clip_right, "right" );

        currentpicture := border;
        if debug:
            drawoptions(scaled 3bp withcolor black );
            drawdot(z1) withcolor blue;
            drawdot(z2) withcolor red;
            drawdot(z3) withcolor red;
            drawdot(z4) withcolor blue;
        fi;
    ]]
    publisher.metapostgraphics.__htmlbox = mptext

    local instr = metapost.boxgraphic(width_sp, height_sp, "__htmlbox", extra_parameter)
    if not instr then
        main.log("error", "Could not create metapost image")
        return
    end

    local ret = node.hpack(instr, width, "exactly")
    ret.height = height
    if parameter.shiftdown then
        ret.height = ret.height + parameter.shiftdown
    end
    ret = node.vpack(ret)

    node.set_attribute(ret, publisher.att_dontadjustlineheight, 1)
    ret.height = 0
    ret.depth = 0
    ret.shift = parameter.margin_left
    return ret
end

-- Create a colored area. width and height are in scaled points.
-- Optional border_color (color name) and border_width (in sp) draw a stroke
-- rectangle at the outer edge; the fill area shrinks inward by border_width.
-- Returns a colored rectangle hbox of the given size, optionally with a
-- border in another color.
---@param width_sp integer
---@param height_sp integer
---@param colorname string|integer Fill color.
---@param border_color string|integer|nil Border color (`nil` for none).
---@param border_width_sp integer? Border width in sp.
---@return Node hbox
function M.box(width_sp, height_sp, colorname, border_color, border_width_sp)
    local h, v
    local _width = sp_to_bp(width_sp)
    local _height = sp_to_bp(height_sp)
    local pdfcmds = {}

    -- Border stroke (full size, centered on edge → offset inward by half line width)
    if border_color and border_width_sp and border_width_sp > 0 then
        local bw = sp_to_bp(border_width_sp)
        local half = bw / 2
        local border_colentry = colors_module.colors[border_color]
        if not border_colentry then
            main.log(
                "error",
                string.format("Color %q unknown, reverting to black", border_color or "(no color name given)")
            )
            border_colentry = colors_module.colors["black"]
        end
        pdfcmds[#pdfcmds + 1] = string.format(
            "q %s %g w %g %g %g %g re S Q",
            border_colentry.pdfstring,
            bw,
            half,
            -half,
            _width - bw,
            -(_height - bw)
        )
    end

    -- Fill (shrunk by border width on each side)
    if colorname ~= "-" then
        local colentry = colors_module.colors[colorname]
        if not colentry then
            main.log(
                "error",
                string.format("Color %q unknown, reverting to black", colorname or "(no color name given)")
            )
            colentry = colors_module.colors["black"]
        end
        local bw = border_width_sp and sp_to_bp(border_width_sp) or 0
        local fill_x = bw
        local fill_y = -bw
        local fill_w = _width - 2 * bw
        local fill_h = _height - 2 * bw
        if fill_w > 0 and fill_h > 0 then
            pdfcmds[#pdfcmds + 1] = string.format(
                "q %s 1 0 0 1 0 0 cm %g %g %g %g re f Q",
                colentry.pdfstring,
                fill_x,
                fill_y,
                fill_w,
                -fill_h
            )
        end
    end

    if #pdfcmds > 0 then
        local paint = node.new("whatsit", "pdf_literal")
        publisher.attribute_helpers.setprop(paint, "role", publisher.structure_tree.get_rolenum("Artifact"))
        paint.data = table.concat(pdfcmds, " ")
        paint.mode = 0
        if colorname ~= "-" then
            local colentry = colors_module.colors[colorname]
            if colentry and colentry.alpha then
                publisher.attribute_helpers.set_attribute(
                    paint,
                    "color",
                    colors_module.get_colorindex_from_name(colorname)
                )
            end
        end
        local hglue = set_glue(nil, { width = 0, stretch = 2 ^ 16, stretch_order = 3 })
        h = node.insert_after(paint, paint, hglue)
        h = node.hpack(h, width_sp, "exactly")
    else
        h = publisher.nodes.create_empty_hbox_with_width(width_sp)
    end

    local vglue = set_glue(nil, { width = 0, stretch = 2 ^ 16, stretch_order = 3 })
    node.insert_after(h, h, vglue)
    v = node.vpack(h, height_sp, "exactly")
    return v
end

-- Inserts a thin black rule at the head of `hbox` for visual debugging.
---@param hbox Node
---@return nil
function M.addhrule(hbox)
    local n = node.new("whatsit", "pdf_literal")
    n.data = string.format(
        "q 0.3 w [2 1] 0 d 0 0 1 RG 0 %g  m %g %g l S Q",
        sp_to_bp(hbox.height),
        -sp_to_bp(hbox.width),
        sp_to_bp(hbox.height)
    )
    local tail = node.tail(hbox)
    hbox = node.insert_after(hbox, tail, n)
    hbox = node.hpack(hbox)
    return hbox
end

-- Adds a debug rule around `box` so its bounding box is visible.
---@param box Node
---@return Node box
function M.boxit(box)
    local box = node.hpack(box)

    local rule_width = 0.1
    local wd = box.width / publisher.factor - rule_width
    local ht = (box.height + box.depth) / publisher.factor - rule_width
    local dp = box.depth / publisher.factor - rule_width / 2

    local wbox = node.new("whatsit", "pdf_literal")
    wbox.data = string.format("q 0.1 G %g w %g %g %g %g re s Q", rule_width, rule_width / 2, -dp, -wd, ht)
    wbox.mode = 0
    -- Draw box at the end so its contents gets "below" it.
    local tmp = node.tail(box.list)
    tmp.next = wbox
    return box
end

-- Builds a colored bar (hrule wrapped in an hbox) with the given metrics.
---@param wd integer Width in sp.
---@param ht integer Height in sp (above baseline).
---@param dp integer Depth in sp (below baseline).
---@param color string|integer Color name or index.
---@param origin? string Origin tag for `setprop` (debugging).
---@param orientation? "horizontal"|"vertical" Defaults to horizontal.
---@return Node hbox
function M.colorbar(wd, ht, dp, color, origin, orientation)
    local colorname = color
    if color == "-" then
        -- ok, ignore
    else
        if not colorname or colorname == "" then
            colorname = "black"
        end
        if not colors_module.colors[colorname] then
            main.log("error", string.format("Color %q not found", color))
            colorname = "black"
        end
    end

    local rule_start = node.new("whatsit", "pdf_literal")
    publisher.attribute_helpers.setprop(rule_start, "origin", "colorbar")
    if colorname ~= "-" then
        local ht_bp = sp_to_bp(ht)
        local wd_bp = sp_to_bp(wd)
        rule_start.mode = 0
        local data = "q " .. colors_module.colors[colorname].pdfstring
        local rule_width_bp, rule_length_bp

        if not publisher.options.tablerulefix then
            if orientation == "horizontal" then
                -- draw horizontal line
                rule_width_bp = ht_bp
                rule_length_bp = wd_bp
                data = data
                    .. string.format(
                        " %g w 0 %g m %g %g l s Q ",
                        rule_width_bp,
                        rule_width_bp / 2,
                        rule_length_bp,
                        rule_width_bp / 2
                    )
            else
                rule_width_bp = wd_bp
                rule_length_bp = ht_bp
                data = data
                    .. string.format(
                        " %g w %g %g m %g %g l s Q ",
                        rule_width_bp,
                        rule_width_bp / 2,
                        rule_length_bp,
                        rule_width_bp / 2,
                        0
                    )
            end
        else
            if orientation == "horizontal" then
                rule_width_bp = ht_bp
                rule_length_bp = wd_bp
                -- draw horiztontal line a bit lower
                data = data
                    .. string.format(
                        " %g w %g %g m %g %g l s Q ",
                        rule_width_bp,
                        0,
                        rule_width_bp / -2,
                        rule_length_bp,
                        rule_width_bp / -2
                    )
            else
                rule_width_bp = wd_bp
                rule_length_bp = ht_bp
                -- draw the vertical borders in negative direction
                data = data
                    .. string.format(
                        " %g w %g %g m %g %g l s Q ",
                        rule_width_bp,
                        rule_width_bp / 2,
                        -1 * rule_length_bp,
                        rule_width_bp / 2,
                        0
                    )
            end
        end
        rule_start.data = data
        if publisher.options.tablerulefix then
            publisher.attribute_helpers.setprop(rule_start, "data", data)
        end
        publisher.attribute_helpers.setprop(rule_start, "role", publisher.structure_tree.get_rolenum("Artifact"))
    end
    local h = node.hpack(rule_start)
    h.width = wd
    h.depth = dp
    h.height = ht
    origin = origin or "origin_colorbar"
    publisher.attribute_helpers.setprop(h, "origin", origin)
    return h
end

local explode = function(s, p)
    local t = {}
    for s in string.gmatch(s, p) do
        if s ~= "" then
            t[#t + 1] = s
        end
    end
    return t
end

-- Stacks `nodelist_foreground` on top of `nodelist_background` with the
-- foreground anchored at `(origin_x, origin_y)` relative to the background.
---@param nodelist_background Node
---@param nodelist_foreground Node
---@param origin_x integer Offset in sp.
---@param origin_y integer Offset in sp.
---@return Node hbox
function M.montage(nodelist_background, nodelist_foreground, origin_x, origin_y)
    local wd_bg = nodelist_background.width
    local ht_bg = nodelist_background.height + nodelist_background.depth
    local dp_bg = nodelist_background.depth
    local wd_fg = nodelist_foreground.width
    local ht_fg = nodelist_foreground.height + nodelist_foreground.depth
    local wd = wd_bg - wd_fg
    local ht = ht_bg - ht_fg
    origin_x = 100 - origin_x
    origin_y = 100 - origin_y
    local x = math.round(sp_to_bp(wd - (wd * origin_x) / 100), 3)
    local y = math.round(sp_to_bp(ht - (ht * origin_y) / 100), 3)

    local pdf_literal_q = node.new("whatsit", "pdf_literal")
    pdf_literal_q.data = string.format("1 0 0 1 %g %g cm ", x, y)

    local pdf_literal_Q = node.new("whatsit", "pdf_literal")
    pdf_literal_Q.data = string.format("1 0 0 1 %g 0 cm ", -1 * math.round(sp_to_bp(wd_bg), 3))

    local pdf_save = node.new("whatsit", "pdf_save")
    local pdf_restore = node.new("whatsit", "pdf_restore")
    local hbox

    hbox = node.insert_before(nodelist_background, nodelist_background, pdf_save)
    hbox = node.insert_after(hbox, node.tail(hbox), pdf_literal_Q)
    hbox = node.insert_after(hbox, node.tail(hbox), pdf_literal_q)
    hbox = node.insert_after(hbox, node.tail(hbox), nodelist_foreground)

    hbox = node.hpack(hbox)
    hbox.depth = 0
    hbox = node.insert_after(hbox, node.tail(hbox), pdf_restore)

    hbox = node.vpack(hbox)
    hbox.width = wd_bg
    hbox.height = ht_bg - dp_bg
    hbox.depth = dp_bg
    return hbox
end

-- Apply transformation matrix to object given at _nodelist_. Called from commands#transformation.
-- Applies an arbitrary affine transformation to a node list.
---@param nodelist Node Source node list.
---@param matrix TransformMatrix
---@param origin_x integer Origin offset in sp.
---@param origin_y integer Origin offset in sp.
---@return Node hbox
function M.matrix(nodelist, matrix, origin_x, origin_y)
    local wd, ht = nodelist.width, nodelist.height
    local tbl = explode(matrix, "[^\t ]+")

    origin_x = 100 - origin_x
    origin_y = 100 - origin_y
    local x = math.round(sp_to_bp(wd - (wd * origin_x) / 100), 3)
    local y = math.round(sp_to_bp(ht - (ht * origin_y) / 100), 3)

    local pdf_literal_q = node.new("whatsit", "pdf_literal")
    local pdf_literal_Q = node.new("whatsit", "pdf_literal")

    pdf_literal_q.data = string.format(
        "q 1 0 0 1 %g %g cm q %g %g %g %g %g %g cm q 1 0 0 1 %g %g cm ",
        x,
        -1 * y,
        tbl[1],
        tbl[2],
        tbl[3],
        tbl[4],
        tbl[5],
        tbl[6],
        x * -1,
        y
    )
    pdf_literal_Q.data = "Q Q Q"

    local pdf_save = node.new("whatsit", "pdf_save")
    local pdf_restore = node.new("whatsit", "pdf_restore")

    local hbox
    hbox = node.insert_before(nodelist, nodelist, pdf_literal_q)
    node.insert_after(nodelist, nodelist, pdf_literal_Q)
    hbox = node.insert_before(hbox, pdf_literal_q, pdf_save)
    hbox = node.hpack(hbox)

    hbox.depth = 0
    node.insert_after(hbox, node.tail(hbox), pdf_restore)

    local newbox = node.vpack(hbox)
    return newbox
end

-- Rotate an object clockwise with a given angle (in degrees).
--
-- First rotate the object at the top left corner (default)
-- If the origin is not top left, we need to shift the object
-- Rotates a node list around `(origin_x, origin_y)` by `angle` degrees.
---@param nodelist Node
---@param angle number Rotation in degrees (counter-clockwise).
---@param origin_x integer Origin offset in sp.
---@param origin_y integer Origin offset in sp.
---@return Node hbox
function M.rotate(nodelist, angle, origin_x, origin_y)
    local wd, ht = nodelist.width, nodelist.height + nodelist.depth
    nodelist.width = 0
    nodelist.height = 0
    nodelist.depth = 0

    -- positive would be counter clockwise, but CSS is clockwise. So we multiply by -1
    local angle_rad = -1 * math.rad(angle)
    local sin = math.round(math.sin(angle_rad), 3)
    local cos = math.round(math.cos(angle_rad), 3)
    local q = node.new("whatsit", "pdf_literal")
    q.mode = 0

    origin_x = 100 - origin_x
    origin_y = 100 - origin_y
    local x = math.round(sp_to_bp(wd - (wd * origin_x) / 100), 3)
    local y = math.round(sp_to_bp(ht - (ht * origin_y) / 100), 3)
    q.data = string.format(
        "q 1 0 0 1 %g -%g cm  q %g %g %g %g 0 0 cm q 1 0 0 1 -%g %g cm ",
        x,
        y,
        cos,
        sin,
        -1 * sin,
        cos,
        x,
        y
    )
    q.next = nodelist
    local tail = node.tail(nodelist)
    local Q = node.new("whatsit", "pdf_literal")
    Q.data = "Q Q Q"
    tail.next = Q
    local tmp = node.vpack(q)
    tmp.width = 0
    tmp.height = 0
    tmp.depth = 0
    return tmp
end

-- Rotate a table cell clockwise with a given angle (in degrees).
-- This is a simple and very basic implementation which needs to be extended in the future.
-- Rotates a table-cell (Td) node list by `angle` degrees, fitting it
-- into the column width.
---@param nodelist Node
---@param angle number Rotation in degrees.
---@param width_sp integer Target width in sp.
---@return Node hbox
function M.rotateTd(nodelist, angle, width_sp)
    if angle % 360 == 0 then
        return nodelist
    end

    -- positive would be counter clockwise, but CSS is clockwise. So we multiply by -1
    local angle_rad = -1 * math.rad(angle)

    -- With multi paragraph table cells it is easier if we have only one node to deal with.
    if nodelist.next then
        nodelist = node.vpack(nodelist)
    end

    -- When text is rotated, it needs to get shifted to the right and to the bottom
    local _wd, _ht, _dp = nodelist.width, nodelist.height, nodelist.depth
    local ht = _ht + _dp

    nodelist.width = 0
    nodelist.height = 0
    nodelist.depth = 0

    local sin = math.round(math.sin(angle_rad), 3)
    local cos = math.round(math.cos(angle_rad), 3)

    local q = node.new("whatsit", "pdf_literal")
    q.mode = 0

    local shift_x, shift_y

    local shift_x_wd = cos * _wd
    local shift_x_ht = sin * ht
    if shift_x_wd > 0 then
        shift_x_wd = 0
    end
    if shift_x_ht > 0 then
        shift_x_ht = 0
    end

    local shift_y_wd = -1 * sin * _wd
    local shift_y_ht = cos * ht
    if shift_y_wd > 0 then
        shift_y_wd = 0
    end
    if shift_y_ht > 0 then
        shift_y_ht = 0
    end

    shift_x = sp_to_bp(shift_x_ht + shift_x_wd) * -1
    shift_y = sp_to_bp(shift_y_ht + shift_y_wd)

    q.data = string.format("q %g %g %g %g %g %g cm ", cos, sin, -1 * sin, cos, shift_x, shift_y)
    local Q = node.new("whatsit", "pdf_literal")
    Q.data = "Q"

    _, q = node.insert_before(nodelist, nodelist, q)
    node.insert_after(q, nodelist, Q)
    q = node.vpack(q)

    q.width = math.abs(_wd * cos) + math.abs(ht * sin)
    q.height = math.abs(ht * cos) + math.abs(_wd * sin)
    q.depth = 0

    return q
end

-- Rotate a text on a given angle (`angle` on textblock).
-- Rotates a textblock node list by `angle` degrees around its origin.
---@param nodelist Node
---@param angle number Rotation in degrees.
---@return Node hbox
function M.rotate_textblock(nodelist, angle)
    local wd, ht = nodelist.width, nodelist.height + nodelist.depth
    nodelist.width = 0
    nodelist.height = 0
    nodelist.depth = 0
    local angle_rad = math.rad(angle)
    local sin = math.round(math.sin(angle_rad), 3)
    local cos = math.round(math.cos(angle_rad), 3)
    local q = node.new("whatsit", "pdf_literal")
    q.mode = 0
    local shift_x =
        math.round(math.min(0, math.sin(angle_rad) * sp_to_bp(ht)) + math.min(0, math.cos(angle_rad) * sp_to_bp(wd)), 3)
    local shift_y = math.round(
        math.max(0, math.sin(angle_rad) * sp_to_bp(wd)) + math.max(0, -1 * math.cos(angle_rad) * sp_to_bp(ht)),
        3
    )
    q.data = string.format("q %g %g %g %g %g %g cm", cos, sin, -1 * sin, cos, -1 * shift_x, -1 * shift_y)
    q.next = nodelist
    local tail = node.tail(nodelist)
    local Q = node.new("whatsit", "pdf_literal")
    Q.data = "Q"
    tail.next = Q
    local tmp = node.vpack(q)
    tmp.width = math.abs(wd * cos) + math.abs(ht * math.cos(math.rad(90 - angle)))
    tmp.height = math.abs(ht * math.sin(math.rad(90 - angle))) + math.abs(wd * sin)
    tmp.depth = 0
    return tmp
end

file_end("drawing.lua")

return M
