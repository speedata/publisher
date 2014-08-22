// Merge two adjacent tokens with the same major and minor number into one token.
package removeduplicates

import (
	"github.com/speedata/decorate/processor"
)

func init() {
	processor.RegisterSanitizer("removeduplicates", Filter)
}

func Filter(in chan processor.Token, out chan processor.Token) {
	prev := processor.Token{}

	for {
		select {
		case x, ok := <-in:
			if x.Major == prev.Major && x.Minor == prev.Minor {
				prev.Value = prev.Value + x.Value
			} else {
				out <- prev
				prev = x
			}
			if !ok {
				out <- prev
				close(out)
				return
			}
		}
	}
}
