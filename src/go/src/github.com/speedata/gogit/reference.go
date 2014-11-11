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
	"errors"
	"io/ioutil"
	"os"
	"path/filepath"
	"regexp"
)

type Reference struct {
	Name       string
	Oid        *Oid
	dest       string
	repository *Repository
}

// not sure if this is needed...
func (ref *Reference) resolveInfo() (*Reference, error) {
	destRef := new(Reference)
	destRef.Name = ref.dest

	destpath := filepath.Join(ref.repository.Path, "info", "refs")
	_, err := os.Stat(destpath)
	if err != nil {
		return nil, err
	}
	infoContents, err := ioutil.ReadFile(destpath)
	if err != nil {
		return nil, err
	}

	r := regexp.MustCompile("([[:xdigit:]]+)\t(.*)\n")
	refs := r.FindAllStringSubmatch(string(infoContents), -1)
	for _, v := range refs {
		if v[2] == ref.dest {
			oid, err := NewOidFromString(v[1])
			if err != nil {
				return nil, err
			}
			destRef.Oid = oid
			return destRef, nil
		}
	}

	return nil, errors.New("Could not resolve info/refs")
}

// A typical Git repository consists of objects (path objects/ in the root directory)
// and of references to HEAD, branches, tags and such.
func (repos *Repository) LookupReference(name string) (*Reference, error) {
	// First we need to find out what's in the text file. It could be something like
	//     ref: refs/heads/master
	// or just a SHA1 such as
	//     1337a1a1b0694887722f8bd0e541bd0f6567a471
	ref := new(Reference)
	ref.repository = repos
	ref.Name = name
	f, err := ioutil.ReadFile(filepath.Join(repos.Path, name))
	if err != nil {
		return nil, err
	}
	rexp := regexp.MustCompile("ref: (.*)\n")
	allMatches := rexp.FindAllStringSubmatch(string(f), 1)
	if allMatches == nil {
		// let's assume this is a SHA1
		oid, err := NewOidFromString(string(f[:40]))
		if err != nil {
			return nil, err
		}
		ref.Oid = oid
		return ref, nil
	}
	// yes, it's "ref: something". Now let's lookup "something"
	ref.dest = allMatches[0][1]
	return repos.LookupReference(ref.dest)
}

// For compatibility with git2go. Return Oid from referece (same as getting .Oid directly)
func (r *Reference) Target() *Oid {
	return r.Oid
}
