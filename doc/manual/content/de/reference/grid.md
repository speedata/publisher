---
linktitle: "Grid"
weight: 380
type: docs
---

# `Grid`


Überschreibt das allgemeine Raster aus [`SetGrid`]({{% relref "setgrid" %}}).



## Kindelemente

(keine)

## Elternelemente

<a href="../group"><code>Group</code></a>, <a href="../pagetype"><code>Pagetype</code></a>

## Attribute


`dx` (optional, _seit Version 2.3.11_)
: Abstand zwischen zwei Rasterzellen (horizontal)



`dy` (optional, _seit Version 2.3.46_)
: Abstand zwischen zwei Rasterzellen (horizontal)



`height` (Längenangabe, optional)
: Höhe einer Rasterzelle.



`nx` (Zahl, optional)
: Anzahl der Rasterzellen in horizontaler Richtung.



`ny` (Zahl, optional)
: Anzahl der Rasterzellen in vertikaler Richtung.



`width` (Längenangabe, optional)
: Breite einer Rasterzelle.





## Bemerkungen

nx und ny haben keinen Sinn in [`Group`]({{% relref "group" %}}).




## Beispiel


```xml
<SetGrid width="5mm" height="14pt" />

<Pagetype name="Seite breit"  test=" $var > 10 ">
  <Margin left="1cm" right="2cm" top="1cm" bottom="1cm" />
  <Grid width="10mm" height="14pt" />
</Pagetype>
```

Wenn diese Seite ausgewählt wird, gilt das dort angegebene Raster.





