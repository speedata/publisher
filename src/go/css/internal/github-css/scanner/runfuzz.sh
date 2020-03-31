#!/bin/bash

set -e

if [ $(which go-fuzz) == '' ]; then
echo Updating go-fuzz....
go get -u github.com/dvyukov/go-fuzz/go-fuzz
fi
if [ $(which go-fuzz-build) == '' ]; then
echo Updating go-fuzz-build...
go get -u github.com/dvyukov/go-fuzz/go-fuzz-build
fi

echo Building fuzz build
rm -f *\#*go* .\#*go
go-fuzz-build github.com/thejerf/css/scanner

mkdir -p fuzz/corpus
cp -r samples/* fuzz/corpus

go-fuzz -bin=./scanner-fuzz.zip -workdir=fuzz

