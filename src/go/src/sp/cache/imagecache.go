package cache

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

func Clear() {
	luaimgcache := os.Getenv("IMGCACHE")
	os.RemoveAll(luaimgcache)
}

func CacheImage(url string) string {
	outfilename := fmt.Sprintf("%x", md5.Sum([]byte(url)))
	luaimgcache := os.Getenv("IMGCACHE")
	err := os.MkdirAll(luaimgcache, 0755)
	if err != nil {
		return "ERR"
	}
	goimgcache := filepath.Join(luaimgcache, "sp")
	err = os.MkdirAll(goimgcache, 0755)
	if err != nil {
		return "ERR 1"
	}
	outpath := filepath.Join(luaimgcache, outfilename)

	dc := diskcache.New(goimgcache)
	t := httpcache.NewTransport(dc)
	client := t.Client()
	resp, err := client.Get(url)
	if err != nil {
		return "ERR 3"
	}
	if resp.StatusCode == http.StatusNotFound {
		os.Remove(outpath)
		return "404"
	}
	outf, err := os.OpenFile(outpath, os.O_RDWR|os.O_TRUNC|os.O_CREATE, 0644)
	if err != nil {
		return "ERR 2"
	}
	defer outf.Close()

	io.Copy(outf, resp.Body)
	return "OK"
}
