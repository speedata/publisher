package css

import (
	"log/slog"
	"strings"

	"github.com/andybalholm/cascadia"
)

// splitSelectorList splits a selector list at the commas on the top level,
// that is not inside parentheses, brackets or strings.
func splitSelectorList(list string) []string {
	var parts []string
	depth := 0
	var quote rune
	escaped := false
	start := 0
	for i, r := range list {
		switch {
		case escaped:
			escaped = false
		case r == '\\':
			escaped = true
		case quote != 0:
			if r == quote {
				quote = 0
			}
		case r == '"' || r == '\'':
			quote = r
		case r == '(' || r == '[':
			depth++
		case r == ')' || r == ']':
			if depth > 0 {
				depth--
			}
		case r == ',' && depth == 0:
			parts = append(parts, list[start:i])
			start = i + 1
		}
	}
	return append(parts, list[start:])
}

// isShadowDOMSelector reports whether sel uses one of the Shadow DOM
// pseudo-classes (:host, :host(), :host-context()). They only match inside
// a shadow tree in a browser, so they never match here.
func isShadowDOMSelector(sel string) bool {
	return strings.Contains(sel, ":host")
}

// parseSelectorGroup parses a selector list such as "h1, h2.title". A
// selector the parser does not understand is skipped, the others apply.
// Stylesheets written for browsers often contain selectors like
// ":root, :host"; dropping the whole rule would lose ":root". Shadow DOM
// selectors are skipped silently, other unknown selectors are reported as
// a warning.
func parseSelectorGroup(list string) cascadia.SelectorGroup {
	if group, err := cascadia.ParseGroupWithPseudoElements(list); err == nil {
		return group
	}
	var group cascadia.SelectorGroup
	for _, part := range splitSelectorList(list) {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		sel, err := cascadia.ParseWithPseudoElement(part)
		if err != nil {
			if isShadowDOMSelector(part) {
				slog.Debug("CSS: selector never matches, ignored", "selector", part)
			} else {
				slog.Warn("CSS: cannot parse selector, ignored", "selector", part, "msg", err.Error())
			}
			continue
		}
		group = append(group, sel)
	}
	return group
}
