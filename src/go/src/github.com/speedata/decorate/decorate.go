// The package decorate is used to highlight code by passing it though an input filter and output filter.
// Both filters can be configured.
//     code -> input filter -> (intermediate format) -> output filter -> output
// for example
//     code.xml -> xml lexer -> html renderer -> output.html
// The intermediate format is not visible to the user and only used as a protocol between
// the input and output filter.
package decorate

import (
	"github.com/speedata/decorate/processor"
	"io/ioutil"

	// all input filters
	_ "github.com/speedata/decorate/inputfilter/lua"
	_ "github.com/speedata/decorate/inputfilter/text"
	_ "github.com/speedata/decorate/inputfilter/xml"

	// and all output filters
	_ "github.com/speedata/decorate/outputfilter/debug"
	_ "github.com/speedata/decorate/outputfilter/html"
	_ "github.com/speedata/decorate/outputfilter/text"

	// and the sanitzers
	_ "github.com/speedata/decorate/sanitizer/removeduplicates"
)

// Return a list of input filters (lexers).
func InputFilters() []string {
	return processor.InputFilters()
}

// Return a list of output filters (renderer)
func OutputFilters() []string {
	return processor.OutputFilters()
}

func Highlight(data []byte, inputfilter string, outputfilter string) (string, error) {
	ret, err := processor.Highlight(inputfilter, outputfilter, data)
	if err != nil {
		return "", err
	}
	return ret, nil
}

// Return a string rendering the given file using the outputfilter and running the inputfilter as a lexer.
func HighlightFile(filename string, inputfilter string, outputfilter string) (string, error) {
	data, err := ioutil.ReadFile(filename)
	if err != nil {
		return "", err
	}
	ret, err := processor.Highlight(inputfilter, outputfilter, data)
	if err != nil {
		return "", err
	}
	return ret, nil
}
