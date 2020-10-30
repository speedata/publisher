module main

replace sp v0.0.0 => ./src/go/sp

replace sp/sp v0.0.0 => ./src/go/sp/sp

replace sphelper v0.0.0 => ./src/go/sphelper

replace splib v0.0.0 => ./src/go/splib

replace splibaux v0.0.0 => ./src/go/splibaux

replace css v0.0.0 => ./src/go/css

replace internal/github-css/scanner v0.0.0 => ./src/go/css/internal/github-css/scanner

go 1.11

require (
	github.com/speedata/css/scanner v0.0.0-20201002105008-5a0a811b34fe // indirect
	github.com/speedata/sdbidi v0.0.0-20201030124501-2f58e192d2d8 // indirect
	sp/sp v0.0.0 // indirect
	sphelper v0.0.0 // indirect
	splib v0.0.0 // indirect
	splibaux v0.0.0 // indirect
)
