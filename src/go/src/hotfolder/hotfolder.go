package hotfolder

import (
	"fsnotify"
	"log"
	"os"
	"os/exec"
	"regexp"
	"time"
)

type Event struct {
	Pattern *regexp.Regexp
	Command *string
}

func f(filepath string, events []Event) {
	script_pattern := regexp.MustCompile(`run\((.*)\)`)
	for _, v := range events {
		if v.Pattern.MatchString(filepath) {
			log.Printf(`File %q complete. Run %q (matched pattern: %s)`, filepath, *v.Command, v.Pattern.String())
			b := script_pattern.FindStringSubmatch(*v.Command)
			if b != nil {
				cmd := exec.Command(b[1], filepath)
				err := cmd.Run()
				if err != nil {
					log.Println(err)
				}
				err = os.Remove(filepath)
				if err != nil {
					log.Println(err)
				}
				log.Println("Command finished, waiting for next file.")
			} else {
				log.Println("No run() command found in event.")
			}
		}
	}
}

// Wait until the file filename gets created in directory dir
func watchDirectory(dir string, events []Event) {
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Fatal(err)
	}
	defer watcher.Close()

	done := make(chan bool)
	go func() {
		fileStarted := make(map[string]bool)
		for {
			timer := time.NewTimer(100 * time.Millisecond)
			select {
			case event := <-watcher.Events:
				if event.Op&fsnotify.Write == fsnotify.Write || event.Op&fsnotify.Create == fsnotify.Create {
					fileStarted[event.Name] = true
				}
			case <-timer.C:
				if len(fileStarted) > 0 {
					for n, _ := range fileStarted {
						f(n, events)
						delete(fileStarted, n)
					}
				}
			case err := <-watcher.Errors:
				log.Println("error:", err)
			}
			timer.Stop()
		}

	}()

	err = watcher.Add("/tmp/foo")
	if err != nil {
		log.Fatal(err)
	}
	<-done
}

// Wait until filename in dir exists and is complete
func Watch(dir string, events []Event) {
	watchDirectory(dir, events)
}
