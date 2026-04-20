---
linktitle: "DefineGraphic"
weight: 290
type: docs
---

# `DefineGraphic`
_since version 4.3.10_

Define a metapost graphic to be used in Box. EXPERIMENTAL!



## Child elements

(none)

## Parent elements

<a href="../layout"><code>Layout</code></a>, <a href="../section"><code>Section</code></a>

## Attributes


`name` (text)
: The name of the graphic.






## Example


```xml
<DefineGraphic name="dottedbox">
   beginfig(1);
        pickup pencircle scaled 0.4mm;
        draw (0,0) -- (box_width,0) -- (box_width, box_height) -- (0, box_height) -- cycle dashed withdots ;
    endfig;
</DefineGraphic>

<Record element="data">
    <PlaceObject row="3" column="1">
        <Box height="5" width="1" graphic="dottedbox" />
    </PlaceObject>
</Record>

```



