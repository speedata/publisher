-- Fonthandling after fontloading.
--
--  fonts.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.
--
-- Loading a font is only one part of the story. Proper dealing with fonts
-- requires post processing at various stages.
file_start("fonts.lua")

local publisher = require("publisher")

local fontloader_mod = require("fonts.fontloader")

local colors_module = require("publisher.colors")

---@class fonts_module
local M = {}

---@type table<string, { [1]: string, [2]: table }>
local lookup_fontname_filename = {}
---@type table<integer, table>
local font_instances = {}

---@type table<integer, table>
M.used_fonts = {}
local used_fonts = M.used_fonts

-- Tracks missing-glyph reports: missing_glyph_counts[font_name][code] = count.
-- Filled by report_missing_glyph(); flushed by summarize_missing_glyphs() at
-- the end of the run. We emit the warning only on first occurrence and then
-- print a "(N times)" summary for repeats, instead of flooding the log.
---@type table<string, table<integer, integer>>
M.missing_glyph_counts = {}

local glue_node = node.id("glue")
local glyph_node = node.id("glyph")
local disc_node = node.id("disc")
local rule_node = node.id("rule")
local dir_node = node.id("dir")
local kern_node = node.id("kern")
local penalty_node = node.id("penalty")
local whatsit_node = node.id("whatsit")
local hlist_node = node.id("hlist")
local vlist_node = node.id("vlist")

local pdf_dest_whatsit
for k, v in pairs(node.whatsits()) do
    if v == "pdf_dest" then
        pdf_dest_whatsit = k
    end
end

-- Every font family ("text", "Chapter") defined via `DefineFontfamily`
-- gets an internal number. This table maps the family name to that number.
---@type table<string, integer>
M.lookup_fontfamily_name_number = {}

-- Reverse lookup: every font family number maps to its `FontFamily` table
-- with the variants `normal`, `bold`, `italic`, `bolditalic` plus the
-- script-size instances and `size`/`baselineskip`.
---@type FontFamily[]
M.lookup_fontfamily_number_instance = {}
local lookup_fontfamily_number_instance = M.lookup_fontfamily_number_instance

-- Registers a font face under `name`, mapped to `filename` plus optional
-- per-call parameters. The actual loading is deferred until the face is
-- first used.
---@param name string Logical font face name.
---@param filename string Source file (resolved via kpse).
---@param parameter_tab? table Per-face parameters (otfeatures, ...).
---@return true
function M.load_fontfile(name, filename, parameter_tab)
    assert(filename)
    assert(name)
    lookup_fontname_filename[name] = { filename, parameter_tab or {} }
    return true
end

-- Reports whether a font face has been registered under `name` via
-- `load_fontfile`.
---@param name string Logical font face name.
---@return boolean
function M.is_registered(name)
    return lookup_fontname_filename[name] ~= nil
end

function table.find(tab, key)
    assert(tab)
    assert(key)
    local found
    for k_tab, v_tab in pairs(tab) do
        if type(key) == "table" then
            found = true
            for k_key, v_key in pairs(key) do
                if k_tab[k_key] ~= v_key then
                    found = false
                end
            end
            if found == true then
                return v_tab
            end
        end
    end
    return nil
end

local preloaded_fonts = {}

-- Resolves a font face name. Used from `html.lua` when a CSS rule
-- references a font face by URL or local name. If `localname` is not
-- registered but `url` is given, the URL is auto-loaded and returned.
---@param localname string?
---@param url string?
---@return string? face_name
function M.get_fontname(localname, url)
    localname = publisher.fontfamilies.get_fontname(localname)
    -- w("get_fontname, localname %q",tostring(localname))
    if localname and lookup_fontname_filename[localname] then
        return localname
    elseif url then
        M.load_fontfile(url, url)
        return url
    end
    return nil
end

