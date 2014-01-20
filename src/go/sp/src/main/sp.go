// go build -ldflags "-X main.dest linux -X main.version local"  main.go

package main

import (
	"configurator"
	"encoding/xml"
	"fmt"
	"hotfolder"
	"io"
	"io/ioutil"
	"log"
	"optionparser"
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
	homedir               string
	add_local_path        bool // Add pwd recursively to extra-dir
	configfilename        string
	extra_dir             []string
	starttime             time.Time
	cfg                   *configurator.ConfigData
	running_processes     []*os.Process
)

// The LuaTeX process writes out a file called "publisher.status"
// which is a valid XML file. Currently the only field is "Errors"
// with the number of errors occured during the publisher run.
type status struct {
	Errors int
}

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

	// log.Print("Built for platform: ",dest)
	switch runtime.GOOS {
	case "darwin":
		defaults["opencommand"] = "open"
		exe_suffix = ""
		homedir = os.Getenv("HOME")
	case "linux":
		defaults["opencommand"] = "xdg-open"
		homedir = os.Getenv("HOME")
		exe_suffix = ""
	case "windows":
		defaults["opencommand"] = "cmd /C start"
		exe_suffix = ".exe"

		me, err := user.Current()
		if err != nil {
			log.Fatal(err)
		}
		homedir = me.HomeDir
	}
	add_local_path = true
	configfilename = "publisher.cfg"

	// FontFolder() is system dependent and defined in extra files
	ff, err := FontFolder()
	if err != nil {
		log.Fatal(err)
	}
	defaults["fontpath"] = ff

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
		path_to_documentation = "/usr/share/doc/speedata-publisher/" + indexpage
	case "directory":
		libdir = filepath.Join(installdir, "share", "lib")
		srcdir = filepath.Join(installdir, "sw")
		path_to_documentation = filepath.Join(installdir, "share/doc/"+indexpage)
		os.Setenv("PUBLISHER_BASE_PATH", installdir)
		os.Setenv("LUA_PATH", srcdir+"/lua/?.lua;"+installdir+"/lib/?.lua;"+srcdir+"/lua/common/?.lua;")
	default:
		// local git installation
		libdir = filepath.Join(installdir, "lib")
		srcdir = filepath.Join(installdir, "src")
		os.Setenv("PUBLISHER_BASE_PATH", srcdir)
		os.Setenv("LUA_PATH", srcdir+"/lua/?.lua;"+installdir+"/lib/?.lua;"+srcdir+"/lua/common/?.lua;")
		extra_dir = append(extra_dir, filepath.Join(installdir, "fonts"))
		extra_dir = append(extra_dir, filepath.Join(installdir, "img"))
		path_to_documentation = filepath.Join(installdir, "/build/manual/"+indexpage)
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
		os.Exit(1)

	}
}

func signalCatcher() {
	ch := make(chan os.Signal)
	signal.Notify(ch, syscall.SIGINT)
	sig := <-ch
	log.Printf("Signal received: %v", sig)
	for _, proc := range running_processes {
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
	var cmdline_array []string
	// The cmdline can have quoted strings. We remove the quotation marks
	// by this ugly construct. That way strings such as "--data=foo\ bar" can
	// be passed to the subprocess.
	j := regexp.MustCompile("([^ \"]+)|\"([^\"]+)\"")
	ret := j.FindAllStringSubmatch(cmdline, -1)
	for _, m := range ret {
		if m[2] != "" {
			cmdline_array = append(cmdline_array, m[2])
		} else {
			cmdline_array = append(cmdline_array, m[0])
		}
	}
	cmd := exec.Command(cmdline_array[0])
	cmd.Args = cmdline_array
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
		log.Fatal(err)
	}
	running_processes = append(running_processes, cmd.Process)
	go io.Copy(os.Stdout, stdout)
	go io.Copy(os.Stderr, stderr)
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
	}
	success = cmd.ProcessState.Success()
	return
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
	extra_dir = append(extra_dir, arg)
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
	log.Println("Version: ", version)
	os.Exit(0)
}

