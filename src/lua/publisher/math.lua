-- Mathematical typesetting via OpenType MATH fonts.
--
-- Pipeline: MathML XML tree -> LuaTeX math noad list -> mlist_to_hlist -> hlist.
-- The hlist that comes out of mlist_to_hlist is an ordinary node list that the
-- paragraph builder (par.lua) can consume like glyphs and boxes.
--
-- The walker covers a MathML subset (mrow, mi, mn, mo, mtext, mfrac, msqrt,
-- mroot, msup, msub, msubsup, munder, mover, munderover, mspace, mstyle).
-- The OpenType MATH table parser handles MathConstants, italic corrections,
-- top-accent attachment and MathVariants (stretchy glyphs); mtable and most
-- mathvariant values are not implemented yet.
--
--  math.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("math.lua")

local publisher = require("publisher")

---@class math_module
local M = {}

-- Math family slots. LuaTeX exposes 256 math families per style; we reserve
-- the lowest three for the speedata math font in text / script / scriptscript
-- size. Set by `M.set_math_font`.
M.FAM_MAIN = 0

-- Track whether a math font has been registered. Without it `mlist_to_hlist`
-- runs with all MathConstants at 0 and produces unusable output.
M.font_ready = false

-- Name of the DefineFontfamily that was registered as the math font, for
-- the warning when a layout asks for a second one.
---@type string?
M.fontfamily_name = nil

-- Font id of the text-size math font, set by `M.set_math_font`. Used for
-- em-based lengths in the MathML input.
---@type integer?
M.fontid_text = nil

----------------------------------------------------------------------------
-- OpenType MATH table parser
----------------------------------------------------------------------------
--
-- We read the raw MATH bytes via luaharfbuzz's `face:get_table()` instead of
-- going through the FontForge fontloader. The format is documented in the
-- OpenType spec, section "MATH — The mathematical typesetting table".
--
-- Scope of the parser: MathConstants (all 57 fields), italic corrections and
-- top-accent attachment (from MathGlyphInfo) and MathVariants (size variants
-- and glyph assemblies for stretchy glyphs, both directions). Per-glyph math
-- kerns and the extended-shape coverage are not handled yet.

local unpack_str = string.unpack

-- 51 fields, in order of appearance, each stored as a MathValueRecord
-- (int16 value + uint16 device-table offset; we discard the device offset).
-- They sit between the fixed `delimitedSubFormulaMinHeight` /
-- `displayOperatorMinHeight` pair and the trailing `radicalDegreeBottomRaisePercent`.
local MVR_CONSTANT_NAMES = {
    "MathLeading",
    "AxisHeight",
    "AccentBaseHeight",
    "FlattenedAccentBaseHeight",
    "SubscriptShiftDown",
    "SubscriptTopMax",
    "SubscriptBaselineDropMin",
    "SuperscriptShiftUp",
    "SuperscriptShiftUpCramped",
    "SuperscriptBottomMin",
    "SuperscriptBaselineDropMax",
    "SubSuperscriptGapMin",
    "SuperscriptBottomMaxWithSubscript",
    "SpaceAfterScript",
    "UpperLimitGapMin",
    "UpperLimitBaselineRiseMin",
    "LowerLimitGapMin",
    "LowerLimitBaselineDropMin",
    "StackTopShiftUp",
    "StackTopDisplayStyleShiftUp",
    "StackBottomShiftDown",
    "StackBottomDisplayStyleShiftDown",
    "StackGapMin",
    "StackDisplayStyleGapMin",
    "StretchStackTopShiftUp",
    "StretchStackBottomShiftDown",
    "StretchStackGapAboveMin",
    "StretchStackGapBelowMin",
    "FractionNumeratorShiftUp",
    "FractionNumeratorDisplayStyleShiftUp",
    "FractionDenominatorShiftDown",
    "FractionDenominatorDisplayStyleShiftDown",
    "FractionNumeratorGapMin",
    -- The OpenType spec abbreviates the next constant to
    -- fractionNumDisplayStyleGapMin, but LuaTeX looks up the written-out
    -- name in MathConstants (texmath.h); same for the denominator below.
    "FractionNumeratorDisplayStyleGapMin",
    "FractionRuleThickness",
    "FractionDenominatorGapMin",
    "FractionDenominatorDisplayStyleGapMin",
    "SkewedFractionHorizontalGap",
    "SkewedFractionVerticalGap",
    "OverbarVerticalGap",
    "OverbarRuleThickness",
    "OverbarExtraAscender",
    "UnderbarVerticalGap",
    "UnderbarRuleThickness",
    "UnderbarExtraDescender",
    "RadicalVerticalGap",
    "RadicalDisplayStyleVerticalGap",
    "RadicalRuleThickness",
    "RadicalExtraAscender",
    "RadicalKernBeforeDegree",
    "RadicalKernAfterDegree",
}

-- Parses a Coverage table (formats 1 and 2). Returns the gid list in
-- coverage-index order (i.e. position [i] is the gid whose entry sits at
-- index i in the corresponding parallel array).
local function parse_coverage(data, offset)
    -- offset is 0-based from start of `data`; string.unpack is 1-based.
    local pos = offset + 1
    if pos < 1 or pos + 3 > #data then
        return {}
    end
    local fmt = unpack_str(">I2", data, pos)
    local count = unpack_str(">I2", data, pos + 2)
    local gids = {}
    if fmt == 1 then
        for i = 0, count - 1 do
            gids[i + 1] = unpack_str(">I2", data, pos + 4 + i * 2)
        end
    elseif fmt == 2 then
        for i = 0, count - 1 do
            local rec_pos = pos + 4 + i * 6
            local start_gid = unpack_str(">I2", data, rec_pos)
            local end_gid = unpack_str(">I2", data, rec_pos + 2)
            local start_idx = unpack_str(">I2", data, rec_pos + 4)
            for g = start_gid, end_gid do
                local coverage_index = start_idx + (g - start_gid)
                gids[coverage_index + 1] = g
            end
        end
    end
    return gids
end

-- Reads the int16 value of a MathValueRecord at `pos` (1-based). The
-- accompanying 2-byte device-table offset is discarded.
local function read_mvr(data, pos)
    return unpack_str(">i2", data, pos)
end

-- Parses a per-glyph MathValueRecord list (a Coverage offset, a count and
-- a parallel array of MathValueRecords), the layout shared by
-- MathItalicsCorrectionInfo and MathTopAccentAttachment.
---@param data string Raw MATH table bytes.
---@param base integer 0-based offset of the subtable within `data`.
---@return table values `{ [gid] = value }` in design units.
local function parse_glyph_values(data, base)
    local coverage_rel = unpack_str(">I2", data, base + 1)
    local count = unpack_str(">I2", data, base + 3)
    local gids = parse_coverage(data, base + coverage_rel)
    local values = {}
    for i = 1, count do
        local gid = gids[i]
        if gid then
            values[gid] = read_mvr(data, base + 5 + (i - 1) * 4)
        end
    end
    return values
end