-- Loads (or reuses) a font face at the given size and returns the LuaTeX font
-- instance id. After this call the font is registered under the key
-- {filename, size}.
---@param name string Registered font face name.
---@param size integer Size in scaled points.
---@return integer? id  LuaTeX font instance id, or `nil` on failure.
---@return string? err  Error message when `id` is `nil`.
function M.make_font_instance(name, size)
    -- Name is something like "TeXGyreHeros-Regular", the visible name of the font file
    assert(name)
    assert(tonumber(size))
    if not lookup_fontname_filename[name] then
        local msg = string.format("Font instance '%s' is not defined!", name)
        main.log("error", "Make font instance: filename is not defined", "filename", name)
        return nil, msg
    end
    local filename, parameter = table.unpack(lookup_fontname_filename[name])
    assert(filename)
    local k = {
        filename = filename,
        fontsize = size,
        space = parameter.space,
        fallbacks = parameter.fallbacks,
    }

    if parameter.otfeatures then
        for fea, enabled in pairs(parameter.otfeatures) do
            if enabled then
                k[fea] = true
            end
        end
    end
    local fontnumber = table.find(font_instances, k)
    if fontnumber then
        return fontnumber
    else
        local f
        local num = font.nextid(true)
        f = fontloader_mod.preload_font(filename, size, parameter)
        f.reserved_num = num
        preloaded_fonts[num] = f
        main.log(
            "debug",
            "Preload font",
            "name",
            filename,
            "size",
            tostring(math.round(size / publisher.factor, 3)),
            "id",
            tostring(num)
        )
        font_instances[k] = num
        return num
    end
end

-- Define font from preloaded font
-- Registers a previously created font instance with LuaTeX so glyphs can
-- reference it by id. Fills in the metrics and feature tables.
---@param instance table Font instance descriptor.
---@return boolean ok
function M.define_font(instance)
    local num = instance.reserved_num
    main.log(
        "info",
        "Create font metrics",
        "name",
        instance.requested_name,
        "size",
        math.round(instance.requested_size / publisher.factor, 3),
        "id",
        num
    )
    local ok, f = fontloader_mod.define_font_hb(
        instance.requested_name,
        instance.requested_size,
        instance.requested_extra_parameter
    )
    if not ok then
        main.log("error", "Failed to load font", "requested name", instance.requested_name, "errormessage", f or "")
        return false
    end
    -- On success the fontloader returns the font table, on failure the message.
    ---@cast f Font
    preloaded_fonts[num] = f
    used_fonts[num] = f
    font.define(num, f)
    return true
end

-- Return instance number from fontfamily number and instance name
-- Looks up the instance descriptor for a family + variant combination.
-- Loads the instance on demand if it has not been used before.
---@param fontfamily integer Family number from `lookup_fontfamily_name_number`.
---@param instancename "normal"|"bold"|"italic"|"bolditalic"|string Variant key.
---@return integer instance LuaTeX font instance id.
function M.get_fontinstance(fontfamily, instancename)
    local instance
    if fontfamily and fontfamily > 0 then
        instance = lookup_fontfamily_number_instance[fontfamily][instancename]
    else
        instance = 1
    end
    if not instance then
        local fam_tbl = lookup_fontfamily_number_instance[fontfamily]
        local familyname = fam_tbl and fam_tbl.name or "?"
        main.log("error", string.format("font %s not found for family %s (%s)", instancename, familyname, fontfamily))
        -- let's try "regular"
        if fontfamily and fontfamily > 0 then
            instance = lookup_fontfamily_number_instance[fontfamily].normal
        end
        if not instance then
            instance = 1
        end
    end
    local pe = preloaded_fonts[instance]
    if pe.loaded == false then
        local ok = M.define_font(pe)
        if not ok then
            return M.get_fontinstance(1, "normal")
        end
    end
    return instance
end

-- Return a defined (LuaTeX-registered) font instance for a font face name
-- at an arbitrary size, loading it on demand. The math setup uses this to
-- get the script and scriptscript sizes of a math font, which are not part
-- of any font family.
---@param name string Font face name (as defined via LoadFontfile).
---@param size number Font size in scaled points.
---@return integer? instance LuaTeX font instance id, nil on error.
---@return string? errmsg
function M.get_fontinstance_by_name_size(name, size)
    local num, err = M.make_font_instance(name, size)
    if not num then
        return nil, err
    end
    local pe = preloaded_fonts[num]
    if pe.loaded == false then
        local ok = M.define_font(pe)
        if not ok then
            return nil, string.format("could not define font %q at size %d", name, size)
        end
    end
    return num
