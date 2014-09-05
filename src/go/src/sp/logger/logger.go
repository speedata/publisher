package logger

import (
	"fmt"
	"os"
)

var trace bool

func Trace(a ...interface{}) {
	if trace {
		fmt.Print("   -|")
		fmt.Println(a...)
		os.Stdout.Sync()
	}
}
