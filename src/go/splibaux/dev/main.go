package main

import (
	"fmt"
	"log"

	"speedatapublisher/splibaux"
)

func dothings() error {
	fmt.Println("Hello from dothings()")
	csstext := `    .foo { color: green }
	.bar { color: rgb(103, 103, 232) }
 `
	htmltext := `<p>bla bla bla</p>
	<p>fo<span class="foo">foo</span></p>`
	tab, err := splibaux.ParseHTMLText(htmltext, csstext)
	if err != nil {
		return err
	}
	fmt.Println(tab)
	return nil
}

func main() {
	err := dothings()
	if err != nil {
		log.Fatal(err)
	}
}
