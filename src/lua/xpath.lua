--
--  xpath.lua
--  speedata publisher
--
--  Copyright 2010-2013 Patrick Gundlach.
--  See file COPYING in the root directory for license info.
--


module(...,package.seeall)

local C,P,R,S,V = lpeg.C,lpeg.P,lpeg.R,lpeg.S,lpeg.V
local dataxml
local namespaces

local char =
  P("\009") +
  P("\010") +
  P("\013") +
  R("\032\127") +
  R("\194\223") * R("\128\191") +
  P("\224") * R("\160\191") * R("\128\191") +
  R("\225\236") * R("\128\191") * R("\128\191") +
  P("\237") * R("\128\159") * R("\128\191") +
  P("\238") * R("\128\191") * R("\128\191") +
  P("\239") * ( R("\128\190") * R("\128\191") + P("\191") * R("\128\190") ) +
  P("\240") * ( P("\144") * R("\129\191") * R("\128\191") + R("\145\191") * R("\128\191") * R("\128\191") ) +
  R("\241\243") * R("\128\191") * R("\128\191") * R("\128\191") +
  P("\244") * ( R("\128\142") * R("\128\191") * R("\128\191") + P("143") * R("\128\144") * R("\128\191") )

local digit = R("\048\057") +
  P("\217") * R("\160\169") +
  P("\219") * R("\176\185") +
  P("\224") * (
    P("\165") * R("\166\175") +
    P("\167") * R("\166\175") +
    P("\169") * R("\166\175") +
    P("\171") * R("\166\175") +
    P("\173") * R("\166\175") +
    P("\175") * R("\167\175") +
    P("\177") * R("\166\175") +
    P("\179") * R("\166\175") +
    P("\181") * R("\166\175") +
    P("\185") * R("\144\153") +
    P("\187") * R("\144\153") +
    P("\188") * R("\160\169") )

