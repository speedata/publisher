package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"

	"sp/sp/luacsv"
	"sp/sp/luaxlsx"
	"sp/sp/luaxml"

	"github.com/yuin/gopher-lua"
)

func lerr(l *lua.LState, errormessage string) int {
	l.SetTop(0)
	l.Push(lua.LFalse)
	l.Push(lua.LString(errormessage))
	return 2
}

func validateRelaxNG(l *lua.LState) int {
	xmlfile := l.CheckString(1)
	rngfile := l.CheckString(2)

	cmd := exec.Command("java", "-jar", filepath.Join(libdir, "jing.jar"), rngfile, xmlfile)

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

	l.Push(lua.LTrue)
	return 1
}

func runSaxon(l *lua.LState) int {
	if l.GetTop() < 3 {
		return lerr(l, "command requires 3 or 4 arguments")
	}
	xsl := l.CheckString(1)
	src := l.CheckString(2)
	out := l.CheckString(3)
	var param string
	if l.GetTop() > 3 {
		param = l.CheckString(4)
	}
	cmd := fmt.Sprintf("java -jar %s -xsl:%s -s:%s -o:%s %s", filepath.Join(libdir, "saxon9804he.jar"), xsl, src, out, param)
	exitcode := run(cmd)
	if exitcode == 0 {
		l.Push(lua.LTrue)
	} else {
		l.Push(lua.LFalse)
	}

	l.Push(lua.LString(cmd))
	return 2
}

var exports = map[string]lua.LGFunction{
	"validate_relaxng": validateRelaxNG,
	"run_saxon":        runSaxon,
}

func runtimeLoader(l *lua.LState) int {
	mod := l.SetFuncs(l.NewTable(), exports)
	fillRuntimeModule(l, mod)
	l.Push(mod)
	return 1

}

// Set projectdir and variables table
func fillRuntimeModule(l *lua.LState, mod lua.LValue) {
	lvars := l.NewTable()
	for k, v := range variables {
		lvars.RawSetString(k, lua.LString(v))
	}
	l.SetField(mod, "variables", lvars)

	wd, _ := os.Getwd()
	l.SetField(mod, "projectdir", lua.LString(wd))
}

func runLuaScript(filename string) bool {
	l := lua.NewState()
	defer l.Close()

	l.PreloadModule("runtime", runtimeLoader)
	l.PreloadModule("csv", luacsv.Open)
	l.PreloadModule("xml", luaxml.Open)
	l.PreloadModule("xlsx", luaxlsx.Open)

	if err := l.DoFile(filename); err != nil {
		fmt.Println(err)
		return false
	}
	return true
}
