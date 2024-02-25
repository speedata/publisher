package main

/*
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


struct splitvalues {
	char** splitted;
	int* directions;
	int count;
	int direction;
};

#cgo CFLAGS: -I/opt/homebrew/opt/lua@5.3/include/lua
*/
import "C"

import (
	"bytes"
	"encoding/xml"
	"fmt"
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"unsafe"

	"speedatapublisher/splibaux"

	"golang.org/x/text/unicode/bidi"
)

var (
	errorpattern     = `**err`
	protocolFilename string
	verbosity        = 0
)

func init() {
	protocolFilename = os.Getenv("SP_JOBNAME") + "-protocol.xml"
	verbosity, _ = strconv.Atoi(os.Getenv("SP_VERBOSITY"))
	loglevel.Set(slog.LevelInfo)
	err := setupLog(protocolFilename)
	if err != nil {
		panic(err)
	}
}

func s2c(input string) *C.char {
	return C.CString(input)
}

// Convert a string slice to a C char* array and add a NULL pointer.
func toCharArray(s []string) **C.char {
	cArray := C.malloc(C.size_t(len(s)+1) * C.size_t(unsafe.Sizeof(uintptr(0))))
	a := (*[1<<29 - 1]*C.char)(cArray)
	for idx, substring := range s {
		a[idx] = C.CString(substring)
	}
	// add sentinel
	a[len(s)] = nil
	return (**C.char)(cArray)
}

//export sdParseHTMLText
func sdParseHTMLText(htmltextC *C.char, csstextC *C.char) *C.char {
	htmltext := C.GoString(htmltextC)
	csstext := C.GoString(csstextC)
	str, err := splibaux.ParseHTMLText(htmltext, csstext)
	if err != nil {
		return s2c(errorpattern + err.Error())
	}
	return C.CString(str)
}

//export sdParseHTML
func sdParseHTML(filenameC *C.char) *C.char {
	filename := C.GoString(filenameC)
	str, err := splibaux.ParseHTML(filename)
	if err != nil {
		return s2c(errorpattern + err.Error())
	}
	return C.CString(str)
}

//export sdContains
func sdContains(haystackC *C.char, needleC *C.char) *C.char {
	haystack := C.GoString(haystackC)
	needle := C.GoString(needleC)
	var ret string
	if strings.Contains(haystack, needle) {
		ret = "true"
	} else {
		ret = "false"
	}
	return C.CString(ret)
}

//export sdMatches
func sdMatches(textC, rexprC, flags *C.char) int {
	text := C.GoString(textC)
	reString := C.GoString(rexprC)
	re, err := regexp.Compile(reString)
	if err != nil {
		return 0
	}
	r := re.MatchString(text)
	if r {
		return 1
	}
	return 0
}

//export sdTokenize
func sdTokenize(textC, rexprC *C.char) **C.char {
	text := C.GoString(textC)
	rexpr := C.GoString(rexprC)

	r := regexp.MustCompile(rexpr)
	idx := r.FindAllStringIndex(text, -1)
	pos := 0
	var res []string
	for _, v := range idx {
		res = append(res, text[pos:v[0]])
		pos = v[1]
	}
	res = append(res, text[pos:])
	return toCharArray(res)
}

//export sdReplace
func sdReplace(textC, rexprC, replC *C.char) *C.char {
	text := C.GoString(textC)
	rexpr := C.GoString(rexprC)
	repl := C.GoString(replC)

	r := regexp.MustCompile(rexpr)

	// xpath uses $12 for $12 or $1, depending on the existence of $12 or $1.
	// go on the other hand uses $12 for $12 and never for $1, so you have to write
	// $1 as ${1} if there is text after the $1.
	// We escape the $n backwards to prevent expansion of $12 to ${1}2
	for i := r.NumSubexp(); i > 0; i-- {
		// first create rexepx that match "$i"
		x := fmt.Sprintf(`\$(%d)`, i)
		nummatcher := regexp.MustCompile(x)
		repl = nummatcher.ReplaceAllString(repl, fmt.Sprintf(`$${%d}`, i))
	}
	str := r.ReplaceAllString(text, repl)
	return C.CString(str)
}

