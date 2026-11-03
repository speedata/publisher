package css

import (
	"strings"
	"testing"
)

func TestResolveValue(t *testing.T) {
	vars := map[string]string{
		"--a":     "4pt",
		"--color": "rgb(1,2,3)",
		"--Case":  "upper",
		"--empty": "",
	}
	tests := []struct {
		in, out string
		err     bool
	}{
		{"var(--a)", "4pt", false},
		{"var(--a) 0", "4pt 0", false},
		{"1pt solid var(--color)", "1pt solid rgb(1,2,3)", false},
		{"VAR( --a )", "4pt", false},
		{"var(--a)var(--a)", "4pt4pt", false},
		{"var(--case)", "", true},
		{"var(--Case)", "upper", false},
		{"var(--x)", "", true},
		{"var(--x, 2pt)", "2pt", false},
		{"var(--x,)", "", false},
		{"var(--x, var(--y, red))", "red", false},
		{"var(--x, var(--a))", "4pt", false},
		{"var(--x, rgb(1, 2, 3))", "rgb(1, 2, 3)", false},
		{"var(--x, \"a)b\")", "\"a)b\"", false},
		{"var(--a, ignored)", "4pt", false},
		{"var(--x, var(--y))", "", true},
		{"a var(--empty) b", "a  b", false},
		{"novar(--a)", "novar(--a)", false},
		{"var(a)", "", true},
		{"var(--a", "", true},
		{"no reference", "no reference", false},
	}
	for _, tc := range tests {
		got, err := resolveValue(tc.in, vars)
		if tc.err {
			if err == nil {
				t.Errorf("resolveValue(%q) = %q, want error", tc.in, got)
			}
			continue
		}
		if err != nil {
			t.Errorf("resolveValue(%q): unexpected error %v", tc.in, err)
			continue
		}
		if got != tc.out {
			t.Errorf("resolveValue(%q) = %q, want %q", tc.in, got, tc.out)
		}
	}
}

func TestComputeVars(t *testing.T) {
	inherited := map[string]string{"--a": "1pt", "--b": "blue"}

	vars, errs := computeVars(inherited, nil)
	if len(errs) != 0 || vars["--a"] != "1pt" {
		t.Errorf("no declarations: got %v, %v", vars, errs)
	}

	vars, errs = computeVars(inherited, []varDecl{
		{"--a", "2pt"},
		{"--c", "var(--a) var(--b)"},
		{"--d", "var(--e)"},
		{"--e", "var(--a)"},
		{"--a", "3pt"},
	})
	if len(errs) != 0 {
		t.Errorf("unexpected errors %v", errs)
	}
	want := map[string]string{"--a": "3pt", "--b": "blue", "--c": "3pt blue", "--d": "3pt", "--e": "3pt"}
	for k, v := range want {
		if vars[k] != v {
			t.Errorf("%s = %q, want %q", k, vars[k], v)
		}
	}
	if inherited["--a"] != "1pt" || len(inherited) != 2 {
		t.Errorf("inherited map changed: %v", inherited)
	}

	// undefined: the declaration is dropped, the earlier one applies
	vars, errs = computeVars(inherited, []varDecl{
		{"--b", "red"},
		{"--b", "var(--undefined)"},
		{"--c", "var(--undefined)"},
	})
	if vars["--b"] != "red" {
		t.Errorf("--b = %q, want red", vars["--b"])
	}
	if _, ok := vars["--c"]; ok {
		t.Errorf("--c should be undefined, got %q", vars["--c"])
	}
	if len(errs) != 2 {
		t.Errorf("want 2 errors, got %v", errs)
	}

	// a cycle invalidates all of its declarations, even with a fallback;
	// the inherited value applies
	vars, errs = computeVars(inherited, []varDecl{
		{"--a", "var(--x, 5pt)"},
		{"--x", "var(--a, 6pt)"},
		{"--self", "var(--self, 1pt)"},
		{"--ok", "var(--a)"},
	})
	if vars["--a"] != "1pt" {
		t.Errorf("--a = %q, want inherited 1pt", vars["--a"])
	}
	if _, ok := vars["--x"]; ok {
		t.Errorf("--x should be undefined, got %q", vars["--x"])
	}
	if _, ok := vars["--self"]; ok {
		t.Errorf("--self should be undefined, got %q", vars["--self"])
	}
	if vars["--ok"] != "1pt" {
		t.Errorf("--ok = %q, want 1pt", vars["--ok"])
	}
	if len(errs) < 3 {
		t.Errorf("want at least 3 errors, got %v", errs)
	}
}

