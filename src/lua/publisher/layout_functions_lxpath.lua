--
--  layout-functions.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.


file_start("layout_functions.lua")

local de = require("dimexpr")


local luxor      = do_luafile("luxor.lua")
local sha        = require('shalocal')

-- Return filename, pagenumber, box and unit from the arg. Used in imagewidth et al.
--- @param arg table
--- @return string, number, string, string | nil
local function get_filename_pagenum_box_unit_from_arg(arg)
    local filename, box, unit
    box = "cropbox"
    local pagenumber = 1
    filename = xpath.string_value(arg[1])
    for i = 2, #arg do
        local ai = arg[i]
        if tonumber(ai) then
            pagenumber = tonumber(ai) or 1
        elseif ai == "cm" or ai == "mm" or ai == "in" or ai == "sp" or ai == "pc" or ai == "pt" or ai == "pp" or ai == "cc" then
            unit = ai
        elseif ai == "artbox" or ai == "cropbox" or ai == "bleedbox" or ai == "trimbox" or ai == "mediabox" then
            box = ai
        end
    end
    -- printtable("{filename,pagenumber,box,unit}",{filename,pagenumber,box,unit})
    return filename, pagenumber, box, unit
end


local function visiblepagenumber(pagenumber)
    pagenumber = tonumber(pagenumber)
    return publisher.visible_pagenumbers[pagenumber] or pagenumber
end

local function fnAllocated(dataxml, arg)
    local x, y, areaname, framenumber
    x = xpath.number_value(arg[1])
    y = xpath.number_value(arg[2])
    if #arg > 2 then
        areaname, msg = xpath.string_value(arg[3])
    end
    if #arg > 3 then
        framenumber = xpath.number_value(arg[4])
    end

    publisher.setup_page(nil, "layout_functions#allocated", dataxml)
    return { publisher.current_grid:isallocated(x, y, areaname, framenumber) }, nil
end

local function fnCurrentPage(dataxml, arg)
    if not publisher.in_init_page then
        publisher.setup_page(nil, "layout_functions#current_page", dataxml)
    end
    return { publisher.current_pagenumber }, nil
end

local function fnCurrentRow(dataxml, arg)
    publisher.setup_page(nil, "layout_functions#current_row", dataxml)
    local areaname = nil
    if #arg == 1 then
        areaname = publisher.xpath.string_value(arg[1])
    end
    return { publisher.current_grid:current_row(areaname) }, nil
end


--- Get the page number of a marker
local function fnpagenumber(dataxml, arg)
    local firstarg = xpath.string_value(arg[1])
    local m = publisher.markers[firstarg]
    if m then
        return { m.page }, nil
    else
        return {}, nil
    end
end

local function current_column(dataxml, arg)
    publisher.setup_page(nil, "layout_functions#current_column", dataxml)
    local firstarg
    if #arg > 0 then
        firstarg = xpath.string_value(arg[1])
    end
    return { publisher.current_grid:current_column(firstarg) }, nil
end

