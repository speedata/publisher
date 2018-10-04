local ffi = require("ffi")

module(...,package.seeall)

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

extern void Init();
extern void AddDir(GoString p0);
extern char* Contains(GoString p0, GoString p1);
extern char** Tokenize(GoString p0, GoString p1);
extern char* Replace(GoString p0, GoString p1, GoString p2);
extern char* HtmlToXml(GoString p0);
extern void BuildFilelist();
extern char* LookupFile(GoString p0);
extern char** ListFonts();

]]

ld = ffi.load("libsplib")

ld.Init()

local function c(str)
    return ffi.new("GoString",str,#str)
end


local function tokenize(dataxml,arg)
    local ret = ld.Tokenize(c(arg[1]),c(arg[2]))
    local tbl = {}
    local i = 0
    while ret[i] ~= nil do
        tbl[#tbl + 1] = ffi.string(ret[i])
        i = i + 1
    end
    return tbl
end

local function contains(haystack,needle)
    local ret = ld.Contains(c(haystack),c(needle))
    return ffi.string(ret)
end

local function replace(text, rexpr, repl)
    text  = tostring(text)
    rexpr = tostring(rexpr)
    repl  = tostring(repl)
    local ret = ld.Replace(c(text),c(rexpr),c(repl))
    return ffi.string(ret)
end

local function htmltoxml(input)
    local ret = ld.HtmlToXml(c(input))
    if ret == nil then
        err("sd:decode")
        return nil
    else
        return ffi.string(ret)
    end
end

local function buildfilelist()
    ld.BuildFilelist()
end

local function add_dir(dirname)
    ld.AddDir(c(dirname))
end

local function lookupfile(filename)
    local ret = ld.LookupFile(c(filename))
    local _ret = ffi.string(ret)
    if _ret == "" then return nil end

    return ffi.string(ret)
end

local function listfonts()
    local ret = ld.ListFonts()
    local tbl = {}
    local i = 0
    while ret[i] ~= nil do
        tbl[#tbl + 1] = ffi.string(ret[i])
        i = i + 1
    end
    return tbl
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
}

