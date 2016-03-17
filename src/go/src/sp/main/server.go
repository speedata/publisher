package main

import (
	"bytes"
	"configurator"
	"encoding/base64"
	"encoding/json"
	"encoding/xml"
	"errors"
	"fmt"
	"fsnotify"
	"github.com/gorilla/mux"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"time"
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
	} else {
		// not a directory, panic!
		return errors.New("Internal error: serverTemp exists, but is not a directory.")
	}

	return nil
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
	WorkQueue <- WorkRequest{Id: id}
}

// Wait until filename in dir exists and is complete
func waitForAllFiles(dir string) error {
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		return err
	}
	defer watcher.Close()
	done := make(chan bool)
	var goerr error
	go func() {
		for {
			timer := time.NewTimer(100 * time.Millisecond)
			select {
			case event := <-watcher.Events:
				if event.Op&fsnotify.Write == fsnotify.Write || event.Op&fsnotify.Create == fsnotify.Create {
				}
			case <-timer.C:
				done <- true
				return
			case err := <-watcher.Errors:
				goerr = err
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
func v0PublishIdHandler(w http.ResponseWriter, r *http.Request) {
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
		response.Status = "error"
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
		response.Blob = "not finished"
		response.Status = "error"
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
		response.Status = "error"
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
func checkIdExists(id string) string {
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
	} else {
		return publishdir
	}
}

// Delete the folder with the given ID
func v0DeleteHandler(w http.ResponseWriter, r *http.Request) {
	// Not found? 404
	// Deleted? 200
	id := mux.Vars(r)["id"]
	fmt.Fprintf(protocolFile, "/v0/delete/%s\n", id)
	if d := checkIdExists(id); d != "" {
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

	statusPath := filepath.Join(publishdir, "publisher.status")
	err = waitForAllFiles(publishdir)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(protocolFile, "Internal error 007:")
		fmt.Fprintln(protocolFile, err)
		fmt.Fprintln(w, "Internal error 007")
		return
	}

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
		f, err := os.Create(filepath.Join(tmpdir, k))
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(protocolFile, "Internal error 015:")
			fmt.Fprintln(protocolFile, err)
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
		cd, err := configurator.ReadFiles(filepath.Join(tmpdir, "publisher.cfg"))
		if err == nil {
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
		Id string `json:"id"`
	}{
		Id: id,
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

// Get the status of the PDF (finished?)
func v0StatusHandler(w http.ResponseWriter, r *http.Request) {
	type statusresponse struct {
		Errstatus string `json:"errorstatus"`
		Result    string `json:"result"`
		Message   string `json:"message"`
		Finished  string `json:"finished"`
	}
	stat := statusresponse{}
	id := mux.Vars(r)["id"]
	publishdir := filepath.Join(serverTemp, id)
	fi, err := os.Stat(publishdir)
	if err != nil && os.IsNotExist(err) || !fi.IsDir() {
		stat.Message = fmt.Sprintf("id %q unknown", id)
		stat.Errstatus = "error"
		stat.Result = "error"
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

	statusPath := filepath.Join(publishdir, "publisher.status")
	finishedPath := filepath.Join(publishdir, "publisher.finished")
	fi, err = os.Stat(finishedPath)
	if err != nil && os.IsNotExist(err) {
		// finished does not exist yet, so it's in progress
		stat.Message = ""
		stat.Result = "not finished"
		stat.Errstatus = "ok"

		buf, marshallerr := json.Marshal(stat)
		if marshallerr != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(protocolFile, "Internal error 021:")
			fmt.Fprintln(protocolFile, marshallerr)
			fmt.Fprintln(w, "Internal error 021")
			return
		}
		w.WriteHeader(http.StatusOK)
		w.Write(buf)
		return
	}
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(protocolFile, "Internal error 022:")
		fmt.Fprintln(protocolFile, err)
		fmt.Fprintln(w, "Internal error 022")
		return
	}

	data, err := ioutil.ReadFile(statusPath)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(protocolFile, "Internal error 023:")
		fmt.Fprintln(protocolFile, err)
		fmt.Fprintln(w, "Internal error 023")
		return
	}

	v := status{}
	err = xml.Unmarshal(data, &v)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(protocolFile, "Internal error 024:")
		fmt.Fprintln(protocolFile, err)
		fmt.Fprintln(w, "Internal error 024")
		return
	}
	stat.Finished = fi.ModTime().Format(time.RFC3339)
	if v.Errors != 0 {
		stat.Errstatus = "ok"
		stat.Result = "failed"
		stat.Message = fmt.Sprintf("%d errors occurred during publishing run", v.Errors)
	} else {
		stat.Result = "finished"
		stat.Errstatus = "ok"
		stat.Message = "no errors found"
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

func v0FormatHandler(w http.ResponseWriter, req *http.Request) {
	if !daemonStarted {
		// The daemon is notneeded in server mode, unless we need to talk to the client.
		go daemon.Run()
		daemonStarted = true
		cmdline := fmt.Sprintf(`"%s" --interaction nonstopmode --ini "--lua=%s" publisher.tex ___server___`, getExecutablePath(), inifile)
		if !run(cmdline) {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(w, "Child process not started")
			fmt.Fprintln(protocolFile, "Child process not started")
			return
		}
	}

	if req.ContentLength > 65536 {
		log.Println("content length for POST request too large, max size 64k")
		return
	}
	buf := make([]byte, req.ContentLength)
	n, err := req.Body.Read(buf)
	if err != nil && err != io.EOF {
		log.Println(err)
		return
	}
	daemon.StringMessage("fmt", string(buf[:n]))

	w.Write(<-daemon.Message)
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

	StartDispatcher(runtime.NumCPU())

	r := mux.NewRouter()
	r.HandleFunc("/available", available)
	v0 := r.PathPrefix("/v0").Subrouter()
	v0.HandleFunc("/format", v0FormatHandler)
	v0.HandleFunc("/publish", v0PublishHandler).Methods("POST")
	v0.HandleFunc("/pdf/{id}", v0GetPDFHandler).Methods("GET")
	v0.HandleFunc("/publish/{id}", v0PublishIdHandler).Methods("GET")
	v0.HandleFunc("/status/{id}", v0StatusHandler).Methods("GET")
	v0.HandleFunc("/delete/{id}", v0DeleteHandler).Methods("GET")
	http.Handle("/", r)
	fmt.Printf("Listen on http://%s:%s\n", address, port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf("%s:%s", address, port), nil))
	os.Exit(0)
}
