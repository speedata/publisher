package css

import (
	"errors"
	"fmt"
	"log/slog"
	"maps"
	"strings"
)

// CSS custom properties (--name: value) and var(). The values are handled
// as source text (see sourceString), because stringValue does not keep
// "--name" intact.
//
// A declaration that cannot be resolved (undefined variable without a
// fallback, or a cycle) is dropped: whatever applies without it takes
// effect. This differs from the browser behavior ("invalid at computed-value
// time"), see doc/CSS-PLAN.md, decision V3.

// varDecl is a custom property declaration in cascade order.
type varDecl struct {
	name  string
	value string
}

// varError describes why a value could not be resolved.
type varError struct {
	name  string // the variable
	cycle bool   // true: part of a cycle, false: undefined
}

// declError is a custom property declaration that was dropped.
type declError struct {
	property string
	err      error
}

func (e *declError) Error() string {
	return e.property + ": " + e.err.Error()
}

func (e *declError) Unwrap() error {
	return e.err
}

func (e *varError) Error() string {
	if e.cycle {
		return fmt.Sprintf("variable %s is part of a cycle", e.name)
	}
	return fmt.Sprintf("undefined variable %s", e.name)
}

// isCustomProperty reports whether the property name is a custom property.
func isCustomProperty(name string) bool {
	return len(name) > 2 && strings.HasPrefix(name, "--")
}

// hasVar reports whether the value contains a var() reference.
func hasVar(value string) bool {
	return strings.Contains(strings.ToLower(value), "var(")
}

// isNameChar reports whether c can be part of a CSS identifier.
func isNameChar(c byte) bool {
	return c == '-' || c == '_' || c >= '0' && c <= '9' || c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= 0x80
}

// findVar returns the position of the next var( in s at or after start, or
// -1.
func findVar(s string, start int) int {
	lower := strings.ToLower(s)
	for {
		i := strings.Index(lower[start:], "var(")
		if i < 0 {
			return -1
		}
		i += start
		if i == 0 || !isNameChar(s[i-1]) {
			return i
		}
		start = i + 4
	}
}

// closingParen returns the position of the parenthesis that closes the one
// before position start, and the position of the first comma at the same
// level (-1 if there is none). Strings are skipped.
func closingParen(s string, start int) (int, int) {
	depth := 0
	comma := -1
	var quote byte
	for i := start; i < len(s); i++ {
		c := s[i]
		switch {
		case quote != 0:
			if c == '\\' {
				i++
			} else if c == quote {
				quote = 0
			}
		case c == '"' || c == '\'':
			quote = c
		case c == '(':
			depth++
		case c == ')':
			if depth == 0 {
				return i, comma
			}
			depth--
		case c == ',' && depth == 0 && comma < 0:
			comma = i
		}
	}
	return -1, comma
}

// substituteVars replaces every var() in value. lookup returns the value of
// a variable. A fallback is used when the variable is undefined.
func substituteVars(value string, lookup func(string) (string, error)) (string, error) {
	var b strings.Builder
	pos := 0
	for {
		i := findVar(value, pos)
		if i < 0 {
			b.WriteString(value[pos:])
			return b.String(), nil
		}
		b.WriteString(value[pos:i])
		argstart := i + 4
		end, comma := closingParen(value, argstart)
		if end < 0 {
			return "", fmt.Errorf("missing ) in %q", value)
		}
		nameEnd := end
		if comma >= 0 {
			nameEnd = comma
		}
		name := strings.TrimSpace(value[argstart:nameEnd])
		if !isCustomProperty(name) {
			return "", fmt.Errorf("invalid variable name %q in %q", name, value)
		}
		replacement, err := lookup(name)
		if err != nil {
			var ve *varError
			if comma < 0 || !errors.As(err, &ve) || ve.cycle {
				return "", err
			}
			// undefined: use the fallback, which may contain var() itself
			replacement, err = substituteVars(strings.TrimSpace(value[comma+1:end]), lookup)
			if err != nil {
				return "", err
			}
		}
		b.WriteString(replacement)
		pos = end + 1
	}
}

// varFrame is a declaration being resolved, for cycle detection.
type varFrame struct {
	name   string
	cyclic bool
}

// varResolver computes the custom properties of an element.
type varResolver struct {
	inherited map[string]string
	declared  map[string][]string // all declarations per name, cascade order
	result    map[string]string
	done      map[string]bool
	stack     []*varFrame
	errors    []error
}

func (r *varResolver) lookup(name string) (string, error) {
	decls, own := r.declared[name]
	if !own {
		if v, ok := r.inherited[name]; ok {
			return v, nil
		}
		return "", &varError{name: name}
	}
	for i, f := range r.stack {
		if f.name == name {
			// a cycle: every declaration from there on is part of it
			for _, g := range r.stack[i:] {
				g.cyclic = true
			}
			return "", &varError{name: name, cycle: true}
		}
	}
	if !r.done[name] {
		r.resolve(name, decls)
	}
	if v, ok := r.result[name]; ok {
		return v, nil
	}
	return "", &varError{name: name}
}

// resolve tries the declarations of name, the last one first. If none can
// be resolved, the inherited value (if any) applies.
func (r *varResolver) resolve(name string, decls []string) {
	r.done[name] = true
	for i := len(decls) - 1; i >= 0; i-- {
		frame := &varFrame{name: name}
		r.stack = append(r.stack, frame)
		v, err := substituteVars(decls[i], r.lookup)
		r.stack = r.stack[:len(r.stack)-1]
		if frame.cyclic {
			err = &varError{name: name, cycle: true}
		}
		if err == nil {
			r.result[name] = v
			return
		}
		r.errors = append(r.errors, &declError{property: name, err: err})
	}
	if v, ok := r.inherited[name]; ok {
		r.result[name] = v
	} else {
		delete(r.result, name)
	}
}

// computeVars returns the custom properties of an element: the inherited
// ones, overridden by the element's own declarations (in cascade order, the
// last one wins). The inherited map is not changed and returned as is if
// the element has no declarations of its own. The errors describe dropped
// declarations.
func computeVars(inherited map[string]string, own []varDecl) (map[string]string, []error) {
	if len(own) == 0 {
		return inherited, nil
	}
	r := &varResolver{
		inherited: inherited,
		declared:  map[string][]string{},
		result:    make(map[string]string, len(inherited)+len(own)),
		done:      map[string]bool{},
	}
	maps.Copy(r.result, inherited)
	for _, d := range own {
		r.declared[d.name] = append(r.declared[d.name], d.value)
	}
	for _, d := range own {
		if !r.done[d.name] {
			r.resolve(d.name, r.declared[d.name])
		}
	}
	return r.result, r.errors
}

// resolveValue replaces the var() references of a property value with the
// values from vars.
func resolveValue(value string, vars map[string]string) (string, error) {
	return substituteVars(value, func(name string) (string, error) {
		if v, ok := vars[name]; ok {
			return v, nil
		}
		return "", &varError{name: name}
	})
}

// warnDropped warns about a dropped declaration, each message only once
// (warned keeps the messages given). Without property, the property is
// taken from a declError.
func warnDropped(warned map[string]bool, property string, err error) {
	var de *declError
	if property == "" && errors.As(err, &de) {
		property, err = de.property, de.err
	}
	msg := property + ": " + err.Error()
	if warned[msg] {
		return
	}
	warned[msg] = true
	if property == "" {
		slog.Warn("CSS: declaration ignored", "reason", err.Error())
	} else {
		slog.Warn("CSS: declaration ignored", "property", property, "reason", err.Error())
	}
}
