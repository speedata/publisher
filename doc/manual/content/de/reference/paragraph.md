---
linktitle: "Paragraph"
weight: 700
type: docs
---

# `Paragraph`


Erzeugt einen Absatz innerhalb eines Textblocks.



## Kindelemente

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../barcode"><code>Barcode</code></a>, <a href="../br"><code>Br</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../hspace"><code>HSpace</code></a>, <a href="../i"><code>I</code></a>, <a href="../image"><code>Image</code></a>, <a href="../initial"><code>Initial</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../span"><code>Span</code></a>, <a href="../sub"><code>Sub</code></a>, <a href="../sup"><code>Sup</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../value"><code>Value</code></a>

## Elternelemente

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../td"><code>Td</code></a>, <a href="../text"><code>Text</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`actualtext` (Text, optional, _seit Version 4.19.23_)
: Setze den Text für Bildschirmlesegeräte.



`allowbreak` (Text, optional)
: (Experimentell) Liste der Zeichen, bei denen ein Umbruch möglich ist. Das Leerzeichen wird nicht automatisch als Umbruchbunkt erkannt, wenn das Attribut angegeben ist.



`bidi` (optional, _seit Version 4.1.14_)
: Analysiere die Richtung des Textes. Hilfreich für gemsichten links-nach-rechts und rechts-nach-links Text.


  - `yes`: Analysiere den Text.
  - `no`: Unterschiedliche Textrichtungen nicht beachten (Voreinstellung).

`class` (Text, optional)
: CSS Klasse für diesen Absatz.



`color` (Text, optional, CSS Eigenschaft: color)
: Farbe des Absatzes. Muss vorher mit [`DefineColor`]({{% relref "definecolor" %}}) definiert worden sein.



`direction` (Text, optional, _seit Version 4.1.12_)
: Die Laufrichtung des Textes (ltr oder rtl)



`font-outline` (Längenangabe, optional, _seit Version 4.13.15_)
: Setze die Liniendicke der Schriftkontur.



`fontfamily` (Text, optional, CSS Eigenschaft: font-family)
: Name der Schriftfamilie. Voreinstellung ist »text« (mit kleinem t).



`html` (optional, _seit Version 4.1.2_)
: Stelle die HTML-Verarbeitung ein. Voreinstellung ist 'all'.


  - `all`: Interpretiere HTML beginnend mit dem aktuellen Element.
  - `inner`: Ignoriere den Namen des äußeren Elements.
  - `off`: HTML in diesem Absatz auschalten. Nehme nur den Text.

`id` (Text, optional)
: CSS id für diesen Absatz.



`label-left` (Text, optional, _seit Version 4.1.4_)
: Text der links vom Absatz ausgegeben wird.



`label-left-align` (optional, _seit Version 4.1.4_)
: Ausrichtung des Textes


  - `left`: Linksbündig
  - `right`: Rechtsbündig

`label-left-distance` (Längenangabe, optional, _seit Version 4.1.4_)
: Horizontaler Abstand zwischen Text und Absatz (wenn rechtsbündig).



`label-left-width` (Längenangabe, optional, _seit Version 4.1.4_)
: Breite des Textes



`language` (optional)
: Name der Sprache für die Silbentrennung und Darstellung.



`padding-left` (Längenangabe, optional, _seit Version 3.9.27_)
: Stelle das padding links ein, also der Innenabstand des Textblocks.



`padding-right` (Längenangabe, optional, _seit Version 3.9.27_)
: Stelle das padding rechts ein, also der Innenabstand des Textblocks.



`parent` (Text, optional, _seit Version 4.19.8_)
: Die ID der Elternstruktur für tagged PDF. Wenn leer (''), dann wird versucht, die implizite Rollen-ID des Elternelements im Layout-XML zu nutzen.



`role` (optional, _seit Version 3.5.7_)
: Die Rolle für PDF/UA (barrierefreiheit, tagged PDF)



`structpos` (top, cur oder Zahl, optional, _seit Version 4.19.23_)
: Bestimme die Position des Tags in der Strukturhierarchie für PDF/UA. Voreinstellung ist 'cur', das Element wird in der aktuellen Postion (also am aktuellen Ende) eingefügt. 'top' oder 1 fügt das Element am Anfang der Struktur ein. Andere Zahlen bestimmen die Position des Elements.



`textformat` (Text, optional)
: Name des zu benutzenden Textformats. Wird kein Textformat angegeben, nimmt das System das Textformat `text`.






## Beispiel


```xml
<Textblock>
  <Paragraph fontfamily="Überschrift">
    <Value>Hallo Welt</Value>
  </Paragraph>
</Textblock>

```

```xml
<Textblock >
  <Paragraph fontfamily="Überschrift" language="German">
    <Value select="node()"/>
  </Paragraph>
  </Textblock>
```

wobei in den Daten ein Text steht, beispielsweise falls der aktuelle Knoten das Element [`Record`]({{% relref "record" %}}) ist:



```xml
<Record>Produktbeschreibung: die Artikelnummer <i>1234</i> setzt sich aus ... </Record>
```



