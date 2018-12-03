package gomddoc

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"testing"
)

var basedir string

func init() {
	thisdir, err := os.Getwd()
	if err != nil {
		log.Fatal(err)
	}
	basedir = filepath.Join(thisdir, "..")
}

func TestOtherLanguage(t *testing.T) {
	dest := "/tmp/build"
	//                  root                dest          base
	md, err := NewMDDoc("dummy/path/other", dest, basedir)
	if err != nil {
		t.Error(err)
	}

	type pairs struct {
		first  string
		second string
	}
	data := []pairs{
		{"/tmp/build/index.html", "index-de.html"},
		{"/tmp/build/sub-en/whatever/index.html", "../../sub-de/whatever/index.html"},
	}
	for _, v := range data {
		if tmp := md.otherLanguage(v.first); tmp != v.second {
			t.Error(fmt.Sprintf("Expected other path to be %q but found %q. Requested path = %q\n", v.second, tmp, v.first))
		}
	}
}
