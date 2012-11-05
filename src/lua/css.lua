file_start("css.lua")

require("lpeg")

local R,P,V,S = lpeg.R,lpeg.P,lpeg.V,lpeg.S
local char =
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


local function _property( ... )
	-- printtable("property",{...})
	return select(1,...)
end

local function _ruleset( ... )
	-- printtable("ruleset",{...})
	local ret = {}
	for i=2,( select("#",...) + 1 ) / 2 do
		ret[select(i * 2 - 2,...)] = select(i * 2 - 1,...)
	end
	-- printtable("ruleset",ret)
	return select(1,...), ret
end

function _returnfirst( ... )
	return select(1,...)
end

function _expr( ... )
	-- expr can have many terms, we just concat them
	-- printtable("expr",{...})
	return table.concat( {...} )
end

local function _declaration(...)
	-- printtable("declaration",{...})
	return ...
end

local function _term(...)
	-- printtable("term",{...})
	return select(1,...)
end

local function _stylesheet( ... )
	local ret = {}
	for i=1,select('#',...) / 2 do
		ret[select(i*2 - 1,...)] = select(i * 2,...)
	end
	-- printtable("stylesheet",ret)
	return ret
end

css = {}

css.parse = function ( filename )
	local path = kpse.find_file(filename)
	if not path then
		err("CSS: cannot find filename %q.",filename or "--")
		return
	end
	log("Loading CSS %q",path)
	local cssio = io.open(path,"r")
	local csstext = cssio:read("*all")
	cssio:close()
	local space = S("\09\010\013\032")^1
	local ident = char * ( char + digit )^0
	local nmchar = char + digit
	local hash = P"#" * nmchar^1
	local cdo = P"<!--"
	local cdc = P"-->"
	-- w(csstext)

	local css_grammar = P{
    	"Stylesheet",
	    --  stylesheet : [ CHARSET_SYM STRING ';' ]?
	    --              [S|CDO|CDC]* [ import [ CDO S* | CDC S* ]* ]* 
	    --              [ [ ruleset | media | page ] [ CDO S* | CDC S* ]* ]*
	    Stylesheet = ( V"Ruleset" )^0  / _stylesheet,
		-- import : IMPORT_SYM S* [STRING|URI] S* media_list? ';' S*
		-- media :  MEDIA_SYM S* media_list '{' S* ruleset* '}' S*
		-- media_list : medium [ COMMA S* medium]*
		-- medium : IDENT S*
		-- page : PAGE_SYM S* pseudo_page? '{' S* declaration? [ ';' S* declaration? ]* '}' S*
		-- pseudo_page ':' IDENT S*
	    -- operator : '/' S* | ',' S*
	    Operator = P"/" * space^0 + P"," * space^0,
	    -- combinator : '+' S* | '>' S*
	    -- unary_operator '-' | '+'
		-- property : IDENT S*
		Property = ident * space^0 / _property,
  		-- ruleset:  selector [ ',' S* selector ]* '{' S* declaration? [ ';' S* declaration? ]* '}' S*
	    Ruleset = V"Selector" * space^0 * (P"," * space^0 * V"Selector" )^-1 * P"{" * space^0 * (V"Declaration")^-1 * ( P";" * space^0 * (V"Declaration")^-1 )^0 *  P"}" * space^0 / _ruleset, 
	    -- selector : simple_selector [ combinator selector | S+ [ combinator? selector ]? ]?
    	Selector = V"SimpleSelector" / _returnfirst,
		-- simple_selector : ( element_name [ HASH | class | attrib | pseudo ]*  ) | [ HASH | class | attrib | pseudo ]+
      	SimpleSelector =  V"ElementName" * (hash + V"Class")^0 + ( hash + V"Class")^1   / _returnfirst,
		-- class  : '.' IDENT
		Class = P"." * ident,
		-- element_name : IDENT | '*'
      	ElementName = ident + P"*" / _returnfirst,
	    -- attrib : '[' S* IDENT S* [ [ '=' | INCLUDES | DASHMATCH ] S* [ IDENT | STRING ] S* ]? ']'
	    -- pseudo : ':' [ IDENT | FUNCTION S* [IDENT S*]? ')' ]
	    -- declaration : property ':' S* expr prio?
		Declaration = V"Property" * P':' * space^0 * V"Expr" / _declaration,
	-- prio : IMPORTANT_SYM S*
	-- expr : term [ operator? term ]*
		Expr = V"Term" * ( V"Operator"^-1 * V"Term" )^0 / _expr,
	-- term : unary_operator? [ NUMBER S* | PERCENTAGE S* | LENGTH S* | EMS S* | EXS S* | ANGLE S* |  TIME S* | FREQ S* ] | STRING S* | IDENT S* | URI S* | hexcolor | function
		Term = ident * space^0 / _term,
	--   function  : FUNCTION S* expr ')' S*
    --   /*
    --    * There is a constraint on the color that it must
    --    * have either 3 or 6 hex-digits (i.e., [0-9a-fA-F])
    --    * after the "#"; e.g., "#000" is OK, but "#abcd" is not.
    --    */
    --   hexcolor
    --     : HASH S*
    --     ;

	}
	local ret = lpeg.match(css_grammar,csstext)
	return ret
