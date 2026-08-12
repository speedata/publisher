// go build -ldflags "-X main.dest linux -X main.version local"  main.go

package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"os/signal"
	"os/user"
	"path/filepath"
	"regexp"
	"runtime"
	"speedatapublisher/configurator"
	"speedatapublisher/server"
	"speedatapublisher/sp"
	"speedatapublisher/splibaux"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/Masterminds/semver"
	"github.com/speedata/hotfolder"
	"github.com/speedata/optionparser"
)

const (
	cmdRun         = "run"
	cmdServer      = "server"
	cmdCompare     = "compare"
	cmdClean       = "clean"
	cmdCheckUpdate = "checkupdate"
	cmdClearcache  = "clearcache"
	cmdDoc         = "doc"
	cmdListFonts   = "list-fonts"
	cmdNew         = "new"
	cmdWatch       = "watch"
	cmdHelp        = "help"

	osWindows = "windows"
	osLinux   = "linux"
	osDarwin  = "darwin"

	stringFalse = "false"
	stringTrue  = "true"
)

// settings from the build script
var (
	dest    string // The platform which this script runs on.
	version string
	pro     string // contains 'yes' if the build is with the pro tag
)

var (
	options        map[string]string
	defaults       map[string]string
	layoutoptions  map[string]string
	variables      map[string]string
	installdir     string
	bindir         string
	libdir         string
	srcdir         string
	inifile        string
	homecfg        string
	systemcfg      string
	pwd            string
	exeSuffix      string
	homedir        string
	addLocalPath   bool // Add pwd recursively to extra-dir
	useSystemFonts bool
	configfilename string
	mainlanguage   string
	extraDir       []string
	extraxml       []string
	prependxml     []string
	starttime      time.Time
	cfg            *configurator.ConfigData
	runningProcess []*os.Process
	versionWithPro string
	verbose        bool
)

func init() {
	var err error
	log.SetFlags(0)
	starttime = time.Now()
	go sigIntCatcher()
	pwd, err = os.Getwd()
	if err != nil {
		log.Fatal(err)
	}
	if pro == "yes" {
		versionWithPro = version + " (Pro)"
	} else {
		versionWithPro = version
	}
	variables = make(map[string]string)
	layoutoptions = make(map[string]string)
	options = make(map[string]string)
	defaults = map[string]string{
		"address":           "127.0.0.1",
		"data":              "data.xml",
		"fontpath":          "",
		"grid":              "",
		"imagecache":        "",
		"jobname":           "publisher",
		"layout":            "layout.xml",
		"loglevel":          "message",
		"port":              "5266",
		"quiet":             stringFalse,
		"runs":              "1",
		"tempdir":           os.TempDir(),
		"cache":             "optimal",
		"inkscape":          "inkscape",
		"inkscape-command":  "--export-filename",
		"jardir":            "",
		"fontloader":        "harfbuzz",
		"referencefilename": "reference",
		"xpath":             "lxpath",
		"hidespinfo":        stringFalse,
	}

	switch runtime.GOOS {
	case osWindows:
		exeSuffix = ".exe"
	}
	// Let's try to find out the installation dir
	if execlocation, err := os.Executable(); err != nil {
		if strings.Contains(os.Args[0], "/") {
			if bindir, err = filepath.Abs(filepath.Dir(os.Args[0])); err != nil {
				log.Fatal(err)
			}
		} else {
			// if that fails (see for example #254), we try exec.LookPath
			if execlocation, err = exec.LookPath("sp" + exeSuffix); err != nil {
				log.Fatal(err)
			}
			bindir = filepath.Dir(execlocation)
		}
	} else {
		bindir = filepath.Dir(execlocation)
	}
	installdir = filepath.Join(bindir, "..")

	if version == "" {
		version = "local"
	}

	// log.Print("Built for platform: ",dest)
	switch runtime.GOOS {
	case osDarwin:
		defaults["opencommand"] = "open"
		defaults["openurl"] = "open -u"
		homedir = os.Getenv("HOME")
	case osLinux:
		defaults["opencommand"] = "xdg-open"
		defaults["openurl"] = "xdg-open"
		homedir = os.Getenv("HOME")
	case osWindows:
		defaults["opencommand"] = "cmd /C start"
		defaults["openurl"] = "start"

		me, err := user.Current()
		if err != nil {
			log.Fatal(err)
		}
		homedir = me.HomeDir
	}
	addLocalPath = true
	useSystemFonts = false
	configfilename = "publisher.cfg"
	mainlanguage = "en_GB"

	switch dest {
	case "custom":
		// pray that the user has set libdir and srcdir during compilation
		os.Setenv("LUA_PATH", fmt.Sprintf("%s/lua/?.lua;%s/lua/common/?.lua;", srcdir, srcdir))
		os.Setenv("PUBLISHER_BASE_PATH", srcdir)
	case "directory":
		libdir = filepath.Join(installdir, "share", "lib")
		srcdir = filepath.Join(installdir, "sw")
		os.Setenv("PUBLISHER_BASE_PATH", srcdir)
		os.Setenv("LUA_PATH", srcdir+"/lua/?.lua;"+installdir+"/lib/?.lua;"+srcdir+"/lua/common/?.lua;")
	default:
		// local git installation
		libdir = filepath.Join(installdir, "lib")
		srcdir = filepath.Join(installdir, "src")
		os.Setenv("PUBLISHER_BASE_PATH", strings.Join([]string{
			filepath.Join(srcdir, "lua"),
			filepath.Join(srcdir, "colorprofiles"),
			filepath.Join(srcdir, "tex"),
			filepath.Join(srcdir, "metapost"),
			filepath.Join(srcdir, "hyphenation"),
		}, string(os.PathListSeparator)))
		os.Setenv("LUA_PATH", srcdir+"/lua/?.lua;"+installdir+"/lib/?.lua;"+srcdir+"/lua/common/?.lua;")
		extradir(filepath.Join(installdir, "fonts"))
		extradir(filepath.Join(installdir, "img"))
	}
	os.Setenv("LUA_CPATH", libdir+"/?.so;"+libdir+"/?.dll;"+bindir+"/?.dll;")
	inifile = filepath.Join(srcdir, "lua/sdini.lua")
	os.Setenv("PUBLISHERVERSION", version)
	os.Setenv("LD_LIBRARY_PATH", libdir)
	os.Setenv("DYLD_LIBRARY_PATH", libdir)
}

