// Just a dummy filter do demonstrate the sanitizers
package noop

import (
	"github.com/speedata/decorate/processor"
)

func init() {
	processor.RegisterSanitizer("noop", Filter)
}

func Filter(in chan processor.Token, out chan processor.Token) {
	for {
		select {
		case x, ok := <-in:
			out <- x
			if !ok {
				close(out)
				return
			}
		}
	}
}
