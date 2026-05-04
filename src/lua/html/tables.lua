--- Table building helpers for the HTML parser.
--- Minimal extraction of build_html_table_tbody and build_html_table.
--- Relies on global `publisher`, `tex`, and uses a callback to build child nodelists.

local publisher = require("publisher")

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
---@param border_collapse boolean|nil     -- true if border-collapse: collapse is set
---@return table                          -- array of Tr{ contents = { Td{...}, ... } }
function M.build_html_table_tbody(tbody, cb, dataxml, stylesstack, border_collapse)
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

                    -- Copy cell border and padding styles onto the container
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

                        local currentcolor = att.color or "black"
                        if bbc then if bbc == "currentcolor" then bbc = currentcolor end newcontents["border-bottom-color"] = bbc end
                        if btc then if btc == "currentcolor" then btc = currentcolor end newcontents["border-top-color"] = btc end
                        if blc then if blc == "currentcolor" then blc = currentcolor end newcontents["border-left-color"] = blc end
                        if brc then if brc == "currentcolor" then brc = currentcolor end newcontents["border-right-color"] = brc end
                        local pt = att["padding-top"]
                        local pb = att["padding-bottom"]
                        local pl = att["padding-left"]
                        local pr = att["padding-right"]
                        if pt then newcontents.padding_top    = units.getsize(styles, pt, styles.fontsize_sp) end
                        if pb then newcontents.padding_bottom = units.getsize(styles, pb, styles.fontsize_sp) end
                        if pl then newcontents.padding_left   = units.getsize(styles, pl, styles.fontsize_sp) end
                        if pr then newcontents.padding_right  = units.getsize(styles, pr, styles.fontsize_sp) end
                        -- Background color for cell, with fallback to tr and thead/tbody
                        local bgcolor = att["background-color"]
                            or (tr.styles and tr.styles["background-color"])
                            or (tbody.styles and tbody.styles["background-color"])
                        if bgcolor then
                            newcontents.backgroundcolor = bgcolor
                        end
                    end
                    -- Copy colspan/rowspan from HTML attributes
                    local td_attr = td.attributes
                    if td_attr then
                        if td_attr.colspan then newcontents.colspan = td_attr.colspan end
                        if td_attr.rowspan then newcontents.rowspan = td_attr.rowspan end
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
---@return any                           -- array of table nodes (split across pages)
function M.build_html_table(table_elt, width, cb, dataxml, stylesstack)
    assert(dataxml, "build_html_table requires dataxml")

    local tablecontents = table_elt
    local head, foot, body = {}, {}, {}

    -- Check for border-collapse before building sections
    local table_styles = tablecontents.styles
    local border_collapse = table_styles and table_styles["border-collapse"] == "collapse"

    -- Decompose into sections
    for i = 1, #tablecontents do
        local thiselt = tablecontents[i]
        local typ = type(thiselt)
        if typ == "table" then
            local eltname = thiselt.elementname
            if eltname == "tbody" then
                body = M.build_html_table_tbody(thiselt, cb, dataxml, stylesstack, border_collapse)
            elseif eltname == "tfoot" then
                foot = M.build_html_table_tbody(thiselt, cb, dataxml, stylesstack, border_collapse)
            elseif eltname == "thead" then
                head = M.build_html_table_tbody(thiselt, cb, dataxml, stylesstack, border_collapse)
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

    -- Wrap thead rows in Tablehead structure so they repeat on each page
    if #head > 0 then
        local tablehead_contents = {}
        for i = 1, #head do
            tablehead_contents[i] = head[i]
        end
        tablehead_contents.page = "all"
        tab[#tab + 1] = { elementname = "Tablehead", contents = tablehead_contents }
    end

    -- Body rows go directly into tab
    for i = 1, #body do tab[#tab + 1] = body[i] end

    -- Wrap tfoot rows in Tablefoot structure so they repeat on each page
    if #foot > 0 then
        local tablefoot_contents = {}
        for i = 1, #foot do
            tablefoot_contents[i] = foot[i]
        end
        tablefoot_contents.page = "all"
        tab[#tab + 1] = { elementname = "Tablefoot", contents = tablefoot_contents }
    end

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
    -- Use publisher.getheight directly - it may be replaced for HTML-in-Output
    tabular.options = { ht_max = publisher.getheight(1,dataxml) } -- a heuristic
    tabular.getheight      = function(...) return publisher.getheight(...) end
    tabular.padding_left   = 0
    tabular.padding_top    = 0
    tabular.padding_right  = 0
    tabular.padding_bottom = 0
    tabular.colsep         = 0
    tabular.rowsep         = 0

    -- For border-collapse: set all three flags for proper visual rendering
    if border_collapse then
        tabular.bordercollapse_horizontal = true
        tabular.bordercollapse_vertical   = true
        tabular.bordercollapse = true
    end

    tabular.dataxml = dataxml

    local n = tabular:make_table(dataxml)
    return n
end

return M