// htmlStyles parses an HTML fragment and returns the computed styles of the
// elements with an id attribute.
func htmlStyles(t *testing.T, htmltext, csstext string, initial map[string]string) map[string]map[string]string {
	t.Helper()
	c := NewCSSParser()
	c.InitialVars = initial
	r, err := c.ParseHTMLFragment(htmltext, csstext)
	if err != nil {
		t.Fatal(err)
	}
	ret := map[string]map[string]string{}
	for n, st := range r.Styles {
		for _, a := range n.Attr {
			if a.Key == "id" {
				ret[a.Val] = st
			}
		}
	}
	return ret
}

func TestHTMLVars(t *testing.T) {
	css := `
:root { --main: rgb(1,2,3); --gap: 4pt }
div { --gap: 6pt; --text: "»" }
.a { color: var(--main); padding: var(--gap) 0 }
.b { color: green; color: var(--undefined) }
.c { color: var(--undefined, blue) }
.d::before { --text: "«"; content: var(--text) }
.e::before { content: var(--text) }
.f { color: var(--fromlayout) }
.g { border: 1pt solid var(--main) }
`
	html := `<body>
<p id="a" class="a">a</p>
<div id="div"><p id="a2" class="a">a</p><p id="d" class="d">d</p><p id="e" class="e">e</p></div>
<p id="b" class="b">b</p>
<p id="c" class="c">c</p>
<p id="f" class="f">f</p>
<p id="g" class="g">g</p>
<p id="h" style="--main: red; color: var(--main)">h</p>
</body>`
	st := htmlStyles(t, html, css, map[string]string{"--fromlayout": "yellow"})
	checks := []struct{ id, prop, want string }{
		{"a", "color", "rgb( 1 , 2 , 3 )"}, // as stringValue serializes it,
		{"a", "padding-top", "4pt"},
		{"a", "padding-left", "0"},
		{"a2", "padding-top", "6pt"},
		{"b", "color", "green"},
		{"c", "color", "blue"},
		{"d", "before::content", "«"},
		{"e", "before::content", "»"},
		{"f", "color", "yellow"},
		{"g", "border-top-color", "rgb( 1 , 2 , 3 )"},
		{"g", "border-top-width", "1pt"},
		{"h", "color", "red"},
	}
	for _, c := range checks {
		if got := st[c.id][c.prop]; got != c.want {
			t.Errorf("#%s %s = %q, want %q", c.id, c.prop, got, c.want)
		}
	}
	for id, s := range st {
		for k := range s {
			if isCustomProperty(k) || strings.HasPrefix(k, "-") {
				t.Errorf("#%s: custom property %q in the computed styles", id, k)
			}
		}
	}
}

func TestHTMLVarsInitialWin(t *testing.T) {
	css := `:root { --main: black; --derived: var(--main) } html { --own: blue } p { color: var(--main); background-color: var(--own) } p.d { color: var(--derived) }`
	html := `<body><p id="p">x</p><p id="d" class="d">y</p></body>`
	st := htmlStyles(t, html, css, map[string]string{"--main": "red", "--derived": "black"})
	checks := []struct{ id, prop, want string }{
		{"p", "color", "red"},
		{"p", "background-color", "blue"},
		{"d", "color", "black"},
	}
	for _, c := range checks {
		if got := st[c.id][c.prop]; got != c.want {
			t.Errorf("#%s %s = %q, want %q", c.id, c.prop, got, c.want)
		}
	}
}
