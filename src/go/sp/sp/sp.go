// go build -ldflags "-X main.dest linux -X main.version local"  main.go

package main

import (
	"bufio"
	"encoding/xml"
	"fmt"
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
	"strconv"
	"strings"
	"syscall"
	"time"

	"sp"

	"github.com/speedata/configurator"
	"github.com/speedata/hotfolder"
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
	cmdNew        = "new"
	cmdWatch      = "watch"
	cmdHelp       = "help"

	osWindows = "windows"
	osLinux   = "linux"
	osDarwin  = "darwin"

	stringFalse = "false"
	stringTrue  = "true"
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
	prependxml          []string
	starttime           time.Time
	cfg                 *configurator.ConfigData
	runningProcess      []*os.Process
)

// The LuaTeX process writes out a file called "publisher.status"
// which is a valid XML file. Currently the only field is "Errors"
// with the number of errors occurred during the publisher run.
type statuserror struct {
	XMLName xml.Name `xml:"Error"`
	Code    int      `xml:"code,attr"`
	Error   string   `xml:",chardata"`
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
		"quiet":      stringFalse,
		"runs":       "1",
		"tempdir":    os.TempDir(),
		"cache":      "optimal",
		"inkscape":   "inkscape",
	}

	// Let's try to find out the installation dir
	if execlocation, err := os.Executable(); err != nil {
		log.Fatal(err)
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
		exeSuffix = ""
		homedir = os.Getenv("HOME")
	case osLinux:
		defaults["opencommand"] = "xdg-open"
		homedir = os.Getenv("HOME")
		exeSuffix = ""
	case osWindows:
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
		indexpage = filepath.Join("de", "index.html")
	} else {
		indexpage = filepath.Join("en", "index.html")
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
		os.Setenv("PUBLISHER_BASE_PATH", strings.Join([]string{
			filepath.Join(srcdir, "lua"),
			filepath.Join(srcdir, "tex"),
			filepath.Join(srcdir, "hyphenation")}, string(os.PathListSeparator)))
		os.Setenv("LUA_PATH", srcdir+"/lua/?.lua;"+installdir+"/lib/?.lua;"+srcdir+"/lua/common/?.lua;")
		extraDir = append(extraDir, filepath.Join(installdir, "fonts"))
		extraDir = append(extraDir, filepath.Join(installdir, "img"))
		pathToDocumentation = filepath.Join(installdir, "/build/manual/"+indexpage)
	}
	inifile = filepath.Join(srcdir, "lua/sdini.lua")
	os.Setenv("PUBLISHERVERSION", version)
	os.Setenv("LD_LIBRARY_PATH", libdir)
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

// Put string a=b into the variables map
func setVariable(str string) {
	a := strings.Split(str, "=")
	variables[a[0]] = a[1]
}

// Prints the total run time in the log file.
func showDuration() {
	log.Printf("Total run time: %v\n", time.Now().Sub(starttime))
}

// Kill all running child processes
// some process (such as java xproc pipelines) are still in the runningProcess queue, so
// let's try to kill these processes as well, and let's ignore the error of the kill command.
func killallProcesses() {
	for _, proc := range runningProcess {
		proc.Kill()
	}
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
		killallProcesses()
		showDuration()
		os.Exit(-1)
	}
}

func sigIntCatcher() {
	ch := make(chan os.Signal)
	signal.Notify(ch, syscall.SIGINT, syscall.SIGTERM)
	sig := <-ch
	log.Printf("Signal received: %v", sig)
	killallProcesses()
	showDuration()
	os.Exit(0)
}

// Run the given command line
func run(command string, cmdline []string, environ []string) (errorcode int) {
	errorcode = 0
	cmd := exec.Command(command, cmdline...)
	cmd.Env = append(os.Environ(), environ...)
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
	if err := cmd.Wait(); err != nil {
		showDuration()
		log.Print(err)
		if _, ok := err.(*exec.ExitError); ok {
			return -1
		}
	}
	return
}

func readVariables() {
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
}

