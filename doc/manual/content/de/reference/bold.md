---
linktitle: "Bold"
weight: 100
type: docs
---

# `Bold`


Name der Schriftart, die für den Schnitt Fett benutzt werden soll.



## Kindelemente

(keine)

## Elternelemente

<a href="../definefontfamily"><code>DefineFontfamily</code></a>

## Attribute


`fontface` (Text)
: Name der Schriftart, die für eine fette Schrift benutzt werden soll.






## Beispiel


```xml
<LoadFontfile name="Times" filename="timesregular.otf" />
<LoadFontfile name="Times Fett" filename="timesbold.otf" />
<LoadFontfile name="Times Kursiv" filename="timesitalic.otf" />
<LoadFontfile name="Times Fett Kursiv" filename="timesbolditalic.otf" />
...

<DefineFontfamily name="text" fontsize="12" leading="14">
  <Regular    fontface="Times"/>
  <Bold       fontface="Times Fett"/>
  <Italic     fontface="Times Kursiv"/>
  <BoldItalic fontface="Times Fett Kursiv"/>
</DefineFontfamily>
```



