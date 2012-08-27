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
	"bufio"
	"os"
	"strings"
	"testing"
)

const tmp = "/tmp/__config_test.go__garbage"

func testGet(t *testing.T, c *Config, section string, option string,
	expected interface{}) {
	ok := false
	switch expected.(type) {
	case string:
		v, _ := c.String(section, option)
		if v == expected.(string) {
			ok = true
		}
	case int:
		v, _ := c.Int(section, option)
		if v == expected.(int) {
			ok = true
		}
	case bool:
		v, _ := c.Bool(section, option)
		if v == expected.(bool) {
			ok = true
		}
	default:
		t.Fatalf("Bad test case")
	}
	if !ok {
		t.Errorf("Get failure: expected different value for %s %s", section, option)
	}
}

// Creates configuration representation and run multiple tests in-memory.
func TestInMemory(t *testing.T) {
	c := NewDefault()

	// === Test empty structure

	// should be empty
	if len(c.Sections()) != 1 {
		t.Errorf("Sections failure: invalid length")
	}

	// test presence of missing section
	if c.HasSection("no-section") {
		t.Errorf("HasSection failure: invalid section")
	}

	// get options for missing section
	_, err := c.Options("no-section")
	if err == nil {
		t.Errorf("Options failure: invalid section")
	}

	// test presence of option for missing section
	if c.HasOption("no-section", "no-option") {
		t.Errorf("HasSection failure: invalid/section/option")
	}

	// get value from missing section/option
	_, err = c.String("no-section", "no-option")
	if err == nil {
		t.Errorf("String failure: got value for missing section/option")
	}

	// get value from missing section/option
	_, err = c.Int("no-section", "no-option")
	if err == nil {
		t.Errorf("Int failure: got value for missing section/option")
	}

	// remove missing section
	if c.RemoveSection("no-section") {
		t.Errorf("RemoveSection failure: removed missing section")
	}

	// remove missing section/option
	if c.RemoveOption("no-section", "no-option") {
		t.Errorf("RemoveOption failure: removed missing section/option")
	}

	// === Fill up structure

	// add section
	if !c.AddSection("section1") {
		t.Errorf("AddSection failure: false on first insert")
	}

	// re-add same section
	if c.AddSection("section1") {
		t.Errorf("AddSection failure: true on second insert")
	}

	// default section always exists
	if c.AddSection(_DEFAULT_SECTION) {
		t.Errorf("AddSection failure: true on default section insert")
	}

	// add option/value
	if !c.AddOption("section1", "option1", "value1") {
		t.Errorf("AddOption failure: false on first insert")
	}
	testGet(t, c, "section1", "option1", "value1") // read it back

	// overwrite value
	if c.AddOption("section1", "option1", "value2") {
		t.Errorf("AddOption failure: true on second insert")
	}
	testGet(t, c, "section1", "option1", "value2") // read it back again

	// remove option/value
	if !c.RemoveOption("section1", "option1") {
		t.Errorf("RemoveOption failure: false on first remove")
	}

	// remove again
	if c.RemoveOption("section1", "option1") {
		t.Errorf("RemoveOption failure: true on second remove")
	}

	// read it back again
	_, err = c.String("section1", "option1")
	if err == nil {
		t.Errorf("String failure: got value for removed section/option")
	}

	// remove existing section
	if !c.RemoveSection("section1") {
		t.Errorf("RemoveSection failure: false on first remove")
	}

	// remove again
	if c.RemoveSection("section1") {
		t.Errorf("RemoveSection failure: true on second remove")
	}

	// === Test types

	// add section
	if !c.AddSection("section2") {
		t.Errorf("AddSection failure: false on first insert")
	}

	// add number
	if !c.AddOption("section2", "test-number", "666") {
		t.Errorf("AddOption failure: false on first insert")
	}
	testGet(t, c, "section2", "test-number", 666) // read it back

	// add 'yes' (bool)
	if !c.AddOption("section2", "test-yes", "yes") {
		t.Errorf("AddOption failure: false on first insert")
	}
	testGet(t, c, "section2", "test-yes", true) // read it back

	// add 'false' (bool)
	if !c.AddOption("section2", "test-false", "false") {
		t.Errorf("AddOption failure: false on first insert")
	}
	testGet(t, c, "section2", "test-false", false) // read it back

	// === Test cycle

	c.AddOption(_DEFAULT_SECTION, "opt1", "%(opt2)s")
	c.AddOption(_DEFAULT_SECTION, "opt2", "%(opt1)s")

	_, err = c.String(_DEFAULT_SECTION, "opt1")
	if err == nil {
		t.Errorf("String failure: no error for cycle")
	} else if strings.Index(err.Error(), "cycle") < 0 {
		t.Errorf("String failure: incorrect error for cycle")
	}
}