func getOptionSection(optionname string, section string) string {
	if options[optionname] != "" {
		return options[optionname]
	}
	if cfg.String(section, optionname) != "" {
		return cfg.String(section, optionname)
	}

	if defaults[optionname] != "" {
		return defaults[optionname]
	}
	return ""
}

func getSectionOptionWithWarning(optionname string, section string) string {
	if o := options[optionname]; o != "" {
		return o
	}
	if val := cfg.String("DEFAULT", optionname); val != "" {
		fmt.Printf("** Warning: please put the option %q in section %q\n", optionname, section)
		return val
	}
	if val := cfg.String(section, optionname); val != "" {
		return val
	}
	return defaults[optionname]
}

func getOption(optionname string) string {
	if o := options[optionname]; o != "" {
		return o
	}
	if val := cfg.String("DEFAULT", optionname); val != "" {
		return val
	}
	return defaults[optionname]
}

// Open the given file with the system's default program
func openFile(filename string) {
	opencommand := getOption("opencommand")
	cmdname := strings.Split(opencommand, " ")
	cmdname = append(cmdname, filepath.Base(filename))
	cmd := exec.Command(cmdname[0], cmdname[1:]...)
	// windows doesn't like quotation marks on the filename argument. So we change into the
	// directory
	cmd.Dir = filepath.Dir(filename)
	err := cmd.Run()
	if err != nil {
		log.Fatal(err)
	}
}

func openWebPage(url string) {
	opencommand := getOption("opencommand")
	cmdname := strings.Split(opencommand, " ")
	cmdname = append(cmdname, url)
	cmd := exec.Command(cmdname[0], cmdname[1:]...)
	// windows doesn't like quotation marks on the filename argument. So we change into the
	// directory
	err := cmd.Run()
	if err != nil {
		log.Fatal(err)
	}
}

func setOption(str string) {
	a := strings.Split(str, "=")
	options[a[0]] = a[1]
}

// Put string a=b into the variables map
func setVariable(str string) {
	a := strings.Split(str, "=")
	variables[a[0]] = a[1]
}

// Prints the total run time in the log file.
func showDuration() {
	if getOption("quiet") != "true" {
		d := time.Since(starttime)
		dStart := d
		var sb strings.Builder
		if d > time.Minute {
			wholeMinutes := d.Truncate(time.Minute) / time.Minute
			fmt.Fprintf(&sb, "%dm", wholeMinutes)
			d -= d.Truncate(time.Minute)
		}
		if d > time.Second {
			wholeSeconds := d.Truncate(time.Second) / time.Second
			fmt.Fprintf(&sb, "%ds", wholeSeconds)
			d -= d.Truncate(time.Second)
		}
		if dStart < time.Second {
			fmt.Fprintf(&sb, "%dms", d.Truncate(time.Millisecond)/time.Millisecond)
		}

		log.Printf("Total run time: %s\n", sb.String())
	}
}

// Kill all running child processes
// some process (such as java xproc pipelines) are still in the runningProcess queue, so
// let's try to kill these processes as well, and let's ignore the error of the kill command.
func killallProcesses() {
	for _, proc := range runningProcess {
		proc.Kill()
	}
}

// exitProgram ensures all child processes are killed before exiting.
// This should be used instead of os.Exit() to prevent orphaned processes.
func exitProgram(code int) {
	killallProcesses()
	showDuration()
	os.Exit(code)
}

func timeoutCatcher(seconds int) {
	timeout := make(chan bool, 1)
	go func() {
		time.Sleep(time.Duration(seconds) * time.Second)
		timeout <- true
	}()
	<-timeout
	log.Printf("\n\nTimeout after %d seconds", seconds)
	exitProgram(-1)
}

func sigIntCatcher() {
	ch := make(chan os.Signal, 1)
	signal.Notify(ch, syscall.SIGINT, syscall.SIGTERM)
	sig := <-ch
	log.Printf("Signal received: %v", sig)
	exitProgram(0)
}

func isASCII(s string) bool {
	for i := 0; i < len(s); i++ {
		if s[i] > '\u007F' {
			return false
		}
	}
	return true
}

