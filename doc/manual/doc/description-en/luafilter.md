title: Pre-processing with a Lua filter
---

The ability to run a Lua script before the publishing run is available since version 3.1.9.

The command line/configuration interface is:

    sp --filter myfile.lua

or

    filter=myfile.lua


The Lua script is run before any rendering gets done, so the main application is probably the transformation of input data into a format that is suitable for the speedata Publisher.

You can use anything that is allowed in Lua.
Additionally the publisher provides the modules `csv, `runtime` and `xml` which contain the following entries:

**Note**: the API is subject to change!

csv
---

`csv.decode(filename,parameter)`: loads a CSV (comma separated values) file and returns (first argument) the boolean success. If true, the second return value contains the table, if false, the second return value contains an error message (string). The value parameter is an optional table which controls the CSV input and output. You can provide the following values:

Value | Description
-----|---------------
charset | If the CSV file is encoded in Latin-1, you have to set this to the value `ISO-8859-1`. Ask us for more character sets.
separator | The value of the field separator. Defaults to a comma, but can be any character.
columns | A table that has the required columns in the given order. For example `{3,2,1}` limits the output to the first three columns in reverse order.

Example:

    csv = require("csv")
    result, msg = csv.decode("myfile.csv", { charset = "ISO-8859-1", separator = ";", columns = {1,2,5} })
    if not result then
        print(msg)
        os.exit(-1)
    end


The table has at index 1..n the rows of the CSV file and each rows is a table in which the index 1..m is each table cell.


runtime
-------

Value | Description
------|-------------
`projectdir` | A value that contains the current working directory (the one with the `layout.xml` and `publisher.cfg`)
`variables`  | A table that contains all the variables given on the command line (`-v`) or in the configuration file (`vars=...`).
`run_saxon`  | A function that calls the external Java-program `saxon`. It accepts three mandatory arguments (the transformation stylesheet, the input file and the output file) and an optional argument that is passed as the parameter string to saxon. The function returns a boolean value (success) and optionally a string in case of a `false` success value.
`validate_relaxng`  | A function that validates an XML file against a RelaxNG schema. The first argument is the XML file, the second argument the RelaxNG schema. You can use relative paths for both.



    runtime = require("runtime")
    ok, err = runtime.run_saxon("transformation.xsl","source.xml","data.xml","param1=value1 param2=value2")

    -- stop the publishing process if an error occurs
    if not ok then
        print(err)
        os.exit(-1)
    end

Validation:

    ok, msg = runtime.validate_relaxng("layout.xml","../schema/layoutschema-de.rng")
    if not ok then
        print(msg)
        os.exit(-1)
    end



xml
---

`xml.encode_table(table)`: Create an XML file from a table. It returns (first argument) the boolean “success”. If false, the second return value contains an error message (string).

The table has the following structure

A comment has the form

    comment = {
             _type = "comment",
             _value = "This is a comment!"
       }

and an element:

    element = {
        ["_type"] = "element",
        ["_name"] = "root",
        attribute1 = "value1",
        attribute2 = "value2",
        child1,
        child2,
        child3,
        ...
    }

`child1`, ... are strings, elements or comments.

The XML file gets written with the name `data.xml`

Example:

    xml = require("xml")
    ok, msg = xml.encode_table(tbl)
    if not ok then
        print(msg)
        os.exit(-1)
    end


xlsx
----

`open(filename)`: loads the given Excel file (file extension `.xlsx`) and in case of success returns an object which can be used to access the contents of the spreadsheet. In case of an error it returns two arguments. The first argument is `false` and the second argument contains the error message.

Usage:

    xlsx = require("xlsx")
    spreadsheet, err = xlsx.open("myfile.xlsx")
    if not spreadsheet then
        print(err)
        os.exit(-1)
    end


The object `spreadsheet` contains the worksheets. The number of worksheets can be obtained by the length operator (#) and each worksheet is indexed stating from one:

    numWorksheets = #spreadsheet
    ws = spreadsheet[1]

The object `ws` can be used to get the contents of each cell.
Use the object as a function call with the coordinates as the arguments.
It returns the cell contents as a string.
The top left cell has the coordinate (1,1), the first cell in the second row (1,2) and so on.

    cell1 = ws(1,1)
    cell2 = ws(1,2)

Some properties can be queried in the worksheet object:

Value    | Description
--------|-------------
minrow  | First row that contains data
maxrow  | Last row that contains data
mincol  | First column that contains data
maxcol  | Last column that contains data
name    | Name of the worksheet




