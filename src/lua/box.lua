--- Building and formatting a paragraph / box
--
--  box.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("box.lua")

Box = {}
Box.__index = Box

function Box:new()
    local mybox = {
        prependbox = {},
        typ = "box"
    }
    setmetatable(mybox, self)
    return mybox
end

function Box:prepend( whatever )
    self.prependbox[#self.prependbox  + 1] = whatever
end

file_end("box.lua")



