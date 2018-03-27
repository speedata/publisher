--- This file contains the code for generating barcodes
--
--  barcodes.lua
--  speedata publisher
--
--  Copyright 2012 Patrick Gundlach.
--  See file COPYING in the root directory for license info.


local function scalebox(scalefactor,box)
    local pdf_save, pdf_restore, pdf_setmatrix
    pdf_save = node.new("whatsit","pdf_save")
    pdf_restore = node.new("whatsit","pdf_restore")
    pdf_setmatrix = node.new("whatsit","pdf_setmatrix")
    scalefactor = math.round(scalefactor,3)
    pdf_setmatrix.data=string.format("%.4g 0 0 %.4g",scalefactor,scalefactor)

    local hbox = node.hpack(box)
    hbox = node.insert_before(hbox,hbox,pdf_setmatrix)
    hbox = node.insert_before(hbox,pdf_setmatrix,pdf_save)

    hbox = node.hpack(hbox)
    hbox.height = box.height * scalefactor
    hbox.width = box.width * scalefactor
    hbox.depth = 0
    node.insert_after(hbox,node.tail(hbox),pdf_restore)

    local newbox = node.vpack(hbox)
    return newbox
end


local function mkpattern( str )
  -- These are the digits represented by the bars. 3211 for example means a gap of three units,
  -- a bar two units wide, another gap of width one and a bar of width one.
  local digits_t = {"3211","2221","2122","1411",
             "1132","1231","1114","1312","1213","3112"}

  -- The first digit is encoded by the appearance of the next six digits. A value of 1 means
  -- that the generated gaps/bars are to be inverted.
  local mirror_t = {"------","--1-11","--11-1","--111-","-1--11",
                    "-11--1","-111--","-1-1-1","-1-11-","-11-1-"}

  -- Convert the digit string into an array.
  local number = {}
  for i=1,string.len(str) do
    number[i] = tonumber(string.sub(str,i,i))
  end

  -- The first digit in a barcode determines how the next six digit patterns are displayed.
  local prefix = table.remove(number,1)
  local mirror_str = mirror_t[prefix + 1]

  -- The variable pattern will hold the constructed pattern. We start with a gap that is wide enough
  -- for the first digit in the barcode and the special code 111, here written as 010 as a signal to
  -- create longer rules later.
  local pattern = "8010"
  local digits_str

  for i=1,#number do
    digits_str = digits_t[number[i] + 1]
    if string.sub(mirror_str,i,i) == "1" then
      digits_str = string.reverse(digits_str)
    end
    pattern = pattern .. digits_str
    -- The middle two bars.
    if i==6 then pattern = pattern .. "10101" end
  end
  -- Append the right 111 pattern as above.
  return pattern .. "010"
end

local function split_number( str )
  return string.match(str,"(%d)(%d%d%d%d%d%d)(%d%d%d%d%d%d)")
end

local function add_to_nodelist( head,entry )
  if head then
    -- Add the entry to the end of the nodelist
    -- and adjust prev/next pointers.
    local tail = node.tail(head)
    tail.next = entry
    entry.prev = tail
  else
    -- No nodelist yet, so just return the new entry.
    head = entry
  end
  return head
end

local function mkrule( wd,ht,dp )
  local r = node.new("rule")
  r.width = wd
  r.height = ht
  r.depth = dp
  return r
end

local function mkkern( wd )
  local k = node.new("kern")
  k.kern = wd
  return k
end

local function mkglyph( char,fontnumber )
  local g = node.new("glyph")
  g.char = string.byte(char)
  g.font = fontnumber
  return g
end


local function calculate_unit(digit_zero)
  -- The relative widths of a digit represented by the
  -- barcode add up to 7.
  return digit_zero.width / 7
end

local function pattern_to_wd_dp( pattern,pos,overshoot)
  local wd,dp
  wd = tonumber(string.sub(pattern,pos,pos))
  if wd == 0 then
    dp = overshoot
    wd = 1
  else
    dp = "0mm"
  end
  return wd,dp
end


