// Sample output filter for debugging purpose.
package debug

import (
	"fmt"
	"github.com/speedata/decorate/processor"
)

func init() {
	processor.RegisterOutputFilter("debug", Render)
}

// Gets called when the user requests debug output
func Render(in chan processor.Token, out chan string) {
	tagnames := map[processor.TypeMajor]string{
		processor.MAJOR_RAW:      "raw",
		processor.MAJOR_COMMENT:  "comment",
		processor.MAJOR_STRING:   "string",
		processor.MAJOR_ERROR:    "error",
		processor.MAJOR_GENERIC:  "generic",
		processor.MAJOR_KEYWORD:  "keyword",
		processor.MAJOR_NAME:     "name",
		processor.MAJOR_NUMBER:   "number",
		processor.MAJOR_VARIABLE: "variable",
	}

	for {
		select {
		case t, ok := <-in:
			if ok {
				out <- fmt.Sprintf("%-5s: %q\n", tagnames[t.Major], t.Value)
			} else {
				close(out)
				return
			}
		}
	}
}