end

-- At this time we must adjust the contents of the paragraph how we would
-- like it. For example the (sub/sup)script glyphs still have the width of
-- the regular characters and need
-- node.direct locals for pre_linebreak hot loop
local d = node.direct
local d_todirect = d.todirect
local d_tonode = d.tonode
local d_getnext = d.getnext
local d_getprev = d.getprev
local d_getid = d.getid
local d_getsubtype = d.getsubtype
local d_getchar = d.getchar
local d_getfont = d.getfont
local d_getlist = d.getlist
local d_getleader = d.getleader
local d_has_attribute = d.has_attribute
local d_set_attribute = d.set_attribute
local d_setfield = d.setfield
local d_getfield = d.getfield
local d_setnext = d.setnext
local d_setprev = d.setprev
local d_insert_after = d.insert_after
local d_insert_before = d.insert_before
local d_vpack = d.vpack
local d_hpack = d.hpack
local d_tail = d.tail
local d_getproperty = d.getproperty

-- Pre-resolved attribute numbers for pre_linebreak hot loop
local plb_att_fontfamily
local plb_att_fontstyle
local plb_att_fontweight
local plb_attval_italic -- index of "italic" in font-style table
local plb_attval_bold -- index of "bold" in font-weight table

-- Pre-linebreak callback (direct API): walks the node list and applies
-- every visual attribute we attached earlier — color, decoration,
-- background color, hyperlinks, vertical alignment, struct destinations.
-- Runs hot, so it uses the `node.direct` API.
---@param head any Node list head in direct-API form.
---@return any head
local function pre_linebreak_direct(head)
    -- Cache for consecutive same-font glyphs
    local cache_ff, cache_fs, cache_fw
    while head do
        local id = d_getid(head)
        if id == hlist_node then
            pre_linebreak_direct(d_getlist(head))
        elseif id == vlist_node then
            pre_linebreak_direct(d_getlist(head))
        elseif id == rule_node then
            -- ignore
        elseif id == dir_node then
            -- ignore
        elseif id == disc_node then
            local pre, post, replace = d.getdisc(head)
            pre_linebreak_direct(pre)
            pre_linebreak_direct(post)
            pre_linebreak_direct(replace)
        elseif id == whatsit_node then
            if d_getsubtype(head) == pdf_dest_whatsit then
                local dest_fontfamily = d_has_attribute(head, plb_att_fontfamily)
                if dest_fontfamily then
                    local tmpnext = d_getnext(head)
                    local tmpprev = d_getprev(head)
                    -- TeXLuaCATS declares direct.getprev as returning Node; the
                    -- corrected declaration in meta/node-extra.lua merges into a
                    -- union instead of replacing it, so narrow explicitly.
                    ---@cast tmpprev integer?
                    d_setnext(head, nil)
                    d_setprev(head, nil)
                    local instance = lookup_fontfamily_number_instance[dest_fontfamily]
                    local f = used_fonts[instance.normal]
                    local g = d_todirect(publisher.nodes.make_glue({ width = f.size }))

                    local h = d_insert_after(head, head, g)
                    h = d_vpack(h)

                    if tmpprev then
                        d_setnext(tmpprev, h)
                        d_setprev(h, tmpprev)
                    end
                    if tmpnext then
                        d_setprev(tmpnext, h)
                        d_setnext(h, tmpnext)
                    end
                end
            end
        elseif id == glue_node then
            if d_getsubtype(head) == 100 then -- leader
                local l = d_getleader(head)
                -- a glue node with the leader subtype always carries a leader
                ---@cast l -nil
                local wd = d_has_attribute(l, publisher.att_leaderwd)

                -- Set the font for the leader
                pre_linebreak_direct(l)

                local tmpbox
                if wd == -1 then
                    tmpbox = d_hpack(l)
                else
                    -- \hbox{ 1fil, text, 1fil }
                    local l1 = d_todirect(
                        set_glue(
                            nil,
                            { width = 0, stretch = 2 ^ 16, stretch_order = 2, shrink = 2 ^ 16, shrink_order = 2 }
                        )
                    )
                    local l2 = d_todirect(
                        set_glue(
                            nil,
                            { width = 0, stretch = 2 ^ 16, stretch_order = 2, shrink = 2 ^ 16, shrink_order = 2 }
                        )
                    )
                    local newhead = d_insert_before(l, l, l1)
                    local endoftext = d_tail(l)
                    newhead = d_insert_after(newhead, endoftext, l2)
                    tmpbox = d_hpack(newhead, wd, "exactly")
                end
                d_set_attribute(tmpbox, publisher.att_leaderwd, wd)
                d_setfield(head, "leader", tmpbox)
            end
        elseif id == kern_node then -- kern
        elseif id == penalty_node then -- penalty
        elseif id == glyph_node then
            local ff = d_has_attribute(head, plb_att_fontfamily)
            if ff then
                local fontfamily = ff

                -- Last resort
                if fontfamily == 0 then
                    fontfamily = 1
                    main.log("warn", "Undefined fontfamily, set fontfamily to 1")
                end

                local fontstyle = d_has_attribute(head, plb_att_fontstyle)
                local fontweight = d_has_attribute(head, plb_att_fontweight)

                if ff ~= cache_ff or fontstyle ~= cache_fs or fontweight ~= cache_fw then
                    local instancename
                    if fontstyle == plb_attval_italic and fontweight ~= plb_attval_bold then
                        instancename = "italic"
                    elseif fontstyle == plb_attval_italic and fontweight == plb_attval_bold then
                        instancename = "bolditalic"
                    elseif fontweight == plb_attval_bold then
                        instancename = "bold"
                    else
                        instancename = "normal"
                    end
                    M.get_fontinstance(fontfamily, instancename)
                    cache_ff = ff
                    cache_fs = fontstyle
                    cache_fw = fontweight
                end
            end
        else
            main.log("warn", string.format("Unknown node: %q", d_getid(head)))
        end
        head = d_getnext(head)
    end
    return true