//export sdHtmlToXml
func sdHtmlToXml(inputC *C.char) *C.char {
	input := C.GoString(inputC)
	input = "<toplevel·toplevel>" + input + "</toplevel·toplevel>"
	r := strings.NewReader(input)
	var w bytes.Buffer

	enc := xml.NewEncoder(&w)
	dec := xml.NewDecoder(r)

	dec.Strict = false
	dec.AutoClose = xml.HTMLAutoClose
	dec.Entity = xml.HTMLEntity
	for {
		t, err := dec.Token()
		if err == io.EOF {
			break
		}
		if err != nil {
			enc.Flush()
			return nil
		}
		switch v := t.(type) {
		case xml.StartElement:
			if v.Name.Local != "toplevel·toplevel" {
				enc.EncodeToken(t)
			}
		case xml.EndElement:
			if v.Name.Local != "toplevel·toplevel" {
				enc.EncodeToken(t)
			}
		case xml.CharData:
			enc.EncodeToken(t)
		default:
			// fmt.Println(v)
		}
	}
	enc.Flush()
	return C.CString(w.String())
}

//export sdBuildFilelist
func sdBuildFilelist() {
	paths := filepath.SplitList(os.Getenv("PUBLISHER_BASE_PATH"))
	if fp := os.Getenv("SP_FONT_PATH"); fp != "" {
		for _, p := range filepath.SplitList(fp) {
			paths = append(paths, p)
		}
	}
	for _, p := range filepath.SplitList(os.Getenv("SP_EXTRA_DIRS")) {
		paths = append(paths, p)
	}
	splibaux.BuildFilelist(paths)
}

//export sdAddDir
func sdAddDir(cpath *C.char) {
	path := C.GoString(cpath)
	splibaux.AddDir(path)
}

//export sdLookupFile
func sdLookupFile(L *C.lua_State) int {
	l := newLuaState(L)
	fn, ok := l.getString(1)
	if !ok {
		return 0
	}
	slog.Debug("Lookup file", "filename", fn)
	ret, err := splibaux.GetFullPath(fn)
	if err != nil {
		slog.Error("internal error", "where", "splibaux.GetFullPath", "argument", fn, "message", err.Error())
		return 0
	}
	l.pushString(ret)
	return 1
}

//export sdListFonts
func sdListFonts() **C.char {
	res := splibaux.ListFonts()
	return toCharArray(res)
}

//export sdConvertContents
func sdConvertContents(contentsC, handlerC *C.char) *C.char {
	contents := C.GoString(contentsC)
	handler := C.GoString(handlerC)
	ret, err := splibaux.ConvertContents(contents, handler)
	if err != nil {
		return s2c(errorpattern + err.Error())
	}
	return s2c(ret)
}

//export sdConvertImage
func sdConvertImage(filenameC, handlerC *C.char) *C.char {
	filename := C.GoString(filenameC)
	handler := C.GoString(handlerC)

	ret, err := splibaux.ConvertImage(filename, handler)
	if err != nil {
		return s2c(errorpattern + err.Error())
	}
	return s2c(ret)
}

//export sdConvertSVGImage
func sdConvertSVGImage(pathC *C.char) *C.char {
	path := C.GoString(pathC)
	ret, err := splibaux.ConvertSVGImage(path)
	if err != nil {
		return s2c(errorpattern + err.Error())
	}
	return s2c(ret)
}

