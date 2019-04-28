--  luxor.lua
--  speedata publisher
--  A crappy non-validating XML parser
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.



local P,S = lpeg.P, lpeg.S

local _string = string
local string = unicode.utf8
local current_element
local decoder
local err = err or print
local filefinder
local parse_xml_file

local html5entities = { apos = "'",
	["Aacute"] = "Á", ["aacute"] = "á",  ["acirc"] = "â",   ["Acirc"] = "Â",   ["acute"] = "´",  ["AElig"] = "Æ",
	["aelig"] = "æ",  ["agrave"] = "à",  ["Agrave"] = "À",  ["alefsym"] = "ℵ", ["Alpha"] = "Α",  ["alpha"] = "α",
	["amp"] = "&",    ["and"] = "∧",     ["ang"] = "∠",     ["Aring"] = "Å",   ["aring"] = "å",  ["asymp"] = "≈",
	["atilde"] = "ã", ["Atilde"] = "Ã",  ["auml"] = "ä",    ["Auml"] = "Ä",    ["bdquo"] = "„",  ["beta"] = "β",
	["Beta"] = "Β",   ["brvbar"] = "¦",  ["bull"] = "•",    ["cap"] = "∩",     ["Ccedil"] = "Ç", ["ccedil"] = "ç",
	["cedil"] = "¸",  ["cent"] = "¢",    ["Chi"] = "Χ",     ["chi"] = "χ",     ["circ"] = "ˆ",   ["clubs"] = "♣",
	["cong"] = "≅",   ["copy"] = "©",    ["crarr"] = "↵",  ["cup"] = "∪",
	["curren"] = "¤", ["dagger"] = "†",  ["Dagger"] = "‡",  ["darr"] = "↓",    ["dArr"] = "⇓",   ["deg"] = "°",
	["delta"] = "δ",  ["Delta"] = "Δ",   ["diams"] = "♦",  ["divide"] = "÷",  ["Eacute"] = "É",  ["eacute"] = "é",
	["ecirc"] = "ê",  ["Ecirc"] = "Ê",   ["egrave"] = "è",  ["Egrave"] = "È",  ["empty"] = "∅",   ["emsp"] = " ",
	["ensp"] = " ",   ["epsilon"] = "ε", ["Epsilon"] = "Ε", ["equiv"] = "≡",   ["eta"] = "η",     ["Eta"] = "Η",
	["ETH"] = "Ð",    ["eth"] = "ð",     ["Euml"] = "Ë",    ["euml"] = "ë",    ["euro"] = "€",    ["exist"] = "∃",
	["fnof"] = "ƒ",   ["forall"] = "∀",  ["frac12"] = "½",  ["frac14"] = "¼",  ["frac34"] = "¾",  ["frasl"] = "⁄",
	["Gamma"] = "Γ",  ["gamma"] = "γ",   ["ge"] = "≥",      ["gt"] = ">",      ["harr"] = "↔",   ["hArr"] = "⇔",
	["hearts"] = "♥",["hellip"] = "…",  ["iacute"] = "í",  ["Iacute"] = "Í",  ["icirc"] = "î",   ["Icirc"] = "Î",
	["iexcl"] = "¡",  ["igrave"] = "ì",  ["Igrave"] = "Ì",  ["image"] = "ℑ",   ["infin"] = "∞",  ["int"] = "∫",
	["Iota"] = "Ι",   ["iota"] = "ι",    ["iquest"] = "¿",  ["isin"] = "∈",    ["Iuml"] = "Ï",    ["iuml"] = "ï",
	["kappa"] = "κ",  ["Kappa"] = "Κ",   ["Lambda"] = "Λ",  ["lambda"] = "λ",  ["lang"] = "〈",   ["laquo"] = "«",
	["larr"] = "←",  ["lArr"] = "⇐",   ["lceil"] = "⌈",    ["ldquo"] = "“",  ["le"] = "≤",      ["lfloor"] = "⌊",
	["lowast"] = "∗", ["loz"] = "◊",     ["lrm"] = "‎",        ["lsaquo"] = "‹", ["lsquo"] = "‘",  ["lt"] = "<",
	["macr"] = "¯",   ["mdash"] = "—",   ["micro"] = "µ",    ["middot"] = "·", ["minus"] = "−",  ["mu"] = "μ",
	["Mu"] = "Μ",     ["nabla"] = "∇",   ["nbsp"] = " ",    ["ndash"] = "–",   ["ne"] = "≠",     ["ni"] = "∋",
	["not"] = "¬",    ["notin"] = "∉",   ["nsub"] = "⊄",    ["Ntilde"] = "Ñ",  ["ntilde"] = "ñ", ["nu"] = "ν",
	["Nu"] = "Ν",     ["Oacute"] = "Ó",  ["oacute"] = "ó",  ["ocirc"] = "ô",   ["Ocirc"] = "Ô",  ["OElig"] = "Œ",
	["oelig"] = "œ",  ["ograve"] = "ò",  ["Ograve"] = "Ò",  ["oline"] = "‾",   ["Omega"] = "Ω",  ["omega"] = "ω",
	["omicron"] = "ο",["Omicron"] = "Ο", ["oplus"] = "⊕",   ["or"] = "∨",      ["ordf"] = "ª",   ["ordm"] = "º",
	["oslash"] = "ø", ["Oslash"] = "Ø",  ["Otilde"] = "Õ",  ["otilde"] = "õ",  ["otimes"] = "⊗", ["Ouml"] = "Ö",
	["ouml"] = "ö",   ["para"] = "¶",    ["part"] = "∂",    ["permil"] = "‰",  ["perp"] = "⊥",   ["phi"] = "φ",
	["Phi"] = "Φ",    ["Pi"] = "Π",      ["pi"] = "π",      ["piv"] = "ϖ",     ["plusmn"] = "±", ["pound"] = "£",
	["prime"] = "′",  ["Prime"] = "″",   ["prod"] = "∏",     ["prop"] = "∝",   ["Psi"] = "Ψ",      ["psi"] = "ψ",
	["quot"] = "\"",  ["radic"] = "√",   ["rang"] = "〉",    ["raquo"] = "»",  ["rarr"] = "→",     ["rArr"] = "⇒",
	["rceil"] = "⌉",  ["rdquo"] = "”",   ["real"] = "ℜ",    ["reg"] = "®",     ["rfloor"] = "⌋",  ["Rho"] = "Ρ",
	["rho"] = "ρ",    ["rlm"] = "‏",      ["rsaquo"] = "›",   ["rsquo"] = "’",  ["sbquo"] = "‚",    ["Scaron"] = "Š",
	["scaron"] = "š", ["sdot"] = "⋅",    ["sect"] = "§",     ["shy"] = "­",     ["sigma"] = "σ",    ["Sigma"] = "Σ",
	["sigmaf"] = "ς", ["sim"] = "∼",     ["spades"] = "♠",  ["sub"] = "⊂",    ["sube"] = "⊆",     ["sum"] = "∑",
	["sup"] = "⊃",    ["sup1"] = "¹",    ["sup2"] = "²",     ["sup3"] = "³",   ["supe"] = "⊇",     ["szlig"] = "ß",
	["Tau"] = "Τ",    ["tau"] = "τ",     ["there4"] = "∴",   ["theta"] = "θ",  ["Theta"] = "Θ",    ["thetasym"] = "ϑ",
	["thinsp"] = " ", ["THORN"] = "Þ",   ["thorn"] = "þ",    ["tilde"] = "˜",   ["times"] = "×",   ["trade"] = "™",
	["Uacute"] = "Ú", ["uacute"] = "ú",  ["uarr"] = "↑",     ["uArr"] = "⇑",    ["Ucirc"] = "Û",   ["ucirc"] = "û",
	["ugrave"] = "ù", ["Ugrave"] = "Ù",  ["uml"] = "¨",      ["upsih"] = "ϒ",   ["upsilon"] = "υ", ["Upsilon"] = "Υ",
	["uuml"] = "ü",   ["Uuml"] = "Ü",    ["weierp"] = "℘",   ["xi"] = "ξ",      ["Xi"] = "Ξ",      ["Yacute"] = "Ý",
	["yacute"] = "ý", ["yen"] = "¥",     ["Yuml"] = "Ÿ",     ["yuml"] = "ÿ",    ["zeta"] = "ζ",    ["Zeta"] = "Ζ",
	["zwj"] = "‍",     ["zwnj"] = "‌",
}

