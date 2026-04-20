---
linktitle: "Barcode"
weight: 90
type: docs
---

# `Barcode` {{< profeature "This feature is only available in the Pro plan" >}}


Print a 1d or 2d barcode. To be used in [`PlaceObject`]({{% relref "placeobject" %}}).



## Child elements

(none)

## Parent elements

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../i"><code>I</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../position"><code>Position</code></a>, <a href="../span"><code>Span</code></a>, <a href="../td"><code>Td</code></a>, <a href="../transformation"><code>Transformation</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`color` (optional, _since version 4.5.11_)
: Color of the barcode. Must be defined with [`DefineColor`]({{% relref "definecolor" %}}) before use. Currently only used for QR codes.



`eclevel` (optional, _since version 2.7.10_)
: Set the error correction level for QR-codes. If not provided, the system uses the maximum level for minimum size. The higher the level, the more error correction is in the QR-code.


  - `L`: Set the lowest level (1) with approx. 7% recovery.
  - `M`: Set the second lowest level (2) with approx. 15% recovery.
  - `Q`: Set the second highest level (3) with approx. 25% recovery.
  - `H`: Set the highest level (4) with approx. 35% recovery.

`fontfamily` (text, optional)
: Name of the font of the text that can be placed beneath the barcode. Not used in all codes.



`height` (number or length, optional)
: Height of the barcode.



`keepfontsize` (yes or no, optional, _since version 4.1.2_)
: Try to keep the size of the requested font. Works with EAN13 only.



`overshoot` (number, optional)
: The factor denoting the extra length of the outer and middle bar. Only useful with EAN13.



`select` ([XPath expression]({{% relref "../manual/xpathref/xpath" %}}))
: The data to be encoded in the barcode.



`showtext` (optional)
: Should the text be written under the barcode?


  - `yes`: Write text beneath the barcode.
  - `no`: Don't display text.

`type` ()
: Type of the barcode. One of `EAN13`, `Code128` or `QRCode`.


  - `QRCode`: Create an “optimal” QR code in terms of error correction and size.
  - `Code128`: Generate a code 128 barcode for numbers and text.
  - `EAN13`: Create an EAN13 barcode for 13 digits.

`width` (number or length, optional)
: Width of the barcode






## Example


```xml
<PlaceObject>
  <Barcode select="'speedata Publisher'" type="Code128" showtext="yes"/>
</PlaceObject>
```

gives



![ref-code128-speedata-publisher.png](/img/ref-code128-speedata-publisher.png)

```xml
<PlaceObject>
  <Barcode select="4242002518169" type="EAN13"/>
</PlaceObject>
```

becomes



![ref-ean13-supertex.png](/img/ref-ean13-supertex.png)

And finally the QR code



```xml
<PlaceObject>
  <Barcode select="'http://www.speedata.de'" type="QRCode" height="5"/>
</PlaceObject>

```

looks like



![ref-speedata-publisher-qrcode.png](/img/ref-speedata-publisher-qrcode.png)



