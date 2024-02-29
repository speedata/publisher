//go:build !pro
// +build !pro

package splibaux

import (
	"fmt"
	"net/url"
)

func saveFileFromURL(parsedURL *url.URL, rawURL string) (string, error) {
	return "", fmt.Errorf("Downloading from the internet needs speedata Publisher Pro")
}

// ResizeImage gets a new image with the given width and height.
func ResizeImage(filename string, imagetype string, width, height int) (string, error) {
	return "", nil
}
