---
linktitle: "Textblock"
weight: 990
type: docs
---

# `Textblock`


Create a rectangular piece of text.



## Child elements

<a href="../bookmark"><code>Bookmark</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../html"><code>HTML</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../mark"><code>Mark</code></a>, <a href="../ol"><code>Ol</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../ul"><code>Ul</code></a>, <a href="../value"><code>Value</code></a>

## Parent elements

<a href="../clip"><code>Clip</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../position"><code>Position</code></a>, <a href="../td"><code>Td</code></a>, <a href="../transformation"><code>Transformation</code></a>

## Attributes


`angle` (number, optional)
: The angle (counter clockwise) that the text gets turned.



`color` (text, optional)
: The name of the color of the text.



`columndistance` (number or length, optional)
: Distance between two columns. Defaults to 3mm.



`columns` (number, optional)
: Number of columns in the textblock. Do not use multi columns for any other purposes than simple text.



`fontfamily` (text, optional)
: The name of the font family. Defaults to `text`.



`language` (optional, _since version 4.1.1_)
: Set the language for hyphenation and rendering.



`minheight` (number or length, optional, _since version 2.3.28_)
: The minimum height of the textblock, given as a length or number (grid cells).



`textformat` (text, optional)
: The name of the text format to be applied to the text. Defaults to `text`.



`width` (number, optional)
: Number of columns for the text. If not given, the surrounding element determines the width of the element.





## Remarks

The textformat change the appearance of the paragraphs. They have to be previously defined by [`DefineTextformat`]({{% relref "definetextformat" %}}).

Be careful when using multi column typesetting. This will only work with simple text, not with lists or so.




## Example


```xml
<Record element="data">
  <PlaceObject>
    <Textblock width="10" angle="-20">
      <Paragraph>
        <B><Value>Bold slanted text</Value></B>
      </Paragraph>
    </Textblock>
  </PlaceObject>
</Record>

```



