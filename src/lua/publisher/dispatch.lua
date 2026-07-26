-- Layout dispatch and pattern matching.
--
--  dispatch.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("dispatch.lua")

local publisher = require("publisher")
local commandattributes = require("publisher.commandattributes")

---@class dispatch_module
local M = {}

-- Warns about attributes that are not defined for the command in
-- commands.xml. Runs once per layout element: the element table is reused
-- on every execution, so the result is remembered in the table itself.
-- Attributes from other namespaces (xml:lang, user annotations, ...) are
-- listed in .__foreign_attributes and are skipped.
---@param layoutxml table Layout XML element.
---@param eltname string Command name (English).
local function check_attributes(layoutxml, eltname)
    if layoutxml[".__attributes_checked"] then
        return
    end
    layoutxml[".__attributes_checked"] = true
    local allowed = commandattributes[eltname]
    local attributes = layoutxml[".__attributes"]
    if not allowed or not attributes then
        return
    end
    local foreign = layoutxml[".__foreign_attributes"]
    for attname in pairs(attributes) do
        if not allowed[attname] and not (foreign and foreign[attname]) then
            main.log("warn", string.format("Unknown attribute %q for element %q", attname, eltname))
        end
    end
end

-- The dispatch table maps every element in the layout xml to a command in the `commands.lua` file.
---@type table<string, fun(layoutxml: table, dataxml: table, opts?: table): any>
local dispatch_table = {
    A = commands.a,
    Action = commands.action,
    AddToList = commands.add_to_list,
    AddSearchpath = commands.add_searchpath,
    AtPageCreation = commands.atpagecreation,
    AtPageShipout = commands.atpageshipout,
    Attribute = commands.attribute,
    AttachFile = commands.attachfile,
    B = commands.bold,
    Barcode = commands.barcode,
    Bookmark = commands.bookmark,
    Box = commands.box,
    Br = commands.br,
    Circle = commands.circle,
    ClearPage = commands.clearpage,
    Clip = commands.clip,
    Color = commands.color,
    Column = commands.column,
    Columns = commands.columns,
    Compatibility = commands.compatibility,
    ["Copy-of"] = commands.copy_of,
    DefineColor = commands.define_color,
    DefineColorprofile = commands.define_colorprofile,
    DefineFontfamily = commands.define_fontfamily,
    DefineFontalias = commands.define_fontalias,
    DefineGraphic = commands.define_graphic,
    DefineTextformat = commands.define_textformat,
    DefineMatter = commands.definematter,
    Element = commands.element,
    EmptyLine = commands.emptyline,
    Fontface = commands.fontface,
    ForAll = commands.forall,
    Frame = commands.frame,
    Function = commands.func,
    Grid = commands.grid,
    Group = commands.group,
    Groupcontents = commands.groupcontents,
    HTML = commands.html,
    HSpace = commands.hspace,
    Hyphenation = commands.hyphenation,
    I = commands.italic,
    Image = commands.image,
    Include = commands.include,
    Layout = commands.include,
    Initial = commands.initial,
    InsertPages = commands.insert_pages,
    Li = commands.li,
    LoadDataset = commands.load_dataset,
    LoadFontfile = commands.load_fontfile,
    Loop = commands.loop,
    Makeindex = commands.makeindex,
    Margin = commands.margin,
    Mark = commands.mark,
    Message = commands.message,
    NewPage = commands.new_page,
    NextFrame = commands.next_frame,
    NextRow = commands.next_row,
    NoBreak = commands.nobreak,
    Ol = commands.ol,
    Options = commands.options,
    Output = commands.output,
    Overlay = commands.overlay,
    Pageformat = commands.page_format,
    Pagetype = commands.pagetype,
    Paragraph = commands.paragraph,
    Param = commands.param,
    PDFOptions = commands.pdfoptions,
    PlaceObject = commands.place_object,
    Position = commands.position,
    PositioningArea = commands.positioning_area,
    PositioningFrame = commands.positioning_frame,
    ProcessNode = commands.process_node,
    ProcessRecord = commands.process_node,
    Record = commands.record,
    Rule = commands.rule,
    SaveDataset = commands.save_dataset,
    SavePages = commands.save_pages,
    Section = commands.section,
    Sequence = commands.sequence,
    SetGrid = commands.set_grid,
    SetVariable = commands.setvariable,
    SortSequence = commands.sort_sequence,
    Span = commands.span,
    StructureElement = commands.structureelement,
    Stylesheet = commands.stylesheet,
    Sub = commands.sub,
    Sup = commands.sup,
    Switch = commands.switch,
    Table = commands.table,
    TableNewPage = commands.talbenewpage,
    Tablefoot = commands.tablefoot,
    Tablehead = commands.tablehead,
    Tablerule = commands.tablerule,
    Td = commands.td,
    Textblock = commands.textblock,
    Text = commands.text,
    Tr = commands.tr,
    Trace = commands.trace,
    Transformation = commands.transformation,
    U = commands.underline,
    Ul = commands.ul,
    Until = commands.until_do,
    URL = commands.url,
    Value = commands.value,
    VSpace = commands.vspace,
    While = commands.while_do,
}

