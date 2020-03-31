// +build gofuzz

package scanner

import "bytes"

func Fuzz(data []byte) int {
	t := []*Token{}
	s := New(string(data))
	var b bytes.Buffer

	for {
		tok := s.Next()
		if tok.Type == Error {
			return 0
		}
		if tok.Type == EOF {
			return 1
		}
		t = append(t, tok)
		err := tok.Emit(&b)
		if err != nil {
			return 0
		}
	}

	return 1
}
