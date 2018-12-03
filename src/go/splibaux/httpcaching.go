package splibaux

import (
	"crypto/md5"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"

	"github.com/gregjones/httpcache"
	"github.com/gregjones/httpcache/diskcache"
)

var (
	cachemethod string
	client      *http.Client
)

func init() {
	cachemethod = os.Getenv("CACHEMETHOD")
}

func DoCaching(cachedir, outfilename, url string) (string, error) {
	// Let's assume cachedir already exists
	var err error
	hashedFilename := fmt.Sprintf("%x", md5.Sum([]byte(outfilename)))
	outpath := filepath.Join(cachedir, hashedFilename)

	if cachemethod == "optimal" {
		if client == nil {
			goimgcache := filepath.Join(cachedir, "sp")
			err = os.MkdirAll(goimgcache, 0755)
			if err != nil {
				return "", err
			}
			dc := diskcache.New(goimgcache)
			dcTP := httpcache.NewTransport(dc)
			client = dcTP.Client()
		}

		resp, err := client.Get(url)
		if err != nil {
			return "", err
		}
		if resp.StatusCode == http.StatusNotFound {
			os.Remove(outpath)
			return "", fmt.Errorf("Resource not found (404): %q", url)
		}
		outf, err := os.Create(outpath)
		if err != nil {
			return "", err
		}
		defer outf.Close()
		io.Copy(outf, resp.Body)
	}
	return outpath, nil
}
