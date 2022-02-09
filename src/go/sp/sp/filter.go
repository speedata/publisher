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

	"speedatapublisher/sp/sp/luacsv"
	"speedatapublisher/sp/sp/luaxlsx"
	"speedatapublisher/sp/sp/luaxml"
	"speedatapublisher/splibaux"

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
	numberArguments := l.GetTop()
	var command []string
	command = []string{"-jar", filepath.Join(libdir, "saxon-he-11.1.jar")}
	if numberArguments == 1 {
		// hopefully a table
		lv := l.Get(-1)
		if tbl, ok := lv.(*lua.LTable); ok {
			m := map[string]string{
				"initialtemplate": "-it:%s",
				"source":          "-s:%s",
				"stylesheet":      "-xsl:%s",
				"out":             "-o:%s",
			}
			for k, val := range m {
				if str := tbl.RawGetString(k); str.Type() == lua.LTString {
					command = append(command, fmt.Sprintf(val, str.String()))
				}
			}
			// parameters at the end
			if str := tbl.RawGetString("params"); str.Type() == lua.LTString {
				command = append(command, str.String())
			} else if tbl := tbl.RawGetString("params"); tbl.Type() == lua.LTTable {
				if paramtbl, ok := tbl.(*lua.LTable); ok {
					paramtbl.ForEach(func(key lua.LValue, value lua.LValue) {
						command = append(command, fmt.Sprintf("%s=%s", key.String(), value.String()))
					})
				}
			}

		} else {
			return lerr("The single argument must be a table (run_saxon)")
		}
	} else if numberArguments < 3 {
		return lerr("command requires 3 or 4 arguments")
	} else {
		xsl := l.CheckString(1)
		src := l.CheckString(2)
		out := l.CheckString(3)

		command = append(command, fmt.Sprintf("-xsl:%s", xsl), fmt.Sprintf("-s:%s", src), fmt.Sprintf("-o:%s", out))

		// fourth argument param is optional
		if numberArguments > 3 {
			command = append(command, l.CheckString(4))
		}
	}
	if verbose {
		fmt.Println(command)
	}
	env := []string{}
	exitcode := run("java", command, env)

	if exitcode == 0 {
		l.Push(lua.LTrue)
	} else {
		l.Push(lua.LFalse)
	}
	l.Push(lua.LString("java " + strings.Join(command, " ")))
	return 2
}

func findFile(l *lua.LState) int {
	numberArguments := l.GetTop()
	if numberArguments != 1 {
		return lerr("find_file requires 1 argument: the file to find")
	}
	fn := l.CheckString(1)
	abspath, err := splibaux.GetFullPath(fn)
	if abspath == "" {
		if err != nil {
			l.Push(lua.LNil)
			l.Push(lua.LString(err.Error()))
			return 2
		}
		l.Push(lua.LNil)
		return 1
	}
	l.Push(lua.LString(abspath))
	return 1
}

var exports = map[string]lua.LGFunction{
	"validate_relaxng": validateRelaxNG,
	"run_saxon":        runSaxon,
	"find_file":        findFile,
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
	l.SetField(mod, "options", getOptionsTable((l)))
	wd, _ := os.Getwd()
	l.SetField(mod, "projectdir", lua.LString(wd))
}

func getOptionsTable(l *lua.LState) *lua.LTable {
	options := l.NewTable()
	mt := l.NewTable()
	l.SetField(mt, "__index", l.NewFunction(indexOptions))
	l.SetField(mt, "__newindex", l.NewFunction(newIndexOptions))
	l.SetMetatable(options, mt)
	return options
}

// Set string
func newIndexOptions(l *lua.LState) int {
	numberArguments := l.GetTop()
	if numberArguments < 3 {
		l.Push(lua.LNil)
		return 1
	}
	// 1: tbl
	// 2: key
	// 3: value
	optionName := l.CheckString(2)
	optionValue := l.CheckString(3)
	options[optionName] = optionValue
	return 0
}

func indexOptions(l *lua.LState) int {
	numberArguments := l.GetTop()
	if numberArguments < 2 {
		l.Push(lua.LNil)
		return 1
	}
	// 1: tbl
	// 2: key
	optionName := l.CheckString(2)
	l.Push(lua.LString(getOption(optionName)))
	return 1
}

// When runtime.finalizer is set, call that function after
// the publishing run
func runFinalizerCallback() {
	val := l.GetGlobal("runtime")
	if val == nil {
		return
	}

	tbl, ok := val.(*lua.LTable)
	if !ok {
		return
	}
	fun := tbl.RawGetString("finalizer")
	if fn, ok := fun.(*lua.LFunction); ok {
		l.Push(fn)
		l.Call(0, 0)
	}
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
