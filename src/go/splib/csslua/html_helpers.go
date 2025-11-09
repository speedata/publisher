package csslua

import (
	"regexp"
	"strings"

	"golang.org/x/net/html"
)

// --- Whitespace helpers (mirrored from your old code) ---

var (
	reLeadcloseWhtsp = regexp.MustCompile(`^[\s\p{Zs}]+|[\s\p{Zs}]+$`)
	reInsideWS       = regexp.MustCompile(`\n|[\s\p{Zs}]{2,}`)
	isSpace          = regexp.MustCompile(`^\s*$`)
	zeroDimen        = regexp.MustCompile(`^0+(px|mm|cm|in|pt|pc|ch|em|ex|lh|rem)?$`)
)

func normalizeText(s string, preserve bool) string {
	if preserve {
		return s
	}
	if isSpace.MatchString(s) {
		return " "
	}
	s = reLeadcloseWhtsp.ReplaceAllString(s, " ")
	s = reInsideWS.ReplaceAllString(s, " ")
	if isSpace.MatchString(s) {
		return ""
	}
	return s
}

// --- Block/Inline classification (same as in your dumper) ---

var blockSet = map[string]struct{}{
	"address": {}, "article": {}, "aside": {}, "audio": {}, "video": {},
	"blockquote": {}, "canvas": {}, "dd": {}, "div": {}, "dl": {},
	"fieldset": {}, "figcaption": {}, "figure": {}, "footer": {}, "form": {},
	"h1": {}, "h2": {}, "h3": {}, "h4": {}, "h5": {}, "h6": {},
	"header": {}, "hgroup": {}, "hr": {}, "noscript": {}, "ol": {},
	"output": {}, "p": {}, "pre": {}, "section": {}, "table": {},
	"tfoot": {}, "ul": {},
}

var inlineishSet = map[string]struct{}{
	"b": {}, "big": {}, "i": {}, "small": {}, "tt": {},
	"abbr": {}, "acronym": {}, "cite": {}, "code": {}, "dfn": {},
	"em": {}, "kbd": {}, "strong": {}, "samp": {}, "var": {},
	"a": {}, "bdo": {}, "img": {}, "map": {}, "object": {},
	"q": {}, "script": {}, "span": {}, "sub": {}, "sup": {},
	"button": {}, "input": {}, "label": {}, "select": {}, "textarea": {},
}

func isBlockElement(name string) bool {
	_, ok := blockSet[strings.ToLower(name)]
	if name == "body" || name == "table" || name == "thead" || name == "tbody" || name == "tr" || name == "td" || name == "th" || name == "tfoot" || name == "ul" || name == "ol" || name == "li" || name == "main" || name == "nav" || name == "section" || name == "article" || name == "aside" || name == "figure" || name == "figcaption" || name == "video" || name == "canvas" || name == "address" || name == "blockquote" || name == "br" || name == "form" || name == "footer" || name == "header" || name == "hr" || name == "pre" {
		ok = true
	}
	return ok
}

func isInlineishElement(name string) bool {
	_, ok := inlineishSet[strings.ToLower(name)]
	return ok
}

// --- hasBorder (copied logic using expanded styles) ---

func hasBorder(styles map[string]string) bool {
	sides := []string{"top", "right", "bottom", "left"}
	for _, loc := range sides {
		wKey := "border-" + loc + "-width"
		sKey := "border-" + loc + "-style"
		if wd, ok := styles[wKey]; ok {
			if st, ok2 := styles[sKey]; ok2 && st != "none" {
				if !zeroDimen.MatchString(wd) {
					return true
				}
			}
		}
	}
	return false
}

// --- Minimal stubs to reuse your existing functions from the css package ---
// If you already expose these in css, remove these stubs and import them instead.

type tokenstream = []struct {
	Type  int
	Value string
}

func resolveAttributes(attrs []html.Attribute) (map[string]string, map[string]string) {
	// Prefer importing csspkg.resolveAttributes; we place a stub to show the call site.
	// Delete this stub and import the real function if it's exported.
	return map[string]string{}, map[string]string{}
}

func papersize(typ string) (string, string) {
	typ = strings.ToLower(typ)
	var width, height string
	portrait := true
	for i, e := range strings.Fields(typ) {
		switch e {
		case "portrait":
			// good, nothing to do
		case "landscape":
			portrait = false
		case "a5":
			width = "148mm"
			height = "210mm"
		case "a4":
			width = "210mm"
			height = "297mm"
		case "a3":
			width = "297mm"
			height = "420mm"
		case "b5":
			width = "176mm"
			height = "250mm"
		case "b4":
			width = "250mm"
			height = "353mm"
		case "jis-b5":
			width = "182mm"
			height = "257mm"
		case "jis-b4":
			width = "257mm"
			height = "364mm"
		case "letter":
			width = "8.5in"
			height = "11in"
		case "legal":
			width = "8.5in"
			height = "14in"
		case "ledger":
			width = "11in"
			height = "17in"
		default:
			if i == 0 {
				width = e
				height = e
			} else {
				height = e
			}
		}
	}

	if portrait {
		return width, height
	}
	return height, width
}
