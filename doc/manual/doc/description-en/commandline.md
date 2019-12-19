title: Command line reference
---
Running the speedata publisher on the command line
==================================================

    $ sp --help
    Usage: [parameter] command
    -h, --help                   Show this help
        --autoopen               Open the PDF file (MacOS X and Linux only)
        --data=NAME              Name of the XML data file. Defaults to 'data.xml'. Use '-' for STDIN
        --cache=METHOD           Use cache method. One of 'none', 'fast' or 'optimal'. Default is 'optimal'
        --dummy                  Don't read a data file, use '<data />' as input
    -c, --config=NAME            Read the config file with the given NAME. Default: 'publisher.cfg'
        --[no-]cutmarks          Display cutmarks in the document
    -x, --extra-dir=DIR          Additional directory for file search
        --extra-xml=NAME         Add this file to the layout file
        --filter=FILTER          Run Lua filter before publishing starts
        --grid                   Display background grid. Disable with --no-grid
        --ignore-case            Ignore case when accessing files (on a case-insensitive file system)
        --imagecache=PATH        Set the image cache
        --inkscape=PATH          Set the path to the inkscape program
        --[no-]local             Add local directory to the search path. Default is true
        --layout=NAME            Name of the layout file. Defaults to 'layout.xml'
        --jobname=NAME           The name of the resulting PDF file (without
                                 extension), default is 'publisher'
        --mainlanguage=NAME      The document's main language in locale format,
                                 for example 'en' or 'en_US'.
        --mode=NAME              Set mode. Multiple modes given in a comma separated list.
        --outputdir=DIR          Copy PDF and protocol to this directory
        --prepend-xml=NAME       Add this file in front of the layout file
        --profile                Run publisher with profiling on (internal use)
        --quiet                  Run publisher in silent mode
        --runs=NUM               Number of publishing runs
        --startpage=NUM          The first page number
        --show-gridallocation    Show the allocated grid cells
        --systemfonts            Use system fonts
        --tempdir=DIR            Use this directory instead of the system temporary directory
        --trace                  Show debug messages and some tracing PDF output
        --timeout=SEC            Exit after SEC seconds
    -v, --var=VAR=VALUE          Set a variable for the publishing run
        --varsfile=NAME          Set variables for the publishing run from key=value... file
        --verbose                Print a bit of debugging output
        --version                Show version information
        --wd=DIR                 Change working directory
        --xml                    Output as (pseudo-)XML (for list-fonts)

    Commands
          clean                  Remove publisher generated files
          clearcache             Clear image cache
          compare                Compare files for quality assurance
          doc                    Open documentation
          list-fonts             List installed fonts (use together with --xml for copy/paste)
          run                    Start publishing (default)
          server                 Run as http-api server on port 5266 (configure with --port)
          watch                  Start watchdog / hotfolder


Description of the command line parameters
------------------------------------------

