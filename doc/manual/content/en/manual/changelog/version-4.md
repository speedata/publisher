---
title: "Version 4"
weight: 20
type: docs
---

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

