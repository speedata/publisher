// Copyright 2012 The Gorilla Authors, Copyright 2015 Barracuda Networks.
// All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package scanner

// Error token type is returned when there are errors in the parse.
//
// CSS tries to avoid these; these are mostly unclosed strings and other
// things with delimiters.
var Error = Type{0}

// EOF token type is the end of the string.
var EOF = Type{1}

// Ident token type for identifiers.
var Ident = Type{2}

// AtKeyword token type is for things like @import. The .Value has the @
// removed.
var AtKeyword = Type{3}

// String token type is for double- or single-quote delimited strings. The strings
// have been processed to their values and do not contain the quotes.
var String = Type{4}

// Hash token type is for things like colors: #fff. The value does not contain
// the #.
var Hash = Type{5}

// Number token type is for numbers that are not percentages or dimensions.
var Number = Type{6}

// Percentage token type is for percentages. The .Value does not include the %.
var Percentage = Type{7}

// Dimension token type is for dimensions. No further parsing is done on the
// dimension, which may be bad since we could break in into number and unit.
var Dimension = Type{8}

// URI token type is for URIs. The .Value will be the processed URI.
var URI = Type{100}

// Local token type is for local(). The .Value will be the processed URI.
var Local = Type{101}

// UnicodeRange token type is for Unicode ranges.
var UnicodeRange = Type{10}

// CDO token type represents the <!-- string.
var CDO = Type{11}

// CDC token type represents the --> string.
var CDC = Type{12}

// S token type is for whitespace. The original space content will be in .Value.
var S = Type{13}

// Comment token type is for comments. The internals of the comment will be in the
// .Value, with no additional processing.
var Comment = Type{14}

// Function token type refers to a function invocation, like "rgb(". The
// .Value does not have the parenthesis on it.
var Function = Type{15}

// Includes token type refers to ~=.
var Includes = Type{16}

// DashMatch token type refers to |=.
var DashMatch = Type{17}

// PrefixMatch token type refers to ^=.
var PrefixMatch = Type{18}

// SuffixMatch token type refers to $=.
var SuffixMatch = Type{19}

// SubstringMatch token type refers to *=.
var SubstringMatch = Type{20}

// Delim token type refers to a character which CSS does not otherwise know how to
// process as any of the above.
var Delim = Type{21}

// BOM token type refers to Byte Order Marks.
var BOM = Type{22}

// tokenNames maps Type's to their names. Used for conversion to string.
var tokenNames = map[Type]string{
	Error:          "error",
	EOF:            "EOF",
	Ident:          "IDENT",
	AtKeyword:      "ATKEYWORD",
	String:         "STRING",
	Hash:           "HASH",
	Number:         "NUMBER",
	Percentage:     "PERCENTAGE",
	Dimension:      "DIMENSION",
	URI:            "URI",
	Local:          "LOCAL",
	UnicodeRange:   "UNICODE-RANGE",
	CDO:            "CDO",
	CDC:            "CDC",
	S:              "S",
	Comment:        "COMMENT",
	Function:       "FUNCTION",
	Includes:       "INCLUDES",
	DashMatch:      "DASHMATCH",
	PrefixMatch:    "PREFIXMATCH",
	SuffixMatch:    "SUFFIXMATCH",
	SubstringMatch: "SUBSTRINGMATCH",
	Delim:          "DELIM",
	BOM:            "BOM",
}
