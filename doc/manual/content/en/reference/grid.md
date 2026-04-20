---
linktitle: "Grid"
weight: 380
type: docs
---

# `Grid`


Override the grid settings from [`SetGrid`]({{% relref "setgrid" %}}).



## Child elements

(none)

## Parent elements

<a href="../group"><code>Group</code></a>, <a href="../pagetype"><code>Pagetype</code></a>

## Attributes


`dx` (optional, _since version 2.3.11_)
: Distance between two grid cells (horizontal)



`dy` (optional, _since version 2.3.46_)
: Distance between two grid cells (horizontal)



`height` (length, optional)
: Height of a grid cell.



`nx` (number, optional)
: Number of grid cells in horizontal direction.



`ny` (number, optional)
: Number of grid cells in vertical direction.



`width` (length, optional)
: Set the width of a grid cell.





## Remarks

nx and ny don't make sense in [`Group`]({{% relref "group" %}}).




## Example


```xml
<Pagetype name="page wide" test=" $var > 10 ">
  <Margin left="1cm" right="2cm" top="1cm" bottom="1cm"/>
  <Grid width="10mm" height="14pt"/>
</Pagetype>
```



