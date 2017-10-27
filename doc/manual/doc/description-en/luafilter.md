title: Pre-processing with a Lua filter
---

The ability to run a Lua script before the publishing run is available since version 3.1.9.

The command line/configuration interface is the same as for the XProc filter:

    sp --filter myfile.lua

or

    filter=myfile.lua


The Lua script is run before any rendering gets done, so the main application is probably the transformation of input data into a format that is suitable for the speedata Publisher.

You can use anything that is allowed in Lua.
Additionally the publisher provides the module `runtime` which contains the following entries:

Value | Description
------|-------------
`projectdir` | A value that contains the current working directory (the one with the `layout.xml` and `publisher.cfg`)
`run_saxon`  | A function that calls the external Java-program `saxon`. It accepts three mandatory arguments (the transformation stylesheet, the input file and the output file) and an optional argument that is passed as the parameter string to saxon. The function returns a boolean value (success) and optionally a string in case of a `false` success value.


    ok, err = runtime.run_saxon("transformation.xsl","source.xml","data.xml","param1=value1 param2=value2")

    -- stop the publishing process if an error occurs
    if not ok then
        print(err)
        os.exit(-1)
    end

