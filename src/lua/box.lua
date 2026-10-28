-- Building and formatting a paragraph / box
--
--  box.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("box.lua")

---@class CSSBlock
---@field x integer Left edge of the border box relative to the containing block (the left margin).
---@field width integer Width of the border box.
---@field border_top_width integer
---@field border_bottom_width integer
---@field padding_top integer
---@field padding_bottom integer
---@field height? integer Content height from the CSS height property.
---@field decoration? CSSBoxStyle Background and borders.

---@class Box
---@field prependbox any[] Items injected at the head of the formatted output.
---@field typ "box"
---@field eltname? string Name of the element that creates the box (div for example)
---@field margintop? number
---@field marginbottom? number
---@field indent_amount? number
---@field width? number
---@field break_before? "page"|"always"
---@field break_after? "avoid"
---@field css? CSSBlock Box model of an HTML block element.
Box = {}
Box.__index = Box

-- Constructs a fresh `Box` instance.
---@param self Box
---@return Box
function Box:new()
    local mybox = {
        prependbox = {},
        typ = "box"
    }
    setmetatable(mybox, self)
    return mybox
end

-- Appends `whatever` to the prepend queue.
---@param self Box
---@param whatever any
---@return nil
function Box:prepend( whatever )
    self.prependbox[#self.prependbox  + 1] = whatever
end

file_end("box.lua")



