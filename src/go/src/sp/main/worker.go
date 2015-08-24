// Heavily inspired by Nick Saika (https://nesv.github.io/golang/2014/02/25/worker-queues-in-go.html)

package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
)

type WorkRequest struct {
	Id string
}

var (
	WorkerQueue chan chan WorkRequest
	WorkQueue   = make(chan WorkRequest, 100)
)

func StartDispatcher(nworkers int) {
	// First, initialize the channel we are going to but the workers' work channels into.
	WorkerQueue = make(chan chan WorkRequest, nworkers)
	// Now, create all of our workers.
	for i := 1; i <= nworkers; i++ {
		NewWorker(i, WorkerQueue).Start()
	}
	go func() {
		for {
			select {
			case work := <-WorkQueue:
				go func() {
					// Dispatching work request
					worker := <-WorkerQueue
					worker <- work
				}()
			}
		}
	}()
}

type Worker struct {
	ID          int
	Work        chan WorkRequest
	WorkerQueue chan chan WorkRequest
	QuitChan    chan bool
}

// Create, and return the worker.
func NewWorker(id int, workerQueue chan chan WorkRequest) Worker {
	worker := Worker{
		ID:          id,
		Work:        make(chan WorkRequest),
		WorkerQueue: workerQueue,
		QuitChan:    make(chan bool)}

	return worker
}

// This function "starts" the worker by starting a goroutine, that is
// an infinite "for-select" loop.
func (w Worker) Start() {
	go func() {
		for {
			// Add ourselves into the worker queue.
			w.WorkerQueue <- w.Work

			select {
			case work := <-w.Work:
				// Receive a work request.
				fmt.Fprintf(protocolFile, "Running speedata publisher for id %s\n", work.Id)
				dir := filepath.Join(serverTemp, work.Id)
				// Force the jobname, so the result is always 'publisher.pdf'
				params := []string{"--jobname", "publisher"}
				if _, err := os.Stat(filepath.Join(dir, "extravars")); err == nil {
					params = append(params, "--varsfile")
					params = append(params, "extravars")
				}
				cmd := exec.Command(filepath.Join(bindir, "sp"+exe_suffix), params...)
				cmd.Dir = dir
				cmd.Run()
				ioutil.WriteFile(filepath.Join(dir, work.Id+"finished.txt"), []byte("finished"), 0600)
				fmt.Fprintf(protocolFile, "Id %s finished\n", work.Id)
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
func (w Worker) Stop() {
	go func() {
		w.QuitChan <- true
	}()
}
