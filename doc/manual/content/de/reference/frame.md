---
linktitle: "Frame"
weight: 360
type: docs
---

# `Frame`


Um ein Objekt ein Rahmen zeichnen. Kann als Clipping-Pfad benutzt werden.



## Kindelemente

<a href="../barcode"><code>Barcode</code></a>, <a href="../box"><code>Box</code></a>, <a href="../circle"><code>Circle</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../image"><code>Image</code></a>, <a href="../rule"><code>Rule</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../table"><code>Table</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../transformation"><code>Transformation</code></a>

## Elternelemente

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../i"><code>I</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../position"><code>Position</code></a>, <a href="../span"><code>Span</code></a>, <a href="../td"><code>Td</code></a>, <a href="../transformation"><code>Transformation</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`background-color` (Text, optional)
: Hintergrundfarbe wenn das Objekt mit einer Farbe hinterlegt werden soll.



`border-bottom-left-radius` (Längenangabe, optional, CSS Eigenschaft: border-bottom-left-radius)
: Radius der Ecke unten links.



`border-bottom-right-radius` (Längenangabe, optional, CSS Eigenschaft: border-bottom-right-radius)
: Radius der Ecke unten rechts.



`border-radius` (optional, _seit Version 4.13.14_)
: Radien aller vier Ecken.



`border-top-left-radius` (Längenangabe, optional, CSS Eigenschaft: border-top-left-radius)
: Radius der Ecke oben links.



`border-top-right-radius` (Längenangabe, optional, CSS Eigenschaft: border-top-right-radius)
: Radius der Ecke oben rechts.



`class` (Text, optional)
: CSS Klasse für dieses Element.



`clip` (optional, _seit Version 3.5.10_)
: Bestimmt, ob die Inhalte des Rahmens auf dessen Fläche begrenzt werden sollen, oder ob sie darüber hinaus ragen dürfen.


  - `yes`: Die Inhalte werden an dessen Rändern des Rahmens abgeschnitten (Voreinstellung).
  - `no`: Die Inhalte nicht abschneiden.

`framecolor` (Text, optional)
: Die Farbe des Rahmens, wenn ein Rahmen ausgegeben wird. Voreinstellung ist 'black'. Kann mit der speziellen Farbe '-' ausgeschaltet werden.



`id` (Text, optional)
: CSS id für dieses Element.



`rulewidth` (Längenangabe, optional)
: Die Dicke des Rahmens, der um das Objekt gezogen wird. 






## Beispiel


```xml
<Record element="data">
  <PlaceObject>
    <Frame framecolor="red" border-bottom-left-radius="10pt">
      <Image width="20" file="_samplea.pdf"></Image>
    </Frame>
  </PlaceObject>
</Record>

```



