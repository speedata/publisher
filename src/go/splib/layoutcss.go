package main

/*
#include <lua.h>
*/
import "C"

import (
	"log/slog"
	"speedatapublisher/css"
	"strconv"
	"strings"
)

// layoutStylesheet holds all CSS rules given in the layout file for the
// layout commands.
var layoutStylesheet = css.NewLayoutStylesheet()

//export sdCSSAdd
func sdCSSAdd(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		csstext, ok := l.getString(1)
		if !ok {
			slog.Error("sdCSSAdd first argument must be a string (CSS text)")
			return 0
		}
		layoutStylesheet.AddCSS(csstext)
		return 0
	})
}

// parseLayoutChain decodes the element chain built in css.lua. Elements are
// separated by \x02, the fields name, class, id and position of an element
// by \x01.
func parseLayoutChain(chain string) []css.LayoutElement {
	var ret []css.LayoutElement
	for _, segment := range strings.Split(chain, "\x02") {
		fields := strings.Split(segment, "\x01")
		if len(fields) != 4 {
			slog.Error("CSS: malformed element chain", "chain", chain)
			return nil
		}
		pos, _ := strconv.Atoi(fields[3])
		ret = append(ret, css.LayoutElement{Name: fields[0], Class: fields[1], ID: fields[2], Position: pos})
	}
	return ret
}

// sdCSSMatch returns two tables for the element chain (first argument) and
// the optional pseudo element (second argument): the declarations and the
// set of properties that come from an !important declaration.
//
//export sdCSSMatch
func sdCSSMatch(L *C.lua_State) int {
	return luaEntry(L, func(l *LuaState) int {
		chain, ok := l.getString(1)
		if !ok {
			slog.Error("sdCSSMatch first argument must be a string (element chain)")
			return 0
		}
		pseudo, _ := l.getString(2)
		decls, important := layoutStylesheet.Match(parseLayoutChain(chain), pseudo)
		l.createTable(0, len(decls))
		for k, v := range decls {
			l.addStringValueToTable(-1, k, v)
		}
		l.createTable(0, len(important))
		for k := range important {
			l.addBoolValueToTable(-1, k, true)
		}
		return 2
	})
}