// Run the given command line
func run(command string, cmdline []string, environ []string) (errorcode int) {
	errorcode = 0
	cmd := exec.Command(command, cmdline...)
	cmd.Env = append(os.Environ(), environ...)
	// Set platform-specific process attributes (e.g., Pdeathsig on Linux/FreeBSD)
	setSysProcAttr(cmd)
	stdin, err := cmd.StdinPipe()
	if err != nil {
		log.Fatal(err)
	}
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		log.Fatal(err)
	}
	stderr, err := cmd.StderrPipe()
	if err != nil {
		log.Fatal(err)
	}
	err = cmd.Start()
	if err != nil {
		fmt.Println(err)
		errorcode = -1
		return
	}
	runningProcess = append(runningProcess, cmd.Process)

	if getOption("quiet") == stringTrue {
		go io.Copy(io.Discard, stdout)
		go io.Copy(io.Discard, stderr)
	} else {
		go io.Copy(os.Stdout, stdout)
		go io.Copy(os.Stderr, stderr)
	}
	// We can read from stdin if data name = "-". But we should only
	// wait on stdin if we really want to.
	if dataname := getOption("data"); dataname == "-" {
		io.Copy(stdin, os.Stdin)
		stdin.Close()
	}
	startTime := time.Now()
	if err := cmd.Wait(); err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			// On Windows, Go shared libraries can crash during DLL unload
			// (STATUS_ACCESS_VIOLATION). If the PDF was written after we
			// started the process, treat it as success.
			if runtime.GOOS == osWindows && exitErr.ExitCode() == 0xc0000005 {
				outfile := getOption("jobname")
				if outfile == "" {
					outfile = "publisher"
				}
				if fi, ferr := os.Stat(outfile + ".pdf"); ferr == nil && fi.ModTime().After(startTime) {
					log.Print("Ignoring Windows DLL cleanup crash (exit 0xc0000005), PDF was created successfully.")
					return 0
				}
			}
			log.Print(err)
			return -1
		}
		log.Print(err)
	}
	return
}

func readVariables() {
	if fn := getOption("varsfile"); fn != "" {
		// Read vars-file
		f, err := os.Open(fn)
		if err != nil {
			fmt.Println("File", fn, "not found. Exit.")
			exitProgram(-1)
		}
		fmt.Print("Read file ", fn, "...")
		s := bufio.NewScanner(f)
		// Read each line
		for s.Scan() {
			txt := s.Text()
			if strings.HasPrefix(txt, "#") {
				continue
			}
			res := strings.Split(txt, "=")
			if len(res) != 2 {
				// ignore
			} else {
				variables[res[0]] = res[1]
			}
		}
		f.Close()
		fmt.Println("done")
	}
	if vars := getOption("vars"); vars != "" {
		for keyvalue := range strings.SplitSeq(vars, ",") {
			tmp := strings.Split(keyvalue, "=")
			if len(tmp) == 2 {
				variables[tmp[0]] = tmp[1]
			}
		}
	}
}

// luaescape writes unicode runes > 127 as an escaped UTF8 sequence.
// For example U+F8FF will be written as `\239\163\191`.
func luaescape(in string) string {
	var out strings.Builder
	for _, b := range []byte(in) {
		if b == 34 {
			// a " (quote)
			out.WriteString(`\"`)
		} else if b == 92 {
			// a backslash
			out.WriteString(`\\`)
		} else if b > 127 {
			// \123 must be exactly three digits, but a byte > 127
			// will be three digits anyway.
			fmt.Fprintf(&out, "\\%d", b)
		} else {
			out.WriteByte(b)
		}
	}

	return out.String()
}

func saveVariables() {
	jobname := getOption("jobname")
	f, err := os.Create(jobname + ".vars")
	if err != nil {
		log.Fatal(err)
	}
	fmt.Fprintln(f, "return { ")
	for key, value := range variables {
		fmt.Fprintf(f, `["%s"] = "%s", `+"\n", key, luaescape(value))
	}
	fmt.Fprintln(f, "} ")
	f.Close()
}

// add the command line argument (extra-dir) into the slice
func extradir(arg string) {
	for p := range strings.SplitSeq(arg, string(filepath.ListSeparator)) {
		extraDir = append(extraDir, p)
	}
}

// Add the command line argument to the list of additional XML files for the layout
func extraXML(arg string) {
	extraxml = append(extraxml, arg)
}

// Add the command line argument to the list of additional XML files for the layout
func prependXML(arg string) {
	prependxml = append(prependxml, arg)
}

// Return the full path to the TeX executable. It is called sdluatex(.exe) and
// can be overridden by the 'luatex' option. As a fallback, luahbtex(.exe) is
// also accepted. It panics if no TeX binary can be found.
func getExecutablePath() string {
	if luatex := getOption("luatex"); luatex != "" {
		return luatex
	}

	for _, name := range []string{"sdluatex", "luahbtex"} {
		executableName := name + exeSuffix

		p := filepath.Join(installdir, "bin", executableName)
		if fi, _ := os.Stat(p); fi != nil {
			return p
		}

		if p, err := exec.LookPath(executableName); err == nil {
			return p
		}
	}

	log.Fatal("Can't find sdluatex or luahbtex binary")
	return ""
}

// Print version information
func versioninfo() {
	log.Printf("Version: %s", versionWithPro)
	os.Exit(0)
}

// copy a file from srcpath to destpath and make
// directory if necessary
func copyFile(srcpath, destpath string) error {
	// check if srcpath and destpath are the same
	if srcpath == destpath {
		if verbose {
			log.Printf("Source and destination are the same: %s", srcpath)
		}
		return nil
	}
	if fileExists(destpath) {
		srcFi, err := os.Stat(srcpath)
		if err != nil {
			return err
		}
		destFi, err := os.Stat(destpath)
		if err != nil {
			return err
		}
		if os.SameFile(srcFi, destFi) {
			// src and dest are the same file, so we don't need to copy
			if verbose {
				log.Printf("Source and destination are the same: %s", srcpath)
			}
			return nil
		}
	}

	dir := filepath.Dir(destpath)
	err := os.MkdirAll(dir, os.ModePerm)
	if err != nil {
		return err
	}
	src, err := os.Open(srcpath)
	if err != nil {
		return err
	}
	dest, err := os.Create(destpath)
	if err != nil {
		return err
	}
	_, err = io.Copy(dest, src)
	if err != nil {
		return err
	}
	return nil // no error
}

func removeLogfile() {
	os.Remove(getOption("jobname") + ".log")
}