-- Parses a GlyphAssembly subtable: the recipe for building an arbitrarily
-- large glyph from parts (e.g. a tall parenthesis from top, extender and
-- bottom pieces).
---@param data string Raw MATH table bytes.
---@param base integer 0-based offset of the GlyphAssembly within `data`.
---@return table assembly `{ italic = du, parts = { { glyph = gid, start = du, ["end"] = du, advance = du, extender = 0|1 }, ... } }`
local function parse_glyph_assembly(data, base)
    local italic = read_mvr(data, base + 1)
    local part_count = unpack_str(">I2", data, base + 5)
    local parts = {}
    for i = 1, part_count do
        local rec = base + 7 + (i - 1) * 10
        local gid, start_len, end_len, advance, flags = unpack_str(">I2I2I2I2I2", data, rec)
        parts[i] = {
            glyph = gid,
            start = start_len,
            ["end"] = end_len,
            advance = advance,
            extender = (flags & 1 == 1) and 1 or 0,
        }
    end
    return { italic = italic, parts = parts }
end

-- Parses a MathGlyphConstruction subtable: the list of pre-drawn size
-- variants of a glyph (smallest first) and, optionally, its assembly.
---@param data string Raw MATH table bytes.
---@param base integer 0-based offset of the MathGlyphConstruction within `data`.
---@return table construction `{ variants = { { glyph = gid, advance = du }, ... }, assembly = table? }`
local function parse_glyph_construction(data, base)
    local assembly_rel = unpack_str(">I2", data, base + 1)
    local variant_count = unpack_str(">I2", data, base + 3)
    local variants = {}
    for i = 1, variant_count do
        local gid, advance = unpack_str(">I2I2", data, base + 5 + (i - 1) * 4)
        variants[i] = { glyph = gid, advance = advance }
    end
    local assembly
    if assembly_rel > 0 then
        assembly = parse_glyph_assembly(data, base + assembly_rel)
    end
    return { variants = variants, assembly = assembly }
end

-- Parses one direction of the MathVariants table: a Coverage table plus a
-- parallel array of MathGlyphConstruction offsets.
---@param data string Raw MATH table bytes.
---@param mv_base integer 0-based offset of the MathVariants table.
---@param coverage_rel integer Coverage offset relative to `mv_base` (0 = none).
---@param count integer Number of construction offsets.
---@param offsets_pos integer 1-based position of the first construction offset.
---@return table constructions `{ [gid] = construction }`
local function parse_variant_direction(data, mv_base, coverage_rel, count, offsets_pos)
    local constructions = {}
    if coverage_rel == 0 or count == 0 then
        return constructions
    end
    local gids = parse_coverage(data, mv_base + coverage_rel)
    for i = 1, count do
        local gid = gids[i]
        local construction_rel = unpack_str(">I2", data, offsets_pos + (i - 1) * 2)
        if gid and construction_rel > 0 then
            constructions[gid] = parse_glyph_construction(data, mv_base + construction_rel)
        end
    end
    return constructions
end

-- Parses the raw bytes of an OpenType MATH table. Pure function — no
-- dependencies on `publisher` or `main.log`, so it can be exercised
-- standalone for testing.
---@param data string Raw MATH table bytes (as returned by harfbuzz).
---@return table? parsed `{ constants = { Name = { value, kind } | int }, italics = { [gid] = value }, top_accents = { [gid] = value }, variants = { min_connector_overlap = du, vert = { [gid] = construction }, horiz = { [gid] = construction } } }`, or nil on parse error / wrong version.
---@return string? errmsg Reason for parse failure when the first return is nil.
function M.parse_math_table(data)
    if not data or #data < 10 then
        return nil, "MATH table too short"
    end
    local version_major = unpack_str(">I2", data, 1)
    if version_major ~= 1 then
        return nil, string.format("unsupported MATH version %d", version_major)
    end
    local math_const_off = unpack_str(">I2", data, 5)
    local math_glyph_info_off = unpack_str(">I2", data, 7)
    local math_variants_off = unpack_str(">I2", data, 9)

    local parsed = {
        constants = {},
        italics = {},
        top_accents = {},
        variants = { min_connector_overlap = 0, vert = {}, horiz = {} },
    }

    -- MathConstants -----------------------------------------------------
    if math_const_off > 0 then
        local p = math_const_off + 1
        parsed.constants.ScriptPercentScaleDown = unpack_str(">i2", data, p)
        parsed.constants.ScriptScriptPercentScaleDown = unpack_str(">i2", data, p + 2)
        parsed.constants.DelimitedSubFormulaMinHeight = { value = unpack_str(">I2", data, p + 4), kind = "dim" }
        parsed.constants.DisplayOperatorMinHeight = { value = unpack_str(">I2", data, p + 6), kind = "dim" }
        local cursor = p + 8
        for _, name in ipairs(MVR_CONSTANT_NAMES) do
            parsed.constants[name] = { value = read_mvr(data, cursor), kind = "dim" }
            cursor = cursor + 4
        end
        parsed.constants.RadicalDegreeBottomRaisePercent = unpack_str(">i2", data, cursor)
    end

    -- MathGlyphInfo: italic corrections and top-accent attachment --------
    if math_glyph_info_off > 0 then
        local mgi_p = math_glyph_info_off + 1
        local italics_off = unpack_str(">I2", data, mgi_p)
        if italics_off > 0 then
            parsed.italics = parse_glyph_values(data, math_glyph_info_off + italics_off)
        end
        local top_accent_off = unpack_str(">I2", data, mgi_p + 2)
        if top_accent_off > 0 then
            parsed.top_accents = parse_glyph_values(data, math_glyph_info_off + top_accent_off)
        end
        -- TODO: extendedShapeCoverage, mathKernInfo.
    end

    -- MathVariants: size variants and assemblies for stretchy glyphs ------
    if math_variants_off > 0 then
        local mv_p = math_variants_off + 1
        local min_overlap, vert_cov, horiz_cov, vert_count, horiz_count = unpack_str(">I2I2I2I2I2", data, mv_p)
        parsed.variants.min_connector_overlap = min_overlap
        local vert_offsets_pos = mv_p + 10
        local horiz_offsets_pos = vert_offsets_pos + vert_count * 2
        parsed.variants.vert = parse_variant_direction(data, math_variants_off, vert_cov, vert_count, vert_offsets_pos)
        parsed.variants.horiz =
            parse_variant_direction(data, math_variants_off, horiz_cov, horiz_count, horiz_offsets_pos)
    end

    return parsed
end

----------------------------------------------------------------------------
-- Font hookup
----------------------------------------------------------------------------

-- Multiplies a design-unit value by the font's `mag` factor and rounds to
-- the nearest scaled point.
local function du_to_sp(value, mag)
    return math.floor(value * mag + 0.5)
end

