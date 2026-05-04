-- Node attribute and property helpers.
--
--  attributes.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("attributes.lua")

local publisher = require("publisher")

---@class attributes_module
local M = {}

---@alias ReadAttributeType
---| "string"
---| "rawstring"
---| "number"
---| "length"
---| "length_sp"
---| "height_sp"
---| "width_sp"
---| "boolean"
---| "booleanornumber"
---| "booleanorlength"
---| "xpath"
---| "xpathraw"

-- Reads an attribute from a layout XML element and converts it to the
-- requested type. Curly-brace expressions inside the attribute value
-- (`{...}`) are evaluated as XPath against `dataxml`, except for the
-- `xpath`, `xpathraw` and `rawstring` types where the raw attribute is used.
---@param layoutxml table Layout XML element holding the attribute.
---@param dataxml table Data XML context for XPath evaluation.
---@param attname string Attribute name to look up.
---@param typ ReadAttributeType
---@param default any Value used when the attribute is missing.
---@param context any? Optional context (unused by this implementation).
---@return any value Converted value, or `default` if absent, or `nil` on error.
function M.read_attribute(layoutxml, dataxml, attname, typ, default, context)
    local namespaces = layoutxml[".__ns"]
    local attr

    if publisher.newxpath then
        local attributes = layoutxml[".__attributes"]
        if not attributes then
            return default
        end
        if not attributes[attname] then
            return default
        end
        attr = attributes[attname]
    else
        if not layoutxml[attname] then
            return default
        end
        attr = layoutxml[attname]
    end

    local val, num, ret
    if typ ~= "xpath" and typ ~= "xpathraw" and typ ~= "rawstring" then
        val = string.gsub(attr, "{(.-)}", function(x)
            if publisher.newxpath then
                local copysequence = dataxml.sequence
                local seq, msg = dataxml:eval(x)
                if msg then
                    main.log("error", msg)
                    return nil
                end
                local txt
                txt, msg = publisher.xpath.string_value(seq)
                if msg then
                    main.log("error", msg)
                    return nil
                end
                dataxml.sequence = copysequence
                return txt
            else
                local ok, xp = publisher.xpath.parse_raw(dataxml, x, namespaces)
                if not ok then
                    main.log("error", xp)
                    return nil
                end
                return publisher.xpath.textvalue(xp[1])
            end
        end)
    else
        val = attr
    end

    if val == "nil" then
        val = nil
    end
    if typ == "xpath" then
        if publisher.newxpath then
            local seq, msg = dataxml:eval(val)
            if msg then
                main.log("error", msg)
                return nil
            end
            return publisher.xpath.string_value(seq)
        else
            return publisher.xpath.textvalue(publisher.xpath.parse(dataxml, val, namespaces))
        end
    elseif typ == "xpathraw" then
        if publisher.newxpath then
            local seq, msg = dataxml:eval(val)
            if msg then
                main.log("error", msg)
                return nil
            end
            return seq
        else
            local ok, tmp = publisher.xpath.parse_raw(dataxml, val, namespaces)
            if not ok then
                main.log("error", tmp)
                return nil
            else
                return tmp
            end
        end
    elseif typ == "string" or typ == "rawstring" then
        return tostring(val or default)
    elseif typ == "number" then
        return tonumber(val)
    elseif typ == "length" then
        return val
    elseif typ == "length_sp" then
        num = tonumber(val or default)
        if num == 0 then
            return 0
        end
        if num then
            ret = publisher.current_grid:width_sp(num)
        else
            ret = val
        end
        if not ret then
            return
        end
        return tex.sp(ret)
    elseif typ == "height_sp" then
        num = tonumber(val or default)
        if num then
            publisher.page_helpers.setup_page(nil, "read_attribute height_sp", dataxml)
            ret = publisher.current_page.grid.gridheight * num
        else
            ret = val
        end
        if not ret then
            return
        end
        return tex.sp(ret)
    elseif typ == "width_sp" then
        num = tonumber(val or default)
        if num then
            publisher.page_helpers.setup_page(nil, "read_attribute width_sp", dataxml)
            ret = publisher.current_page.grid:width_sp(num)
        else
            ret = val
        end
        if not ret then
            return
        end
        return tex.sp(ret)
    elseif typ == "boolean" then
        val = val or default
        if val == "yes" then
            return true
        elseif val == "no" then
            return false
        end
        return nil
    elseif typ == "booleanornumber" then
        val = val or default
        if val == "yes" then
            return true
        elseif val == "no" then
            return false
        else
            return tonumber(val)
        end
    elseif typ == "booleanorlength" then
        val = val or default
        if val == "yes" then
            return true
        elseif val == "no" then
            return false
        else
            return tex.sp(val)
        end
    else
        main.log("warn", string.format("read_attribute (2): unknown type: %s", type(val)))
    end
    return val
end

