package main

import (
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"log"
	"net/http"
	"os"
)

func v0FormatHandler(rw http.ResponseWriter, req *http.Request) {
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
	server.StringMessage("fmt", string(buf[:n]))

	rw.Write(<-server.Message)
}

func runServer(port string) {
	r := mux.NewRouter()
	v0 := r.PathPrefix("/v0").Subrouter()
	v0.HandleFunc("/format", v0FormatHandler)
	http.Handle("/", r)
	fmt.Printf("Listen on http://127.0.0.1:%s\n", port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf("127.0.0.1:%s", port), nil))

	os.Exit(0)
}
