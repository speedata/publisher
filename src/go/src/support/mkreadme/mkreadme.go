package main

import (
	"fmt"
	"os"
	"path/filepath"
	"text/template"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Not enough arguments, use `mkreadme <os> <destdir>'.")
		fmt.Println("Where <os> is one of 'linux', 'darwin' or 'windows'.")
		os.Exit(-1)
	}
	t := template.Must(template.ParseFiles("doc/installation.txt"))
	data := struct {
		Os string
	}{
		os.Args[1],
	}

	w, err := os.OpenFile(filepath.Join(os.Args[2], "installation.txt"), os.O_WRONLY|os.O_TRUNC|os.O_CREATE, 0644)
	if err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}

	err = t.Execute(w, data)
	if err != nil {
		fmt.Println(err)
		os.Exit(-1)
	}
}
