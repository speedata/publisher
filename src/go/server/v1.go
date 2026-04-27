//go:build pro
// +build pro

package server

import (
	"encoding/base64"
	"encoding/json"
	"encoding/xml"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/fsnotify/fsnotify"
	"github.com/gorilla/mux"
)

// problemDetail implements RFC 9457 (Problem Details for HTTP APIs)
type problemDetail struct {
	Type     string `json:"type"`
	Title    string `json:"title"`
	Status   int    `json:"status"`
	Detail   string `json:"detail,omitempty"`
	Instance string `json:"instance,omitempty"`
}

func (s *Server) writeProblem(w http.ResponseWriter, statusCode int, title, detail, instance string) {
	pd := problemDetail{
		Type:     "about:blank",
		Title:    title,
		Status:   statusCode,
		Detail:   detail,
		Instance: instance,
	}
	w.Header().Set("Content-Type", "application/problem+json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(pd)
}

func writeJSON(w http.ResponseWriter, statusCode int, v interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(v)
}

// apiError is returned by v1 internal functions instead of writing to the ResponseWriter directly.
type apiError struct {
	Status  int
	Message string
}

func (e *apiError) Error() string { return e.Message }

// writeFilesV1 is the v1 variant of writeFiles. It does not write to the ResponseWriter on error,
// and sanitizes filenames with filepath.Base to prevent path traversal.
func (s *Server) writeFilesV1(r *http.Request) (string, *apiError) {
	var files map[string]interface{}
	data, err := io.ReadAll(r.Body)
	if err != nil {
		return "", &apiError{Status: http.StatusInternalServerError, Message: "Failed to read request body"}
	}

	if len(data) > 0 {
		err = json.Unmarshal(data, &files)
		if err != nil {
			return "", &apiError{Status: http.StatusBadRequest, Message: "Invalid JSON in request body"}
		}
	}

	err = s.makePublisherTemp()
	if err != nil {
		return "", &apiError{Status: http.StatusInternalServerError, Message: "Failed to create temp directory"}
	}

	tmpdir, err := os.MkdirTemp(s.serverTemp, "")
	if err != nil {
		return "", &apiError{Status: http.StatusInternalServerError, Message: "Failed to create job directory"}
	}

	id, err := filepath.Rel(s.serverTemp, tmpdir)
	if err != nil {
		return "", &apiError{Status: http.StatusInternalServerError, Message: "Failed to determine job ID"}
	}

	fmt.Fprintf(s.ProtocolFile, "%s: Publishing request from %s at %s\n", id, r.RemoteAddr, time.Now().Format("2006-01-02 15:04:05"))

	for k, v := range files {
		safeName := filepath.Base(k)
		bb := strings.NewReader(v.(string))
		b64reader := base64.NewDecoder(base64.StdEncoding, bb)
		f, nerr := os.Create(filepath.Join(tmpdir, safeName))
		if nerr != nil {
			return "", &apiError{Status: http.StatusInternalServerError, Message: fmt.Sprintf("Failed to create file %q", safeName)}
		}
		_, err = io.Copy(f, b64reader)
		if err != nil {
			f.Close()
			return "", &apiError{Status: http.StatusInternalServerError, Message: fmt.Sprintf("Failed to write file %q", safeName)}
		}
		f.Close()
	}

	if vars := r.FormValue("vars"); vars != "" {
		f, err := os.OpenFile(filepath.Join(tmpdir, "extravars"), os.O_RDWR|os.O_CREATE, 0644)
		if err != nil {
			return "", &apiError{Status: http.StatusInternalServerError, Message: "Failed to write variables"}
		}
		for _, v := range strings.Split(vars, ",") {
			f.Write([]byte(v + "\n"))
		}
		f.Close()
	}
	return id, nil
}

const pdfTimeout = 5 * time.Minute

// waitForFileWithTimeout waits for a file to appear in dir, returning an error on timeout.
func waitForFileWithTimeout(dir string, filename string, timeout time.Duration) error {
	requestedFile := filepath.Join(dir, filename)

	// Check if the file already exists
	if _, err := os.Stat(requestedFile); err == nil {
		return nil
	}

	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		return err
	}
	defer watcher.Close()

	done := make(chan error, 1)
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
							done <- nil
							return
						}
					}
				}
			case nerr := <-watcher.Errors:
				done <- nerr
				return
			}
			timer.Stop()
		}
	}()

	if err = watcher.Add(dir); err != nil {
		return err
	}

	select {
	case err := <-done:
		return err
	case <-time.After(timeout):
		return fmt.Errorf("timeout after %s waiting for %s", timeout, filename)
	}
}

