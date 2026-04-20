---
linktitle: "Box"
weight: 130
type: docs
---

# `Box`


Erzeugt einen rechteckigen gefärbten Bereich. Die Fläche muss mit den Rasterzellen übereinstimmen.



## Kindelemente

(keine)

## Elternelemente

<a href="../case"><code>Case</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../position"><code>Position</code></a>, <a href="../td"><code>Td</code></a>, <a href="../transformation"><code>Transformation</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`background-color` (Text, optional, CSS Eigenschaft: background-color)
: Farbe der Box. Wird für die Farbe ein Strich angegeben (`-`), ist der Hintergrund transparent.



`bleed` (optional)
: Lässt die Box am Rand größer werden. Wird z.B. für Daumenregister benutzt, die inkl. Beschnitt ganz zum Rand gehen sollen. Inhalt ist eine Ortsangabe bestehend aus den Werten »top«, »bottom«, »left« oder »right« bzw. eine Kombination wie »top,right«.


  - `auto`: Vergrößere aufgrund der Position der Box.
  - `top`: Vergrößere nach oben.
  - `left`: Vergrößere nach links.
  - `bottom`: Vergrößere nach unten.
  - `right`: Vergrößere nach rechts.
  - `top,left`: Vergrößere nach oben und links.
  - `top,right`: Vergrößere nach oben und rechts.
  - `bottom,left`: Vergrößere nach unten und links.
  - `bottom,right`: Vergrößere nach unten und rechts.

`border-color` (Text, optional, _seit Version 5.5.8_)
: Farbe des Rahmens. Muss zusammen mit `border-width` verwendet werden. Der Rahmen wird innerhalb der Box-Abmessungen gezeichnet und verkleinert die Füllfläche entsprechend.



`border-width` (Längenangabe, optional, _seit Version 5.5.8_)
: Breite des Rahmens. Muss zusammen mit `border-color` verwendet werden.



`class` (Text, optional)
: CSS Klasse für diese Box.



`graphic` (Text, optional, _seit Version 4.3.10_)
: Der Name der Metapost Grafik, die anstelle der Box angezeigt werden soll.



`height` (Zahl oder Längenangabe)
: Höhe der Box in Rasterzellen.



`id` (Text, optional)
: CSS id für diese Box.



`padding-bottom` (Längenangabe, optional, CSS Eigenschaft: padding-bottom, _seit Version 2.5.10_)
: Bestimmt den Innenabstand der Box (unten)



`padding-left` (Längenangabe, optional, CSS Eigenschaft: padding-left, _seit Version 2.5.10_)
: Bestimmt den Innenabstand der Box (links)



`padding-right` (Längenangabe, optional, CSS Eigenschaft: padding-right, _seit Version 2.5.10_)
: Bestimmt den Innenabstand der Box (rechts)



`padding-top` (Längenangabe, optional, CSS Eigenschaft: padding-top, _seit Version 2.5.10_)
: Bestimmt den Innenabstand der Box (oben)



`vertical-align` (optional, _seit Version 5.5.8_)
: Vertikale Ausrichtung der Box bei Verwendung als Inline-Element in einem Absatz. Wirkt nur, wenn die Box zusammen mit Text oder anderen Inline-Elementen in einem Absatz steht.


  - `bottom`: Die Unterkante der Box an der Unterkante der Zeilenbox ausrichten (unterhalb der Grundlinie, an der Unterlängenlinie).

`width` (Zahl oder Längenangabe)
: Breite der Box in Rasterzellen.






## Beispiel


```xml
<DefineColor name="meingrün" model="cmyk" c="22" m="0" y="55" k="0"/>
<PlaceObject>
  <Box width="10" height="5" background-color="meingrün" />
</PlaceObject>

```

erzeugt ein farbiges Rechteck



![ref-greenbox.png](/img/ref-greenbox.png)



