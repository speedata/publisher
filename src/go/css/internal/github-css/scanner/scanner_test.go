// Copyright as given in CONTRIBUTORS
// All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package scanner

import (
	"bytes"
	"errors"
	"io/ioutil"
	"reflect"
	"testing"
)

func T(ty Type, v string) Token {
	return Token{ty, v, 0, 0}
}

func parse(input string) ([]Token, error) {
	tokens := []Token{}
	s := New(input)
	for {
		tok := s.Next()
		if tok.Type == Error {
			tok = s.Next()
			if tok.Type != Error {
				panic("Fatal error: got non-error after error")
			}
			return tokens, errors.New("error token")
		}
		if tok.Type == EOF {
			break
		}
		tok.Line = 0
		tok.Column = 0
		tokens = append(tokens, *tok)
	}
	return tokens, nil
}

func TestSuccessfulScan(t *testing.T) {
	for _, test := range []struct {
		input  string
		tokens []Token
	}{
		{"bar(", []Token{T(Function, "bar")}},
		{"abcd", []Token{T(Ident, "abcd")}},
		{`"abcd"`, []Token{T(String, `abcd`)}},
		{"'abcd'", []Token{T(String, "abcd")}},
		{"#name", []Token{T(Hash, "name")}},
		{"4.2", []Token{T(Number, "4.2")}},
		{".42", []Token{T(Number, ".42")}},
		{"42%", []Token{T(Percentage, "42")}},
		{"4.2%", []Token{T(Percentage, "4.2")}},
		{".42%", []Token{T(Percentage, ".42")}},
		{"42px", []Token{T(Dimension, "42px")}},
		{"url('http://www.google.com/')", []Token{T(URI, "http://www.google.com/")}},
		{"U+0042", []Token{T(UnicodeRange, "U+0042")}},
		{"<!--", []Token{T(CDO, "")}},
		{"-->", []Token{T(CDC, "")}},
		{"   \n   \t   \n", []Token{T(S, "   \n   \t   \n")}},
		{"/* foo */", []Token{T(Comment, " foo ")}},
		{"~=", []Token{T(Includes, "")}},
		{"|=", []Token{T(DashMatch, "")}},
		{"^=", []Token{T(PrefixMatch, "")}},
		{"$=", []Token{T(SuffixMatch, "")}},
		{"*=", []Token{T(SubstringMatch, "")}},
		{"{", []Token{T(Delim, "{")}},
		{"@keyword", []Token{T(AtKeyword, "keyword")}},
		{"\uFEFF", []Token{T(BOM, "\uFEFF")}},

		{"42''", []Token{
			T(Number, "42"),
			T(String, ""),
		}},
		{`╯︵┻━┻"stuff"`, []Token{
			T(Ident, "╯︵┻━┻"),
			T(String, "stuff"),
		}},
		{"color:red", []Token{
			T(Ident, "color"),
			T(Delim, ":"),
			T(Ident, "red"),
		}},
		{"color:red;background:blue", []Token{
			T(Ident, "color"),
			T(Delim, ":"),
			T(Ident, "red"),
			T(Delim, ";"),
			T(Ident, "background"),
			T(Delim, ":"),
			T(Ident, "blue"),
		}},
		{"color:rgb(0,1,2)", []Token{
			T(Ident, "color"),
			T(Delim, ":"),
			T(Function, "rgb"),
			T(Number, "0"),
			T(Delim, ","),
			T(Number, "1"),
			T(Delim, ","),
			T(Number, "2"),
			T(Delim, ")"),
		}},
		{"color:#fff", []Token{
			T(Ident, "color"),
			T(Delim, ":"),
			T(Hash, "fff"),
		}},

		// Check note in CSS2 4.3.4:
		// Note that COMMENT tokens cannot occur within other tokens: thus, "url(/*x*/pic.png)" denotes the URI "/*x*/pic.png", not "pic.png".
		{"url(/*x*/pic.png)", []Token{
			T(URI, "/*x*/pic.png"),
		}},

		// More URI testing, since it's important
		{"url(/pic.png)", []Token{
			T(URI, "/pic.png"),
		}},
		{"url( /pic.png )", []Token{
			T(URI, "/pic.png"),
		}},
		{"uRl(/pic.png)", []Token{
			T(URI, "/pic.png"),
		}},
		{"url(\"/pic.png\")", []Token{
			T(URI, "/pic.png"),
		}},
		{"url('/pic.png')", []Token{
			T(URI, "/pic.png"),
		}},
		{"url('/pic.png?badchars=\\(\\'\\\"\\)\\ ')", []Token{
			T(URI, "/pic.png?badchars=('\") "),
		}},
		{"local('pic.png')", []Token{
			T(Local, "pic.png"),
		}},

		// CSS2 section 4.1.1: "red-->" is IDENT "red--" followed by DELIM ">",
		{"red-->", []Token{
			T(Ident, "red--"),
			T(Delim, ">"),
		}},

		{"-moz-border:1", []Token{
			T(Ident, "-moz-border"),
			T(Delim, ":"),
			T(Number, "1"),
		}},

		// CSS2 section 4.1.3, second bullet point: Identifier B&W? may be
		// written in two ways
		{"B\\&W\\?", []Token{
			T(Ident, "B&W?"),
		}},
		{"B\\26 W\\3F", []Token{
			T(Ident, "B&W?"),
		}},
		// CSS2 4.1.3 third bullet point: A backslash by itself is a DELIM.
		{"\\", []Token{
			T(Delim, "\\"),
		}},

		// CSS2 section 4.1.3, last bullet point: identifier test
		// is the same as te\st.
		// commenting out while this fails, so I can commit other tests
		{"test", []Token{T(Ident, "test")}},
		{"te\\st", []Token{T(Ident, "test")}},

		// Coverage:
		{". .", []Token{T(Delim, "."), T(S, " "), T(Delim, ".")}},
		{"# ", []Token{T(Delim, "#"), T(S, " ")}},
		{"@ ", []Token{T(Delim, "@"), T(S, " ")}},
		{"/ ", []Token{T(Delim, "/"), T(S, " ")}},
		{"~ ", []Token{T(Delim, "~"), T(S, " ")}},
		{"url('    ')", []Token{T(URI, "    ")}},
		{"url(\"    \")", []Token{T(URI, "    ")}},
		{"url(     )", []Token{T(URI, "")}},
		{"'\t!'", []Token{T(String, "\t!")}},

		{".bla0 { background: #000; }", []Token{
			T(Delim, "."),
			T(Ident, "bla0"),
			T(S, " "),
			T(Delim, "{"),
			T(S, " "),
			T(Ident, "background"),
			T(Delim, ":"),
			T(S, " "),
			T(Hash, "000"),
			T(Delim, ";"),
			T(S, " "),
			T(Delim, "}"),
		}},

		{"@font-face { font-family: 'FAM'; src: local('LOCAL'), url('URI') format('truetype'); }", []Token{
			T(AtKeyword, "font-face"),
			T(S, " "),
			T(Delim, "{"),
			T(S, " "),
			T(Ident, "font-family"),
			T(Delim, ":"),
			T(S, " "),
			T(String, "FAM"),
			T(Delim, ";"),
			T(S, " "),
			T(Ident, "src"),
			T(Delim, ":"),
			T(S, " "),
			T(Local, "LOCAL"),
			T(Delim, ","),
			T(S, " "),
			T(URI, "URI"),
			T(S, " "),
			T(Function, "format"),
			T(String, "truetype"),
			T(Delim, ")"),
			T(Delim, ";"),
			T(S, " "),
			T(Delim, "}"),
		}},

		{"@font-face { font-family: 'HAPPY-FAMILY'; font-style: normal; font-weight: 400; src: url('/FIND/THIS') format('truetype'); } @font-face { font-family: 'ANOTHER HAPPY FAMILY'; font-style: normal; font-weight: 400; src: url('https://FIND/THAT/') format('truetype'); }", []Token{
			T(AtKeyword, "font-face"),
			T(S, " "),
			T(Delim, "{"),
			T(S, " "),
			T(Ident, "font-family"),
			T(Delim, ":"),
			T(S, " "),
			T(String, "HAPPY-FAMILY"),
			T(Delim, ";"),
			T(S, " "),
			T(Ident, "font-style"),
			T(Delim, ":"),
			T(S, " "),
			T(Ident, "normal"),
			T(Delim, ";"),
			T(S, " "),
			T(Ident, "font-weight"),
			T(Delim, ":"),
			T(S, " "),
			T(Number, "400"),
			T(Delim, ";"),
			T(S, " "),
			T(Ident, "src"),
			T(Delim, ":"),
			T(S, " "),
			T(URI, "/FIND/THIS"),
			T(S, " "),
			T(Function, "format"),
			T(String, "truetype"),
			T(Delim, ")"),
			T(Delim, ";"),
			T(S, " "),
			T(Delim, "}"),
			T(S, " "),
			T(AtKeyword, "font-face"),
			T(S, " "),
			T(Delim, "{"),
			T(S, " "),
			T(Ident, "font-family"),
			T(Delim, ":"),
			T(S, " "),
			T(String, "ANOTHER HAPPY FAMILY"),
			T(Delim, ";"),
			T(S, " "),
			T(Ident, "font-style"),
			T(Delim, ":"),
			T(S, " "),
			T(Ident, "normal"),
			T(Delim, ";"),
			T(S, " "),
			T(Ident, "font-weight"),
			T(Delim, ":"),
			T(S, " "),
			T(Number, "400"),
			T(Delim, ";"),
			T(S, " "),
			T(Ident, "src"),
			T(Delim, ":"),
			T(S, " "),
			T(URI, "https://FIND/THAT/"),
			T(S, " "),
			T(Function, "format"),
			T(String, "truetype"),
			T(Delim, ")"),
			T(Delim, ";"),
			T(S, " "),
			T(Delim, "}"),
		}},

		// Crashers found in fuzz testing:
		{"url(')", []Token{T(URI, "'")}},
	} {
		tokens, err := parse(test.input)
		if err != nil {
			t.Fatalf("For input string %q, unexpected parse error", test.input)
		}
		if !reflect.DeepEqual(tokens, test.tokens) {
			t.Fatalf("For input string %q, bad initial parse. Expected:\n%#v\n\nGot:\n%#v", test.input, test.tokens, tokens)
		}

		// Reconstitute the input, reparse it, and see if it's the same.
		var wr bytes.Buffer
		for _, token := range tokens {
			token.Emit(&wr)
		}
		tokens2, err := parse(wr.String())
		if err != nil {
			t.Fatalf("When parsing reconstituted %q, unexpected error", wr.String())
		}
		if !reflect.DeepEqual(tokens2, test.tokens) {
			t.Fatalf("For input string %q, failed to round trip. Expected:\n%#v\nGot string: %q\nWhich parsed as:\n%#v\n", test.input, test.tokens, wr.String(), tokens2)
		}
	}
}

