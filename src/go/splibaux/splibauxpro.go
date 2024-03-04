//go:build pro
// +build pro

package splibaux

import (
	"crypto/md5"
	"fmt"
	"io"
	"log/slog"
	"net/url"
	"os"
	"path/filepath"

	"github.com/speedata/bild/imgio"
	"github.com/speedata/bild/transform"
)

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
	f, err := os.CreateTemp(rawimgcache, "download")
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

// ResizeImage gets a new image with the given width and height.
func ResizeImage(filename string, imagetype string, width, height int) (string, error) {
	var err error

	fn := filepath.Join(os.TempDir(), "speedata_publisher")
	if err = os.MkdirAll(fn, 0755); err != nil {
		return "", err
	}

	pathPart := filepath.Dir(filename)
	filenamePart := filepath.Base(filename)

	h := md5.New()
	io.WriteString(h, pathPart)

	prefix := fmt.Sprintf("%x", h.Sum(nil))
	destFilename := filepath.Join(fn, fmt.Sprintf("%s_%d_%d_%s", prefix, width, height, filenamePart))

	if _, err = os.Stat(destFilename); err == nil {
		return destFilename, nil
	}

	slog.Info("Resize file", "out", destFilename)
	img, err := imgio.Open(filename)
	if err != nil {
		return "", err
	}

	resized := transform.Resize(img, width, height, transform.Linear)
	var encoder imgio.Encoder

	switch imagetype {
	case "png":
		encoder = imgio.PNGEncoder()
	case "jpg":
		encoder = imgio.JPEGEncoder(70)
	default:
		return "", fmt.Errorf("Image file type not supported (resize image)")
	}

	err = imgio.Save(destFilename, resized, encoder)
	return destFilename, err
}