-- Converts a parsed glyph assembly to the LuaTeX `vert_variants` /
-- `horiz_variants` record list (glyphs as character codes, lengths in sp).
-- Parts whose glyph has no character code in the font are dropped.
---@param f table Font definition.
---@param assembly table Parsed GlyphAssembly.
---@param mag number `size / units_per_em`.
---@return table[] parts
local function assembly_to_variants(f, assembly, mag)
    local parts = {}
    for _, part in ipairs(assembly.parts) do
        local uni = f.backmap[part.glyph]
        if uni and f.characters[uni] then
            parts[#parts + 1] = {
                glyph = uni,
                extender = part.extender,
                start = du_to_sp(part.start, mag),
                ["end"] = du_to_sp(part["end"], mag),
                advance = du_to_sp(part.advance, mag),
            }
        end
    end
    return parts
end

-- Writes one direction of the MathVariants data into `f.characters`: the
-- size variants become a `next` chain starting at the base glyph, the
-- assembly is attached to the last glyph of the chain under `fieldname`.
-- A `next` link that is already set (by the other direction) is kept.
---@param f table Font definition with `characters` and `backmap`.
---@param constructions table `{ [gid] = construction }` from the parser.
---@param fieldname "vert_variants"|"horiz_variants"
---@param mag number `size / units_per_em`.
local function attach_variants(f, constructions, fieldname, mag)
    local backmap = f.backmap
    for base_gid, construction in pairs(constructions) do
        local base_uni = backmap[base_gid]
        local last = base_uni and f.characters[base_uni]
        if last then
            local seen = { [base_gid] = true }
            for _, variant in ipairs(construction.variants) do
                local gid = variant.glyph
                local uni = backmap[gid]
                local ch = uni and f.characters[uni]
                if ch and not seen[gid] then
                    seen[gid] = true
                    if not last.next then
                        last.next = uni
                    end
                    last = ch
                end
            end
            if construction.assembly then
                local parts = assembly_to_variants(f, construction.assembly, mag)
                if #parts > 0 then
                    last[fieldname] = parts
                end
            end
        end
    end
end

-- Attempts to attach OpenType MATH metrics to a harfbuzz-loaded font
-- definition. No-op when the face has no MATH table or harfbuzz is
-- unavailable. Called once per font from `define_font_hb`.
---@param f table Font definition (the same table later passed to font.define).
---@param face HbFace harfbuzz Face object.
---@param mag number `size / units_per_em`.
---@return boolean attached True if a MATH table was found, parsed and attached.
function M.attach_to_font(f, face, mag)
    if not f or not face or not publisher.harfbuzz then
        return false
    end
    if type(face.get_table) ~= "function" then
        return false
    end
    local tag = publisher.harfbuzz.Tag.new("MATH")
    local ok, blob = pcall(face.get_table, face, tag)
    if not ok or not blob then
        return false
    end
    local length = blob:get_length()
    if length == 0 then
        return false
    end
    local data = blob:get_data()

    local parse_ok, parsed, errmsg = pcall(M.parse_math_table, data)
    if not parse_ok or not parsed then
        main.log(
            "warn",
            "Math: failed to parse MATH table",
            "font",
            f.name or f.fullname or "?",
            "error",
            parse_ok and tostring(errmsg) or tostring(parsed)
        )
        return false
    end

    -- Populate `f.MathConstants`. Dimension values are scaled to sp;
    -- percent values pass through as plain integers. LuaTeX picks the
    -- table up at `font.define` time.
    local mc = {}
    for name, entry in pairs(parsed.constants) do
        if type(entry) == "table" then
            mc[name] = du_to_sp(entry.value, mag)
        else
            mc[name] = entry
        end
    end
    -- LuaTeX pseudo-constants without an OpenType counterpart. LuaTeX
    -- reports "Math error: parameter \Umathfraction_del_size... is not set"
    -- when they are missing. The factors are the classic plain-TeX values
    -- for delim2 (1.01 em) and delim1 (2.39 em), as used by luaotfload.
    mc.FractionDelimiterSize = math.floor(1.01 * f.size + 0.5)
    mc.FractionDelimiterDisplayStyleSize = math.floor(2.39 * f.size + 0.5)
    -- Minimum overlap of adjacent parts in a glyph assembly. Lives in the
    -- MathVariants header in OpenType, but LuaTeX reads it from MathConstants.
    mc.MinConnectorOverlap = du_to_sp(parsed.variants.min_connector_overlap, mag)
    f.MathConstants = mc

    -- The font loader takes the depth from the glyph bounding box, so a glyph
    -- that floats above the baseline (a combining accent) gets a negative
    -- depth and a glyph below the baseline a negative height. TeX assumes
    -- both are non-negative; a negative accent depth pulls the accent down
    -- into its base.
    for _, ch in pairs(f.characters) do
        if ch.depth and ch.depth < 0 then
            ch.depth = 0
        end
        if ch.height and ch.height < 0 then
            ch.height = 0
        end
    end

    -- Per-glyph italic correction and top-accent attachment point (the
    -- horizontal position accents are centered on). Lookup via backmap
    -- (gid → primary unicode). Glyphs without a unicode mapping are
    -- skipped, they cannot be addressed from a `math_char` noad anyway.
    local backmap = f.backmap
    if backmap then
        for gid, value in pairs(parsed.italics) do
            local uni = backmap[gid]
            local ch = uni and f.characters[uni]
            if ch then
                ch.italic = du_to_sp(value, mag)
            end
        end
        for gid, value in pairs(parsed.top_accents) do
            local uni = backmap[gid]
            local ch = uni and f.characters[uni]
            if ch then
                ch.top_accent = du_to_sp(value, mag)
            end
        end
    end

    -- Stretchy glyphs. LuaTeX walks the `next` chain of a character until
    -- it finds a variant that is large enough; a character with
    -- `vert_variants` / `horiz_variants` is built from parts instead. The
    -- assembly therefore goes on the last link of the chain (a glyph with
    -- an assembly would be assembled even when a variant would do).
    if backmap then
        attach_variants(f, parsed.variants.vert, "vert_variants", mag)
        attach_variants(f, parsed.variants.horiz, "horiz_variants", mag)
    end

    main.log(
        "info",
        "Math: attached MATH metrics",
        "font",
        f.name or "?",
        "italics",
        (next(parsed.italics) and "yes" or "no")
    )
    return true
end

----------------------------------------------------------------------------
-- Math-family binding
----------------------------------------------------------------------------

