package splibaux

import (
	"crypto/md5"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
)

var (
	files      map[string]string
	ignorefile string
	verbosity  int
)

func init() {
	wd, _ := os.Getwd()
	ignorefile = filepath.Join(wd, os.Getenv("SP_JOBNAME")+".pdf")
	files = make(map[string]string)
	if v := os.Getenv("SP_VERBOSITY"); v != "" {
		verbosity, _ = strconv.Atoi(v)
	}
}

func downloadFile(resourceURL string, outfile io.Writer) error {
	// get HTTP file
	res, err := http.Get(resourceURL)
	if err != nil {
		return err
	}
	defer res.Body.Close()
	_, err = io.Copy(outfile, res.Body)
	return err
}

// Download a file via http / https and save it into a file in the imagecache folder.
// If the environment variable CACHEMETHOD is set to 'optimal', the method docaching()
// will perform a query to the server even if the image file exists in the IMGCACHE directory
// to check if the local file is up to date.
// The return value is the file name for the LuaTeX process
func saveFileFromURL(parsedURL *url.URL, rawURL string) (string, error) {
	rawimgcache := os.Getenv("IMGCACHE")
	if rawimgcache == "" {
		rawimgcache = filepath.Join(os.TempDir(), "imagecache")
	}

	if fi, err := os.Stat(rawimgcache); os.IsExist(err) {
		// file exists
		if !fi.IsDir() {
			fmt.Println("Image cache exists but is not a directory")
			return "", fmt.Errorf("Image cache %q exists but is not a directory", rawimgcache)
		}
	} else {
		err = os.MkdirAll(rawimgcache, 0755)
		if err != nil {
			return "", err
		}
	}

	destfile := parsedURL.Hostname() + parsedURL.Path
	if parsedURL.RawQuery != "" {
		destfile += "?" + parsedURL.RawQuery
	}

	// docaching does not do anything if the cache method is not "optimal".
	// So the resultingFilename may not exist. But at least we now know the
	// filename (it is basically a md5 sum of the URL, but this is not guaranteed).
	resultingFilename, err := getFilenameAndDoCaching(rawimgcache, destfile, rawURL)
	if err != nil {
		return "", err
	}
	if cachemethod != "none" {
		// docaching has downloaded the file, so we can pass it back
		// to the lua process
		if _, err = os.Stat(resultingFilename); err == nil {
			return resultingFilename, nil
		}
		// only keep on going if the error of stat is a "file not found" error.
		if !os.IsNotExist(err) {
			return "", err
		}
	}

	// We create a temporary file and use that for downloading.
	// After that (the process can take some time) we create the file we need.
	f, err := ioutil.TempFile(rawimgcache, "download")
	if err != nil {
		return "", err
	}
	defer f.Close()
	err = downloadFile(rawURL, f)
	if err != nil {
		return "", err
	}
	err = os.Rename(f.Name(), resultingFilename)
	return resultingFilename, err
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
				files[filepath.Base(path)] = path
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
	replacer := strings.NewReplacer("%%input%%", inputfilename, "%%output%%", outfile)
	replacedHandler := strings.Fields(replacer.Replace(handler))
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

	fmt.Print("Running inkscape on ", svgfile, "...")
	switch runtime.GOOS {
	case "windows":
		if !strings.HasSuffix(binaryname, ".exe") {
			binaryname = binaryname + ".exe"
		}
	}
	cmd := exec.Command(binaryname, "--export-pdf", pdffile, svgfile)
	out, err := cmd.CombinedOutput()
	fmt.Println("done. Output follows (if any):")
	fmt.Println(string(out))
	if err != nil {
		return "", err
	}
	return pdffile, nil
}
