---
title: "Version 3"
weight: 30
type: docs
---

## 3.9

### 3.9.36 (2020-09-07)

- New Option reportmissingglyphs="warning".

### 3.9.35 (2020-08-26)

- Bugfix for empty Value tag.

### 3.9.34 (2020-08-24)

- Safe require harfbuzz library, new binaries for Windows/Mac/Linux.

### 3.9.33 (2020-08-23)

- Disable harfbuzz on windows.

### 3.9.32 (2020-08-21)

- Experimental (unsupported) inclusion of harfbuzz renderer.

### 3.9.31 (2020-08-16)

- Allow interactions (hyperlinks) as a default.

### 3.9.30 (2020-08-14)

- Fix hyperlinks (no border in acrobat, make them work).

### 3.9.29 (2020-08-14)

- Bugfix for ForAll and reduced result set ([#261](https://github.com/speedata/publisher/issues/261)).

### 3.9.28 (2020-08-03)

- Bugfix for rowspan/colspan calculation. ([#259](https://github.com/speedata/publisher/issues/259))

### 3.9.27 (2020-07-31)

- padding-left and padding-right on Paragraph. ([#258](https://github.com/speedata/publisher/issues/258))

### 3.9.26 (2020-07-29)

- New xpath functions firstmark and lastmark to get the first and the last marker on a page.
- New internal variable `$_lastpage` that holds the page number of the previous run.

### 3.9.25 (2020-07-26)

- Bugfix for underline color ([#256](https://github.com/speedata/publisher/issues/256)).
- Enhance schema ([#257](https://github.com/speedata/publisher/issues/257)).

### 3.9.24 (2020-07-10)

- New `&lt;Option>` randomseed.
- Bugfix for hyperlinks at the end of a line starting with space ([#255](https://github.com/speedata/publisher/issues/255)).

### 3.9.23 (2020-07-05)

- Server mode: `/v0/pdf/‹id›` deletes the PDF file on the server after the request.

### 3.9.22 (2020-07-05)

- Server mode: add configurable filter and extra-dir, move entries to section `server`.

### 3.9.21 (2020-07-03)

- Lua filter `runtime.find_file` to get the absolute path of a resource.

### 3.9.20 (2020-07-02)

- Server mode: specify modes in the URL.

### 3.9.19 (2020-07-01)

- Enhance HTML support (margin-top, margin-bottom and other).

### 3.9.18 (2020-06-25)

- Enhance HTML support.

### 3.9.17 (2020-06-22)

- Bugfix qrcode (from upstream).
- CSS border-radius.

### 3.9.16 (2020-06-12)

- Bugfix HTML, update documentation.

### 3.9.15 (2020-06-10)

- Update to new LuaTeX 1.12 (without visible changes).
- New Englisch manual.

### 3.9.14 (2020-05-19)

- Various bugfixes introduced in recent development version.

### 3.9.13 (2020-05-15)

- Bugfixes related finding the executable ([#254](https://github.com/speedata/publisher/issues/254)).

### 3.9.12 (2020-05-12)

- Two bugfixes related to HTML mode ([#252](https://github.com/speedata/publisher/issues/252) and [#253](https://github.com/speedata/publisher/issues/253)).

### 3.9.11 (2020-05-12)

- New HTML mode: better table support.

### 3.9.10 (2020-05-10)

- New HTML mode: `sp html myfile.html`.
- Second argument for sd:imageheight, sd:imagewidth for exact size.
- `Image` as a child of `Output`.

### 3.9.9 (2020-04-21)

- Enhanced HTML support.

### 3.9.8 (2020-04-03)

- New option PDFOptions/showbookmarks for Adobe Acrobat.

### 3.9.7 (2020-03-31)

- Bugfix: double hyperlink in one line ([#251](https://github.com/speedata/publisher/issues/251))
- CSS: table 100% width, td: align
- Textformat: set margin at the top of the surrounding box.
- First (preliminary) version of the new HTML parser.

### 3.9.6 (2020-03-12)

- Table balancing: single tablerule in last frame gets into previous frame. ([#250](https://github.com/speedata/publisher/issues/250))
- Bugfix: simple HTML table ([#249](https://github.com/speedata/publisher/issues/249)).
- Bugfix: html hyperlinks with widows/orphan ([#248](https://github.com/speedata/publisher/issues/248)).
- Bugfix: run_saxon() fails.
- Bugfix: backgroundcolor of table cells with defaults in `Column` ([#247](https://github.com/speedata/publisher/issues/247)).

### 3.9.5 (2020-02-25)

- Fix height calculation for cell allocation.

### 3.9.4 (2020-02-14)

- New way to call run_saxon in the preprocessing filter.

### 3.9.3 (2020-02-10)

- Set log file for server mode.

### 3.9.2 (2020-01-27)

- New option interaction to remove hyperlinks, handle U+2011 correctly.

### 3.9.1 (2020-01-16)

- External image processors and converter.

## 3.8

### 3.8.0 (2020-01-14)

- Release stable version 3.8.0.

## 3.7

### 3.7.24 (2020-01-06)

- A few bugfixes ([#242](https://github.com/speedata/publisher/issues/242), [#174](https://github.com/speedata/publisher/issues/174), [#239](https://github.com/speedata/publisher/issues/239)). Prepare for 3.8.

### 3.7.23 (2019-12-19)

- Add cache option "none".

### 3.7.22 (2019-12-11)

- Improvements for caching external media files.

### 3.7.21 (2019-12-11)

- Improvements for downloading assets.

### 3.7.20 (2019-11-27)

- New command line parameter: set image cache.

### 3.7.19 (2019-11-25)

- Bugfix for table balancing ([#243](https://github.com/speedata/publisher/issues/243)).

### 3.7.18 (2019-11-22)

- New finalizer callback and new http module in Lua filter.

### 3.7.17 (2019-11-19)

- Better error messages for external files loading ([#241](https://github.com/speedata/publisher/issues/241)).

### 3.7.16 (2019-11-18)

- Bugfix 2 for table balancing ([#240](https://github.com/speedata/publisher/issues/240)).

### 3.7.15 (2019-11-05)

- Bugfix for table balancing ([#240](https://github.com/speedata/publisher/issues/240)).

### 3.7.14 (2019-10-31)

- Halloween release. (Bugfix for SavePages in backward mode).

### 3.7.13 (2019-10-28)

- Update to LuaTeX version 1.11.1 for the new `page_order_index` callback.
- Allow mode access via `$_mode` variable.
- Remove feature “insert after” on NewPage.

### 3.7.12 (2019-10-22)

- New command line switch `mode` for alternative code execution.
- Re-order pages with `SavePages` and `InsertPages`.

### 3.7.11 (2019-10-09)

- Page number on errors and warnings

### 3.7.10 (2019-09-11)

- New command 'sp new' for scaffolding.
- Add XML Schema (XSD).

### 3.7.9 (2019-09-03)

- Allow Options to appear more than once in the layout file.

### 3.7.8 (2019-08-15)

- sd:group-width() now has a second parameter for get the exact width, just as sd:group-height().
- Allow re-setting the page dimensions.
- Better rotation in table cells.

### 3.7.7 (2019-07-18)

- Fallback for LoadFontfile.

### 3.7.6 (2019-07-01)

- Allow elements in Message.
- New XPath function number().
- Bugfix initials and line height.

### 3.7.5 (2019-06-12)

- Bugfix textformat/fill-last-line ([#234](https://github.com/speedata/publisher/issues/234)).
- Bugfix valign=bottom ([#233](https://github.com/speedata/publisher/issues/233)).

### 3.7.4 (2019-05-21)

- Bugfix table balancing ([#232](https://github.com/speedata/publisher/issues/232)).

### 3.7.3 (2019-05-02)

- AttachFile: set the PDF name of the included file.

### 3.7.2 (2019-04-28)

- Bugfix: TD with align=right containing only one or more spaces ([#230](https://github.com/speedata/publisher/issues/230))
- AttachFile can select an XML node from data instead of reading from an external resource.

### 3.7.1 (2019-04-02)

- Some bug fixes ([#221](https://github.com/speedata/publisher/issues/221), [#225](https://github.com/speedata/publisher/issues/225), [#226](https://github.com/speedata/publisher/issues/226), [#228](https://github.com/speedata/publisher/issues/228), [#229](https://github.com/speedata/publisher/issues/229)).

## 3.6

### 3.6.0 (2019-02-13)

- Release version 3.6.0

## 3.5

### 3.5.13 (2019-02-13)

- Bugfix for valign="botton" in PlaceObject ([#222](https://github.com/speedata/publisher/issues/222))
- Fix leading in paragraphs for small fonts ([#221](https://github.com/speedata/publisher/issues/221))
- Fix URL breaking ([#173](https://github.com/speedata/publisher/issues/173))
- Fix textformat tracing ([#172](https://github.com/speedata/publisher/issues/172))

### 3.5.12 (2019-01-31)

- Bugfix for table balancing and break-below=no

### 3.5.11 (2019-01-27)

- Bugfix: set row when balancing tables.
- Row height in table balancing taken into account.

### 3.5.10 (2018-12-21)

- Various bugfixes. Remove XProc filter. New attribute clip with Frame. Update hyphenation patterns. XInclude for data. Move to Go 1.11 modules.

### 3.5.9 (2018-11-29)

- Default margin now 1cm, bugfix for dynamic table head and balance="yes".

### 3.5.8 (2018-11-28)

- Fix a few minor errors.

### 3.5.7 (2018-11-21)

- Bugfix table split and cursor movement ([#202](https://github.com/speedata/publisher/issues/202)).
- Support for PDF/X-3 and PDF/X-4.
- Basic support for PDF/UA (accessibility).

### 3.5.6 (2018-11-09)

- Better handling of rotation in table cells.

### 3.5.5 (2018-10-30)

- SVG on the fly conversion with Inkscape.
- Optional filename in Lua-filter XML-writer.

### 3.5.4 (2108-10-04)

- New file loader allows many ways to include files.
- Allow inclusion of files with non-ascii characters on Windows.

### 3.5.3 (2018-09-25)

- Various bugfixes (HTML-linking in data, pdf-dest link too low [#198](https://github.com/speedata/publisher/issues/198)).

### 3.5.2 (2018-09-18)

- Letter spacing in Span.
- Break-below works with Tablerule.
- CID-keyd fonts can be used.
- Bugfixes for `upper-case()`, `lower-case()` and `replace()`.
- Various bugfixes introduced by LuaTeX 1.0.7.

### 3.5.1 (2018-09-05)

- First release with dynamic library, mainly for testing.

## 3.4

### 3.4.0 (2018-09-03)

- Release version 3.4.0

## 3.3

### 3.3.14 (2018-08-30)

- Update to LuaTeX version 1.0.7
- sp compare HTML status report
- limit TCP connection to localhost

### 3.3.13 (2018-08-22)

- New command TableNewPage to eject a page within a table
- Access user variables within the Lua filter
- New xpath function lower-case()

### 3.3.12 (2018-08-13)

- Bugfix for table cell width calculation ([#194](https://github.com/speedata/publisher/issues/194))
- Ellipsis can be drawn using the circle command.

### 3.3.11 (2018-08-08)

- Bugfix for tables spanning multiple frames ([#191](https://github.com/speedata/publisher/issues/191))
- Ensure minimal length of last line of a paragraph ([#188](https://github.com/speedata/publisher/issues/188))

### 3.3.10 (2018-07-31)

- sd:group-height() with a second argument, a unit.
- Bookmarks don't change the zoom of the PDF
- Bugfix for NoBreak
- New Lua implementation for the filter (yuin/gopher-lua instead of Shopify/go-lua)

### 3.3.9 (2018-06-18)

- Various bugfixes, expose `$_jobname`

### 3.3.8 (2018-06-18)

- SaveDataset: rename attribute `filename` to `name`.
- Hyperlinks within documents
- Allow bookmarks in dynamic table headers (Tr/sethead='yes')
- XPath: fix comparison of elements and atomic values.

### 3.3.7 (2018-06-13)

- Text rotation in table cells (Td)

### 3.3.6 (2018-06-01)

- Bugfix in textformat/spacebelow ([#171](https://github.com/speedata/publisher/issues/171))

### 3.3.5 (2018-05-30)

- New attribute `minwidth` to set the `HSpace` width.
- Various bug fixes (leaders in table, documentation links, `space="..."` with `LoadFontfile`)
- New xpath function `local-name()`
- HTML text now allows the em tag
- “New” color model RGB for values between 0 and 255
- Add language “French” to schema.

### 3.3.4 (2018-05-16)

- Bugfixes for ctrl-c when running sp ([#167](https://github.com/speedata/publisher/issues/167)) and Output/balance="yes".

### 3.3.3 (2018-05-15)

- Bugfix: allow page format taken from the data source.
- Fix QR code generation.

### 3.3.2 (2018-04-20)

- Bugfix height calculation Output/Text and balance="yes"

### 3.3.1 (2018-04-16)

- Balance: padding-bottom and valign on last page
- Output/Text balance="yes" and textformat/column-padding-top

## 3.2

### 3.2.0 (2018-03-27)

- Release version 3.2.0

## 3.1

### 3.1.28 (2018-03-27)

- Documentation enhancements

### 3.1.27 (2018-03-23)

- Another bugfix with Tables

### 3.1.26 (2018-03-23)

- Bugfix with Tables ([#166](https://github.com/speedata/publisher/issues/166))
- Bugfix with Ul/Li

### 3.1.25 (2018-03-20)

- Bugfix with XPath operators ([#165](https://github.com/speedata/publisher/issues/165))
- Updated the German documentation

### 3.1.24 (2018-03-16)

- New feature: Table/balance="yes"

### 3.1.23 (2018-03-14)

- Tr/minheight allows length units

### 3.1.22 (2018-03-09)

- PlaceObject: enhance absolute positioning
- SortSequence: allow descending sort
- More detailled setting of orphan/widow

### 3.1.21 (2018-02-16)

- Bugfix for multipage table
- New standard fonts

### 3.1.20 (2018-02-01)

- Lot's of font improvements, first attempt to get chinese right

### 3.1.19 (2018-01-30)

- Allow setting of PDF title and author

### 3.1.18 (2018-01-29)

- Fix fontmapping problem

### 3.1.17 (2018-01-28)

- Report glyphs missing from a font
- exit="yes" at Message to quit a publishing run

### 3.1.16 (2017-12-19)

- Allow other namespaces in Layout file
- Bugfix for FontFace

### 3.1.15 (2017-12-07)

- New command Span for background color

### 3.1.14 (2017-12-01)

- speedup

### 3.1.13 (2017-11-30)

- Use exeSufix for sp compare on Windows
- Bugfix for Output/allocate="auto"

### 3.1.12 (2017-11-28)

- Bugfix for future pages

### 3.1.11 (2017-11-23)

- Add Excel reader and RelaxNG validaton
- Add basic support for LuaTeX 1.0.4

### 3.1.10 (2017-11-03)

- Enhance Lua CSV reader

### 3.1.9 (2017-10-31)

- New Lua based pre-processing

### 3.1.8 (2017-10-24)

- New xpath function round, padding-* in Column

### 3.1.7 (2017-10-22)

- Various bugfixes (Grid, Fontface)

### 3.1.6 (2017-09-27)

- Various bugfixes

### 3.1.5 (2017-09-08)

- New feature: DefineTextformat/tab=hspace change tab into a stretching space

### 3.1.4 (2017-09-06)

- Bugfix: Image/page does not work with href

### 3.1.3 (2017-08-22)

- New xpath function `sd:dimexpr()` for calculation with dimensions

### 3.1.2 (2017-07-31)

- Bugfix for underline.

### 3.1.1 (2017-07-28)

- ZUGFeRD integration, new commands AttachFile and AddSearchpath

## 3.0

### 3.0.0 (2017-07-25)

- Release version 3.0