local basechar =
  R("\065\090") +
  R("\097\122") +
  P("\195") * ( R("\128\150") + R("\152\182") + R("\184\191") ) +
  P("\196") * ( R("\128\177") + R("\180\190") ) +
  P("\197") * ( R("\129\136") + R("\138\190") ) +
  P("\198") * R("\128\191") +
  P("\199") * ( R("\128\131") + R("\141\176") + R("\180\181") + R("\186\191") ) +
  P("\200") * R("\128\151") +
  P("\201") * R("\144\191") +
  P("\202") * ( R("\128\168") + R("\187\191") ) +
  P("\203") * R("\129\129") +
  P("\206") * ( P("\134") + R("\136\138") + P("\140") + R("\142\161") + R("\163\191") )  +
  P("\207") * ( R("\128\142") + R("\144\150") + P("\154") + P("\156") + P("\158") + P("\160") + R("\162\179") ) +
  P("\208") * ( R("\129\140") + R("\142\191") ) +
  P("\209") * ( R("\128\143") + R("\145\156") + R("\158\191") ) +
  P("\210") * ( R("\128\129") + R("\144\191") ) +
  P("\211") * ( R("\128\132") + R("\135\136") + R("\139\140") + R("\144\171") + R("\174\181") + R("\184\185") ) +
  P("\212") *   R("\177\191") +
  P("\213") * ( R("\128\150") + P("\153") + R("\161\191") ) +
  P("\214") *   R("\128\134") +
  P("\215") * ( R("\144\170") + R("\176\178") ) +
  P("\216") *   R("\161\186") +
  P("\217") * ( R("\129\138") + R("\177\191") )+
  P("\218") * ( R("\128\183") + R("\186\190")) +
  P("\219") * ( R("\128\142") + R("\144\147") + P("\149") + R("\165\166") ) +
  P("\224") * (
    P("\164") * ( R("\133\185") + P("\189") ) +
    P("\165") *   R("\152\161") +
    P("\166") * ( R("\133\140") + R("\143\144") + R("\147\168") + R("\170\176") + P("\178") + R("\182\185")) +
    P("\167") * ( R("\156\157") + R("\159\161") + R("\176\177") ) +
    P("\168") * ( R("\133\138") + R("\143\144") + R("\147\168") + R("\170\176") + R("\178\179") + R("\181\182") + R("\184\185") ) +
    P("\169") * ( R("\153\156") + P("\158") + R("\178\180") ) +
    P("\170") * ( R("\133\139") + P("\141") + R("\143\145") + R("\147\168") + R("\170\176") + R("\178\179") + R("\181\185") + P("\189") ) +
    P("\171") *   P("\160") +
    P("\172") * ( R("\133\140") + R("\143\144") + R("\147\168") + R("\170\176") + R("\178\179") + R("\182\185") + P("\189") ) +
    P("\173") * ( R("\156\157") + R("\159\161") ) +
    P("\174") * ( R("\133\138") + R("\142\144") + R("\146\149") + R("\153\154") + P("\156") + R("\158\159") + R("\163\164") + R("\168\170") + R("\174\181") + R("\183\185") ) +
    P("\176") * ( R("\133\140") + R("\142\144") + R("\146\168") + R("\170\179") + R("\181\185") ) +
    P("\177") *   R("\160\161") +
    P("\178") * ( R("\133\140") + R("\142\144") + R("\146\168") + R("\170\179") + R("\181\185") ) +
    P("\179") * ( P("\158") + R("\160\161") ) +
    P("\180") * ( R("\133\140") + P("\180") * R("\142\144") + R("\146\168") + R("\170\185") ) +
    P("\181") *   R("\160\161") +
    P("\184") * ( R("\129\174") + P("\176") + R("\178\179") ) +
    P("\185") *   R("\128\133") +
    P("\186") * ( R("\129\130") + P("\132") + R("\135\136") + P("\138") + P("\141") + R("\148\151") + R("\153\159") + R("\161\163") + P("\165") + P("\167") + R("\170\171") + R("\173\174") + P("\176") + R("\178\179") + P("\189") ) +
    P("\187") *   R("\128\132") +
    P("\189") * ( R("\128\135") + R("\137\169") ) ) +
  P("\225") * (
    P("\130") *   R("\160\191") +
    P("\131") * ( R("\128\133") + R("\144\182") ) +
    P("\132") * ( P("\128") + R("\130\131") + R("\133\135") + P("\137") + R("\139\140") + R("\142\146") + P("\188") + P("\190") ) +
    P("\133") * ( P("\128") + P("\140") + P("\142") + P("\144") + R("\148\149") + P("\153") + R("\159\161") + P("\163") + P("\165") + P("\167") + P("\169") + R("\173\174") + R("\178\179") + P("\181") ) +
    P("\134") * ( P("\158") + P("\168") + P("\171") + R("\174\175") + R("\183\184") + P("\186") + R("\188\191") ) +
    P("\135") * ( R("\128\130") + P("\171") + P("\176") + P("\185") ) +
    P("\184") * R("\128\191") +
    P("\186") * R("\128\155") +
    P("\186") * R("\160\191") +
    P("\187") * R("\128\185") +
    P("\188") * ( R("\128\149") + R("\152\157") + R("\160\191") ) +
    P("\189") * ( R("\128\133") + R("\136\141") + R("\144\151") + P("\153") + P("\155") + P("\157") + R("\159\189")) +
    P("\190") * ( R("\128\180") + R("\182\188") + P("\190") ) +
    P("\191") * ( R("\130\132") + R("\134\140") + R("\144\147") + R("\150\155") + R("\160\172") + R("\178\180") + R("\182\188")) ) +
  P("\226") * (
    P("\132") * ( P("\166") + R("\170\171") + P("\174") ) +
    P("\134") * R("\128\130")  ) +
  P("\227") * (
    P("\129") * R("\129\191") +
    P("\130") * ( R("\128\148") + R("\161\191") ) +
    P("\131") * R("\128\186") +
    P("\132") * R("\133\172") ) +
  P("\234") * R("\176\191") * R("\128\191") +
  R("\235\236") * R("\128\191") * R("\128\191") +
  P("237") * ( R("\128\157") * R("\128\191") + P("158") * R("\128\163") )

