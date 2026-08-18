--- Page/layout helpers for the HTML parser.
--- Provides handle_pages(), which prepares page size, margins, and maxwidth vars.

local publisher = require("publisher")

local M = {}

---Prepare page geometry and max layout width/height variables.
---Mirrors the legacy behavior from html.lua.
---@param pages table                              -- elt.pages
---@param maxwidth_sp number|nil                   -- optional override for max width
---@param dataxml table                            -- data context (vars)
---@return nil
function M.handle_pages(pages, maxwidth_sp, dataxml)
    -- Relies on global publisher/tex/xpath as in the legacy code
    local pagewd = tex.pagewidth

    -- nothing here; set below where needed

    local masterpage = pages and pages["*"]

    if masterpage then
        local wd, ht

        if masterpage.width then
            wd = tex.sp(masterpage.width) or pagewd
            dataxml.vars["_pagewidth"] = masterpage.width

            pagewd = wd

            if masterpage.height then
                dataxml.vars["_pageheight"] = masterpage.height
                ht = tex.sp(masterpage.height) or tex.pageheight
                publisher.page_helpers.set_pageformat(wd, ht)

                dataxml.vars["__maxwidth"] = wd
                dataxml.vars["__maxheight"] = ht
            end
        end

        -- Default margins: 10mm each side
        local margin_left = publisher.tenmm_sp
        local margin_right = publisher.tenmm_sp
        local margin_bottom = publisher.tenmm_sp
        local margin_top = publisher.tenmm_sp

        local mt = masterpage["margin-top"]
        local mr = masterpage["margin-right"]
        local mb = masterpage["margin-bottom"]
        local ml = masterpage["margin-left"]

        if mt then
            margin_top = tex.sp(mt) or margin_top
        end
        if mr then
            margin_right = tex.sp(mr) or margin_right
        end
        if mb then
            margin_bottom = tex.sp(mb) or margin_bottom
        end
        if ml then
            margin_left = tex.sp(ml) or margin_left
        end

        pagewd = pagewd - margin_left - margin_right

        dataxml.vars["__maxwidth"] = pagewd

        -- Ensure pageformat is set even if only width provided.
        -- Without a width (e.g. an @page rule with margins only) there is
        -- nothing to set and tex.pagewidth/pageheight must keep their values.
        if wd then
            publisher.page_helpers.set_pageformat(wd, ht or tex.pageheight)
        end

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
                    end,
                },
            },
            name = "Default HTML page",
            ns = { [""] = "urn:speedata.de:2009/publisher/en" },
        }
    else
        -- No explicit master page
        if maxwidth_sp then
            pagewd = maxwidth_sp
        else
            local margin_right = publisher.tenmm_sp
            local margin_left = publisher.tenmm_sp
            pagewd = pagewd - margin_left - margin_right
        end

        dataxml.vars["__maxwidth"] = pagewd
    end
end

return M
