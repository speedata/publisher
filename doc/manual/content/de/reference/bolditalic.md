---
linktitle: "BoldItalic"
weight: 110
type: docs
---

# `BoldItalic`


Name der Schriftart, die für den Schnitt Fett-Kursiv benutzt werden soll.



## Kindelemente

(keine)

## Elternelemente

<a href="../definefontfamily"><code>DefineFontfamily</code></a>

## Attribute


`fontface` (Text)
: Name der Schriftart, die für eine Fett/Kursive Schrift benutzt werden soll.






## Beispiel


```xml
<LoadFontfile name="Times" filename="timesregular.otf" />
<LoadFontfile name="Times Fett" filename="timesbold.otf" />
<LoadFontfile name="Times Fett" filename="timesbold.otf" />
<LoadFontfile name="Times Kursiv" filename="timesitalic.otf" />
<LoadFontfile name="Times Fett Kursiv" filename="timesbolditalic.otf" />
...

<DefineFontfamily name="text" fontsize="12" leading="14">
  <Regular     fontface="Times"/>
  <Bold       fontface="Times Fett"/>
  <Italic     fontface="Times Kursiv"/>
  <BoldItalic fontface="Times Fett Kursiv"/>
</DefineFontfamily>
```



