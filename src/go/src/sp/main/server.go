package main

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"encoding/xml"
	"errors"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"time"
)

var (
	daemonStarted bool
	serverTemp    string
	protocolFile  *os.File
)

func init() {
	serverTemp = filepath.Join(os.TempDir(), "publisher-server")

}

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

func v0GetPDFHandler(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]
	response := struct {
		Status string `json:"status"`
		Path   string `json:"path"`
		Blob   string `json:"blob"`
	}{}

	publishdir := filepath.Join(serverTemp, id)
	fi, err := os.Stat(publishdir)
	if err != nil && os.IsNotExist(err) || !fi.IsDir() {
		response.Status = "error"
		response.Blob = "id unknown"
		buf, marshallerr := json.Marshal(response)
		if marshallerr != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(w, marshallerr)
			return
		}
		w.WriteHeader(http.StatusBadRequest)
		w.Write(buf)
		return
	}

	pdfPath := filepath.Join(publishdir, "publisher.pdf")
	if r.FormValue("delete") != "false" {
		defer os.RemoveAll(publishdir)
	}

	fi, err = os.Stat(pdfPath)
	if err != nil && os.IsNotExist(err) {
		// status does not exist yet, so it's in progress
		response.Blob = "not finished"
		response.Status = "error"
	}
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(w, err)
		return
	}

	// data, err := ioutil.ReadFile(pdfPath)
	response.Status = "ok"
	response.Path = pdfPath
	response.Blob, err = encodeFileToBase64(pdfPath)
	buf, marshallerr := json.Marshal(response)
	if marshallerr != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(w, marshallerr)
		return
	}
	w.WriteHeader(http.StatusOK)
	w.Write(buf)
	return
}

func v0PublishHandler(w http.ResponseWriter, r *http.Request) {
	var files map[string]interface{}
	fmt.Fprintf(protocolFile, "%s: Publishing request from %s ... ", time.Now().Format("2006-01-02 15:04:05"), r.RemoteAddr)
	data, err := ioutil.ReadAll(r.Body)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(w, err)
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
		fmt.Fprintln(w, err)
		return
	}

	tmpdir, err := ioutil.TempDir(serverTemp, "")
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(w, err)
		return
	}

	id, err := filepath.Rel(serverTemp, tmpdir)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(w, err)
		return
	}

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(w, err)
		return
	}

	for k, v := range files {
		bb := bytes.NewBuffer([]byte(v.(string)))
		b64reader := base64.NewDecoder(base64.StdEncoding, bb)
		f, err := os.Create(filepath.Join(tmpdir, k))
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(w, err)
			return
		}
		_, err = io.Copy(f, b64reader)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(w, err)
			return
		}
		f.Close()
	}

	fmt.Fprintf(protocolFile, "executing with id %s\n", id)

	cmd := exec.Command(filepath.Join(bindir, "sp"+exe_suffix))
	cmd.Dir = tmpdir
	go cmd.Run()

	jsonid := struct {
		Id string `json:"id"`
	}{
		Id: id,
	}
	buf, marshallerr := json.Marshal(jsonid)
	if marshallerr != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(w, marshallerr)
		return
	}
	w.WriteHeader(http.StatusOK)
	w.Write(buf)

	return
}

func v0StatusHandler(w http.ResponseWriter, r *http.Request) {
	type statusresponse struct {
		Errstatus string `json:"errorstatus"`
		Result    string `json:"result"`
		Message   string `json:"message"`
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
			fmt.Fprintln(w, marshallerr)
			return
		}
		w.WriteHeader(http.StatusBadRequest)
		w.Write(buf)
		return
	}

	statusPath := filepath.Join(publishdir, "publisher.status")
	fi, err = os.Stat(statusPath)
	if err != nil && os.IsNotExist(err) {
		// status does not exist yet, so it's in progress
		stat.Message = ""
		stat.Result = "not finished"
		stat.Errstatus = "ok"
	}
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(w, err)
		return
	}

	data, err := ioutil.ReadFile(statusPath)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(w, err)
		return
	}

	v := status{}
	err = xml.Unmarshal(data, &v)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintln(w, err)
		return
	}

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
		fmt.Fprintln(w, marshallerr)
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

func runServer(port string, address string) {
	var err error
	protocolFile, err = os.Create("publisher.protocol")
	if err != nil {
		log.Fatal(err)
	}
	fmt.Fprintf(protocolFile, "Protocol file for speedata Publisher (%s) - server mode\n", version)
	fmt.Fprintln(protocolFile, "Time:", starttime.Format(time.ANSIC))

	options["quiet"] = "true"
	options["autoopen"] = "false"

	r := mux.NewRouter()
	v0 := r.PathPrefix("/v0").Subrouter()
	v0.HandleFunc("/format", v0FormatHandler)
	v0.HandleFunc("/publish", v0PublishHandler).Methods("POST")
	v0.HandleFunc("/publish/{id}", v0GetPDFHandler).Methods("GET")
	v0.HandleFunc("/status/{id}", v0StatusHandler).Methods("GET")
	http.Handle("/", r)
	fmt.Printf("Listen on http://%s:%s\n", address, port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf("%s:%s", address, port), nil))
	os.Exit(0)
}
