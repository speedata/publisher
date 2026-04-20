---
linktitle: "Box"
weight: 130
type: docs
---

# `Box`


Create a rectangular colored area. The area must fit the grid cells.



## Child elements

(none)

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../position"><code>Position</code></a>, <a href="../td"><code>Td</code></a>, <a href="../transformation"><code>Transformation</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`background-color` (text, optional, CSS property: background-color)
: Color of the box. If the color name is a dash (`-`), a transparent background is used.



`bleed` (optional)
: Lets the box increase its size by the amount of trim given in the options. Useful for thumb indexes. The contents of the attribute is either “left”, “right”, “top” or “bottom” or any combination such as “top,right”.


  - `auto`: Increase the size depending on the position.
  - `top`: Increase the size to the top.
  - `left`: Increase the size to the left.
  - `bottom`: Increase the size to the bottom.
  - `right`: Increase the size to the right.
  - `top,left`: Increase the size to the top and left.
  - `top,right`: Increase the size to the top and right.
  - `bottom,left`: Increase the size to the bottom and left.
  - `bottom,right`: Increase the size to the bottom and right.

`border-color` (text, optional, _since version 5.5.8_)
: Color of the border. Must be used together with `border-width`. The border is drawn inside the box dimensions, shrinking the fill area accordingly.



`border-width` (length, optional, _since version 5.5.8_)
: Width of the border. Must be used together with `border-color`.



`class` (text, optional)
: CSS class for this box.



`graphic` (text, optional, _since version 4.3.10_)
: The name of the metapost graphic to use instead of the box.



`height` (number or length)
: Height of the box in grid cells.



`id` (text, optional)
: CSS id for this box.



`padding-bottom` (length, optional, CSS property: padding-bottom, _since version 2.5.10_)
: Set the inner distance (width between contents and the border) to the bottom edge.



`padding-left` (length, optional, CSS property: padding-left, _since version 2.5.10_)
: Set the inner distance (width between contents and the border) to the left edge.



`padding-right` (length, optional, CSS property: padding-right, _since version 2.5.10_)
: Set the inner distance (width between contents and the border) to the right edge.



`padding-top` (length, optional, CSS property: padding-top, _since version 2.5.10_)
: Set the inner distance (width between contents and the border) to the top edge.



`vertical-align` (optional, _since version 5.5.8_)
: Vertical alignment of the box when used inline in a paragraph. Only effective when the box appears inside a paragraph together with text or other inline elements.


  - `bottom`: Align the bottom of the box with the bottom of the line box (below the text baseline, at the descender line).

`width` (number or length)
: Width of the box in grid cells or in absolute values.






## Example


```xml
<DefineColor name="mygreen" model="cmyk" c="22" m="0" y="55" k="0"/>
<PlaceObject>
  <Box width="10" height="5" background-color="mygreen"/>
</PlaceObject>

```

looks like



![ref-greenbox.png](/img/ref-greenbox.png)



