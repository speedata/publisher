---
title: "How to configure the speedata publisher"
linkTitle: "Configuration"
weight: 40
type: docs
---


The speedata publisher can be configured in several ways:

1. The file publisher.cfg in `/etc/speedata/`, in the home directory (with a leading dot) and in the current working directory (Linux, Mac)
2. The file `%APPDATA%\speedata\publisher.cfg` on Windows.
3. Parameters given on the command line
4. Options given in the layout file

## The file `publisher.cfg`

The file publisher.cfg (`/etc/speedata/publisher.cfg`, `$HOME/.publisher.cfg` and in the current working directory) is a text file that is read at the beginning of the publisher run. The default file looks like this:

```
data      = data.xml
layout    = layout.xml
autoopen  = false
# This is a comment
# But this is not a comment
# ^^^ of course the line above is also a comment
#

# section specific values
[section]
key = value
```

You can access the base directory of the project with `%(projectdir)s`. This is the directory with the file `publisher.cfg`.

All entries in the configuration file are optional.
The configuration files are read in the following order: `/etc/speedata/publisher.cfg`, `~/.publisher.cfg` and in the current directory `publisher.cfg`.
The current directory can be changed on the command line with the switch `--wd=....`.

The format of the file is important, otherwise it won’t be recognized. The following options are supported:

`autoopen` (command line: `--autoopen`)
: If true, the publisher opens the PDF file after the run. Default: false.

`addlocalpath` (command line: `--local`, `--no-local`)
: If true, the publisher adds the current working directory recursively to the search path. Default: true.

`cache` (command line: `--cache`)
: Caching-strategy for http(s) image requests and external image processors. Use `fast` for file system lookup only or `optimal` for checking on each request. Use `none` for no caching. `none` works also for SVG conversion. In this case, PDF is generated on each request. The default is `optimal`.

`data` (command line: `--data`)
: Name of the data file (XML). If not given, the system uses `data.xml`. Use `-` to read the data from standard input (STDIN, only one run possible). An external resource (`http://`) can be given as well.

`dummy` (command line: `--dummy`)
: If true, the system won’t read the data file, instead it uses the single element `<data />` as its input.

`extra-dir` (command line: `-x`, `--extra-dir`)
: A list of directories in the file system separated by `;` (Windows) or `:` (Mac, Linux). These directories contain the images, fonts, source files and other assets that are used during the publisher run. Example for windows: `extra-dir=c:\myfonts`. On the command line the parameter can be given multiple times.

`extensionhandler`
: Assignment of file extensions to converters defined in 'imagehandler'. To convert graphics on-the-fly. Example: `extensionhandler="mmd:mermaid"`. Multiple entries are separated by semicolon. See also `imagehandler`. (Since version 3.9.1.)

`extraxml` (command line: `--extra-xml`)
: Add this XML file to the layout instructions. List of comma separated file names (`extraxml=file1.xml,file2.xml`). Not supported with the new XPath module. Use xinclude instead.

`fontloader`
: Set the fontloader to `fontforge` (default until version 4.16) or `harfbuzz` (default starting from version 4.18). The `fontforge` fontloader is deprecated and scheduled for removal in version 6.0.

`filter` (command line: `--filter`)
: Run the given file as a Lua filter. See the section [Lua-Filter / Vorverarbeitung]({{% relref "preprocessing" %}}).

`fontpath`
: Set the path for system fonts. On Windows this is `%WINDIR%\Fonts`, on Mac OS X it defaults to `/Library/Fonts:/System/Library/Fonts`.

`grid` (command line: `--grid`, `--no-grid`)
: If true, the underlying grid is shown in the PDF file. For debugging purpose only. Can also be enabled in the layout with the [`<Trace>`]({{% relref "/reference/commands/trace" %}}) command.

`hidespinfo`
: If set to 'true', the speedata Publisher does not add the `(Created with the speedata Publisher - www.speedata.de)` information. Needs a Pro plan.

`imagecache` (command line: `--imagecache`)
: Folder for cached images (`href="http://..."` and image processors). Defaults to `$TMPDIR/sp/images`. The directory is created if necessary.

`imagehandler`
: Assignments of image type to external converters, for example `imagehandler="mermaid:(/usr/bin/mmdc -i %%input%% -o %%output%%.pdf)"`. Multiple entries are separated by semicolons. How this works, the placeholders and further examples are described in the section [External Conversion Tools]({{% relref "/manual/imagesandgraphics#external-conversion-tools" %}}).

`ignore-case` (command line: `--ignore-case`)
: Ignore case when accessing files (on a case-insensitive file system) in the recursive file lookup.

`inkscape` (command line: `--inkscape`)
: The path to the program inkscape when you need on the fly SVG to PDF conversion.

