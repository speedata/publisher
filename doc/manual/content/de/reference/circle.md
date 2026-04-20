---
linktitle: "Circle"
weight: 160
type: docs
---

# `Circle`
_seit Version 2.3.42_

Erzeugt einen Kreis oder eine Ellipse.



## Kindelemente

(keine)

## Elternelemente

<a href="../clip"><code>Clip</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../position"><code>Position</code></a>, <a href="../transformation"><code>Transformation</code></a>

## Attribute


`background-color` (Text, optional, CSS Eigenschaft: background-color)
: Farbe des Kreises.



`class` (Text, optional)
: CSS Klasse für diesen Kreis.



`framecolor` (Text, optional, CSS Eigenschaft: color)
: Farbe der Kreislinie.



`id` (Text, optional)
: CSS id für diesen Kreis.



`radiusx` (Zahl oder Längenangabe)
: Radius des Kreises in Rasterzellen (horizontal) oder als absolute Maßangabe. In Verbindung mit `radiusy` lässt sich eine Ellipse erzeugen.



`radiusy` (Zahl oder Längenangabe, optional)
: Radius der Ellipse in Rasterzellen (vertikal) oder als absolute Maßangabe.



`rulewidth` (Längenangabe, optional)
: Die Dicke des Striches um den Kreis.






## Beispiel


```xml
<DefineColor name="meingrün" model="cmyk" c="22" m="0" y="55" k="0"/>
<PlaceObject>
  <Circle radiusx="10mm" background-color="blue" framecolor="meingrün" rulewidth="1mm"/>
</PlaceObject>

```

erzeugt einen Kreis



![ref-circlewithborder.png](/img/ref-circlewithborder.png)



