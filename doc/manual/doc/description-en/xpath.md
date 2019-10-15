title: XPath expressions
---
XPath expressions
=================

The speedata Publisher accepts XPath expressions in some attributes.
These attributes are called `test` or `select` or documented as such. In
all other attributes XPath expressions can be used via curly braces (`{`
and `}`). In the following example XPath expressions are used in the
attribute `width` and in the element `Value`. The width of the textblock
is taken from the variable `$width`, the contents of the paragraph is
the string value of the current node.

    <PlaceObject>
      <Textblock width="{$width}" fontface="text" textformat="text with indentation">
        <Paragraph>
          <Value select="."/>
        </Paragraph>
      </Textblock>
    </PlaceObject>

The next example uses the `test` attribute. The given XPath expression
must return either *true* or *false*.

    <Switch>
      <Case test="$article = 1 and sd:current-page() > 4">
        ....
      </Case>
      <Otherwise>
        ....
      </Otherwise>
    </Switch>

The following XPath expressions are handled by the software:
------------------------------------------------------------

-   Number: Return the value without change: `5`
-   Text: Return the text without change: `'hello world'`
-   Arithmetic operation (`*`, `div`, `idiv`, `+`, `-`, `mod`). Example:
    `( 6 + 4.5 ) * 2`
-   Variables. Example: `$column + 2`
-   Access to the current node (dot operator). Example: `. + 2`
-   Access to subelements. Examples: `productdata`, `node()`, `*`, `foo/bar`
-   Attribute access in the current node. Example `@a`
-   Attribute access in subnodes, for example `foo/@bar`
-   Boolean expressions: `<`, `>`, `<=`, `>=`, `=`, `!=`. Attention, the
    less than symbol `<` **must** be written in XML as `&lt;`, the
    symbol `>` **can** be written as `&gt;`. Example: `$number > 6`. Can
    be used in tests.
-   Simple if/then/else expressions: `if (...) then ... else ...`.

The following XPath functions are known to the system:
------------------------------------------------------

There are two classes of XPath functions: standard XPath functions and
speedata Publisher specific ones. The specific functions are in the
namespace `urn:speedata:2009/publisher/functions/en` (denoted by `sd:`
below). The standard functions should behave like documented by the
XPath 2.0 standard.


