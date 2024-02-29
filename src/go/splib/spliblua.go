package main

import (
	"fmt"
	"log/slog"
	"unsafe"
)

/*
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

*/
import "C"

type LuaState struct {
	l *C.lua_State
}

func newLuaState(L *C.lua_State) LuaState {
	return LuaState{L}
}

func (l *LuaState) getTop() int {
	return int(C.lua_gettop(l.l))
}

func (l *LuaState) setTop(n int) {
	C.lua_settop(l.l, C.int(n))
}

func (l *LuaState) getGlobal(name string) lType {
	i := C.lua_getglobal(l.l, C.CString(name))
	return lType(i)
}

// pop removes n elements from the stack
func (l *LuaState) pop(n int) {
	l.setTop(-n - 1)
}

func (l *LuaState) rotate(idx, n int) {
	C.lua_rotate(l.l, C.int(idx), C.int(n))
}

type lType int

const (
	luaTNil           lType = C.LUA_TNIL
	luaTNumber              = C.LUA_TNUMBER
	luaTBoolean             = C.LUA_TBOOLEAN
	luaTString              = C.LUA_TSTRING
	luaTTable               = C.LUA_TTABLE
	luaTFunction            = C.LUA_TFUNCTION
	luaTUserdata            = C.LUA_TUSERDATA
	luaTThread              = C.LUA_TTHREAD
	luaTLightuserdata       = C.LUA_TLIGHTUSERDATA
)

func (lt lType) String() string {
	switch lt {
	case luaTNil:
		return "nil"
	case luaTNumber:
		return "number"
	case luaTBoolean:
		return "boolean"
	case luaTString:
		return "string"
	case luaTTable:
		return "table"
	case luaTFunction:
		return "function"
	case luaTUserdata:
		return "userdata"
	case luaTThread:
		return "thread"
	case luaTLightuserdata:
		return "lightuserdata"
	}
	return "--"
}

func (l *LuaState) luaType(idx int) lType {
	return (lType(C.lua_type(l.l, C.int(idx))))
}

// Removes the element at the given valid index, shifting down the elements
// above this index to fill the gap. This function cannot be called with a
// pseudo-index, because a pseudo-index is not an actual stack position.
func (l *LuaState) remove(n int) {
	l.rotate(n, -1)
	l.pop(1)
}

func (l *LuaState) pushString(str string) {
	cStr := C.CString(str)
	C.lua_pushstring(l.l, cStr)
	C.free(unsafe.Pointer(cStr))
}

func (l *LuaState) pushInt(i int) {
	C.lua_pushinteger(l.l, C.longlong(i))
}

func (l *LuaState) getAny(idx int) (any, bool) {
	if l.getTop() == 0 {
		return nil, false
	}

	switch l.luaType(idx) {
	case luaTString:
		return l.getString(idx)
	case luaTNumber:
		return l.getNumber(idx)
	default:
		slog.Error("not implemented yet", "where", "getAny", "arg", l.luaType(idx))
	}

	return nil, false
}

func (l *LuaState) getInt(idx int) (int, bool) {
	if l.getTop() == 0 {
		return 0, false
	}
	if l.luaType(idx) == luaTNumber {
		var isnum C.int
		dbl := C.lua_tonumberx(l.l, C.int(idx), &isnum)
		return int(dbl), true
	}
	return 0, false
}

func (l *LuaState) getNumber(idx int) (float64, bool) {
	if l.getTop() == 0 {
		return 0, false
	}
	if l.luaType(idx) == luaTNumber {
		var isnum C.int
		dbl := C.lua_tonumberx(l.l, C.int(idx), &isnum)
		return float64(dbl), true
	}
	return 0, false
}

// getString returns the string at the index and true, if the value is a string,
// otherwise the empty string and false. The stack is unchanged.
func (l *LuaState) getString(idx int) (string, bool) {
	if l.getTop() == 0 {
		return "", false
	}
	if l.luaType(idx) == luaTString {
		str := C.lua_tolstring(l.l, C.int(idx), nil)
		return C.GoString(str), true
	}
	return "", false
}

// getField pushes the value of the table key onto the stack. The table is at
// index idx.
func (l *LuaState) getField(idx int, key string) {
	C.lua_getfield(l.l, C.int(idx), C.CString(key))
}

// getStringTable returns the string value of the table entry t[key] of the
// table t at index idx. If the value at t[key] is not a string, it returns the
// empty string and false, otherwise the value and true.
func (l *LuaState) getStringTable(idx int, key string) (string, bool) {
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

func (l *LuaState) getIntTable(idx int, key string) (int, bool) {
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

func (l *LuaState) createTable(seq int, other int) int {
	C.lua_createtable(l.l, 0, 0)
	return l.getTop()
}

// Similar to lua_settable, but does a raw assignment (i.e., without
// metamethods).
func (l *LuaState) rawSet(index int) {
	C.lua_rawset(l.l, C.int(index))
}

// len returns the length of the item at the index. The stack is unchanged.
func (l *LuaState) len(index int) int {
	C.lua_len(l.l, C.int(index))
	i, _ := l.getInt(-1)
	l.pop(1)
	return i
}

func (l *LuaState) rawGet(index int) lType {
	return lType(C.lua_rawget(l.l, C.int(index)))
}

// Pushes onto the stack the value t[n], where t is the table at the given index. The access is raw, that is, it does not invoke the __index metamethod.
// Returns the type of the pushed value.
func (l *LuaState) rawGetI(index int, n int) lType {
	return lType(C.lua_rawgeti(l.l, C.int(index), C.longlong(n)))
}

// setTable oes the equivalent to t[k] = v, where t is the value at the given
// index, v is the value at the top of the stack, and k is the value just below
// the top.
//
// This function pops both the key and the value from the stack. As in Lua, this
// function may trigger a metamethod for the "newindex" event (see §2.4).
func (l *LuaState) setTable(index int) {
	C.lua_rawset(l.l, C.int(index))
}

func (l *LuaState) rawSetI(index int, i int) {
	C.lua_rawseti(l.l, C.int(index), C.longlong(i))
}

func (l *LuaState) stackDump() {
	top := l.getTop()
	fmt.Println("~~> stack", top, "<~~")
	for i := 1; i <= top; i++ {
		fmt.Print(i, " -", top-i+1, " ")
		luaTyp := C.lua_type(l.l, C.int(i))
		switch int(luaTyp) {
		case C.LUA_TSTRING:
			str, _ := l.getString(i)
			fmt.Println("string:", str)
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

func (l *LuaState) pushAny(value any) {
	switch t := value.(type) {
	case string:
		l.pushString(t)
	case int:
		l.pushInt(t)
	default:
		fmt.Printf("~~> t %#T\n", t)
		panic("l.pushAny()")
	}
}

// addKeyValueToTable adds the key and value to the table at the given index.
func (l *LuaState) addKeyValueToTable(index int, key any, value any) {
	l.pushAny(key)
	l.pushAny(value)

	if index < 0 {
		index = index - 2
	}
	l.rawSet(index)
}
