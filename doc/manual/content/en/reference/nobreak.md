---
linktitle: "NoBreak"
weight: 610
type: docs
---

# `NoBreak`
_since version 2.3.14_

Don't allow a line break within this element



## Child elements

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../barcode"><code>Barcode</code></a>, <a href="../br"><code>Br</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../hspace"><code>HSpace</code></a>, <a href="../i"><code>I</code></a>, <a href="../image"><code>Image</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../span"><code>Span</code></a>, <a href="../sub"><code>Sub</code></a>, <a href="../sup"><code>Sup</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../value"><code>Value</code></a>

## Parent elements

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../i"><code>I</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../span"><code>Span</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`factor` (number, optional)
: Multiplier for the font size when reduce=fontsize. Default value: 0.9. That means the font size gets decreased by 0.9 until the text fits the objects width.



`fontfamily` (text, optional)
: The name of the fontface for text to be reduced. The default is “text” (lowercase t).



`maxwidth` (number or length, optional)
: Set the maximum width of the text if it cannot be deduced from the current surrounding (such as table cells).



`reduce` (optional)
: Reduce the text size if necessary.


  - `fontfit`: Reduces the text by scaling down the font size so the text exactly fits the available space.
  - `fontsize`: Reduces the text by decreasing the font size in steps.
  - `cut`: Inserts text given in the attribute text if the paragraph is too long.
  - `keeptogether`: Don't allow a line break within NoBreak (default)

`text` (optional, _since version 2.3.53_)
: The text to be inserted if the paragraph should be cut. For example '...'






## Example


```xml
<PlaceObject>
  <Textblock width="5">
    <Paragraph>
      <NoBreak reduce="fontsize" factor="0.7">
        <Value>The quick brown fox jumps over the lazy dog.</Value>
      </NoBreak>
      <Value> </Value>
      <Value>The quick brown fox jumps over the lazy dog.</Value>
    </Paragraph>
  </Textblock>
</PlaceObject>

```



