// Copyright 2012 The Gorilla Authors, Copyright 2015 Barracuda Networks.
// All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/*
Package scanner generates tokens for a CSS2/3 input.

It is a CSS2 scanner with bits of a CSS3 scanner in it.

To use it, create a new scanner for a given CSS string and call Next() until
the token returned has type scanner.EOF or scanner.Error:

	s := scanner.New(myCSS)
	for {
		token := s.Next()
		if token.Type == scanner.TokenEOF || token.Type == scanner.TokenError {
			break
		}
		// Do something with the token...
	}

Following the CSS3 specification, an error can only occur when the scanner
finds an unclosed quote or unclosed comment. In these cases the text becomes
"untokenizable". Everything else is tokenizable and it is up to a parser
to make sense of the token stream (or ignore nonsensical token sequences).

Note: the scanner doesn't perform lexical analysis or, in other words, it
doesn't care about the token context. It is intended to be used by a
lexer or parser.
*/
package scanner
