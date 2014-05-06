package main

import (
	"gomddoc"
	"log"
	"optionparser"
)

var (
	version string
)

func main() {
	var (
		root    string
		basedir string
		dest    string
	)
	op := optionparser.NewOptionParser()
	op.On("--source DIR", "source directory", &root)
	op.On("--dest DIR", "destination directory", &dest)
	op.On("--base DIR", "base directory", &basedir)
	err := op.Parse()
	if err != nil {
		log.Fatal(err)
	}

	mkdoc, err := gomddoc.NewMDDoc(root, dest, basedir)
	if err != nil {
		log.Fatal(err)
	}
	mkdoc.Version = version
	err = mkdoc.DoThings()
	if err != nil {
		log.Fatal(err)
	}
}
