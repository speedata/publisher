--  xpath.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.
local string = unicode.utf8

local stack = {}

local M = {}
-- file global:

M.variables = {}
M.functions = {}
M.default_functions = {}
local nilmarker = "\1"

-- We need push/pop to run a sub-xpath during an active xpath session.
-- file global variables suck!
function M.push_state()
    stack[#stack + 1] = {
        tok = M.tok,
        nextpos = M.nextpos
    }
end

function M.pop_state()
    M.tok     = stack[#stack].tok
    M.nextpos = stack[#stack].nextpos
    stack[#stack] = nil
end

function M.is_ifthenelse(dataxml,str,pos,ns)
    local start,stop,num
    start,stop = string.find(str,"^if%s+%(",pos)
    if start then
        local lvl = 1
        local curpos,curstring = stop + 1, ""
        while lvl > 0 do
            curstring = string.sub(str,curpos,curpos)
            if curstring == "(" then
                lvl = lvl + 1
            elseif curstring == ")" then
                lvl = lvl - 1
            end
            curpos = curpos + 1
        end
        local eval = string.sub(str,stop + 1,curpos - 2)
        M.push_state()
        local ok = M.parse_internal(dataxml,eval,ns,1)[1]
        M.pop_state()
        local thenpart, elsepart
        _, _, thenpart, elsepart = string.find(str,"then(.-)else(.*)")
        local ret
        M.push_state()
        if ok then
            ret = M.parse_internal(dataxml,thenpart,ns,1)[1]
        else
            ret = M.parse_internal(dataxml,elsepart,ns,1)[1]
        end
        M.pop_state()
        M.tok = ret

        return true
    end
    return false
end

function M.is_number(str,pos)
    local start,stop,num
    start, stop, num = string.find(str,"^([%-+]?%d+%.?%d*)%s*",pos)
    if num then
        M.nextpos = stop + 1
        M.tok = num
        return true
    end
    return false
end

function M.is_dimension(str,pos)
    if not is_dim then return false end
    local start,stop,num
    start, stop, num = string.find(str,"^([%-+]?%d+%.?%d*%a+)%s*",pos)
    if num then
        M.nextpos = stop + 1
        M.tok = num
        return true
    end
    return false
end


function M.is_attribute(dataxml,str,pos)
    local start,stop,attr
    start,stop,attr = string.find(str,"^@([%w_:-]+)%s*",pos)
    if attr then
        M.nextpos = stop + 1
        M.tok = dataxml[attr]
        if type(M.tok) == "string" and #M.tok == 0 then
            M.tok = nil
        end
        if M.tok == nil then M.tok = nilmarker end
        return true
    end
    local eltname
    start,stop,eltname = string.find(str,"^(%a[%w-/_*]*@[%w-_]+)%s*",pos)
    if start then
        local ret = {}
        local attrname
        M.nextpos = stop + 1
        local tmp = { dataxml }
        local ret

        for part in string.gmatch(eltname,"([^/]+)") do
            ret = {}
            for i=1,#tmp do
                for j=1,#tmp[i] do
                    if part == "*" or part == tmp[i][j][".__local_name"] then
                        if type(tmp[i][j]) == "table" then
                            ret[#ret + 1] = tmp[i][j]
                        end
                    end
                end
            end
            if string.sub(part,1,1) == "@" then
                attrname = string.sub(part,2,-1)
            end
            if #ret ~= 0 then
                tmp = ret
            end
        end
        ret = {}
        for i=1,#tmp do
            if tmp[i][attrname] then
                ret[#ret + 1] = tmp[i][attrname]
            end
        end
        if #ret == 1 then
            M.tok = ret[1]
            return true
        end
        if #ret > 1 then
            M.tok = ret
            return true
        end
        if attrname and attrname ~= "" then
            M.tok = ""
            return true
        end
    end
    return false
end

function M.is_dataexpr( dataxml,str,pos )
    local start,stop,expr
    start,stop,expr = string.find(str,"^(xs:[^%s]*)%s*",pos)
    if expr then
        M.nextpos = stop + 1
        M.tok = expr
        return true
    end
    return false
end

function M.is_variable(str,pos)
    local start,stop,var
    start,stop,var = string.find(str,"^%$([%w_%-]+)%s*",pos)
    if var then
        M.nextpos = stop + 1
        M.tok = M.get_variable(var)
        if M.tok == nil then
            M.err = true
            M.errmsg = string.format("Variable %q undefined",var)
            M.tok = nilmarker
        end
        return true
    end
    return false
end

function M.is_openparen( dataxml,str,pos,ns )
    local start,stop
    start, stop = string.find(str,"^%(%s*",pos)
    if start then
        pos = stop + 1
        local contents = M.parse_internal(dataxml,str,ns,pos)
        M.tok = contents[1]
        return true
    end
    return false
end

function M.is_function(dataxml,str,pos,ns)
    local start,stop,prefix,fname
    start,stop,prefix = string.find(str,"^([^%(]+):",pos)
    if prefix then
        pos = stop + 1
    else
        prefix = ""
    end
    start,stop,fname = string.find(str,"^([^(: %.]+)%(%s*",pos)
    if prefix and fname then
        local x
        if prefix == "" then
            x = M.default_functions
        else
            x = M.functions[ns[prefix]]
        end
        if x and x[fname] then
            local y = x[fname]
            pos = stop + 1
            M.nextpos = pos
            start, stop = string.find(str,"^%s*%)%s*",pos)
            if start then
                M.nextpos = stop + 1
                M.tok = y(dataxml)
                -- After calling the function y, M.nextpos can be different
                -- so we re-assign it
                M.nextpos = stop + 1
            else
                -- function has some xpath contents in it, we need to parse it
                local contents = M.parse_internal(dataxml,str,ns,pos)
                if contents == nil and M.err ~= nil then
                    return nil
                end
                M.tok = y(dataxml,contents)
            end
            if M.tok == nil then M.tok = nilmarker end
            return true
        else
            M.err = true
            M.errmsg = string.format("Function %q with prefix %q unknown", tostring(fname),tostring(prefix))
            return true
        end
    end
    return false
end

function M.is_string(str,pos)
    local start,stop,s
    start, stop, s = string.find(str,"^'([^']*)'%s*",pos)
    if s then
        M.tok = s
        M.nextpos = stop + 1
        return true
    end
    start, stop, s = string.find(str,'^"([^"]*)"%s*',pos)
    if s then
        M.tok = s
        M.nextpos = stop + 1
        return true
    end
    return false
end

function M.check_restriction(dataxml,str,pos)
    local start,stop,subxpath
    start,stop,subxpath = string.find(str,"^%[(.-)%]%s*",pos)
    subxpath = tonumber(subxpath)
    local ret = {}
    if start then
        for i=1,#M.tok do
            if i == subxpath then
                ret[#ret + 1] = M.tok[i]
            end
        end
        M.nextpos = stop + 1
        M.tok = ret
        return
    end
    return
end


function M.is_nodeselector( dataxml,str,pos,ns )
    local start,stop
    -- Just the current node (focus, ".")
    start,stop = string.find(str,"^%.%s*",pos)
    if start then
        M.nextpos = stop + 1
        M.tok = {dataxml}
        return true
    end
    -- All sub nodes
    start,stop = string.find(str,"^%*%s*",pos)
    if start then
        M.nextpos = stop + 1
        local tmp = {}
        for i=1,#dataxml do
            if type(dataxml[i]) == "table" then
                tmp[#tmp + 1] = dataxml[i]
            end
        end
        M.tok = tmp
        M.check_restriction(dataxml,str,M.nextpos)
        return true
    end
    local eltname
    start,stop,eltname = string.find(str,"^(%a[%w-/_*]*)%s*",pos)
    if start then
        local something_found = false
        local ret = {}
        M.nextpos = stop + 1
        local tmp = { dataxml }
        for part in string.gmatch(eltname,"([^/]+)") do
            local ret = {}
            for i=1,#tmp do
                for j=1,#tmp[i] do
                    if part == "*" or part == tmp[i][j][".__local_name"] then
                        if type(tmp[i][j]) == "table" then
                            something_found = true
                            ret[#ret + 1] = tmp[i][j]
                        end
                    end
                end
            end
            tmp = ret
        end
        if something_found then
            M.tok = tmp
        else
            M.tok = nilmarker
        end
        return true
    end
    return false
end


function M.get_operand(dataxml,str,pos,ns)
    local start, stop
    if M.is_dimension(str,pos) then
         return M.tok
    elseif M.is_number(str,pos) then
         return tonumber(M.tok)
    elseif M.is_ifthenelse(dataxml,str,pos,ns) then
        return M.tok
    elseif M.is_attribute(dataxml,str,pos) then
        return M.tok
    elseif M.is_string(str,pos) then
        return M.tok
    elseif M.is_variable(str,pos) then
        return M.tok
    elseif M.is_openparen(dataxml,str,pos,ns) then
        return M.tok
    elseif M.is_function(dataxml,str,pos,ns) then
        return M.tok
    elseif M.is_dataexpr(dataxml,str,pos,ns) then
        return M.tok
    elseif M.is_nodeselector(dataxml,str,pos,ns) then
        return M.tok
    end
end

function M.is_additive_expr(dataxml,str,pos,ns)
    pos = pos or M.nextpos
    local start,stop,op
    start,stop,op = string.find(str,"^([%+%-])%s*",pos)
    if start then
        M.tok = "\1" .. op
        M.nextpos = stop + 1
        return true
    end
end

function M.is_comparison_epxr(dataxml,str,pos,ns)
    pos = pos or M.nextpos
    local start,stop,op
    start,stop,op = string.find(str,"^([><=!]+)%s*",pos)
    if start then
        M.nextpos = stop + 1
        M.tok = "\1" .. op
        return true
    end
    return false
end

function M.is_andor_expr(dataxml,str,pos,ns)
    pos = pos or M.nextpos
    local start,stop,op
    start,stop,op = string.find(str,"^and%s*",pos)
    if start then
        M.tok = "\1and"
        M.nextpos = stop + 1
        return true
    end
    start,stop,op = string.find(str,"^or%s*",pos)
    if start then
        M.tok = "\1or"
        M.nextpos = stop + 1
        return true
    end
    return false
end

function M.is_castable_expr(dataxml,str,pos,ns)
    pos = pos or M.nextpos
    local start,stop,op
    start,stop,op = string.find(str,"^castable as%s*",pos)
    if start then
        M.tok = "castable_as"
        M.nextpos = stop + 1
        return true
    end
    return false
end


function M.is_multiplicative_expr(dataxml,str,pos,ns)
    local start,stop
    pos = pos or M.nextpos
    start,stop = string.find(str,"^%*%s*",pos)
    if start then
        M.tok = "\1*"
        M.nextpos = stop + 1
        return true
    end
    -- "div" | "idiv" | "mod"
    start,stop = string.find(str,"^div%s*",pos)
    if start then
        M.tok = "\1div"
        M.nextpos = stop + 1
        return true
    end
    start,stop = string.find(str,"^mod%s*",pos)
    if start then
        M.tok = "\1mod"
        M.nextpos = stop + 1
        return true
    end
    start,stop = string.find(str,"^idiv%s*",pos)
    if start then
        M.tok = "\1idiv"
        M.nextpos = stop + 1
        return true
    end
end

function M.get_single_expr(dataxml,str,pos,ns)
    local stop
    local stack = {}
    stack[#stack + 1] = M.get_operand(dataxml,str,pos,ns)
    pos = M.nextpos
    while M.is_comparison_epxr(dataxml,str,pos,ns) or
        M.is_andor_expr(dataxml,str,pos,ns) or
        M.is_multiplicative_expr(dataxml,str,pos,ns) or
        M.is_additive_expr(dataxml,str,pos,ns) or
        M.is_castable_expr(dataxml,str,pos,ns) do
        pos = M.nextpos
        local op = M.tok
        stack[#stack + 1] = op
        stack[#stack + 1] = M.get_operand(dataxml,str,pos,ns)
        pos = M.nextpos
    end
    _,stop = string.find(str,"^%s*%)%s*",M.nextpos)
    if stop then
        M.nextpos = stop + 1
        return stack,true
    end
    -- We are now at the end of an expression (either closing paren or end of string)
    return stack,false
end

-- Return a table with one entry for each comma separated expression.
-- Each expression is the stack (table) of operators/operands
function M.get_expr(dataxml,str,ns,pos)
    M.str = str
    local ret = {}
    pos = string.find(str,"%S",pos)
    while true do
        local end_of_expression
        local a = string.find(str,"^%s*%)",pos)
        if a then
            M.err = true
            M.errmsg = "XPath error: looking for an expression but found a closing parentheses"
            return nil
        end

        ret[#ret + 1],end_of_expression = M.get_single_expr(dataxml,str,pos,ns)
        if end_of_expression then break end
        local start,stop = string.find(str,"^%s*,%s*",M.nextpos)
        if not start then break end
        pos = stop + 1
    end
    return ret
end

function M.eval_comparison(first,second,operator)
    -- When comparing a string a and a number, we
    -- turn everything into a number.
    -- IIRC this is in the XPath sepc TODO: check
    -- nilmarker is the code for "nil"
    if first == nilmarker and second ~= nilmarker or first ~= nilmarker and second == nilmarker then
        if operator ~= "\1!=" then
            return false
        else
            return true
        end
    elseif first == nilmarker and second == nilmarker then
        return false
    end

    if type(first) == "number" then
        if type(second) == "table" then
            second = table_textvalue(second)
        end
        second = tonumber(second)
    elseif type(second) == "number" then
        if type(first) == "table" then
            first = table_textvalue(first)
        end
        first = tonumber(first)
    end
    if type(first) == "table" then
        first = table_textvalue(first)
    end
    if type(second) == "table" then
        second = table_textvalue(second)
    end

    if operator == "\1<" then
        return first < second
    elseif operator == "\1>" then
        return first > second
    elseif operator == "\1>=" then
        return first >= second
    elseif operator == "\1<=" then
        return first <= second
    elseif operator == "\1=" then
        return first == second
    elseif operator == "\1!=" then
        return first ~= second
    end
end

local function xml_to_string( self )
    local ret = {}
    for i=1,#self do
      ret[#ret + 1] = tostring(self[i])
    end
    return table.concat(ret)
end

local mt = {
    __tostring = xml_to_string
}


function M.eval_addition(first,second,operator)
    if type(first)=='table' then
        setmetatable(first, mt)
        first = tostring(first)
    end
    if type(second)=='table' then
        setmetatable(second, mt)
        second = tostring(second)
    end
    if type(first)=='string' then
        if is_dim then
            first = tex.sp(first)
        else
            first = tonumber(first)
        end
    end
    if first == nil then
        if err then
            err("The first operand of +/- is not a number. Evaluating to 0 (%q)",M.str)
        end
        return 0
    end
    if type(second)=='string' then
        if is_dim then
            second = tex.sp(second)
        else
            second = tonumber(second)
        end
    end
    if second == nil then
        err("The second operand of +/- is not a number. Evaluating to 0")
        return 0
    end

    if operator == "\1+" then
        return first + second
    elseif operator == "\1-" then
        return first - second
    end
end

function M.eval_castable_as(first,second,operator)
    if second == "xs:double" then
        if tonumber(first) then
            return true
        end
    elseif second == "xs:string" then
        return true
    end
    return false
end


function M.eval_multiplication(first,second,operator)
    if type(first)=='table' then
        err("The first operand of the multiplication is a table. Evaluating to 0")
        return 0
    end
    if type(second)=='table' then
        err("The second operand of the multiplication is a table. Evaluating to 0")
        return 0
    end
    if type(first)=='string' then
        if is_dim then
            first = tex.sp(first)
        else
            first = tonumber(first)
        end
    end
    if first == nil then
        if err then
            err("The first operand of the multiplication is not a number. Evaluating to 0")
        end
        return 0
    end
    if type(second)=='string' then
        if is_dim then
            second = tex.sp(second)
        else
            second = tonumber(second)
        end
    end
    if second == nil then
        err("The second operand of the multiplication is not a number. Evaluating to 0")
        return 0
    end

    if operator == "\1*" then
        return first * second
    elseif operator == "\1mod" then
        return math.fmod(first,second)
    elseif operator == "\1div" then
        return first / second
    elseif operator =="\1idiv" then
        local a = first / second
        if a > 0 then
            return math.floor(a)
        else
            return math.ceil(a)
        end
    end
end

-- Precedence order
-- #   Operator    Associativity
-- 1   , (comma)   left-to-right
-- 3   for, some, every, if    left-to-right
-- 4   or  left-to-right
-- 5   and left-to-right
-- 6   eq, ne, lt, le, gt, ge, =, !=, <, <=, >, >=, is, <<, >> left-to-right
-- 7   to  left-to-right
-- 8   +, -    left-to-right
-- 9   *, div, idiv, mod   left-to-right
-- 10  union, |    left-to-right
-- 11  intersect, except   left-to-right
-- 12  instance of left-to-right
-- 13  treat   left-to-right
-- 14  castable    left-to-right
-- 15  cast    left-to-right
-- 16  -(unary), +(unary)  right-to-left
-- 17  ?, *(OccurrenceIndicator), +(OccurrenceIndicator)   left-to-right
-- 18  /, //   left-to-right
-- 19  [ ] left-to-right

function M.reduce( tab )
    local operator_found = false
    local op,first,second
    local max, i

    -- castable as
    max = #tab
    i = 1
    while i <= max do
        op = tab[i]
        if op == "castable_as" then
            operator_found = true
            second = table.remove(tab,i + 1)
            table.remove(tab,i)
            first  = table.remove(tab,i - 1)
            table.insert(tab,i - 1,M.eval_castable_as(first,second,op))
            i = i - 2
            max = max - 2
        end
    i = i + 1
    end

    max = #tab
    i = 1
    while i <= max do
        op = tab[i]
        if op == "\1*" or op == "\1mod" or op == "\1div" or op == "\1idiv" then
            operator_found = true
            second = table.remove(tab,i + 1)
            table.remove(tab,i)
            first  = table.remove(tab,i - 1)
            table.insert(tab,i - 1,M.eval_multiplication(first,second,op))
            i = i - 2
            max = max - 2
        end
        i = i + 1
    end
    max = #tab
    i = 1
    while i <= max do
        op = tab[i]
        if op == "\1+" or op == "\1-" then
            operator_found = true
            second = table.remove(tab,i + 1)
            table.remove(tab,i)
            first  = table.remove(tab,i - 1)
            table.insert(tab,i - 1,M.eval_addition(first,second,op))
            i = i - 2
            max = max - 2
        end
        i = i + 1
    end

    -- comparison < > <= >= != =
    max = #tab
    i = 2
    while i <= max do
        op = tab[i]
        if op == "\1<" or op == "\1>" or op == "\1<=" or op == "\1>=" or op == "\1!=" or op == "\1=" then
            operator_found = true
            second = table.remove(tab,i + 1)
            table.remove(tab,i)
            first  = table.remove(tab,i - 1)
            table.insert(tab,i - 1,M.eval_comparison(first,second,op))
            i = i - 2
            max = max - 2
        end
        i = i + 1
    end

    -- "and"
    max = #tab
    i = 1
    while i <= max do
        op = tab[i]
        if op == "\1and" then
            operator_found = true
            second = table.remove(tab,i + 1)
            table.remove(tab,i)
            first  = table.remove(tab,i - 1)
            table.insert(tab,i - 1, first and second)
            i = i - 2
            max = max - 2
        end
        i = i + 1
    end


    -- "or"
    max = #tab
    i = 1
    while i <= max do
        op = tab[i]
        if op == "\1or" then
            operator_found = true
            second = table.remove(tab,i + 1)
            table.remove(tab,i)
            first  = table.remove(tab,i - 1)
            table.insert(tab,i - 1, first or second)
            i = i - 2
            max = max - 2
        end
        i = i + 1
    end

    if #tab == 1 then return false end
    return operator_found
end

function M.eval_argument( tab )
    if #tab == 1 then
        if tab[1] == nilmarker then
            return nil
        else
            return tab[1]
        end
    end
    while #tab > 1 do
        if not M.reduce(tab) then
            break
        end
    end
    return tab
end

function M.parse_internal(dataxml,str,ns,pos)
    local r = M.get_expr(dataxml,str,ns,pos)
    if not r then
        return nil
    end
    local ret = {}
    for i=1,#r do
        if type(r[i]) == "table" then
            local tmp = M.eval_argument(r[i])
            if type(tmp) == "table" then
                for j=1,#tmp do
                    ret[#ret + 1] = tmp[j]
                end
            else
                ret[#ret + 1] = tmp
            end
        else
            ret[#ret + 1] = r[i]
        end
    end
    return ret
end

-- return err,result
function M.parse_raw( dataxml,str,ns )
    M.err = false
    M.nextpos = nil
    local r = M.parse_internal(dataxml,str,ns,1)
    if M.err then
        return false,M.errmsg
    else
        return true, r
    end
end


function M.parse(dataxml,str,ns)
    M.nextpos = nil
    M.err = false
    local r = M.parse_internal(dataxml,str,ns,1)
    if #r == 1 then
        return r[1]
    elseif #r == 0 then
        return ""
    end
    return r
end

function M.textvalue_raw(ok,value)
    if not ok then
        return ""
    end
    if #value == 1 and type(value[1]) == "boolean" then return value[1] end
    if type(value) == "string" then return value end
    local ret = {}
    for i=1,#value do
        ret[#ret + 1] = value[i]
    end
    return table.concat(ret)
end

function M.textvalue(arg)
    if type(arg) == "boolean" then
        return arg
    end
    return tostring(arg)
end
-- ------

function M.set_variable(var,value)
    M.variables[var] = value
end

function M.get_variable(var)
    local v
    if var == "_mode" then
        local tmp = {}
        for k,_ in pairs(publisher.modes) do
            tmp[#tmp + 1] = k
        end
        v = table.concat( tmp, "," )
    else
        v = M.variables[var]
    end
    return v
end

function M.register_function(ns,fname,fun)
    if ns == "" then
        M.default_functions[fname] = fun
        return
    end
    M.functions[ns] = M.functions[ns] or {}
    M.functions[ns][fname] = fun
end


-- ------------------------------------------------------------
-- -- Standard XPath functions
-- ------------------------------------------------------------

M.default_functions.abs = function(dataxml,arg)
    local tmp = math.abs(tonumber(arg[1]))
    return tmp
end

M.default_functions.position = function()
    local pos = publisher.xpath.get_variable("__position")
    return pos
end

M.default_functions.ceiling = function( dataxml,arg )
    return math.ceil(arg[1])
end

M.default_functions.concat = function(dataxml, arg )
    local ret = ""
    for i=1,#arg do
        ret = ret .. tostring(arg[i])
    end
    return ret
end

M.default_functions.count = function(dataxml, arg )
    local tocount = arg
    return #tocount
end

M.default_functions.empty = function( dataxml,arg )
    if arg and arg[1] ~= nil and arg[1] ~= "" then
        return false
    end
    return true
end

M.default_functions.floor = function(dataxml, arg)
    return math.floor(arg[1])
end

-- Return number of records with the same name
M.default_functions.last = function( dataxml )
    if dataxml[".__context"] then
        return #dataxml[".__context"]
    end
    local recordname    = dataxml[".__local_name"]
    local parentelement = dataxml[".__parent"]
    if not parentelement then
        return 1
    end
    local count = 0
    for i=1,#parentelement do
        if type(parentelement[i]) == 'table' and parentelement[i][".__local_name"] == recordname then
            count = count + 1
        end
    end
    return count
end

M.default_functions.max = function(dataxml,arg)
    local max = tonumber(arg[1])
    if not max then
        if err then
            err("First argument in max() is not a number, returning 0")
        end
        return 0
    end
    for i=2,#arg do
        if tonumber(arg[i]) and tonumber(arg[i]) > max then
            max = tonumber(arg[i])
        end
    end
    return max
end

M.default_functions.min = function(dataxml,arg)
    local min = tonumber(arg[1])
    for i=2,#arg do
        if tonumber(arg[i]) < min then
            min = arg[i]
        end
    end
    return min
end


M.default_functions["normalize-space"] = function(dataxml, arg )
    local str = arg[1]
    if type(str) == "string" then
        return str:gsub("^%s*(.-)%s*$","%1"):gsub("[%s\n]+"," ")
    end
end

M.default_functions.node = function(dataxml)
    local tab={}
    for i=1,#dataxml do
        tab[#tab + 1] = dataxml[i]
    end
    return tab
end

M.default_functions["string"] = function(dataxml,arg)
    local ret
    if type(arg)=="table" then
        ret = {}
        for i=1,#arg do
            ret[#ret + 1] = tostring(arg[i])
        end
        ret = table.concat(ret)
    elseif arg == "\1" then -- nil value
        ret = ""
    elseif type(arg) == "string" then
        ret = arg
    elseif type(arg) == "boolean" then
        ret = tostring(arg)
    elseif arg == nil then
        ret = ""
    else
        warning("Unknown type in XPath-function 'string()': %s",type(arg))
        ret = tostring(arg)
    end
    return ret
end

M.default_functions["number"] = function(dataxml,arg)
    local ret
    if type(arg)=="table" then
        if #arg > 1 then
            err("A sequence of more than one item is not allowed as the first argument of fn:number()")
            return
        end
        setmetatable(arg, mt)
        ret = tostring(arg)
    elseif arg == "\1" then -- nil value
        ret = ""
    elseif type(arg) == "string" then
        ret = arg
    elseif type(arg) == "boolean" then
        if arg then ret = 1 else ret = 0 end
    elseif arg == nil then
        ret = ""
    else
        warning("Unknown type in XPath-function 'number()': %s",type(arg))
        ret = tostring(arg)
    end
    return tonumber(ret)
end

-- Tokenize is the first function we ask 'splib' for help
M.default_functions["tokenize"] = function(dataxml,arg)
    if arg[1] == nil or arg[2] == nil then
        err("tokenize: one of the arguments is empty")
        return ""
    end
    return publisher.splib.tokenize(dataxml,arg)
end

M.default_functions["round"] = function( dataxml,arg )
    local arg1 = arg[1]
    local arg2 = arg[2] or 0
    return math.round(arg1,arg2)
end

M.default_functions["replace"] = function(dataxml,arg)
    if arg[1] == nil or arg[2] == nil or arg[3] == nil then
        warning("replace: one of the arguments is empty")
        return ""
    end
    return publisher.splib.replace(arg[1],arg[2],arg[3])
end

M.default_functions["contains"] = function(dataxml,arg)
    if arg[1] == nil or arg[2] == nil  then
        -- warning("contains(): one of the arguments is empty")
        return false
    end
    if type(arg[1]) ~= "string" or type(arg[2]) ~= "string"  then
        err("contains(): one of the arguments is not a string")
        return false
    end
    local ret = publisher.splib.contains(arg[1],arg[2])
    return ret == "true"
end

M.default_functions["upper-case"] = function(dataxml,arg)
    local str = arg and arg[1]
    if str then
        return string.upper(tostring(arg[1]))
    else
        warning("No string given for upper-case()")
        return ""
    end
end

M.default_functions["lower-case"] = function(dataxml,arg)
    local str = arg and arg[1]
    if str then
        return string.lower(tostring(arg[1]))
    else
        warning("No string given for lower-case()")
        return ""
    end
end

M.default_functions["true"] = function()
    return true
end

M.default_functions["false"] = function()
    return false
end

M.default_functions["not"] = function (dataxml,arg)
    return not arg[1]
end

M.default_functions["string-join"] = function (dataxml,arg)
    ret = {}
    for i=1,#arg - 1 do
        ret[#ret + 1] = tostring(arg[i])
    end
    return table.concat(ret,arg[#arg])
end

M.default_functions["string-length"] = function (dataxml,arg)
    return string.len(arg[1])
end

M.default_functions["substring"] = function (dataxml,arg)
    local input = tostring(arg[1])
    local start = tonumber(arg[2])
    local length
    if tonumber(arg[3]) then
        length = arg[2] + tonumber(arg[3]) - 1
    end
    return string.sub(input,start,length)
end

M.default_functions["local-name"] = function (dataxml,arg)
    return dataxml[".__local_name"]
end

return {
   get_variable      = M.get_variable,
   parse             = M.parse,
   parse_raw         = M.parse_raw,
   register_function = M.register_function,
   set_variable      = M.set_variable,
   textvalue         = M.textvalue,
   textvalue_raw     = M.textvalue_raw,
   push_state        = M.push_state,
   pop_state         = M.pop_state,
}

-- Todo:
-- boolean()
-- round(), ceiling(), floor(), and round-half-to-even()
-- sum(), avg(),