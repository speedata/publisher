---
title: "Changelog"
weight: 900
type: docs
---

## 5.5

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

## 4.21

### 4.21.20 (2025-03-11)

- Remove direction attribute on Span.

### 4.21.19 (2025-03-10)

- Better error messages for internal Lua errors.

### 4.21.18 (2025-03-04)

- Fix bidi brackets ([#650](https://github.com/speedata/publisher/issues/650)).

### 4.21.17 (2025-02-26)

- Bugfix in HTML mode.

### 4.21.16 (2025-02-25)

- Bugfix: break-before="page" and break-below="no" in DefineTextformat has no effect.

### 4.21.15 (2025-02-25)

- Textformat: force page break before element.

### 4.21.14 (2025-02-19)

- Fix incorrect ordering in bidi ([#649](https://github.com/speedata/publisher/issues/649)).

### 4.21.13 (2025-02-18)

- Various bugfixes (EAN13 barcodes, metapost colors and new XPath parser).
- Value/Function can be used to create a table cell ([#647](https://github.com/speedata/publisher/issues/647)).

### 4.21.12 (2025-02-17)

- Column width in tables allow fixed widths and dynamic width calculation ([#648](https://github.com/speedata/publisher/issues/648)).

### 4.21.11 (2025-02-10)

- Bugfix NoBreak and incomplete font family ([#646](https://github.com/speedata/publisher/issues/646)).

### 4.21.10 (2025-02-05)

- Allow clipping of objects at page margin ([#640](https://github.com/speedata/publisher/issues/640)).

### 4.21.8 (2025-02-03)

- Various bug fixes, documentation fixes ([#582](https://github.com/speedata/publisher/issues/582), [#594](https://github.com/speedata/publisher/issues/594), [#611](https://github.com/speedata/publisher/issues/611), [#629](https://github.com/speedata/publisher/issues/629), [#630](https://github.com/speedata/publisher/issues/630)).
- Allow grid tracing of groups ([#569](https://github.com/speedata/publisher/issues/569)).

### 4.21.7 (2025-01-31)

- Bugfix for Fallback command in HarfBuzz mode.

### 4.21.6 (2025-01-30)

- Start Fallback command for fonts in HarfBuzz mode ([#603](https://github.com/speedata/publisher/issues/603)).

### 4.21.5 (2025-01-23)

- Allow variables in Pagetype and new XPath mode.

### 4.21.4 (2025-01-22)

- Bugfix: font fallbacks and old XPath mode.

### 4.21.3 (2025-01-22)

- Fix display error for table rules in Adobe Acrobat ([#644](https://github.com/speedata/publisher/issues/644)).

### 4.21.2 (2025-01-20)

- Rewrite border-collapse ([#645](https://github.com/speedata/publisher/issues/645)).
- Remove white background on every page.

### 4.21.1 (2025-01-17)

- Bugfix: hyperlinks to URLs broken.

### 4.21.0 (2025-01-16)

- Add bleed="auto" for Box.
- Rename extension from intermediate files (now .xml instead of .dataxml).

## 4.20

### 4.20.0 (2025-01-15)

- Release Version 4.20.

## 4.19

### 4.19.40 (2025-01-15)

- Saturation for spot colors.

### 4.19.39 (2025-01-13)

- Bugfix Harfbuzz: make OSF and other non-standard glyphs copy-able in PDF.

### 4.19.38 (2025-01-09)

- Fix filename detection and ZUGFeRD attachments.
- Allow PDF/A-3 as an output format.

### 4.19.37 (2025-01-07)

- Better ZUGFeRD version detection.
- New possibility to flip objects ([#642](https://github.com/speedata/publisher/issues/642)).
- Write OutputIntent with ZUGFeRD PDF/A files. This fixes an error for invalid PDF files.
- Bug fix: fallback for fonts in fontforge mode ([#605](https://github.com/speedata/publisher/issues/605)).
- Lax and strict handling of XML namespaces ([#641](https://github.com/speedata/publisher/issues/641)).
- Harfbuzz: make OSF and other non-standard glyphs copy-able in PDF.

### 4.19.36 (2024-12-17)

- New XPath function namespace-uri().
- Change ZUGFeRD default file name to 'factur-x.xml'.
- Better ZUGFeRD profile detection.

### 4.19.35 (2024-12-02)

- Bugfix border collapse and colspan ([#636](https://github.com/speedata/publisher/issues/636)).

### 4.19.34 (2024-11-26)

- Fix value of last() in new XPath parser when called with ProcessNode.

### 4.19.33 (2024-11-24)

- Option to switch off color profile for spot colors.

### 4.19.32 (2024-11-22)

- Bugfix image dimensions in HTML mode and new XPath mode.
- Function: now mixed commands and values are allowed ([#627](https://github.com/speedata/publisher/issues/627)).

### 4.19.31 (2024-11-04)

- Add option to control script size and offsets ([#625](https://github.com/speedata/publisher/issues/625)).

### 4.19.30 (2024-10-29)

- Bugfix sd:variable() and new XPath parser ([#623](https://github.com/speedata/publisher/issues/623)).

### 4.19.29 (2024-10-29)

- New Margin parameters inner and outer instead of left and right.

### 4.19.28 (2024-10-28)

- New strategy `&lt;NoBreak reduce="fontfit" />` ([#622](https://github.com/speedata/publisher/issues/622)).

### 4.19.27 (2024-10-23)

- Data XML now available in the root layout XML element ([#621](https://github.com/speedata/publisher/issues/621)).
- Bugfix: SetGrid with width/height after nx/ny ([#619](https://github.com/speedata/publisher/issues/619)).

### 4.19.26 (2024-10-05)

- Bugfix ClearPage within SavePages ([#617](https://github.com/speedata/publisher/issues/617)).

### 4.19.25 (2024-10-02)

- Fix multiple InsertPages in forward mode.

### 4.19.24 (2024-09-30)

- Bugfix sd:count-saved-pages and new xpath mode.

### 4.19.23 (2024-09-16)

- PDF/UA enhancements.

### 4.19.22 (2024-09-06)

- PDF/UA enhancements.
- Handle UTF-16 XML files.

### 4.19.21 (2024-09-04)

- Backward incompatible change: Change XPath variable semantics ([#612](https://github.com/speedata/publisher/issues/612)).
- Fix tab="hspace" for harfbuzz mode.
- Reduce logging noise.

### 4.19.20 (2024-08-14)

- Assume inkscape &gt; version 1.0 for SVG conversion.
- Remove superfluous ET/BT/EMC command in page stream ([#602](https://github.com/speedata/publisher/issues/602)).

### 4.19.19 (2024-07-24)

- Bug fix Image and width="100%" and lxpath mode ([#600](https://github.com/speedata/publisher/issues/600)).
- Bug fix NoBreak/fontsize and empty input ([#598](https://github.com/speedata/publisher/issues/598)).

### 4.19.18 (2024-07-17)

- Fix NoBreak/fontsize and dynamic data ([#598](https://github.com/speedata/publisher/issues/598)).
- Error message and documentation for `--prepend-xml` and `--extra-xml` in lxpath-mode ([#597](https://github.com/speedata/publisher/issues/597)).
- Enable margin protrusion in harfbuzz mode ([#595](https://github.com/speedata/publisher/issues/595)).

### 4.19.17 (2024-07-12)

- Allow setting of font expansion parameter.
- sp list-fonts works again.

### 4.19.16 (2024-07-07)

- Enhance accessibility options.

### 4.19.15 (2024-07-04)

- New platform support: Linux ARM 64 bit (experimental).

### 4.19.14 (2024-07-01)

- Bugfix Lists and multicolumn ([#593](https://github.com/speedata/publisher/issues/593)).
- Bugfix nested HTML ul/ol list.

### 4.19.13 (2024-07-01)

- Bugfix SavePages in forward mode and contents after SavePages ([#592](https://github.com/speedata/publisher/issues/592)).

### 4.19.12 (2024-06-25)

- Bugfix for space below Image in Paragraph ([#591](https://github.com/speedata/publisher/issues/591)).
- Overflow objects start in column 1.

### 4.19.11 (2024-06-23)

- Make white background configurable ([#590](https://github.com/speedata/publisher/issues/590)).

### 4.19.10 (2024-06-18)

- New XPath function for getting lengths ([#587](https://github.com/speedata/publisher/issues/587)).
- New Option for reporting overfull lines ([#588](https://github.com/speedata/publisher/issues/588)).
- Bugfix for overfull line detection.

### 4.19.9 (2024-06-13)

- Fix Image/bleed=auto for bottom margin ([#586](https://github.com/speedata/publisher/issues/586)).

### 4.19.8 (2024-06-13)

- Add Sanskrit hyphenation patterns.
- The PDF version is now 1.7 as the default.
- Better support for tagged PDF.

### 4.19.7 (2024-06-10)

- Honor jpeg orientation in includes images ([#584](https://github.com/speedata/publisher/issues/584)).

### 4.19.6 (2024-05-30)

- Better error message for sd:decode-html().

### 4.19.5 (2024-05-23)

- Fix underline in sd:decode-html ([#581](https://github.com/speedata/publisher/issues/581)).

### 4.19.4 (2024-05-22)

- Allow setting of /Creator with `--suppressinfo` ([#577](https://github.com/speedata/publisher/issues/577)).

### 4.19.3 (2024-05-15)

- Set PDF producer.
- Fix sd:(keep-)alternating for new XPath parser.

### 4.19.2 (2024-04-22)

- Fix autoopen when an error occurs.

### 4.19.1 (2024-04-21)

- Bug fix: color of table rules when no width is given in Columns ([#576](https://github.com/speedata/publisher/issues/576)).
- Bug fix: Value in Function.

### 4.19.0 (2024-04-20)

- Enhance Function.

## 4.18

### 4.18.0 (2024-04-19)

- Release version 4.18.0

## 4.17

### 4.17.24 (2024-04-19)

- Add SavePages test case.

### 4.17.23 (2024-04-17)

- Fix Makeindex for new xpath mode.
- Marginprotrusion with harfbuzz.

### 4.17.22 (2024-04-12)

- Lots of bug fixes: number(), internal variables and While in new XPath mode, single space in Harfbuzz mode ([#570](https://github.com/speedata/publisher/issues/570), [#573](https://github.com/speedata/publisher/issues/573), [#574](https://github.com/speedata/publisher/issues/574)).

### 4.17.21 (2024-03-27)

- Re-introduce C library to fix error on Windows ([#570](https://github.com/speedata/publisher/issues/570)).

### 4.17.20 (2024-03-21)

- Spacing fixes (kerning in initials, multiple non-breaking-spaces in harfbuzz mode, multiple zero width spaces).
- Bugfixes for various layout functions in lxpath mode.

### 4.17.19 (2024-03-18)

- Fix layout functions for lxpath.

### 4.17.18 (2024-03-14)

- Re-introduce kerning in HB mode when fontforge is the default font loader.

### 4.17.17 (2024-03-13)

- sdluatex binary lookup now in PATH environment variable.
- CGO_C/LDFLAGS override for compiling sp library.

### 4.17.16 (2024-03-06)

- Change the default harfbuzz shaper to "ot".
- Bugfix harfbuzz and newline with some fonts ([#566](https://github.com/speedata/publisher/issues/566)).

### 4.17.15 (2024-03-04)

- Re-introduce status file (compatibility in server mode).
- Update the image processing library (resize).

### 4.17.14 (2024-03-03)

- Remove status file, better error messages/exit status.

### 4.17.13 (2024-03-02)

- Remove luaglue library.
- Log level 'notice' is between info and warn.

### 4.17.12 (2024-03-01)

- Unicode left to right and similar markers don't give warning ([#565](https://github.com/speedata/publisher/issues/565)).

### 4.17.11 (2024-02-29)

- Markdown implementation.
- Image resize does not require imageserver anymore.

### 4.17.10 (2024-02-19)

- New (pro) feature for resizing images (needs the speedata imageserver).
- Rewrite Go/Lua XML parser (lxpath).

### 4.17.9 (2024-02-12)

- Bugfix not updating $_lastpage in luxor XML mode ([#561](https://github.com/speedata/publisher/issues/561)).

### 4.17.8 (2024-01-29)

- Enhance error messages.

### 4.17.7 (2024-01-18)

- Better output when process exits.

### 4.17.6 (2024-01-18)

- Remove debugging message.

### 4.17.5 (2024-01-17)

- Experimental option "xmlfile" to use intermediate files for lxpath ([#557](https://github.com/speedata/publisher/issues/557)).

### 4.17.4 (2024-01-11)

- Few bugfixes related to harfbuzz/lxpath ([#556](https://github.com/speedata/publisher/issues/556)).

### 4.17.3 (2024-01-11)

- lxpath is the new default XPath parser..

### 4.17.2 (2024-01-10)

- Make harfbuzz the default font loader.

### 4.17.1 (2024-01-10)

- Switch go Go 1.21.
- Rewrite speedata Publisher logging/output.

### 4.17.0 (2024-01-08)

- New ZIP layout without extra sdluatex folder.

## 4.16

### 4.16.0 (2024-01-07)

- Release version 4.16.0.

## 4.15

### 4.15.21 (2024-01-04)

- Rename backgroundcolor to background-color on various elements ([#554](https://github.com/speedata/publisher/issues/554)).
- Allow frame color '-' for “no color”.
- Opacity with DefineColor and `value="..."`.
- Set default schema in catalog.xml to RELAX NG.

### 4.15.20 (2024-01-02)

- Bugfix: zero width space ([#552](https://github.com/speedata/publisher/issues/552)).
- Log file lookup when verbose > 0.

### 4.15.19 (2023-12-23)

- Bugfix background with Span ([#547](https://github.com/speedata/publisher/issues/547)).

### 4.15.18 (2023-12-20)

- Transparency with Frame border ([#544](https://github.com/speedata/publisher/issues/544)).

### 4.15.17 (2023-12-19)

- Line information on Message ([#545](https://github.com/speedata/publisher/issues/545)).
- Transparency with Frame ([#544](https://github.com/speedata/publisher/issues/544)).

### 4.15.16 (2023-11-28)

- Various metapost related fixes ([#542](https://github.com/speedata/publisher/issues/542), [#543](https://github.com/speedata/publisher/issues/543)).

### 4.15.15 (2023-11-26)

- Fix Various bugs related to transparency ([#542](https://github.com/speedata/publisher/issues/542)).

### 4.15.14 (2023-11-25)

- Few bugfixes related to lxpath (DefineGraphic and ProcessNode).
- Schema change (allow Overlay in Case).

### 4.15.13 (2023-11-21)

- Rename A/embed to embedded ([#522](https://github.com/speedata/publisher/issues/522)).

### 4.15.12 (2023-11-15)

- Bugfix Mark command with the new XPath parser.
- New function `sd:dimexpr()` for unit calculation.

### 4.15.11 (2023-11-14)

- Overlay: fix positioning of multiple children ([#520](https://github.com/speedata/publisher/issues/520)).
- Link to embedded files ([#522](https://github.com/speedata/publisher/issues/522)).
- Update lxpath XPath parser.

### 4.15.10 (2023-11-08)

- Bug fix new XPath parser again ([#538](https://github.com/speedata/publisher/issues/538)).
- New attribute require on Layout command.

### 4.15.9 (2023-11-07)

- Enhance new XPath parser with simple for expression.
- Bug fix new XPath parser ([#537](https://github.com/speedata/publisher/issues/537)).

### 4.15.8 (2023-11-02)

- New XML/XPath parser ([#536](https://github.com/speedata/publisher/issues/536)).
- Remove standalone HTML subsystem.

### 4.15.7 (2023-10-21)

- Border color with A ([#526](https://github.com/speedata/publisher/issues/526)).
- Re-implement sp --ignore-case ([#534](https://github.com/speedata/publisher/issues/534)).
- Not found hyphenation patterns give warning instead of error ([#532](https://github.com/speedata/publisher/issues/532)).

### 4.15.6 (2023-10-18)

- Bugfix for URL text disappearing ([#529](https://github.com/speedata/publisher/issues/529)).
- Allow white space in image handlers ([#527](https://github.com/speedata/publisher/issues/527)).

### 4.15.5 (2023-10-10)

- Add new metapost command spcolor ([#524](https://github.com/speedata/publisher/issues/524)).
- Allow comments in variables file ([#518](https://github.com/speedata/publisher/issues/518)).

### 4.15.4 (2023-09-18)

- Rewrite and extension of the MetaPost subsystem.

### 4.15.3 (2023-09-07)

- Add more Unicode spacing characters.

### 4.15.2 (2023-08-18)

- Warning for image not found on non-last Option fix ([#514](https://github.com/speedata/publisher/issues/514)).

### 4.15.1 (2023-08-16)

- New PDFOptions for page layout.

### 4.15.0 (2023-07-17)

- Allow tracing grid to stay on front ([#512](https://github.com/speedata/publisher/issues/512)).

## 4.14

### 4.14.0 (2023-07-03)

- Release version 4.14.

## 4.13

### 4.13.18 (2023-06-06)

- Bugfix: border collapse and rowspan ([#482](https://github.com/speedata/publisher/issues/482)).
- Bugfix Nobreak can have only one child ([#455](https://github.com/speedata/publisher/issues/455)).
- Bugfix. Span/padding and space at the beginning ([#506](https://github.com/speedata/publisher/issues/506)).

### 4.13.17 (2023-06-05)

- Bugfix valign and halign on PlaceObject ([#503](https://github.com/speedata/publisher/issues/503)).
- Bugfix available space with grid dy > 0 ([#505](https://github.com/speedata/publisher/issues/505)).

### 4.13.16 (2023-06-02)

- Bugfix halign="right" with grid gap &gt; 0 ([#503](https://github.com/speedata/publisher/issues/503)).
- Add warning on duplicate file search entries ([#501](https://github.com/speedata/publisher/issues/501)).
- New syntax for filename, page number and PDF box in image functions ([#502](https://github.com/speedata/publisher/issues/502)).

### 4.13.15 (2023-05-11)

- Bugfix with Options startpage.
- Bugfix: Image bleed="auto" and Options trim not set.
- Outline fonts.

### 4.13.14 (2023-05-04)

- Bug fix for *-columns in tables and minwidth.
- Bug fix for image margin ([#491](https://github.com/speedata/publisher/issues/491)).
- Frame: set border radius for all four corner ([#492](https://github.com/speedata/publisher/issues/492)).

### 4.13.13 (2023-04-20)

- margin-* in Image.
- Bugfix colspan ([#481](https://github.com/speedata/publisher/issues/481)).

### 4.13.12 (2023-03-27)

- \r in version file ([#486](https://github.com/speedata/publisher/issues/486)).
- Update dependencies.

### 4.13.11 (2023-03-14)

- Bugfix for empty aux files.

### 4.13.10 (2023-03-10)

- Special file name with colon syntax in layout functions ([#468](https://github.com/speedata/publisher/issues/468)).
- B: # in URLs correctly encoded ([#472](https://github.com/speedata/publisher/issues/472)).
- Set display mode only if requested ([#470](https://github.com/speedata/publisher/issues/470)).

### 4.13.9 (2023-02-27)

- New Column spec `minwidth` and new keywords for width (`min` and `max`).
- New XPath function `matches()` ([#453](https://github.com/speedata/publisher/issues/453)).
- Remove documenation from ZIP.

### 4.13.8 (2023-02-23)

- Two new functions for page width and page height ([#464](https://github.com/speedata/publisher/issues/464)).

### 4.13.7 (2023-02-22)

- Bugfix: broken hyperlink gets inserted at kern ([#461](https://github.com/speedata/publisher/issues/461)).
- Fix bottom radii at Frame ([#459](https://github.com/speedata/publisher/issues/459)).

### 4.13.6 (2023-02-20)

- Rename graphics attribute on Td to graphic ([#457](https://github.com/speedata/publisher/issues/457)).
- Remove command NewPage from schema and documentation.
- Colon syntax for specifying page number on sd:aspectratio, sd:imagewidth and sd:imageheight ([#456](https://github.com/speedata/publisher/issues/456)).

### 4.13.5 (2023-01-07)

- Bugfix for sd list-fonts ([#454](https://github.com/speedata/publisher/issues/454)).
- Bugfix for border with hyphens ([#449](https://github.com/speedata/publisher/issues/449)).
- Specify default type for attachments ([#451](https://github.com/speedata/publisher/issues/451)).

### 4.13.4 (2022-11-22)

- Bugfixes calculating hashes and reading attachments ([#446](https://github.com/speedata/publisher/issues/446)).
- Bugfix style at penalty ([#449](https://github.com/speedata/publisher/issues/449)).

### 4.13.3 (2022-11-18)

- A few bugfixes related to AttachFile.

### 4.13.2 (2022-11-10)

- Vertical shift for hyperlink anchors.
- AttachFile can now attach other files than ZUGFeRD invoices..

### 4.13.1 (2022-11-09)

- Bugfix spacing in RTL mode ([#445](https://github.com/speedata/publisher/issues/445)).

### 4.13.0 (2022-09-30)

- Start with Pro plan.

## 4.12

### 4.12.0 (2022-09-30)

- Release version 4.12.0.

## 4.11

### 4.11.8 (2022-09-06)

- Suppressinfo allows creator to be set ([#420](https://github.com/speedata/publisher/issues/420)).
- New attribute displaymode for PDFOptions ([#428](https://github.com/speedata/publisher/issues/428)).
- Optional delay execution on SetVariable ([#412](https://github.com/speedata/publisher/issues/412)).
- Add sd:sha256, sd:sha512 and sd:md5 functions ([#414](https://github.com/speedata/publisher/issues/414)).
- Set border color for hyperlinks ([#416](https://github.com/speedata/publisher/issues/416)).

### 4.11.7 (2022-08-25)

- Fix NoBreak inside Td ([#410](https://github.com/speedata/publisher/issues/410)).
- Handle command line variables with backslashes ([#411](https://github.com/speedata/publisher/issues/411)).
- Allow Unicode strings in attachment description ([#376](https://github.com/speedata/publisher/issues/376)).
- Correct kerning in mixed fontforge / harfbuzz paragraphs ([#413](https://github.com/speedata/publisher/issues/413)).
- Fix space at end of the paragraph ([#392](https://github.com/speedata/publisher/issues/392)).

### 4.11.6 (2022-07-25)

- Better error handling for file lookup ([#407](https://github.com/speedata/publisher/issues/407)).

### 4.11.5 (2022-07-15)

- Rename the methods on command Clip ([#405](https://github.com/speedata/publisher/issues/405)).

### 4.11.4 (2022-07-12)

- Bugfix for URL escaping.

### 4.11.3 (2022-07-12)

- New command Clip to cut off edges from objects.

### 4.11.2 (2022-07-08)

- Various bugfixes introduced in the migration from LuaJIT/FFI.

### 4.11.1 (2022-07-07)

- Remove LuaJIT/FFI dependency.

## 4.10

### 4.10.0 (2022-07-07)

- Release version 4.10.

## 4.9

### 4.9.10 (2022-07-07)

- Bugfix: remove space between text and number ([#392](https://github.com/speedata/publisher/issues/392)).
- Bugfix: named destinations and unbalanced parenthesis.

### 4.9.9 (2022-07-06)

- Filter: show output on runtime.execute.

### 4.9.8 (2022-07-01)

- Allow to set image shape on Image element.
- Add XML decoder for lua filter.
- Bugfix URL rendering with hyperlinks ([#381](https://github.com/speedata/publisher/issues/381)).

### 4.9.7 (2022-06-27)

- runtime.execute in Lua filter.

### 4.9.6 (2022-06-22)

- Only documentation updates.

### 4.9.5 (2022-05-17)

- Bugfix for long table foot on the last page ([#268](https://github.com/speedata/publisher/issues/268)).

### 4.9.4 (2022-05-12)

- Better fix for ZWJ ([#369](https://github.com/speedata/publisher/issues/369)).

### 4.9.3 (2022-05-10)

- New command line option to set the PDF version (`--pdfversion`).
- Bugfix zero width joiner in Hindi texts ([#369](https://github.com/speedata/publisher/issues/369)).

### 4.9.2 (2022-05-09)

- Allow setting the creator of the document.

### 4.9.1 (2022-05-03)

- Fix PDFOptions overrides previous entries ([#367](https://github.com/speedata/publisher/issues/367)).
- Fix ordering of bookmarks in InsertPages ([#366](https://github.com/speedata/publisher/issues/366)).

## 4.8

### 4.8.0 (2022-05-02)

- Release version 4.8.

## 4.7

### 4.7.13 (2022-04-29)

- Bugfix: indent and br in HTML mode ([#302](https://github.com/speedata/publisher/issues/302)).
- Start-attribute with ol (HTML mode) ([#311](https://github.com/speedata/publisher/issues/311)).
- Bugfix: A href und interaction="no" ([#362](https://github.com/speedata/publisher/issues/362)).

### 4.7.12 (2022-04-28)

- Bugfixes (sd:group-height() and HTML rendering) ([#364](https://github.com/speedata/publisher/issues/364)).
- VSpace now has minheight and height attributes.

### 4.7.11 (2022-04-07)

- Allow color `-` in Tablerule.

### 4.7.10 (2022-04-05)

- Bugfix table split and rowsep / leading ([#361](https://github.com/speedata/publisher/issues/361)).

### 4.7.9 (2022-04-01)

- Bugfix transparency and multipage table ([#360](https://github.com/speedata/publisher/issues/360)).
- Re-implement pathrewrite.

### 4.7.8 (2022-03-24)

- NextFrame moves cursor to first column ([#358](https://github.com/speedata/publisher/issues/358)).
- URL escape hyperlinks.
- sd:decode-html() decodes all HTML entities.
- Bugfix ul/ol missing first entry of li ([#357](https://github.com/speedata/publisher/issues/357)).

### 4.7.7 (2022-03-02)

- XML parser: ignore DTD ([#355](https://github.com/speedata/publisher/issues/355)).
- Schema: add NoBreak to ForAll, Case, Otherwise, Loop,... ([#356](https://github.com/speedata/publisher/issues/356)).

### 4.7.6 (2022-02-21)

- Background color (text) and kerning ([#353](https://github.com/speedata/publisher/issues/353)).

### 4.7.5 (2022-02-20)

- Background color and mix of rtl/ltr text ([#352](https://github.com/speedata/publisher/issues/352)).

### 4.7.4 (2022-02-09)

- Update to Saxon 11.

### 4.7.3 (2022-01-21)

- Bugfix unicode escape in HTML parsing ([#350](https://github.com/speedata/publisher/issues/350)).

### 4.7.2 (2022-01-07)

- Bugfix: table balancing and minheight=1 ([#348](https://github.com/speedata/publisher/issues/348)).

### 4.7.1 (2021-12-17)

- Bugfix: colspan > 1 and border-collapse ([#347](https://github.com/speedata/publisher/issues/347)).

## 4.6

### 4.6.0 (2021-11-10)

- Release version 4.6.

## 4.5

### 4.5.19 (2021-11-04)

- Enhanced error handling.

### 4.5.18 (2021-11-02)

- Set DYLD_LIBRARY_PATH on macOS.
- Restrict {} xpath evaluation for non-xpath attributes (all except select, test).

### 4.5.17 (2021-10-26)

- Set the number of publishing-runs for the server.

### 4.5.16 (2021-10-26)

- Increase verbosity of sp server (`sp server --verbose`).

### 4.5.15 (2021-10-20)

- Add new route for REST API to send data and get PDF in one request.

### 4.5.14 (2021-10-08)

- Deprecate NewPage, use ClearPage. See [#345](https://github.com/speedata/publisher/issues/345) for details.

### 4.5.13 (2021-10-07)

- Include color profile in distribution ([#344](https://github.com/speedata/publisher/issues/344)).

### 4.5.12 (2021-10-06)

- Internal/Tablerule: replace filled rectangular by PDF line.
- Set vertical excess space behavior for rowspan in tables.

### 4.5.11 (2021-09-23)

- Colored QR codes.

### 4.5.10 (2021-09-13)

- Switch back to Lua based XML reader.

### 4.5.9 (2021-09-12)

- Allow Br before Image ([#342](https://github.com/speedata/publisher/issues/342))

### 4.5.8 (2021-08-30)

- Remove spurious line break in HTML ([#340](https://github.com/speedata/publisher/issues/340)).

### 4.5.7 (2021-08-25)

- Bugfix for self closing HTML tags ([#339](https://github.com/speedata/publisher/issues/339)).
- Better length calculation in XPath expressions.

### 4.5.6 (2021-07-16)

- New layout function `sd:tounit()` for unit conversion.
- PlaceObject keepposition="yes" with absolute positioning.

### 4.5.5 (2021-07-06)

- Allow SetGrid to access data.

### 4.5.4 (2021-07-02)

- HSpace at the beginning of text ([#338](https://github.com/speedata/publisher/issues/338)).

### 4.5.3 (2021-07-02)

- Ignore data attributes for css styling ([#337](https://github.com/speedata/publisher/issues/337)).

### 4.5.2 (2021-06-01)

- Handle double XInclude with the new XML parser.

### 4.5.1 (2021-05-25)

- Internal changes (named attributes, more CSS alike style names).
- New Go based XML reader.

## 4.4

### 4.4.1 (2021-05-25)

- Bugfix for InsertPages ([#335](https://github.com/speedata/publisher/issues/335)).

### 4.4.0 (2021-05-11)

- Release version 4.4.

## 4.3

### 4.3.21 (2021-05-11)

- Warning for Windows users and non-ascii path names ([#310](https://github.com/speedata/publisher/issues/310)).

### 4.3.20 (2021-05-04)

- Bugfix for multiple NewPage ([#334](https://github.com/speedata/publisher/issues/334)).

### 4.3.19 (2021-05-03)

- Bugfix for InsertPages after NewPage ([#333](https://github.com/speedata/publisher/issues/333)).

### 4.3.18 (2021-04-27)

- Better border-collapse implementation ([#260](https://github.com/speedata/publisher/issues/260), [#332](https://github.com/speedata/publisher/issues/332)).

### 4.3.17 (2021-04-26)

- Various bugfixes ([#330](https://github.com/speedata/publisher/issues/330), [#331](https://github.com/speedata/publisher/issues/331), [#316](https://github.com/speedata/publisher/issues/316), [#317](https://github.com/speedata/publisher/issues/317)).

### 4.3.16 (2021-04-16)

- New alignment PlaceObject/hreference=center ([#327](https://github.com/speedata/publisher/issues/327)).
- Bugfix: NewPage openon="..." at end of document  ([#329](https://github.com/speedata/publisher/issues/329)).
- Print md5sum of XML files with --verbose.

### 4.3.15 (2021-04-15)

- New PDFOption for hyperlink borders.
- Transparency with text and images.
- MetaPost enhancements.

### 4.3.14 (2021-03-24)

- Change MetaPost variable names, add page.* variables.
- Bugfix error on `sd:file-exists()` and external resource (again).

### 4.3.13 (2021-03-23)

- MetaPost CSS colors and bug fixes.
- Bugfix error on `sd:file-exists()` and external resource.

### 4.3.12 (2021-03-16)

- Bugfix for Incscape on Windows ([#324](https://github.com/speedata/publisher/issues/324)).
- Set language on `Hyphenation` ([#319](https://github.com/speedata/publisher/issues/319)).

### 4.3.11 (2021-03-16)

- Bugfix for Incscape on Windows ([#324](https://github.com/speedata/publisher/issues/324)).
- Include metapost format in distribution.

### 4.3.10 (2021-03-12)

- Basic MetaPost functionality.

### 4.3.9 (2021-03-10)

- Better error message for problems running sdluatex.

### 4.3.8 (2021-03-09)

- Grow image if needed (maxwidth,maxheight set and stretch="yes") ([#321](https://github.com/speedata/publisher/issues/321)).

### 4.3.7 (2021-03-08)

- Bugfix visible-pagenumbers ([#320](https://github.com/speedata/publisher/issues/320)).

### 4.3.6 (2021-02-23)

- Bugfix Tablefoot ([#315](https://github.com/speedata/publisher/issues/315)).
- Cleanup Go source organization.
- Allow hyperlinks for Image and Box.

### 4.3.5 (2021-02-12)

- New variable for page sectioning (`_matter`).
- Bugfix li/p ([#313](https://github.com/speedata/publisher/issues/313)).
- `sd:merge-pagenumbers()` with hyperlinks.
- New layout function `sd:visible-pagenumber()`.
- Link to pages (`&lt;A page="..."`).
- Document parts (frontmatter, mainmatter) for different page numbering.
- New xpath function `sd:romannumeral()`.

### 4.3.4 (2021-02-04)

- Set temporary directory in server mode.

### 4.3.3 (2021-01-20)

- Empty &lt;p&gt; in HTML mode creates an empty line ([#309](https://github.com/speedata/publisher/issues/309)).
- Bugfix: space creates a new line in HTML mode ([#308](https://github.com/speedata/publisher/issues/308)).

### 4.3.2 (2021-01-19)

- Bugfix for newlines introduced by empty attributes ([#306](https://github.com/speedata/publisher/issues/306)).
- Support for mulitple br tags in HTML ([#303](https://github.com/speedata/publisher/issues/303), [#305](https://github.com/speedata/publisher/issues/305)).
- Bugfix for rowspan in table head ([#300](https://github.com/speedata/publisher/issues/300)).

### 4.3.1 (2021-01-13)

- `$_lastpage` handles final NewPage ([#299](https://github.com/speedata/publisher/issues/299)).
- Empty paragraph results in newline ([#297](https://github.com/speedata/publisher/issues/297)).
- Fix indentation of UL/OL, set fontfamily.
- Harfbuzz: fix accents placement ([#296](https://github.com/speedata/publisher/issues/296), [#298](https://github.com/speedata/publisher/issues/298)).
- HTML: allow br in elements ([#293](https://github.com/speedata/publisher/issues/293)).
- HTML parser: handle void elements.
- Windows 64 bit package

## 4.2

### 4.2.0 (2021-01-09)

- Release version 4.2

## 4.1

### 4.1.25 (2021-01-06)

- Rewrite command Initial (backwards incompatible change) ([#287](https://github.com/speedata/publisher/issues/287)).

### 4.1.24 (2021-01-04)

- Styling of li::before ([#286](https://github.com/speedata/publisher/issues/286)).
- Underline after dash ([#291](https://github.com/speedata/publisher/issues/291)).
- Bookmark at PlaceObject level ([#290](https://github.com/speedata/publisher/issues/290)).
- Bugfix incorrect line height ([#289](https://github.com/speedata/publisher/issues/289)).

### 4.1.23 (2020-12-15)

- Implement li::before for alternative bullet points. ([#286](https://github.com/speedata/publisher/issues/286))

### 4.1.22 (2020-12-11)

- Bugfix for right-to-left and empty strings ([#285](https://github.com/speedata/publisher/issues/285)).

### 4.1.21 (2020-12-08)

- Beautify version information ([#284](https://github.com/speedata/publisher/issues/284)).
- Bugfix for incorrect font scaling ([#283](https://github.com/speedata/publisher/issues/283)).

### 4.1.20 (2020-12-07)

- Bugfix for thin lines in qrcodes ([#282](https://github.com/speedata/publisher/issues/282)).

### 4.1.19 (2020-12-03)

- Lots of minor changes (documentation and re-organization of internal code).

### 4.1.18 (2020-11-23)

- New options columndirection in Pagetype.
- Bugfix for initials in rtl mode.
- Re-organize Go files, move sp server to a separate package.

### 4.1.17 (2020-11-18)

- Fixes for bidi text/right to left text, documentation updates.

### 4.1.16 (2020-11-13)

- Bugfix for background-color and word space.

### 4.1.15 (2020-11-12)

- Some right-to-left and mixed ltr/rtl fixes.
- Bugfix for rowspan in table heads ([#279](https://github.com/speedata/publisher/issues/279), [#280](https://github.com/speedata/publisher/issues/280)).
- Remove doctype from XML catalog (this is due to a regression in VSCode/XML mode).
- Report missing glyphs for harfbuzz mode.

### 4.1.14 (2020-10-30)

- Automatic NewPage before SavePages (forward mode).
- Bidi algorithm (experimental).

### 4.1.13 (2020-10-28)

- Set page width and page height at Pagetype.
- Bugfix color at end of a paragraph ([#276](https://github.com/speedata/publisher/issues/276)).

### 4.1.12 (2020-10-27)

- Paragraph: allow direction setting (experimental).
- Bugfixes for harfbuzz mode.
- Allow setting of fontloader in sp/config.
- Higher resolution for QA images.
- Schema fix (languages).

### 4.1.11 (2020-10-22)

- Better accents placement in harfbuzz mode (RTL).
- Bugfix for hyphenation after a `&lt;br>` ([#274](https://github.com/speedata/publisher/issues/274)).
- Deprecate `fontface` on text commands (Paragraph, Textblock, Initial, Text, Barcode, Table, Nobreak). This command will stop working in version 5.

### 4.1.10 (2020-10-21)

- Set language on `Span` ([#273](https://github.com/speedata/publisher/issues/273)).
- Allow language short codes in XML Schema.
- First preparations for right-to-left text.
- Schema fix (allow XPath in Paragraph/language).
- Bugfix textformat/margin bottom and border bottom ([#262](https://github.com/speedata/publisher/issues/262)).

### 4.1.9 (2020-10-19)

- Bugfix reordering bookmarks with forward pagestore.
- Guess language/script if not explicitly set (harfbuzz mode).
- Lazy loading of fonts.
- Bugfix empty first table head and last table foot ([#271](https://github.com/speedata/publisher/issues/271)). 
- More diagnostic information on failed server mode publisher run.

### 4.1.8 (2020-10-13)

- Bugfix textformat in table cells ([#270](https://github.com/speedata/publisher/issues/270)).
- Add kerning in harfbuzz mode, allow kern tracing.
- Disable liga in harfbuzz mode.
- Replace font CrimsonText by CrimsonPro.

### 4.1.7 (2020-10-07)

- Add basic support for simplified Chinese. ([#204](https://github.com/speedata/publisher/issues/204))
- Fix HTML whitespace handling.

### 4.1.6 (2020-10-05)

- Better padding-left and padding-right on Paragraph (fixes [#267](https://github.com/speedata/publisher/issues/267)).
- Control vertical spacing in HTML mode and HTML data.
- Enhance harfbuzz font loader (more supported fonts).
- Server temporary directories can start with any character.

### 4.1.5 (2020-10-01)

- Access options during the prepressing stage.

### 4.1.4 (2020-10-01)

- Bugfix ordering of ul/ol li ([#264](https://github.com/speedata/publisher/issues/264)).
- Margin notes left for Paragraph.

### 4.1.3 (2020-09-28)

- Fix HTML ul/ol and li.
- Allow xinclude in table cells ([#263](https://github.com/speedata/publisher/issues/263)).

### 4.1.2 (2020-09-23)

- Few bugfixes and improvements (Barcode/keepfontsize).

### 4.1.1 (2020-09-14)

- New paragraph construction mode and new HTML processing, better language support.

### 4.1.0 (2020-09-08)

- Bugfix for locale setting.

## 4.0

### 4.0.0 (2020-09-07)

- Release stable version 4.0.0.

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

## 2.9

### 2.9.15 (2017-07-12)

- Force pagetype if provided at NewPage, strip NL/Tab at beginning / end of paragraph.

### 2.9.14 (2017-06-27)

- Allow font-family setting in CSS for custom element.

### 2.9.13 (2017-06-27)

- Bugfix numerical entities in data. New: base64 decode, filecontents.

### 2.9.12 (2017-06-16)

- Bugfix PlaceObject/hreference=right and absolute positioning

### 2.9.11 (2017-05-18)

- Lazy evaluation of defaultcolor / Pagetype, minor bugfixes.

### 2.9.10 (2017-05-10)

- New command: Groupcontents to insert a group in a Td. Bugfix XPath parser, sd:current-framenumber().

### 2.9.9 (2017-05-08)

- Lazy evaluation of Grid in Pagetype ([#130](https://github.com/speedata/publisher/issues/130)), bugfix nested tables ([#129](https://github.com/speedata/publisher/issues/129)), improved Initials (color), bugfix cursor movement ([#128](https://github.com/speedata/publisher/issues/128))

### 2.9.8 (2017-04-24)

- Bugfix XML attributes with quotation marks

### 2.9.7 (2017-04-16)

- New command Initial.

### 2.9.6 (2017-03-21)

- Enhancements on Image/bleed="auto", extra allocation margin on PlaceObject

### 2.9.5 (2017-03-09)

- Absolute positioning now allows allocate="yes".
- New internal variables _bleed, _pagewidth, _pageheight
- New attribute bleed="..." on Image.

### 2.9.4 (2017-02-24)

- Box with backgroundcolor="-" only allocates cells.

### 2.9.3 (2017-02-20)

- Bugfix resetmarks, new attribute defaultcolor on Pagetype, remove obsolete commands.

### 2.9.2 (2017-02-10)

- Bugfix for processing instructions in the XML file (will be ignored now)
- New feature: style &lt;span> and other elemnts in data with CSS.

### 2.9.1 (2017-02-08)

- Bugfix: top-distance in Tr

## 2.8

### 2.8.1 (2017-02-06)

- Fix hotfolder (variable directory)

## 2.7

### 2.7.13 (2017-02-03)

- Use tempdir setting to calculate imagecache.

### 2.7.12 (2017-01-26)

- New command DefineFontalias
- Bugfixes for multipage tables

### 2.7.11 (2017-01-16)

- Makeindex: make page number attribute variable
- Bugfix: objects with ht > 0 and “jump to next row”
- Remove images from cache when 404.

### 2.7.10 (2017-01-06)

- Allow setting of error correction level for QR-codes.

### 2.7.9 (2016-11-28)

- allowbreak=" " does not break at a hyphen character anymore.
- NoBreak default is now 'keeptogether' which prevents a line break.

### 2.7.8 (2016-11-25)

- Change U+2011 (NON-BREAKING HYPHEN) to U+002D (HYPHEN-MINUS) and don't insert a break.

### 2.7.7 (2016-10-21)

- Don't clear image cache before first run

### 2.7.6 (2016-10-14)

- Better image cache - don't re-load images during the same run.

### 2.7.5 (2016-10-12)

- New method for image caching. Rename Image/maxsize to visiblebox.

### 2.7.4 (2016-10-03)

- New command Trace for debugging selections. Remove show-* on Options.
- Behavior change with NextRow, remove command EmptyLine, compatibility switch with Compatibility.
- New Option: defaultarea.

### 2.7.3 (2016-09-14)

- New API /v0/statusfile/&lt;id> to get the file publisher.status.

### 2.7.2 (2016-09-14)

- When PlaceObject goes past the right margin (for example in full width text), go to next row.

### 2.7.1 (2016-09-08)

- Fix error when fallback image is not found
- Emtpy attributes in Attribute don't give a table value

### 2.7.0 (2016-08-18)

- Disable German layoutrules, bugfix ([#104](https://github.com/speedata/publisher/issues/104)) distribution error

## 2.6

### 2.6.1 (2016-08-18)

- Bugfix for Mac and Linux ZIP files

## 2.5

### 2.5.13 (2016-08-10)

- Bugfix for large tables (> 200 pages?)

### 2.5.12 (2016-08-08)

- Bugfixes for paragraph shape, move LuaTeX binary to different directory

### 2.5.11 (2016-08-02)

- Add padding-* to Stylesheet, allow image styling with CSS (padding only), add padding-* to Image

### 2.5.10 (2016-08-02)

- Many improvements for Text/Output and allocate="yes"
- Remove all German commands from the manual
- New attributes for Text: fontface, color and textformat
- Improvements to the documentation (spelling fixes), Language string "English (Great Britan)" corrected

### 2.5.9 (2016-07-06)

- Bugfix related to “jump to next area” and multipage table/

### 2.5.8 (2016-07-02)

- Bugfix get remaining height jumps to last line, even if “full”

### 2.5.7 (2016-06-25)

- Bugfix allocation on non-integer columns

### 2.5.6 (2016-06-25)

- Remove obsolete command ProcessRecord, add limit option for ProcessNode, bugfix Output/Text paragraph shape ([#89](https://github.com/speedata/publisher/issues/89))

### 2.5.5 (2016-06-23)

- Various bugfixes / future objects and tables

### 2.5.4 (2016-06-20)

- Allow control over size of background-text in Td.

### 2.5.3 (2016-06-18)

- Include bugfixes from 2.4.4

### 2.5.2 (2016-06-13)

- (2.4.2) A few bugfixes related to sd:current-framenumber(), minheight in Textblock and looking for next free row.

### 2.5.1 (2016-06-10)

- Interpret &lt;sub> and &lt;sup> in data.
- Bugfix: pagetype and NewPage, version assertion in Layout tag

## 2.4

### 2.4.4 (2016-06-18)

- Various bugfixes: leaders disappear on a linebreak, Nobreak allows setting for font family, escape attribute contents, fix for bad images.

### 2.4.3 (2016-06-17)

- Bugfix related to an improper fix in 2.4.2 / find next free row for an object

### 2.4.2 (2016-06-13)

- A few bugfixes related to sd:current-framenumber(), minheight in Textblock and looking for next free row.

### 2.4.1 (2016-06-09)

- Bugfix: pagetype and NewPage, version assertion in Layout tag

### 2.4.0 (2016-06-07)

- Release version 2.4.0

## 2.3

### 2.3.77 (2016-06-06)

- Fallback filename for image (in case of image not found)

### 2.3.76 (2016-06-02)

- New API /v0/layout/&lt;id> to get the layout.xml

### 2.3.75 (2016-05-31)

- New API /v0/data/&lt;id> to get the data.xml
- Bugfix empty value should not make a space.

### 2.3.74 (2016-05-23)

- New API /v0/status to get all statuses

### 2.3.73 (2016-05-20)

- Allow frame number in sd:allocated()

### 2.3.72 (2016-04-28)

- Bugfix: element names with dash accpeted

### 2.3.71 (2016-04-28)

- New xpath function sd:allocated(x,y,name)

### 2.3.70 (2016-04-26)

- Messages can set error code on error

### 2.3.69 (2016-04-25)

- Bugfix indent and parshape with allocate="auto"

### 2.3.68 (2016-04-08)

- Bugfix: API /v0/pdf/&lt;id> must wait for the pdf file to finish. Error happens with mutliple runs

### 2.3.67 (2016-04-07)

- ForAll has a new attribute: start to give the starting point (default: 1)

### 2.3.66 (2016-04-05)

- Change mechanism on image wrapping, only partly enabled.

### 2.3.65 (2016-03-29)

- Various bugfixes with HTML output and Output/Text

### 2.3.64 (2016-03-21)

- Underline in data respects CSS style

### 2.3.63 (2016-03-18)

- Bufgfix line height calculation with Output/Text and allocation = auto

### 2.3.62 (2016-03-17)

- Various bugfixes: paragraph shape, server wait until run finished

### 2.3.61 (2016-03-14)

- New feature U/dashed="yes"

### 2.3.60 (2016-03-14)

- Bugfix for HTML tables and sp --ignore-case / font files

### 2.3.59 (2016-02-24)

- Bugfix HTML tables

### 2.3.58 (2016-02-22)

- Experimental HTML tables

### 2.3.57 (2016-02-19)

- New sp option --ignore-case for case insensitive file loading

### 2.3.56 (2016-02-18)

- Bufgix Ouptut/allocate="auto"

### 2.3.55 (2016-02-18)

- halign on PlaceObject
- Much better wrap around with Output allocate="auto".

### 2.3.54 (2016-02-08)

- New XPath function sd:randomitem(Value, Value, Value)

### 2.3.53 (2016-02-06)

- Nobreak allows to cut text with ...
- PDF producer is set to LuaTeX, creator is set to speedata Publisher - version number
- Various bugfixes

### 2.3.52 (2016-01-21)

- Various bugfixes: multi paragraph Output with par shape, decode-html

### 2.3.51 (2016-01-18)

- Temporary directory configurable.

### 2.3.50 (2016-01-18)

- Dashed rules
- Leaders in HSpace

### 2.3.48 (2016-01-12)

- Server mode: id always start with a non-zero value.

### 2.3.47 (2016-01-11)

- New PDFOption Duplex

### 2.3.46 (2016-01-08)

- Vertical spacing between grid cells
- PDF options PrintScaling and PickTrayByPDFSize

### 2.3.45 (2015-12-18)

- API call /v0/status returns time stamp-

### 2.3.44 (2015-12-16)

- Write warnings to status file

### 2.3.43 (2015-12-15)

- Options / imagenotfound: error or warning

### 2.3.42 (2015-12-13)

- Access foo/@bar attributes on sub elements
- New shape: Circle

### 2.3.41 (2015-12-10)

- New xpath function substring()

### 2.3.40 (2015-12-08)

- Bugfix when reading a config file

### 2.3.39 (2015-12-07)

- Server mode honors jobname from publisher.cfg

### 2.3.38 (2015-11-30)

- New XPath function 'string-length()', bug fixes, prepare for LuaTeX 0.85

### 2.3.37 (2015-11-19)

- Bugfix for broken utf8/status file

### 2.3.36 (2015-11-19)

- Workaround for broken publisher.status file
- Table and vreference=bottom works.

### 2.3.35 (2015-11-06)

- Schematron rules in RelaxNG schema
- Image/href can omit file: scheme

### 2.3.34 (2015-11-04)

- Bugfix: configuration file requires end of line marker on last line

### 2.3.33 (2015-11-04)

- Possible bug fix with LoadDataset/Windows

### 2.3.32 (2015-09-18)

- Bugfix: height calculation in tables with row where break-below=no
- Much better table debugging with --trace
- Dynamic table heads can be removed
- Action / Mark can have multiple entries

### 2.3.31 (2015-09-12)

- New xpath function 'contains()'

### 2.3.30 (2015-09-08)

- New API call /v0/delete/id to remove the publishing request
- New xpath function sd:keep-alternating() to re-use the current alternating value.

### 2.3.29 (2015-08-24)

- Bugfix with servermode on windows

### 2.3.28 (2015-08-11)

- Textblock can have a minimum height.
- Option crop can take a length.

### 2.3.27 (2015-08-07)

- Bugfix for Overlay command: Image can be stacked on another element.

### 2.3.26 (2015-08-07)

- New command Overlay to stack objects.

### 2.3.25 (2015-08-05)

- New command line option --extra-xml and new configuration option extraxml to add additional XML files to the layout instructions (similar to xinclude).
- New configuration option var to add variables.
- New server mode api parameter vars to send additional variables to the publishing process.
- New command line option --varsfile to define more variables.

### 2.3.24 (2015-06-26)

- Add option »trimmarks«, show the trim box when show-grid is turned on.

### 2.3.23 (2015-06-25)

- Bugfix width calculation in the grid

### 2.3.22 (2015-06-19)

- Bugfix with dx and nx in SetGrid

### 2.3.21 (2015-05-30)

- New option crop for pages with a tight cropbox.

### 2.3.20 (2015-04-21)

- Bugfix: width Table and Rule and grid distance

### 2.3.19 (2015-04-20)

- PositioningFrames can now use the current data ({@attrib} for example)
- Bugfix/workaround for an issue introduced in 2.3.18 in multi line Td cells.

### 2.3.18 (2015-04-08)

- Bugfixes: replace() and $1, $2, ... / multi line &lt;Td align="center">...&lt;/Td> contents

### 2.3.17 (2015-03-25)

- Experimental garbage collection, in effect with SetVariable.

### 2.3.16 (2015-03-11)

- Command NoBreak to disable a line break within.

### 2.3.15 (2015-03-09)

- API changes: make jobname configurable through parameter, better error messages.

### 2.3.14 (2015-03-04)

- Server-mode: /v0/pdf/&lt;id&gt; returns the PDF
- Server-mode: add timestamp for /v0/publish/&lt;id&gt;

### 2.3.12 (2015-02-27)

- New api call /available -> 200 OK, /v0/publish returns 201

### 2.3.11 (2015-02-26)

- Grid distance horizontal can be set.

### 2.3.10 (2015-02-25)

- Bugfix: index entry without contents crashes the publisher.

### 2.3.9 (2015-02-24)

- Bugfixes (sp server mode protocol file, infinite loop on malformed utf8 data)
- Empty attributes (attr="") are treated as nil. empty(@attr) now returns true().

### 2.3.8 (2015-02-21)

- Rotate (steps of 90°) for images
- New xpath function sd:aspectratio('imgname.png')
- Simple if/then/else expressions in XPath

### 2.3.7 (2015-02-19)

- Background text for table cells (td)

### 2.3.6 (2015-02-12)

- publisher.status file contains the (error-)messages.

### 2.3.4 (2015-01-27)

- Bugfix: spot colors apply to stroking and non-stroking operations

### 2.3.3 (2015-01-26)

- Some CSS for rule, direct color definition.

### 2.3.2 (2015-01-22)

- New server mode for remote publishing.

## 2.2

### 2.1.36 (2015-01-15)

- Add all CSS level 3 colors (see https://www.w3.org/TR/css-color-3/ for a list)

### 2.1.35 (2014-12-19)

- Allow bookmarks on any level (experimental)

### 2.1.34 (2014-12-18)

- New function sd:attr() to access attribute with a dynamically constructed name.

### 2.1.32 (2014-12-01)

- XML parser / XInclude takes --extra-dir into account

### 2.1.28 (2014-11-11)

- Allow specification of hyphen char in textformat.

### 2.1.27 (2014-11-06)

- New example "mail merge"

### 2.1.26 (2014-10-29)

- New command: Frame. Can be used inside PlaceObject to frame an object.

### 2.1.23 (2014-10-13)

- Rounded corners on PlaceObject / Frame

### 2.1.22 (2014-10-09)

- Transformations can be nested inside PlaceObject

### 2.1.21 (2014-10-08)

- Custom spot colors
- Transformation origin for rotate and matrix (PlaceObject)

### 2.1.20 (2014-09-16)

- Copy-of copys does not destroy the underlying content.

### 2.1.18 (2014-09-09)

- A transformation matrix can be set on PlaceObject

### 2.1.16 (2014-08-22)

- Don't break lines on / anymore, unless specified in allowbreaks="/".

### 2.1.15 (2014-08-18)

- Experimental server-mode (/v0/format)

### 2.1.14 (2014-08-15)

- Hyphenation = yes/no at DefineTextformat

### 2.1.13 (2014-08-12)

- Basic version of tokenize() and replace(), basic server mode.
- Colors can have overprinting enabled.
- Spot colors (PANTONE and HKS)

### 2.1.12 (2014-07-25)

- New command »Color« to switch to a different text color in text.

### 2.1.10 (2014-07-03)

- Change behaviour of allowbreak=".." at Paragraph. Space must be made explicit.
- New xpath function sd:dummytext() and sd:loremipsum() for a sample text (lorem ipsum)

### 2.1.9 (2014-06-27)

- XInclude rebirth

### 2.1.8 (2014-06-24)

- Extend table rows (Tr) to re-use as table header.
- Merge pagenumbers now accept page ranges.

### 2.1.7 (2014-06-06)

- Bugfix for table in table and alignment. align="right" didn't work.

### 2.1.6 (2014-06-05)

- Experimental option 'allowbreak' on Paragraph to provide a list of characters where line break may occur.
- sp --quiet for console-less output
- Parallelise sp compare for much better performance.

### 2.1.5 (2014-05-28)

- Bugfix table cells with align=center and a fixed width.

### 2.1.3 (2014-05-20)

- Allow hyphenation in the second word in compound words such as longword-anotherlongword. Also enable line breaks after "/"

### 2.1.1 (2014-05-19)

- New implemtation of paragraph splitting, should be completely backward compatible.

### 2.1.0 (2014-05-15)

- New behaviour of contents in table cells (Td). The rules of HTML (see https://developer.mozilla.org/en-US/docs/Web/HTML/Block-level_elements - HTML block elements) are followed as far as possible.

