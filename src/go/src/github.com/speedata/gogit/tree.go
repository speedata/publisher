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
	"path"
)

// A tree is a flat directory listing.
type Tree struct {
	TreeEntries []*TreeEntry
	Oid         *Oid
	repository  *Repository
}

// A tree entry is similar to a directory entry (file name, type) in a real file system.
type TreeEntry struct {
	Filemode int
	Name     string
	Id       *Oid
	Type     ObjectType
}

// There are only a few file modes in Git. They look like unix file modes, but they can only be
// one of these.
const (
	FileModeBlob     = 0100644
	FileModeBlobExec = 0100755
	FileModeSymlink  = 0120000
	FileModeCommit   = 0160000
	FileModeTree     = 0040000
)

// Parse tree information from the (uncompressed) raw
// data from the tree object.
func parseTreeData(data []byte) (*Tree, error) {
	tree := new(Tree)
	tree.TreeEntries = make([]*TreeEntry, 0, 10)
	l := len(data)
	pos := 0
	for pos < l {
		te := new(TreeEntry)
		spacepos := bytes.IndexByte(data[pos:], ' ')
		switch string(data[pos : pos+spacepos]) {
		case "100644":
			te.Filemode = FileModeBlob
			te.Type = ObjectBlob
		case "100755":
			te.Filemode = FileModeBlobExec
			te.Type = ObjectBlob
		case "120000":
			te.Filemode = FileModeSymlink
			te.Type = ObjectBlob
		case "160000":
			te.Filemode = FileModeCommit
			te.Type = ObjectCommit
		case "40000":
			te.Filemode = FileModeTree
			te.Type = ObjectTree
		default:
			return nil, errors.New("unknown type: " + string(data[pos:pos+spacepos]))
		}
		pos += spacepos + 1
		zero := bytes.IndexByte(data[pos:], 0)
		te.Name = string(data[pos : pos+zero])
		pos += zero + 1
		oid, err := NewOid(data[pos : pos+20])
		if err != nil {
			return nil, err
		}
		te.Id = oid
		pos = pos + 20
		tree.TreeEntries = append(tree.TreeEntries, te)
	}
	return tree, nil
}

// Find the entry in this directory (tree) with the given name.
func (t *Tree) EntryByName(name string) *TreeEntry {
	for _, v := range t.TreeEntries {
		if v.Name == name {
			return v
		}
	}
	return nil
}

// Get the n-th entry of this tree (0 = first entry). You can also access
// t.TreeEntries[index] directly.
func (t *Tree) EntryByIndex(index int) *TreeEntry {
	if index >= len(t.TreeEntries) {
		return nil
	}
	return t.TreeEntries[index]
}

// Get the number of entries in the directory (tree). Same as
// len(t.TreeEntries).
func (t *Tree) EntryCount() int {
	return len(t.TreeEntries)
}

type TreeWalkCallback func(string, *TreeEntry) int

// The entries will be traversed in the specified order,
// children subtrees will be automatically loaded as required, and the
// callback will be called once per entry with the current (relative) root
// for the entry and the entry data itself.
//
// If the callback returns a positive value, the passed entry will be skipped
// on the traversal (in pre mode). A negative value stops the walk.
//
// Walk will panic() if an error occurs
func (t *Tree) Walk(callback TreeWalkCallback) error {
	t._walk(callback, "")
	return nil
}

func (t *Tree) _walk(cb TreeWalkCallback, dirname string) bool {
	for _, te := range t.TreeEntries {
		cont := cb(dirname, te)
		switch {
		case cont < 0:
			return false
		case cont == 0:
			// descend if it is a tree
			if te.Type == ObjectTree {
				t, err := t.repository.LookupTree(te.Id)
				if err != nil {
					panic(err)
				}
				if t._walk(cb, path.Join(dirname, te.Name)) == false {
					return false
				}
			}
		case cont > 0:
			// do nothing, don't descend into the tree
		}
	}
	return true
}

// Find the tree object in the repository.
func (repos *Repository) LookupTree(oid *Oid) (*Tree, error) {
	_, _, data, err := repos.getRawObject(oid)
	if err != nil {
		return nil, err
	}
	tree, err := parseTreeData(data)
	if err != nil {
		return nil, err
	}
	tree.Oid = oid
	tree.repository = repos
	return tree, nil
}
