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
	"speedatapublisher/sp/sp/luahttp"
	"speedatapublisher/sp/sp/lualib"
	"speedatapublisher/sp/sp/luaxlsx"
	"speedatapublisher/sp/sp/luaxml"
	"speedatapublisher/splibaux"

	lua "github.com/speedata/go-lua"
)

var (
	l *lua.State
)

// jarDir returns the directory used to look up bundled JAR files
// (Saxon, jing, xmlresolver). When the "jardir" option is set, JARs
// are expected to live flat in that directory — this matches OS
// package layouts such as FreeBSD's /usr/local/share/java/classes/.
// Otherwise the bundled libdir is used, with companion JARs in
// libdir/lib/.
func jarDir() string {
	if d := getOption("jardir"); d != "" {
		return d
	}
	return libdir
}

func validateRelaxNG(l *lua.State) int {
	xmlfile := lua.CheckString(l, 1)
	rngfile := lua.CheckString(l, 2)

	cmd := exec.Command("java", "-jar", filepath.Join(jarDir(), "jing.jar"), rngfile, xmlfile)

	stdoutPipe, err := cmd.StdoutPipe()
	if err != nil {
		return lualib.PushError(l, err.Error())
	}
	var b bytes.Buffer

	err = cmd.Start()
	if err != nil {
		return lualib.PushError(l, err.Error())
	}

	go io.Copy(&b, stdoutPipe)
	err = cmd.Wait()
	if err != nil {
		return lualib.PushError(l, b.String())
	}

	l.PushBoolean(true)
	return 1
}

func saxonClasspath() string {
	sep := string(os.PathListSeparator)
	dir := jarDir()
	// Saxon JAR — match any version so OS packagers (e.g. FreeBSD,
	// which ships 12.8) can substitute their own point release.
	var cp string
	if matches, _ := filepath.Glob(filepath.Join(dir, "saxon-he-*.jar")); len(matches) > 0 {
		cp = matches[0]
	} else {
		cp = filepath.Join(dir, "saxon-he-12.9.jar")
	}
	// Companion JARs (xmlresolver and its data jar). When jardir is
	// overridden, JARs sit flat alongside saxon; otherwise they live
	// in the historical libdir/lib/ subdirectory.
	companionDir := filepath.Join(dir, "lib")
	if getOption("jardir") != "" {
		companionDir = dir
	}
	jars, _ := filepath.Glob(filepath.Join(companionDir, "xmlresolver-*.jar"))
	for _, jar := range jars {
		cp += sep + jar
	}
	return cp
}

func runSaxon(l *lua.State) int {
	n := l.Top()
	command := []string{"-cp", saxonClasspath(), "net.sf.saxon.Transform"}
	if n == 1 {
		if l.TypeOf(1) != lua.TypeTable {
			return lualib.PushError(l, "The single argument must be a table (run_saxon)")
		}
		m := map[string]string{
			"initialtemplate": "-it:%s",
			"source":          "-s:%s",
			"stylesheet":      "-xsl:%s",
			"out":             "-o:%s",
		}
		for k, fmtStr := range m {
			if v, ok := lualib.FieldString(l, 1, k); ok {
				command = append(command, fmt.Sprintf(fmtStr, v))
			}
		}
		// params can be a string or a table
		l.Field(1, "params")
		switch l.TypeOf(-1) {
		case lua.TypeString:
			s, _ := l.ToString(-1)
			command = append(command, s)
		case lua.TypeTable:
			pIdx := l.AbsIndex(-1)
			l.PushNil()
			for l.Next(pIdx) {
				k, _ := l.ToString(-2)
				v, _ := l.ToString(-1)
				command = append(command, fmt.Sprintf("%s=%s", k, v))
				l.Pop(1)
			}
		}
		l.Pop(1)
	} else if n < 3 {
		return lualib.PushError(l, "command requires 3 or 4 arguments")
	} else {
		xsl := lua.CheckString(l, 1)
		src := lua.CheckString(l, 2)
		out := lua.CheckString(l, 3)
		command = append(command, fmt.Sprintf("-xsl:%s", xsl), fmt.Sprintf("-s:%s", src), fmt.Sprintf("-o:%s", out))
		if n > 3 {
			command = append(command, lua.CheckString(l, 4))
		}
	}
	if verbose {
		fmt.Println(command)
	}
	env := []string{}
	exitcode := run("java", command, env)

	l.PushBoolean(exitcode == 0)
	l.PushString("java " + strings.Join(command, " "))
	return 2
}

