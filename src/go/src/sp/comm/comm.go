package comm

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"strconv"
)

func reader(message chan []byte, c net.Conn) {
	msgstart := make([]byte, 12)

	_, err := c.Read(msgstart)
	if err != nil {
		if err == io.EOF {
			return
		} else {
			log.Fatal("c.Read: ", err)
		}
	}
	tmp := bytes.Split(msgstart, []byte(","))
	if len(tmp) != 3 {
		log.Println("Internal error: message length 3 expected, got: ", len(tmp))
		message <- ""
		return
	}

	numberOfMessages := tmp[0]
	messageType := tmp[1]
	messageLength, err := strconv.Atoi(string(tmp[2]))
	if err != nil {
		log.Println("Can't decode integer", tmp[2], err)
		message <- ""
		return
	}

	msg := make([]byte, messageLength)
	n, err := c.Read(msg)
	if err != nil {
		log.Println("Can't read enough bytes", err)
		message <- ""
		return
	}

	if n != messageLength {
		log.Println("not enough bytes read. Got ", n, " but expected ", messageLength)
		message <- ""
		return
	}
	message <- msg
}

func (s *Server) StringMessage(typ, msg string) {
	write := fmt.Sprintf("1,%s,%06d%s", typ, len(msg), msg)
	s.Conn.Write([]byte(write))
}

type Server struct {
	Listener   net.Listener
	Conn       net.Conn
	serverused bool
	Message    chan []byte
}

func NewServer() *Server {
	l, err := net.Listen("tcp", ":0")
	if err != nil {
		log.Fatalf("net.Listen %s", err)
	}
	usedport := l.Addr().(*net.TCPAddr).Port
	os.Setenv("SP_SERVERPORT", strconv.Itoa(usedport))
	s := &Server{}
	s.Listener = l
	s.Message = make(chan []byte)
	return s
}

func (s *Server) Close() {
	if s.serverused {
		s.Conn.Close()
		s.Listener.Close()
	}
}

func (s *Server) Run() {
	var err error
	s.Conn, err = s.Listener.Accept()
	if err != nil {
		log.Fatalf("lAccept %s", err)
	}

	msg := make(chan []byte)

	for {
		go reader(msg, s.Conn)
		select {

		case x := <-msg:
			s.Message <- x
		}
	}
}
