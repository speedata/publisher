local M = {
    private = {},
    funcs = {},
    dodebug = false,
    debugindent = "  ",
    fnNS = "http://www.w3.org/2005/xpath-functions",
    xsNS = "http://www.w3.org/2001/XMLSchema",
    stringmatch = string.match,
    stringfind = string.find,
    findfile = function(fn) return fn end,
    parse_xml = function(fn) return {} end, -- dummy
    ignoreNS = false,
}

local debuglevel = 0

local nan = 0 / 0

local function unread_rune(tbl)
    tbl.pos = tbl.pos - 1
end

---@return string
---@return boolean
local function read_rune(tbl)
    local r = tbl[tbl.pos]
    tbl.pos = tbl.pos + 1
    if tbl.pos > #tbl + 1 then return r, true end
    return r, false
end

local function is_letter(str)
    return M.stringmatch(str, "%w")
end

local function is_digit(str)
    return M.stringmatch(str, "[0-9]")
end

local function is_space(str)
    return M.stringmatch(str, "%s")
end

---@param runes table
---@return string
local function get_qname(runes)
    local word = {}
    local hasColon = false
    local r, eof
    while true do
        r, eof = read_rune(runes)
        if eof then break end
        if is_letter(r) or is_digit(r) or r == '_' or r == '-' or r == '·' or r == '‿' or r == '⁀' or r == '*' then
            word[#word + 1] = r
        elseif r == ":" then
            -- double colon must not be part of a qname
            if hasColon then
                unread_rune(runes)
                break
            end
            word[#word + 1] = r
            hasColon = true
        else
            unread_rune(runes)
            break
        end
    end
    local word_str = table.concat(word)
    return word_str
end
M.private.get_qname = get_qname

---@return string
local function get_delimited_string(tbl)
    local str = {}
    local eof = false
    local r
    local delim = read_rune(tbl)
    while true do
        r, eof = read_rune(tbl)
        if eof then break end
        if r == delim then
            break
        else
            str[#str + 1] = r
        end
    end
    return table.concat(str)
end

---@return string comment
local function get_comment(tbl)
    local level = 1
    local cur, after
    local eof
    local comment = {}
    while true do
        cur, eof = read_rune(tbl)
        if eof then break end
        after, eof = read_rune(tbl)
        if eof then break end
        if cur == ':' and after == ')' then
            level = level - 1
            if level == 0 then
                break
            end
        elseif cur == '(' and after == ':' then
            level = level + 1
        end
        comment[#comment + 1] = cur

        if after == ':' or after == '(' then
            unread_rune(tbl)
        else
            -- add after to comment
            comment[#comment + 1] = after
        end
    end
    return table.concat(comment)
end


---@return number?
local function get_num(runes)
    local tbl = {}
    local eof = false
    local r
    while true do
        r, eof = read_rune(runes)
        if eof then break end
        if '0' <= r and r <= '9' then
            tbl[#tbl + 1] = r
        elseif r == "." or r == "e" or r == "-" then
            tbl[#tbl + 1] = r
        else
            unread_rune(runes)
            break
        end
    end
    return tonumber(table.concat(tbl, ""))
end
M.private.get_num = get_num

---@return table
local function split_chars(str)
    local runes = {}
    for _, c in utf8.codes(str) do
        runes[#runes + 1] = utf8.char(c)
    end
    runes.pos = 1
    return runes
end
M.private.split_chars = split_chars

---@class token


---@class tokenlist
local tokenlist = {}


function tokenlist:new(o)
    o = o or {} -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    self.pos = 1
    self.attributeMode = false
    return o
end

---@param pos integer?
---@return token?
---@return boolean
function tokenlist:peek(pos)
    pos = pos or 1
    if self.pos + pos - 1 > #self then
        return nil, true
    end
    return self[self.pos + pos - 1], false
end

---@return token?
---@return string?
function tokenlist:read()
    if self.pos > #self then
        return nil, "eof"
    end
    self.pos = self.pos + 1
    return self[self.pos - 1], nil
end

---@return string?
function tokenlist:unread()
    if self.pos == 1 then
        return "eof"
    end
    self.pos = self.pos - 1
    return nil
end

---@return string?
function tokenlist:skipNCName(name)
    local tok, errmsg = self:read()
    if errmsg then
        return errmsg
    end
    if tok[2] ~= "tokQName" then
        return "QName expected, got " .. tok[2]
    end
    if tok[1] == name then return nil end
    return ""
end

---@param tokvalues table
---@return token?
---@return string?
function tokenlist:readNexttokIfIsOneOfValue(tokvalues, typ)
    if self.pos > #self then
        return nil, nil
    end
    for _, tokvalue in ipairs(tokvalues) do
        if self[self.pos][1] == tokvalue then
            if typ and self[self.pos][2] == typ then
                return self:read()
            elseif typ and self[self.pos][2] ~= typ then
                -- ignore
            else
                return self:read()
            end
        end
    end
    return nil, nil
end

function tokenlist:nextTokIsType(typ)
    if self.pos > #self then return false end
    local t = self:peek()
    -- tokQName main contain '*', which is incorrect.
    if typ == "tokQName" then
        if string.find(t[1],'*',1,true) then
            return false
        end
    end
    return t[2] == typ
end

---@return boolean true if the next token is the provided type.
function tokenlist:skipType(typ)
    if self.pos > #self then return false end
    local t = self:peek()
    if t[2] == typ then
        self:read()
        return true
    end
end

---@param str string
---@return tokenlist?
---@return string?
function M.string_to_tokenlist(str)
    if str == nil then return {} end
    local tokens = tokenlist:new()
    local nextrune
    local eof
    local runes = split_chars(str)
    while true do
        local r
        r, eof = read_rune(runes)
        if eof then break end
        if '0' <= r and r <= '9' then
            unread_rune(runes)
            local num
            num = get_num(runes)
            if num then
                tokens[#tokens + 1] = { num, "tokNumber" }
            end
        elseif r == '.' then
            nextrune, eof = read_rune(runes)
            if eof then
                tokens[#tokens + 1] = { '.', "tokOperator" }
                break
            end
            if nextrune == "." then
                tokens[#tokens + 1] = { '..', "tokOperator" }
            elseif '0' <= nextrune and nextrune <= '9' then
                unread_rune(runes)
                unread_rune(runes)
                local num
                num = get_num(runes)
                tokens[#tokens + 1] = { num, "tokNumber" }
            else
                unread_rune(runes)
                tokens[#tokens + 1] = { '.', "tokOperator" }
            end
        elseif r == '*' then
            nextrune, eof = read_rune(runes)
            if eof then
                tokens[#tokens + 1] = { r, "tokOperator" }
                break
            end
            unread_rune(runes)
            if nextrune == ':' then
                local word = '*' .. get_qname(runes)
                tokens[#tokens + 1] = { word, "tokQName" }
            else
                tokens[#tokens + 1] = { r, "tokOperator" }
            end
        elseif r == '+' or r == '-' or r == '?' or r == '@' or r == '|' or r == '=' then
            tokens[#tokens + 1] = { r, "tokOperator" }
        elseif r == "," then
            tokens[#tokens + 1] = { r, "tokComma" }
        elseif r == '>' or r == '<' then
            nextrune, eof = read_rune(runes)
            if eof then break end
            if nextrune == '=' or nextrune == r then
                tokens[#tokens + 1] = { r .. nextrune, "tokOperator" }
            else
                tokens[#tokens + 1] = { r, "tokOperator" }
                unread_rune(runes)
            end
        elseif r == '!' then
            nextrune, eof = read_rune(runes)
            if eof then break end
            if nextrune == '=' then
                tokens[#tokens + 1] = { "!=", "tokOperator" }
            else
                return nil, string.format("= expected after !, got %s", nextrune)
            end
        elseif r == '/' or r == ':' then
            nextrune, eof = read_rune(runes)
            if eof then
                tokens[#tokens + 1] = { r, "tokOperator" }
                break
            end
            if nextrune == r then
                tokens[#tokens + 1] = { r .. r, "tokOperator" }
            else
                tokens[#tokens + 1] = { r, "tokOperator" }
                unread_rune(runes)
            end
        elseif r == '[' then
            tokens[#tokens + 1] = { r, "tokOpenBracket" }
        elseif r == ']' then
            tokens[#tokens + 1] = { r, "tokCloseBracket" }
        elseif r == '$' then
            local name
            name = get_qname(runes)
            tokens[#tokens + 1] = { name, "tokVarname" }
        elseif is_space(r) then
            -- ignore whitespace
        elseif is_letter(r) then
            unread_rune(runes)
            local name
            name = get_qname(runes)
            nextrune, eof = read_rune(runes)
            if eof then
                tokens[#tokens + 1] = { name, "tokQName" }
                break
            end
            if nextrune == ':' then
                tokens[#tokens + 1] = { string.sub(name, 1, -2), "tokDoubleColon" }
            else
                unread_rune(runes)
                tokens[#tokens + 1] = { name, "tokQName" }
            end
        elseif r == '"' or r == "'" then
            unread_rune(runes)
            str = get_delimited_string(runes)
            tokens[#tokens + 1] = { str, "tokString" }
        elseif r == '(' then
            nextrune, eof = read_rune(runes)
            if eof then
                return tokens, "parse error, unbalanced ( at end"
            end
            if nextrune == ':' then
                get_comment(runes)
            else
                unread_rune(runes)
                tokens[#tokens + 1] = { "(", "tokOpenParen" }
            end
        elseif r == ')' then
            tokens[#tokens + 1] = { ")", "tokCloseParen" }
        else
            return nil, string.format("Invalid char for xpath expression %q", r)
        end
    end
    return tokens
end

--------------------------
local function is_element(itm)
    return type(itm) == "table" and itm[".__type"] == "element"
end

local function is_document(itm)
    return type(itm) == "table" and itm[".__type"] == "document"
end

local function is_attribute(itm)
    return type(itm) == "table" and itm[".__type"] == "attribute"
end

M.is_element = is_element
M.is_attribute = is_attribute

local string_value
local function number_value(sequence)
    if type(sequence) == "string" then return tonumber(sequence) end

    if is_attribute(sequence) then
        return tonumber(sequence.value)
    end

    if type(sequence) == "number" then
        return sequence
    end

    -- NEW: pass through single numeric item in a sequence
    if type(sequence) == "table" and #sequence == 1 and type(sequence[1]) == "number" then
        return sequence[1]
    end

    if not sequence then
        return nil, "empty sequence"
    end
    if #sequence == 0 then
        return nil, "empty sequence"
    end
    if #sequence > 1 then
        return nil, "number value, # must be 1"
    end

    if is_attribute(sequence[1]) then
        return tonumber(sequence[1].value)
    end
    return tonumber(string_value(sequence)), nil
end

local function boolean_value(seq)
    if type(seq) == "boolean" then
        return seq
    end
    if #seq == 0 then return false, nil end
    local val = seq[1]
    local ok = false
    if type(val) == "string" then
        ok = (val ~= "")
    elseif type(val) == "number" then
        ok = (val ~= 0 and val == val)
    elseif type(val) == "boolean" then
        ok = val
    elseif is_element(val) then
        return true
    elseif is_attribute(val) then
        return true
    end
    return ok, nil
end

function string_value(seq)
    local ret = {}
    if type(seq) == "string" then return seq end
    if is_attribute(seq) then return seq.value end
    for _, itm in ipairs(seq) do
        if tonumber(itm) and itm ~= itm then
            ret[#ret + 1] = 'NaN'
        elseif is_element(itm) then
            for _, cld in ipairs(itm) do
                ret[#ret + 1] = string_value(cld)
            end
        elseif is_attribute(itm) then
            ret[#ret + 1] = itm.value
        elseif type(itm) == "table" then
            ret[#ret + 1] = string_value(itm)
        else
            ret[#ret + 1] = tostring(itm)
        end
    end
    return table.concat(ret)
end

M.string_value = string_value
M.boolean_value = boolean_value
M.number_value = number_value


local function docomparestring(op, left, right)
    if op == "=" then
        return left == right, nil
    elseif op == "!=" then
        return left ~= right, nil
    elseif op == "<" then
        return left < right, nil
    elseif op == ">" then
        return left > right, nil
    elseif op == "<=" then
        return left <= right, nil
    elseif op == ">=" then
        return left >= right, nil
    else
        return nil, "not implemented: op " .. op
    end
end


local function docomparenumber(op, left, right)
    if op == "=" then
        return left == right, nil
    elseif op == "!=" then
        return left ~= right, nil
    elseif op == "<" then
        return left < right, nil
    elseif op == ">" then
        return left > right, nil
    elseif op == "<=" then
        return left <= right, nil
    elseif op == ">=" then
        return left >= right, nil
    else
        return nil, "not implemented: number comparison op " .. op
    end
end

local function docomparefunc(op, leftitem, rightitem)
    if is_attribute(leftitem) then leftitem = leftitem.value end
    if is_attribute(rightitem) then rightitem = rightitem.value end


    if type(leftitem) == "boolean" or type(rightitem) == "boolean" then
        local x, errmsg = docomparestring(op, string_value({ leftitem }), string_value({ rightitem }))
        return x, errmsg
    elseif type(number_value(leftitem)) == "number" and type(number_value(rightitem)) == "number" then
        local x, errmsg = docomparenumber(op, number_value(leftitem), number_value(rightitem))
        return x, errmsg
    elseif type(leftitem) == "string" or type(rightitem) == "string" then
        local x, errmsg = docomparestring(op, string_value({ leftitem }), string_value({ rightitem }))
        return x, errmsg
    else
        assert(false, "nyi")
    end
end

local function docompare(op, lhs, rhs)
    local evaler = function(ctx)
        local left, right, errmsg, ok
        left, errmsg = lhs(ctx)
        if errmsg ~= nil then return nil, errmsg end
        right, errmsg = rhs(ctx)
        if errmsg ~= nil then return nil, errmsg end
        for _, leftitem in ipairs(left) do
            for _, rightitem in ipairs(right) do
                ok, errmsg = docomparefunc(op, leftitem, rightitem)
                if errmsg ~= nil then return nil, errmsg end
                if ok then return { true }, nil end
            end
        end

        return { false }, nil
    end
    return evaler, nil
end

local function patternescape(s)
    return (s:gsub('%%', '%%%%')
        :gsub('^%^', '%%^')
        :gsub('%$$', '%%$')
        :gsub('%(', '%%(')
        :gsub('%)', '%%)')
        :gsub('%.', '%%.')
        :gsub('%[', '%%[')
        :gsub('%]', '%%]')
        :gsub('%*', '%%*')
        :gsub('%+', '%%+')
        :gsub('%-', '%%-')
        :gsub('%?', '%%?'))
end



local function fnAbs(cts, seq)
    local firstarg = seq[1]
    local n, errmsg = number_value(firstarg)
    if not n or errmsg then return nil, errmsg end
    return { math.abs(n) }, nil
end

local function fnBoolean(cts, seq)
    local firstarg = seq[1]
    local tf, errmsg = boolean_value(firstarg)
    if tf == nil or errmsg then return nil, errmsg end
    return { tf }, nil
end

local function fnCeiling(cts, seq)
    local n, errmsg = number_value(seq[1])
    if errmsg then return errmsg end
    if n == nil then return { nan }, nil end
    return { math.ceil(n) }, nil
end

local function fnConcat(ctx, seq)
    local ret = {}
    for _, itm in ipairs(seq) do
        ret[#ret + 1] = string_value(itm)
    end
    return { table.concat(ret) }
end

local function fnCodepointsToString(ctx, seq)
    local firstarg = seq[1]
    local ret = {}
    for _, itm in ipairs(firstarg) do
        local n, errmsg = number_value(itm)
        if errmsg then
            return nil, errmsg
        end
        ret[#ret + 1] = utf8.char(n)
    end

    return { table.concat(ret) }, nil
end

local function fnContains(ctx, seq)
    local firstarg = string_value(seq[1])
    local secondarg = string_value(seq[2])
    local x = string.find(firstarg, secondarg, 1, true)
    return { x ~= nil }, nil
end

local function fnCount(ctx, seq)
    local firstarg = seq[1]
    if not firstarg then return { 0 }, nil end
    return { #firstarg }, nil
end

local function fnDoc(ctx, seq)
    local firstarg = string_value(seq[1])
    local fn = M.findfile(firstarg)
    local xmltab = M.parse_xml(fn)
    ctx.sequence = xmltab[1]
    return {ctx.sequence}, nil
end

local function fnEmpty(ctx, seq)
    return { #seq[1] == 0 }, nil
end

local function fnEndsWith(ctx, seq)
    local firstarg = string_value(seq[1])
    local secondarg = string_value(seq[2])
    secondarg = patternescape(secondarg)
    local m = M.stringmatch(firstarg, secondarg .. "$")
    return { m ~= nil }, nil
end

local function fnFalse(ctx, seq)
    return { false }, nil
end

local function fnFloor(ctx, seq)
    local n, errmsg = number_value(seq[1])
    if errmsg then return errmsg end
    if n == nil then return { nan }, nil end
    return { math.floor(n) }, nil
end

-- Implementation of XPath 2.0 fn:format-number($value, $picture)
-- Supports:
--   - Digit placeholders: '0' (mandatory), '#' (optional)
--   - Decimal separator '.'
--   - Grouping separator ',' (primary grouping only, e.g. ###,##0)
--   - Percent '%' (×100) and per-mille '‰' (×1000)
--   - Positive/negative sub-patterns (separated by ';')
--   - NaN and Infinity cases
-- Implementation of XPath-like fn:format-number($value, $picture)
-- Adjusted to your desired behavior:
--  - Half-to-even rounding (banker's rounding)
--  - If a fractional pattern exists at all, ensure at least one digit (e.g. '#.##' -> '12.0')
--  - Percent/permille scaling but keep their symbols as literals in output
--  - Negative subpattern formats the absolute value (no extra '-')
-- XPath 2.0 style fn:format-number($value, $picture)
local function fnFormatNumber(ctx, seq)
    --------------------------------------------------------------------------
    -- Helpers
    --------------------------------------------------------------------------
    local function is_infinite(x)
        return x == math.huge or x == -math.huge
    end

    local function split_once(s, sep)
        local a, b = string.find(s, sep, 1, true)
        if not a then return s, nil end
        return string.sub(s, 1, a - 1), string.sub(s, b + 1)
    end

    --------------------------------------------------------------------------
    -- Extract arguments
    --------------------------------------------------------------------------
    local n, errmsg = M.number_value(seq[1])
    if errmsg and errmsg ~= "empty sequence" then
        return nil, errmsg
    end
    local picture = M.string_value(seq[2])

    if n == nil then return { "NaN" }, nil end
    if n ~= n then return { "NaN" }, nil end
    if is_infinite(n) then
        return { (n < 0 and "-Infinity" or "Infinity") }, nil
    end

    local posPattern, negPattern = split_once(picture, ";")
    posPattern = posPattern or picture

    --------------------------------------------------------------------------
    -- Parse a picture
    --------------------------------------------------------------------------
    local function parse_pattern(pat)
        local scale = 1
        if pat:find("%", 1, true) then scale = 100 end
        if pat:find("‰", 1, true) then scale = 1000 end

        -- find first/last digit
        local firstIdx, lastIdx
        for i = 1, #pat do
            local c = pat:sub(i,i)
            if c == '0' or c == '#' then firstIdx = i; break end
        end
        for i = #pat, 1, -1 do
            local c = pat:sub(i,i)
            if c == '0' or c == '#' then lastIdx = i; break end
        end
        if not firstIdx then
            return {
                prefix=pat, suffix="", intPat="", fracPat="",
                minInt=0, minFrac=0, maxFrac=0, groupSize=0, scale=scale
            }
        end

        local prefix = pat:sub(1, firstIdx-1)
        local core   = pat:sub(firstIdx, lastIdx)
        local suffix = pat:sub(lastIdx+1)

        -- detect decimal point (robust loop)
        local dotPos
        for i=1,#core do
            if core:sub(i,i) == "." then dotPos = i; break end
        end
        local intPat, fracPat = core, ""
        if dotPos then
            intPat  = core:sub(1, dotPos-1)
            fracPat = core:sub(dotPos+1)
        end

        -- grouping
        local lastCommaIdx
        for i = #intPat, 1, -1 do
            if intPat:sub(i,i) == "," then lastCommaIdx = i; break end
        end
        local groupSize = 0
        if lastCommaIdx then
            local tail = intPat:sub(lastCommaIdx+1):gsub("[^0#]","")
            groupSize = #tail
            if groupSize == 0 then groupSize = 3 end
        end

        -- count digits
        local minInt, minFrac, maxFrac = 0,0,0
        for i=1,#intPat do if intPat:sub(i,i) == '0' then minInt=minInt+1 end end
        for i=1,#fracPat do
            local c = fracPat:sub(i,i)
            if c=='0' then minFrac=minFrac+1; maxFrac=maxFrac+1
            elseif c=='#' then maxFrac=maxFrac+1 end
        end

        return {
            prefix=prefix, suffix=suffix,
            intPat=intPat, fracPat=fracPat,
            minInt=minInt, minFrac=minFrac, maxFrac=maxFrac,
            groupSize=groupSize, scale=scale
        }
    end

    --------------------------------------------------------------------------
    -- Grouping helper
    --------------------------------------------------------------------------
    local function apply_grouping(intStr, groupSize)
        if not groupSize or groupSize <= 0 then return intStr end
        local out, cnt = {}, 0
        for i = #intStr, 1, -1 do
            out[#out+1] = intStr:sub(i,i)
            cnt = cnt + 1
            if cnt == groupSize and i > 1 then
                out[#out+1] = ","
                cnt = 0
            end
        end
        local rev = {}
        for i = #out, 1, -1 do rev[#rev+1] = out[i] end
        return table.concat(rev)
    end

    --------------------------------------------------------------------------
    -- Format number with parsed pattern
    --------------------------------------------------------------------------
    local function format_with_pattern(value, P)
        local maxF = P.maxFrac or 0
        local rounded = round_half_even((value or 0) * (P.scale or 1), maxF)

        local sign = ""
        if rounded < 0 then sign = "-" end
        local absval = math.abs(rounded)

        local intPart = math.floor(absval + 0.0)
        local intStr  = tostring(intPart)
        if #intStr < (P.minInt or 0) then
            intStr = string.rep("0", (P.minInt or 0) - #intStr) .. intStr
        end
        intStr = apply_grouping(intStr, P.groupSize)

        local fracStr = ""
        if maxF > 0 then
            local m = 10^maxF
            local scaled = math.floor(absval * m + 1e-9)
            local fracScaled = scaled % m
            fracStr = string.format("%0"..maxF.."d", fracScaled)

            if maxF > (P.minFrac or 0) then
                local keep = math.max(P.minFrac or 0, 0)
                fracStr = fracStr:gsub("0+$", function(z)
                    local drop = math.min(#z, #fracStr - keep)
                    return string.rep("0", #z - drop)
                end)
            end

            -- Heuristic: ensure one digit only if pattern is pure optional fraction and no int '0'
            if fracStr == "" and (P.fracPat or "") ~= "" and (P.minFrac or 0)==0 and (P.minInt or 0)==0 then
                fracStr = "0"
            end
        end

        local dot = (#fracStr > 0) and "." or ""
        return sign .. P.prefix .. intStr .. dot .. fracStr .. P.suffix
    end

    --------------------------------------------------------------------------
    -- Choose pattern
    --------------------------------------------------------------------------
    if n < 0 then
        if negPattern and #negPattern > 0 then
            local Pneg = parse_pattern(negPattern)
            return { format_with_pattern(-n, Pneg) }, nil
        else
            local Ppos = parse_pattern(posPattern)
            local s = format_with_pattern(-math.abs(n), Ppos)
            return { "-" .. s }, nil
        end
    else
        local Ppos = parse_pattern(posPattern)
        return { format_with_pattern(n, Ppos) }, nil
    end
end


local function fnLast(ctx, seq)
    return { ctx.size }, nil
end

local function fnLocalName(ctx, seq)
    local input_seq = ctx.sequence
    if #seq == 1 then
        input_seq = seq[1]
    end
    -- first item
    seq = input_seq
    if #seq == 0 then
        return { "" }, nil
    end
    if #seq > 1 then
        return {}, "sequence too long"
    end
    -- first element
    seq = seq[1]

    if is_element(seq) then
        return { seq[".__local_name"] }, nil
    end

    return { "" }, nil
end

-- Not unicode aware!
local function fnLowerCase(ctx, seq)
    local firstarg = seq[1]
    local x = string_value(firstarg)
    return { string.lower(x) }, nil
end

local function fnName(ctx, seq)
    local input_seq = ctx.sequence
    if #seq == 1 then
        input_seq = seq[1]
    end
    -- first item
    seq = input_seq
    if #seq == 0 then
        return { "" }, nil
    end
    if #seq > 1 then
        return {}, "sequence too long"
    end
    -- first element
    seq = seq[1]

    if is_element(seq) then
        return { seq[".__name"] }, nil
    end

    return { "" }, nil
end

local function fnNamespaceURI(ctx, seq)
    local input_seq = ctx.sequence
    if #seq == 1 then
        input_seq = seq[1]
    end
    -- first item
    seq = input_seq
    if #seq == 0 then
        return { "" }, nil
    end
    if #seq > 1 then
        return {}, "sequence too long"
    end
    -- first element
    seq = seq[1]

    if is_element(seq) then
        return { seq[".__namespace"] }, nil
    end

    return { "" }, nil
end

local function fnMax(ctx, seq)
    local firstarg = seq[1]
    local x
    for _, itm in ipairs(firstarg) do
        if not x then
            x = number_value({ itm })
        else
            local y = number_value({ itm })
            if y > x then x = y end
        end
    end
    return { x }, nil
end

local function fnMatches(ctx, seq)
    local text = string_value(seq[1])
    local re = string_value(seq[2])
    if string.match(text, re) then
        return { true }, nil
    end
    return { false }, nil
end

local function fnMin(ctx, seq)
    local firstarg = seq[1]
    local x
    for _, itm in ipairs(firstarg) do
        if not x then
            x = number_value({ itm })
        else
            local y = number_value({ itm })
            if y < x then x = y end
        end
    end
    return { x }, nil
end

local function fnNormalizeSpace(ctx, seq)
    local firstarg = seq[1]
    local x = string_value(firstarg)
    x = x:gsub("^%s+", "")
    x = x:gsub("%s+$", "")
    x = x:gsub("%s+", " ")
    return { x }, nil
end

local function fnNot(ctx, seq)
    local firstarg = seq[1]
    local x, errmsg = boolean_value(firstarg)
    if errmsg then
        return {}, errmsg
    end
    return { not x }, nil
end

local function fnNumber(ctx, seq)
    local x = number_value(seq[1])
    if not x then return { nan }, nil end
    return { x }, nil
end

local function fnPosition(ctx, seq)
    return { ctx.pos }, nil
end


local function fnReverse(ctx, seq)
    local firstarg = seq[1]
    local ret = {}
    for i = #firstarg, 1, -1 do
        ret[#ret + 1] = firstarg[i]
    end
    return ret, nil
end

local function fnRoot(ctx, seq)
    if #seq ~= 0 then
        return nil, "not yet implmented: root(arg)"
    end
    if not ctx.xmldoc then
        return nil, "no root found"
    end
    if not ctx.xmldoc[1] then
        return nil, "no root found"
    end
    for i = 1, #ctx.xmldoc[1] do
        local tab = ctx.xmldoc[1][i]
        if is_element(tab) then
            ctx.sequence = { tab }
            return { tab }, nil
        end
    end
    return nil, "no root found"
end

local function fnRound(ctx, seq)
    local firstarg = seq[1]
    if #firstarg == 0 then
        return {}, nil
    end
    local n, errmsg = number_value(firstarg)
    if errmsg then
        return nil, errmsg
    end
    if not n then return { nan }, nil end
    return { math.floor(n + 0.5) }, nil
end

local function fnString(ctx, seq)
    local input_seq = ctx.sequence
    if #seq == 1 then
        input_seq = seq[1]
    end
    -- first item
    seq = input_seq
    local x = string_value(seq)
    return { x }, nil
end


function round_half_even(value, precision)
  if value == nil then
    return nil
  end
  precision = precision or 0
  local factor = 10 ^ precision
  local shifted = value * factor
  local floor_val = math.floor(shifted)
  local frac = shifted - floor_val

  if frac > 0.5 then
    return (floor_val + 1) / factor
  elseif frac < 0.5 then
    return floor_val / factor
  else
    -- genau auf der Hälfte → round half to even
    if floor_val % 2 == 0 then
      return floor_val / factor
    else
      return (floor_val + 1) / factor
    end
  end
end

local function fnRoundHalfToEven(ctx, seq)
    firstarg = number_value(seq[1])
    if not firstarg then return { nan }, nil end
    local secondarg = 0
    if #seq > 1 then
        secondarg = number_value(seq[2]) or 0
    end
    local res = round_half_even(firstarg, secondarg)
    return { res }, nil
end

local function fnStartsWith(ctx, seq)
    local firstarg = string_value(seq[1])
    local secondarg = string_value(seq[2])
    secondarg = patternescape(secondarg)
    local m = M.stringmatch(firstarg, "^" .. secondarg)
    return { m ~= nil }, nil
end

local function fnStringJoin(ctx, seq)
    local firstarg = seq[1]
    local secondarg = seq[2]
    if #secondarg ~= 1 then
        return nil, "string-join: second argument should be a string"
    end
    local tab = {}

    for _, itm in ipairs(firstarg) do
        local str = string_value(itm)
        tab[#tab + 1] = str
    end
    return { table.concat(tab, string_value(secondarg[1])) }, nil
end

local function fnStringLength(ctx, seq)
    local input_seq = ctx.sequence
    if #seq == 1 then
        input_seq = seq[1]
    end
    -- first item
    seq = input_seq
    local x = string_value(seq)
    return { utf8.len(x) }, nil
end

local function fnStringToCodepoints(ctx, seq)
    local str = string_value(seq[1])
    local ret = {}
    for _, c in utf8.codes(str) do
        ret[#ret + 1] = c
    end
    return ret, nil
end

local function fnSubstring(ctx, seq)
    local str = string_value(seq[1])
    local pos, errmsg = number_value(seq[2])
    if errmsg then
        return nil, errmsg
    end
    local len = #str
    if #seq > 2 then
        len = number_value(seq[3])
    end
    local ret = {}
    local l = 0
    for i, c in utf8.codes(str) do
        if i >= pos and l < len then
            ret[#ret + 1] = utf8.char(c)
            l = l + 1
        end
    end

    return { table.concat(ret) }, nil
end

local function fnSubstringAfter(ctx, seq)
    local firstarg = string_value(seq[1])
    local secondarg = string_value(seq[2])
    local a, b = M.stringfind(firstarg, secondarg, 1, true)
    if not a then return { "" }, nil end
    return { string.sub(firstarg, b + 1, -1) }
end


local function fnSubstringBefore(ctx, seq)
    local firstarg = string_value(seq[1])
    local secondarg = string_value(seq[2])
    local a = M.stringfind(firstarg, secondarg, 1, true)
    if not a then return { "" }, nil end
    return { string.sub(firstarg, 1, a - 1) }
end


local function fnTrue(ctx, seq)
    return { true }, nil
end

local function fnUnparsedText(ctx, seq)
    local firstarg = string_value(seq[1])
    local fn = M.findfile(firstarg)
    local rd,msg = io.open(fn,"r")
    if not rd then
        return nil, msg
    end
    local txt = rd:read("a")
    rd:close()
    return {txt},nil
end

-- Not unicode aware!
local function fnUpperCase(ctx, seq)
    local firstarg = seq[1]
    local x = string_value(firstarg)
    return { string.upper(x) }, nil
end

local funcs = {
    -- function name, namespace, function, minarg, maxarg
    { "abs",                  M.fnNS, fnAbs,                1, 1 },
    { "boolean",              M.fnNS, fnBoolean,            1, 1 },
    { "ceiling",              M.fnNS, fnCeiling,            1, 1 },
    { "codepoints-to-string", M.fnNS, fnCodepointsToString, 1, 1 },
    -- { "compare",              M.fnNS, fnCompare,             2, 2 },
    { "concat",               M.fnNS, fnConcat,             0, -1 },
    { "contains",             M.fnNS, fnContains,           2, 2 },
    { "count",                M.fnNS, fnCount,              1, 1 },
    { "doc",                  M.fnNS, fnDoc,                1, 1 },
    { "empty",                M.fnNS, fnEmpty,              1, 1 },
    { "false",                M.fnNS, fnFalse,              0, 0 },
    { "floor",                M.fnNS, fnFloor,              1, 1 },
    { "format-number",        M.fnNS, fnFormatNumber,       2, 2 },
    { "last",                 M.fnNS, fnLast,               0, 0 },
    { "local-name",           M.fnNS, fnLocalName,          0, 1 },
    { "lower-case",           M.fnNS, fnLowerCase,          1, 1 },
    { "namespace-uri",        M.fnNS, fnNamespaceURI,       0, 1 },
    { "max",                  M.fnNS, fnMax,                1, 1 },
    { "matches",              M.fnNS, fnMatches,            2, 3 },
    { "min",                  M.fnNS, fnMin,                1, 1 },
    { "name",                 M.fnNS, fnName,               0, 1 },
    { "normalize-space",      M.fnNS, fnNormalizeSpace,     1, 1 },
    { "not",                  M.fnNS, fnNot,                1, 1 },
    { "number",               M.fnNS, fnNumber,             1, 1 },
    { "position",             M.fnNS, fnPosition,           0, 0 },
    { "reverse",              M.fnNS, fnReverse,            1, 1 },
    { "root",                 M.fnNS, fnRoot,               0, 1 },
    { "round",                M.fnNS, fnRound,              1, 1 },
    { "round-half-to-even",   M.fnNS, fnRoundHalfToEven,    1, 2 },
    { "starts-with",          M.fnNS, fnStartsWith,         2, 2 },
    { "ends-with",            M.fnNS, fnEndsWith,           2, 2 },
    { "substring-after",      M.fnNS, fnSubstringAfter,     2, 2 },
    { "substring-before",     M.fnNS, fnSubstringBefore,    2, 2 },
    { "string-join",          M.fnNS, fnStringJoin,         2, 2 },
    { "string-length",        M.fnNS, fnStringLength,       0, 1 },
    { "string-to-codepoints", M.fnNS, fnStringToCodepoints, 1, 1 },
    { "string",               M.fnNS, fnString,             0, 1 },
    { "substring",            M.fnNS, fnSubstring,          2, 3 },
    { "true",                 M.fnNS, fnTrue,               0, 0 },
    { "unparsed-text",        M.fnNS, fnUnparsedText,       1, 1 },
    { "upper-case",           M.fnNS, fnUpperCase,          1, 1 },
}

local function registerFunction(func)
    M.funcs[func[2] .. " " .. func[1]] = func
end

for _, func in ipairs(funcs) do
    registerFunction(func)
end

M.registerFunction = registerFunction

local function getFunction(namespace, fname)
    return M.funcs[namespace .. " " .. fname]
end

local function callFunction(fname, seq, ctx)
    local fn = {}
    for str in string.gmatch(fname, "([^:]+)") do
        table.insert(fn, str)
    end
    local namespace = M.fnNS
    if #fn == 2 then
        namespace = ctx.namespaces[fn[1]]
        fname = fn[2]
    end
    local func = getFunction(namespace, fname)
    if not func then return {}, string.format("cannot find function with name %s",fname) end
    local minarg, maxarg = func[4], func[5]

    if #seq < minarg or (maxarg ~= -1 and #seq > maxarg) then
        if minarg == maxarg then
            return {}, string.format("function %s() requires %d arguments, %d supplied", table.concat(fn,':'), minarg, #seq)
        else
            return {}, string.format("function %s() requires %d to %d arguments, %d supplied", table.concat(fn,':'), minarg, maxarg,
                #seq)
        end
    end

    if func then
        return func[3](ctx, seq)
    end

    return {}, "Could not find function " .. fname .. " with name space " .. namespace
end


local function filter(ctx, f)
    local res = {}
    local errmsg, predicate
    local copysequence = ctx.sequence
    local positions
    local lengths
    if ctx.positions then
        positions = ctx.positions
        lengths = ctx.lengths
    else
        positions = {}
        lengths = {}
        for i = 1, #ctx.sequence do
            positions[#positions + 1] = i
            lengths[#lengths + 1] = 1
        end
    end
    for i, itm in ipairs(copysequence) do
        ctx.sequence = { itm }
        ctx.pos = positions[i]
        if #lengths >= i then
            ctx.size = lengths[i]
        else
            ctx.size = 1
        end
        predicate, errmsg = f(ctx)
        if errmsg then
            return nil, errmsg
        end
        if #predicate == 1 then
            local idx = tonumber(predicate[1])
            if idx then
                if idx > #copysequence then
                    ctx.sequence = {}
                    return {}, nil
                end
                if idx == i then
                    ctx.sequence = { itm }
                    return { itm }, nil
                end
            end
        end

        if boolean_value(predicate) then
            res[#res + 1] = itm
        end
    end
    ctx.size = #res
    ctx.sequence = res
    return res, nil
end


-------------------------

---@class context
---@field sequence table
---@field xmldoc table
---@field namespaces table
---@field vars table
local context = {}

function context:new(o)
    o = o or {} -- create object if user does not provide one
    o.vars = o.vars or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

---@return context
function context:copy()
    local newcontexttab = {
        xmldoc = self.xmldoc,
        sequence = self.sequence,
        vars = {},
        pos = self.pos,
        size = self.size,
        namespaces = self.namespaces,
    }
    for key, value in pairs(self.vars) do
        newcontexttab.vars[key] = value
    end
    local newcontext = context:new(newcontexttab)
    return newcontext
end

---@alias xmlelement table

---@return xmlelement?
---@return string? Error message
function context:root()
    for _, elt in ipairs(self.xmldoc) do
        if type(elt) == "table" then
            self.sequence = { elt }
            return elt, nil
        end
    end
    return nil, "no root element found"
end

function context:document()
    self.sequence = self.xmldoc
    self.pos = nil
    self.size = nil
    return self.sequence
end

function context:attributeaixs(testfunc)
    local seq = {}
    for _, itm in ipairs(self.sequence) do
        if is_element(itm) then
            for key, value in pairs(itm[".__attributes"]) do
                local x = {
                    name = key,
                    value = value,
                    [".__type"] = "attribute",
                }
                if testfunc(self,x) then
                    seq[#seq + 1] = x
                end
            end
        elseif is_attribute(itm) then
            if testfunc(self,itm) then
                seq[#seq + 1] = itm
            end
        end
    end
    self.sequence = seq
    return seq, nil
end

function context:childaxis(testfunc)
    local seq = {}
    for _, elt in ipairs(self.sequence) do
        if type(elt) == "table" then
            for _, child in ipairs(elt) do
                if is_element(child) then
                    child[".__parent"] = elt
                end
                if testfunc(self,child) then
                    seq[#seq + 1] = child
                end
            end
        end
    end
    self.sequence = seq
    return seq, nil
end

function context:descendant(testfunc)
    local seq = {}
    for _, elt in ipairs(self.sequence) do
        if type(elt) == "table" then
            if is_element(elt) or is_document(elt) then
                for i = 1, #elt do
                    local child = elt[i]
                    if is_element(child) then
                        child[".__parent"] = elt
                    end
                    if is_element(child) then
                        if testfunc(self,child) then
                            seq[#seq + 1] = child
                        end
                        local newself = self:copy()
                        newself.sequence = { child }
                        local s, errmsg = newself:descendant(testfunc)
                        if errmsg then return nil, errmsg end
                        if not s then return nil, "descendant is nil" end
                        for j = 1, #s do
                            seq[#seq + 1] = s[j]
                        end
                    else
                        if testfunc(self,child) then
                            seq[#seq + 1] = child
                        end
                    end
                end
            else
                assert(false)
            end
        elseif type(elt) == "string" then
            seq[#seq + 1] = elt
        else
            -- ignore
        end
    end
    self.sequence = seq
    return seq, nil
end

function context:following(testfunc)
    local seq   = {}
    local newself
    local ret, errmsg
    newself     = self:copy()
    ret, errmsg = newself:followingSibling(testfunc)
    if errmsg then return nil, errmsg end
    ret, errmsg = newself:descendantOrSelf(testfunc)
    if errmsg then return nil, errmsg end
    if not ret then return nil, "following: ret is empty" end
    for _, itm in ipairs(ret) do
        seq[#seq + 1] = itm
    end
    self.sequence = seq
    return seq, nil
end

function context:followingSibling(testfunc)
    local seq = {}
    for _, elt in ipairs(self.sequence) do
        if is_element(elt) then
            local curid = elt[".__id"]
            local parent = elt[".__parent"]
            local startCollecting = false
            for i = 1, #parent do
                local sibling = parent[i]
                if is_element(sibling) then
                    if sibling[".__id"] > curid then
                        startCollecting = true
                    end
                end
                if startCollecting and testfunc(self,sibling) then
                    seq[#seq + 1] = sibling
                end
            end
        end
    end
    self.sequence = seq
    return seq, nil
end

function context:descendantOrSelf(testfunc)
    local seq = {}
    for _, elt in ipairs(self.sequence) do
        if type(elt) == "table" then
            if is_element(elt) or is_document(elt) then
                if testfunc(self,elt) then
                    seq[#seq + 1] = elt
                end
                for i = 1, #elt do
                    local child = elt[i]
                    if is_element(child) then
                        local newself = self:copy()
                        newself.sequence = { child }
                        local s, errmsg = newself:descendantOrSelf(testfunc)
                        if errmsg then return nil, errmsg end
                        if not s then return nil, "descendantOrSelf is nil" end
                        for j = 1, #s do
                            seq[#seq + 1] = s[j]
                        end
                    else
                        if testfunc(self,child) then
                            seq[#seq + 1] = child
                        end
                    end
                end
            else
                assert(false)
            end
        elseif type(elt) == "string" then
            seq[#seq + 1] = elt
        else
            -- ignore
        end
    end
    self.sequence = seq
    return seq, nil
end

function context:parentAxis(testfunc)
    local seq = {}
    for _, elt in ipairs(self.sequence) do
        if is_element(elt) then
            local parent = elt[".__parent"]
            if testfunc(self,parent) then
                seq[#seq + 1] = parent
            end
        end
    end
    self.sequence = seq
    return seq, nil
end

function context:ancestorAxis(testfunc)
    local seq = {}
    for _, elt in ipairs(self.sequence) do
        if is_element(elt) then
            local parent = elt[".__parent"]
            if is_element(parent) then
                local newcontext = self:copy()
                newcontext.sequence = { parent }
                local ret, errmsg = newcontext:ancestorAxis(testfunc)
                if errmsg then return nil, errmsg end
                for _, itm in ipairs(ret) do
                    seq[#seq + 1] = itm
                end
            end
            if testfunc(self,parent) then
                seq[#seq + 1] = parent
            end
        end
    end
    self.sequence = seq
    return seq, nil
end

function context:ancestorOrSelfAxis(testfunc)
    local seq = {}
    for _, elt in ipairs(self.sequence) do
        if is_element(elt) then
            local parent = elt[".__parent"]
            if is_element(parent) then
                local newcontext = self:copy()
                newcontext.sequence = { parent }
                local ret, errmsg = newcontext:ancestorOrSelfAxis(testfunc)
                if errmsg then return nil, errmsg end
                for _, itm in ipairs(ret) do
                    seq[#seq + 1] = itm
                end
            end
        end
        if testfunc(self,elt) then
            seq[#seq + 1] = elt
        end
    end
    self.sequence = seq
    return seq, nil
end

function context:precedingSiblingAxis(testfunc)
    local seq = {}
    for _, elt in ipairs(self.sequence) do
        if is_element(elt) then
            local curid = elt[".__id"]
            local parent = elt[".__parent"]
            local startCollecting = true
            for i = 1, #parent do
                local sibling = parent[i]
                if is_element(sibling) then
                    if sibling[".__id"] >= curid then
                        startCollecting = false
                    end
                end
                if startCollecting and testfunc(self,sibling) then
                    seq[#seq + 1] = sibling
                end
            end
        end
    end
    self.sequence = seq
    return seq, nil
end

function context:precedingAxis(testfunc)
    local newself
    local ret, errmsg
    local seq   = {}
    newself     = self:copy()
    ret, errmsg = newself:precedingSiblingAxis(testfunc)
    if errmsg then return nil, errmsg end
    ret, errmsg = newself:descendantOrSelf(testfunc)
    if errmsg then return nil, errmsg end
    if not ret then return nil, "following: ret is empty" end
    for _, itm in ipairs(ret) do
        seq[#seq + 1] = itm
    end
    self.sequence = seq
    return seq, nil
end

M.context = context
-------------------------

---@param tl tokenlist
---@param step string
local function enterStep(tl, step)
    if M.dodebug then
        local token, _ = tl:peek()
        token = token or { "-", "-" }
        print(string.format("%s>%s: {%s,%s}", string.rep(M.debugindent, debuglevel), step, tostring(token[1]), token[2]))
        io.flush()
        debuglevel = debuglevel + 1
    end
end

---@param tl tokenlist
---@param step string
local function leaveStep(tl, step)
    if M.dodebug then
        local token, _ = tl:peek()
        token = token or { "-", "-" }
        debuglevel = debuglevel - 1
        print(string.format("%s<%s: {%s,%s}", string.rep(M.debugindent, debuglevel), step, tostring(token[1]), token[2]))
        io.flush()
    end
end

---------------------------

local parse_expr, parse_expr_single, parse_or_expr, parse_and_expr, parse_comparison_expr, parse_range_expr, parse_additive_expr, parse_multiplicative_expr

---@type table sequence


---@alias evalfunc function(context) sequence?, string?
---@alias testfunc function(context) boolean?, string?

---@param tl tokenlist
---@return evalfunc?
---@return string? error
-- [2] Expr ::= ExprSingle ("," ExprSingle)*
function parse_expr(tl)
    enterStep(tl, "2 parseExpr")
    local efs = {}
    while true do
        local ef, errmsg = parse_expr_single(tl)
        if errmsg ~= nil then
            leaveStep(tl, "2 parseExpr")
            return nil, errmsg
        end
        efs[#efs + 1] = ef
        if not tl:nextTokIsType("tokComma") then
            break
        end
        tl:read()
    end
    if #efs == 1 then
        leaveStep(tl, "2 parseExpr")
        return efs[1], nil
    end
    local evaler = function(ctx)
        local newcontext = ctx:copy()
        local copysequence = newcontext.sequence
        local ret = {}
        local seq
        local errmsg
        for i, ef in ipairs(efs) do
            newcontext.sequence = copysequence
            seq, errmsg = ef(newcontext)
            if errmsg then
                return nil, errmsg
            end
            for _, itm in ipairs(seq) do
                ret[#ret + 1] = itm
            end
        end
        newcontext.sequence = copysequence
        return ret, nil
    end

    leaveStep(tl, "2 parseExpr")
    return evaler, nil
end

-- [3] ExprSingle ::= ForExpr | QuantifiedExpr | IfExpr | OrExpr
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_expr_single(tl)
    enterStep(tl, "3 parse_expr_single")
    local tok, errmsg
    tok = tl:peek()
    if tok and tok[2] == "tokQName" and (tok[1] == "for" or tok[1] == "some" or tok[1] == "every" or tok[1] == "if") then
        local ef
        if tok[1] == "for" then
            tl:read()
            ef, errmsg = parse_for_expr(tl)
        elseif tok[1] == "some" or tok[1] == "every" then
            ef, errmsg = parse_quantified_expr(tl)
        elseif tok[1] == "if" then
            tl:read()
            ef, errmsg = parse_if_expr(tl)
        else
            return nil, "nil"
        end
        return ef, errmsg
    end
    local ef
    ef, errmsg = parse_or_expr(tl)
    if errmsg ~= nil then
        leaveStep(tl, "3 parse_expr_single")
        return nil, errmsg
    end
    leaveStep(tl, "3 parse_expr_single")
    return ef, nil
end

-- [4] ForExpr ::= SimpleForClause "return" ExprSingle
-- [5] SimpleForClause ::= "for" "$" VarName "in" ExprSingle ("," "$" VarName "in" ExprSingle)*
function parse_for_expr(tl)
    enterStep(tl, "4 parse_for_expr")

    local vartoken, errmsg = tl:read()
    if errmsg then
        leaveStep(tl, "4 parse_for_expr")
        return nil, errmsg
    end
    if vartoken[2] ~= "tokVarname" then
        leaveStep(tl, "4 parse_for_expr")
        return nil, "variable name expected"
    end

    local varname = vartoken[1]
    errmsg = tl:skipNCName("in")
    if errmsg then
        leaveStep(tl, "4 parse_for_expr")
        return nil, errmsg
    end

    local sfc
    sfc, errmsg = parse_expr_single(tl)

    errmsg = tl:skipNCName("return")
    if errmsg then
        leaveStep(tl, "4 parse_for_expr")
        return nil, errmsg
    end
    local ef
    ef, errmsg = parse_expr_single(tl)
    if errmsg then
        leaveStep(tl, "4 parse_for_expr")
        return errmsg
    end

    local evaler = function(ctx)
        local ret = {}
        local seqfc, errmsg
        seqfc, errmsg = sfc(ctx)
        if errmsg then return errmsg end
        for _, itm in ipairs(seqfc) do
            ctx.vars[varname] = { itm }
            ctx.context = { itm }
            local seq
            seq, errmsg = ef(ctx)
            if errmsg then return nil, errmsg end
            for i = 1, #seq do
                ret[#ret + 1] = seq[i]
            end
        end
        return ret, nil
    end
    leaveStep(tl, "4 parse_for_expr")
    return evaler, nil
end

-- [6] QuantifiedExpr ::= ("some" | "every") "$" VarName "in" ExprSingle ("," "$" VarName "in" ExprSingle)* "satisfies" ExprSingle
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_quantified_expr(tl)
    enterStep(tl, "6 parse_quantified_expr")
    local efs, varnames = {}, {}
    local ef, errmsg
    local someEveryTok = tl:read()
    if not someEveryTok then
        return nil, "some or every expected"
    end
    local someEvery = someEveryTok[1]
    while true do
        local vartok, errmsg = tl:read()
        if errmsg then
            leaveStep(tl, "6 parse_quantified_expr")
            return nil, errmsg
        end
        if not vartok then
            leaveStep(tl, "6 parse_quantified_expr")
            return nil, "could not read variable name"
        end
        if vartok[2] ~= "tokVarname" then
            leaveStep(tl, "6 parse_quantified_expr")
            return nil, "variable expected"
        end
        local varname = vartok[1]
        local intok = tl:readNexttokIfIsOneOfValue({ "in" }, "tokQName")
        if not intok then
            leaveStep(tl, "6 parse_quantified_expr")
            return nil, "\"in\" expected"
        end
        ef, errmsg = parse_expr_single(tl)
        if errmsg then
            leaveStep(tl, "6 parse_quantified_expr")
            return nil, errmsg
        end
        efs[#efs + 1] = ef
        varnames[#varnames + 1] = varname
        local comma = tl:readNexttokIfIsOneOfValue({ "," }, "tokComma")
        if not comma then break end
    end
    local intok = tl:readNexttokIfIsOneOfValue({ "satisfies" }, "tokQName")
    if not intok then
        leaveStep(tl, "6 parse_quantified_expr")
        return nil, "\"satisfies\" expected"
    end
    local singleef
    singleef, errmsg = parse_expr_single(tl)
    if errmsg then
        leaveStep(tl, "6 parse_quantified_expr")
        return nil, errmsg
    end

    local evaler = function(ctx)
        local newcontext = ctx:copy()
        local copysequence = newcontext.sequence
        local sequences = {}
        local seq, errmsg
        for i = 1, #efs do
            local ef = efs[i]
            newcontext.sequence = copysequence
            seq, errmsg = ef(newcontext)
            if errmsg then return nil, errmsg end
            sequences[i] = seq
        end
        newcontext.sequence = copysequence
        if singleef == nil then return nil, "single ef == nil" end

        local func
        func = function(vars, seq, ef)
            if #vars > 0 then
                local varname = table.remove(vars, 1)
                local sequence = table.remove(seq, 1)

                for i = 1, #sequence do
                    local nvars = {}
                    local nseq = {}
                    for i = 1, #vars do
                        nvars[#nvars + 1] = vars[i]
                        nseq[#nseq + 1] = seq[i]
                    end
                    newcontext.vars[varname] = { sequence[i] }
                    local x = func(nvars, nseq, ef)
                    if x then
                        if someEvery == "some" then
                            if boolean_value(x) then
                                return { true }
                            end
                        else
                            if not boolean_value(x) then
                                return { false }
                            end
                        end
                    end
                end
            else
                local x, y = ef(newcontext)
                return x, y
            end
            if "some" then
                return { false }
            else
                return { true }
            end
        end

        local z = func(varnames, sequences, singleef)
        return z, nil
    end
    leaveStep(tl, "6 parse_quantified_expr")
    return evaler, nil
end

-- [7] IfExpr ::= "if" "(" Expr ")" "then" ExprSingle "else" ExprSingle
function parse_if_expr(tl)
    enterStep(tl, "7 parse_if_expr")
    -- var nexttok *token
    -- var err error
    -- var boolEval, thenpart, elsepart EvalFunc
    local nexttok, errmsg
    nexttok, errmsg = tl:read()
    if errmsg then
        leaveStep(tl, "7 parse_if_expr")
        return nil, errmsg
    end
    if nexttok[2] ~= "tokOpenParen" then
        return nil, string.format("open parenthesis expected, found %s", tostring(nexttok[1]))
    end
    local boolEval, thenpart, elsepart
    boolEval, errmsg = parse_expr(tl)
    if errmsg then
        leaveStep(tl, "7 parse_if_expr")
        return nil, errmsg
    end
    ok = tl:skipType("tokCloseParen")
    if not ok then
        leaveStep(tl, "7 parse_if_expr")
        return nil, ") expected"
    end
    errmsg = tl:skipNCName("then")
    if errmsg then
        leaveStep(tl, "7 parse_if_expr")
        return nil, errmsg
    end
    thenpart, errmsg = parse_expr_single(tl)
    if errmsg then
        leaveStep(tl, "7 parse_if_expr")
        return nil, errmsg
    end

    tl:skipNCName("else")
    elsepart, errmsg = parse_expr_single(tl)
    if errmsg then
        leaveStep(tl, "7 parse_if_expr")
        return nil, errmsg
    end
    ef = function(ctx)
        local res, bv, errmsg
        res, errmsg = boolEval(ctx)
        if errmsg then return nil, errmsg end
        bv, errmsg = boolean_value(res)
        if errmsg then return nil, errmsg end
        if bv then
            return thenpart(ctx)
        end
        return elsepart(ctx)
    end
    leaveStep(tl, "7 parse_if_expr")
    return ef, nil
end

-- [8] OrExpr ::= AndExpr ( "or" AndExpr )*
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_or_expr(tl)
    enterStep(tl, "8 parse_or_expr")
    local errmsg
    local efs = {}
    while true do
        efs[#efs + 1], errmsg = parse_and_expr(tl)
        if errmsg ~= nil then
            leaveStep(tl, "8 parse_or_expr")
            return nil, errmsg
        end
        if not tl:readNexttokIfIsOneOfValue({ "or" }) then
            break
        end
    end
    if #efs == 1 then
        leaveStep(tl, "8 parse_or_expr")
        return efs[1], nil
    end

    local evaler = function(ctx)
        local seq, errmsg
        for _, ef in ipairs(efs) do
            local newcontext = ctx:copy()
            seq, errmsg = ef(newcontext)
            if errmsg ~= nil then
                return nil, errmsg
            end
            local bv
            bv, errmsg = boolean_value(seq)
            if errmsg ~= nil then
                return nil, errmsg
            end
            if bv then return { true }, nil end
        end
        return { false }, nil
    end
    leaveStep(tl, "8 parse_or_expr")
    return evaler, nil
end

-- [9] AndExpr ::= ComparisonExpr ( "and" ComparisonExpr )*
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_and_expr(tl)
    enterStep(tl, "9 parse_and_expr")
    local efs = {}
    while true do
        tl.attributeMode = false
        local ef, errmsg = parse_comparison_expr(tl)
        if errmsg then
            leaveStep(tl, "8 parse_or_expr")
            return nil, errmsg
        end
        if ef then
            efs[#efs + 1] = ef
        end
        if not tl:readNexttokIfIsOneOfValue({ "and" }) then
            break
        end
    end

    if #efs == 1 then
        leaveStep(tl, "9 parse_and_expr (#efs == 1)")
        return efs[1], nil
    end
    local evaler = function(ctx)
        local ef, msg, ok, seq
        for i = 1, #efs do
            ef = efs[i]
            local newcontext = ctx:copy()
            seq, msg = ef(newcontext)
            if msg then return nil, msg end
            ok, msg = boolean_value(seq)
            if msg then return nil, msg end
            if not ok then return { false }, nil end
        end
        return { true }, nil
    end

    leaveStep(tl, "9 parse_and_expr")
    return evaler, nil
end

-- [10] ComparisonExpr ::= RangeExpr ( (ValueComp | GeneralComp| NodeComp) RangeExpr )?
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_comparison_expr(tl)
    enterStep(tl, "10 parse_comparison_expr")
    local lhs, errmsg = parse_range_expr(tl)
    if errmsg ~= nil then
        leaveStep(tl, "10 parse_comparison_expr")
        return nil, errmsg
    end
    local op
    op, errmsg = tl:readNexttokIfIsOneOfValue({ "=", "<", ">", "<=", ">=", "!=", "eq", "ne", "lt", "le", "gt", "ge",
        "is",
        "<<", ">>" })
    if errmsg ~= nil then
        leaveStep(tl, "10 parse_comparison_expr")
        return nil, errmsg
    end
    if not op then
        leaveStep(tl, "10 parse_comparison_expr")
        return lhs, nil
    end

    local rhs
    rhs, errmsg = parse_range_expr(tl)
    if errmsg ~= nil then
        leaveStep(tl, "10 parse_comparison_expr")
        return nil, errmsg
    end

    leaveStep(tl, "10 parse_comparison_expr")
    return docompare(op[1], lhs, rhs)
end

-- [11] RangeExpr  ::=  AdditiveExpr ( "to" AdditiveExpr )?
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_range_expr(tl)
    enterStep(tl, "11 parse_range_expr")
    local efs = {}
    local ef, errmsg = parse_additive_expr(tl)
    if errmsg ~= nil then
        leaveStep(tl, "11 parse_range_expr")
        return nil, errmsg
    end
    efs[#efs + 1] = ef
    if tl:nextTokIsType("tokQName") then
        if tl:readNexttokIfIsOneOfValue({ "to" }) then
            ef, errmsg = parse_additive_expr(tl)
            if errmsg ~= nil then
                leaveStep(tl, "11 parse_range_expr")
                return nil, errmsg
            end
            efs[#efs + 1] = ef
        end
    end
    if #efs == 1 then
        leaveStep(tl, "11 parse_range_expr")
        return efs[1], nil
    end

    local evaler = function(ctx)
        local lhs, rhs, msg
        lhs, msg = efs[1](ctx)
        if msg then return nil, msg end
        rhs, msg = efs[2](ctx)
        if msg then return nil, msg end
        local lhsn, rhsn
        lhsn, msg = number_value(lhs)
        if msg then return nil, msg end
        rhsn, msg = number_value(rhs)
        if msg then return nil, msg end
        local seq = {}
        for i = lhsn, rhsn do
            seq[#seq + 1] = i
        end
        return seq, nil
    end
    leaveStep(tl, "11 parse_range_expr")
    return evaler, nil
end

-- [12] AdditiveExpr ::= MultiplicativeExpr ( ("+" | "-") MultiplicativeExpr )*
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_additive_expr(tl)
    enterStep(tl, "12 parse_additive_expr")
    local efs = {}
    local operators = {}
    while true do
        local ef, errmsg = parse_multiplicative_expr(tl)
        if errmsg ~= nil then
            leaveStep(tl, "12 parse_additive_expr")
            return nil, errmsg
        end
        efs[#efs + 1] = ef
        local op
        op, errmsg = tl:readNexttokIfIsOneOfValue({ "+", "-" })
        if errmsg ~= nil then
            leaveStep(tl, "12 parse_additive_expr")
            return nil, errmsg
        end
        if not op then break end
        operators[#operators + 1] = op[1]
    end
    if #efs == 1 then
        leaveStep(tl, "12 parse_additive_expr (#efs == 1)")
        return efs[1], nil
    end

    local evaler = function(ctx)
        local s0, errmsg = efs[1](ctx)
        if errmsg ~= nil then return nil, errmsg end
        local sum
        sum, errmsg = number_value(s0)
        if errmsg ~= nil then return nil, errmsg end
        for i = 2, #efs do
            s0, errmsg = efs[i](ctx)
            if errmsg ~= nil then return nil, errmsg end
            local val
            val, errmsg = number_value(s0)
            if errmsg ~= nil then return nil, errmsg end

            if operators[i - 1] == "+" then
                sum = sum + val
            else
                sum = sum - val
            end
        end
        return { sum }, nil
    end
    leaveStep(tl, "12 parse_additive_expr")
    return evaler, nil
end

-- [13] MultiplicativeExpr ::=  UnionExpr ( ("*" | "div" | "idiv" | "mod") UnionExpr )*
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_multiplicative_expr(tl)
    enterStep(tl, "13 parse_multiplicative_expr")

    local efs = {}
    local operators = {}
    while true do
        local ef, errmsg = parse_union_expr(tl)
        if errmsg ~= nil then
            leaveStep(tl, "13 parse_multiplicative_expr (ue err)")
            return nil, errmsg
        end
        efs[#efs + 1] = ef
        local op
        op, errmsg = tl:readNexttokIfIsOneOfValue({ "*", "mod", "div", "idiv" })
        if errmsg ~= nil then
            leaveStep(tl, "13 parse_multiplicative_expr")
            return nil, errmsg
        end
        if not op then break end
        operators[#operators + 1] = op[1]
    end
    if #efs == 1 then
        leaveStep(tl, "13 parse_multiplicative_expr #efs 1")
        return efs[1], nil
    end

    local evaler = function(ctx)
        local s0, errmsg = efs[1](ctx)
        if errmsg ~= nil then return nil, errmsg end
        local result
        result, errmsg = number_value(s0)
        if errmsg ~= nil then return nil, errmsg end
        if not result then return nil, "number expected" end
        for i = 2, #efs do
            s0, errmsg = efs[i](ctx)
            if errmsg ~= nil then return nil, errmsg end
            local val
            val, errmsg = number_value(s0)
            if errmsg ~= nil then return nil, errmsg end

            if operators[i - 1] == "*" then
                result = result * val
            elseif operators[i - 1] == "div" then
                -- Guard against division by zero with IEEE-like semantics:
                if val == 0 then
                    if result == 0 then
                        -- 0 div 0 => NaN
                        result = 0/0
                    else
                        -- x div 0 => ±Infinity depending on sign of numerator
                        result = (result > 0) and math.huge or -math.huge
                    end
                else
                    result = result / val
                end
            elseif operators[i - 1] == "idiv" then
                local d = result / val
                local sign = 1
                if d < 0 then sign = -1 end
                result = math.floor(math.abs(d)) * sign
            elseif operators[i - 1] == "mod" then
                result = result % val
            else
                return nil, "unknown operator in mult expression"
            end
        end
        return { result }, nil
    end

    leaveStep(tl, "13 parse_multiplicative_expr (leave)")
    return evaler, nil
end

-- [14] UnionExpr ::= IntersectExceptExpr ( ("union" | "|") IntersectExceptExpr )*
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_union_expr(tl)
    enterStep(tl, "14 parse_union_expr")
    local ef, errmsg = parse_intersect_except_expr(tl)
    if errmsg ~= nil then
        leaveStep(tl, "14 parse_union_expr")
        return nil, errmsg
    end
    leaveStep(tl, "14 parse_union_expr")
    return ef, nil
end

-- [15] IntersectExceptExpr  ::= InstanceofExpr ( ("intersect" | "except") InstanceofExpr )*
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_intersect_except_expr(tl)
    enterStep(tl, "15 parse_intersect_except_expr")
    local ef, errmsg = parse_instance_of_expr(tl)
    if errmsg ~= nil then
        leaveStep(tl, "15 parse_intersect_except_expr")
        return nil, errmsg
    end
    leaveStep(tl, "15 parse_intersect_except_expr")
    return ef, nil
end

-- [16] InstanceofExpr ::= TreatExpr ( "instance" "of" SequenceType )?
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_instance_of_expr(tl)
    enterStep(tl, "16 parse_instance_of_expr")
    local ef, errmsg = parse_treat_expr(tl)
    if errmsg ~= nil then
        leaveStep(tl, "16 parse_instance_of_expr")
        return nil, errmsg
    end
    leaveStep(tl, "16 parse_instance_of_expr")
    return ef, nil
end

-- [17] TreatExpr ::= CastableExpr ( "treat" "as" SequenceType )?
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_treat_expr(tl)
    enterStep(tl, "17 parse_treat_expr")
    local ef, errmsg = parse_castable_expr(tl)
    if errmsg ~= nil then
        leaveStep(tl, "17 parse_treat_expr")
        return nil, errmsg
    end
    leaveStep(tl, "17 parse_treat_expr")
    return ef, nil
end

-- [18] CastableExpr ::= CastExpr ( "castable" "as" SingleType )?
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_castable_expr(tl)
    enterStep(tl, "18 parse_castable_expr")
    local ef, errmsg = parse_cast_expr(tl)
    if errmsg ~= nil then
        leaveStep(tl, "18 parse_castable_expr")
        return nil, errmsg
    end
    if tl:readNexttokIfIsOneOfValue({ "castable" }) then
        errmsg = tl:skipNCName("as")
        if errmsg ~= nil then
            leaveStep(tl, "18 parse_castable_expr")
            return nil, errmsg
        end
        local tok
        tok, errmsg = tl:read()
        if errmsg ~= nil then
            leaveStep(tl, "18 parse_castable_expr")
            return nil, errmsg
        end

        local evaler = function(ctx)
            local seq, errmsg = ef(ctx)
            if errmsg ~= nil then return nil, errmsg end
            if tok[1] == "xs:double" then
                local nv, _ = number_value(seq)
                if nv then return { true }, nil end
            elseif tok[1] == "xs:string" then
                local sv, _ = string_value(seq)
                if sv then return { true }, nil end
            end
            return { false }, nil
        end

        return evaler, nil
    end
    leaveStep(tl, "18 parse_castable_expr")
    return ef, nil
end

-- [19] CastExpr ::= UnaryExpr ( "cast" "as" SingleType )?
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_cast_expr(tl)
    enterStep(tl, "19 parse_cast_expr")
    local ef, errmsg = parse_unary_expr(tl)
    if errmsg ~= nil then
        leaveStep(tl, "19 parse_cast_expr")
        return nil, errmsg
    end
    leaveStep(tl, "19 parse_cast_expr")
    return ef, nil
end

-- [20] UnaryExpr ::= ("-" | "+")* ValueExpr
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_unary_expr(tl)
    enterStep(tl, "20 parse_unary_expr")
    local mult = 1
    while true do
        local tok, errmsg = tl:readNexttokIfIsOneOfValue({ "+", "-" })
        if errmsg ~= nil then
            leaveStep(tl, "20 parse_unary_expr (err)")
            return nil, errmsg
        end
        if tok == nil then
            break
        end
        if tok[2] == "tokString" then
            tl:unread()
            break
        end
        if tok[1] == "-" then mult = mult * -1 end
    end

    local ef, errmsg = parse_value_expr(tl)
    if errmsg ~= nil then
        leaveStep(tl, "20 parse_unary_expr")
        return nil, errmsg
    end
    if ef == nil then
        leaveStep(tl, "20 parse_unary_expr (nil ef)")
        return function() return {}, nil end, nil
    end

    local evaler = function(ctx)
        if mult == -1 then
            local seq, errmgs = ef(ctx)
            if errmgs ~= nil then
                return nil, errmgs
            end
            flt, errmgs = number_value(seq)
            if errmgs ~= nil then
                return nil, errmgs
            end
            return { flt * -1 }, nil
        end
        return ef(ctx)
    end
    leaveStep(tl, "20 parse_unary_expr")
    return evaler, nil
end

-- [21] ValueExpr ::= PathExpr
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_value_expr(tl)
    enterStep(tl, "21 parse_value_expr")
    local ef, errmsg = parse_path_expr(tl)
    if errmsg ~= nil then
        leaveStep(tl, "21 parse_value_expr")
        return nil, errmsg
    end
    leaveStep(tl, "21 parse_value_expr")
    return ef, nil
end

-- [25] PathExpr ::= ("/" RelativePathExpr?) | ("//" RelativePathExpr) | RelativePathExpr
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_path_expr(tl)
    enterStep(tl, "25 parse_path_expr")
    local op
    if tl:nextTokIsType('tokOperator') then
        op = tl:readNexttokIfIsOneOfValue({ "/", "//" })
    end
    local eof
    _, eof = tl:peek()
    if eof then
        if op then
            if op[1] == "/" then
                local evaler = function(ctx)
                    ctx:document()
                    return ctx.sequence, nil
                end
                return evaler
            end
            -- [err:XPST0003]
            return nil, "// - unexpected EOF"
        end
    end
    local rpe, errmsg = parse_relative_path_expr(tl)
    if errmsg ~= nil then
        leaveStep(tl, "25 parse_path_expr")
        return nil, errmsg
    end
    if op then
        local evaler = function(ctx)
            ctx:document()
            if op[1] == "//" then
                ctx:descendantOrSelf(function() return true end)
            end
            seq, msg = rpe(ctx)
            if msg then return nil, msg end
            return seq, nil
        end
        return evaler, nil
    end

    leaveStep(tl, "25 parse_path_expr")
    return rpe, nil
end

-- [26] RelativePathExpr ::= StepExpr (("/" | "//") StepExpr)*
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_relative_path_expr(tl)
    enterStep(tl, "26 parse_relative_path_expr")

    local efs = {}
    local ops = {}
    while true do
        local ef, errmsg = parse_step_expr(tl)
        if errmsg ~= nil then
            leaveStep(tl, "26 parse_relative_path_expr")
            return nil, errmsg
        end
        efs[#efs + 1] = ef
        local nt, eof = tl:peek()
        if eof then break end
        if nt and nt[2] == "tokOperator" and (nt[1] == "/" or nt[1] == "//") then
            ops[#ops + 1] = nt[1]
            tl:read()
        else
            break
        end
    end
    if #efs == 1 then
        leaveStep(tl, "26 parse_relative_path_expr #efs1")
        return efs[1], nil
    end

    local evaler = function(ctx)
        local retseq
        for i = 1, #efs do
            retseq = {}
            local copysequence = ctx.sequence
            local ef = efs[i]
            ctx.size = #copysequence
            for j, itm in ipairs(copysequence) do
                ctx.sequence = { itm }
                ctx.pos = j
                local seq, errmsg = ef(ctx)
                if errmsg then
                    return nil, errmsg
                end
                for _, val in ipairs(seq) do
                    retseq[#retseq + 1] = val
                end
            end
            ctx.sequence = retseq
            if i <= #ops and ops[i] == "//" then
                ctx:descendantOrSelf(function(ctx,itm) return is_element(itm) end)
            end
        end
        return retseq, nil
    end
    leaveStep(tl, "26 parse_relative_path_expr (last)")
    return evaler, nil
end

-- [27] StepExpr := FilterExpr | AxisStep
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_step_expr(tl)
    enterStep(tl, "27 parse_step_expr")
    local ef, errmsg = parse_filter_expr(tl)
    if errmsg ~= nil then
        leaveStep(tl, "27 parse_step_expr (err nil)")
        return nil, errmsg
    end
    if not ef then
        ef, errmsg = parse_axis_step(tl)
        if errmsg ~= nil then
            leaveStep(tl, "27 parse_step_expr")
            return nil, errmsg
        end
    end
    leaveStep(tl, "27 parse_step_expr (leave)")
    return ef, nil
end

-- [28] AxisStep ::= (ReverseStep | ForwardStep) PredicateList
-- [39] PredicateList ::= Predicate*
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_axis_step(tl)
    enterStep(tl, "28 parse_axis_step")
    local errmsg = nil
    local ef
    ef, errmsg = parse_forward_step(tl)
    if errmsg ~= nil then
        leaveStep(tl, "28 parse_axis_step")
        return nil, errmsg
    end
    local predicates = {}

    while true do
        if not tl:nextTokIsType("tokOpenBracket") then
            break
        end
        local predicate
        tl:read()
        predicate, errmsg = parse_expr(tl)
        if errmsg then
            leaveStep(tl, "28 parse_axis_step (err)")
            return nil, errmsg
        end
        predicates[#predicates + 1] = predicate
        tl:skipType("tokCloseBracket")
    end

    if #predicates > 0 then
        local ff = function(ctx)
            local seq, errmsg = ef(ctx)
            if errmsg then
                return nil, errmsg
            end
            ctx.sequence = seq
            for _, predicate in ipairs(predicates) do
                local _, errmsg = filter(ctx, predicate)
                if errmsg then return nil, errmsg end
            end
            ctx.size = #ctx.sequence
            return ctx.sequence, nil
        end
        leaveStep(tl, "28 parse_axis_step (ff)")
        return ff
    end
    leaveStep(tl, "28 parse_axis_step")
    return ef, nil
end

-- [29] ForwardStep ::= (ForwardAxis NodeTest) | AbbrevForwardStep
-- [30] ForwardAxis ::= ("child" "::") | ("descendant" "::") | ("attribute" "::") | ("self" "::") | ("descendant-or-self" "::") | ("following-sibling" "::") | ("following" "::") | ("namespace" "::")
-- [31] AbbrevForwardStep ::= "@"? NodeTest
-- [32] ReverseStep ::= (ReverseAxis NodeTest) | AbbrevReverseStep
-- [33] ReverseAxis ::= ("parent" "::") | ("ancestor" "::") | ("preceding-sibling" "::") | ("preceding" "::") | ("ancestor-or-self" "::")
-- [34] AbbrevReverseStep ::= ".."
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_forward_step(tl)
    enterStep(tl, "29 parse_forward_step")
    local errmsg = nil
    local tf
    local axisChild, axisAttribute, axisSelf, axisDescendant, axisDescendantOrSelf, axisFollowing, axisFollowingSibling, axisNamespace =
        1, 2, 3, 4, 5, 6, 7, 8
    local axisParent, axisAncestor, axisPrecedingSibling, axisPreceding, axisAncestorOrSelf = 9, 10, 11, 12, 13
    local stepAxis = axisChild

    if tl:nextTokIsType("tokDoubleColon") then
        local tok
        tok, errmsg = tl:read()
        if errmsg then
            leaveStep(tl, "29 parse_forward_step")
            return nil, errmsg
        end
        if not tok then
            return nil, "tok is nil"
        end
        if tok[1] == "child" then
            stepAxis = axisChild
        elseif tok[1] == "self" then
            stepAxis = axisSelf
        elseif tok[1] == "descendant" then
            stepAxis = axisDescendant
        elseif tok[1] == "descendant-or-self" then
            stepAxis = axisDescendantOrSelf
        elseif tok[1] == "following" then
            stepAxis = axisFollowing
        elseif tok[1] == "following-sibling" then
            stepAxis = axisFollowingSibling
        elseif tok[1] == "parent" then
            stepAxis = axisParent
        elseif tok[1] == "ancestor" then
            stepAxis = axisAncestor
        elseif tok[1] == "ancestor-or-self" then
            stepAxis = axisAncestorOrSelf
        elseif tok[1] == "preceding-sibling" then
            stepAxis = axisPrecedingSibling
        elseif tok[1] == "preceding" then
            stepAxis = axisPreceding
        else
            assert(false, tok[1])
        end

        if tl:readNexttokIfIsOneOfValue({ "@" }) then
            return nil, "@ invalid"
        end
    end

    if tl:nextTokIsType("tokOperator") and tl:readNexttokIfIsOneOfValue({ ".." }) then
        local evaler = function(ctx)
            local seq, errmsg = ctx:parentAxis(function() return true end)
            if errmsg then
                return nil, errmsg
            end
            ctx.sequence = seq
            return seq, nil
        end
        return evaler, nil
    end

    if tl:readNexttokIfIsOneOfValue({ "@" }) then
        tl.attributeMode = true
        stepAxis = axisAttribute
    else
        tl.attributeMode = false
    end

    tf, errmsg = parse_node_test(tl)
    if errmsg then
        leaveStep(tl, "29 parse_forward_step")
        return nil, errmsg
    end
    if not tf then
        leaveStep(tl, "29 parse_forward_step (nil)")
        return nil, nil
    end
    local evaler = function(ctx)
        if not tf then return nil, nil end
        if not ctx.xmldoc then
            return nil, "XML not set, aborting"
        end
        if stepAxis == axisSelf then
            -- do nothing
        elseif stepAxis == axisChild then
            ctx:childaxis(tf)
        elseif stepAxis == axisAttribute then
            ctx:attributeaixs(tf)
        elseif stepAxis == axisDescendant then
            ctx:descendant(tf)
        elseif stepAxis == axisDescendantOrSelf then
            ctx:descendantOrSelf(tf)
        elseif stepAxis == axisFollowing then
            ctx:following(tf)
        elseif stepAxis == axisFollowingSibling then
            ctx:followingSibling(tf)
        elseif stepAxis == axisParent then
            ctx:parentAxis(tf)
        elseif stepAxis == axisAncestor then
            ctx:ancestorAxis(tf)
        elseif stepAxis == axisAncestorOrSelf then
            ctx:ancestorOrSelfAxis(tf)
        elseif stepAxis == axisPrecedingSibling then
            ctx:precedingSiblingAxis(tf)
        elseif stepAxis == axisPreceding then
            ctx:precedingAxis(tf)
        else
            assert(false, "not yet implemented stepAxis")
        end
        local ret = {}
        ctx.positions = {}
        ctx.lengths = {}
        local c = 1
        for _, itm in ipairs(ctx.sequence) do
            ctx.positions[#ctx.positions + 1] = c
            c = c + 1
            ret[#ret + 1] = itm
        end
        for i = 1, #ret do
            ctx.lengths[#ctx.lengths + 1] = #ret
        end
        return ret, nil
    end

    leaveStep(tl, "29 parse_forward_step (exit)")

    return evaler, nil
end

-- [35] NodeTest ::= KindTest | NameTest
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_node_test(tl)
    enterStep(tl, "35 parse_node_test")
    local tf, errmsg
    tf, errmsg = parse_kind_test(tl)
    if errmsg then
        leaveStep(tl, "35 parse_node_test")
        return nil, errmsg
    end
    if not tf then
        tf, errmsg = parse_name_test(tl)
        if errmsg then
            leaveStep(tl, "35 parse_node_test")
            return nil, errmsg
        end
    end
    leaveStep(tl, "35 parse_node_test")
    return tf, nil
end

-- [36] NameTest ::= QName | Wildcard
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_name_test(tl)
    enterStep(tl, "36 parse_name_test")
    local tf, errmsg
    if tl:nextTokIsType("tokQName") then
        local n
        n, errmsg = tl:read()
        if errmsg then
            leaveStep(tl, "36 parse_name_test")
            return nil, errmsg
        end
        if not n then
            return nil, "qname should not be empty"
        end
        local name = n[1]
        if tl.attributeMode then
            tf = function(ctx, itm)
                return itm.name == name
            end
        else
            tf = function(ctx, itm)
                if is_element(itm) then
                    if M.ignoreNS then
                        -- name might have a namespace prefix
                        name = string.gsub(name,"^(.*:)","")
                        return itm[".__local_name"] == name
                    end
                    local prefix, locname = string.match(name,"(.*):(.*)")
                    prefix = prefix or ""
                    locname = locname or name
                    local ns = ctx.namespaces[prefix]
                    return itm[".__local_name"] == locname and itm[".__namespace"] == ( ns or "" )
                end
                return false
            end
        end
        leaveStep(tl, "36 parse_name_test")
        return tf, nil
    end
    tf, errmsg = parse_wild_card(tl)
    leaveStep(tl, "36 parse_name_test")
    return tf, nil
end

-- [37] Wildcard ::= "*" | (NCName ":" "*") | ("*" ":" NCName)
function parse_wild_card(tl)
    enterStep(tl, "37 parse_wild_card")
    local nexttok, errmsg = tl:read()
    if errmsg ~= nil then
        leaveStep(tl, "37 parse_wild_card")
        return nil, errmsg
    end
    local str = nexttok[1]
    if str == "*" or str:match("^%*:") or str:match(":%*$") then
        if tl.attributeMode then
            tf = function(ctx, itm)
                if is_attribute(itm) then
                    return true
                end
            end
        else
            tf = function(ctx,itm)
                if not is_element(itm) then
                    return false
                end
                if str == '*' then
                    return true
                end
                local prefix, locname = string.match(str,"(.*):(.*)")
                if prefix == "*" then
                    if itm[".__local_name"] == locname then
                        return true
                    end
                end
                if locname == "*" then
                    local reqns = ctx.namespaces[prefix]
                    if itm[".__namespace"] == reqns then
                        return true
                    end
                end
            end
        end
        leaveStep(tl, "37 parse_wild_card")
        return tf, nil
    else
        tl:unread()
    end
    leaveStep(tl, "37 parse_wild_card")
end

-- [38] FilterExpr ::= PrimaryExpr PredicateList
-- [39] PredicateList ::= Predicate*
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_filter_expr(tl)
    enterStep(tl, "38 parse_filter_expr")
    local ef, errmsg = parse_primary_expr(tl)
    if errmsg ~= nil then
        leaveStep(tl, "38 parse_filter_expr")
        return nil, errmsg
    end
    while true do
        if tl:nextTokIsType("tokOpenBracket") then
            tl:read()
            local f, errmsg = parse_expr(tl)
            if errmsg ~= nil then
                leaveStep(tl, "38 parse_filter_expr")
                return nil, errmsg
            end
            if not tl:skipType("tokCloseBracket") then
                leaveStep(tl, "38 parse_filter_expr")
                return nil, "] expected"
            end
            local filterfunc = function(ctx)
                local seq, errmsg = ef(ctx)
                if errmsg then
                    return nil, errmsg
                end

                ctx.sequence = seq
                return filter(ctx, f)
            end
            leaveStep(tl, "38 parse_filter_expr")
            return filterfunc, nil
        end
        break
    end
    leaveStep(tl, "38 parse_filter_expr")
    return ef, nil
end

-- [40] Predicate ::= "[" Expr "]"
-- [41] PrimaryExpr ::= Literal | VarRef | ParenthesizedExpr | ContextItemExpr | FunctionCall
function parse_primary_expr(tl)
    enterStep(tl, "41 parse_primary_expr")
    local nexttok, errmsg = tl:read()
    if errmsg ~= nil then
        leaveStep(tl, "41 parse_primary_expr (err)")
        return nil, errmsg
    end

    -- StringLiteral
    if nexttok[2] == "tokString" then
        leaveStep(tl, "41 parse_primary_expr (sl)")
        local evaler = function(ctx)
            return { nexttok[1] }, nil
        end
        return evaler, nil
    end

    -- NumericLiteral
    if nexttok[2] == "tokNumber" then
        leaveStep(tl, "41 parse_primary_expr (nl)")
        local evaler = function(ctx)
            return { nexttok[1] }, nil
        end
        return evaler, nil
    end

    -- ParenthesizedExpr
    if nexttok[2] == "tokOpenParen" then
        local ef, errmsg = parse_parenthesized_expr(tl)
        if errmsg ~= nil then
            leaveStep(tl, "41 parse_primary_expr (err2)")
            return nil, errmsg
        end
        leaveStep(tl, "41 parse_primary_expr (op)")
        return ef, nil
    end


    -- VarRef
    if nexttok[2] == "tokVarname" then
        local evaler = function(ctx)
            local varname = nexttok[1]
            local value = ctx.vars[varname]
            if type(value) == "table" then return value, nil end
            if not ctx.vars[varname] then return nil, string.format("variable %s does not exist", varname) end
            return { ctx.vars[varname] }, nil
        end
        leaveStep(tl, "41 parse_primary_expr (vr)")
        return evaler, nil
    end


    if nexttok[2] == "tokOperator" and nexttok[1] == "." then
        local evaler = function(ctx)
            return ctx.sequence, nil
        end
        leaveStep(tl, "41 parse_primary_expr (ci)")
        return evaler, nil
    end

    -- FunctionCall
    if nexttok[2] == "tokQName" then
        if tl:nextTokIsType("tokOpenParen") then
            local fnname = nexttok[1]
            if fnname == "node" or fnname == "element" or fnname == "text" or fnname == "comment" or fnname == "schema-attribute" or fnname == "schema-element" or fnname == "attribute" or fnname == "document" or fnname == "processing-instruction" then
                tl:unread()
                leaveStep(tl, "41 parse_primary_expr (kindtest)")
                return nil, nil
            end
            tl:unread()
            local ef
            ef, errmsg = parse_function_call(tl)
            if errmsg ~= nil then
                leaveStep(tl, "41 parse_primary_expr: " .. errmsg)
                return nil, errmsg
            end
            leaveStep(tl, "41 parse_primary_expr (fc)")
            return ef, nil
        end
    end
    tl:unread()
    leaveStep(tl, "41 parse_primary_expr (exit)")
    return nil, nil
end

-- [46] ParenthesizedExpr ::= "(" Expr? ")"
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_parenthesized_expr(tl)
    enterStep(tl, "46 parse_parenthesized_expr")
    -- shortcut for empty sequence ():
    if tl:nextTokIsType("tokCloseParen") then
        tl:read()
        return function(ctx) return {}, nil end
    end

    local ef, errmsg = parse_expr(tl)
    if errmsg ~= nil then
        leaveStep(tl, "46 parse_parenthesized_expr (err)")
        return nil, errmsg
    end
    if not tl:skipType("tokCloseParen") then
        leaveStep(tl, "46 parse_parenthesized_expr (err)")
        return nil, errmsg
    end
    local evaler = function(ctx)
        local seq, errmsg = ef(ctx)
        if errmsg ~= nil then
            return nil, errmsg
        end
        return seq, nil
    end
    leaveStep(tl, "46 parse_parenthesized_expr")
    return evaler, nil
end

-- [48] FunctionCall ::= QName "(" (ExprSingle ("," ExprSingle)*)? ")"
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_function_call(tl)
    enterStep(tl, "48 parse_function_call")
    local function_name_token, errmsg = tl:read()
    if errmsg ~= nil then
        leaveStep(tl, "48 parse_function_call")
        return nil, errmsg
    end
    if function_name_token == nil then
        return nil, "function name token expected"
    end
    tl:skipType("tokOpenParen")
    if tl:nextTokIsType("tokCloseParen") then
        tl:read()
        local evaler = function(ctx)
            return callFunction(function_name_token[1], {}, ctx)
        end
        leaveStep(tl, "48 parse_function_call")
        return evaler, nil
    end

    local efs = {}
    while true do
        local es
        es, errmsg = parse_expr_single(tl)
        if errmsg ~= nil then
            leaveStep(tl, "48 parse_function_call")
            return nil, errmsg
        end
        efs[#efs + 1] = es
        if not tl:nextTokIsType("tokComma") then
            leaveStep(tl, "48 parse_function_call")
            break
        end
        tl:read()
    end

    if not tl:skipType("tokCloseParen") then
        return nil, ") expected"
    end

    local evaler = function(ctx)
        local arguments = {}
        -- TODO: save context and restore afterwards
        local seq, errmsg
        for _, ef in ipairs(efs) do
            local newctx = ctx:copy()
            seq, errmsg = ef(newctx)
            if errmsg ~= nil then return nil, errmsg end
            arguments[#arguments + 1] = seq
        end
        return callFunction(function_name_token[1], arguments, ctx)
    end
    leaveStep(tl, "48 parse_function_call")
    return evaler, nil
end

-- [54] ::= KindTest ::= DocumentTest | ElementTest | AttributeTest | SchemaElementTest | SchemaAttributeTest | PITest | CommentTest | TextTest | AnyKindTest
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_kind_test(tl)
    enterStep(tl, "54 parse_kind_test")
    local tf, errmsg
    tf, errmsg = parse_element_test(tl)
    if errmsg then
        leaveStep(tl, "54 parse_kind_test")
        return nil, errmsg
    end
    if tf then
        leaveStep(tl, "54 parse_kind_test")
        return tf, nil
    end
    tf, errmsg = parse_text_test(tl)
    if errmsg then
        leaveStep(tl, "54 parse_kind_test")
        return nil, errmsg
    end
    if tf then
        leaveStep(tl, "54 parse_kind_test")
        return tf, nil
    end
    tf, errmsg = parse_any_kind_test(tl)
    if errmsg then
        leaveStep(tl, "54 parse_kind_test")
        return nil, errmsg
    end

    leaveStep(tl, "54 parse_kind_test")
    return tf, nil
end

-- [55] AnyKindTest ::= "node" "(" ")"
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_any_kind_test(tl)
    enterStep(tl, "55 parse_any_kind_test")
    local tok, eof
    tok, eof = tl:peek(1)
    if not eof and tok[1] == "node" and tok[2] == "tokQName" then
        tok, eof = tl:peek(2)
        if not eof and tok[2] == "tokOpenParen" then
            tok, eof = tl:peek(3)
            if not eof and tok[2] == "tokCloseParen" then
                tl:read()
                tl:read()
                tl:read()
                local tf = function(ctx, itm)
                    return true, nil
                end
                leaveStep(tl, "55 parse_any_kind_test")
                return tf, nil
            end
        end
    end
    leaveStep(tl, "55 parse_any_kind_test")
    return nil, nil
end

-- [64] ElementTest ::= "element" "(" ")"
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_element_test(tl)
    enterStep(tl, "64 parse_element_test")
    local tok, eof
    tok, eof = tl:peek(1)
    if not eof and tok[1] == "element" and tok[2] == "tokQName" then
        tok, eof = tl:peek(2)
        if not eof and tok[2] == "tokOpenParen" then
            tok, eof = tl:peek(3)
            if not eof and tok[2] == "tokCloseParen" then
                tl:read()
                tl:read()
                tl:read()
                local tf = function(ctx,itm)
                    return is_element(itm), nil
                end
                leaveStep(tl, "64 parse_element_test")
                return tf, nil
            end
        end
    end
    leaveStep(tl, "64 parse_element_test")
    return nil, nil
end

-- [57] TextTest ::= "text" "(" ")"
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_text_test(tl)
    enterStep(tl, "57 parse_text_test")
    local tok, eof
    tok, eof = tl:peek(1)
    if not eof and tok[1] == "text" and tok[2] == "tokQName" then
        tok, eof = tl:peek(2)
        if not eof and tok[2] == "tokOpenParen" then
            tok, eof = tl:peek(3)
            if not eof and tok[2] == "tokCloseParen" then
                tl:read()
                tl:read()
                tl:read()
                local tf = function(ctx, itm)
                    return type(itm) == "string", nil
                end
                leaveStep(tl, "57 parse_text_test")
                return tf, nil
            end
        end
    end
    leaveStep(tl, "57 parse_text_test")
    return nil, nil
end

---@param tl tokenlist
---@return evalfunc?
---@return string? error
function M.parse_xpath(tl)
    local evaler, errmsg = parse_expr(tl)
    if errmsg ~= nil then
        return nil, errmsg
    end
    return evaler, nil
end

-- Execute the xpath and restore the context.
---@param xpathstring string
---@return table? sequence
---@return string? error
function context:eval(xpathstring)
    local toks, msg = M.string_to_tokenlist(xpathstring)
    if toks == nil then
        return nil, msg
    end
    if #toks == 0 then
        return {}, nil
    end
    local evaler, errmsg = parse_expr(toks)
    if errmsg ~= nil then
        return nil, errmsg
    end
    if not evaler then
        return nil, "internal error"
    end
    local copy = self:copy()
    return evaler(copy)
end

-- Execute the xpath string
---@param xpathstring string
---@return table? sequence
---@return string? error
function context:execute(xpathstring)
    local toks, msg = M.string_to_tokenlist(xpathstring)
    if toks == nil then
        return nil, msg
    end
    if #toks == 0 then
        return {}, nil
    end
    local evaler, errmsg = parse_expr(toks)
    if errmsg ~= nil then
        return nil, errmsg
    end
    if not evaler then
        return nil, "internal error"
    end

    return evaler(self)
end

return M
