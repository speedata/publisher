-- Mathematical typesetting via OpenType MATH fonts.
--
-- Pipeline: MathML XML tree -> LuaTeX math noad list -> mlist_to_hlist -> hlist.
-- The hlist that comes out of mlist_to_hlist is an ordinary node list that the
-- paragraph builder (par.lua) can consume like glyphs and boxes.
--
-- This file is a SKELETON. The walker covers a minimal MathML subset
-- (mrow, mi, mn, mo, mtext, mfrac, msup, msub, msubsup, msqrt). The
-- OpenType MATH table parser handles MathConstants and italic corrections;
-- the operator-spacing dictionary, stretchy delimiters, mtable and the
-- remaining MathML elements still need to be implemented.
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

----------------------------------------------------------------------------
-- OpenType MATH table parser
----------------------------------------------------------------------------
--
-- We read the raw MATH bytes via luaharfbuzz's `face:get_table()` instead of
-- going through the FontForge fontloader. The format is documented in the
-- OpenType spec, section "MATH — The mathematical typesetting table".
--
-- Scope of the parser: MathConstants (all 57 fields) and italic corrections
-- (from MathGlyphInfo → MathItalicsCorrectionInfo). Stretchy variants,
-- glyph assemblies, top-accent attachment and per-glyph math kerns are not
-- yet handled — leave them as TODOs.

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

-- Parses the raw bytes of an OpenType MATH table. Pure function — no
-- dependencies on `publisher` or `main.log`, so it can be exercised
-- standalone for testing.
---@param data string Raw MATH table bytes (as returned by harfbuzz).
---@return table? parsed `{ constants = { Name = { value, kind } | int }, italics = { [gid] = value } }`, or nil on parse error / wrong version.
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
    -- MathVariants offset at byte 9; not parsed yet.

    local parsed = { constants = {}, italics = {} }

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

    -- MathGlyphInfo → MathItalicsCorrectionInfo -------------------------
    if math_glyph_info_off > 0 then
        local mgi_p = math_glyph_info_off + 1
        local italics_off = unpack_str(">I2", data, mgi_p)
        if italics_off > 0 then
            local ic_base = math_glyph_info_off + italics_off
            local coverage_rel = unpack_str(">I2", data, ic_base + 1)
            local count = unpack_str(">I2", data, ic_base + 3)
            local gids = parse_coverage(data, math_glyph_info_off + italics_off + coverage_rel)
            -- The italicsCorrection array runs parallel to the coverage,
            -- one MathValueRecord per covered glyph.
            for i = 1, count do
                local gid = gids[i]
                if gid then
                    parsed.italics[gid] = read_mvr(data, ic_base + 5 + (i - 1) * 4)
                end
            end
        end
        -- TODO: mathTopAccentAttachment, extendedShapeCoverage, mathKernInfo.
    end

    -- TODO: MathVariants (stretchy delimiters + glyph assemblies).

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
    f.MathConstants = mc

    -- Per-glyph italic correction. Lookup via backmap (gid → primary
    -- unicode). Glyphs without a unicode mapping are skipped — they
    -- can't be addressed from a `math_char` noad anyway.
    local backmap = f.backmap
    if backmap then
        for gid, value in pairs(parsed.italics) do
            local uni = backmap[gid]
            local ch = uni and f.characters[uni]
            if ch then
                ch.italic = du_to_sp(value, mag)
            end
        end
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
local NOAD_OP = 1 -- opdisplaylimits — default for sum, prod, int
local NOAD_BIN = 4
local NOAD_REL = 5
local NOAD_OPEN = 6
local NOAD_CLOSE = 7
local NOAD_PUNCT = 8

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
    -- The radical sign itself is a delimiter subnode. Growing it to match
    -- tall radicands needs the MathVariants data (vert_variants), which the
    -- font loader does not provide yet; until then the base glyph is used.
    local delim = node.new("delim") --[[@as DelimNode]]
    delim.small_fam = fam
    delim.small_char = 0x221A -- '√'
    n.left = delim
    if degree then
        n.degree = sub_mlist(degree) --[[@as KernNode]]
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

