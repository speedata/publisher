# speedata Publisher architecture

- [speedata Publisher architecture](#speedata-publisher-architecture)
  - [Overview](#overview)
  - [Helper libraries](#helper-libraries)
  - [Build system](#build-system)
  - [The sp binary](#the-sp-binary)
  - [File lookup](#file-lookup)
  - [Startup sequence](#startup-sequence)
  - [The typesetting part](#the-typesetting-part)
  - [Directory structure](#directory-structure)

This document describes the architecture of the speedata Publisher.
Hopefully it helps to understand the logical structure of the directories and enables you to start hacking on the software itself.

## Overview

When you start the speedata Publisher, you run `sp(.exe)` on the command line, which is a small piece of software written in Go. This command looks for a LuaTeX binary (sdluatex) in the bin directory (provided in the ZIP file) and executes it. The LuaTeX binary loads all the Lua script files and does the typesetting task.

![architecture](doc/images/overview.png)

## Helper libraries

There are two libraries loaded by the LuaTeX process, a Go library that handles XML parsing and resources loading and other stuff and a minimal C library which just makes these functions available to the Lua scripts.

## Build system

The software is built using a custom build system called `sphelper` written in Go which allows you to build the software and the documentation.

There is also a Rakefile (requires Ruby's `rake`) which is mostly a wrapper for `sphelper`. To install `sphelper`, run `rake sphelper`, to build the software, run `rake buildlib` and `rake build`.

## The sp binary

There are roughly four modes for the start program to run in:

| Mode | Description |
|------|--------------|
| run  | This is the default mode. This starts the LuaTeX binary |
| filter | This can be used in addition to the mode _run_. It looks for a Lua script and executes it. |
| compare | This starts the QA mode. It recurses into a directory and compares the publisher output to a given PDF (see the [manual](https://doc.speedata.de/publisher/en/advancedtopics/qa/)) |
| server | The REST API described in [the manual](https://doc.speedata.de/publisher/en/advancedtopics/servermode/) |

## File lookup

File lookup is done by building a file list on startup (see [the Go library](https://github.com/speedata/publisher/blob/develop/src/go/splib/splib.go)) and a lookup in this list.  External resources are dowloaded and saved in a temporary file (see caching in the source).

## Startup sequence

The `sp` start program runs LuaTeX in _ini_ mode, which does not load any formats. It disables the kpathsea-library for file lookup and instead uses its own lookup. The startup sequence loads a shared library (splib) written in Go and has a Lua-ffi wrapper for the Lua side. The TeX input file is just [a small wrapper](https://github.com/speedata/publisher/blob/develop/src/tex/publisher.tex) that runs the Lua script `spinit`. The Lua part is the typesetting part of the software.



## The typesetting part

The typesetting works basically by transforming text and other input into LuaTeXs internal data structure and let LuaTeX output the PDF. See [TeX without TeX](http://wiki.luatex.org/index.php/TeX_without_TeX) in the LuaTeX wiki for the underlying idea.


## Directory structure

    .
    ├── bin          Testing script
    ├── doc          Documentation source code
    ├── fonts        Default fonts
    ├── img          Sample images
    ├── lib          Java helper
    ├── qa           Quality assurance test files
    ├── schema       XML schema (RELAX NG, XSD)
    ├── src          Go and Lua source files
    └── test         unittests


