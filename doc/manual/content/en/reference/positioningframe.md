---
linktitle: "PositioningFrame"
weight: 750
type: docs
---

# `PositioningFrame`


Defines a rectangular area for objects.



## Child elements

(none)

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../positioningarea"><code>PositioningArea</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`column` (number)
: First column of the frame, in grid cells.



`height` (number)
: The height of the frame in grid cells.



`row` (number)
: The row number relative to the grid.



`width` (number)
: The width of the frame in grid cells.






## Example


```xml
<Pagetype name="right page" test="sd:odd( sd:current-page() )">
  <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>
  <PositioningArea name="frame1">
    <PositioningFrame width="12" height="30" column="2" row="2"/>
    <PositioningFrame width="12" height="30" column="16" row="2"/>
  </PositioningArea>
</Pagetype>
```



