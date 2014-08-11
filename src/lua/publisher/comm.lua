--  Internal communication with the parent process
--
--  comm.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.
local socket = require("socket")

local tcp

local function listen()
    local port = os.getenv("SP_SERVERPORT")
    log("Talking to server on port %s",port)

    local host = "127.0.0.1"
    tcp = assert(socket.tcp())

    tcp:connect(host, port);
    return tcp
end

return {
    listen = listen,
    tcp = tcp,
}