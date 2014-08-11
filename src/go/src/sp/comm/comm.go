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

func reader(done chan bool, c net.Conn) {
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
		log.Fatal("Internal error: message length 3 expected, got: ", len(tmp))
	}

	numberOfMessages := tmp[0]
	messageType := tmp[1]
	messageLength, err := strconv.Atoi(string(tmp[2]))

	if err != nil {
		log.Fatal(err)
	}

	if false {
		fmt.Println(numberOfMessages, messageType)
	}

	msg := make([]byte, messageLength)
	n, err := c.Read(msg)
	if err != nil {
		log.Fatal(err)
	}

	if n != messageLength {
		log.Fatal("not enough bytes read. Got ", n, " but expected ", messageLength)
	}
	done <- true
}

func (s *Server) StringMessage(typ, msg string) {
	write := fmt.Sprintf("1,%s,%06d%s", typ, len(msg), msg)
	s.Conn.Write([]byte(write))
}

type Server struct {
	Listener net.Listener
	Conn     net.Conn
}

func NewServer() *Server {
	l, err := net.Listen("tcp", ":0")
	if err != nil {
		log.Fatalf("net.Listen %s", err)
	}
	usedport := l.Addr().(*net.TCPAddr).Port
	// fmt.Println("Internal server start on port", usedport)
	os.Setenv("SP_SERVERPORT", strconv.Itoa(usedport))
	s := &Server{}
	s.Listener = l
	return s
}

func (s *Server) Run() {
	var err error
	s.Conn, err = s.Listener.Accept()
	if err != nil {
		log.Fatalf("lAccept %s", err)
	}

	done := make(chan bool)

	for {
		go reader(done, s.Conn)
		// fmt.Println("for")
		select {

		case <-done:
			// fmt.Println("reader")
		} // Wait for a connection.
	}

	// err = conn.Close()
	// if err != nil {
	// 	log.Fatal("conn.Close", err)
	// }
	// defer l.Close()
}
