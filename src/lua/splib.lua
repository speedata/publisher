local ffi = require("ffi")

module(...,package.seeall)

fileslookup = {}

if os.name == "windows" then
    ffi.cdef[[
typedef char _check_for_32_bit_pointer_matching_GoInt[sizeof(void*)==32/8 ? 1:-1];
]]
    else ffi.cdef[[
typedef char _check_for_64_bit_pointer_matching_GoInt[sizeof(void*)==64/8 ? 1:-1];
]]
end

ffi.cdef[[
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

extern void addDir(GoString p0);
extern char* contains(GoString p0, GoString p1);
extern char** tokenize(GoString p0, GoString p1);
extern char* replace(GoString p0, GoString p1, GoString p2);
extern char* htmlToXml(GoString p0);
extern void buildFilelist();
extern char* lookupFile(GoString p0);
extern char** listFonts();
extern char* convertSVGImage(GoString p0);
extern char* convertContents(GoString p0, GoString p1);
extern char* convertImage(GoString p0, GoString p1);

]]

ld = ffi.load("libsplib")
errorpattern = "^%*%*err"

local function c(str)
    return ffi.new("GoString",str,#str)
end


local function tokenize(dataxml,arg)
    local ret = ld.tokenize(c(arg[1]),c(arg[2]))
    local tbl = {}
    local i = 0
    while ret[i] ~= nil do
        tbl[#tbl + 1] = ffi.string(ret[i])
        i = i + 1
    end
    return tbl
end

local function contains(haystack,needle)
    local ret = ld.contains(c(haystack),c(needle))
    return ffi.string(ret)
end

local function replace(text, rexpr, repl)
    text  = tostring(text)
    rexpr = tostring(rexpr)
    repl  = tostring(repl)
    local ret = ld.replace(c(text),c(rexpr),c(repl))
    return ffi.string(ret)
end

local function htmltoxml(input)
    local ret = ld.htmlToXml(c(input))
    if ret == nil then
        err("sd:decode")
        return nil
    else
        return ffi.string(ret)
    end
end

local function buildfilelist()
    ld.buildFilelist()
end

local function add_dir(dirname)
    ld.addDir(c(dirname))
end

local function lookupfile(filename)
    local found = fileslookup[filename]
    if found then
        return found
    end

    local ret = ld.lookupFile(c(filename))
    local _ret = ffi.string(ret)
    if string.match( _ret,errorpattern ) then
        err(string.gsub( _ret,errorpattern ,"" ))
        return
    end
    if _ret == "" then return nil end
    fileslookup[filename] = _ret
    return _ret
end

local function listfonts()
    local ret = ld.listFonts()
    local tbl = {}
    local i = 0
    while ret[i] ~= nil do
        tbl[#tbl + 1] = ffi.string(ret[i])
        i = i + 1
    end
    return tbl
end

local function convertcontents(contents,imagehandler)
    local ret = ld.convertContents(c(contents),c(imagehandler))
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
    local ret = ld.convertImage(c(filename),c(imagehandler))
    local _ret = ffi.string(ret)

    if string.match( _ret,errorpattern ) then
        err(string.gsub( _ret,errorpattern ,"" ))
        return
    end

    if _ret == "" then return nil end

    return _ret
end


local function convertSVGImage(filename)
    local ret = ld.convertSVGImage(c(filename))
    local _ret = ffi.string(ret)

    if string.match( _ret,errorpattern ) then
        err(string.gsub( _ret,errorpattern ,"" ))
        return
    end

    if _ret == "" then return nil end

    return _ret
end


return {
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
}

