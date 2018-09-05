package main

import "C"

import (
	"bytes"
	"crypto/md5"
	"encoding/xml"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"unsafe"

	"github.com/gregjones/httpcache"
	"github.com/gregjones/httpcache/diskcache"
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

//export Contains
func Contains(haystack string, needle string) *C.char {
	var ret string
	if strings.Contains(haystack, needle) {
		ret = "true"
	} else {
		ret = "false"
	}
	return C.CString(ret)
}

//export Tokenize
func Tokenize(text, rexpr string) **C.char {
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

//export Replace
func Replace(text string, rexpr string, repl string) *C.char {
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

//export HtmlToXml
func HtmlToXml(input string) *C.char {
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

//export CacheImage
func CacheImage(url string) *C.char {
	outfilename := fmt.Sprintf("%x", md5.Sum([]byte(url)))
	luaimgcache := os.Getenv("IMGCACHE")
	err := os.MkdirAll(luaimgcache, 0755)
	if err != nil {
		return s2c("ERR")
	}
	goimgcache := filepath.Join(luaimgcache, "sp")
	err = os.MkdirAll(goimgcache, 0755)
	if err != nil {
		return s2c("ERR 1")
	}
	outpath := filepath.Join(luaimgcache, outfilename)

	dc := diskcache.New(goimgcache)
	t := httpcache.NewTransport(dc)
	client := t.Client()
	resp, err := client.Get(url)
	if err != nil {
		return s2c("ERR 3")
	}
	if resp.StatusCode == http.StatusNotFound {
		os.Remove(outpath)
		return s2c("404")
	}
	outf, err := os.OpenFile(outpath, os.O_RDWR|os.O_TRUNC|os.O_CREATE, 0644)
	if err != nil {
		return s2c("ERR 2")
	}
	defer outf.Close()

	io.Copy(outf, resp.Body)
	return s2c("OK")
}

func main() {}
