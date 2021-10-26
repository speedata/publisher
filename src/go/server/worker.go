// Heavily inspired by Nick Saika (https://nesv.github.io/golang/2014/02/25/worker-queues-in-go.html)

package server

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// WorkRequest contains an ID
type WorkRequest struct {
	ID    string
	Modes []string
}

var (
	workerQueue chan chan WorkRequest         //
	workQueue   = make(chan WorkRequest, 100) // workque
)

// startDispatcher starts the worker queue with the number of processors
func startDispatcher(s *Server, nworkers int) {
	// First, initialize the channel we are going to but the workers' work channels into.
	workerQueue = make(chan chan WorkRequest, nworkers)
	// Now, create all of our workers.
	for i := 1; i <= nworkers; i++ {
		newWorker(s, i, workerQueue).Start()
	}
	go func() {
		for {
			select {
			case work := <-workQueue:
				go func() {
					// Dispatching work request
					worker := <-workerQueue
					worker <- work
				}()
			}
		}
	}()
}

// Worker needs documentation
type worker struct {
	Server      *Server
	ID          int
	Work        chan WorkRequest
	WorkerQueue chan chan WorkRequest
	QuitChan    chan bool
}

// NewWorker creates and return the worker
func newWorker(s *Server, id int, workerQueue chan chan WorkRequest) worker {
	worker := worker{
		Server:      s,
		ID:          id,
		Work:        make(chan WorkRequest),
		WorkerQueue: workerQueue,
		QuitChan:    make(chan bool)}

	return worker
}

// Start the worker by starting a goroutine, that is  an infinite "for-select" loop.
func (w worker) Start() {
	go func() {
		for {
			// Add ourselves into the worker queue.
			w.WorkerQueue <- w.Work

			select {
			case work := <-w.Work:
				// Receive a work request.
				fmt.Fprintf(w.Server.ProtocolFile, "%s: running speedata publisher\n", work.ID)
				dir := filepath.Join(w.Server.serverTemp, work.ID)
				// Force the jobname, so the result is always 'publisher.pdf'
				params := []string{"--jobname", "publisher", "--quiet"}
				if _, err := os.Stat(filepath.Join(dir, "extravars")); err == nil {
					params = append(params, "--varsfile")
					params = append(params, "extravars")
				}
				if len(work.Modes) > 0 {
					params = append(params, "--mode")
					params = append(params, strings.Join(work.Modes, ","))
				}
				for _, p := range w.Server.ClientExtraDir {
					if p != "" {
						params = append(params, "--extra-dir")
						params = append(params, p)
					}
				}
				if f := w.Server.Filter; f != "" {
					params = append(params, "--filter", f)
				}
				if r := w.Server.Runs; r != "" {
					params = append(params, "--runs", r)
				}
				cmd := exec.Command(w.Server.BinaryPath, params...)
				if w.Server.Verbose {
					fmt.Fprintf(w.Server.ProtocolFile, "%v\n", cmd.Args)
				}
				cmd.Dir = dir
				out, err := cmd.CombinedOutput()
				if err != nil {
					fmt.Fprintf(w.Server.ProtocolFile, "%s: start sp, returns %q\n", work.ID, err.Error())
				}
				ioutil.WriteFile(filepath.Join(dir, "output.txt"), out, 0600)
				ioutil.WriteFile(filepath.Join(dir, work.ID+"finished.txt"), []byte("finished"), 0600)
				fmt.Fprintf(w.Server.ProtocolFile, "%s: finished\n", work.ID)
			case <-w.QuitChan:
				// We have been asked to stop.
				return
			}
		}
	}()
}

// Stop tells the worker to stop listening for work requests.
//
// Note that the worker will only stop *after* it has finished its work.
func (w worker) Stop() {
	go func() {
		w.QuitChan <- true
	}()
}
