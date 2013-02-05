// litebrite is a library for generating syntax-highlighted HTML from your
// Go source code.  Use is simple: create a Highlighter, add some CSS styles,
// and pass in some source.
// 
// `h := new(litebrite.Highlighter)`<br>
// `h.CommentClass = "commentz"`<br>
// `h.OperatorClass = "opz"`<br>
// `html := h.Highlight(myCodez)`
// 
// This will return a string of HTML where all comments are surrounded by
// `<div class="commentz">` tags and all operators are surrounded by
// `<div class="opz">` tags.
// 
// The following fields are exposed on `Highlighter` for customizing the
// div tags:
// 
// - `CommentClass`
// - `OperatorClass`
// - `IdentClass`
// - `LiteralClass`
// - `KeywordClass`

// Copyright 2012 Daniel Connelly.  All rights reserved.  Use of
// this source code is governed by a BSD-style license that can be
// found in the `LICENSE` file.

package litebrite

import (
	"bytes"
	"fmt"
	"go/scanner"
	"go/token"
	"html/template"
	"strings"
)

// ## Source tokenizing

// sep represents a split in source code due to a token occurrence.
type sep struct {
	pos int
	tok token.Token
}

// tokenize scans src and emits a sep on every token occurrence.
func tokenize(src string, tc chan *sep) {
	var s scanner.Scanner
	fset := token.NewFileSet() // boilerplate stuff for scanner...
	file := fset.AddFile("", fset.Base(), len(src))
	s.Init(file, []byte(src), nil, 1)
	for {
		filePos, tok, _ := s.Scan()
		tc <- &sep{int(filePos) - file.Base(), tok}
		if tok == token.EOF {
			close(tc)
			break
		}
	}
}

// tokens returns a channel that emits seps from tokenizing src.
func tokens(src string) <-chan *sep {
	tc := make(chan *sep)
	go tokenize(src, tc)
	return tc
}

// trim splits a source chunk into three pieces: the leading whitespace, the
// source code, and the trailing whitespace.
func trim(chunk string) (string, string, string) {
	code := strings.TrimSpace(chunk)
	wsl := chunk[:strings.Index(chunk, code)]
	wsr := chunk[len(wsl)+len(code):]
	return wsl, code, wsr
}

// ## HTML templating

type div struct {
	Code  string
	Class string
}

const ELEM = `{{with .Class}}<div class="{{.}}">{{end}}{{.Code}}{{with .Class}}</div>{{end}}`

var elemT = template.Must(template.New("golang-elem").Parse(ELEM))

// ## Highlighting

// Highlighter contains the CSS class names that are applied to the
// corresponding source code token types and the desired width of tabs.
type Highlighter struct {
	OperatorClass string
	IdentClass    string
	LiteralClass  string
	KeywordClass  string
	CommentClass  string
}

// getClass returns the CSS class name associated with tok.
func (h *Highlighter) getClass(tok token.Token) string {
	switch {
	case tok.IsKeyword():
		return h.KeywordClass
	case tok.IsLiteral():
		if tok == token.IDENT {
			return h.IdentClass
		} else {
			return h.LiteralClass
		}
	case tok.IsOperator():
		return h.OperatorClass
	case tok == token.COMMENT:
		return h.CommentClass
	case tok == token.ILLEGAL:
		break
	default:
		panic(fmt.Sprintf("unknown token type: %v", tok))
	}
	return ""
}

// Highlight returns an HTML fragment containing elements for all Go tokens in
// src.  The elements will be of the form `<div class="TYPE_CLASS">CODE</div>`
// where `TYPE_CLASS` is the CSS class name provided in `h` corresponding to
// the token type of `CODE`.  For instance, if `CODE` is a keyword, then
// `TYPE_CLASS` will be `h.keywordClass`.
func (h *Highlighter) Highlight(src string) string {
	var b bytes.Buffer
	tc := tokens(src)
	prev := <-tc
	for cur := <-tc; cur != nil; prev, cur = cur, <-tc {
		wsl, code, wsr := trim(src[prev.pos:cur.pos])
		b.WriteString(wsl)
		elemT.Execute(&b, &div{code, h.getClass(prev.tok)})
		b.WriteString(wsr)
	}
	return b.String()
}