//export sdSegmentize
func sdSegmentize(originalC *C.char) *C.struct_splitvalues {
	inputstring := C.GoString(originalC)
	p := bidi.Paragraph{}
	p.SetString(inputstring)
	ordering, err := p.Order()
	if err != nil {
		panic(err)
	}
	nr := ordering.NumRuns()

	cLenghtsInt := C.malloc(C.size_t(nr) * C.size_t(unsafe.Sizeof(C.int(0))))
	cSplittedStrings := C.malloc(C.size_t(nr) * C.size_t(unsafe.Sizeof(uintptr(0))))
	returnStruct := (*C.struct_splitvalues)(C.malloc(C.size_t(unsafe.Sizeof(C.struct_splitvalues{}))))

	ints := (*[1<<15 - 1]C.int)(cLenghtsInt)[:nr:nr]
	a := (*[1<<15 - 1]*C.char)(cSplittedStrings)

	for i := 0; i < nr; i++ {
		r := ordering.Run(i)
		ints[i] = C.int(int(r.Direction()))
		a[i] = C.CString(r.String())
	}

	returnStruct.splitted = (**C.char)(cSplittedStrings)
	returnStruct.directions = (*C.int)(cLenghtsInt)
	returnStruct.count = C.int(nr)

	return returnStruct
}

//export sdLoadXMLString
func sdLoadXMLString(L *C.lua_State) int {
	l := newLuaState(L)
	str, ok := l.getString(1)
	if !ok {
		slog.Error("loadxmlstring first argument should be a string")
		return 0
	}
	sr := strings.NewReader(str)

	l.createTable(0, 0)
	l.addKeyValueToTable(-1, ".__type", "document")
	err := l.readXMLFile(sr, 1)
	if err != nil {
		slog.Error("Parsing XML file failed", "message", err.Error())
		return 0
	}

	return 1
}

//export sdTeardown
func sdTeardown() {
	err := teardownLog()
	if err != nil {
		slog.Error("internal error", "where", "sdTeardown", "message", err.Error())
	}
}

//export sdLog
func sdLog(L *C.lua_State) int {
	l := newLuaState(L)
	level, ok := l.getString(1)
	if !ok {
		return 0
	}
	message, ok := l.getString(2)
	if !ok {
		return 0
	}

	extraArguments := []any{}
	max := l.getTop()
	for i := 3; i <= max; i++ {
		if arg, ok := l.getAny(i); ok {
			extraArguments = append(extraArguments, arg)
		}
	}
	switch level {
	case "notice":
		slog.Log(nil, LevelNotice, message, extraArguments...)
	case "info":
		slog.Info(message, extraArguments...)
	case "debug":
		slog.Debug(message, extraArguments...)
	case "warning", "warn":
		slog.Warn(message, extraArguments...)
	case "error":
		slog.Error(message, extraArguments...)
	}

	return 0
}

//export sdReloadImage
func sdReloadImage(L *C.lua_State) int {
	l := LuaState{L}
	fn, ok := l.getStringTable(1, "filename")
	if !ok {
		slog.Error("internal error", "where", "sdReloadImage", "message", "filename is not a string")
		return 0
	}
	wd, ok := l.getIntTable(1, "width")
	if !ok {
		slog.Error("internal error", "where", "sdReloadImage", "message", "width is not a number")
		return 0
	}
	ht, ok := l.getIntTable(1, "height")
	if !ok {
		slog.Error("internal error", "where", "sdReloadImage", "message", "height is not a number")
		return 0
	}
	imagetype, ok := l.getStringTable(1, "imagetype")
	if !ok {
		slog.Error("internal error", "where", "sdReloadImage", "message", "imagetype is not a string")
		return 0
	}

	newfn, err := splibaux.ResizeImage(fn, imagetype, wd, ht)
	if err != nil {
		slog.Error("internal error", "where", "sdReloadImage", "message", err)
		return 0
	}
	l.pushString(newfn)
	return 1
}

//export sdGetErrCount
func sdGetErrCount() int {
	return errCount
}

//export sdGetWarnCount
func sdGetWarnCount() int {
	return warnCount
}

//export sdLoadXMLFile
func sdLoadXMLFile(L *C.lua_State) int {
	l := newLuaState(L)
	err := l.buildXMLTable()
	if err != nil {
		return 0
	}
	return 1
}

func main() {}
