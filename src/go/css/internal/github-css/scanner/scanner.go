// Copyright as given in CONTRIBUTORS
// All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package scanner

import (
	"regexp"
	"strings"
	"unicode"
	"unicode/utf8"
)

var macroRegexp = regexp.MustCompile(`\{[a-z]+\}`)

// macros maps macro names to patterns to be expanded.
var macros = map[string]string{
	// must be escaped: `\.+*?()|[]{}^$`
	"ident":      `-?{nmstart}{nmchar}*`,
	"name":       `{nmchar}+`,
	"nmstart":    `[a-zA-Z_]|{nonascii}|{escape}`,
	"nonascii":   "[\u0080-\uD7FF\uE000-\uFFFD\U00010000-\U0010FFFF]",
	"unicode":    `\\[0-9a-fA-F]{1,6}{wc}?`,
	"escape":     "{unicode}|\\\\[\u0020-\u007E\u0080-\uD7FF\uE000-\uFFFD\U00010000-\U0010FFFF]",
	"nmchar":     `[a-zA-Z0-9_-]|{nonascii}|{escape}`,
	"num":        `[0-9]*\.[0-9]+|[0-9]+`,
	"string":     `"(?:{stringchar}|')*?"|'(?:{stringchar}|")*?'`,
	"stringchar": `{urlchar}|[ ]|\\{nl}`,
	"urlchar":    "[\u0009\u0021\u0023-\u0026\u0027-\u007E]|{nonascii}|{escape}",
	"nl":         `[\n\r\f]|\r\n`,
	"w":          `{wc}*`,
	"wc":         `[\t\n\f\r ]`,
}

// productions maps the list of tokens to patterns to be expanded.
var productions = map[Type]string{
	// Unused regexps (matched using other methods) are commented out.
	Ident:        `{ident}`,
	AtKeyword:    `@{ident}`,
	String:       `{string}`,
	Hash:         `#{name}`,
	Number:       `{num}`,
	Percentage:   `{num}%`,
	Dimension:    `{num}{ident}`,
	URI:          `[Uu][Rr][Ll]\({w}(?:{string}|{urlchar}*){w}\)`,
	Local:        `[Ll][Oo][Cc][Aa][Ll]\({w}(?:{string}|{urlchar}*){w}\)`,
	UnicodeRange: `[Uu]\+[0-9A-F\?]{1,6}(?:-[0-9A-F]{1,6})?`,
	//CDO:            `<!--`,
	CDC:      `-->`,
	S:        `{wc}+`,
	Comment:  `/\*[^\*]*[\*]+(?:[^/][^\*]*[\*]+)*/`,
	Function: `{ident}\(`,
	//BOM:            "\uFEFF",
}

// matchers maps the list of tokens to compiled regular expressions.
//
// The map is filled on init() using the macros and productions defined in
// the CSS specification.
var matchers = map[Type]*regexp.Regexp{}

// matchOrder is the order to test regexps when first-char shortcuts
// can't be used.
var matchOrder = []Type{
	URI,
	Local,
	Function,
	UnicodeRange,
	Ident,
	Dimension,
	Percentage,
	Number,
	CDC,
}

func init() {
	// replace macros and compile regexps for productions.
	replaceMacro := func(s string) string {
		return "(?:" + macros[s[1:len(s)-1]] + ")"
	}
	for t, s := range productions {
		for macroRegexp.MatchString(s) {
			s = macroRegexp.ReplaceAllStringFunc(s, replaceMacro)
		}
		matchers[t] = regexp.MustCompile("^(?:" + s + ")")
	}
}

// New returns a new CSS scanner for the given input.
func New(input string) *Scanner {
	// Normalize newlines.
	// FIXME: This is unnecessary resource consumption.
	input = strings.Replace(input, "\r\n", "\n", -1)
	return &Scanner{
		input: input,
		row:   1,
		col:   1,
	}
}

// Scanner scans an input and emits tokens following the CSS3 specification.
type Scanner struct {
	input string
	pos   int
	row   int
	col   int
	err   *Token
}

