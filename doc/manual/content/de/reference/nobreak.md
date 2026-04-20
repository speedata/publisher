---
linktitle: "NoBreak"
weight: 610
type: docs
---

# `NoBreak`
_seit Version 2.3.14_

Kein Umbruch innerhalb des Elements erlauben



## Kindelemente

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../barcode"><code>Barcode</code></a>, <a href="../br"><code>Br</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../hspace"><code>HSpace</code></a>, <a href="../i"><code>I</code></a>, <a href="../image"><code>Image</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../span"><code>Span</code></a>, <a href="../sub"><code>Sub</code></a>, <a href="../sup"><code>Sup</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../value"><code>Value</code></a>

## Elternelemente

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../i"><code>I</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../span"><code>Span</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`factor` (Zahl, optional)
: Multiplikator für die Schriftgröße, wenn reduce=fontsize. Voreinstellung: 0.9. Das bedeutet, dass die Schriftgröße um 0,9 reduziert wird, bis der Text in die vorgegebene Breite hineinpasst.



`fontfamily` (Text, optional)
: Name der Schriftart für den Text, der verkürzt werden soll. Voreinstellung ist »text« (mit kleinem t).



`maxwidth` (Zahl oder Längenangabe, optional)
: Setzt die maximale Breite des Texts, wenn sie sich nicht aus der Umgebung herleiten lässt (wie beispielsweise Tabellenzellen).



`reduce` (optional)
: Verringere die Textgröße falls notwendig.


  - `fontfit`: Verkleinert durch Verringerung der Schriftgröße, sodass der verfügbare Platz genau gefüllt wird.
  - `fontsize`: Verkleinert durch stufenweise Verringerung der Schriftgröße.
  - `cut`: Fügt den Text im Attribut text als Platzhalter ein, wenn der Paragraph zu lang ist.
  - `keeptogether`: Kein Zeilenumbruch innerhalb von NoBreak erlauben (Voreinstellung)

`text` (optional, _seit Version 2.3.53_)
: Der einzufügende Text, wenn der Paragraph zu lang ist. Zum Beispiel '...'






## Beispiel


```xml
<PlaceObject>
  <Textblock width="5">
    <Paragraph>
      <Value>Seit zwei Jahren ist meine Arbeit in Düsseldorf. </Value><Br/>
      <NoBreak reduce="fontsize" factor="0.9">
        <Value>Meine Familie lebt dagegen in Hamburg.</Value>
      </NoBreak>
      <Value> Und dazwischen ich, aber ganz cool.</Value>
    </Paragraph>
  </Textblock>
</PlaceObject>
```



