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