func findFile(l *lua.State) int {
	if l.Top() != 1 {
		return lualib.PushError(l, "find_file requires 1 argument: the file to find")
	}
	fn := lua.CheckString(l, 1)
	abspath, err := splibaux.GetFullPath(fn)
	if abspath == "" {
		if err != nil {
			l.PushNil()
			l.PushString(err.Error())
			return 2
		}
		l.PushNil()
		return 1
	}
	l.PushString(abspath)
	return 1
}

func execute(l *lua.State) int {
	lua.CheckType(l, 1, lua.TypeTable)
	n := l.RawLength(1)
	var cmd string
	var arguments []string
	for i := 1; i <= n; i++ {
		l.RawGetInt(1, i)
		s, _ := l.ToString(-1)
		l.Pop(1)
		if i == 1 {
			cmd = s
		} else {
			arguments = append(arguments, s)
		}
	}
	command := exec.Command(cmd, arguments...)
	command.Stdout = os.Stdout
	command.Stdin = os.Stdin
	if err := command.Run(); err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			l.PushBoolean(false)
			l.PushInteger(exitError.ExitCode())
			return 2
		}
		return lualib.PushError(l, err.Error())
	}
	l.PushBoolean(true)
	return 1
}

var runtimeExports = []lua.RegistryFunction{
	{Name: "validate_relaxng", Function: validateRelaxNG},
	{Name: "run_saxon", Function: runSaxon},
	{Name: "find_file", Function: findFile},
	{Name: "execute", Function: execute},
}

func runtimeLoader(l *lua.State) int {
	lua.NewLibrary(l, runtimeExports)

	// runtime.variables
	l.NewTable()
	for k, v := range variables {
		l.PushString(v)
		l.SetField(-2, k)
	}
	l.SetField(-2, "variables")

	// runtime.options (table with __index/__newindex metatable)
	l.NewTable()
	l.NewTable()
	l.PushGoFunction(indexOptions)
	l.SetField(-2, "__index")
	l.PushGoFunction(newIndexOptions)
	l.SetField(-2, "__newindex")
	l.SetMetaTable(-2)
	l.SetField(-2, "options")

	// runtime.projectdir
	wd, _ := os.Getwd()
	l.PushString(wd)
	l.SetField(-2, "projectdir")

	return 1
}

// __newindex(table, key, value)
func newIndexOptions(l *lua.State) int {
	if l.Top() < 3 {
		l.PushNil()
		return 1
	}
	name := lua.CheckString(l, 2)
	value := lua.CheckString(l, 3)
	options[name] = value
	return 0
}

// __index(table, key)
func indexOptions(l *lua.State) int {
	if l.Top() < 2 {
		l.PushNil()
		return 1
	}
	name := lua.CheckString(l, 2)
	l.PushString(getOption(name))
	return 1
}

// runFinalizerCallback runs runtime.finalizer (if defined) after the
// publishing run.
func runFinalizerCallback() {
	if l == nil {
		return
	}
	l.Global("runtime")
	if !l.IsTable(-1) {
		l.Pop(1)
		return
	}
	l.Field(-1, "finalizer")
	if !l.IsFunction(-1) {
		l.Pop(2)
		return
	}
	l.Call(0, 0)
	l.Pop(1)
}

func runLuaScript(filename string) bool {
	if l == nil {
		l = lua.NewState()
		httpModule := luahttp.New(&http.Client{})
		lua.OpenLibraries(l,
			lua.RegistryFunction{Name: "runtime", Function: runtimeLoader},
			lua.RegistryFunction{Name: "csv", Function: luacsv.Open},
			lua.RegistryFunction{Name: "xml", Function: luaxml.Open},
			lua.RegistryFunction{Name: "xlsx", Function: luaxlsx.Open},
			lua.RegistryFunction{Name: "http", Function: httpModule.Loader},
		)
	}

	if err := lua.DoFile(l, filename); err != nil {
		fmt.Println(err)
		return false
	}

	return true
}