local ideographic =
  P("\227") * P("\128") * ( P("\135") + R("\161\169") ) +
  P("\228") * P("\184\191") * R("\128\191") +
  R("\229\232") * R("\128\191") * R("\128\191") +
  P("\233") * ( R("\128\189") * R("\128\191") + P("\190") * R("\128\165") )

local combining_char =
  P("\204") * R("\128\191") +
  P("\205") * ( R("\128\133") + R("\160\161") ) +
  P("\210") * R("\131\134") +
  P("\214") * ( R("\145\161") + R("\163\185") + R("\187\189") + P("\191") ) +
  P("\215") * ( R("\129\130") + P("\132") ) +
  P("\217") * ( R("\139\146") + P("\176") ) +
  P("\219") * ( R("\150\156") + R("\157\159") + R("\160\164") + R("\167\168") + R("\170\173") ) +
  P("\224") * (
    P("\164") * ( R("\129\131") + P("\188") +  R("\190\191") ) +
    P("\165") * ( R("\128\140") + P("\141") + R("\145\148") + R("\162\163") ) +
    P("\166") * ( R("\129\131") + P("\188") + P("\190") + P("\191") ) +
    P("\167") * ( R("\128\132") + R("\135\136") + R("\139\141") + P("\151") + R("\162\163") ) +
    P("\168") * ( P("\130") + P("\188") + P("\190") + P("\191") ) +
    P("\169") * ( R("\128\130") + R("\135\136") + R("\139\141") + R("\176\177") ) +
    P("\170") * ( R("\129\131") + P("\188") +  R("\190\191") ) +
    P("\171") * ( R("\128\133") + R("\135\137") + R("\139\141") ) +
    P("\172") * ( R("\129\131") + P("\188") + R("\190\191") ) +
    P("\173") * ( R("\128\131") + R("\135\136") + R("\139\141") + R("\150\151")) +
    P("\174") * ( R("\130\131") + R("\190\191") ) +
    P("\175") * ( R("\128\130") + R("\134\136") + R("\138\141") +P("\151") ) +
    P("\176") * ( R("\129\131") + R("\190\191") ) +
    P("\177") * ( R("\128\132") + R("\134\136") + R("\138\141") + R("\149\150") ) +
    P("\178") * ( R("\130\131") + R("\190\191") ) +
    P("\179") * ( R("\128\132") + R("\134\136") + R("\138\141") + R("\149\150") ) +
    P("\180") * ( R("\130\131") + R("\190\191") ) +
    P("\181") * ( R("\128\131") + R("\134\136") + R("\138\141") + P("\151") ) +
    P("\184") * ( P("\177") + R("\180\186") ) +
    P("\185") *   R("\135\142") +
    P("\186") * ( P("\177") + R("\180\185") + R("\187\188")) +
    P("\187") *   R("\136\141") +
    P("\188") * ( R("\152\153") + P("\181") + P("\183") + P("\185") +P("\190") + P("\191") ) +
    P("\189") *   R("\177\191") +
    P("\190") * ( R("\128\132") + R("\134\139") + R("\144\149") + P("\151") +R("\153\173") + R("\177\183") + P("\185")) ) +
  P("\226") * (
    P("\131") * ( R("\144\156") + P("\161") ) ) +
  P("\227") * (
    P("\128") * R("\170\175") +
    P("\130") * ( P("\153") + P("\154") ))

local extender =
  P("\194") * P("\183") +
  P("\203") * ( P("\144") + P("\145") ) +
  P("\206") * P("\135") +
  P("\217") * P("\128") +
  P("\224") *  ( P("\185") + P("\187")  ) * P("\134") +
  P("\227") * (
    P("\128") * ( P("\133") + R("\177\181") ) +
    P("\130") * R("\157\158") +
    P("\131") * R("\188\190"))

