package main

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"encoding/xml"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"github.com/fsnotify/fsnotify"
	"github.com/gorilla/mux"
	"github.com/speedata/configurator"
)

const (
	statusError       = "error"
	statusNotFinished = "not finished"
)

var (
	daemonStarted bool
	serverTemp    string
	protocolFile  *os.File
)

func makePublisherTemp() error {
	fi, err := os.Stat(serverTemp)
	if err != nil && !os.IsNotExist(err) {
		return err
	}

	// If it doesn't exist, make it
	if os.IsNotExist(err) {
		err = os.MkdirAll(serverTemp, 0755)
		return err
	}

	// if it exists and is a directory, that's fine
	if fi.IsDir() {
		return nil
	}
	// not a directory, panic!
	return errors.New("internal error: serverTemp exists, but is not a directory")
}

func encodeFileToBase64(filename string) (string, error) {
	layoutf, err := ioutil.ReadFile(filename)
	if err != nil {
		return "", err
	}
	var layoutbase64 bytes.Buffer

	layoutwc := base64.NewEncoder(base64.StdEncoding, &layoutbase64)
	_, err = layoutwc.Write(layoutf)
	if err != nil {
		return "", err
	}
	err = layoutwc.Close()
	if err != nil {
		return "", err
	}
	return layoutbase64.String(), nil
}

func addPublishrequestToQueue(id string) {
	fmt.Fprintf(protocolFile, "Add request %s to queue.\n", id)
	workQueue <- WorkRequest{ID: id}
}

// Wait until filename in dir exists and is complete
// func waitForAllFiles(dir string) error {
// 	watcher, err := fsnotify.NewWatcher()
// 	if err != nil {
// 		return err
// 	}
// 	defer watcher.Close()
// 	done := make(chan bool)
// 	var goerr error
// 	go func() {
// 		for {
// 			timer := time.NewTimer(100 * time.Millisecond)
// 			select {
// 			case event := <-watcher.Events:
// 				if event.Op&fsnotify.Write == fsnotify.Write || event.Op&fsnotify.Create == fsnotify.Create {
// 				}
// 			case <-timer.C:
// 				done <- true
// 				return
// 			case nerr := <-watcher.Errors:
// 				goerr = nerr
// 				done <- true
// 			}
// 			timer.Stop()
// 		}

// 	}()

// 	err = watcher.Add(dir)
// 	if err != nil {
// 		return err
// 	}
// 	<-done
// 	return goerr
// }

// Wait until the file filename gets created in directory dir
func waitForFile(dir string, filename string) error {
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		return err
	}
	defer watcher.Close()
	requestedFile := filepath.Join(dir, filename)
	done := make(chan bool)
	var goerr error
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
					for n := range fileStarted {
						delete(fileStarted, n)
						if n == requestedFile {
							done <- true
							return
						}
					}
				}
			case nerr := <-watcher.Errors:
				goerr = nerr
				done <- true
			}
			timer.Stop()
		}

	}()

	err = watcher.Add(dir)
	if err != nil {
		return err
	}
	<-done
	return goerr
}

