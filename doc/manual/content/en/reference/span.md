---
linktitle: "Span"
weight: 860
type: docs
---

# `Span`
_since version 3.1.15_

Surround text by styling options.



## Child elements

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../barcode"><code>Barcode</code></a>, <a href="../br"><code>Br</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../hspace"><code>HSpace</code></a>, <a href="../i"><code>I</code></a>, <a href="../image"><code>Image</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../span"><code>Span</code></a>, <a href="../sub"><code>Sub</code></a>, <a href="../sup"><code>Sup</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../value"><code>Value</code></a>

## Parent elements

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../i"><code>I</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../span"><code>Span</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`background-color` (text, optional, CSS property: background-color)
: The background color of the content



`background-padding-bottom` (length, optional, CSS property: background-padding-bottom)
: The bottom padding of the background color (can be negative)



`background-padding-top` (length, optional, CSS property: background-padding-top)
: The top padding of the background color (can be negative)



`class` (text, optional)
: CSS class for this element.



`fontfamily` (text, optional, _since version 4.1.14_)
: The name of the font family to switch to.



`id` (text, optional)
: CSS id for this element.



`language` (optional, _since version 4.1.10_)
: Name of the language for hyphenation and rendering.



`letter-spacing` (length, optional, CSS property: letter-spacing, _since version 3.5.2_)
: Increase spacing between glyphs.



`role` (optional, _since version 4.19.8_)
: The role for PDF/UA (accessibility, tagged PDF)






## Example


```xml
<Stylesheet>
  .green { background-color: lightgreen; }
</Stylesheet>

<Record element="data">
  <PlaceObject>
    <Textblock>
      <Paragraph>
        <Span class="green"><Value>green</Value></Span>
      </Paragraph>
    </Textblock>
  </PlaceObject>
</Record>

```



