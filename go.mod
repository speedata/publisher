module main

replace sp v0.0.0 => ./src/go/sp

replace sp/sp v0.0.0 => ./src/go/sp/sp

replace sphelper v0.0.0 => ./src/go/sphelper

replace splib v0.0.0 => ./src/go/splib

replace splibaux v0.0.0 => ./src/go/splibaux

replace css v0.0.0 => ./src/go/css

replace internal/github-css/scanner v0.0.0 => ./src/go/css/internal/github-css/scanner


require (
	sp/sp v0.0.0 // indirect
	sphelper v0.0.0 // indirect
	splib v0.0.0 // indirect
	splibaux v0.0.0 // indirect
	internal/github-css/scanner v0.0.0 // indirect
)

go 1.11