Function | Description
---------|------------
sd:allocated(x,y,\<areaname\>,\<framenumber\>) | Return true if the grid cell is allocated, false otherwise (since 2.3.71).
sd:current-page() | Return the current page number.
sd:current-row(\<name\>) | Return the current row. If `name` is given, return the row of the given frame.
sd:current-column(\<name\>) | Return the current column. If `name` is given, return the column of the given frame.
sd:current-framenumber(\<name\>) | Return the current frame number of given positioning area.
sd:count-saved-pages(\<name\>)  | Return the number of saved pages from `<SavePages>`.
sd:dimexpr(\<string>) | Evaluate the string as a dimension with a unit. Handy if you want to add / multiply two lengths.
sd:alternating(\<type\>, \<text\>,\<text\>,.. ) | On each call the next element will be returned. You can define more alternating sequences by using distinct type values. Example: `sd:alternating("tbl", "White","Gray")` can be used for alternating color of table rules. To reset the state, use `sd:reset-alternating(<type>)`.
sd:filecontents(\<binarycontent>) | Save the given contents into a file and return the file name.
sd:first-free-row(<areaname>) | Return the first free row of this area (experimental).
sd:reset-alternating(\<type\>) | Reset alternating so the next `sd:alternating()` starts again from the first element.
sd:keep-alternating(\<type\>) | Use the current value of `sd:alternating(<type>)` without changing the value.
sd:aspectratio(\<imagename>) | Return the result of the division width by height of the given image. (< 1 for portrait images, > 1 for landscape).
sd:attr(\<name\>, ...)|  Is the same as `@name`, but can be used to dynamically construct the attribute name. See example at `sd:variable()`.
sd:decode-base64(\<contents\>) | Expect a string encoded in base64 and return the binary contents.
sd:decode-html(\<node\>) | Change text such as `&lt;i&gt;italic&lt;/i&gt;` into HTML markup.
sd:merge-pagenumbers(\<pagenumbers\>,\<separator for range\>,\<separator for space\>) | Merge page numbers. For example the numbers `"1, 3, 4, 5"` are merged into `1, 3–5`. Defaults for the separator for the range is an en-dash (–), default for the spacing separator is ', ' (comma, space). This function sorts the page numbers and removes duplicates. When the separator for range is empty, the page numbers are separated each with the separator for the space.
sd:number-of-datasets(\<Sequence\>) | Return the number of records of the sequence.
sd:number-of-pages(\<filename or URI schema\>) | Determines the number of pages of a (PDF-)file.
sd:number-of-columns() | Number of columns in the current grid.
sd:number-of-rows() | Number of rows in the current grid.
sd:imageheight(\<filename or URI schema\>) | Natural height of the image in grid cells. Attention: if the image is not found, the height of the file-not-found placeholder will be returned. Therefore you need to check in advance if the image exists.
sd:imagewidth(\<filename or URI schema\>) | Natural width of the image in grid cells. Attention: if the image is not found, the width of the file-not-found placeholder will be returned. Therefore you need to check in advance if the image exists.
sd:file-exists(\<filename or URI schema\>) | True if file exists in the current search path. Otherwise it returns false.
sd:format-number(Number or string, thousands separator, comma separator) | Format the number and insert thousands separators and change comma separator. Example: `sd:format-number(12345.67, ',','.')` returns the string `12,345.67`.
sd:format-string(object, object, ... ,formatting instructions) | Return a text string with the objects formatted as given by the formatting instructions. These instructions are the same as the instructions by the C function `printf()`.
sd:even(\<number\>) | True if number is even. Example: `sd:even(sd:current-page())`
sd:odd(\<number\>) | True if number is odd.
sd:group-width(\<string\>[, \<unit\>]) | Return the number of gridcells of the given group’s width. The argument must be the name of an existing group. Example: `sd:group-width('My group')`. See `sd:group-height()` for description of the second parameter.
sd:group-height(\<string\>[, \<unit\>]) | Return the given group’s height (in gridcells). See `sd:group-width(...)` If provided with an optional second argument, it returns the height of the group in multiples of this unit. For example `sd:group-height('mygroup', 'in')` returns the group height in inches.
sd:group(\<string\>[,\<string>...]) | Evaluates to `true()` if one of the modes is given on the command line or set in the options.
sd:pagenumber(\<string\>) | Get the number of the page where the given mark is placed on. See the command [Mark](../commands-en/mark.html).
sd:randomitem(\<Value\>,\<Value\>, …) | Return one of the values.
sd:variable(\<name\>, ...) | The same as `$name`. This function allows variable names to be constructed dynamically. Example: `sd:variable('myvar',$num)` – if `$num` contains the number 3, the resulting variable name is `myvar3`.
sd:variable-exists(\<name\>) | True if variable `name` exists.
sd:sha1(\<value\>,\<value\>, …) | Return the SHA-1 sum of the concatenation of each value as a hex string. Example: `sd:sha1('hello ', 'world')` gives the string `2aae6c35c94fcfb415dbe95f408b9ce91ee846ed`.
sd:dummytext(\<count>) | Returns the dummy text "Lorem ipsum..." (more than 50 words, enough for a paragraph). Repeated count times if provided.
sd:loremipsum() | Same as `sd:dummytext()`

Function | Description
---------|------------
abs()      |
ceiling()  |
concat( \<value\>,\<value\>, … ) | Create a new text value by concatenating the arguments.
contains(\<haystack\>,\<needle\>)  | True if haystack contains needle.
count(\<text\>) | Counts all child elements with the given name. Example: `count(article)` counts, how many child elements with the name `article` exists.
ceiling() | Returns the smallest number with no fractional part that is not less than the value of the given argument.
empty(\<attribute\>) | Checks, if an attribute is (not) available.
false() | Return *false*.
floor() | Returns the largest number with no fractional part that is not greater than the value of the argument.
last() | Return the number of elements of the same named sibling elements. **Not yet XPath conform.**
local-name() | Return the local name (without namespace) of the current element.
lower-case(\<text>)  | Return the text in lowercase letters.
max()  |
min()  |
node()  |
not() | Negates the value of the argument. Example: `not(true())` returns `false()`.
normalize-space(\<text\>) | Return the text without leading and trailing spaces. All newlines will be changed to spaces. Multiple spaces/newlines will be changed to a single space.
position() | Return the position of the current node.
replace(\<input\>,\<regexp\>, \<replacement\>) | Replace the input using the regular expression with the given replacement text. Example: `replace("banana", "a", "o")` yields `bonono`.
string(\<sequence\>) | Return the text value of the sequence e.g. the contents of the elements.
string-join(\<sequence\>,separator) | Return the string value of the sequence, where each element is separated by the separator.
substring(\<input>,\<start>,\<length>) | Return the part of the string `input` that starts at `start` and optionally has the given length. `start` can be (in contrast to the XPath specification) negative which counts from the end of the input.
tokenize(\<input\>,\<regexp\>) | This function returns a sequence of strings. The input text is read from left to right. When the regular expression matches the current position, the text read so far from the last match is returned. Example (from the great XPath / XSLT book by M. Key): `tokenize("Go home, Jack!", "\W+")` returns the sequence `"Go", "home", "Jack", ""`.
string-length(\<string\>) | Return the length of the string in characters. Multi-byte UTF-8 sequences are counted as 1.
true() | Return *true*.
upper-case() |