// Request a JSON answer with the PDF and the status file.
func v0PublishIDHandler(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]
	response := struct {
		Status     string `json:"status"`
		Path       string `json:"path"`
		Blob       string `json:"blob"`
		Statusfile string `json:"statusfile"`
		Finished   string `json:"finished"`
	}{}
	publishdir := filepath.Join(serverTemp, id)
	fi, err := os.Stat(publishdir)
	if err != nil && os.IsNotExist(err) || !fi.IsDir() {
		response.Status = statusError
		response.Blob = "id unknown"
		buf, marshallerr := json.Marshal(response)
		if marshallerr != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(protocolFile, "Internal error 001:")
			fmt.Fprintln(protocolFile, marshallerr)
			fmt.Fprintln(w, "Internal error 001")
			return
		}
		w.WriteHeader(http.StatusBadRequest)
		w.Write(buf)
		return
	}

	pdfPath := filepath.Join(publishdir, "publisher.pdf")
	statusfilePath := filepath.Join(publishdir, "publisher.status")
	finishedfile := filepath.Join(serverTemp, id, id+"finished.txt")

	fi, err = os.Stat(finishedfile)
	if err != nil && os.IsNotExist(err) {
		// status does not exist yet, so it's in progress
		response.Blob = statusNotFinished
		response.Status = statusError
		buf, marshallerr := json.Marshal(response)
		if marshallerr != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(protocolFile, "Internal error 002:")
			fmt.Fprintln(protocolFile, marshallerr)
			fmt.Fprintln(w, "Internal error 002")
			return
		}
		w.WriteHeader(http.StatusNotFound)
		w.Write(buf)
		return
	}
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(protocolFile, "Internal error 003:")
		fmt.Fprintln(protocolFile, err)
		fmt.Fprintln(w, "Internal error 003")
		return
	}

	// Only if the PDF is finished, we may remove the directory
	if r.FormValue("delete") != "false" {
		defer os.RemoveAll(publishdir)
	}

	response.Status = "ok"
	response.Path = pdfPath
	response.Finished = fi.ModTime().Format(time.RFC3339)
	response.Blob, err = encodeFileToBase64(pdfPath)
	if err != nil && !os.IsNotExist(err) {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(protocolFile, "Internal error 004:")
		fmt.Fprintln(protocolFile, err)
		fmt.Fprintln(w, "Internal error 004")
		return
	}
	if response.Blob == "" {
		response.Status = statusError
		response.Path = ""
	}

	response.Statusfile, err = encodeFileToBase64(statusfilePath)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(protocolFile, "Internal error 005:")
		fmt.Fprintln(protocolFile, err)
		fmt.Fprintln(w, "Internal error 005")
		return
	}

	buf, marshallerr := json.Marshal(response)
	if marshallerr != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(protocolFile, "Internal error 006:")
		fmt.Fprintln(protocolFile, marshallerr)
		fmt.Fprintln(w, "Internal error 006")
		return
	}
	w.WriteHeader(http.StatusOK)
	w.Write(buf)
	return
}

// Return full path to directory on success, empty string on failure
func checkIDExists(id string) string {
	publishdir := filepath.Join(serverTemp, id)
	fi, err := os.Stat(publishdir)
	if err != nil {
		return ""
	}
	if err != nil && os.IsNotExist(err) || !fi.IsDir() {
		// Does not exist or is not a directory
		return ""
	}
	if a, err := filepath.Rel(filepath.Join(publishdir, ".."), serverTemp); err != nil && a == "." {
		return ""
	}
	return publishdir
}

// Delete the folder with the given ID
func v0DeleteHandler(w http.ResponseWriter, r *http.Request) {
	// Not found? 404
	// Deleted? 200
	id := mux.Vars(r)["id"]
	fmt.Fprintf(protocolFile, "/v0/delete/%s\n", id)
	if d := checkIDExists(id); d != "" {
		err := os.RemoveAll(d)
		if err != nil {
			fmt.Fprintln(protocolFile, err)
		} else {
			fmt.Fprintln(protocolFile, "ok")
		}
		w.WriteHeader(http.StatusOK)
	} else {
		fmt.Fprintln(protocolFile, "not found")
		w.WriteHeader(http.StatusNotFound)
	}
}

// Return the PDF from job id (given in the URL)
func v0GetPDFHandler(w http.ResponseWriter, r *http.Request) {
	// Not found? 404
	// PDF not ready? Wait
	// PDF has errors? 406
	// PDF ok? 200
	// Internal error? 500
	id := mux.Vars(r)["id"]
	fmt.Fprintf(protocolFile, "/v0/pdf/%s\n", id)
	publishdir := filepath.Join(serverTemp, id)
	fi, err := os.Stat(publishdir)
	if err != nil && os.IsNotExist(err) || !fi.IsDir() {
		w.WriteHeader(http.StatusNotFound)
		fmt.Fprintln(protocolFile, err)
		return
	}

	finishedPath := filepath.Join(publishdir, "publisher.finished")
	fi, err = os.Stat(finishedPath)
	if err != nil && os.IsNotExist(err) {
		// not finished yet, wait
		waitForFile(publishdir, "publisher.finished")
	}

	statusPath := filepath.Join(publishdir, "publisher.status")
	data, err := ioutil.ReadFile(statusPath)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(protocolFile, "Internal error 008:")
		fmt.Fprintln(protocolFile, err)
		fmt.Fprintln(w, "Internal error 008")
		return
	}

	v := status{}
	err = xml.Unmarshal(data, &v)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(protocolFile, "Internal error 009:")
		fmt.Fprintln(protocolFile, err)
		fmt.Fprintln(w, "Internal error 009")
		return
	}

	if v.Errors > 0 {
		w.WriteHeader(http.StatusNotAcceptable)
		fmt.Fprintf(protocolFile, "PDF with errors")
		return
	}

	filename := "publisher.pdf"
	// if jobname.txt was written, use the contents for the jobname
	fi, err = os.Stat(filepath.Join(publishdir, "jobname.txt"))
	if err == nil {
		name, err := ioutil.ReadFile(filepath.Join(publishdir, "jobname.txt"))
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(protocolFile, "Internal error 010:")
			fmt.Fprintln(protocolFile, err)
			fmt.Fprintln(w, "Internal error 010")
			return
		}
		filename = string(name) + ".pdf"
	}

	w.Header().Set("Content-Type", "application/pdf")
	w.Header().Add("Content-Disposition", fmt.Sprintf(`attachment; filename=%q`, filename))
	w.Header().Add("Content-Transfer-Encoding", "binary")
	http.ServeFile(w, r, filepath.Join(publishdir, "publisher.pdf"))
}

