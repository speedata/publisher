goxlsx
======

Excel-XML reader for Go

Installation
------------
    go get github.com/speedata/goxlsx


Usage example
-------------
````go
package main

import (
    "fmt"
    "github.com/speedata/goxlsx"
    "log"
)

func main() {
    excelfile := "Worksheet1.xlsx"
    spreadsheet, err := goxlsx.OpenFile(excelfile)
    if err != nil {
        log.Fatal(err)
    }
    ws1, err := spreadsheet.GetWorksheet(0)
    if err != nil {
        log.Fatal(err)
    }
    fmt.Println(ws1.Name)
    fmt.Printf("Spreadsheet 0 (%s) starts at (%d,%d) and extends to (%d,%d)\n", ws1.Name, ws1.MinColumn, ws1.MinRow, ws1.MaxColumn, ws1.MaxRow)
    fmt.Println(ws1.Cell(ws1.MinColumn, ws1.MinRow))
    fmt.Println(ws1.Cell(3, 3))

}
````

Other:
-----

Status: usable<br>
Maturity level: 1/5 (expect changes!)<br>
Supported/maintained: yes<br>
Contribution welcome: yes (pull requests, issues)<br>
Main page: https://github.com/speedata/goxlsx<br>
License: MIT<br>
Contact: gundlach@speedata.de<br>
