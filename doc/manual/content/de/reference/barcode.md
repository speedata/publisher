---
linktitle: "Barcode"
weight: 90
type: docs
---

# `Barcode` {{< profeature "Dieses Feature ist nur im Pro-Paket verfügbar" >}}


Erzeugt einen 1D oder 2D Strichcode (barcode), der in [`PlaceObject`]({{% relref "placeobject" %}}) ausgegeben werden kann.



## Kindelemente

(keine)

## Elternelemente

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../i"><code>I</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../position"><code>Position</code></a>, <a href="../span"><code>Span</code></a>, <a href="../td"><code>Td</code></a>, <a href="../transformation"><code>Transformation</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`color` (optional, _seit Version 4.5.11_)
: Farbe des Strichcodes. Muss vorher mit [`DefineColor`]({{% relref "definecolor" %}}) definiert worden sein. Derzeit nur für QR-Codes.



`eclevel` (optional, _seit Version 2.7.10_)
: Setzt den Fehlerkorrekturlevel für QR-Codes. Wenn nicht angegeben, nutzt das System den maximalen Level für die kleinste QR-Code Größe. Je höher der Level, desto mehr Fehlerkorrektur ist im QR-Code.


  - `L`: Setzt den kleinsten Fehlerkorrekturwert (1) mit ca. 7% Korrektur.
  - `M`: Setzt den zweitkleinsten Fehlerkorrekturwert (2) mit ca. 15% Korrektur.
  - `Q`: Setzt den zweitgrößten Fehlerkorrekturwert (3) mit ca. 25% Korrektur.
  - `H`: Setzt den größten Fehlerkorrekturwert (4) mit ca. 35% Korrektur.

`fontfamily` (Text, optional)
: Name der Schriftart des Textes, der ggf. unterhalb des Strichcodes ausgegeben wird. Nicht in allen Codes verwendet.



`height` (Zahl oder Längenangabe, optional)
: Höhe des Strichcodes.



`keepfontsize` (yes oder no, optional, _seit Version 4.1.2_)
: Versuche die Schriftgröße beizubehalten (EAN13).



`overshoot` (Zahl, optional)
: Der Faktor, um den die äußeren und der innere Balken die normalen Balken übersteigt. Nur anwendbar bei EAN13.



`select` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}))
: Wert, der als Strichcode kodiert werden soll.



`showtext` (optional)
: Bestimmt, ob unterhalb des Barcodes der Text erscheint.


  - `yes`: Text unterhalb des Barcodes schreiben.
  - `no`: Keinen Text anzeigen.

`type` ()
: Typ des Strichcodes. Kann `EAN13`, `Code128` oder `QRCode` sein.


  - `QRCode`: Erzeugt einen QR-Code, der für den Inhalt die kleinstmögliche Größe und den besten Fehlerkorrekturwert hat, sofern kein Fehlerkorrekturlevel angegeben ist.
  - `Code128`: Erzeugt einen Code 128 Barcode für Ziffern und Text (ohne Umlaute)
  - `EAN13`: Erzeugt einen EAN13 Barcode mit genau 13 Ziffern.

`width` (Zahl oder Längenangabe, optional)
: Breite des Strichcodes






## Beispiel


```xml
<PlaceObject>
  <Barcode select="'speedata Publisher'" type="Code128" showtext="yes"/>
</PlaceObject>
```

ergibt



![ref-code128-speedata-publisher.png](/img/ref-code128-speedata-publisher.png)

```xml
<PlaceObject>
  <Barcode select="4242002518169" type="EAN13"/>
</PlaceObject>
```

wird zu



![ref-ean13-supertex.png](/img/ref-ean13-supertex.png)

und



```xml
<PlaceObject>
  <Barcode select="'http://www.speedata.de'" type="QRCode" height="5"/>
</PlaceObject>

```

wird zu



![ref-speedata-publisher-qrcode.png](/img/ref-speedata-publisher-qrcode.png)



