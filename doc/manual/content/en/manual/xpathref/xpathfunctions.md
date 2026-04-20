---
title: "XPath Standard Functions"
weight: 164
type: docs
---

The Publisher supports the following XPath standard functions.
In addition, there are the Publisher-specific [layout functions]({{< relref "layoutfunctions" >}}) and [user-defined functions]({{< relref "/reference/function" >}}).


## Strings

`concat(<value>,<value>, ...)`
: Create a new text by concatenating the values.

`contains(<haystack>,<needle>)`
: True if haystack contains needle. Example: `contains('bana','na')` returns `true()`.

`starts-with(<string>, <string>)`
: True if the first string starts with the second.

`ends-with(<string>, <string>)`
: True if the first string ends with the second.

`substring(<input>,<start>[,<length>])`
: Return a part of the string. `substring('Goldfarb', 5, 3)` returns `far`. `start` can be negative (counts from the end).

`substring-before(<string>,<string>)`
: Return the part of the first string before the second. Example: `substring-before("tattoo", "attoo")` returns `"t"`.

`substring-after(<string>,<string>)`
: Return the part of the first string after the second. Example: `substring-after("tattoo", "tat")` returns `"too"`.

`string-length(<string>)`
: Return the length of the string. Multi-byte UTF-8 sequences count as one.

`string-join(<sequence>, <separator>)`
: Join the elements of the sequence with the separator.

`normalize-space(<text>)`
: Remove leading and trailing whitespace. Multiple spaces and newlines are replaced by a single space.

`upper-case(<text>)`
: Convert text to uppercase. `upper-case('text')` returns `TEXT`.

`lower-case(<text>)`
: Convert text to lowercase. `lower-case('Text')` returns `text`.

`translate(<input>,<from>,<to>)`
: Replace all characters in `input` found in `from` with the corresponding character in `to`. Example: `translate('banana','an','uo')` returns `buouou`. If `to` is shorter than `from`, extra characters are deleted.

`matches(<text>,<regexp>[,<flags>])`
: True if the text matches the regular expression. Flags: `s`, `i`, `m` (see [XPath spec](https://www.w3.org/TR/xpath-functions-31/#flags)). Example: `matches("banana", "^(.a)+$")` returns true.

`replace(<input>,<regexp>,<replacement>)`
: Replace all matches of the regular expression with the replacement text. Example: `replace('banana', 'a', 'o')` returns `bonono`. With groups: `replace('W151TBH','^[A-Z]([0-9]+)[A-Z]+$', '$1')` returns `151`.

`tokenize(<input>,<regexp>)`
: Split the input by the regular expression into a sequence of strings. Example: `tokenize("Go home, Jack!", "\W+")` returns the sequence `"Go", "home", "Jack", ""`.

`string(<sequence>)`
: Return the text value of the sequence.

`codepoints-to-string(<codepoints>)`
: Convert a sequence of codepoints to a string.

`string-to-codepoints(<string>)`
: Convert a string to a sequence of codepoints.


## Numbers

`number(<value>)`
: Convert the value to a number. Returns NaN if conversion fails.

`abs(<number>)`
: Return the absolute value. `abs(-1.34)` returns `1.34`.

`ceiling(<number>)`
: Round up to the next integer. `ceiling(1.34)` returns `2`.

`floor(<number>)`
: Round down to the next integer. `floor(1.7)` returns `1`.

`round(<number>[,<decimals>])`
: Round to the given number of decimal places (default: 0).

`round-half-to-even(<number>[,<decimals>])`
: Banker's rounding: at .5, round to the nearest even number.

`format-number(<number>, <pattern>)`
: Format the number according to the pattern. Example: `format-number(12345.67, '#,##0.00')` returns `12,345.67`.

`max(<sequence>)`
: Return the maximum. `max((1.1, 2.2, 3.3))` returns `3.3`.

`min(<sequence>)`
: Return the minimum. `min((1.1, 2.2, 3.3))` returns `1.1`.


## Boolean Functions

`true()`
: Return true.

`false()`
: Return false.

`not(<value>)`
: Negate the boolean value. `not(true())` returns `false()`.

`boolean(<sequence>)`
: Return the [effective boolean value](https://www.w3.org/TR/xpath20/#id-ebv).

`empty(<sequence>)`
: True if the sequence is empty (e.g. a non-existing attribute or element).


## Sequences and Nodes

`count(<nodes>)`
: Count child elements with the given name. Example: `count(article)`.

`position()`
: Return the position of the current node.

`last()`
: Return the number of same-named sibling elements.

`distinct-values(<sequence>)`
: Return unique values. `distinct-values((1,2,2,3))` returns `(1,2,3)`.

`reverse(<sequence>)`
: Reverse the order of the sequence.

`local-name()`
: Return the name of the current node (without namespace).

`name()`
: Return the name of the current node (with namespace prefix).

`namespace-uri([<nodeset>])`
: Return the namespace URI of the first node.

`root(<element>)`
: Return the root element.

`doc(<filename>)`
: Open the file and return its content as an XML tree.

`unparsed-text(<filename>)`
: Return the file content as uninterpreted text.
