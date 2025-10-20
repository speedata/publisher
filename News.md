# NEWS

This file gets updated before a stable release. There is a [detailed changelog](https://doc.speedata.de/publisher/en/changelog/#ch-changelog) in the [manual](https://doc.speedata.de/publisher/en/).


## Planned for version 5.4

* Rewrite Go dynamic runtime library in Rust (to remove cgo dependency))
* More unit testing and refactoring
* Speed improvements
* More HTML/CSS support
* More XPath functions

## Version 5.2

Released 2025-10-14

Major changes from version 5.1:

* New XML parser
The XML parser has been completely reimplemented. It is now more robust, includes automated tests, and records source file information (.__file) for better XInclude handling and error diagnostics.
* Improved XPath functions
Added several new XPath functions, including translate() and distinct-values().
The doc() function now returns the document node instead of the root element for more standard-compliant behavior.
Numeric and boolean functions (format-number(), round-half-to-even()) and general boolean logic have been improved for more consistent results.
* Better international and typographic support
Added initial Japanese typesetting support and improved multi-character fallback handling.
* Enhanced HTML/CSS rendering
    * Many refinements to the internal HTML/CSS engine:
    * Support for pseudo-class selectors and list-style-position
    * Better handling of borders, padding, and spacing
    * font-family now accepts multiple fallbacks
    * Improved custom @font-face and font-size calculations (rem, px)
* PDF metadata improvements
Dates in PDF metadata now use ISO format, and additional metadata fields (like “Producer” and color profile defaults) are included automatically.
* Reliability and diagnostics
* Improved logging and clearer error messages
* Multi-run behavior continues even after previous errors, when needed
* Safer handling of file attachments and image conversions
* More detailed debug output for troubleshooting
* Stability and maintainability
Numerous internal cleanups, documentation improvements, and test enhancements make this release more stable and easier to maintain.


## Version 5

Released 2025-03-11

This software is now completely error free ;-)

Now it is time to make a good release, and then add some more features.

Major changes from version 4:

* New default XML and XPath parser
* New default Text shaper (Harfbuzz) with left-to-right, right-to-left and mixed typesetting
* Accessibility support (PDF/UA)
* speedata Pro package
* And much more, see below


## Version 4.20

Released 2025-01-15

The last version before 5

* Fully accessible documents
* Make new XPath parser robust
* ZUGFeRD attachment enhancements
* Ability to flip (mirror) objects
* Strict namespace handling (optional)
* Spot color saturation

## Version 4.18

Released 2024-04-19

* New defaults for the XPath engine and the font loader (preparation for the version 5)
* New output / logging backend.
* New [dpi attribute with PDFOption](https://doc.speedata.de/publisher/en/images/#_image_size_and_resolution) for automatic image resizing.
* [Markdown](https://doc.speedata.de/publisher/en/advancedtopics/markdown/).

## Version 4.16

Released 2024-01-07

* Complete overhaul of the MetaPost integration.
* New XPath engine (optional).

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




