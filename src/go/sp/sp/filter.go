package main

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"sp/sp/luacsv"
	"sp/sp/luaxlsx"
	"sp/sp/luaxml"

	"github.com/cjoudrey/gluahttp"
	lua "github.com/yuin/gopher-lua"
)

var (
	l *lua.LState
)

func lerr(errormessage string) int {
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
		return lerr(err.Error())
	}
	var b bytes.Buffer

	err = cmd.Start()
	if err != nil {
		return lerr(err.Error())
	}

	go io.Copy(&b, stdoutPipe)
	err = cmd.Wait()
	if err != nil {
		return lerr(b.String())
	}

	l.Push(lua.LTrue)
	return 1
}

func runSaxon(l *lua.LState) int {
	if l.GetTop() < 3 {
		return lerr("command requires 3 or 4 arguments")
	}
	xsl := l.CheckString(1)
	src := l.CheckString(2)
	out := l.CheckString(3)

	cmd := []string{"-jar", filepath.Join(libdir, "saxon9804he.jar"), fmt.Sprintf("-xsl:%s", xsl), fmt.Sprintf("-s:%s", src), fmt.Sprintf("-o:%s", out)}

	// fourth argument param is optional
	if l.GetTop() > 3 {
		cmd = append(cmd, l.CheckString(4))
	}
	env := []string{}
	exitcode := run("java", cmd, env)

	if exitcode == 0 {
		l.Push(lua.LTrue)
	} else {
		l.Push(lua.LFalse)
	}
	l.Push(lua.LString("java " + strings.Join(cmd, " ")))
	return 2
}

var exports = map[string]lua.LGFunction{
	"validate_relaxng": validateRelaxNG,
	"run_saxon":        runSaxon,
}

func runtimeLoader(l *lua.LState) int {
	mod := l.SetFuncs(l.NewTable(), exports)
	fillRuntimeModule(mod)
	l.Push(mod)
	return 1

}

// set projectdir and variables table
func fillRuntimeModule(mod lua.LValue) {
	lvars := l.NewTable()
	for k, v := range variables {
		lvars.RawSetString(k, lua.LString(v))
	}
	l.SetField(mod, "variables", lvars)

	wd, _ := os.Getwd()
	l.SetField(mod, "projectdir", lua.LString(wd))
}

// When runtime.finalizer is set, call that function after
// the publishing run
func runFinalizerCallback() {
	val := l.GetGlobal("runtime")
	if val == nil {
		return
	}
	if tbl, ok := val.(*lua.LTable); !ok {
		return
	} else {
		fun := tbl.RawGetString("finalizer")
		if fn, ok := fun.(*lua.LFunction); ok {
			l.Push(fn)
			l.Call(0, 0)
		}
	}
	return
}

func runLuaScript(filename string) bool {
	if l == nil {
		l = lua.NewState()
	}

	l.PreloadModule("runtime", runtimeLoader)
	l.PreloadModule("csv", luacsv.Open)
	l.PreloadModule("xml", luaxml.Open)
	l.PreloadModule("xlsx", luaxlsx.Open)
	l.PreloadModule("http", gluahttp.NewHttpModule(&http.Client{}).Loader)

	if err := l.DoFile(filename); err != nil {
		fmt.Println(err)
		return false
	}
	return true
}
