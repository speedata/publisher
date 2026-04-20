---
linktitle: "Clip"
weight: 180
type: docs
---

# `Clip`
_seit Version 4.11.3_

Beschneide ein Bild oder eine andere Ausgabe



## Kindelemente

<a href="../barcode"><code>Barcode</code></a>, <a href="../box"><code>Box</code></a>, <a href="../circle"><code>Circle</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../image"><code>Image</code></a>, <a href="../rule"><code>Rule</code></a>, <a href="../table"><code>Table</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../transformation"><code>Transformation</code></a>

## Elternelemente

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../i"><code>I</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../span"><code>Span</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`bottom` (Längenangabe, optional)
: Das Maß, das von der unteren Seite abgeschnitten wird.



`height` (Längenangabe, optional)
: Die sichtbare Höhe des Objekts. Sollte mit einem Wert top oder bottom benutzt werden.



`left` (Längenangabe, optional)
: Das Maß, das von der linken Seite abgeschnitten wird.



`method` (optional)
: Setze die Verkleinerungsmethode des erzeugten Objekts.


  - `clip`: Abschneiden und verkleinern.
  - `frame`: Nur den Rand des Objekts verstecken, nicht die Größe ändern.

`right` (Längenangabe, optional)
: Das Maß, das von der rechten Seite abgeschnitten wird.



`top` (Längenangabe, optional)
: Das Maß, das von der oberen Seite abgeschnitten wird.



`width` (Längenangabe, optional)
: Die sichtbare Breite des Objekts. Sollte mit einem Wert left oder right benutzt werden.






## Beispiel


```xml
<PlaceObject frame="solid">
    <Clip left="1cm" right="1cm" top="1cm" bottom="2cm" method="clip">
        <Image width="5cm" file="_sampleb.pdf" />
    </Clip>
</PlaceObject>
```