-- Compiles a match pattern string into a test function and priority.
-- Simple element names (no special chars) return `nil` to signal the fast
-- path so the caller can do a direct table lookup.
--
-- Supported patterns:
--
--     "foo"           -> fast path (nil)
--     "*"             -> matches any element, priority -0.5
--     "foo[pred]"     -> self::foo[pred], priority 0.5
--     "*[pred]"       -> self::*[pred], priority 0.5
--     "parent/child"  -> self::child[parent::parent], priority 0.5
--     "anc//desc"     -> self::desc[ancestor::anc], priority 0.5
---@param pattern string
---@return (fun(ctx: table, node: any): boolean)? matchfunc `nil` means use the fast path.
---@return number priority
---@return string? elementname Set only for the fast path.
function M.compile_match_pattern(pattern)
    -- Simple element name: no /, [, ], *
    if not string.find(pattern, "[/%[%]%*]") then
        return nil, 0, pattern
    end
    -- Wildcard: just "*"
    if pattern == "*" then
        return function(ctx, node)
            return publisher.xpath.is_element(node)
        end, -0.5, nil
    end
    local selftest = M.convert_pattern_to_selftest(pattern)
    return function(ctx, node)
        local testctx = publisher.xpath.context:new({
            xmldoc = ctx.xmldoc,
            sequence = { node },
            namespaces = ctx.namespaces or {},
            vars = ctx.vars or {},
        })
        local seq, evalerr = testctx:eval(selftest)
        if evalerr then
            main.log("error", "match pattern evaluation failed", "pattern", pattern, "error", evalerr)
            return false
        end
        return seq and #seq > 0
    end,
        0.5,
        nil
end

-- Converts a match pattern to a `self::` XPath expression.
--
--     "foo[pred]"    -> "self::foo[pred]"
--     "*[pred]"      -> "self::*[pred]"
--     "parent/child" -> "self::child[parent::parent]"
--     "anc//desc"    -> "self::desc[ancestor::anc]"
---@param pattern string
---@return string xpath
function M.convert_pattern_to_selftest(pattern)
    local ancestor, desc = string.match(pattern, "^([^/]+)//(.+)$")
    if ancestor and desc then
        local descname, descpred = string.match(desc, "^([^%[]+)(.*)")
        local ancname = string.match(ancestor, "^([^%[]+)")
        return "self::" .. descname .. "[ancestor::" .. ancname .. "]" .. descpred
    end
    local parent, child = string.match(pattern, "^([^/]+)/([^/]+)$")
    if parent and child then
        local childname, childpred = string.match(child, "^([^%[]+)(.*)")
        local parentname = string.match(parent, "^([^%[]+)")
        return "self::" .. childname .. "[parent::" .. parentname .. "]" .. childpred
    end
    local name, pred = string.match(pattern, "^([^%[]+)(.*)")
    if name then
        return "self::" .. name .. pred
    end
    return "self::" .. pattern
end

-- Finds the highest-priority pattern-based `<Record>` registered for `mode`
-- whose match function accepts `datanode`. Returns the layout XML body of
-- that record, or `nil` if no pattern matches.
---@param mode string Mode name (the `mode` attribute on `<Record>`).
---@param datanode any Current data XML node.
---@param ctx table XPath context (used by the match function).
---@return table? layoutxml
function M.find_matching_pattern(mode, datanode, ctx)
    local patterns = publisher.data_dispatcher_patterns[mode]
    if not patterns then
        return nil
    end
    local best_match = nil
    local best_priority = -math.huge
    for _, entry in ipairs(patterns) do
        if entry.priority > best_priority then
            if entry.matchfunc(ctx, datanode) then
                best_match = entry.layoutxml
                best_priority = entry.priority
            end
        end
    end
    return best_match
