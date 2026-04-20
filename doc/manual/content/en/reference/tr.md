---
linktitle: "Tr"
weight: 1000
type: docs
---

# `Tr`


Tablerow



## Child elements

<a href="../copy-of"><code>Copy-of</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../message"><code>Message</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../td"><code>Td</code></a>, <a href="../value"><code>Value</code></a>

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../table"><code>Table</code></a>, <a href="../tablefoot"><code>Tablefoot</code></a>, <a href="../tablehead"><code>Tablehead</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`align` (optional)
: Horizontal alignment of the table cells in this row.


  - `left`: The contents is left aligned (ragged right). This is the default.
  - `right`: The contents of the cell is right aligned.
  - `center`: The contents of the cell is aligned at the center, with ragged right and left margin.
  - `justify`: Justified text with straight margins.

`background-color` (text, optional)
: Background color of each cell in this row.



`break-below` (optional)
: Allow a table break between this row and the following.


  - `yes`: Allow a table break between this row and the following (default).
  - `no`: Disable a table break between this row and the following.

`data` ([XPath expression]({{% relref "../manual/xpathref/xpath" %}}), optional)
: Data that can be accessed via `$_last_tr_data` in the tablefoot and tablehead.



`minheight` (number or length, optional)
: Minimum row height in grid cells or length.



`parent` (text, optional, _since version 4.19.23_)
: The id of the parent structure element for tagged PDF



`role` (optional, _since version 4.19.23_)
: The role for PDF/UA (accessibility, tagged PDF)



`sethead` (optional)
: Use this line for future table heads.


  - `yes`: Use this line for future table heads.
  - `no`: No special treatment of this line (default).
  - `clear`: Delete head. Next pages will have no head until new one is set with 'yes'.

`top-distance` (number or length, optional)
: The space above this row if it is not the first line on a new page / area.



`valign` (optional)
: Vertical alignment of the table cells in this row.


  - `top`: The objects in this row are aligned at the top.
  - `middle`: The objects in this row are aligned at the middle axis.
  - `bottom`: The objects in this row are aligned at the bottom.



## Remarks

The attribute `background-color` used to be `backgroundcolor` until version 4.16.




## Example


```xml
<Tr minheight="8mm" background-color="yellow">
  <Td align="center"><Paragraph><Value>A</Value></Paragraph></Td>
  <Td><Paragraph><Value>B</Value></Paragraph></Td>
  <Td align="center"><Paragraph><Value>C</Value></Paragraph></Td>
  <Td align="center"><Paragraph><Value>D</Value></Paragraph></Td>
  <Td><Paragraph><Value>E</Value></Paragraph></Td>
</Tr>
```



