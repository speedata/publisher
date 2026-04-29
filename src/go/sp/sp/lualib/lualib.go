// Package lualib bundles small helpers used by the Go-side Lua modules
// (luacsv, luaxml, luaxlsx, ...) when working with the stack-based
// speedata/go-lua API.
package lualib

import (
	lua "github.com/speedata/go-lua"
)

// PushError clears the stack and pushes (false, errormessage). Returns 2 so
// it can be used directly as the result of a Go-registered Lua function.
func PushError(l *lua.State, msg string) int {
	l.SetTop(0)
	l.PushBoolean(false)
	l.PushString(msg)
	return 2
}

// SetFieldString assigns table[key] = value where the table is at the
// given stack index.
func SetFieldString(l *lua.State, idx int, key, value string) {
	idx = l.AbsIndex(idx)
	l.PushString(value)
	l.SetField(idx, key)
}

// SetFieldInteger assigns table[key] = value (Lua integer).
func SetFieldInteger(l *lua.State, idx int, key string, value int) {
	idx = l.AbsIndex(idx)
	l.PushInteger(value)
	l.SetField(idx, key)
}

// SetFieldNumber assigns table[key] = value (Lua float).
func SetFieldNumber(l *lua.State, idx int, key string, value float64) {
	idx = l.AbsIndex(idx)
	l.PushNumber(value)
	l.SetField(idx, key)
}

// FieldString fetches table[key] and returns it as a string. Pops the value
// from the stack before returning.
func FieldString(l *lua.State, idx int, key string) (string, bool) {
	l.Field(idx, key)
	defer l.Pop(1)
	if l.IsString(-1) {
		return l.ToString(-1)
	}
	return "", false
}

// FieldInteger fetches table[key] and returns it as an int.
func FieldInteger(l *lua.State, idx int, key string) (int, bool) {
	l.Field(idx, key)
	defer l.Pop(1)
	if l.IsNumber(-1) {
		return l.ToInteger(-1)
	}
	return 0, false
}

// HasField returns true when table[key] is non-nil.
func HasField(l *lua.State, idx int, key string) bool {
	l.Field(idx, key)
	defer l.Pop(1)
	return !l.IsNil(-1)
}
