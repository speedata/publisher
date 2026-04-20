---
linktitle: "Regular"
weight: 780
type: docs
---

# `Regular`


Dient als Festlegung des Schriftschnittes, wenn keine Formatierung angegeben ist.



## Kindelemente

(keine)

## Elternelemente

<a href="../definefontfamily"><code>DefineFontfamily</code></a>

## Attribute


`fontface` (Text)
: Name der Schriftdatei, die geladen werden soll.






## Beispiel


```xml
<LoadFontfile name="Helvetica" filename="helvetica-regular.otf" />
...

<DefineFontfamily name="text" fontsize="12" leading="14">
  <Regular    fontface="Helvetica"/>
  <Bold       fontface="Helvetica Fett"/>
  <Italic     fontface="Helvetica Kursiv"/>
  <BoldItalic fontface="Helvetica Fett Kursiv"/>
</DefineFontfamily>
```