local function ean13(width,height,fontfamily,digits,showtext,overshoot_factor)
    if #digits ~= 13 and showtext then
        err("Not enough numbers for EAN13 code _and_ text")
        showtext = false
    end
	local fontnumber  = publisher.fonts.lookup_fontfamily_number_instance[fontfamily].normal
  local digit_zero  = font.fonts[fontnumber].characters[48]
	local unit = calculate_unit(digit_zero)
	local scalefactor
	if width then -- we need to scale the resulting barcode
		scalefactor =  width / ( unit * 105 )
	else
		scalefactor = 1
	end

	local barlength,overshoot
	if showtext then
		overshoot_factor = overshoot_factor or 50
        if height then
        	barlength = height / scalefactor
        else
        	barlength = math.abs(tex.sp("2cm") / scalefactor )
        end
    	local zerosize = 466387
    	overshoot = zerosize * overshoot_factor / 100
    	barlength = barlength - zerosize - 0.1 * overshoot
	else
		overshoot_factor = overshoot_factor or 10
        if height then
        	barlength = height
      	else
      		barlength = math.abs(tex.sp("2cm") / scalefactor )
        end
        overshoot = 0.5 * barlength * overshoot_factor / 100
        barlength = barlength - overshoot
	end

	local nodelist
  	local pattern = mkpattern(digits)
    local wd,dp
    for i=1,string.len(pattern) do
      wd,dp = pattern_to_wd_dp(pattern,i,overshoot)
      if i % 2 == 0 then
        nodelist = add_to_nodelist(nodelist,mkrule(wd * unit,barlength,tex.sp(dp)))
      else
        nodelist = add_to_nodelist(nodelist,mkkern(wd * unit))
      end
    end
    -- barcode_top will become the vbox
    local barcode_top = node.hpack(nodelist)
    if showtext then
        nodelist = nil
        for i,v in ipairs({split_number(digits)}) do
          for j=1,string.len(v) do
            nodelist = add_to_nodelist(nodelist,mkglyph(string.sub(v,j,j),fontnumber))
          end
          if i == 1 then
            nodelist = add_to_nodelist(nodelist,mkkern(5 * unit))
          elseif i == 2 then
            nodelist = add_to_nodelist(nodelist,mkkern(4 * unit))
          end
        end
        local barcode_bottom = node.hpack(nodelist)
        -- barcode_top now has three elements: the hbox
        -- from the rules and kerns, the kern of -1.7mm
        -- and the hbox with the digits below the bars.
        local vkern = mkkern(-0.9 * overshoot)
        barcode_top = add_to_nodelist(barcode_top,vkern)
        barcode_top = add_to_nodelist(barcode_top,barcode_bottom)
    else
    	-- don't show text
    end

    local bc = node.vpack(barcode_top)
    if scalefactor ~= 1 then -- we need to scale the resulting barcode
      bc = scalebox(scalefactor,bc)
    end
    return bc
end
--- Code 128
--- --------
local code128encoding = {
    [0] = "212222", "222122", "222221", "121223", "121322", --  0 -  4
    "131222", "122213", "122312", "132212", "221213",
    "221312", "231212", "112232", "122132", "122231", -- 10 - 14
    "113222", "123122", "123221", "223211", "221132",
    "221231", "213212", "223112", "312131", "311222",  -- 20 - 24
    "321122", "321221", "312212", "322112", "322211",
    "212123", "212321", "232121", "111323", "131123",  -- 30 - 34
    "131321", "112313", "132113", "132311", "211313",
    "231113", "231311", "112133", "112331", "132131",  -- 40 - 44
    "113123", "113321", "133121", "313121", "211331",
    "231131", "213113", "213311", "213131", "311123",  -- 50 - 54
    "311321", "331121", "312113", "312311", "332111",
    "314111", "221411", "431111", "111224", "111422",  -- 60 - 64
    "121124", "121421", "141122", "141221", "112214",
    "112412", "122114", "122411", "142112", "142211",  -- 70 - 74
    "241211", "221114", "413111", "241112", "134111",
    "111242", "121142", "121241", "114212", "124112",  -- 80 - 84
    "124211", "411212", "421112", "421211", "212141",
    "214121", "412121", "111143", "111341", "131141",  -- 90 - 94
    "114113", "114311", "411113", "411311", "113141",
    "114131", "311141", "411131", "211412", "211214",  -- 100 - 104
    "211232", "2331112"
}