// copy a file from srcpath to destpath and make
// directory if necessary
func copy_file(srcpath, destpath string) error {

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

func runPublisher() (exitstatus int) {
	log.Print("run speedata publisher")
	defer removeLogfile()
	exitstatus = 0
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
		layoutoptions_ary = append(layoutoptions_ary, `showgrid=`+layoutoptions["grid"])
	}
	if layoutoptions["show-gridallocation"] != "" {
		layoutoptions_ary = append(layoutoptions_ary, `showgridallocation=`+layoutoptions["show-gridallocation"])
	}
	if layoutoptions["startpage"] != "" {
		layoutoptions_ary = append(layoutoptions_ary, `startpage=`+layoutoptions["startpage"])
	}
	if layoutoptions["trace"] != "" {
		layoutoptions_ary = append(layoutoptions_ary, `trace=`+layoutoptions["trace"])
	}
	layoutoptions_cmdline := strings.Join(layoutoptions_ary, ",")
	jobname := getOption("jobname")
	layoutname := getOption("layout")
	dataname := getOption("data")
	exec_name := getExecutablePath()
	dummy_data := getOption("dummy")
	if dummy_data == "true" {
		dataname = "-dummy"
	}

	runs, err := strconv.Atoi(getOption("runs"))
	if err != nil {
		log.Fatal(err)
	}
	for i := 1; i <= runs; i++ {
		cmdline := fmt.Sprintf(`"%s" --interaction nonstopmode "--jobname=%s" --ini "--lua=%s" publisher.tex %q %q %q`, exec_name, jobname, inifile, layoutname, dataname, layoutoptions_cmdline)
		if !run(cmdline) {
			exitstatus = 1
		}
	}
	data, err := ioutil.ReadFile(fmt.Sprintf("%s.status", jobname))
	if err == nil {
		v := new(status)
		err = xml.Unmarshal(data, &v)
		if err != nil {
			log.Printf("Error reading status XML: %v", err)
		} else {
			if v.Errors != 0 {
				exitstatus = 1
			}
		}
	}

	// If user supplied an outpath, copy the PDF and the protocol to that path
	p := getOption("outputdir")
	if p != "" {
		pdffilename := jobname + ".pdf"
		protocolfilename := jobname + ".protocol"
		err = copy_file(pdffilename, filepath.Join(p, pdffilename))
		if err != nil {
			log.Println(err)
			return
		}
		err = copy_file(protocolfilename, filepath.Join(p, protocolfilename))
		if err != nil {
			log.Println(err)
			return
		}
	}
	return
}

func compareTwoPages(sourcefile, referencefile, dummyfile string) bool {
	res, err := exec.Command("compare", "-metric", "mae", sourcefile, referencefile, dummyfile).CombinedOutput()
	if err != nil {
		log.Println(string(res))
		log.Fatal(err)
	}
	delta, err := strconv.ParseFloat(strings.Split(string(res), " ")[0], 32)
	if err != nil {
		log.Fatal(err)
	}
	if delta > 0.6 {
		log.Println("Delta is", delta)
		return false
	}
	return true
}

func newer(src, dest string) bool {
	dest_fi, err := os.Stat(dest)
	if err != nil {
		return true
	}
	src_fi, err := os.Stat(src)
	if err != nil {
		panic(fmt.Sprintf("Source %s does not exist!", src))
	}
	return dest_fi.ModTime().Before(src_fi.ModTime())
}

func convertReference(soureFiles []string) error {
	var dest string
	if len(soureFiles) == 1 {
		dest = "reference.png"
	} else {
		dest = "reference-1.png"
	}
	if newer("reference.pdf", dest) {
		err := exec.Command("convert", "reference.pdf", "+adjoin", "reference.png").Run()
		return err
	}
	return nil
}

