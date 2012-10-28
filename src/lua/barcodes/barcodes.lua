--- This file contains the code for generating barcodes
--
--  barcodes.lua
--  speedata publisher
--
--  Copyright 2012 Patrick Gundlach.
--  See file COPYING in the root directory for license info.

require('lpeg')

barcodes = {}

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
		local a = node.new("whatsit","pdf_literal")
		a.data = string.format("q %.4g 0 0 %.4g 0 0 cm",scalefactor,scalefactor)
		a.next = bc
		bc.prev = a
		local b = node.new("whatsit","pdf_literal")
		b.data = "Q"
		bc.next = b
		b.prev = bc
		bc = node.vpack(a)
		bc.width = width
		return bc
	end
    return bc
end

local function code128_switch_mode(current_mode, future_mode)
	w("switch from mode %q to mode %q",current_mode or "nil",future_mode or "nil")
	if current_mode == future_mode then return current_mode end
	if not current_mode then
		-- starting
		if future_mode == "128C" then
			w("start with 128C")
		elseif future_mode == "128B" then
			w("start with 128B")
		else
			assert(false,"code128: start mode unknown")
		end
		return future_mode
	end
	if current_mode == "128C" then
		if future_mode == "128B" then
			w("128C -> 128B")
		else
			assert(false, "128C -> ??")
		end
	elseif current_mode == "128B" then
		if future_mode == "128C" then
			w("128B -> 128C")
		else
			assert(false, "128B -> ??")
		end
	end		

	return future_mode
end

local function code128(text)
	text="1y23"
	w("Code128, text=%q",text or "???")
	local mode,output
	while string.len(text) > 0 do
    	if string.match(text,"^%d%d") then
    		mode =  code128_switch_mode(mode,"128C")
    		output = string.sub(text,1,2)
    		w("output: two digits in 128C %q",output or "???")
    		text = string.sub(text,3,-1)
    		w("text is now %q",text or "???")
    	else
    		mode =  code128_switch_mode(mode,"128B")
    		output = string.sub(text,1,1)
    		w("output: one char in 128B %q",output or "???")
    		text = string.sub(text,2,-1)
    		w("text is now %q",text or "???")
    	end
    end
end


return {
	ean13 = ean13,
	code128 = code128
}