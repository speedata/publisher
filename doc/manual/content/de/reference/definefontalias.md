---
linktitle: "DefineFontalias"
weight: 270
type: docs
---

# `DefineFontalias`
_seit Version 2.7.12_

Definiert einen Alias für die Verwendung bei [`DefineFontfamily`]({{% relref "definefontfamily" %}}). Aliase werden rekursiv aufgelöst.



## Kindelemente

(keine)

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`alias` (Text)
: Neuer (gleichberechtigter) Name der Schriftart



`existing` (Text)
: Der Name der existierenden Schriftfamilie.






## Beispiel


```xml
<DefineFontalias existing="DejaVuSerif" alias="serif"/>
<DefineFontalias existing="DejaVuSerif-Bold" alias="serif-bold"/>
<DefineFontalias existing="DejaVuSerif-Italic" alias="serif-italic"/>
<DefineFontalias existing="DejaVuSerif-BoldItalic" alias="serif-bolditalic"/>
```

Eine neue Schriftfamilie kann nun so definiert werden:



```xml
<DefineFontfamily name="Überschrift" fontsize="15" leading="17">
  <Regular fontface="serif"/>
  <Bold fontface="serif-bold"/>
  <BoldItalic fontface="serif-bolditalic"/>
  <Italic fontface="serif-italic"/>
</DefineFontfamily>
```



