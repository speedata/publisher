package css

import (
	"fmt"
	"strings"
)

func w(a ...interface{}) {
	fmt.Println(a...)
}

func indent(s string) string {
	ret := []string{}
	for _, line := range strings.Split(s, "\n") {
		ret = append(ret, "    "+line)
	}
	return strings.Join(ret, "\n")
}

func (b sBlock) String() string {
	ret := []string{}
	var firstline string
	if b.Name != "" {
		firstline = fmt.Sprintf("@%s ", b.Name)
	}
	firstline = firstline + b.ComponentValues.String() + " {"
	ret = append(ret, firstline)
	for _, v := range b.Rules {
		ret = append(ret, "    "+v.Key.String()+":"+v.Value.String()+";")
	}
	for _, v := range b.ChildAtRules {
		ret = append(ret, indent(v.String()))
	}
	for _, v := range b.Blocks {
		ret = append(ret, indent(v.String()))
	}
	ret = append(ret, "}")
	return strings.Join(ret, "\n")
}

func (t tokenstream) String() string {
	ret := []string{}
	for _, tok := range t {
		ret = append(ret, tok.Value)
	}
	return strings.Join(ret, "")
}

func (c *CSS) dump() {
	w("CSS +++++++")
	for name, ff := range c.Fontfamilies {
		w(" Font family", name)
		w("    Regular: ", ff.Regular)
		w("    Italic: ", ff.Italic)
		w("    Bold: ", ff.Bold)
		w("    BoldItalic: ", ff.BoldItalic)
	}
	for name, pg := range c.Pages {
		w(" Page", name)
		w("   Size", pg.papersize)
		attributes := resolveAttributes(pg.attributes)
		w("   Margin: ", attributes["margin-top"], attributes["margin-right"], attributes["margin-bottom"], attributes["margin-left"])
		for areaname, rules := range pg.pagearea {
			w("   @", areaname)
			for _, rule := range rules {
				w("     ", rule.Key, rule.Value)

			}
		}
	}
	for _, stylesheet := range c.Stylesheet {
		for _, block := range stylesheet.Blocks {
			w("-------")
			w(block)
		}
		w("++++++++++")

	}
}
