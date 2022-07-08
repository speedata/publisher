/* Code generated by cmd/cgo; DO NOT EDIT. */

/* package speedatapublisher/splib */


#line 1 "cgo-builtin-export-prolog"

#include <stddef.h> /* for ptrdiff_t below */

#ifndef GO_CGO_EXPORT_PROLOGUE_H
#define GO_CGO_EXPORT_PROLOGUE_H

#ifndef GO_CGO_GOSTRING_TYPEDEF
typedef struct { const char *p; ptrdiff_t n; } _GoString_;
#endif

#endif

/* Start of preamble from import "C" comments.  */


#line 3 "splib.go"


struct splitvalues {
	char** splitted;
	int* directions;
	int count;
	int direction;
};


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
typedef __SIZE_TYPE__ GoUintptr;
typedef float GoFloat32;
typedef double GoFloat64;
typedef float _Complex GoComplex64;
typedef double _Complex GoComplex128;

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

extern char* sdParseHTMLText(const char* htmltext, const char* csstext);
extern char* sdParseHTML(const char* filename);
extern char* sdContains(const char* haystack, const char* needle);
extern char** sdTokenize(const char* text, const char* rexpr);
extern char* sdReplace(const char* text, const char* rexpr, const char* repl);
extern char* sdHtmlToXml(const char* input);
extern void sdBuildFilelist();
extern void sdAddDir(const char* cpath);
extern char* sdLookupFile(const char* cpath);
extern char** sdListFonts();
extern char* sdConvertContents(const char* contents, const char* handler);
extern char* sdConvertImage(const char* filename, const char* handler);
extern char* sdConvertSVGImage(const char* path);
extern struct splitvalues* sdSegmentize(const char* original);
extern char* sdReadXMLFile(const char* filename);

#ifdef __cplusplus
}
#endif