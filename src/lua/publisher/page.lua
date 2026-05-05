--
--  page.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

local publisher = require("publisher")

local grid = require("publisher.grid")

---@class Page
---@field grid Grid Page grid instance.
---@field width integer Page width in sp (without bleed).
---@field height integer Page height in sp (without bleed).
---@field transparenttext table<integer, true> Set of alpha values used on the page.
---@field pagebox Node Vlist node holding the page contents.
---@field defaultcolor? string Default text color name.
---@field matter? string Matter name (for page label generation).
---@field structparents? integer PDF/UA `/StructParents` index.
page = {}

-- Constructs a fresh `Page` with a fresh `Grid` and 1cm default margins.
---@param self Page
---@param width integer Page width in sp.
---@param height integer Page height in sp.
---@param additional_margin? integer Cut-mark margin in sp (default 0).
---@param trim? integer Bleed in sp (default 0).
---@param pagenumber? integer Logical page number (debugging).
---@return Page? page
---@return string? errmsg Set when `width` is missing.
function page.new(self, width, height, additional_margin, trim, pagenumber)
    assert(self)
    if not width then
        return nil, "No information about page width found. Did you give the command <Pageformat>?"
    end
    assert(height)

    additional_margin = additional_margin or 0
    trim = trim or 0

    local s = {
        grid = grid:new(pagenumber),
        width = width,
        height = height,
        transparenttext = {}, -- values for alpha
        pagebox = node.new("vlist"),
    }

    s.grid.extra_margin = additional_margin
    s.grid.trim = trim
    -- default margin: 1cm
    s.grid:set_margin(publisher.tenmm_sp, publisher.tenmm_sp, publisher.tenmm_sp, publisher.tenmm_sp)

    tex.pagewidth = width + additional_margin * 2
    tex.pageheight = height + additional_margin * 2

    setmetatable(s, self)
    return s
end

return page
