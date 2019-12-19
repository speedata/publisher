package splibaux

import (
	"crypto/md5"
	"fmt"
	"io"
	"io/ioutil"
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

func getFilenameAndDoCaching(cachedir, outfilename, url string) (string, error) {
	// Let's assume cachedir already exists
	var err error
	hashedFilename := fmt.Sprintf("%x", md5.Sum([]byte(outfilename)))
	outpath := filepath.Join(cachedir, hashedFilename)

	if cachemethod != "optimal" {
		return outpath, nil
	}

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
	outf, err := ioutil.TempFile(cachedir, "download")
	if err != nil {
		return "", err
	}

	if _, err = io.Copy(outf, resp.Body); err != nil {
		return "", err
	}
	resp.Body.Close()

	temfilename := outf.Name()
	if err = outf.Close(); err != nil {
		return "", err
	}
	err = os.Rename(temfilename, outpath)
	return outpath, err
}
