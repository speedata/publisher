--
--  metapost.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.


module(...,package.seeall)

-- PostScript operators and their pdf equivalent and #arguments. These are just the simple cases.
local pdfoperators = {
    closepath = {"h",0},
    curveto = {"c",6},
    clip = {"W n",0},
    fill = {"f",0},
    gsave = {"q",0},
    grestore = {"Q",0},
    lineto = {"l",2},
    moveto = {"m",2},
    setlinejoin = {"j",1},
    setlinecap = {"J",1},
    setlinewidth = {"w",1},
    stroke = {"S",0},
    setmiterlimit = {"M",1},
}

local ignored_pdfoperators = {
    showpage = true,
    newpath = true,
}

local function getboundingbox(pdfimage,txt)
    local a,b,c,d = string.match(txt,"^%%%%HiResBoundingBox: (%S+) (%S+) (%S+) (%S+)")
    pdfimage.highresbb = { tonumber(a), tonumber(b), tonumber(c), tonumber(d)}
end

-- PostScript is a stack based, full featured programming langauge whereas pdf is just a simple
-- text format. Therefore an interpretation of the input would be necessary, but I try
-- with a simple analysis for now.
local function getpostscript(stack,pdfimage,txt)
    local push = function(elt)
        -- w("PUSH %s",tostring(elt))
        table.insert(stack,elt)
    end

    local pop = function()
        local elt = table.remove(stack)
        -- w("POP %s",tostring(elt))
        return elt
    end

    local tbl = string.explode(txt)
    for i = 1, #tbl do
        local thistoken = tbl[i]
        if tonumber(thistoken) then
            push(tonumber(thistoken))
        elseif thistoken == "[]" then
            push({})
        elseif string.match(thistoken,"^%[") then
            push("[")
            push(string.sub(thistoken,2))
        elseif string.match(thistoken,"%]$") then
            push(string.sub(thistoken,1,-2))
            local arystart = #stack
            for s = #stack,1,-1 do
                if stack[s] == "[" then
                    arystart = s
                end
            end
            local ary = {}
            table.remove(stack,arystart)
            for s = arystart,#stack do
                table.insert(ary,stack[s])
            end
            for s = #stack,arystart,-1 do
                pop()
            end
            push(ary)
        elseif thistoken == "concat" then
            local ary = pop()
            for s = 1,#ary do
                table.insert(pdfimage,ary[s])
            end
            table.insert(pdfimage,"cm")
        elseif thistoken == "dtransform" then
            -- get two, push two
        elseif thistoken == "truncate" then
            -- truncate prev token
        elseif thistoken == "idtransform" then
            -- get two, push two
        elseif thistoken == "setdash" then
            -- TODO: correct
            local a = pop()
            local b = pop()
            table.insert(pdfimage, "[" .. table.concat(b," ") .. "]")
            table.insert(pdfimage,a)
            table.insert(pdfimage,"d")
        elseif thistoken == "setrgbcolor" then
            local b, g, r = pop(),pop(),pop()
            table.insert(pdfimage, r)
            table.insert(pdfimage, g)
            table.insert(pdfimage, b)
            table.insert(pdfimage, "rg")
            table.insert(pdfimage, r)
            table.insert(pdfimage, g)
            table.insert(pdfimage, b)
            table.insert(pdfimage, "RG")
        elseif thistoken == "setcmykcolor" then
            local k, y, m, c = pop(),pop(),pop(),pop()
            table.insert(pdfimage, c)
            table.insert(pdfimage, m)
            table.insert(pdfimage, y)
            table.insert(pdfimage, k)
            table.insert(pdfimage, "K")
            table.insert(pdfimage, c)
            table.insert(pdfimage, m)
            table.insert(pdfimage, y)
            table.insert(pdfimage, k)
            table.insert(pdfimage, "k")
        elseif thistoken == "exch" then
            local a,b = pop(), pop()
            table.insert(pdfimage, a)
            table.insert(pdfimage, b)
        elseif thistoken == "pop" then
            table.remove(stack)
        elseif thistoken == "rlineto" then
            local dy,dx = pop(),pop()
            pdfimage.curx = pdfimage.curx + dx
            pdfimage.cury = pdfimage.cury + dy
            table.insert(pdfimage,pdfimage.curx)
            table.insert(pdfimage,pdfimage.cury)
            table.insert(pdfimage,"l")
        elseif pdfoperators[thistoken] then
            local tab = pdfoperators[thistoken]
            for s = tab[2],1,-1 do
                table.insert(pdfimage,stack[#stack + 1 - s])
            end
            for s = 1,tab[2] do
                table.remove(stack)
            end
            if thistoken == "moveto" or thistoken == "lineto" or thistoken == "curveto" then
                pdfimage.curx = pdfimage[#pdfimage - 1]
                pdfimage.cury = pdfimage[#pdfimage]
            end
            table.insert(pdfimage,tab[1])
        elseif ignored_pdfoperators[thistoken] then
            -- ignore
        else
            w("metapost.lua: ignore %s ",thistoken)
        end
    end
end

function pstopdf(str)
    -- w("str %s",tostring(str))
    lines = {}
    for s in str:gmatch("[^\r\n]+") do
        table.insert(lines, s)
    end

    local pdfimage = {}
    local stack = {}
    for i =1,#lines do
        local thisline = lines[i]
        if string.match(thisline,"^%%%%HiResBoundingBox:") then
            getboundingbox(pdfimage,thisline)
        elseif string.match(thisline,"^%%") then
            -- ignore
        else
            getpostscript(stack,pdfimage,thisline)
        end
    end

    return table.concat(pdfimage," ")
end


local function finder (name, mode, type)
    local loc = kpse.find_file(name)
    if mode == "r" then return loc  end
    return name
end

function execute(mpobj,str)
    -- w("execute %q",str)
    if not str then
        err("Empty metapost string for execute")
        return false
    end
    local l = mpobj.mp:execute(str)
    if l and l.status > 0 then
        err("Executing %s: %s", str,l.term)
        return false
    end
    mpobj.l = l
    return true
end

function newbox(width_sp, height_sp)
    local mp = mplib.new({mem_name = 'plain', find_file = finder,ini_version=true })
    local mpobj = {
        mp = mp,
        width = width_sp,
        height = height_sp,
    }
    if not execute(mpobj,"input plain;") then
        err("Cannot start metapost.")
        return nil
    end
    execute(mpobj,string.format("box_width = %fbp;",width_sp / 65782))
    execute(mpobj,string.format("box_height = %fbp;",height_sp / 65782))


    local declarations = {}
    for name,v in pairs(publisher.metapostcolors) do
        if v.model == "cmyk" then
            local varname = string.gsub(name,"%d","[]")
            local decl = string.format("cmykcolor colors_%s;",varname)
            if not declarations[decl] then
                declarations[decl] = true
                execute(mpobj,decl)
            end
            local mpstatement = string.format("colors_%s := (%g, %g, %g, %g);",name, v.c, v.m, v.y, v.k )

            execute(mpobj,mpstatement)
        elseif v.model == "rgb" then
            execute(mpobj,string.format("rgbcolor colors_%s; colors_%s := (%g, %g, %g);",name, name, v.r, v.g, v.b ))
        end
    end

    for name, v in pairs(publisher.metapostvariables) do
        local expr
        expr = string.format("%s %s ; %s := %s ;", v.typ,name,name,v[1])
        metapost.execute(mpobj,expr)
    end
    return mpobj
end

function finish(mpobj)
    local pdfstring
    if mpobj.l and mpobj.l.fig and mpobj.l.fig[1] then
        pdfstring = "q " .. pstopdf(mpobj.l.fig[1]:postscript()) .. " Q"
    end
    mpobj.mp:finish()
    return pdfstring
end

-- Return a pdf_whatsit node
function prepareboxgraphic(width_sp,height_sp,graphic)
    if not publisher.metapostgraphics[graphic] then
        err("MetaPost graphic %s not defined",graphic)
        return nil
    end
    local mpobj = newbox(width_sp,height_sp)
    execute(mpobj,"beginfig(1);")
    execute(mpobj,publisher.metapostgraphics[graphic])
    execute(mpobj,"endfig;")
    local pdfstring = finish(mpobj);
    local a=node.new("whatsit","pdf_literal")
    a.data = pdfstring
    a.mode = 0
    return mpobj,a
end

-- return a vbox with the pdf_whatsit node
function boxgraphic(width_sp,height_sp,graphic)
    local mpobj, a = prepareboxgraphic(width_sp,height_sp,graphic)
    a = node.hpack(a,mpobj.width,"exactly")
    a.height = mpobj.height
    a = node.vpack(a)
    return a
end