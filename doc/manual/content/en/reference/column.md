---
linktitle: "Column"
weight: 200
type: docs
---

# `Column`


Set the properties of a column in the table.



## Child elements

(none)

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../columns"><code>Columns</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`align` (optional)
: The horizontal alignment of the table cells in this column. Can be overridden in a cell ([`Td`]({{% relref "td" %}})).


  - `left`: The table cells are left aligned.
  - `center`: The table cells are horizontally centered.
  - `right`: The table cells are right aligned.

`background-color` (text, optional)
: All cells in this column have this background color.



`minwidth` (length, optional, _since version 4.13.9_)
: Minimum width of the column. Argument can be a number (in grid cells) or a length (e.g. 2cm).



`padding-left` (length, optional, _since version 3.1.8_)
: Set the left padding for the column



`padding-right` (length, optional, _since version 3.1.8_)
: Set the right padding for the column



`valign` (optional)
: The vertical alignment of the cells in this column. Can be overridden in a cell ([`Td`]({{% relref "td" %}})).


  - `top`: The table cells are top aligned.
  - `middle`: The table cells are vertically centered.
  - `bottom`: The table cells are aligned at the bottom.

`width` (Number, length or *-numbers, optional)
: Width of the column. Argument can be a number (in grid cells) a length (e.g. 2cm), a *-number (e.g. 4*) or the keyword `min` or `max`.






## Example


See the example at [`Columns`]({{% relref "columns" %}}).





