---
title: "Version 2"
weight: 40
type: docs
---

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

