-- Servermode - don't create pdf but ask for things
--
--  listen.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

local luxor = do_luafile("luxor.lua")
local comm = require("publisher.comm")
local paragraph  = require("paragraph")

local function analyze_format_xml( nodelist )
    local head = nodelist
    local txt = {}
    while head do
        if head.id == publisher.hlist_node or head.id == publisher.vlist_node then
            txt[#txt + 1] = analyze_format_xml(head.list)
        elseif head.id == publisher.glyph_node then
            txt[#txt + 1] = unicode.utf8.char(head.char)
        elseif head.id == publisher.glue_node then
            if head.subtype == 9 then
                txt[#txt + 1] = "<br />"
            elseif head.spec.width > 0 then
                txt[#txt + 1] = " "
            end
        elseif head.id == publisher.disc_node then
            local x = node.has_attribute(head,publisher.att_keep)
            if x == 1 then
                txt[#txt + 1] = '<shy class="keep" />'
            else
                txt[#txt + 1] = "<shy />"
            end
        end
        head = head.next
    end
    return table.concat(txt,"")
end

-- todo: move this into another file
local function fmt(msg)
    local nodelist
    local ret = {}
    local rootelt = luxor.parse_xml(msg)
    local a = paragraph:new()
    local parameter
    for i=1,#rootelt do
        local thiselement = rootelt[i]

        if type(thiselement) == "table" and thiselement[".__name"] == "text" then
            parameter = {}

            if thiselement["hyphenate-limit-before"] then
                parameter.left = tonumber(thiselement["hyphenate-limit-before"])
            end
            if thiselement["hyphenate-limit-after"] then
                parameter.right = tonumber(thiselement["hyphenate-limit-after"])
            end

            local txt = {}
            for j=1,#thiselement do
                local elt = thiselement[j]
                if type(elt) == "string" then
                    txt[#txt + 1] = elt
                elseif type(elt) == "table" and elt[".__name"] == "br" then
                    if elt.class == "keep" then
                        txt[#txt + 1] = "\n"
                    else
                        txt[#txt + 1] = " "
                    end
                elseif type(elt) == "table" and elt[".__name"] == "shy" then
                    if elt.class == "keep" then
                        txt[#txt + 1] = unicode.utf8.char(173)
                    end
                end
            end
            a:append(table.concat(txt,""),parameter)
            nodelist = a:format(1073741823)
            ret[#ret + 1] = "<text>" .. analyze_format_xml(nodelist) .. "</text>\n"
        end
    end

    comm.send_string_message("<root>\n" .. table.concat(ret) .."</root>\n\r")
end


local function servermode(tcp)
    log("Waiting for the server to talk to me...\n")
    synclog()
    while true do
        local s, status, partial = tcp:receive(12)
        nummessage,msgtype,msglength = unpack(string.explode(s,","))
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