local XMLentities = { gt = ">", lt = "<", amp = "&",  apos = "'", quot = '"' }

local function escape( txt )
	txt = string.gsub(txt,"&(.-);",function (arg)
		if string.find(arg,"^#x") then
			return string.char(tonumber(string.sub(arg,3,-1),16))
		elseif string.find(arg,"^#X") then
			return string.char(tonumber(string.sub(arg,3,-1),16))
		elseif string.find(arg,"^#") then
			return string.char(string.sub(arg,2,-1))
		end
	end)
	return txt
end

local function decode_xmlstring_html(txt)
	txt = escape(txt)
	txt = string.gsub(txt,"&(.-);",html5entities)
	return txt
end

local function decode_xmlstring( txt )
	txt = escape(txt)
	txt = string.gsub(txt,"&(.-);",XMLentities)
	return txt
end


local function _att_value( ... )
	local txt = select(1,...)
	txt = escape(txt)
	return txt
end

local function _attribute( ... )
	local key, value = select(1,...), select(2,...)
	value = decode_xmlstring(value)
	current_element[key] = value
end

local quote = P'"'
local apos  = P"'"
local non_att_quote = P( 1 - quote)^0
local non_att_apos  = P( 1 - apos)^0
local space = S("\09\010\013\032")^1
local name = P(1 - ( space + "=" + "<" + ">"))^1
local att_value = ( quote * lpeg.C(non_att_quote) * quote + apos * lpeg.C(non_att_apos) * apos ) / _att_value
local attrib = (space^-1 * lpeg.C(name) * space^-1 * P"=" * space^-1 * att_value) / _attribute
local attributes = attrib^0 * space^-1

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

