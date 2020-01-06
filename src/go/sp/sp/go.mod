module sp/sp

require (
	github.com/cjoudrey/gluahttp v0.0.0-20190104103309-101c19a37344
	github.com/fsnotify/fsnotify v1.4.7
	github.com/gorilla/context v1.1.1 // indirect
	github.com/gorilla/mux v1.6.2
	github.com/speedata/config v0.0.0-20181203093101-3a3f44982ec4 // indirect
	github.com/speedata/configurator v0.0.0-20181204130920-092f848de8e1
	github.com/speedata/goxlsx v1.0.1
	github.com/speedata/hotfolder v0.0.0-20181204121114-5f743a840a92
	github.com/speedata/optionparser v1.0.0
	github.com/yuin/gopher-lua v0.0.0-20181109042959-a0dfe84f6227
	golang.org/x/sys v0.0.0-20181128092732-4ed8d59d0b35 // indirect
	golang.org/x/text v0.3.0
	sp v0.0.0
)

replace sp v0.0.0 => ../../sp

go 1.11
