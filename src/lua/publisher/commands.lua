--- This file contains the code for the user commands. They are called from publisher#dispatch.
--
--  commands.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("commands.lua")

require("publisher.fonts")
require("publisher.tabular")
local spotcolors = require("spotcolors")
local par  = require("par")
local metapost = require("publisher.metapost")
do_luafile("css.lua")

local function lineinfo(layout)
    if publisher.newxpath then
        return "line",layout[".__line"], "page", publisher.current_pagenumber
    else
        return nil
    end
end

-- This module contains the commands in the layout file (the tags)
commands = {}

--- A
--- -----
--- Insert a hyperlink into the PDF.
function commands.a( layoutxml,dataxml )
    local interaction = ( publisher.options.interaction ~= false )

    local tab = publisher.dispatch(layoutxml,dataxml)
    local eltname = publisher.elementname(tab[1])
    if not interaction then
        return tab
    end
    local bordercolor = publisher.read_attribute(layoutxml,dataxml,"bordercolor","string")
    local description = publisher.read_attribute(layoutxml,dataxml,"description","string","-")
    local href = publisher.read_attribute(layoutxml,dataxml,"href","string")
    local link = publisher.read_attribute(layoutxml,dataxml,"link","string")
    local page = publisher.read_attribute(layoutxml,dataxml,"page","number")
    local embedded = publisher.read_attribute(layoutxml,dataxml,"embedded","string")
    local structelemobjnum = pdf.reserveobj()
    if false then
    elseif embedded then
        publisher.hlembed(embedded,page,link,bordercolor)
    elseif link then
        publisher.hllink(link,bordercolor)
        if publisher.options.format == "PDF/UA" then
            publisher.hyperlinks[#publisher.hyperlinks]["/StructParent "] = #publisher.struct_root_numtree
            publisher.hyperlinks[#publisher.hyperlinks]["/Contents "] = publisher.utf8_to_utf16_string_pdf(description)
            local tbl = setmetatable({ string.format("%d 0 R",structelemobjnum ) }, {__tostring = function(tbl) return rawget(tbl,1) end } )
            publisher.struct_root_numtree[#publisher.struct_root_numtree + 1] = tbl
        end

    elseif href then
        publisher.hlurl(href,bordercolor)
        if publisher.options.format == "PDF/UA" then
            publisher.hyperlinks[#publisher.hyperlinks]["/StructParent "] = #publisher.struct_root_numtree
            publisher.hyperlinks[#publisher.hyperlinks]["/Contents "] = publisher.utf8_to_utf16_string_pdf(description)
            local tbl = setmetatable({ string.format("%d 0 R",structelemobjnum ) }, {__tostring = function(tbl) return rawget(tbl,1) end } )
            publisher.struct_root_numtree[#publisher.struct_root_numtree + 1] = tbl
        end
    elseif page then
        publisher.hlpage(page,bordercolor)
    end

    if eltname == "Image" or eltname == "Box" then
        local c
        if eltname == "Image" then
            c = tab[1].contents[1]
        else
            c = tab[1].contents
        end
        local ai = publisher.get_action_node(3)
        local data = publisher.hyperlinks[#publisher.hyperlinks]
        ai.data = data

        local stl = node.new("whatsit","pdf_start_link")
        stl.action = ai
        stl.width = -1073741824
        stl.height = -1073741824
        stl.depth = -1073741824

        local enl = node.new("whatsit","pdf_end_link")

        c = node.insert_after(c,c,enl)
        c = node.insert_before(c,c,stl)
        c = node.hpack(c)

        return c
    else
        p = par:new(nil,"a")
        local ch = #publisher.hyperlinks
        for _,j in ipairs(tab) do
            local c = publisher.element_contents(j)
            local params = {hyperlink = ch}
            if publisher.options.format == "PDF/UA" then
                params.role = publisher.get_rolenum("Link")
                params.structelemobjnum = structelemobjnum
                publisher.rolecounter = publisher.rolecounter + 1
                params.rolecounter = publisher.rolecounter
                params.parent = 0
            end
            p:append(c, params )
        end

        return p
    end
end

--- Action
--- ------
--- Create a whatsit node of type `user_defined`. The action
--- `AddToList` is not well tested. Actions are
--- processed  after page ship out. The idea behind that is that we don't
--- really know in advance which elements are put on a page and which are
--- broken to the next page. This way we can find out exactly where something
--- is  placed.
function commands.action( layoutxml,dataxml)
    local tab = publisher.dispatch(layoutxml,dataxml)
    p = par:new(nil,"action")

    for _,j in ipairs(tab) do
        local eltname = publisher.elementname(j)
        if eltname == "AddToList" then
            local n = node.new("whatsit","user_defined")
            n.user_id = publisher.user_defined_addtolist
            n.type = 100  -- type 100: "value is a number"
            n.value = publisher.element_contents(j) -- pointer to the function (int)
            p:append(n)
        elseif eltname == "Mark" then
            local tab = publisher.element_contents(j)
            for _,v in ipairs(tab) do
                local n = node.new("whatsit","user_defined")
                if v.append == true then
                    n.user_id = publisher.user_defined_mark_append -- a magic number
                else
                    n.user_id = publisher.user_defined_mark
                end
                n.type = 115  -- type 115: "value is a string"
                n.value = v.selection
                if v.pdftarget then
                    local d = publisher.mkstringdest("mark" .. tostring(v.selection))
                    if v.shiftup ~= nil then
                        d = node.hpack(d)
                        d.shift = -1 * tex.sp(v.shiftup)
                    end
                    p:append(d)
                end
                p:append(n)
            end
        end
    end
    return p
end



--- AddToList -- obsolete (2.9.3)
--- ---------
--- Return a number. This number is an index to the table `publisher.user_defined_functions` and the value
--- is a function that sets a key of another table.
function commands.add_to_list( layoutxml,dataxml )
    local key        = publisher.read_attribute(layoutxml,dataxml,"key","string")
    local listname   = publisher.read_attribute(layoutxml,dataxml,"list","string")
    local selection  = publisher.read_attribute(layoutxml,dataxml,"select","string")

    local value = xpath.parse(dataxml,selection,layoutxml[".__ns"])
    local var = publisher.xpath.get_variable(listname)
    if not var then var = {} end
    publisher.xpath.set_variable(listname,var)

    local udef = publisher.user_defined_functions
    udef[udef.last + 1] = function() var[#var + 1] = { key , value } end
    udef.last = udef.last + 1
    return udef.last
end

--- AddSearchpath
--- -------------
--- Add the given path to the global search path for image loading etc.
function commands.add_searchpath( layoutxml,dataxml )
    local selection = publisher.read_attribute(layoutxml,dataxml,"select","xpathraw")
    if not selection then
        err("AddSearchpath: Can't add an empty search path")
        return
    end
    selection = table_textvalue(selection)
    if not lfs.isdir(selection) then
        err("AddSearchpath: The path %q does not exist",selection)
        return
    end
    splib.log("info","Add search path","path",selection)
    kpse.add_dir(selection)
end

--- Attribute
--- ---------
--- Create an attribute to be used in a XML structure. The XML structure can be formed via
--- Element and Attribute commands and written to disk with SaveDataset.
function commands.attribute( layoutxml,dataxml )
    local selection = publisher.read_attribute(layoutxml,dataxml,"select","xpath")
    local attname   = publisher.read_attribute(layoutxml,dataxml,"name","string")

    if not selection then return { [".__type"]="attribute", [attname] = "" } end
    -- Escaping the xpath.textvalue makes & into &amp; etc.
    local ret
    if publisher.newxpath then
        ret = { [".__type"]="attribute", [attname] = xpath.string_value(selection) }
    else
        ret = { [".__type"]="attribute", [attname] = xpath.textvalue(selection) }
    end
    return ret
end


function commands.attachfile( layoutxml,dataxml )
    -- destfilename is optional. It defaults to 'ZUGFeRD-invoice.xml' when
    -- attaching a ZUGFeRD file or to the input file name otherwise.
    local inputfilename = publisher.read_attribute(layoutxml,dataxml,"filename","string")
    local selection = publisher.read_attribute(layoutxml,dataxml,"select","xpathraw")
    local destfilename = publisher.read_attribute(layoutxml,dataxml,"name","string")
    local filetype = publisher.read_attribute(layoutxml,dataxml,"type","string","application/octet-stream")


    if filetype == "ZUGFeRD invoice" then
        if not publisher.pro then
            err("attaching ZUGReRD files need a pro plan")
            publisher.has_pro_error = true
            return nil
        end

        if not destfilename then
            warning("AttachFile: please provide a filename for the attachment by setting the attribute name.")
            destfilename = "ZUGFeRD-invoice.xml"
        end
    end

    local filecontents
    local modificationtime
    if selection ~= nil then
        filecontents = publisher.xml_to_string(selection[1],0)
        if not destfilename then
            err("AttachFile: you must provide a file name when reading from selection")
        end
        modificationtime = os.time()
    else
        local path = publisher.find_file(inputfilename)
        if path == nil then
            err("Cannot find file %q",inputfilename)
            return
        end
        local stat = lfs.attributes(path)
        local filename_extension = inputfilename:match("^.*%.(.+)$"):lower()
        destfilename = destfilename or inputfilename
        if destfilename:match("^.*%.(.+)$") == nil then
            warning("AttachFile: name attribute has no file extension, take from source.")
            destfilename = string.format("%s.%s",destfilename,filename_extension)
        end
        modificationtime = stat.modification
        local attachfile,msg = io.open(path,"rb")
        if attachfile == nil then
            err("could not read file %s",msg)
            return
        end
        filecontents = attachfile:read("*all")
        attachfile:close()
    end
    local description = publisher.read_attribute(layoutxml,dataxml,"description","string")
    publisher.attach_file_pdf(filecontents,description,filetype,modificationtime,destfilename)
end

--- AtPageCreation
--- -------------
--- Run these commands when a page is created (as soon as the first element is written to it).
--- You can add header/footer and other repeating elements. These commands are
--- not executed when encountered, rather in `publisher#setup_page()`.
function commands.atpagecreation( layoutxml,dataxml )
    return layoutxml
end

--- AtPageShipout
--- -------------
--- Run these commands when a page is ready to be put in
--- the PDF. You can add header/footer. These commands are
--- not executed when encountered, rather in `publisher#new_page()`.
function commands.atpageshipout( layoutxml,dataxml )
    return layoutxml
end

--- Barcode
--- -------
--- Create a EAN 13 barcode. The width of the barcode depends on the font
--- given in `fontface` (or the default `text`).
function commands.barcode( layoutxml,dataxml )
    if not publisher.pro then
        err("barcodes and qr codes need a pro plan")
        publisher.has_pro_error = true
        return nil
    end
    local colorname      = publisher.read_attribute(layoutxml,dataxml,"color"  ,     "string","black")
    local eclevel        = publisher.read_attribute(layoutxml,dataxml,"eclevel"  ,   "string")
    local fontname       = publisher.read_attribute(layoutxml,dataxml,"fontface" ,   "string")
    local fontfamilyname = publisher.read_attribute(layoutxml,dataxml,"fontfamily",  "string",fontname)
    local height         = publisher.read_attribute(layoutxml,dataxml,"height"   ,   "height_sp")
    local keepfontsize   = publisher.read_attribute(layoutxml,dataxml,"keepfontsize","boolean", "no")
    local overshoot      = publisher.read_attribute(layoutxml,dataxml,"overshoot",   "number")
    local selection      = publisher.read_attribute(layoutxml,dataxml,"select",      "xpath")
    local showtext       = publisher.read_attribute(layoutxml,dataxml,"showtext",    "boolean", "yes")
    local typ            = publisher.read_attribute(layoutxml,dataxml,"type",        "string")
    local width          = publisher.read_attribute(layoutxml,dataxml,"width",       "length_sp")
    if fontname then warning("Barcode/fontface is deprecated and will be removed in version 5. Please use fontfamily instead") end

    if not width then
        local maxwidth
        if publisher.newxpath then
            maxwidth = dataxml.vars["__maxwidth"]
        else
            maxwidth = xpath.get_variable("__maxwidth")
        end
        width = maxwidth
    end

    local fontfamily
    if fontfamilyname then
        fontfamily = publisher.fonts.lookup_fontfamily_name_number[fontfamilyname]
        if not fontfamily then
            err("Fontfamily %q not found.",fontfamilyname or "???")
            fontfamily = 1
        end
    else
        fontfamily = 1
    end
    if typ=="Code128" then
        return barcodes.code128(width,height,fontfamily,selection,showtext)
    elseif typ=="EAN13" then
        return barcodes.ean13(width,height,fontfamily,selection,showtext,overshoot,keepfontsize)
    elseif typ=="QRCode" then
        if eclevel == "L" then eclevel = 1
        elseif eclevel == "M" then eclevel = 2
        elseif eclevel == "Q" then eclevel = 3
        elseif eclevel == "H" then eclevel = 4
        else
            eclevel = nil
        end
        return barcodes.qrcode(width,height,selection,eclevel,colorname)
    else
        err("Unknown barcode type %q", typ or "?")
    end
end

--- Bold text (`<B>`)
--- -------------------
--- Set the contents of this element in boldface
function commands.bold( layoutxml,dataxml )
    local p = par:new(nil,"b")
    local tab = publisher.dispatch(layoutxml,dataxml)
    for _,j in ipairs(tab) do
        local c = publisher.element_contents(j)
        p:append(c,{
            bold = 1,
            role = 0,
        })
    end

    return p
end

--- Br
--- ---
--- Insert a newline
function commands.br( layoutxml,dataxml )
    a = par:new(nil,"br")
    a:append("\n",{})
    return a
end

--- Box
--- ----
--- Draw a rectangular filled area
function commands.box( layoutxml,dataxml )
    local bleed     = publisher.read_attribute(layoutxml,dataxml,"bleed",          "string")
    local colorname = publisher.read_attribute(layoutxml,dataxml,"background-color","string")
    colorname       = publisher.read_attribute(layoutxml,dataxml,"backgroundcolor","string",colorname)
    local graphic   = publisher.read_attribute(layoutxml,dataxml,"graphic",        "string")
    local height    = publisher.read_attribute(layoutxml,dataxml,"height",         "length")
    local width     = publisher.read_attribute(layoutxml,dataxml,"width",          "length")

    local class     = publisher.read_attribute(layoutxml,dataxml,"class",          "string")
    local id        = publisher.read_attribute(layoutxml,dataxml,"id",             "string")

    local css_rules = publisher.css:matches({element = 'box', class=class,id=id}) or {}
    colorname = colorname or css_rules["background-color"] or "black"

    local attribute = {
        ["padding-top"]      = "length",
        ["padding-right"]    = "length",
        ["padding-bottom"]   = "length",
        ["padding-left"]     = "length",
    }

    -- Todo: document length or number
    if tonumber(width) ~= nil then
        width  = current_grid:width_sp(width)
    else
        width = tex.sp(width)
    end
    if tonumber(height) ~= nil then
        height = current_grid:height_sp(tonumber(height))
    else
        height = tex.sp(height)
    end

    local tab = {}

    local tmpattr
    for attname,atttyp in pairs(attribute) do
        tmpattr = publisher.read_attribute(layoutxml,dataxml,attname,atttyp)
        if tmpattr then
            tab[attname] = tmpattr
        end
    end

    if tab["padding-top"]    then tab.padding_top    = tex.sp(tab["padding-top"])    end
    if tab["padding-bottom"] then tab.padding_bottom = tex.sp(tab["padding-bottom"]) end
    if tab["padding-left"]   then tab.padding_left   = tex.sp(tab["padding-left"])   end
    if tab["padding-right"]  then tab.padding_right  = tex.sp(tab["padding-right"])  end


    if css_rules and type(css_rules) == "table" then
        for k,v in pairs(css_rules) do
            tab[k]=v
        end
    end

    if graphic then
        local instr, bbox = metapost.boxgraphic(width,height,graphic)
        if not instr then
            splib.error("Could not create metapost image","graphic",graphic)
            return
        end

        local bx = node.hpack(instr,width,"exactly")
        bx.height = height
        bx = node.vpack(bx)
        return bx, bbox
    end

    local shift_left,shift_up = 0,0

    if tab.padding_left then
        width = width - tab.padding_left
        shift_left = shift_left - tab.padding_left
    end
    if tab.padding_right then
        width = width - tab.padding_right
    end

    if tab.padding_bottom then
        height = height - tab.padding_bottom
    end
    if tab.padding_top then
        height = height - tab.padding_top
        shift_up = shift_up - tab.padding_top
    end


    if bleed then
        local trim = publisher.options.trim or 0
        local positions = string.explode(bleed,",")
        for i,v in ipairs(positions) do
            if v == "top" then
                height = height + trim
                shift_up = trim
            elseif v == "right" then
                width = width + trim
            elseif v == "bottom" then
                height = height + trim
            elseif v == "left" then
                width = width + trim
                shift_left = trim
            end
        end
    end

    local n = publisher.box(width,height,colorname)
    node.set_attribute(n, publisher.att_shift_left, shift_left)
    node.set_attribute(n, publisher.att_shift_up  , shift_up )
    return n
end

--- Bookmark
--- --------
--- PDF bookmarks (for the PDF viewer)
function commands.bookmark( layoutxml,dataxml )
    --- For bookmarks, we need two things:
    ---
    --- 1) a destination and
    --- 2) the bookmark itself that points to the destination.
    ---
    --- So we can safely insert the destination in our text flow but save the
    --- destination code (a number) for later. There is a slight problem now: as
    --- the text flow is asynchronous, we evaluate the bookmark during page
    --- ship out. Then we have the correct order (hopefully)
    local title  = publisher.read_attribute(layoutxml,dataxml,"select","xpath")
    local level  = publisher.read_attribute(layoutxml,dataxml,"level", "number")
    local open_p = publisher.read_attribute(layoutxml,dataxml,"open",  "boolean")


    local hlist = publisher.mkbookmarknodes(level,open_p,title,dataxml)

    if publisher.intextblockcontext == 0 then
        publisher.setup_page(nil,"commands#bookmark",dataxml)
        publisher.output_absolute_position({nodelist = hlist, x = 0, y = 0})
    else
        local p = par:new(nil,"bookmark")
        p:append(hlist)
        return p
    end
end

--- Circle
--- ------
--- Draw a circle or an ellipse
function commands.circle( layoutxml,dataxml )
    local radiusx        = publisher.read_attribute(layoutxml,dataxml,"radiusx", "width_sp")
    local radiusy        = publisher.read_attribute(layoutxml,dataxml,"radiusy", "height_sp", radiusx)
    local framecolorname = publisher.read_attribute(layoutxml,dataxml,"framecolor","string")
    local rulewidth_sp   = publisher.read_attribute(layoutxml,dataxml,"rulewidth","length_sp", 0)
    local colorname      = publisher.read_attribute(layoutxml,dataxml,"background-color","string")
    colorname            = publisher.read_attribute(layoutxml,dataxml,"backgroundcolor","string",colorname)
    local class          = publisher.read_attribute(layoutxml,dataxml,"class",          "string")
    local id             = publisher.read_attribute(layoutxml,dataxml,"id",             "string")

    local css_rules = publisher.css:matches({element = 'circle', class=class,id=id}) or {}
    colorname      = colorname      or css_rules["background-color"] or "black"
    framecolorname = framecolorname or css_rules["color"]            or "black"

    return publisher.circle(radiusx,radiusy,colorname,framecolorname,rulewidth_sp)
end

--- Clearpage
--- ---------
--- Finishes the current page
function commands.clearpage( layoutxml,dataxml)
    local matter = publisher.read_attribute(layoutxml,dataxml,"matter","string")
    local pagetype     = publisher.read_attribute(layoutxml,dataxml,"pagetype","string")
    local skippagetype = publisher.read_attribute(layoutxml,dataxml,"skippagetype","string")
    local openon       = publisher.read_attribute(layoutxml,dataxml,"openon","string")
    local force        = publisher.read_attribute(layoutxml,dataxml,"force", "boolean")

    publisher.clearpage({matter = matter,pagetype = pagetype, openon = openon, skippagetype = skippagetype,force = force,dataxml = dataxml})
end


--- Clip
--- --------------
--- Apply a clip on an object for PlaceObject.
function commands.clip( layoutxml,dataxml )
    local clip_top_sp = publisher.read_attribute(layoutxml,dataxml,"top","length_sp", 0)
    local clip_bottom_sp = publisher.read_attribute(layoutxml,dataxml,"bottom","length_sp", 0)
    local clip_left_sp = publisher.read_attribute(layoutxml,dataxml,"left","length_sp", 0)
    local clip_right_sp = publisher.read_attribute(layoutxml,dataxml,"right","length_sp", 0)
    local clip_width_sp = publisher.read_attribute(layoutxml,dataxml,"width","width_sp", 0)
    local clip_height_sp = publisher.read_attribute(layoutxml,dataxml,"height","height_sp", 0)
    local method = publisher.read_attribute(layoutxml,dataxml,"method", "string","clip")

    local tab = publisher.dispatch(layoutxml,dataxml)
    for i=1,#tab do
        local contents = publisher.element_contents(tab[i])


        if node.is_node(contents) then
            -- This case is for <Textblock>...
            tab[i].contents = publisher.clip({
                box = contents,
                clip_top_sp = clip_top_sp,
                clip_bottom_sp = clip_bottom_sp,
                clip_left_sp = clip_left_sp,
                clip_right_sp = clip_right_sp,
                clip_width_sp = clip_width_sp,
                clip_height_sp = clip_height_sp,
                method = method,
            })
        else
            -- This case is for <Table>
            for j=1,#contents do
                if node.is_node(contents[j]) then
                    contents[j] = publisher.clip({
                        box = contents[j],
                        clip_top_sp = clip_top_sp,
                        clip_bottom_sp = clip_bottom_sp,
                        clip_left_sp = clip_left_sp,
                        clip_right_sp = clip_right_sp,
                        clip_width_sp = clip_width_sp,
                        clip_height_sp = clip_height_sp,
                        method = method,
                    })
                end
            end
        end
    end
    return tab
end

--- Color
--- -----
--- Set the color of the enclosed text.
function commands.color( layoutxml, dataxml )
    local colorname = publisher.read_attribute(layoutxml,dataxml,"name","string")
    local colorindex = publisher.get_colorindex_from_name(colorname,"black")

    local p = par:new(nil,"color")

    local prev_fgcolor = publisher.current_fgcolor
    publisher.current_fgcolor = colorindex
    local tab = publisher.dispatch(layoutxml,dataxml)
    publisher.current_fgcolor = prev_fgcolor

    for _,j in ipairs(tab) do
        local c = publisher.element_contents(j)
        p:append(c,{color = colorindex})
    end

    return p
end


--- Column
--- ------
--- Set definitions for a specific column of a table.
function commands.column( layoutxml,dataxml )
    local ret = {}
    ret.minwidth         = publisher.read_attribute(layoutxml,dataxml,"minwidth","width_sp")
    ret.width            = publisher.read_attribute(layoutxml,dataxml,"width","string")
    ret.backgroundcolor  = publisher.read_attribute(layoutxml,dataxml,"background-color","string")
    ret.backgroundcolor  = publisher.read_attribute(layoutxml,dataxml,"backgroundcolor","string",ret.backgroundcolor)
    ret.align            = publisher.read_attribute(layoutxml,dataxml,"align","string")
    ret.valign           = publisher.read_attribute(layoutxml,dataxml,"valign","string")
    ret.padding_left     = publisher.read_attribute(layoutxml,dataxml,"padding-left","length_sp")
    ret.padding_right    = publisher.read_attribute(layoutxml,dataxml,"padding-right","length_sp")

    return ret
end


--- Columns
--- -------
--- Set the width of a table to a fixed size. Expects multiple occurrences of element
--- Column as the child elements.
function commands.columns( layoutxml,dataxml )
    local tab = publisher.dispatch(layoutxml,dataxml)
    return tab
end

function commands.compatibility( layoutxml,dataxml )
    local movecursoronrightedge = publisher.read_attribute(layoutxml,dataxml,"movecursoronplaceobject", "boolean","yes")
    publisher.compatibility.luaxmlreader = publisher.read_attribute(layoutxml,dataxml,"luaxmlreader", "boolean","no")

    publisher.compatibility.movecursoronrightedge = movecursoronrightedge
end

--- CopyOf
--- ------
--- Return the contents of a variable. Warning: this function does not actually copy the contents, so the name is a bit misleading.
function commands.copy_of( layoutxml,dataxml )
    local selection
    if layoutxml[1] and #layoutxml[1] > 0 then
        return table.concat(layoutxml)
    else
        if publisher.newxpath then
            local selectionstring = publisher.read_attribute(layoutxml,dataxml,"select", "string")
            local seq, msg = dataxml:eval(selectionstring)
            if msg then
                err(msg)
                return
            end
            selection = {}
            for i, itm in ipairs(seq) do
                if #itm > 0 then
                    for j = 1, #itm do
                        selection[#selection+1] = itm[j]
                    end
                else
                    selection[#selection+1] = itm
                end
            end
            if type(selection) == "table" and selection[1] == "expand" then
                local tmp = publisher.dispatch(selection,dataxml)
                return tmp
            end
        else
            selection = publisher.read_attribute(layoutxml,dataxml,"select", "string")
            local ok
                ok,selection = xpath.parse_raw(dataxml,selection,layoutxml[".__ns"])
            if not ok then
                err(selection)
                return nil
            end
            if type(selection) == "table" and selection[1] == "expand"  then
                local tmp = publisher.dispatch(selection,dataxml)
                return tmp
            end
        end
        return publisher.deepcopy(selection)
    end
end

--- DefineColor
--- -----------
--- Colors can be in model cmyk or rgb.
function commands.define_color( layoutxml,dataxml )
    local name  = publisher.read_attribute(layoutxml,dataxml,"name","string")
    local value = publisher.read_attribute(layoutxml,dataxml,"value","string")
    local alpha = publisher.read_attribute(layoutxml,dataxml,"alpha","number")
    local model = publisher.read_attribute(layoutxml,dataxml,"model","string")
    local colorname = publisher.read_attribute(layoutxml,dataxml,"colorname","string")
    local overprint = publisher.read_attribute(layoutxml,dataxml,"overprint","boolean")

    local color = setmetatable({}, publisher.colormetatable)
    color.overprint = overprint
    if alpha then
        publisher.transparentcolorstack()
        -- color.alpha is in the range of 0 to 100
        color.alpha = alpha
    end
    local op
    if overprint then
        op = "/GS0 gs"
    else
        op = ""
    end

    local mpname = function(str)
        local invalid = "[^a-zA-Z]"
        if string.find(str,invalid) then
            local mpcolorname = string.gsub(str,invalid,"")
            publisher.metapostcolorwarnings[#publisher.metapostcolorwarnings+1] = {str,mpcolorname}
            return mpcolorname
        end
        return str
    end

    if model=="cmyk" then
        color.c = publisher.read_attribute(layoutxml,dataxml,"c","number")
        color.m = publisher.read_attribute(layoutxml,dataxml,"m","number")
        color.y = publisher.read_attribute(layoutxml,dataxml,"y","number")
        color.k = publisher.read_attribute(layoutxml,dataxml,"k","number")
        color.pdfstring = string.format("%s %g %g %g %g k %g %g %g %g K", op, color.c/100, color.m/100, color.y/100, color.k/100,color.c/100, color.m/100, color.y/100, color.k/100)
        publisher.metapostcolors[mpname(name)] = {model = "cmyk", c = color.c/100, m = color.m/100, y = color.y/100, k = color.k/100 }
    elseif model=="rgb" then
        color.r = publisher.read_attribute(layoutxml,dataxml,"r","number") / 100
        color.g = publisher.read_attribute(layoutxml,dataxml,"g","number") / 100
        color.b = publisher.read_attribute(layoutxml,dataxml,"b","number") / 100
        color.pdfstring = string.format("%s %g %g %g rg %g %g %g RG", op, color.r, color.g, color.b, color.r,color.g, color.b)
        publisher.metapostcolors[mpname(name)] = {model = "rgb", r = color.r, g = color.g, b = color.b }
    elseif model=="RGB" then
        color.r = publisher.read_attribute(layoutxml,dataxml,"r","number") / 255
        color.g = publisher.read_attribute(layoutxml,dataxml,"g","number") / 255
        color.b = publisher.read_attribute(layoutxml,dataxml,"b","number") / 255
        color.pdfstring = string.format("%s %g %g %g rg %g %g %g RG", op, color.r, color.g, color.b, color.r,color.g, color.b)
        publisher.metapostcolors[mpname(name)] = {model = "rgb", r = color.r, g = color.g, b = color.b }
    elseif model=="gray" then
        color.g = publisher.read_attribute(layoutxml,dataxml,"g","number")
        color.pdfstring = string.format("%s %g g %g G",op,color.g/100,color.g/100)
        publisher.metapostcolors[mpname(name)] = {model = "gray", k = color.g }
    elseif model=="spotcolor" then
        if not publisher.pro then
            err("spot colors need a Pro plan")
            publisher.has_pro_error = true
            return
        end
        local c = publisher.read_attribute(layoutxml,dataxml,"c","number")
        local m = publisher.read_attribute(layoutxml,dataxml,"m","number")
        local y = publisher.read_attribute(layoutxml,dataxml,"y","number")
        local k = publisher.read_attribute(layoutxml,dataxml,"k","number")
        color.colornum = spotcolors.register(colorname,c,m,y,k)
    elseif value then
        local calpha
        color.r,color.g,color.b,calpha = publisher.getrgb(value)
        if calpha then
            color.alpha = calpha
        end
        color.pdfstring = string.format("%s %g %g %g rg %g %g %g RG", op, color.r, color.g, color.b, color.r,color.g, color.b)
        model = "rgb"
        publisher.metapostcolors[mpname(name)] = {model = model, r = color.r, g = color.g, b = color.b }
    else
        err("Unknown color model: %s",model or "?")
    end

    color.model = model
    color.index = publisher.register_color(name)
    splib.log("info","Define color","name",name,"index",color.index)
    publisher.colors[name]=color
end


--- DefineColorprofile
--- -----------
--- Associate a name with a color profile.
function commands.define_colorprofile( layoutxml,dataxml )
    local condition  = publisher.read_attribute(layoutxml,dataxml,"condition", "string")
    local colors     = publisher.read_attribute(layoutxml,dataxml,"colors",    "number" , 4)
    local filename   = publisher.read_attribute(layoutxml,dataxml,"filename",  "string")
    local identifier = publisher.read_attribute(layoutxml,dataxml,"identifier","string")
    local info       = publisher.read_attribute(layoutxml,dataxml,"info",      "string")
    local name       = publisher.read_attribute(layoutxml,dataxml,"name",      "string")
    local registry   = publisher.read_attribute(layoutxml,dataxml,"registry",  "string","http://www.color.org")
    spotcolors.register_colorprofile(name,{filename = filename, identifier = identifier, condition = condition, registry = registry, colors = colors, info = info })
end

--- DefineGraphic
--- ------------
--- Define a metapost graphic for later use
function commands.define_graphic(layoutxml,dataxml)
    local name = publisher.read_attribute(layoutxml,dataxml,"name","string")
    local code
    if publisher.newxpath then
        code = xpath.string_value(layoutxml)
    else
        code = layoutxml[1]
    end
    publisher.metapostgraphics[name] = code
end


--- Define Textformat
--- ----------------
--- A text format defines the alignment and indentation of a paragraph.
---
--- The rules for textformat:
---
--- * if a paragraph has a textformat then use it, end
--- * if the textblock has a textformat then use it, end
--- * use the textformat `text` end
function commands.define_textformat(layoutxml,dataxml)
    local alignment    = publisher.read_attribute(layoutxml,dataxml,"alignment",   "string")
    local indentation  = publisher.read_attribute(layoutxml,dataxml,"indentation", "length")
    local name         = publisher.read_attribute(layoutxml,dataxml,"name",        "string")
    local rows         = publisher.read_attribute(layoutxml,dataxml,"rows",        "number")
    local bordertop    = publisher.read_attribute(layoutxml,dataxml,"border-top",  "string")
    local borderbottom = publisher.read_attribute(layoutxml,dataxml,"border-bottom","string")
    local htmlverticalspacing = publisher.read_attribute(layoutxml,dataxml,"html-vertical-spacing","string")
    local margintop     = publisher.read_attribute(layoutxml,dataxml,"margin-top",    "string")
    local marginbottom  = publisher.read_attribute(layoutxml,dataxml,"margin-bottom", "string")
    local paddingtop    = publisher.read_attribute(layoutxml,dataxml,"padding-top",   "string")
    local colpaddingtop = publisher.read_attribute(layoutxml,dataxml,"column-padding-top", "length_sp")
    local paddingbottom = publisher.read_attribute(layoutxml,dataxml,"padding-bottom","string")
    local breakbelow    = publisher.read_attribute(layoutxml,dataxml,"break-below",   "boolean", true)
    local orphan        = publisher.read_attribute(layoutxml,dataxml,"orphan",        "booleanornumber", false)
    local widow         = publisher.read_attribute(layoutxml,dataxml,"widow",         "booleanornumber", false)
    local hyphenate     = publisher.read_attribute(layoutxml,dataxml,"hyphenate",     "boolean", true)
    local hyphenchar    = publisher.read_attribute(layoutxml,dataxml,"hyphenchar",    "string")
    local tab           = publisher.read_attribute(layoutxml,dataxml,"tab",           "string")
    local filllastline  = publisher.read_attribute(layoutxml,dataxml,"fill-last-line","number")
    local margintopboxstart  = publisher.read_attribute(layoutxml,dataxml,"margin-top-box-start","length_sp")
    local fmt = {
        colpaddingtop = colpaddingtop,
        htmlverticalspacing = htmlverticalspacing,
        name = name,
    }

    if alignment == "leftaligned" or alignment == "rightaligned" or alignment == "centered" or alignment == "start" or alignment == "end" then
        fmt.alignment = alignment
    else
        fmt.alignment = "justified"
    end
    if orphan == false then
        fmt.orphan = 2
    elseif tonumber(orphan) then
        fmt.orphan = tonumber(orphan)
    else
        fmt.orphan = 0
    end

    if widow == false then
        fmt.widow = 2
    elseif tonumber(widow) then
        fmt.widow = tonumber(widow)
    else
        fmt.widow = 0
    end

    fmt.disable_hyphenation = not hyphenate
    fmt.hyphenchar = hyphenchar

    if indentation then
        fmt.indent = tex.sp(indentation)
    end
    if rows then
        fmt.rows = rows
    else
        fmt.rows = 1
    end
    if bordertop then
        fmt.bordertop = tex.sp(bordertop)
    end
    if borderbottom then
        fmt.borderbottom = tex.sp(borderbottom)
    end
    if margintop then
        fmt.margintop = tex.sp(margintop)
    end
    if marginbottom then
        fmt.marginbottom = tex.sp(marginbottom)
    end
    if paddingtop then
        fmt.paddingtop = tex.sp(paddingtop)
    end
    if paddingbottom then
        fmt.paddingbottom = tex.sp(paddingbottom)
    end

    fmt.breakbelow = breakbelow
    if margintopboxstart then
        fmt.margintopboxstart = margintopboxstart
    else
        fmt.margintopboxstart = fmt.margintop
    end

    fmt.tab = tab

    if filllastline then
        fmt.filllastline = filllastline
    end

    publisher.textformats[name] = fmt
end


--- Define FontAlias
--- -----------------
--- Define a font alias.
function commands.define_fontalias( layoutxml,dataxml )
    local existing = publisher.read_attribute(layoutxml,dataxml,"existing", "string" )
    local alias    = publisher.read_attribute(layoutxml,dataxml,"alias",    "string" )
    publisher.fontaliases[alias] = existing
end

--- Define Fontfamily
--- -----------------
--- Define a font family. A font family must consist of a `Regular` shape, optional are `Bold`,
--- `BoldItalic` and `Italic`.
function commands.define_fontfamily( layoutxml,dataxml )
    -- fontsize and baselineskip are in dtp points (bp, 1 bp ≈ 65782 sp)
    -- Concrete font instances are created here. fontsize and baselineskip are known
    local name         = publisher.read_attribute(layoutxml,dataxml,"name",    "string" )
    local size         = publisher.read_attribute(layoutxml,dataxml,"fontsize","string")
    local baselineskip = publisher.read_attribute(layoutxml,dataxml,"leading", "string")
    if size == nil then
        err("DefineFontfamily: no size given.")
        return
    end

    -- warning: this is not the same! See bug #99.
    if tonumber(size) == nil then
        size = tex.sp(size)
    else
        size = tex.sp(tostring(size) .."pt")
    end

    if baselineskip == nil then
        err("DefineFontfamily: no leading given.")
        return
    end
    if tonumber(baselineskip) == nil then
        baselineskip = tex.sp(baselineskip)
    else
        baselineskip = tex.sp(tostring(baselineskip) .."pt")
    end

    local elementname,fontface
    local regular, bold, italic, bolditalic
    for i,v in ipairs(layoutxml) do
        elementname = v[".__local_name"]
        fontface = publisher.read_attribute(v,dataxml,"fontface","string")
        fontface = publisher.get_fontname(fontface)
        if type(v) ~= "table" then
            -- ignore
        elseif elementname=="Regular" then
            regular = fontface
        elseif elementname=="Bold" then
            bold = fontface
        elseif elementname =="Italic" then
            italic = fontface
        elseif elementname =="BoldItalic" then
            bolditalic = fontface
        end
    end
    local fam = publisher.define_fontfamily(regular,bold,italic,bolditalic,name,size,baselineskip)
end

--- DefineMatter
function commands.definematter(layoutxml,dataxml)
    local name       = publisher.read_attribute(layoutxml,dataxml,"name","string")
    local label      = publisher.read_attribute(layoutxml,dataxml,"label","string")
    local prefix     = publisher.read_attribute(layoutxml,dataxml,"prefix","string")
    local resetafter = publisher.read_attribute(layoutxml,dataxml,"resetafter","boolean")
    local resetbefore = publisher.read_attribute(layoutxml,dataxml,"resetbefore","boolean")
    publisher.matters[name] = {label = label, prefix = prefix, resetafter = resetafter, resetbefore = resetbefore }
end

--- Element
--- -------
--- Create an element for use with Attribute and SaveDataset
function commands.element( layoutxml,dataxml )
    local name = publisher.read_attribute(layoutxml,dataxml,"name","string")
    local ret = {
        [".__local_name"] = name,
        [".__name"] = name,
        [".__attributes"] = {},
        [".__namespace"] = "",
        [".__ns"] = {},
        [".__type"] = "element",
    }

    local tab = publisher.dispatch(layoutxml,dataxml)
    for i,v in ipairs(tab) do
        local contents = publisher.element_contents(v)
        if contents then
            local eltname = publisher.elementname(v)
            if contents[".__type"]=="attribute" then
                -- Attribute
                for _k,_v in pairs(contents) do
                    if _k ~= ".__type" then
                        ret[_k] = _v
                        ret[".__attributes"][_k] = _v
                    end
                end
            elseif eltname == "Value" then
                ret[#ret + 1] = contents
            else
                -- .__local_name can be nil if we add Elements in another Element
                -- The Elements are stored in sub-tables
                if contents[".__local_name"] == nil then
                    for i=1,#contents do
                        ret[#ret + 1] = contents[i]
                    end
                else
                    ret[#ret + 1] = contents
                end
            end
        end
    end
    return ret
end


--- FontFace
--- --------
--- Set the font face (family) of the enclosed text.
function commands.fontface( layoutxml,dataxml )
    local fontfamily   = publisher.read_attribute(layoutxml,dataxml,"fontfamily","string")
    local familynumber = publisher.fonts.lookup_fontfamily_name_number[fontfamily]
    if not familynumber then
        err("font: family %q unknown",fontfamily)
    else
        local p = par:new(nil,"fontface")
        local tab = publisher.dispatch(layoutxml,dataxml)
        for _,j in ipairs(tab) do
            local c = publisher.element_contents(j)
            p:append(c,{fontfamily = familynumber})
        end

        return p
    end
end

--- ForAll
--- --------
--- Execute the child elements for all elements given by the `select` attribute.
function commands.forall( layoutxml,dataxml )
    local limit = publisher.read_attribute(layoutxml,dataxml,"limit","number")
    local start = publisher.read_attribute(layoutxml,dataxml,"start","number")

    local tab = {}
    if publisher.newxpath then
        if limit or start then
            splib.error("ForAll: the new xpath parser does not allow limit or start, please use predicates instead.")
        end
        local copysequence = dataxml.sequence
        local selection = publisher.read_attribute(layoutxml,dataxml,"select","xpathraw")
        dataxml.size = #selection
        local savepos = dataxml.pos
        for i = 1, #selection do
            dataxml.pos = i
            dataxml.sequence = {selection[i]}
            local tmp_tab = publisher.dispatch(layoutxml,dataxml)
            for j = 1, #tmp_tab do
                tab[#tab+1] = tmp_tab[j]
            end
        end
        dataxml.pos = savepos
        dataxml.sequence = copysequence
        return tab
    end

    local tmp_tab
    local current_position
    current_position = publisher.xpath.get_variable("__position")
    local selection = publisher.read_attribute(layoutxml,dataxml,"select","xpathraw")
    if not selection then
        err("Can't iterate over an unknown sequence")
        return {}
    end

    limit = limit or #selection
    if limit > #selection then
        limit = #selection
    end
    start = start or 1

    for i = start,limit do
        publisher.xpath.set_variable("__position",i)
        if type(selection[i]) == "table" then
            selection[i][".__context"] = selection
        end
        tmp_tab = publisher.dispatch(layoutxml,selection[i])
        for j=1,#tmp_tab do
            tab[#tab + 1] = tmp_tab[j]
        end
    end
    publisher.xpath.set_variable("__position",current_position)
    return tab
end

--- Frame
--- --------------
--- Apply a frame on an object for PlaceObject. Frames can be nested (with Transformation)
function commands.frame( layoutxml,dataxml )
    local tab = publisher.dispatch(layoutxml,dataxml)
    local b_radius         = publisher.read_attribute(layoutxml,dataxml,"border-radius", "string")
    local b_b_r_radius     = publisher.read_attribute(layoutxml,dataxml,"border-bottom-right-radius", "string")
    local b_t_r_radius     = publisher.read_attribute(layoutxml,dataxml,"border-top-right-radius",    "string")
    local b_t_l_radius     = publisher.read_attribute(layoutxml,dataxml,"border-top-left-radius",     "string")
    local b_b_l_radius     = publisher.read_attribute(layoutxml,dataxml,"border-bottom-left-radius",  "string")
    local framecolor       = publisher.read_attribute(layoutxml,dataxml,"framecolor",                 "string")
    local backgroundcolor  = publisher.read_attribute(layoutxml,dataxml,"background-color",            "string")
    backgroundcolor        = publisher.read_attribute(layoutxml,dataxml,"backgroundcolor",            "string", backgroundcolor)
    local rulewidth_sp     = publisher.read_attribute(layoutxml,dataxml,"rulewidth",                  "length_sp", 26312) -- 0.4bp
    local class            = publisher.read_attribute(layoutxml,dataxml,"class",                      "string")
    local id               = publisher.read_attribute(layoutxml,dataxml,"id",                         "string")
    local clip             = publisher.read_attribute(layoutxml,dataxml,"clip",                       "boolean", true)

    local css_rules = publisher.css:matches({element = 'frame', class=class,id=id}) or {}

    b_b_r_radius = b_b_r_radius or b_radius or css_rules["border-bottom-right-radius"]
    b_b_l_radius = b_b_l_radius or b_radius or css_rules["border-bottom-left-radius"]
    b_t_r_radius = b_t_r_radius or b_radius or css_rules["border-top-right-radius"]
    b_t_l_radius = b_t_l_radius or b_radius or css_rules["border-top-left-radius"]

    for i=1,#tab do
        local contents = publisher.element_contents(tab[i])
        if node.is_node(contents) then
            -- This case is for <Textblock>...
            if backgroundcolor then
                contents = publisher.background(contents,backgroundcolor)
            end
            tab[i].contents = publisher.frame({
                box       = contents,
                clip      = clip,
                colorname = framecolor,
                rulewidth = rulewidth_sp,
                b_b_r_radius = tex.sp(b_b_r_radius or 0),
                b_t_r_radius = tex.sp(b_t_r_radius or 0),
                b_t_l_radius = tex.sp(b_t_l_radius or 0),
                b_b_l_radius = tex.sp(b_b_l_radius or 0),
            })
        else
            -- This case is for <Table>
            for j=1,#contents do
                if node.is_node(contents[j]) then
                    if backgroundcolor then
                        contents[j] = publisher.background(contents[j],backgroundcolor)
                    end
                    contents[j] = publisher.frame({
                        box       = contents[j],
                        clip      = clip,
                        colorname = framecolor,
                        rulewidth = rulewidth_sp,
                        b_b_r_radius = tex.sp(b_b_r_radius or 0),
                        b_t_r_radius = tex.sp(b_t_r_radius or 0),
                        b_t_l_radius = tex.sp(b_t_l_radius or 0),
                        b_b_l_radius = tex.sp(b_b_l_radius or 0),
                    })
                end
            end
        end
    end
    return tab
end

--- Function
--- -----
---
function commands.func(layoutxml, dataxml)
    local name = publisher.read_attribute(layoutxml, dataxml, "name", "string")
    local params = {}

    local exploded = string.explode(name,":")
    if #exploded ~= 2 then
        err("function name needs a prefix and a name")
    end
    local prefix, functionname
    prefix = exploded[1]
    functionname = exploded[2]
    local ns = dataxml.namespaces[prefix]
    if not ns then
        err("No namespace defined for prefix %q",prefix)
        return
    end

    for i = 1, #layoutxml do
        local thisitem = layoutxml[i]
        if xpath.is_element(thisitem) and thisitem[".__name"] == "Param" then
            local attr = thisitem[".__attributes"]
            params[#params+1] = attr.name
        end
    end

    local fn = function(dataxml,arg)
        local copy = dataxml:copy()
        for i = 1, #arg do
            copy.vars[params[i]] = arg[i]
        end

        local x = publisher.dispatch(layoutxml,copy)
        local res = {}
        local has_value = false
        for i = 1, #x do
            local thiselt = x[i]
            local eltname = publisher.elementname(thiselt)
            if eltname ~= "Param" then
                res[#res+1] = thiselt
            end
            if eltname == "Value" then
                has_value = true
            end
        end

        res.raw = not has_value
        return res,nil
    end
    -- name, namespace, function, minarg, maxarg
    xpath.registerFunction({functionname,ns,fn,#params,#params})
end

--- Param
--- -----
---
function commands.param(layoutxml, dataxml)
    local name = publisher.read_attribute(layoutxml, dataxml, "name", "string")
    return name
end
--- Grid
--- -----
--- Set the grid in a group (also in a pagetype?)
function commands.grid( layoutxml,dataxml )
    local width  = publisher.read_attribute(layoutxml,dataxml,"width",  "length_sp")
    local height = publisher.read_attribute(layoutxml,dataxml,"height", "length_sp") -- shouldn't this be height_sp??? --PG
    local nx     = publisher.read_attribute(layoutxml,dataxml,"nx",     "string")
    local ny     = publisher.read_attribute(layoutxml,dataxml,"ny",     "string")
    local dx     = publisher.read_attribute(layoutxml,dataxml,"dx",     "length_sp")
    local dy     = publisher.read_attribute(layoutxml,dataxml,"dy",     "length_sp")

    -- layoutxml and dataxml are used when determining the grid of a pagetype
    return { width = width, height = height, nx = tonumber(nx), ny = tonumber(ny), dx = dx, dy = dy , layoutxml = layoutxml, dataxml = dataxml }
end

--- Group
--- -----
--- Create a virtual area
function commands.group( layoutxml,dataxml )
    local elementname
    local grid
    publisher.setup_page(nil,"commands#group",dataxml)
    local groupname = publisher.read_attribute(layoutxml,dataxml,"name", "string")

    if publisher.groups[groupname] == nil then
        splib.log("debug","Create group","name",groupname)
    else
        splib.log("debug","Re-use group","name",groupname)
        -- The old nodes are still in the group. We should clean the nodes
        -- but this cleans too much.
        node.flush_list(publisher.groups[groupname].contents)
        publisher.groups[groupname] = nil
    end

    for _,v in ipairs(layoutxml) do
        elementname=v[".__local_name"]
        if type(v)=="table" and elementname=="Grid" then
            grid = commands.grid(v,dataxml)
        end
    end


    local r = publisher.grid:new(-999)
    r:set_margin(0,0,0,0)
    if grid then
        if grid.nx or grid.ny then
            err("Setting grid via nx or ny doesn't make sense in groups. Fallback to 1cm.")
            grid.width = tex.sp("1cm")
            grid.height = grid.width
        end
        r:set_width_height({wd = grid.width, ht = grid.height})
    else
        r:set_width_height({wd = publisher.current_page.grid.gridwidth, ht = publisher.current_page.grid.gridheight, dx = publisher.current_page.grid.grid_dx })
    end
    publisher.groups[groupname] = {
        contents = contents,
        grid     = r,
    }

    local save_grid      = publisher.current_grid
    local save_groupname = publisher.current_group

    publisher.current_group = groupname
    publisher.current_grid  = r

    for _,v in ipairs(layoutxml) do
        elementname=v[".__local_name"]
        if type(v)=="table" and elementname=="Contents" then
            publisher.dispatch(v,dataxml)
        end
    end

    publisher.current_group  = save_groupname
    publisher.current_grid = save_grid
end

--- Groupcontents
--- -----
--- Insert the contents of a virtual area into a table cell.
function commands.groupcontents( layoutxml,dataxml )
    local name = publisher.read_attribute(layoutxml,dataxml,"name", "string")
    local g = publisher.groups[name]
    if not g then
        err("group %q does not exist!",tostring(name))
        return {publisher.emergency_block()}
    end
    return {node.copy(g.contents)}
end

--- HTML
--- ------
--- Collect paragraphs to insert into the text stream (Textblock/Text)
function commands.html( layoutxml,dataxml)
    local tab = publisher.dispatch(layoutxml,dataxml)
    local ret = {}
    if publisher.htmlfilename then
        return publisher.htmlblocks
    end
    for i=1,#tab do
        local contents = publisher.element_contents(tab[i])
        local blocks = publisher.parse_html(contents[1], dataxml) or {}
        for b=1,#blocks do
            local thisblock = blocks[b]
            ret[#ret + 1] = thisblock
        end
    end
    return ret
end


--- HSpace
--- ------
--- Create a horizontal space that stretches up to infinity
function commands.hspace( layoutxml,dataxml )
    local width      = publisher.read_attribute(layoutxml,dataxml,"width", "length_sp")
    local minwidth   = publisher.read_attribute(layoutxml,dataxml,"minwidth", "length_sp")
    local leadertext = publisher.read_attribute(layoutxml,dataxml,"leader", "string")
    local leaderwd   = publisher.read_attribute(layoutxml,dataxml,"leader-width", "length_sp")
    local a = par:new(nil,"hspace")

    -- We insert a function that gets called in paragraph creation
    local ud = node.new("whatsit","user_defined")
    ud.type = 108
    ud.value = function(options)
        local n
        if width == nil then
            n = set_glue(nil,{width = minwidth or 0, stretch = 2^16, stretch_order = 3})
        else
            n = set_glue(nil,{width = tonumber(width)})
        end
        if leadertext then
            n.subtype = 100
            n.leader = publisher.mknodes(leadertext,options)
            node.set_attribute(n.leader, publisher.att_leaderwd, leaderwd or -1)
        end

        local p1, p2
        p1 = node.new("penalty")
        p1.penalty = 0
        p2 = node.new("penalty")
        p2.penalty = 10000
        local h1 = node.new("hlist")

        -- TODO: also copy all other attributes necessary for styling
        local att_tbl = {color = options.color, hyperlink = options.hyperlink }

        publisher.set_attributes(p1,att_tbl)
        publisher.set_attributes(p2,att_tbl)
        publisher.set_attributes(h1,att_tbl)
        publisher.set_attributes(n,att_tbl)

        node.insert_after(p1,p1,h1)
        node.insert_after(p1,h1,p2)
        node.insert_after(p1,p2,n)
        return p1
    end
    a:append(ud,{})
    return a
end

--- Hyphenation
--- -----------
--- The contents of this element must be a string such as `hy-phen-ation`.
-- FIXME: allow language attribute.
function commands.hyphenation( layoutxml,dataxml )
    local languagename = publisher.read_attribute(layoutxml,dataxml,"language","string")
    local languagecode
    if languagename then
        languagecode = publisher.get_languagecode(languagename)
    else
        languagecode = publisher.defaultlanguage
    end

    local l = publisher.get_language(languagecode)
    lang.hyphenation(l.l,layoutxml[1])
end

--- Include
--- -------
--- Dummy element for use in files that are included by the `xi:include` instruction.
function commands.include( layoutxml,dataxml )
    return publisher.dispatch(layoutxml,dataxml)
end

local box_lookup = {
    ["artbox"]   = "art",
    ["cropbox"]  = "crop",
    ["trimbox"]  = "trim",
    ["mediabox"] = "media",
    ["bleedbox"] =  "bleed",
}


--- Image
--- -----
--- Load an image from a file. To be used in a table cell and PlaceObject.
function commands.image( layoutxml,dataxml )
    local bleed        = publisher.read_attribute(layoutxml,dataxml,"bleed" ,      "string")
    local class        = publisher.read_attribute(layoutxml,dataxml,"class",       "string")
    local clip         = publisher.read_attribute(layoutxml,dataxml,"clip",        "boolean")
    local description  = publisher.read_attribute(layoutxml,dataxml,"description", "string")
    local dpiwarn      = publisher.read_attribute(layoutxml,dataxml,"dpiwarn",     "number")
    local fallback     = publisher.read_attribute(layoutxml,dataxml,"fallback",    "string")
    local filename     = publisher.read_attribute(layoutxml,dataxml,"file",        "string")
    local height       = publisher.read_attribute(layoutxml,dataxml,"height",      "string")
    local id           = publisher.read_attribute(layoutxml,dataxml,"id",          "string")
    local imageshape   = publisher.read_attribute(layoutxml,dataxml,"imageshape",  "boolean",false)
    local imagetype    = publisher.read_attribute(layoutxml,dataxml,"imagetype",   "string")
    local margin_bottom = publisher.read_attribute(layoutxml,dataxml,"margin-bottom","length_sp")
    local margin_left  = publisher.read_attribute(layoutxml,dataxml,"margin-left", "length_sp")
    local margin_right = publisher.read_attribute(layoutxml,dataxml,"margin-right","length_sp")
    local margin_top   = publisher.read_attribute(layoutxml,dataxml,"margin-top",  "length_sp")
    -- deprecated since 2.7.5:
    local max_box      = publisher.read_attribute(layoutxml,dataxml,"maxsize",     "string")
    local maxheight    = publisher.read_attribute(layoutxml,dataxml,"maxheight",   "string")
    local maxwidth     = publisher.read_attribute(layoutxml,dataxml,"maxwidth",    "string")
    local minheight    = publisher.read_attribute(layoutxml,dataxml,"minheight",   "string")
    local minwidth     = publisher.read_attribute(layoutxml,dataxml,"minwidth",    "string")
    local opacity      = publisher.read_attribute(layoutxml,dataxml,"opacity",     "number")
    local page         = publisher.read_attribute(layoutxml,dataxml,"page",        "number")
    local parent       = publisher.read_attribute(layoutxml,dataxml,"parent",      "string")
    local role         = publisher.read_attribute(layoutxml,dataxml,"role",        "string", "Figure")
    local rotate       = publisher.read_attribute(layoutxml,dataxml,"rotate",      "number")
    local stretch      = publisher.read_attribute(layoutxml,dataxml,"stretch",     "boolean",false)
    local url          = publisher.read_attribute(layoutxml,dataxml,"href",        "string")
    local vis_box      = publisher.read_attribute(layoutxml,dataxml,"visiblebox",  "string")
    local width        = publisher.read_attribute(layoutxml,dataxml,"width",       "string")

    local css_rules    = publisher.css:matches({element = 'img', class=class,id=id}) or {}

    -- fallback for older versions (< 2.7.5)
    vis_box = vis_box or max_box

    local attribute = {
        ["padding-top"]      = "length",
        ["padding-right"]    = "length",
        ["padding-bottom"]   = "length",
        ["padding-left"]     = "length",
        ["padding"]          = "length",
    }
    local tab = {}
    if css_rules and type(css_rules) == "table" then
        for k,v in pairs(css_rules) do
            tab[k]=v
        end
    end

    local tmpattr
    for attname,atttyp in pairs(attribute) do
        tmpattr = publisher.read_attribute(layoutxml,dataxml,attname,atttyp)
        if tmpattr then
            tab[attname] = tmpattr
        end
    end
    if tab["padding"]        then
        tab.padding_top     = tex.sp(tab["padding"])
        tab.padding_bottom  = tab.padding_top
        tab.padding_left    = tab.padding_top
        tab.padding_right   = tab.padding_top
    end
    if tab["padding-top"]    then tab.padding_top    = tex.sp(tab["padding-top"])    end
    if tab["padding-bottom"] then tab.padding_bottom = tex.sp(tab["padding-bottom"]) end
    if tab["padding-left"]   then tab.padding_left   = tex.sp(tab["padding-left"])   end
    if tab["padding-right"]  then tab.padding_right  = tex.sp(tab["padding-right"])  end


    -- width = 100%  => take width from surrounding area
    -- auto on any value ({max,min}?{width,height}) is default

    local children = publisher.dispatch(layoutxml,dataxml)
    if #children > 0 then
        if not imagetype then
            err("Cannot handle image without imagetype")
            filename = nil
        elseif imagetype == "metapost" then
            return publisher.do_metapostimage(dataxml,children[1].contents,width,height,clip)
        else
            log("Image: found %q contents",imagetype or "?")
            local elt = children[1]
            local contents = publisher.element_contents(elt)
            if publisher.elementname(elt) == "Value" and type(contents) == "table" then
                contents = publisher.xml_stringvalue(contents)
            end
            local ih = publisher.imagehandler[imagetype]
            if not ih then
                err("No imagehandler for image type %s found.",imagetype)
            else
                filename = splib.convertcontents(contents,ih)
            end
        end
    end

    filename = filename or url

    if filename and string.match(filename,"%.mp$") then
        local mpfile, msg = io.open(filename,"r")
        if mpfile == nil then
            err(msg)
            return nil
        end
        local contents = mpfile:read("*a")
        mpfile:close()
        return publisher.do_metapostimage(dataxml,contents,width,height,clip)
    end

    local imageinfo
    imageinfo = publisher.new_image(filename,page,box_lookup[vis_box] or "crop", fallback,imageshape)

    local image = img.copy(imageinfo.img)
    if rotate then
        if rotate == -90 or rotate == 270 then
            image.transform = 1
            image.height, image.width = image.width, image.height
        elseif rotate == 90 or rotate == -270 then
            image.transform = 3
            image.height, image.width = image.width, image.height
        elseif rotate == 180 or rotate == -180 then
            image.transform = 2
        elseif rotate == 0 or rotate == 360 or rotate == 360 then
            image.transform = 0
        else
            err("Image/rotate: rotation must be between -360 and 360 and given in multiple of 90")
        end
    end

    height    = publisher.set_image_length(dataxml,height,   "height") or image.height
    width     = publisher.set_image_length(dataxml,width,    "width" ) or image.width
    minheight = publisher.set_image_length(dataxml,minheight,"height") or 0
    minwidth  = publisher.set_image_length(dataxml,minwidth, "width" ) or 0
    maxheight = publisher.set_image_length(dataxml,maxheight,"height") or publisher.maxdimen
    maxwidth  = publisher.set_image_length(dataxml,maxwidth, "width" ) or publisher.maxdimen

    if not clip then
        width, height = publisher.calculate_image_width_height( image, width,height,minwidth,minheight,maxwidth, maxheight,stretch)


        local destdpi = tonumber(publisher.options.dpi)
        if publisher.options.dpi then
            if not publisher.pro then
                splib.error("Image reduction is a pro feature")
                publisher.has_pro_error = true
            else
                if image.imagetype == "pdf" then
                    splib.log("info","Unsupported image type PDF for resize","filename",filename)
                else
                    local destpx_x = math.round(destdpi * width / publisher.factor / 72,0)
                    local destpx_y = math.round(destdpi * height / publisher.factor / 72,0)

                    filename = publisher.reload_image(image.filepath,image.imagetype,destpx_x, destpx_y)
                    if filename then
                        imageinfo = publisher.new_image(filename,page,box_lookup[vis_box] or "crop", fallback,imageshape)
                        image = img.copy(imageinfo.img)
                    end
                end
            end
        end

        if dpiwarn then
            local inch_x = width / publisher.factor / 72
            local inch_y = height / publisher.factor / 72
            if (image.xsize / inch_x) < dpiwarn then
                splib.log("warn","Image DPI value to small (horizontal)","rendered",tostring(math.floor(image.xsize / inch_x)), "requested minimum", tostring(dpiwarn),"filename",filename)
            end
            if (image.ysize / inch_y) < dpiwarn then
                splib.log("warn","Image DPI value to small (vertical)","rendered",tostring(math.floor(image.ysize / inch_y)), "requested minimum", tostring(dpiwarn),"filename",filename)
            end
        end
    end

    if bleed and bleed == "auto" then
        local col, row
        if publisher.newxpath then
            col = dataxml.vars["__column"]
            row = dataxml.vars["__row"]
        else
            col = xpath.get_variable("__column")
            row = xpath.get_variable("__row")
        end
        if col == 0 then
            tab.padding_left = (tab.padding_left or 0 ) - ( publisher.options.trim or 0 )
            if width == publisher.options.pagewidth then
                tab.padding_right = (tab.padding_right or 0) - ( publisher.options.trim or 0 )
            end
        elseif publisher.options.pagewidth - col - width < 100 then
            tab.padding_right = (tab.padding_right or 0) - ( publisher.options.trim or 0 )
        end
        if row == 0 then
            tab.padding_top = (tab.padding_top or 0) - ( publisher.options.trim or 0 )
            if height == publisher.options.pageheight then
                tab.padding_bottom = (tab.padding_bottom or 0) - ( publisher.options.trim or 0 )
            end
        elseif publisher.options.pageheight - row - height < 100 then
            tab.padding_bottom = (tab.padding_bottom or 0) - ( publisher.options.trim or 0 )
        end

    end


    local overshoot
    if clip then
        local stretch_shrink
        if image.orientation > 4 then
            -- rotated, perhaps mirrored
            local image_xsize, image_ysize = image.xsize, image.ysize
            if width / image_xsize > height / image_ysize then
                stretch_shrink = width / image_ysize
                overshoot = math.round(  (image_xsize * stretch_shrink - height ) / publisher.factor / 2,3)
                overshoot = -overshoot
            else
                stretch_shrink = height / image_xsize
                overshoot = math.round(  (image_ysize * stretch_shrink - width) / publisher.factor / 2 ,3)
            end
            width = image_ysize  * stretch_shrink
            height = image_xsize * stretch_shrink
        else
            -- no rotation, but maybe mirrored
            if width / image.xsize > height / image.ysize then
                stretch_shrink = width / image.xsize
                overshoot = math.round(  (image.ysize * stretch_shrink - height ) / publisher.factor / 2,3)
                overshoot = -overshoot
            else
                stretch_shrink = height / image.ysize
                overshoot = math.round(  (image.xsize * stretch_shrink - width) / publisher.factor / 2 ,3)
            end

            width = image.xsize  * stretch_shrink
            height = image.ysize * stretch_shrink
        end
    end

    local padding_shift_left,padding_shift_up = 0,0

    if tab.padding_left then
        width = width - tab.padding_left
        padding_shift_left = padding_shift_left - tab.padding_left
    end
    if tab.padding_right then
        width = width - tab.padding_right
    end

    if tab.padding_bottom then
        height = height - tab.padding_bottom
    end
    if tab.padding_top then
        height = height - tab.padding_top
        padding_shift_up = padding_shift_up - tab.padding_top
    end

    image.width  = width
    image.height = height

    local imagenode = img.node(image)
    if publisher.options.format == "PDF/UA" then
        local figrole = publisher.get_rolenum(role)
        publisher.setprop(imagenode,"role",figrole)
        if parent then
            publisher.setprop(imagenode,"parent",parent)
        end
        publisher.rolecounter = publisher.rolecounter + 1
        publisher.setprop(imagenode,"rolecounter",publisher.rolecounter)
        publisher.setprop(imagenode,"alttext",description)
    end

    if opacity then
        publisher.transparentcolorstack()
        publisher.setprop(imagenode,"opacity",opacity)
    end
    local head, hbox = imagenode, imagenode
    if margin_left then
        local g = node.new("glue")
        g.width = tex.sp(margin_left)
        head = node.insert_before(head,imagenode,g)
    end

    if margin_right then
        local g = node.new("glue")
        g.width = tex.sp(margin_right)
        head = node.insert_after(head,imagenode,g)
    end

    if margin_left or margin_right then
        head = node.hpack(head)
        hbox = head
    end

    if margin_top then
        local g = node.new("glue")
        g.width = tex.sp(margin_top)
        head = node.insert_before(head,hbox,g)
    end

    if margin_bottom then
        local g = node.new("glue")
        g.width = tex.sp(margin_bottom)
        head = node.insert_after(head,hbox,g)
    end

    if margin_left or margin_right or margin_top or margin_bottom then
        imagenode = node.vpack(head)
    end

    local box
    if clip then
        local shift_left,shift_up = 0,0
        local a=node.new("whatsit","pdf_literal")
        local ht = math.round(height / publisher.factor,4)
        local wd = math.round(width  / publisher.factor,4)
        local right,left,top,bottom
        -- overshoot > 0 if image is too wide else < 0
        if overshoot > 0 then
            right  = wd - overshoot
            left   = overshoot
            top    = ht
            bottom = 0
            shift_left = left * publisher.factor
        else
            right  = wd
            left   = 0
            top    = ht + overshoot
            bottom = -overshoot
            shift_up = bottom * publisher.factor
        end
        left   = math.round(left,3)
        right  = math.round(right,3)
        top    = math.round(top,3)
        bottom = math.round(bottom,3)

        pdf_save = node.new("whatsit","pdf_save")
        pdf_restore = node.new("whatsit","pdf_restore")

        a.data = string.format("%g %g m %g %g l %g %g l %g %g l W n ",left,bottom,right,bottom,right,top,left,top)
        node.insert_after(pdf_save,pdf_save,a)
        node.insert_after(a,a,imagenode)
        box = node.hpack(pdf_save)
        box.depth = 0
        node.insert_after(box,node.tail(box),pdf_restore)
        box = node.vpack(box)

        local g = set_glue(nil,{width = -1 * shift_left})
        g = node.insert_after(g,g,box)
        box = node.hpack(g)

        local g = set_glue(nil,{width = -1 * shift_up})
        g = node.insert_after(g,g,box)
        box = node.vpack(g)

        box.height = height -  2 * shift_up - padding_shift_up
        box.width  = width  - 2 * shift_left - padding_shift_left

        node.set_attribute(box, publisher.att_shift_left, padding_shift_left)
        node.set_attribute(box, publisher.att_shift_up, padding_shift_up)

    else
        box = node.vpack(imagenode)
        publisher.setprop(box,"origin","image")
        node.set_attribute(box,publisher.att_lineheight,box.height)
        node.set_attribute(box, publisher.att_shift_left, padding_shift_left)
        node.set_attribute(box, publisher.att_shift_up  , padding_shift_up  )
        box.width = box.width - padding_shift_left
        box.height = box.height - padding_shift_up
    end
    return {box,imageinfo.allocate}
end

--- Initial
--- -------
--- Insert a decorated letter (or more than one) at the beginning of the paragraph.
function commands.initial( layoutxml,dataxml)
    local colorname      = publisher.read_attribute(layoutxml,dataxml,"color",        "string")
    local fontname       = publisher.read_attribute(layoutxml,dataxml,"fontface",     "string")
    local fontfamilyname = publisher.read_attribute(layoutxml,dataxml,"fontfamily",   "string",fontname)
    local padding_left   = publisher.read_attribute(layoutxml,dataxml,"padding-left", "length_sp",0)
    local padding_right  = publisher.read_attribute(layoutxml,dataxml,"padding-right","length_sp",0)
    local padding_top    = publisher.read_attribute(layoutxml,dataxml,"padding-top", "length_sp",0)
    local padding_bottom = publisher.read_attribute(layoutxml,dataxml,"padding-bottom","length_sp",0)
    if fontname then warning("Initial/fontface is deprecated and will be removed in version 5. Please use fontfamily instead") end

    local fontfamily = 0
    if fontfamilyname then
        fontfamily = publisher.fonts.lookup_fontfamily_name_number[fontfamilyname]
        if fontfamily == nil then
            err("Fontfamily %q not found.",fontfamilyname)
            fontfamily = 0
        end
    end

    local tab = publisher.dispatch(layoutxml,dataxml)
    local initialvalue
    for i,j in ipairs(tab) do
        if publisher.elementname(j) == "Value" and type(publisher.element_contents(j)) == "table" then
            if publisher.newxpath then
                initialvalue = xpath.string_value(publisher.element_contents(j))
            else
                initialvalue = table.concat(publisher.element_contents(j))
            end
        else
            initialvalue = publisher.element_contents(j)
        end
    end
    local box
    box = publisher.mknodes(initialvalue,{fontfamily = fontfamily,color = publisher.get_colorindex_from_name(colorname,"black")})
    box = publisher.addstrut(box,"head","initial")
    publisher.finish_par(box,nil,{})
    box = node.hpack(box)
    local head = box
    if padding_left and padding_left ~= 0 then
        head = node.insert_before(box,box,publisher.make_glue({width = padding_left}))
    end
    if padding_right and pading_right ~= 0 then
        head = node.insert_after(head,box,publisher.make_glue({width = padding_right}))
    end
    box = node.hpack(head)
    head = box

    if padding_top and padding_top ~= 0 then
        head = node.insert_before(box,box,publisher.make_glue({width = padding_top}))
    end
    if padding_bottom and pading_bottom ~= 0 then
        head = node.insert_after(head,box,publisher.make_glue({width = padding_bottom}))
    end
    box = node.vpack(head)

    return box
end

--- InsertPages
--- -----------
--- Insert previously saved pages with SavePages
function commands.insert_pages( layoutxml,dataxml )
    local pagestore_name = publisher.read_attribute(layoutxml,dataxml,"name","string")
    local pages          = publisher.read_attribute(layoutxml,dataxml,"pages","number")

    local current_pagenumber = publisher.current_pagenumber
    local thispagestore = publisher.pagestore[pagestore_name]
    if not thispagestore then
        -- Forward mode: re-order pages
        if not pages then
            err("For future mode please provide the number of pages to insert.")
            return
        end
        local thispage = publisher.pages[current_pagenumber]
        splib.log("info","InsertPages forward mode","pages",pages,"insert at page",current_pagenumber)
        local savenextpage = publisher.nextpage
        publisher.nextpage = nil
        --- If we insert before the first page, we don't need to to anything.
        --- Otherwise finish the current page.
        --- This duplicates code in publisher#initialize_luatex_and_generate_pdf
        if publisher.page_initialized_p(current_pagenumber) and current_pagenumber > 1 then
            publisher.dothingsbeforeoutput(thispage,dataxml)
            local n = node.vpack(publisher.pages[current_pagenumber].pagebox)
            publisher.shipout(n,current_pagenumber)
            current_pagenumber = current_pagenumber + 1
        end

        -- Increase the page number and remember where we want to insert
        -- the reserved pages (publisher.pagestore)
        -- the pagenum_tbl is used in the callback
        publisher.total_inserted_pages = publisher.total_inserted_pages + pages
        local new_pagenumber = current_pagenumber + pages
        publisher.current_pagenumber = new_pagenumber
        publisher.pagestore[pagestore_name] = {pages,current_pagenumber,#publisher.bookmarks,pagetype = savenextpage}
        publisher.forward_pagestore[pagestore_name] = true
        publisher.nextpage = nil
        return
    end
    local tmp = publisher.pages[publisher.current_pagenumber]
    if not tmp and not publisher.pages_shippedout[current_pagenumber - 1] then
        publisher.setup_page(publisher.current_pagenumber,"insert_pages",dataxml)
        current_pagenumber = publisher.current_pagenumber
    end
    splib.log("info","InsertPages backward mode","name", pagestore_name)
    for i=1,#thispagestore do
        tex.box[666] = thispagestore[i]
        publisher.pagenum_tbl[#publisher.pagenum_tbl+1] = current_pagenumber
        tex.shipout(666)
    end
    publisher.pagestore[pagestore_name] = nil
    publisher.current_pagenumber = publisher.current_pagenumber + #thispagestore
end


--- Italic text (`<I>`)
--- -------------------
--- Set the contents of this element in italic text
function commands.italic( layoutxml,dataxml )
    local p = par:new(nil,"I")
    local tab = publisher.dispatch(layoutxml,dataxml)
    for _,j in ipairs(tab) do
        local c = publisher.element_contents(j)
        p:append(c,{italic = 1})
    end
    return p
end

--- List item (`<Li>`)
--- ------------------
--- An entry of an ordered or unordered list.
function commands.li(layoutxml,dataxml )
    local p = par:new(nil,"li")
    local tab = publisher.dispatch(layoutxml,dataxml)
    for _,j in ipairs(tab) do
        local c = publisher.element_contents(j)
        p:append(c,{padding_left = 0})
    end
    return p
end


--- Load Fontfile
--- -------------
--- Load a given font file (`name`).
--- Actually the font file is not loaded yet, only stored in a table. See `publisher.font#load_fontfile()`.
function commands.load_fontfile( layoutxml,dataxml )
    local features         = publisher.read_attribute(layoutxml,dataxml,"features",        "string")
    local filename         = publisher.read_attribute(layoutxml,dataxml,"filename",        "string")
    local marginprotrusion = publisher.read_attribute(layoutxml,dataxml,"marginprotrusion","number")
    local mode             = publisher.read_attribute(layoutxml,dataxml,"mode",            "string", publisher.options.fontloader)
    local name             = publisher.read_attribute(layoutxml,dataxml,"name",            "string")
    local osf              = publisher.read_attribute(layoutxml,dataxml,"oldstylefigures", "boolean")
    local shrink           = publisher.read_attribute(layoutxml,dataxml,"shrink",          "number")
    local smcp             = publisher.read_attribute(layoutxml,dataxml,"smallcaps",       "string")
    local space            = publisher.read_attribute(layoutxml,dataxml,"space",           "number")
    local step             = publisher.read_attribute(layoutxml,dataxml,"step",            "number")
    local stretch          = publisher.read_attribute(layoutxml,dataxml,"stretch",         "number")

    local fallbacks = {}
    for _,v in ipairs(layoutxml) do
        if type(v) == "table" then
            if v[".__local_name"] == "Fallback" then
               fallbacks[#fallbacks + 1] = v.filename
            end
        end
    end


    local extra_parameter = {
        space            = space or 25,
        marginprotrusion = marginprotrusion or 0,
        fallbacks        = fallbacks,
        mode             = mode,
        shrink           = shrink,
        stretch          = stretch,
        step             = step,
        otfeatures       = {
            smcp = smcp == "yes",
            onum = osf == true,
            liga = false,
        },
    }
    if features then
        for _,fea in ipairs(string.explode(features,",")) do
            local firstletter = string.sub( fea, 1, 1 )
            if firstletter == "+" then
                local fname = string.sub(fea,2,5)
                extra_parameter.otfeatures[fname] = true
            elseif firstletter == "-" then
                local fname = string.sub(fea,2,5)
                extra_parameter.otfeatures[fname] = false
            else
                extra_parameter.otfeatures[fea] = true
            end
        end
    end

    if publisher.lowercase then filename = unicode.utf8.lower(filename) end
    splib.log("info","Load font file","filename",filename or "?")
    publisher.fonts.load_fontfile(name,filename,extra_parameter)
end

--- Load Dataset
--- ------------
--- Load a data file (XML) and start processing its contents by calling the `Record`
--- elements in the layout file.
function commands.load_dataset( layoutxml,dataxml )
    local path
    local filename = publisher.read_attribute(layoutxml,dataxml,"filename", "string")
    local name = publisher.read_attribute(layoutxml,dataxml,"name", "string")
    if filename then
        splib.log("info","Load data file","filename",filename)
        path = publisher.find_file(filename)
    elseif name then
        name = tex.jobname .. "-" .. name .. ".dataxml"
        splib.log("info","Load data file","filename",name)
        path = publisher.find_file(name)
    else
        err("LoadDataset: no (file)name given.")
    end

    if path == nil then
        -- at the first run, the file does not exist. That's ok
        return
    end
    local root_name
    if publisher.newxpath then
        local tmp_data = publisher.load_xml(name or filename)
        local tmpctx = xpath.context:new()
        tmpctx.xmldoc = { tmp_data}
        tmpctx.sequence = { tmp_data }

        local seq,msg = tmpctx:eval("local-name(root())")
        if msg then
            err(msg)
            return
        end
        local copysequence = dataxml.sequence
        local copyxmldoc = dataxml.xmldoc
        root_name = xpath.string_value(seq)
        tmpctx:execute("root()")
        dataxml.xmldoc = tmpctx.xmldoc
        dataxml.sequence = tmpctx.sequence
        publisher.dispatch(publisher.data_dispatcher[""][root_name],dataxml)
        dataxml.sequence = copysequence
        dataxml.xmldoc = copyxmldoc
    else
        local tmp_data = publisher.load_xml(name or filename)
        root_name = tmp_data[".__local_name"]
        log("Selecting node: %q, mode=%q",root_name,"")
        publisher.dispatch(publisher.data_dispatcher[""][root_name],tmp_data)
    end
end


--- Loop
--- ----
--- Repeat the contents several times (given by the attribute select). If the attribute
--- `variable` is given, store the current loop value there, if not, it is stored
--- in the variable `_loopcounter`.
function commands.loop( layoutxml, dataxml )
    local num
    if publisher.newxpath then
        local numstr = publisher.read_attribute(layoutxml,dataxml,"select","string")
        local copysequence = dataxml.sequence
        local seq, msg = dataxml:eval(numstr)
        dataxml.sequence = copysequence
        if msg then return nil, msg end
        num, msg = xpath.number_value(seq)
        if msg then return nil, msg end
    else
        local numstr = publisher.read_attribute(layoutxml,dataxml,"select","xpath")
        num = tonumber(numstr)
    end
    if not num then
        err("loop: can't parse number given in the attribute select: %q",tostring(num))
        return
    end
    local var = publisher.read_attribute(layoutxml,dataxml,"variable","string")
    var = var or "_loopcounter"
    local ret = {}
    local tab
    for i=1,num do
        if publisher.newxpath then
            dataxml.vars[var] = i
        else
            publisher.xpath.set_variable(var,i)
        end
        tab = publisher.dispatch(layoutxml,dataxml)
        for j=1,#tab do
            ret[#ret + 1] = tab[j]
        end
    end
    return ret
end

--- Empty line
--- ----------
--- Create an empty row in the layout. Set the cursor to the next free line and
--- let an empty row between.
function commands.emptyline( layoutxml,dataxml )
    warning("EmptyLine is deprecated since 2.7.4. Use NextRow instead.")
    local areaname = publisher.read_attribute(layoutxml,dataxml,"area","string")
    areaname = areaname or publisher.default_area or publisher.default_areaname
    local current_grid = publisher.current_grid
    local current_row = current_grid:find_suitable_row(1,current_grid:number_of_columns(),1,areaname)
    if not current_row then
        current_grid:set_current_row(1)
    else
        current_grid:set_current_row(current_row + 1)
    end
    current_grid:set_current_column(1)
end

--- Makeindex
--- ---------
--- Generate an index from data
function commands.makeindex( layoutxml,dataxml )
    local selection, selectstring
    if publisher.newxpath then
        selectstring = publisher.read_attribute(layoutxml,dataxml,"select", "string")
    else
        selection = publisher.read_attribute(layoutxml,dataxml,"select", "xpathraw")
    end
    local sortkey        = publisher.read_attribute(layoutxml,dataxml,"sortkey", "string")
    local sectionname    = publisher.read_attribute(layoutxml,dataxml,"section", "string")
    local pagenumbername = publisher.read_attribute(layoutxml,dataxml,"pagenumber", "string","page")

    local section, lastname, lastindex
    local lastfirstletter = ""
    local ret = {}

    if publisher.newxpath then
        local msg
        selection, msg = dataxml:eval(selectstring)
        if msg then
            err(msg)
        end
    end

    publisher.stable_sort(selection,function(elta,eltb)
        return string.lower(elta[sortkey]) < string.lower(eltb[sortkey])
    end)

    for i=1,#selection do
        local tmp = string.sub(selection[i][sortkey],1,1)
        if tmp == nil or tmp == "" then
            err("Incorrect index entry - no contents?")
        else
            local startletter = string.upper(tmp)

            if startletter ~= lastfirstletter then
                -- create a new section
                section = {
                    [".__local_name"] = sectionname,
                    [".__name"] = sectionname,
                    [".__type"] = "element",
                    [".__attributes"] = {
                        name = startletter
                    },
                    name = startletter
                }
                ret[#ret + 1] = section
            end
            -- Add current entry to this section
            -- The current implementation only concatenates page numbers
            if selection[i].name == lastname and pagenumbername ~= "" then
                if not selection[lastindex][pagenumbername] then
                    err("Can't find the page number in the index entries. Did you set the pagenumber attribute in Makeindex?")
                else
                    selection[lastindex][pagenumbername] = selection[lastindex][pagenumbername] .. ", " .. selection[i][pagenumbername]
                end
            else
                lastindex = i
                lastname = selection[i].name
                section[#section + 1] = selection[i]
            end
            lastfirstletter = startletter
        end
    end
    return ret
end


--- Margin
--- ------
--- Set margin for this page.
function commands.margin( layoutxml,dataxml )
    local left   = publisher.read_attribute(layoutxml,dataxml,"left", "length_sp")
    local right  = publisher.read_attribute(layoutxml,dataxml,"right","length_sp")
    local top    = publisher.read_attribute(layoutxml,dataxml,"top",  "length_sp")
    local bottom = publisher.read_attribute(layoutxml,dataxml,"bottom", "length_sp")

    return function(_page) _page.grid:set_margin(left,top,right,bottom) end
end

--- Mark
--- ----
--- Set an invisible marker into the output (whatsit/user_defined)
function commands.mark( layoutxml,dataxml )
    local selection = publisher.read_attribute(layoutxml,dataxml,"select","xpathraw")
    local append    = publisher.read_attribute(layoutxml,dataxml,"append","boolean")
    local pdftarget = publisher.read_attribute(layoutxml,dataxml,"pdftarget","boolean")
    local shiftup   = publisher.read_attribute(layoutxml,dataxml,"shiftup","height_sp")
    local ret = {}
    if type(selection) == "table" then
        if publisher.newxpath then
            for _,v in ipairs(selection) do
                ret[#ret + 1] = { selection = xpath.string_value(v) , append = append, pdftarget = pdftarget, shiftup = shiftup }
            end
        else
            for _,v in ipairs(selection) do
                ret[#ret + 1] = { selection = v, append = append, pdftarget = pdftarget, shiftup = shiftup }
            end
        end
        return ret
    else
        err("Unknown type in <Mark>")
    end
end

--- Message
--- -------
--- Write a message to the terminal
function commands.message( layoutxml, dataxml )
    local selection = publisher.read_attribute(layoutxml,dataxml,"select","string")
    local errcond   = publisher.read_attribute(layoutxml,dataxml,"error", "boolean",false)
    local exitnow   = publisher.read_attribute(layoutxml,dataxml,"exit",  "boolean",false)
    local errorcode = publisher.read_attribute(layoutxml,dataxml,"errorcode", "number",1)

    local contents
    if selection then
        if publisher.newxpath then
            local copysequence = dataxml.sequence
            local seq, msg = dataxml:eval(selection)
            if msg then
                err(msg)
                return
            end
            contents = xpath.string_value(seq)
            dataxml.sequence = copysequence
        else
            local ret = {}
            local tmp = publisher.read_attribute(layoutxml,dataxml,"select","xpathraw")
            if tmp then
                for i=1,#tmp do
                    ret[#ret + 1] = tostring(tmp[i])
                end
                contents = table.concat(ret)
            else
                contents = nil
            end
        end
    else
        local tab = publisher.dispatch(layoutxml,dataxml)
        contents = tab
    end

    if type(contents) == "table" then
        local ret = {}
        for i=1,#contents do
            local eltname = publisher.elementname(contents[i])
            local contents = publisher.element_contents(contents[i])
            if eltname == "Sequence" or eltname == "Value" then
                if type(contents) == "table" then
                    for k,v in pairs(contents) do
                        if type(v) == "boolean" then
                            contents[k] = v and "True" or "False"
                        end
                    end
                    ret[#ret + 1] = table.concat(contents)
                elseif type(contents) == "string" then
                    ret[#ret + 1] = contents
                elseif type(contents) == "number" then
                    ret[#ret + 1] = tostring(contents)
                elseif type(contents) == "nil" then
                    -- ignore
                else
                    err("Message: unknown type in value: %q",type(contents))
                end
            elseif eltname == "Element" then
                ret[#ret + 1] = publisher.xml_stringvalue(contents)
            else
                err("Unknown element name in <Message> %q",tostring(eltname))
            end
        end
        contents = table.concat(ret)
    end

    if errcond then
        splib.log("error",contents,"errorcode",errorcode,"from","message",lineinfo(layoutxml))
        if errorcode > publisher.errorcode then
            publisher.errorcode = errorcode
        end
    else
        splib.log("message",contents,lineinfo(layoutxml))
    end

    if exitnow then
        err(-1,"Exiting on user request.")
        quit()
    end
end

--- NextFrame
--- ---------
--- Switch to the next frame of the given positioning area.
function commands.next_frame( layoutxml,dataxml )
    local areaname = publisher.read_attribute(layoutxml,dataxml,"area","string")
    publisher.next_area(areaname,nil, dataxml)
end

--- Next Row
--- --------
--- Go to the next row in the current area.
function commands.next_row( layoutxml,dataxml )
    publisher.setup_page(nil,"commands#next_row",dataxml)
    local rownumber = publisher.read_attribute(layoutxml,dataxml,"row", "string")
    local areaname  = publisher.read_attribute(layoutxml,dataxml,"area","string")
    local rows      = publisher.read_attribute(layoutxml,dataxml,"rows","string")
    local tmp

    if rownumber ~= nil then
        tmp = tonumber(rownumber)
        if tmp == nil then
            err("Cannot parse row in NextRow, number expected, but got %q",tostring(rownumber))
            rownumber = nil
        else
            rownumber = tmp
        end
    end

    if rows ~= nil then
        tmp = tonumber(rows)
        if tmp == nil then
            err("Cannot parse rows in NextRow, number expected, but got %q",tostring(rows))
            rows = nil
        else
            rows = tmp
        end
    end

    rows = rows or 1
    local areaname = areaname or publisher.default_area or publisher.default_areaname

    publisher.next_row(rownumber,areaname,rows,dataxml)
end

--- NewPage
--- -------
--- Create a new page. Run the hooks in AtPageShipout.
function commands.new_page( layoutxml,dataxml )
    local pagetype     = publisher.read_attribute(layoutxml,dataxml,"pagetype","string")
    local skippagetype = publisher.read_attribute(layoutxml,dataxml,"skippagetype","string")
    local openon       = publisher.read_attribute(layoutxml,dataxml,"openon","string")
    local force        = publisher.read_attribute(layoutxml,dataxml,"force", "boolean")
    warning("NewPage is deprecated and will be removed in version 5.\nPlease use ClearPage instead.\nSee https://github.com/speedata/publisher/discussions/345 for details.")

    -- two new pages right after each other should insert a new page
    if publisher.skippages then
        publisher.skippages = nil
        publisher.new_page("new_page",dataxml)
    end
    local doubleopen = false
    if ( openon == "right" and math.fmod(publisher.current_pagenumber,2) == 1 ) or ( openon == "left" and math.fmod(publisher.current_pagenumber,2) == 0 ) then
        doubleopen = true
    end
    publisher.skippages = {skippagetype = skippagetype, pagetype = pagetype, doubleopen = doubleopen}
    if force then
        local thispage = publisher.pages[publisher.current_pagenumber]
        publisher.dothingsbeforeoutput(thispage)
        local n = node.vpack(thispage.pagebox)
        publisher.shipout(n,publisher.current_pagenumber)
        publisher.current_pagenumber = publisher.current_pagenumber + 1
    end
end

--- NoBreak
--- -------
--- Don't allow a line break of the contents. Reduce font size if necessary
function commands.nobreak( layoutxml, dataxml )
    local maxwidth
    if publisher.newxpath then
        maxwidth = dataxml.vars["__maxwidth"]
    else
        maxwidth = xpath.get_variable("__maxwidth")
    end
    local current_maxwidth = publisher.read_attribute(layoutxml,dataxml,"maxwidth",   "length_sp", maxwidth)
    local fontname         = publisher.read_attribute(layoutxml,dataxml,"fontface",   "string")
    local strategy         = publisher.read_attribute(layoutxml,dataxml,"reduce",     "string", "keeptogether")
    local shrinkfactor     = publisher.read_attribute(layoutxml,dataxml,"factor",     "string",0.9)
    local text             = publisher.read_attribute(layoutxml,dataxml,"text",       "string")
    if fontname then warning("Nobreak/fontface is deprecated and will be removed in version 5. Please use fontfamily instead") end

    local p = par:new(nil,"nobreak")
    local tab = publisher.dispatch(layoutxml,dataxml)

    if strategy == "fontsize" then
        p:append(tab,{})
        p.flatten_callback = function(thiselt,options)
            local fam = options.fontfamily
            local fam_tbl = publisher.fonts.lookup_fontfamily_number_instance[fam]
            local strut
            strut = publisher.add_rule(nil,"head",{height = fam_tbl.baselineskip * 0.75 , depth = fam_tbl.baselineskip * 0.25 , width = 0 })
            local loops = 0
            local nl

            local tmppar
            repeat
                tmppar = par:new(nil,"nobreak(fontsize 1)")
                loops = loops + 1
                if loops > 10 then
                    err("Nobreak: More than 10 loops, giving up")
                    break
                end
                local thisoptions = publisher.copy_table_from_defaults(options)
                thisoptions.fontfamily = fam
                for _,j in ipairs(thiselt) do
                    local c = publisher.element_contents(j)
                    tmppar:append(publisher.deepcopy(c),thisoptions)
                end
                tmppar:mknodelist(thisoptions,dataxml)
                if #tmppar.objects == 0 then
                    return tmppar
                end
                nl = node.copy_list(tmppar.objects[1])
                nl = node.hpack(nl)
                nl = node.insert_before(nl, nl , node.copy(strut))
                fam = publisher.fonts.clone_family(fam, {size = shrinkfactor})
                local wd = node.dimensions(nl)
            until wd <= current_maxwidth

            return tmppar
        end
        return p
    elseif strategy == "cut" then
        p:append(tab,{})
        p.flatten_callback = function(thiselt,options)
            tmppar = par:new(nil,"cut")
            for _,j in ipairs(thiselt) do
                local c = publisher.element_contents(j)
                tmppar:append(c,options)
            end
            tmppar:mknodelist(options,dataxml)
            local nl = tmppar.objects[1]
            local wd = node.dimensions(nl)
            if wd < current_maxwidth then
                return tmppar
            end
            local cuttextnodelist = publisher.mknodes(text,{fontfamily = options.fontfamily})
            cuttextnodelist = node.hpack(cuttextnodelist)

            local txtwd = node.dimensions(cuttextnodelist)

            local head = nl
            local wd = 0
            while head and wd + txtwd <= current_maxwidth do
                head = head.next
                wd = node.dimensions(nl,head)
            end
            local tmpnl = node.copy_list(nl,head)
            node.insert_after(tmpnl,node.tail(tmpnl),cuttextnodelist)
            tmppar[1] = tmpnl
            tmppar.objects = { tmpnl  }
            return tmppar
        end
        return p
    elseif strategy == "keeptogether" then
        p:append(tab,{})
        p.flatten_callback = function(thiselt,options)
            tmppar = par:new(nil,"keeptogether")
            tmppar:append(thiselt)
            tmppar:mknodelist(options,dataxml)
            local nl = tmppar.objects[1]
            local fam_tbl = publisher.fonts.lookup_fontfamily_number_instance[options.fontfamily]
            local lineheight = fam_tbl.baselineskip
            local strut = publisher.add_rule(nil,"head",{height = lineheight * 0.75 , depth = lineheight * 0.25 , width = 0 })
            nl = node.hpack(nl)
            nl = node.insert_before(nl,nl,strut)
            tmppar.objects[1] = nl
            return tmppar
        end
        return p
    end
end


--- Ordered list (`<Ol>`)
--- ------------------
--- A list with numbers
function commands.ol(layoutxml,dataxml )
    local fontfamilyname = publisher.read_attribute(layoutxml,dataxml,"fontfamily","string")
    local fontfamily
    if fontfamilyname then
        fontfamily = publisher.fonts.lookup_fontfamily_name_number[fontfamilyname]
        if fontfamily == nil then
            err("Fontfamily %q not found.",fontfamilyname)
            fontfamily = 0
        end
        publisher.current_fontfamily = fontfamily
    else
        fontfamily = nil
    end
    if not fontfamily then fontfamily = publisher.fonts.lookup_fontfamily_name_number["text"] end

    local ret = {}
    local labelwidth = tex.sp("5mm")
    local tab = publisher.dispatch(layoutxml,dataxml)
    for i,j in ipairs(tab) do
        local a = par:new(nil,"ol")
        a:append(publisher.number_hbox(i,labelwidth,{fontfamily = fontfamily}))
        a:append(publisher.element_contents(j),{})
        ret[#ret + 1] = a
    end
    return ret
end


--- Options
--- -------
--- This is a top-level element in the layout definition file. It saves the options such as `trim` and `mainlanguage`.
function commands.options( layoutxml,dataxml )
    -- deprecated:
    publisher.options.showhyphenation    = publisher.read_attribute(layoutxml,dataxml,"show-hyphenation","boolean")
    local showgrid                       = publisher.read_attribute(layoutxml,dataxml,"show-grid",   "boolean")
    local showgridallocation             = publisher.read_attribute(layoutxml,dataxml,"show-gridallocation","boolean")
    local trace                          = publisher.read_attribute(layoutxml,dataxml,"trace",       "boolean")

    if publisher.options.interaction == nil then
        publisher.options.interaction = true
    end

    if showgrid ~= nil then
        publisher.options.showgrid = showgrid
    end
    if showgridallocation ~= nil then
        publisher.options.showgridallocation = showgridallocation
    end
    if trace ~= nil then
        publisher.options.trace = trace
    end

    publisher.options.background          = publisher.read_attribute(layoutxml,dataxml,"background-color", "string", publisher.options.background)
    publisher.options.cutmarks            = publisher.read_attribute(layoutxml,dataxml,"cutmarks",    "boolean",publisher.options.cutmarks)
    publisher.options.trimmarks           = publisher.read_attribute(layoutxml,dataxml,"trimmarks",   "boolean",publisher.options.trimmarks)
    publisher.options.trimmarks           = publisher.read_attribute(layoutxml,dataxml,"bleedmarks",  "boolean",publisher.options.trimmarks)
    local num = publisher.read_attribute(layoutxml,dataxml,"startpage",   "number", publisher.options.startpage)
    if tonumber(num) then
        publisher.current_pagenumber = tonumber(num)
        log("Set page number to %d",num)
    end

    publisher.options.fontstretch         = publisher.read_attribute(layoutxml,dataxml,"fontstretch", "number", publisher.options.fontstretch)
    publisher.options.fontshrink          = publisher.read_attribute(layoutxml,dataxml,"fontshrink",  "number", publisher.options.fontshrink)
    publisher.options.fontstep            = publisher.read_attribute(layoutxml,dataxml,"fontstep",    "number", publisher.options.fontstep)
    local fontexpansion                   = publisher.read_attribute(layoutxml,dataxml,"fontexpansion", "string")
    if fontexpansion ~= nil then
        if fontexpansion == "yes" then
            tex.adjustspacing = 2
        elseif fontexpansion == "some" then
            tex.adjustspacing = 1
        else
            tex.adjustspacing = 0
        end
    end
    publisher.options.trim                = publisher.read_attribute(layoutxml,dataxml,"trim",        "length", publisher.options.trim)
    publisher.options.trim                = publisher.read_attribute(layoutxml,dataxml,"bleed",       "length", publisher.options.trim)
    publisher.options.ignoreeol           = publisher.read_attribute(layoutxml,dataxml,"ignoreeol",   "boolean",publisher.options.ignoreeol)
    publisher.options.resetmarks          = publisher.read_attribute(layoutxml,dataxml,"resetmarks",  "boolean",publisher.options.resetmarks or false)
    publisher.options.colorprofile        = publisher.read_attribute(layoutxml,dataxml,"colorprofile","string",publisher.options.colorprofile)
    publisher.options.crop                = publisher.read_attribute(layoutxml,dataxml,"crop",        "booleanorlength",publisher.options.crop or false)
    local randomseed                      = publisher.read_attribute(layoutxml,dataxml,"randomseed",  "number")
    local reportmissingglyphs             = publisher.read_attribute(layoutxml,dataxml,"reportmissingglyphs", "string")
    publisher.options.interaction         = publisher.read_attribute(layoutxml,dataxml,"interaction", "boolean", publisher.options.interaction)
    local overfullline                    = publisher.read_attribute(layoutxml,dataxml,"overfull-line", "string")
    local imagenotfound                   = publisher.read_attribute(layoutxml,dataxml,"imagenotfound", "string")
    local mainlanguage                    = publisher.read_attribute(layoutxml,dataxml,"mainlanguage","string","")
    local default_area                    = publisher.read_attribute(layoutxml,dataxml,"defaultarea","string")
    local markdownextensions              = publisher.read_attribute(layoutxml,dataxml,"markdown-extensions","string")
    if markdownextensions then
        splib.markdownextensions = string.explode(markdownextensions,",")
    end

    if default_area then
        publisher.default_area = default_area
    end

    if imagenotfound == "warning" or imagenotfound == "error" then
        publisher.options.imagenotfounderror = (imagenotfound == "error")
    end

    if overfullline == "warning" or overfullline == "error"  then
        publisher.options.overfulllineerror = (overfullline == "error")
    elseif overfullline == "ignore" then
        publisher.options.overfulllineerror = nil
    end

    if mainlanguage ~= "" then
        publisher.set_mainlanguage(mainlanguage,true)
    end
    if publisher.options.trim then
        if publisher.newxpath then
            dataxml.vars["_bleed"] = publisher.options.trim
        else
            xpath.set_variable("_bleed",publisher.options.trim)
        end
        publisher.options.trim = tex.sp(publisher.options.trim)
    end
    if randomseed then
        local uuid = require "uuid"
        uuid.randomseed(randomseed)
    end
    if reportmissingglyphs == true or reportmissingglyphs == "yes" then
        publisher.options.reportmissingglyphs = true
    elseif reportmissingglyphs == false or reportmissingglyphs == "no" then
        publisher.options.reportmissingglyphs = false
    elseif reportmissingglyphs == "warning" then
        publisher.options.reportmissingglyphs = "warning"
    end


end

--- Output
--- ------
--- This command is able to produce multi-area contents by pulling from the underlying command.
--- That means the children (currently only `<Text>`) must implement a function called `pull()`
--- taking two arguments: 1) parameters, 2) state. Parameters is a table with the following layout:
---
---     parameters = {
---         area = area,
---         maxheight = maxht,
---         width = wd,
---         balance = true/false,
---         current_grid = current_grid,
---         allocate = allocate,
---     }
--- The state is just a table that is empty in the beginning and re-passed into `pull()`
--- every time there is output left over.
---
--- The function `pull()` must return three values:
---
---  1. `obj`: The vbox that should be placed in the pdf at the current position
---  1. `state`: The table that is passed to the next iteration of `pull()`
---  1. `more_to_follow`: boolean which indicates that there is output left for the next area
function commands.output( layoutxml,dataxml )
    publisher.setup_page(nil,"commands#output",dataxml)
    local area     = publisher.read_attribute(layoutxml,dataxml,"area","string")
    local allocate = publisher.read_attribute(layoutxml,dataxml,"allocate", "string", "yes")
    local row      = publisher.read_attribute(layoutxml,dataxml,"row","number")
    local balance  = publisher.read_attribute(layoutxml,dataxml,"balance", "boolean", false)
    local valignlast = publisher.read_attribute(layoutxml,dataxml,"valign-last","string")
    local lastpaddingbottommax = publisher.read_attribute(layoutxml,dataxml,"last-padding-bottom-max","length_sp")

    local maxwidth = publisher.current_grid:width_sp(publisher.current_grid:number_of_columns(area))
    local maxheight = publisher.current_grid:height_sp(publisher.current_grid:number_of_rows(area))

    local current_maxwidth
    if publisher.newxpath then
        current_maxwidth = dataxml.vars["__maxwidth"]
        dataxml.vars["__maxwidth"] = maxwidth
        dataxml.vars["__maxheight"] = maxheight
    else
        current_maxwidth = xpath.get_variable("__maxwidth")
        xpath.set_variable("__maxwidth", maxwidth)
        xpath.set_variable("__maxheight", maxheight)
    end

    local tab  = publisher.dispatch(layoutxml,dataxml)
    area = area or publisher.default_area or publisher.default_areaname
    local last_area
    if publisher.newxpath then
        last_area = dataxml.vars["__area"]
        dataxml.vars["__area"] = area
    else
        last_area = publisher.xpath.get_variable("__area")
        publisher.xpath.set_variable("__area",area)
    end
    publisher.next_row(row,area,0,dataxml)

    local tosplit
    if balance then
        tosplit = publisher.current_grid:number_of_frames(area)
    else
        tosplit = 1
    end

    local current_grid

    local state
    for i=1,#tab do
        local contents = publisher.element_contents(tab[i])

        local parameters
        local more_to_follow
        local obj
        local maxht,row,nextfreerow
        local objcount = 0
        -- We call pull so long as it is needed. Say we have enough
        -- material for three pages (areas), we call pull three times.
        -- So pull()'s duty is to assemble enough material for that area.
        -- pull needs to know the width and the height of the area.
        --
        -- Currently only the command Text implements pull.
        while true do
            objcount = objcount + 1
            publisher.setup_page(nil,"commands#output",dataxml)
            maxht,row,nextfreerow = publisher.get_remaining_height(area,allocate)
            current_grid = publisher.current_grid
            current_row = publisher.current_grid:current_row(area)
            parameters = {
                area = area,
                maxheight = maxht,
                width = maxwidth,
                current_grid = current_grid,
                allocate = allocate,
            }
            if current_grid:framenumber(area) == 1 then
                parameters.balance = tosplit
            else
                parameters.balance = 1
            end
            parameters.valignlast = valignlast
            parameters.lastpaddingbottommax = lastpaddingbottommax

            obj,state,more_to_follow = contents.pull(parameters,state)
            if not more_to_follow then
                nextfreerow = nil
            end
            if obj == nil then
                break
            elseif state.split then
                local obj1 = obj
                local obj2 = state.split
                local ht = current_grid:height_in_gridcells_sp(obj.height)
                publisher.output_at({nodelist = obj1, x = 1, y = row, allocate = true, area = area})
                publisher.next_area(area,nil,dataxml)
                publisher.output_at({nodelist = obj2, x = 1, y = row, allocate = true, area = area})
                current_grid:set_framenumber(area,1)
            else
                local ht = current_grid:height_in_gridcells_sp(obj.height)
                publisher.output_at({nodelist = obj, x = 1, y = row, allocate = true, area = area})
                -- We don't need to go to the next page when we are at the end
                if nextfreerow then
                    if nextfreerow <= row then
                        nextfreerow = row + 1
                    end
                    publisher.next_row(nextfreerow,area,0,dataxml)
                else
                    if more_to_follow then
                        publisher.next_area(area,nil,dataxml)
                    else
                        -- We need to go down a bit to ensure that the next
                        -- current row for allocation detection is not
                        -- at the last position. See bug #89
                        current_grid:set_current_row(row + ht,area)
                    end
                end
            end
        end
    end
    -- reset the current maxwidth
    if publisher.newxpath then
        dataxml.vars["__maxwidth"] = current_maxwidth
    else
        xpath.set_variable("__maxwidth",current_maxwidth)
    end
    _,row,_ = publisher.get_remaining_height(area,allocate)
    current_grid:set_current_row(row,area)
    if publisher.newxpath then
        dataxml.vars["__area"] = last_area
    else
        publisher.xpath.set_variable("__area",last_area)
    end
end

--- Overlay
--- -------
--- Stacks things (like images, barcode, etc) on top of each other
function commands.overlay( layoutxml, dataxml )
    local tab = publisher.dispatch(layoutxml,dataxml)
    local fg
    local box
    local ti
    for i,v in ipairs(tab) do
        ti = tab[i].contents
        if i == 1 then
            if publisher.elementname(tab[i]) == "Image" then
                box = ti[1]
            else
                box = ti
            end
        else
            box = publisher.montage(box,ti.contents,ti.x,ti.y)
        end
    end
    return box
end

--- PageFormat
--- ----------
--- Set the dimensions of the page
function commands.page_format(layoutxml,dataxml,options)
    local width  = publisher.read_attribute(layoutxml,dataxml,"width","length")
    local height = publisher.read_attribute(layoutxml,dataxml,"height","length")

    local wd_sp = tex.sp(width)
    local ht_sp = tex.sp(height)
    if publisher.newxpath then
        dataxml.vars["_pagewidth"] = width
        dataxml.vars["_pageheight"] = height
    else
        xpath.set_variable("_pagewidth",width)
        xpath.set_variable("_pageheight",height)
    end
    publisher.set_pageformat(wd_sp,ht_sp)
    publisher.options.default_pagewidth = wd_sp
    publisher.options.default_pageheight = ht_sp
end

--- PageType
--- --------
--- This command should be probably called master page or something similar.
function commands.pagetype(layoutxml,dataxml)
    local columnordering = publisher.read_attribute(layoutxml,dataxml,"columnordering","string")
    local test           = publisher.read_attribute(layoutxml,dataxml,"test","string")
    local pagetypename   = publisher.read_attribute(layoutxml,dataxml,"name","string")
    local part           = publisher.read_attribute(layoutxml,dataxml,"part","string")

    local width  = publisher.read_attribute(layoutxml,dataxml,"width","length")
    local height = publisher.read_attribute(layoutxml,dataxml,"height","length")

    local tmp_tab = {
        layoutxml = layoutxml,
        width = width,
        height = height,
        columnordering = columnordering,
        part = part,
    }
    -- evaluate the default color for this page later on, so we can set it dynamically (XPath)

    local tab = publisher.dispatch(layoutxml,dataxml)

    for i,j in ipairs(tab) do
        local eltname = publisher.elementname(j)
        if eltname=="Margin" or eltname == "AtPageShipout" or eltname == "AtPageCreation" or eltname=="Grid" or eltname=="PositioningArea" then
            tmp_tab [#tmp_tab + 1] = j
        else
            err("Element %q in “Pagetype” unknown",tostring(eltname))
            tmp_tab [#tmp_tab + 1] = j
        end
    end
    publisher.masterpages[#publisher.masterpages + 1] = { is_pagetype = test, res = tmp_tab, name = pagetypename,ns=layoutxml[".__ns"]}
end

--- Paragraph
--- ---------
--- A paragraph is just a bunch of text that is not yet typeset.
--- It can have a font face, color,... but these can be also given
--- On the surrounding element (`Textblock`).
function commands.paragraph( layoutxml, dataxml,textblockoptions )
    textblockoptions = textblockoptions or {}
    local allowbreak        = publisher.read_attribute(layoutxml,dataxml,"allowbreak",         "string")
    local bidi              = publisher.read_attribute(layoutxml,dataxml,"bidi",               "boolean")
    local colorname         = publisher.read_attribute(layoutxml,dataxml,"color",              "string")
    local actualtext        = publisher.read_attribute(layoutxml,dataxml,"actualtext",         "string")
    local direction         = publisher.read_attribute(layoutxml,dataxml,"direction",          "string")
    local fontname          = publisher.read_attribute(layoutxml,dataxml,"fontface",           "string")
    local fontfamilyname    = publisher.read_attribute(layoutxml,dataxml,"fontfamily",         "string",fontname)
    local fontoutline       = publisher.read_attribute(layoutxml,dataxml,"font-outline",       "width_sp")
    local html              = publisher.read_attribute(layoutxml,dataxml,"html",               "string","all")
    local language_name     = publisher.read_attribute(layoutxml,dataxml,"language",           "string")
    local labelleft         = publisher.read_attribute(layoutxml,dataxml,"label-left",         "string")
    local labelleftwidth    = publisher.read_attribute(layoutxml,dataxml,"label-left-width",   "width_sp")
    local labelleftalign    = publisher.read_attribute(layoutxml,dataxml,"label-left-align",   "string")
    local labelleftdistance = publisher.read_attribute(layoutxml,dataxml,"label-left-distance","width_sp")
    local paddingleft       = publisher.read_attribute(layoutxml,dataxml,"padding-left",       "width_sp")
    local paddingright      = publisher.read_attribute(layoutxml,dataxml,"padding-right",      "width_sp")
    local role              = publisher.read_attribute(layoutxml,dataxml,"role",               "string")
    local parent            = publisher.read_attribute(layoutxml,dataxml,"parent",             "string")
    local structpos         = publisher.read_attribute(layoutxml,dataxml,"structpos",          "string","cur")
    local textformat        = publisher.read_attribute(layoutxml,dataxml,"textformat",         "string")
    if fontname then warning("Paragraph/fontface is deprecated and will be removed in version 5. Please use fontfamily instead") end
    if textformat and not publisher.textformats[textformat] then err("Paragraph: textformat %q unknown",tostring(textformat)) end
    if direction and not ( direction == "ltr" or direction == "rtl") then
        if not ( direction == "" ) then
            warning("direction must be 'ltr' or 'rtl', ignoring direction")
        end
        direction = nil
    end
    local fontfamily
    if fontfamilyname then
        fontfamily = publisher.fonts.lookup_fontfamily_name_number[fontfamilyname]
        if fontfamily == nil then
            err("Fontfamily %q not found.",fontfamilyname)
            fontfamily = 0
        end
        publisher.current_fontfamily = fontfamily
    else
        fontfamily = nil
    end
    local colorindex = publisher.get_colorindex_from_name(colorname)
    local languagecode
    if language_name then
        languagecode = publisher.get_languagecode(language_name)
    else
        languagecode = textblockoptions.languagecode or publisher.defaultlanguage
    end

    local fontoutlinewidth
    if fontoutline then
        fontoutlinewidth = fontoutline
    end
    if role and not parent then
        parent = "doc"
    end

    local params = {
        allowbreak = allowbreak,
        bidi = bidi,
        color = colorindex,
        direction = direction,
        fontfamily = fontfamily,
        fontoutlinewidth = fontoutlinewidth,
        html = html,
        labelleft = labelleft,
        labelleftalign = labelleftalign,
        labelleftdistance = labelleftdistance,
        labelleftwidth = labelleftwidth,
        languagecode = languagecode,
        padding_left = paddingleft,
        padding_right = paddingright,
        textformat = publisher.textformats[textformat],
    }

    if publisher.options.format == "PDF/UA" then
        publisher.rolecounter = publisher.rolecounter + 1
        params.rolecounter = publisher.rolecounter
        params.role = publisher.get_rolenum(role)
        params.parent = parent
        params.structpos = structpos
        params.actualtext = actualtext
    end


    local tab = publisher.dispatch(layoutxml,dataxml)
    local p = par:new(nil,"commands.paragraph")
    p.fontfamily = fontfamily
    if #tab == 1 and tab[1].contents == "" then
        tab[1].contents = " " -- U+00A0, non breaking space
    end

    for i=1,#tab do
        local thischild = tab[i]
        local eltname = publisher.elementname(thischild)
        local contents = publisher.element_contents(thischild)
        if eltname == "Initial" then
            params.initial = contents
        elseif eltname == "Image" then
            node.set_attribute(contents[1],publisher.att_dontadjustlineheight,1)
            p:append(contents[1],params)
        else
            p:append(contents,params)
        end
    end
    if publisher.options.format == "PDF/UA" then
        params.role = params.role or publisher.get_rolenum("P")
        if not params.role then
            splib.error("Paragraph: role unknown",lineinfo(layoutxml))
        else
            p.parent = params.parent
            p.role = params.role
            p.rolecounter = params.rolecounter
            p.id = publisher.roles_a[params.role] .. "_" .. tostring(params.rolecounter)
            p.structpos = params.structpos
            p.actualtext = params.actualtext
        end
    end
    return p
end

--- PDFOptions
--- ------------
--- Sets number of copies and such. See #57
function commands.pdfoptions( layoutxml, dataxml )
    local author                = publisher.read_attribute(layoutxml,dataxml,"author",                "string")
    local colorprofile          = publisher.read_attribute(layoutxml,dataxml,"colorprofile",          "string")
    local creator               = publisher.read_attribute(layoutxml,dataxml,"creator",               "string")
    local displaymode           = publisher.read_attribute(layoutxml,dataxml,"displaymode",           "string")
    local dpi                   = publisher.read_attribute(layoutxml,dataxml,"dpi",                   "number")
    local duplex                = publisher.read_attribute(layoutxml,dataxml,"duplex",                "string")
    local format                = publisher.read_attribute(layoutxml,dataxml,"format",                "string")
    local hyperlinksbordercolor = publisher.read_attribute(layoutxml,dataxml,"hyperlinksbordercolor", "string")
    local hyperlinkbordercolor  = publisher.read_attribute(layoutxml,dataxml,"hyperlinkbordercolor",  "string",hyperlinksbordercolor)
    local hyperlinkborderwidth  = publisher.read_attribute(layoutxml,dataxml,"hyperlinkborderwidth",  "width_sp")
    local keywords              = publisher.read_attribute(layoutxml,dataxml,"keywords",              "string")
    local nc                    = publisher.read_attribute(layoutxml,dataxml,"numcopies",             "number")
    local pagelayout            = publisher.read_attribute(layoutxml,dataxml,"pagelayout",            "string")
    local picktray              = publisher.read_attribute(layoutxml,dataxml,"picktraybypdfsize",     "boolean")
    local printscaling          = publisher.read_attribute(layoutxml,dataxml,"printscaling",          "string")
    local producer              = publisher.read_attribute(layoutxml,dataxml,"producer",              "string")
    local showbookmarks         = publisher.read_attribute(layoutxml,dataxml,"showbookmarks",         "boolean")
    local showhyperlinks        = publisher.read_attribute(layoutxml,dataxml,"showhyperlinks",        "boolean", false)
    local subject               = publisher.read_attribute(layoutxml,dataxml,"subject",               "string")
    local title                 = publisher.read_attribute(layoutxml,dataxml,"title",                 "string")

    if title then
        publisher.options.documenttitle = title
    end
    if author then
        publisher.options.documentauthor = author
    end
    if creator then
        publisher.options.documentcreator = creator
    end
    if producer then
        if not publisher.pro then
            err("Setting the producer needs a pro plan")
            publisher.has_pro_error = true
            return nil
        end

        publisher.options.documentproducer = producer
    end
    if subject then
        publisher.options.documentsubject = subject
    end
    if keywords then
        publisher.options.documentkeywords = keywords
    end
    if dpi then
        publisher.options.dpi = dpi
    end
    if showhyperlinks then
        publisher.options.showhyperlinks = showhyperlinks
    end
    if hyperlinkbordercolor then
        publisher.options.hyperlinkbordercolor = hyperlinkbordercolor
    end
    if hyperlinkborderwidth then
        publisher.options.hyperlinkborderwidth = hyperlinkborderwidth
    end
    if nc then
        publisher.viewerpreferences.numcopies = nc
    end

    if pagelayout == "twocolumnleft" then
        publisher.options.pagelayout = "TwoColumnLeft"
    elseif pagelayout == "twocolumnright" then
        publisher.options.pagelayout = "TwoColumnRight"
    elseif pagelayout == "twopageleft" then
        publisher.options.pagelayout = "TwoPageLeft"
    elseif pagelayout == "twopageright" then
        publisher.options.pagelayout = "TwoPageRight"
    elseif pagelayout == "onecolumn" then
        publisher.options.pagelayout = "OneColumn"
    elseif pagelayout == "singlepage" then
        publisher.options.pagelayout = "SinglePage"
    end

    if displaymode == "attachments" then
        publisher.options.displaymode = "UseAttachments"
    elseif displaymode == "bookmarks" then
        publisher.options.displaymode = "UseOutlines"
    elseif displaymode == "fullscreen" then
        publisher.options.displaymode = "FullScreen"
    elseif displaymode == "thumbnails" then
        publisher.options.displaymode = "UseThumbs"
    end

    if showbookmarks then
        publisher.options.displaymode = "UseOutlines"
        warning("PDFOptions/showbookmarks is deprecated and will be removed in version 5. Please use displaymode instead")
    end

    if printscaling then
        if printscaling == "appdefault" then
            publisher.viewerpreferences.printscaling = "AppDefault"
        elseif printscaling == "none" then
            publisher.viewerpreferences.printscaling = "None"
        else
            publisher.viewerpreferences.printscaling = ""
        end
    end

    if picktray ~= nil then
        publisher.viewerpreferences.picktray = tostring(picktray)
    end

    if duplex then
        if duplex == "simplex" then
            publisher.viewerpreferences.duplex = "Simplex"
        elseif duplex == "duplexflipshortedge" then
            publisher.viewerpreferences.duplex = "DuplexFlipShortEdge"
        elseif duplex == "duplexfliplongedge" then
            publisher.viewerpreferences.duplex = "DuplexFlipLongEdge"
        else
            publisher.viewerpreferences.duplex = ""
        end
    end

    if colorprofile then
        spotcolors.set_colorprofile(colorprofile)
    end

    if format then
        publisher.options.format = format
        if format == "PDF/X-3" or format == "PDF/X-4" or format == "PDF/UA" then
            pdf.setobjcompresslevel(0)
            if not title then publisher.options.documenttitle = "document" end
        end
        if format == "PDF/X-3" then
            publisher.options.format = "PDF/X-3:2002"
        end
    end
end

--- PlaceObject
--- -----------
--- Emit a rectangular object. The object can be
--- one of `Textblock`, `Table`, `Image`, `Box` or `Rule`.
function commands.place_object( layoutxml,dataxml)
    local absolute_positioning = false
    local column           = publisher.read_attribute(layoutxml,dataxml,"column",         "string")
    local row              = publisher.read_attribute(layoutxml,dataxml,"row",            "string")
    local area             = publisher.read_attribute(layoutxml,dataxml,"area",           "string")
    local allocate         = publisher.read_attribute(layoutxml,dataxml,"allocate",       "string")
    local framecolor       = publisher.read_attribute(layoutxml,dataxml,"framecolor",     "string")
    local backgroundcolor  = publisher.read_attribute(layoutxml,dataxml,"background-color","string")
    backgroundcolor        = publisher.read_attribute(layoutxml,dataxml,"backgroundcolor","string",backgroundcolor)
    local rulewidth_sp     = publisher.read_attribute(layoutxml,dataxml,"rulewidth",      "length_sp", 26312) -- 0.4bp
    local maxheight        = publisher.read_attribute(layoutxml,dataxml,"maxheight",      "number")
    local onpage           = publisher.read_attribute(layoutxml,dataxml,"page",           "string")
    local keepposition     = publisher.read_attribute(layoutxml,dataxml,"keepposition",   "boolean",false)
    local frame            = publisher.read_attribute(layoutxml,dataxml,"frame",          "string")
    local background       = publisher.read_attribute(layoutxml,dataxml,"background",     "string")
    local groupname        = publisher.read_attribute(layoutxml,dataxml,"groupname",      "string")
    local valign           = publisher.read_attribute(layoutxml,dataxml,"valign",         "string")
    local halign           = publisher.read_attribute(layoutxml,dataxml,"halign",         "string")
    local hreference       = publisher.read_attribute(layoutxml,dataxml,"hreference",     "string")
    local vreference       = publisher.read_attribute(layoutxml,dataxml,"vreference",     "string")
    local rotate           = publisher.read_attribute(layoutxml,dataxml,"rotate",         "number")
    local origin_x         = publisher.read_attribute(layoutxml,dataxml,"origin-x",       "string", nil, "origin")
    local origin_y         = publisher.read_attribute(layoutxml,dataxml,"origin-y",       "string", nil, "origin")
    local b_b_r_radius     = publisher.read_attribute(layoutxml,dataxml,"border-bottom-right-radius", "string")
    local b_t_r_radius     = publisher.read_attribute(layoutxml,dataxml,"border-top-right-radius",    "string")
    local b_t_l_radius     = publisher.read_attribute(layoutxml,dataxml,"border-top-left-radius",     "string")
    local b_b_l_radius     = publisher.read_attribute(layoutxml,dataxml,"border-bottom-left-radius",  "string")
    local allocate_left    = publisher.read_attribute(layoutxml,dataxml,"allocate-left",  "width_sp")
    local allocate_right   = publisher.read_attribute(layoutxml,dataxml,"allocate-right", "width_sp")
    local allocate_top     = publisher.read_attribute(layoutxml,dataxml,"allocate-top",   "height_sp")
    local allocate_bottom  = publisher.read_attribute(layoutxml,dataxml,"allocate-bottom","height_sp")
    local class            = publisher.read_attribute(layoutxml,dataxml,"class",      "string")
    local id               = publisher.read_attribute(layoutxml,dataxml,"id",         "string")

    local css_rules = publisher.css:matches({element = "placeobject", class=class,id=id}) or {}
    if rotate and tonumber(rotate) % 360 ~= 0 then
        allocate = "no"
    end

    if origin_x == "left" then
        origin_x = 0
    elseif origin_x == "center" then
        origin_x = 50
    elseif origin_x == "right" then
        origin_x = 100
    end
    if origin_y == "top" then
        origin_y = 0
    elseif origin_y == "center" then
        origin_y = 50
    elseif origin_y == "bottom" then
        origin_y = 100
    end

    if publisher.current_group and area and area ~= publisher.default_areaname then
        err("Areas can't be combined with groups")
    end
    area = area or publisher.default_area or publisher.default_areaname
    local save_current_area
    if publisher.newxpath then
        save_current_area = dataxml.vars["__currentarea"]
        dataxml.vars["__currentarea"] = area
    else
        save_current_area = xpath.get_variable("__currentarea")
        xpath.set_variable("__currentarea", area)
    end
    framecolor = framecolor or "black"


    if onpage then
        if onpage == 'next' then
            onpage = publisher.current_pagenumber + 1
        elseif tonumber(onpage) then
            onpage = tonumber(onpage)
        end
    end

    publisher.setup_page(onpage,"commands#PlaceObject",dataxml)
    -- current_grid should be local. But then the test tables/future objects fails
    -- FIXME: check why the test fails
    -- local current_grid
    if onpage then
        current_grid = publisher.pages[onpage].grid
    else
        current_grid = publisher.current_grid
    end



    if ( column and not tonumber(column) ) or ( row and not tonumber(row)) then
        absolute_positioning = true
    end

    if column and absolute_positioning then
        if tonumber(column) then
            -- looks like column is a string
            column = current_grid:posx_sp(column)
        else
            column = tex.sp(column)
        end
    end

    if row and absolute_positioning then
        if tonumber(row) then
            row = current_grid:posy_sp(row)
        else
            row = tex.sp(row)
        end
    end

    if absolute_positioning then
        if not ( row and column ) then
            err("“Column” and “Row” must be given with absolute positioning (PlaceObject).")
            return
        end
    end

    -- remember the current maximum width for later
    local current_maxwidth
    if publisher.newxpath then
        dataxml.vars["__row"] = row
        dataxml.vars["__column"] = column
        current_maxwidth = dataxml.vars["__maxwidth"]
    else
        xpath.set_variable("__row", row)
        xpath.set_variable("__column", column)
        current_maxwidth = xpath.get_variable("__maxwidth")
    end

    local mw = current_grid:number_of_columns(area)
    local mh = current_grid:number_of_rows(area)
    if not mw then
        err("Something is wrong with the current page, expect strange results")
        return
    end

    if absolute_positioning == false then
        if tonumber(column) then
            mw = current_grid:width_sp(mw - column + 1)
        else
            mw = current_grid:width_sp(mw)
        end
        mh = current_grid:height_sp(mh)
        if not allocate then allocate = "yes" end
    else
        mw = tex.pdfpagewidth
        mh = tex.pdfpageheight
        if not allocate then allocate = "no" end
    end
    if publisher.newxpath then
        dataxml.vars["__maxwidth"] = mw
        dataxml.vars["__maxheight"] = mh
    else
        xpath.set_variable("__maxwidth", mw)
        xpath.set_variable("__maxwheight", mh)
    end

    local current_row_start  = current_grid:current_row(area)
    if not current_row_start then
        return nil
    end
    -- jump to the next row if the requested column is < than the current column
    if absolute_positioning == false and column and tonumber(column) < current_grid:current_column(area) then
        publisher.next_row(nil,area,1,dataxml)
    end
    local current_column_start = tonumber(column or current_grid:current_column(area))

    -- current_height is the remaining space on the current page in sps
    local maxcells = maxheight or current_grid:number_of_rows(area)
    if not tonumber(maxcells) then
        splib.error("Cannot calculate the number of rows in the area","area",area)
        return
    end
    local areaheight = maxcells * current_grid.gridheight + ( maxcells - 1 ) * current_grid.grid_dy
    local options = {}
    if publisher.current_group == nil then
        options.ht_max = areaheight
        if vreference == "bottom" then
            options.current_height = areaheight
        elseif vreference == "middle" then
            -- incorrect, but irrelevant since vreference==middle only in
            -- absolute positioning
            options.current_height = areaheight
        else
            options.current_height = math.min(current_grid:remaining_height_sp(row,area,tonumber(column)),areaheight)
        end
    else
        options.ht_max = publisher.maxdimen
        options.current_height = publisher.maxdimen
    end
    if allocate == "no" then
        options.current_height = areaheight
    end

    local tab = publisher.dispatch(layoutxml,dataxml,options)

    -- reset the current maxwidth
    if publisher.newxpath then
        dataxml.vars["__maxwidth"] = current_maxwidth
    else
        xpath.set_variable("__maxwidth",current_maxwidth)
    end
    local objects = {}
    local object, objecttype

    if groupname then
        if not publisher.groups[groupname] then
            err("Unknown group %q in PlaceObject",groupname)
        else
            objects[1] = { object = node.copy(publisher.groups[groupname].contents),
                objecttype = string.format("Group (%s)", groupname)}
        end
    else
        for i,j in ipairs(tab) do
            object = publisher.element_contents(j)
            objecttype = publisher.elementname(j)
            if objecttype == "Image" then
                -- return value is a table, #1 is the image, #2 is the allocation grid
                objects[#objects + 1] = {object = object[1], objecttype = objecttype, allocate_matrix = object[2] }
            else
                if type(object)=="table" then
                    -- last page of balanced objects must not change active frame
                    -- see last lines of place_object
                    objects.balance = object.balance
                    for i=1,#object do
                        objects[#objects + 1] = {object = object[i], objecttype = objecttype }
                    end
                else
                    if objecttype == "Bookmark" then
                        -- ignore
                    else
                        objects[#objects + 1] = {object = object, objecttype = objecttype }
                    end
                end
            end
        end
    end
    for i=1,#objects do
        if not onpage then
            current_grid = publisher.current_grid
        end
        local framewidth
        object     = objects[i].object
        objecttype = objects[i].objecttype


        if background == "full" or css_rules["background-color"] then
            object = publisher.background(object,backgroundcolor or css_rules["background-color"])
        end
        if frame == "solid" then
            framewidth = rulewidth_sp
            object = publisher.frame({
                box       = object,
                colorname = framecolor,
                rulewidth = rulewidth_sp,
                b_b_r_radius = tex.sp(b_b_r_radius or 0),
                b_t_r_radius = tex.sp(b_t_r_radius or 0),
                b_t_l_radius = tex.sp(b_t_l_radius or 0),
                b_b_l_radius = tex.sp(b_b_l_radius or 0),
                })
        else
            -- set to 0 so framewidth in parameter below
            framewidth = 0
        end
        if not object then
            err("Something is wrong with <PlaceObject>, content is missing")
            return
        end
        if publisher.options.showobjects then
            publisher.boxit(object)
        end
        assert(object.width,"Can't determine object width")
        local width_in_gridcells   = current_grid:width_in_gridcells_sp(object.width)
        local height_in_gridcells  = current_grid:height_in_gridcells_sp(object.height + object.depth,{floor = ( valign == "bottom" )})

        if absolute_positioning then
            if hreference == "right" then
                column = column - object.width
            elseif hreference == "center" then
                column = column - object.width / 2
            end
            local top = row + current_grid.extra_margin
            if vreference == "bottom" then
                top = top - object.height
            elseif vreference == "middle" then
                top = top - object.height / 2
            end
            publisher.output_absolute_position({
                nodelist = object,
                x        = column + current_grid.extra_margin,
                y        = top,
                rotate   = rotate,
                origin_x = origin_x,
                origin_y = origin_y,
                allocate = allocate == "yes",
                allocate_matrix = objects[i].allocate_matrix,
                allocate_left   = allocate_left,
                allocate_right  = allocate_right,
                allocate_top    = allocate_top,
                allocate_bottom = allocate_bottom,
                keepposition = keepposition,
            })
        else
            -- Look for a place for the object
            local current_row
            -- local current_row = current_grid:current_row(area)
            if not node.has_field(object,"width") then
                warning("Can't calculate with object's width!")
            end
            -- w("PlaceObject: finished calculating width: wd=%d,ht=%d",width_in_gridcells,height_in_gridcells)
            -- w("PlaceObject: find suitable row for object, current_row = %d",row or current_grid:current_row(area) or "-1")
            if row then
                if vreference == "bottom" then
                    current_row = row - height_in_gridcells + 1
                elseif vreference == "middle" then
                    current_row = row - math.round (height_in_gridcells / 2,0) + 1
                else
                    current_row = row
                end
            else
                current_row = nil
            end

            if hreference == "right" then
                current_column_start = current_column_start - width_in_gridcells + 1
            elseif hreference == "center" then
                current_column_start = current_column_start - math.round(width_in_gridcells / 2,0) + 1
            end

            -- While (not found a free area) switch to next frame
            while current_row == nil do
                if not column then
                    -- no row or column given. So I'll look for the values myself:
                    if current_column_start + width_in_gridcells - 1 > current_grid:number_of_columns() then
                        current_column_start = 1
                    end
                end

                if publisher.current_group then
                    current_row = current_grid:find_suitable_row(current_column_start,width_in_gridcells,height_in_gridcells,area)
                    if not current_row then
                        current_row = 1
                    end
                else
                    -- the current grid is different when in a group
                    current_row = current_grid:find_suitable_row(current_column_start,width_in_gridcells,height_in_gridcells,area)
                    if not current_row then
                        splib.log("warn","No suitable row found","type", objecttype,lineinfo(layoutxml))
                        publisher.next_area(area,nil, dataxml)
                        publisher.setup_page(nil,"commands#PlaceObject",dataxml)
                        current_grid = publisher.current_grid
                        current_row = current_grid:current_row(area)
                        current_column_start = 1
                    end
                end
            end
            -- if the object has no height (for example an Action node), we don't move the cursor
            if height_in_gridcells == 0  then allocate = "no" end
            splib.log("debug","PlaceObject","type",objecttype,"col",tostring(math.floor(current_column_start)),"row",tostring(math.floor(current_row)),"wd",width_in_gridcells,"ht",height_in_gridcells,"page",onpage or publisher.current_pagenumber)
            publisher.output_at({
                nodelist = node.copy(object),
                x = current_column_start,
                y = current_row,
                allocate = ( allocate == "yes"),
                area = area,
                valign = valign,
                halign = halign,
                allocate_matrix = objects[i].allocate_matrix,
                pagenumber = onpage,
                keepposition = keepposition,
                grid = current_grid,
                rotate = rotate,
                origin_x = origin_x,
                origin_y = origin_y,
                framewidth = framewidth,
                allocate_left   = allocate_left,
                allocate_right  = allocate_right,
                allocate_top    = allocate_top,
                allocate_bottom = allocate_bottom,
                vreference = vreference,
                })
            row = nil -- the current rows is not valid anymore because an object is already rendered
            node.flush_list(object)
        end -- no absolute positioning
        if i < #objects then
            -- don't switch when inside a group
            if publisher.current_group == nil then
                publisher.next_area(area,nil,dataxml)
                publisher.setup_page(nil,"commands#PlaceObject",dataxml)
            end
        else
            if objects.balance then
                -- a split table and the last object.
                current_grid:set_framenumber(area,1)
                local first_free_row = current_grid:first_free_row(area,1)
                current_grid:set_current_row(first_free_row,area)
            end
        end
    end
    if not allocate == "yes" then
        current_grid:set_current_row(current_row_start)
    end

    if onpage then
        publisher.setup_page(nil,"commands#PlaceObject",dataxml)
        current_grid = publisher.pages[publisher.current_pagenumber].grid
    end
    if publisher.newxpath then
        dataxml.vars["__currentarea"] = save_current_area
    else
        xpath.set_variable("__currentarea",save_current_area)
    end
end

--- ProcessNode
--- -----------
--- Call the given (in attribute `select`) names of elements in the data file.
--- The optional attribute `mode` must match, if given. Since the attribute `select` is a fixed
--- string, this function is rather stupid but nevertheless currently the main
--- function for processing data.
function commands.process_node(layoutxml,dataxml)
    local copysequence
    if publisher.newxpath then
        copysequence = dataxml.sequence
    end

    local dataxml_selection = publisher.read_attribute(layoutxml,dataxml,"select","xpathraw")
    local mode              = publisher.read_attribute(layoutxml,dataxml,"mode","string") or ""
    local limit             = publisher.read_attribute(layoutxml,dataxml,"limit","number")

    -- To restore the current value of `__position`, we save it.
    -- The value of `__position` is available from xpath (function position()).
    local current_position
    if publisher.newxpath then
        current_position = dataxml.pos
    else
        current_position = publisher.xpath.get_variable("__position")
    end
    local element_name
    local layoutnode
    local pos = 1
    if not dataxml_selection then return nil end
    if limit then
        limit = math.min(#dataxml_selection,limit)
    else
        limit = #dataxml_selection
    end
    local items = dataxml_selection
    for i=1, limit do
        element_name = dataxml_selection[i][".__local_name"]
        if publisher.newxpath then
            dataxml.sequence = {items[i]}
        end
        local modeselector = publisher.data_dispatcher[mode]
        if modeselector == nil then
            err("No combination of mode %q element name %q is defined.",mode,element_name)
            return
        end
        layoutnode = publisher.data_dispatcher[mode][element_name]
        if layoutnode then
            splib.log("debug","Process node", "node",element_name,"mode",mode,"pos",string.format("%d",pos))
            if publisher.newxpath then
                dataxml.pos = pos
                publisher.dispatch(layoutnode,dataxml)
            else
                publisher.xpath.set_variable("__position",pos)
                dataxml_selection[i][".__context"] = dataxml_selection
                publisher.dispatch(layoutnode,dataxml_selection[i])
            end

            pos = pos + 1
        end
    end
    --- Now restore the value for the parent element
    if publisher.newxpath then
        dataxml.sequence = copysequence
        dataxml.pos = current_position
    else
        publisher.xpath.set_variable("__position",current_position)
    end

end

--- Position
--- -------
--- Used from Overlay to stack one thing on top of the first element of Overlay
function commands.position( layoutxml, dataxml )
    local x = publisher.read_attribute(layoutxml,dataxml,"x","number")
    local y = publisher.read_attribute(layoutxml,dataxml,"y","number")

    local tab = publisher.dispatch(layoutxml,dataxml)
    if publisher.elementname(tab[1]) == "Image" then
        return {x = x, y = y, contents = publisher.element_contents(tab[1])[1]}
    else
        return {x = x, y = y, contents = tab[1].contents}
    end
end


--- PositioningFrame
--- ----------------
--- Define a rectangular area on the page where content gets placed.
function commands.positioning_frame( layoutxml, dataxml )
    local column = publisher.read_attribute(layoutxml,dataxml,"column","number")
    local row    = publisher.read_attribute(layoutxml,dataxml,"row" ,"number")
    local width  = publisher.read_attribute(layoutxml,dataxml,"width","number")
    local height = publisher.read_attribute(layoutxml,dataxml,"height"  ,"number")
    return {
        column = column,
        row    = row,
        width  = width,
        height = height
    }
end

--- PositioningArea
--- ----------------
--- Contains one or more positioning frames.
function commands.positioning_area( layoutxml,dataxml )
    -- Warning: if we call publisher.dispatch now, the xpath functions
    -- might depend on values on the _current_ page, which is not set!
    local colorname = publisher.read_attribute(layoutxml,dataxml,"framecolor", "string")
    local name      = publisher.read_attribute(layoutxml,dataxml,"name","string")
    local tab = {}
    tab.colorname = colorname
    tab.layoutxml = layoutxml
    if publisher.newxpath then
        tab.dataxml = dataxml:copy()
    else
        tab.dataxml = dataxml
    end
    tab.name = name
    return tab
end


--- Record
--- ------
--- Matches an element name of the data file. To be called from ProcessNodes
function commands.record( layoutxml )
    local elementname, mode = "", ""
    if publisher.newxpath then
        elementname = layoutxml[".__attributes"].element
        mode        = layoutxml[".__attributes"].mode or ""
    else
        elementname = publisher.read_attribute(layoutxml,{},"element","string")
        mode        = publisher.read_attribute(layoutxml,{},"mode","string","")
    end
    splib.log("debug","Record","element",elementname,"mode",mode)
    publisher.data_dispatcher[mode] = publisher.data_dispatcher[mode] or {}
    publisher.data_dispatcher[mode][elementname] = layoutxml
end


--- Rule
--- -----
--- Draw a horizontal or vertical rule
function commands.rule( layoutxml,dataxml )
    local direction     = publisher.read_attribute(layoutxml,dataxml,"direction",  "string")
    local length        = publisher.read_attribute(layoutxml,dataxml,"length",     "string")
    local rulewidth     = publisher.read_attribute(layoutxml,dataxml,"rulewidth",  "string")
    local dashed        = publisher.read_attribute(layoutxml,dataxml,"dashed",     "boolean")
    local color         = publisher.read_attribute(layoutxml,dataxml,"color",      "string")
    local class         = publisher.read_attribute(layoutxml,dataxml,"class",      "string")
    local id            = publisher.read_attribute(layoutxml,dataxml,"id",         "string")

    local css_rules = publisher.css:matches({element = "rule", class=class,id=id}) or {}

    local colorname = color or css_rules["background-color"] or "black"
    -- #hexvalue -> colorname

    if tonumber(length) then
        if direction == "horizontal" then
            length = publisher.current_grid:width_sp(length)
        elseif direction == "vertical" then
            length = publisher.current_grid:height_sp(length)
        else
            err("Attribute “direction” with “Rule”: unknown direction: %q",direction)
        end
    else
        length = tex.sp(length)
    end
    length = sp_to_bp(length)

    rulewidth = rulewidth or css_rules["height"] or "1pt"
    if tonumber(rulewidth) then
        if direction == "horizontal" then
            rulewidth = publisher.current_grid.gridwidth * rulewidth
        elseif direction == "vertical" then
            rulewidth = publisher.current_grid.gridheight * rulewidth
        end
    else
        rulewidth = tex.sp(rulewidth)
    end
    rulewidth = math.round(sp_to_bp(rulewidth),3)
    local n = node.new("whatsit","pdf_literal")
    n.mode = 0
    local dashpattern
    if dashed then
        -- 3 * rule width seems to be a reasonable dash pattern
        dashpattern = string.format("[%g] 0 d",3 * rulewidth)
    else
        dashpattern = ""
    end
    local colentry = publisher.get_colentry_from_name(colorname,"black")
    if direction == "horizontal" then
        n.data = string.format("q %g w %s %s 0 0 m %g 0 l S Q",rulewidth, dashpattern, colentry.pdfstring,length)
    elseif direction == "vertical" then
        n.data = string.format("q %g w %s %s 0 0 m 0 %g l S Q",rulewidth,dashpattern, colentry.pdfstring,-length)
    else
        --
    end
    if colentry.alpha then
        publisher.set_attribute(n,"color",colentry.index)
    end
    n = node.hpack(n)
    return n
end

--- SaveDataset
--- -----------
--- Write a Lua table representing an XML file to the disk. See `#load_dataset` for the opposite.
function commands.save_dataset( layoutxml,dataxml )
    local towrite, tmp,tab
    -- filename is obsolete, LoadDataset has "name" too. And it is actually not a filename, just part
    -- of it.
    local filename    = publisher.read_attribute(layoutxml,dataxml,"filename",   "string")
    local name        = publisher.read_attribute(layoutxml,dataxml,"name",       "string")
    local elementname = publisher.read_attribute(layoutxml,dataxml,"elementname","string")
    local selection   = publisher.read_attribute(layoutxml,dataxml,"select",     "string")
    local attributes  = publisher.read_attribute(layoutxml,dataxml,"attributes", "xpathraw")
    name = name or filename

    assert(name)
    assert(elementname)

    tmp = {}
    if attributes then
        for i=1,#attributes do
            if publisher.elementname(attributes[i]) == "Attribute" then
                for k,v in pairs(publisher.element_contents(attributes[i])) do
                    if k ~= ".__type" then
                        tmp[k] = v
                    end
                end
            end
        end
    end
    if selection then
        if publisher.newxpath then
            local seq, msg = dataxml:eval(selection)
            if msg then
                err(msg)
            end
            tab = seq
        else
            local ok
            ok, tab = xpath.parse_raw(dataxml,selection,layoutxml[".__ns"])
            if not ok then err(tab) return end
        end
    else
        tab = publisher.dispatch(layoutxml,dataxml)
    end

    for i=1,#tab do
        local eltname = tab[i].elementname
        if eltname == "Element" then
            tmp[#tmp + 1] = publisher.element_contents(tab[i])
        elseif eltname=="elementstructure" or eltname=="Makeindex" then
            for j=1,#publisher.element_contents(tab[i]) do
                tmp[#tmp + 1] = publisher.element_contents(tab[i])[j]
            end
        else
            tmp[#tmp + 1] = tab[i]
        end
    end

    --- tmp has now this structure:
    ---    tmp = {
    ---      [1] = {
    ---        [".__parent"] =
    ---        [".__local_name"] = "bar"
    ---        ["att1"] = "1"
    ---      },
    ---      [2] = {
    ---        [".__parent"] =
    ---        [".__local_name"] = "bar"
    ---        ["att2"] = "2"
    ---      },
    ---      [3] = {
    ---        [".__parent"] =
    ---        [".__local_name"] = "bar"
    ---        ["att3"] = "3"
    ---      },
    ---    },
    tmp[".__local_name"] = elementname
    local full_filename = tex.jobname .. "-" .. name .. ".dataxml"
    local file = io.open(full_filename,"wb")
    towrite = publisher.xml_to_string(tmp)
    file:write(towrite)
    file:close()
end

--- SavePages
--- ---------
--- Save pages for later restore
function commands.save_pages( layoutxml,dataxml )
    local pagestore_name = publisher.read_attribute(layoutxml,dataxml,"name","string")

    if publisher.forward_pagestore[pagestore_name] == nil then
        -- backwards mode. First save_pages, then insert_pages
        local save_current_pagenumber = publisher.current_pagenumber
        splib.log("info","SavePages backwards mode","start page",save_current_pagenumber, "name",pagestore_name)
        publisher.current_pagestore_name = pagestore_name
        publisher.pagestore[pagestore_name] = {}
        local tab = publisher.dispatch(layoutxml,dataxml)
        publisher.new_page("save_pages",dataxml)
        for i=save_current_pagenumber,publisher.current_pagenumber - 1 do
            publisher.pages[i] = nil
        end
        publisher.current_pagestore_name = nil
        publisher.current_pagenumber = save_current_pagenumber

        return tab
    else
        -- forward mode. First insert pages then save pages
        -- Run NewPage if the current page is not finished
        if publisher.page_initialized_p(publisher.current_pagenumber) then
            publisher.new_page("save_pages forward mode",dataxml)
        end
        local save_current_pagenumber = publisher.current_pagenumber
        local ps = publisher.pagestore[pagestore_name]
        local number_of_pages = ps[1]
        local location = ps[2]
        splib.log("info","SavePages forward mode","number of pages",number_of_pages,"insert location",location)
        -- oldbookmarkspos = the number of bookmarks before the insert pages command
        local oldbookmarkspos = ps[3]
        local bookmarkscount = #publisher.bookmarks
        publisher.current_pagenumber = location
        -- We need to set the destination before the pages are created
        -- since the callback for page ordering is called after
        -- each shipout.
        publisher.nextpage = ps.pagetype
        local tab = publisher.dispatch(layoutxml,dataxml)

        local realpagecount = publisher.current_pagenumber - location + 1
        if realpagecount ~= number_of_pages then
            splib.error("SavePages: incorrect number of pages.","expected",number_of_pages, "got", realpagecount)
            return tab
        end

        -- for next pages, if any:
        publisher.new_page("save_pages forward mode 2",dataxml)

        -- If bookmarks are used in SavePages, we need to insert them at the
        -- correct location (InsertPages)
        local newbookmarkscount = #publisher.bookmarks
        if newbookmarkscount > bookmarkscount then
            local tmpbookmarks = {}
            for i = bookmarkscount + 1, newbookmarkscount do
                local item = table.remove(publisher.bookmarks,i)
                table.insert(tmpbookmarks,item)
            end
            for i = 1,#tmpbookmarks do
                local pos = oldbookmarkspos + i
                table.insert(publisher.bookmarks,pos,tmpbookmarks[i])
            end
        end

        publisher.current_pagenumber = save_current_pagenumber
        return tab

    end
end

--- SetGrid
--- -------
--- Set the grid to the given values.
function commands.set_grid(layoutxml,dataxml)
    local wd = publisher.read_attribute(layoutxml,dataxml,"width", "string")
    local ht = publisher.read_attribute(layoutxml,dataxml,"height","string")
    local nx = publisher.read_attribute(layoutxml,dataxml,"nx",    "string")
    local ny = publisher.read_attribute(layoutxml,dataxml,"ny",    "string")
    local dx = publisher.read_attribute(layoutxml,dataxml,"dx",    "length_sp")
    local dy = publisher.read_attribute(layoutxml,dataxml,"dy",    "length_sp")

    publisher.options.gridcells_dx = dx
    publisher.options.gridcells_dy = dy

    local _nx = tonumber(nx)
    local _ny = tonumber(ny)
    if _nx then
        publisher.options.gridcells_x = _nx
        publisher.options.gridwidth = 0
    else
        if tonumber(wd) then
            err("SetGrid: width must be a length (with unit). Setting it to 1cm.")
            wd = "1cm"
        end
        if wd == nil then
            err("Gridwidth not set")
        else
            publisher.options.gridwidth = tex.sp(wd)
            publisher.options.gridcells_x = 0
        end
    end
    if _ny then
        publisher.options.gridcells_y = _ny
        publisher.options.gridheight = 0
    else
        if tonumber(ht) then
            err("SetGrid: height must be a length (with unit). Setting it to 1cm.")
            ht = "1cm"
        end
        publisher.options.gridheight  = tex.sp(ht)
        publisher.options.gridcells_y = 0
    end
end


--- Sequence
--- --------
--- Get parts of the data. Can be stored in a variable. Obsolete, can be removed (2.9.3).
function commands.sequence( layoutxml,dataxml )
    local selection = publisher.read_attribute(layoutxml,dataxml,"select","xpathraw")
    return selection
end

--- SetVariable
--- -----------
--- Assign a value to a variable.
function commands.setvariable( layoutxml,dataxml )
    local trace_p   = publisher.options.showassignments or publisher.read_attribute(layoutxml,dataxml,"trace","boolean")
    local selection = publisher.read_attribute(layoutxml,dataxml,"select","string")
    local varname   = publisher.read_attribute(layoutxml,dataxml,"variable","string")
    local typ       = publisher.read_attribute(layoutxml,dataxml,"type","string","sd")
    local execute   = publisher.read_attribute(layoutxml,dataxml,"execute", "string","now")
    -- FIXME: if the variable contains nodes, the must be freed.

    if not varname then
        err("Variable name in “SetVariable” not recognized")
        return
    end
    local contents

    if execute == "later" then
        local save = {}
        if selection then
            save = selection
        else
            save[#save+1] = "expand"
            for i = 1, #layoutxml do
                save[#save+1] = layoutxml[i]
            end
        end
        if publisher.newxpath then
            dataxml.vars[varname] = save
        else
            publisher.xpath.set_variable(varname, save)
        end
        return
    else
        if selection then
            if publisher.newxpath then
                local seq, msg = dataxml:eval(selection)
                if msg then
                    err(msg)
                end
                dataxml.vars[varname] = seq
                contents = seq
            else
                contents = xpath.parse(dataxml,selection,layoutxml[".__ns"])
            end
        else
            local tab = publisher.dispatch(layoutxml,dataxml)
            contents = tab
        end
    end

    if publisher.newxpath then
        if type(contents) == "table" then
            local ret
            local has_element = false
            for i=1,#contents do
                local thiscontents = contents[i]
                if type(thiscontents) == "table" and thiscontents.elementname then
                    local eltname = publisher.elementname(thiscontents)
                    local element_contents = publisher.element_contents(thiscontents)
                    if eltname == "Sequence" or eltname == "Value" or eltname == "SortSequence" then
                        if type(element_contents) == "table" then
                            ret = ret or {}
                            if getmetatable(ret) == nil then
                                setmetatable(ret,{ __concat = table.__concat })
                            end
                            ret = ret .. element_contents
                        elseif type(element_contents) == "string" then
                            local typ = type(ret)
                            if  typ == "table" then
                                ret[#ret + 1] = element_contents
                            elseif typ == "string" then
                                ret = ret .. element_contents
                            end
                        elseif type(element_contents) == "number" then
                            ret = ret or ""
                            ret = ret .. tostring(element_contents)
                        elseif type(element_contents) == "nil" then
                            -- ignore
                        else
                            err("Unknown type: %q",type(element_contents))
                            ret = nil
                        end
                    elseif eltname == "elementstructure" then
                        for j=1,#element_contents do
                            ret = ret or {}
                            ret[#ret + 1] = element_contents[j]
                        end
                    elseif eltname == "Element" then
                        has_element = true
                        ret = ret or {}
                        ret[#ret + 1] = element_contents
                    end
               end
            end
            if ret then
                if has_element then
                    contents = {ret}
                else
                    contents = ret
                end
            end
        end
    else
        if type(contents) == "table" then
            local ret
            for i=1,#contents do
                local eltname = publisher.elementname(contents[i])
                local element_contents = publisher.element_contents(contents[i])
                if eltname == "Sequence" or eltname == "Value" or eltname == "SortSequence" then
                    if type(element_contents) == "table" then
                        ret = ret or {}
                        if getmetatable(ret) == nil then
                            setmetatable(ret,{ __concat = table.__concat })
                        end
                        ret = ret .. element_contents
                    elseif type(element_contents) == "string" then
                        local typ = type(ret)
                        if  typ == "table" then
                            ret[#ret + 1] = element_contents
                        elseif typ == "string" then
                            ret = ret .. element_contents
                        end
                    elseif type(element_contents) == "number" then
                        ret = ret or ""
                        ret = ret .. tostring(element_contents)
                    elseif type(element_contents) == "nil" then
                        -- ignore
                    else
                        err("Unknown type: %q",type(element_contents))
                        ret = nil
                    end
                elseif eltname == "elementstructure" then
                    for j=1,#element_contents do
                        ret = ret or {}
                        ret[#ret + 1] = element_contents[j]
                    end
                elseif eltname == "Element" then
                    ret = ret or {}
                    ret[#ret + 1] = element_contents
                end
            end
            if ret then
                contents = ret
            end
        end
    end

    if trace_p then
        splib.log("info","SetVariable","varname",varname or "(no variable name)","value",tostring(contents))
        if type(contents) == "table" then
            printtable("SetVariable",contents)
        end
    end
    if varname == "_mode" then
        publisher.modes = {}
        if publisher.newxpath then
            contents = xpath.string_value(contents)
        end
        local _modes = string.explode(tostring(contents),",")
        for _,m in ipairs(_modes) do
            publisher.modes[m] = true
        end
    end
    publisher.flush_variable(varname)
    if string.sub(typ,1,2) == "mp" then
        publisher.metapostvariables[varname] = { typ = string.sub(typ,4), contents}
    else
        if publisher.newxpath then
            dataxml.vars[varname] = contents
        else
            publisher.xpath.set_variable(varname,contents)
        end
    end
end

--- SortSequence
--- ------------
--- Sort a sequence.
function commands.sort_sequence( layoutxml,dataxml )
    local selection        = publisher.read_attribute(layoutxml,dataxml,"select","string")
    local removeduplicates = publisher.read_attribute(layoutxml,dataxml,"removeduplicates","string")
    local criterion        = publisher.read_attribute(layoutxml,dataxml,"criterion","string")
    local numerical        = publisher.read_attribute(layoutxml,dataxml,"numerical",   "boolean")
    local criterium        = publisher.read_attribute(layoutxml,dataxml,"criterium","string")
    local order            = publisher.read_attribute(layoutxml,dataxml,"order","string","ascending")

    -- spelling error in schema
    local sortkey = criterion or criterium
    local sequence
    if publisher.newxpath then
        sequence, msg = dataxml:eval(selection)
        if msg then err(msg) end
    else
        sequence = xpath.parse(dataxml,selection,layoutxml[".__ns"])
    end
    local tmp = {}
    if #sequence == 0 then
        tmp[1] = sequence
    else
        for i,v in ipairs(sequence) do
            tmp[i] = sequence[i]
        end
    end
    local compare
    if order == "ascending" then
        compare = function( a,b )  return a < b end
    else
        compare = function( a,b )  return a > b end
    end

    if publisher.newxpath then
        if numerical then
            table.sort(tmp, function(a,b) return compare(tonumber(a[".__attributes"][sortkey]), tonumber(b[".__attributes"][sortkey])) end)
        else
            table.sort(tmp, function(a,b) return compare(a[".__attributes"][sortkey],b[".__attributes"][sortkey]) end)
        end
    else
        if numerical then
            table.sort(tmp, function(a,b) return compare(tonumber(a[sortkey]), tonumber(b[sortkey])) end)
        else
            table.sort(tmp, function(a,b) return compare(a[sortkey],b[sortkey]) end)
        end
    end

    if removeduplicates then
        local deleteme = {}
        if publisher.newxpath then
            local last_entry = {[".__attributes"] = {}}
            for i,v in ipairs(tmp) do
                if v[".__attributes"][removeduplicates] == last_entry[".__attributes"][removeduplicates] then
                    deleteme[#deleteme + 1] = i
                end
                last_entry = v
            end
        else
            local last_entry = {}
            for i,v in ipairs(tmp) do
                if v[removeduplicates] == last_entry[removeduplicates] then
                    deleteme[#deleteme + 1] = i
                end
                last_entry = v
            end
        end

        for i=#deleteme,1,-1 do
            -- backwards, otherwise the indexes would be mangled
            table.remove(tmp,deleteme[i])
        end
    end
    return tmp
end


--- Span
--- ---------
--- Surround text by some style like underline or (background-)color
function commands.span( layoutxml,dataxml )
    local backgroundcolor    = publisher.read_attribute(layoutxml,dataxml,"background-color",         "string")
    local bg_padding_top     = publisher.read_attribute(layoutxml,dataxml,"background-padding-top",   "length_sp")
    local bg_padding_bottom  = publisher.read_attribute(layoutxml,dataxml,"background-padding-bottom","length_sp")
    local direction          = publisher.read_attribute(layoutxml,dataxml,"direction",                "string")
    local fontfamilyname     = publisher.read_attribute(layoutxml,dataxml,"fontfamily",               "string")
    local language_name      = publisher.read_attribute(layoutxml,dataxml,"language",                 "string")
    local letterspacing      = publisher.read_attribute(layoutxml,dataxml,"letter-spacing",           "booleanorlength")
    local class              = publisher.read_attribute(layoutxml,dataxml,"class",                    "string")
    local id                 = publisher.read_attribute(layoutxml,dataxml,"id",                       "string")
    local css_rules          = publisher.css:matches({element = 'span', class=class,id=id}) or {}
    local role               = publisher.read_attribute(layoutxml,dataxml,"role",                     "string")


    if letterspacing == nil then
        if css_rules["letter-spacing"] then
            letterspacing = tex.sp(css_rules["letter-spacing"])
        end
    elseif letterspacing == true then
        -- FIXME: this is just a dummy value
        letterspacing = tex.sp("2pt")
    end

    if dashed == nil then dashed = ( css_rules["border-style"] == "dashed") end
    if backgroundcolor == nil then backgroundcolor = css_rules["background-color"]  end
    if bg_padding_top == nil then
        if css_rules["background-padding-top"] then
            bg_padding_top = tex.sp(css_rules["background-padding-top"])
        end
    end
    if bg_padding_bottom == nil then
        if css_rules["background-padding-bottom"] then
            bg_padding_bottom =  tex.sp(css_rules["background-padding-bottom"])
        end
    end
    local colornumber = nil
    if backgroundcolor then
        colornumber = publisher.colors[backgroundcolor].index
    end
    local languagecode
    if language_name then
        languagecode = publisher.get_languagecode(language_name)
    end

    local params = {
        allowbreak = publisher.allowbreak,
        direction = direction,
        fontfamily = publisher.fonts.lookup_fontfamily_name_number[fontfamilyname],
        backgroundcolor = colornumber,
        bg_padding_top = bg_padding_top,
        bg_padding_bottom = bg_padding_bottom,
        letterspacing = letterspacing,
        languagecode = languagecode,
    }
    if publisher.options.format == "PDF/UA" then
        publisher.rolecounter = publisher.rolecounter + 1
        params.role = publisher.get_rolenum(role)
        params.rolecounter = publisher.rolecounter
        params.parent = 0
    end

    local p = par:new(nil,"span2")
    local tab = publisher.dispatch(layoutxml,dataxml)
    for _,j in ipairs(tab) do
        local c = publisher.element_contents(j)
        p:append(c,params)
    end

    return p
end


function commands.structureelement( layoutxml,dataxml )
    local analyzeStructureElement
    analyzeStructureElement = function (lx,parenttable)
        local role = publisher.read_attribute(lx,dataxml,"role", "string")
        local id = publisher.read_attribute(lx,dataxml,"id", "string")
        local parent = publisher.read_attribute(lx,dataxml,"parent", "string")
        if parent then
            parenttable = publisher.structElements[parent]
        end
        local entry = {
            role = role,
            parent = parenttable,
            obj = pdf.reserveobj(),
        }
        if not parenttable then
            publisher.structElements[".root"] = entry
        else
            parenttable[#parenttable+1] = entry
        end
        id = id or string.sub(tostring(entry),8)
        publisher.structElements[id] = entry
        for i = 1, #lx do
            local l = lx[i]
            if type(l) == "table" then
                local cld = analyzeStructureElement(l,entry)
            end
        end

        return entry
    end

    analyzeStructureElement(layoutxml,nil)
end

--- Stylesheet
--- ----------
--- Load a CSS file or read the command's value.
function commands.stylesheet( layoutxml,dataxml )
    local filename = publisher.read_attribute(layoutxml,dataxml,"filename","string")
    if filename then
        publisher.css:parse(filename)
    else
        publisher.css:parsetxt(layoutxml[1])
    end
end

--- Sub
--- ---
--- Subscript. The contents of this element should be written in subscript (smaller, lower)
function commands.sub( layoutxml,dataxml )
    local p = par:new(nil,"sub")
    local tab = publisher.dispatch(layoutxml,dataxml)
    for _,j in ipairs(tab) do
        local c = publisher.element_contents(j)
        p:append(c,{verticalalign = "sub", fontsize = "small"})
    end
    return p
end

--- Sup
--- ---
--- Superscript. The contents of this element should be written in superscript (smaller, higher)
function commands.sup( layoutxml,dataxml )
    local p = par:new(nil,"sup")
    local tab = publisher.dispatch(layoutxml,dataxml)
    for _,j in ipairs(tab) do
        local c = publisher.element_contents(j)
        p:append(c,{verticalalign = "super", fontsize = "small"})
    end
    return p
end

--- Switch
--- ------
--- A case / switch instruction. Can be used on any level.
function commands.switch( layoutxml,dataxml )
    local case_matched = false
    local otherwise,ret,elementname
    for _,case_or_otherwise_element in ipairs(layoutxml) do
        elementname = case_or_otherwise_element[".__local_name"]
        if type(case_or_otherwise_element)=="table" and elementname=="Case" and case_matched ~= true then
            local test = publisher.read_attribute(case_or_otherwise_element,dataxml,"test","string")
            if publisher.newxpath then
                local seq, msg = dataxml:eval(test)
                if msg then err(msg) return nil end
                case_matched = xpath.boolean_value(seq)
                if case_matched then
                    ret = publisher.dispatch(case_or_otherwise_element, dataxml)
                end
            else
            -- newxpath!!
                local ok, tab = xpath.parse_raw(dataxml,test,layoutxml[".__ns"])
                if not ok then
                    err(tab)
                elseif tab[1] then
                    case_matched = true
                    ret = publisher.dispatch(case_or_otherwise_element,dataxml)
                end
            end
        elseif type(case_or_otherwise_element)=="table" and elementname=="Otherwise" then
            otherwise = case_or_otherwise_element
        end -- case/otherwise
    end
    if otherwise and case_matched==false then
        ret = publisher.dispatch(otherwise,dataxml)
    end
    if not ret then return {} end
    return ret
end


--- Table
--- -----
--- Typesets tabular material. Mostly like an HTML table.
function commands.table( layoutxml,dataxml,options )
    local autostretch    = publisher.read_attribute(layoutxml,dataxml,"stretch",         "string")
    local balance        = publisher.read_attribute(layoutxml,dataxml,"balance",         "boolean", false)
    local collapse       = publisher.read_attribute(layoutxml,dataxml,"border-collapse", "string", "separate")
    local columndistance = publisher.read_attribute(layoutxml,dataxml,"columndistance",  "length")
    local eval           = publisher.read_attribute(layoutxml,dataxml,"eval",            "xpath")
    local fontname       = publisher.read_attribute(layoutxml,dataxml,"fontface",        "string")
    local fontfamilyname = publisher.read_attribute(layoutxml,dataxml,"fontfamily",      "string",fontname)
    local padding        = publisher.read_attribute(layoutxml,dataxml,"padding",         "length")
    local rowdistance    = publisher.read_attribute(layoutxml,dataxml,"leading",         "length")
    local textformat     = publisher.read_attribute(layoutxml,dataxml,"textformat",      "string", "__leftaligned")
    local width          = publisher.read_attribute(layoutxml,dataxml,"width",           "length")
    local vexcess        = publisher.read_attribute(layoutxml,dataxml,"vexcess",         "string", "stretch")
    local parent         = publisher.read_attribute(layoutxml,dataxml,"parent",          "string")
    local role           = publisher.read_attribute(layoutxml,dataxml,"role",            "string")

    if fontname then warning("Table/fontface is deprecated and will be removed in version 5. Please use fontfamily instead") end

    -- FIXME: leading -> row distance or so
    padding        = tex.sp(padding        or "0pt")
    columndistance = tex.sp(columndistance or "0pt")
    rowdistance    = tex.sp(rowdistance    or "0pt")
    publisher.setup_page(nil,"commands#table",dataxml)

    if width == nil then
        if publisher.newxpath then
            local tmp = dataxml.vars["__maxwidth"]
            if tmp then
                width = tmp
            else
                err("Can't determine the current width. Tables in groups and data cells must contain explicit widths.")
                width = 50 * 2^16
            end
        else
            if xpath.get_variable("__maxwidth") == nil then
                err("Can't determine the current width. Tables in groups and data cells must contain explicit widths.")
                width = 50 * 2^16
            else
                width = xpath.get_variable("__maxwidth")
            end
        end
    else
        if tonumber(width) ~= nil then
            width  = publisher.current_grid:width_sp(width)
        else
            width = tex.sp(width)
        end
    end
    if not width then
        err("Can't get the width of the table!")
        rule = publisher.add_rule(nil,"head",{height=100*2^16,width=100*2^16})
        local v = node.vpack(rule)
        return v
    end

    if not fontfamilyname then fontfamilyname = "text" end
    local fontfamily = publisher.fonts.lookup_fontfamily_name_number[fontfamilyname]
    publisher.current_fontfamily = fontfamily

    if fontfamily == nil then
        err("Fontfamily %q not found.",fontfamilyname or "???")
        fontfamily = 1
    end
    local tab = {}
    local tab_tmp = publisher.dispatch(layoutxml,dataxml)

    for i=1,#tab_tmp do
        local eltname = publisher.elementname(tab_tmp[i])
        if eltname == "Tr" or eltname == "Columns" or eltname == "Tablehead" or eltname == "Tablefoot" or eltname == "Tablerule" or eltname == "TableNewPage" then
            tab[#tab + 1] = tab_tmp[i]
        elseif eltname == "Value" then
            -- ignore
        else
            if eltname and eltname ~= "elementstructure" then
                splib.log("debug","Ignore command in table","cmd",eltname)
            end
        end
    end

    local tabular = publisher.tabular:new()

    tabular.tab = tab
    tabular.getheight      = publisher.getheight
    tabular.options        = options or { ht_max=99999*2^16 } -- FIXME! Test - this is for tabular in tabular
    tabular.layoutxml      = layoutxml
    tabular.dataxml        = dataxml
    tabular.width          = width
    tabular.fontfamily     = fontfamily
    tabular.padding_left   = padding
    tabular.padding_top    = padding
    tabular.padding_right  = padding
    tabular.padding_bottom = padding
    tabular.colsep         = columndistance
    tabular.rowsep         = rowdistance
    tabular.autostretch    = autostretch
    tabular.vexcess        = vexcess
    tabular.bordercollapse = collapse == "collapse"

    if columndistance > 0 then tabular.bordercollapse_horizontal = false end
    if rowdistance    > 0 then tabular.bordercollapse_vertical   = false end
    if balance then
        local current_area
        if publisher.newxpath then
            current_area = dataxml.vars["__currentarea"]
        else
            current_area = xpath.get_variable("__currentarea")
        end
        tabular.split = publisher.current_grid:number_of_frames(current_area)
    else
        tabular.split = 1
    end
    tabular.textformat = textformat

    if publisher.newxpath then
        dataxml.vars["_last_tr_data"] = ""
    else
        xpath.set_variable("_last_tr_data","")
    end

    local n = tabular:make_table(dataxml)
    if publisher.options.format == "PDF/UA" and role then
        if not parent then
            parent = "doc"
        end
        publisher.setprop(n[1],"role", publisher.get_rolenum(role))
        publisher.setprop(n[1],"parentid", parent)
        publisher.setprop(n[1],"rolecounter", publisher.rolecounter)
        local tblid = role .. "_" .. publisher.rolecounter
        publisher.setprop(n[1],"id", tblid)
        node.set_attribute(n[1],publisher.att_role,publisher.get_rolenum(role))
    end
    if not node.is_node(n) then
        n.balance = balance
    end
    -- Helpful for debugging purpose:
    -- for i=1,#n do
    --     publisher.setprop(n[i],"origin","table")
    -- end
    return n
end

--- Tablefoot
--- ---------
--- The foot gets repeated on every page.
function commands.tablefoot( layoutxml,dataxml )
    local tab = publisher.dispatch(layoutxml,dataxml)
    local page = publisher.read_attribute(layoutxml,dataxml,"page","string","all")
    tab.page = page
    tab._layoutxml = layoutxml
    tab._dataxml = dataxml
    return tab
end

--- Tablehead
--- ---------
--- The foot gets repeated on every page.
function commands.tablehead( layoutxml,dataxml )
    local tab = publisher.dispatch(layoutxml,dataxml)
    local page = publisher.read_attribute(layoutxml,dataxml,"page","string","all")
    tab.page = page
    tab._layoutxml = layoutxml
    tab._dataxml = dataxml
    return tab
end

--- TableNewPage
--- ---------
--- Page break inside a table
function commands.talbenewpage( layoutxml, dataxml )
    return {}
end

--- Tablerule
--- ---------
--- A horizontal rule that is placed between two rows.
function commands.tablerule( layoutxml,dataxml )
    local class     = publisher.read_attribute(layoutxml,dataxml,"class","string")
    local id        = publisher.read_attribute(layoutxml,dataxml,"id",   "string")

    local css_rules = publisher.css:matches({element = "tablerule", class=class,id=id}) or {}

    local tab = {}
    local tmp = css_rules["height"]
    if tmp then
        tab.rulewidth = tex.sp(tmp)
    end


    local attribute = {
        ["rulewidth"]   = "length",
        ["color"]       = "string",
        ["start"]       = "number",
        ["break-below"] = "boolean",
    }

    local tmpattr
    for attname,atttyp in pairs(attribute) do
        tmpattr = publisher.read_attribute(layoutxml,dataxml,attname,atttyp)
        if tmpattr ~= nil then
            tab[attname] = tmpattr
        end
    end
    if tab["break-below"] == nil then tab["break-below"] = true end

    rulewidth  = tab.rulewidth or tex.sp("0.25pt")
    color      = tab.color     or css_rules["background-color"]
    start      = tab.start     or tonumber(css_rules["rule-start"])

    return { rulewidth = rulewidth, color = color, start = start, breakbelow = tab["break-below"] }
end

--- Tr
--- ----
--- A table row. Consists of several Td's
function commands.tr( layoutxml,dataxml )
    local tab = {}
    local tab_tmp = publisher.dispatch(layoutxml,dataxml)

    local class  = publisher.read_attribute(layoutxml,dataxml,"class",  "string")
    local id     = publisher.read_attribute(layoutxml,dataxml,"id",     "string")
    local parent = publisher.read_attribute(layoutxml,dataxml,"parent", "string")
    local role   = publisher.read_attribute(layoutxml,dataxml,"role",   "string")

    local css_rules = publisher.css:matches({element = "tr", class=class,id=id})

    if css_rules and type(css_rules) == "table" then
        for k,v in pairs(css_rules) do
            if k == "vertical-align" then
                tab.valign = v
            elseif k == "background-color" then
                tab.backgroundcolor = v
            else
                tab[k] = v
            end
        end
    end

    local eltname
    -- filter things like <Message ...> that don't give sensible output
    for i=1,#tab_tmp do
        eltname = publisher.elementname(tab_tmp[i])

        if eltname ~= "elementstructure" and eltname ~= "Message" then
            tab[#tab + 1] = tab_tmp[i]
        end
    end
    tab.role = role
    tab.parent = parent

    local attribute = {
        ["data"]             = "xpath",
        ["valign"]           = "string",
        ["background-color"] = "string",
        ["backgroundcolor"]  = "string",
        ["minheight"]        = "length",
        ["top-distance"]     = "string",
        ["break-below"]      = "string",
    }

    local tmpattr
    for attname,atttyp in pairs(attribute) do
        tmpattr = publisher.read_attribute(layoutxml,dataxml,attname,atttyp)
        if tmpattr then
            if attname == "background-color" then attname = "backgroundcolor" end
            tab[attname] = tmpattr
        end
    end

    tab.align = publisher.read_attribute(layoutxml,dataxml,"align","string",nil,"align")
    local sethead = publisher.read_attribute(layoutxml,dataxml,"sethead","string")
    if sethead == "yes" then
        tab.sethead = 1
    elseif sethead == "clear" then
        tab.sethead = 2
    else
        tab.sethead = 0
    end

    if tab["top-distance"] then
        if tonumber(tab["top-distance"]) then
            tab["top-distance"] = publisher.current_grid.gridheight * tab["top-distance"]
        else
            tab["top-distance"] = tex.sp(tab["top-distance"])
        end
    end

    return tab
end

--- Transformation
--- --------------
--- Apply a transformation on an object for PlaceObject. Transformations can be nested.
function commands.transformation( layoutxml,dataxml )
    local tab = publisher.dispatch(layoutxml,dataxml)
    local matrix   = publisher.read_attribute(layoutxml,dataxml,"matrix",  "string")
    local origin_x = publisher.read_attribute(layoutxml,dataxml,"origin-x","string", "50", "origin")
    local origin_y = publisher.read_attribute(layoutxml,dataxml,"origin-y","string", "50", "origin")
    if origin_x == "left" then
        origin_x = 0
    elseif origin_x == "center" then
        origin_x = 50
    elseif origin_x == "right" then
        origin_x = 100
    end
    if origin_y == "top" then
        origin_y = 0
    elseif origin_y == "center" then
        origin_y = 50
    elseif origin_y == "bottom" then
        origin_y = 100
    end
    for i=1,#tab do
        local contents = publisher.element_contents(tab[i])
        if node.is_node(contents) then
            if matrix then
                tab[i].contents = publisher.matrix(contents,matrix,origin_x, origin_y)
            end
        else
            for j=1,#contents do
                if node.is_node(contents[j]) then
                    contents[j] = publisher.matrix(contents[j],matrix,origin_x, origin_y)
                end
            end
        end
    end
    return tab
end

--- Td
--- -----
--- A table cell. Can have anything in it that is a horizontal box.
function commands.td( layoutxml,dataxml )
    local tab = publisher.dispatch(layoutxml,dataxml)
    local parent    = publisher.read_attribute(layoutxml,dataxml,"parent", "string")
    local role      = publisher.read_attribute(layoutxml,dataxml,"role",   "string")

    local class = publisher.read_attribute(layoutxml,dataxml,"class","string")
    local id    = publisher.read_attribute(layoutxml,dataxml,"id",   "string")

    local css_rules = publisher.css:matches({element = "td", class=class,id=id})

    if css_rules and type(css_rules) == "table" then
        for k,v in pairs(css_rules) do
            if k == "vertical-align" then
                tab.valign = v
            elseif k == "background-color" then
                tab.backgroundcolor = v
            elseif k == "border-left-width" then
                tab["border-left"] = v
            elseif k == "border-right-width" then
                tab["border-right"] = v
            elseif k == "border-top-width" then
                tab["border-top"] = v
            elseif k == "border-bottom-width" then
                tab["border-bottom"] = v
            elseif k == "text-align" then
                tab.align = v
            elseif k == "background-text" then
                local x = string.match(v,"\"(.*)\"")
                tab["background-text"] = x
            elseif k == "background-size" then
                tab["background-size"] = v
            else
                tab[k] = v
            end
        end
    end

    local attribute = {
        ["colspan"]          = "number",
        ["rowspan"]          = "number",
        ["padding"]          = "length",
        ["padding-top"]      = "length",
        ["padding-right"]    = "length",
        ["padding-bottom"]   = "length",
        ["padding-left"]     = "length",
        ["background-color"]     = "string",
        ["backgroundcolor"]      = "string",
        ["background-text"]      = "string",
        ["background-textcolor"] = "string",
        ["background-transform"] = "string",
        ["background-size"]        = "string",
        ["background-font-family"] = "string",
        ["graphics"]               = "string",
        ["graphic"]                = "string",
        ["valign"]           = "string",
        ["border-left"]      = "length",
        ["border-right"]     = "length",
        ["border-top"]       = "length",
        ["border-bottom"]    = "length",
        ["border-left-color"]      = "string",
        ["border-right-color"]     = "string",
        ["border-top-color"]       = "string",
        ["border-bottom-color"]    = "string",
        ["rotate"] = "number",
    }

    local tmpattr
    for attname,atttyp in pairs(attribute) do
        tmpattr = publisher.read_attribute(layoutxml,dataxml,attname,atttyp)
        if tmpattr then
            if attname == "background-color" then attname = "backgroundcolor" end
            tab[attname] = tmpattr
        end
    end

    tab.role    = role
    tab.parent  = parent
    -- backwards compatibility. Used to be graphics, but should be without "s" (#457)
    if tab.graphics then
        warning("deprecation note: attribute graphics on Td should be graphic (without s)")
        tab.graphic = tab.graphics
    end

    local tmp = publisher.read_attribute(layoutxml,dataxml,"align","string",nil,"align")
    if tmp then
        tab.align = tmp
    end

    if tab["background-transform"] then
        local angle = string.match(tab["background-transform"],"rotate%((.-)deg%)")
        tab["background-angle"] = tonumber(angle)
    end

    if tab.padding then
        tab.padding_left   = tex.sp(tab.padding)
        tab.padding_right  = tex.sp(tab.padding)
        tab.padding_top    = tex.sp(tab.padding)
        tab.padding_bottom = tex.sp(tab.padding)
    end
    if tab["padding-top"]    then tab.padding_top    = tex.sp(tab["padding-top"])    end
    if tab["padding-bottom"] then tab.padding_bottom = tex.sp(tab["padding-bottom"]) end
    if tab["padding-left"]   then tab.padding_left   = tex.sp(tab["padding-left"])   end
    if tab["padding-right"]  then tab.padding_right  = tex.sp(tab["padding-right"])  end
    return tab
end

--- Trace
--- -----
--- Set various tracing options
function commands.trace(layoutxml,dataxml)
    local assignments      = publisher.read_attribute(layoutxml,dataxml,"assignments",   "boolean")
    local debug            = publisher.read_attribute(layoutxml,dataxml,"debug",         "boolean")
    local grid             = publisher.read_attribute(layoutxml,dataxml,"grid",          "boolean")
    local gridallocation   = publisher.read_attribute(layoutxml,dataxml,"gridallocation","boolean")
    local gridlocation     = publisher.read_attribute(layoutxml,dataxml,"gridlocation",  "string")
    local hyphenation      = publisher.read_attribute(layoutxml,dataxml,"hyphenation",   "boolean")
    local kerning          = publisher.read_attribute(layoutxml,dataxml,"kerning",       "boolean")
    local objects          = publisher.read_attribute(layoutxml,dataxml,"objects",       "boolean")
    local verbose          = publisher.read_attribute(layoutxml,dataxml,"verbose",       "boolean")
    local textformat       = publisher.read_attribute(layoutxml,dataxml,"textformat",    "boolean")

    if assignments ~= nil then
        publisher.options.showassignments = assignments
    end
    if debug ~= nil then
        publisher.options.showdebug = debug
    end
    if grid ~= nil then
        publisher.options.showgrid = grid
    end
    if gridallocation ~= nil then
        publisher.options.showgridallocation = gridallocation
    end
    if hyphenation ~= nil then
        publisher.options.showhyphenation = hyphenation
    end
    if kerning ~= nil then
        publisher.options.showkerning = kerning
    end
    if objects ~= nil then
        publisher.options.showobjects = objects
    end
    if verbose ~= nil then
        publisher.options.trace = verbose
    end
    if textformat ~= nil then
        publisher.options.showtextformat = textformat
    end
    if gridlocation ~= nil then
        if gridlocation == "foreground" or gridlocation == "background" then
            publisher.options.gridlocation = gridlocation
        else
            warning("Grid location %s unknown",gridlocation)
        end

    end
end

--- Text
--- ----
--- Text is currently the only function / command that implements the pull-interface defined by output.
function commands.text(layoutxml,dataxml)
    local colorname      = publisher.read_attribute(layoutxml,dataxml,"color",      "string", "black")
    local fontname       = publisher.read_attribute(layoutxml,dataxml,"fontface",   "string")
    local fontfamilyname = publisher.read_attribute(layoutxml,dataxml,"fontfamily", "string",fontname)
    local textformat     = publisher.read_attribute(layoutxml,dataxml,"textformat", "string","text")
    if fontname then warning("Text/fontface is deprecated and will be removed in version 5. Please use fontfamily instead") end

    local colorindex
    if colorname then
        if not publisher.colors[colorname] then
            err("Color %q is not defined.",colorname)
        else
            colorindex = publisher.colors[colorname].index
        end
    end
    local save_color = publisher.current_fgcolor
    publisher.current_fgcolor = colorindex
    local tab = publisher.dispatch(layoutxml,dataxml)
    publisher.current_fgcolor = save_color

    if not fontfamilyname then fontfamilyname = "text" end
    fontfamily = publisher.fonts.lookup_fontfamily_name_number[fontfamilyname]
    if fontfamily == nil then
        err("Fontfamily %q not found.",fontfamilyname or "???")
        fontfamily = 1
    end

    local save_fontfamily = publisher.current_fontfamily
    publisher.current_fontfamily = fontfamily

    local objects = {}
    for i,j in ipairs(tab) do
        local eltname = publisher.elementname(j)
        local contents = publisher.element_contents(j)
        if eltname == "Paragraph" then
            objects[#objects + 1] = contents
        elseif eltname == "Par" then
            objects[#objects + 1] = contents
        elseif eltname == "Image" then
            local a = par:new(nil,"text")
            local c = contents[1]
            node.set_attribute(c,publisher.att_dontadjustlineheight,1)
            a:append(c)
            objects[#objects + 1] = a
        elseif eltname == "Ul" or eltname == "Ol" then
            for _,w in ipairs(contents) do
                objects[#objects + 1] = w
            end
        elseif eltname == "Text" then
            assert(false)
        elseif eltname == "Action" then
            objects[#objects + 1] = contents
        elseif eltname == "Bookmark" then
            objects[#objects + 1] = contents
        elseif eltname == "HTML" then
            for i=1,#contents do
                objects[#objects + 1] = contents[i]
            end
        else
            err("Unknown element in Text: %q",eltname or "?")
        end
    end
    tab = objects
    tab = publisher.flatten_boxes(tab)

    -- pull returns 'obj', 'state', 'more_to_follow'

    -- pull() gets called whenever we want to fill an area (perhaps the whole page).
    -- We get the height (parameter.maxheight) and the width (parameter.width)
    -- of the area to be filled.
    local cg = publisher.current_grid
    tab.pull = function(parameter,state)
            parameter.fontfamily = fontfamily
            parameter.textformat = publisher.textformats[textformat]
            -- When pull is called the first time the state is not set yet.
            -- Currently we format all sub-objects (paragraphs),
            -- add them into the "object list" (state.objects) and
            -- call vsplit on the object list.
            if not state then
                state = {}
                local objects = {}
                state.total_height = 0
                state.objects = objects
                local obj
                local extra_accumulated = 0
                for i=1,#tab do
                    local contents = tab[i]
                    local dont_format = 0
                    if  node.is_node(contents.nodelist) then
                        dont_format = node.has_attribute(contents.nodelist,publisher.att_dont_format)
                    end
                    if dont_format == 1 then
                        obj = node.vpack(contents.nodelist)
                    else
                        -- contents.nodelist = publisher.set_color_if_necessary(contents.nodelist,colorindex)
                        -- publisher.set_fontfamily_if_necessary(contents.nodelist,fontfamily)
                        obj = contents:format(parameter.width,parameter,dataxml)
                    end
                    objects[#objects + 1] = obj
                    local ht_rows, extra = cg:height_in_gridcells_sp(obj.height + obj.depth + extra_accumulated, {extrathreshold = -100})
                    extra_accumulated = extra
                    local overshoot = cg:advance_cursor(ht_rows,parameter.area)
                    if overshoot > 0 then
                        if cg:number_of_frames(parameter.area) > cg:framenumber(parameter.area) then
                            cg:advance_cursor(overshoot,parameter.area)
                        elseif publisher.pages[cg.pagenumber + 1] then
                            -- FIXME: it could be that the advance_cursor is so large that it should
                            -- get to some future page..
                            local next_page_grid = publisher.pages[cg.pagenumber + 1].grid
                            next_page_grid:advance_cursor(overshoot,parameter.area)
                        end
                    end
                end
            end

            if #state.objects > 0 then
                local obj1, obj2 = publisher.vsplit(state.objects,parameter)
                -- if state.prevobj1 == obj1 then
                --     err("Internal error vsplit / objects too high. Some objects are discarded from the output.")
                --     state.objects = {}
                --     return obj1,state,false
                -- end
                if obj2 then
                    state.split = obj2
                    return obj1, state, false
                else
                    state.prevobj1 = obj1
                    return obj1,state, #state.objects > 0
                end
            else
                return nil,nil, false
            end
        end
   return tab
end

--- Textblock
--- ---------
--- A rectangular block of text. Return a vertical nodelist.
function commands.textblock( layoutxml,dataxml )
    local fontfamily
    local angle          = publisher.read_attribute(layoutxml,dataxml,"angle",         "number")
    local colorname      = publisher.read_attribute(layoutxml,dataxml,"color",         "string", "black")
    local columns        = publisher.read_attribute(layoutxml,dataxml,"columns",       "number")
    local columndistance = publisher.read_attribute(layoutxml,dataxml,"columndistance","string")
    local fontname       = publisher.read_attribute(layoutxml,dataxml,"fontface",      "string")
    local fontfamilyname = publisher.read_attribute(layoutxml,dataxml,"fontfamily",    "string",fontname)
    local language_name  = publisher.read_attribute(layoutxml,dataxml,"language",      "string")
    local minheight      = publisher.read_attribute(layoutxml,dataxml,"minheight",     "height_sp")
    local textformat     = publisher.read_attribute(layoutxml,dataxml,"textformat",    "string","text")
    local width          = publisher.read_attribute(layoutxml,dataxml,"width",         "length_sp")
    if fontname then warning("Textblock/fontface is deprecated and will be removed in version 5. Please use fontfamily instead") end

    local save_width
    if publisher.newxpath then
        save_width = dataxml.vars["__maxwidth"]
    else
        save_width = xpath.get_variable("__maxwidth")
    end
    width = width or save_width
    if publisher.newxpath then
        dataxml.vars["__maxwidth"] = width
    else
        xpath.set_variable("__maxwidth", width)
    end
    if not width then
        err("Can't evaluate width in textblock")
        rule = publisher.add_rule(nil,"head",{height=100*2^16,width=100*2^16})
        local v = node.vpack(rule)
        return v
    end

    if textformat and not publisher.textformats[textformat] then err("Textblock: textformat %q unknown",tostring(textformat)) end

    publisher.intextblockcontext = publisher.intextblockcontext + 1

    columns = columns or 1
    if not columndistance then columndistance = "3mm" end
    if tonumber(columndistance) then
        columndistance = publisher.current_grid.gridwidth * columndistance
    else
        columndistance = tex.sp(columndistance)
    end

    if not fontfamilyname then fontfamilyname = "text" end
    fontfamily = publisher.fonts.lookup_fontfamily_name_number[fontfamilyname]
    if fontfamily == nil then
        err("Fontfamily %q not found.",fontfamilyname or "???")
        fontfamily = 1
    end

    local save_fontfamily = publisher.current_fontfamily
    publisher.current_fontfamily = fontfamily

    local colorindex
    if colorname then
        if not publisher.colors[colorname] then
            err("Color %q is not defined.",colorname)
        else
            colorindex = publisher.colors[colorname].index
        end
    end

    if language_name then
        languagecode = publisher.get_languagecode(language_name)
    else
        languagecode = publisher.defaultlanguage
    end

    -- FIXME: remove width_sp
    local width_sp = width

    local objects, nodes = {},{}
    local nodelist

    if colorname then
        save_color = publisher.current_fgcolor
        publisher.current_fgcolor = colorindex
    end


    local options = {
        color = colorindex,
        fontfamily = fontfamily,
        languagecode = languagecode,
        textformat = publisher.textformats[textformat],
    }

    local tab = publisher.dispatch(layoutxml,dataxml,options)
    if colorname then
        publisher.current_fgcolor = save_color
    end

    for i,j in ipairs(tab) do
        local eltname = publisher.elementname(j)
        local contents = publisher.element_contents(j)
        if eltname == "Paragraph" then
            objects[#objects + 1] = contents
        elseif eltname == "Par" then
            objects[#objects + 1] = contents
        elseif eltname == "Ul" or eltname == "Ol" then
            for j,w in ipairs(contents) do
                objects[#objects + 1] = w
            end
        elseif eltname == "Action" then
            objects[#objects + 1] = contents
        elseif eltname == "Bookmark" then
            objects[#objects + 1] = contents
        elseif eltname == "HTML" then
            for c=1,#contents do
                local par = contents[c]
                objects[#objects + 1]  = par
            end
        end
    end

    if columns > 1 then
        width_sp = math.floor(  (width_sp - columndistance * ( columns - 1 ) )   / columns)
    end

    for _,paragraph in ipairs(objects) do
        if paragraph.id == publisher.whatsit_node then
            -- todo: document how this can be!
            nodes[#nodes + 1] = paragraph
        elseif paragraph.nodelist then
            nodelist = paragraph.nodelist
            local tmp = node.has_attribute(nodelist,publisher.att_dont_format)
            if tmp ~= 1 then
                publisher.set_fontfamily_if_necessary(nodelist,fontfamily)
                paragraph.nodelist = publisher.set_color_if_necessary(nodelist,colorindex)
                node.slide(nodelist)
                nodelist = paragraph:format(width_sp,{textformat = textformat},dataxml)
            end

            nodes[#nodes + 1] = nodelist
        else
            -- new <Par> mode
            local fmt = paragraph:format(width_sp,options,dataxml)
            if publisher.options.format == "PDF/UA" then
                publisher.setprop(fmt,"role", paragraph.role)
                local parent = paragraph.parent or "doc"
                publisher.setprop(fmt,"parentid", parent)
                publisher.setprop(fmt,"rolecounter", paragraph.rolecounter)
                publisher.setprop(fmt,"id", paragraph.id)
                publisher.setprop(fmt,"strutpos", paragraph.strutpos)
                publisher.setprop(fmt,"actualtext",paragraph.actualtext)
                node.set_attribute(fmt,publisher.att_role,paragraph.role)
            end
            table.insert( nodes, fmt )
        end
    end

    if #objects == 0 then
        splib.log("warn","Textblock: no objects found", lineinfo(layoutxml))
        warning("Textblock: no objects found!")
        local vrule = {  width = 10 * 2^16, height = -1073741824}
        nodes[1] = publisher.add_rule(nil,"head",vrule)
    end

    --- Multi column typesetting
    if columns > 1 then
        local rows = {}
        local number_of_rows = 0
        local new_nodes = {}
        for i=1,#nodes do
            for n in node.traverse_id(publisher.hlist_node,nodes[i].list) do
                number_of_rows = number_of_rows + 1
                rows[number_of_rows] = node.vpack(node.copy(n))
            end
        end

        local rows_in_multicolumn = math.ceil(number_of_rows / columns)
        for i=1,rows_in_multicolumn do
            local current_row,hbox_current_row
            hbox_current_row = rows[i] -- first column
            local tail = hbox_current_row
            for j=2,columns do -- second and following columns
                local g1 = set_glue(nil,{width = columndistance})
                tail.next = g1
                g1.prev = tail
                current_row = (j - 1) * rows_in_multicolumn + i
                if current_row <= number_of_rows then
                    tail = rows[current_row]
                    g1.next = tail
                    tail.prev = g1
                end
            end
            tail.next = nil
            local tmp = node.hpack(hbox_current_row)
            publisher.setprop(tmp,"origin","columns > 1")
            new_nodes[#new_nodes + 1] = tmp
        end
        nodes=new_nodes
    end

    local tail
    for i=2,#nodes do
        tail = node.tail(nodes[i-1])
        tail.next = nodes[i]
        nodes[i].prev = tail
    end

    nodelist = node.vpack(nodes[1])
    if angle then
        nodelist = publisher.rotate_textblock(nodelist,angle)
    end

    publisher.current_fontfamily = save_fontfamily
    if publisher.newxpath then
        dataxml.vars["__maxwidth"] = save_width
    else
        xpath.set_variable("__maxwidth", save_width)
    end
    publisher.intextblockcontext = publisher.intextblockcontext - 1
    if minheight then
        nodelist.height = math.max(nodelist.height + nodelist.depth, minheight )
        nodelist.depth = 0
    end
    return nodelist
end

--- Underline
--- ---------
--- Underline text. This is done by setting the `att_underline` attribute and in the "finalizer"
--- drawing a line underneath the text.
function commands.underline( layoutxml,dataxml )
    local dashed = publisher.read_attribute(layoutxml,dataxml,"dashed", "boolean")
    local class  = publisher.read_attribute(layoutxml,dataxml,"class",  "string")
    local id     = publisher.read_attribute(layoutxml,dataxml,"id",     "string")

    local css_rules = publisher.css:matches({element = 'u', class=class,id=id}) or {}
    if dashed == nil then dashed = ( css_rules["border-style"] == "dashed") end

    local p = par:new(nil,"underline")
    local tds = "solid"
    if dashed then
        tds = "dashed"
    end


    local tab = publisher.dispatch(layoutxml,dataxml)

    for _,j in ipairs(tab) do
        local c = publisher.element_contents(j)
        p:append(c,{textdecorationline = "underline", textdecorationstyle = tds})
    end
    return p
end

--- Unordered list (`<Ul>`)
--- ------------------
--- A list with bullet points.
function commands.ul(layoutxml,dataxml )
    local fontfamilyname = publisher.read_attribute(layoutxml,dataxml,"fontfamily","string")
    local fontfamily
    if fontfamilyname then
        fontfamily = publisher.fonts.lookup_fontfamily_name_number[fontfamilyname]
        if fontfamily == nil then
            err("Fontfamily %q not found.",fontfamilyname)
            fontfamily = 0
        end
        publisher.current_fontfamily = fontfamily
    else
        fontfamily = nil
    end
    if not fontfamily then fontfamily = publisher.fonts.lookup_fontfamily_name_number["text"] end

    local ret = {}
    local labelwidth = tex.sp("5mm")
    local tab = publisher.dispatch(layoutxml,dataxml)
    for i,j in ipairs(tab) do
        local a = par:new(nil,"ul")
        a:append(publisher.bullet_hbox(labelwidth,{fontfamily = fontfamily}))
        a:append(publisher.element_contents(j),{})
        ret[#ret + 1] = a
    end

    return ret
end


--- Until
--- -----
--- A repeat .. until loop. Use the condition in `test` to determine if the loop should exit
function commands.until_do( layoutxml,dataxml )
    local test = publisher.read_attribute(layoutxml,dataxml,"test","string")
    assert(test)
    repeat
        publisher.dispatch(layoutxml,dataxml)
    until xpath.parse(dataxml,test,layoutxml[".__ns"])
end


--- URL
--- ---
--- Format the current URL. It should make the URL active.
function commands.url(layoutxml,dataxml)
    local a = par:new(nil,"URL")
    local strings = {}
    local tab = publisher.dispatch(layoutxml,dataxml)
    for i = 1, #tab do
        local contents = publisher.element_contents(tab[i])
        if publisher.elementname(tab[i]) == "Value" and type(contents) == "table" then
            strings[#strings+1] = publisher.xml_stringvalue(contents)
        end
    end
    local str = table.concat(strings)
    local urlnodes = publisher.mknodes(str,options)
    a:append(publisher.break_url(urlnodes))
    return a
end


--- Value
--- -----
--- Get the value of an xpath expression (attribute `select`) or of the literal string.
function commands.value( layoutxml,dataxml )
    local selection = publisher.read_attribute(layoutxml,dataxml,"select","string")
    local tab
    if selection then
        if publisher.newxpath then
            local ret = {}
            local seq, msg = dataxml:eval(selection)
            if msg then
                splib.error("xpath error","message",msg)
                return
            end
            if seq then
                if seq.raw == true then
                    return seq
                else
                    for i = 1, #seq do
                        ret[#ret+1] = seq[i]
                    end
                end
            end
            return ret
        else
            local ok
            ok, tab = xpath.parse_raw(dataxml,selection,layoutxml[".__ns"])
            if not ok then err(tab) return end
            -- tab can now contain markup coming from data.xml such as <sup>...</sup>
        end
    else
        -- Change all br elements to \n
        for i=1,#layoutxml do
            if type(layoutxml[i]) == "table" and string.match(layoutxml[i][".__local_name"],"^[bB][rR]$") then
                layoutxml[i] = "\n"
            end
        end
        tab = table.concat(layoutxml)
    end
    return tab
end

--- VSpace
--- ------
--- Create a vertical space that stretches up to infinity
function commands.vspace( layoutxml,dataxml )
    local height      = publisher.read_attribute(layoutxml,dataxml,"height", "height_sp")
    local minheight   = publisher.read_attribute(layoutxml,dataxml,"minheight", "height_sp")

    local n
    if height == nil then
        n = set_glue(nil,{width = minheight or 0, stretch = 2^16, stretch_order = 3})
    else
        n = set_glue(nil,{width = tonumber(height)})
    end

    publisher.setprop(n,"origin","vspace")
    return n
end


--- While
--- -----
--- A while loop. Use the condition in `test` to determine if the loop should be entered
function commands.while_do( layoutxml,dataxml )
    local test = publisher.read_attribute(layoutxml,dataxml,"test","string")
    assert(test)
    if publisher.newxpath then
        while true do
            local seq, msg = dataxml:eval(test)
            if msg then
                splib.error(msg)
                break
            end
            local tf = xpath.boolean_value(seq)
            if not tf then
                break
            end
            publisher.dispatch(layoutxml,dataxml)
        end
    else
        while xpath.parse(dataxml,test,layoutxml[".__ns"]) do
            publisher.dispatch(layoutxml,dataxml)
        end
    end
end

file_end("commands.lua")
return commands

