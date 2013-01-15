-- xml parser


local require,lpeg,io,select,string,type,tonumber,tostring,setmetatable=require,lpeg,io,select,string,type,tonumber,tostring,setmetatable
local err = err
local table = table
local w = w
local printtable=printtable
module(...)

bit = require('bit')

local C,P,R,S,V = lpeg.C,lpeg.P,lpeg.R,lpeg.S,lpeg.V
local lt = P"<"
local gt = P">"
local amp = P"&"
local ampgt = P"&>"
local questionmarkgt = P"?>"
local Quote = P('"')
local quote = P("'")
local lts = P"</"
local sgt = P"/>"
local cdataend = P"]]>"
local space = S("\09\010\013\032")^1
local non_att = P( 1 - ( lt + amp + quote)  )
local non_Att = P( 1 - ( lt + amp + Quote)  )
local dot,minus,underscore,colon= P"." ,P"-", P"_", P":"
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

local char_without_minus = char - minus
local char_without_piend = char - ampgt
local text = char^0
--*
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

local chardata = 	P(1 - ( lt + amp ) )
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


-- Return the textvalue of an element (tostring(xml))
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


-- If it's a namespace, extract it
local function _attribute(...)
  local attr = select(1,...)
  if string.sub(attr,1,5) == "xmlns" then
    local prefix = string.match(select(1,...),"^xmlns:?(.*)")
    if prefix then
      namespaces[prefix] = select(2,...)
    end
  end
  return ...
end

local function c_return_self(...)
  return ...
end
local function c_stag(...)
  local ret = { [".__name"]=select(1,...)}
  for i=2,select('#',...),2 do 
    ret[select(i,...)] = select(i+1,...)
  end
  return ret
end
local function c_attvalue(...)
  local ret = tostring(...):gsub("&(%w-);",{ apos = "'", lt = "<",quot = '"' })
  return ret
end
local function c_empty_elem_tag(...)
  local ret = {[".__name"]= select(1,...)}
  for i=2, select('#', ...),2 do
    ret[select(i,...)] = select(i+1,...)
  end
  return ret
