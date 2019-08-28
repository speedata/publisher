module main

require (
	github.com/google/btree v1.0.0 // indirect
	github.com/gregjones/httpcache v0.0.0-20190611155906-901d90724c79 // indirect
	github.com/peterbourgon/diskv v2.0.1+incompatible // indirect
	github.com/speedata/goxlsx v1.0.1
	sp/sp v0.0.0 // indirect
	sphelper v0.0.0 // indirect
	splib v0.0.0 // indirect
	splibaux v0.0.0 // indirect
)

replace sp v0.0.0 => ./src/go/sp

replace sp/sp v0.0.0 => ./src/go/sp/sp

replace sphelper v0.0.0 => ./src/go/sphelper

replace splib v0.0.0 => ./src/go/splib

replace splibaux v0.0.0 => ./src/go/splibaux