func saveVariables() {
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

// Add the command line argument to the list of additional XML files for the layout
func extraXML(arg string) {
	extraxml = append(extraxml, arg)
}

// Add the command line argument to the list of additional XML files for the layout
func prependXML(arg string) {
	prependxml = append(prependxml, arg)
}

/// We don't know where the executable is. On systems where we have
/// LuaTeX, we don't want to interfere with the binary so we
/// install a binary called sdluatex (linux package). Therefore
/// we check for `sdluatex` and `luatex`, if the former is not found.
func getExecutablePath() string {
	// 1 check the installdir/bin for sdluatex(.exe)
	// 2 check PATH for sdluatex(.exe)
	// 3 assume simple installation and take luatex(.exe)
	// 4 check then installdir/bin for luatex(.exe)
	// 5 check PATH for luatex(.exe)
	// 6 panic!
	if luatex := getOption("luatex"); luatex != "" {
		return luatex
	}
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

func runPublisher(cachemethod string) (exitstatus int) {
	log.Print("Run speedata publisher")
	defer removeLogfile()

	cmdline := []string{}
	if runtime.GOOS == osWindows {
		// to allow UT8 filenames
		cmdline = append(cmdline, "--cmdx")
	}

	jobname := getOption("jobname")

	exitstatus = 0
	saveVariables()

	f, err := os.Create(jobname + ".protocol")
	if err != nil {
		log.Fatal(err)
	}
	fmt.Fprintf(f, "Protocol file for speedata Publisher (%s)\n", version)
	fmt.Fprintln(f, "Time:", starttime.Format(time.ANSIC))
	f.Close()

	layoutoptions["grid"] = getOption("grid")
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
	if imagehandler := getOption("imagehandler"); imagehandler != "" {
		layoutoptionsSlice = append(layoutoptionsSlice, `imagehandler=`+imagehandler)
	}
	if extensionhandler := getOption("extensionhandler"); extensionhandler != "" {
		layoutoptionsSlice = append(layoutoptionsSlice, `extensionhandler=`+extensionhandler)
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
	env := []string{"LC_ALL=C", "SP_JOBNAME=%s" + jobname}
	for i := 1; i <= runs; i++ {
		if run(getExecutablePath(), cmdline, env) < 0 {
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
		if cachemethod != "none" {
			os.Setenv("CACHEMETHOD", "fast")
		}
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

	// If user supplied an outputdir, copy the PDF and the protocol to that path
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
		return fmt.Errorf("data.xml already exists.")
	}
	_, err = os.Stat("layout.xml")
	if err == nil {
		return fmt.Errorf("layout.xml already exists.")
	}

	dataTxt := `<data>Hello, world!</data>`
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

	err = ioutil.WriteFile("data.xml", []byte(dataTxt), 0644)
	if err != nil {
		return err
	}

	err = ioutil.WriteFile("layout.xml", []byte(layoutTxt), 0644)
	if err != nil {
		return err
	}

	return nil
}

func showCredits() {
	fmt.Println("This is the speedata Publisher, version", version)
	fmt.Println(`
Copyright 2019 speedata GmbH, Berlin. Licensed under
the GNU Affero GPL License, see
  https://raw.githubusercontent.com/speedata/publisher/develop/COPYING
for details.

This software is built upon and contains third party libraries including:

LuaTeX (http://www.luatex.org/)
goconfig (https://github.com/Unknwon/goconfig)
TeX Gyre Heros fonts (http://www.gust.org.pl/projects/e-foundry/tex-gyre/heros)
Parts of the Go library (https://golang.org/)
Blackfriday (https://github.com/russross/blackfriday)
GopherLua (https://github.com/yuin/gopher-lua)
jing/trang (https://github.com/relaxng/jing-trang)

Contact:
   gundlach@speedata.de
or see the web page
   https://www.speedata.de/imprint/`)

	os.Exit(0)
}

func main() {
	op := optionparser.NewOptionParser()
	op.On("--address IPADDRESS", "Address to be used for the server mode. Defaults to 127.0.0.1", options)
	op.On("--autoopen", "Open the PDF file (MacOS X and Linux only)", options)
	op.On("--cache METHOD", "Use cache method. One of 'none', 'fast' or 'optimal'. Default is 'optimal'", options)
	op.On("-c NAME", "--config", "Read the config file with the given NAME. Default: 'publisher.cfg'", &configfilename)
	op.On("--credits", "Show credits and exit", showCredits)
	op.On("--no-cutmarks", "Display cutmarks in the document", layoutoptions)
	op.On("--data NAME", "Name of the XML data file. Defaults to 'data.xml'. Use '-' for STDIN (only 1 run possible).", options)
	op.On("--dummy", "Don't read a data file, use '<data />' as input", options)
	op.On("-x", "--extra-dir DIR", "Additional directory for file search", extradir)
	op.On("--extra-xml NAME", "Add this file to the layout file", extraXML)
	op.On("--filter FILTER", "Run Lua filter before publishing starts", options)
	op.On("--grid", "Display background grid. Disable with --no-grid", options)
	op.On("--ignore-case", "Ignore case when accessing files (on a case-insensitive file system)", options)
	op.On("--imagecache PATH", "Set the image cache", options)
	op.On("--inkscape PATH", "Set the path to the inkscape program", options)
	op.On("--jobname NAME", "The name of the resulting PDF file (without extension), default is 'publisher'", options)
	op.On("--no-local", "Add local directory to the search path. Default is true", &addLocalPath)
	op.On("--layout NAME", "Name of the layout file. Defaults to 'layout.xml'", options)
	op.On("--mainlanguage NAME", "The document's main language in locale format, for example 'en' or 'en_US'.", &mainlanguage)
	op.On("--mode NAME", "Set mode. Multiple modes given in a comma separated list.", options)
	op.On("--outputdir=DIR", "Copy PDF and protocol to this directory", options)
	op.On("--prepend-xml NAME", "Add this file in front of the layout file", prependXML)
	op.On("--port PORT", "Port to be used for the server mode. Defaults to 5266", options)
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

	op.Command(cmdHelp, "Show usage help")
	op.Command(cmdClean, "Remove publisher generated files")
	op.Command(cmdCompare, "Compare files for quality assurance")
	op.Command(cmdClearcache, "Clear image cache")
	op.Command(cmdDoc, "Open documentation")
	op.Command(cmdListFonts, "List installed fonts (use together with --xml for copy/paste)")
	op.Command(cmdNew, "Create simple layout and data file to start. Provide optional directory")
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
		} else if optSystemfonts == stringFalse {
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
	os.Setenv("SP_INKSCAPE", getOption("inkscape"))

	ic := getOption("imagecache")
	if finfo, err := os.Stat(ic); err == nil {
		if !finfo.IsDir() {
			fmt.Println("Image cache is not a directory. Please remove it before running sp")
			fmt.Println(ic)
			os.Exit(1)
		}
	}

	os.Setenv("IMGCACHE", ic)
	cachemethod := getOption("cache")
	os.Setenv("CACHEMETHOD", cachemethod)

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

	if prependxmloption := getOption("prependxml"); prependxmloption != "" {
		for _, xmlfile := range strings.Split(prependxmloption, ",") {
			prependxml = append(prependxml, xmlfile)
		}
	}

	os.Setenv("SD_EXTRA_XML", strings.Join(extraxml, ","))
	os.Setenv("SD_PREPEND_XML", strings.Join(prependxml, ","))
	verbose := false
	if getOption("verbose") != "" {
		verbose = true
		os.Setenv("SP_VERBOSITY", "1")
		fmt.Println("SD_EXTRA_DIRS:", os.Getenv("SD_EXTRA_DIRS"))
		fmt.Println("SD_EXTRA_XML:", os.Getenv("SD_EXTRA_XML"))
		fmt.Println("SD_PREPEND_XML:", os.Getenv("SD_PREPEND_XML"))
	}

	if getOption("ignore-case") == stringTrue {
		os.Setenv("SP_IGNORECASE", "1")
		if verbose {
			fmt.Println("Ignore case for file system access")
		}
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
	case cmdRun:
		jobname := getOption("jobname")
		finishedfilename := fmt.Sprintf("%s.finished", jobname)
		os.Remove(finishedfilename)
		var filterfile string
		if filter := getOption("filter"); filter != "" {
			filterext := filepath.Ext(filter)
			switch filterext {
			case ".lua":
				if !fileExists(filter) {
					fmt.Printf("Lua file %q not found\n", filter)
					exitstatus = 1
				} else {
					filterfile = filter
					if !runLuaScript(filter) {
						exitstatus = 1
					}
				}
			case ".xpl":
				fmt.Println("XProc filter not supported anymore.")
				exitstatus = 1
			default:
				if fileExists(filter + ".lua") {
					filterfile = filter
					if !runLuaScript(filter + ".lua") {
						exitstatus = 1
					}
				} else {
					fmt.Printf("Cannot find filter %q\n", filter)
					exitstatus = 1
				}
			}
		}
		if exitstatus == 1 {
			os.Exit(exitstatus)
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
			sp.DoCompare(absDir, true)
		} else {
			log.Println("Please give one directory")
		}
	case cmdClearcache:
		ic := getOption("imagecache")
		os.RemoveAll(ic)
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
		os.Exit(0)
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
	showDuration()
	os.Exit(exitstatus)
}
