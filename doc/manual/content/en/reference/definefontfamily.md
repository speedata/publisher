---
linktitle: "DefineFontfamily"
weight: 280
type: docs
---

# `DefineFontfamily`


Defines a font family consisting of the shapes “regular”, “bold”, “bold italic” and “italic”. To be used in [`Paragraph`]({{% relref "paragraph" %}}), [`Textblock`]({{% relref "textblock" %}}), [`Fontface`]({{% relref "fontface" %}}) and [`Table`]({{% relref "table" %}}) with the attribute `fontfamily`.



## Child elements

<a href="../bold"><code>Bold</code></a>, <a href="../bolditalic"><code>BoldItalic</code></a>, <a href="../italic"><code>Italic</code></a>, <a href="../regular"><code>Regular</code></a>

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`fontsize` (number)
: Font size. Without unit, DTP points are assumed.



`leading` (number)
: Distance between two baselines. Without unit, DTP points are expected.



`name` (text)
: The symbolic name that is used as a reference to access this font family.



`scriptsize` (length, optional, _since version 4.19.31_)
: Super/subscript font size. Defautlts to 80% of the font size.



`subshift` (length, optional, _since version 4.19.31_)
: (Down-)shift of subscript. 0pt is on the base line, positive values move down. Defaults to 30% of the font size.



`supershift` (length, optional, _since version 4.19.31_)
: (Up-)shift of superscript. 0pt is on the base line, positive values move up. Defaults to 30% of the font size.





## Remarks

The default fontface is named “text” and it can be redefined by defining a new font family called “text”.

The variants bold, italic and bold italic are optional. 




## Example


```xml
<DefineFontfamily name="Title" fontsize="12" leading="14">
  <Regular fontface="Helvetica Regular"/>
  <Bold fontface="Helvetica Bold"/>
  <Italic fontface="Helvetica Italic"/>
  <BoldItalic fontface="Helvetica Bold Italic"/>
</DefineFontfamily>

```

This font family can now be accessed like this:



```xml
<Textblock fontfamily="Title">
  <Paragraph>
    <Value>...<Value>
  </Paragraph>
</Textblock>

```



