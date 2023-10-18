package splibaux

import (
	"crypto/md5"
	"encoding/csv"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

var (
	files       map[string]string = make(map[string]string)
	ignorefile  string
	verbosity   int
	pathrewrite *strings.Replacer
	nr          *strings.Replacer
)

func init() {
	wd, _ := os.Getwd()
	ignorefile = filepath.Join(wd, os.Getenv("SP_JOBNAME")+".pdf")
	if v := os.Getenv("SP_VERBOSITY"); v != "" {
		verbosity, _ = strconv.Atoi(v)
	}
	nr = strings.NewReplacer("\n", `\n`, `"`, `\"`, `\`, `\\`)

	if rewriteString := os.Getenv("SP_PATH_REWRITE"); rewriteString != "" {
		var rewrites = []string{}

		elements := strings.Split(rewriteString, ",")
		for _, elt := range elements {
			kv := strings.Split(elt, "=")
			if len(kv) == 2 {
				rewrites = append(rewrites, kv[0])
				rewrites = append(rewrites, kv[1])
			}
		}
		pathrewrite = strings.NewReplacer(rewrites...)
	}
}

func downloadFile(resourceURL string, outfile io.Writer) error {
	// get HTTP file
	res, err := http.Get(resourceURL)
	if err != nil {
		return err
	}
	defer res.Body.Close()
	if res.StatusCode != 200 {
		return fmt.Errorf("Resource not found")
	}
	_, err = io.Copy(outfile, res.Body)
	return err
}

// GetFullPath returns the real path of a file.
// filename can be a filename (w/o path), an absolute path to a file,
// a file:// or a http(s):// URL.
func GetFullPath(filename string) (string, error) {
	u, err := url.Parse(filename)
	if err != nil {
		return "", err
	}
	if u.Scheme == "http" || u.Scheme == "https" {
		return saveFileFromURL(u, filename)
	} else if u.Scheme == "file" {
		fn := u.Path
		if hn := u.Hostname(); hn != "" {
			fn = hn + ":" + fn
		}
		return LookupFile(fn), nil
	} else {
		return LookupFile(filename), nil
	}
}

// LookupFile returns the full path of the given file name. The file name can be a
// simple name, a path, a URL etc.
func LookupFile(path string) string {
	// TODO: lowercase
	// local lowercase = os.getenv("SP_IGNORECASE") == "1"
	//  if lowercase then filename_or_uri = unicode.utf8.lower(filename_or_uri) end
	if pathrewrite != nil {
		path = pathrewrite.Replace(path)
	}

	if ret, ok := files[path]; ok {
		return ret
	}
	if _, err := os.Stat(path); err == nil {
		return path
	}
	return ""
}

func addFileToList(path string, info os.FileInfo, err error) error {
	if info != nil {
		if !info.IsDir() {
			if ignorefile != path {
				fb := filepath.Base(path)
				if dup, found := files[fb]; found && verbosity > 0 {
					fmt.Println("warning: duplicate entry in directories:", dup, "and", path)
				} else {
					files[fb] = path
				}
			}
		}
	}
	return nil
}

// AddDir adds a directory to the list of search paths.
func AddDir(p string) {
	filepath.Walk(p, addFileToList)
}

// BuildFilelist walks through every given path and adds all found
// files to the global file search list.
func BuildFilelist(paths []string) {
	var err error
	for _, p := range paths {
		if !filepath.IsAbs(p) {
			p, err = filepath.Abs(p)
			if err != nil {
				fmt.Println(err)
				continue
			}
		}
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

func isFont(filename string) bool {
	lc := strings.ToLower(filename)
	return strings.HasSuffix(lc, ".pfb") || strings.HasSuffix(lc, ".ttf") || strings.HasSuffix(lc, ".otf")
}

// ListFonts returns a string of all font files found in the paths.
func ListFonts() []string {
	var res []string
	for _, f := range files {
		if isFont(f) {
			res = append(res, f)
		}
	}
	return res

}

func writeContentsToTempfile(contents string) (string, error) {
	var filename string
	f, err := ioutil.TempFile("", "speedata")
	if err != nil {
		return "", err
	}

	stringReader := strings.NewReader(contents)
	_, err = io.Copy(f, stringReader)
	if err != nil {
		return "", err
	}
	filename = f.Name()
	f.Close()
	return filename, nil
}

func convertFile(inputfilename, baseoutputfilename, handler string) (string, error) {
	var err error
	rawimgcache := os.Getenv("IMGCACHE")
	if rawimgcache == "" {
		rawimgcache = filepath.Join(os.TempDir(), "imagecache")
	}
	err = os.MkdirAll(rawimgcache, 0755)
	if err != nil {
		return "", err
	}

	outfile := filepath.Join(rawimgcache, baseoutputfilename)
	replaced := strings.NewReplacer("%%input%%", inputfilename, "%%output%%", outfile).Replace(handler)
	r := csv.NewReader(strings.NewReader(replaced))
	r.Comma = ' '

	record, err := r.Read()
	if err != nil {
		return "", err
	}

	replacedHandler := record
	executableFile := replacedHandler[0]
	replacedHandler = replacedHandler[1:]
	for _, itm := range replacedHandler {
		if strings.HasPrefix(itm, outfile) {
			outfile = itm
		}
	}
	cmd := exec.Command(executableFile, replacedHandler...)
	if verbosity > 0 {
		fmt.Println("command for image conversion:", cmd)
	}
	err = cmd.Run()
	return outfile, err
}

// ConvertContents runs an external program to convert the image into a file
// format suitable for the speedata Publisher.
func ConvertContents(contents, handler string) (string, error) {
	inputfilename, err := writeContentsToTempfile(contents)
	if err != nil {
		return "", err
	}
	hashedFilename := fmt.Sprintf("%x", md5.Sum([]byte(contents)))

	if verbosity == 0 {
		defer func() {
			os.RemoveAll(inputfilename)
		}()
	}
	return convertFile(inputfilename, hashedFilename, handler)
}

// ConvertImage runs an external program to convert the image into a file
// format suitable for the speedata Publisher.
func ConvertImage(filename, handler string) (string, error) {
	return convertFile(filename, "outfilename", handler)
}

// ConvertSVGImage runs inkscape to convert an SVG image to PDF.
// It returns the PDF file and an error.
func ConvertSVGImage(filename string) (string, error) {
	svgfile, err := GetFullPath(filename)
	if err != nil {
		return "", err
	}
	rawimgcache := os.Getenv("IMGCACHE")
	if rawimgcache == "" {
		rawimgcache = filepath.Join(os.TempDir(), "imagecache")
	}
	err = os.MkdirAll(rawimgcache, 0755)
	if err != nil {
		return "", err
	}

	hashedFilename := fmt.Sprintf("%x", md5.Sum([]byte(svgfile)))
	pdffile := filepath.Join(rawimgcache, hashedFilename+".pdf")

	if _, err := os.Stat(pdffile); err == nil {
		return pdffile, nil
	}

	binaryname := os.Getenv("SP_INKSCAPE")
	if binaryname == "" {
		fmt.Println("SP_INKSCAPE should be set. Why is it empty?")
		binaryname = "inkscape"
	}
	argument := os.Getenv("SP_INKSCAPECMD")

	fmt.Print("Running inkscape on ", svgfile, "...")
	cmd := exec.Command(binaryname, argument, pdffile, svgfile)
	out, err := cmd.CombinedOutput()
	fmt.Println("done. Output follows (if any):")
	fmt.Println(string(out))
	if err != nil {
		return "", err
	}
	return pdffile, nil
}

func handleXInclude(href string, startindex, indent int) (string, error) {
	fullpath := LookupFile(href)
	f, err := os.Open(fullpath)
	if err != nil {
		return "", err
	}
	return readXMLFile(f, startindex, indent)
}

func ReadXMLFile(filename string) (string, error) {
	fullpath := LookupFile(filename)
	f, err := os.Open(fullpath)
	if err != nil {
		return "", err
	}
	str, err := readXMLFile(f, 1, 0)
	f.Close()
	return "tbl = {" + str + "}", err
}
