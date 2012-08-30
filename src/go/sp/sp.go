// go build -ldflags "-X main.dest linux -X main.version local"  main.go

package main

import (
	"configurator"
	"fmt"
	"io"
	"log"
	"optionparser"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"syscall"
	"time"
)

var (
	options               map[string]string
	defaults              map[string]string
	layoutoptions         map[string]string
	variables             map[string]string
	installdir            string
	libdir                string
	srcdir                string
	path_to_documentation string // Where the documentation (index.html) is
	inifile               string
	dest                  string // The platform which this script runs on.
	version               string
	homecfg               string
	systemcfg             string
	pwd                   string
	exe_suffix            string
	extra_dir             []string
	starttime             time.Time
	cfg                   *configurator.ConfigData
)

func init() {
	var err error
	log.SetFlags(0)
	starttime = time.Now()
	go signalCatcher()
	pwd, err = os.Getwd()
	if err != nil {
		log.Fatal(err)
	}
	variables = make(map[string]string)
	layoutoptions = make(map[string]string)
	options = make(map[string]string)
	defaults = map[string]string{
		"layout":  "layout.xml",
		"jobname": "publisher",
		"data":    "data.xml",
		"runs":    "1",
	}

	// The problem now is that we don't know where the executable file is
	// if it's in the PATH, it has no ../ prefix
	// if it is relative, make an absolute path from it.

	executable_name := filepath.Base(os.Args[0])
	var bindir string
	if executable_name == os.Args[0] {
		// most likely an absolute path
		bindir, err = exec.LookPath(executable_name)
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
	installdir = filepath.Join(bindir, "..")

	if version == "" {
		version = "local"
	}

	extra_dir = append(extra_dir, pwd)
	// log.Print("Built for platform: ",dest)
	switch os := runtime.GOOS; os {
	case "darwin":
		defaults["opencommand"] = "open"
		exe_suffix = ""
	case "linux":
		defaults["opencommand"] = "xdg-open"
		exe_suffix = ""
	case "windows":
		defaults["opencommand"] = "cmd /C start"
		exe_suffix = ".exe"
	}

	switch dest {
	case "linux-usr":
		libdir = "/usr/share/speedata-publisher/lib"
		srcdir = "/usr/share/speedata-publisher/sw"
		os.Setenv("PUBLISHER_BASE_PATH", "/usr/share/speedata-publisher")
		os.Setenv("LUA_PATH", fmt.Sprintf("%s/lua/?.lua;%s/lua/common/?.lua;", srcdir, srcdir))
		path_to_documentation = "/usr/share/doc/speedata-publisher/index.html"
	case "directory":
		libdir = filepath.Join(installdir, "lib")
		srcdir = filepath.Join(installdir, "sw")
		path_to_documentation = filepath.Join(installdir, "share/doc/index.html")
		os.Setenv("PUBLISHER_BASE_PATH",installdir)
		os.Setenv("LUA_PATH", srcdir+"/lua/?.lua;"+installdir+"/lib/?.lua;"+srcdir+"/lua/common/?.lua;")
	default:
		// local git installation
		libdir = filepath.Join(installdir, "lib")
		srcdir = filepath.Join(installdir, "src")
		os.Setenv("PUBLISHER_BASE_PATH", srcdir)
		os.Setenv("LUA_PATH", srcdir+"/lua/?.lua;"+installdir+"/lib/?.lua;"+srcdir+"/lua/common/?.lua;")
		extra_dir = append(extra_dir, filepath.Join(installdir, "fonts"))
		extra_dir = append(extra_dir, filepath.Join(installdir, "img"))
		path_to_documentation = filepath.Join(installdir, "/build/handbuch_publisher/index.html")
	}
	inifile = filepath.Join(srcdir, "lua/sdini.lua")
	// cfg, err = configurator.ReadFiles("/Users/patrick/.publisher.cfg", path.Join(pwd, "publisher.cfg"))
	cfg, err = configurator.ReadFiles(filepath.Join(pwd, "publisher.cfg"), "/Users/patrick/.publisher.cfg")
	if err != nil {
		log.Fatal(err)
	}
}

func getOption(optionname string) string {
	if options[optionname] != "" {
		return options[optionname]
	}
	if cfg.String("DEFAULT", optionname) != "" {
		return cfg.String("DEFAULT", optionname)
	}
	if defaults[optionname] != "" {
		return defaults[optionname]
	}
	return ""
}

// Open the given file with the system's default program
func openFile(filename string) {
	opencommand := getOption("opencommand")
	cmdname := strings.SplitN(opencommand+" "+filename, " ", 2)
	cmd := exec.Command(cmdname[0], cmdname[1])
	err := cmd.Start()
	if err != nil {
		log.Fatal(err)
	}
	err = cmd.Wait()
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

func signalCatcher() {
	ch := make(chan os.Signal)
	signal.Notify(ch, syscall.SIGINT)
	sig := <-ch
	log.Printf("Signal received: %v", sig)
	showDuration()
	os.Exit(0)
}

// Run the given command line
func run(cmdline string) {
	// Todo: don't split quoted commands
	cmdline_array := strings.Split(cmdline, " ")
	cmd := exec.Command(cmdline_array[0])
	cmd.Args = cmdline_array
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
		log.Fatal(err)
	}
	go io.Copy(os.Stdout, stdout)
	go io.Copy(os.Stderr, stderr)
	err = cmd.Wait()
	if err != nil {
		showDuration()
		log.Print(err)
	}
}

func save_variables() {
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
	extra_dir = append(extra_dir,arg)
}

// We don't know where the executable is and we don't know
// if we should run sdluatex (with libxml2 parser) or simple
// luatex
func getExecutablePath() string {
	// 1 check the installdir/bin for sdluatex(.exe)
	// 2 check PATH for sdluatex(.exe)
	// 3 assume simple installation and take luatex(.exe)
	// 4 check then installdir/bin for luatex(.exe)
	// 5 check PATH for luatex(.exe)
	// 6 panic!
	executable_name := "sdluatex" + exe_suffix
	var p string

	// 1 check the installdir/bin for sdluatex(.exe)
	p = fmt.Sprintf("%s/bin/%s", installdir, executable_name)
	fi, _ := os.Stat(p)
	if fi != nil {
		return p
	}

	// 2 check PATH for sdluatex(.exe)
	p, _ = exec.LookPath(executable_name)
	if p != "" {
		return p
	}

	// 3 assume simple installation and take luatex(.exe)
	executable_name = "luatex" + exe_suffix

	// 4 check then installdir/bin for luatex(.exe)
	p = fmt.Sprintf("%s/bin/%s", installdir, executable_name)
	fi, _ = os.Stat(p)
	if fi != nil {
		return p
	}
	// 5 check PATH for luatex(.exe)
	p, _ = exec.LookPath(executable_name)
	if p != "" {
		return p
	}

	// 6 panic!
	log.Fatal("Can't find sdluatex or luatex binary")
	return ""
}

// Print version information
func versioninfo() {
	log.Println("Version: ",version)
	os.Exit(0)
}

func runPublisher() {
	log.Print("run speedata publisher")

	save_variables()

	f, err := os.Create(getOption("jobname") + ".protocol")
	if err != nil {
		log.Fatal(err)
	}
	fmt.Fprintf(f, "Protocol file for speedata Publisher (%s)\n", version)
	fmt.Fprintln(f, "Time:", starttime.Format(time.ANSIC))
	f.Close()

	// layoutoptions are passed as a command line argument to the publisher
	var layoutoptions_ary []string
	if layoutoptions["grid"] != "" {
		layoutoptions_ary = append(layoutoptions_ary, `showgrid="`+layoutoptions["grid"]+`"`)
	}
	if layoutoptions["startpage"] != "" {
		layoutoptions_ary = append(layoutoptions_ary, `startpage="`+layoutoptions["startpage"]+`"`)
	}
	layoutoptions_cmdline := strings.Join(layoutoptions_ary, ",")
	jobname := getOption("jobname")
	layoutname := getOption("layout")
	dataname := getOption("data")
	exec_name := getExecutablePath()

	runs, err := strconv.Atoi(getOption("runs"))
	if err != nil {
		log.Fatal(err)
	}
	for i := 1; i <= runs; i++ {
		cmdline := fmt.Sprintf("%s --interaction nonstopmode --jobname=%s --ini --lua=%s publisher.tex %s %s %s", exec_name, jobname, inifile, layoutname, dataname, layoutoptions_cmdline)
		run(cmdline)
	}
}

func main() {
	op := optionparser.NewOptionParser()
	op.On("--autoopen", "Open the PDF file (MacOS X and Linux only)", options)
	op.On("--data NAME", "Name of the XML data file. Defaults to 'data.xml'", options)
	op.On("--filter FILTER", "Run XPROC filter before publishing starts", options)
	op.On("--grid", "Display background grid. Disable with --no-grid", layoutoptions)
	op.On("--layout NAME", "Name of the layout file. Defaults to 'layout.xml'", options)
	op.On("--jobname NAME", "The name of the resulting PDF file, default is 'publisher.pdf'", options)
	op.On("--runs NUM", "Number of publishing runs ", options)
	op.On("--startpage NUM", "The first page number", layoutoptions)
	op.On("-v", "--var VAR=VALUE", "Set a variable for the publishing run", setVariable)
	op.On("--version", "Show version information", versioninfo)
	op.On("-x", "--extra-dir DIR", "Additional directory for file search", extradir)
	op.On("--xml", "Output as (pseudo-)XML (for list-fonts)", options)

	op.Command("list-fonts", "List installed fonts (use together with --xml for copy/paste)")
	op.Command("doc", "Open documentation")
	op.Command("watch", "Start watchdog / hotfolder")
	op.Command("run", "Start publishing (default)")
	err := op.Parse()
	if err != nil {
		log.Fatal("Parse error: ", err)
	}

	var command string
	switch len(op.Extra) {
	case 0:
		// no command given, run is the default command 
		command = "run"
	case 1:
		// great
		command = op.Extra[0]
	default:
		// more than one command given, what should I do?
		command = op.Extra[0]
	}

	os.Setenv("SD_EXTRA_DIRS", strings.Join(extra_dir, ":"))

	switch command {
	case "run":
		if filter := getOption("filter"); filter != "" {
			if filepath.Ext(filter) != ".xpl" {
				filter = filter + ".xpl"
			}
			log.Println("Run filter: ", filter)
			os.Setenv("CLASSPATH", libdir+"/calabash.jar:"+libdir+"/saxon9he.jar")
			cmdline := "java com.xmlcalabash.drivers.Main " + filter
			run(cmdline)
		}
		runPublisher()
		// open PDF if necessary
		if getOption("autoopen") == "true" {
			openFile(getOption("jobname") + ".pdf")
		}
	case "doc":
		openFile(path_to_documentation)
		os.Exit(0)
	case "list-fonts":
		var xml string
		if getOption("xml") == "true" {
			xml = "xml"
		}
		cmdline := fmt.Sprintf("%s/bin/sdluatex --luaonly %s/lua/sdscripts.lua %s list-fonts %s", installdir, srcdir, inifile, xml)
		run(cmdline)
	case "watch":
		log.Fatal("not implemented yet.")
	default:
		log.Fatal("unknown command:", command)
	}
	showDuration()
}
