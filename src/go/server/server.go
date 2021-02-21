package server

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

// The LuaTeX process writes out a file called "publisher.status"
// which is a valid XML file. Currently the only field is "Errors"
// with the number of errors occurred during the publisher run.
type statuserror struct {
	XMLName xml.Name `xml:"Error"`
	Code    int      `xml:"code,attr"`
	Error   string   `xml:",chardata"`
}

type status struct {
	XMLName xml.Name `xml:"Status"`
	Error   []statuserror
	Errors  int
}

func (s *Server) makePublisherTemp() error {
	fi, err := os.Stat(s.serverTemp)
	if err != nil && !os.IsNotExist(err) {
		return err
	}

	// If it doesn't exist, make it
	if os.IsNotExist(err) {
		err = os.MkdirAll(s.serverTemp, 0755)
		return err
	}

	// if it exists and is a directory, that's fine
	if fi.IsDir() {
		return nil
	}
	// not a directory, panic!
	return errors.New("internal error: s.serverTemp exists, but is not a directory")
}

func fileToString(filename string) string {
	myfile, err := ioutil.ReadFile(filename)
	if err != nil {
		return ""
	}
	return string(myfile)
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

func (s *Server) addPublishrequestToQueue(id string, modes []string) {
	fmt.Fprintf(s.ProtocolFile, "%s: Add request to queue.\n", id)
	workQueue <- WorkRequest{ID: id, Modes: modes}
}

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
func (s *Server) v0PublishIDHandler(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]
	response := struct {
		Status     string `json:"status"`
		Path       string `json:"path"`
		Blob       string `json:"blob"`
		Statusfile string `json:"statusfile"`
		Finished   string `json:"finished"`
		Output     string `json:"output"`
	}{}
	publishdir := filepath.Join(s.serverTemp, id)
	fi, err := os.Stat(publishdir)
	if err != nil && os.IsNotExist(err) || !fi.IsDir() {
		response.Status = statusError
		response.Blob = "id unknown"
		buf, marshallerr := json.Marshal(response)
		if marshallerr != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(s.ProtocolFile, "Internal error 001:")
			fmt.Fprintln(s.ProtocolFile, marshallerr)
			fmt.Fprintln(w, "Internal error 001")
			return
		}
		w.WriteHeader(http.StatusBadRequest)
		w.Write(buf)
		return
	}

	pdfPath := filepath.Join(publishdir, "publisher.pdf")
	statusfilePath := filepath.Join(publishdir, "publisher.status")
	finishedfile := filepath.Join(s.serverTemp, id, id+"finished.txt")
	outputfile := filepath.Join(s.serverTemp, id, "output.txt")

	fi, err = os.Stat(finishedfile)
	if err != nil && os.IsNotExist(err) {
		// status does not exist yet, so it's in progress
		response.Blob = statusNotFinished
		response.Status = statusError
		buf, marshallerr := json.Marshal(response)
		if marshallerr != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(s.ProtocolFile, "Internal error 002:")
			fmt.Fprintln(s.ProtocolFile, marshallerr)
			fmt.Fprintln(w, "Internal error 002")
			return
		}
		w.WriteHeader(http.StatusNotFound)
		w.Write(buf)
		return
	}
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(s.ProtocolFile, "Internal error 003:")
		fmt.Fprintln(s.ProtocolFile, err)
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
	response.Blob, _ = encodeFileToBase64(pdfPath)

	if response.Blob == "" {
		response.Status = statusError
		response.Path = ""
	}

	response.Statusfile, err = encodeFileToBase64(statusfilePath)
	if err != nil {
		fmt.Fprintf(s.ProtocolFile, "%s: No status file, something went wrong\n", id)
		response.Status = statusError
	}

	response.Output = fileToString(outputfile)

	buf, marshallerr := json.Marshal(response)
	if marshallerr != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(s.ProtocolFile, "Internal error 006:")
		fmt.Fprintln(s.ProtocolFile, marshallerr)
		fmt.Fprintln(w, "Internal error 006")
		return
	}
	w.WriteHeader(http.StatusOK)
	w.Write(buf)
	return
}