end

-- Public pre-linebreak callback. Wraps `pre_linebreak_direct` for the
-- node API caller and is registered through `callback.register`.
---@param head Node
---@return Node head
function M.pre_linebreak(head)
    if not plb_att_fontfamily then
        plb_att_fontfamily = publisher.attribute_name_number["fontfamily"]
        plb_att_fontstyle = publisher.attribute_name_number["font-style"]
        plb_att_fontweight = publisher.attribute_name_number["font-weight"]
        -- font-style and font-weight are declared with fixed value lists in
        -- publisher.attributes, so they are never the `true` variant.
        local fs = publisher.attributes["font-style"]
        ---@cast fs string[]
        for i, v in ipairs(fs) do
            if v == "italic" then
                plb_attval_italic = i
                break
            end
        end
        local fw = publisher.attributes["font-weight"]
        ---@cast fw string[]
        for i, v in ipairs(fw) do
            if v == "bold" then
                plb_attval_bold = i
                break
            end
        end
    end
    return pre_linebreak_direct(d_todirect(head))
end

-- Inserts a background-color rule behind a glyph run starting at `start`
-- and extending while the same `bgcolorindex` is set.
---@param parent Node Surrounding hbox/vbox.
---@param head Node Head of the run.
---@param start Node First node carrying the background color.
---@param bgcolorindex integer? Color index from `colortable`.
---@param bg_padding_top integer? Padding above baseline in sp.
---@param bg_padding_bottom integer? Padding below baseline in sp.
---@param reverse boolean? Walk backwards (used for RTL runs).
---@return nil
function M.insert_backgroundcolor(parent, head, start, bgcolorindex, bg_padding_top, bg_padding_bottom, reverse)
    if bgcolorindex == nil then
        return
    end
    reverse = reverse or false
    bg_padding_top = bg_padding_top or 0
    bg_padding_bottom = bg_padding_bottom or 0
    local wd = node.dimensions(parent.glue_set, parent.glue_sign, parent.glue_order, start, head)
    local ht = parent.height
    local dp = parent.depth

    local colorname = colors_module.colortable[bgcolorindex]
    local pdfstring = colors_module.colors[colorname].pdfstring

    -- wd, ht and dp are now in pdf points
    wd = wd / publisher.factor
    ht = ht / publisher.factor
    dp = dp / publisher.factor
    bg_padding_top = bg_padding_top / publisher.factor
    bg_padding_bottom = bg_padding_bottom / publisher.factor
    local rule = node.new("whatsit", "pdf_literal")
    if reverse then
        wd = wd * -1
    end
    rule.data = string.format(
        "q %s 0 %g %g %g re f Q",
        pdfstring,
        -dp - bg_padding_bottom,
        wd,
        ht + dp + bg_padding_top + bg_padding_bottom
    )
    rule.mode = 0
    parent.head = node.insert_before(parent.head, start, rule)
    return rule
