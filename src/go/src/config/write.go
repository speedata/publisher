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
	"fmt"
	"os"
	"strings"
)

// WriteFile saves the configuration representation to a file.
// The desired file permissions must be passed as in os.Open. The header is a
// string that is saved as a comment in the first line of the file.
func (self *Config) WriteFile(fname string, perm os.FileMode, header string) error {
	file, err := os.OpenFile(fname, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, perm)
	if err != nil {
		return err
	}

	buf := bufio.NewWriter(file)
	if err = self.write(buf, header); err != nil {
		return err
	}
	buf.Flush()

	return file.Close()
}

func (self *Config) write(buf *bufio.Writer, header string) (err error) {
	if header != "" {
		// Add comment character after of each new line.
		if i := strings.Index(header, "\n"); i != -1 {
			header = strings.Replace(header, "\n", "\n"+self.comment, -1)
		}

		if _, err = buf.WriteString(self.comment + header + "\n"); err != nil {
			return err
		}
	}

	for _, orderedSection := range self.Sections() {
		for section, sectionMap := range self.data {
			if section == orderedSection {

				// Skip default section if empty.
				if section == _DEFAULT_SECTION && len(sectionMap) == 0 {
					continue
				}

				if _, err = buf.WriteString("\n[" + section + "]\n"); err != nil {
					return err
				}

				// Follow the input order in options.
				for i := 0; i < self.lastIdOption[section]; i++ {
					for option, tValue := range sectionMap {

						if tValue.position == i {
							if _, err = buf.WriteString(fmt.Sprint(
								option, self.separator, tValue.v, "\n")); err != nil {
								return err
							}
							self.RemoveOption(section, option)
							break
						}
					}
				}
			}
		}
	}

	if _, err = buf.WriteString("\n"); err != nil {
		return err
	}

	return nil
}