// sendPDFV1 is the v1 variant of sendPDF. It does not auto-delete the work directory
// and returns errors instead of writing to the ResponseWriter.
func (s *Server) sendPDFV1(w http.ResponseWriter, r *http.Request, id string) *apiError {
	publishdir := filepath.Join(s.serverTemp, id)
	fi, err := os.Stat(publishdir)
	if err != nil || !fi.IsDir() {
		return &apiError{Status: http.StatusNotFound, Message: fmt.Sprintf("No job with id %q", id)}
	}

	finishedPath := filepath.Join(publishdir, "publisher.finished")
	_, err = os.Stat(finishedPath)
	if err != nil && os.IsNotExist(err) {
		if waitErr := waitForFileWithTimeout(publishdir, "publisher.finished", pdfTimeout); waitErr != nil {
			return &apiError{Status: http.StatusGatewayTimeout, Message: fmt.Sprintf("Job %s did not finish within %s", id, pdfTimeout)}
		}
	}

	statusPath := filepath.Join(publishdir, "publisher.status")
	data, err := os.ReadFile(statusPath)
	if err != nil {
		return &apiError{Status: http.StatusInternalServerError, Message: "Failed to read status file"}
	}

	v := status{}
	err = xml.Unmarshal(data, &v)
	if err != nil {
		return &apiError{Status: http.StatusInternalServerError, Message: "Failed to parse status file"}
	}

	if v.Errors > 0 {
		return &apiError{Status: http.StatusNotAcceptable, Message: fmt.Sprintf("PDF generated with %d error(s)", v.Errors)}
	}

	filename := "publisher.pdf"
	if jobname := r.FormValue("jobname"); jobname != "" {
		filename = jobname + ".pdf"
	}

	if r.FormValue("keep") != "true" {
		defer os.RemoveAll(publishdir)
	}

	w.Header().Set("Content-Type", "application/pdf")
	w.Header().Add("Content-Disposition", fmt.Sprintf(`attachment; filename=%q`, filename))
	w.Header().Add("Content-Transfer-Encoding", "binary")
	http.ServeFile(w, r, filepath.Join(publishdir, "publisher.pdf"))
	return nil
}

// parseModes extracts the mode parameter from the request and splits by comma.
func parseModes(r *http.Request) []string {
	if mode := r.FormValue("mode"); mode != "" {
		return strings.Split(mode, ",")
	}
	return nil
}

// --- v1 Handlers ---

func (s *Server) v1AvailableHandler(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (s *Server) v1CreateJobHandler(w http.ResponseWriter, r *http.Request) {
	id, apiErr := s.writeFilesV1(r)
	if apiErr != nil {
		fmt.Fprintf(s.ProtocolFile, "v1 create job error: %s\n", apiErr.Message)
		s.writeProblem(w, apiErr.Status, "Job creation failed", apiErr.Message, r.URL.Path)
		return
	}
	s.addPublishrequestToQueue(id, parseModes(r))
	writeJSON(w, http.StatusCreated, map[string]string{"id": id})
}

func (s *Server) v1ListJobsHandler(w http.ResponseWriter, r *http.Request) {
	ids := s.getAllIds()
	jobs := make([]map[string]interface{}, 0, len(ids))
	for _, id := range ids {
		entry := map[string]interface{}{"id": id}
		stat, err := s.getStatusForID(id)
		switch err {
		case nil:
			entry["status"] = stat.Result
			entry["message"] = stat.Message
			entry["finished"] = stat.Finished
		case ErrNotfinished:
			entry["status"] = "processing"
		default:
			entry["status"] = "error"
			entry["message"] = err.Error()
		}
		jobs = append(jobs, entry)
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"jobs": jobs})
}

