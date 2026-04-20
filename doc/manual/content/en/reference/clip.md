---
linktitle: "Clip"
weight: 180
type: docs
---

# `Clip`
_since version 4.11.3_

Clip an image or other output



## Child elements

<a href="../barcode"><code>Barcode</code></a>, <a href="../box"><code>Box</code></a>, <a href="../circle"><code>Circle</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../image"><code>Image</code></a>, <a href="../rule"><code>Rule</code></a>, <a href="../table"><code>Table</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../transformation"><code>Transformation</code></a>

## Parent elements

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../i"><code>I</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../span"><code>Span</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`bottom` (length, optional)
: The amount of clip from the bottom border.



`height` (length, optional)
: The clipped height of the object. Should be used with one of top or bottom.



`left` (length, optional)
: The amount of clip from the left border.



`method` (optional)
: Set the resize method of the resulting object.


  - `clip`: Clip and shrink the object.
  - `frame`: Just hide the outer frame of the object, do not change the size.

`right` (length, optional)
: The amount of clip from the right border.



`top` (length, optional)
: The amount of clip from the top border.



`width` (length, optional)
: The clipped width of the object. Should be used with one of left or right.






## Example


```xml
<PlaceObject frame="solid">
    <Clip left="1cm" right="1cm" top="1cm" bottom="2cm" method="clip">
        <Image width="5cm" file="_sampleb.pdf" />
    </Clip>
</PlaceObject>
```