// Return full path to directory on success, empty string on failure
func (s *Server) checkIDExists(id string) string {
	publishdir := filepath.Join(s.serverTemp, id)
	fi, err := os.Stat(publishdir)
	if err != nil {
		return ""
	}
	if err != nil && os.IsNotExist(err) || !fi.IsDir() {
		// Does not exist or is not a directory
		return ""
	}
	if a, err := filepath.Rel(filepath.Join(publishdir, ".."), s.serverTemp); err != nil && a == "." {
		return ""
	}
	return publishdir
}

// Delete the folder with the given ID
func (s *Server) v0DeleteHandler(w http.ResponseWriter, r *http.Request) {
	// Not found? 404
	// Deleted? 200
	id := mux.Vars(r)["id"]
	fmt.Fprintf(s.ProtocolFile, "/v0/delete/%s\n", id)
	if d := s.checkIDExists(id); d != "" {
		err := os.RemoveAll(d)
		if err != nil {
			fmt.Fprintln(s.ProtocolFile, err)
		} else {
			fmt.Fprintln(s.ProtocolFile, "ok")
		}
		w.WriteHeader(http.StatusOK)
	} else {
		fmt.Fprintln(s.ProtocolFile, "not found")
		w.WriteHeader(http.StatusNotFound)
	}
}

// Return the PDF from job id (given in the URL)
func (s *Server) v0GetPDFHandler(w http.ResponseWriter, r *http.Request) {
	// Not found? 404
	// PDF not ready? Wait
	// PDF has errors? 406
	// PDF ok? 200
	// Internal error? 500
	id := mux.Vars(r)["id"]
	fmt.Fprintf(s.ProtocolFile, "/v0/pdf/%s\n", id)
	publishdir := filepath.Join(s.serverTemp, id)
	fi, err := os.Stat(publishdir)
	if err != nil && os.IsNotExist(err) || !fi.IsDir() {
		w.WriteHeader(http.StatusNotFound)
		fmt.Fprintln(s.ProtocolFile, err)
		return
	}

	// Only if the PDF is finished, we may remove the directory
	if r.FormValue("delete") != "false" {
		defer os.RemoveAll(publishdir)
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
		fmt.Fprintln(s.ProtocolFile, "Internal error 008:")
		fmt.Fprintln(s.ProtocolFile, err)
		fmt.Fprintln(w, "Internal error 008")
		return
	}

	v := status{}
	err = xml.Unmarshal(data, &v)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(s.ProtocolFile, "Internal error 009:")
		fmt.Fprintln(s.ProtocolFile, err)
		fmt.Fprintln(w, "Internal error 009")
		return
	}

	if v.Errors > 0 {
		w.WriteHeader(http.StatusNotAcceptable)
		fmt.Fprintf(s.ProtocolFile, "PDF with errors")
		return
	}

	filename := "publisher.pdf"
	// if jobname.txt was written, use the contents for the jobname
	fi, err = os.Stat(filepath.Join(publishdir, "jobname.txt"))
	if err == nil {
		name, err := ioutil.ReadFile(filepath.Join(publishdir, "jobname.txt"))
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(s.ProtocolFile, "Internal error 010:")
			fmt.Fprintln(s.ProtocolFile, err)
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
func (s *Server) sendFile(id string, filename string, w http.ResponseWriter, r *http.Request) {
	publishdir := filepath.Join(s.serverTemp, id)
	fi, err := os.Stat(publishdir)
	if err != nil && os.IsNotExist(err) || !fi.IsDir() {
		w.WriteHeader(http.StatusNotFound)
		fmt.Fprintln(s.ProtocolFile, err)
		return
	}
	val := r.URL.Query()
	f, err := os.Open(filepath.Join(publishdir, filename))
	if err != nil {
		s.writeInternalError(w)
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
			s.writeInternalError(w)
			return
		}

		a := struct {
			Data string `json:"contents"`
		}{
			Data: string(buf),
		}

		b, err := json.Marshal(a)
		if err != nil {
			s.writeInternalError(w)
			return
		}
		fmt.Fprintln(w, string(b))
	default:
		w.Header().Set("Content-Type", "application/xml")
		io.Copy(w, f)
	}

}

