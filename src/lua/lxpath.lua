local M = {
    private = {},
    funcs = {},
    dodebug = false,
    debugindent = "  ",
    fnNS = "http://www.w3.org/2005/xpath-functions",
    xsNS = "http://www.w3.org/2001/XMLSchema",
    stringmatch = string.match,
    stringfind = string.find
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
        if is_letter(r) or is_digit(r) or r == '_' or r == '-' or r == '·' or r == '‿' or r == '⁀' then
            word[#word + 1] = r
        elseif r == ":" then
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
    return table.concat(word)
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

---@return token?
---@return boolean
function tokenlist:peek()
    if self.pos > #self then
        return nil, true
    end
    return self[self.pos], false
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
function tokenlist:readNexttokIfIsOneOfValue(tokvalues)
    if self.pos > #self then
        return nil, nil
    end
    for _, tokvalue in ipairs(tokvalues) do
        if self[self.pos][1] == tokvalue then
            return self:read()
        end
    end
    return nil, nil
end

function tokenlist:nextTokIsType(typ)
    if self.pos > #self then return false end
    local t = self:peek()
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
            if '0' <= nextrune and nextrune <= '9' then
                unread_rune(runes)
                unread_rune(runes)
                local num
                num = get_num(runes)
                tokens[#tokens + 1] = { num, "tokNumber" }
            else
                unread_rune(runes)
                tokens[#tokens + 1] = { '.', "tokOperator" }
            end
        elseif r == '+' or r == '-' or r == '*' or r == '?' or r == '@' or r == '|' or r == '=' then
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
M.is_element = is_element

local function is_attribute(itm)
    return type(itm) == "table" and itm[".__type"] == "attribute"
end

local function number_value(sequence)
    if type(sequence) == "string" then return tonumber(sequence) end

    if is_attribute(sequence) then
        return tonumber(sequence.value)
    end

    if type(sequence) == "number" then
        return sequence
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
    return tonumber(sequence[1]), nil
end

local function boolean_value(seq)
    if #seq == 0 then return false, nil end
    if #seq > 1 then return false, "invalid argument for boolean value" end
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
    end
    return ok, nil
end

local function string_value(seq)
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

    local ln, rn
    ln, _ = number_value(leftitem)
    rn, _ = number_value(rightitem)

    if type(ln) == "number" and type(rn) == "number" then
        local x, errmsg = docomparenumber(op, ln, rn)
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
    { "empty",                M.fnNS, fnEmpty,              1, 1 },
    { "false",                M.fnNS, fnFalse,              0, 0 },
    { "floor",                M.fnNS, fnFloor,              1, 1 },
    { "last",                 M.fnNS, fnLast,               0, 0 },
    { "local-name",           M.fnNS, fnLocalName,          0, 1 },
    { "lower-case",           M.fnNS, fnLowerCase,          1, 1 },
    { "max",                  M.fnNS, fnMax,                1, 1 },
    { "matches",              M.fnNS, fnMatches,            2, 3 },
    { "min",                  M.fnNS, fnMin,                1, 1 },
    { "normalize-space",      M.fnNS, fnNormalizeSpace,     1, 1 },
    { "not",                  M.fnNS, fnNot,                1, 1 },
    { "number",               M.fnNS, fnNumber,             1, 1 },
    { "position",             M.fnNS, fnPosition,           0, 0 },
    { "reverse",              M.fnNS, fnReverse,            1, 1 },
    { "root",                 M.fnNS, fnRoot,               0, 1 },
    { "round",                M.fnNS, fnRound,              1, 1 },
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
    local minarg, maxarg = func[4], func[5]

    if #seq < minarg or (maxarg ~= -1 and #seq > maxarg) then
        if minarg == maxarg then
            return {}, string.format("function %s requires %d arguments, %d supplied", func[1], minarg, #seq)
        else
            return {}, string.format("function %s requires %d to %d arguments, %d supplied", func[1], minarg, maxarg,
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

function context:attributeaixs()
    local seq = {}
    for _, itm in ipairs(self.sequence) do
        if is_element(itm) then
            for key, value in pairs(itm[".__attributes"]) do
                local x = {
                    name = key,
                    value = value,
                    [".__type"] = "attribute",
                }
                seq[#seq + 1] = x
            end
        end
    end
    self.sequence = seq
    return seq, nil
end

function context:childaxis()
    local seq = {}
    for _, elt in ipairs(self.sequence) do
        if type(elt) == "table" then
            if is_element(elt) then
                for _, cld in ipairs(elt) do
                    seq[#seq + 1] = cld
                end
            elseif elt[".__type"] and elt[".__type"] == "document" then
                for _, cld in ipairs(elt) do
                    seq[#seq + 1] = cld
                end
            else
                for key, value in pairs(elt) do
                    print(key, value)
                end
                assert(false, "table, not element")
            end
        elseif type(elt) == "string" then
            seq[#seq + 1] = elt
        else
            print("something else", type)
        end
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
        local ret = {}
        local seq
        local errmsg
        for _, ef in ipairs(efs) do
            seq, errmsg = ef(ctx)
            if errmsg then
                return nil, errmsg
            end
            for _, itm in ipairs(seq) do
                ret[#ret + 1] = itm
            end
        end
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
    local tok, errmsg = tl:readNexttokIfIsOneOfValue({ "for", "some", "if" })
    if errmsg then
        leaveStep(tl, "3 parse_expr_single")
        return nil, errmsg
    end
    if tok then
        local ef
        if tok[1] == "for" then
            ef, errmsg = parse_for_expr(tl)
        elseif tok[1] == "some" then
            assert(false, "nyi")
        elseif tok[1] == "if" then
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
            seq, errmsg = ef(ctx)
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
            seq, msg = ef(ctx)
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
                result = result / val
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
                    w("/, eof")
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
        if op[1] == "/" then
            local evaler = function(ctx)
                ctx:document()
                seq, msg = rpe(ctx)
                if msg then return nil, msg end
                return seq, nil
            end
            return evaler, nil
            -- print("/")
        else
            assert(false, "nyi")
        end
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
    while true do
        local ef, errmsg = parse_step_expr(tl)
        if errmsg ~= nil then
            leaveStep(tl, "26 parse_relative_path_expr")
            return nil, errmsg
        end
        efs[#efs + 1] = ef
        if not tl:readNexttokIfIsOneOfValue { "/", "//" } then
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
            for i, itm in ipairs(copysequence) do
                ctx.sequence = { itm }
                ctx.pos = i
                local seq, errmsg = ef(ctx)
                if errmsg then
                    return nil, errmsg
                end
                for _, val in ipairs(seq) do
                    retseq[#retseq + 1] = val
                end
            end
            ctx.sequence = retseq
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
-- [31] AbbrevForwardStep ::= "@"? NodeTest
--
---@param tl tokenlist
---@return evalfunc?
---@return string? error
function parse_forward_step(tl)
    enterStep(tl, "29 parse_forward_step")
    local errmsg = nil
    local tf
    local axisChild, axisAttribute = 1, 2
    local stepAxis = axisChild

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
        if stepAxis == axisChild then
            ctx:childaxis()
        else
            ctx:attributeaixs()
        end
        if not tf then return nil, nil end
        local ret = {}
        ctx.positions = {}
        ctx.lengths = {}
        local c = 1
        for _, itm in ipairs(ctx.sequence) do
            if tf(itm) then
                ctx.positions[#ctx.positions + 1] = c
                c = c + 1
                ret[#ret + 1] = itm
            end
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
    tf, errmsg = parse_name_test(tl)
    if errmsg then
        leaveStep(tl, "35 parse_node_test")
        return nil, errmsg
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
            tf = function(itm)
                return itm.name == name
            end
        else
            tf = function(itm)
                if is_element(itm) then
                    return itm[".__name"] == name
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
            tf = function(itm)
                if is_attribute(itm) then
                    return true
                end
            end
        else
            tf = function(itm)
                if is_element(itm) then
                    return true
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
            seq, errmsg = ef(ctx)
            if errmsg ~= nil then return nil, errmsg end
            arguments[#arguments + 1] = seq
        end
        return callFunction(function_name_token[1], arguments, ctx)
    end
    leaveStep(tl, "48 parse_function_call")
    return evaler, nil
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
