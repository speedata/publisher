package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"

	"sp/main/luacsv"
	"sp/main/luaxlsx"
	"sp/main/luaxml"

	"github.com/Shopify/go-lua"
)

// Lua error message in the form of bool, string.
// bool indicates success, string the error message in case of a false value.
func lerr(l *lua.State, errormessage string) int {
	l.SetTop(0)
	l.PushBoolean(false)
	l.PushString(errormessage)
	return 2
}

func validateRelaxNG(l *lua.State) int {
	var xml, schema string
	var ok bool
	xml, ok = l.ToString(1)
	if !ok {
		return lerr(l, "first argument must be a string")
	}
	schema, ok = l.ToString(2)
	if !ok {
		return lerr(l, "second argument must be a string")
	}
	cmd := exec.Command("java", "-jar", filepath.Join(libdir, "jing.jar"), schema, xml)

	stdoutPipe, err := cmd.StdoutPipe()
	if err != nil {
		return lerr(l, err.Error())
	}
	var b bytes.Buffer

	err = cmd.Start()
	if err != nil {
		return lerr(l, err.Error())
	}

	go io.Copy(&b, stdoutPipe)
	err = cmd.Wait()
	if err != nil {
		return lerr(l, b.String())
	}
	l.PushBoolean(true)
	return 1
}

func saxon(l *lua.State) int {
	if l.Top() < 3 {
		fmt.Println("command requires 3 or 4 arguments")
		return 0
	}
	var param string
	var ok bool

	if l.Top() == 4 {
		param, ok = l.ToString(-1)
		if !ok {
			return lerr(l, "fourth argument must be a string")
		}
		l.Pop(1)
	}

	xsl, ok := l.ToString(-3)
	if !ok {
		l.SetTop(0)
		l.PushBoolean(false)
		l.PushString("Something is wrong with the first argument")
		return 2
	}
	src, ok := l.ToString(-2)
	if !ok {
		l.SetTop(0)
		l.PushBoolean(false)
		l.PushString("Something is wrong with the second argument")
		return 2
	}
	out, ok := l.ToString(-1)
	if !ok {
		l.SetTop(0)
		l.PushBoolean(false)
		l.PushString("Something is wrong with the third argument")
		return 2
	}
	l.Pop(3)

	cmd := fmt.Sprintf("java -jar %s -xsl:%s -s:%s -o:%s %s", filepath.Join(libdir, "saxon9804he.jar"), xsl, src, out, param)
	success := run(cmd)
	l.PushBoolean(success)
	l.PushString(cmd)
	return 2
}

var runtimeLib = []lua.RegistryFunction{
	{"run_saxon", saxon},
	{"validate_relaxng", validateRelaxNG},
}

func runLuaScript(filename string) bool {
	l := lua.NewState()
	lua.OpenLibraries(l)

	requireRuntime := func(l *lua.State) int {
		lua.NewLibrary(l, runtimeLib)
		return 1
	}
	lua.Require(l, "runtime", requireRuntime, true)
	wd, _ := os.Getwd()
	l.PushString(wd)
	l.SetField(-2, "projectdir")
	l.Pop(1)

	luaxml.Open(l)
	luacsv.Open(l)
	luaxlsx.Open(l)

	if err := lua.DoFile(l, filename); err != nil {
		fmt.Println(err)
		return false
	}

	return true
}