func fileExists(filename string) bool {
	fi, err := os.Stat(filename)
	if err != nil {
		return false
	}
	return !fi.IsDir()
}

func writeFinishedfile(path string) {
	os.WriteFile(path, []byte("finished\n"), 0600)
}

func runPublisher(cachemethod string) (exitstatus int) {
	if getOption("quiet") != "true" {
		log.Printf("Run speedata publisher %s", versionWithPro)
	}
	defer removeLogfile()

	cmdline := []string{}
	if runtime.GOOS == osWindows {
		// to allow UT8 filenames
		cmdline = append(cmdline, "--cmdx")
	}

	jobname := getOption("jobname")

	exitstatus = 0
	saveVariables()

	layoutoptions["grid"] = getOption("grid")
	os.Setenv("SP_FONTLOADER", getOption("fontloader"))
	os.Setenv("SP_XMLPARSER", getOption("xpath"))

	layoutoptions["reportmissingglyphs"] = getOption("reportmissingglyphs")

	// layoutoptions are passed as a command line argument to the publisher
	var layoutoptionsSlice []string
	if layoutoptions["grid"] != "" {
		layoutoptionsSlice = append(layoutoptionsSlice, `showgrid=`+layoutoptions["grid"])
	}
	if layoutoptions["show-gridallocation"] != "" {
		layoutoptionsSlice = append(layoutoptionsSlice, `showgridallocation=`+layoutoptions["show-gridallocation"])
	}
	if layoutoptions["startpage"] != "" {
		layoutoptionsSlice = append(layoutoptionsSlice, `startpage=`+layoutoptions["startpage"])
	}
	if layoutoptions["cutmarks"] != "" {
		layoutoptionsSlice = append(layoutoptionsSlice, `cutmarks=`+layoutoptions["cutmarks"])
	}
	if layoutoptions["trace"] != "" {
		layoutoptionsSlice = append(layoutoptionsSlice, `trace=`+layoutoptions["trace"])
	}
	if layoutoptions["reportmissingglyphs"] != "" {
		layoutoptionsSlice = append(layoutoptionsSlice, `reportmissingglyphs=`+layoutoptions["reportmissingglyphs"])
	}
	if mode := getOption("mode"); mode != "" {
		layoutoptionsSlice = append(layoutoptionsSlice, `mode=`+mode)
	}
	if pro == "yes" {
		layoutoptionsSlice = append(layoutoptionsSlice, `pro=yes`)
	}
	if hidespinfo := getOption("hidespinfo"); hidespinfo != "" {
		layoutoptionsSlice = append(layoutoptionsSlice, `hidespinfo=`+hidespinfo)
	}
	if imagehandler := getOption("imagehandler"); imagehandler != "" {
		layoutoptionsSlice = append(layoutoptionsSlice, `imagehandler=`+imagehandler)
	}
	if extensionhandler := getOption("extensionhandler"); extensionhandler != "" {
		layoutoptionsSlice = append(layoutoptionsSlice, `extensionhandler=`+extensionhandler)
	}
	if resizehandler := getOption("resizehandler"); resizehandler != "" {
		layoutoptionsSlice = append(layoutoptionsSlice, `resizehandler=`+resizehandler)
	}
	if html := getOption("html"); html != "" {
		layoutoptionsSlice = append(layoutoptionsSlice, `html=`+html)
	}

	layoutname := getOption("layout")
	dataname := getOption("data")

	if dummyData := getOption("dummy"); dummyData == stringTrue {
		dataname = "-dummy"
	}
	runs, err := strconv.Atoi(getOption("runs"))
	if err != nil {
		log.Fatal(err)
	}

	cmdline = append(cmdline, "--shell-escape", "--interaction", "nonstopmode", fmt.Sprintf("--jobname=%s", jobname))
	cmdline = append(cmdline, "--ini", fmt.Sprintf("--lua=%s", inifile), "publisher.tex")
	cmdline = append(cmdline, layoutname, dataname)
	cmdline = append(cmdline, layoutoptionsSlice...)
	env := []string{"LC_ALL=C", "SP_JOBNAME=" + jobname}
	for i := 1; i <= runs; i++ {
		ep := getExecutablePath()
		if runtime.GOOS == "windows" && !isASCII(ep) {
			fmt.Println(`!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Your windows path contains non-ascii characters.
The speedata Publisher will probably not work in this environment.
Please make sure that you install the speedata Publisher in a directory
without accented characters.

See https://github.com/speedata/publisher/issues/310 for details.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!`)
		}

		if run(ep, cmdline, env) < 0 {
			exitstatus = -1
		}

		if cachemethod != "none" {
			os.Setenv("CACHEMETHOD", "fast")
		}
	}

	// If user supplied an outputdir, copy the PDF and the protocol to that path
	p := getOption("outputdir")
	if p != "" {
		pdffilename := jobname + ".pdf"
		protocolfilename := jobname + "-protocol.xml"
		err = copyFile(pdffilename, filepath.Join(p, pdffilename))
		if err != nil {
			log.Println(err)
			return
		}
		err = copyFile(protocolfilename, filepath.Join(p, protocolfilename))
		if err != nil {
			log.Println(err)
			return
		}
	}
	return
}

