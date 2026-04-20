---
linktitle: "DefineTextformat"
weight: 310
type: docs
---

# `DefineTextformat`


Define text formatting instructions. A textformat is used to align and indent text and create margins and rules before and after the text.



## Child elements

(none)

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`alignment` (optional)
: Determines the formatting of the text. It defaults to justified.


  - `justified`: Textblock has a rectangular shape.
  - `leftaligned`: The text is ragged at the right margin.
  - `rightaligned`: The text is ragged right at the left margin.
  - `centered`: The text is ragged at the left and the right margin.
  - `start`: The text is ragged at the right margin for left-to-right texts and at the left margin for right-to-left texts.
  - `end`: The text is ragged at the left margin for left-to-right texts and at the right margin for right-to-left texts.

`border-bottom` (length, optional)
: The thickness of the rule below the text.



`border-top` (length, optional)
: The thickness of the rule above the text.



`break-before` (optional, _since version 4.21.15_)
: Force break before the text. This only works within an [`Output`]({{% relref "output" %}}) container.


  - `auto`: Default: don't force a page break.
  - `page`: Force page break above

`break-below` (optional)
: (Dis-)Allow break below the text. This only works within an [`Output`]({{% relref "output" %}}) container.


  - `yes`: Allow a break below this text (default).
  - `no`: Prevent a page break below this text.

`column-padding-top` (optional, _since version 3.2.1_)
: The height of the padding that is inserted in a column (at the top) with Output/Text.



`cssfontsize` (yes or no, optional, _since version 5.3.9_)
: If yes, the fontsize is interpreted as CSS fontsize (e.g. 1.2em, 150%, etc.). If no, the font size is taken from the font family setting. Default is no.



`fill-last-line` (0 up to 100, optional, _since version 3.3.11_)
: Ensure the length of the last line in a paragraph. Values from 0 (no change) to 100 (last line is full). Handle with care. Default is 0.



`html-vertical-spacing` (optional, _since version 4.1.6_)
: Set the vertical spacing for HTML contents. Defaults to “off”.


  - `all`: Allow each vertical spacing.
  - `inner`: Discard first and last vertical spacing.
  - `off`: Ignore all vertical spacing.

`hyphenate` (optional)
: Enable or disable hyphenation (default: on).


  - `yes`: Enable hyphenation (default).
  - `no`: Disable hyphenation.

`hyphenchar` (text, optional)
: The character used for hyphenation (default: -)



`indentation` (length, optional)
: The amount of indentation.



`letter-spacing` (number, optional, _since version 5.3.18_)
: Additional space between characters in 1/1000 em. For example, a value of 50 adds 0.05 em between each character. This is font-size independent and scales with the text.



`margin-bottom` (length, optional)
: Distance between the bottom rule and the text of the next paragraph.



`margin-top` (length, optional)
: Distance between the top rule and the text of the previous paragraph.



`margin-top-box-start` (optional, _since version 3.9.7_)
: The top margin at the beginning of a page or column with [`Output`]({{% relref "output" %}}). Defaults to the value of `margin-top`.



`name` (text)
: Name of the textformat that is used later in the layout.



`orphan` (yesnonumber, optional)
: If yes, allow orphans (first line of paragraph is on the previous page). If you provide a number, it is the number of lines that must be kept together. Default: no.



`padding-top` (length, optional)
: Distance between the top of the text and the top rule.



`rows` (number, optional)
: The number of rows with indentation given in the attribute `indentation`. If the number is negative, this determines the number of rows that are not indented.



`tab` (optional, _since version 3.1.5_)
: What to do on the tab (& #09;) character.


  - `space`: Use tab as space
  - `hspace`: Use tab as a stretching space

`widow` (yesnonumber, optional)
: If yes, allow widows (last line of paragraph is on the next page). If you provide a number, it is the number of lines that must be kept together.  Default: no.





## Remarks

The textformats `text`, `centered`, `left` and `right` are predefined. They stand for justified, centered, left aligned and right aligned text.

Indentation with negative values for rows do not work with HTML text.




## Example


```xml
<DefineTextformat name="text with indentation" alignment="justified" indentation="1cm"/>

<Record element="...">
  <PlaceObject>
    <Textblock textformat="text with indentation">
    <Paragraph>
      <Value>Text ...</Value>
    </Paragraph>
  </Textblock>
  </PlaceObject>
</Record>

```



