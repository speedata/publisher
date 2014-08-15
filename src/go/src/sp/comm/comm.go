package comm

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"strconv"

	"sp/xpath"
)

func getMessage(c net.Conn) (n int, typ string, message []byte, err error) {
	msgstart := make([]byte, 12)

	_, err = c.Read(msgstart)
	if err != nil {
		return
	}

	tmp := bytes.Split(msgstart, []byte(","))
	if len(tmp) != 3 {
		log.Println("Internal error: message length 3 expected, got: ", len(tmp))
		log.Printf("%#v\n", tmp)
		return
	}

	n, err = strconv.Atoi(string(tmp[0]))
	if err != nil {
		return
	}
	typ = string(tmp[1])
	messageLength, err := strconv.Atoi(string(tmp[2]))
	if err != nil {
		return
	}

	message = make([]byte, messageLength)
	var n_ int
	n_, err = c.Read(message)
	if err != nil {
		log.Println("Can't read enough bytes", err)
		return
	}

	if n_ != messageLength {
		log.Println("not enough bytes read. Got ", n, " but expected ", messageLength)
		err = errors.New("Message too short")
		return
	}
	return
}

func reader(message chan []byte, c net.Conn) {
	_, typ, msg, err := getMessage(c)
	if err != nil {
		if err == io.EOF {
			// publisher quits data processing, we can stop listening to it
			close(message)
		} else {
			log.Println(err)
			message <- []byte{}
		}
		return
	}
	switch typ {
	case "tok":
		_, _, rexp, err := getMessage(c)
		if err != nil {
			log.Println(err)
			message <- []byte{}
			return
		}
		res := xpath.Tokenize(msg, string(rexp))
		for i := 0; i < len(res); i++ {
			msg := res[i]
			write := fmt.Sprintf("%d,str,%06d%s", len(res)-i-1, len(msg), msg)
			c.Write([]byte(write))
		}
		message <- []byte{}
		return
	case "rep":
		_, _, rexp, err := getMessage(c)
		if err != nil {
			log.Println(err)
			message <- []byte{}
			return
		}
		_, _, repl, err := getMessage(c)
		if err != nil {
			log.Println(err)
			message <- []byte{}
			return
		}
		res := xpath.Replace(msg, string(rexp), repl)
		write := fmt.Sprintf("0,str,%06d%s", len(res), res)
		c.Write([]byte(write))
		message <- []byte{}
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
		case x, ok := <-msg:
			if !ok {
				return
			}
			if len(x) > 0 {
				s.Message <- x
			}
		}
	}
}
