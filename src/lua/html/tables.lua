--- Table building helpers for the HTML parser.
--- Minimal extraction of build_html_table_tbody and build_html_table.
--- Relies on global `publisher`, `tex`, and uses a callback to build child nodelists.
local units      = require("html.units")
local styles_mod = require("html.styles")
local inherit    = require("html.inherit")

local M = {}

---@class HtmlTableCallbacks
---@field build_nodelist fun(elt:table, options:table|nil, before_box:any|nil, caller:string, prevdir:string|nil, dataxml:table): (any[], string|nil)

---Build the table body (tbody/thead/tfoot) into the Publisher tabular row structure.
---@param tbody table                     -- the HTML tbody/thead/tfoot element tree
---@param cb HtmlTableCallbacks           -- callbacks including build_nodelist
---@param dataxml table                   -- data context
---@param stylesstack table               -- styles inheritance stack
---@return table                          -- array of Tr{ contents = { Td{...}, ... } }
function M.build_html_table_tbody(tbody, cb, dataxml, stylesstack)
    local trtab = {}

    for row = 1, #tbody do
        local tr = tbody[row]
        if type(tr) == "table" and tr.elementname then
            local tdtab = {}

            for cell = 1, #tr do
                local td = tr[cell]
                if type(td) == "table" and td.elementname then
                    -- Set up a fresh styles table with inheritance via the surrounding stack in html.lua.
                    -- Here we just copy attributes to a new table instance and compute paddings/borders.

                    local td_styles = td.styles or {}
                    local styles = inherit.push(stylesstack)
                    styles_mod.copy_attributes(styles, td_styles)
                    -- Build nodelist for td contents using the host's build_nodelist
                    local r = cb.build_nodelist(td, {["font-weight"] = styles["font-weight"]}, nil, "build_html_table_tbody/td", nil, dataxml)

                    r = publisher.flatten_boxes(r)

                    -- Transform each line/box into Paragraph nodes expected by tabular
                    local newcontents = {}
                    for i = 1, #r do
                        local newtd = { elementname = "Paragraph", contents = r[i] }
                        table.insert(newcontents, newtd)
                    end

                    -- Copy cell border and padding styles onto the container (as in your original)
                    local att = td_styles
                    if att then
                        local bbw = att["border-bottom-width"]
                        local btw = att["border-top-width"]
                        local brw = att["border-right-width"]
                        local blw = att["border-left-width"]
                        if bbw then newcontents["border-bottom"] = bbw end
                        if btw then newcontents["border-top"] = btw end
                        if blw then newcontents["border-left"] = blw end
                        if brw then newcontents["border-right"] = brw end
                        local bbc = att["border-bottom-color"]
                        local btc = att["border-top-color"]
                        local brc = att["border-right-color"]
                        local blc = att["border-left-color"]
                        if bbc then newcontents["border-bottom-color"] = bbc end
                        if btc then newcontents["border-top-color"] = btc end
                        if blc then newcontents["border-left-color"] = blc end
                        if brc then newcontents["border-right-color"] = brc end
                        local pt = att["padding-top"]
                        local pb = att["padding-bottom"]
                        local pl = att["padding-left"]
                        local pr = att["padding-right"]
                        if pt then newcontents.padding_top    = units.getsize(styles, pt, styles.fontsize_sp) end
                        if pb then newcontents.padding_bottom = units.getsize(styles, pb, styles.fontsize_sp) end
                        if pl then newcontents.padding_left   = units.getsize(styles, pl, styles.fontsize_sp) end
                        if pr then newcontents.padding_right  = units.getsize(styles, pr, styles.fontsize_sp) end
                    end
                    inherit.pop(stylesstack)
                    tdtab[#tdtab + 1] = { elementname = "Td", contents = newcontents }
                end
            end

            -- Row attributes (e.g., vertical-align)
            local att = tr.attributes
            if att then
                local valign = att["vertical-align"]
                if valign == "top" or valign == "bottom" or valign == "middle" then
                    tdtab.valign = valign
                end
            end

            trtab[#trtab + 1] = { elementname = "Tr", contents = tdtab }
        end
    end

    return trtab
end

---Build a Publisher tabular node from a <table> element.
---@param table_elt table                -- the HTML table element
---@param cb HtmlTableCallbacks          -- callbacks including build_nodelist
---@param dataxml table
---@param stylesstack table              -- styles inheritance stack
---@return any                           -- a single node (the constructed table box)
function M.build_html_table(table_elt, width, cb, dataxml, stylesstack)
    assert(dataxml, "build_html_table requires dataxml")

    local tablecontents = table_elt
    local head, foot, body = {}, {}, {}

    -- Decompose into sections
    for i = 1, #tablecontents do
        local thiselt = tablecontents[i]
        local typ = type(thiselt)
        if typ == "table" then
            local eltname = thiselt.elementname
            if eltname == "tbody" then
                body = M.build_html_table_tbody(thiselt, cb, dataxml, stylesstack)
            elseif eltname == "tfoot" then
                foot = M.build_html_table_tbody(thiselt, cb, dataxml, stylesstack)
            elseif eltname == "thead" then
                head = M.build_html_table_tbody(thiselt, cb, dataxml, stylesstack)
            end
        end
    end

    -- Instantiate tabular and transfer geometry/options like in your original
    local t = require("publisher.tabular")
    local tabular = t:new()
    tabular.width = width

    if tablecontents.styles and tablecontents.styles.width == "100%" then
        tabular.autostretch = "max"
    end

    local tab = {}
    for i = 1, #head do tab[#tab + 1] = head[i] end
    for i = 1, #body do tab[#tab + 1] = body[i] end
    for i = 1, #foot do tab[#tab + 1] = foot[i] end
    tabular.tab = tab

    -- Fontfamily "text" fallback wie im Original
    local fontname = "text"
    local fontfamily = publisher.fonts.lookup_fontfamily_name_number[fontname]
    if fontfamily == nil then
        err(string.format("Fontfamily %q not found.", fontname or "???"))
        fontfamily = 1
    end
    tabular.fontfamily = fontfamily

    -- Original default options / paddings / borders
    tabular.options = { ht_max = 99999 * 2^16 }
    tabular.padding_left   = 0
    tabular.padding_top    = 0
    tabular.padding_right  = 0
    tabular.padding_bottom = 0
    tabular.colsep         = 0
    tabular.rowsep         = 0
    tabular.bordercollapse_horizontal = true
    tabular.bordercollapse_vertical   = true
    tabular.dataxml = dataxml

    local n = tabular:make_table(dataxml)
    return n[1]
end

return M
