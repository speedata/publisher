---
linktitle: "HSpace"
weight: 410
type: docs
---

# `HSpace`


Zwei Modi: bei einer gegebenen Breite wird ein Leerraum mit dieser Breite erzeugt.

Ohne Breitenangabe: erzeugt einen horizontalen dehnbaren Leerraum. Der Leerraum hat die minimale Größe 0 und die maximale Größe »unendlich«. Sinnvoll nutzbar in einzeiligen Absätzen. Im Fließtext wird es vermutlich unerwartete Ergebnisse hervorrufen. Der Leerraum in einer Zeile verteilt sich normalerweise gleichmäßig über jeden Wortzwischenraum. Wenn ein
      [`HSpace`]({{% relref "hspace" %}}) enthalten ist, erhalten alle Leerräume die minimale Breite, nur der dehnbare Leerraum hat den überschüssigen Leerraum »angehäuft«.



## Kindelemente

(keine)

## Elternelemente

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../i"><code>I</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../span"><code>Span</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`leader` (Text, optional, _seit Version 2.3.50_)
: Der Text, der anstelle des Leerraums angezeigt wird. Beispielsweise der Punkt (.).



`leader-width` (Längenangabe, optional, _seit Version 2.3.50_)
: Abstand zwischen zwei Startpunkten des Texts in der Führungslinie.



`minwidth` (Längenangabe, optional, _seit Version 3.3.5_)
: Die (optionale) minimale Breite des eingefügten Leerraums.



`width` (Längenangabe, optional)
: Optionale Breite des Leerraums






## Beispiel


```xml
<PlaceObject>
  <Textblock>
    <Paragraph>
      <Value>Hallo</Value><HSpace/><Value>Welt</Value>
    </Paragraph>
  </Textblock>
</PlaceObject>
```



