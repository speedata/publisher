--  Internal communication with the parent process
--
--  comm.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.
local socket = require("socket")

local tcp,sendmessage

local function send_string_message(msg)
    sendmessage("str",msg)
end

function sendmessage(typ,msg)
    local x = string.format("1,%s,%06d%s",typ,#msg,msg)
    tcp:send(x)
end

function getmessage()
    local s, status, partial = tcp:receive(12)
    local nummessage,msgtype,_msglength = unpack(string.explode(s,","))
    local msglength = tonumber(_msglength)
    if msglength == 0 then
        return tonumber(nummessage),msgtype,""
    end
    local msg = tcp:receive(msglength)
    return tonumber(nummessage),msgtype,msg
end

function get_string_messages()
    local ret = {}
    repeat
        nummsg, msgtype, msg = getmessage()
        ret[#ret + 1] = msg
    until nummsg == 0
    return ret
end



local function listen()
    local port = os.getenv("SP_SERVERPORT")
    assert(port,"Port must be set (environment variable SP_SERVERPORT)")
    log("Talking to server on port %s",port)

    local host = "127.0.0.1"
    tcp = assert(socket.tcp())

    tcp:connect(host, port);
    return tcp
end

return {
    listen = listen,
    tcp = tcp,
    sendmessage = sendmessage,
    get_string_messages = get_string_messages,
    send_string_message = send_string_message,
}
