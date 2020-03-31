package css

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"

	"internal/github-css/scanner"
)

func parseCSSFile(filename string) tokenstream {
	curwd, err := os.Getwd()
	if err != nil {
		fmt.Println(err)
		return nil
	}
	p, err := filepath.Abs(filepath.Dir(filename))
	if err != nil {
		fmt.Println(err)
		return nil
	}
	rel := filepath.Base(filename)
	err = os.Chdir(p)
	if err != nil {
		fmt.Println(err)
		return nil
	}
	defer os.Chdir(curwd)
	tokens := parseCSSBody(rel)

	var finalTokens []*scanner.Token

	for i := 0; i < len(tokens); i++ {
		tok := tokens[i]
		if tok.Type == scanner.AtKeyword && tok.Value == "import" {
			importvalue := tokens[i+1]
			toks := parseCSSFile(importvalue.Value)
			finalTokens = append(toks, finalTokens...)
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
	return finalTokens
}

func parseCSSBody(filename string) tokenstream {
	b, err := ioutil.ReadFile(filename)
	if err != nil {
		log.Fatal(err)
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
	return tokens
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