-- Operator dictionary stub. The full MathML operator dictionary
-- (Appendix C of the MathML 3 spec / unicode-math-table.tex) maps each
-- operator code point to a noad class plus default lspace/rspace. For the
-- skeleton we keep a tiny table; everything not listed becomes "bin".
--
-- TODO: replace with a generated table covering the ~1500 operator entries.
local OP_CLASS = {
    [0x002B] = NOAD_BIN, -- '+'
    [0x2212] = NOAD_BIN, -- '−' minus
    [0x00D7] = NOAD_BIN, -- '×'
    [0x22C5] = NOAD_BIN, -- '⋅'
    [0x003D] = NOAD_REL, -- '='
    [0x2260] = NOAD_REL, -- '≠'
    [0x003C] = NOAD_REL, -- '<'
    [0x003E] = NOAD_REL, -- '>'
    [0x2264] = NOAD_REL, -- '≤'
    [0x2265] = NOAD_REL, -- '≥'
    [0x0028] = NOAD_OPEN, -- '('
    [0x005B] = NOAD_OPEN, -- '['
    [0x007B] = NOAD_OPEN, -- '{'
    [0x0029] = NOAD_CLOSE, -- ')'
    [0x005D] = NOAD_CLOSE, -- ']'
    [0x007D] = NOAD_CLOSE, -- '}'
    [0x002C] = NOAD_PUNCT, -- ','
    [0x003B] = NOAD_PUNCT, -- ';'
    [0x2211] = NOAD_OP, -- '∑'
    [0x220F] = NOAD_OP, -- '∏'
    [0x222B] = NOAD_OP, -- '∫'
    -- Primes are designed as raised glyphs in OpenType math fonts (they sit
    -- above the x-height at text size), so they are set as ord atoms without
    -- any script treatment. Do not wrap them in msup: that would scale and
    -- raise them a second time.
    [0x2032] = NOAD_ORD, -- '′' prime
    [0x2033] = NOAD_ORD, -- '″' double prime
    [0x2034] = NOAD_ORD, -- '‴' triple prime
    [0x2035] = NOAD_ORD, -- '‵' reversed prime
    [0x2057] = NOAD_ORD, -- '⁗' quadruple prime
}

-- Maps an ASCII letter to its Unicode math-italic counterpart (block
-- "Mathematical Alphanumeric Symbols"). TeX renders single-letter
-- identifiers with these glyphs. Non-letters pass through unchanged.
-- U+210E (planck constant) fills the hole at 'h' in the italic block.
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
    end
    return cp
end

-- Extracts inline text content of an XML element produced by lxpath. Joins
-- string children; nested elements are ignored (caller should not pass
-- container elements like <mrow>).
---@param elt table lxpath element.
---@return string
local function inner_text(elt)
    local parts = {}
    for i = 1, #elt do
        if type(elt[i]) == "string" then
            parts[#parts + 1] = elt[i]
        end
    end
    return table.concat(parts)
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

-- Forward declaration so handlers can call back into the walker.
local walk

local mml_handler = {}

function mml_handler.mrow(elt, ctx)
    local head
    for k = 1, #elt do
        if type(elt[k]) == "table" then
            head = M.append(head, walk(elt[k], ctx))
        end
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
    -- upright. mathvariant styling (bold/script/…) is a later milestone.
    local single = utf8.len(txt) == 1
    local head
    for _, cp in utf8.codes(txt) do
        if single then
            cp = to_math_italic(cp)
        end
        head = M.append(head, M.mchar(NOAD_ORD, ctx.fam, cp))
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
        local class = OP_CLASS[cp] or NOAD_BIN
        head = M.append(head, M.mchar(class, ctx.fam, cp))
    end
    return head
end

function mml_handler.mtext(elt, ctx)
    -- mtext should switch to text mode (upright, with text-font spacing).
    -- For the skeleton we treat it like mi to keep something visible.
    -- TODO: build an hlist of glyph nodes via the regular font pipeline and
    -- wrap it in a sub_box nucleus.
    return mml_handler.mi(elt, ctx)
end

function mml_handler.mfrac(elt, ctx)
    local num = walk(child_element(elt, 1), ctx)
    local den = walk(child_element(elt, 2), ctx)
    return M.frac(num, den, nil)
end

function mml_handler.msup(elt, ctx)
    local base = walk(child_element(elt, 1), ctx)
    local sup = walk(child_element(elt, 2), ctx)
    return M.attach_scripts(M.ord_from_mlist(base), sup, nil)
end

function mml_handler.msub(elt, ctx)
    local base = walk(child_element(elt, 1), ctx)
    local sub = walk(child_element(elt, 2), ctx)
    return M.attach_scripts(M.ord_from_mlist(base), nil, sub)
end

function mml_handler.msubsup(elt, ctx)
    local base = walk(child_element(elt, 1), ctx)
    local sub = walk(child_element(elt, 2), ctx)
    local sup = walk(child_element(elt, 3), ctx)
    return M.attach_scripts(M.ord_from_mlist(base), sup, sub)
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
---@param ctx table Walker context: `{ fam = math-family index, display = bool }`.
---@return Node? Head of an mlist (chain of noads), or nil if `elt` is nil/empty.
walk = function(elt, ctx)
    if not elt or type(elt) ~= "table" then
        return nil
    end
    local name = elt[".__local_name"] or elt[".__name"]
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
---@return Node? hlist Head of the resulting hlist, or nil on error.
function M.mathml_to_hlist(mathml_elt, display)
    if not M.font_ready then
        main.log("error", "Math: no math font registered; call publisher.math.set_math_font first")
        return nil
    end
    local ctx = { fam = M.FAM_MAIN, display = display }
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
