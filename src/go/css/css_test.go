package css

import "testing"

func TestConsumeBlockCommentBeforeAtRule(t *testing.T) {
	for _, s := range []string{
		"a { color: black }\n  /* comment */\n  @font-face { src: url(\"a.ttf\"); }\n  .c { color: red }",
		"a { color: black } /* one */ /* two */ @font-face { src: url(\"a.ttf\"); } .c { color: red }",
		"a {} @font-face { src: url(\"a.ttf\"); } .c { color: red }",
	} {
		block := consumeBlock(parseCSSString(s), false)
		if len(block.ChildAtRules) != 1 || block.ChildAtRules[0].Name != "font-face" {
			t.Errorf("%q: got %d at-rules, want @font-face", s, len(block.ChildAtRules))
		}
		var selectors []string
		for _, b := range block.Blocks {
			selectors = append(selectors, sourceString(b.ComponentValues))
		}
		if selectors[len(selectors)-1] != ".c" {
			t.Errorf("%q: got selectors %q, want .c last", s, selectors)
		}
	}
}
