// go build -ldflags "-X main.dest linux -X main.version local"  main.go

package main

import (
	"bufio"
	"configurator"
	"encoding/xml"
	"fmt"
	"hotfolder"
	"io"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"os/user"
	"path/filepath"
	"regexp"
	"runtime"
	"sp"
	"sp/cache"
	"strconv"
	"strings"
	"syscall"
	"time"

	"sp/comm"

	"github.com/speedata/optionparser"
)

const (
	cmdRun        = "run"
	cmdServer     = "server"
	cmdCompare    = "compare"
	cmdClean      = "clean"
	cmdClearcache = "clearcache"
	cmdDoc        = "doc"
	cmdListFonts  = "list-fonts"
	cmdWatch      = "watch"

	strTrue string = "true"
)

var (
	options             map[string]string
	defaults            map[string]string
	layoutoptions       map[string]string
	variables           map[string]string
	installdir          string
	bindir              string
	libdir              string
	srcdir              string
	pathToDocumentation string // Where the documentation (index.html) is
	inifile             string
	dest                string // The platform which this script runs on.
	version             string
	homecfg             string
	systemcfg           string
	pwd                 string
	exeSuffix           string
	homedir             string
	addLocalPath        bool // Add pwd recursively to extra-dir
	useSystemFonts      bool
	configfilename      string
	mainlanguage        string
	extraDir            []string
	extraxml            []string
	starttime           time.Time
	cfg                 *configurator.ConfigData
	runningProcess      []*os.Process
	daemon              *comm.Server
)

// The LuaTeX process writes out a file called "publisher.status"
// which is a valid XML file. Currently the only field is "Errors"
// with the number of errors occured during the publisher run.
type statuserror struct {
	XMLName xml.Name `xml:"Error"`
	Code    int      `xml:"code,attr"`
	Error   string   `xml:",innerxml"`
}

type status struct {
	XMLName xml.Name `xml:"Status"`
	Error   []statuserror
	Errors  int
}