// Next returns the next token from the input.
//
// At the end of the input the token type is EOF.
//
// If the input can't be tokenized the token type is Error. This occurs
// in case of unclosed quotation marks or comments.
func (s *Scanner) Next() *Token {
	if s.err != nil {
		return s.err
	}
	if s.pos >= len(s.input) {
		s.err = &Token{EOF, "", s.row, s.col}
		return s.err
	}
	if s.pos == 0 {
		// Test BOM only once, at the beginning of the file.
		if strings.HasPrefix(s.input, "\uFEFF") {
			return s.emitSimple(BOM, "\uFEFF")
		}
	}
	// There's a lot we can guess based on the first byte so we'll take a
	// shortcut before testing multiple regexps.
	input := s.input[s.pos:]
	switch input[0] {
	case '\t', '\n', '\f', '\r', ' ':
		// Whitespace.
		return s.emitToken(S, matchers[S].FindString(input))
	case '.':
		// Dot is too common to not have a quick check.
		// We'll test if this is a Char; if it is followed by a number it is a
		// dimension/percentage/number, and this will be matched later.
		if len(input) > 1 && !unicode.IsDigit(rune(input[1])) {
			return s.emitSimple(Delim, ".")
		}
	case '#':
		// Another common one: Hash or Char.
		if match := matchers[Hash].FindString(input); match != "" {
			return s.emitToken(Hash, match)
		}
		return s.emitSimple(Delim, "#")
	case '@':
		// Another common one: AtKeyword or Char.
		if match := matchers[AtKeyword].FindString(input); match != "" {
			return s.emitSimple(AtKeyword, match)
		}
		return s.emitSimple(Delim, "@")
	case ':', ',', ';', '%', '&', '+', '=', '>', '(', ')', '[', ']', '{', '}':
		// More common chars.
		return s.emitSimple(Delim, string(input[0]))
	case '"', '\'':
		// String or error.
		match := matchers[String].FindString(input)
		if match != "" {
			return s.emitToken(String, match)
		}
		s.err = &Token{Error, "unclosed quotation mark", s.row, s.col}
		return s.err
	case '/':
		// Comment, error or Char.
		if len(input) > 1 && input[1] == '*' {
			match := matchers[Comment].FindString(input)
			if match != "" {
				return s.emitToken(Comment, match)
			}
			s.err = &Token{Error, "unclosed comment", s.row, s.col}
			return s.err
		}
		return s.emitSimple(Delim, "/")
	case '~':
		// Includes or Char.
		return s.emitPrefixOrChar(Includes, "~=")
	case '|':
		// DashMatch or Char.
		return s.emitPrefixOrChar(DashMatch, "|=")
	case '^':
		// PrefixMatch or Char.
		return s.emitPrefixOrChar(PrefixMatch, "^=")
	case '$':
		// SuffixMatch or Char.
		return s.emitPrefixOrChar(SuffixMatch, "$=")
	case '*':
		// SubstringMatch or Char.
		return s.emitPrefixOrChar(SubstringMatch, "*=")
	case '<':
		// CDO or Char.
		return s.emitPrefixOrChar(CDO, "<!--")
	}
	// Test all regexps, in order.
	for _, token := range matchOrder {
		if match := matchers[token].FindString(input); match != "" {
			return s.emitToken(token, match)
		}
	}
	// We already handled unclosed quotation marks and comments,
	// so this can only be a Char.
	r, width := utf8.DecodeRuneInString(input)
	token := &Token{Delim, string(r), s.row, s.col}
	s.col += width
	s.pos += width
	return token
}

// updatePosition updates input coordinates based on the consumed text.
func (s *Scanner) updatePosition(text string) {
	width := utf8.RuneCountInString(text)
	lines := strings.Count(text, "\n")
	s.row += lines
	if lines == 0 {
		s.col += width
	} else {
		s.col = utf8.RuneCountInString(text[strings.LastIndex(text, "\n"):])
	}
	s.pos += len(text) // while col is a rune index, pos is a byte index
}

// emitToken returns a Token for the string v and updates the scanner position.
func (s *Scanner) emitToken(t Type, v string) *Token {
	token := &Token{t, v, s.row, s.col}
	s.updatePosition(v)
	token.normalize()
	return token
}

// emitSimple returns a Token for the string v and updates the scanner
// position in a simplified manner.
//
// The string is known to have only ASCII characters and to not have a newline.
func (s *Scanner) emitSimple(t Type, v string) *Token {
	token := &Token{t, v, s.row, s.col}
	s.col += len(v)
	s.pos += len(v)
	token.normalize()
	return token
}

// emitPrefixOrChar returns a Token for type t if the current position
// matches the given prefix. Otherwise it returns a Char token using the
// first character from the prefix.
//
// The prefix is known to have only ASCII characters and to not have a newline.
func (s *Scanner) emitPrefixOrChar(t Type, prefix string) *Token {
	if strings.HasPrefix(s.input[s.pos:], prefix) {
		return s.emitSimple(t, prefix)
	}
	return s.emitSimple(Delim, string(prefix[0]))
}