// Send the given file down the stream. Change format with ?format=json/base64/... Default is the unencoded / unchanged file
func sendFile(id string, filename string, w http.ResponseWriter, r *http.Request) {
	publishdir := filepath.Join(serverTemp, id)
	fi, err := os.Stat(publishdir)
	if err != nil && os.IsNotExist(err) || !fi.IsDir() {
		w.WriteHeader(http.StatusNotFound)
		fmt.Fprintln(protocolFile, err)
		return
	}
	val := r.URL.Query()
	f, err := os.Open(filepath.Join(publishdir, filename))
	if err != nil {
		writeInternalError(w)
		return
	}
	defer f.Close()
	switch val.Get("format") {
	case "base64":
		encoder := base64.NewEncoder(base64.StdEncoding, w)
		io.Copy(encoder, f)
		encoder.Close()
	case "json", "JSON":
		var buf []byte
		buf, err = ioutil.ReadAll(f)
		if err != nil {
			writeInternalError(w)
			return
		}

		a := struct {
			Data string `json:"contents"`
		}{
			Data: string(buf),
		}

		b, err := json.Marshal(a)
		if err != nil {
			writeInternalError(w)
			return
		}
		fmt.Fprintln(w, string(b))
	default:
		w.Header().Set("Content-Type", "application/xml")
		io.Copy(w, f)
	}

}

func v0DataHandler(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]
	fmt.Fprintf(protocolFile, "/v0/data/%s\n", id)
	sendFile(id, "data.xml", w, r)
}

func v0LayoutHandler(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]
	fmt.Fprintf(protocolFile, "/v0/layout/%s\n", id)
	sendFile(id, "layout.xml", w, r)
}

// send the file publisher.status
func v0StatusfileHandler(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]
	fmt.Fprintf(protocolFile, "/v0/statusfile/%s\n", id)
	sendFile(id, "publisher.status", w, r)
}

func writeInternalError(w http.ResponseWriter) {
	fmt.Fprintln(w, "Internal error")
	return
}

