---
linktitle: "Transformation"
weight: 1020
type: docs
---

# `Transformation`


Manipulate an object's appearance by applying a matrix. See the PDF reference 4.2.2 Common Transformations and following.



## Child elements

<a href="../barcode"><code>Barcode</code></a>, <a href="../box"><code>Box</code></a>, <a href="../circle"><code>Circle</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../image"><code>Image</code></a>, <a href="../rule"><code>Rule</code></a>, <a href="../table"><code>Table</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../transformation"><code>Transformation</code></a>

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../position"><code>Position</code></a>, <a href="../transformation"><code>Transformation</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`flip` (optional, _since version 4.19.37_)
: Flip object.


  - `horizontal`: Flip object horizontally (left becomes right)
  - `vertical`: Mirror object on the vertical axes (top/bottom)
  - `both`: Flip object on both axes
  - `none`: Don't flip the object

`matrix` (text, optional)
: The transformation matrix for the object. Expected is a space separated string of six values.



`origin-x` (text, optional)
: The origin for matrix transformation. Must be left, center or right or a number from 0 to 100 (0 = left, 100 = right).



`origin-y` (text, optional)
: The vertical origin for the matrix transformation. Must be top, center or bottom or a number from 0 to 100 (0 = top, 100 = bottom).






## Example


```xml
<Record element="data">
  <PlaceObject>
    <Transformation matrix="1 0 0 1 72 -72">
      <Transformation matrix="1 0 0 0.5 0 0" origin-x="100">
        <Transformation matrix="1 1 -1 1 0 0">
          <Image file="_samplea.pdf" maxwidth="4" maxheight="4"/>
        </Transformation>
      </Transformation>
    </Transformation>
  </PlaceObject>
</Record>

```



