# NEWS

This file gets updated before a stable release. There is a [detailed changelog](https://doc.speedata.de/publisher/en/changelog/#ch-changelog) in the [manual](https://doc.speedata.de/publisher/).


## Version 4.16

Not yet released.

* Complete overhaul of the MetaPost integration.

## Version 4.14

Released 2023-07-03

* New syntax for filename, page number and PDF box in image functions ([#502](https://github.com/speedata/publisher/issues/502)).
* Outline fonts.
* Tables: new Column spec `minwidth` and new keywords for width (`min` and `max`).
* New XPath function `matches()` ([#453](https://github.com/speedata/publisher/issues/453)).
* [Pro package](https://doc.speedata.de/publisher/en/speedatapro/).
* Bug fixes

## Version  4.12

Released 2022-09-30

* PDFOptions displaymode
* Delay execution on SetVariable.
* Set border color for hyperlinks.
* Add sha256, sha512 functions.
* New command Clip.
* Remove LuaJIT/FFI, add new lua glue library.


## Version 4.10

* Mostly bug fixes
* `runtime.execute()` in Lua filter/preprocessing for executing external programs
* `xml.decode_xml()` in Lua filter/preprocessing for reading XML files

Version 4.10 will be the last stable version that runs with LuaJIT/FFI.

## Version 4.8

Released 2022-05-02

* Bug fixes
* Allow `color="-"` in `<Tablerule>`
* `<VSpace>` with attributes `height` and `minheight`


## Version 4.6

Released 2021-11-10

* Lots of bug fixes, as always.
* REST API: set number of runs.
* REST API: enhanced server verbosity.
* REST API: new route for direct publishing (send data and get PDF in one request).
* [NewPage deprecation (use ClearPage instead)](https://github.com/speedata/publisher/discussions/345).
* macOS 12.0 compatibility.
* Include color profile in distribution.
* Easier calculation with lengths.
* Use new Go based XML parser.

## Version 4.4

Released 2021-05-11

* Transparency (available for text and images).
* MetaPost integration.
* Windows 64 binaries.
* Document separation (frontmatter, mainmatter).
* Logical and visible page numbering.
* Better hyperlinks within a document (pages, page numbers, leaders, images and boxes).
* Lots of bug fixes (mostly related to table head/foots and HTML support).


## Version 4.2

Released 2021-01-07

* Better OpenType (`.otf` and `.ttf`) font support. Including font features, colored fonts and perhaps variable fonts.
* Basic print CSS support. This includes a completely new HTML parser and renderer.
* This branch now has a new paragraph builder, a new font shaper (harfbuzz) and an enhanced HTML mode. The HTML mode is currently limited to Textblock/Paragraph, but will be enhanced in the next versions.
* New language settings (`Other`) to let the font shape guess the language and the script.
* Support for non-western scripts such as CJK and Arabic. This includes right to left (rtl) typesetting.
* Support for mixing left to right and right to left typesetting (bidi).

## Version 4

Released 2020-09-07

Most visible changes from version 3.8

* New XPath functions `firstmark()` and `lastmark()` to get the first and the last marker on a page. Useful for headers in dictionaries.
* New internal variable `$_lastpage` which has the number of the last page from the previous run.
* Improved server mode
* New HTML mode
* New English manual
* Better support for Adobe Acrobat (remove colored links)
* External image conversion tools (for example Inkscape)

The main reason to release this as version 4 is that this version includes some changes that might break the backward compatibility promise.
The paragraph building mode is completely rewritten in version 4 and could lead to different results in line breaking.




