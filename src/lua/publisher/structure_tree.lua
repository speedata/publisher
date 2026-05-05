-- PDF/UA structure tree, bookmarks and page-label helpers.
--
--  structure_tree.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("structure_tree.lua")

local publisher = require("publisher")

---@class structure_tree_module
local M = {}

---@type table<string, integer>
local roles = {}

-- Initialize the roles lookup at first use; publisher.roles_a is set in
-- publisher.lua's body and we run our require there too late to access it
-- directly.
---@return nil
local function ensure_roles()
    if next(roles) then
        return
    end
    for k, v in pairs(publisher.roles_a) do
        roles[v] = k
    end
end

-- Bookmarks are collected during the run and processed at shipout. This
-- function recursively emits `\pdfoutline` TeX code from the bookmark tree.
---@param tbl Bookmark Bookmark tree (or single bookmark with children).
---@return nil
function M.bookmarkstotex(tbl)
    local countstring
    local open_string
    if #tbl == 0 then
        countstring = ""
    else
        if tbl.open == "true" then
            open_string = ""
        else
            open_string = "-"
        end
        countstring = string.format("count %s%d", open_string, #tbl)
    end
    if tbl.destination then
        tex.sprint(
            string.format(
                "\\pdfoutline goto num %s %s {%s}",
                tbl.destination,
                countstring,
                publisher.utf8_to_utf16_string_pdf(tbl.name)
            )
        )
    end
    for _, v in ipairs(tbl) do
        M.bookmarkstotex(v)
    end
end

---@alias PdfActionType
---| 0 # page
---| 1 # goto
---| 2 # thread
---| 3 # user

-- Creates a `pdf_action` whatsit node for the given action type.
---@param action_type PdfActionType
---@return Node
function M.get_action_node(action_type)
    local ai = node.new("whatsit", "pdf_action")
    ai.action_type = action_type
    return ai
end

-- Resolves a structure role name (e.g. `"Document"`, `"P"`) to its numeric
-- index in `publisher.roles_a`. Logs an error for unknown roles.
---@param rolestring string?
---@return integer? rolenum
function M.get_rolenum(rolestring)
    if not rolestring then
        return nil
    end
    ensure_roles()
    local ret = roles[rolestring]
    if ret then
        return ret
    end
    main.log("error", string.format("Unknown role %q", tostring(rolestring)))
end

-- Returns the sort key for a structure-tree child: the mapped page number
-- for nested struct elements, or `math.huge` for raw MCID numbers (so they
-- keep their relative order). Recurses into descendants when no `page` is
-- set on the child itself.
---@param child table|integer
---@param page_map table<integer, integer> Maps PDF page reference numbers to logical page numbers.
---@return integer|number
local function get_struct_page_position(child, page_map)
    if type(child) == "number" then
        return math.huge
    end
    if child.page then
        return page_map[child.page] or math.huge
    end
    for i = 1, #child do
        local pos = get_struct_page_position(child[i], page_map)
        if pos ~= math.huge then
            return pos
        end
    end
    return math.huge
end

-- Sorts the children of each structure element by page order (reading
-- order), using a stable sort to preserve original order within a page.
-- Only changes anything when pages were rearranged (InsertPages /
-- SavePages).
---@param elem table Structure element (modified in place).
---@param page_ref_to_pagenumber table<integer, integer>
---@return nil
function M.sort_struct_tree_by_page_order(elem, page_ref_to_pagenumber)
    if type(elem) ~= "table" then
        return
    end
    for i = 1, #elem do
        if type(elem[i]) == "table" then
            M.sort_struct_tree_by_page_order(elem[i], page_ref_to_pagenumber)
        end
    end
    if #elem < 2 then
        return
    end
    local tagged = {}
    for i = 1, #elem do
        tagged[i] = { child = elem[i], orig = i, page_pos = get_struct_page_position(elem[i], page_ref_to_pagenumber) }
    end
    publisher.utilities.stable_sort(tagged, function(a, b)
        if a.page_pos ~= b.page_pos then
            return a.page_pos < b.page_pos
        end
        return a.orig < b.orig
    end)
    for i = 1, #elem do
        elem[i] = tagged[i].child
    end
end

-- Escapes the five XML metacharacters in a string. Used by the structure
-- tree XML dumper, not by the production XMP path.
---@param s string
---@return string
local function struct_xml_escape(s)
    s = string.gsub(s, "&", "&amp;")
    s = string.gsub(s, "<", "&lt;")
    s = string.gsub(s, ">", "&gt;")
    s = string.gsub(s, '"', "&quot;")
    return s
end

-- Serializes a structure tree to indented XML for debugging. MCID children
-- are emitted as `<MCID>n</MCID>`; nested struct elements recurse.
---@param elem table Structure tree root or sub-tree.
---@param indent string? Leading whitespace prefix (used internally).
---@param page_ref_to_num table<integer, integer>? Maps PDF page refs to logical page numbers.
---@return string xml
function M.dump_struct_tree_xml(elem, indent, page_ref_to_num)
    indent = indent or ""
    local lines = {}
    local role = elem.role or "Unknown"
    local attrs = ""
    if elem.page then
        local pagenum = page_ref_to_num and page_ref_to_num[tonumber(elem.page)] or elem.page
        attrs = attrs .. string.format(' page="%s"', tostring(pagenum))
    end
    if elem.actualtext then
        attrs = attrs .. string.format(' actualtext="%s"', struct_xml_escape(elem.actualtext))
    end
    if elem.alttext then
        attrs = attrs .. string.format(' alttext="%s"', struct_xml_escape(elem.alttext))
    end

    local mcids = {}
    local children = {}
    for i = 1, #elem do
        local child = elem[i]
        if type(child) == "table" then
            children[#children + 1] = child
        else
            mcids[#mcids + 1] = tostring(child)
        end
    end

    if #children == 0 and #mcids == 0 then
        lines[#lines + 1] = indent .. "<" .. role .. attrs .. "/>"
    else
        lines[#lines + 1] = indent .. "<" .. role .. attrs .. ">"
        for _, mcid in ipairs(mcids) do
            lines[#lines + 1] = indent .. "  <MCID>" .. mcid .. "</MCID>"
        end
        for _, child in ipairs(children) do
            lines[#lines + 1] = M.dump_struct_tree_xml(child, indent .. "  ", page_ref_to_num)
        end
        lines[#lines + 1] = indent .. "</" .. role .. ">"
    end
    return table.concat(lines, "\n")
end

-- Recursively writes `/StructElem` PDF objects for the given structure
-- tree. Returns the indirect reference of `itm` so callers can splice it
-- into their parent's `/K` array.
---@param itm StructElement
---@param parentobjectnumber integer PDF object number of the parent struct elem.
---@return string indirect_ref e.g. `"7 0 R"`.
function M.writeStructElements(itm, parentobjectnumber)
    local obj = itm.obj
    local objectnumbers = {}
    for i = 1, #itm do
        local thisitm = itm[i]
        if type(thisitm) == "table" then
            local onum = M.writeStructElements(thisitm, obj)
            objectnumbers[#objectnumbers + 1] = onum
        else
            objectnumbers[#objectnumbers + 1] = string.format("%d", thisitm)
        end
    end
    if itm.linkobjects then
        objectnumbers[#objectnumbers + 1] =
            string.format("<</Type/OBJR /Obj %d 0 R /Pg %d 0 R >>", itm.linkobjects[1], itm.page)
    end

    local k
    if #objectnumbers > 1 then
        k = string.format("[ %s ]", table.concat(objectnumbers, " "))
    else
        k = objectnumbers[1]
    end

    if k then
        if not itm.role then
            main.log("error", "Unknown role in structure")
        end
        local str = {
            "/Type /StructElem",
            "/S /" .. (itm.role or "???"),
            "/P " .. parentobjectnumber .. " 0 R",
            "/K " .. k,
        }
        if itm.actualtext then
            str[#str + 1] = "/ActualText " .. publisher.utf8_to_utf16_string_pdf(itm.actualtext)
        end
        if itm.alttext then
            str[#str + 1] = "/Alt " .. publisher.utf8_to_utf16_string_pdf(itm.alttext)
        end
        if itm.bbox then
            local bbox = itm.bbox
            str[#str + 1] = string.format(
                "/A << /BBox [%s %s %s %s] /Placement /Block /O /Layout >>",
                bbox[1],
                bbox[2],
                bbox[3],
                bbox[4]
            )
        end
        if itm.page then
            str[#str + 1] = "/Pg " .. itm.page .. " 0 R"
        end
        pdf.obj({ type = "raw", objnum = obj, immediate = true, string = "<<" .. table.concat(str, " ") .. ">>" })
    end
    return string.format("%d 0 R", obj)
end

-- Builds the `/PageLabels` catalog entry from `publisher.pagelabels` and
-- populates `publisher.visible_pagenumbers` as a side effect. Returns
-- `nil` when the labels reduce to a single trivial decimal range.
---@return string? page_labels_dict The full `/PageLabels << ... >>` fragment, or `nil`.
function M.get_page_labels_str()
    local labeltypes = {
        ["lowercase-romannumeral"] = "/r",
        ["uppercase-romannumeral"] = "/R",
        decimal = "/D",
        ["lowercase-letter"] = "/a",
        ["uppercase-letter"] = "/A",
    }
    local labelfunc = function(label, pagenumber)
        if label == "lowercase-romannumeral" then
            return tex.romannumeral(pagenumber)
        elseif label == "uppercase-romannumeral" then
            return string.upper(tex.romannumeral(pagenumber))
        elseif label == "lowercase-letter" then
            return string.char(96 + pagenumber)
        elseif label == "uppercase-letter" then
            return string.char(64 + pagenumber)
        else
            return pagenumber
        end
    end

    local prevmatter
    local tmp = {}
    local c = 0
    -- reset, there might be more pages in the previous run.
    publisher.visible_pagenumbers = {}
    local pagelabels = publisher.pagelabels
    local matters = publisher.matters
    for i = 1, #pagelabels do
        c = c + 1
        local p = pagelabels[i]
        if p then
            local mattername = p.matter
            local thismatter = matters[mattername]

            if prevmatter ~= mattername then
                local str = {}
                if thismatter.prefix and thismatter.prefix ~= "" then
                    str[#str + 1] = "/P " .. publisher.utf8_to_utf16_string_pdf(thismatter.prefix)
                end
                if thismatter.label then
                    str[#str + 1] = "/S " .. (labeltypes[thismatter.label] or "/D")
                else
                    str[#str + 1] = "/S /D"
                end
                if prevmatter and matters[prevmatter].resetafter then
                    c = 1
                end
                if thismatter.resetbefore then
                    c = 1
                end
                if c > 1 then
                    str[#str + 1] = string.format("/St %d", c)
                end
                prevmatter = mattername
                tmp[#tmp + 1] = string.format("%d << %s >>", p.pagenumber - 1, table.concat(str, " "))
            end
            publisher.visible_pagenumbers[i] =
                string.format("%s%s", thismatter.prefix or "", labelfunc(thismatter.label, c))
        end
    end
    local tmpstring = table.concat(tmp, " ")
    if tmpstring == "" or tmpstring == "0 << /S /D >>" then
        return nil
    end
    return string.format("/PageLabels << /Nums [ %s ] >> ", tmpstring)
end

---@type integer
local destcounter = 0

-- Creates a numeric PDF destination (`pdf_dest` whatsit) and returns it
-- together with its destination number, suitable for use in PDF links
-- or outline entries.
---@return Node dest
---@return integer destnum
function M.mknumdest()
    destcounter = destcounter + 1
    local d = node.new("whatsit", "pdf_dest") --[[@as PdfDestWhatsitNode]]
    d.named_id = 0
    d.dest_id = destcounter
    d.dest_type = 0
    return d, destcounter
end

-- Creates a named PDF destination (`pdf_dest` whatsit) using `name` as the
-- string identifier (encoded as a UTF-16 PDF string).
---@param name string
---@return Node dest
function M.mkstringdest(name)
    local d = node.new("whatsit", "pdf_dest") --[[@as PdfDestWhatsitNode]]
    d.named_id = 1
    d.dest_id = publisher.utf8_to_utf16_string_pdf(name)
    d.dest_type = 0
    return d
end

-- Builds a hlist holding the destination + bookmark whatsit nodes that
-- get picked up at shipout to emit the PDF outline entry.
-- The hlist is sometimes reused (e.g. with `Td/sethead="yes"`); see
-- `tabular#remove_bookmark_nodes()` for the matching cleanup.
---@param level integer? Outline depth (1 = top-level).
---@param open_p boolean Whether the bookmark starts open.
---@param title string? Bookmark title.
---@param data table Data XML context for `setup_page`.
---@return Node hbox
function M.mkbookmarknodes(level, open_p, title, data)
    publisher.page_helpers.setup_page(nil, "mkbookmarknodes", data)
    local openclosed
    if open_p then
        openclosed = 1
    else
        openclosed = 2
    end
    level = level or 1
    title = title or "no title for bookmark given"

    local n, counter = M.mknumdest()
    local udw = node.new("whatsit", "user_defined")
    udw.user_id = publisher.user_defined_bookmark
    udw.type = 115 -- a string
    udw.value = string.format("%d+%d+%d+%s", level, openclosed, counter, title)
    n.next = udw
    udw.prev = n
    -- This hlist sometimes gets reused, for example with Td/sethead=yes.
    -- See tabular#remove_bookmark_nodes() for the matching cleanup.
    return node.hpack(n)
end

file_end("structure_tree.lua")

return M
