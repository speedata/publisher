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
		{"order", []LayoutElement{elt("table", "", ""), elt("tr", "", ""), elt("td", "", "")}, "", "padding-left", "2mm"},
		{"pseudo element", []LayoutElement{elt("ol", "brace", ""), elt("li", "", "")}, "marker", "content", `"}"`},
		{"pseudo element only", []LayoutElement{elt("ol", "brace", ""), elt("li", "", "")}, "", "content", ""},
		{"media skipped", []LayoutElement{elt("span", "three", "")}, "", "letter-spacing", "2pt"},
		{"after at-rules", []LayoutElement{elt("span", "four", "")}, "", "border-left-color", "rgb(1,2,3)"},
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
	if decls["color"] != "red" || !important["color"] || decls["padding-top"] != "1mm" || important["padding-top"] {
		t.Errorf("got %v, %v", decls, important)
	}
}

func TestLayoutNthChild(t *testing.T) {
	ls := NewLayoutStylesheet()
	ls.AddCSS(`tr:nth-child(even) { background-color: gray } tr:first-child { color: blue } tr:last-child { color: green } layout > td { color: red }`)
	for pos, want := range map[int]string{1: "", 2: "gray", 3: ""} {
		chain := []LayoutElement{elt("table", "", ""), {Name: "tr", Position: pos}}
		decls, _ := ls.Match(chain, "")
		if got := decls["background-color"]; got != want {
			t.Errorf("row %d: got %q, want %q", pos, got, want)
		}
		wantcolor := ""
		if pos == 1 {
			wantcolor = "blue"
		}
		if got := decls["color"]; got != wantcolor {
			t.Errorf("row %d: got color %q, want %q", pos, got, wantcolor)
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

func TestLayoutFontFace(t *testing.T) {
	ls := NewLayoutStylesheet()
	ls.AddCSS(`@font-face { font-family: "Body"; src: local("CrimsonPro-Regular") }
		@font-face { font-family: "Body"; font-weight: bold; src: url("crimson-bold.otf") }
		p { color: red }`)
	ff, ok := ls.Fontfamilies["Body"]
	if !ok || ff.Regular.Local != "CrimsonPro-Regular" || ff.Bold.URL != "crimson-bold.otf" {
		t.Errorf("got %#v", ls.Fontfamilies)
	}
}

func TestFontFaceNumericWeight(t *testing.T) {
	ls := NewLayoutStylesheet()
	ls.AddCSS(`@font-face { font-family: "Icons"; font-weight: 400; src: url("regular-400.ttf") }
		@font-face { font-family: "Icons"; font-weight: 900; src: url("solid-900.ttf") }
		@font-face { font-family: "Icons"; font-weight: 600; font-style: oblique 10deg; src: url("semibold-oblique.ttf") }
		@font-face { font-family: "Icons"; font-weight: 300; font-style: italic; src: url("light-italic.ttf") }`)
	ff := ls.Fontfamilies["Icons"]
	if ff.Regular.URL != "regular-400.ttf" || ff.Bold.URL != "solid-900.ttf" ||
		ff.BoldItalic.URL != "semibold-oblique.ttf" || ff.Italic.URL != "light-italic.ttf" {
		t.Errorf("got %#v", ff)
	}
}

func TestIsBoldWeight(t *testing.T) {
	for weight, want := range map[string]bool{
		"": false, "normal": false, "bold": true, "bolder": true, "lighter": false,
		"400": false, "599": false, "600": true, "900": true, "100 900": false, "700 900": true,
	} {
		if got := isBoldWeight(weight); got != want {
			t.Errorf("isBoldWeight(%q) = %v, want %v", weight, got, want)
		}
	}
}

func TestLayoutVars(t *testing.T) {
	ls := NewLayoutStylesheet()
	ls.AddCSS(`
		:root { --main: rgb(1,2,3); --gap: 1mm }
		table.wide { --gap: 3mm }
		td { padding: var(--gap) 0 }
		td.c { color: var(--main) }
		td.u { color: green }
		td.u { color: var(--undefined) }
		td.f { color: var(--undefined, blue) }
		tr:nth-child(even) { --zebra: gray }
		tr td { background-color: var(--zebra, white) }
		td.imp { --main: red !important }
		td#imp { --main: yellow; color: var(--main) }
		ol { --marker: "»" }
		ol.other li::marker { --marker: "«" }
		li::marker { content: var(--marker) }
	`)
	table := elt("table", "", "")
	wide := elt("table", "wide", "")
	tr := func(pos int) LayoutElement { return LayoutElement{Name: "tr", Position: pos} }
	testdata := []struct {
		name   string
		chain  []LayoutElement
		pseudo string
		key    string
		want   string
	}{
		{"root", []LayoutElement{table, tr(1), elt("td", "c", "")}, "", "color", "rgb(1,2,3)"},
		{"shorthand", []LayoutElement{table, tr(1), elt("td", "", "")}, "", "padding-top", "1mm"},
		{"shorthand second value", []LayoutElement{table, tr(1), elt("td", "", "")}, "", "padding-left", "0"},
		{"inherited override", []LayoutElement{wide, tr(1), elt("td", "", "")}, "", "padding-bottom", "3mm"},
		{"undefined dropped", []LayoutElement{table, tr(1), elt("td", "u", "")}, "", "color", "green"},
		{"fallback", []LayoutElement{table, tr(1), elt("td", "f", "")}, "", "color", "blue"},
		{"structural odd", []LayoutElement{table, tr(1), elt("td", "", "")}, "", "background-color", "white"},
		{"structural even", []LayoutElement{table, tr(2), elt("td", "", "")}, "", "background-color", "gray"},
		{"important variable", []LayoutElement{table, tr(1), elt("td", "imp", "imp")}, "", "color", "red"},
		{"pseudo inherits", []LayoutElement{elt("ol", "", ""), elt("li", "", "")}, "marker", "content", `"»"`},
		{"pseudo own", []LayoutElement{elt("ol", "other", ""), elt("li", "", "")}, "marker", "content", `"«"`},
		{"no custom properties", []LayoutElement{table}, "", "--gap", ""},
	}
	for _, tc := range testdata {
		t.Run(tc.name, func(t *testing.T) {
			decls, _ := ls.Match(tc.chain, tc.pseudo)
			if got := decls[tc.key]; got != tc.want {
				t.Errorf("%s = %q, want %q", tc.key, got, tc.want)
			}
		})
	}
	vars := ls.Vars([]LayoutElement{wide, tr(2), elt("td", "", "")})
	if vars["--gap"] != "3mm" || vars["--zebra"] != "gray" || vars["--main"] != "rgb(1,2,3)" {
		t.Errorf("Vars = %v", vars)
	}
	if NewLayoutStylesheet().Vars([]LayoutElement{table}) != nil {
		t.Errorf("Vars without variables should be nil")
	}
}

func TestLayoutShorthands(t *testing.T) {
	ls := NewLayoutStylesheet()
	ls.AddCSS(`
		:root { --frame: 2pt dashed rgb(1, 2, 3) }
		td { border-top-color: blue }
		td.later { border: 1pt solid red }
		td.longhand { border-top-color: green }
		td { border: 3pt solid }
		td.imp { border: 1pt solid red !important }
		td.imp.x { border-color: green }
		td.pad { padding: 1pt 2pt 3pt; padding-left: 9pt }
		td.pad.over { padding: 5pt }
		td.five { padding: 1pt 2pt 3pt 4pt 5pt }
		td.side { border-bottom: thick double }
		td.nostyle { border: 1pt #ff8c00 }
		td.var { border: var(--frame) }
		td.width { border-width: 1pt 2pt }
		td.plain { vertical-align: top }
		td.legacy { border-right: 0.25pt }
	`)
	td := func(class string) []LayoutElement { return []LayoutElement{elt("td", class, "")} }
	testdata := []struct {
		name  string
		chain []LayoutElement
		key   string
		want  string
	}{
		{"more specific shorthand wins", td("later"), "border-top-color", "red"},
		{"more specific longhand wins", td("longhand"), "border-top-color", "green"},
		{"shorthand keeps parts it does not name", td(""), "border-top-color", "blue"},
		{"shorthand width", td(""), "border-left-width", "3pt"},
		{"shorthand style", td(""), "border-right-style", "solid"},
		{"important shorthand", td("imp x"), "border-top-color", "red"},
		{"three values top", td("pad"), "padding-top", "1pt"},
		{"three values right", td("pad"), "padding-right", "2pt"},
		{"three values bottom", td("pad"), "padding-bottom", "3pt"},
		{"later longhand", td("pad"), "padding-left", "9pt"},
		{"more specific shorthand over longhand", td("pad over"), "padding-left", "5pt"},
		{"invalid number of values", td("five"), "padding-top", ""},
		{"one side width", td("side"), "border-bottom-width", "2pt"},
		{"one side style", td("side"), "border-bottom-style", "double"},
		{"one side color not set", td("side"), "border-bottom-color", ""},
		{"one side only", td("side"), "border-top-style", "solid"},
		{"missing style not set", td("nostyle"), "border-top-style", "solid"},
		{"color without style", td("nostyle"), "border-top-color", "#ff8c00"},
		{"var() in shorthand", td("var"), "border-left-style", "dashed"},
		{"color with spaces", td("var"), "border-left-color", "rgb(1, 2, 3)"},
		{"two widths", td("width"), "border-right-width", "2pt"},
		{"no shorthand key", td(""), "border", ""},
		{"longhand unchanged", td("plain"), "vertical-align", "top"},
		{"width only", td("legacy"), "border-right-width", "0.25pt"},
		{"width only keeps style", td("legacy"), "border-right-style", "solid"},
		{"later shorthand replaces longhand", td("later"), "border-top-width", "1pt"},
	}
	for _, tc := range testdata {
		t.Run(tc.name, func(t *testing.T) {
			decls, _ := ls.Match(tc.chain, "")
			if got := decls[tc.key]; got != tc.want {
				t.Errorf("%s = %q, want %q", tc.key, got, tc.want)
			}
		})
	}
	_, important := ls.Match(td("imp x"), "")
	if !important["border-top-color"] || !important["border-left-width"] || important["border"] {
		t.Errorf("important = %v", important)
	}
}

func TestLayoutStyleAttribute(t *testing.T) {
	ls := NewLayoutStylesheet()
	ls.AddCSS(`
		:root { --accent: green }
		td { color: red; padding: 1pt }
		td#x.y.z { color: blue }
		td.imp { color: red !important }
		td[style] { vertical-align: top }
	`)
	styled := func(class, style string) []LayoutElement {
		return []LayoutElement{{Name: "td", Class: class, Style: style}}
	}
	testdata := []struct {
		name  string
		chain []LayoutElement
		key   string
		want  string
	}{
		{"style over rule", styled("", "color: green"), "color", "green"},
		{"style over specific rule", []LayoutElement{{Name: "td", Class: "y z", ID: "x", Style: "color: green"}}, "color", "green"},
		{"important rule over style", styled("imp", "color: green"), "color", "red"},
		{"important style over important rule", styled("imp", "color: green !important"), "color", "green"},
		{"shorthand in style", styled("", "border: 1pt solid red"), "border-left-color", "red"},
		{"style shorthand over rule longhand", styled("", "padding: 3pt"), "padding-top", "3pt"},
		{"var() in style", styled("", "color: var(--accent)"), "color", "green"},
		{"custom property in style", styled("", "--c: olive; color: var(--c)"), "color", "olive"},
		{"attribute selector", styled("", "color: green"), "vertical-align", "top"},
		{"other elements unaffected", []LayoutElement{{Name: "tr", Style: "color: green"}, elt("td", "", "")}, "color", "red"},
	}
	for _, tc := range testdata {
		t.Run(tc.name, func(t *testing.T) {
			decls, _ := ls.Match(tc.chain, "")
			if got := decls[tc.key]; got != tc.want {
				t.Errorf("%s = %q, want %q", tc.key, got, tc.want)
			}
		})
	}
	_, important := ls.Match(styled("", "color: green !important"), "")
	if !important["color"] {
		t.Errorf("important = %v", important)
	}
	// custom properties of the style attribute are inherited
	decls, _ := ls.Match([]LayoutElement{{Name: "tr", Style: "--c: navy"}, {Name: "td", Style: "color: var(--c)"}}, "")
	if decls["color"] != "navy" {
		t.Errorf("inherited custom property: color = %q", decls["color"])
	}
	// no rules at all
	empty := NewLayoutStylesheet()
	decls, _ = empty.Match(styled("", "color: green"), "")
	if decls["color"] != "green" {
		t.Errorf("without stylesheet: color = %q", decls["color"])
	}
	// no style for the pseudo element
	decls, _ = ls.Match(styled("", "color: green"), "marker")
	if decls["color"] != "" {
		t.Errorf("pseudo element: color = %q", decls["color"])
	}
}
