// Copyright 2009  The "goconfig" Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package config

import (
	"regexp"
	"strings"
)

const (
	// Default section name.
	_DEFAULT_SECTION = "DEFAULT"
	// Maximum allowed depth when recursively substituing variable names.
	_DEPTH_VALUES = 200

	DEFAULT_COMMENT       = "# "
	ALTERNATIVE_COMMENT   = "; "
	DEFAULT_SEPARATOR     = ":"
	ALTERNATIVE_SEPARATOR = "="
)

var (
	// Strings accepted as boolean.
	boolString = map[string]bool{
		"t":     true,
		"true":  true,
		"y":     true,
		"yes":   true,
		"on":    true,
		"1":     true,
		"f":     false,
		"false": false,
		"n":     false,
		"no":    false,
		"off":   false,
		"0":     false,
	}

	varRegExp = regexp.MustCompile(`%\(([a-zA-Z0-9_.\-]+)\)s`) // %(variable)s
)

// Config is the representation of configuration settings.
type Config struct {
	comment   string
	separator string

	// === Sections order
	lastIdSection int            // Last section identifier
	idSection     map[string]int // Section : position

	// The last option identifier used for each section.
	lastIdOption map[string]int // Section : last identifier

	// Section -> option : value
	data map[string]map[string]*tValue
}

// Hold the input position for a value.
type tValue struct {
	position int    // Option order
	v        string // value
}

// New creates an empty configuration representation.
// This representation can be filled with AddSection and AddOption and then
// saved to a file using WriteFile.
// 
// === Arguments
// 
// comment: has to be `DEFAULT_COMMENT` or `ALTERNATIVE_COMMENT`
// separator: has to be `DEFAULT_SEPARATOR` or `ALTERNATIVE_SEPARATOR`
// preSpace: indicate if is inserted a space before of the separator
// postSpace: indicate if is added a space after of the separator
func New(comment, separator string, preSpace, postSpace bool) *Config {
	if comment != DEFAULT_COMMENT && comment != ALTERNATIVE_COMMENT {
		panic("comment character not valid")
	}

	if separator != DEFAULT_SEPARATOR && separator != ALTERNATIVE_SEPARATOR {
		panic("separator character not valid")
	}

	// === Get spaces around separator
	if preSpace {
		separator = " " + separator
	}

	if postSpace {
		separator += " "
	}
	// ===

	c := new(Config)

	c.comment = comment
	c.separator = separator
	c.idSection = make(map[string]int)
	c.lastIdOption = make(map[string]int)
	c.data = make(map[string]map[string]*tValue)

	c.AddSection(_DEFAULT_SECTION) // Default section always exists.

	return c
}

// NewDefault creates a configuration representation with values by default.
func NewDefault() *Config {
	return New(DEFAULT_COMMENT, DEFAULT_SEPARATOR, false, true)
}

// === Utility
// ===

func stripComments(l string) string {
	// Comments are preceded by space or TAB
	for _, c := range []string{" ;", "\t;", " #", "\t#"} {
		if i := strings.Index(l, c); i != -1 {
			l = l[0:i]
		}
	}
	return l
}
