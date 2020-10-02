package css

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"

	"github.com/speedata/css/scanner"
)

func parseCSSFile(filename string) (tokenstream, error) {
	if filename == "" {
		return nil, fmt.Errorf("parseCSSFile: no filename given")
	}
	curwd, err := os.Getwd()
	if err != nil {
		return nil, err
	}
	p, err := filepath.Abs(filepath.Dir(filename))
	if err != nil {
		return nil, err
	}
	rel := filepath.Base(filename)
	err = os.Chdir(p)
	if err != nil {
		return nil, err
	}
	defer os.Chdir(curwd)
	tokens, err := parseCSSBody(rel)
	if err != nil {
		return nil, err
	}

	var finalTokens []*scanner.Token

	for i := 0; i < len(tokens); i++ {
		tok := tokens[i]
		if tok.Type == scanner.AtKeyword && tok.Value == "import" {
			i++
			for {
				if tokens[i].Type == scanner.S {
					i++
				} else {
					break
				}
			}
			importvalue := tokens[i]
			toks, err := parseCSSFile(importvalue.Value)
			if err != nil {
				return nil, err
			}
			// if the last token of the imported file is a space, remove it.
			lasttoc := toks[len(toks)-1]
			if lasttoc.Type == scanner.S {
				finalTokens = append(toks[:len(toks)-1], finalTokens...)
			} else {
				finalTokens = append(toks, finalTokens...)
			}
			// hopefully there is no keyword before the semicolon
			for {
				i++
				if i >= len(tokens) {
					break
				}
				if tokens[i].Value == ";" {
					break
				}
			}
		} else {
			finalTokens = append(finalTokens, tok)
		}
	}
	return finalTokens, nil
}

func parseCSSBody(filename string) (tokenstream, error) {
	b, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, err
	}

	var tokens tokenstream

	s := scanner.New(string(b))
	for {
		token := s.Next()
		if token.Type == scanner.EOF || token.Type == scanner.Error {
			break
		}
		switch token.Type {
		case scanner.Comment:
		default:
			tokens = append(tokens, token)
		}
	}
	return tokens, nil
}

func parseCSSString(contents string) tokenstream {
	var tokens tokenstream

	s := scanner.New(contents)
	for {
		token := s.Next()
		if token.Type == scanner.EOF || token.Type == scanner.Error {
			break
		}
		switch token.Type {
		case scanner.Comment:
			// ignore
		default:
			tokens = append(tokens, token)
		}
	}
	return tokens
}