func init() {
	var err error
	log.SetFlags(0)
	starttime = time.Now()
	go sigIntCatcher()
	go sigTermCatcher()
	pwd, err = os.Getwd()
	if err != nil {
		log.Fatal(err)
	}
	variables = make(map[string]string)
	layoutoptions = make(map[string]string)
	options = make(map[string]string)
	defaults = map[string]string{
		"address":    "127.0.0.1",
		"data":       "data.xml",
		"fontpath":   "",
		"grid":       "",
		"imagecache": "",
		"jobname":    "publisher",
		"layout":     "layout.xml",
		"port":       "5266",
		"quiet":      "false",
		"runs":       "1",
		"tempdir":    os.TempDir(),
		"cache":      "optimal",
	}

	// The problem now is that we don't know where the executable file is
	// if it's in the PATH, it has no ../ prefix
	// if it is relative, make an absolute path from it.
	if execdir := filepath.Base(os.Args[0]); execdir == os.Args[0] {
		// most likely an absolute path
		bindir, err = exec.LookPath(execdir)
		if err != nil {
			log.Fatal(err)
		}
		bindir = filepath.Dir(bindir)
	} else {
		// a relative path hopefully
		bindir, err = filepath.Abs(filepath.Dir(os.Args[0]))
		if err != nil {
			log.Fatal(err)
		}
	}
	bindir, err = filepath.Abs(bindir)
	if err != nil {
		log.Fatal(err)
	}

	installdir = filepath.Join(bindir, "..")

	if version == "" {
		version = "local"
	}

	// log.Print("Built for platform: ",dest)
	switch runtime.GOOS {
	case "darwin":
		defaults["opencommand"] = "open"
		exeSuffix = ""
		homedir = os.Getenv("HOME")
	case "linux":
		defaults["opencommand"] = "xdg-open"
		homedir = os.Getenv("HOME")
		exeSuffix = ""
	case "windows":
		defaults["opencommand"] = "cmd /C start"
		exeSuffix = ".exe"

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

	// LC_ALL is something like "de_DE.UTF-8"
	re := regexp.MustCompile("^(d|D)(e|E)")
	var indexpage string
	if re.MatchString(os.Getenv("LANG")) {
		indexpage = "index-de.html"
	} else {
		indexpage = "index.html"
	}

	switch dest {
	case "linux-usr":
		libdir = "/usr/share/speedata-publisher/lib"
		srcdir = "/usr/share/speedata-publisher/sw"
		os.Setenv("PUBLISHER_BASE_PATH", "/usr/share/speedata-publisher")
		os.Setenv("LUA_PATH", fmt.Sprintf("%s/lua/?.lua;%s/lua/common/?.lua;", srcdir, srcdir))
		pathToDocumentation = "/usr/share/doc/speedata-publisher/" + indexpage
	case "directory":
		libdir = filepath.Join(installdir, "share", "lib")
		srcdir = filepath.Join(installdir, "sw")
		pathToDocumentation = filepath.Join(installdir, "share/doc/"+indexpage)
		os.Setenv("PUBLISHER_BASE_PATH", srcdir)
		os.Setenv("LUA_PATH", srcdir+"/lua/?.lua;"+installdir+"/lib/?.lua;"+srcdir+"/lua/common/?.lua;")
	default:
		// local git installation
		libdir = filepath.Join(installdir, "lib")
		srcdir = filepath.Join(installdir, "src")
		os.Setenv("PUBLISHER_BASE_PATH", srcdir)
		os.Setenv("LUA_PATH", srcdir+"/lua/?.lua;"+installdir+"/lib/?.lua;"+srcdir+"/lua/common/?.lua;")
		extraDir = append(extraDir, filepath.Join(installdir, "fonts"))
		extraDir = append(extraDir, filepath.Join(installdir, "img"))
		pathToDocumentation = filepath.Join(installdir, "/build/manual/"+indexpage)
	}
	inifile = filepath.Join(srcdir, "lua/sdini.lua")
	os.Setenv("PUBLISHERVERSION", version)
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
	cmdname := strings.SplitN(opencommand, " ", -1)
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

// Put string a=b into the variabls map
func setVariable(str string) {
	a := strings.Split(str, "=")
	variables[a[0]] = a[1]
}

func showDuration() {
	log.Printf("Total run time: %v\n", time.Now().Sub(starttime))
}

func timeoutCatcher(seconds int) {
	timeout := make(chan bool, 1)
	go func() {
		time.Sleep(time.Duration(seconds) * time.Second)
		timeout <- true
	}()
	select {
	case <-timeout:
		log.Printf("\n\nTimeout after %d seconds", seconds)
		showDuration()
		os.Exit(-1)

	}
}

// fixme: move the next two functions into one function
func sigTermCatcher() {
	ch := make(chan os.Signal)
	signal.Notify(ch, syscall.SIGTERM)
	sig := <-ch
	log.Printf("Signal received: %v", sig)
	for _, proc := range runningProcess {
		err := proc.Kill()
		if err != nil {
			log.Fatal(err)
		}
	}
	showDuration()
	os.Exit(0)
}

func sigIntCatcher() {
	ch := make(chan os.Signal)
	signal.Notify(ch, syscall.SIGINT)
	sig := <-ch
	log.Printf("Signal received: %v", sig)
	for _, proc := range runningProcess {
		err := proc.Kill()
		if err != nil {
			log.Fatal(err)
		}
	}
	showDuration()
	os.Exit(0)
}

// Run the given command line
func run(cmdline string) (success bool) {
	var commandlineArray []string
	// The cmdline can have quoted strings. We remove the quotation marks
	// by this ugly construct. That way strings such as "--data=foo\ bar" can
	// be passed to the subprocess.
	j := regexp.MustCompile("([^ \"]+)|\"([^\"]+)\"")
	ret := j.FindAllStringSubmatch(cmdline, -1)
	for _, m := range ret {
		if m[2] != "" {
			commandlineArray = append(commandlineArray, m[2])
		} else {
			commandlineArray = append(commandlineArray, m[0])
		}
	}
	cmd := exec.Command(commandlineArray[0])
	cmd.Args = commandlineArray
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
		success = false
		return
	}
	runningProcess = append(runningProcess, cmd.Process)

	if getOption("quiet") == strTrue {
		go io.Copy(ioutil.Discard, stdout)
		go io.Copy(ioutil.Discard, stderr)
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
	err = cmd.Wait()

	if err != nil {
		showDuration()
		log.Print(err)
		success = false
		return
	}
	success = cmd.ProcessState.Success()
	return
}

func saveVariables() {
	if fn := getOption("varsfile"); fn != "" {
		// Read vars-file
		f, err := os.Open(fn)
		if err != nil {
			fmt.Println("File", fn, "not found. Exit.")
			os.Exit(-1)
		}
		fmt.Print("Read file ", fn, "...")
		s := bufio.NewScanner(f)
		// Read each line
		for s.Scan() {
			res := strings.Split(s.Text(), "=")
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
		for _, keyvalue := range strings.Split(vars, ",") {
			tmp := strings.Split(keyvalue, "=")
			if len(tmp) == 2 {
				variables[tmp[0]] = tmp[1]
			}
		}
	}

	jobname := getOption("jobname")
	f, err := os.Create(jobname + ".vars")
	if err != nil {
		log.Fatal(err)
	}
	fmt.Fprintln(f, "return { ")
	for key, value := range variables {
		fmt.Fprintf(f, `["%s"] = "%s", `+"\n", key, value)
	}
	fmt.Fprintln(f, "} ")
	f.Close()
}

// add the command line argument (extra-dir) into the slice
func extradir(arg string) {
	extraDir = append(extraDir, arg)
}

// Add the commandline argument to the list of additional XML files for the layout
func extraXML(arg string) {
	extraxml = append(extraxml, arg)
}

/// We don't know where the executable is. On systems where we have
/// LuaTeX, we don't want to interfere with the binary so we
/// install a binary called sdluatex (linux package). Therefore
/// we check for `sdluatex` and `luatex`, of the former is not found.
func getExecutablePath() string {
	// 1 check the installdir/bin for sdluatex(.exe)
	// 2 check PATH for sdluatex(.exe)
	// 3 assume simple installation and take luatex(.exe)
	// 4 check then installdir/bin for luatex(.exe)
	// 5 check PATH for luatex(.exe)
	// 6 panic!
	executableName := "sdluatex" + exeSuffix
	var p string

	// 0 check the installdir/bin for sdluatex(.exe)
	p = filepath.Join(installdir, "sdluatex", executableName)
	fi, _ := os.Stat(p)
	if fi != nil {
		return p
	}

	// 1 check the installdir/bin for sdluatex(.exe)
	p = fmt.Sprintf("%s/bin/%s", installdir, executableName)
	fi, _ = os.Stat(p)
	if fi != nil {
		return p
	}

	// 2 check PATH for sdluatex(.exe)
	p, _ = exec.LookPath(executableName)
	if p != "" {
		return p
	}

	// 3 assume simple installation and take luatex(.exe)
	executableName = "luatex" + exeSuffix

	// 3.5 check the installdir/bin for sdluatex(.exe)
	p = filepath.Join(installdir, "sdluatex", executableName)
	fi, _ = os.Stat(p)
	if fi != nil {
		return p
	}

	// 4 check then installdir/bin for luatex(.exe)
	p = fmt.Sprintf("%s/bin/%s", installdir, executableName)
	fi, _ = os.Stat(p)
	if fi != nil {
		return p
	}
	// 5 check PATH for luatex(.exe)
	p, _ = exec.LookPath(executableName)
	if p != "" {
		return p
	}

	// 6 panic!
	log.Fatal("Can't find sdluatex or luatex binary")
	return ""
}

// Print version information
func versioninfo() {
	log.Println("Version: ", version)
	os.Exit(0)
}

// copy a file from srcpath to destpath and make
// directory if necessary
func copyFile(srcpath, destpath string) error {

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
	ioutil.WriteFile(path, []byte("finished\n"), 0600)
}

func runPublisher() (exitstatus int) {
	log.Print("Run speedata publisher")
	defer removeLogfile()

	exitstatus = 0
	saveVariables()

	f, err := os.Create(getOption("jobname") + ".protocol")
	if err != nil {
		log.Fatal(err)
	}
	fmt.Fprintf(f, "Protocol file for speedata Publisher (%s)\n", version)
	fmt.Fprintln(f, "Time:", starttime.Format(time.ANSIC))
	f.Close()

	layoutoptions["grid"] = getOption("grid")

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
	layoutoptionsCommandline := strings.Join(layoutoptionsSlice, ",")
	jobname := getOption("jobname")
	layoutname := filepath.Clean(getOption("layout"))
	dataname := filepath.Clean(getOption("data"))
	execName := getExecutablePath()
	if dummyData := getOption("dummy"); dummyData == strTrue {
		dataname = "-dummy"
	}
	os.Setenv("SP_JOBNAME", jobname)

	runs, err := strconv.Atoi(getOption("runs"))
	if err != nil {
		log.Fatal(err)
	}
	for i := 1; i <= runs; i++ {
		go daemon.Run()
		cmdline := fmt.Sprintf(`"%s" --interaction nonstopmode "--jobname=%s" --ini "--lua=%s" publisher.tex %q %q %q`, execName, jobname, inifile, layoutname, dataname, layoutoptionsCommandline)
		if !run(cmdline) {
			exitstatus = -1
			v := status{}
			v.Errors = 1
			v.Error = append(v.Error, statuserror{Error: "Error executing sdluatex", Code: 1})
			data, nerr := xml.Marshal(v)
			if nerr != nil {
				log.Fatal(nerr)
			}
			err = ioutil.WriteFile(fmt.Sprintf("%s.status", jobname), data, 0600)
			if err != nil {
				log.Fatal(err)
			}
			writeFinishedfile(fmt.Sprintf("%s.finished", getOption("jobname")))
			os.Exit(-1)
			break
		}
		os.Setenv("CACHEMETHOD", "fast")
	}
	// todo: DRY code -> server/status
	data, err := ioutil.ReadFile(fmt.Sprintf("%s.status", jobname))
	if err == nil {
		v := new(status)
		err = xml.Unmarshal(data, &v)
		if err != nil {
			log.Printf("Error reading status XML: %v", err)
		} else {
			for _, er := range v.Error {
				exitstatus = er.Code
				break
			}
		}
	}

	// If user supplied an outpath, copy the PDF and the protocol to that path
	p := getOption("outputdir")
	if p != "" {
		pdffilename := jobname + ".pdf"
		protocolfilename := jobname + ".protocol"
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

func showCredits() {
	fmt.Println("This is the speedata Publisher, version", version)
	fmt.Println(`
Copyright 2017 speedata GmbH, Berlin. Licensed under
the GNU Affero GPL License, see
  https://raw.githubusercontent.com/speedata/publisher/develop/COPYING
for details.

This software is built upon and contains third party libraries including:

LuaTeX (http://www.luatex.org/)
goconfig (https://github.com/Unknwon/goconfig)
TeX Gyre Heros fonts (http://www.gust.org.pl/projects/e-foundry/tex-gyre/heros)
Parts of the Go library (https://code.google.com/p/go/)
Blackfriday (https://github.com/russross/blackfriday)

Contact:
   gundlach@speedata.de
or see the web page
   https://github.com/speedata/publisher/wiki/contact`)

	os.Exit(0)
}

func main() {
	op := optionparser.NewOptionParser()
	op.On("--address IPADDRESS", "Address to be used for the server mode. Defaults to 127.0.0.1", options)
	op.On("--autoopen", "Open the PDF file (MacOS X and Linux only)", options)
	op.On("--cache METHOD", "Use cache method. One of 'fast' or 'optimal'. Default is 'optimal'", options)
	op.On("-c NAME", "--config", "Read the config file with the given NAME. Default: 'publisher.cfg'", &configfilename)
	op.On("--credits", "Show credits and exit", showCredits)
	op.On("--no-cutmarks", "Display cutmarks in the document", layoutoptions)
	op.On("--data NAME", "Name of the XML data file. Defaults to 'data.xml'. Use '-' for STDIN", options)
	op.On("--dummy", "Don't read a data file, use '<data />' as input", options)
	op.On("-x", "--extra-dir DIR", "Additional directory for file search", extradir)
	op.On("--extra-xml NAME", "Add this file to the layout file", extraXML)
	op.On("--filter FILTER", "Run XProc or Lua filter before publishing starts", options)
	op.On("--grid", "Display background grid. Disable with --no-grid", options)
	op.On("--ignore-case", "Ignore case when accessing files (on a case-insensitive file system)", options)
	op.On("--no-local", "Add local directory to the search path. Default is true", &addLocalPath)
	op.On("--layout NAME", "Name of the layout file. Defaults to 'layout.xml'", options)
	op.On("--jobname NAME", "The name of the resulting PDF file (without extension), default is 'publisher'", options)
	op.On("--mainlanguage NAME", "The document's main language in locale format, for example 'en' or 'en_US'.", &mainlanguage)
	op.On("--outputdir=DIR", "Copy PDF and protocol to this directory", options)
	op.On("--port PORT", "Port to be used for the server mode. Defaults to 5266", options)
	op.On("--profile", "Run publisher with profiling on (internal use)", options)
	op.On("--quiet", "Run publisher in silent mode", options)
	op.On("--runs NUM", "Number of publishing runs ", options)
	op.On("--startpage NUM", "The first page number", layoutoptions)
	op.On("--show-gridallocation", "Show the allocated grid cells", layoutoptions)
	op.On("--systemfonts", "Use system fonts (not Win XP)", &useSystemFonts)
	op.On("--tempdir=DIR", "Use this directory instead of the system temporary directory", options)
	op.On("--trace", "Show debug messages and some tracing PDF output", layoutoptions)
	op.On("--timeout SEC", "Exit after SEC seconds", options)
	op.On("-v", "--var VAR=VALUE", "Set a variable for the publishing run", setVariable)
	op.On("--varsfile NAME", "Set variables for the publishing run from key=value... file", options)
	op.On("--verbose", "Print a bit of debugging output", options)
	op.On("--version", "Show version information", versioninfo)
	op.On("--wd DIR", "Change working directory", options)
	op.On("--xml", "Output as (pseudo-)XML (for list-fonts)", options)

	op.Command(cmdClean, "Remove publisher generated files")
	op.Command(cmdCompare, "Compare files for quality assurance")
	op.Command(cmdClearcache, "Clear image cache")
	op.Command(cmdDoc, "Open documentation")
	op.Command(cmdListFonts, "List installed fonts (use together with --xml for copy/paste)")
	op.Command(cmdRun, "Start publishing (default)")
	op.Command(cmdServer, "Run as http-api server on localhost port 5266 (configure with --address and --port)")
	op.Command(cmdWatch, "Start watchdog / hotfolder")
	err := op.Parse()
	if err != nil {
		log.Fatal("Parse error: ", err)
	}

	var command string
	switch len(op.Extra) {
	case 0:
		// no command given, run is the default command
		command = cmdRun
	case 1:
		// great
		command = op.Extra[0]
	default:
		// more than one command given, what should I do?
		command = op.Extra[0]
	}

	cfg, err = configurator.ReadFiles(filepath.Join(homedir, ".publisher.cfg"), "/etc/speedata/publisher.cfg")
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

	if addLocalPath {
		extraDir = append(extraDir, pwd)
	}

	// if the user sets systemfonts=true in the config file, we should honor this.
	if optSystemfonts := getOption("systemfonts"); optSystemfonts != "" {
		if optSystemfonts == "true" {
			useSystemFonts = true
		} else if optSystemfonts == "false" {
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

	if getOption("imagecache") == "" {
		options["imagecache"] = filepath.Join(getOption("tempdir"), "sp", "images")
	}
	os.Setenv("SP_TEMPDIR", getOption("tempdir"))
	os.Setenv("SP_MAINLANGUAGE", mainlanguage)
	os.Setenv("SP_FONT_PATH", getOption("fontpath"))
	os.Setenv("SP_PATH_REWRITE", getOption("pathrewrite"))
	os.Setenv("IMGCACHE", getOption("imagecache"))
	os.Setenv("CACHEMETHOD", getOption("cache"))

	if ed := cfg.String("DEFAULT", "extra-dir"); ed != "" {
		abspath, err := filepath.Abs(ed)
		if err != nil {
			log.Fatal("Cannot find directory", ed)
		}
		extraDir = append(extraDir, abspath)
	}
	os.Setenv("SD_EXTRA_DIRS", strings.Join(extraDir, string(filepath.ListSeparator)))

	if extraxmloption := getOption("extraxml"); extraxmloption != "" {
		for _, xmlfile := range strings.Split(extraxmloption, ",") {
			extraxml = append(extraxml, xmlfile)
		}
	}

	os.Setenv("SD_EXTRA_XML", strings.Join(extraxml, ","))
	verbose := false
	if getOption("verbose") != "" {
		verbose = true
		os.Setenv("SP_VERBOSITY", "1")
		fmt.Println("SD_EXTRA_DIRS:", os.Getenv("SD_EXTRA_DIRS"))
		fmt.Println("SD_EXTRA_XML:", os.Getenv("SD_EXTRA_XML"))
	}

	if getOption("ignore-case") == strTrue {
		os.Setenv("SP_IGNORECASE", "1")
		if verbose {
			fmt.Println("Ignore case for file system access")
		}
	}

	var exitstatus int
	if getOption("profile") != "" {
		fmt.Println("Profiling publisher run. Removing lprof_* now.")
		os.Setenv("SD_PROFILER", strTrue)
		files, err := filepath.Glob("lprof_*")
		if err != nil {
			log.Fatal(err)
		}
		for _, filename := range files {
			err = os.Remove(filename)
			if err != nil {
				log.Fatal(err)
			}
		}
	}

	if seconds := getOption("timeout"); seconds != "" {
		num, err := strconv.Atoi(seconds)
		if err != nil {
			log.Fatal(err)
		}
		log.Printf("Setting timeout to %d seconds", num)
		go timeoutCatcher(num)
	}

	// There is no need for the internal daemon when we do the other commands
	switch command {
	case cmdRun, cmdServer:
		daemon = comm.NewServer()
	}

	switch command {
	case cmdRun:
		jobname := getOption("jobname")
		finishedfilename := fmt.Sprintf("%s.finished", jobname)
		os.Remove(finishedfilename)

		if filter := getOption("filter"); filter != "" {
			filterext := filepath.Ext(filter)
			switch filterext {
			case ".lua":
				if !fileExists(filter) {
					fmt.Printf("Lua file %q not found\n", filter)
					exitstatus = 1
				} else {
					runLuaScript(filter)
				}
			case ".xpl":
				if !fileExists(filter) {
					fmt.Printf("XProc file %q not found\n", filter)
					exitstatus = 1
				} else {
					runXProcPipeline(filter)
				}
			default:
				if fileExists(filter + ".lua") {
					runLuaScript(filter + ".lua")
				} else if fileExists(filter + ".xpl") {
					runXProcPipeline(filter + ".xpl")
				} else {
					fmt.Printf("Cannot find filter %q\n", filter)
					exitstatus = 1
				}
			}
		}
		if exitstatus == 1 {
			os.Exit(exitstatus)
		}
		exitstatus = runPublisher()
		// profiler requested?
		if getOption("profile") != "" {
			fmt.Println("Run 'summary.lua' on resulting lprof_* file.")
			files, err := filepath.Glob("lprof_*")
			if err != nil {
				log.Fatal(err)
			}
			if len(files) != 1 {
				log.Println("Profiling not done, expecting exactly one file matching lprof_*.")
			} else {
				cmdline := fmt.Sprintf(`"%s" --luaonly "%s/lua/summary.lua"  -v %s`, getExecutablePath(), srcdir, files[0])
				run(cmdline)
			}

		}
		writeFinishedfile(finishedfilename)

		// open PDF if necessary
		if getOption("autoopen") == strTrue {
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
			sp.DoCompare(absDir)
		} else {
			log.Println("Please give one directory")
		}
	case cmdClearcache:
		cache.Clear()
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
			if v == jobname+"-aux.xml" {
				log.Printf("Removing %s", v)
				err = os.Remove(v)
				if err != nil {
					log.Println(err)
				}
			}
		}
	case cmdDoc:
		openFile(pathToDocumentation)
		os.Exit(0)
	case cmdListFonts:
		var xml string
		if getOption("xml") == strTrue {
			xml = "xml"
		}

		cmdline := fmt.Sprintf(`"%s" --luaonly "%s/lua/sdscripts.lua" "%s" list-fonts %s`, getExecutablePath(), srcdir, inifile, xml)
		run(cmdline)
	case cmdWatch:
		watchDir := getOptionSection("hotfolder", "hotfolder")
		events := getOptionSection("events", "hotfolder")
		var hotfolderEvents []hotfolder.Event

		for _, v := range strings.Split(events, ";") {
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
		runServer(getOption("port"), getOption("address"), getOption("tempdir"))
	default:
		log.Fatal("unknown command:", command)
	}
	if daemon != nil {
		daemon.Close()
	}
	showDuration()
	os.Exit(exitstatus)
}
