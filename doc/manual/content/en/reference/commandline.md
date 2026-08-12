---
title: "Running the speedata publisher on the command line"
linkTitle: "Command line"
weight: 30
type: docs
---


The speedata Publisher is started via the command line (also: terminal, command window).
On the one hand there are _commands_, on the other hand the commands can be controlled via _parameters_.

```shell
$ sp <Command> <Parameter> <Parameter> ...
```

{{< callout >}}
On Windows/PowerShell you have to run `sp.exe` since `sp` is an internal command of PowerShell.
{{< /callout >}}

The default command is `run`. So the call of

```shell
$ sp
```

the same as

```shell
$ sp run
```

Besides the command `run` there are other commands (see below).

With

```shell
$ sp --help
```

you can display a list of the allowed commands and parameters.

## Description of the commands

`clean`
: Deletes all generated intermediate files and keeps the PDF file.

`checkupdate`
: Checks if a new version of the Publisher is available. Return code is 0 if the version is up to date. 1 if a new version is available.

`clearcache`
: Removes files from the image cache.

`compare`
: Recursively check a directory for layout changes. See the topic about [quality assurance]({{% relref "qualityassurance" %}}).

`doc`
: Shows the manual in the browser. If the manual is part of the installation (directory `share/doc`), it is served through a local web server; the address is also printed on the console, and the server runs until ctrl-c. The German or the English edition is opened, depending on the language setting of the system (environment variables `LC_ALL`, `LC_MESSAGES`, `LANG`). With `--no-autoopen` the browser is not opened. Without a local manual, the command opens the online documentation at <https://doc.speedata.de>, also in the matching language.

`list-fonts`
: Lists all font files found in the Publisher directories. Together with `--xml` this command allows you to copy and paste the output into the layout rules. See [Using fonts]({{% relref "fonts" %}}).

`new [DIRECTORY]`
: Create simple layout and data file to start. Provide optional directory.

`run`
: Start publishing (default).

`server`
: Run as http-api server on localhost port 5266 (configure with `--address` and `--port`). See the chapter [Server-Modus (REST API)]({{% relref "servermode" %}}).

`watch`
: Start watchdog / hotfolder. See [Starting the Publisher via the Hotfolder]({{% relref "hotfolder" %}}).

## Description of the commandline parameters

Most parameters correspond to a key in the configuration file and are described on the page [Configuration]({{< relref "configuration" >}}).
The following table maps the parameters to the keys; values given on the command line take precedence over the configuration file.

| Parameter | Configuration key |
| --- | --- |
| `--address=IPADDRESS` | `address` (section `server`) |
| `--autoopen` | `autoopen` |
| `--cache=METHOD` | `cache` |
| `--data=NAME` | `data` |
| `--dummy` | `dummy` |
| `-x`, `--extra-dir=DIR` | `extra-dir` |
| `--extra-xml=NAME` | `extraxml` |
| `--filter=FILTER` | `filter` |
| `--grid`, `--no-grid` | `grid` |
| `--ignore-case` | `ignore-case` |
| `--imagecache=PATH` | `imagecache` |
| `--inkscape=PATH` | `inkscape` |
| `--jobname=NAME` | `jobname` |
| `--layout=NAME` | `layout` |
| `--[no-]local` | `addlocalpath` |
| `--logfile=NAME` | `logfile` (section `server`) |
| `--loglevel=LVL` | `loglevel` |
| `--mode=NAME[,NAME…]` | `mode` |
| `--pdfversion=VERSION` | `pdfversion` |
| `--port=PORT` | `port` (section `server`) |
| `--runs=NUM` | `runs` |
| `--startpage=NUM` | `startpage` |
| `--systemfonts` | `systemfonts` |
| `--tempdir=DIR` | `tempdir` |
| `--timeout=SEC` | `timeout` |
| `-v`, `--var=VAR=VALUE` | `vars` |
| `--verbose` | `verbose` |
| `--wd=DIR` | `wd` |
| `--xpath=PARSER` | `xpath` |

The following parameters exist only on the command line:

`-h`, `--help`
: Show this help

`-c`, `--config=NAME`
: Read the config file with the given NAME. Default: `publisher.cfg`

`--credits`
: Show credits and exit

`--[no-]cutmarks`
: Display cutmarks in the document

`--generate-completion=SHELL`
: Print a shell completion script (`bash`, `zsh` or `fish`) to standard output and exit. See the section _Shell completion_ below.

`--mainlanguage=NAME`
: The document's main language in locale format, for example `en` or `en_US`.

`--option=OPTION`
: Set a specific option that has no command line parameter.

`--outputdir=DIR`
: Copy PDF and protocol to this directory.

`--progress`
: Show progress information on standard output. Displays the current page number and elapsed time during a publishing run. If the publisher has been run before, it also shows the expected total number of pages (from the previous run) and the previous run duration. This option disables `--verbose`.

`--quiet`
: Run publisher in silent mode

`--show-gridallocation`
: Show the allocated grid cells

`-s`, `--suppressinfo`
: Suppress optional information (timestamp) and use a fixed document ID

`--trace`
: Show debug messages and some tracing PDF output

`--varsfile=NAME`
: Set variables for the publishing run from a file with each line containing `key=value` pairs. Lines starting with a `#` are ignored. See also `-v`, `--var`.

`--version`
: Show version information

`--xml`
: Output as (pseudo-)XML (for list-fonts)

## Shell completion

`sp` can produce tab-completion scripts for `bash`, `zsh` and `fish`. The script is written to standard output, so redirect it to wherever your shell expects completion files.

The completion knows all options and commands; for options that take a value it offers file completion as a generic default.

### Bash

Per user (requires the `bash-completion` package):

```shell
$ sp --generate-completion=bash > ~/.local/share/bash-completion/completions/sp
```

System-wide (e.g. from a distribution package): `/usr/share/bash-completion/completions/sp`.

### Zsh

Per user, one possible setup:

```shell
$ mkdir -p ~/.zsh/completions
$ sp --generate-completion=zsh > ~/.zsh/completions/_sp
```

Then add the following to `~/.zshrc` _before_ the `compinit` call:

```shell
fpath=(~/.zsh/completions $fpath)
```

System-wide locations are `/usr/share/zsh/vendor-completions/_sp` (Debian/Ubuntu) or `/usr/share/zsh/site-functions/_sp`.

### Fish

Fish picks completions up automatically from the user configuration directory:

```shell
$ sp --generate-completion=fish > ~/.config/fish/completions/sp.fish
```

System-wide path: `/usr/share/fish/vendor_completions.d/sp.fish`.

