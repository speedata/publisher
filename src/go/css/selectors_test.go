package css

import (
	"reflect"
	"testing"
)

func TestSplitSelectorList(t *testing.T) {
	for list, want := range map[string][]string{
		"a":                          {"a"},
		":root, :host":               {":root", " :host"},
		"p:not(.a, .b), h1":          {"p:not(.a, .b)", " h1"},
		`a[title="x,y"], b`:          {`a[title="x,y"]`, " b"},
		`a[title='x,y'],b`:           {`a[title='x,y']`, "b"},
		`.a\,b, c`:                   {`.a\,b`, " c"},
		"li:nth-child(2n+1), li.odd": {"li:nth-child(2n+1)", " li.odd"},
	} {
		if got := splitSelectorList(list); !reflect.DeepEqual(got, want) {
			t.Errorf("splitSelectorList(%q) = %q, want %q", list, got, want)
		}
	}
}

func TestParseSelectorGroup(t *testing.T) {
	for list, want := range map[string]int{
		"h1, h2":                   2,
		":root, :host":             1,
		":host":                    0,
		"p, :host(.x), li::before": 2,
		"p, :unknown-thing":        1,
	} {
		if got := len(parseSelectorGroup(list)); got != want {
			t.Errorf("parseSelectorGroup(%q) has %d selectors, want %d", list, got, want)
		}
	}
}

func TestLayoutRootHost(t *testing.T) {
	ls := NewLayoutStylesheet()
	ls.AddCSS(`:root, :host { color: red }`)
	if len(ls.rules) != 1 {
		t.Errorf("got %d rules, want 1 (:root)", len(ls.rules))
	}
}