end
local function c_element(...)
  local number_of_args=select('#',...)
  local ret = select(1,...)
  if number_of_args > 1 then
    for i=2,select('#',...) do
      if type(select(i,...)) == "string" and type(select(i-1,...)) == "string" then
        ret[#ret] = ret[#ret] .. select(i,...)
      else
        ret[#ret + 1] = select(i,...)
      end
    end
  end
  setmetatable(ret,mt)
  return ret
end
local function c_gobble(...)
end
local function c_charref(...)
  local str = string.sub(...,3,-2)
  local ret = ""
  local num = nil
  if str:byte(1) == 120 then
    -- hex
    num = tonumber(str:sub(2,-1),16)
  else
    num = tonumber(str:sub(1,-1))
  end
  if num < 0x80 then
      ret = ret .. string.char(num)
  elseif num < 0x800 then
      ret = ret .. string.char ( bit.bor (0xC0, bit.brshift(num, 6 ) ) )
      ret = ret .. string.char ( bit.bor (0x80, bit.band(num, 0x3F ) ) )
  elseif num < 0x10000 then
      ret = ret .. string.char( bit.bor (0xE0, bit.brshift(num, 12 ) ) )
      ret = ret .. string.char( bit.bor (0x80, bit.band (bit.brshift(num, 6 ), 0x3F ) ) )
      ret = ret .. string.char( bit.bor (0x80, bit.band (num                 , 0x3F ) ) )
  else
      ret = ret .. string.char( bit.bor (0xF0, bit.brshift(num, 18 ) ) )
      ret = ret .. string.char( bit.bor (0x80, bit.band (bit.brshift(num, 12), 0x3F ) ) )
      ret = ret .. string.char( bit.bor (0x80, bit.band (bit.brshift(num, 6 ), 0x3F ) ) )
      ret = ret .. string.char( bit.bor (0x80, bit.band (num                 , 0x3F ) ) )
  end
  return ret
end
local function c_entityref(...)
  local ret = ...
  if ...=="apos" then
    ret = "'"
  elseif ...=="lt" then
    ret = "<"
  elseif ...=="gt" then
    ret = ">"
  elseif ...=="quot" then
    ret = '"'
  elseif ...=="amp" then
    ret = "&"
  end
  return ret
end

xml = P {
   "document",
-- 1
   document = (V"prolog" * V"element" *  ( V"Misc" )^0) / c_return_self,
-- 2
   Char = char, -- / _BaseChar, 
-- 4
   NameChar =( V"Letter" + V"Digit" + dot + minus + underscore + colon  + V"CombiningChar" + V"Extender"), -- / _namechar, 
-- 5
   Name =  ( V"Letter" + underscore + colon) * (V"NameChar")^0/ c_return_self,
-- 10 * 
   AttValue = (	Quote * C( ( non_Att + V"Reference" )^0 ) * Quote + quote * C( ( non_att + V"Reference" )^0 ) * quote ) /c_attvalue,
-- 14
   CharData = (chardata)^0 / c_return_self,
-- 15
   Comment = "<!--" * (  char_without_minus  + ( minus * char_without_minus)  )^0  *  "-->",
-- 16 ?
   PI = ( P'<?' * V"PITarget" * space * (V"Char" - questionmarkgt )^0   * questionmarkgt ),
-- 17
   PITarget = V"Name",
-- 18
   CDSect = V"CDStart" * V"CData" * V"CDEnd",
-- 19
   CDStart = P"<![CDATA[",
-- [20]    CData    ::=    (Char* - (Char* ']]>' Char*))
-- 20
   CData = ( (char - cdataend)^0 )/ c_return_self,
-- 21
   CDEnd = cdataend,
-- 22 - 	XMLDecl? Misc* (doctypedecl Misc*)?
   prolog = V"XMLDecl"^-1 *  ( V"Misc" )^0 ,
-- 23
   XMLDecl = '<?xml' * V"VersionInfo" * (V"EncodingDecl")^-1 *  V"SDDecl"^-1 * space^-1 * questionmarkgt,
-- 24
   VersionInfo = space * P'version' * V"Eq" * ( quote * V"VersionNum" * quote + Quote *  V"VersionNum" * Quote )  ,
-- 25
   Eq = (space)^0 * P("=") * (space)^0,
-- 26
   VersionNum = ( (R("az","AZ","09") + S"_.:" ) + minus )^1,
-- 27
   Misc = V"Comment" + V"PI" + space ,
-- 32
   SDDecl = space * P'standalone' * V"Eq" * ( (quote * (P'yes' + P'no' ) * quote ) + (Quote * (P'yes' + P'no' ) * Quote ) ), 
-- 39
   element = (V"EmptyElemTag" + V"STag" * V"content" * V"ETag" ) / c_element,
-- 40
   STag = ( lt * V"Name" * ( space * V"Attribute" )^0 * (space)^0 * gt) / c_stag,
-- 41
   Attribute = ( V"Name" * V"Eq" * V"AttValue" )  / _attribute,
-- 42
   ETag = lts * V"Name" * (space)^0 * gt / c_gobble,
-- 43 *
-- [43]    content    ::=    CharData? ((element | Reference | CDSect | PI | Comment) CharData?)*  /* */
   content = ( (V"CharData")^-1 * ( (V"element" + V"Reference" + V"CDSect" + V"PI" + V"Comment") * (V"CharData")^-1 )^0  ) / c_return_self,
-- 44
   EmptyElemTag	= ( lt * V"Name" * (space * V"Attribute")^0 * space^-1 * sgt ) /c_empty_elem_tag,
-- 66
   CharRef = ( (P'&#' * R("09")^1  * ';') + ( '&#x' * R("09","af","AF")^1  * P';')  ) / c_charref,
-- 67
   Reference = V"EntityRef" + V"CharRef",
-- 68
   EntityRef = '&' * V"Name" * ';' / c_entityref,
-- 69  	PEReference	   ::=   	'%' Name ';'
-- 80
   EncodingDecl =  space * 'encoding' * V"Eq" * ( Quote * V"EncName" * Quote + quote * V"EncName" * quote  ) ,
-- 81
   EncName = R("AZ","az") * ( ( R("AZ","az","09") + S"._") + "-" )^0, 
-- 84 
   Letter = V"BaseChar" + V"Ideographic",
-- 85
   BaseChar =   basechar,
-- 86
   Ideographic = ideographic, 
-- 87
   CombiningChar = combining_char,
-- 88
   Digit = digit,
-- 89
   Extender = extender,
}

function parse_xml(txt)
  namespaces = {}
  if string.byte(txt) ~= 60 then
  -- Skip everything until the first appearance of < (either an XML instruction or a start-tag)
  -- This is probably a bom
    local count = string.find(txt,"<",1,true)
    txt = string.sub(txt,count,-1)
  end

  local root = lpeg.match(xml,txt)
  if not root then
    err("Can't parse XML file.")
    err("%q",txt)
    return nil
  end
  root["__namespace"] = namespaces
  return root
end