// Start a publishing process. Accepted parameter:
//   jobname=<jobname>
//   vars=var1=foo,var2=bar (where all but the frist = is encoded as %3D)
func v0PublishHandler(w http.ResponseWriter, r *http.Request) {
	var files map[string]interface{}
	data, err := ioutil.ReadAll(r.Body)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(protocolFile, "Internal error 011:")
		fmt.Fprintln(protocolFile, err)
		fmt.Fprintln(w, "Internal error 011")
		return
	}

	err = json.Unmarshal(data, &files)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		fmt.Fprintln(w, "JSON error:", err)
		return
	}
	err = makePublisherTemp()
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(protocolFile, "Internal error 012:")
		fmt.Fprintln(protocolFile, err)
		fmt.Fprintln(w, "Internal error 012")
		return
	}

	// Always start with non-0 to avoid problems out of scope of the publisher
	tmpdir, err := ioutil.TempDir(serverTemp, "1")
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(protocolFile, "Internal error 013:")
		fmt.Fprintln(protocolFile, err)
		fmt.Fprintln(w, "Internal error 013")
		return
	}

	id, err := filepath.Rel(serverTemp, tmpdir)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(protocolFile, "Internal error 014:")
		fmt.Fprintln(protocolFile, err)
		fmt.Fprintln(w, "Internal error 014")
		return
	}

	fmt.Fprintf(protocolFile, "%s: Publishing request from %s with id %s\n", time.Now().Format("2006-01-02 15:04:05"), r.RemoteAddr, id)

	for k, v := range files {
		bb := bytes.NewBuffer([]byte(v.(string)))
		b64reader := base64.NewDecoder(base64.StdEncoding, bb)
		f, nerr := os.Create(filepath.Join(tmpdir, k))
		if nerr != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(protocolFile, "Internal error 015:")
			fmt.Fprintln(protocolFile, nerr)
			fmt.Fprintln(w, "Internal error 015")
			return
		}
		_, err = io.Copy(f, b64reader)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(protocolFile, "Internal error 016:")
			fmt.Fprintln(protocolFile, err)
			fmt.Fprintln(w, "Internal error 016")
			return
		}
		f.Close()
	}
	jobname := r.FormValue("jobname")
	if jobname == "" {
		// let's try the config file
		cd, nerr := configurator.ReadFiles(filepath.Join(tmpdir, "publisher.cfg"))
		if nerr == nil {
			jobname = cd.String("DEFAULT", "jobname")
		}
	}
	if jobname != "" {
		err = ioutil.WriteFile(filepath.Join(tmpdir, "jobname.txt"), []byte(jobname), 0644)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(protocolFile, "Internal error 017:")
			fmt.Fprintln(protocolFile, err)
			fmt.Fprintln(w, "Internal error 017")
			return
		}
	}

	if vars := r.FormValue("vars"); vars != "" {
		f, err := os.OpenFile(filepath.Join(tmpdir, "extravars"), os.O_RDWR|os.O_CREATE, 0644)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(protocolFile, "Internal error 018:")
			fmt.Fprintln(protocolFile, err)
			fmt.Fprintln(w, "Internal error 018")
			return
		}
		for _, v := range strings.Split(vars, ",") {
			f.Write([]byte(v + "\n"))
		}
		f.Close()
	}

	addPublishrequestToQueue(id)

	jsonid := struct {
		ID string `json:"id"`
	}{
		ID: id,
	}
	buf, marshallerr := json.Marshal(jsonid)
	if marshallerr != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(protocolFile, "Internal error 019:")
		fmt.Fprintln(protocolFile, marshallerr)
		fmt.Fprintln(w, "Internal error 019")
		return
	}
	w.WriteHeader(http.StatusCreated)
	w.Write(buf)

	return
}

var (
	// ErrNotfinished is returned when the PDF generation still runs
	ErrNotfinished = errors.New(statusNotFinished)
	// ErrUnknownID is returned when an unknown ID is encountered
	ErrUnknownID = errors.New("Unknown ID")
)

func getStatusForID(id string) (statusresponse, error) {
	spstatus := statusresponse{}
	publishdir := filepath.Join(serverTemp, id)
	fi, err := os.Stat(publishdir)
	if err != nil && os.IsNotExist(err) || !fi.IsDir() {
		return spstatus, ErrUnknownID
	}

	statusPath := filepath.Join(publishdir, "publisher.status")
	finishedPath := filepath.Join(publishdir, "publisher.finished")
	fi, err = os.Stat(finishedPath)
	if err != nil && os.IsNotExist(err) {
		return spstatus, ErrNotfinished
	}
	if err != nil {
		return spstatus, fmt.Errorf("Error stat: %s", err)
	}

	data, err := ioutil.ReadFile(statusPath)
	if err != nil {
		return spstatus, fmt.Errorf("Error read: %s", err)
	}

	v := status{}
	err = xml.Unmarshal(data, &v)
	if err != nil {
		return spstatus, fmt.Errorf("Error unmarshal XML: %s", err)
	}

	spstatus.Finished = fi.ModTime().Format(time.RFC3339)
	if v.Errors != 0 {
		spstatus.Errstatus = "ok"
		spstatus.Result = "failed"
		spstatus.Message = fmt.Sprintf("%d errors occurred during publishing run", v.Errors)
	} else {
		spstatus.Result = "finished"
		spstatus.Errstatus = "ok"
		spstatus.Message = "no errors found"
	}
	return spstatus, nil
}

type statusresponse struct {
	Errstatus string `json:"errorstatus"`
	Result    string `json:"result"`
	Message   string `json:"message"`
	Finished  string `json:"finished"`
}

// Return true if the given dir is a directory that contains
// something that looks like a source to be published (layout.xml)
func isPublishingDir(dir string) bool {
	fi, err := os.Stat(dir)
	if err != nil {
		return false
	}
	if !fi.IsDir() {
		return false
	}
	layoutxmlfi, err := os.Stat(filepath.Join(dir, "layout.xml"))
	if err != nil {
		return false
	}
	if layoutxmlfi.IsDir() {
		return false
	}
	return true
}

