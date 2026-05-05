-- Building and formatting a paragraph / box
--
--  box.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("box.lua")

---@class BoxBorder
---@field borderstart? boolean
---@field border_top_style? string
---@field border_right_style? string
---@field border_bottom_style? string
---@field border_left_style? string
---@field padding_top? number
---@field padding_right? number
---@field padding_bottom? number
---@field padding_left? number
---@field border_top_width? number
---@field border_right_width? number
---@field border_bottom_width? number
---@field border_left_width? number
---@field border_top_color? string
---@field border_right_color? string
---@field border_bottom_color? string
---@field border_left_color? string
---@field border_top_left_radius? number
---@field border_top_right_radius? number
---@field border_bottom_left_radius? number
---@field border_bottom_right_radius? number
---@field margin_top? number
---@field margin_right? number
---@field margin_bottom? number
---@field margin_left? number
---@field debug? boolean

---@class Box
---@field prependbox any[] Items injected at the head of the formatted output.
---@field typ "box"
---@field eltname? string Name of the element that creates the box (div for example)
---@field margintop? number
---@field marginbottom? number
---@field padding_top? number
---@field padding_bottom? number
---@field border_top_width? number
---@field border_bottom_width? number
---@field indent_amount? number
---@field width? number
---@field draw_border? boolean
---@field break_before? "page"|"always"
---@field break_after? "avoid"
---@field border? BoxBorder
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