func (s *Server) v0DataHandler(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]
	fmt.Fprintf(s.ProtocolFile, "/v0/data/%s\n", id)
	s.sendFile(id, "data.xml", w, r)
}

func (s *Server) v0LayoutHandler(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]
	fmt.Fprintf(s.ProtocolFile, "/v0/layout/%s\n", id)
	s.sendFile(id, "layout.xml", w, r)
}

// send the file publisher.status
func (s *Server) v0StatusfileHandler(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]
	fmt.Fprintf(s.ProtocolFile, "/v0/statusfile/%s\n", id)
	s.sendFile(id, "publisher.status", w, r)
}

func (s *Server) writeInternalError(w http.ResponseWriter) {
	fmt.Fprintln(w, "Internal error")
	return
}

// Start a publishing process. Accepted parameter:
//   jobname=<jobname>
//   vars=var1=foo,var2=bar (where all but the frist = is encoded as %3D)
func (s *Server) v0PublishHandler(w http.ResponseWriter, r *http.Request) {
	var files map[string]interface{}
	data, err := ioutil.ReadAll(r.Body)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(s.ProtocolFile, "Internal error 011:")
		fmt.Fprintln(s.ProtocolFile, err)
		fmt.Fprintln(w, "Internal error 011")
		return
	}

	err = json.Unmarshal(data, &files)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		fmt.Fprintln(w, "JSON error:", err)
		return
	}
	err = s.makePublisherTemp()
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(s.ProtocolFile, "Internal error 012:")
		fmt.Fprintln(s.ProtocolFile, err)
		fmt.Fprintln(w, "Internal error 012")
		return
	}

	tmpdir, err := ioutil.TempDir(s.serverTemp, "")
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(s.ProtocolFile, "Internal error 013:")
		fmt.Fprintln(s.ProtocolFile, err)
		fmt.Fprintln(w, "Internal error 013")
		return
	}

	id, err := filepath.Rel(s.serverTemp, tmpdir)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(s.ProtocolFile, "Internal error 014:")
		fmt.Fprintln(s.ProtocolFile, err)
		fmt.Fprintln(w, "Internal error 014")
		return
	}

	fmt.Fprintf(s.ProtocolFile, "%s: Publishing request from %s at %s\n", id, r.RemoteAddr, time.Now().Format("2006-01-02 15:04:05"))

	for k, v := range files {
		bb := bytes.NewBuffer([]byte(v.(string)))
		b64reader := base64.NewDecoder(base64.StdEncoding, bb)
		f, nerr := os.Create(filepath.Join(tmpdir, k))
		if nerr != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(s.ProtocolFile, "Internal error 015:")
			fmt.Fprintln(s.ProtocolFile, nerr)
			fmt.Fprintln(w, "Internal error 015")
			return
		}
		_, err = io.Copy(f, b64reader)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(s.ProtocolFile, "Internal error 016:")
			fmt.Fprintln(s.ProtocolFile, err)
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
			fmt.Fprintln(s.ProtocolFile, "Internal error 017:")
			fmt.Fprintln(s.ProtocolFile, err)
			fmt.Fprintln(w, "Internal error 017")
			return
		}
	}

	if vars := r.FormValue("vars"); vars != "" {
		f, err := os.OpenFile(filepath.Join(tmpdir, "extravars"), os.O_RDWR|os.O_CREATE, 0644)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(s.ProtocolFile, "Internal error 018:")
			fmt.Fprintln(s.ProtocolFile, err)
			fmt.Fprintln(w, "Internal error 018")
			return
		}
		for _, v := range strings.Split(vars, ",") {
			f.Write([]byte(v + "\n"))
		}
		f.Close()
	}
	var modes []string
	if mode := r.FormValue("mode"); mode != "" {
		modes = strings.Split(mode, ",")
	}

	s.addPublishrequestToQueue(id, modes)

	jsonid := struct {
		ID string `json:"id"`
	}{
		ID: id,
	}
	buf, marshallerr := json.Marshal(jsonid)
	if marshallerr != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(s.ProtocolFile, "Internal error 019:")
		fmt.Fprintln(s.ProtocolFile, marshallerr)
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

