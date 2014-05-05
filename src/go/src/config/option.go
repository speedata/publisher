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

import "errors"

// AddOption adds a new option and value to the configuration.
//
// If the section is nil then uses the section by default; if it does not exist,
// it is created in advance.
//
// It returns true if the option and value were inserted, and false if the value
// was overwritten.
func (self *Config) AddOption(section string, option string, value string) bool {
	self.AddSection(section) // Make sure section exists

	if section == "" {
		section = _DEFAULT_SECTION
	}

	_, ok := self.data[section][option]

	self.data[section][option] = &tValue{self.lastIdOption[section], value}
	self.lastIdOption[section]++

	return !ok
}

// RemoveOption removes a option and value from the configuration.
// It returns true if the option and value were removed, and false otherwise,
// including if the section did not exist.
func (self *Config) RemoveOption(section string, option string) bool {
	if _, ok := self.data[section]; !ok {
		return false
	}

	_, ok := self.data[section][option]
	delete(self.data[section], option)

	return ok
}

// HasOption checks if the configuration has the given option in the section.
// It returns false if either the option or section do not exist.
func (self *Config) HasOption(section string, option string) bool {
	if _, ok := self.data[section]; !ok {
		return false
	}

	_, okd := self.data[_DEFAULT_SECTION][option]
	_, oknd := self.data[section][option]

	return okd || oknd
}

// Options returns the list of options available in the given section.
// It returns an error if the section does not exist and an empty list if the
// section is empty. Options within the default section are also included.
func (self *Config) Options(section string) (options []string, err error) {
	if _, ok := self.data[section]; !ok {
		return nil, errors.New(sectionError(section).Error())
	}

	options = make([]string, len(self.data[_DEFAULT_SECTION])+len(self.data[section]))
	i := 0
	for s, _ := range self.data[_DEFAULT_SECTION] {
		options[i] = s
		i++
	}
	for s, _ := range self.data[section] {
		options[i] = s
		i++
	}

	return options, nil
}