func (s *Server) v1GetJobHandler(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]
	if d := s.checkIDExists(id); d == "" {
		s.writeProblem(w, http.StatusNotFound, "Job not found", fmt.Sprintf("No job with id %q", id), r.URL.Path)
		return
	}
	stat, err := s.getStatusForID(id)
	if err == ErrNotfinished {
		writeJSON(w, http.StatusAccepted, map[string]interface{}{
			"id":     id,
			"status": "processing",
		})
		return
	}
	if err != nil {
		s.writeProblem(w, http.StatusInternalServerError, "Status retrieval failed", err.Error(), r.URL.Path)
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"id":       id,
		"status":   stat.Result,
		"message":  stat.Message,
		"finished": stat.Finished,
	})
}

func (s *Server) v1GetPDFHandler(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]
	fmt.Fprintf(s.ProtocolFile, "v1 /v1/jobs/%s/pdf\n", id)
	if d := s.checkIDExists(id); d == "" {
		s.writeProblem(w, http.StatusNotFound, "Job not found", fmt.Sprintf("No job with id %q", id), r.URL.Path)
		return
	}
	if apiErr := s.sendPDFV1(w, r, id); apiErr != nil {
		fmt.Fprintf(s.ProtocolFile, "v1 pdf error: %s\n", apiErr.Message)
		s.writeProblem(w, apiErr.Status, "PDF retrieval failed", apiErr.Message, r.URL.Path)
	}
}

func (s *Server) v1CreatePDFHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(s.ProtocolFile, "v1 /v1/pdf\n")
	id, apiErr := s.writeFilesV1(r)
	if apiErr != nil {
		fmt.Fprintf(s.ProtocolFile, "v1 create pdf error: %s\n", apiErr.Message)
		s.writeProblem(w, apiErr.Status, "Job creation failed", apiErr.Message, r.URL.Path)
		return
	}
	s.addPublishrequestToQueue(id, parseModes(r))
	if apiErr := s.sendPDFV1(w, r, id); apiErr != nil {
		fmt.Fprintf(s.ProtocolFile, "v1 pdf error: %s\n", apiErr.Message)
		s.writeProblem(w, apiErr.Status, "PDF generation failed", apiErr.Message, r.URL.Path)
	}
}

func (s *Server) v1GetFileHandler(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]
	filename := filepath.Base(mux.Vars(r)["filename"])

	publishdir := s.checkIDExists(id)
	if publishdir == "" {
		s.writeProblem(w, http.StatusNotFound, "Job not found", fmt.Sprintf("No job with id %q", id), r.URL.Path)
		return
	}

	fullPath := filepath.Join(publishdir, filename)
	if _, err := os.Stat(fullPath); os.IsNotExist(err) {
		s.writeProblem(w, http.StatusNotFound, "File not found", fmt.Sprintf("File %q not found in job %q", filename, id), r.URL.Path)
		return
	}

	http.ServeFile(w, r, fullPath)
}

func (s *Server) v1DeleteJobHandler(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]
	fmt.Fprintf(s.ProtocolFile, "v1 DELETE /v1/jobs/%s\n", id)
	publishdir := s.checkIDExists(id)
	if publishdir == "" {
		s.writeProblem(w, http.StatusNotFound, "Job not found", fmt.Sprintf("No job with id %q", id), r.URL.Path)
		return
	}
	if err := os.RemoveAll(publishdir); err != nil {
		fmt.Fprintln(s.ProtocolFile, err)
		s.writeProblem(w, http.StatusInternalServerError, "Deletion failed", err.Error(), r.URL.Path)
		return
	}
	fmt.Fprintln(s.ProtocolFile, "ok")
	w.WriteHeader(http.StatusNoContent)
}