// Creates a 'tough' configuration file and test (read) parsing.
func TestReadFile(t *testing.T) {
	file, err := os.Create(tmp)
	if err != nil {
		t.Fatal("Test cannot run because cannot write temporary file: " + tmp)
	}

	buf := bufio.NewWriter(file)
	buf.WriteString("[section-1]\n")
	buf.WriteString("  option1=value1 ; This is a comment\n")
	buf.WriteString(" option2 : 2#Not a comment\t#Now this is a comment after a TAB\n")
	buf.WriteString("  # Let me put another comment\n")
	buf.WriteString("    option3= line1\nline2 \n\tline3 # Comment\n")
	buf.WriteString("; Another comment\n")
	buf.WriteString("[" + _DEFAULT_SECTION + "]\n")
	buf.WriteString("variable1=small\n")
	buf.WriteString("variable2=a_part_of_a_%(variable1)s_test\n")
	buf.WriteString("[secTION-2]\n")
	buf.WriteString("IS-flag-TRUE=Yes\n")
	buf.WriteString("[section-1]\n") // continue again [section-1]
	buf.WriteString("option4=this_is_%(variable2)s.\n")
	buf.Flush()
	file.Close()

	c, err := ReadDefault(tmp)
	if err != nil {
		t.Fatalf("ReadDefault failure: %s", err)
	}

	// check number of sections
	if len(c.Sections()) != 3 {
		t.Errorf("Sections failure: wrong number of sections")
	}

	// check number of options 4 of [section-1] plus 2 of [default]
	opts, err := c.Options("section-1")
	if len(opts) != 6 {
		t.Errorf("Options failure: wrong number of options")
	}

	testGet(t, c, "section-1", "option1", "value1")
	testGet(t, c, "section-1", "option2", "2#Not a comment")
	testGet(t, c, "section-1", "option3", "line1\nline2\nline3")
	testGet(t, c, "section-1", "option4", "this_is_a_part_of_a_small_test.")
	testGet(t, c, "secTION-2", "IS-flag-TRUE", true) // case-sensitive
}

// Tests writing and reading back a configuration file.
func TestWriteReadFile(t *testing.T) {
	cw := NewDefault()

	// write file; will test only read later on
	cw.AddSection("First-Section")
	cw.AddOption("First-Section", "option1", "value option1")
	cw.AddOption("First-Section", "option2", "2")

	cw.AddOption("", "host", "www.example.com")
	cw.AddOption(_DEFAULT_SECTION, "protocol", "https://")
	cw.AddOption(_DEFAULT_SECTION, "base-url", "%(protocol)s%(host)s")

	cw.AddOption("Another-Section", "useHTTPS", "y")
	cw.AddOption("Another-Section", "url", "%(base-url)s/some/path")

	cw.WriteFile(tmp, 0644, "Test file for test-case")

	// read back file and test
	cr, err := ReadDefault(tmp)
	if err != nil {
		t.Fatalf("ReadDefault failure: %s", err)
	}

	testGet(t, cr, "First-Section", "option1", "value option1")
	testGet(t, cr, "First-Section", "option2", 2)
	testGet(t, cr, "Another-Section", "useHTTPS", true)
	testGet(t, cr, "Another-Section", "url", "https://www.example.com/some/path")

	defer os.Remove(tmp)
}
