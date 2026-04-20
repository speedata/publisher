---
linktitle: "Span"
weight: 860
type: docs
---

# `Span`
_seit Version 3.1.15_

Text mit Style-Optionen umgeben.



## Kindelemente

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../barcode"><code>Barcode</code></a>, <a href="../br"><code>Br</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../hspace"><code>HSpace</code></a>, <a href="../i"><code>I</code></a>, <a href="../image"><code>Image</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../span"><code>Span</code></a>, <a href="../sub"><code>Sub</code></a>, <a href="../sup"><code>Sup</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../value"><code>Value</code></a>

## Elternelemente

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../i"><code>I</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../span"><code>Span</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`background-color` (Text, optional, CSS Eigenschaft: background-color)
: Die Hintergrundfarbe des Inhalts.



`background-padding-bottom` (Längenangabe, optional, CSS Eigenschaft: background-padding-bottom)
: Der Innenabstand (unten) der Hintergrundfarbe (kann negativ sein)



`background-padding-top` (Längenangabe, optional, CSS Eigenschaft: background-padding-top)
: Der Innenabstand (oben) der Hintergrundfarbe (kann negativ sein)



`class` (Text, optional)
: CSS Klasse für dieses Element.



`fontfamily` (Text, optional, _seit Version 4.1.14_)
: Schaltet auf die angegebene Schriftfamilie um.



`id` (Text, optional)
: CSS id für dieses Element.



`language` (optional, _seit Version 4.1.10_)
: Name der Sprache für die Silbentrennung und Darstellung.



`letter-spacing` (Längenangabe, optional, CSS Eigenschaft: letter-spacing, _seit Version 3.5.2_)
: Erhöhe Leerraum zwischen Zeichen.



`role` (optional, _seit Version 4.19.8_)
: Die Rolle für PDF/UA (barrierefreiheit, tagged PDF)






## Beispiel


```xml
<Stylesheet>
  .green { background-color: lightgreen; }
</Stylesheet>

<Record element="data">
  <PlaceObject>
    <Textblock>
      <Paragraph>
        <Span class="green"><Value>green</Value></Span>
      </Paragraph>
    </Textblock>
  </PlaceObject>
</Record>

```



