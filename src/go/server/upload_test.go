//go:build pro

package server

import "testing"

func TestUploadFileName(t *testing.T) {
	valid := map[string]string{
		"layout.xml":                "layout.xml",
		"../../../victim/pwned.txt": "pwned.txt",
		"/etc/passwd":               "passwd",
		"sub/data.xml":              "data.xml",
	}
	for in, want := range valid {
		got, ok := uploadFileName(in)
		if !ok || got != want {
			t.Errorf("uploadFileName(%q) = %q, %v, want %q, true", in, got, ok, want)
		}
	}
	for _, in := range []string{"", ".", "..", "/", "../", "a/.."} {
		if got, ok := uploadFileName(in); ok {
			t.Errorf("uploadFileName(%q) = %q, true, want rejection", in, got)
		}
	}
}
