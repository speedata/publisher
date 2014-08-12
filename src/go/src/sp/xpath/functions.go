package xpath

import (
	"regexp"
)

// tokenize() xpath function
func Tokenize(text []byte, rexpr string) []string {
	r, err := regexp.Compile(rexpr)
	if err != nil {
		return nil
	}
	idx := r.FindAllIndex(text, -1)
	pos := 0
	var res []string
	for _, v := range idx {
		res = append(res, string(text[pos:v[0]]))
		pos = v[1]
	}
	res = append(res, string(text[pos:]))
	return res
}
