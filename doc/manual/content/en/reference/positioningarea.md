---
linktitle: "PositioningArea"
weight: 740
type: docs
---

# `PositioningArea`


Describes an area which contains one or more frames. Elements can be placed within these frames.



## Child elements

<a href="../loop"><code>Loop</code></a>, <a href="../positioningframe"><code>PositioningFrame</code></a>, <a href="../switch"><code>Switch</code></a>

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../pagetype"><code>Pagetype</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`framecolor` (text, optional, _since version 2.9.12_)
: Set the color of the frame in grid=yes mode. Defaults to 'red'



`name` (text)
: Name of the area.






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



