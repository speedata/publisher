--
--  metadata.lua
--  speedata publisher
--
--  PDF metadata/XMP helpers.
--

file_start("publisher/metadata.lua")

local publisher = require("publisher")

---@class metadata_module
local M = {}

local uuid = require("uuid")
local xmlbuilder = require("xmlbuilder")

-- Encodes a Unicode codepoint as a hex UTF-16 string (BMP) or surrogate pair.
---@param codepoint integer Unicode scalar.
---@return string hex Uppercase hex digits, 4 chars (BMP) or 8 chars (surrogate pair).
local function to_utf16(codepoint)
    assert(codepoint)
    if codepoint < 65536 then
        return string.format("%04X", codepoint)
    else
        return string.format("%04X%04X", math.floor(codepoint / 1024) + 0xD800, codepoint % 1024 + 0xDC00)
    end
end

-- Parses a PDF "date" string (`D:YYYYMMDDHHmmSS[±HH'mm']`) into ISO 8601.
---@param s string PDF date.
---@return string? iso ISO 8601 string, or `nil` on parse error.
---@return string? errmsg Error message when parsing fails.
local function pdf_to_iso(s)
    -- input: D:YYYYMMDDHHmmSS[Z|+/-HH['?]mm['?]]
    local Y, Month, D, h, mi, se, sign, th, tm =
        s:match("^D:(%d%d%d%d)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d)([Z+-]?)(%d?%d?)'?([%d%?]?%d?)'?$")
    if not Y then
        return nil, "Unbekanntes PDF-Datum"
    end

    local iso = string.format("%s-%s-%sT%s:%s:%s", Y, Month, D, h, mi, se)

    if sign == "Z" then
        return iso .. "Z"
    elseif sign == "+" or sign == "-" then
        -- timezone given
        th = (#th == 2) and th or (th == "" and "00" or (th .. "0"))
        tm = (#tm == 2) and tm or (tm == "" and "00" or (tm .. "0"))
        return string.format("%s%s%s:%s", iso, sign, th, tm)
    else
        -- no timezone given, assume local time
        return iso
    end
end
M.pdf_to_iso = pdf_to_iso

-- Returns the value for the PDF info "Creator" field. Honors
-- `opts.documentcreator` and the `sp_suppressinfo` global.
---@param opts table? Options table; falls back to `publisher.options` if available.
---@return string creator
function M.getcreator(opts)
    opts = opts or (package.loaded["publisher"] and package.loaded["publisher"].options)
    if opts and opts.documentcreator and opts.documentcreator ~= "" then
        return opts.documentcreator
    elseif sp_suppressinfo then
        return "speedata Publisher"
    else
        return string.format("speedata Publisher %s using LuaTeX", publisher.env_publisherversion)
    end
end

-- Returns the value for the PDF info "Producer" field. Honors
-- `opts.documentproducer`, `opts.documentcreator` and `sp_suppressinfo`.
---@param opts table? Options table; falls back to `publisher.options` if available.
---@return string producer
function M.getproducer(opts)
    opts = opts or (package.loaded["publisher"] and package.loaded["publisher"].options)
    if opts and opts.documentproducer and opts.documentproducer ~= "" then
        return opts.documentproducer
    elseif opts and opts.documentcreator and opts.documentcreator ~= "" and sp_suppressinfo then
        return string.format("speedata Publisher using LuaTeX")
    elseif opts and opts.documentcreator and opts.documentcreator ~= "" then
        return string.format("speedata Publisher %s using LuaTeX", publisher.env_publisherversion)
    elseif sp_suppressinfo then
        return "LuaTeX"
    else
        return string.format("LuaTeX %s (build %s)", luatex_version, status.development_id or "-")
    end
end

-- Returns a valid PDF date string such as `"D:20170721195500+00'00'"`.
---@param num integer Unix epoch seconds.
---@return string pdfdate
local function pdfdate(num)
    local ret = os.date("D:%Y%m%d%H%M%S+00'00'", num)
    return ret
end

-- Escapes the `/` character in a PDF name object as `#2f`.
---@param str string
---@return string escaped
local function escape_pdfname(str)
    return string.gsub(str, "/", "#2f")
end

-- Escapes parentheses in a PDF literal string. `nil` passes through unchanged.
---@param str string?
---@return string? escaped
function M.escape_pdfstring(str)
    if str then
        str = string.gsub(str, "%(", "\\(")
        str = string.gsub(str, "%)", "\\)")
    end
    return str
end

-- Converts a UTF-8 string to its PDF representation. ASCII-only inputs are
-- wrapped in `(...)`; everything else becomes a `<feff...>` UTF-16 hex string.
---@param str string UTF-8 input.
---@return string pdfstring PDF-ready string literal.
function M.utf8_to_utf16_string_pdf(str)
    if str:match("^[a-zA-Z.0-9- ]+$") then
        return "(" .. str .. ")"
    end
    local ret = {}
    for s in string.utfvalues(str) do
        ret[#ret + 1] = to_utf16(s)
    end
    local utf16str = "<feff" .. table.concat(ret) .. ">"
    return utf16str
end

-- Builds the XMP metadata XML for the document.
-- Selects the right schema (PDF/A-3, PDF/UA, PDF/X-4, PDF/X-3:2002) from
-- `opts.format` and injects ZUGFeRD properties when an embedded invoice is present.
---@param filespecnumbers table? Attachment info as appended by `attach_file_pdf` (used to detect ZUGFeRD).
---@param opts table? Options table; falls back to `publisher.options` if available.
---@return string xmp Pretty-printed XMP packet ready for `pdf.immediateobj`.
function M.getmetadata(filespecnumbers, opts)
    opts = opts or (package.loaded["publisher"] and package.loaded["publisher"].options)
    local zugferd_level = nil
    local zugferd_filename = nil
    if filespecnumbers and type(filespecnumbers) == "table" then
        for _, v in ipairs(filespecnumbers) do
            if type(v) == "table" and v[2] ~= nil then
                zugferd_level = v[2]
                zugferd_filename = v[3]
            end
        end
    end
    local isoformatted, docid, instanceid
    if sp_suppressinfo then
        isoformatted = "2000-01-01T00:00:00Z"
        docid = "00000000-0000-0000-0000-000000000000"
        instanceid = "00000000-0000-0000-0000-000000000000"
    else
        isoformatted = pdf_to_iso(pdf.getcreationdate())
        docid = uuid()
        instanceid = uuid()
    end
    local fmt = opts and opts.format

    local doc = xmlbuilder.new_document()
    doc:add_pi("xpacket", 'begin="\239\187\191" id="W5M0MpCehiHzreSzNTczkc9d"')

    local meta = doc:add_element("x:xmpmeta")
    meta:set_attr("xmlns:x", "adobe:ns:meta/")

    local rdf = meta:add_element("rdf:RDF")
    rdf:set_attr("xmlns:rdf", "http://www.w3.org/1999/02/22-rdf-syntax-ns#")

    local desc = rdf:add_element("rdf:Description")
    desc:set_attr("rdf:about", "")
    desc:set_attr("xmlns:xmpMM", "http://ns.adobe.com/xap/1.0/mm/")
    desc:set_attr("xmlns:pdfuaid", "http://www.aiim.org/pdfua/ns/id/")
    desc:set_attr("xmlns:xmp", "http://ns.adobe.com/xap/1.0/")
    desc:set_attr("xmlns:pdf", "http://ns.adobe.com/pdf/1.3/")
    desc:set_attr("xmlns:dc", "http://purl.org/dc/elements/1.1/")
    desc:set_attr("xmlns:pdfaid", "http://www.aiim.org/pdfa/ns/id/")

    if fmt == "PDF/A-3" then
        desc:add_element("xmpMM:RenditionClass"):set_text("default")
        desc:add_element("pdfaid:part"):set_text("3")
        desc:add_element("pdfaid:conformance"):set_text("B")
    elseif fmt == "PDF/UA" then
        desc:add_element("pdfuaid:part"):set_text("1")
    elseif fmt == "PDF/X-4" or fmt == "PDF/X-3:2002" then
        desc:add_element("xmpMM:RenditionClass"):set_text("default")
        desc:add_element("xmpMM:VersionID"):set_text("1")
        desc:add_element("pdf:Trapped"):set_text("False")
        if fmt == "PDF/X-3:2002" then
            desc:set_attr("xmlns:pdfx", "http://ns.adobe.com/pdfx/1.3/")
            desc:add_element("pdfx:GTS_PDFXVersion"):set_text("PDF/X-3:2002")
        elseif fmt == "PDF/X-4" then
            desc:set_attr("xmlns:pdfxid", "http://www.npes.org/pdfx/ns/id/")
            desc:add_element("pdfxid:GTS_PDFXVersion"):set_text("PDF/X-4")
        end
    end
    -- common metadata
    desc:add_element("xmpMM:DocumentID"):set_text("uuid:" .. docid)
    desc:add_element("xmpMM:InstanceID"):set_text("uuid:" .. instanceid)
    desc:add_element("xmp:CreateDate"):set_text(isoformatted)
    desc:add_element("xmp:ModifyDate"):set_text(isoformatted)
    desc:add_element("xmp:MetadataDate"):set_text(isoformatted)
    desc:add_element("xmp:CreatorTool"):set_text(M.getcreator(opts))
    desc:add_element("pdf:Producer"):set_text(M.getproducer(opts))

    -- title
    if opts and opts.documenttitle and opts.documenttitle ~= "" then
        if fmt == "PDF/A-3" or fmt == "PDF/UA" then
            local li = desc:add_element("dc:title"):add_element("rdf:Alt"):add_element("rdf:li")
            li:set_attr("xml:lang", "x-default"):set_text(opts.documenttitle)
        else
            desc:add_element("dc:title"):set_text(opts.documenttitle)
        end
    end

    -- author/creator
    if opts and opts.documentauthor and opts.documentauthor ~= "" then
        if fmt == "PDF/A-3" or fmt == "PDF/UA" then
            desc:add_element("dc:creator"):add_element("rdf:Seq"):add_element("rdf:li"):set_text(opts.documentauthor)
        else
            desc:add_element("dc:creator"):set_text(opts.documentauthor)
        end
    end

    if fmt == "PDF/A-3" and zugferd_level and zugferd_filename then
        desc:set_attr("xmlns:pdfaExtension", "http://www.aiim.org/pdfa/ns/extension/")
        desc:set_attr("xmlns:pdfaField", "http://www.aiim.org/pdfa/ns/field#")
        desc:set_attr("xmlns:pdfaProperty", "http://www.aiim.org/pdfa/ns/property#")
        desc:set_attr("xmlns:pdfaSchema", "http://www.aiim.org/pdfa/ns/schema#")
        desc:set_attr("xmlns:pdfaType", "http://www.aiim.org/pdfa/ns/type#")

        local ext = desc:add_element("pdfaExtension:schemas")
        local bag = ext:add_element("rdf:Bag")
        local li = bag:add_element("rdf:li")
        li:set_attr("rdf:parseType", "Resource")
        li:add_element("pdfaSchema:schema"):set_text("ZUGFeRD PDFA Extension Schema")
        li:add_element("pdfaSchema:namespaceURI"):set_text("urn:ferd:pdfa:CrossIndustryDocument:invoice:1p0#")
        li:add_element("pdfaSchema:prefix"):set_text("zf")
        local prop = li:add_element("pdfaSchema:property")
        local seq = prop:add_element("rdf:Seq")

        local function add_zugferd_property(name, valuetype, category, description)
            local li = seq:add_element("rdf:li")
            li:set_attr("rdf:parseType", "Resource")
            li:add_element("pdfaProperty:name"):set_text(name)
            li:add_element("pdfaProperty:valueType"):set_text(valuetype)
            li:add_element("pdfaProperty:category"):set_text(category)
            li:add_element("pdfaProperty:description"):set_text(description)
        end

        add_zugferd_property("DocumentFileName", "Text", "external", "name of the embedded XML invoice file")
        add_zugferd_property("DocumentType", "Text", "external", "INVOICE")
        add_zugferd_property("Version", "Text", "external", "The actual version of the ZUGFeRD data")
        add_zugferd_property("ConformanceLevel", "Text", "external", "The conformance level of the ZUGFeRD data")

        local rdfdesc = rdf:add_element("rdf:Description")
        rdfdesc:set_attr("xmlns:zf", "urn:ferd:pdfa:CrossIndustryDocument:invoice:1p0#")
        rdfdesc:set_attr("rdf:about", "")
        rdfdesc:set_attr("zf:ConformanceLevel", zugferd_level)
        rdfdesc:set_attr("zf:DocumentFileName", zugferd_filename)
        rdfdesc:set_attr("zf:DocumentType", "INVOICE")
        rdfdesc:set_attr("zf:Version", "1.0")
    end
    doc:add_pi("xpacket", [[end="r"]])

    return doc:to_string({ pretty = true, indent = "  " })
end

-- Attaches an embedded file to the PDF and registers the resulting filespec
-- object number in `filespecnumbers`. `mimetype = "ZUGFeRD invoice"` triggers
-- ZUGFeRD conformance-level detection from the invoice contents.
---@param filecontents string Raw contents of the file to embed.
---@param description string? Human-readable description.
---@param mimetype string MIME type or the literal `"ZUGFeRD invoice"`.
---@param modificationtime integer Unix epoch seconds.
---@param destfilename string File name stored inside the PDF.
---@param filespecnumbers table Table the filespec entry is appended to.
---@return nil
function M.attach_file_pdf(filecontents, description, mimetype, modificationtime, destfilename, filespecnumbers)
    local is_zugferd = false
    if mimetype == "ZUGFeRD invoice" then
        is_zugferd = true
        mimetype = "text/xml"
    end
    local fileobjectnum = pdf.immediateobj(
        "stream",
        filecontents,
        string.format(
            [[/Params <</ModDate (%s) /Size %d >> /Subtype /%s /Type /EmbeddedFile ]],
            pdfdate(modificationtime),
            #filecontents,
            escape_pdfname(mimetype)
        )
    )
    local descPDF = ""
    if description then
        descPDF = string.format("/Desc %s\n  ", M.utf8_to_utf16_string_pdf(description))
    end
    local filespecnum = pdf.immediateobj(
        string.format(
            [[<<
  /AFRelationship /Alternative
  %s/EF <<
    /F %d 0 R
    /UF %d 0 R
  >>
  /F %s
  /Type /Filespec
  /UF %s
>>]],
            descPDF,
            fileobjectnum,
            fileobjectnum,
            M.utf8_to_utf16_string_pdf(destfilename),
            M.utf8_to_utf16_string_pdf(destfilename)
        )
    )
    if is_zugferd then
        local conformancelevel
        if
            string.find(filecontents, "urn:cen.eu:en16931:2017#conformant#urn:factur-x.eu:1p0:extended", 1, true)
            or string.find(filecontents, "urn:cen.eu:en16931:2017#conformant#urn:zugferd.de:2p0:extended", 1, true)
            or string.find(filecontents, "urn:ferd:CrossIndustryDocument:invoice:1p0:extended", 1, true)
        then
            conformancelevel = "extended"
        elseif
            string.find(filecontents, "urn:ferd:CrossIndustryDocument:invoice:1p0:comfort", 1, true)
            or string.find(filecontents, "urn:cen.eu:en16931:2017", 1, true)
        then
            conformancelevel = "comfort" -- EN16931
        elseif
            string.find(filecontents, "urn:cen.eu:en16931:2017#compliant#urn:factur-x.eu:1p0:basic", 1, true)
            or string.find(filecontents, "urn:cen.eu:en16931:2017#compliant#urn:zugferd.de:2p0:basic", 1, true)
        then
            conformancelevel = "basic"
        elseif string.find(filecontents, "urn:factur-x.eu:1p0:basicwl", 1, true) then
            conformancelevel = "basicwl"
        elseif
            string.find(filecontents, "urn:factur-x.eu:1p0:minimum", 1, true)
            or string.find(filecontents, "urn:zugferd.de:2p0:minimum", 1, true)
        then
            conformancelevel = "minimum"
        end
        if not conformancelevel then
            main.log("error", "No ZUGFeRD conformance level found")
            return
        else
            conformancelevel = string.upper(conformancelevel)
        end

        filespecnumbers[#filespecnumbers + 1] = { filespecnum, conformancelevel, destfilename }
    else
        filespecnumbers[#filespecnumbers + 1] = { filespecnum, nil, destfilename }
    end
end

file_end("publisher/metadata.lua")

return M
