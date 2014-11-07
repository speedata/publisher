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
	"errors"
)

// Who am I?
type TagType int

const (
	TagCommit TagType = iota
)

type Tag struct {
	Type       TagType
	Name       string
	Message    string
	TargetId   *Oid
	Tagger     *Signature
	repository *Repository
}

// <TAG_CONTENTS>
//     :   "object" <SP> <HEX_OBJ_ID> <LF>
//         "type" <SP> <OBJ_TYPE> <LF>
//         "tag" <SP> <TAG_NAME> <LF>
//         "tagger" <SP> <SAFE_NAME> <SP> <LT> <SAFE_EMAIL> <GT> <SP><GIT_DATE> <LF>
//         <LF>
//         <DATA>
//     ;
func parseTagData(data []byte) (*Tag, error) {
	tag := new(Tag)
	var err error
	if !bytes.HasPrefix(data, []byte("object ")) {
		return nil, errors.New("This is not a Tag object, it doesn't start with 'object '")
	}
	// We know now that we have a tag object. So we can assume the
	// datastructure is fixed (keep fingers crossed!)
	tag.TargetId, err = NewOidFromByteString(data[7:47])
	if err != nil {
		return nil, err
	}
	// 6 = "\ntype "
	pos := 47 + 6
	nlpos := bytes.IndexByte(data[pos:], '\n')
	committype := string(data[pos : pos+nlpos])
	switch committype {
	case "commit":
		tag.Type = TagCommit
	default:
		return nil, errors.New("Unknown Tag type: " + committype)
	}
	// 5 = "\ntag "
	pos += nlpos + 5

	nlpos = bytes.IndexByte(data[pos:], '\n')
	tag.Name = string(data[pos : pos+nlpos])

	// 8 = "\ntagger "
	pos += nlpos + 8
	nlpos = bytes.IndexByte(data[pos:], '\n')
	tag.Tagger, err = newSignatureFromCommitline(data[pos : pos+nlpos])
	if err != nil {
		return nil, err
	}

	pos += nlpos + 2
	tag.Message = string(data[pos:])
	return tag, nil
}

// Find the tag object in the repository.
func (repos *Repository) LookupTag(oid *Oid) (*Tag, error) {
	_, _, data, err := repos.getRawObject(oid)
	if err != nil {
		return nil, err
	}
	tag, err := parseTagData(data)
	if err != nil {
		return nil, err
	}
	tag.repository = repos
	return tag, nil
}
