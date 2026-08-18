# speedata Publisher architecture

- [speedata Publisher architecture](#speedata-publisher-architecture)
  - [Overview](#overview)
  - [Helper libraries](#helper-libraries)
  - [Build system](#build-system)
  - [The sp binary](#the-sp-binary)
  - [File lookup](#file-lookup)
  - [Startup sequence](#startup-sequence)
  - [The typesetting part](#the-typesetting-part)
  - [Lua module map](#lua-module-map)
  - [Go module map](#go-module-map)
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


## Lua module map

The Lua source lives under `src/lua/`. The publisher core is split across `publisher.lua` (the orchestrator) and a set of thematic submodules under `src/lua/publisher/`. Every submodule returns its `M` table; `publisher.lua` mirrors all public functions back onto the global `publisher` table at load time, so external code can keep calling `publisher.foo()` regardless of which file `foo` lives in.

### Entry points

| File | Role |
|------|------|
| `src/tex/publisher.tex` | TeX bootstrap. One `\directlua{require("publisher.spinit")}` call. |
| `sdini.lua` | Pre-publisher hook. Sets `package.path` from `LUA_PATH`, loads the splib shared library, exposes `kpse.find_file` and `do_luafile`. |
| `publisher/spinit.lua` | Application bootstrap. Defines logging globals (`warning`, `err`, `log`), unit helpers, then `require("publisher")` to load the core. |
| `publisher.lua` | Core orchestrator. Holds module-level state (options, current page/grid, attributes, language tables, dispatch table, …) and the top-level entry points `dothings()` and `initialize_luatex_and_generate_pdf()`. |

### Core submodules (under `src/lua/publisher/`)

These all follow the same `local M = {}; function M.foo(...); return M` pattern and read shared state via explicit `publisher.foo` references.

| File | Responsibility |
|------|---------------|
| `commands.lua` | XML element handlers for every Layout tag (`PlaceObject`, `Paragraph`, `Table`, `LoadFontfile`, …). The dispatch table in `publisher.lua` maps element names to functions in here. |
| `dispatch.lua` | The XML walking loop and pattern-matching record selection (`compile_match_pattern`, `find_matching_pattern`, `dispatch`). |
| `pages.lua` | Page lifecycle: `initialize_page`, `setup_page`, `new_page`, `clearpage`, `next_area`, `next_row`, `shipout`, `output_at`, `output_absolute_position`, `vsplit`. |
| `nodes.lua` | Node creation and paragraph composition: `mknodes` (the central glyph→nodelist function), `do_linebreak`, `hbkern`, `fix_justification`, glue/rule helpers, `insert_nonmoving_whatsits`. |
| `drawing.lua` | PDF drawing primitives: `frame`, `clip`, `circle`, `box`, `bgtext`, `background`, transformations (`rotate`, `matrix`, `montage`, `concat_transformation`), MetaPost integration, `pdf_*` path helpers. |
| `attributes.lua` | Lua-side helpers for LuaTeX node attributes and node properties: `get_attribute`, `set_attribute(s)`, `setprop`/`getprop`, plus the central XML attribute parser `read_attribute`. |
| `images.lua` | Image discovery and dimension resolution: `imageinfo`, `calculate_image_width_height`, `validateimagetype`, `reload_image`, `set_image_length`. |
| `fonts.lua` | Font instance bookkeeping (LuaTeX font numbers, fallback chains, font family lookup tables, line-break post-processing for underline / background colors). |
| `fontfamilies.lua` | Font family registration: `define_fontfamily`, `define_default_fontfamily`, alias resolution `get_fontname`. |
| `language.lua` | Hyphenation and locale handling: `get_language`, `get_languagecode`, `set_mainlanguage`. |
| `xml_helpers.lua` | XML loading, serialization and traversal: `load_xml`, `xml_escape`, `xml_to_string`, `fixup_xmlfile`, `elementname`, `element_contents`. |
| `structure_tree.lua` | PDF/UA structure tree, bookmarks, page labels: `bookmarkstotex`, `mkbookmarknodes`, `mkstringdest`, `writeStructElements`, `get_page_labels_str`, `sort_struct_tree_by_page_order`. |
| `utilities.lua` | Pure helpers: `deepcopy`, `copy_table_from_defaults`, `stable_sort`, `flush_table`, `flush_variable`, `string_random`. |
| `colors.lua` | Color definitions and PDF color-string formatters. |
| `links.lua` | Hyperlink and PDF action helpers. |
| `metadata.lua` | PDF metadata / XMP. |
| `metapost.lua` | MetaPost-Lua bridge (separate from `drawing.lua`'s consumer). |
| `grid.lua` | Page grid: cell allocation, frame/area management, cursor logic. |
| `tabular.lua` | Table layout (column widths, row heights, splitting, head/foot). |
| `page.lua` | Page object factory used by `pages.initialize_page`. |
| `commands.lua` ↔ `dispatch.lua` ↔ `pages.lua` ↔ `nodes.lua` form the hot loop. The remaining files are leaves: they expose helpers but rarely call back into the others. |

### Adjacent libraries (under `src/lua/`)

| File | Role |
|------|------|
| `lxpath.lua` | XPath engine. The legacy parser (luxor) was removed in v6.0. |
| `layout_functions.lua` | XPath function library registered into the engine at startup. |
| `html.lua` plus `html/*.lua` | HTML/CSS rendering pipeline (CSS resolution, inline / block layout, lists, tables, font handling). |
| `par.lua` | Paragraph builder used by both XML and HTML pipelines. |
| `fonts/fontloader.lua` | Low-level font file reader (HarfBuzz). |
| `barcodes/barcodes.lua` | EAN, QR, etc. |
| `xmlbuilder.lua` | Pure-Lua XML serializer. |
| `spotcolors.lua` | ICC-based spot color handling. |
| `uuid.lua`, `socket_url.lua` | Vendored third-party helpers. |
| `common/sd-callbacks.lua`, `common/sd-debug.lua` | LuaTeX callback registration and debug helpers, loaded by `sdini.lua`. |


## Go module map

The Go source lives under `src/go/`. The Go module is named `speedatapublisher` (see `go.mod`); internal imports use that prefix. Two binaries are produced from the tree:

- **`sp`** — the user-facing launcher and command-line front-end (package `main` in `src/go/sp/sp`).
- **`splib`** — a CGo shared library (`libsplib.so` / `.dll` / `.dylib`) loaded by LuaTeX via FFI. Its `package main` produces a buildmode `c-shared` artifact.

A third binary, **`sphelper`**, is a developer tool that builds both of the above plus the documentation and schemas. It is not shipped to end users.

The publisher has two build flavors selected with the Go build tag `pro`: the open-source build (no tag) and the commercial Pro build (`-tags pro`). Several files come in `*.go` / `*free.go` / `*pro.go` triples that gate functionality at compile time.

### Top-level entry points

| File | Role |
|------|------|
| `src/go/sp/sp/sp.go` | The `sp` binary. Argument parsing, configuration loading, mode dispatch (`run`, `filter`, `compare`, `server`, `clean`, …), locating and launching the `sdluatex` process, hotfolder handling, and version checks. |
| `src/go/sp/sp/filter.go` | Implementation of `sp filter`. Embeds a Lua interpreter (`speedata/go-lua`, Lua 5.4) and registers the Lua-side helpers (`luacsv`, `luaxml`, `luaxlsx`, `luahttp`, RELAX NG validation). |
| `src/go/sp/compare.go` | Implementation of `sp compare`: parallel QA runner, PDF rendering through Ghostscript, pixel diffs, HTML report generation. Exposes `Compare()` as a package API consumed by `sp.go`. |
| `src/go/sp/sp/fontdir_*.go` | Build-tag-gated font directory discovery for macOS, Windows, and the rest. |
| `src/go/sp/sp/procattr_*.go` | OS-specific `syscall.SysProcAttr` defaults used when forking `sdluatex`. |
| `src/go/splib/splib.go` | The shared library exposed to LuaTeX. CGo `//export` functions for file lookup, configuration, image registration, MetaPost helpers, bidi text, CSS parsing/HTML rendering, structure-tree handling. Holds the global file table that replaces kpathsea. |
| `src/go/splib/spliblua.go` | Thin Go wrapper around the Lua C API (`lua_State *`) that the rest of `splib` uses to push tables and values back to Lua. |
| `src/go/splib/luaxmlparser.go` | Bridge that hands the result of `xmltree.ParseXMLToLua` straight onto the Lua stack via the `LuaState` adapter. |
| `src/go/splib/logging.go` | Structured logger (`log/slog`) that writes the XML protocol file and `status.xml` consumed by other tools. |
| `src/go/sphelper/sphelper/sphelper.go` | The `sphelper` binary. Subcommand dispatch for `build`, `buildlib`, `doc`, `schema`, `dist`, `mkreadme`, … |

### `sp` binary helper packages (under `src/go/sp/sp/`)

These are loaded only when running `sp filter` and registered into the embedded Lua state.

| File | Role |
|------|------|
| `lualib/lualib.go` | Small helpers shared by the Lua-callable Go modules: `PushError`, `SetFieldString`, `FieldString`, etc. — keeps the stack idioms consistent. |
| `luacsv/luacsv.go` | Lua module `csv`: read CSV files (with charset and separator options) into Lua tables. |
| `luahttp/luahttp.go` | Lua module `http`: get/post/put/delete/head/patch/request, response objects with status/headers/body. Replaces the previously vendored `gluahttp`. |
| `luaxlsx/luaxlsx.go` | Lua module `xlsx`: read XLSX spreadsheets via `speedata/goxlsx`. |
| `luaxml/luaxml.go`, `luaxml/decode.go` | Lua module `xml`: encode and decode XML through `encoding/xml`, with comment and processing-instruction support. |

### Shared library packages (under `src/go/splib/`)

| File | Role |
|------|------|
| `xmltree/xmltree.go` | Plain in-memory tree types (`Node`, `Child`, namespace bookkeeping). |
| `xmltree/parse.go` | Streaming XML decoder that builds the tree, preserving namespaces, line/column positions, and resolving XIncludes. |
| `xmltree/render_lua.go` | Renders a parsed tree onto a Lua stack via the `LuaStater` interface (the `__type`, `__ns`, numbered-children format expected by the Lua side). |
| `xmltree/stream_to_lua.go` | Memory-optimized variant: streams XML directly onto the Lua stack without an intermediate Go tree. Used for large data files. |
| `csslua/render.go` | Walks a CSS-styled DOM (from `speedatapublisher/css`) and pushes the layout tree to Lua for HTML mode rendering. |
| `csslua/html_helpers.go` | Whitespace normalization, dimension parsing, and other small helpers used by the renderer. |

### Auxiliary library (`src/go/splibaux/`)

`splibaux` is a regular Go package (no CGo) imported by both `sp` and `splib`. It owns the file-list and image-cache logic.

| File | Role |
|------|------|
| `splibaux.go` | File-list construction (`BuildFilelist`), `LookupFile`, image-info caching, environment variable handling (`SP_JOBNAME`, `SP_VERBOSITY`, `IMGCACHE`, `IGNOREFILE`). |
| `httpcaching.go` | HTTP client with on-disk caching (`gregjones/httpcache`) for downloaded resources, including the `optimal` cache method that revalidates against the server. |
| `splibauxpro.go` | Pro-only image handling: download from URL, resize via `speedata/bild`. Built only with `-tags pro`. |
| `splibauxfree.go` | Stubs that print a Pro-required message. Built only without `-tags pro`. |

### CSS engine (`src/go/css/`)

A self-contained CSS parser/cascader used by HTML mode. Has no Lua or LuaTeX dependencies and is consumed by `splib/csslua`.

| File | Role |
|------|------|
| `css.go` | Public types (`CSS`, `Result`, `Page`, `FontFamilyFiles`), entry points to load and apply stylesheets. |
| `tokenize.go` | CSS tokenization wrapper around `speedata/css/scanner`, with `@import` resolution. |
| `tree.go` | DOM walker, dimension/color/font-shorthand expansion, `@page` handling. |
| `compute.go` | Specificity-ordered cascade. Fills `Result.Styles` and `Result.Attributes` for each `*html.Node`. |

### Server mode (`src/go/server/`)

Built only with `-tags pro`; the open-source build pulls in `serverfree.go` instead, which prints a "Pro plan only" message.

| File | Role |
|------|------|
| `server.go` | HTTP server (`gorilla/mux`): publish endpoints, file uploads, status polling, hotfolder integration via `fsnotify`. |
| `v1.go` | The v1 REST API (RFC 9457 problem details, JSON/XML negotiation). |
| `worker.go` | Bounded worker pool that runs `sp` subprocesses for incoming jobs. |
| `serverfree.go` | Stub that returns a non-functional `Server` in non-Pro builds. |

### Configurator (`src/go/configurator/`)

| File | Role |
|------|------|
| `configurator.go` | Reads INI-style configuration files (`speedata/config`), with section/key fall-through across multiple files. Used by both `sp` and the server. |

### Build system (`src/go/sphelper/`)

All packages here are only used by the `sphelper` developer binary.

| File | Role |
|------|------|
| `config/config.go` | Resolves the project layout (`Srcdir`, `Builddir`, `Libdir`), loads the version file, decides Pro vs. free, exposes the `Config` object passed to every subcommand. |
| `buildlib/buildlib.go` | Compiles `splib` to a C shared library for the host or a cross-target. Manages CGo/`CC` environment for cross-compilation. |
| `buildsp/buildsp.go` | Compiles the `sp` binary, sets `-ldflags` for version and platform, optionally signs Windows builds. |
| `dirstructure/dirstructure.go` | Lays out the distribution tree (`bin/`, `share/`, `sw/`, …) and copies LuaTeX binaries from `LUATEX_BIN`. |
| `distcustom/distcustom.go` | Customer-specific custom distribution builds driven by `SP_BUILDDIR_SW`. |
| `fileutils/fileutils.go` | `IsDir`, `IsExeFile`, `CopyFile`, `CopyDir` — the small file helpers used everywhere else. |
| `changelog/changelog.go` | Reads `doc/changelog.xml` into Go structs for the documentation and release-notes generators. |
| `commandsxml/commandsxml.go`, `commandsxml/markdown.go` | Reads `doc/commands-xml/commands.xml`, the canonical reference of all Layout commands. Provides Markdown rendering for embedded paragraph content. |
| `genadoc/genmarkdown.go` | Generates the AsciiDoc reference pages under `doc/newmanual/adoc-{en,de}/ref/` from `commands.xml`. |
| `genschema/genschema.go`, `genschema/relaxng.go`, `genschema/commandsxml.go` | Generates RELAX NG and XSD schemas for the Layout language in English and German from `commands.xml`. |

### Vendored Unicode data (`src/go/text/`)

| File | Role |
|------|------|
| `unicode/bidi/*.go` | Vendored copy of `golang.org/x/text/unicode/bidi` exposed via `splib` so the Lua side can run the UAX #9 bidi algorithm. The tables are from Unicode 15.0.0. |

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

