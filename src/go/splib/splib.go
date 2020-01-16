package main

import "C"

import (
	"bytes"
	"encoding/xml"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"unsafe"

	"splibaux"
)

var (
	errorpattern = `**err`
)

// Convert a string slice to a C char* array and add a NULL pointer.
func toCharArray(s []string) **C.char {
	cArray := C.malloc(C.size_t(len(s)+1) * C.size_t(unsafe.Sizeof(uintptr(0))))
	a := (*[1<<29 - 1]*C.char)(cArray)
	for idx, substring := range s {
		a[idx] = C.CString(substring)
	}
	// add sentinel
	a[len(s)] = nil
	return (**C.char)(cArray)
}

func s2c(input string) *C.char {
	return C.CString(input)
}

//export contains
func contains(haystack string, needle string) *C.char {
	var ret string
	if strings.Contains(haystack, needle) {
		ret = "true"
	} else {
		ret = "false"
	}
	return C.CString(ret)
}

//export tokenize
func tokenize(text, rexpr string) **C.char {
	r := regexp.MustCompile(rexpr)
	idx := r.FindAllStringIndex(text, -1)
	pos := 0
	var res []string
	for _, v := range idx {
		res = append(res, text[pos:v[0]])
		pos = v[1]
	}
	res = append(res, text[pos:])
	return toCharArray(res)
}

//export replace
func replace(text string, rexpr string, repl string) *C.char {
	r := regexp.MustCompile(rexpr)

	// xpath uses $12 for $12 or $1, depending on the existence of $12 or $1.
	// go on the other hand uses $12 for $12 and never for $1, so you have to write
	// $1 as ${1} if there is text after the $1.
	// We escape the $n backwards to prevent expansion of $12 to ${1}2
	for i := r.NumSubexp(); i > 0; i-- {
		// first create rexepx that match "$i"
		x := fmt.Sprintf(`\$(%d)`, i)
		nummatcher := regexp.MustCompile(x)
		repl = nummatcher.ReplaceAllString(repl, fmt.Sprintf(`$${%d}`, i))
	}
	str := r.ReplaceAllString(text, repl)
	return C.CString(str)
}

//export htmlToXml
func htmlToXml(input string) *C.char {
	input = "<toplevel·toplevel>" + input + "</toplevel·toplevel>"
	r := strings.NewReader(input)
	var w bytes.Buffer

	enc := xml.NewEncoder(&w)
	dec := xml.NewDecoder(r)

	dec.Strict = false
	dec.AutoClose = xml.HTMLAutoClose
	for {
		t, err := dec.Token()
		if err == io.EOF {
			break
		}
		if err != nil {
			enc.Flush()
			return nil
		}
		switch v := t.(type) {
		case xml.StartElement:
			if v.Name.Local != "toplevel·toplevel" {
				enc.EncodeToken(t)
			}
		case xml.EndElement:
			if v.Name.Local != "toplevel·toplevel" {
				enc.EncodeToken(t)
			}
		case xml.CharData:
			enc.EncodeToken(t)
		default:
			// fmt.Println(v)
		}
	}
	enc.Flush()
	return C.CString(w.String())
}

//export buildFilelist
func buildFilelist() {
	paths := filepath.SplitList(os.Getenv("PUBLISHER_BASE_PATH"))
	if fp := os.Getenv("SP_FONT_PATH"); fp != "" {
		for _, p := range filepath.SplitList(fp) {
			paths = append(paths, p)
		}
	}
	for _, p := range filepath.SplitList(os.Getenv("SD_EXTRA_DIRS")) {
		paths = append(paths, p)
	}

	splibaux.BuildFilelist(paths)
}

//export addDir
func addDir(p string) {
	splibaux.AddDir(p)
}

//export lookupFile
func lookupFile(path string) *C.char {
	ret, err := splibaux.GetFullPath(path)
	if err != nil {
		return s2c(errorpattern + err.Error())
	}
	return s2c(ret)
}

//export listFonts
func listFonts() **C.char {
	res := splibaux.ListFonts()
	return toCharArray(res)
}

//export convertContents
func convertContents(contents, handler string) *C.char {
	ret, err := splibaux.ConvertContents(contents, handler)
	if err != nil {
		return s2c(errorpattern + err.Error())
	}
	return s2c(ret)
}

//export convertImage
func convertImage(filename, handler string) *C.char {
	ret, err := splibaux.ConvertImage(filename, handler)
	if err != nil {
		return s2c(errorpattern + err.Error())
	}
	return s2c(ret)
}

//export convertSVGImage
func convertSVGImage(path string) *C.char {
	ret, err := splibaux.ConvertSVGImage(path)
	if err != nil {
		return s2c(errorpattern + err.Error())
	}
	return s2c(ret)
}

func main() {}