func scaffold(extra ...string) error {
	var err error
	fmt.Print("Creating layout.xml and data.xml in ")
	if len(extra) > 0 {
		dir := extra[0]
		fmt.Println("a new directory", dir)
		err = os.MkdirAll(dir, 0755)
		if err != nil {
			return err
		}
		err = os.Chdir(dir)
		if err != nil {
			return err
		}
	} else {
		fmt.Println("current directory")
	}

	// Let's not overwrite existing files
	_, err = os.Stat("data.xml")
	if err == nil {
		return fmt.Errorf("data.xml already exists")
	}
	_, err = os.Stat("layout.xml")
	if err == nil {
		return fmt.Errorf("layout.xml already exists")
	}

	dataTxt := `<data>Hello, world!</data>
`
	layoutTxt := `<Layout
	xmlns="urn:speedata.de:2009/publisher/en"
	xmlns:sd="urn:speedata:2009/publisher/functions/en">

	<Record element="data">
	  <PlaceObject>
		<Textblock>
		  <Paragraph>
			<Value select="."/>
		  </Paragraph>
		</Textblock>
	  </PlaceObject>
	</Record>
</Layout>
`

	err = os.WriteFile("data.xml", []byte(dataTxt), 0644)
	if err != nil {
		return err
	}

	err = os.WriteFile("layout.xml", []byte(layoutTxt), 0644)
	if err != nil {
		return err
	}

	return nil
}

// luaTeXInfo returns the path to the TeX binary that will be used and its
// version, extracted from the first line of its '--version' output.
func luaTeXInfo() (binpath string, version string) {
	binpath = getExecutablePath()
	out, err := exec.Command(binpath, "--version").Output()
	if err != nil {
		return binpath, "unknown version"
	}
	// The first line looks like:
	//   This is LuaHBTeX, Version 1.24.0 (TeX Live 2026)
	firstLine := strings.SplitN(string(out), "\n", 2)[0]
	return binpath, strings.TrimSpace(firstLine)
}

func showCredits() {
	fmt.Println("This is the speedata Publisher, version", versionWithPro)
	luatexBin, luatexVersion := luaTeXInfo()
	fmt.Println(`
Copyright 2009-2026 Patrick Gundlach. Licensed under
the GNU Affero GPL License, see
  https://raw.githubusercontent.com/speedata/publisher/develop/COPYING
for details.

This software is built upon and contains third party libraries including:`)
	fmt.Printf("\nLuaTeX (http://www.luatex.org/)\n   binary:  %s\n   %s\n", luatexBin, luatexVersion)
	fmt.Println(`
Camingo Code font (https://www.janfromm.de/typefaces/camingomono/camingocode/, CC BY-ND 3.0)
Crimson text (https://fonts.google.com/specimen/Crimson+Text, SIL Open font license)
goconfig (https://github.com/Unknwon/goconfig)
go-lua (https://github.com/speedata/go-lua)
jing/trang (https://github.com/relaxng/jing-trang)
Parts of the Go library (https://golang.org/)
Saxon (http://saxon.sourceforge.net)
TeX Gyre Heros fonts (http://www.gust.org.pl/projects/e-foundry/tex-gyre/heros)

Contact:
   gundlach@speedata.de
or see the web page
   https://www.speedata.de/imprint/`)

	exitProgram(0)
}

