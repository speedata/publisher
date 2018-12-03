module main

require (
	configurator v0.0.0
	fsnotify v0.0.0
	github.com/google/btree v0.0.0-20180813153112-4030bb1f1f0c // indirect
	github.com/gorilla/mux v1.6.2
	github.com/gregjones/httpcache v0.0.0-20181110185634-c63ab54fda8f
	github.com/peterbourgon/diskv v2.0.1+incompatible // indirect
	github.com/speedata/goxlsx v1.0.1
	github.com/speedata/optionparser v1.0.0
	github.com/yuin/gopher-lua v0.0.0-20181109042959-a0dfe84f6227
	golang.org/x/text v0.3.0

	hotfolder v0.0.0
	sp v0.0.0
	sphelper v0.0.0
	splib v0.0.0
	splibaux v0.0.0
)

replace configurator v0.0.0 => ./src/go/configurator

replace fsnotify v0.0.0 => ./src/go/fsnotify

replace hotfolder v0.0.0 => ./src/go/hotfolder

replace sp v0.0.0 => ./src/go/sp

replace sphelper v0.0.0 => ./src/go/sphelper

replace splib v0.0.0 => ./src/go/splib

replace splibaux v0.0.0 => ./src/go/splibaux