func TestEncoding(t *testing.T) {
	variants := map[Token]string{
		T(Ident, "bla0"):        `bla0`,
		T(Ident, "_allowed"):    `_allowed`,
		T(Ident, "0forbidden"):  `\30 forbidden`,
		T(Ident, "-1forbidden"): `-\31 forbidden`,
		T(Hash, "cafebabe"):     `#cafebabe`,
		T(Hash, "000"):          `#000`,
		T(Hash, "00a"):          `#00a`,
		T(Hash, "a00"):          `#a00`,
		T(Hash, "773300"):       `#773300`,
	}

	for token, expectation := range variants {
		buf := &bytes.Buffer{}
		token.Emit(buf)

		if buf.String() != expectation {
			t.Errorf("OMG, totally expected %+v to be emitted as '%s', but got ' %s'\n", token, expectation, buf.String())
		}
	}
}

func TestUnbackslash(t *testing.T) {
	for _, test := range []struct {
		isString bool
		in       string
		out      string
	}{
		{false, "", ""},
		{true, "", ""},
		// from CSS2 4.1.3 examples:
		{true, "\\26 B", "&B"},
		{true, "\\000026B", "&B"},
		{true, "\\26G", "&G"},
		{true, "\\2aG", "*G"},
		{true, "\\2AG", "*G"},
		{true, "\\2fG", "/G"},
		{true, "\\2FG", "/G"},
		// standard does not appear to require an even number of digits
		{true, "\\026 B", "&B"},
		{true, "\\026  B", "& B"},
		{true, "\\026", "&"},
		{true, "\\", "\\"},
		{true, "\\{", "{"},

		// Check the special string handling
		{true, "a\\\nb", "ab"},
		{true, "a\\\r\nb", "ab"},
	} {
		result := unbackslash(test.in, test.isString)
		if result != test.out {
			t.Fatalf("Error in TestUnbackslash. In: %q\nOut: %q\nExpected: %q",
				test.in, result, test.out)
		}
	}
}

