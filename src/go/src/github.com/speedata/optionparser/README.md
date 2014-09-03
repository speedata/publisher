optionparser
============

Ruby (OptionParser) like command line arguments processor.

Installation
------------

    go get github.com/speedata/optionparser

Usage
-----

    op := optionparser.NewOptionParser()
    op.On(arguments ...interface{})
    ...
    err := op.Parse()

where `arguments` is one of:

 * `"-a"`: a short argument
 * `"--argument"`: a long argument
 * `"--argument [FOO]"` a long argument with an optional parameter
 * `"--argument FOO"` a long argument with a mandatory parameter
 * `"Some text"`: The description text for the command line parameter
 * `&aboolean`: Set the given boolean to `true` if the argument is given, set to `false` if parameter is prefixed with `no-`, such as `--no-foo`.
 * `&astring`: Set the string to the value of the given parameter
 * `function`: Call the function. The function must have the signature `func()`.
 * `amap[string]string`: Set an entry of the map to the value of the given parameter and the key of the argument.


Example usage
-------------

````go
package main

import (
    "fmt"
    "github.com/speedata/optionparser"
    "log"
)

func myfunc() {
    fmt.Println("myfunc called")
}

func main() {
    var somestring string
    var truefalse bool
    options := make(map[string]string)

    op := optionparser.NewOptionParser()
    op.On("-a", "--func", "call myfunc", myfunc)
    op.On("--bstring FOO", "set string to FOO", &somestring)
    op.On("-c", "set boolean option (try -no-c)", options)
    op.On("-d", "--dlong VAL", "set option", options)
    op.On("-e", "--elong [VAL]", "set option with optional parameter", options)
    op.On("-f", "boolean option", &truefalse)
    op.Command("y", "Run command y")
    op.Command("z", "Run command z")

    err := op.Parse()
    if err != nil {
        log.Fatal(err)
    }
    fmt.Printf("string `somestring' is now %q\n", somestring)
    fmt.Printf("options %v\n", options)
    fmt.Printf("-f %v\n", truefalse)
    fmt.Printf("Extra: %#v\n", op.Extra)
}
````

and the output of `go run main.go -a --bstring foo -c -d somevalue -e x -f y z`

is:

    myfunc called
    string `somestring' is now "foo"
    options map[c:true dlong:somevalue elong:x]
    -f true
    Extra: []string{"y", "z"}
