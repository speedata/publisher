// Package html is an output filter to generate an html chunk wrapped in a
// div to be highlighted by CSS.
// A sample output is
//    <div class="highlight"><pre><span class="name ntag">&lt;root&gt;</span>
//      <span class="name ntag">&lt;child</span> <span class="name ntag">/&gt;</span>
//    <span class="name ntag">&lt;/root&gt;</span>
//    </pre></div>
// Which requires a suitable CSS file.
//
// Note that this package does not export any symbols, as it actively registers
// at the process package with
//     processor.RegisterOutputFilter("html", Render)
// in the init function. Render
//     (f filter) Render(t processor.Tokenizer) string
package html

import (
	"fmt"
	"github.com/speedata/decorate/processor"
	"html"
	"strings"
)

func init() {
	processor.RegisterOutputFilter("html", Render)
}

// Gets called when the user requests HTML output
func Render(in chan processor.Token, out chan string) {
	classes_major := map[processor.TypeMajor]string{
		processor.MAJOR_COMMENT:  "c",
		processor.MAJOR_STRING:   "s",
		processor.MAJOR_ERROR:    "err",
		processor.MAJOR_GENERIC:  "gen",
		processor.MAJOR_KEYWORD:  "kw",
		processor.MAJOR_NAME:     "name",
		processor.MAJOR_NUMBER:   "num",
		processor.MAJOR_VARIABLE: "var",
		processor.MAJOR_OPERATOR: "op",
	}
	classes_minor := map[processor.TypeMinor]string{
		processor.MINOR_NAME_ATTRIBUTE: "natt",
		processor.MINOR_NAME_TAG:       "ntag",
	}

	out <- fmt.Sprint(`<div class="highlight"><pre>`)
	var cls string

	for {
		select {
		case t, ok := <-in:
			if ok {
				if t.Major == processor.MAJOR_RAW {
					out <- html.EscapeString(t.Value)
				} else {
					if t.Minor == processor.MINOR_RAW {
						cls = classes_major[t.Major]
					} else {
						cls = strings.Join([]string{classes_major[t.Major], classes_minor[t.Minor]}, " ")
					}

					out <- fmt.Sprintf(`<span class="%s">%s</span>`, cls, html.EscapeString(t.Value))
				}
			} else {
				out <- fmt.Sprint(`</pre></div>`)
				close(out)
				return
			}
		}
	}
}
