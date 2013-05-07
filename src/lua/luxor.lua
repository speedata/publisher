--  luxor.lua
--  speedata publisher
--
--  Copyright 2013 Patrick Gundlach.
--  See file COPYING in the root directory for license info.


-- TODO:
--  * xinclude


local P,S = lpeg.P, lpeg.S

local string = unicode.utf8
local current_element
local decoder

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

local function decode_xmlstring_html(txt)
	return string.gsub(txt,"&(.-);",function(arg)
		if html5entities[arg] then return html5entities[arg]
		elseif string.find(arg,"^#x") then
			return string.char(tonumber(string.sub(arg,3,-1),16))
		elseif string.find(arg,"^#") then
			return string.char(string.sub(arg,2,-1))
		end
	end)
end

local function decode_xmlstring( txt )
	return string.gsub(txt,"&(.-);",function (arg)
		if arg == "lt" then
			return "<"
		elseif arg == "gt" then
			return ">"
		elseif arg == "amp" then
			return "&"
		elseif arg == "quot" then
			return '"'
		elseif arg == "apos" then
			return "'"
		elseif string.find(arg,"^#x") then
			return string.char(tonumber(string.sub(arg,3,-1),16))
		elseif string.find(arg,"^#") then
			return string.char(string.sub(arg,2,-1))
		end
	end)
end


local function _att_value( ... )
	return decoder(select(1,...))
end

local function _attribute( ... )
	current_element[select(1,...)] = select(2,...)
end

local quote = P'"'
local apos  = P"'"
local non_att_quote = P( 1 - quote)^0
local non_att_apos  = P( 1 - apos)^0
local space = S("\09\010\013\032")^1
local name = P(1 - ( space + "="))^1
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
	current_element = setmetatable({[".__ns"] = {}},mt)
	local ns,prefix
	ns = current_element[".__ns"]
	for key,value in next,namespaces,nil do
		ns[key] = value
	end
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
local function parse_comment( txt,pos )
	local _,newpos,contents = string.find(txt,"%-(.-)%-%->",pos+3)
	-- return {[".__type"]="comment",contents},newpos
	return "",newpos
end
local function parse_pi(txt,pos)
	local _,newpos,contents = string.find(txt,"<%?(.-)%?>",pos)
	return {[".__type"]="pi", contents },newpos
end
local function parse_cdata( txt,pos )
	local _,newpos,contents = string.find(txt,"<!%[CDATA%[(.-)%]%]>",pos)
	return contents,newpos
end

local function parse_endelement( txt,pos )
	local endpos = string.find(txt,">",pos)
	return endpos
end

local function parse_element( txt,pos,namespaces )
	local second_nextchar
	local contents
	local _,_,nextchar = string.find(txt,"(.)",pos+1)
	if nextchar == "!" then
		_,_,second_nextchar = string.find(txt,"(.)",pos+2)
		if second_nextchar=="-" then
			-- exclam hyphen -> comment
			return parse_comment(txt,pos)
		else
			return parse_cdata(txt,pos)
		end
	elseif nextchar == "/" then -- </endelement
		pos = parse_endelement(txt,pos)
		return nil,pos
		-- end element
	elseif nextchar == "?" then
		return parse_pi(txt,pos)
	else
		local elt,eltname,namespace,local_name,ns
		_,pos,eltname = string.find(txt,"([^/>%s]+)",pos + 1)
		pos, elt = read_attributes(txt,pos + 1,namespaces)
		_,_,namespace,local_name = string.find(eltname,"^(.-):(.*)$")
		ns = elt[".__ns"]
		if namespace then
			if ns and ns[namespace] then
				elt[".__namespace"] = ns[namespace]
				elt[".__local_name"] = local_name
			else
				print("unknown namespace!!!")
			end
		else
			if ns then
				elt[".__namespace"] = ns[""]
			end
			elt[".__local_name"] = eltname
		end
		elt[".__name"] = eltname
		-- We're now at the end of attributes. Get a /> or > now
		local rangle,pre_rangle
		_,rangle = string.find(txt,">",pos)
		_,_,pre_rangle = string.find(txt,"(.)",rangle - 1)
		if pre_rangle == "/" then
			return elt,rangle
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
			contents, pos = parse_element(txt,start,elt[".__ns"])
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
				return elt,pos
			end
		end
	end
end

local function parse_xml(txt,options)
	options = options or {}
	local pos = 1
	local line = 1
	if string.byte(txt) ~= 60 then
		_,_,txt = string.find(txt,"(<.*)$",pos)
	end
	if options.htmlentities then
		decoder = decode_xmlstring_html
	else
		decoder = decode_xmlstring
	end
	txt = txt.gsub(txt,"\13\n?","\n")
	if string.match(txt,"<%?xml",pos) then
		pos = parse_xmldecl(txt,pos)
	end
	local ret
	while true do
		ret,pos = parse_element(txt,pos,{})
		if type(ret) == "table" then break end
		_,pos = string.find(txt,"<",pos)
	end
	return ret
end

local function parse_xml_file( path, options)
	options = options or {}
  local xmlfile = io.open(path,"r")
  if not xmlfile then
    err("Can't open XML file. Abort.")
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
