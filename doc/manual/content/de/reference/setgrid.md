---
linktitle: "SetGrid"
weight: 830
type: docs
---

# `SetGrid`


Setzt die Größe und Höhe eines Rasterkästchens. In dem Seitenraster können Elemente platziert werden.



## Kindelemente

(keine)

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`dx` (optional, _seit Version 2.3.11_)
: Abstand zwischen zwei Rasterzellen (horizontal)



`dy` (optional, _seit Version 2.3.46_)
: Abstand zwischen zwei Rasterzellen (horizontal)



`height` (Längenangabe, optional)
: Höhe einer Rasterzelle. Entweder höhe oder ny angeben, nicht beide.



`nx` (Zahl, optional)
: Anzahl der Rasterzellen in horizontaler Richtung. Entweder nx oder width angeben.



`ny` (Zahl, optional)
: Gibt die Anzahl der Rasterzellen in vertikaler Richtung an. Entweder ny oder höhe angeben.



`width` (Längenangabe, optional)
: Breite einer Rasterzelle. Entweder width oder nx benutzen, nicht beide.






## Beispiel


```xml
<SetGrid width="4mm" height="14pt" />
```