`inkscape-command`
: Command line for image conversion. Version 0.92 and before needs `--export-pdf` and since version 1 it is `--export-filename`.

`jardir`
: Directory containing the Java JAR files used for XSLT and RELAX-NG processing. Defaults to the bundled `lib` directory. Mainly relevant for OS package maintainers — see [Using system-provided Java JARs]({{% relref "installation#using-system-provided-java-jars" %}}).

`jobname` (command line: `--jobname`)
: Name of the output file (without extension). Default is `publisher`.

`layout` (command line: `--layout`)
: Name of the layout rule set (XML). The default name is `layout.xml`. An external resource (`http://`) can be given as well.

`loglevel` (command line: `--loglevel`)
: Set the log level to one of `debug`, `info`, `message`, `warn` and `error`. Messages from this level and above are written to the protocol file.

`luatex`
: Path to the LuaTeX binary. Experimental! This is provided for your experiments, not for production use.

`mode` (command line: `--mode`)
: Set the layout mode. See [Control of the layout]({{% relref "controllayout" %}}).

`opencommand`
: Command that will be run to open the documentation and the PDF file. For MacOS X this should be `open`, for Linux `xdg-open` or `exo-open` (xfce).

`pathrewrite`
: Comma separated list of entries of the form A=B which replace parts in `file:///media/XYZ` to `file:///path/to/project/myfiles/XYZ`. Useful when you have absolute paths in the data which must be changed during the publishing process.

`pdfversion` (command line: `--pdfversion`)
: The PDF version that gets written. Default is `1.7`.

`prependxml` (command line: `--prepend-xml`)
: Add this XML file in front of the layout instructions. List of comma separated file names (`prependxml=file1.xml,file2.xml`). Not supported with the new XPath module. Use xinclude instead.

`reportmissingglyphs`
: Should requested but missing glyphs be reported as an error or as a warning? The allowed values are `true`, `false`, or `warning`. `false` disables the reporting.

`resizehandler`
: Assignment of screen type to external converters that resize images to the desired DPI. For example, `resizehandler="jpegimage:(magick %%input%% -resize %%width%%x%%height%%! %%output%%)"`. See also the section [Configuration of the Resize Handler]({{% relref "/manual/imagesandgraphics#configuration-of-the-resize-handler" %}}). (Since version 5.1.23.)

`runs` (command line: `--runs`)
: Set the number of runs.

`startpage` (command line: `--startpage`)
: Number of the first page.

`systemfonts` (command line: `--systemfonts`)
: If set to `true`, then the publisher searches for fonts in the system directories. Does not work on Windows XP.

`tempdir` (command line: `--tempdir`)
: Name of the temporary directory. Default is the system's temp.

`timeout` (command line: `--timeout`)
: Maximum time of the publishing run. If time is exceeded, the publisher exits with status 1.

`vars` (command line: `-v`, `--var`)
: Comma separated list of variables and values in the form `var=value` to set additional variables. On the command line each `--var variable=value` sets one variable and can be given multiple times, see also `--varsfile`. The variables can be used in the layout with `select="$variable"`.

`verbose` (command line: `--verbose`)
: `true` prints the messages from the protocol file to the standard output.

`wd` (command line: `--wd`)
: Change into this directory before the run starts, as if you had changed into it with `cd` beforehand.

`xpath` (command line: `--xpath`)
: [Set the XML module]({{% relref "/reference/xpath/xpath" %}}). The current default is `lxpath`, and the old is called `luxor`. The old parser is deprecated and scheduled for removal in version 6.0.

### Section server (`server`)

`address` (command line: `--address`)
: IP address to which the server should open the port. Default is 127.0.0.1.

`extra-dir`
: Extra directories for the publishing runs to be included.

`filter`
: Lua script to run before processing the publishing runs (like a call to `sp --filter ...`).

`logfile` (command line: `--logfile`)
: File name for the log. `STDOUT` for standard output and `STDERR` for standard error.

`loglevel`
: Set the log level to one of `debug`, `info`, `message`, `warn` and `error`.

`port` (command line: `--port`)
: Port to which a connection can be established. Default is 5266.

`runs`
: Set the number of publishing runs for the client document.

### Section Hotfolder (`hotfolder`)

``hotfolder``
: Directory to be “watched”.

`events`
: Rules which programs to run on which files.

A detailed description can be found in the [Starting the Publisher via the Hotfolder]({{< relref "hotfolder" >}}) section.

## Command line parameters
The valid command line parameters are written on a [separate page]({{< relref "commandline" >}}).

## Options given in the layout file
The XML layout file has a command called [`<Options>`]({{< relref "/reference/commands/options" >}}) that allows to set some parameters (tracing, default language, …)

