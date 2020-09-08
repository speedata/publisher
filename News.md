# NEWS

This file gets updated before a release. There is a [detailed changelog](https://doc.speedata.de/publisher/en/changelog/#ch-changelog) in the [manual](https://doc.speedata.de/publisher/).

## Version 4

Released 2020-09-07

## Most visible changes from version 3.8

* New XPath functions `firstmark()` and `lastmark()` to get the first and the last marker on a page. Useful for headers in dictionaries.
* New internal variable `$_lastpage` which has the number of the last page from the previous run.
* Improved server mode
* New HTML mode
* New English manual
* Better support for Adobe Acrobat (remove colored links)
* External image conversion tools (for example Inkscape)

The main reason to release this as version 4 is that this version includes some changes that might break the backward compatibility promise.
The paragraph building mode is completely rewritten in version 4 and could lead to different results in line breaking.

## Plans for Version 4.2

* Better OpenType (`.otf` and `.ttf`) font support. Including font features, colored fonts and perhaps variable fonts.
* Support for non-western scripts such as CJK and Arabic. This includes left to right typesetting.
* Print CSS support. This includes a completely new HTML parser and renderer.



