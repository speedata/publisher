---
linktitle: "Italic"
weight: 490
type: docs
---

# `Italic`


The font face to be used when the user switches to italic.



## Child elements

(none)

## Parent elements

<a href="../definefontfamily"><code>DefineFontfamily</code></a>

## Attributes


`fontface` (text)
: The name of the fontface.






## Example


```xml
<LoadFontfile name="Helvetica" filename="helvetica-regular.otf"/>
<LoadFontfile name="Helvetica Bold" filename="helvetica-bold.otf"/>
<LoadFontfile name="Helvetica Italic" filename="helvetica-italic.otf"/>
<LoadFontfile name="Helvetica Bold Italic" filename="helvetica-bolditalic.otf"/>

<DefineFontfamily name="text" fontsize="12" leading="14">
  <Regular fontface="Helvetica"/>
  <Bold fontface="Helvetica Bold"/>
  <Italic fontface="Helvetica Italic"/>
  <BoldItalic fontface="Helvetica Bold Italic"/>
</DefineFontfamily>

```



