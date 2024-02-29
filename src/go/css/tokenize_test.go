package css

import (
	"testing"
)

func TestParseCSSString(t *testing.T) {
	str := "color:#000;font-weight:bold"
	toks := parseCSSString(str)
	expected := 7
	if got := len(toks); got != expected {
		t.Errorf("len(parseCSSString(%s)) = %d, want %d", str, got, expected)
	}
	kv := keyValueFromToks(toks)
	expected = 2
	if got := len(kv); got != expected {
		t.Errorf("len(keyValueFromToks(toks)) = %d, want %d", got, expected)
	}
}