func (s *Server) getStatusForID(id string) (statusresponse, error) {
	spstatus := statusresponse{}
	publishdir := filepath.Join(s.serverTemp, id)
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
func (s *Server) getAllIds() []string {
	ret := []string{}

	matches, err := filepath.Glob(s.serverTemp + "/*")
	if err != nil {
		fmt.Println(err)
		return []string{}
	}
	serverTempWithSlash := s.serverTemp + "/"
	for _, match := range matches {
		if isPublishingDir(match) {
			id := strings.TrimPrefix(match, serverTempWithSlash)
			ret = append(ret, id)
		}
	}
	return ret
}

func (s *Server) v0GetAllStatusHandler(w http.ResponseWriter, r *http.Request) {

	allstatus := make(map[string]statusresponse)

	for _, id := range s.getAllIds() {
		stat, err := s.getStatusForID(id)
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
		fmt.Fprintln(s.ProtocolFile, "Internal error 003:")
		fmt.Fprintln(s.ProtocolFile, marshallerr)
		fmt.Fprintln(w, "Internal error 003")
		return
	}
	w.WriteHeader(http.StatusOK)
	w.Write(buf)
	return
}

// Get the status of the PDF (finished?)
func (s *Server) v0StatusHandler(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]
	stat, err := s.getStatusForID(mux.Vars(r)["id"])
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
			fmt.Fprintln(s.ProtocolFile, "Internal error 020:")
			fmt.Fprintln(s.ProtocolFile, marshallerr)
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
		fmt.Fprintln(s.ProtocolFile, "Internal error 025:")
		fmt.Fprintln(s.ProtocolFile, marshallerr)
		fmt.Fprintln(w, "Internal error 025")
		return
	}
	w.WriteHeader(http.StatusOK)
	w.Write(buf)
	return
}

func (s *Server) available(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	return
}

// Server configuration
type Server struct {
	Address        string
	ClientExtraDir []string
	Port           string
	Filter         string
	Verbose        bool
	Tempdir        string
	BinaryPath     string
	ProtocolFile   io.Writer
	serverTemp     string
}

// NewServer returns a new server object
func NewServer() *Server {
	return &Server{}
}

// Run starts the speedata server on the given port
func (s *Server) Run() {

	s.serverTemp = filepath.Join(s.Tempdir, "publisher-server")
	startDispatcher(s, runtime.NumCPU())

	r := mux.NewRouter()
	r.HandleFunc("/available", s.available)
	v0 := r.PathPrefix("/v0").Subrouter()
	v0.HandleFunc("/publish", s.v0PublishHandler).Methods("POST")
	v0.HandleFunc("/status", s.v0GetAllStatusHandler).Methods("GET")
	v0.HandleFunc("/pdf/{id}", s.v0GetPDFHandler).Methods("GET")
	v0.HandleFunc("/publish/{id}", s.v0PublishIDHandler).Methods("GET")
	v0.HandleFunc("/status/{id}", s.v0StatusHandler).Methods("GET")
	v0.HandleFunc("/delete/{id}", s.v0DeleteHandler).Methods("GET")
	v0.HandleFunc("/data/{id}", s.v0DataHandler).Methods("GET")
	v0.HandleFunc("/layout/{id}", s.v0LayoutHandler).Methods("GET")
	v0.HandleFunc("/statusfile/{id}", s.v0StatusfileHandler).Methods("GET")
	http.Handle("/", r)
	fmt.Fprintf(s.ProtocolFile, "Listen on http://%s:%s\n", s.Address, s.Port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf("%s:%s", s.Address, s.Port), nil))
	os.Exit(0)
}
