// go build -ldflags "-X main.dest linux -X main.version local"  main.go

package main

import (
	"fmt"
	"log"
	"optionparser"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"
	"time"
)

var (
	options       map[string]string
	layoutoptions map[string]string
	installdir    string
	libdir        string
	srcdir        string
	inifile       string
	dest          string // The platform which this script runs on. 
	version       string
	homecfg       string
	systemcfg     string
	starttime     time.Time
)

func init() {
	log.SetFlags(0)
	starttime = time.Now()
	pwd, err := os.Getwd()
	if err != nil {
		log.Fatal(err)
	}

	options = map[string]string{
		"layout":    "layout.xml",
		"jobname":   "publisher",
		"data":      "data.xml",
		"runs":      "1",
		"extra-dir": pwd,
	}
	installdir, err = filepath.Abs(path.Join(path.Dir(os.Args[0]), ".."))
	if err != nil {
		log.Fatal(err)
	}
	if version == "" {
		version = "local"
	}
	// log.Print("Built for platform: ",dest)
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
		// options["extra-dir"].push(installdir + "/fonts")
		// options["extra-dir"].push(installdir + "/img")
	}
}

func set_variable(str string) {
	fmt.Println("function called", str)
}

func showDuration() {
	fmt.Printf("Duration: %v\n", time.Now().Sub(starttime))
}

func runPublisher() {
	fmt.Println("installdir",installdir)
	log.Print("run speedata publisher")
	// process.env["SD_EXTRA_DIRS"] = cfg.getArray("extra-dir").join(":")
	// save_variables()

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
	layoutname := options["layoutname"]
	dataname := options["dataname"]
	// inifile ,layoutname,dataname, 

	cmd := exec.Command(installdir+"/bin/sdluatex", "--interaction", "nonstopmode", "--jobname="+jobname, "--ini", "--lua="+inifile, "publisher.tex", layoutname, dataname, layoutoptions_cmdline)
	fmt.Printf("%v\n", cmd)
	// cmdline:= fmt.Sprintf("%s/bin/sdluatex --interaction nonstopmode --jobname=%s --ini --lua=%s  publisher.tex %s %s %s",installdir,jobname,inifile,layoutname,dataname, layoutoptions_cmdline)

	// var jobname    = cfg.getString("jobname"),
	//     layoutname = cfg.getString("layout"),
	//     dataname   = cfg.getString("data"),
	//     runs       = cfg.getNumber("runs")
	//     cmdline = sprintf("%s/bin/sdluatex --interaction nonstopmode --jobname=%s --ini --lua=%s  publisher.tex %s %s %s",installdir,jobname,inifile,layoutname,dataname, layoutoptions_ary.join(",")),
	//     cmdary = cmdline.split(/\s+/),
	//     command = cmdary.shift()

	// run_publisher_core(command,cmdary,runs,openpdf)
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
	op.On("-v", "--var VAR=VALUE", "Set a variable for the publishing run", set_variable)
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
	case "doc":
		// if (installdir == '/usr') {
		//     open_file('/usr/share/doc/speedata-publisher/index.html')
		// } else {
		//     open_file(path.join(installdir,"/build/handbuch_publisher/index.html"))
		// }
		log.Fatal("not implemented yet.")
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
