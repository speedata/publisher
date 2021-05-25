package splibaux

import (
	"fmt"

	"speedatapublisher/css"
)

// ParseHTMLText reads a HTML and a CSS string and returns a table
// to be used for Lua
func ParseHTMLText(htmltext string, csstext string) (string, error) {
	c := css.NewCssParser()
	return c.ParseHTMLFragment(htmltext, csstext)
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
	c := css.NewCssParser()
	str, err := c.Run(string(p))
	if err != nil {
		return "", err
	}
	return str, nil
}
