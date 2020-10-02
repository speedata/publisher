package splibaux

import (
	"fmt"

	"css"
)

// ParseHTMLText reads a HTML and a CSS string and returns a table
// to be used for Lua
func ParseHTMLText(htmltext string, csstext string) (string, error) {
	return css.ParseHTMLFragment(htmltext, csstext)
}

// ParseHTML reads a file and returns a table to be used for Lua
func ParseHTML(filename string) (string, error) {
	p, err := GetFullPath(filename)
	if err != nil {
		return "", err
	}
	if p == "" {
		return "", fmt.Errorf("File not found: %q", filename)
	}

	str, err := css.Run([]string{p})
	if err != nil {
		return "", err
	}
	return str, nil
}
