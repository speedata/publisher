--
--  tabstops.lua
--  speedata publisher
--
--  Tab stops (DefineTextformat tab-stops): a tab character advances to the
--  next stop instead of being a space.
--

file_start("publisher/tabstops.lua")

local publisher = require("publisher")

---@class tabstops_module
local M = {}

local glyph_node = node.id("glyph")
local glue_node = node.id("glue")
local penalty_node = node.id("penalty")
local hlist_node = node.id("hlist")

---@class TabStop
---@field pos? integer Position in sp from the start edge of the paragraph.
---@field percent? number Position in percent of the paragraph width.
---@field align "left"|"right"|"center"|"decimal"
---@field separator? integer Code point a decimal stop aligns on.
---@field leader? string Text repeated across the tab.

-- Splits str at the separator characters seps outside of parentheses and
-- quotes and returns the non-empty parts.
---@param str string
---@param seps string Lua pattern character class, such as "[,]".
---@return string[]
local function split(str, seps)
    local ret = {}
    local depth = 0
    local quote
    local buf = {}
    for _, c in utf8.codes(str) do
        local ch = utf8.char(c)
        if quote then
            if ch == quote then
                quote = nil
            end
            buf[#buf + 1] = ch
        elseif ch == '"' or ch == "'" then
            quote = ch
            buf[#buf + 1] = ch
        elseif ch == "(" then
            depth = depth + 1
            buf[#buf + 1] = ch
        elseif ch == ")" then
            depth = depth - 1
            buf[#buf + 1] = ch
        elseif depth == 0 and string.find(ch, seps) then
            if #buf > 0 then
                ret[#ret + 1] = table.concat(buf)
            end
            buf = {}
        else
            buf[#buf + 1] = ch
        end
    end
    if #buf > 0 then
        ret[#ret + 1] = table.concat(buf)
    end
    return ret
end

-- Removes the quotes around a function argument.
---@param arg string
---@return string
local function unquote(arg)
    arg = string.gsub(arg, "^%s*(.-)%s*$", "%1")
    local unquoted = string.match(arg, [[^"(.*)"$]]) or string.match(arg, [[^'(.*)'$]])
    return unquoted or arg
end

local alignments = {
    left = "left",
    start = "left",
    right = "right",
    ["end"] = "right",
    center = "center",
    decimal = "decimal",
}

-- Parses the value of the tab-stops attribute, a comma separated list of
-- stops such as "10mm, 100% right leader('.'), 80mm decimal(',')".
---@param str string
---@return TabStop[]
function M.parse(str)
    local stops = {}
    for _, item in ipairs(split(str, "[,]")) do
        local tokens = split(item, "%s")
        local stop = { align = "left" }
        local position = tokens[1]
        local percent = string.match(position, "^(%d*%.?%d+)%%$")
        if percent then
            stop.percent = tonumber(percent)
        else
            local ok, sp = pcall(tex.sp, position)
            if not ok then
                main.log("error", "tab-stops: invalid position", "position", position)
                sp = 0
            end
            stop.pos = sp
        end
        for i = 2, #tokens do
            local tok = tokens[i]
            local name, arg = string.match(tok, "^(%a+)%((.*)%)$")
            name = name or tok
            if name == "leader" and arg then
                stop.leader = unquote(arg)
            elseif alignments[name] then
                stop.align = alignments[name]
                if name == "decimal" and arg then
                    stop.separator = utf8.codepoint(unquote(arg))
                end
            else
                main.log("error", "tab-stops: unknown value", "value", tok)
            end
        end
        if stop.align == "decimal" and not stop.separator then
            stop.separator = 46 -- "."
        end
        stops[#stops + 1] = stop
    end
    return stops
end

-- Returns the stops with their positions in sp for a paragraph that is
-- width wide, sorted by position.
---@param stops TabStop[]
---@param width integer
---@return TabStop[]
local function resolve(stops, width)
    local ret = {}
    for i, s in ipairs(stops) do
        local r = {}
        for k, v in pairs(s) do
            r[k] = v
        end
        if s.percent then
            r.pos = math.floor(width * s.percent / 100 + 0.5)
        end
        r.index = i
        ret[#ret + 1] = r
    end
    table.sort(ret, function(a, b)
        if a.pos == b.pos then
            return a.index < b.index
        end
        return a.pos < b.pos
    end)
    return ret
end

---@param n Node?
---@return boolean
local function is_tab(n)
    return n ~= nil and n.id == glue_node and node.has_attribute(n, publisher.att_tab) ~= nil
end

---@param n Node
---@return boolean
local function is_forced_break(n)
    return n.id == penalty_node and n.penalty <= -10000
end

-- Returns the end of the text after the tab: the next tab, forced break or
-- nil at the end of the list, and the natural width up to there.
---@param tab Node
---@return Node? stop
---@return integer width
local function run_after(tab)
    local first = tab.next
    local e = first
    while e and not is_tab(e) and not is_forced_break(e) do
        e = e.next
    end
    if not first or first == e then
        return e, 0
    end
    return e, (node.dimensions(first, e))
end

-- Returns the separator glyph of a decimal stop in the text from first up
-- to stop, or nil if there is none.
---@param first Node?
---@param stop Node?
---@param separator integer
---@return Node?
local function find_separator(first, stop, separator)
    local n = first
    while n and n ~= stop do
        if n.id == glyph_node and n.char == separator then
            return n
        end
        n = n.next
    end
    return nil
end

-- Returns how much of the text after the tab (from first up to stop, runw
-- wide) the stop puts before itself.
---@param s TabStop
---@param first Node?
---@param stop Node?
---@param runw integer
---@return integer
local function align_offset(s, first, stop, runw)
    if s.align == "right" then
        return runw
    elseif s.align == "center" then
        return runw // 2
    elseif s.align == "decimal" then
        local sep = find_separator(first, stop, s.separator)
        if sep and first and sep ~= first then
            return math.min((node.dimensions(first, sep)), runw)
        elseif sep then
            return 0
        end
        return runw
    end
    return 0
end

-- Returns where the tab at x ends and the stop it reaches, both measured
-- from the start of the line's content in a line with the given start
-- inset. The text after a right, center or decimal stop does not move the
-- tab below its own width. Nil when the stops have run out.
---@param stops TabStop[]
---@param inset integer
---@param x integer
---@param tab Node
---@return integer? target
---@return TabStop? stop
local function next_stop(stops, inset, x, tab)
    for _, s in ipairs(stops) do
        local pos = s.pos - inset
        if pos > x then
            if s.align == "left" then
                return pos, s
            end
            local stop, runw = run_after(tab)
            local off = align_offset(s, tab.next, stop, runw)
            return math.max(x + tab.width, pos - off), s
        end
    end
    return nil, nil
end

-- Sets the leader of the stop on the tab glue.
---@param tab Node
---@param s TabStop
local function set_leader(tab, s)
    if not s.leader or tab.leader then
        return
    end
    local fontfamily = node.has_attribute(tab, publisher.attribute_name_number["fontfamily"])
    local l = publisher.nodes.mknodes(s.leader, { fontfamily = fontfamily })
    publisher.fonts.pre_linebreak(l)
    tab.subtype = 100 -- aligned leaders
    tab.leader = node.hpack(l)
end

-- Removes the spaces next to each tab.
---@param head Node
---@return Node head
local function remove_spaces(head)
    local att_spaceglue = publisher.attribute_name_number["spaceglue"]
    ---@type Node?
    local n = head
    while n do
        local nxt = n.next
        if is_tab(n) then
            local p = n.prev
            while p and p.id == glue_node and node.has_attribute(p, att_spaceglue) do
                local pp = p.prev
                head = node.remove(head, p)
                node.free(p)
                p = pp
            end
            while nxt and nxt.id == glue_node and node.has_attribute(nxt, att_spaceglue) do
                local nn = nxt.next
                head = node.remove(head, nxt)
                node.free(nxt)
                nxt = nn
            end
        end
        n = nxt
    end
    return head
end

-- Keeps the text from first up to stop on one line: no break at its glue
-- and no hyphenation.
---@param first Node?
---@param stop Node?
local function keep_together(first, stop)
    local n = first
    while n and n ~= stop do
        if n.id == glue_node and n.prev and n.prev.id ~= penalty_node then
            local p = node.new(penalty_node)
            p.penalty = 10000
            node.insert_before(first, n, p)
        elseif n.id == glyph_node then
            n.left = 63
            n.right = 63
        end
        n = n.next
    end
end

-- Prepares the paragraph for the line breaker: each tab gets the width it
-- has when the paragraph is set without soft breaks, so that the line
-- breaker sees about the right line widths. The text after a right, center
-- or decimal stop is kept on one line if it fits there. inset(row) and
-- measure(row) are the start inset and the width of the row (counted from 1).
---@param head Node
---@param stops TabStop[]
---@param width integer Paragraph width, the base for percentages.
---@param inset fun(row: integer): integer
---@param measure fun(row: integer): integer
---@return Node head
function M.prepare(head, stops, width, inset, measure)
    head = remove_spaces(head)
    stops = resolve(stops, width)
    local row = 1
    local x = 0
    ---@type Node?
    local n = head
    while n do
        local nxt = n.next
        if is_forced_break(n) then
            row = row + 1
            x = 0
        elseif is_tab(n) then
            local target, s = next_stop(stops, inset(row), x, n)
            if target and s then
                n.width = target - x
                n.stretch, n.shrink = 0, 0
                set_leader(n, s)
                x = target
                local stop, runw = run_after(n)
                if s.align ~= "left" and target + runw <= measure(row) then
                    keep_together(n.next, stop)
                end
            else
                x = x + n.width
            end
        else
            x = x + (node.dimensions(n, nxt))
        end
        n = nxt
    end
    return head
end

-- Sets the tabs of one line and repacks it. Returns false if no tab on the
-- line reaches a stop.
---@param line Node hlist
---@param stops TabStop[]
---@param ragged boolean
---@return boolean
local function set_line(line, stops, ragged)
    local inset = line.shift or 0
    local x = 0
    local last, keep_end, aligned
    local n = line.head
    while n do
        if is_tab(n) then
            local target, s = next_stop(stops, inset, x, n)
            if target and s then
                n.width = target - x
                n.stretch, n.shrink = 0, 0
                set_leader(n, s)
                last = n
                keep_end, aligned = nil, false
                if s.align ~= "left" then
                    local stop = run_after(n)
                    keep_end, aligned = stop, true
                end
            end
        end
        x = x + (node.dimensions(n, n.next))
        n = n.next
    end
    if not last then
        return false
    end
    -- Text before the last stop keeps its natural width, and so does the
    -- text after a right, center or decimal stop.
    n = line.head
    while n and n ~= last do
        if n.id == glue_node then
            n.stretch, n.shrink = 0, 0
        end
        n = n.next
    end
    if aligned then
        n = last
        while n and n ~= keep_end do
            if n.id == glue_node and n.stretch_order == 0 then
                n.stretch, n.shrink = 0, 0
            end
            n = n.next
        end
    end
    if aligned or ragged then
        local fill = node.new(glue_node)
        fill.stretch = 2 ^ 16
        fill.stretch_order = 2
        node.insert_after(line.head, node.tail(line.head), fill)
    end
    local box = node.hpack(line.head, line.width, "exactly")
    line.glue_set, line.glue_sign, line.glue_order = box.glue_set, box.glue_sign, box.glue_order
    box.head = nil
    node.free(box)
    node.set_attribute(line, publisher.att_tab, 1)
    return true
end

-- Puts the tabs of the broken paragraph at their stops, line by line. The
-- stops are measured from the start edge of the paragraph, a line's shift
-- is its start inset. Lines with a tab stop are marked with att_tab and
-- always start at the start edge.
---@param vlist Node The broken paragraph.
---@param stops TabStop[]
---@param width integer Paragraph width, the base for percentages.
---@param ragged boolean
function M.set_lines(vlist, stops, width, ragged)
    stops = resolve(stops, width)
    ---@type Node?
    local line = vlist.head
    while line do
        if line.id == hlist_node then
            set_line(line, stops, ragged)
        end
        line = line.next
    end
end

file_end("publisher/tabstops.lua")

return M