func TestErrors(t *testing.T) {
	for _, test := range []string{
		"url('http://",
		"moo /* unclosed comment",
	} {
		_, err := parse(test)
		if err == nil {
			t.Fatalf("While parsing %q, unexpected success", test)
		}
	}
}

var errTest = errors.New("error")

func TestCoverage(t *testing.T) {
	if fromHexChar('N') != 0 {
		t.Fatal("Unexpected failure of fromHexChar")
	}
	if unbackslash("\\\r", true) != "\\" {
		t.Fatal("Incorrect unbackslashing for backslash-CR")
	}
	if unbackslash("\\\rx", true) != "x" {
		t.Fatal("Incorrect handling of backslash-CR-(not LF)")
	}
	tok := &Token{Error, "", 0, 0}
	if tok.Emit(ioutil.Discard) == nil {
		t.Fatal("Can emit an error???")
	}
	tok.Type = EOF
	if tok.Emit(ioutil.Discard) == nil {
		t.Fatal("Can emit EOF???")
	}

	err := wr(BadWriter{}, "anything")
	if err != errTest {
		t.Fatal("wr succeeds even with errors")
	}

	if EOF.String() != "EOF" {
		t.Fatal("Unexpected string value of the EOF token")
	}
	if EOF.GoString() != "EOF" {
		t.Fatal("Unexpected string value of the EOF token")
	}
	// Just don't crash
	_ = tok.String()
	tok.Value = "something really long"
	_ = tok.String()
}

type BadWriter struct{}

func (bw BadWriter) Write(b []byte) (n int, err error) {
	return 0, errTest
}
