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
)

type Commit struct {
	Author        *Signature
	Committer     *Signature
	Oid           *Oid // The id of this commit object
	CommitMessage string
	Tree          *Tree
	treeId        *Oid
	parents       []*Oid // sha1 strings
	repository    *Repository
}

// Return the commit message. Same as retrieving CommitMessage directly.
func (ci *Commit) Message() string {
	return ci.CommitMessage
}

// Get the id of the commit.
func (ci *Commit) Id() *Oid {
	return ci.Oid
}

// Return parent number n (0-based index)
func (ci *Commit) Parent(n int) *Commit {
	if n >= len(ci.parents) {
		return nil
	}
	oid := ci.parents[n]
	parent, err := ci.repository.LookupCommit(oid)
	if err != nil {
		return nil
	}
	return parent
}

// Return oid of the parent number n (0-based index). Return nil if no such parent exists.
func (ci *Commit) ParentId(n int) *Oid {
	if n >= len(ci.parents) {
		return nil
	}
	return ci.parents[n]
}

// Return the number of parents of the commit. 0 if this is the
// root commit, otherwise 1,2,...
func (ci *Commit) ParentCount() int {
	return len(ci.parents)
}

// Return oid of the (root) tree of this commit.
func (ci *Commit) TreeId() *Oid {
	return ci.treeId
}

// Parse commit information from the (uncompressed) raw
// data from the commit object.
// \n\n separate headers from message
func parseCommitData(data []byte) (*Commit, error) {
	commit := new(Commit)
	commit.parents = make([]*Oid, 0, 1)
	// we now have the contents of the commit object. Let's investigate...
	nextline := 0
l:
	for {
		eol := bytes.IndexByte(data[nextline:], '\n')
		switch {
		case eol > 0:
			line := data[nextline : nextline+eol]
			spacepos := bytes.IndexByte(line, ' ')
			reftype := line[:spacepos]
			switch string(reftype) {
			case "tree":
				oid, err := NewOidFromString(string(line[spacepos+1:]))
				if err != nil {
					return nil, err
				}
				commit.treeId = oid
			case "parent":
				// A commit can have one or more parents
				oid, err := NewOidFromString(string(line[spacepos+1:]))
				if err != nil {
					return nil, err
				}
				commit.parents = append(commit.parents, oid)
			case "author":
				sig, err := newSignatureFromCommitline(line[spacepos+1:])
				if err != nil {
					return nil, err
				}
				commit.Author = sig
			case "committer":
				sig, err := newSignatureFromCommitline(line[spacepos+1:])
				if err != nil {
					return nil, err
				}
				commit.Committer = sig
			}
			nextline += eol + 1
		case eol == 0:
			commit.CommitMessage = string(data[nextline+1:])
			break l
		default:
			break l
		}
	}
	return commit, nil
}

// Find the commit object in the repository.
func (repos *Repository) LookupCommit(oid *Oid) (*Commit, error) {
	_, _, data, err := repos.getRawObject(oid)
	if err != nil {
		return nil, err
	}
	ci, err := parseCommitData(data)
	if err != nil {
		return nil, err
	}
	ci.repository = repos
	ci.Oid = oid

	_, _, data, err = repos.getRawObject(ci.treeId)
	if err != nil {
		return nil, err
	}
	tree, err := parseTreeData(data)
	tree.Oid = ci.TreeId()
	if err != nil {
		return nil, err
	}
	tree.repository = repos
	ci.Tree = tree
	return ci, nil
}
