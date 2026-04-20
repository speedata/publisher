---
linktitle: "Image"
weight: 450
type: docs
---

# `Image`


Includes an external Graphic. Allowed graphic formats are PDF (.pdf), PNG (.png) and JPEG (.jpg). Other file types might be possible with external converters. See below for a limitation on the number of included PDF files.



## Child elements

<a href="../value"><code>Value</code></a>

## Parent elements

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../i"><code>I</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../position"><code>Position</code></a>, <a href="../span"><code>Span</code></a>, <a href="../td"><code>Td</code></a>, <a href="../text"><code>Text</code></a>, <a href="../transformation"><code>Transformation</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`bleed` (optional, _since version 2.9.5_)
: Should the image size increase by the amount of bleed setting ([`Options`]({{% relref "options" %}}))?


  - `auto`: If the image touches a paper edge, extend the image in that direction.
  - `no`: Do not extend the image.

`class` (text, optional, _since version 2.5.11_)
: CSS class for this element.



`clip` (optional)
: When yes, the image keeps its aspect ratio if both width and hight is given. To be able to fit the image into the given dimensions, the image gets clipped.


  - `yes`: Keep the aspect ratio and cut off left/right or top/bottom edges.
  - `no`: Distort the image to make it fit in the given area.

`description` (text, optional, _since version 4.19.8_)
: An alternative text for accessibility



`dpiwarn` (number, optional)
: Warn if the image gets lower resolution than given.



`fallback` (optional, _since version 2.3.77_)
: The filename of the replacement image if the file is not found. If none given, a red 'file not found' image will gets displayed.



`file` (text, optional)
: Filename of the image. Can be a file in the search path, an absolute file name, a file-URI for absolute paths (e.g. `file:///path/to/image.pdf`) or a location on the web (http, https).



`height` (number or length, optional)
: Image height. One of 'auto' (default, take image width), length (such as '3cm') or number (in grid cells).



`id` (text, optional, _since version 2.5.11_)
: CSS id for this element.



`imageshape` (yes or no, optional, _since version 4.9.8_)
: Try to load an image shape. Defaults to no.



`imagetype` (optional, _since version 3.9.1_)
: Set the converter to be used for the enclosed image (if any).



`margin-bottom` (length, optional, _since version 4.13.13_)
: Extra space at the bottom of the image.



`margin-left` (length, optional, _since version 4.13.13_)
: Extra space at the left of the image.



`margin-right` (length, optional, _since version 4.13.13_)
: Extra space at the right of the image.



`margin-top` (length, optional, _since version 4.13.13_)
: Extra space at the top of the image.



`maxheight` (number or length, optional)
: The maximum height of the image. Only used when clip="no". Value is a number (grid cells) or a length.



`maxwidth` (number or length, optional)
: The maximum width of the image. Only used when clip="no". Value is a number (grid cells), a length or the value “100%” for full width image.



`minheight` (number or length, optional)
: The minimum height of the image. Only used when clip="no". Value is a number (grid cells) or a length.



`minwidth` (number or length, optional)
: The minimum width of the image. Only used when clip="no". Value is a number (grid cells), a length or the value “100%” for full width image.



`opacity` (number, optional, _since version 4.3.15_)
: Set image opacity (0-100, 100=fully opaque).



`padding` (length, optional, _since version 2.9.5_)
: Set padding for all four sides.



`padding-bottom` (length, optional, CSS property: padding-bottom, _since version 2.5.11_)
: Set the inner distance (width between contents and the border) to the bottom edge.



`padding-left` (length, optional, CSS property: padding-left, _since version 2.5.11_)
: Set the inner distance (width between contents and the border) to the left edge.



`padding-right` (length, optional, CSS property: padding-right, _since version 2.5.11_)
: Set the inner distance (width between contents and the border) to the right edge.



`padding-top` (length, optional, CSS property: padding-top, _since version 2.5.11_)
: Set the inner distance (width between contents and the border) to the top edge.



`page` (number, optional)
: The page number from the PDF. Default is 1 (include the first page).



`parent` (text, optional, _since version 4.19.8_)
: The id of the parent structure element for tagged PDF



`role` (optional, _since version 4.19.23_)
: The role for PDF/UA (accessibility, tagged PDF)



`rotate` (number, optional)
: Rotate the image in steps of 90°. The amount of movement is defined by the specified angle; if positive, the movement will be clockwise, if negative, it will be counter-clockwise.



`stretch` (yes or no, optional, _since version 4.3.8_)
: Stretch image until one of maximum width and maximum height is reached. Useful if images should be as large as possible but should not use more than the given space.



`vertical-align` (optional, _since version 5.5.8_)
: Vertical alignment of the image when used inline in a paragraph. Only effective when multiple images (or images and text) appear in the same paragraph. Default is baseline.


  - `baseline`: Align the bottom of the image at the text baseline (default). Each image extends upward from the baseline.
  - `top`: Align the top edges of all images. The baseline is at the bottom of the tallest image. Text sits on the baseline.
  - `middle`: Align the vertical centers of all images. The baseline is at the center of the tallest image.
  - `hanging`: The top of the image is placed on the baseline. The image hangs below the text. Each image extends downward independently.

`visiblebox` (optional)
: The PDF box that represents the visible area of the included image. Default is “cropbox”.


  - `artbox`: Use the artbox as the visible area. The artbox is usually not contained in a PDF.
  - `bleedbox`: Use the bleedbox of the included PDF.
  - `cropbox`: Use the cropbox of the included PDF (default).
  - `mediabox`: Use the mediabox of the included PDF. This is the largest box.
  - `trimbox`: Use the trimbox of the includes PDF. The trimbox is the final paper size. For example, the trim box of an A4 PDF is 210mm x 297mm.

`width` (number or length, optional)
: Image width. One of 'auto' (default, take image width), '100%' (whole area width), length (such as '3cm') or number (in grid cells).





## Remarks

The values of the attributes naturalsize and maxsize can be ‘artbox’, ‘bleedbox’, ‘cropbox’, ‘mediabox’ and ‘trimbox’. These two values are used to
      enlarge the image for the bleed. In the second example below the designated view port of the image is defined in the artbox, but the image has a larger
      area (the cropbox) that is used for bleeding.




## Example


```xml
<Record element="productdata">
  <PlaceObject column="{ $column }">
    <Image width="10" file="{ string(.) }"/>
  </PlaceObject>
</Record>

```

Takes the file name of the image from the contents of the current element in the data file (here: productdata). Sample data XML:



```xml
<productdata>image.pdf</productdata>
```

The following example reads a pdf file, extracts a page and make the given artbox (should be set in the pdf file) the width of 210mm.
        If we have an area in the pdf that is larger than the artbox, it will be larger than the given size.



```xml
<Record element="data">
  <PlaceObject column="0mm" row="0mm">
    <Image width="210mm" file="catalog.pdf" page="132" naturalsize="artbox"/>
  </PlaceObject>
</Record>

```



## Info


The number of pages in a PDF file can be determined with the XPath function `sd:number-of-pages(<filename or URI>).`



Attention. The number of PDF files that can be included in a document is limited. This limit can be increased in is system dependant. On Mac OS X it can be queried with `ulimit -a` and set for example with `ulimit -n 1024`.




