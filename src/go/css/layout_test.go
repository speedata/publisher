package css

import (
	"testing"
)

func elt(name, class, id string) LayoutElement {
	return LayoutElement{Name: name, Class: class, ID: id}
}

func TestLayoutMatch(t *testing.T) {
	ls := NewLayoutStylesheet()
	ls.AddCSS(`
		span { letter-spacing: 2pt }
		.warn { background-color: yellow }
		.a { color: orange }
		#head { color: green }
		span#foot { color: blue }
		div td { background-color: red }
		tr td.x { background-color: green }
		tr td { padding: 1mm }
		table td { padding: 2mm }
		ol.brace li::marker { content: "}"; padding-right: 2mm }
		@media print { span.three { letter-spacing: 5pt } }
		@import "foo.css";
		span.four { border: 1pt solid rgb(1,2,3) }
		td.imp { text-align: right !important }
		td#imp { text-align: left }
	`)

	testdata := []struct {
		name   string
		chain  []LayoutElement
		pseudo string
		key    string
		want   string
	}{
		{"cascade element", []LayoutElement{elt("span", "warn", "")}, "", "letter-spacing", "2pt"},
		{"cascade class", []LayoutElement{elt("span", "warn", "")}, "", "background-color", "yellow"},
		{"class as suffix", []LayoutElement{elt("span", "superwarn", "")}, "", "background-color", ""},
		{"first of two classes", []LayoutElement{elt("span", "a b", "")}, "", "color", "orange"},
		{"class prefix", []LayoutElement{elt("span", "aa", "")}, "", "color", ""},
		{"id", []LayoutElement{elt("span", "", "head")}, "", "color", "green"},
		{"id substring", []LayoutElement{elt("span", "", "pagehead")}, "", "color", ""},
		{"element with id", []LayoutElement{elt("span", "", "foot")}, "", "color", "blue"},
		{"descendant missing", []LayoutElement{elt("table", "", ""), elt("tr", "", ""), elt("td", "", "")}, "", "background-color", ""},
		{"descendant", []LayoutElement{elt("table", "", ""), elt("tr", "", ""), elt("td", "x", "")}, "", "background-color", "green"},
		{"order", []LayoutElement{elt("table", "", ""), elt("tr", "", ""), elt("td", "", "")}, "", "padding", "2mm"},
		{"pseudo element", []LayoutElement{elt("ol", "brace", ""), elt("li", "", "")}, "marker", "content", `"}"`},
		{"pseudo element only", []LayoutElement{elt("ol", "brace", ""), elt("li", "", "")}, "", "content", ""},
		{"media skipped", []LayoutElement{elt("span", "three", "")}, "", "letter-spacing", "2pt"},
		{"after at-rules", []LayoutElement{elt("span", "four", "")}, "", "border", "1pt solid rgb(1,2,3)"},
		{"important", []LayoutElement{elt("td", "imp", "imp")}, "", "text-align", "right"},
	}
	for _, tc := range testdata {
		t.Run(tc.name, func(t *testing.T) {
			decls, _ := ls.Match(tc.chain, tc.pseudo)
			if got := decls[tc.key]; got != tc.want {
				t.Errorf("%s = %q, want %q", tc.key, got, tc.want)
			}
		})
	}
}

func TestLayoutImportant(t *testing.T) {
	ls := NewLayoutStylesheet()
	ls.AddCSS(`td { color: red ! important; padding: 1mm }`)
	decls, important := ls.Match([]LayoutElement{elt("td", "", "")}, "")
	if decls["color"] != "red" || !important["color"] || important["padding"] {
		t.Errorf("got %v, %v", decls, important)
	}
}

func TestLayoutNthChild(t *testing.T) {
	ls := NewLayoutStylesheet()
	ls.AddCSS(`tr:nth-child(even) { background-color: gray } layout > td { color: red }`)
	for pos, want := range map[int]string{1: "", 2: "gray", 3: ""} {
		chain := []LayoutElement{elt("table", "", ""), {Name: "tr", Position: pos}}
		decls, _ := ls.Match(chain, "")
		if got := decls["background-color"]; got != want {
			t.Errorf("row %d: got %q, want %q", pos, got, want)
		}
	}
	decls, _ := ls.Match([]LayoutElement{elt("td", "", "")}, "")
	if decls["color"] != "red" {
		t.Errorf("root element layout: got %v", decls)
	}
}

func BenchmarkLayoutMatch(b *testing.B) {
	ls := NewLayoutStylesheet()
	ls.AddCSS(`span { color: red } .a { color: blue } table td.x { padding: 1mm } tr:nth-child(even) td { background-color: gray }`)
	chain := []LayoutElement{elt("table", "t", ""), {Name: "tr", Position: 4}, {Name: "td", Class: "x", Position: 2}}
	for i := 0; i < b.N; i++ {
		ls.Match(chain, "")
	}
}
