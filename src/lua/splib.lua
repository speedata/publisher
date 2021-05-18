local ffi = require("ffi")

module(...,package.seeall)

fileslookup = {}

ffi.cdef[[
typedef char _check_for_64_bit_pointer_matching_GoInt[sizeof(void*)==64/8 ? 1:-1];
]]

ffi.cdef[[
struct splitvalues {
    char** splitted;
    int* directions;
    int count;
    int direction;
};



typedef struct { const char *p; ptrdiff_t n; } _GoString_;

typedef signed char GoInt8;
typedef unsigned char GoUint8;
typedef short GoInt16;
typedef unsigned short GoUint16;
typedef int GoInt32;
typedef unsigned int GoUint32;
typedef long long GoInt64;
typedef unsigned long long GoUint64;
typedef GoInt64 GoInt;
typedef GoUint64 GoUint;
typedef float GoFloat32;
typedef double GoFloat64;
typedef float _Complex GoComplex64;
typedef double _Complex GoComplex128;

/*
  static assertion to make sure the file is being used on architecture
  at least with matching size of GoInt.
*/

typedef _GoString_ GoString;
typedef void *GoMap;
typedef void *GoChan;
typedef struct { void *t; void *v; } GoInterface;
typedef struct { void *data; GoInt len; GoInt cap; } GoSlice;

extern char* sdParseHTMLText(GoString htmltext, GoString csstext);
extern char* sdParseHTML(GoString filename);
extern char* sdContains(GoString haystack, GoString needle);
extern char** sdTokenize(GoString text, GoString rexpr);
extern char* sdReplace(GoString text, GoString rexpr, GoString repl);
extern char* sdHtmlToXml(GoString input);
extern void sdBuildFilelist();
extern void sdAddDir(GoString p);
extern char* sdLookupFile(GoString path);
extern char** sdListFonts();
extern char* sdConvertContents(GoString contents, GoString handler);
extern char* sdConvertImage(GoString filename, GoString handler);
extern char* sdConvertSVGImage(GoString path);
extern struct splitvalues* sdSegmentize(GoString original);
extern char* sdReadXMLFile(GoString filename);
]]

ld = ffi.load("libsplib")
errorpattern = "^%*%*err"

local function c(str)
    return ffi.new("GoString",str,#str)
end

local function parse_html_text(htmltext,csstext)
    htmltext = "<body>"..htmltext.."</body>"
    local ret = ld.sdParseHTMLText(c(htmltext),c(csstext))
    local _ret = ffi.string(ret)

    if string.match( _ret,errorpattern ) then
        err(string.gsub( _ret,errorpattern ,"" ))
        return ""
    end
    return ffi.string(ret)
end

local function parse_html(filename)
    local ret = ld.sdParseHTML(c(filename))
    local _ret = ffi.string(ret)

    if string.match( _ret,errorpattern ) then
        err(string.gsub( _ret,errorpattern ,"" ))
        return ""
    end
    return ffi.string(ret)
end

local function tokenize(dataxml,arg)
    local ret = ld.sdTokenize(c(arg[1]),c(arg[2]))
    local tbl = {}
    local i = 0
    while ret[i] ~= nil do
        tbl[#tbl + 1] = ffi.string(ret[i])
        i = i + 1
    end
    return tbl
end

local function contains(haystack,needle)
    local ret = ld.sdContains(c(haystack),c(needle))
    return ffi.string(ret)
end

local function replace(text, rexpr, repl)
    text  = tostring(text)
    rexpr = tostring(rexpr)
    repl  = tostring(repl)
    local ret = ld.sdReplace(c(text),c(rexpr),c(repl))
    return ffi.string(ret)
end

local function htmltoxml(input)
    local ret = ld.sdHtmlToXml(c(input))
    if ret == nil then
        err("sd:decode")
        return nil
    else
        return ffi.string(ret)
    end
end

local function buildfilelist()
    ld.sdBuildFilelist()
end

local function add_dir(dirname)
    ld.sdAddDir(c(dirname))
end

local function lookupfile(filename)
    local found = fileslookup[filename]
    if found then
        return found
    end

    local ret = ld.sdLookupFile(c(filename))
    local _ret = ffi.string(ret)
    if string.match( _ret,errorpattern ) then
        return nil
    end
    if _ret == "" then return nil end
    fileslookup[filename] = _ret
    return _ret
end

local function listfonts()
    local ret = ld.sdListFonts()
    local tbl = {}
    local i = 0
    while ret[i] ~= nil do
        tbl[#tbl + 1] = ffi.string(ret[i])
        i = i + 1
    end
    return tbl
end

local function convertcontents(contents,imagehandler)
    local ret = ld.sdConvertContents(c(contents),c(imagehandler))
    local _ret = ffi.string(ret)

    if string.match( _ret,errorpattern ) then
        err(string.gsub( _ret,errorpattern ,"" ))
        err("Something went wrong converting the image. Ignore the next error about the missing file name.")
        if publisher.options.verbosity > 0 then
            log("Contents %q",tostring(contents))
        end
        return
    end

    if _ret == "" then return nil end

    return _ret
end

local function convertimage(filename,imagehandler)
    local ret = ld.sdConvertImage(c(filename),c(imagehandler))
    local _ret = ffi.string(ret)

    if string.match( _ret,errorpattern ) then
        err(string.gsub( _ret,errorpattern ,"" ))
        return
    end

    if _ret == "" then return nil end

    return _ret
end


local function convertSVGImage(filename)
    local ret = ld.sdConvertSVGImage(c(filename))
    local _ret = ffi.string(ret)

    if string.match( _ret,errorpattern ) then
        err(string.gsub( _ret,errorpattern ,"" ))
        return
    end

    if _ret == "" then return nil end

    return _ret
end

local function segmentize(inputstring)
    -- struct splitvalues* sv;
    sv = ld.sdSegmentize(c(inputstring))
    local ret = {}
    for i = 0,sv.count - 1 do
        ret[#ret + 1] = {
            sv.directions[i],ffi.string(sv.splitted[i])
        }
    end
    return ret
end

local function loadxmlfile(filename)
    local ret = ld.sdReadXMLFile(c(filename))
    local _ret = ffi.string(ret)

    if string.match( _ret,errorpattern ) then
        err(string.gsub( _ret,errorpattern ,"" ))
        return
    end
    return _ret
end


return {
    parse_html    = parse_html,
    parse_html_text = parse_html_text,
    add_dir       = add_dir,
    contains      = contains,
    htmltoxml     = htmltoxml,
    replace       = replace,
    tokenize      = tokenize,
    buildfilelist = buildfilelist,
    lookupfile    = lookupfile,
    listfonts     = listfonts,
    convertcontents = convertcontents,
    convertimage    = convertimage,
    convert_svg_image = convertSVGImage,
    segmentize = segmentize,
    loadxmlfile = loadxmlfile,
}

