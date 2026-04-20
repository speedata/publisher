---
linktitle: "Rule"
weight: 790
type: docs
---

# `Rule`


Zeichnet eine horizontale oder vertikale Linie im Raster.



## Kindelemente

(keine)

## Elternelemente

<a href="../clip"><code>Clip</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../position"><code>Position</code></a>, <a href="../transformation"><code>Transformation</code></a>

## Attribute


`color` (Text, optional, CSS Eigenschaft: background-color)
: Farbe der Linie. Vorgabe: Schwarz



`dashed` (optional, _seit Version 2.3.50_)
: Benutze eine gestrichelte Linie.


  - `yes`: Zeichne eine gestrichelte Linie.
  - `no`: Zeichne eine durchgezogene Linie.

`direction` ()
: Bestimmt die Ausrichtung der Linie.


  - `horizontal`: Horizontale Linie
  - `vertical`: Vertikale Linie

`length` (Zahl oder Längenangabe)
: Länge der Linie in Rasterzellen oder als absolute Angabe.



`rulewidth` (Zahl oder Längenangabe, optional, CSS Eigenschaft: height)
: Dicke der Linie in Rasterzellen oder als absolute Angabe.






## Beispiel


```xml
<Record element="data">
  <PlaceObject>
    <Rule direction="horizontal" length="10" rulewidth="3"/>
  </PlaceObject>
</Record>

```



