---
linktitle: "Paragraph"
weight: 700
type: docs
---

# `Paragraph`


Insert a paragraph of text. The width of the paragraph is inherited from the surrounding element.



## Child elements

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../barcode"><code>Barcode</code></a>, <a href="../br"><code>Br</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../hspace"><code>HSpace</code></a>, <a href="../i"><code>I</code></a>, <a href="../image"><code>Image</code></a>, <a href="../initial"><code>Initial</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../span"><code>Span</code></a>, <a href="../sub"><code>Sub</code></a>, <a href="../sup"><code>Sup</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../value"><code>Value</code></a>

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../td"><code>Td</code></a>, <a href="../text"><code>Text</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`actualtext` (text, optional, _since version 4.19.23_)
: Set the text for screen readers.



`allowbreak` (text, optional)
: (Experimental!) list of characters where a line break is possible. Space character is not implied when this attribute is set.



`bidi` (optional, _since version 4.1.14_)
: Analyze direction of the text. Useful for mixing left-to-right and right-to-left text.


  - `yes`: Analyze text.
  - `no`: Don't handle mixed directions (default).

`class` (text, optional)
: CSS class for this paragraph.



`color` (text, optional, CSS property: color)
: Color of the paragraph. Must be defined with [`DefineColor`]({{% relref "definecolor" %}}) before use.



`direction` (text, optional, _since version 4.1.12_)
: The text direction (ltr or rtl)



`font-outline` (length, optional, _since version 4.13.15_)
: Set the line width of the font outline.



`fontfamily` (text, optional, CSS property: font-family)
: The name of the font family for the paragraph. The default is “text” (lowercase t).



`html` (optional, _since version 4.1.2_)
: Set the HTML processing mode. Defaults to 'all'.


  - `all`: Interpret HTML starting from the current element.
  - `inner`: Ignore the name of the outer element.
  - `off`: Switch off HTML in this paragraph. Use only the text value.

`id` (text, optional)
: CSS id for this paragraph.



`label-left` (text, optional, _since version 4.1.4_)
: A text to the left of the paragraph.



`label-left-align` (optional, _since version 4.1.4_)
: Alignment of the text.


  - `left`: Left aligned
  - `right`: Right aligned

`label-left-distance` (length, optional, _since version 4.1.4_)
: Horizontal distance between text and paragraph (if right aligned).



`label-left-width` (length, optional, _since version 4.1.4_)
: Width of the text.



`language` (optional)
: Name of the language for hyphenation and rendering.



`padding-left` (length, optional, _since version 3.9.27_)
: Set the left padding, i.e. the inner distance to the allocated area.



`padding-right` (length, optional, _since version 3.9.27_)
: Set the right padding, i.e. the inner distance to the allocated area.



`parent` (text, optional, _since version 4.19.8_)
: The id of the parent structure element for tagged PDF. If left empty, the software tries to derive the parent id from the layout structure.



`role` (optional, _since version 3.5.7_)
: The role for PDF/UA (accessibility, tagged PDF)



`structpos` (top, cur or number, optional, _since version 4.19.23_)
: Set the position of the tag in the structure hierarchy for PDF/UA. Default is 'cur', which inserts the element at the current position (the current “bottom”). 'top' (or 1) inserts the element at the beginning of the structure. Use any other number to control the insertion.



`textformat` (text, optional)
: Name of the textformat that is applied to the paragraph. If none is specified the textformat `text` is used.






## Example


```xml
<Textblock>
  <Paragraph fontfamily="Title">
    <Value>Hello World</Value>
  </Paragraph>
</Textblock>

```



