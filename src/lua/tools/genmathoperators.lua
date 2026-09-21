-- Generates src/lua/publisher/mathoperators.lua, the operator dictionary
-- used by the MathML walker in src/lua/publisher/math.lua.
--
-- Source: unicode-math-table.tex from the LaTeX package unicode-math
-- (Will Robertson and others, LPPL 1.3c). The table assigns every
-- mathematical Unicode code point a TeX math class. Only the classes that
-- change the noad type are emitted; everything not listed is an ordinary
-- atom (mathord / mathalpha in unicode-math).
--
-- Usage:
--   rake mathoperators
-- or
--   bin/sdluatex --luaonly src/lua/tools/genmathoperators.lua \
--       $(kpsewhich unicode-math-table.tex) src/lua/publisher/mathoperators.lua

local infile, outfile = arg[1], arg[2]
if not infile or not outfile then
    io.stderr:write("usage: genmathoperators.lua unicode-math-table.tex mathoperators.lua\n")
    os.exit(1)
end

-- unicode-math class -> dictionary class. Classes that map to nil are
-- ordinary atoms and are left out of the table.
local CLASS = {
    mathbin = "bin",
    mathrel = "rel",
    mathopen = "open",
    mathclose = "close",
    mathpunct = "punct",
    mathop = "op",
    mathfence = "fence",
    mathaccent = "accent",
    mathaccentwide = "accent",
    mathaccentoverlay = "accent",
    mathbotaccent = "botaccent",
    mathbotaccentwide = "botaccent",
    mathover = "over",
    mathunder = "under",
    mathord = false,
    mathalpha = false,
}

-- Integral-like operators take their limits as scripts even in display
-- style (TeX: \nolimits). Every other large operator uses limits in
-- display style and scripts in text style (TeX: \displaylimits).
local function is_integral(cp)
    return (cp >= 0x222B and cp <= 0x2233) or (cp >= 0x2A0B and cp <= 0x2A1C)
end

local entries = {}
local order = {}
local n = 0
for line in io.lines(infile) do
    local hex, umclass, desc = line:match('^\\UnicodeMathSymbol{"(%x+)}{[^}]*}{\\(%a+)}{(.-)}%%?$')
    if hex then
        n = n + 1
        local cp = tonumber(hex, 16)
        local class = CLASS[umclass]
        if class == nil then
            error(string.format("line %d: unknown unicode-math class %q", n, umclass))
        end
        if class == "op" and is_integral(cp) then
            class = "opnolimits"
        end
        local existing = entries[cp]
        if existing == nil then
            entries[cp] = { class = class, desc = desc }
            order[#order + 1] = cp
        elseif existing.class ~= class then
            -- A code point listed with two classes (for example U+221A as
            -- mathopen and mathord, or an accent listed as mathaccent and
            -- mathaccentwide). Ordinary wins, otherwise the first entry.
            if class == false then
                existing.class = false
            end
        end
    end
end
table.sort(order)

local out = assert(io.open(outfile, "w"))
out:write([[
-- Operator dictionary for the MathML walker (src/lua/publisher/math.lua).
-- Maps a Unicode code point to its math class. Code points not listed are
-- ordinary atoms.
--
-- Generated from unicode-math-table.tex of the LaTeX package unicode-math
-- (LPPL 1.3c) by src/lua/tools/genmathoperators.lua. Do not edit; run
-- "rake mathoperators" to regenerate.
--
-- Classes: bin, rel, open, close, punct, op (large operator, limits in
-- display style), opnolimits (integral-like, limits always as scripts),
-- fence (vertical bars), accent, botaccent, over, under.
return {
]])
local count = 0
for _, cp in ipairs(order) do
    local e = entries[cp]
    if e.class then
        count = count + 1
        out:write(string.format("    [0x%04X] = %q, -- %s\n", cp, e.class, e.desc))
    end
end
out:write("}\n")
out:close()
io.stderr:write(string.format("%d entries read, %d written to %s\n", n, count, outfile))