local function code128_switch_mode(current_mode, future_mode,pattern)
	if current_mode == future_mode then return current_mode end
	if not current_mode then
		-- starting
		if future_mode == "128C" then
      pattern[#pattern + 1] = 105
		elseif future_mode == "128B" then
      pattern[#pattern + 1] = 104
		else
			assert(false,"code128: start mode unknown")
		end
		return future_mode
	end
	if current_mode == "128C" then
		if future_mode == "128B" then
      pattern[#pattern + 1] = 100
		else
			assert(false, "128C -> ??")
		end
	elseif current_mode == "128B" then
		if future_mode == "128C" then
      pattern[#pattern + 1] = 99
		else
			assert(false, "128B -> ??")
		end
	end

	return future_mode
end

local function code128_push( text,pattern)
  if unicode.utf8.len(text) == 1 then
    local cp = unicode.utf8.byte(text)
    if cp <= 128 then
      pattern[#pattern + 1] = string.byte(text) - 32
    else
      -- not supported by any commercial barcode decoder?!?
      pattern[#pattern + 1] = 100 -- FNC4
      pattern[#pattern + 1] = cp - 128 - 32
    end
  elseif string.len(text) == 2 then
    -- hopefully two digits
    pattern[#pattern + 1] = tonumber(text)
  end

end

local function code128_calculate_checksum_and_add_stop_pattern(pattern)
  local sum = pattern[1]
  for i=2,#pattern do
    sum = sum + ( i - 1 ) * pattern[i]
  end
  pattern[#pattern + 1] = sum % 103
  pattern[#pattern + 1] = 106
end

local function code128_make_nodelist(pattern,wd,ht)
  local rule,kern
  local nodelist,pat,m
  m = 0
  for i=1,#pattern do
    pat = code128encoding[pattern[i]]
    string.gsub(pat,".", function(c)
      if m % 2 == 1 then
        -- gap
        kern = mkkern(tonumber(c) * wd)
        nodelist = add_to_nodelist(nodelist,kern)
      else
        -- bar
        rule = mkrule(tonumber(c) * wd,ht,0)
        nodelist = add_to_nodelist(nodelist,rule)
      end
      m = m + 1
    end)
  end
  local hbox = node.hpack(nodelist)
  return hbox
end

local function code128(width,height,fontfamily,text,showtext)
  local textnodelist
  if showtext then
    textnodelist = publisher.mknodes(text,fontfamily,{})
  end
  local pattern = {}
	local mode,output
	while string.len(text) > 0 do
    	if string.match(text,"^%d%d") then
    		mode = code128_switch_mode(mode,"128C",pattern)
    		output = string.sub(text,1,2)
    		text = string.sub(text,3,-1)
    	else
    		mode = code128_switch_mode(mode,"128B",pattern)
    		output = unicode.utf8.sub(text,1,1)
    		text = unicode.utf8.sub(text,2,-1)
    	end
      code128_push(output,pattern)
  end
  code128_calculate_checksum_and_add_stop_pattern (pattern)



  -- At this point we have the text in a nodelist and the
  -- pattern of the barcode. We can easily calculate the
  -- width of the barcode. Each pattern entry has bars
  -- and spaces of total width 11, the stop pattern has
  -- two more.
  wd_pattern_units = #pattern * 11 + 2
  local unit_width, barcode_height
  if width then
    unit_width = width / wd_pattern_units
  else
    unit_width = tex.sp("1pt")
  end
  if height then
    if showtext then
      local fontsize = publisher.fonts.lookup_fontfamily_number_instance[fontfamily].size
      barcode_height = height - 2*2^16 - fontsize
    else
      barcode_height = height
    end
  else
    barcode_height = tex.sp("1cm")
  end


  local code_hbox = code128_make_nodelist(pattern,unit_width,barcode_height)
  local vbox
  if showtext then
    local textbox,vkern,hglue_left,hglue_right
    hglue_right = set_glue(nil,{width = 0, stretch = 2^16, stretch_order = 2})

    hglue_left=node.copy(hglue_right)
    hglue_left.next=textnodelist
    node.tail(textnodelist).next = hglue_right
    textbox = node.hpack(hglue_left,code_hbox.width,"exactly")

    vkern = mkkern(2*2^16)
    code_hbox.next = vkern

    vkern.next = textbox
    vbox = node.vpack(code_hbox)
  else
    vbox = node.vpack(code_hbox)
  end

  return vbox
end

--- QR Codes
--- --------

barcodes_qrencode = nil

-- size is in scaled points
local function make_code(size,matrix)
  local size_bp = size / publisher.factor
  local dark_bits
  local white_bits
  local unit = math.round(size_bp / #matrix,3)
  local bc = {}
  bc[#bc + 1] = "q"
  for x=1,#matrix do
    last_bit = "-"
    dark_bits = 0
    white_bits = 0

    for y=1,#matrix do
      if matrix[x][y] > 0 then -- black
        if last_bit == "white" then
          white_bits = 0
          dark_bits = 1
        else
          dark_bits = dark_bits + 1
        end
        last_bit = "black"
      else -- white
        if last_bit == "white" then
          white_bits = white_bits + 1
        else
          -- draw black
          bc[#bc + 1] = string.format("%g %g %g %g re f",( x - 1) * unit,( y - 1 ) * -unit, unit * 1.02, dark_bits * unit)
          dark_bits = 0
          white_bits = 1
        end
        last_bit = "white"
      end
    end
    if last_bit == "black" then
      bc[#bc + 1] = string.format("%g %g %g %g re f",(x - 1) * unit,( #matrix ) * -unit, unit * 1.02, dark_bits * unit)
    end
  end
  bc[#bc + 1] = "Q"
  local n = node.new("whatsit","pdf_literal")
  n.data = table.concat(bc," ")
  n.mode = 0
  -- Avoid underfull boxes message:
  n = publisher.add_glue(n,"tail",{width = 0, stretch = 1, stretch_order = 3})
  local h = node.hpack(n,size,"exactly")
  h = publisher.add_glue(h,"tail",{stretch = 1, stretch_order = 3})
  local v = node.vpack(h,size,"exactly")
  return v
end

local function qrcode(width,height,codeword,eclevel)
  if not barcodes_qrencode then barcodes_qrencode = do_luafile("qrencode.lua") end
  local ok, tab_or_message =  barcodes_qrencode.qrcode(codeword,eclevel)
  if not ok then
    err(tab_or_message)
    return nil
  else
    return make_code(width,tab_or_message)
  end
end


return {
	ean13 = ean13,
	code128 = code128,
	qrcode = qrcode,
}
