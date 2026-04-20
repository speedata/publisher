---
title: "Layout Functions"
weight: 162
type: docs
---

The Publisher's layout functions are defined in the namespace `urn:speedata:2009/publisher/functions/en` (denoted by `sd:` below).
In addition, there are [XPath standard functions]({{< relref "xpathfunctions" >}}) and [user-defined functions]({{< relref "/reference/function" >}}).

Optional parameters are marked with square brackets. The ellipsis `...` means the last value can be repeated.


## Page and Grid

`sd:current-page()`
: Return the current page number.

`sd:current-column([<area>])`
: Return the current column. If area is given, return the column of the given positioning area.

`sd:current-row([<area>])`
: Return the current row. If area is given, return the row of the given positioning area.

`sd:current-framenumber(<area>)`
: Return the current frame number of the given positioning area.

`sd:number-of-columns([<area>])`
: Number of columns in the current grid or given area.

`sd:number-of-rows([<area>])`
: Number of rows in the current grid or given area.

`sd:allocated(x,y,[<areaname>],[<framenumber>])`
: Return true if the grid cell is allocated.

`sd:first-free-row(<area>)`
: Return the first free row of this area (experimental).

`sd:pagewidth(<unit>)`
: Get the width of the page in the given unit (as a number without unit). Example: `sd:pagewidth("mm")` returns `210` for an A4 page. This function initializes a page.

`sd:pageheight(<unit>)`
: Similar to `sd:pagewidth()`, for the height.

`sd:length(<what>[,<unit>])`
: Get the length of _what_ in the given unit (without unit). Example: `sd:length('_bleed','mm')` returns `3` if bleed is set to 3mm. _what_ can be `_bleed`, `_pagewidth` or `_pageheight`. Unit defaults to `mm`.


## Images

`sd:imagewidth(<filename>,[pagenumber],[pdfbox],[<unit>])`
: Natural width of the image in grid cells. With an optional unit, returns width as a multiple of that unit. Note: if the image is not found, the placeholder width is returned. Arguments can contain a page number and PDF box, see [images]({{% relref "imagesandgraphics" %}}).

`sd:imageheight(<filename>,[pagenumber],[pdfbox],[<unit>])`
: Natural height of the image in grid cells. See `sd:imagewidth()` for details.

`sd:aspectratio(<filename>,[pagenumber],[pdfbox])`
: Return width/height ratio (< 1 for portrait, > 1 for landscape).

`sd:number-of-pages(<filename>)`
: Return the number of pages of the given (PDF) file.

`sd:file-exists(<filename>)`
: Return `true()` if the file exists in the search path.


## Groups

`sd:group-width(<name>[,<unit>])`
: Return the group's width in grid cells. With an optional unit, returns width as a multiple of that unit. Example: `sd:group-width('My group','mm')`.

`sd:group-height(<name>[,<unit>])`
: Return the group's height. See `sd:group-width()` for details.


## Text and Formatting

`sd:format-number(<number>, <thousands separator>, <decimal separator>)`
: Format the number with separators. Example: `sd:format-number(12345.67, ',','.')` returns `12,345.67`.

`sd:format-string(<object>,...,<format>)`
: Format objects using `printf()`-style instructions.

`sd:dummytext([<count>])`
: Return "Lorem ipsum..." dummy text. The count controls repetition.

`sd:loremipsum()`
: Alias for `sd:dummytext()`.

`sd:markdown(<text>)`
: Render text as markdown. See [Markdown]({{% relref "markdown" %}}).

`sd:decode-html(<node>)`
: Convert text like `&lt;i&gt;italic&lt;/i&gt;` into HTML markup.

`sd:symbol(<value>[,<value>,...])`
: Return characters from the current font by glyph ID. Example: `sd:symbol(123, 444)`.

`sd:romannumeral(<number>)`
: Convert the number to a lowercase Roman numeral.


## Variables and State

`sd:variable(<name>[, ...])`
: Same as `$name`, but allows dynamic name construction. If `$i` is 3, `sd:variable('foo',$i)` reads `$foo3`.

`sd:variable-exists(<name>)`
: True if the variable is defined.

`sd:attr(<name>[, ...])`
: Same as `@name`, but allows dynamic attribute name construction.

`sd:alternating(<type>, <text>[,<text>,...])`
: Return the next argument on each call. Example: `sd:alternating("tbl", "White","Gray")` for alternating table colors.

`sd:keep-alternating(<type>)`
: Use the current value of `sd:alternating()` without advancing.

`sd:reset-alternating(<type>)`
: Reset the state for `sd:alternating()`.

`sd:even(<number>)`
: True if the number is even.

`sd:odd(<number>)`
: True if the number is odd.

`sd:mode(<string>[,<string>,...])`
: Return `true()` if one of the given modes is set. See [controlling the layout]({{< relref "controllayout" >}}).

`sd:randomitem(<value>[,<value>,...])`
: Return one of the values randomly.


## Page Markers and Directories

`sd:pagenumber(<mark>)`
: Return the page number where the given mark was placed. See [Mark]({{% relref "/reference/mark" %}}).

`sd:visible-pagenumber([<number>])`
: Return the user-visible page number for the given real page number. Without argument, uses the current page.

`sd:firstmark(<pagenumber>)`
: The first marker of the given page. Useful for dictionary headings.

`sd:lastmark(<pagenumber>)`
: The last marker of the given page.

`sd:merge-pagenumbers(<pagenumbers>,[<range separator>],[<space separator>],[hyperlinks])`
: Merge page numbers. `"1, 3, 4, 5"` becomes `1, 3–5`. Sorts and removes duplicates. With `hyperlinks = true()`, page numbers become clickable.

`sd:count-saved-pages(<name>)`
: Return the number of pages saved with `<SavePages>`.


## Units and Calculation

`sd:tounit(<target unit>,<value>[,<decimals>])`
: Convert a value to another unit. Example: `sd:tounit('pt','1pc')` returns 12.

`sd:dimexpr(<unit>,<expression>)`
: Evaluate a calculation with units. Example: `sd:dimexpr('cm',' (40mm + 2cm) / 2 ')` returns 3.0.


## Files and Binary Data

`sd:decode-base64(<string>)`
: Convert a base64-encoded string to binary content.

`sd:filecontents(<binarycontent>)`
: Save the content to a temporary file and return the filename.


## Hash Functions

`sd:md5(<value>[,<value>,...])`
: Return the MD5 hash as a hex string. Example: `sd:md5('hello ', 'world')` returns `5eb63bbbe01eeed093cb22bb8f5acdc3`.

`sd:sha1(<value>[,<value>,...])`
: Return the SHA-1 hash as a hex string.

`sd:sha256(<value>[,<value>,...])`
: Return the SHA-256 hash as a hex string.

`sd:sha512(<value>[,<value>,...])`
: Return the SHA-512 hash as a hex string.