local dot        = P"."
local minus      = P"-"
local underscore = P"_"
local colon      = P":"

function textvalue( tab )
  if type(tab)=="table" then
    if #tab == 0 then
      return ""
    elseif #tab > 1 then
      err("Sequence must not contain more than one item")
    end
    tab = tab[1]
  end
  local ret = {}
  if tab==nil then return nil end
  if type(tab)=="boolean" then
    if tab==true then
      return true
    else
      return false
    end
  end
  if type(tab)=="string" then return tab end
  if type(tab)=="number" then return tostring(tab) end
  -- The first argument can be a function (XPath function)
  if type(tab[1])=="function" then
    table.insert(tab,2,dataxml)
    local ok,value = pcall(unpack(tab))
    return tostring(value)
  end
  if #tab == 1 then
    if type(tab[1])=="number" then return tab[1] end
  end
  for i,v in ipairs(tab) do
    if type(v)=="string" then
      ret[#ret + 1]=v
    end
  end
  return table.concat(ret)
end


local function get_value( v )
  if type(v)=="string" then return v end
  if type(v)=="number" then return v end
  if type(v)=="function" then return v()  end
  if type(v)=="table" then return v end
  if type(v)=="boolean" then return v end
  if type(v)=="nil" then return nil end
  w(debug.traceback())
  assert(false,string.format("get_value, type(v)==%s, v=%s",type(v),tostring(v)))
end

local function get_number_value( v )
  -- w("get_number_value, type=%s",type(v))
  if type(v)=="number" then return v end
  if type(v)=="function" then return tonumber(v())  end
  if type(v)=="table"    then return get_number_value(v[1]) end
  if type(v)=="string"   then return tonumber(v) end
  w(debug.traceback())
  assert(false,string.format("get_number_value, type(v)==%s, v=%s",type(v),tostring(v)))
end

local function _add( ... )
  -- w("_add: %d",select('#',...))
  -- printtable("add",{...})
  if select('#',...) == 1 then return ... end
  local ret = get_number_value(select(1,...))
  local i = 2
  while i <= select('#',...) do
    local operator = select(i,...)
    -- print(operator)
    if operator == "+" then ret = ret + get_number_value(select(i + 1,...)) end
    if operator == "-" then ret = ret - get_number_value(select(i + 1,...)) end
    i = i + 2
  end
  return function() return ret end
end

local function _mult( ... )
  -- w("_mult: %d",select('#',...))
  -- printtable('mult',{...})
  -- printtable("dataxml",dataxml)
  -- ... hat 3, 5, 7, .. Argumente: 'a' '*' 'b' 'div' 'c' 'idiv' 'd'
  if select('#',...) == 1 then return ... end
  local ret = get_number_value(select(1,...))
  local i = 2
  while i <= select('#',...) do
    local operator = select(i,...)
    -- print(operator)
    if operator == "*"   then ret = ret * get_number_value(select(i + 1,...)) end
    if operator == "div" then ret = ret / get_number_value(select(i + 1,...)) end
    if operator == "mod" then ret = math.fmod(ret,get_number_value(select(i + 1,...))) end
    i = i + 2
  end
  return function() return ret end
end

local function _variable( ... )
  -- printtable("variable",{...})
  -- local varname = ...
  return publisher.variablen[select(1,...)]
end

local function _mkfunc( ... )
  -- w("_mkfunc: (%d) %s",select('#',...),table.concat({...}," - "))
  local tmp = select(1,...)
  return function() return tmp end
end

local function _verbose( ... )
  w("_verbose, %s\n",select('#',...))
  for i,v in ipairs({...}) do
    print(i,v)
  end
  return ...
end

local function _curr_data_tbl( ... )
  -- w("_curr_data_tbl, %d",select('#',...))
  return { dataxml }
end

local function _paren( ... )
  -- printtable("_paren",{...})
  -- print(select(1,...)())
  return select(1,...)
end

local function _nodetest( ... )
  -- printtable("_nodetest",{...})
  if select(1,...)=="@" then return dataxml[select(2,...)] end
  if not dataxml then
    warning("Empty sequence")
    return nil
  end
  local ret = {}
  if select(1,...)=="*" then
    for i,v in ipairs(dataxml) do
      if type(v)=="table" then
        ret[#ret + 1] = v
      end
    end
    return ret
  end
  for i,v in ipairs(dataxml) do
    if type(v)=="table" and v[".__name"] == ... then
      ret[#ret + 1] = v
    end
  end
  return ret
end

local function _funcall( ... )
  local name=select(1,...)
  local fun
  local prefix,rest = string.match(name,"^(.*):(.*)$")
  rest = rest or name
  if prefix then
    -- a special publisher xpath function
    local ns = namespaces[prefix]
    local lang
    if not ns then
      err("Cannot resolve namespace for prefix %q in function %q\nPlease use urn:speedata:2009/publisher/functions/en (or .../de)",prefix or "?",name or "?")
      lang="en"
    else
      lang = string.gsub(ns,"urn:speedata:2009/publisher/functions/","")
      if not publisher.sd_xpath_funktionen[lang] then
        err("Language %q unknown!",lang)
      end
    end
    fun = publisher.sd_xpath_funktionen[lang][rest:gsub("-","_")]
  else
    -- regular XPath function
    name = name:gsub("-","_")
    fun = publisher.orig_xpath_funktionen[name]
  end
  if fun==nil then
    err("Unknown function %q", name or "???")
    return nil
  end
  local ret = fun(dataxml, unpack({...},2))
  return ret
end

local function _comparison( ... )
  if select('#',...) == 1 then
   return ...
  end
  if not (select(1,...) and select(2,...) and select(3,...)) then
    return false
  end
  local value1, value2 = select(1,...), select(3,...)
  local operator = select(2,...)
  local ret
  -- See http://www.w3.org/TR/xpath/#booleans
  if type(value1) == "number" or type(value2) == "number" then
    value1 = get_number_value(value1)
    value2 = get_number_value(value2)
  else
    value1 = get_value(value1)
    value2 = get_value(value2)
  end
  if operator == "<" then
    ret = value1 < value2
  elseif operator == "<=" then
    ret = value1 <= value2
  elseif operator == "!=" then
    ret = value1 ~= value2
  elseif operator == "=" then
    ret = value1 == value2
  elseif operator == ">" then
    ret = value1 > value2
  elseif operator == ">=" then
    ret = value1 >= value2
  else
    assert(false,"unknown operator %s",operator)
  end
  return ret
end

local function _unaryexpr( ... )
  printtable("foo",{...})
  return get_number_value(select(1,...))
end

local function _comp( ... )
  printtable("comp",{...})
  return ...
end

local function _orexpr( ... )
   -- printtable("orexpr",{...})
  for i=1,select("#",...) do
    if select(i,...) == true then return true end
    if select(i,...) ~= false then return get_value(select(i,...)) end
  end
  return false
end

local function _andexpr( ... )
  -- printtable("_andexpr",{...})
  local x
  for i=1,select("#",...) do
    x = select(i,...)
    if type(x) =="boolean" then
      if x==false then return false end
    else
      return x
    end
  end
  return true
end


function parse( data_xml, str, ns )

  if str==nil then return nil end

  -- shortcut for variables "$foo" / huge speed gain
  local cap = string.match(str,"^%s*%$([^%s]+)%s*$")
  if cap then
    return publisher.variablen[cap]
  end

  dataxml    = data_xml
  namespaces = ns
  local space = S("\010\013\032")^1
  local xpath = P{
    "xpath",
    -- [1]
    xpath = V"Expr",
    -- [2]
    Expr = V"ExprSingle" * (P"," * V"ExprSingle")^0,
    -- [3]     ExprSingle    ::=     ForExpr | QuantifiedExpr | IfExpr | OrExpr
    ExprSingle = (V"OrExpr"),
    -- [8]     OrExpr    ::=     AndExpr ( "or" AndExpr )*
    OrExpr = V"AndExpr" * (space^0 * P"or" * space^0 * V"AndExpr")^0 / _orexpr,
    -- [9]     AndExpr     ::=     ComparisonExpr ( "and" ComparisonExpr )*
    AndExpr = V"ComparisonExpr" *(space^0 * P"and" * space^0 * V"ComparisonExpr")^0 / _andexpr,
    -- [10]      ComparisonExpr    ::=     RangeExpr ( (ValueComp | GeneralComp | NodeComp) RangeExpr )?
    ComparisonExpr = V"RangeExpr" *  ( space^0 *  V"GeneralComp" * space^0 *  V"RangeExpr"  )^-1 / _comparison,
    -- [11]
    RangeExpr = V"AdditiveExpr" * (P"to" * V"AdditiveExpr")^-1,
    -- [12]
    AdditiveExpr = V"MultiplicativeExpr" * ( space^0 * C( P"+" + P"-") * space^0 * V"MultiplicativeExpr")^0 / _add,
    -- [13]      MultiplicativeExpr    ::=     UnionExpr ( ("*" | "div" | "idiv" | "mod") UnionExpr )*
    MultiplicativeExpr = V"StepExpr" *  (space^0 * C(P"*" + P"div" + P"idiv" + P"mod") * space^0 * V"StepExpr" )^0 / _mult,
    -- [14]      UnionExpr     ::=     IntersectExceptExpr ( ("union" | "|") IntersectExceptExpr )*
    -- [15]      IntersectExceptExpr     ::=     InstanceofExpr ( ("intersect" | "except") InstanceofExpr )*
    -- [16]      InstanceofExpr    ::=     TreatExpr ( "instance" "of" SequenceType )?
    -- [17]      TreatExpr     ::=     CastableExpr ( "treat" "as" SequenceType )?
    -- [18]      CastableExpr    ::=     CastExpr ( "castable" "as" SingleType )?
    -- [19]      CastExpr    ::=     UnaryExpr ( "cast" "as" SingleType )?
    -- [20]      UnaryExpr     ::=    ("-" | "+")* ValueExpr
-- UnaryExpr =  space^0 * C(  ( P"-" + P"+")^0 *  V"ValueExpr" )  / _unaryexpr ,
    -- [21]      ValueExpr     ::=     PathExpr
    ValueExpr = V"StepExpr",
    -- [22]
    GeneralComp = C( P"!=" + P"=" + P"<=" + P"<" + P">=" + P">"),
    -- [25]      PathExpr    ::=    ("/" RelativePathExpr?) | ("//" RelativePathExpr) | RelativePathExpr /* xgs: leading-lone-slash */
    -- [26]      RelativePathExpr    ::=     StepExpr (("/" | "//") StepExpr)*

    -- [27]
    StepExpr = V"FilterExpr" + V"AxisStep", --  step is a part of a path expression that generates a sequence of items and then filters the sequence by zero or more predicates.
    -- [28]      AxisStep    ::=    (ReverseStep | ForwardStep) PredicateList
    AxisStep = V"ForwardStep",
    -- [29]      ForwardStep     ::=    (ForwardAxis NodeTest) | AbbrevForwardStep
    ForwardStep = (V"NodeTest" + V"AbbrevForwardStep") / _nodetest,
    -- [31]
    AbbrevForwardStep = space^0 * C( P"@" )^-1 * V"NodeTest",
    -- [35]      NodeTest    ::=     KindTest | NameTest
    NodeTest = space^0 * V"NameTest" * space^0, 
    -- [36]
    NameTest = V"QName" + V"Wildcard",
    -- [37]      Wildcard    ::=    "*" | (NCName ":" "*") | ("*" ":" NCName) /* ws: explicit */
    Wildcard = P"*",
    -- [38]      FilterExpr    ::=     PrimaryExpr PredicateList
    FilterExpr = V"PrimaryExpr",
    -- [41]
    PrimaryExpr = V"Literal" + V"VarRef" + V"ParenthesizedExpr" + V"ContextItemExpr" +  V"FunctionCall",
    -- [42]
    Literal = space^0 * ( V"NumericLiteral" + V"StringLiteral") * space^0 ,
    -- [43] -- gedreht gegenüber dem ursprünglichen wegen Priorisierung
    NumericLiteral = (  C(V"DoubleLiteral") + C(V"DecimalLiteral") + C(V"IntegerLiteral"))/ tonumber,
    -- [44]
    VarRef = space^0 * P"$" * V"VarName" * space^0 / _variable,
    -- [45]
    VarName = V"QName",
    -- [47]
    ContextItemExpr = space^0 * P"." * space^0 / _curr_data_tbl,
    -- [46]
    ParenthesizedExpr = space^0 * P"(" *  space^0 * ( V"Expr")^-1  * space^0 * P")" * space^0  / _paren ,
    -- [48]
    FunctionCall = space^0 *  V"QName" * P"(" * space^0 * (V"ExprSingle" * (P"," * V"ExprSingle")^0 )^-1 * space^0 * P")"/ _funcall,
    -- [71]
    IntegerLiteral = V"Digits",
    -- [72]
    DecimalLiteral = ( P"." * V"Digits") + ( V"Digits" * P"." * R("09")^0 ),
    -- [73]
    DoubleLiteral = (( P"." * V"Digits")  + (V"Digits" * ( P"." * R("09")^0)^-1 )) * S("eE") * S("+-")^-1 * V"Digits",
    -- [74]
    StringLiteral = P'"' * C( (V"EscapeQuot" + ( 1 - P'"') )^0 ) * P'"' + P"'" * C(  ( V"EscapeApos" + (1-P"'"))^0 )* P"'",
    -- [75]
    EscapeQuot = P'""',
    -- [76]
    EscapeApos = P"''",
    -- [78]
    QName =  C((  basechar + ideographic + digit + dot + minus + underscore + combining_char + extender   ) * (  basechar + ideographic + digit + dot + minus + colon + underscore + combining_char + extender  )^0 ),
    -- [81]
    Digits = R("09")^1,
    
  }
  local ret = lpeg.match(xpath,str)
  if type(ret)=="function" then return ret() end
  return ret
end



-- [4]     ForExpr     ::=     SimpleForClause "return" ExprSingle
-- [5]     SimpleForClause     ::=    "for" "$" VarName "in" ExprSingle ("," "$" VarName "in" ExprSingle)*
-- [6]     QuantifiedExpr    ::=    ("some" | "every") "$" VarName "in" ExprSingle ("," "$" VarName "in" ExprSingle)* "satisfies" ExprSingle
-- [7]     IfExpr    ::=    "if" "(" Expr ")" "then" ExprSingle "else" ExprSingle
-- [14]      UnionExpr     ::=     IntersectExceptExpr ( ("union" | "|") IntersectExceptExpr )*
-- [15]      IntersectExceptExpr     ::=     InstanceofExpr ( ("intersect" | "except") InstanceofExpr )*
-- [16]      InstanceofExpr    ::=     TreatExpr ( "instance" "of" SequenceType )?
-- [17]      TreatExpr     ::=     CastableExpr ( "treat" "as" SequenceType )?
-- [18]      CastableExpr    ::=     CastExpr ( "castable" "as" SingleType )?
-- [19]      CastExpr    ::=     UnaryExpr ( "cast" "as" SingleType )?
-- [20]      UnaryExpr     ::=    ("-" | "+")* ValueExpr
-- [21]      ValueExpr     ::=     PathExpr
-- [23]      ValueComp     ::=    "eq" | "ne" | "lt" | "le" | "gt" | "ge"
-- [24]      NodeComp    ::=    "is" | "<<" | ">>"
-- [25]      PathExpr    ::=    ("/" RelativePathExpr?) | ("//" RelativePathExpr) | RelativePathExpr /* xgs: leading-lone-slash */
-- [26]      RelativePathExpr    ::=     StepExpr (("/" | "//") StepExpr)*
-- [30]      ForwardAxis     ::=    ("child" "::") | ("descendant" "::") | ("attribute" "::") | ("self" "::") | ("descendant-or-self" "::")| ("following-sibling" "::") | ("following" "::") | ("namespace" "::") 
-- [32]      ReverseStep     ::=    (ReverseAxis NodeTest) | AbbrevReverseStep
-- [33]      ReverseAxis     ::=    ("parent" "::") | ("ancestor" "::") | ("preceding-sibling" "::") | ("preceding" "::") | ("ancestor-or-self" "::")
-- [34]      AbbrevReverseStep     ::=    ".."
-- [36]      NameTest    ::=     QName | Wildcard
-- [37]      Wildcard    ::=    "*" | (NCName ":" "*") | ("*" ":" NCName) /* ws: explicit */
-- [38]      FilterExpr    ::=     PrimaryExpr PredicateList
-- [39]      PredicateList     ::=     Predicate*
-- [40]      Predicate     ::=    "[" Expr "]"
-- [48]      FunctionCall    ::=     QName "(" (ExprSingle ("," ExprSingle)*)? ")"  /* xgs: reserved-function-names */
-- /* gn: parens */
-- [49]      SingleType    ::=     AtomicType "?"?
-- [50]      SequenceType    ::=    ("empty-sequence" "(" ")") | (ItemType OccurrenceIndicator?)
-- [51]      OccurrenceIndicator     ::=    "?" | "*" | "+" /* xgs: occurrence-indicators */
-- [52]      ItemType    ::=     KindTest | ("item" "(" ")") | AtomicType
-- [53]      AtomicType    ::=     QName
-- [54]      KindTest    ::=     DocumentTest | ElementTest  | AttributeTest  | SchemaElementTest  | SchemaAttributeTest  | PITest  | CommentTest  | TextTest  | AnyKindTest
-- [55]      AnyKindTest     ::=    "node" "(" ")"
-- [56]      DocumentTest    ::=    "document-node" "(" (ElementTest | SchemaElementTest)? ")"
-- [57]      TextTest    ::=    "text" "(" ")"
-- [58]      CommentTest     ::=    "comment" "(" ")"
-- [59]      PITest    ::=    "processing-instruction" "(" (NCName | StringLiteral)? ")"
-- [60]      AttributeTest     ::=    "attribute" "(" (AttribNameOrWildcard ("," TypeName)?)? ")"
-- [61]      AttribNameOrWildcard    ::=     AttributeName | "*"
-- [62]      SchemaAttributeTest     ::=    "schema-attribute" "(" AttributeDeclaration ")"
-- [63]      AttributeDeclaration    ::=     AttributeName
-- [64]      ElementTest     ::=    "element" "(" (ElementNameOrWildcard ("," TypeName "?"?)?)? ")"
-- [65]      ElementNameOrWildcard     ::=     ElementName | "*"
-- [66]      SchemaElementTest     ::=    "schema-element" "(" ElementDeclaration ")"
-- [67]      ElementDeclaration    ::=     ElementName
-- [68]      AttributeName     ::=     QName
-- [69]      ElementName     ::=     QName
-- [70]      TypeName    ::=     QName
-- [77]      Comment     ::=    "(:" (CommentContents | Comment)* ":)"  /* ws: explicit */
-- /* gn: comments */
-- [78]     QName    ::=     [http://www.w3.org/TR/REC-xml-names/#NT-QName] Names /* xgs: xml-version */
-- [79]     NCName     ::=     [http://www.w3.org/TR/REC-xml-names/#NT-NCName] Names  /* xgs: xml-version */
-- [80]     Char     ::=     [http://www.w3.org/TR/REC-xml#NT-Char] XML /* xgs: xml-version */
-- The following symbols are used only in the definition of terminal symbols; they are not terminal symbols in the grammar of A.1 EBNF .
-- [82]      CommentContents     ::=    (Char+ - (Char* ('(:' | ':)') Char*))


-- http://www.w3.org/TR/xpath20/