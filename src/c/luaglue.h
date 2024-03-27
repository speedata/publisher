/* Code generated by cmd/cgo; DO NOT EDIT. */

/* package speedatapublisher/splib */


#line 1 "cgo-builtin-export-prolog"

#include <stddef.h>

#ifndef GO_CGO_EXPORT_PROLOGUE_H
#define GO_CGO_EXPORT_PROLOGUE_H

#ifndef GO_CGO_GOSTRING_TYPEDEF
typedef struct { const char *p; ptrdiff_t n; } _GoString_;
#endif

#endif

/* Start of preamble from import "C" comments.  */


#line 3 "splib.go"

#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>




#line 1 "cgo-generated-wrapper"


/* End of preamble from import "C" comments.  */


/* Start of boilerplate cgo prologue.  */
#line 1 "cgo-gcc-export-header-prolog"

#ifndef GO_CGO_PROLOGUE_H
#define GO_CGO_PROLOGUE_H

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
typedef size_t GoUintptr;
typedef float GoFloat32;
typedef double GoFloat64;
#ifdef _MSC_VER
#include <complex.h>
typedef _Fcomplex GoComplex64;
typedef _Dcomplex GoComplex128;
#else
typedef float _Complex GoComplex64;
typedef double _Complex GoComplex128;
#endif

/*
  static assertion to make sure the file is being used on architecture
  at least with matching size of GoInt.
*/
typedef char _check_for_64_bit_pointer_matching_GoInt[sizeof(void*)==64/8 ? 1:-1];

#ifndef GO_CGO_GOSTRING_TYPEDEF
typedef _GoString_ GoString;
#endif
typedef void *GoMap;
typedef void *GoChan;
typedef struct { void *t; void *v; } GoInterface;
typedef struct { void *data; GoInt len; GoInt cap; } GoSlice;

#endif

/* End of boilerplate cgo prologue.  */

#ifdef __cplusplus
extern "C" {
#endif

extern int sdParseHTMLText(lua_State* L);
extern int sdParseHTML(lua_State* L);
extern int sdMarkdown(lua_State* L);
extern int sdContains(lua_State* L);
extern int sdMatches(lua_State* L);
extern int sdTokenize(lua_State* L);
extern int sdReplace(lua_State* L);
extern int sdHtmlToXml(lua_State* L);
extern int sdBuildFilelist(lua_State* L);
extern int sdAddDir(lua_State* L);
extern int sdLookupFile(lua_State* L);
extern int sdListFonts(lua_State* L);
extern int sdConvertContents(lua_State* L);
extern int sdConvertImage(lua_State* L);
extern int sdConvertSVGImage(lua_State* L);
extern int sdSegmentizeText(lua_State* L);
extern int sdLoadXMLString(lua_State* L);
extern int sdTeardown(lua_State* L);
extern int sdError(lua_State* L);
extern int sdLog(lua_State* L);
extern int sdReloadImage(lua_State* L);
extern int sdGetErrCount(lua_State* L);
extern int sdGetWarnCount(lua_State* L);
extern int sdLoadXMLFile(lua_State* L);

#ifdef __cplusplus
}
#endif
