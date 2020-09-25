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


function Box:format(width_sp)
    -- w("box:format")
    -- w("self.indent_amount %s",tostring(self.indent_amount))
    -- printtable("self",self)
    for i=1,#self do
        local thisboxpart = self[i]
        if thisboxpart[1] and thisboxpart[1].contents then
            thisboxpart:indent(self.indent_amount)
            return thisboxpart:format(width_sp)
        end
    end
end

file_end("box.lua")