end

-- Insert a horizontal rule in the nodelist that is used for underlining.
-- Draws a text-decoration rule (underline / overline / line-through)
-- across the run starting at `start`.
---@param parent Node Surrounding box.
---@param head Node Head of the run.
---@param start Node First node carrying the decoration.
---@param typ integer? Value index into `publisher.attributes["text-decoration-line"]`.
---@param style integer? Value index into `publisher.attributes["text-decoration-style"]`.
---@param colornumber integer? Color index.
---@return nil
function M.insert_underline(parent, head, start, typ, style, colornumber)
    colornumber = colornumber or 1
    if colornumber == 0 then
        colornumber = 1
    end
    -- typ and style arrive as the integer indices stored in the node
    -- attributes; publisher.attributes maps them back to the CSS names.
    local td_lines = publisher.attributes["text-decoration-line"]
    local td_styles = publisher.attributes["text-decoration-style"]
    ---@cast td_lines string[]
    ---@cast td_styles string[]
    local typname = typ and td_lines[typ]
    local stylename = style and td_styles[style]
    local wd = node.dimensions(parent.glue_set, parent.glue_sign, parent.glue_order, start, head)
    local ht = parent.height
    local dp = parent.depth
    local dashpattern = ""
    local pdfstring = colors_module.pdfstring_from_color(colornumber)

    -- wd, ht and dp are now in pdf points
    wd = wd / publisher.factor
    ht = ht / publisher.factor
    dp = dp / publisher.factor
    local rule = node.new("whatsit", "pdf_literal")
    publisher.attribute_helpers.setprop(rule, "origin", "insert_underline")
    -- thickness: ht / ...
    -- downshift: dp/2
    local rule_width = math.round(ht / 13, 3)
    if stylename == "dashed" then
        dashpattern = string.format("[%g] 0 d", 3 * rule_width)
    end

    local shift_down = (dp - rule_width) / 1.5
    if typname == "line-through" then
        shift_down = -1.6 * shift_down
    end
    rule.data = string.format(
        "q %s %g w %s 0 %g m %g %g l S Q",
        pdfstring,
        rule_width,
        dashpattern,
        -1 * shift_down,
        -wd,
        -1 * shift_down
    )
    rule.mode = 0
    local attribs = publisher.attribute_helpers.get_attributes(start)
    publisher.attribute_helpers.set_attributes(rule, attribs)
    parent.head = node.insert_before(parent.head, head, rule)
    return rule
end

