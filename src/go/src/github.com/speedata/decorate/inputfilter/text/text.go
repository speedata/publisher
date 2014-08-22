// Sample input filter (basicly a no-op)
package text

import (
	"github.com/speedata/decorate/processor"
)

func init() {
	processor.RegisterInputFilter("text", Highlight)
}

// Highlight is called once for every input file.
func Highlight(data []byte, out chan processor.Token) {
	tok := processor.Token{}
	tok.Major = processor.MAJOR_RAW
	tok.Minor = processor.MINOR_RAW
	tok.Value = string(data)
	out <- tok
	close(out)
}
