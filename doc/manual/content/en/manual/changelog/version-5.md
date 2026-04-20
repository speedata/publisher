---
title: "Version 5"
weight: 10
type: docs
aliases:
  - latest
---

## 5.5

### 5.5.9 (2026-04-20)

- Documentation: move to Hugo static site generator, reorganize structure.
- Allow Textblock in Td for better control with rotation.
- Support css ::marker.<br>
  CSS ::marker pseudo-element is now supported for list styling, including custom content and colors.
- Images are drawn when trace objects="yes".
- Bug fix HTML borders width calculation.

### 5.5.8 (2026-04-14)

- Honor box height in lines (line height).
- Box border.
- Vertical align for Box in paragraph mode.
- Images: vertical alignment in Paragraph.
- Remove action command.
- Suppressinfo for metadata.
- Show sum mismatch in sp compare.
- New attribute match on Record.

### 5.5.7 (2026-04-02)

- Bugfix table shrink algorithm.

### 5.5.6 (2026-04-02)

- Bugfix PDF copy/paste hyphen minus.

### 5.5.5 (2026-04-01)

- Fix minimum width in tables with colspan and rowspan.
- Fix CSS inheritance on td/tr.

### 5.5.4 (2026-04-01)

- HTML tables: honor rowspan and colospan, Prevent rowspan at bottom of page.

### 5.5.3 (2026-03-09)

- Server mode: add endpoint to retrieve publisher-protocol.xml.

### 5.5.2 (2026-03-06)

