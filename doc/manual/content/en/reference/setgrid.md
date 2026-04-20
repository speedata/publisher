---
linktitle: "SetGrid"
weight: 830
type: docs
---

# `SetGrid`


Set size of the grid cells. All objects are placed in the grid.



## Child elements

(none)

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`dx` (optional, _since version 2.3.11_)
: Distance between two grid cells (horizontal)



`dy` (optional, _since version 2.3.46_)
: Distance between two grid cells (horizontal)



`height` (length, optional)
: The height of a grid cell. Use either height or ny, but not both.



`nx` (number, optional)
: Specify the number of grid cells in horizontal direction. Use either nx or width, not both.



`ny` (number, optional)
: Set the number of grid cells in vertical direction. Give ny or height, but not both.



`width` (length, optional)
: The width of a grid cell. Use either width or nx, not both.






## Example


```xml
<SetGrid width="4mm" height="14pt"/>
```



