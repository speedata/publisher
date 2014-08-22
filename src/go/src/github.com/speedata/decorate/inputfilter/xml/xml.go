// Basic functionality, don't consider this final in any way.

// Syntax highlighting for XML files.
package xml

import (
	"bufio"
	"bytes"
	"github.com/speedata/decorate/processor"
	"strings"
	"unicode"
	"unicode/utf8"
)

func init() {
	processor.RegisterInputFilter("xml", Highlight)
}

func nameboundary(r rune) bool {
	return unicode.IsSpace(r) || r == '=' || r == '/'
}

func tokenizeXML(data []byte, atEOF bool) (advance int, token []byte, err error) {
	var tcomment = []byte{'<', '!', '-', '-'}
	if bytes.HasPrefix(data, tcomment) {
		return len(tcomment), tcomment, nil
	}
	r, size := utf8.DecodeRune(data)
	if unicode.IsSpace(r) {
		return size, data[:size], nil
	}
	if data[0] == '<' || data[0] == '>' {
		return 1, data[:1], nil
	}
	if data[0] == '/' && data[1] == '>' {
		return 2, data[:2], nil
	}
	num := bytes.IndexFunc(data, nameboundary)
	if num > 0 {
		return num, data[:num], nil
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
		TAGSTART
		TAG
	)
	state := RAW
	scanner := bufio.NewScanner(buf)
	scanner.Split(tokenizeXML)
	for scanner.Scan() {
		text := scanner.Text()
		if strings.HasPrefix(text, `"`) {
			state = STRING
			send(out, processor.MAJOR_STRING, processor.MINOR_RAW, text)
			continue
		}
		switch text {
		case "<!--":
			send(out, processor.MAJOR_COMMENT, processor.MINOR_RAW, text)
			state = COMMENT
		case "-->":
			send(out, processor.MAJOR_COMMENT, processor.MINOR_RAW, text)
			state = RAW
		case "<":
			send(out, processor.MAJOR_NAME, processor.MINOR_NAME_TAG, text)
			state = TAGSTART
		case " ", "\n":
			switch state {
			case COMMENT:
				send(out, processor.MAJOR_COMMENT, processor.MINOR_RAW, text)
			case TAGSTART:
				send(out, processor.MAJOR_RAW, processor.MINOR_RAW, text)
				state = TAG
			default:
				send(out, processor.MAJOR_RAW, processor.MINOR_RAW, text)
			}
		default:
			switch state {
			case COMMENT:
				send(out, processor.MAJOR_COMMENT, processor.MINOR_RAW, text)
			case TAGSTART:
				send(out, processor.MAJOR_NAME, processor.MINOR_NAME_TAG, text)
			case TAG:
				send(out, processor.MAJOR_NAME, processor.MINOR_NAME_ATTRIBUTE, text)
			default:
				send(out, processor.MAJOR_RAW, processor.MINOR_RAW, text)
			}
		}
	}
	close(out)
}
