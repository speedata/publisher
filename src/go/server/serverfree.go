//go:build !pro
// +build !pro

package server

import (
	"fmt"
	"io"
)

// Server configuration
type Server struct {
	Address        string
	ClientExtraDir []string
	Port           string
	Filter         string
	Verbose        bool
	Tempdir        string
	BinaryPath     string
	Runs           string
	ProtocolFile   io.Writer
}

// NewServer returns a new server object
func NewServer() *Server {
	fmt.Println("The speedata server mode is available in the Pro plan.")
	return &Server{}
}

// Run starts the speedata server on the given port
func (s *Server) Run() {

}
