--
--  layout-functions.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.


file_start("layout_functions.lua")

local luxor = do_luafile("luxor.lua")
local sha1  = require('sha1')


local function allocated( dataxml,arg )
    local x = arg[1]
    local y = arg[2]
    local areaname = arg[3]
    local framenumber = arg[4]
    publisher.setup_page(nil,"layout_functions#allocated")
    return publisher.current_grid:isallocated(x,y,areaname,framenumber)
end

local function current_page(  )
    publisher.setup_page(nil,"layout_functions#current_page")
    return publisher.current_pagenumber
end

local function current_row(dataxml,arg)
    publisher.setup_page(nil,"layout_functions#current_row")
    return publisher.current_grid:current_row(arg and arg[1])
end

-- Evaluate the string arg as a dimension. The return value is a string with the dimension "sp".
local function dimexpression( dataxml,arg )
    arg = table.concat(arg)
    local save_dim = is_dim
    is_dim = true
    xpath.push_state()
    local ret = xpath.parse(dataxml,arg,"")
    xpath.pop_state()
    is_dim = save_dim
    return ret .. "sp"
end

--- Get the page number of a marker
local function pagenumber(dataxml,arg)
  local m = publisher.markers[arg[1]]
  if m then
    return m.page
  else
    return nil
  end
end

local function current_column(dataxml,arg)
  publisher.setup_page(nil,"layout_functions#current_column")
  return publisher.current_grid:current_column(arg and arg[1])
end