-- Registers `fontid_*` as the math font for `family` (default `M.FAM_MAIN`)
-- in all three style sizes. Call this once per math family after the math
-- fonts have been loaded via LoadFontfile. Callers typically load the same
-- file three times at three sizes (text / script ≈ 70% / scriptscript ≈ 50%).
---@param family integer? Math family index (0..255). Defaults to `M.FAM_MAIN`.
---@param fontid_text integer Font id for text size.
---@param fontid_script integer? Font id for script size. Falls back to text.
---@param fontid_scriptscript integer? Font id for scriptscript size. Falls back to script.
function M.set_math_font(family, fontid_text, fontid_script, fontid_scriptscript)
    family = family or M.FAM_MAIN
    M.fontid_text = fontid_text
    fontid_script = fontid_script or fontid_text
    fontid_scriptscript = fontid_scriptscript or fontid_script
    -- LuaTeX exposes no direct Lua setter for `\textfont`. We invoke the
    -- TeX primitives through `tex.runtoks`. `\setfontid <id>` makes the
    -- font with the given id the currently-active font; the keyword `\font`
    -- then refers to it and can be assigned to a math-family slot.
    -- Assigning a font to `\textfont` is what causes LuaTeX to read the
    -- `MathConstants` table off that font, so this binding step is what
    -- actually activates the math metrics.
    tex.runtoks(function()
        tex.sprint(string.format("\\setfontid%d \\global\\textfont%d=\\font ", fontid_text, family))
        tex.sprint(string.format("\\setfontid%d \\global\\scriptfont%d=\\font ", fontid_script, family))
        tex.sprint(string.format("\\setfontid%d \\global\\scriptscriptfont%d=\\font ", fontid_scriptscript, family))
        -- The publisher runs LuaTeX in ini mode, so the mu-glue parameters
        -- that control inter-atom spacing are all zero. Use the plain-TeX
        -- values, otherwise `a+b=c` comes out without any spacing.
        tex.sprint("\\global\\thinmuskip=3mu ")
        tex.sprint("\\global\\medmuskip=4mu plus 2mu minus 4mu ")
        tex.sprint("\\global\\thickmuskip=5mu plus 5mu ")
        -- Line breaks inside inline formulas: TeX prefers a break after a
        -- relation (=) over one after a binary operator (+). In ini mode
        -- both penalties are 0, these are the plain-TeX values.
        tex.sprint("\\global\\relpenalty=500 \\global\\binoppenalty=700 ")
    end)
    M.font_ready = true
end

----------------------------------------------------------------------------
-- Noad constructors
----------------------------------------------------------------------------

-- Simple-noad subtypes that show up in MathML. The LuaTeX manual (section
-- 8.3.6) lists noad subtypes as integers: 0 = ord, 1 = opdisplaylimits,
-- 2 = oplimits, 3 = opnolimits, 4 = bin, 5 = rel, 6 = open, 7 = close,
-- 8 = punct, 9 = inner.
local NOAD_ORD = 0
local NOAD_OP = 1 -- opdisplaylimits: limits in display style, scripts in text style
local NOAD_OPLIMITS = 2 -- limits always above and below
local NOAD_OPNOLIMITS = 3 -- limits always as scripts (integrals)
local NOAD_BIN = 4
local NOAD_REL = 5
local NOAD_OPEN = 6
local NOAD_CLOSE = 7
local NOAD_PUNCT = 8
local NOAD_INNER = 9

