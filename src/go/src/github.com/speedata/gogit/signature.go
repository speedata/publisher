// Copyright (c) 2013 Patrick Gundlach, speedata (Berlin, Germany)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

package gogit

import (
	"bytes"
	"strconv"
	"time"
)

// Author and Committer information
type Signature struct {
	Email string
	Name  string
	When  time.Time
}

// Helper to get a signature from the commit line, which looks like this:
//     author Patrick Gundlach <gundlach@speedata.de> 1378823654 +0200
// but without the "author " at the beginning (this method should)
// be used for author and committer.
//
// FIXME: include timezone!
func newSignatureFromCommitline(line []byte) (*Signature, error) {
	sig := new(Signature)
	emailstart := bytes.IndexByte(line, '<')
	sig.Name = string(line[:emailstart-1])
	emailstop := bytes.IndexByte(line, '>')
	sig.Email = string(line[emailstart+1 : emailstop])
	timestop := bytes.IndexByte(line[emailstop+2:], ' ')
	timestring := string(line[emailstop+2 : emailstop+2+timestop])
	seconds, err := strconv.ParseInt(timestring, 10, 64)
	if err != nil {
		return nil, err
	}
	sig.When = time.Unix(seconds, 0)
	return sig, nil
}