local function fnAlternating(dataxml, arg)
    local alt_type = xpath.string_value(arg[1])
    if not publisher.alternating[alt_type] then
        publisher.alternating[alt_type] = 1
    else
        publisher.alternating[alt_type] = math.fmod(publisher.alternating[alt_type], #arg - 1) + 1
    end
    local val = arg[publisher.alternating[alt_type] + 1]
    publisher.alternating_value[alt_type] = val
    return { val }
end

local function first_free_row(dataxml, arg)
    local ret = 0
    local firstarg
    if #arg > 0 then
        firstarg = xpath.string_value(arg[1])
    else
        firstarg = publisher.default_areaname
    end
    ret = publisher.current_grid:first_free_row(firstarg)
    return { ret }, nil
end

-- Get the first mark of a page (for example used in the head of dictionaries)
local function firstmark(dataxml, arg)
    local pagenumber = xpath.number_value(arg[1])
    if not tonumber(pagenumber) then err("firstmark: cannot get page number") end
    local minid = publisher.marker_min[pagenumber]
    if not minid then return "" end
    return { publisher.marker_id_value[minid].name }
end

-- Get the last mark of a page (for example used in the head of dictionaires)
local function lastmark(dataxml, arg)
    local pagenumber = xpath.number_value(arg[1])
    if not tonumber(pagenumber) then err("lasttmark: cannot get page number") end
    local maxid = publisher.marker_max[pagenumber]
    if not maxid then return "" end
    return { publisher.marker_id_value[maxid].name }
end

-- Read the contents given in arg[1] and write it to a temporary file.
-- Return the name of the file. Useful in conjunction with sd:decode-base64()
-- and Image to read an image from the data.
local function filecontents(dataxml, arg)
    local tmpdir = os.getenv("SP_TEMPDIR")
    if tmpdir == nil then
        err("SD_TEMPDIR is nil")
        return
    end

    lfs.mkdir(tmpdir)
    local filename = publisher.string_random(20)
    local path = tmpdir .. publisher.os_separator .. filename
    local file, e = io.open(path, "wb")
    if file == nil then
        err("Could not write filecontents into temp directory: %q", e)
        return nil
    end
    local firstarg = xpath.string_value(arg[1])
    file:write(firstarg)
    file:close()
    return { path }
end

local function mode(dataxml, arg)
    local entry
    for _, v in pairs(arg) do
        entry = publisher.modes[v]
        if entry == true then return { true }, nil end
    end
    return { false }, nil
end

local function keepalternating(dataxml, arg)
    local alt_type = xpath.string_value(arg[1])
    return { publisher.alternating_value[alt_type] }, nil
end


local function reset_alternating(dataxml, arg)
    local alt_type = xpath.string_value(arg[1])
    publisher.alternating[alt_type] = 0
    return {}, nil
end

local function fnNumberOfColumns(dataxml, arg)
    publisher.setup_page(nil, "layout_functions#number_of_columns", dataxml)
    return { publisher.current_grid:number_of_columns(arg and arg[1]) }, nil
end

--- Merge numbers like '1,2,3,4,5, 8, 9,10' into '1-5, 8-10'
local function fnMergePagenumbers(dataxml, arg)
    local firstarg, secondarg, thirdarg, fourtharg
    firstarg = xpath.string_value(arg[1])
    if #arg > 1 then
        secondarg = xpath.string_value(arg[2])
    end
    if #arg > 2 then
        thirdarg = xpath.string_value(arg[3])
    end
    if #arg > 3 then
        fourtharg = xpath.string_value(arg[4])
    end

    local pagenumbers_string = string.gsub(firstarg or "", "%s", "")
    local mergechar          = secondarg or "–"
    local spacer             = thirdarg or ", "
    local interaction        = fourtharg or false

    local pagenumbers        = string.explode(pagenumbers_string, ",")

    -- let's remove duplicates now
    local dupes              = {}
    local withoutdupes       = {}
    local cap1, cap2
    for i = 1, #pagenumbers do
        local num = pagenumbers[i]
        cap1, cap2 = string.match(num, "^(.)-(.)$")
        if cap1 then
            for i = tonumber(cap1), tonumber(cap2) do
                num = tostring(i)
                if (not dupes[num]) then
                    withoutdupes[#withoutdupes + 1] = num
                    dupes[num] = true
                end
            end
        else
            if (not dupes[num]) then
                withoutdupes[#withoutdupes + 1] = num
                dupes[num] = true
            end
        end
    end
    publisher.stable_sort(withoutdupes, function(elta, eltb) return tonumber(elta) < tonumber(eltb) end)
    local gethyperlink
    if interaction then
        gethyperlink = function(pagenum) return { hyperlink = publisher.hlpage(pagenum) } end
    else
        gethyperlink = function(pagenum) return nil end
    end

    local p = par:new(nil, "merge-pagenumbers")
    if mergechar == "" then
        local pagenumber
        for i = 1, #withoutdupes - 1 do
            pagenumber = withoutdupes[i]
            p:append(visiblepagenumber(pagenumber), gethyperlink(pagenumber))
            p:append(spacer)
        end
        pagenumber = withoutdupes[#withoutdupes]
        p:append(visiblepagenumber(pagenumber), gethyperlink(pagenumber))
    else
        -- Buckets have consecutive pages. For example 1,2,3,4,5
        -- So when merging the numbers, we just have to look for the first and last
        -- entry in a bucket.
        local buckets = {}
        local bucket
        local cur
        local prev = -99
        for i = 1, #withoutdupes do
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

        for i = 1, #buckets do
            if #buckets[i] > 2 then
                local from, to = buckets[i][1], buckets[i][#buckets[i]]
                p:append(visiblepagenumber(from), gethyperlink(from))
                p:append(mergechar)
                p:append(visiblepagenumber(to), gethyperlink(to))
            elseif #buckets[i] == 2 then
                local from, to = buckets[i][1], buckets[i][#buckets[i]]
                p:append(visiblepagenumber(from), gethyperlink(from))
                p:append(spacer)
                p:append(visiblepagenumber(to), gethyperlink(to))
            else
                local to = buckets[i][1]
                p:append(visiblepagenumber(to), gethyperlink(to))
            end
            if i < #buckets then
                p:append(spacer)
            end
        end
    end
    return p, nil
end

local function fnNumberOfRows(dataxml, arg)
    local areaname
    if #arg > 0 then
        areaname = publisher.xpath.string_value(arg[1])
    end
    publisher.setup_page(nil, "layout_functions#number_of_rows", dataxml)
    return { publisher.current_grid:number_of_rows(areaname) }
end

local function fnNumberOfPages(dataxml, arg)
    local filename = xpath.string_value(arg[1])
    local img = publisher.imageinfo(filename)
    return { img.img.pages }, nil
end

local function imagewidth(dataxml, arg)
    local filename, pagenumber, box, unit = get_filename_pagenum_box_unit_from_arg(arg)
    local img = publisher.imageinfo(filename, pagenumber, box)
    publisher.setup_page(nil, "layout_functions#imagewidth", dataxml)

    local width
    if unit then
        width = img.img.width
        local ret
        if unit == "cm" then
            ret = width / publisher.tenmm_sp
        elseif unit == "mm" then
            ret = width / publisher.onemm_sp
        elseif unit == "in" then
            ret = width / publisher.onein_sp
        elseif unit == "sp" then
            ret = width
        elseif unit == "pc" then
            ret = width / publisher.onepc_sp
        elseif unit == "pt" then
            ret = width / publisher.onept_sp
        elseif unit == "pp" then
            ret = width / publisher.onepp_sp
        elseif unit == "dd" then
            ret = width / publisher.onedd_sp
        elseif unit == "cc" then
            ret = width / publisher.onecc_sp
        else
            err("unsupported unit: %q, please use 'sp', 'pt', 'pc', 'cm', 'mm', 'in', 'dd' or 'cc'", unit)
        end
        return { math.round(ret, 4) }, nil
    else
        width = publisher.current_grid:width_in_gridcells_sp(img.img.width)
        return { width }, nil
    end
end

local function imageheight(dataxml, arg)
    local filename, pagenumber, box, unit = get_filename_pagenum_box_unit_from_arg(arg)
    local img = publisher.imageinfo(filename, pagenumber, box)
    publisher.setup_page(nil, "layout_functions#imageheight", dataxml)
    local height
    if unit then
        height = img.img.height
        local ret
        if unit == "cm" then
            ret = height / publisher.tenmm_sp
        elseif unit == "mm" then
            ret = height / publisher.onemm_sp
        elseif unit == "in" then
            ret = height / publisher.onein_sp
        elseif unit == "sp" then
            ret = height
        elseif unit == "pc" then
            ret = height / publisher.onepc_sp
        elseif unit == "pt" then
            ret = height / publisher.onept_sp
        elseif unit == "pp" then
            ret = height / publisher.onepp_sp
        elseif unit == "dd" then
            ret = height / publisher.onedd_sp
        elseif unit == "cc" then
            ret = height / publisher.onecc_sp
        else
            err("unsupported unit: %q, please use 'sp', 'pt', 'pc', 'cm', 'mm', 'in', 'dd' or 'cc'", unit)
        end
        return { math.round(ret, 4) }, nil
    else
        height = publisher.current_grid:height_in_gridcells_sp(img.img.height)
        return { height }, nil
    end
end

local function file_exists(dataxml, arg)
    local filename = xpath.string_value(arg[1])
    if not filename then return { false }, nil end
    if filename == "" then return { false }, nil end
    return { publisher.find_file(filename) ~= nil }, nil
end

--- Insert 1000's separator and comma separator
local function format_number(dataxml, arg)
    local num, thousandssep, commasep
    local msg
    num, msg = xpath.number_value(arg[1])
    if msg then return nil, msg end
    thousandssep, msg = xpath.string_value(arg[2])
    if msg then return nil, msg end
    commasep, msg = xpath.string_value(arg[3])
    if msg then return nil, msg end

    local sign, digits, commadigits = string.match(tostring(num), "([%-%+]?)(%d*)%.?(%d*)")
    local first_digits = math.fmod(#digits, 3)
    local ret = {}
    if first_digits > 0 then
        ret[1] = string.sub(digits, 0, first_digits)
    end
    for i = 1, (#digits - first_digits) / 3 do
        ret[#ret + 1] = string.sub(digits, first_digits + (i - 1) * 3 + 1, first_digits + i * 3)
    end
    local retstr = table.concat(ret, thousandssep)
    if commadigits and #commadigits > 0 then
        return { sign .. retstr .. commasep .. commadigits }, nil
    else
        return { sign .. retstr }, nil
    end
end

local function format_string(dataxml, arg)
    local argument = {}
    for i = 1, #arg - 1 do
        argument[#argument + 1] = xpath.string_value(arg[i])
    end
    local unpacked = table.unpack(argument)
    if unpacked == nil or unpacked == "" then
        err("format-string: first arguments are empty")
        return ""
    end
    local ret = string.format(xpath.string_value(arg[#arg]), unpacked)
    return { ret }
end


local function even(dataxml, arg)
    local firstarg = xpath.number_value(arg[1])
    if not tonumber(firstarg) then
        err("sd:even() - argument is not a number")
        return false
    end
    return { math.fmod(firstarg, 2) == 0 }, nil
end

local function current_frame_number(dataxml, arg)
    publisher.setup_page(nil, "layout_functions#current_framenumber", dataxml)
    local framename = arg[1]
    if framename == nil then return { 1 }, nil end
    local current_framenumber = publisher.current_grid:framenumber(framename)
    return { current_framenumber }, nil
end

local function groupheight(dataxml, arg)
    publisher.setup_page(nil, "layout_functions#groupheight", dataxml)
    local groupname = xpath.string_value(arg[1])
    if not publisher.groups[groupname] then
        err("Can't find group with the name %q", groupname)
        return 0
    end

    local groupcontents = publisher.groups[groupname].contents
    if not groupcontents then
        err("Can't find group with the name %q", groupname)
        return 0
    end
    local height
    local unit = arg[2]
    if unit then
        unit = xpath.string_value(arg[2])
        height = groupcontents.height
        local ret
        if unit == "cm" then
            ret = height / publisher.tenmm_sp
        elseif unit == "mm" then
            ret = height / publisher.onemm_sp
        elseif unit == "in" then
            ret = height / publisher.onein_sp
        elseif unit == "sp" then
            ret = height
        elseif unit == "pc" then
            ret = height / publisher.onepc_sp
        elseif unit == "pt" then
            ret = height / publisher.onept_sp
        elseif unit == "pp" then
            ret = height / publisher.onepp_sp
        elseif unit == "dd" then
            ret = height / publisher.onedd_sp
        elseif unit == "cc" then
            ret = height / publisher.onecc_sp
        else
            err("unsupported unit: %q, please use 'sp', 'pt', 'pc', 'cm', 'mm', 'in', 'dd' or 'cc'", unit)
        end
        return { math.round(ret, 4) }, nil
    else
        local grid = publisher.current_grid
        height = grid:height_in_gridcells_sp(groupcontents.height)
        return { height }, nil
    end
end

local function groupwidth(dataxml, arg)
    publisher.setup_page(nil, "layout_functions#groupwidth", dataxml)
    local groupname = xpath.string_value(arg[1])
    if not publisher.groups[groupname] then
        err("Can't find group with the name %q", groupname)
        return 0
    end
    local groupcontents = publisher.groups[groupname].contents

    if not groupcontents then
        err("Can't find group with the name %q", groupname)
        return 0
    end
    local unit = arg[2]
    local width
    if unit then
        unit = xpath.string_value(arg[2])
        width = groupcontents.width
        local ret
        if unit == "cm" then
            ret = width / publisher.tenmm_sp
        elseif unit == "mm" then
            ret = width / publisher.onemm_sp
        elseif unit == "in" then
            ret = width / publisher.onein_sp
        elseif unit == "sp" then
            ret = width
        elseif unit == "pc" then
            ret = width / publisher.onepc_sp
        elseif unit == "pt" then
            ret = width / publisher.onept_sp
        elseif unit == "pp" then
            ret = width / publisher.onepp_sp
        elseif unit == "dd" then
            ret = width / publisher.onedd_sp
        elseif unit == "cc" then
            ret = width / publisher.onecc_sp
        else
            err("unsupported unit: %q, please use 'sp', 'pt', 'pc', 'cm', 'mm', 'in', 'dd' or 'cc'", unit)
        end
        return { math.round(ret, 4) }, nil
    else
        local grid = publisher.current_grid
        width = grid:width_in_gridcells_sp(groupcontents.width)
        return { width }, nil
    end
end


local function odd(dataxml, arg)
    local firstarg = arg[1]
    local num, msg = xpath.number_value(firstarg)
    if msg then return nil, msg end
    if not tonumber(num) then
        err("sd:odd() - argument is not a number")
        return false
    end
    return { math.fmod(num, 2) ~= 0 }, nil
end

local function variable(dataxml, arg)
    local args = {}
    for i = 1, #arg do
        args[#args + 1] = xpath.string_value(arg[i])
    end
    local varname = table.concat(args)
    local var = dataxml.vars[varname]
    return {var}, nil
end

local function attr(dataxml, arg)
    local attname = table.concat(arg)
    local att = dataxml[attname]
    return { att }, nil
end

local function variable_exists(dataxml, arg)
    local varname = xpath.string_value(arg[1])
    return { dataxml.vars[varname] ~= nil }, nil
end

-- SHA-1
local function shaone(dataxml, arg)
    local message = table.concat(arg)
    local ret = sha.sha1(message)
    return { ret }, nil
end

local function sha256(dataxml, arg)
    local message = table.concat(arg)
    local ret = sha.sha256(message)
    return { ret }, nil
end

local function sha512(dataxml, arg)
    local message = table.concat(arg)
    local ret = sha.sha512(message)
    return { ret }, nil
end

local function md5(dataxml, arg)
    local message = table.concat(arg)
    local ret = sha.md5(message)
    return { ret }, nil
end

-- convert a textual dimension (e.g. '2cm') to a scalar in another dimension.
local function tounit(dataxml, arg)
    local unit = arg[1]
    local decimal = arg[3] or 0
    local width = tex.sp(arg[2])
    local ret
    if unit == "cm" then
        ret = width / publisher.onecm_sp
    elseif unit == "mm" then
        ret = width / publisher.onemm_sp
    elseif unit == "in" then
        ret = width / publisher.onein_sp
    elseif unit == "sp" then
        ret = width
    elseif unit == "pc" then
        ret = width / publisher.onepc_sp
    elseif unit == "pt" then
        ret = width / publisher.onept_sp
    elseif unit == "pp" then
        ret = width / publisher.onepp_sp
    elseif unit == "dd" then
        ret = width / publisher.onedd_sp
    elseif unit == "cc" then
        ret = width / publisher.onecc_sp
    else
        err("unsupported unit: %q, please use 'sp', 'pt', 'pc', 'cm', 'mm', 'in', 'dd' or 'cc'", unit)
    end
    return { math.round(ret, decimal) }, nil
end

local function fnDimexpr(dataxml, arg)
    local unit = xpath.string_value(arg[1])
    local secondarg = xpath.string_value(arg[2])
    local ret = de.string_to_tokenlist(secondarg,dataxml)
    local fun = load(" value = " .. ret)
    if not fun then return nil, "error in sd:dimexpr" end
    fun()
    if unit == "cm" then
        ret = value / publisher.onecm_sp
    elseif unit == "mm" then
        ret = value / publisher.onemm_sp
    elseif unit == "in" then
        ret = value / publisher.onein_sp
    elseif unit == "sp" then
        ret = value
    elseif unit == "pc" then
        ret = value / publisher.onepc_sp
    elseif unit == "pt" then
        ret = value / publisher.onept_sp
    elseif unit == "pp" then
        ret = value / publisher.onepp_sp
    elseif unit == "dd" then
        ret = value / publisher.onedd_sp
    elseif unit == "cc" then
        ret = value / publisher.onecc_sp
    else
        err("unsupported unit: %q, please use 'sp', 'pt', 'pc', 'cm', 'mm', 'in', 'dd' or 'cc'", unit)
    end

    return {math.round(ret,3)}, nil
end
-- Turn &lt;b&gt;Hello&lt;b /&gt; into an HTML table and then into XML structure.
local function decode_html(dataxml, arg)
    if arg == nil then
        arg = dataxml
    end
    local firstarg = xpath.string_value(arg[1])
    if type(firstarg) == "string" then
        local msg = publisher.splib.htmltoxml(firstarg)
        if msg == nil then
            err("decode-html failed")
            return nil
        end
        -- two dummy tags because xpath.parse_raw removes the surrounding table
        local ret = luxor.parse_xml("<dummy><dummy>" .. msg .. "</dummy></dummy>")
        return ret
    end
end

local function decode_base64(dataxml, arg)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local data = xpath.string_value(arg[1])
    data = string.gsub(data, '[^' .. b .. '=]', '')
    local a = (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
    return { a }, nil
end

local function count_saved_pages(dataxml, arg)
    local tmp = publisher.pagestore[arg[1]]
    if not tmp then
        return { 0 }, "count-saved-pages(): no saved pages found. Return 0"
    else
        return { #tmp }, nil
    end
end

local function randomitem(dataxml, arg)
    local x = math.random(#arg)
    return { arg[x] }, nil
end

local function romannumeral(dataxml, arg)
    return { tex.romannumeral(xpath.number_value(arg[1])) }, nil
end

local function aspectratio(dataxml, arg)
    local filename, pagenumber, box, _ = get_filename_pagenum_box_unit_from_arg(arg)
    local img = publisher.imageinfo(filename, pagenumber, box)
    return { img.img.xsize / img.img.ysize }, nil
end

local function pageheight(dataxml, arg)
    publisher.setup_page(nil, "layout_functions#pageheight", dataxml)
    local unit = arg[1] or "mm"
    if unit then
        local width = publisher.current_page.height
        local ret
        if unit == "cm" then
            ret = width / publisher.tenmm_sp
        elseif unit == "mm" then
            ret = width / publisher.onemm_sp
        elseif unit == "in" then
            ret = width / publisher.onein_sp
        elseif unit == "sp" then
            ret = width
        elseif unit == "pc" then
            ret = width / publisher.onepc_sp
        elseif unit == "pt" then
            ret = width / publisher.onept_sp
        elseif unit == "pp" then
            ret = width / publisher.onepp_sp
        elseif unit == "dd" then
            ret = width / publisher.onedd_sp
        elseif unit == "cc" then
            ret = width / publisher.onecc_sp
        else
            err("unsupported unit: %q, please use 'sp', 'pt', 'pc', 'cm', 'mm', 'in', 'dd' or 'cc'", unit)
        end
        return { math.round(ret, 0) }, nil
    end
end


local function pagewidth(dataxml, arg)
    publisher.setup_page(nil, "layout_functions#pagewidth", dataxml)
    local unit = arg[1] or "mm"
    if unit then
        local width = publisher.current_page.width
        local ret
        if unit == "cm" then
            ret = width / publisher.tenmm_sp
        elseif unit == "mm" then
            ret = width / publisher.onemm_sp
        elseif unit == "in" then
            ret = width / publisher.onein_sp
        elseif unit == "sp" then
            ret = width
        elseif unit == "pc" then
            ret = width / publisher.onepc_sp
        elseif unit == "pt" then
            ret = width / publisher.onept_sp
        elseif unit == "pp" then
            ret = width / publisher.onepp_sp
        elseif unit == "dd" then
            ret = width / publisher.onedd_sp
        elseif unit == "cc" then
            ret = width / publisher.onecc_sp
        else
            err("unsupported unit: %q, please use 'sp', 'pt', 'pc', 'cm', 'mm', 'in', 'dd' or 'cc'", unit)
        end
        return { math.round(ret, 0) }, nil
    end
end

local function fnVisiblePagenumber(dataxml, arg)
    local firstarg = xpath.string_value(arg[1])
    local vpn = visiblepagenumber(firstarg)
    return { vpn }, nil
end

local function loremipsum(dataxml, arg)
    local count = 1
    if #arg == 1 then
        local num, msg = xpath.number_value(arg[1])
        if msg then return nil, msg end
        count = num
    end

    local lorem = [[
        Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
        tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
        veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea
        commodo consequat. Duis aute irure dolor in reprehenderit in voluptate
        velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint
        occaecat cupidatat non proident, sunt in culpa qui officia deserunt
        mollit anim id est laborum.
    ]]
    return { string.rep(lorem:gsub("^%s*(.-)%s*$", "%1"):gsub("[%s\n]+", " "), count, " ") }, nil
end

local sdns = "urn:speedata:2009/publisher/functions/en"


local funcs = {
    { "allocated",           sdns, fnAllocated,          1, 4 },
    { "alternating",         sdns, fnAlternating,        1, -1 },
    { "aspectratio",         sdns, aspectratio,          1, 3 },
    { "attr",                sdns, attr,                 1, -1 },
    { "count-saved-pages",   sdns, count_saved_pages,    1, 1 },
    { "current-column",      sdns, current_column,       0, 1 },
    { "current-framenumber", sdns, current_frame_number, 0, 1 },
    { "current-page",        sdns, fnCurrentPage,        0, 0 },
    { "current-row",         sdns, fnCurrentRow,         0, 1 },
    { "decode-base64",       sdns, decode_base64,        1, 1 },
    { "decode-html",         sdns, decode_html,          1, 1 },
    { "dimexpr",             sdns, fnDimexpr,            2, 2 },
    { "dummytext",           sdns, loremipsum,           0, 1 },
    { "even",                sdns, even,                 1, 1 },
    { "file-exists",         sdns, file_exists,          1, 1 },
    { "filecontents",        sdns, filecontents,         1, 1 },
    { "first-free-row",      sdns, first_free_row,       0, 1 },
    { "firstmark",           sdns, firstmark,            1, 1 },
    { "format-number",       sdns, format_number,        1, 3 },
    { "format-string",       sdns, format_string,        1, -1 },
    { "group-height",        sdns, groupheight,          1, 1 },
    { "group-width",         sdns, groupwidth,           1, 1 },
    { "groupheight",         sdns, groupheight,          1, 1 },
    { "groupwidth",          sdns, groupwidth,           1, 1 },
    { "html",                sdns, html,                 1, 1 },
    { "imageheight",         sdns, imageheight,          1, 1 },
    { "imagewidth",          sdns, imagewidth,           1, 1 },
    { "keep-alternating",    sdns, keepalternating,      1, -1 },
    { "lastmark",            sdns, lastmark,             1, 1 },
    { "loremipsum",          sdns, loremipsum,           0, 1 },
    { "md5",                 sdns, md5,                  1, 1 },
    { "merge-pagenumbers",   sdns, fnMergePagenumbers,   1, 4 },
    { "mode",                sdns, mode,                 1, 1 },
    { "number-of-columns",   sdns, fnNumberOfColumns,    0, 1 },
    { "number-of-pages",     sdns, fnNumberOfPages,      1, 1 },
    { "number-of-rows",      sdns, fnNumberOfRows,       0, 1 },
    { "odd",                 sdns, odd,                  1, 1 },
    { "pageheight",          sdns, pageheight,           0, 0 },
    { "pagenumber",          sdns, fnpagenumber,         1, 1 },
    { "pagewidth",           sdns, pagewidth,            0, 0 },
    { "randomitem",          sdns, randomitem,           1, -1 },
    { "reset-alternating",   sdns, reset_alternating,    1, 1 },
    { "romannumeral",        sdns, romannumeral,         1, 1 },
    { "sha1",                sdns, shaone,               1, 1 },
    { "sha256",              sdns, sha256,               1, 1 },
    { "sha512",              sdns, sha512,               1, 1 },
    { "todimen",             sdns, tounit,               1, 1 },
    { "tounit",              sdns, tounit,               1, 1 },
    { "variable-exists",     sdns, variable_exists,      1, 1 },
    { "variable",            sdns, variable,             1, -1 },
    { "visible-pagenumber",  sdns, fnVisiblePagenumber,  1, 1 },
}

local register = publisher.xpath.registerFunction
for _, func in ipairs(funcs) do
    register(func)
end


-- Contains
local function fnContains(dataxml, arg)
    local firstarg = xpath.string_value(arg[1])
    local secondarg = xpath.string_value(arg[2])
    return { publisher.splib.contains(firstarg, secondarg) }, nil
end

-- Matches
local function fnMatches(dataxml, arg)
    local firstarg = xpath.string_value(arg[1])
    local secondarg = xpath.string_value(arg[2])
    return { publisher.splib.matches(firstarg, secondarg) }, nil
end

-- Replace
local function fnReplace(dataxml, arg)
    local firstarg = xpath.string_value(arg[1])
    local secondarg = xpath.string_value(arg[2])
    local thirdarg = xpath.string_value(arg[3])
    return { publisher.splib.replace(firstarg, secondarg, thirdarg) }, nil
end

-- Tokenize is the first function we ask 'splib' for help
local function fnTokenize(dataxml, arg)
    local firstarg = xpath.string_value(arg[1])
    local secondarg = xpath.string_value(arg[2])
    if firstarg == nil or secondarg == nil then
        err("tokenize: one of the arguments is empty")
        return { "" }, nil
    end
    local seq = publisher.splib.tokenize(firstarg, secondarg)
    return seq, nil
end

funcs = {
    { "contains", xpath.fnNS, fnContains, 2, 2 },
    { "matches",  xpath.fnNS, fnMatches,  1, 2 },
    { "tokenize", xpath.fnNS, fnTokenize, 1, 2 },
    { "replace",  xpath.fnNS, fnReplace,  1, 3 },
}

for _, func in ipairs(funcs) do
    register(func)
end


file_end("layout_functions.lua")
