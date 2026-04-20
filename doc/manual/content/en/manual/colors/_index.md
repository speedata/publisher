---
title: "Colors"
weight: 65
type: docs
---


Using colors in the speedata Publisher is straightforward. Usually one specification for the object to be output is sufficient:

```xml
    <PlaceObject column="4" row="4">
      <Circle
         radiusx="2"
         background-color="deeppink"
         framecolor="mediumaquamarine"
         rulewidth="8pt"/>
    </PlaceObject>
```

All CSS4 colors are predefined, see the list at [`<DefineColor>`]({{< relref "/reference/definecolor" >}}).

![Not every color combination is beautiful](/img/kreismitfarbe.png)

## Color definitions

Colors can be assigned to a name with [`<DefineColor>`]({{< relref "/reference/definecolor" >}}) and then addressed under that name:

```xml
<DefineColor name="logocolor" model="cmyk" c="0" m="18" y="90" k="2" />
<PlaceObject>
  <Box height="4" width="3" background-color="logocolor" />
</PlaceObject>
```

The values are between 0 (no color application) and 100 or 255 (full color application). The permitted attributes can be found in the following table:

| Color space | Attributes | Values |
| --- | --- | --- |
| `cmyk` | `c`, `m`, `y`, `k` | 0–100 (0,0,0,0 = white, 0,0,0,100 = black) |
| `rgb` | `r`, `g`, `b` | 0–100 (0,0,0 = black, 100,100,100 = white) |
| `RGB` | `r`, `g`, `b` | 0–255 (0,0,0 = black, 255,255,255 = white) |
| `gray` | `g` | 0–100 (0 = black, 100 = white) |


## Spot colors {{< profeature "Available in the Pro plan" >}}

Spot colors are colors that are addressed separately in the printer.
They are unknown to the PDF display program and must be approximated for the screen output.
For many printing colors such as Pantone or HKS, these values are already stored in the Publisher, but they can or must be defined separately for unknown spot colors.

In the following case, the spot color is already known and can be used without CMYK values:

```xml
<DefineColor name="logocolor" model="spotcolor"
             colorname="PANTONE 116 C" />

<Record element="data">
  <PlaceObject>
    <Box width="5" height="2" background-color="logocolor"/>
  </PlaceObject>
</Record>
```

![Various spot colors are predefined in the Publisher, such as the Pantone 116 color.](/img/box116c.png)

In the next example, the spot color `speedatagreen` is used and the CMYK replacement value is defined for the PDF display program:

```xml
<DefineColor
    name="mycolor"
    model="spotcolor"
    colorname="speedatagreen"
    c="56" m="7" y="98" k="21" />
```

Here a color is defined which is addressed in the Publisher with the output commands under the name `mycolor`. In the PDF this color is called `speedatagreen` and in the output it appears in a dark green.

![The new color appears in the PDF as a separate color channel](/img/speedatagruen.png)

## Color values similar to HTML/CSS

HTML and CSS like colors can be used directly:

```xml
<PlaceObject allocate="no" column="3">
    <Box height="4" width="5" background-color="#FFC72C"  />
</PlaceObject>
```

The colors can not only be written as hex values (three or six digits), but also as `rgb(...)` such as `rgb(255, 19, 147)`. These values can also be used with `<DefineColor>`:

```xml
<DefineColor name="myred" value="rgb(255,0,0)" />
```

## Transparency

Color values can be specified with an alpha channel that specifies the color intensity in the range 0-100, where 100 is full coverage and 0 does not represent the color at all. HTML specifications like `rgb(...)` can specify the opacity as a fourth parameter as a value from 0-1. Transparency may not work with all graphic objects. If you encounter a problem, please don't hesitate to file a [bug report]({{< relref "troubleshooting" >}}).
