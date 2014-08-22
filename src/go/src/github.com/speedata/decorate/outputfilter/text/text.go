// Sample output filter (basicly a no-op).
package text

import (
	"github.com/speedata/decorate/processor"
)

func init() {
	processor.RegisterOutputFilter("text", Render)
}

func Render(in chan processor.Token, out chan string) {
	for {
		select {
		case t, ok := <-in:
			if ok {
				out <- t.Value
			} else {
				close(out)
				return
			}
		}
	}
}