local function read_attributes(txt,pos,namespaces)
	current_element = setmetatable({[".__ns"] = namespaces},mt)
	local ns,prefix
	ns = current_element[".__ns"]
	pos = lpeg.match(attributes,txt,pos)
	for key,value in next,current_element,nil do
		if key == "xmlns" then
			ns[""] = value
			current_element[key] = nil
		elseif string.match(key,"^xmlns:(.*)$") then
			prefix = string.match(key,"^xmlns:(.*)")
			ns[prefix] = value
			current_element[key] = nil
		end
	end
	current_element[".__type"]="element"
	return pos, current_element
end

local function parse_xmldecl( txt,pos )
	local newpos = string.find(txt,"<",pos+1)
	return newpos
end
local function parse_doctype(txt,pos)
	local newpos = string.find(txt,"<",pos+1)
	return newpos
end

-- PIs are ignored at the moment
local function parse_pi(txt,pos)
	local _,newpos,contents = string.find(txt,"<%?(.-)%?>%s*",pos)
	return newpos + 1
end

local function parse_endelement( txt,pos )
	local endpos = string.find(txt,">",pos)
	return endpos
end

local function parse_element( txt,pos,namespaces,options )
	namespaces = setmetatable({}, {__index=namespaces})
	options = options or {}
	local second_nextchar
	local contents
	local _,_,nextchar = string.find(txt,"(.)",pos+1)
	if nextchar == "?" then
		-- jump over pi
		pos = parse_pi(txt,pos)
	end
	if nextchar == "/" then -- </endelement
		pos = parse_endelement(txt,pos)
		return nil,pos
		-- end element
	else
		local elt,eltname,prefix,local_name,ns,xinclude
		_,pos,eltname = string.find(txt,"([^/>%s]+)",pos + 1)
		pos, elt = read_attributes(txt,pos + 1,namespaces)
		_,_,prefix,local_name = string.find(eltname,"^(.-):(.*)$")
		ns = elt[".__ns"]
		for k,v in pairs(ns) do
			namespaces[k] = v
		end
		if namespaces[prefix] == "http://www.w3.org/2001/XInclude" and local_name == "include" then
			xinclude = parse_xml_file(elt["href"],options)
		end
		if prefix then
			if namespaces[prefix] then
				elt[".__namespace"] = ns[prefix]
				elt[".__local_name"] = local_name
			else
				print("unknown namespace for prefix " .. prefix)
			end
		else
			elt[".__namespace"] = ns[""]
			elt[".__local_name"] = eltname
		end
		elt[".__name"] = eltname
		-- We're now at the end of attributes. Get a /> or > now
		local rangle,pre_rangle
		_,rangle = string.find(txt,">",pos)
		_,_,pre_rangle = string.find(txt,"(.)",rangle - 1)
		if pre_rangle == "/" then
			if xinclude then
				return xinclude,rangle
			else
				return elt,rangle
			end
		end
		pos = rangle
		-- "Regular" (non-empty) element. Now parse it
		local start, stop, contents
		while true do
			start, stop = string.find(txt,"<",pos)
			contents = string.match(txt,"(.-)<",pos + 1)
			if contents ~= "" then
				if type(elt[#elt]) == "string" then
					elt[#elt] = elt[#elt] .. decoder(contents)
				else
					elt[#elt + 1] = decoder(contents)
				end
			end
			contents, pos = parse_element(txt,start,namespaces,options)
			if contents then
				if type(contents) == "string" then
					if contents ~= "" then
						if type(elt[#elt]) == "string" then
							elt[#elt] = elt[#elt] .. decoder(contents)
						else
							elt[#elt + 1] = decoder(contents)
						end
					end
				else
					elt[#elt + 1] = contents
					contents[".__parent"] = elt
				end
			else
				if xinclude then
					return xinclude,pos
				else
					return elt,pos
				end
			end
		end
	end
end

local function replacecdata( txt )
	return string.gsub(txt,".", function(arg)
		if arg == "<" then return "&lt;"
		elseif arg == "&" then return "&amp;"
		elseif arg == "'" then return "&apos;"
		elseif arg == '"' then return "&quot;"
		end
	end)
end

local function parse_xml(txt,options)
	options = options or {}
	local pos = 1
	local line = 1

	txt = string.gsub(txt,"<!%-%-.-%-%->","")
	txt = string.gsub(txt,"<!%[CDATA%[(.-)%]%]>",replacecdata)

	if string.byte(txt) ~= 60 then
		local tmp
		_,_,tmp = string.find(string.sub(txt,1,5),"(<.*)$")
		if tmp == nil then
			return nil, "Not an XML file"
		end

		_,_,txt = string.find(txt,"(<.*)$",pos)
	end
	if options.htmlentities then
		decoder = decode_xmlstring_html
	else
		decoder = decode_xmlstring
	end

	txt = txt.gsub(txt,"\13\n?","\n")

	if options.ignoreeol == true then
		txt = txt.gsub(txt,"\n%s*"," ")
	else
		txt = txt.gsub(txt,"\13\n?","\n")
	end

	-- If the file has utf8 errors, utf8.match goes into an infinite loop. Therefore
	-- we use the plain old string.match function, which should be good enough for
	-- detecting <%?xml
	if _string.match(txt,"<%?xml",pos) then
		pos = parse_xmldecl(txt,pos)
	end
	if _string.match(txt,"<!DOCTYPE",pos) then
		pos = parse_doctype(txt,pos)
	end

	local ret
	while true do
		ret,pos = parse_element(txt,pos,{},options)
		if type(ret) == "table" then break end
		_,pos = string.find(txt,"<",pos)
	end
	return ret
end

function parse_xml_file( path, options, filefinderfunc)
	options = options or {}
	if filefinderfunc then
		filefinder = filefinderfunc
	end
	if filefinder then
		path = filefinder(path) or path
	end
  local xmlfile = io.open(path,"rb")
  if not xmlfile then
    err("Can't open XML file %q. Abort.",path)
    os.exit(-1)
  end
  local text = xmlfile:read("*all")
  xmlfile:close()
  return parse_xml(text,options)
end


return {
	parse_xml = parse_xml,
	parse_xml_file = parse_xml_file,
}
