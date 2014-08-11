-- Servermode - don't create pdf but ask for things
--
--  listen.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

local comm = require("publisher.comm")

local function servermode(tcp)
    log("Waiting for the server to talk to me...\n")
    synclog()
    while true do
        local s, status, partial = tcp:receive(12)
        nummessage,msgtype,msglength = table.unpack(string.explode(s,","))
        msglength = tonumber(msglength)
        msg = tcp:receive(msglength)
        if status == "closed" then break end
    end

end

return {
    servermode = servermode,
}