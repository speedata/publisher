package gogit

import (
	"encoding/hex"
	"errors"
	"fmt"
)

// Oid is the representation of a sha1-string
type Oid struct {
	Bytes SHA1
}

// Create a new Oid from a Sha1 string of length 40.
func NewOidFromString(sha1 string) (*Oid, error) {
	b, err := hex.DecodeString(sha1)
	if err != nil {
		return nil, err
	}
	o := new(Oid)
	for i := 0; i < 20; i++ {
		o.Bytes[i] = b[i]
	}

	return o, nil
}

// Create a new Oid from a 20 byte slice.
func NewOid(b []byte) (*Oid, error) {
	if len(b) != 20 {
		return nil, errors.New("Length must be 20")
	}
	o := new(Oid)
	for i := 0; i < 20; i++ {
		o.Bytes[i] = b[i]
	}
	return o, nil
}

// Create a new Oid from a 40 byte slice representing a string. This saves calling
// string(data) every time we need a new Oid
func NewOidFromByteString(b []byte) (*Oid, error) {
	if len(b) != 40 {
		return nil, errors.New(fmt.Sprintf("Length must be 40, but is %d", len(b)))
	}
	return NewOidFromString(string(b))
}

// Create a new Oid from a 20 byte array
func NewOidFromArray(a SHA1) *Oid {
	return &Oid{a}
}

// Return string (hex) representation of the Oid
func (o *Oid) String() string {
	result := make([]byte, 0, 40)
	hexvalues := []byte("0123456789abcdef")
	for i := 0; i < 20; i++ {
		result = append(result, hexvalues[o.Bytes[i]>>4])
		result = append(result, hexvalues[o.Bytes[i]&0xf])
	}
	return string(result)
}

// Return true if oid2 has the same sha1 as caller
func (o *Oid) Equal(oid2 *Oid) bool {
	for i, v := range oid2.Bytes {
		if o.Bytes[i] != v {
			return false
		}
	}
	return true
}