Parameter | Description
----------|------------
`--autoopen` | Opens the PDF file after running the publisher. Can also be set in the [configuration file](configuration.html).
`--data=NAME` | Name of the data XML file. Default is `data.xml`. Can be set in the [configuration file](configuration.html). If the file name is a dash(`-`), the speedata publisher reads the XML data from standard input (STDIN).
`--cache=METHOD` | Caching-strategy for http* image requests. Use `fast` for file system lookup only or `optimal` for http checking on each request. https requests are currently always checked with the `optimal` strategy.
`--cutmarks` | Show cut marks. Can be also configured in the [Layout](../commands-en/options.html).
`--dummy` | Only read the layout rules. A simple data file is assumed which only contains one element: `<data />`. This is for quick testing of layout files.
`-x`, `--extra-dir` | Puts the given directory into the search path. All assets (images, fonts, XML data and layout rules) must be found in the search path, which will be traversed recursively. This parameter can be given multiple times and preset in the [configuration file](configuration.html).
`--extra-xml=NAME` | Add this file to the layout instructions. Similar to inclusion of the file with xinclude.
`--filter=FILTER` | Run the given Lua file.
`--grid` | Show the grid. Can be turned off with `--no-grid`. Can be configured in the layout XML file: [Layout](../commands-en/options.html).
`--ignore-case`|  Ignore case when accessing files (on a case-insensitive file system).
`--inkscape=PATH` | Set the path to the inkscape program, if you need SVG->PDF conversion.
`--layout=NAME` | Name of the layout XML file. Default is `layout.xml`. Can be [configured](configuration.html).
`--[no-]local` | The current directory is (not) added to the search path recursively.The default is `--local` which means that the current directory and all its subdirectories is added to the search path. This allows you to run the publisher in any directory and put your assets in a subdirectory.
`--jobname=NAME` | The name of the output file. Default is `publisher`. The extension(`.pdf`) is added automatically.
`--mainlanguage=NAME` | Set the main language for the document (hyphenation). Allowed values are: `af`, `as`, `bg`, `ca`, `cs`, `cy`, `da`, `de`, `el`, `en`,`en_GB`, `en_US`, `eo`, `es`, `et`, `eu`, `fi`, `fr`, `ga`, `gl`,`gu`, `hi`, `hr`, `hu`, `hy`, `ia`, `id`, `is`, `it`, `ku`, `kn`,`la`, `lo`, `lt`, `ml`, `lv`, `ml`, `mn`, `mr`, `nb`, `nl`, `nn`,`or`, `pa`, `pl`, `pt`, `ro`, `ru`, `sa`, `sk`, `sl`, `sr`, `sv`,`ta`, `te`, `tk`, `tr`, `uk` and `zh`. See also the [language codelist](http://www.loc.gov/standards/iso639-2/php/code_list.php).
`--outputdir=DIR` | Name of the directory of the resulting file. The directory will be created if necessary.
`--prepend-xml=NAME | Indclude this XML file and insert it before processing the main layout file. Can be given multiple times.
`--profile`     |   Run publisher with profiling on (internal use).
`--quiet`     |    Run publisher in silent mode.
`--runs=NUM` | The number of passes. Normally the publisher will process a file only once, but more passes can be necessary if intermediate files are created for generating a table of contents or other document dependent data.
`--show-gridallocation` | Show the allocated grid cells in yellowish color and double allocated grid cells in red.
`--startpage=NUM` | The number of the first page.
`--systemfonts` | Also use system fonts. Does not work on Windows XP.
`--tempdir` | Use this directory instead of the system's temp dir.
`--timeout=SEC` | Exit after SEC seconds with exit status 1.
`-v`, `--var=value` | Passes additional variables to the publisher run. The variables can be accessed as usual with `select="$variable"`.
`--varsfile=NAME` | Read an external file where each line has the format `variable=value` to add additional variables`
`--verbose` | More information than necessary.
`--wd=DIR` | Change working directory. Exactly the same as if you’d cd into that directory before running `sp`.
`--xml` | The output of some commands (currently only `list-fonts`) will be printed in (pseudo) XML. That way the output can be re-used in the layout XML.

Commands
--------

Command   | Description
----------|------------
`list-fonts` | Lists all fonts that are found in the search path. Together with `--xml` the output format can re used in the layout XML.
`compare` | Recursively check a directory for layout changes. See the topic [about quality assurance](qualityassurance.html).
`clearcache` | Removes files from the image cache.
`clean` | Remove temporary files from the publisher run. Keeps the PDF file.
`doc` | Opens the HTML documentation.
`run` | Starts the speedata publisher (this is the default command).
`server` | Runs in [Server-mode](servermode.html).
`watch` | Runs in internal hotfolder mode.

### Example for hotfolder configuration
    [hotfolder]
    hotfolder = /home/speedata/hotfolder
    events = layout\.xml:run(runpublisher);data\.xml:run(runpublisher)

Parameter | Description
----------|------------
`hotfolder` | Directory to be watched.
`events` | Entries (separated by a semicolon) in the form `pattern:command`. The `pattern` is a regular expression. If this pattern matches a file, the command given in the configuration is executed. Currently only external programs can be run. These programs must be given in parentheses. The path to the file will be passed as the first argument. The hotfolder waits until the program is finished and removes the file afterwards.