-- Collects all LuaTeX attributes attached to the head node into a table
-- keyed by attribute number. If `reuse_table` is given, it is cleared and
-- reused for the result.
---@param nodelist node?
---@param reuse_table table<integer, integer>?
---@return table<integer, integer> attributes
function M.get_attributes(nodelist, reuse_table)
    local attributes = reuse_table or {}
    if reuse_table then
        for k in pairs(reuse_table) do
            reuse_table[k] = nil
        end
    end
    local n = nodelist and nodelist.attr
    while n do
        local num = n.number
        if num then
            attributes[num] = n.value
        end
        n = n.next
    end
    return attributes
end

-- Reads a named attribute from a node. If the attribute is declared with an
-- enum-like value list in `publisher.attributes`, the integer value is
-- mapped back to the corresponding string.
---@param nodelist node?
---@param attribute_name string Key in `publisher.attribute_name_number`.
---@return integer|string|nil value `nil` if the attribute is unknown or unset.
function M.get_attribute(nodelist, attribute_name)
    if not nodelist then
        return nil
    end
    local att_number = publisher.attribute_name_number[attribute_name]
    if not att_number then
        return nil
    end
    local entry = publisher.attributes[attribute_name]
    local val = node.has_attribute(nodelist, att_number)
    if val == nil then
        return nil
    end
    if type(entry) == "table" then
        return entry[val]
    end
    return val
end

-- Writes a named attribute on a node. For enum-like attributes the string
-- value is converted to its integer index from `publisher.attributes`. A
-- `nil` final value unsets the attribute. The attribute name must be known
-- to `publisher.attribute_name_number`.
---@param nodelist node
---@param attribute_name string
---@param value integer|string|nil
---@return nil
function M.set_attribute(nodelist, attribute_name, value)
    local att_number = publisher.attribute_name_number[attribute_name]
    if not att_number then
        main.log("error", string.format("Internal error: attribute %s unknown", attribute_name or "?"))
        return
    end
    local entry = publisher.attributes[attribute_name]
    local att_value
    if type(entry) == "table" then
        for k, v in ipairs(entry) do
            if v == value then
                att_value = k
                break
            end
        end
    else
        att_value = value
    end
    if att_value == nil then
        node.unset_attribute(nodelist, att_number)
    else
        node.set_attribute(nodelist, att_number, att_value)
    end
end

-- Removes a named attribute from a node.
---@param nodelist node
---@param attribute_name string
---@return nil
function M.clear_attribute(nodelist, attribute_name)
    local att_number = publisher.attribute_name_number[attribute_name]
    if not att_number then
        main.log("error", string.format("Internal error: attribute %s unknown", attribute_name or "?"))
        return
    end
    node.unset_attribute(nodelist, att_number)
end

-- Applies many attributes to a node at once. Keys may be attribute names
-- or attribute numbers (numbers are translated via `attribute_number_name`).
---@param nodelist node
---@param att_tbl table<string|integer, integer|string>?
---@return nil
function M.set_attributes(nodelist, att_tbl)
    if att_tbl == nil then
        return
    end
    for k, v in pairs(att_tbl) do
        if k and v then
            local num = k
            if type(k) == "number" then
                k = publisher.attribute_number_name[k]
            end
            if not k then
                w("attribute name %d not found", num)
            end
            M.set_attribute(nodelist, k, v)
        end
    end
end

-- Sets an attribute on the list and recursively on every sublist of any
-- hlist/vlist nodes encountered.
---@param nodelist node
---@param attribute string Attribute name.
---@param value integer|string|nil
---@return nil
function M.set_attribute_recurse(nodelist, attribute, value)
    while nodelist do
        if nodelist.id == publisher.vlist_node or nodelist.id == publisher.hlist_node then
            M.set_attribute_recurse(nodelist.list, attribute, value)
        else
            M.set_attribute(nodelist, attribute, value)
        end
        nodelist = nodelist.next
    end
end

-- Sets a value in the node's property table, creating the table on demand.
---@param n node
---@param prop string Property key.
---@param value any
---@return nil
function M.setprop(n, prop, value)
    local props = node.getproperty(n)
    if not props then
        props = {}
        node.setproperty(n, props)
    end
    props[prop] = value
end

-- Reads a value from the node's property table.
---@param n node
---@param prop string
---@return any value `nil` if no property table exists or the key is absent.
function M.getprop(n, prop)
    local props = node.getproperty(n)
    if not props then
        return nil
    end
    if type(props) == "table" then
        return props[prop]
    end
    return nil
end

-- Removes a key from the node's property table and returns the previous value.
---@param n node
---@param prop string
---@return any previous_value
function M.clearprop(n, prop)
    local props = node.getproperty(n)
    if not props then
        return nil
    end
    if type(props) == "table" then
        local ret = props[prop]
        props[prop] = nil
        return ret
    end
    return nil
end

file_end("attributes.lua")

return M
