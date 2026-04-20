---
linktitle: "PositioningFrame"
weight: 750
type: docs
---

# `PositioningFrame`


Beschreibt einen rechteckigen Bereich, in dem Elemente platziert werden können. Inhalte in diesen Bereichen werden bei Platzmangel automatisch in den nächsten Rahmen desselben Bereichs platziert.



## Kindelemente

(keine)

## Elternelemente

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../positioningarea"><code>PositioningArea</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`column` (Zahl)
: Erste Spalte des Rahmens



`height` (Zahl)
: Höhe des Rahmens in Rasterkästen



`row` (Zahl)
: Erste Zeile des Rahmens



`width` (Zahl)
: Breite des Rahmens in Rasterkästen






## Beispiel


```xml
<PositioningArea name="rahmen1">
  <PositioningFrame width="12" height="30" column="2" row="2"/>
  <PositioningFrame width="12" height="30" column="16" row="2"/>
</PositioningArea>
```



