package splibaux

import (
	"bytes"
	"crypto/md5"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
)

const (
	basedir = "_testdata"
)

func init() {
	BuildFilelist([]string{"_testdata"})
}

func TestHTTPGet(t *testing.T) {
	expected := "teststring"

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { fmt.Fprint(w, expected) }))
	defer ts.Close()
	var b bytes.Buffer
	err := downloadFile(ts.URL+"/path/img.png", &b)
	if err != nil {
		t.Error(err)
	}
	if res := b.String(); res != expected {
		t.Errorf("%q expected but got %q", expected, res)
	}
}

func TestSimple(t *testing.T) {
	expected := "teststring"

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { fmt.Fprint(w, expected) }))
	defer ts.Close()

	testimg := filepath.Join(basedir, `cow.pdf`)
	testimgAbs, err := filepath.Abs(testimg)
	if err != nil {
		t.Fatal(err)
	}

	md5sum := fmt.Sprintf("%x", md5.Sum([]byte("127.0.0.1/path/cow.pdf?foo=bar")))

	tmp := map[string]string{
		"cow.pdf": testimgAbs,
		testimg:   testimg,
		"file://" + filepath.FromSlash(testimgAbs): testimgAbs,
		filepath.Join(basedir, `doesnotexist.txt`): "",
		ts.URL + "/path/cow.pdf?foo=bar":           filepath.Join(os.TempDir(), "imagecache", md5sum),
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