end

-- Creates and registers a textformat that inherits from `base` (or from
-- `text` if `base` is missing) and overlays `options_arg`. An empty `name`
-- gets a random 10-character key so the result can still be referenced.
---@param name string
---@param base string|Textformat|nil Base textformat (name or instance).
---@param options_arg table? Per-call overrides merged on top of the base.
---@return Textformat
function M.new_textformat(name, base, options_arg)
    if name == "" then
        name = publisher.utilities.string_random(10)
    end
    local textformats = publisher.textformats
    local baseformat
    if type(base) == "table" then
        baseformat = base
    else
        baseformat = textformats[base] or textformats.text
    end
    options_arg = options_arg or {}
    local tf = {}
    for k, v in pairs(baseformat) do
        tf[k] = v
    end
    for k, v in pairs(options_arg) do
        tf[k] = v
    end
    tf.name = name
    textformats[name] = tf
    return tf
end

---@class DispatchEntry
---@field elementname string Layout element that produced the entry.
---@field contents any Whatever the corresponding command returned.

-- Walks the children of a layout XML element and executes the command
-- registered in `dispatch_table` for each known element. Wrapper elements
-- (`Copy-of`, `Switch`, `ForAll`, `Loop`, `Transformation`, `Frame`,
-- `Include`, `Layout`, `Clip`, `Section`) are flattened into the result.
-- For example:
--
--     {
--       [1] = {
--         ["elementname"] = "Paragraph"
--         ["contents"] = {
--           ["nodelist"] = "<node    nil <  58515 >    nil : glyph 1>"
--         },
--       },
--     }
---@param layoutxml table Layout XML element with children to walk.
---@param dataxml table Current data XML context.
---@param opts? table Forwarded to each command.
---@return DispatchEntry[]
function M.dispatch(layoutxml, dataxml, opts)
    local ret = {}
    local tmp
    if not layoutxml then
        assert(false, "No elements for dispatch, why?")
        return ret
    end

    local options = publisher.options
    local newxpath = publisher.newxpath
    for _, j in ipairs(layoutxml) do
        if type(j) == "table" then
            local eltname = j[".__local_name"]
            if dispatch_table[eltname] ~= nil then
                if options.verbosity > 0 then
                    if newxpath then
                        main.log("debug", "Call command", "name", eltname, "line", j[".__line"])
                    else
                        main.log("debug", "Call command", "name", eltname)
                    end
                end
                if newxpath then
                    publisher.current_layout_line = j[".__line"]
                    publisher.current_layout_file = j[".__file"]
                    check_attributes(j, eltname)
                    if
                        dataxml.sequence
                        and type(dataxml.sequence) == "table"
                        and dataxml.sequence[1]
                        and type(dataxml.sequence[1]) == "table"
                        and dataxml.sequence[1][".__line"]
                    then
                        publisher.current_data_line = dataxml.sequence[1][".__line"]
                    else
                        publisher.current_data_line = "(unknown)"
                    end
                end

                tmp = dispatch_table[eltname](j, dataxml, opts)
                if type(tmp) == "table" and tmp.raw == true then
                    for i = 1, #tmp do
                        ret[#ret + 1] = tmp[i]
                    end
                end
                if
                    eltname == "Copy-of"
                    or eltname == "Switch"
                    or eltname == "ForAll"
                    or eltname == "Loop"
                    or eltname == "Transformation"
                    or eltname == "Frame"
                    or eltname == "Include"
                    or eltname == "Layout"
                    or eltname == "Clip"
                    or eltname == "Section"
                then
                    if type(tmp) == "table" then
                        for i = 1, #tmp do
                            if tmp[i].contents then
                                ret[#ret + 1] = { elementname = tmp[i].elementname, contents = tmp[i].contents }
                            else
                                ret[#ret + 1] = { elementname = "elementstructure", contents = { tmp[i] } }
                            end
                        end
                    end
                else
                    ret[#ret + 1] = { elementname = eltname, contents = tmp }
                end
            else
                local prefix, localname = table.unpack(string.explode(j[".__name"], ":"))
                if localname == nil then
                    prefix = ""
                end
                if j[".__ns"][prefix] == "urn:speedata.de:2009/publisher/en" then
                    main.log(
                        "error",
                        string.format("Unknown element found in layoutfile: %q", j[".__local_name"] or "???")
                    )
                end
            end
        end
    end
    return ret
end

file_end("dispatch.lua")

return M
