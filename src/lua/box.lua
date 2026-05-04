-- Building and formatting a paragraph / box
--
--  box.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("box.lua")

---@class Box
---@field prependbox any[] Items injected at the head of the formatted output.
---@field typ "box"
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



