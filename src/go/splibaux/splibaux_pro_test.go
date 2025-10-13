//go:build pro
// +build pro

package splibaux

import (
	"crypto/md5"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
)

func TestSimplePro(t *testing.T) {
	expected := "teststring"

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { fmt.Fprint(w, expected) }))
	defer ts.Close()

	md5sum := fmt.Sprintf("%x", md5.Sum([]byte("127.0.0.1/path/cow.pdf?foo=bar")))

	tmp := map[string]string{
		ts.URL + "/path/cow.pdf?foo=bar": filepath.Join(os.TempDir(), "imagecache", md5sum),
	}

	for fn, expected := range tmp {
		if retfn, err := GetFullPath(fn); retfn != expected || err != nil {
			if err != nil {
				t.Error(err)
			}
			t.Error("test simple: input:", fn, "expected:", expected, "but got", retfn)
		}

	}

	{
		expected := true
		if ret := isFont("foo.ttf"); ret != expected {
			t.Error("isFont", expected, "expected, but got", ret)
		}
	}

	{
		expected, _ := filepath.Abs("_testdata/afile.txt")
		if ret := LookupFile("afile.txt"); ret != expected {
			t.Error("LookupFile", expected, "expected, but got", ret)
		}
	}
}
