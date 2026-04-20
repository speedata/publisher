---
linktitle: "PlaceObject"
weight: 720
type: docs
---

# `PlaceObject`


Outputs a rectangular object (image, table, box, barcode or textblock).



## Child elements

<a href="../a"><code>A</code></a>, <a href="../barcode"><code>Barcode</code></a>, <a href="../bookmark"><code>Bookmark</code></a>, <a href="../box"><code>Box</code></a>, <a href="../circle"><code>Circle</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../image"><code>Image</code></a>, <a href="../mark"><code>Mark</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../rule"><code>Rule</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../table"><code>Table</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../transformation"><code>Transformation</code></a>

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`allocate` (optional)
: Determines if the area of the object is marked as “allocated”. With `allocate="no"`, the cursor position is not changed.


  - `yes`: Occupy space in the grid (default for grid positioning).
  - `no`: Don't allocate space in the grid (default for absolute positioning).

`allocate-bottom` (number or length, optional, _since version 2.9.6_)
: Additional allocation area to the bottom.



`allocate-left` (number or length, optional, _since version 2.9.6_)
: Additional allocation area to the left.



`allocate-right` (number or length, optional, _since version 2.9.6_)
: Additional allocation area to the right.



`allocate-top` (number or length, optional, _since version 2.9.6_)
: Additional allocation area to the top.



`area` (text, optional)
: Name of the (positioning) area, the object is placed in. If no area is given, the object is placed on the main area, the page (this is the area that contains all grid cells).



`background` (optional)
: Fill the background of the object (full grid cells) with a color, given by background-color.


  - `full`: Fill background with the given color (in background-color).
  - `without`: Empty background

`background-color` (text, optional)
: Color of the background if ›background‹ is set to ›full‹.



`border-bottom-left-radius` (length, optional)
: Radius of corner bottom left.



`border-bottom-right-radius` (length, optional)
: Radius of corner bottom right.



`border-top-left-radius` (length, optional)
: Radius of corner top left.



`border-top-right-radius` (length, optional)
: Radius of corner top right.



`clipatmargin` (yes or no, optional, _since version 4.21.9_)
: Clip objects at page margin.



`column` (number or length, optional)
: If contents is a number: the grid cell from the left margin of the area. If it is a length: the absolute position from the left paper margin. If this attribute is omitted, the system tries to place the object by itself.



`frame` (optional)
: Draw a frame around the object. You need to supply the frame color.


  - `solid`: Draw a frame around the object.
  - `without`: Don't draw a frame around the object.

`framecolor` (text, optional)
: The color of the frame around the object. Only makes sense in combination with the attribute 'frame'.



`groupname` (text, optional)
: The name of the group that gets output. When given a groupname, PlaceObject should not contain any objects.



`halign` (optional, _since version 2.3.55_)
: When an object is placed on the grid and it's width is not a multiple of grid width, there is a space left on the page between the object an the next grid cell. With this attribute you can instruct the software where to place the gap.


  - `left`: The object is aligned at the left.
  - `center`: The object is aligned so that the space to the left is the same as to the right.
  - `right`: The object is aligned to the right.

`hreference` (optional)
: Determines the placement of the object relative to the given column. If 'left' (which is the default), the given column is the left border of the object. If 'right', the column determines the right edge of the object.


  - `left`: The object is placed in given column.
  - `center`: The column determines the center of the object. Works only with absolute positioning.
  - `right`: The given columns determines the right edge of the border.

`keepposition` (optional)
: Don't move the virtual cursor to the next free space


  - `yes`: Don't move the virtual cursor.
  - `no`: Move the virtual cursor (default).

`maxheight` (number, optional)
: Only used for multi-page table: the maximum height of tables.



`origin-x` (optional)
: The origin for rotation.


  - `left`: The origin is at the left hand side.
  - `center`: The origin is in the center of the object.
  - `right`: The origin is at the right hand side.

`origin-y` (optional)
: The origin for rotation (on the vertical axis)


  - `top`: Rotation around a point at the top.
  - `center`: Rotate around the vertical center.
  - `bottom`: Rotate around a point at the bottom.

`page` (number, optional)
: The page (later in the PDF), the object should appear on. Number of the keyword “next” for the next page.



`rotate` (number, optional)
: Rotates the object.  The amount of movement is defined by the specified angle; if positive, the movement will be clockwise, if negative, it will be counter-clockwise. When the angle is != 0 then grid allocation is turned off.



`row` (number or length, optional)
: The row where the object is placed. If none given, the publisher tries to find a row by itself. You can give a number (in grid cells) or an absolute value (from top left).



`rulewidth` (length, optional)
: The thickness of the frame that is drawn around the object. Only makes sense in combination with the attribute 'frame'.



`valign` (optional)
: When an object is placed on the grid and it's height is not a multiple of grid height, there is a space left on the page between the object an the next grid cell. With this attribute you can instruct the software where to place the gap.


  - `top`: The object is aligned at the top.
  - `middle`: The object is aligned so that the space at the top is the same as at the bottom.
  - `bottom`: The object is aligned at the bottom.

`vreference` (optional)
: Sets the placement of the object relative to the given row. 


  - `bottom`: The row determines the bottom edge of the object.
  - `middle`: If 'middle', the given row is the center of the object. Works only with absolute positioning.
  - `top`: If 'top' (default), the given row is the top border of the object.




## Example


Positioning inside the grid:



```xml
<Record element="image">
  <PlaceObject column="12" frame="solid" framecolor="red">
    <Image width="10" file="_samplea.pdf"/>
  </PlaceObject>
</Record>
```

Absolute positioning (from top left edge):



```xml
<Record element="image">
  <PlaceObject column="1cm" row="4cm" frame="solid" framecolor="red">
    <Image width="10" file="_samplea.pdf"/>
  </PlaceObject>
</Record>

```



## Info


The objects can be placed in a grid (when the value in the attributes row and column are numbers) or they can be placed with absolute positions where the origin is at the top and left border of the page.