end


file_end("css.lua")
return css


--  stylesheet
--     : [ CHARSET_SYM STRING ';' ]?
--       [S|CDO|CDC]* [ import [ CDO S* | CDC S* ]* ]*
--       [ [ ruleset | media | page ] [ CDO S* | CDC S* ]* ]*
--     ;
--   import
--     : IMPORT_SYM S*
--       [STRING|URI] S* media_list? ';' S*
--     ;
--   media
--     : MEDIA_SYM S* media_list '{' S* ruleset* '}' S*
--     ;
-- media_list
--     : medium [ COMMA S* medium]*
--     ;
-- medium
--     : IDENT S*
--     ; 
-- page
--     : PAGE_SYM S* pseudo_page?
--       '{' S* declaration? [ ';' S* declaration? ]* '}' S*
--     ;
-- pseudo_page
--    : ':' IDENT S*
--    ;
-- operator
--   : '/' S* | ',' S*
--   ;
-- combinator
--   : '+' S*
--   | '>' S*
--   ;
-- unary_operator
--   : '-' | '+'
--   ;
-- property
--   : IDENT S*
--   ;
-- ruleset
--   : selector [ ',' S* selector ]*
--     '{' S* declaration? [ ';' S* declaration? ]* '}' S*
--   ;
-- selector
--   : simple_selector [ combinator selector | S+ [ combinator? selector ]? ]?
--   ;
-- simple_selector
--   : element_name [ HASH | class | attrib | pseudo ]*
--   | [ HASH | class | attrib | pseudo ]+
--   ;
-- class
--   : '.' IDENT
--   ;
-- element_name
--   : IDENT | '*'
--   ;
-- attrib
--   : '[' S* IDENT S* [ [ '=' | INCLUDES | DASHMATCH ] S*
--     [ IDENT | STRING ] S* ]? ']'
--   ;
-- pseudo
--   : ':' [ IDENT | FUNCTION S* [IDENT S*]? ')' ]
--   ;
-- declaration
--   : property ':' S* expr prio?
--   ;
-- prio
--   : IMPORTANT_SYM S*
--   ;
-- expr
--   : term [ operator? term ]*
--   ;
-- term
--     : unary_operator?
--       [ NUMBER S* | PERCENTAGE S* | LENGTH S* | EMS S* | EXS S* | ANGLE S* | TIME S* | FREQ S* ]  | STRING S* | IDENT S* | URI S* | hexcolor | function
--     ;
--   function
--     : FUNCTION S* expr ')' S*
--     ;
--   /*
--    * There is a constraint on the color that it must
--    * have either 3 or 6 hex-digits (i.e., [0-9a-fA-F])
--    * after the "#"; e.g., "#000" is OK, but "#abcd" is not.
--    */
--   hexcolor
--     : HASH S*
--     ;