-- Builds a `math_char` subnode (the leaf inside a noad's `nucleus`).
---@param fam integer Math family.
---@param char integer Unicode code point.
---@return MathCharNode
local function math_char(fam, char)
    local n = node.new("math_char") --[[@as MathCharNode]]
    n.fam = fam
    n.char = char
    return n
end

-- Wraps an existing math node list as a `sub_mlist` subnode. Used so an
-- inner mlist (e.g. a fraction numerator) can appear as the nucleus of an
-- outer noad. A nil head yields an empty sub-mlist.
---@param head Node? Head of an mlist (a chain of noads). May be nil.
---@return SubMlistNode
local function sub_mlist(head)
    local n = node.new("sub_mlist") --[[@as SubMlistNode]]
    if head then
        n.head = head
    end
    return n
end

-- Builds a `simple_noad` of the given subtype with a single `math_char`
-- nucleus.
---@param subtype integer Noad subtype (see NOAD_* above).
---@param fam integer Math family.
---@param char integer Unicode code point.
---@return NoadNode
function M.mchar(subtype, fam, char)
    local n = node.new("noad", subtype) --[[@as NoadNode]]
    n.nucleus = math_char(fam, char)
    return n
end

-- Wraps an existing mlist as the nucleus of a fresh ord-noad. Used by mrow
-- when a single child needs to act as an atom.
---@param head Node?
---@return NoadNode
function M.ord_from_mlist(head)
    local n = node.new("noad", NOAD_ORD) --[[@as NoadNode]]
    n.nucleus = sub_mlist(head)
    return n
end

-- Attaches `sup` / `sub` mlists to an existing noad. Both are optional.
---@param noad NoadNode Target noad (its `sup` / `sub` fields are overwritten).
---@param sup Node? Math-list head for the superscript.
---@param sub Node? Math-list head for the subscript.
---@return NoadNode noad The same noad, for chaining.
function M.attach_scripts(noad, sup, sub)
    if sup then
        noad.sup = sub_mlist(sup)
    end
    if sub then
        noad.sub = sub_mlist(sub)
    end
    return noad
end

-- TeX's `default_code`: a fraction whose rule thickness has this value
-- gets the thickness from the font (MathConstants.FractionRuleThickness).
-- A thickness of 0 means "no rule" (that is what \atop produces), and 0 is
-- also what node.new("fraction") initializes the field to.
local FRACTION_DEFAULT_THICKNESS = 0x40000000

-- Builds a `fraction_noad`. `thickness` defaults to the font's rule
-- thickness; pass 0 for a rule-less fraction (atop/binomial).
---@param num Node? Numerator mlist head.
---@param den Node? Denominator mlist head.
---@param thickness integer? Fraction-rule thickness in scaled points.
---@return FractionNode
function M.frac(num, den, thickness)
    local n = node.new("fraction") --[[@as FractionNode]]
    n.num = sub_mlist(num) --[[@as KernNode]]
    n.denom = sub_mlist(den) --[[@as KernNode]]
    -- The Lua field is called `width`, but it maps to the internal
    -- `thickness` field of the fraction noad (see lnodelib.c); the noad
    -- has no Lua field named thickness.
    n.width = thickness or FRACTION_DEFAULT_THICKNESS
    return n
end

-- Builds a `radical_noad` (e.g. msqrt).
---@param fam integer Math family (for the radical sign).
---@param body Node? Radicand mlist head.
---@param degree Node? Degree mlist head (for `mroot`, unused for `msqrt`).
---@return RadicalNode
function M.sqrt(fam, body, degree)
    -- radical subtypes: 0 = radical, 1 = uradical, 2 = uroot, 3..6 = various
    -- under/overdelimiter variants. msqrt maps to subtype 1 (uradical) — the
    -- Unicode-math style \Uradical without a fixed delimiter selection.
    local n = node.new("radical", 1) --[[@as RadicalNode]]
    n.nucleus = sub_mlist(body) --[[@as KernNode]]
    -- The radical sign itself is a delimiter subnode. LuaTeX grows it to
    -- match tall radicands via the `next` chain and `vert_variants` that
    -- `attach_to_font` sets from the font's MathVariants data.
    local delim = node.new("delim") --[[@as DelimNode]]
    delim.small_fam = fam
    delim.small_char = 0x221A -- '√'
    n.left = delim
    if degree then
        n.degree = sub_mlist(degree) --[[@as KernNode]]
    end
    return n
end

-- Fence noad subtypes (the side of the delimiter).
local FENCE_LEFT = 1
local FENCE_MIDDLE = 2
local FENCE_RIGHT = 3

-- Builds a `fence` noad, the counterpart of TeX's \left, \middle and
-- \right. LuaTeX grows the delimiter to the height of the enclosing
-- mlist. A fence noad created from Lua has class 0 (ord); TeX's primitives
-- leave the class unset and derive open / close from the side, so the
-- class is set explicitly here to get the same spacing.
---@param side integer FENCE_LEFT, FENCE_MIDDLE or FENCE_RIGHT.
---@param fam integer Math family.
---@param char integer Unicode code point of the delimiter.
---@return FenceNode
function M.fence(side, fam, char)
    local n = node.new("fence", side) --[[@as FenceNode]]
    local delim = node.new("delim") --[[@as DelimNode]]
    delim.small_fam = fam
    delim.small_char = char
    delim.large_fam = fam
    delim.large_char = char
    n.delim = delim
    if side == FENCE_LEFT then
        n.class = NOAD_OPEN
    else
        n.class = NOAD_CLOSE
    end
    return n
end

-- Wraps an mlist that starts with a left fence and ends with a right fence
-- in an inner noad, as TeX does at \right. The fences are sized to the
-- content of this sub-mlist only, not to the surrounding formula.
---@param head Node? Head of the fenced mlist.
---@return NoadNode
function M.inner_from_mlist(head)
    local n = node.new("noad", NOAD_INNER) --[[@as NoadNode]]
    n.nucleus = sub_mlist(head)
    return n
end

-- Builds an `accent` noad: `body` with an accent glyph above (`top`) and/or
-- below (`bottom`). LuaTeX stretches the accent glyph to wide bases using
-- the font's horizontal variants (see `attach_to_font`).
---@param fam integer Math family (for the accent glyphs).
---@param body Node? Base mlist head.
---@param top integer? Code point of the accent above, or nil.
---@param bottom integer? Code point of the accent below, or nil.
---@return Node
function M.accent(fam, body, top, bottom)
    local n = node.new("accent") --[[@as AccentNode]]
    n.nucleus = sub_mlist(body)
    if top then
        n.accent = math_char(fam, top)
    end
    if bottom then
        n.bot_accent = math_char(fam, bottom)
    end
    return n
end

-- Concatenates two math node lists. Returns the new head. Either argument
-- may be nil. Intended for building mrow contents one child at a time.
---@param head Node?
---@param tail Node?
---@return Node?
function M.append(head, tail)
    if not head then
        return tail
    end
    if not tail then
        return head
    end
    local last = node.tail(head)
    last.next = tail
    tail.prev = last
    return head
end

----------------------------------------------------------------------------
-- MathML walker
----------------------------------------------------------------------------

-- Operator dictionary: Unicode code point -> class string (see the header
-- of mathoperators.lua for the class names). Code points that are not
-- listed are ordinary atoms.
local operators = require("publisher.mathoperators")

-- Dictionary class -> simple-noad subtype for a plain <mo> inside an mrow.
-- Fences, accents and over/under braces have no atom class of their own in
-- TeX; on their own they are set as ordinary atoms.
local CLASS_SUBTYPE = {
    bin = NOAD_BIN,
    rel = NOAD_REL,
    open = NOAD_OPEN,
    close = NOAD_CLOSE,
    punct = NOAD_PUNCT,
    op = NOAD_OP,
    opnolimits = NOAD_OPNOLIMITS,
}

-- Prime glyphs are designed as raised glyphs in OpenType math fonts (they
-- sit above the x-height at text size), so they are set as ordinary atoms
-- without any script treatment, even when the MathML input wraps them in
-- msup as MathML Core recommends.
local PRIMES = {
    [0x2032] = true, -- '′' prime
    [0x2033] = true, -- '″' double prime
    [0x2034] = true, -- '‴' triple prime
    [0x2035] = true, -- '‵' reversed prime
    [0x2057] = true, -- '⁗' quadruple prime
}

-- MathML input usually writes accents with spacing characters (a plain ^
-- for a hat, → for a vector arrow), as MathML Core lists them in its
-- operator dictionary. In an accent position they are replaced by the
-- combining characters that OpenType math fonts provide accent metrics for.
local ACCENT_MAP = {
    [0x005E] = 0x0302, -- ^ -> combining circumflex
    [0x02C6] = 0x0302, -- ˆ modifier circumflex
    [0x007E] = 0x0303, -- ~ -> combining tilde
    [0x02DC] = 0x0303, -- ˜ small tilde
    [0x00AF] = 0x0304, -- ¯ macron
    [0x203E] = 0x0305, -- ‾ overline
    [0x005F] = 0x0332, -- _ -> combining low line
    [0x02D8] = 0x0306, -- ˘ breve
    [0x02D9] = 0x0307, -- ˙ dot above
    [0x002E] = 0x0307, -- . as dot accent
    [0x00A8] = 0x0308, -- ¨ diaeresis
    [0x02C7] = 0x030C, -- ˇ caron
    [0x0060] = 0x0300, -- ` grave
    [0x00B4] = 0x0301, -- ´ acute
    [0x02DA] = 0x030A, -- ˚ ring above
    [0x2192] = 0x20D7, -- → -> combining right arrow above
    [0x2190] = 0x20D6, -- ← -> combining left arrow above
    [0x2194] = 0x20E1, -- ↔ -> combining left right arrow above
    [0x20D7] = 0x20D7,
    [0x20D6] = 0x20D6,
    [0x20E1] = 0x20E1,
}

-- Invisible MathML operators (function application, invisible times,
-- invisible separator, invisible plus). They carry no glyph; the atom
-- spacing takes care of the layout.
local INVISIBLE = {
    [0x2061] = true,
    [0x2062] = true,
    [0x2063] = true,
    [0x2064] = true,
}

-- Maps an ASCII letter to its Unicode math-italic counterpart (block
-- "Mathematical Alphanumeric Symbols"). TeX renders single-letter
-- identifiers with these glyphs. Non-letters pass through unchanged.
-- U+210E (planck constant) fills the hole at 'h' in the italic block.
-- Lowercase Greek letters are italic as well (TeX convention: lowercase
-- Greek italic, uppercase Greek upright). The variant forms and the
-- partial differential follow the italic block in Unicode order.
local GREEK_ITALIC = {
    [0x2202] = 0x1D715, -- ∂
    [0x03F5] = 0x1D716, -- ϵ
    [0x03D1] = 0x1D717, -- ϑ
    [0x03F0] = 0x1D718, -- ϰ
    [0x03D5] = 0x1D719, -- ϕ
    [0x03F1] = 0x1D71A, -- ϱ
    [0x03D6] = 0x1D71B, -- ϖ
}
---@param cp integer Unicode code point.
---@return integer
local function to_math_italic(cp)
    if cp >= 0x61 and cp <= 0x7A then
        if cp == 0x68 then
            return 0x210E
        end
        return 0x1D44E + (cp - 0x61)
    elseif cp >= 0x41 and cp <= 0x5A then
        return 0x1D434 + (cp - 0x41)
    elseif cp >= 0x03B1 and cp <= 0x03C9 then
        return 0x1D6FC + (cp - 0x03B1)
    end
    return GREEK_ITALIC[cp] or cp
end

-- Extracts inline text content of an XML element produced by lxpath. Joins
-- string children; nested elements are ignored (caller should not pass
-- container elements like <mrow>). Surrounding whitespace is removed, as
-- MathML token elements ignore it.
---@param elt table lxpath element.
---@return string
local function inner_text(elt)
    local parts = {}
    for i = 1, #elt do
        if type(elt[i]) == "string" then
            parts[#parts + 1] = elt[i]
        end
    end
    return (table.concat(parts):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Returns the i-th child element of `elt`, skipping whitespace-only text
-- nodes. MathML structure-bearing elements use child order positionally
-- (msup expects child #1 = base, child #2 = exponent).
---@param elt table
---@param i integer 1-based child index.
---@return table?
local function child_element(elt, i)
    local seen = 0
    for k = 1, #elt do
        if type(elt[k]) == "table" then
            seen = seen + 1
            if seen == i then
                return elt[k]
            end
        end
    end
    return nil
end

-- Returns the value of the XML attribute `name` of `elt`, or nil.
---@param elt table lxpath element.
---@param name string
---@return string?
local function attribute(elt, name)
    local attrs = elt[".__attributes"]
    return attrs and attrs[name]
end

-- Returns the local element name of an lxpath element.
---@param elt table?
---@return string?
local function element_name(elt)
    if type(elt) ~= "table" then
        return nil
    end
    return elt[".__local_name"] or elt[".__name"]
end

-- If `elt` is an <mo> with exactly one code point, returns that code point.
---@param elt table?
---@return integer?
local function single_mo_codepoint(elt)
    if element_name(elt) ~= "mo" then
        return nil
    end
    local txt = inner_text(elt --[[@as table]])
    if utf8.len(txt) ~= 1 then
        return nil
    end
    return utf8.codepoint(txt)
end

-- Parses a MathML length (a number with a unit such as 1em, 3pt, 0.5mm,
-- or a plain number). Em-based units refer to the math font size, other
-- units go through TeX. Unknown input yields 0 with a warning.
---@param str string
---@param ctx table Walker context (for the font size).
---@return integer sp
local function mml_length(str, ctx)
    str = str:gsub("^%s+", ""):gsub("%s+$", "")
    local num, unit = str:match("^([+-]?%d*%.?%d+)%s*(%a*)$")
    if not num then
        main.log("warn", string.format("Math: cannot parse length %q", str))
        return 0
    end
    local n = tonumber(num)
    if unit == "" or unit == "em" or unit == "ex" then
        local size = ctx.fontsize or 0
        if unit == "ex" then
            size = size / 2
        end
        return math.floor(n * size + 0.5)
    end
    local ok, sp = pcall(tex.sp, num .. unit)
    if not ok or not sp then
        main.log("warn", string.format("Math: cannot parse length %q", str))
        return 0
    end
    return sp
end

-- True if `head` is a single simple noad (no following node).
---@param head Node?
---@return boolean
local function is_single_noad(head)
    return head ~= nil and head.next == nil and node.type(head.id) == "noad"
end

-- True if `head` is a single large-operator noad (op, oplimits, opnolimits).
---@param head Node?
---@return boolean
local function is_single_op(head)
    if not head or not is_single_noad(head) then
        return false
    end
    local st = head.subtype
    return st == NOAD_OP or st == NOAD_OPLIMITS or st == NOAD_OPNOLIMITS
end

-- Returns a copy of the walker context for a nested part that is set in
-- a smaller style: `delta` is added to the script level (0 = text, 1 =
-- script, 2 = scriptscript) and the display flag is cleared. The level is
-- used by elements that set text with the paragraph font (mtext) and by
-- relative scriptlevel values on mstyle; the noads themselves get their
-- style from LuaTeX.
---@param ctx table
---@param delta integer
---@return table
local function smaller_ctx(ctx, delta)
    local inner = {}
    for k, v in pairs(ctx) do
        inner[k] = v
    end
    inner.scriptlevel = math.min((ctx.scriptlevel or 0) + delta, 2)
    inner.display = false
    return inner
end

-- Returns a noad that scripts can be attached to. A single simple noad is
-- used directly: this keeps the atom class, so scripts on a large operator
-- such as ∑ get display limits and the display-size glyph. Everything else
-- (several nodes, fractions, radicals) is wrapped in an ord noad.
---@param head Node?
---@return NoadNode
local function script_base(head)
    if is_single_noad(head) then
        return head --[[@as NoadNode]]
    end
    return M.ord_from_mlist(head)
end

-- Forward declarations so handlers can call back into the walker.
local walk

local mml_handler = {}

-- Operator classes that may act as a stretchy delimiter on each side of a
-- fenced mrow. Vertical bars are "fence" in the operator dictionary and
-- work on either side and in the middle.
local FENCE_CLASSES = {
    [FENCE_LEFT] = { open = true, fence = true },
    [FENCE_RIGHT] = { close = true, fence = true },
    [FENCE_MIDDLE] = { fence = true },
}

-- Returns the code point of `elt` when it is a single-character `<mo>`
-- that can serve as a stretchy delimiter on `side`, nil otherwise. The
-- MathML attribute `stretchy="false"` opts out.
---@param elt table? Child element of an mrow.
---@param side integer FENCE_LEFT, FENCE_MIDDLE or FENCE_RIGHT.
---@return integer? cp
local function fence_codepoint(elt, side)
    local cp = elt and single_mo_codepoint(elt)
    if
        not cp or attribute(elt --[[@as table]], "stretchy") == "false"
    then
        return nil
    end
    if FENCE_CLASSES[side][operators[cp]] then
        return cp
    end
    return nil
end

-- An mrow whose first child is an opening and whose last child is a closing
-- `<mo>` becomes a fenced group (\left ... \right): the delimiters grow with
-- the content, vertical bars in between become \middle fences. Any other
-- mrow is just the concatenation of its children.
function mml_handler.mrow(elt, ctx)
    local children = {}
    for k = 1, #elt do
        if type(elt[k]) == "table" then
            children[#children + 1] = elt[k]
        end
    end
    local n = #children
    local left_cp, right_cp
    if n >= 2 then
        left_cp = fence_codepoint(children[1], FENCE_LEFT)
        right_cp = fence_codepoint(children[n], FENCE_RIGHT)
    end
    local fenced = left_cp ~= nil and right_cp ~= nil
    local head
    local first, last = 1, n
    if fenced then
        head = M.fence(FENCE_LEFT, ctx.fam, left_cp --[[@as integer]])
        first, last = 2, n - 1
    end
    for k = first, last do
        local child = children[k]
        local middle_cp = fenced and fence_codepoint(child, FENCE_MIDDLE)
        if middle_cp then
            head = M.append(head, M.fence(FENCE_MIDDLE, ctx.fam, middle_cp))
        else
            head = M.append(head, walk(child, ctx))
        end
    end
    if fenced then
        head = M.append(head, M.fence(FENCE_RIGHT, ctx.fam, right_cp --[[@as integer]]))
        return M.inner_from_mlist(head)
    end
    return head
end

function mml_handler.mi(elt, ctx)
    local txt = inner_text(elt)
    if txt == "" then
        return nil
    end
    -- Single-character identifiers are italic by MathML convention (mapped
    -- to the math-italic code points), multi-character identifiers are
    -- upright. mathvariant="normal" keeps a single letter upright (the d in
    -- dx, units, the constants e and i); the other mathvariant values
    -- (bold, script, fraktur, …) are not supported yet.
    local single = utf8.len(txt) == 1
    local italic = single and attribute(elt, "mathvariant") ~= "normal"
    local head
    for _, cp in utf8.codes(txt) do
        if italic then
            cp = to_math_italic(cp)
        end
        head = M.append(head, M.mchar(NOAD_ORD, ctx.fam, cp))
    end
    -- A multi-letter identifier such as "sin" or "lim" is a function name:
    -- one atom, set as an operator (as \sin and \lim in TeX) so that a
    -- thin space separates it from its argument and limits can go below.
    if not single and head then
        local op = node.new("noad", NOAD_OPNOLIMITS) --[[@as NoadNode]]
        op.nucleus = sub_mlist(head)
        head = op
    end
    return head
end

function mml_handler.mn(elt, ctx)
    local head
    for _, cp in utf8.codes(inner_text(elt)) do
        head = M.append(head, M.mchar(NOAD_ORD, ctx.fam, cp))
    end
    return head
end

function mml_handler.mo(elt, ctx)
    local txt = inner_text(elt)
    local head
    for _, cp in utf8.codes(txt) do
        -- The ASCII hyphen-minus stands for the minus sign in MathML input.
        if cp == 0x2D then
            cp = 0x2212
        end
        if not INVISIBLE[cp] then
            local subtype = CLASS_SUBTYPE[operators[cp]] or NOAD_ORD
            head = M.append(head, M.mchar(subtype, ctx.fam, cp))
        end
    end
    return head
end

function mml_handler.mtext(elt, ctx)
    -- Text inside a formula ("for all", units, words) is set with the font
    -- of the surrounding paragraph through the regular text pipeline and
    -- embedded as a box (sub_box nucleus of an ord atom). Inner whitespace
    -- is collapsed to single spaces as in MathML, leading and trailing
    -- whitespace is dropped (use mspace for explicit spacing). Inside
    -- scripts and limits the script size of the font family is used, as
    -- for Sub and Sup. mathvariant selects bold and italic faces.
    local txt = inner_text(elt):gsub("%s+", " ")
    if txt == "" then
        return nil
    end
    local text = ctx.text
    if not text then
        -- No paragraph context (should not happen): fall back to the
        -- characters of the math font.
        return mml_handler.mn(elt, ctx)
    end
    local parameter = { fontfamily = text.fontfamily, languagecode = text.languagecode }
    if (ctx.scriptlevel or 0) >= 1 then
        parameter.fontsize = "small"
    end
    local mv = attribute(elt, "mathvariant")
    if mv == "bold" or mv == "bold-italic" then
        parameter.bold = 1
    end
    if mv == "italic" or mv == "bold-italic" then
        parameter.italic = 1
    end
    local nodes = publisher.nodes.mknodes(txt, parameter, "math/mtext")
    local box = node.hpack(nodes)
    local sb = node.new("sub_box") --[[@as SubBoxNode]]
    sb.head = box
    local n = node.new("noad", NOAD_ORD) --[[@as NoadNode]]
    n.nucleus = sb
    return n
end

function mml_handler.mfrac(elt, ctx)
    -- Numerator and denominator are set in text style within display
    -- style and one level smaller otherwise.
    local fctx = smaller_ctx(ctx, ctx.display and 0 or 1)
    local num = walk(child_element(elt, 1), fctx)
    local den = walk(child_element(elt, 2), fctx)
    -- linethickness="0" gives a rule-less fraction (binomial coefficients).
    -- The keywords thin, medium and thick and no attribute use the rule
    -- thickness of the font, a length sets it explicitly.
    local thickness
    local lt = attribute(elt, "linethickness")
    if lt and lt ~= "thin" and lt ~= "medium" and lt ~= "thick" then
        thickness = mml_length(lt, ctx)
    end
    return M.frac(num, den, thickness)
end

function mml_handler.mroot(elt, ctx)
    local body = walk(child_element(elt, 1), ctx)
    local degree = walk(child_element(elt, 2), smaller_ctx(ctx, 2))
    return M.sqrt(ctx.fam, body, degree)
end

function mml_handler.mspace(elt, ctx)
    local wd = attribute(elt, "width")
    if not wd then
        return nil
    end
    local g = node.new("glue") --[[@as GlueNode]]
    g.width = mml_length(wd, ctx)
    return g
end

-- Maps mstyle attributes to a LuaTeX style: displaystyle chooses between
-- display and text, scriptlevel between text, script and scriptscript.
---@param elt table
---@param ctx table
---@return string? style
local function mstyle_style(elt, ctx)
    local sl = attribute(elt, "scriptlevel")
    if sl then
        local n = tonumber(sl)
        if n then
            if sl:match("^[+-]") then
                n = (ctx.scriptlevel or 0) + n
            end
            if n >= 2 then
                return "scriptscript"
            elseif n == 1 then
                return "script"
            end
            return ctx.display and "display" or "text"
        end
    end
    local ds = attribute(elt, "displaystyle")
    if ds == "true" then
        return "display"
    elseif ds == "false" then
        return "text"
    end
    return nil
end

function mml_handler.mstyle(elt, ctx)
    local style = mstyle_style(elt, ctx)
    if not style then
        return mml_handler.mrow(elt, ctx)
    end
    -- A style node changes the style until the end of its mlist, so the
    -- contents are wrapped in an ord noad to keep the change local. The
    -- context tells nested elements which style is in effect.
    local inner = {}
    for k, v in pairs(ctx) do
        inner[k] = v
    end
    inner.display = style == "display"
    inner.scriptlevel = style == "script" and 1 or style == "scriptscript" and 2 or 0
    local body = mml_handler.mrow(elt, inner)
    local st = node.new("style") --[[@as StyleNode]]
    st.style = style
    return M.ord_from_mlist(M.append(st, body))
end

-- Shared implementation of msup / msub / msubsup. `sup_elt` / `sub_elt`
-- may be nil.
---@param elt table
---@param ctx table
---@param sup_elt table?
---@param sub_elt table?
---@return Node?
local function scripts(elt, ctx, sup_elt, sub_elt)
    local base = walk(child_element(elt, 1), ctx)
    local sctx = smaller_ctx(ctx, 1)
    local sub = sub_elt and walk(sub_elt, sctx)
    -- MathML Core writes primes as superscripts (<msup><mi>a</mi><mo>′</mo>
    -- </msup>). The glyph is already raised, so it is appended as an
    -- ordinary atom instead of being raised a second time.
    local sup_cp = single_mo_codepoint(sup_elt)
    if sup_cp and PRIMES[sup_cp] then
        local noad = script_base(base)
        M.attach_scripts(noad, nil, sub)
        return M.append(noad, M.mchar(NOAD_ORD, ctx.fam, sup_cp))
    end
    local sup = sup_elt and walk(sup_elt, sctx)
    return M.attach_scripts(script_base(base), sup, sub)
end

function mml_handler.msup(elt, ctx)
    return scripts(elt, ctx, child_element(elt, 2), nil)
end

function mml_handler.msub(elt, ctx)
    return scripts(elt, ctx, nil, child_element(elt, 2))
end

function mml_handler.msubsup(elt, ctx)
    return scripts(elt, ctx, child_element(elt, 3), child_element(elt, 2))
end

-- True if the under/over element should be treated as an accent: either the
-- MathML attribute says so, or it is a single <mo> that the operator
-- dictionary lists as a (bottom) accent.
---@param elt table The munder/mover/munderover element.
---@param attr string "accent" or "accentunder".
---@param script_elt table? The over or under child.
---@param class string "accent" or "botaccent".
---@return boolean
local function is_accent(elt, attr, script_elt, class)
    local a = attribute(elt, attr)
    if a == "true" then
        return true
    elseif a == "false" then
        return false
    end
    local cp = single_mo_codepoint(script_elt)
    if cp == nil then
        return false
    end
    return operators[cp] == class or operators[ACCENT_MAP[cp]] == class
end

-- Shared implementation of munder / mover / munderover. Either script
-- element may be nil.
--
-- Three cases:
--  1. The base is a large operator (∑, ∫, …): the scripts become its
--     limits. Operators with movable limits keep them (limits in display
--     style, scripts in text style), integrals get explicit limits since
--     the input asked for them.
--  2. Accents (a hat, a bar, an arrow over a vector): an accent noad, so
--     the font's accent placement is used.
--  3. Anything else (a word under an arrow, "def" over an equals sign):
--     an op noad with forced limits, wrapped in a noad of the base's class
--     so the spacing of the base is kept (the amsmath \overset trick).
---@param elt table
---@param ctx table
---@param over_elt table?
---@param under_elt table?
---@return Node?
local function underover(elt, ctx, over_elt, under_elt)
    local base = walk(child_element(elt, 1), ctx)
    local sctx = smaller_ctx(ctx, 1)
    if is_single_op(base) then
        local over = over_elt and walk(over_elt, sctx)
        local under = under_elt and walk(under_elt, sctx)
        if base.subtype == NOAD_OPNOLIMITS then
            base.subtype = NOAD_OPLIMITS
        end
        return M.attach_scripts(base, over, under)
    end
    local over_accent = over_elt and is_accent(elt, "accent", over_elt, "accent")
    local under_accent = under_elt and is_accent(elt, "accentunder", under_elt, "botaccent")
    if (over_elt == nil or over_accent) and (under_elt == nil or under_accent) then
        local over_cp = over_elt and single_mo_codepoint(over_elt)
        local under_cp = under_elt and single_mo_codepoint(under_elt)
        if (over_elt == nil or over_cp) and (under_elt == nil or under_cp) then
            over_cp = over_cp and (ACCENT_MAP[over_cp] or over_cp)
            under_cp = under_cp and (ACCENT_MAP[under_cp] or under_cp)
            return M.accent(ctx.fam, base, over_cp, under_cp)
        end
    end
    local over = over_elt and walk(over_elt, sctx)
    local under = under_elt and walk(under_elt, sctx)
    local class = is_single_noad(base) and base.subtype or NOAD_ORD
    if class == NOAD_OP or class == NOAD_OPLIMITS or class == NOAD_OPNOLIMITS then
        class = NOAD_ORD
    end
    local op = node.new("noad", NOAD_OPLIMITS) --[[@as NoadNode]]
    op.nucleus = sub_mlist(base)
    M.attach_scripts(op, over, under)
    local wrapper = node.new("noad", class) --[[@as NoadNode]]
    wrapper.nucleus = sub_mlist(op)
    return wrapper
end

function mml_handler.mover(elt, ctx)
    return underover(elt, ctx, child_element(elt, 2), nil)
end

function mml_handler.munder(elt, ctx)
    return underover(elt, ctx, nil, child_element(elt, 2))
end

function mml_handler.munderover(elt, ctx)
    return underover(elt, ctx, child_element(elt, 3), child_element(elt, 2))
end

function mml_handler.msqrt(elt, ctx)
    -- msqrt takes an arbitrary number of children, treated as an implicit mrow.
    local body = mml_handler.mrow(elt, ctx)
    return M.sqrt(ctx.fam, body, nil)
end

function mml_handler.math(elt, ctx)
    -- The top-level <math> element is just an mrow wrapper.
    return mml_handler.mrow(elt, ctx)
end

-- Dispatches an MathML element to its handler. Unknown elements fall back
-- to mrow semantics (process children) so unsupported markup degrades to a
-- best-effort rendering instead of dropping the formula entirely.
---@param elt table? lxpath element.
---@param ctx table Walker context: `{ fam = math-family index, display = bool, fontsize = sp, scriptlevel = 0..2, text = paragraph text options }`.
---@return Node? Head of an mlist (chain of noads), or nil if `elt` is nil/empty.
walk = function(elt, ctx)
    if not elt or type(elt) ~= "table" then
        return nil
    end
    local name = element_name(elt)
    local h = mml_handler[name]
    if h then
        return h(elt, ctx)
    end
    main.log("warn", string.format("Math: unsupported MathML element %q, treating as mrow", tostring(name)))
    return mml_handler.mrow(elt, ctx)
end

M.walk = walk

----------------------------------------------------------------------------
-- Top-level entry: MathML tree -> hlist
----------------------------------------------------------------------------

-- Converts a parsed MathML element (lxpath table) into an hlist node that
-- the paragraph builder can splice into a line, or that PlaceObject can
-- wrap into a positioned box.
---@param mathml_elt table lxpath element (typically the <math> root).
---@param display boolean `true` for display style, `false` for inline.
---@param text table? Text options of the surrounding paragraph (`fontfamily`, `languagecode`), used for mtext.
---@return Node? hlist Head of the resulting hlist, or nil on error.
function M.mathml_to_hlist(mathml_elt, display, text)
    if not M.font_ready then
        main.log("error", "Math: no math font registered; call publisher.math.set_math_font first")
        return nil
    end
    local fnt = M.fontid_text and font.getfont(M.fontid_text)
    local ctx = { fam = M.FAM_MAIN, display = display, fontsize = fnt and fnt.size or 0, text = text }
    local mlist = walk(mathml_elt, ctx)
    if not mlist then
        return nil
    end
    local style = display and "display" or "text"
    -- The third arg (penalties) is `true` so LuaTeX inserts the usual
    -- inline-break penalties around binary operators. For display math the
    -- value is ignored.
    local hlist = node.mlist_to_hlist(mlist, style, true)
    return hlist
end

file_end("math.lua")

return M