// Return a string list of all IDs in the publishing dir, possibly empty
func getAllIds() []string {
	ret := []string{}

	matches, err := filepath.Glob(serverTemp + "/*")
	if err != nil {
		fmt.Println(err)
		return []string{}
	}
	serverTempWithSlash := serverTemp + "/"
	for _, match := range matches {
		if isPublishingDir(match) {
			id := strings.TrimPrefix(match, serverTempWithSlash)
			ret = append(ret, id)
		}
	}
	return ret
}

func v0GetAllStatusHandler(w http.ResponseWriter, r *http.Request) {

	allstatus := make(map[string]statusresponse)

	for _, id := range getAllIds() {
		stat, err := getStatusForID(id)
		if err != nil {
			switch err {
			case ErrUnknownID:
				stat.Message = fmt.Sprintf("id %q unknown", id)
				stat.Errstatus = statusError
				stat.Result = statusError
			case ErrNotfinished:
				// finished does not exist yet, so it's in progress
				stat.Message = ""
				stat.Result = statusNotFinished
				stat.Errstatus = "ok"
			default:
				stat.Errstatus = statusError
				stat.Message = err.Error()
			}
		}
		allstatus[id] = stat
	}

	buf, marshallerr := json.Marshal(allstatus)
	if marshallerr != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(protocolFile, "Internal error 003:")
		fmt.Fprintln(protocolFile, marshallerr)
		fmt.Fprintln(w, "Internal error 003")
		return
	}
	w.WriteHeader(http.StatusOK)
	w.Write(buf)
	return
}

// Get the status of the PDF (finished?)
func v0StatusHandler(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]
	stat, err := getStatusForID(mux.Vars(r)["id"])
	if err != nil {
		switch err {
		case ErrUnknownID:
			stat.Message = fmt.Sprintf("id %q unknown", id)
			stat.Errstatus = statusError
			stat.Result = statusError
		case ErrNotfinished:
			// finished does not exist yet, so it's in progress
			stat.Message = ""
			stat.Result = statusNotFinished
			stat.Errstatus = "ok"
		default:
			stat.Errstatus = statusError
			stat.Message = err.Error()
		}

		buf, marshallerr := json.Marshal(stat)
		if marshallerr != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(protocolFile, "Internal error 020:")
			fmt.Fprintln(protocolFile, marshallerr)
			fmt.Fprintln(w, "Internal error 020")
			return
		}
		w.WriteHeader(http.StatusBadRequest)
		w.Write(buf)
		return
	}

	buf, marshallerr := json.Marshal(stat)
	if marshallerr != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(protocolFile, "Internal error 025:")
		fmt.Fprintln(protocolFile, marshallerr)
		fmt.Fprintln(w, "Internal error 025")
		return
	}
	w.WriteHeader(http.StatusOK)
	w.Write(buf)
	return
}

func available(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	return
}

func runServer(port string, address string, tempdir string) {
	var err error
	serverTemp = filepath.Join(tempdir, "publisher-server")

	protocolFile, err = os.Create("publisher.protocol")
	if err != nil {
		log.Fatal(err)
	}
	fmt.Fprintf(protocolFile, "Protocol file for speedata Publisher (%s) - server mode\n", version)
	fmt.Fprintln(protocolFile, "Time:", starttime.Format(time.ANSIC))

	options["quiet"] = "true"
	options["autoopen"] = "false"

	startDispatcher(runtime.NumCPU())

	r := mux.NewRouter()
	r.HandleFunc("/available", available)
	v0 := r.PathPrefix("/v0").Subrouter()
	v0.HandleFunc("/publish", v0PublishHandler).Methods("POST")
	v0.HandleFunc("/status", v0GetAllStatusHandler).Methods("GET")
	v0.HandleFunc("/pdf/{id}", v0GetPDFHandler).Methods("GET")
	v0.HandleFunc("/publish/{id}", v0PublishIDHandler).Methods("GET")
	v0.HandleFunc("/status/{id}", v0StatusHandler).Methods("GET")
	v0.HandleFunc("/delete/{id}", v0DeleteHandler).Methods("GET")
	v0.HandleFunc("/data/{id}", v0DataHandler).Methods("GET")
	v0.HandleFunc("/layout/{id}", v0LayoutHandler).Methods("GET")
	v0.HandleFunc("/statusfile/{id}", v0StatusfileHandler).Methods("GET")
	http.Handle("/", r)
	fmt.Printf("Listen on http://%s:%s\n", address, port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf("%s:%s", address, port), nil))
	os.Exit(0)
}