func runComparison(info os.FileInfo) {
	log.Println("Run comparison in directory", info.Name())

	sourceFiles, err := filepath.Glob("source*.png")
	if err != nil {
		log.Fatal(err)
	}
	// Let's remove the old source files, otherwise
	// the number of pages (below) might
	// be incorrect which results in a fatal
	// error
	for _, name := range sourceFiles {
		err = os.Remove(name)
		if err != nil {
			log.Println(err)
		}
	}

	err = exec.Command("sp").Run()
	if err != nil {
		log.Fatal(err)
	}
	err = exec.Command("convert", "publisher.pdf", "+adjoin", "source.png").Run()
	if err != nil {
		log.Fatal(err)
	}

	sourceFiles, err = filepath.Glob("source*.png")
	if err != nil {
		log.Fatal(err)
	}
	number_of_sourcefiles := len(sourceFiles)
	badPages := make([]int, 0, number_of_sourcefiles)

	err = convertReference(sourceFiles)
	if err != nil {
		log.Fatal(err)
	}

	if number_of_sourcefiles == 1 {
		if !compareTwoPages("source.png", "reference.png", "pagediff.png") {
			badPages = append(badPages, 1)
		}
	} else {
		for i := 0; i < number_of_sourcefiles; i++ {
			sourceFile := fmt.Sprintf("source-%d.png", i)
			referenceFile := fmt.Sprintf("reference-%d.png", i)
			dummyFile := fmt.Sprintf("pagediff-%d.png", i)
			if !compareTwoPages(sourceFile, referenceFile, dummyFile) {
				badPages = append(badPages, i)
			}
		}
	}

	if len(badPages) > 0 {
		log.Println("Comparison failed. Bad pages are:", badPages)
	} else {
		log.Println("OK")
	}
}

func compare(path string, info os.FileInfo, err error) error {
	if info.IsDir() {
		if err := os.Chdir(path); err != nil {
			log.Println(err)
			return err
		}
		if _, err := os.Stat("publisher.cfg"); err == nil {
			// publisher.cfg exists, run comparison here
			runComparison(info)
		} else if _, err := os.Stat("layout.xml"); err == nil {
			runComparison(info)
		}
		return nil
	}
	return nil
}

