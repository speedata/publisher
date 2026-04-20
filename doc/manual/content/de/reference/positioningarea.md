---
linktitle: "PositioningArea"
weight: 740
type: docs
---

# `PositioningArea`


Beschreibt einen Platzierungsbereich, der mehrere Platzierungsrahmen beinhalten kann. In diesen Rahmen können Elemente platziert werden



## Kindelemente

<a href="../loop"><code>Loop</code></a>, <a href="../positioningframe"><code>PositioningFrame</code></a>, <a href="../switch"><code>Switch</code></a>

## Elternelemente

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../pagetype"><code>Pagetype</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`framecolor` (Text, optional, _seit Version 2.9.12_)
: Setze die Farbe im Modus wenn die Platzierungsbereiche angezeigt werden (grid=yes). Voreinstellung ist 'red'.



`name` (Text)
: Name des Platzierungsbereichs






## Beispiel


```xml
<PositioningArea name="rahmen1">
  <PositioningFrame width="12" height="30" column="2" row="2"/>
  <PositioningFrame width="12" height="30" column="16" row="2"/>
</PositioningArea>
```



