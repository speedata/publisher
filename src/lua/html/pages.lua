--- Page/layout helpers for the HTML parser.
--- Provides handle_pages(), which prepares page size, margins, and maxwidth vars.
local M = {}

---Prepare page geometry and max layout width/height variables.
---Mirrors the legacy behavior from html.lua.
---@param pages table                              -- elt.pages
---@param maxwidth_sp number|nil                   -- optional override for max width
---@param dataxml table                            -- data context (vars if newxpath)
---@return nil
function M.handle_pages(pages, maxwidth_sp, dataxml)
    -- Relies on global publisher/tex/xpath as in the legacy code
    local pagewd = tex.pagewidth

    if publisher.newxpath then
        -- nothing here; set below where needed
    else
        xpath.set_variable("__maxwidth", pagewd)
        xpath.set_variable("__maxheight", tex.pageheight)
    end

    local masterpage = pages and pages["*"]

    if masterpage then
        local wd, ht

        if masterpage.width then
            wd = tex.sp(masterpage.width)
            if publisher.newxpath then
                dataxml.vars["_pagewidth"] = masterpage.width
            else
                xpath.set_variable("_pagewidth", masterpage.width)
            end

            pagewd = wd

            if masterpage.height then
                if publisher.newxpath then
                    dataxml.vars["_pageheight"] = masterpage.height
                else
                    xpath.set_variable("_pageheight", masterpage.height)
                end
                ht = tex.sp(masterpage.height)
                publisher.set_pageformat(wd, ht)

                if publisher.newxpath then
                    dataxml.vars["__maxwidth"]  = wd
                    dataxml.vars["__maxheight"] = ht
                else
                    xpath.set_variable("__maxwidth", wd)
                    xpath.set_variable("__maxheight", ht)
                end
            end
        end

        -- Default margins: 10mm each side
        local margin_left   = publisher.tenmm_sp
        local margin_right  = publisher.tenmm_sp
        local margin_bottom = publisher.tenmm_sp
        local margin_top    = publisher.tenmm_sp

        local mt            = masterpage["margin-top"]
        local mr            = masterpage["margin-right"]
        local mb            = masterpage["margin-bottom"]
        local ml            = masterpage["margin-left"]

        if mt then margin_top = tex.sp(mt) end
        if mr then margin_right = tex.sp(mr) end
        if mb then margin_bottom = tex.sp(mb) end
        if ml then margin_left = tex.sp(ml) end

        pagewd = pagewd - margin_left - margin_right

        if publisher.newxpath then
            dataxml.vars["__maxwidth"] = pagewd
        else
            xpath.set_variable("__maxwidth", pagewd)
        end

        -- Ensure pageformat is set even if only width provided
        publisher.set_pageformat(wd, ht)

        -- Create a default masterpage entry (as in legacy)
        publisher.masterpages[1] = {
            is_pagetype = "true()",
            res = {
                width = wd,
                height = ht,
                {
                    elementname = "Margin",
                    contents = function(page)
                        page.grid:set_margin(margin_left, margin_top, margin_right, margin_bottom)
                    end
                }
            },
            name = "Default HTML page",
            ns = { [""] = "urn:speedata.de:2009/publisher/en" }
        }
    else
        -- No explicit master page
        if maxwidth_sp then
            pagewd = maxwidth_sp
        else
            local margin_right = publisher.tenmm_sp
            local margin_left  = publisher.tenmm_sp
            pagewd             = pagewd - margin_left - margin_right
        end

        if publisher.newxpath then
            dataxml.vars["__maxwidth"] = pagewd
        else
            xpath.set_variable("__maxwidth", pagewd)
        end
    end
end

return M
