---
linktitle: "Frame"
weight: 360
type: docs
---

# `Frame`


Manipulate an object's appearance by drawing a frame. Can be used as a clipping path.



## Child elements

<a href="../barcode"><code>Barcode</code></a>, <a href="../box"><code>Box</code></a>, <a href="../circle"><code>Circle</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../image"><code>Image</code></a>, <a href="../rule"><code>Rule</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../table"><code>Table</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../transformation"><code>Transformation</code></a>

## Parent elements

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../i"><code>I</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../position"><code>Position</code></a>, <a href="../span"><code>Span</code></a>, <a href="../td"><code>Td</code></a>, <a href="../transformation"><code>Transformation</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`background-color` (text, optional)
: Color of the background if ›background‹ is set to ›full‹.



`border-bottom-left-radius` (length, optional, CSS property: border-bottom-left-radius)
: Radius of corner bottom left.



`border-bottom-right-radius` (length, optional, CSS property: border-bottom-right-radius)
: Radius of corner bottom right.



`border-radius` (optional, _since version 4.13.14_)
: Border radius of the four corners.



`border-top-left-radius` (length, optional, CSS property: border-top-left-radius)
: Radius of corner top left.



`border-top-right-radius` (length, optional, CSS property: border-top-right-radius)
: Radius of corner top right.



`class` (text, optional)
: CSS class for this element.



`clip` (optional, _since version 3.5.10_)
: Constrain the contents of the frame to its area or allow them to protrude.


  - `yes`: The contents are clipped at the frame border (default).
  - `no`: The contents are not clipped.

`framecolor` (text, optional)
: The color of the frame around the object. This defaults to 'black'. Can be hidden with the special color '-'.



`id` (text, optional)
: CSS id for this element.



`rulewidth` (length, optional)
: The thickness of the frame that is drawn around the object.






## Example


```xml
<Record element="data">
  <PlaceObject>
    <Frame framecolor="red" border-bottom-left-radius="10pt">
      <Image width="20" file="_samplea.pdf"/>
    </Frame>
  </PlaceObject>
</Record>

```



