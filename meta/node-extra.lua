---@meta
-- Additional fields for the base `Node` class. The TeXLuaCATS LuaTeX library
-- declares these only on the subtype classes (ListNode, GlueNode, GlyphNode, …),
-- but the publisher code handles nodes generically, so the fields are widened
-- onto the base class here. lua-language-server merges duplicate @class
-- declarations. This file is annotation-only and never loaded at runtime.

-- The TeXLuaCATS library declares font.nextid without its optional
-- parameter: with true, the id is only reserved, not yet assigned.
---@param reserve? boolean
---@return integer id
function font.nextid(reserve) end

-- The TeXLuaCATS library declares tex.shipout without its box number
-- parameter and tex.saveboxresource with all parameters required, although
-- only the box is mandatory. Worth a PR upstream.
---@param n integer Box register number.
---@return nil
function tex.shipout(n) end

---@param n Node|integer
---@param attributes? string
---@param resources? string
---@param immediate? boolean
---@param type? integer
---@param margin? integer
---@return integer index
function tex.saveboxresource(n, attributes, resources, immediate, type, margin) end

-- The TeXLuaCATS library declares node.direct.getprev as returning Node
-- instead of a direct node index, and setnext/setprev without the
-- possibility to unlink by passing nil. Worth a PR upstream.
---@param d integer
---@return integer|nil prev
function node.direct.getprev(d) end

---@param d integer
---@param next? integer
function node.direct.setnext(d, next) end

---@param d integer
---@param prev? integer
function node.direct.setprev(d, prev) end

-- The TeXLuaCATS library declares setlink with a single parameter, but the
-- LuaTeX API takes a list of nodes to be chained. Worth a PR upstream.
---@param d integer
---@param ... integer
---@return integer head
function node.direct.setlink(d, ...) end

---@param n Node
---@param ... Node
---@return Node head
function node.setlink(n, ...) end

-- The TeXLuaCATS library declares node.insert_before/insert_after with all
-- parameters required, but the LuaTeX manual states "If head is initially
-- nil, it will become new", and a nil current is accepted as well (new
-- becomes the head/tail). Worth a PR upstream.
---@param head Node?
---@param current Node?
---@param new Node
---@return Node head
---@return Node new
function node.insert_before(head, current, new) end

---@param head Node?
---@param current Node?
---@param new Node
---@return Node head
---@return Node new
function node.insert_after(head, current, new) end

-- The TeXLuaCATS library declares the six-argument overload of
-- node.dimensions with direct-access integers for the node arguments,
-- but the node API variant takes nodes (the direct variant lives in
-- node.direct.dimensions). glue_set is a float factor, not an integer.
-- Worth a PR upstream.
---@param glue_set number
---@param glue_sign integer
---@param glue_order integer
---@param n Node
---@param t Node Terminating node.
---@param dir? DirectionSpecifier
---@return integer width
---@return integer height
---@return integer depth
function node.dimensions(glue_set, glue_sign, glue_order, n, t, dir) end

---@class Node
---@field width number
---@field height number
---@field depth number
---@field shift number
---@field list Node|nil
---@field glue_set number
---@field glue_sign integer
---@field glue_order integer
---@field stretch number
---@field stretch_order integer
---@field shrink number
---@field shrink_order integer
---@field penalty integer
---@field kern number
---@field char integer
---@field font integer
---@field lang integer
---@field uchyph integer
---@field left integer
---@field right integer
---@field xoffset number
---@field yoffset number
---@field dir string
---@field mode any
---@field data any
---@field value any
---@field type any
---@field user_id integer
---@field action any
---@field action_type integer
---@field objnum integer
---@field command any
---@field stack integer
---@field leader Node|nil
---@field pre Node|nil
---@field post Node|nil
---@field replace Node|nil
---@field spec Node|nil Legacy glue spec (only when `node.has_field(n, "spec")`).
