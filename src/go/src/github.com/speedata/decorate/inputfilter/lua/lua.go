// Very basic functionality, don't consider this final in any way.

// Syntax highlighting for Lua programs.
package lua

import (
	"bufio"
	"bytes"
	"fmt"
	"github.com/speedata/decorate/processor"
	"regexp"
	"strings"
)

var (
	rComment, rKeyword *regexp.Regexp
)

func init() {
	processor.RegisterInputFilter("lua", Highlight)

	rComment = regexp.MustCompile(`^(--.*?)\n`)
	rKeyword = regexp.MustCompile(`^(function|local)`)
}

func tokenizeLua(data []byte, atEOF bool) (advance int, token []byte, err error) {
	b := rComment.FindSubmatch(data)
	if len(b) > 0 {
		return len(b[1]), b[1], nil
	}
	b = rKeyword.FindSubmatch(data)
	if len(b) > 0 {
		return len(b[1]), b[1], nil
	}

	if false {
		fmt.Println()
	}
	return 1, data[:1], nil
}

func send(out chan processor.Token, major processor.TypeMajor, minor processor.TypeMinor, value string) {
	tok := processor.Token{}
	tok.Major = major
	tok.Minor = minor
	tok.Value = value
	out <- tok
}

func Highlight(data []byte, out chan processor.Token) {
	buf := bytes.NewBuffer(data)
	const (
		RAW = iota
		COMMENT
		STRING
	)
	state := RAW
	scanner := bufio.NewScanner(buf)
	scanner.Split(tokenizeLua)
	for scanner.Scan() {
		text := scanner.Text()
		if strings.HasPrefix(text, `"`) {
			state = STRING
			send(out, processor.MAJOR_STRING, processor.MINOR_RAW, text)
			continue
		}
		if strings.HasPrefix(text, `--`) {
			state = COMMENT
			send(out, processor.MAJOR_COMMENT, processor.MINOR_RAW, text)
			continue
		}
		switch text {
		case "function", "local":
			send(out, processor.MAJOR_KEYWORD, processor.MINOR_RAW, text)
		case "=":
			send(out, processor.MAJOR_OPERATOR, processor.MINOR_RAW, text)
		case " ", "\n":
			switch state {
			case COMMENT:
				send(out, processor.MAJOR_RAW, processor.MINOR_RAW, text)
			default:
				send(out, processor.MAJOR_RAW, processor.MINOR_RAW, text)
			}
			state = RAW
		default:
			switch state {
			case COMMENT:
				send(out, processor.MAJOR_RAW, processor.MINOR_RAW, text)
			default:
				send(out, processor.MAJOR_RAW, processor.MINOR_RAW, text)
			}
			state = RAW
		}
	}
	close(out)
}
