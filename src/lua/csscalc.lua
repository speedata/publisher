-- Evaluation of CSS calc() expressions such as "calc( ( 6 / 14 - 0.375 ) * 1em )".
-- The CSS parser (Go) keeps the operators and separates the tokens with
-- spaces. Relative units are resolved with the sizes given in the context.

local M = {}

-- Size of one unit in sp, computed on first use with tex.sp (which knows
-- the publisher's interpretation of pt and px).
local unitsize = {}
local absolute_units = { pt = true, px = true, mm = true, cm = true, ["in"] = true, pc = true, bp = true, sp = true }

---@class CalcContext
---@field em? number Size of 1em in sp.
---@field rem? number Size of 1rem in sp.
---@field percent? number Size of 100% in sp. Without it, percentages are an error.

---@class CalcValue
---@field n number Number, or length in sp if `len` is set.
---@field len boolean

-- Returns true if `str` is a calc() expression.
---@param str any
---@return boolean
function M.is_calc(str)
    return type(str) == "string" and string.match(str, "^%s*calc%(") ~= nil
end

---@param str string
---@return string[]
local function tokenize(str)
    local toks = {}
    local pos = 1
    local len = #str
    while pos <= len do
        local c = string.sub(str, pos, pos)
        if string.match(c, "%s") then
            pos = pos + 1
        elseif c == "(" or c == ")" or c == "*" or c == "/" or c == "+" or c == "," then
            toks[#toks + 1] = c
            pos = pos + 1
        else
            -- number with optional sign and unit, a function name such as
            -- "calc(", or a lone minus (operator)
            local num = string.match(str, "^[-+]?%d*%.?%d+[%a%%]*", pos)
            if num then
                toks[#toks + 1] = num
                pos = pos + #num
            else
                local fn = string.match(str, "^%a[%w-]*%(", pos)
                if fn then
                    toks[#toks + 1] = string.lower(fn)
                    pos = pos + #fn
                elseif c == "-" then
                    toks[#toks + 1] = c
                    pos = pos + 1
                else
                    error("unexpected character " .. c, 0)
                end
            end
        end
    end
    return toks
end

---@param str string
---@param ctx CalcContext
---@return CalcValue
local function value(str, ctx)
    local num, unit = string.match(str, "^([-+]?%d*%.?%d+)([%a%%]*)$")
    if not num then
        error("not a number: " .. str, 0)
    end
    local n = tonumber(num)
    unit = string.lower(unit)
    if unit == "" then
        return { n = n, len = false }
    elseif unit == "em" then
        if not ctx.em then
            error("em not allowed here", 0)
        end
        return { n = n * ctx.em, len = true }
    elseif unit == "rem" then
        if not ctx.rem then
            error("rem not allowed here", 0)
        end
        return { n = n * ctx.rem, len = true }
    elseif unit == "%" then
        if not ctx.percent then
            error("percentage not allowed here", 0)
        end
        return { n = n * ctx.percent / 100, len = true }
    elseif absolute_units[unit] then
        if not unitsize[unit] then
            unitsize[unit] = tex.sp("1" .. unit)
        end
        return { n = n * unitsize[unit], len = true }
    end
    error("unknown unit " .. unit, 0)
end

local expression

---@param toks string[]
---@param state { pos: integer }
---@param ctx CalcContext
---@return CalcValue
local function factor(toks, state, ctx)
    local tok = toks[state.pos]
    if tok == nil then
        error("unexpected end", 0)
    end
    state.pos = state.pos + 1
    if tok == "(" or tok == "calc(" then
        local v = expression(toks, state, ctx)
        if toks[state.pos] ~= ")" then
            error("missing )", 0)
        end
        state.pos = state.pos + 1
        return v
    elseif tok == "-" then
        local v = factor(toks, state, ctx)
        return { n = -v.n, len = v.len }
    elseif tok == "+" then
        return factor(toks, state, ctx)
    elseif string.match(tok, "%($") then
        error("function " .. tok .. ") not supported", 0)
    end
    return value(tok, ctx)
end

---@param toks string[]
---@param state { pos: integer }
---@param ctx CalcContext
---@return CalcValue
local function term(toks, state, ctx)
    local v = factor(toks, state, ctx)
    while toks[state.pos] == "*" or toks[state.pos] == "/" do
        local op = toks[state.pos]
        state.pos = state.pos + 1
        local w = factor(toks, state, ctx)
        if op == "*" then
            if v.len and w.len then
                error("cannot multiply two lengths", 0)
            end
            v = { n = v.n * w.n, len = v.len or w.len }
        else
            if w.len then
                error("cannot divide by a length", 0)
            end
            if w.n == 0 then
                error("division by zero", 0)
            end
            v = { n = v.n / w.n, len = v.len }
        end
    end
    return v
end

---@param toks string[]
---@param state { pos: integer }
---@param ctx CalcContext
---@return CalcValue
expression = function(toks, state, ctx)
    local v = term(toks, state, ctx)
    while toks[state.pos] == "+" or toks[state.pos] == "-" do
        local op = toks[state.pos]
        state.pos = state.pos + 1
        local w = term(toks, state, ctx)
        if v.len ~= w.len then
            error("cannot add a number and a length", 0)
        end
        if op == "+" then
            v = { n = v.n + w.n, len = v.len }
        else
            v = { n = v.n - w.n, len = v.len }
        end
    end
    return v
end

-- Evaluates the calc() expression `str`. Returns the result (a length in
-- sp is rounded) and whether it is a length. On error, the message is
-- logged and nil is returned.
---@param str string
---@param ctx CalcContext?
---@return number? result
---@return boolean? is_length
function M.evaluate(str, ctx)
    ctx = ctx or {}
    local ok, toks = pcall(tokenize, str)
    local v
    if ok then
        local state = { pos = 1 }
        ok, v = pcall(expression, toks, state, ctx)
        if ok and toks[state.pos] ~= nil then
            ok, v = false, "unexpected " .. toks[state.pos]
        end
    else
        v = toks
    end
    if not ok then
        main.log("error", "Cannot evaluate calc()", "expression", str, "reason", tostring(v))
        return nil
    end
    if v.len then
        return math.floor(v.n + 0.5), true
    end
    return v.n, false
end

-- Evaluates `str` as a length in sp. A plain number is an error.
---@param str string
---@param ctx CalcContext?
---@return integer?
function M.length(str, ctx)
    local n, is_length = M.evaluate(str, ctx)
    if n == nil then
        return nil
    end
    if not is_length and n ~= 0 then
        main.log("error", "calc() must give a length", "expression", str)
        return nil
    end
    return math.floor(n + 0.5)
end

return M
