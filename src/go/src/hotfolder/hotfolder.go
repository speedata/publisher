package hotfolder

import (
	"fsnotify"
	"log"
	"os"
	"os/exec"
	"regexp"
	"time"
)

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

func watchFile(filepath string, events []Event) {
	log.Println("Watching file ", filepath)
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Fatal(err)
	}

	err = watcher.Watch(filepath)
	if err != nil {
		log.Fatal(err)
	}
	for {
		timer := time.NewTimer(500 * time.Millisecond)
		select {
		case <-watcher.Event:
		case err := <-watcher.Error:
			log.Println("error:", err)
		case <-timer.C:
			f(filepath, events)
			return
		}

		timer.Stop()
	}
	watcher.Close()
}

type Event struct {
	Pattern *regexp.Regexp
	Command *string
}

func watchDirectory(dir string, events []Event) {
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Fatal(err)
	}
	err = watcher.WatchFlags(dir, fsnotify.FSN_CREATE)
	if err != nil {
		log.Fatal(err)
	}

	for {
		select {
		case ev := <-watcher.Event:
			if ev.IsCreate() {
				watchFile(ev.Name, events)
			}
		case err := <-watcher.Error:
			log.Println("error:", err)

		}
	}
	watcher.Close()
}

func Watch(dir string, events []Event) {
	watchDirectory(dir, events)
}
