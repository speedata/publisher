package main

import "fmt"

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

type LuaState struct {
	l *C.lua_State
}

func (l *LuaState) getTop() int {
	top := int(C.lua_gettop(l.l))
	return top
}

func (l *LuaState) pop(n int) {
	C.lua_settop(l.l, C.int(-n-1))
}

func (l *LuaState) pushString(str string) {
	C.lua_pushstring(l.l, C.CString(str))
}

// getField pushes the value of the table key onto the stack. The table is at
// index idx.
func (l *LuaState) getField(idx int, key string) {
	C.lua_getfield(l.l, C.int(idx), C.CString(key))
}

func (l *LuaState) getTableEntry(idx int, key string) any {
	l.getField(idx, key)
	defer l.pop(1)
	luaTyp := C.lua_type(l.l, C.int(-1))
	switch int(luaTyp) {
	case C.LUA_TNIL:
		return nil
	case C.LUA_TBOOLEAN:
		ok := C.lua_toboolean(l.l, C.int(-1))
		return C.int(ok) == 1
	case C.LUA_TNUMBER:
		var isnum C.int
		dbl := C.lua_tonumberx(l.l, C.int(-1), &isnum)
		return float64(dbl)
	case C.LUA_TSTRING:
	case C.LUA_TTABLE:

	}
	fmt.Println(luaTyp)
	return nil
}

// getString returns the string value of the table entry t[key] of the table t
// at index idx. If the value at t[key] is not a string, it returns the empty
// string and false, otherwise the value and true.
func (l *LuaState) getString(idx int, key string) (string, bool) {
	l.getField(idx, key)
	defer l.pop(1)
	luaTyp := C.lua_type(l.l, C.int(-1))
	if luaTyp == C.LUA_TSTRING {
		var length C.size_t
		str := C.lua_tolstring(l.l, C.int(-1), &length)
		return C.GoString(str), true
	}

	return "", false
}

func (l *LuaState) getInt(idx int, key string) (int, bool) {
	l.getField(idx, key)
	defer l.pop(1)
	luaTyp := C.lua_type(l.l, C.int(-1))
	if luaTyp == C.LUA_TNUMBER {
		var isnum C.int
		dbl := C.lua_tonumberx(l.l, C.int(-1), &isnum)
		return int(dbl), true
	}

	return 0, false
}

func (l *LuaState) stackDump() {
	top := l.getTop()
	fmt.Println("~~> stack", top, "<~~")
	for i := 1; i <= top; i++ {
		fmt.Print(i, " ")
		luaTyp := C.lua_type(l.l, C.int(i))
		switch int(luaTyp) {
		case C.LUA_TSTRING:
			fmt.Println("string")
		case C.LUA_TBOOLEAN:
			fmt.Println("boolean")
		case C.LUA_TNIL:
			fmt.Println("nil")
		case C.LUA_TTABLE:
			fmt.Println("table")
		default:
			typName := C.lua_typename(l.l, C.int(luaTyp))
			fmt.Println(C.GoString(typName))
		}
	}
	fmt.Println("~~> end stack <~~")
}