- Correct lots of spelling mistakes in the documentation.
- Implement accessibility for Output/Text ([#614](https://github.com/speedata/publisher/issues/614)).
- PDF/UA structure tree.
- Fix PDF/UA and InsertPages / SavePages ([#613](https://github.com/speedata/publisher/issues/613)).
- Add search path, don't duplicate files.
- Better error message for function calls and old XPath parser.
- Bugfix letter-spacing and hyphenation.
- Filter: set classpath for Saxon correctly, including all required JAR files.

### 5.5.1 (2026-03-02)

- Bug fixe for image inclusion (opacity), attribute context handling and Creator version.

### 5.5.0 (2026-02-26)

- Bugfix letter-spacing in tables.

## 5.4

### 5.4.3 (2026-03-04)

- Bugfix letter-spacing and hyphenation.
- Better error message for function calls and old XPath parser.
- Filter: set classpath for Saxon correctly, including all required JAR files.

### 5.4.2 (2026-02-27)

- Fix attribute context handling.
- Fix transparent PDF inclusion.
- Fix Creator/Producer version in PDF metadata.

### 5.4.1 (2026-02-26)

- Bugfix letter-spacing in tables.

### 5.4.0 (2026-02-24)

- Release stable version 5.4.

## 5.3

### 5.3.24 (2026-02-23)

- New command Section to organize layout files (without affecting formatting).

### 5.3.23 (2026-02-19)

- Bugfix ForAll keeping the context.

### 5.3.22 (2026-02-18)

- Massive speed improvement.
- Margin protrusion setting is now in 1/1000 em.

### 5.3.21 (2026-02-05)

- Bugfix: hyphenation now works correctly with letter-spacing.

### 5.3.20 (2026-01-29)

- Bugfix: calculate remaining height in PlaceObject / absolute positioning.

### 5.3.19 (2026-01-29)

- Fix panic on sp --help / --version.

### 5.3.18 (2026-01-26)

- Add letter-spacing attribute to DefineTextformat (in 1/1000 em).
- Fix infinite loop in post_linebreak.

### 5.3.17 (2026-01-23)

- Fix infinite loop in HTML tables.
- Better handling of killing child processes in sp.

### 5.3.16 (2026-01-20)

- HTML tables with only header or footer (empty body) are now rendered correctly.

### 5.3.15 (2026-01-19)

- Bugfix for empty HTML tables.
- Implement Until for the new XPath parser.
- HTML enhancements (including documentation).

### 5.3.14 (2026-01-15)

- HTML can now wrap across multiple pages.

### 5.3.13 (2026-01-14)

- Remove infinite loop in HTML tables.

### 5.3.12 (2025-12-05)

- Add global html option in Options command and --option html=off command line flag to control HTML parsing.

### 5.3.11 (2025-12-04)

- Improve typesetting performance with early exits, cached lookups, and leaner attribute handling in mknodes.
- Modularize publisher.lua into color, links, and metadata modules to reduce file size.
- Update qrencode to the latest upstream version.

### 5.3.10 (2025-11-30)

- Fix CSS/HTML rendering slowdown.

### 5.3.9 (2025-11-25)

- Allow text formats to use the font size defined in CSS for HTML content.
- Fix handling of relative (em) font sizes based on the current font size.
- Fix HTML border rendering in regular paragraph mode.
- Update to latest Saxon HE.
- Remove Rust source code.

### 5.3.8 (2025-11-21)

- Fix HTML borders and currentcolor in table rules.

### 5.3.7 (2025-11-19)

- Rewrite HTML border.
- Allow styles in HTML tables.

### 5.3.6 (2025-11-11)

- Bugfix reset ul counter.

### 5.3.5 (2025-11-10)

- Fix @font-face in CSS (fatal crash).

### 5.3.4 (2025-11-10)

- HTML: add support for more list style types (lower-alpha, upper-alpha, etc.).
- Set exit code when error count is greater than zero.
- Compare tool: refactor for stability and improved HTML report (checksums, build errors, thumbnails, sorting).
- Refactor HTML → Lua rendering pipeline for structured output and cleaner CSS separation.

### 5.3.3 (2025-11-04)

- Reinstate old curly brace syntax for Value/select and old xpath parser ([#680](https://github.com/speedata/publisher/issues/680)).
- Remove building of Rust library ([#678](https://github.com/speedata/publisher/issues/678)).

### 5.3.2 (2025-11-01)

- Fix indentation after br newline.

### 5.3.1 (2025-10-21)

- Fix Windows/Rust loading.

### 5.3.0 (2025-10-21)

- Alternative Rust library for dynamic binding.

## 5.2

### 5.2.0 (2025-10-14)

- Release Version 5.2.

## 5.1

### 5.1.29 (2025-10-14)

- Rewrite parts of the Go-XML parser.

### 5.1.28 (2025-10-05)

- Fix PDF metadata / ISO dates.

### 5.1.27 (2025-10-04)

- Bugfix XPath function doc() returns root node instead of document node.

### 5.1.26 (2025-09-23)

- New XPath function translate().
- Documentation: clarified use of px (pixels).
- tabular.lua converted into a module (internal change only).
- Safeguard for missing file name in AttachFile.
- New XPath function distinct-values().

### 5.1.25 (2025-09-15)

- Publisher now continues multiple runs even if errors occur.
- Support for Japanese typesetting.
- Fixed fallback with multi-character sequences.

### 5.1.24 (2025-09-15)

- Warning when empty hyperlink.
- Improved error message for empty group/trace.
- Improved error messages for duplicate files and errors writing aux-file.
- XPath: Added format-number() and round-half-to-even().
- New attribute type "rawstring" without {} escaping.

### 5.1.23 (2025-09-10)

- Optional resizehandler for DPI setting (configuration file).
- CSS font-family can now have multiple entries.

### 5.1.22 (2025-08-25)

- More HTML/CSS features (pseudo classes, padding in tables and borders).

### 5.1.21 (2025-08-23)

- NoBreak with background color.
- NoBreak in table cells ([#670](https://github.com/speedata/publisher/issues/670)).
- Bugfix image conversion with same filename and different extensions.
- Extend basic HTML features (custom fonts, border, rem size).

### 5.1.20 (2025-08-19)

- Set trapped to false in PDF for preflight check.
- Do some safeguards to prevent Go/Lua thread errors.

### 5.1.19 (2025-08-18)

- Allow paragraph shape in groups.
- Bugfix: copy files truncate itself ([#668](https://github.com/speedata/publisher/issues/668)).
- Put PDF producer entry in metadata.

### 5.1.18 (2025-08-01)

- Bugfix PlaceObject/rotate and vreference.

### 5.1.17 (2025-07-30)

- Bugfix lxpath mode and new XPath parser.
- Re-implemented HTML mode.
- Set log level in server mode.

### 5.1.16 (2025-07-15)

- Fix sd:format-number ([#664](https://github.com/speedata/publisher/issues/664)).

### 5.1.15 (2025-07-14)

- Proper escaping of XML metadata in ZUGFeRD attachments.

### 5.1.14 (2025-07-10)

- Bugfix HTML and uppercase tags.

### 5.1.13 (2025-07-03)

- Ignore DEL (decimal 127) control character in input ([#663](https://github.com/speedata/publisher/issues/663)).

### 5.1.12 (2025-06-25)

- Fix (XPath) boolean value of attributes.

### 5.1.11 (2025-06-18)

- No fatal error in case of missing http-image.

### 5.1.10 (2025-06-06)

- Better log messages.
- New XPath function sd:symbol() to enter a glyph id.
- Remove old XPath documentation.

### 5.1.9 (2025-05-23)

- New option 'addlocalpath' in the configuration file for turning off recursive search of the working directory.
- New Option mpcolorwarning to show the MetaPost color warning (defaults to true).

### 5.1.8 (2025-05-22)

- Bugfix: layout function sd:current-framenumber() and new XPath parser.

### 5.1.7 (2025-05-18)

- cache=none works for SVG conversion ([#622](https://github.com/speedata/publisher/issues/622)).

### 5.1.6 (2025-05-15)

- New command `sp checkversion` to see if a newer version is available ([#660](https://github.com/speedata/publisher/issues/660)).

### 5.1.5 (2025-05-05)

- Update to new LuaTeX binaries (1.22.0).
- Change Windows system font directory discovery.

### 5.1.4 (2025-05-05)

- Bugfix: table split in AtPageShipout ([#659](https://github.com/speedata/publisher/issues/659)).
- Absolute positioning within a group.

### 5.1.3 (2025-04-07)

- Fix spaces in imagehandler.

### 5.1.2 (2025-04-07)

- Change then width and the height for vertical rules. Internal change, should not create visible changes.

### 5.1.1 (2025-04-07)

- Lua-preprocessor: runtime.execute returns success/exit code.

### 5.1.0 (2025-04-04)

- Set background-color for each page.

## 5.0

### 5.0.2 (2025-04-04)

- Bugfix image handler automatic conversion.

### 5.0.1 (2025-04-01)

- Bugfix: rounding error in some grid configurations.

### 5.0.0 (2025-03-11)

- Release Version 5.0.

