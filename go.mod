module main

replace sp v0.0.0 => ./src/go/sp

replace sp/sp v0.0.0 => ./src/go/sp/sp

replace sphelper v0.0.0 => ./src/go/sphelper

replace splib v0.0.0 => ./src/go/splib

replace splibaux v0.0.0 => ./src/go/splibaux


require (
	sp/sp v0.0.0 // indirect
	sphelper v0.0.0 // indirect
	splib v0.0.0 // indirect
	splibaux v0.0.0 // indirect
)
