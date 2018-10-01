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

var (
	files   map[string]string
	wd      string
	jobname string
)

//export Init
func Init() {
	wd, _ = os.Getwd()
	jobname = os.Getenv("SP_JOBNAME")
}

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

func addFileToList(path string, info os.FileInfo, err error) error {
	if info != nil {
		if !info.IsDir() {
			cmp := filepath.Join(wd, jobname+".pdf")
			if cmp != path {
				files[filepath.Base(path)] = path
			}
		}
	}
	return nil
}

//export BuildFilelist
func BuildFilelist() {
	files = make(map[string]string)

	basepath := os.Getenv("PUBLISHER_BASE_PATH")
	extraDirs := os.Getenv("SD_EXTRA_DIRS")
	filepath.Walk(filepath.Join(basepath), addFileToList)
	if fp := os.Getenv("SP_FONT_PATH"); fp != "" {
		for _, p := range filepath.SplitList(fp) {
			filepath.Walk(p, addFileToList)
		}
	}
	for _, p := range filepath.SplitList(extraDirs) {
		filepath.Walk(p, addFileToList)
	}

	if os.Getenv("SP_IGNORECASE") == "1" {
		newMap := make(map[string]string, len(files))
		for k, v := range files {
			newMap[strings.ToLower(k)] = v
		}
		files = newMap
	}

}

//export LookupFile
func LookupFile(path string) *C.char {
	if ret, ok := files[path]; ok {
		return s2c(ret)
	}
	if _, err := os.Stat(path); err == nil {
		return s2c(path)
	}
	return s2c("")
}

func isFont(filename string) bool {
	lc := strings.ToLower(filename)
	return strings.HasSuffix(lc, ".pfb") || strings.HasSuffix(lc, ".ttf") || strings.HasSuffix(lc, ".otf")
}

//export ListFonts
func ListFonts() **C.char {
	var res []string
	for _, f := range files {
		if isFont(f) {
			res = append(res, f)
		}
	}
	return toCharArray(res)
}

func main() {}
