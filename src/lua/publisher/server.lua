-- Servermode - don't create pdf but ask for things
--
--  listen.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

local luxor = do_luafile("luxor.lua")
local comm = require("publisher.comm")

-- todo: move this into another file


local function fmt(msg)
    local x = luxor.parse_xml(msg)
    local rootelt = x
    for i=1,#rootelt do
        if type(rootelt[i]) == "table" and rootelt[i][".__name"] == "text" then
            local foo = rootelt[i]
            local txt = ""
            for j=1,#foo do
                local elt = foo[j]
                if type(elt) == "string" then
                    txt = txt .. elt
                elseif type(elt) == "table" and elt[".__name"] == "br" then
                    txt = txt .. "\n"
                end
            end
            w(txt)
            local j = publisher.mknodes(txt)
        end
    end
    synclog()
    comm.sendmessage(msg)
end


local function servermode(tcp)
    log("Waiting for the server to talk to me...\n")
    synclog()
    while true do
        local s, status, partial = tcp:receive(12)
        nummessage,msgtype,msglength = table.unpack(string.explode(s,","))
        msglength = tonumber(msglength)
        msg = tcp:receive(msglength)
        if msgtype == "fmt" then
            fmt(msg)
        end
        if status == "closed" then break end
    end
end




return {
    servermode = servermode,
}