func main() {
	CheckWindowsGUIDoubleClick()
	op := optionparser.NewOptionParser()
	op.On("--address IPADDRESS", "Address to be used for the server mode. Defaults to 127.0.0.1", options)
	op.On("--autoopen", "Open the PDF file", options)
	op.On("--cache METHOD", "Use cache method. One of 'none', 'fast' or 'optimal'. Default is 'optimal'", options)
	op.On("-c NAME", "--config", "Read the config file with the given NAME. Default: 'publisher.cfg'", &configfilename)
	op.On("--credits", "Show credits and exit", showCredits)
	op.On("--no-cutmarks", "Display cutmarks in the document", layoutoptions)
	op.On("--data NAME", "Name of the XML data file. Defaults to 'data.xml'. Use '-' for STDIN (only 1 run possible).", options)
	op.On("--dummy", "Don't read a data file, use '<data />' as input", options)
	op.On("-x", "--extra-dir DIR", "Additional directory for file search", extradir)
	op.On("--extra-xml NAME", "Add this file to the layout file", extraXML)
	op.On("--filter FILTER", "Run Lua filter before publishing starts", options)
	op.On("--generate-completion SHELL", "Print shell completion script (bash, zsh or fish) to stdout and exit", func(shell string) {
		if err := op.GenerateCompletion(shell, "sp", os.Stdout); err != nil {
			log.Fatal(err)
		}
		os.Exit(0)
	})
	op.On("--grid", "Display background grid. Disable with --no-grid", options)
	op.On("--ignore-case", "Ignore case when accessing files in the recursive file list (on a case-insensitive file system)", options)
	op.On("--imagecache PATH", "Set the image cache", options)
	op.On("--inkscape PATH", "Set the path to the inkscape program", options)
	op.On("--jobname NAME", "The name of the resulting PDF file (without extension), default is 'publisher'", options)
	op.On("--no-local", "Add local directory to the search path. Default is true", &addLocalPath)
	op.On("--layout NAME", "Name of the layout file. Defaults to 'layout.xml'", options)
	op.On("--logfile NAME", "Logfile for server mode. Default 'publisher.protocol'. Use STDOUT for standard output and STDERR for standard error.", options)
	op.On("--loglevel LVL", "Set the log level for the console to one of debug, info, warn, error", options)
	op.On("--mainlanguage NAME", "The document's main language in locale format, for example 'en' or 'en_US'.", &mainlanguage)
	op.On("--mode NAME", "Set mode. Multiple modes given in a comma separated list.", options)
	op.On("--outputdir=DIR", "Copy PDF and protocol to this directory", options)
	op.On("--option=OPTION", "Set a specific option", setOption)
	op.On("--pdfversion=VERSION", "Set the PDF version. Default is 1.6", options)
	op.On("--prepend-xml NAME", "Add this file in front of the layout file", prependXML)
	op.On("--port PORT", "Port to be used for the server mode. Defaults to 5266", options)
	op.On("--progress", "Show progress information on standard output", options)
	op.On("--quiet", "Run publisher in silent mode", options)
	op.On("--runs NUM", "Number of publishing runs ", options)
	op.On("--startpage NUM", "The first page number", layoutoptions)
	op.On("--show-gridallocation", "Show the allocated grid cells", layoutoptions)
	op.On("-s", "--suppressinfo", "Suppress optional information (timestamp) and use a fixed document ID", options)
	op.On("--systemfonts", "Use system fonts (not Win XP)", &useSystemFonts)
	op.On("--tempdir=DIR", "Use this directory instead of the system temporary directory", options)
	op.On("--trace", "Show debug messages and some tracing PDF output", layoutoptions)
	op.On("--timeout SEC", "Exit after SEC seconds", options)
	op.On("-v", "--var VAR=VALUE", "Set a variable for the publishing run", setVariable)
	op.On("--varsfile NAME", "Set variables for the publishing run from key=value... file", options)
	op.On("--verbose", "Print a bit of debugging output", options)
	op.On("--version", "Show version information", versioninfo)
	op.On("--wd DIR", "Change working directory", options)
	op.On("--xpath MODE", "Set the xpath mode (old: 'luxor', new: 'lxpath'). Default is lxpath", options)
	op.On("--xml", "Output as (pseudo-)XML (for list-fonts)", options)

	op.Command(cmdHelp, "Show usage help")
	op.Command(cmdClean, "Remove publisher generated files")
	op.Command(cmdCompare, "Compare files for quality assurance")
	op.Command(cmdCheckUpdate, "Check for updates")
	op.Command(cmdClearcache, "Clear image cache")
	op.Command(cmdDoc, "Open documentation")
	op.Command(cmdListFonts, "List installed fonts (use together with --xml for copy/paste)")
	op.Command(cmdNew, "Create simple layout and data file to start. Provide optional directory")
	op.Command(cmdRun, "Start publishing (default)")
	op.Command(cmdServer, "Run as http-api server on localhost port 5266 (configure with --address and --port)")
	op.Command(cmdWatch, "Start watchdog / hotfolder")
	err := op.Parse()

	if errors.Is(err, optionparser.ErrHelp) {
		os.Exit(0)
	}

	if err != nil {
		log.Fatal("Parse error: ", err)
	}

	switch runtime.GOOS {
	case osWindows:
		cfg, err = configurator.ReadFiles(filepath.Join(os.Getenv("APPDATA"), "speedata", "publisher.cfg"))
	default:
		cfg, err = configurator.ReadFiles(filepath.Join(homedir, ".publisher.cfg"), "/etc/speedata/publisher.cfg")
	}
	if err != nil {
		log.Fatal(err)
	}
	// When the user requests another working directory, we should
	// change into the given wd first, before reading the local
	// options
	wdIsSet := false
	if wd := getOption("wd"); wd != "" {
		wdIsSet = true
		err := os.Chdir(wd)
		if err != nil {
			log.Fatal(err)
		}
		log.Printf("Working directory now: %s", wd)
		pwd = wd
	}

	cfg.ReadFile(filepath.Join(pwd, configfilename))

	var command string

	switch len(op.Extra) {
	case 0:
		// no command given, run is the default command
		if cmdOpt := getOption("command"); cmdOpt == "" {
			command = cmdRun
		} else {
			command = cmdOpt
		}
	case 1:
		// great
		command = op.Extra[0]
	default:
		// more than one command given, what should I do?
		command = op.Extra[0]
	}

	// ... but if the local config file has a wd=... option, we should honor this
	// and also honor the settings in that publisher.cfg file
	if !wdIsSet {
		if wd := getOption("wd"); wd != "" {
			err := os.Chdir(wd)
			if err != nil {
				log.Fatal(err)
			}
			log.Printf("Working directory now: %s", wd)
			pwd = wd
			cfg.ReadFile(filepath.Join(pwd, configfilename))
		}
	}
	if getOption("progress") == "true" {
		os.Setenv("SP_PROGRESS", "1")
	} else if getOption("verbose") == "true" {
		verbose = true
		os.Setenv("SP_VERBOSITY", "1")
		fmt.Println("Config files read: ", strings.Join(cfg.Filenames, ", "))
	}

	os.Setenv("SD_LOGLEVEL", getOption("loglevel"))

	if addLocalPath && getOption("addlocalpath") != "false" {
		if homeDir, err := os.UserHomeDir(); err == nil && pwd == homeDir {
			// don't add the home directory, it takes too long
			log.Printf("Not adding home directory %q to search path,\n", homeDir)
			log.Println(" this would result in long startup times. To add the home directroy")
			log.Println(" anyway, use --no-local and add it manually with --extra-dir.")
		} else {
			extradir(pwd)
		}
	}

	// if the user sets systemfonts=true in the config file, we should honor this.
	if optSystemfonts := getOption("systemfonts"); optSystemfonts != "" {
		switch optSystemfonts {
		case stringTrue:
			useSystemFonts = true
		case stringFalse:
			useSystemFonts = false
		}
	}

	if useSystemFonts {
		// FontFolder() is system dependent and defined in extra files
		ff, err := FontFolder()
		if err != nil {
			log.Fatal(err)
		}
		defaults["fontpath"] = ff
	}
	if getOption("suppressinfo") == "true" {
		os.Setenv("SP_SUPPRESSINFO", "TRUE")
	}

	os.Setenv("SP_TEMPDIR", getOption("tempdir"))
	os.Setenv("SP_MAINLANGUAGE", mainlanguage)
	os.Setenv("SP_FONT_PATH", getOption("fontpath"))
	os.Setenv("SP_PATH_REWRITE", getOption("pathrewrite"))
	os.Setenv("SP_INKSCAPE", getOption("inkscape"))
	os.Setenv("SP_INKSCAPECMD", getOption("inkscape-command"))

	if pdfversion := getOption("pdfversion"); pdfversion == "" {
		os.Setenv("SP_PDFMAJORVERSION", "1")
		os.Setenv("SP_PDFMINORVERSION", "7")
	} else {
		vi := strings.Split(pdfversion, ".")
		if len(vi) != 2 {
			fmt.Println("The option pdfversion must have the format X.Y where X is the major version and Y is the minor version number.")
			exitProgram(-1)
		}
		os.Setenv("SP_PDFMAJORVERSION", vi[0])
		os.Setenv("SP_PDFMINORVERSION", vi[1])
	}

	ic := getOption("imagecache")
	if ic == "" {
		options["imagecache"] = filepath.Join(getOption("tempdir"), "sp", "images")
		ic = options["imagecache"]
	}
	if finfo, err := os.Stat(ic); err == nil {
		if !finfo.IsDir() {
			fmt.Println("Image cache is not a directory. Please remove it before running sp")
			fmt.Println(ic)
			exitProgram(1)
		}
	}
	os.Setenv("IMGCACHE", ic)
	cachemethod := getOption("cache")
	os.Setenv("CACHEMETHOD", cachemethod)

	if ed := cfg.String("DEFAULT", "extra-dir"); ed != "" {
		for p := range strings.SplitSeq(ed, string(filepath.ListSeparator)) {
			if abspath, err := filepath.Abs(p); err != nil {
				log.Fatalf("Failed to make %q into an absolute path", p)
			} else {
				extradir(abspath)
			}
		}
	}
	os.Setenv("SP_EXTRA_DIRS", strings.Join(extraDir, string(filepath.ListSeparator)))

	if extraxmloption := getOption("extraxml"); extraxmloption != "" {
		for _, xmlfile := range strings.Split(extraxmloption, ",") {
			extraxml = append(extraxml, xmlfile)
		}
	}

	if prependxmloption := getOption("prependxml"); prependxmloption != "" {
		for _, xmlfile := range strings.Split(prependxmloption, ",") {
			prependxml = append(prependxml, xmlfile)
		}
	}

	os.Setenv("SP_EXTRA_XML", strings.Join(extraxml, ","))
	os.Setenv("SP_PREPEND_XML", strings.Join(prependxml, ","))

	if getOption("ignore-case") == stringTrue {
		os.Setenv("SP_IGNORECASE", "1")
	}

	var exitstatus int

	if seconds := getOption("timeout"); seconds != "" {
		num, err := strconv.Atoi(seconds)
		if err != nil {
			log.Fatal(err)
		}
		log.Printf("Setting timeout to %d seconds", num)
		go timeoutCatcher(num)
	}

	readVariables()

	switch command {
	case cmdHelp:
		op.Help()
		os.Exit(0)
	case cmdRun:
		os.Setenv("SP_PRO", pro)
		jobname := getOption("jobname")
		finishedfilename := fmt.Sprintf("%s.finished", jobname)
		os.Remove(finishedfilename)
		var filterfile string
		if filter := getOption("filter"); filter != "" {
			filterext := filepath.Ext(filter)
			switch filterext {
			case ".xpl":
				fmt.Println("XProc filter not supported anymore.")
				exitstatus = 1
			default:
				if filterext != ".lua" {
					filter = filter + ".lua"
				}
				splibaux.BuildFilelist(extraDir)

				if fn := splibaux.LookupFile(filter); fn == "" {
					fmt.Printf("Cannot find filter %q\n", filter)
					exitstatus = 1
				} else {
					filterfile = fn
					if !runLuaScript(fn) {
						exitstatus = 1
					}
				}
			}
		}
		if exitstatus == 1 {
			exitProgram(exitstatus)
		}
		exitstatus = runPublisher(cachemethod)
		if filterfile != "" {
			runFinalizerCallback()
		}
		writeFinishedfile(finishedfilename)

		// open PDF if necessary
		if getOption("autoopen") == stringTrue {
			openFile(jobname + ".pdf")
		}
	case cmdCompare:
		if len(op.Extra) > 1 {
			dir := op.Extra[1]
			fi, err := os.Stat(dir)
			if err != nil {
				log.Fatal(err)
			}
			if !fi.IsDir() {
				log.Fatalf("%q must be a directory", dir)
			}
			absDir, err := filepath.Abs(dir)
			if err != nil {
				log.Fatal(err)
			}
			// true = write HTML file to $TEMPDIR
			if err = sp.DoCompare(absDir, true, verbose, getOption("referencefilename")); err != nil {
				fmt.Println(err)
				exitstatus = 1
			}
		} else {
			log.Println("Please give one directory")
		}
	case cmdClearcache:
		ic := getOption("imagecache")
		os.RemoveAll(ic)
	case cmdCheckUpdate:
		url := "https://download.speedata.de/versioninfo"
		// Get the data
		resp, err := http.Get(url)
		if err != nil {
			log.Fatal(err)
		}
		var data []byte
		if data, err = io.ReadAll(resp.Body); err != nil {
			log.Fatal(err)
		}
		resp.Body.Close()

		var vi map[string]string
		if err = json.Unmarshal(data, &vi); err != nil {
			log.Fatal(err)
		}

		dev := semver.MustParse(vi["Development"])
		stable := semver.MustParse(vi["Stable"])
		cur := semver.MustParse(version)
		needsUpdate := false
		if dev.GreaterThan(cur) {
			needsUpdate = true
		}
		if stable.GreaterThan(cur) {
			needsUpdate = true
		}
		if needsUpdate {
			fmt.Println("Update available")
			fmt.Println("Installed version:", version)
			fmt.Println("Development version:", dev)
			fmt.Println("Stable version:", stable)
			fmt.Println("\nPlease visit https://download.speedata.de/ for the latest version.")
			exitProgram(1)
		} else {
			fmt.Println("No update available")
			exitProgram(0)
		}
	case cmdClean:
		jobname := getOption("jobname")
		files, err := filepath.Glob(jobname + "*")
		if err != nil {
			log.Fatal(err)
		}
		for _, v := range files {
			switch filepath.Ext(v) {
			case ".vars", ".log", ".protocol", ".dataxml", ".status", ".finished":
				log.Printf("Removing %s", v)
				err = os.Remove(v)
				if err != nil {
					log.Println(err)
				}
			}
			if v == jobname+"-aux.xml" || v == jobname+"-protocol.xml" {
				log.Printf("Removing %s", v)
				err = os.Remove(v)
				if err != nil {
					log.Println(err)
				}
			}
		}
	case cmdDoc:
		// The manual exists in German and English, pick by locale.
		doclang := "en"
		for _, v := range []string{"LC_ALL", "LC_MESSAGES", "LANG"} {
			if val := os.Getenv(v); val != "" {
				if strings.HasPrefix(strings.ToLower(val), "de") {
					doclang = "de"
				}
				break
			}
		}
		// Serve the manual from the local installation if present, otherwise
		// fall back to the online documentation.
		var docroot string
		for _, d := range []string{
			filepath.Join(installdir, "share", "doc"),
			filepath.Join(installdir, "doc", "manual", "public"),
		} {
			if fileExists(filepath.Join(d, "index.html")) {
				docroot = d
				break
			}
		}
		if docroot == "" {
			onlineURL := "https://doc.speedata.de/publisher/" + doclang + "/"
			fmt.Println("Documentation available at " + onlineURL)
			if getOption("autoopen") != "false" {
				openWebPage(onlineURL)
			}
			exitProgram(0)
		}
		ln, err := net.Listen("tcp", "127.0.0.1:5267")
		if err != nil {
			// port already in use, let the system pick a free one
			if ln, err = net.Listen("tcp", "127.0.0.1:0"); err != nil {
				log.Fatal(err)
			}
		}
		docURL := fmt.Sprintf("http://%s/%s/", ln.Addr().String(), doclang)
		fmt.Printf("Serving documentation from %s\n", docroot)
		fmt.Printf("Documentation available at %s (press ctrl-c to quit)\n", docURL)
		if getOption("autoopen") != "false" {
			openWebPage(docURL)
		}
		log.Fatal(http.Serve(ln, http.FileServer(http.Dir(docroot))))
	case cmdListFonts:
		var xml string
		if getOption("xml") == stringTrue {
			xml = "xml"
		}
		cmdline := []string{"--luaonly", filepath.Join(srcdir, "lua", "sdscripts.lua"), inifile, "list-fonts", xml}
		run(getExecutablePath(), cmdline, []string{"LC_ALL=C"})
	case cmdNew:
		err = scaffold(op.Extra[1:]...)
		if err != nil {
			fmt.Println(err)
		}
		exitProgram(0)
	case cmdWatch:
		if pro != "yes" {
			fmt.Println("The hotfolder is part of the Pro package. See https://doc.speedata.de/publisher/en/speedatapro/")
			break
		}
		watchDir := getOptionSection("hotfolder", "hotfolder")
		events := getOptionSection("events", "hotfolder")
		var hotfolderEvents []hotfolder.Event

		for v := range strings.SplitSeq(events, ";") {
			patternCommand := strings.Split(v, ":")
			if len(patternCommand) < 2 {
				log.Fatal("Something is wrong with the configuration file. hotfolder section correct?")
			}
			hotfolderEvent := new(hotfolder.Event)
			hotfolderEvent.Pattern = regexp.MustCompile(patternCommand[0])
			hotfolderEvent.Command = &patternCommand[1]
			hotfolderEvents = append(hotfolderEvents, *hotfolderEvent)
		}

		if watchDir != "" {
			hotfolder.Watch(watchDir, hotfolderEvents)
		} else {
			log.Fatal("Problem with watch dir in section [hotfolder].")
		}
	case cmdServer:
		options["quiet"] = "true"
		options["autoopen"] = "false"
		s := server.NewServer()
		s.Verbose = verbose
		s.ClientExtraDir = strings.Split(getOptionSection("extra-dir", "server"), string(filepath.ListSeparator))
		s.LogLevel = getOptionSection("loglevel", "server")
		s.Port = getSectionOptionWithWarning("port", "server")
		s.Filter = getOptionSection("filter", "server")
		s.Address = getSectionOptionWithWarning("address", "server")
		s.Tempdir = getOption("tempdir")
		s.Runs = getOptionSection("runs", "server")
		logfilename := "publisher.protocol"
		if fn := getSectionOptionWithWarning("logfile", "server"); fn != "" {
			logfilename = fn
		}
		var protocolFile io.Writer
		switch logfilename {
		case "STDOUT":
			protocolFile = os.Stdout
		case "STDERR":
			protocolFile = os.Stderr
		default:
			protocolFile, err = os.Create(logfilename)
			if err != nil {
				log.Fatal(err)
			}
		}
		fmt.Fprintf(protocolFile, "Protocol file for speedata Publisher (%s) - server mode\n", version)
		fmt.Fprintln(protocolFile, "Time:", time.Now().Format(time.ANSIC))
		s.BinaryPath = filepath.Join(bindir, "sp"+exeSuffix)
		s.ProtocolFile = protocolFile
		s.Run()
	default:
		log.Print("unknown command:", command)
		exitProgram(1)
	}
	exitProgram(exitstatus)
}
