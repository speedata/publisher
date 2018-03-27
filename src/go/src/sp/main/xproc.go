package main

import (
	"os"
)

// Return success
func runXProcPipeline(filename string) bool {
	os.Setenv("CLASSPATH", libdir+"/calabash.jar:"+libdir+"/saxon9he.jar")
	cmdline := "java com.xmlcalabash.drivers.Main " + filename
	return (run(cmdline) == 0)
}
