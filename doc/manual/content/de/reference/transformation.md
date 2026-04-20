---
linktitle: "Transformation"
weight: 1020
type: docs
---

# `Transformation`


Das Aussehen eines Objekts manipulieren, in dem eine Matrix-Operation angewendet wird. Siehe PDF-Referenz 4.2.2 und folgende.



## Kindelemente

<a href="../barcode"><code>Barcode</code></a>, <a href="../box"><code>Box</code></a>, <a href="../circle"><code>Circle</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../image"><code>Image</code></a>, <a href="../rule"><code>Rule</code></a>, <a href="../table"><code>Table</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../transformation"><code>Transformation</code></a>

## Elternelemente

<a href="../case"><code>Case</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../position"><code>Position</code></a>, <a href="../transformation"><code>Transformation</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`flip` (optional, _seit Version 4.19.37_)
: Objekt spiegeln


  - `horizontal`: Objekt horizontal spiegeln (links wird zu rechts)
  - `vertical`: Objekt vertikal spiegeln: Oben wird zu unten
  - `both`: Objekt auf beiden Achsen spiegeln
  - `none`: Objekt nicht spiegeln

`matrix` (Text, optional)
: Die Transformations-Matrix für das Objekt. Erwartet wird eine Leerzeichen-separierte Zeichenkette mit sechs Werten.



`origin-x` (Text, optional)
: Der Ursprung für Matrix-Transformation. Muss links, mitte oder rechts oder eine Zahl von 0 bis 100 (0 = links, 100 = rechts) sein.



`origin-y` (Text, optional)
: Der vertikale Ursprung der der Matrix-Transformation. Muss oben, mitte oder unten sein oder eine Zahl von 0 bis 100 (0 = oben, 100 = unten)






## Beispiel


```xml
<Record element="data">
  <PlaceObject>
    <Transformation matrix="1 0 0 1 72 -72">
      <Transformation matrix="1 0 0 0.5 0 0" origin-x="100">
        <Transformation matrix="1 1 -1 1 0 0">
          <Image file="_samplea.pdf" maxwidth="4" maxheight="4" />
        </Transformation>
      </Transformation>
    </Transformation>
  </PlaceObject>
</Record>

```



