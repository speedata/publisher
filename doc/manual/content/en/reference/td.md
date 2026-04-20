---
linktitle: "Td"
weight: 970
type: docs
---

# `Td`


Td wraps a table cell, just like HTML.



## Child elements

<a href="../barcode"><code>Barcode</code></a>, <a href="../bookmark"><code>Bookmark</code></a>, <a href="../box"><code>Box</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../groupcontents"><code>Groupcontents</code></a>, <a href="../image"><code>Image</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../mark"><code>Mark</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../table"><code>Table</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../vspace"><code>VSpace</code></a>, <a href="../value"><code>Value</code></a>

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../tr"><code>Tr</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`align` (optional, CSS property: text-align)
: Horizontal alignment of the cell contents. Defaults to left.


  - `left`: The contents is left aligned (ragged right). This is the default.
  - `right`: The contents of the cell is right aligned.
  - `center`: The contents of the cell is aligned at the center, with ragged right and left margin.
  - `justify`: Justified text with straight margins.

`background-color` (text, optional, CSS property: background-color)
: The name of the background color (if the cell should get a background).



`background-font-family` (text, optional, CSS property: background-font-family, _since version 2.3.7_)
: Set the font family of the background text. Defaults to the table font.



`background-size` (optional, CSS property: background-size, _since version 2.3.7_)
: Controls the size of the background text. Currently only 'contain' and 'auto' is allowed.


  - `contain`: Fill the height of the table cell.
  - `auto`: The background text is not scaled.

`background-text` (optional, CSS property: background-text, _since version 2.3.7_)
: A text that should be placed in the background of the table cell.



`background-textcolor` (optional, CSS property: background-textcolor, _since version 2.3.7_)
: The color of the text in the background (if any).



`background-transform` (optional, CSS property: background-transform, _since version 2.3.7_)
: The transformation of the background text (if any). Currently supported: `rotate(-40deg)` (and other angles in the range 0 to -90).



`border-bottom` (length, optional, CSS property: border-bottom-width)
: The width (thickness) of the bottom border. The border is inside the cell.



`border-bottom-color` (text, optional, CSS property: border-bottom-color)
: The color of the bottom border.



`border-left` (length, optional, CSS property: border-left-width)
: The width (thickness) of the left border. The border is inside the cell.



`border-left-color` (text, optional, CSS property: border-left-color)
: The color of the left border.



`border-right` (length, optional, CSS property: border-right-width)
: The width (thickness) of the right border. The border is inside the cell.



`border-right-color` (text, optional, CSS property: border-right-color)
: The color of the left border.



`border-top` (length, optional, CSS property: border-top-width)
: The width (thickness) of the top border. The border is inside the cell.



`border-top-color` (text, optional, CSS property: border-top-color)
: The color of the top border.



`class` (text, optional)
: The css class to be used for formatting the table cell.



`colspan` (number, optional)
: The number of columns this cell spans. Defaults to 1.



`graphic` (text, optional, _since version 4.3.12_)
: Draw the predefined MetaPost graphic around the table cell.



`id` (text, optional)
: CSS id for this table cell.



`padding` (length, optional, CSS property: padding)
: Shorthand for setting padding-top and the other values with this length.



`padding-bottom` (length, optional, CSS property: padding-bottom)
: Set the inner distance (width between contents and the border) to the bottom edge.



`padding-left` (length, optional, CSS property: padding-left)
: Set the inner distance (width between contents and the border) to the left edge.



`padding-right` (length, optional, CSS property: padding-right)
: Set the inner distance (width between contents and the border) to the right edge.



`padding-top` (length, optional, CSS property: padding-top)
: Set the inner distance (width between contents and the border) to the top edge.



`role` (optional, _since version 4.19.23_)
: The role for PDF/UA (accessibility, tagged PDF)



`rotate` (number, optional, _since version 3.3.7_)
: Rotate the contents of the table cell. Positive values return clockwise. This is experimental and currently only for text.



`rowspan` (number, optional)
: The number of rows for this cell. Defaults to 1.



`valign` (optional, CSS property: vertical-align)
: The vertical alignment of the cell.


  - `top`: The contents is aligned at the top edge of the cell.
  - `middle`: The contents is vertically centered.
  - `bottom`: The contents is aligned at the bottom edge of the cell.



## Remarks

The child elements of the table cells are either block objects that start a new line or inline objects that are placed horizontally next to each other (from left to right) until the width of the table cell forces a line break.
        Block objects are [`Paragraph`]({{% relref "paragraph" %}}), [`Table`]({{% relref "table" %}}) and [`Box`]({{% relref "box" %}}), inline objects are [`Barcode`]({{% relref "barcode" %}}) and [`Image`]({{% relref "image" %}}).




## Example


The following example places a background text behind the Td cell.



```xml
<DefineFontfamily name="td-background" fontsize="12" leading="12">
  <Regular fontface="TeXGyreHeros-Bold"/>
</DefineFontfamily>

<Record element="data">
   <PlaceObject>
     <Table stretch="max">
       <Columns>
         <Column width="5cm"/>
       </Columns>
       <Tr>
         <Td border-top="0.25pt" border-bottom="0.25pt"
            background-text="hello!"
            background-textcolor="goldenrod"
            background-transform="rotate(-30deg)"
            background-size="contain"
            background-font-family="td-background">
           <Paragraph><Value>A wonderful serenity has taken possession of my entire soul,
             like these sweet mornings of spring which I enjoy with my whole heart.</Value>
           </Paragraph>
         </Td>
       </Tr>
     </Table>
   </PlaceObject>
</Record>

```