local function alternating(dataxml, arg )
  local alt_type = arg[1]
  if not publisher.alternating[alt_type] then
    publisher.alternating[alt_type] = 1
  else
    publisher.alternating[alt_type] = math.fmod( publisher.alternating[alt_type], #arg - 1 ) + 1
  end
  local val = arg[publisher.alternating[alt_type] + 1]
  publisher.alternating_value[alt_type] = val
  return val
end

local function first_free_row( dataxml, arg )
  local ret = 0
  if arg and arg[1] then
      ret = publisher.current_grid:first_free_row(arg[1])
  end
  return ret
end

-- Read the contents given in arg[1] and write it to a temporary file.
-- Return the name of the file. Useful in conjunction with sd:decode-base64()
-- and Image to read an image from the data.
local function filecontents( dataxml,arg )
      local tmpdir = os.getenv("SP_TEMPDIR")
      lfs.mkdir(tmpdir)
      local filename = publisher.string_random(20)
      local path = tmpdir .. publisher.os_separator .. filename
      local file,e = io.open(path,"wb")
      if file == nil then
          err("Could not write filecontents into temp directory: %q",e)
          return nil
      end
      file:write(arg[1])
      file:close()
      return path
end

local function mode( dataxml,arg )
  local entry
  for _,v in pairs(arg) do
    entry = publisher.modes[v]
    if entry == true then return true end
  end
  return false
end

local function keepalternating(dataxml, arg )
  local alt_type = arg[1]
  return publisher.alternating_value[alt_type]
end


local function reset_alternating( dataxml,arg )
  local alt_type = arg[1]
  publisher.alternating[alt_type] = 0
end

local function number_of_datasets(dataxml,d)
  if not d then return 0 end
  local count = 0
  for i=1,#d do
    if type(d[i]) == 'table' then
      count = count + 1
    end
  end
  return count
end

local function number_of_columns(dataxml,arg)
  publisher.setup_page(nil,"layout_functions#number_of_columns")
  return publisher.current_grid:number_of_columns(arg and arg[1])
end

--- Merge numbers like '1,2,3,4,5, 8, 9,10' into '1-5, 8-10'
local function merge_pagenumbers(dataxml,arg )
    local pagenumbers_string = string.gsub(arg[1] or "","%s","")
    local mergechar = arg[2] or "–"
    local spacer    = arg[3] or ", "

    local pagenumbers = string.explode(pagenumbers_string,",")
    -- let's remove duplicates now
    local dupes = {}
    local withoutdupes = {}
    local cap1,cap2
    for i=1,#pagenumbers do
        local num = pagenumbers[i]
        cap1, cap2 = string.match(num,"^(.)-(.)$")
        if cap1 then
            for i=tonumber(cap1),tonumber(cap2) do
                num = tostring(i)
                if (not dupes[num]) then
                    withoutdupes[#withoutdupes+1] = num
                    dupes[num] = true
                end
            end
        else
            if (not dupes[num]) then
                withoutdupes[#withoutdupes+1] = num
                dupes[num] = true
            end
        end
    end
    publisher.stable_sort(withoutdupes,function(elta,eltb)
          return tonumber(elta) < tonumber(eltb)
      end)

    if mergechar ~= "" then
        local buckets = {}
        local bucket
        local cur
        local prev = -99
        for i=1,#withoutdupes do
            cur = tonumber(withoutdupes[i])
            if cur == prev + 1 then
                -- same bucket
                bucket[#bucket + 1] = cur
            else
                bucket = { cur }
                buckets[#buckets + 1] = bucket
            end
            prev = cur
        end
        for i=1,#buckets do
            if #buckets[i] > 2 then
                buckets[i] = buckets[i][1] .. mergechar .. buckets[i][#buckets[i]]
            elseif #buckets[i] == 2 then
                buckets[i] = buckets[i][1] .. spacer .. buckets[i][#buckets[i]]
            else
                buckets[i] = buckets[i][1]
            end
        end
        return table.concat(buckets,spacer)
    else
        return table.concat(withoutdupes, spacer)
    end
end

local function number_of_rows(dataxml,arg)
  publisher.setup_page(nil,"layout_functions#number_of_rows")
  return publisher.current_grid:number_of_rows(arg and arg[1])
end

local function number_of_pages(dataxml,arg )
  local filename = arg[1]
  local img = publisher.imageinfo(filename)
  return img.img.pages
end

local function imagewidth(dataxml, arg )
  local filename = arg[1]
  local img = publisher.imageinfo(filename)
  publisher.setup_page(nil,"layout_functions#imagewidth")
  local tmp = publisher.current_grid:width_in_gridcells_sp(img.img.width)
  return tmp
end

local function imageheight(dataxml, arg )
  local filename = arg[1]
  local img = publisher.imageinfo(filename)
  publisher.setup_page(nil,"layout_functions#imageheight")
  return publisher.current_grid:height_in_gridcells_sp(img.img.height)
end

local function file_exists(dataxml, arg )
    local filename = arg[1]
    if not filename then return false end
    if filename == "" then return false end
    return kpse.find_file(filename) ~= nil
end

--- Insert 1000's separator and comma separator
local function format_number(dataxml,arg)
  local num, thousandssep,commasep = arg[1], arg[2], arg[3]
  local sign,digits,commadigits = string.match(tostring(num),"([%-%+]?)(%d*)%.?(%d*)")
  local first_digits = math.fmod(#digits,3)
  local ret = {}
  if first_digits > 0 then
    ret[1] = string.sub(digits,0,first_digits)
  end
  for i=1, ( #digits - first_digits) / 3 do
    ret[#ret + 1] = string.sub(digits,first_digits + ( i - 1) * 3 + 1 ,first_digits + i * 3 )
  end
  ret = table.concat(ret, thousandssep)
  if commadigits and #commadigits > 0 then
    return  sign .. ret .. commasep .. commadigits
  else
    return sign .. ret
  end
end

local function format_string( dataxml,arg )
    local argument = {}
    for i=1,#arg - 1 do
        argument[#argument + 1] = table_textvalue(arg[i])
    end
    local unpacked = table.unpack(argument)
    if unpacked == nil or unpacked == "" then
        err("format-string: first arguments are empty")
        return ""
    end
    local ret = string.format(arg[#arg],unpacked)
    return ret
end


local function even(dataxml, arg )
  return math.fmod(arg[1],2) == 0
end

local function current_frame_number(dataxml,arg)
  publisher.setup_page(nil,"layout_functions#current_framenumber")
  local framename = arg[1]
  if framename == nil then return 1 end
  local current_framenumber = publisher.current_grid:framenumber(framename)
  return current_framenumber
end

local function groupheight(dataxml, arg )
    publisher.setup_page(nil,"layout_functions#groupheight")
    local groupname=arg[1]
    if not publisher.groups[groupname] then
        err("Can't find group with the name %q",groupname)
        return 0
    end

    local groupcontents=publisher.groups[groupname].contents
    if not groupcontents then
        err("Can't find group with the name %q",groupname)
        return 0
    end
    local height
    local unit = arg[2]
    if unit then
        height = groupcontents.height
        local ret
        if unit == "cm" then
            ret = height / publisher.tenmm_sp
        elseif unit == "mm" then
            ret = height / publisher.onemm_sp
        elseif unit == "in" then
            ret = height / publisher.onein_sp
        else
            err("unsupported unit: %q",unit)
        end
        return math.round(ret, 4)
    else
        local grid = publisher.current_grid
        height = grid:height_in_gridcells_sp(groupcontents.height)
        return height
    end
end

local function groupwidth(dataxml, arg )
  publisher.setup_page(nil,"layout_functions#groupwidth")
  local groupname=arg[1]
  if not publisher.groups[groupname] then
    err("Can't find group with the name %q",groupname)
    return 0
  end
  local groupcontents=publisher.groups[groupname].contents

  if not groupcontents then
    err("Can't find group with the name %q",groupname)
    return 0
  end
  local unit = arg[2]
  local width
  if unit then
      width = groupcontents.width
      local ret
      if unit == "cm" then
          ret = width / publisher.tenmm_sp
      elseif unit == "mm" then
          ret = width / publisher.onemm_sp
      elseif unit == "in" then
          ret = width / publisher.onein_sp
      else
          err("unsupported unit: %q",unit)
      end
      return math.round(ret, 4)
  else
      local grid = publisher.current_grid
      width = grid:width_in_gridcells_sp(groupcontents.width)
      return width
  end
end


local function odd(dataxml, arg )
    local num = arg[1]
    if not tonumber(num) then
        err("sd:odd() - argument is not a number")
        return false
    end
    return math.fmod(num,2) ~= 0
end

local function variable(dataxml, arg )
  local varname = table.concat(arg)
  local var = publisher.xpath.get_variable(varname)
  return var
end

local function attr(dataxml, arg )
  local attname = table.concat(arg)
  local att = dataxml[attname]
  return att
end

local function variable_exists(dataxml,arg)
  local var = publisher.xpath.get_variable(arg[1])
  return var ~= nil
end

-- SHA-1
local function shaone(dataxml,arg)
    local message = table.concat(arg)
    local ret = sha1.sha1(message)
    return ret
end

-- Turn &lt;b&gt;Hello&lt;b /&gt; into an HTML table and then into XML structure.
local function decode_html( dataxml, arg )
    if arg == nil then
        arg = dataxml
    end
    arg = table_textvalue(arg)
    if type(arg) == "string" then
        local msg = publisher.splib.htmltoxml(arg)
        if msg == nil then
            err("decode-html failed")
            return nil
        end
        local ret = luxor.parse_xml("<dummy>" .. msg .. "</dummy>")
        return ret
    end
end

local function decode_base64(dataxml,arg)
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local data = tostring(arg[1])
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

local function count_saved_pages(dataxml,arg)
    local tmp = publisher.pagestore[arg[1]]
    if not tmp then
        err("count-saved-pages(): no saved pages found. Return 0")
        return 0
    else
        return #tmp
    end
end

local function randomitem(dataxml, arg)
    local x = math.random(#arg)
    return arg[x]
end

local function aspectratio( dataxml,arg )
  local filename = arg[1]
  local img = publisher.imageinfo(filename)
  return img.img.xsize / img.img.ysize
end

local function loremipsum(dataxml,arg)
    local count = arg and arg[1] or 1
    local lorem = [[
        Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
        tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
        veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea
        commodo consequat. Duis aute irure dolor in reprehenderit in voluptate
        velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint
        occaecat cupidatat non proident, sunt in culpa qui officia deserunt
        mollit anim id est laborum.
    ]]
    return string.rep(lorem:gsub("^%s*(.-)%s*$","%1"):gsub("[%s\n]+"," "),count, " ")
end

local register = publisher.xpath.register_function

register("urn:speedata:2009/publisher/functions/en","attr",attr)

register("urn:speedata:2009/publisher/functions/en","dimexpr",dimexpression)

register("urn:speedata:2009/publisher/functions/en","alternating",alternating)

register("urn:speedata:2009/publisher/functions/en","aspectratio",aspectratio)

register("urn:speedata:2009/publisher/functions/en","count-saved-pages",count_saved_pages)

register("urn:speedata:2009/publisher/functions/en","current-page",current_page)

register("urn:speedata:2009/publisher/functions/en","current-row",current_row)

register("urn:speedata:2009/publisher/functions/en","current-framenumber",current_frame_number)

register("urn:speedata:2009/publisher/functions/en","current-column",current_column)

register("urn:speedata:2009/publisher/functions/en","decode-html",decode_html)

register("urn:speedata:2009/publisher/functions/en","decode-base64",decode_base64)

register("urn:speedata:2009/publisher/functions/en","dummytext",loremipsum)
register("urn:speedata:2009/publisher/functions/en","loremipsum",loremipsum)

register("urn:speedata:2009/publisher/functions/en","even",even)

register("urn:speedata:2009/publisher/functions/en","first-free-row",first_free_row)

register("urn:speedata:2009/publisher/functions/en","filecontents",filecontents)

register("urn:speedata:2009/publisher/functions/en","file-exists",file_exists)

register("urn:speedata:2009/publisher/functions/en","format-number",format_number)

register("urn:speedata:2009/publisher/functions/en","format-string",format_string)

register("urn:speedata:2009/publisher/functions/en","group-height",groupheight)
register("urn:speedata:2009/publisher/functions/en","groupheight",groupheight)

register("urn:speedata:2009/publisher/functions/en","group-width",groupwidth)
register("urn:speedata:2009/publisher/functions/en","groupwidth",groupwidth)

register("urn:speedata:2009/publisher/functions/en","imagewidth",imagewidth)

register("urn:speedata:2009/publisher/functions/en","imageheight",imageheight)

register("urn:speedata:2009/publisher/functions/en","mode",mode)

register("urn:speedata:2009/publisher/functions/en","allocated",allocated)

register("urn:speedata:2009/publisher/functions/en","keep-alternating",keepalternating)

register("urn:speedata:2009/publisher/functions/en","merge-pagenumbers",merge_pagenumbers)

register("urn:speedata:2009/publisher/functions/en","number-of-datasets",number_of_datasets)

register("urn:speedata:2009/publisher/functions/en","number-of-rows",number_of_rows)

register("urn:speedata:2009/publisher/functions/en","number-of-columns",number_of_columns)

register("urn:speedata:2009/publisher/functions/en","number-of-pages",number_of_pages)

register("urn:speedata:2009/publisher/functions/en","odd",odd)

register("urn:speedata:2009/publisher/functions/en","pagenumber",pagenumber)

register("urn:speedata:2009/publisher/functions/en","randomitem",randomitem)

register("urn:speedata:2009/publisher/functions/en","reset_alternating",reset_alternating) -- backward comp.
register("urn:speedata:2009/publisher/functions/en","reset-alternating",reset_alternating)

register("urn:speedata:2009/publisher/functions/en","sha1",shaone)

register("urn:speedata:2009/publisher/functions/en","variable",variable)

register("urn:speedata:2009/publisher/functions/en","variable-exists",variable_exists)


file_end("layout_functions.lua")
