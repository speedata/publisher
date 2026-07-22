package main

/*
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


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
	"runtime"
	"speedatapublisher/css"
	"speedatapublisher/splib/csslua"
	"speedatapublisher/splibaux"
	"speedatapublisher/text/unicode/bidi"
	"strconv"
	"strings"
	"time"

	"github.com/alecthomas/chroma/v2/formatters/html"
	"github.com/yuin/goldmark"
	highlighting "github.com/yuin/goldmark-highlighting/v2"
	"github.com/yuin/goldmark/extension"
	"golang.org/x/text/cases"
	"golang.org/x/text/language"
)

var (
	protocolFilename string
	statusFilename   string
	verbosity        = 0
	now              time.Time
)

func init() {
	jobname := os.Getenv("SP_JOBNAME")
	if jobname == "" {
		jobname = "publisher"
	}
	protocolFilename = jobname + "-protocol.xml"
	statusFilename = jobname + ".status"
	verbosity, _ = strconv.Atoi(os.Getenv("SP_VERBOSITY"))

	loglevel.Set(slog.LevelInfo)
	err := setupLog(protocolFilename)
	if err != nil {
		panic(err)
	}
	err = setupStatusfile(statusFilename)
	if err != nil {
		panic(err)
	}
	now = time.Now()
}

// luaEntry is the entry point for Lua functions. It locks the OS thread to ensure
// that the Lua state is not accessed from multiple threads at the same time.
// It also recovers from panics in Lua functions to prevent the program from crashing.
func luaEntry(L *C.lua_State, f func(l *LuaState) int) (ret int) {
	runtime.LockOSThread()
	defer runtime.UnlockOSThread()
	// Hard-guard against panics in Lua functions.
	// This is necessary because Lua does not have a way to recover from panics.
	defer func() {
		if r := recover(); r != nil {
			slog.Error("panic in Lua glue", "panic", r)
			ret = 0
		}
	}()
	return f(&LuaState{L})
}

//export sdParseRawHTMLText
func sdParseRawHTMLText(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		htmltext, ok := l.getString(1)
		if !ok {
			slog.Error("sdParseRawHTMLText first argument must be a string (HTML text)")
			return 0
		}
		csstext, ok := l.getString(2)
		if !ok {
			slog.Error("sdParseRawHTMLText second argument must be a string (CSS text)")
			return 0
		}

		c := css.NewCSSParser()
		cssResult, err := c.ParseHTMLFragment(htmltext, csstext)
		if err != nil {
			slog.Error("sdParseRawHTMLText could not parse HTML", "msg", err.Error())
			return 0
		}

		csslua.Render(luaAdapter{l: l}, cssResult)
		return 1
	})
}

//export sdParseHTMLText
func sdParseHTMLText(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		htmltext, ok := l.getString(1)
		if !ok {
			slog.Error("sdParseHTMLText first argument must be a string (HTML text)")
			return 0
		}
		csstext, ok := l.getString(2)
		if !ok {
			slog.Error("sdParseHTMLText second argument must be a string (CSS text)")
			return 0
		}
		c := css.NewCSSParser()
		cssresult, err := c.ParseHTMLFragment("<body>"+htmltext+"</body>", csstext)
		if err != nil {
			slog.Error("sdParseRawHTMLText could not parse HTML", "msg", err.Error())
			return 0
		}

		csslua.Render(luaAdapter{l: l}, cssresult)
		return 1
	})
}

//export sdMarkdown
func sdMarkdown(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		mdExtensions := []goldmark.Extender{}
		hlOptions := []highlighting.Option{}
		htmlOptions := []html.Option{}
		mdExtensionsStr := []string{}
		mdText, ok := l.getString(1)
		if !ok {
			slog.Error("markdown needs string as first argument")
			return 0
		}
		useHighlight := false
		l.getGlobal("splib")
		l.pushString("markdownextensions")
		if l.rawGet(-2) == luaTTable {
			length := l.len(-1)
			for i := 1; i <= length; i++ {
				l.rawGetI(-1, i)
				arg, ok := l.getString(-1)
				if ok {
					switch {
					case arg == "gfm":
						mdExtensions = append(mdExtensions, extension.GFM)
						mdExtensionsStr = append(mdExtensionsStr, arg)
					case arg == "table":
						mdExtensions = append(mdExtensions, extension.Table)
						mdExtensionsStr = append(mdExtensionsStr, arg)
					case arg == "strikethrough":
						mdExtensions = append(mdExtensions, extension.Strikethrough)
						mdExtensionsStr = append(mdExtensionsStr, arg)
					case arg == "linkify":
						mdExtensions = append(mdExtensions, extension.Linkify)
						mdExtensionsStr = append(mdExtensionsStr, arg)
					case arg == "definitionlist":
						mdExtensions = append(mdExtensions, extension.DefinitionList)
						mdExtensionsStr = append(mdExtensionsStr, arg)
					case arg == "footnote":
						mdExtensions = append(mdExtensions, extension.Footnote)
						mdExtensionsStr = append(mdExtensionsStr, arg)
					case arg == "typographer":
						mdExtensions = append(mdExtensions, extension.Typographer)
						mdExtensionsStr = append(mdExtensionsStr, arg)
					case arg == "cjk":
						mdExtensions = append(mdExtensions, extension.Linkify)
						mdExtensionsStr = append(mdExtensionsStr, arg)
					case arg == "highlight":
						useHighlight = true
						mdExtensionsStr = append(mdExtensionsStr, arg)
					case strings.HasPrefix(arg, "hlstyle_"):
						suffix, _ := strings.CutPrefix(arg, "hlstyle_")
						hlOptions = append(hlOptions, highlighting.WithStyle(suffix))
					case strings.HasPrefix(arg, "hloption_"):
						suffix, _ := strings.CutPrefix(arg, "hloption_")
						switch suffix {
						case "withclasses":
							htmlOptions = append(htmlOptions, html.WithClasses(true))
						}
					default:
						slog.Warn("markdown extension not supported", "extension", arg)
					}
					l.pop(1)
				}
			}
		}
		if useHighlight {
			hlOptions = append(hlOptions, highlighting.WithFormatOptions(htmlOptions...))
			mdExtensions = append(mdExtensions, highlighting.NewHighlighting(hlOptions...))
		}
		slog.Debug("Render markdown with extensions", "extensions", strings.Join(mdExtensionsStr, ", "))
		gm := goldmark.New(goldmark.WithExtensions(mdExtensions...))
		var out bytes.Buffer
		err := gm.Convert([]byte(mdText), &out)
		if err != nil {
			slog.Error("Could not convert text to markdown", "message", err.Error())
			return 0
		}
		l.pushString(out.String())
		return 1
	})
}

//export sdContains
func sdContains(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		haystack, ok := l.getString(1)
		if !ok {
			slog.Error("sdContains requires two string arguments")
			return 0
		}
		needle, ok := l.getString(2)
		if !ok {
			slog.Error("sdContains requires two string arguments")
			return 0
		}
		l.pushBool(strings.Contains(haystack, needle))
		return 1
	})
}

//export sdMatches
func sdMatches(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		text, ok := l.getString(1)
		if !ok {
			slog.Error("sdMatches first argument must be a string (the text)")
			return 0
		}
		r, ok := l.getString(2)
		if !ok {
			slog.Error("sdMatches second argument must be a string (the regular expression)")
			return 0
		}
		re, err := regexp.Compile(r)
		if err != nil {
			slog.Error("Could not compile regular expression", "msg", err.Error(), "regexp", r)
			return 0
		}
		l.pushBool(re.MatchString(text))
		return 1
	})
}

//export sdTokenize
func sdTokenize(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		text, ok := l.getString(1)
		if !ok {
			slog.Error("sdTokenize first argument must be a string (the text)")
			return 0
		}
		r, ok := l.getString(2)
		if !ok {
			slog.Error("sdTokenize second argument must be a string (the regular expression)")
			return 0
		}
		re, err := regexp.Compile(r)
		if err != nil {
			slog.Error("sdTokenize could not compile regular expression", "msg", err.Error())
			return 0
		}
		idx := re.FindAllStringIndex(text, -1)
		pos := 0
		var res []string
		for _, v := range idx {
			res = append(res, text[pos:v[0]])
			pos = v[1]
		}
		res = append(res, text[pos:])
		l.createTable(len(res), 0)
		for i, str := range res {
			l.pushString(str)
			l.rawSetI(-2, i+1)
		}

		return 1
	})
}

//export sdReplace
func sdReplace(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		text, ok := l.getString(1)
		if !ok {
			slog.Error("sdReplace first argument must be a string (the text)")
			return 0
		}
		r, ok := l.getString(2)
		if !ok {
			slog.Error("sdReplace second argument must be a string (the regular expression)")
			return 0
		}
		repl, ok := l.getString(3)
		if !ok {
			slog.Error("sdReplace third argument must be a string (the regular expression)")
			return 0
		}

		re, err := regexp.Compile(r)
		if err != nil {
			slog.Error("sdReplace could not compile regular expression", "msg", err.Error())
			return 0
		}

		// xpath uses $12 for $12 or $1, depending on the existence of $12 or $1.
		// go on the other hand uses $12 for $12 and never for $1, so you have to write
		// $1 as ${1} if there is text after the $1.
		// We escape the $n backwards to prevent expansion of $12 to ${1}2
		for i := re.NumSubexp(); i > 0; i-- {
			// first create rexepx that match "$i"
			x := fmt.Sprintf(`\$(%d)`, i)
			nummatcher := regexp.MustCompile(x)
			repl = nummatcher.ReplaceAllString(repl, fmt.Sprintf(`$${%d}`, i))
		}
		str := re.ReplaceAllString(text, repl)
		l.pushString(str)
		return 1
	})
}

//export sdUpperCase
func sdUpperCase(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		text, ok := l.getString(1)
		if !ok {
			slog.Error("sdUpperCase first argument must be a string (the text)")
			return 0
		}
		l.pushString(cases.Upper(language.Und).String(text))
		return 1
	})
}

//export sdLowerCase
func sdLowerCase(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		text, ok := l.getString(1)
		if !ok {
			slog.Error("sdLowerCase first argument must be a string (the text)")
			return 0
		}
		l.pushString(cases.Lower(language.Und).String(text))
		return 1
	})
}

//export sdHtmlToXml
func sdHtmlToXml(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		input, ok := l.getString(1)
		if !ok {
			slog.Error("sdHtmlToXml first argument must be a string (the text)")
			return 0
		}
		rawInput := input
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
				slog.Error("html to xml", "message", err.Error(), "source", rawInput)
				return 0
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
		l.pushString(w.String())
		return 1
	})
}

//export sdBuildFilelist
func sdBuildFilelist(L *C.lua_State) int {
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
	return 0
}

//export sdAddDir
func sdAddDir(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		fn, ok := l.getString(1)
		if !ok {
			slog.Error("sdAddDir requires one argument: a string")
			return 0
		}
		splibaux.AddDir(fn)
		return 0
	})
}

//export sdLookupFile
func sdLookupFile(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
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
		if ret == "" {
			return 0
		}
		l.pushString(ret)
		return 1
	})
}

//export sdListFonts
func sdListFonts(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		fonts := splibaux.ListFonts()
		l.createTable(len(fonts), 0)
		for i, entry := range fonts {
			l.pushString(entry)
			l.rawSetI(-2, i+1)
		}
		return 1
	})
}

//export sdConvertContents
func sdConvertContents(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		contents, ok := l.getString(1)
		if !ok {
			slog.Error("First argument to sdConvertContents must be a string")
			return 0
		}
		handler, ok := l.getString(2)
		if !ok {
			slog.Error("second argument to sdConvertContents must be a string")
			return 0
		}
		ret, err := splibaux.ConvertContents(contents, handler)
		if err != nil {
			slog.Error("sdConvertContents", "msg", err.Error())
		}
		l.pushString(ret)
		return 1
	})
}

//export sdConvertImage
func sdConvertImage(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		filename, ok := l.getString(1)
		if !ok {
			slog.Error("First argument to sdConvertImage must be a string")
			return 0
		}
		handler, ok := l.getString(2)
		if !ok {
			slog.Error("second argument to sdConvertImage must be a string")
			return 0
		}
		ret, err := splibaux.ConvertImage(filename, handler)
		if err != nil {
			slog.Error("ConvertImage", "msg", err.Error())
			return 0
		}
		l.pushString(ret)
		return 1
	})
}

//export sdConvertSVGImage
func sdConvertSVGImage(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		filename, ok := l.getString(1)
		if !ok {
			slog.Error("First argument to sdConvertSVGImage must be a string")
			return 0
		}

		ret, err := splibaux.ConvertSVGImage(filename)
		if err != nil {
			slog.Error("ConvertSVGImage", "errmsg", err.Error())
			return 0
		}
		l.pushString(ret)
		return 1
	})
}

//export sdSegmentizeText
func sdSegmentizeText(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		str, ok := l.getString(1)
		if !ok {
			slog.Error("sdSegmentizeText: first argument must be a string")
			return 0
		}
		dir, ok := l.getInt(2)
		defaultDir := bidi.Neutral
		if ok {
			switch dir {
			case 0:
				// ok, neutral
			case 1:
				defaultDir = bidi.LeftToRight
			case 2:
				defaultDir = bidi.RightToLeft
			}
		}
		p := bidi.Paragraph{}
		_, err := p.SetString(str, bidi.DefaultDirection(defaultDir))
		if err != nil {
			slog.Error("sdSegmentize SetString", "errmsg", err.Error())
			return 0
		}
		ordering, err := p.Order()
		if err != nil {
			slog.Error("sdSegmentizeText p.Order", "msg", err.Error())
			return 0
		}

		nr := ordering.NumRuns()
		l.createTable(nr, 0)
		for i := 0; i < nr; i++ {
			l.createTable(2, 0)
			r := ordering.Run(i)
			switch r.Direction() {
			case bidi.LeftToRight:
				l.pushInt(0)
			case bidi.RightToLeft:
				l.pushInt(1)
			}
			l.rawSetI(-2, 1)
			l.pushString(r.String())
			l.rawSetI(-2, 2)
			l.rawSetI(-2, i+1)
		}

		return 1
	})
}

//export sdLoadXMLString
func sdLoadXMLString(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		str, ok := l.getString(1)
		if !ok {
			slog.Error("loadxmlstring first argument should be a string")
			return 0
		}
		sr := strings.NewReader(str)

		l.createTable(0, 0)
		l.addStringValueToTable(-1, ".__type", "document")
		err := l.readXMLFile(sr, 1)
		if err != nil {
			slog.Error("Parsing XML file failed", "message", err.Error())
			return 0
		}

		return 1
	})
}

//export sdTeardown
func sdTeardown(L *C.lua_State) int {
	_ = L
	err := teardownLog()
	if err != nil {
		fmt.Println("Internal error", err.Error())
	}
	return 0
}

//export sdError
func sdError(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		l.getGlobal("publisher")
		errorcode, ok := l.getIntTable(-1, "errorcode")
		_ = errorcode
		if ok {
			if errorcode < 1 {
				l.pushString("errorcode")
				l.pushInt(1)
				l.rawSet(-3)
			}
		}
		l.pop(1)
		message, ok := l.getString(1)
		if !ok {
			return 0
		}

		extraArguments := []any{}
		max := l.getTop()
		for i := 2; i <= max; i++ {
			if arg, ok := l.getAny(i); ok {
				extraArguments = append(extraArguments, arg)
			}
		}
		slog.Error(message, extraArguments...)

		return 0
	})
}

//export sdLog
func sdLog(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
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
				if arg != nil {
					extraArguments = append(extraArguments, arg)
				}
			}
		}
		switch level {
		case "message", "notice":
			slog.Log(nil, LevelMessage, message, extraArguments...)
		case "info":
			slog.Info(message, extraArguments...)
		case "debug":
			slog.Debug(message, extraArguments...)
		case "warning", "warn":
			slog.Warn(message, extraArguments...)
		case "error":
			slog.Error(message, extraArguments...)
		default:
			slog.Error("internal error", "unknown log level", level)
		}

		return 0
	})
}

//export sdReloadImage
func sdReloadImage(L *C.lua_State) int {
	// arguments are
	// filename, width, height, imagetype, and an optional resizehandler
	// returns new filename
	// uses splibaux.ResizeImage

	return luaEntry(L, func(l *LuaState) int {
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
		// resizehandler is optional
		resizehandler, ok := l.getStringTable(1, "resizehandler")
		if !ok {
			resizehandler = ""
		}

		newfn, err := splibaux.ResizeImage(fn, imagetype, wd, ht, resizehandler)
		if err != nil {
			slog.Error("internal error", "where", "sdReloadImage", "message", err)
			return 0
		}
		l.pushString(newfn)
		return 1
	})
}

//export sdGetErrCount
func sdGetErrCount(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		l.pushInt(errCount)
		return 1
	})
}

//export sdGetWarnCount
func sdGetWarnCount(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		l.pushInt(warnCount)
		return 1
	})
}

//export sdLoadXMLFile
func sdLoadXMLFile(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		err := l.buildXMLTable()
		if err != nil {
			slog.Error(err.Error(), "where", "sdLoadXMLFile")
			return 0
		}
		return 1
	})
}

func main() {}