-- In the post_linebreak function we manipulate the paragraph that doesn't
-- affect it's typesetting. Underline and 'showhyphens' is done here. The
-- overall appearance of the paragraph is fixed at this time, we can only add
-- decoration now.
do
    local curdir = {}
    local plb_attnum_td_line
    local plb_attnum_td_style
    local plb_attnum_td_color
    local plb_attnum_bgcolor
    local plb_attnum_bgpad_top
    local plb_attnum_bgpad_bottom

    local function post_linebreak_direct(head, list_head_d)
        local insert_bgcolor = M.insert_backgroundcolor
        local insert_ul = M.insert_underline
        local opts = publisher.options
        local underlinetype = nil
        local underlinestyle = nil
        local start_underline = nil
        local underline_color = nil
        local bgcolorindex = nil
        local start_bgcolor = nil
        local bgcolor_reverse = false
        -- Always assigned together with start_bgcolor; nil when the glyph
        -- carries no background padding attribute.
        local bg_padding_top, bg_padding_bottom
        local reportmissingglyphs = opts.reportmissingglyphs
        local lasthead = nil
        local fast_path = not (opts.showhyphenation or opts.showkerning or reportmissingglyphs)
        while head do
            local id = d_getid(head)
            local props = d_getproperty(head)
            if props then
                local pd = props.pardir
                if pd and #curdir == 0 then
                    curdir = { pd }
                end
            end
            if id == hlist_node then
                post_linebreak_direct(d_getlist(head), head)
            elseif id == vlist_node then
                post_linebreak_direct(d_getlist(head), head)
            elseif id == dir_node then
                local dirval = d_getfield(head, "dir")
                local mode = string.sub(dirval, 1, 1)
                local texdir = string.sub(dirval, 2, 4)
                local ldir
                if texdir == "TLT" then
                    ldir = "ltr"
                else
                    ldir = "rtl"
                end
                if mode == "+" then
                    curdir[#curdir + 1] = ldir
                elseif mode == "-" then
                    local x = curdir[#curdir]
                    curdir[#curdir] = nil
                    if x ~= ldir then
                        main.log("warn", string.format("paragraph direction incorrect, found %s, expected %s", ldir, x))
                    end
                end
                if start_bgcolor then
                    insert_bgcolor(
                        d_tonode(list_head_d),
                        d_tonode(head),
                        d_tonode(start_bgcolor),
                        bgcolorindex,
                        bg_padding_top,
                        bg_padding_bottom,
                        bgcolor_reverse
                    )
                    start_bgcolor = nil
                end
            elseif id == disc_node then
                if opts.showhyphenation then
                    local n = node.new("whatsit", "pdf_literal")
                    n.mode = 0
                    n.data = "q 0.3 w 0 2 m 0 7 l S Q"
                    node.insert_before(d_tonode(list_head_d), d_tonode(head), n)
                end
            elseif id == kern_node then
                if fast_path and not start_underline and not start_bgcolor then
                    goto continue_loop
                end
                local ul = d_has_attribute(head, plb_attnum_td_line)
                local bgcolor = d_has_attribute(head, plb_attnum_bgcolor)
                if ul == nil then
                    if start_underline then
                        insert_ul(
                            d_tonode(list_head_d),
                            d_tonode(head),
                            d_tonode(start_underline),
                            underlinetype,
                            underlinestyle,
                            underline_color
                        )
                        start_underline = nil
                    end
                end
                if bgcolor == nil then
                    if start_bgcolor then
                        insert_bgcolor(
                            d_tonode(list_head_d),
                            d_tonode(head),
                            d_tonode(start_bgcolor),
                            bgcolorindex,
                            bg_padding_top,
                            bg_padding_bottom,
                            bgcolor_reverse
                        )
                        start_bgcolor = nil
                    end
                end
                if opts.showkerning then
                    local n = node.new("whatsit", "pdf_literal")
                    n.mode = 0
                    n.data = "q .4 G 0.3 w 0 2 m 0 7 l S Q"
                    node.insert_before(d_tonode(list_head_d), d_tonode(head), n)
                end
            elseif id == glue_node then
                -- Fast path: skip when no decoration/bgcolor active or pending
                if fast_path and not start_underline and not start_bgcolor then
                    if
                        not d_has_attribute(head, plb_attnum_td_line) and not d_has_attribute(head, plb_attnum_bgcolor)
                    then
                        goto continue_loop
                    end
                end
                local ul = d_has_attribute(head, plb_attnum_td_line)
                local bgcolor = d_has_attribute(head, plb_attnum_bgcolor)

                -- at rightskip we must underline (if start exists)
                if ul == nil or d_getsubtype(head) == 9 then
                    if start_underline then
                        insert_ul(
                            d_tonode(list_head_d),
                            d_tonode(head),
                            d_tonode(start_underline),
                            underlinetype,
                            underlinestyle,
                            underline_color
                        )
                        start_underline = nil
                    end
                end
                if bgcolor and bgcolor > 0 and not start_bgcolor then
                    bgcolor_reverse = (curdir[#curdir] == "rtl")
                    bgcolorindex = bgcolor
                    start_bgcolor = head
                    bg_padding_top = d_has_attribute(head, plb_attnum_bgpad_top)
                    bg_padding_bottom = d_has_attribute(head, plb_attnum_bgpad_bottom)
                elseif bgcolor == nil or d_getsubtype(head) == 9 then -- 9 == rightskip
                    if start_bgcolor then
                        insert_bgcolor(
                            d_tonode(list_head_d),
                            d_tonode(head),
                            d_tonode(start_bgcolor),
                            bgcolorindex,
                            bg_padding_top,
                            bg_padding_bottom,
                            bgcolor_reverse
                        )
                        start_bgcolor = nil
                    end
                end
            elseif id == glyph_node then
                local ul = d_has_attribute(head, plb_attnum_td_line)
                local bgcolor = d_has_attribute(head, plb_attnum_bgcolor)
                -- Fast path: skip when no decoration/bgcolor active or pending
                if fast_path and not ul and not bgcolor and not start_underline and not start_bgcolor then
                    goto continue_loop
                end
                if reportmissingglyphs then
                    local thisfont = used_fonts[d_getfont(head)]
                    local thischar = d_getchar(head)
                    if thisfont and thischar and not thisfont.characters[thischar] then
                        local lvl = reportmissingglyphs == "warning" and "warn" or "error"
                        M.report_missing_glyph(lvl, thisfont.name, thischar)
                    end
                end
                if ul then
                    if not start_underline then
                        underlinetype = ul
                        underlinestyle = d_has_attribute(head, plb_attnum_td_style)
                        start_underline = head
                        underline_color = d_has_attribute(head, plb_attnum_td_color)
                    end
                else
                    if start_underline then
                        insert_ul(
                            d_tonode(list_head_d),
                            d_tonode(head),
                            d_tonode(start_underline),
                            underlinetype,
                            underlinestyle,
                            underline_color
                        )
                        start_underline = nil
                    end
                end
                if bgcolor and bgcolor > 0 then
                    if not start_bgcolor then
                        bgcolorindex = bgcolor
                        bg_padding_top = d_has_attribute(head, plb_attnum_bgpad_top)
                        bg_padding_bottom = d_has_attribute(head, plb_attnum_bgpad_bottom)
                        start_bgcolor = head
                        bgcolor_reverse = (curdir[#curdir] == "rtl")
                    end
                else
                    if start_bgcolor then
                        insert_bgcolor(
                            d_tonode(list_head_d),
                            d_tonode(head),
                            d_tonode(start_bgcolor),
                            bgcolorindex,
                            bg_padding_top,
                            bg_padding_bottom,
                            bgcolor_reverse
                        )
                        start_bgcolor = nil
                    end
                end
            end
            ::continue_loop::
            lasthead = head
            head = d_getnext(head)
        end
        if start_bgcolor then
            local _, dummy = publisher.nodes.add_rule(
                d_tonode(lasthead),
                "tail",
                { width = 0, height = 0, depth = 0 },
                "bgcolor dummy"
            )
            insert_bgcolor(
                d_tonode(list_head_d),
                assert(dummy),
                d_tonode(start_bgcolor),
                bgcolorindex,
                bg_padding_top,
                bg_padding_bottom,
                bgcolor_reverse
            )
        end
        return head
    end

    function M.post_linebreak(head, list_head)
        if not plb_attnum_td_line then
            plb_attnum_td_line = publisher.attribute_name_number["text-decoration-line"]
            plb_attnum_td_style = publisher.attribute_name_number["text-decoration-style"]
            plb_attnum_td_color = publisher.attribute_name_number["text-decoration-color"]
            plb_attnum_bgcolor = publisher.attribute_name_number["background-color"]
            plb_attnum_bgpad_top = publisher.attribute_name_number["bgpaddingtop"]
            plb_attnum_bgpad_bottom = publisher.attribute_name_number["bgpaddingbottom"]
        end
        return post_linebreak_direct(d_todirect(head), list_head and d_todirect(list_head))
    end
end

-- Clones an existing font family with overridden parameters (size,
-- baselineskip, ...). Used when one family inherits from another.
-- On failure the original family number is returned.
---@param fam integer Source family number.
---@param params table Overrides applied to the clone.
---@return integer newfam New family number (or `fam` on failure).
function M.clone_family(fam, params)
    -- fam_tbl = {
    --   ["baselineskip"] = "789372"
    --   ["name"] = "text"
    --   ["normalscript"] = "10"
    --   ["scriptsize"] = "526248"
    --   ["normal"] = "9"
    --   ["size"] = "657810"
    -- },
    local fam_tbl = lookup_fontfamily_number_instance[fam]
    local newfam = {}
    for k, v in pairs(fam_tbl) do
        newfam[k] = v
    end
    newfam.name = "cloned"

    if newfam.fontfaceregular then
        local id, err = M.make_font_instance(newfam.fontfaceregular, params.size * newfam.size)
        if not id then
            main.log("error", err or "could not make the font instance")
            return fam
        end
        newfam.normal = id
    end

    if newfam.fontfacebold then
        local id, err = M.make_font_instance(newfam.fontfacebold, params.size * newfam.size)
        if not id then
            main.log("error", err or "could not make the font instance")
            return fam
        end
        newfam.bold = id
    end

    if newfam.fontfaceitalic then
        local id, err = M.make_font_instance(newfam.fontfaceitalic, params.size * newfam.size)
        if not id then
            main.log("error", err or "could not make the font instance")
            return fam
        end
        newfam.italic = id
    end

    if newfam.fontfacebolditalic then
        local id, err = M.make_font_instance(newfam.fontfacebolditalic, params.size * newfam.size)
        if not id then
            main.log("error", err or "could not make the font instance")
            return fam
        end
        newfam.bolditalic = id
    end

    newfam.size = math.floor(params.size * newfam.size)
    lookup_fontfamily_number_instance[#lookup_fontfamily_number_instance + 1] = newfam
    return #lookup_fontfamily_number_instance
end

-- Report a missing glyph, deduplicated by (font, code).
-- The first occurrence is logged immediately at `level` ("warn" or "error");
-- subsequent occurrences only increment the counter. summarize_missing_glyphs()
-- emits a "(N times)" summary line for codes seen more than once.
-- Extra arguments are passed through to the immediate log call only.
-- Records a missing-glyph occurrence. The first hit per (font, code)
-- emits a log entry; subsequent hits only bump the counter.
---@param level "warn"|"error"|"info"|string Log level for the first occurrence.
---@param font_name string
---@param code integer Unicode codepoint.
---@param ... any Additional log arguments.
---@return nil
function M.report_missing_glyph(level, font_name, code, ...)
    local per_font = M.missing_glyph_counts[font_name]
    if not per_font then
        per_font = {}
        M.missing_glyph_counts[font_name] = per_font
    end
    local prev = per_font[code]
    if prev then
        per_font[code] = prev + 1
        return
    end
    per_font[code] = 1
    main.log(level, "Glyph is missing from the font", "font", font_name, "glyph_hex", string.format("%04x", code), ...)
end

-- Emits the `(N times)` summary log lines for repeated missing-glyph
-- reports collected during the run. Called once at shutdown.
---@return nil
function M.summarize_missing_glyphs()
    local rows = {}
    for font_name, per_font in next, M.missing_glyph_counts do
        for code, count in next, per_font do
            if count > 1 then
                rows[#rows + 1] = { font = font_name, code = code, count = count }
            end
        end
    end
    if #rows == 0 then
        return
    end
    table.sort(rows, function(a, b)
        if a.count ~= b.count then
            return a.count > b.count
        end
        if a.font ~= b.font then
            return a.font < b.font
        end
        return a.code < b.code
    end)
    for _, r in ipairs(rows) do
        main.log(
            "warn",
            "Glyph is missing from the font (repeated)",
            "font",
            r.font,
            "glyph_hex",
            string.format("%04x", r.code),
            "count",
            tostring(r.count)
        )
    end
end

file_end("fonts.lua")

return M
