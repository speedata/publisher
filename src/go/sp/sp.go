// go build -ldflags "-X main.dest linux -X main.version local"  main.go

package main

import (
	"fmt"
	"io"
	"log"
	"optionparser"
	"os"
	"os/exec"
	"os/signal"
	"path"
	"path/filepath"
	"runtime"
	"strings"
	"syscall"
	"time"
)

var (
	options            map[string]string
	layoutoptions      map[string]string
	variables          map[string]string
	installdir, libdir string
	srcdir             string
	inifile            string
	dest               string // The platform which this script runs on. 
	version            string
	homecfg            string
	systemcfg          string
	pwd                string
	open_command       string
	extra_dir          []string
	starttime          time.Time
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

	options = map[string]string{
		"layout":  "layout.xml",
		"jobname": "publisher",
		"data":    "data.xml",
		"runs":    "1",
	}
	installdir, err = filepath.Abs(path.Join(path.Dir(os.Args[0]), ".."))
	if err != nil {
		log.Fatal(err)
	}
	if version == "" {
		version = "local"
	}
	extra_dir = append(extra_dir, pwd)
	// log.Print("Built for platform: ",dest)
	switch os := runtime.GOOS; os {
	case "darwin":
		open_command = "open"
	case "linux":
		open_command = "xdg-open"
	case "windows":
		open_command = "/Programme/Internet Explorer/iexplore.exe"
	}

	switch dest {
	case "linux":
		libdir = "/usr/share/speedata-publisher/lib"
		srcdir = "/usr/share/speedata-publisher/sw"
		inifile = path.Join(srcdir, "lua/sdini.lua")
		os.Setenv("PUBLISHER_BASE_PATH", "/usr/share/speedata-publisher")
		os.Setenv("LUA_PATH", fmt.Sprintf("%s/lua/?.lua;%s/lua/common/?.lua;", srcdir, srcdir))
	case "windows":
		log.Fatal("Platform not supported yet!")
	default:
		// local git installation
		libdir = path.Join(installdir, "lib")
		srcdir = path.Join(installdir, "src")
		inifile = path.Join(srcdir, "lua/sdini.lua")
		os.Setenv("PUBLISHER_BASE_PATH", srcdir)
		os.Setenv("LUA_PATH", srcdir+"/lua/?.lua;"+installdir+"/lib/?.lua;"+srcdir+"/lua/common/?.lua;")
		extra_dir = append(extra_dir, path.Join(installdir, "fonts"))
		extra_dir = append(extra_dir, path.Join(installdir, "img"))
	}
}

// Open the given file with the system's default program
func openFile(filename string) {
	fmt.Println("open_command", open_command, filename)
	cmd := exec.Command(open_command, filename)
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
	log.Printf("Duration: %v\n", time.Now().Sub(starttime))
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
	return
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
	// fmt.Printf("%v\n", cmd)
	go io.Copy(os.Stdout, stdout)
	go io.Copy(os.Stderr, stderr)
	err = cmd.Wait()
	if err != nil {
		showDuration()
		log.Print(err)
	}
}

func save_variables() {
	f, err := os.Create(options["jobname"] + ".vars")
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

func runPublisher() {
	fmt.Println("installdir", installdir)
	log.Print("run speedata publisher")
	os.Setenv("SD_EXTRA_DIRS", strings.Join(extra_dir, ":"))

	save_variables()

	f, err := os.Create(options["jobname"] + ".protocol")
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
	jobname := options["jobname"]
	layoutname := options["layout"]
	dataname := options["data"]

	run(fmt.Sprintf("%s/bin/sdluatex --interaction nonstopmode --jobname=%s --ini --lua=%s publisher.tex %s %s %s", installdir, jobname, inifile, layoutname, dataname, layoutoptions_cmdline))
	fmt.Println("run finished")
}

func main() {
	layoutoptions = make(map[string]string)
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
	op.On("--version", "Show version information", options)
	op.On("-x", "--extra-dir DIR", "Additional directory for file search", options)
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

	fmt.Printf("%v\n", options)
	fmt.Printf("%v\n", layoutoptions)

	switch command {
	case "run":
		filter := options["filter"]
		if filter != "" {
			// run xproc filter
			log.Fatal("Running xproc filter not implemented")
		}
		runPublisher()
		// open PDF if necessary
		if options["autoopen"] == "true" {
			openFile(options["jobname"] + ".pdf")
		}
	case "doc":
		if installdir == "/usr" {
			openFile("/usr/share/doc/speedata-publisher/index.html")
		} else {
			openFile(path.Join(installdir, "/build/handbuch_publisher/index.html"))
		}
	case "list-fonts":
		log.Fatal("not implemented yet.")
	case "watch":
		log.Fatal("not implemented yet.")
	default:
		fmt.Println("unknown command:", command)
		os.Exit(-1)
	}
	showDuration()
}