func main() {
	op := optionparser.NewOptionParser()
	op.On("--autoopen", "Open the PDF file (MacOS X and Linux only)", options)
	op.On("--data NAME", "Name of the XML data file. Defaults to 'data.xml'. Use '-' for STDIN", options)
	op.On("--dummy", "Don't read a data file, use '<data />' as input", options)
	op.On("-c NAME", "--config", "Read the config file with the given NAME. Default: 'publisher.cfg'", &configfilename)
	op.On("-x", "--extra-dir DIR", "Additional directory for file search", extradir)
	op.On("--filter FILTER", "Run XPROC filter before publishing starts", options)
	op.On("--grid", "Display background grid. Disable with --no-grid", layoutoptions)
	op.On("--no-local", "Add local directory to the search path. Default is true", &add_local_path)
	op.On("--layout NAME", "Name of the layout file. Defaults to 'layout.xml'", options)
	op.On("--jobname NAME", "The name of the resulting PDF file (without extension), default is 'publisher'", options)
	op.On("--outputdir=DIR", "Copy PDF and protocol to this directory", options)
	op.On("--profile", "Run publisher with profiling on (internal use)", options)
	op.On("--runs NUM", "Number of publishing runs ", options)
	op.On("--startpage NUM", "The first page number", layoutoptions)
	op.On("--show-gridallocation", "Show the allocated grid cells", layoutoptions)
	op.On("--trace", "Show debug messages and some tracing PDF output", layoutoptions)
	op.On("--timeout SEC", "Exit after SEC seconds", options)
	op.On("-v", "--var VAR=VALUE", "Set a variable for the publishing run", setVariable)
	op.On("--verbose", "Print a bit of debugging output", options)
	op.On("--version", "Show version information", versioninfo)
	op.On("--wd DIR", "Change working directory", options)
	op.On("--xml", "Output as (pseudo-)XML (for list-fonts)", options)

	op.Command("clean", "Remove publisher generated files")
	op.Command("compare", "Compare files for quality assurance")
	op.Command("doc", "Open documentation")
	op.Command("list-fonts", "List installed fonts (use together with --xml for copy/paste)")
	op.Command("run", "Start publishing (default)")
	op.Command("watch", "Start watchdog / hotfolder")
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

	cfg, _ = configurator.ReadFiles(filepath.Join(homedir, ".publisher.cfg"), "/etc/speedata/publisher.cfg")
	if err != nil {
		log.Fatal(err)
	}

	// When the user requests another working directory, we should
	// change into the given wd first, before reading the local
	// options
	if wd := getOption("wd"); wd != "" {
		err := os.Chdir(wd)
		if err != nil {
			log.Fatal(err)
		}
		log.Printf("Working directory now: %s", wd)
		pwd = wd
	}

	cfg.ReadFile(filepath.Join(pwd, configfilename))

	if add_local_path {
		extra_dir = append(extra_dir, pwd)
	}
	os.Setenv("SP_FONT_PATH", getOption("fontpath"))
	os.Setenv("SP_PATH_REWRITE", getOption("pathrewrite"))

	if ed := cfg.String("DEFAULT", "extra-dir"); ed != "" {
		extra_dir = append(extra_dir, ed)
	}
	os.Setenv("SD_EXTRA_DIRS", strings.Join(extra_dir, string(filepath.ListSeparator)))
	if getOption("verbose") != "" {
		os.Setenv("SP_VERBOSITY", "1")
		fmt.Println("SD_EXTRA_DIRS:", os.Getenv("SD_EXTRA_DIRS"))
	}
	var exitstatus int
	if getOption("profile") != "" {
		fmt.Println("Profiling publisher run. Removing lprof_* now.")
		os.Setenv("SD_PROFILER", "true")
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
		// open PDF if necessary
		if getOption("autoopen") == "true" {
			openFile(getOption("jobname") + ".pdf")
		}
	case "compare":
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
			filepath.Walk(absDir, compare)

		} else {
			log.Println("Please give one directory")
		}
	case "clean":
		jobname := getOption("jobname")
		files, err := filepath.Glob(jobname + "*")
		if err != nil {
			log.Fatal(err)
		}
		for _, v := range files {
			switch filepath.Ext(v) {
			case ".vars", ".log", ".protocol", ".dataxml", ".status":
				log.Printf("Removing %s", v)
				err = os.Remove(v)
				if err != nil {
					log.Println(err)
				}
			}
		}
	case "doc":
		openFile(path_to_documentation)
		os.Exit(0)
	case "list-fonts":
		var xml string
		if getOption("xml") == "true" {
			xml = "xml"
		}

		cmdline := fmt.Sprintf(`"%s" --luaonly "%s/lua/sdscripts.lua" "%s" list-fonts %s`, getExecutablePath(), srcdir, inifile, xml)
		run(cmdline)
	case "watch":
		watch_dir := getOptionSection("hotfolder", "hotfolder")
		events := getOptionSection("events", "hotfolder")
		var hotfolder_events []hotfolder.Event
		// hotfolder_events := make([]hotfolder.Event, 0, 4)
		for _, v := range strings.Split(events, ";") {
			pattern_command := strings.Split(v, ":")
			hotfolder_event := new(hotfolder.Event)
			hotfolder_event.Pattern = regexp.MustCompile(pattern_command[0])
			hotfolder_event.Command = &pattern_command[1]
			hotfolder_events = append(hotfolder_events, *hotfolder_event)
		}

		if watch_dir != "" {
			hotfolder.Watch(watch_dir, hotfolder_events)
		} else {
			log.Fatal("Problem with watch dir in section [hotfolder].")
		}
	default:
		log.Fatal("unknown command:", command)
	}
	showDuration()
	os.Exit(exitstatus)
}
