package main

/*

struct splitvalues {
	char** splitted;
	int* directions;
	int count;
	int direction;
};

*/
import "C"

import (
	"bytes"
	"encoding/xml"
	"fmt"
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"unsafe"

	"speedatapublisher/splibaux"

	"golang.org/x/text/unicode/bidi"
)

var (
	errorpattern     = `**err`
	protocolFilename string
	verbosity        = 0
)

func init() {
	protocolFilename = os.Getenv("SP_JOBNAME") + "-protocol.xml"
	verbosity, _ = strconv.Atoi(os.Getenv("SP_VERBOSITY"))
	loglevel.Set(slog.LevelInfo)
	err := setupLog(protocolFilename)
	if err != nil {
		panic(err)
	}
}

func s2c(input string) *C.char {
	return C.CString(input)
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

//export sdParseHTMLText
func sdParseHTMLText(htmltextC *C.char, csstextC *C.char) *C.char {
	htmltext := C.GoString(htmltextC)
	csstext := C.GoString(csstextC)
	str, err := splibaux.ParseHTMLText(htmltext, csstext)
	if err != nil {
		return s2c(errorpattern + err.Error())
	}
	return C.CString(str)
}

//export sdParseHTML
func sdParseHTML(filenameC *C.char) *C.char {
	filename := C.GoString(filenameC)
	str, err := splibaux.ParseHTML(filename)
	if err != nil {
		return s2c(errorpattern + err.Error())
	}
	return C.CString(str)
}

//export sdContains
func sdContains(haystackC *C.char, needleC *C.char) *C.char {
	haystack := C.GoString(haystackC)
	needle := C.GoString(needleC)
	var ret string
	if strings.Contains(haystack, needle) {
		ret = "true"
	} else {
		ret = "false"
	}
	return C.CString(ret)
}

//export sdMatches
func sdMatches(textC, rexprC, flags *C.char) int {
	text := C.GoString(textC)
	reString := C.GoString(rexprC)
	re, err := regexp.Compile(reString)
	if err != nil {
		return 0
	}
	r := re.MatchString(text)
	if r {
		return 1
	}
	return 0
}

//export sdTokenize
func sdTokenize(textC, rexprC *C.char) **C.char {
	text := C.GoString(textC)
	rexpr := C.GoString(rexprC)

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

//export sdReplace
func sdReplace(textC, rexprC, replC *C.char) *C.char {
	text := C.GoString(textC)
	rexpr := C.GoString(rexprC)
	repl := C.GoString(replC)

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

//export sdHtmlToXml
func sdHtmlToXml(inputC *C.char) *C.char {
	input := C.GoString(inputC)
	input = "<toplevel·toplevel>" + input + "</toplevel·toplevel>"
	r := strings.NewReader(input)
	var w bytes.Buffer

	enc := xml.NewEncoder(&w)
	dec := xml.NewDecoder(r)

	dec.Strict = false
	dec.AutoClose = xml.HTMLAutoClose
	dec.Entity = xml.HTMLEntity
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

//export sdBuildFilelist
func sdBuildFilelist() {
	paths := filepath.SplitList(os.Getenv("PUBLISHER_BASE_PATH"))
	if fp := os.Getenv("SP_FONT_PATH"); fp != "" {
		for _, p := range filepath.SplitList(fp) {
			paths = append(paths, p)
		}
	}
	for _, p := range filepath.SplitList(os.Getenv("SP_EXTRA_DIRS")) {
		paths = append(paths, p)
	}
	splibaux.BuildFilelist(paths)
}

//export sdAddDir
func sdAddDir(cpath *C.char) {
	path := C.GoString(cpath)
	splibaux.AddDir(path)
}

//export sdLookupFile
func sdLookupFile(cpath *C.char) *C.char {
	path := C.GoString(cpath)
	ret, err := splibaux.GetFullPath(path)
	if err != nil {
		slog.Error("internal error", "where", "splibaux.GetFullPath", "argument", path, "errormessage", err.Error())
		return s2c(errorpattern + err.Error())
	}
	slog.Debug("File lookup", "request", path, "found", ret)
	return s2c(ret)
}

//export sdListFonts
func sdListFonts() **C.char {
	res := splibaux.ListFonts()
	return toCharArray(res)
}

//export sdConvertContents
func sdConvertContents(contentsC, handlerC *C.char) *C.char {
	contents := C.GoString(contentsC)
	handler := C.GoString(handlerC)
	ret, err := splibaux.ConvertContents(contents, handler)
	if err != nil {
		return s2c(errorpattern + err.Error())
	}
	return s2c(ret)
}

//export sdConvertImage
func sdConvertImage(filenameC, handlerC *C.char) *C.char {
	filename := C.GoString(filenameC)
	handler := C.GoString(handlerC)

	ret, err := splibaux.ConvertImage(filename, handler)
	if err != nil {
		return s2c(errorpattern + err.Error())
	}
	return s2c(ret)
}

//export sdConvertSVGImage
func sdConvertSVGImage(pathC *C.char) *C.char {
	path := C.GoString(pathC)
	ret, err := splibaux.ConvertSVGImage(path)
	if err != nil {
		return s2c(errorpattern + err.Error())
	}
	return s2c(ret)
}

//export sdSegmentize
func sdSegmentize(originalC *C.char) *C.struct_splitvalues {
	inputstring := C.GoString(originalC)
	p := bidi.Paragraph{}
	p.SetString(inputstring)
	ordering, err := p.Order()
	if err != nil {
		panic(err)
	}
	nr := ordering.NumRuns()

	cLenghtsInt := C.malloc(C.size_t(nr) * C.size_t(unsafe.Sizeof(C.int(0))))
	cSplittedStrings := C.malloc(C.size_t(nr) * C.size_t(unsafe.Sizeof(uintptr(0))))
	returnStruct := (*C.struct_splitvalues)(C.malloc(C.size_t(unsafe.Sizeof(C.struct_splitvalues{}))))

	ints := (*[1<<15 - 1]C.int)(cLenghtsInt)[:nr:nr]
	a := (*[1<<15 - 1]*C.char)(cSplittedStrings)

	for i := 0; i < nr; i++ {
		r := ordering.Run(i)
		ints[i] = C.int(int(r.Direction()))
		a[i] = C.CString(r.String())
	}

	returnStruct.splitted = (**C.char)(cSplittedStrings)
	returnStruct.directions = (*C.int)(cLenghtsInt)
	returnStruct.count = C.int(nr)

	return returnStruct
}

//export sdReadXMLFile
func sdReadXMLFile(filenameC *C.char) *C.char {
	filename := C.GoString(filenameC)
	str, err := splibaux.ReadXMLFile(filename)
	slog.Debug("Checksum", "filename", filename, "md5", md5calc(filename))
	if err != nil {
		return s2c(errorpattern + err.Error())
	}
	return s2c(str)
}

//export sdReadXMLString
func sdReadXMLString(xmlstring *C.char) *C.char {
	goXMLString := C.GoString(xmlstring)
	str, err := splibaux.ReadXMLString(goXMLString)
	if err != nil {
		return s2c(errorpattern + err.Error())
	}
	return s2c(str)
}

//export sdTeardown
func sdTeardown() {
	err := teardownLog()
	if err != nil {
		fmt.Println(err)
	}
}

//export sdLogMessage
func sdLogMessage(level *C.char, message *C.char) {
	goLevel := C.GoString(level)
	goMessage := C.GoString(message)
	switch goLevel {
	case "notice":
		slog.Log(nil, LevelNotice, goMessage)
	case "info":
		slog.Log(nil, slog.LevelInfo, goMessage)
	case "debug":
		slog.Log(nil, slog.LevelDebug, goMessage)
	case "warning", "warn":
		slog.Log(nil, slog.LevelWarn, goMessage)
	case "error":
		slog.Log(nil, slog.LevelError, goMessage)
	default:
		fmt.Println("~~> unknown log level", goLevel)
	}
}

//export sdLogMessages
func sdLogMessages(level *C.char, message *C.char, arguments []*C.char) {
	goLevel := C.GoString(level)
	goMessage := C.GoString(message)
	var argsAny []any
	for _, arg := range arguments {
		argsAny = append(argsAny, C.GoString(arg))
	}
	switch goLevel {
	case "notice":
		slog.Log(nil, LevelNotice, goMessage, argsAny...)
	case "info":
		slog.Info(goMessage, argsAny...)
	case "debug":
		slog.Debug(goMessage, argsAny...)
	case "warning", "warn":
		slog.Warn(goMessage, argsAny...)
	case "error":
		slog.Error(goMessage, argsAny...)
	default:
		fmt.Println("~~> unknown log level", goLevel)
	}
}

//export sdGetErrCount
func sdGetErrCount() int {
	return errCount
}

//export sdGetWarnCount
func sdGetWarnCount() int {
	return warnCount
}

func main() {}
