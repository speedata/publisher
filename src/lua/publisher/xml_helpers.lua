--- XML loading and serialization helpers.
--
--  xml_helpers.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("xml_helpers.lua")

local M = {}

local luxor = do_luafile("luxor.lua")

--- Make a string XML safe
function M.xml_escape( str )
    if type(str) == "table" then
        str = table.concat(str)
    end
    if not str then return "" end
    local replace = {
        [">"] = "&gt;",
        ["<"] = "&lt;",
        ["\""] = "&quot;",
        ["&"] = "&amp;",
    }
    -- FIXME, str can be bool
    local ret = string.gsub(str,".",replace)
    return ret
end

--- See commands#save_dataset() for documentation on the data structure for `xml_element`.
function M.xml_to_string_newxpath( xml_element, level, namespace_written )
    local new_namespaces = publisher.copy_table_from_defaults(namespace_written or {})
    local str = ""
    if type(xml_element) == "string" then
        return M.xml_escape(xml_element)
    end
    if type(xml_element) ~= "table" then
        err("xml_to_string is not a table, but a %s %q",type(xml_element),tostring(xml_element))
        return "error in publisher run"
    end
    level = level or 0
    local eltname = xml_element[".__name"] or xml_element[".__local_name"] or ""
    if level == 0 and eltname == "" then eltname = "undefined" end
    if eltname ~= "" then
        str = str ..  "<" .. eltname
        if type(xml_element[".__attributes"]) == "table" then
            for k,v in pairs(xml_element[".__attributes"]) do
                str = str .. string.format(" %s=%q", k,M.xml_escape(v))
            end
        end
        if xml_element[".__ns"] then
            for k,v in pairs(xml_element[".__ns"]) do
                local key = k
                if new_namespaces[k] == nil then
                    if type(k) == "string" then
                        if k == "" then
                            k = "xmlns"
                        else
                            k = "xmlns:" .. k
                        end
                        str = str .. string.format(" %s=%q", k,M.xml_escape(v))
                    end
                end
                new_namespaces[key] = true
            end
        end
        str = str .. ">"
    end
    for i,v in ipairs(xml_element) do
        if type(v) == "string" and v == "" then
            -- ok, nothing to do
        else
            str = str .. M.xml_to_string_newxpath(v,level + 1,new_namespaces)
        end
    end
    if eltname ~= "" then
        str = str ..  "</" .. eltname .. ">"
    end
    return str
end

function M.xml_to_string( xml_element, level )
    local str = ""
    if type(xml_element) == "string" then
        return M.xml_escape(xml_element)
    end
    if type(xml_element) ~= "table" then
        err("xml_to_string is not a table, but a %s %q",type(xml_element),tostring(xml_element))
        return "error in publisher run"
    end
    level = level or 0
    local eltname = xml_element[".__name"] or xml_element[".__local_name"] or ""
    if level == 0 and eltname == "" then eltname = "undefined" end
    if eltname ~= "" then
        str = str ..  "<" .. eltname
        for k,v in pairs(xml_element) do
            if type(k) == "string" and not k:match("^%.") then
                str = str .. string.format(" %s=%q", k,M.xml_escape(v))
            end
        end
        if xml_element[".__ns"] then
            for k,v in pairs(xml_element[".__ns"]) do
                if type(k) == "string" then
                    if k == "" then
                        k = "xmlns"
                    else
                        k = "xmlns:" .. k
                    end
                    str = str .. string.format(" %s=%q", k,M.xml_escape(v))
                end
            end
        end
        str = str .. ">"
    end
    for i,v in ipairs(xml_element) do
        if type(v) == "string" and v == "" then
            -- ok, nothing to do
        else
            str = str .. M.xml_to_string(v,level + 1)
        end
    end
    if eltname ~= "" then
        str = str ..  "</" .. eltname .. ">"
    end
    return str
end

function M.xml_stringvalue( self )
    if type(self) == "string" then return self end
    local ret = {}
    for i=1,#self do
        local val = self[i]
        if type(val) == "table" then
            ret[#ret + 1] = M.xml_stringvalue(val)
        else
            ret[#ret + 1] = tostring(val)
        end
    end
    return table.concat(ret)
end

M.xml_stringvalue_mt = {
    __tostring = M.xml_stringvalue
}

-- Adds index metatable for namespace lookup to layout xml
function M.fixup_xmlfile(tbl, ignoreeol, parent)
    setmetatable(tbl, M.xml_stringvalue_mt)
    if parent and tbl[".__ns"] then
        setmetatable(tbl[".__ns"], {__index = parent[".__ns"]})
    end
    for i = 1, #tbl do
        if type(tbl[i]) == "table" then
            M.fixup_xmlfile(tbl[i], ignoreeol, tbl)
        elseif ignoreeol and type(tbl[i]) == "string" then
            tbl[i] = string.gsub(tbl[i], "\n", " ")
        end
    end
end

--- Load an XML file from the hard drive. filename is without path but including extension,
--- filetype is a string representing the type of file read, such as "layout" or "data".
function M.load_xml(filename, filetype, parameter)
    if not filename or filename == "" then
        main.log("error","Load XML: no file name given")
        return
    end
    parameter = parameter or {}
    main.log("info", "Load XML", "type", filetype or "file", "filename", filename)
    if publisher.newxpath then
        local xmltable
        local ignoreeol_str = parameter.ignoreeol and "true" or nil
        xmltable = splib.load_xmlfile(filename, filetype or "file", ignoreeol_str)
        if not xmltable then
            return nil
        end
        if parameter.ignoreeol then
            xmltable.ignoreeol_done = true
        end
        return xmltable
    else
        if publisher.options.verbosity > 0 then
            log("Using old Lua based XML reader")
        end
        local path = kpse.find_file(filename)
        if not path then
            main.log("error","Can't find XML file. Abort","filename",filename or "?")
            return nil
        end
        if publisher.options.verbosity > 0 then
            M.calculate_md5sum(filename)
        end
        main.log("info","Load XML","type",filetype or "file","filename",path)
        local parsed_xml = luxor.parse_xml_file(path, parameter, kpse.find_file)
        return parsed_xml
    end
end

function M.calculate_md5sum(filename)
    local p = kpse.find_file(filename)
    if p then
        local f, msg = io.open(p)
        if not f then
            main.log("error", msg)
            return nil
        end
        local str = f:read("*a")
        local sum = md5.sumhexa(str)
        f:close()
        log("filename %q, md5sum: %s", filename, sum)
    end
end

-- Return the element name of the given element (elt)
function M.elementname(elt)
    if not elt then
        main.log("error","Could not get element name", publisher.lineinfo())
        return nil
    end
    return elt.elementname
end

--- Return the contents of an entry from the `dispatch()` function call.
function M.element_contents( elt )
    return elt.contents
end

file_end("xml_helpers.lua")

return M
