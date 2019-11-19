package splibaux

import (
	"crypto/md5"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
)

var (
	files      map[string]string
	ignorefile string
)

func init() {
	wd, _ := os.Getwd()
	ignorefile = filepath.Join(wd, os.Getenv("SP_JOBNAME")+".pdf")
	files = make(map[string]string)

}

func downloadFile(resourceUrl string, outfile io.Writer) error {
	// get HTTP file
	res, err := http.Get(resourceUrl)
	if err != nil {
		return err
	}
	defer res.Body.Close()
	_, err = io.Copy(outfile, res.Body)
	return err
}

func saveFileFromUrl(parsedURL *url.URL, rawURL string) (string, error) {
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

	resultingFilename, err := DoCaching(rawimgcache, destfile, rawURL)
	if err != nil {
		return "", err
	}

	if _, err := os.Stat(resultingFilename); err == nil {
		return resultingFilename, nil
	} else {
		if !os.IsNotExist(err) {
			return "", err
		}
	}
	f, err := os.Create(resultingFilename)
	if err != nil {
		return "", err
	}
	defer f.Close()
	err = downloadFile(rawURL, f)
	return resultingFilename, err
}

// Return the real path of a file
// filename can be a short file, an absolute path to a file,
// a file:// or a http(s):// URL.
func GetFullPath(filename string) (string, error) {
	u, err := url.Parse(filename)
	if err != nil {
		return "", err
	}
	if u.Scheme == "http" || u.Scheme == "https" {
		return saveFileFromUrl(u, filename)
	} else if u.Scheme == "file" {
		fn := u.Path
		if hn := u.Hostname(); hn != "" {
			fn = hn + ":" + fn
		}
		return LookupFile(fn), nil
	} else {
		return LookupFile(filename), nil
	}
	return "", nil
}

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

func AddDir(p string) {
	filepath.Walk(p, addFileToList)
}

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

func ListFonts() []string {
	var res []string
	for _, f := range files {
		if isFont(f) {
			res = append(res, f)
		}
	}
	return res

}

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
