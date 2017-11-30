package sp

import (
	"bufio"
	"fmt"
	"log"
	"math"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"syscall"
)

var (
	wg        sync.WaitGroup
	finished  chan bool
	exeSuffix string
)

func init() {
	finished = make(chan bool)
}

func fileExists(filename string) bool {
	fi, err := os.Stat(filename)
	if err != nil {
		return false
	}
	return !fi.IsDir()
}

// DoCompare starts comparing the files in the
// current directory and its subdirectory
func DoCompare(absdir string) {
	switch runtime.GOOS {
	case "windows":
		exeSuffix = ".exe"
	default:
		exeSuffix = ""
	}
	cs := make(chan compareStatus, 0)
	compare := mkCompare(cs)
	filepath.Walk(absdir, compare)
	go getCompareStatus(cs)
	wg.Wait()
	finished <- true
}

func compareTwoPages(sourcefile, referencefile, dummyfile, path string) float64 {
	// More complicated than the trivial case because I need the different exit statuses.
	// See http://stackoverflow.com/a/10385867
	if !fileExists(filepath.Join(path, sourcefile)) || !fileExists(filepath.Join(path, referencefile)) {
		return 99.0
	}

	cmd := exec.Command("compare"+exeSuffix, "-metric", "mae", sourcefile, referencefile, dummyfile)
	cmd.Dir = path
	// err == 1 looks like an indicator that the comparison is OK but some diffs in the images
	// err == 2 seems to be a fatal error
	stderr, err := cmd.StderrPipe()
	if err != nil {
		log.Fatal(err)
	}

	if err := cmd.Start(); err != nil {
		log.Println("Do you have imagemagick installed?")
		log.Fatalf("cmd.Start: %v", err)
	}

	r := bufio.NewReader(stderr)
	line, _ := r.ReadBytes('\n')

	if err := cmd.Wait(); err != nil {
		if exiterr, ok := err.(*exec.ExitError); ok {
			// The program has exited with an exit code != 0

			// This works on Mac and hopefully on Unix and Windows. Although package
			// syscall is generally platform dependent, WaitStatus is
			// defined for both Unix and Windows and in both cases has
			// an ExitStatus() method with the same signature.
			if status, ok := exiterr.Sys().(syscall.WaitStatus); ok {
				if status.ExitStatus() == 1 {
					// comparison ok with differences
					delta, nerr := strconv.ParseFloat(strings.Split(string(line), " ")[0], 32)
					if nerr != nil {
						log.Fatal(nerr)
					}
					return delta
				}
				log.Fatal(err)
			}
		} else {
			log.Fatalf("cmd.Wait: %v", err)
		}
	}
	return 0.0
}

func newer(src, dest string) bool {
	destFi, err := os.Stat(dest)
	if err != nil {
		return true
	}
	srcFi, err := os.Stat(src)
	if err != nil {
		panic(fmt.Sprintf("Source %s does not exist!", src))
	}
	return destFi.ModTime().Before(srcFi.ModTime())
}

func runComparison(path string, status chan compareStatus) {
	cs := compareStatus{}
	cs.path = path

	sourceFiles, err := filepath.Glob(filepath.Join(path, "source-*.png"))
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

	cmd := exec.Command("sp" + exeSuffix)
	cmd.Dir = path
	err = cmd.Run()
	if err != nil {
		log.Println(path)
		log.Fatal("Error running command 'sp': ", err)
	}
	cmd = exec.Command("convert"+exeSuffix, "publisher.pdf", "source-%02d.png")
	cmd.Dir = path
	cmd.Run()
	if err != nil {
		log.Fatal(err)
	}

	// convert the reference pdf to png for later comparisons
	// we only do that when the pdf is newer than the png files
	// (that is: the pdf has been updated)
	if newer(filepath.Join(path, "reference.pdf"), filepath.Join(path, "reference-00.png")) {
		cmd := exec.Command("convert"+exeSuffix, "reference.pdf", "reference-%02d.png")
		cmd.Dir = path
		err = cmd.Run()
		if err != nil {
			log.Fatal("Errror converting reference. Do you have ghostscript installed?", err)
		}
	}

	sourceFiles, err = filepath.Glob(filepath.Join(path, "source-*.png"))
	if err != nil {
		log.Fatal("No source files found. ", err)
	}

	for i := 0; i < len(sourceFiles); i++ {
		sourceFile := fmt.Sprintf("source-%02d.png", i)
		referenceFile := fmt.Sprintf("reference-%02d.png", i)
		dummyFile := fmt.Sprintf("pagediff-%02d.png", i)
		if delta := compareTwoPages(sourceFile, referenceFile, dummyFile, path); delta > 0 {
			cs.delta = math.Max(cs.delta, delta)
			if delta > 0.3 {
				cs.badpages = append(cs.badpages, i)
			}
		}
	}

	status <- cs
	wg.Done()
}

type compareStatus struct {
	path     string
	badpages []int
	diff     bool
	delta    float64
}

func getCompareStatus(cs chan compareStatus) {
	for {
		select {
		case st := <-cs:
			if len(st.badpages) > 0 {
				fmt.Println("---------------------------")
				fmt.Println("Finished with comparison in")
				fmt.Println(st.path)
				fmt.Println("Comparison failed. Bad pages are:", st.badpages)
				fmt.Println("Max delta is", st.delta)
			}
		case <-finished:
			// now that we have read from the channel, we are all done
		}
	}
}

// Return a filepath.WalkFunc that looks into a directory, runs convert to generate the PNG files from the PDF and
// compares the two resulting files. The function puts the result into the channel compareStatus.
func mkCompare(status chan compareStatus) filepath.WalkFunc {
	return func(path string, info os.FileInfo, err error) error {
		if info == nil || !info.IsDir() {
			return nil
		}
		if _, err := os.Stat(filepath.Join(path, "reference.pdf")); err == nil {
			wg.Add(1)
			go runComparison(path, status)
		}
		return nil
	}
}
