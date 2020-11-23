module sp/sp

require (
	github.com/cjoudrey/gluahttp v0.0.0-20190104103309-101c19a37344
	github.com/speedata/configurator v0.0.0-20181204130920-092f848de8e1
	github.com/speedata/goxlsx v1.0.1
	github.com/speedata/hotfolder v0.0.0-20181204121114-5f743a840a92
	github.com/speedata/optionparser v1.0.0
	github.com/yuin/gopher-lua v0.0.0-20181109042959-a0dfe84f6227
	golang.org/x/text v0.3.0
	sp v0.0.0
	sp/server v0.0.0
	splibaux v0.0.0
)

replace sp/server => ../server

replace sp v0.0.0 => ../../sp

replace splibaux => ../../splibaux

replace css => ../../css

go 1.11
