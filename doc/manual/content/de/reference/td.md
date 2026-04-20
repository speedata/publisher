---
linktitle: "Td"
weight: 970
type: docs
---

# `Td`


Erstellt eine Tabellenzelle, wie in HTML



## Kindelemente

<a href="../barcode"><code>Barcode</code></a>, <a href="../bookmark"><code>Bookmark</code></a>, <a href="../box"><code>Box</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../groupcontents"><code>Groupcontents</code></a>, <a href="../image"><code>Image</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../mark"><code>Mark</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../table"><code>Table</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../vspace"><code>VSpace</code></a>, <a href="../value"><code>Value</code></a>

## Elternelemente

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../tr"><code>Tr</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`align` (optional, CSS Eigenschaft: text-align)
: Die horizontale Ausrichtung des Tabelleninhalts


  - `left`: Der Inhalt der Zelle ist am linken Rand ausgerichtet. (Voreinstellung)
  - `right`: Der Inhalt der Zelle ist rechtsbündig ausgerichtet.
  - `center`: Der Inhalt der Zelle ist auf der Mittelachse ausgerichtet mit links und rechts Flatterrand.
  - `justify`: Text im Blocksatz.

`background-color` (Text, optional, CSS Eigenschaft: background-color)
: Der Name der Hintergrundfarbe, wenn die Zelle eingefärbt werden soll.



`background-font-family` (Text, optional, CSS Eigenschaft: background-font-family, _seit Version 2.3.7_)
: Setzt die Fontfamilie für den Hintergrundtext. Voreinstellung ist die Fontfamilie für die Tabelle.



`background-size` (optional, CSS Eigenschaft: background-size, _seit Version 2.3.7_)
: Bestimmt die Größe des Hintergrundtexts. Derzeit ist nur 'contain' und 'auto' erlaubt.


  - `contain`: Der Text passt sich der Zellenhöhe an.
  - `auto`: Der Hintergrundtext wird nicht skaliert.

`background-text` (optional, CSS Eigenschaft: background-text, _seit Version 2.3.7_)
: Ein Text, der in den Tabellenhintergrund gelegt wird.



`background-textcolor` (optional, CSS Eigenschaft: background-textcolor, _seit Version 2.3.7_)
: Die Farbe des Hintergrundtexts, falls vorhanden.



`background-transform` (optional, CSS Eigenschaft: background-transform, _seit Version 2.3.7_)
: Die Transformation des Hintergrundtexts (falls vorhanden). Derzeit wird folgende Angabe unterstützt: `rotate(-40deg) (und andere Winkel im Bereich 0 bis -90).`



`border-bottom` (Längenangabe, optional, CSS Eigenschaft: border-bottom-width)
: Die Breite der Linie unten. Die Linie liegt innerhalb der Zelle.



`border-bottom-color` (Text, optional, CSS Eigenschaft: border-bottom-color)
: Die Farbe der Linie unten.



`border-left` (Längenangabe, optional, CSS Eigenschaft: border-left-width)
: Die Breite der Linie links. Die Linie liegt innerhalb der Zelle.



`border-left-color` (Text, optional, CSS Eigenschaft: border-left-color)
: Die Farbe der Linie links.



`border-right` (Längenangabe, optional, CSS Eigenschaft: border-right-width)
: Die Breite der Linie rechts. Die Linie liegt innerhalb der Zelle.



`border-right-color` (Text, optional, CSS Eigenschaft: border-right-color)
: Die Farbe der Linie rechts.



`border-top` (Längenangabe, optional, CSS Eigenschaft: border-top-width)
: Die Breite der Linie oben. Die Linie liegt innerhalb der Zelle.



`border-top-color` (Text, optional, CSS Eigenschaft: border-top-color)
: Die Farbe der Linie oben.



`class` (Text, optional)
: Die CSS-Klasse für die Formtierung.



`colspan` (Zahl, optional)
: Die Anzahl der Spalten, die die Zelle überdecken soll. Voreinstellung ist 1.



`graphic` (Text, optional, _seit Version 4.3.12_)
: Zeichne die vordefinierte MetaPost-Grafik um die Tabellenzelle.



`id` (Text, optional)
: CSS id für diese Tabellenzelle.



`padding` (Längenangabe, optional, CSS Eigenschaft: padding)
: Kurzform für die Bestimmung von padding-top und den anderen drei Werten mit derselben Maßangabe



`padding-bottom` (Längenangabe, optional, CSS Eigenschaft: padding-bottom)
: Bestimmt den Innenabstand einer Tabelle (unten)



`padding-left` (Längenangabe, optional, CSS Eigenschaft: padding-left)
: Bestimmt den Innenabstand einer Tabelle (links)



`padding-right` (Längenangabe, optional, CSS Eigenschaft: padding-right)
: Bestimmt den Innenabstand einer Tabelle (rechts)



`padding-top` (Längenangabe, optional, CSS Eigenschaft: padding-top)
: Bestimmt den Innenabstand einer Tabelle (oben)



`role` (optional, _seit Version 4.19.23_)
: Die Rolle für PDF/UA (barrierefreiheit, tagged PDF)



`rotate` (Zahl, optional, _seit Version 3.3.7_)
: Drehe den Inhalt (im Uhrzeigersinn) der Tabellenzelle. Experimentell und derzeit nur für Textinhalte.



`rowspan` (Zahl, optional)
: Die Anzahl der Zeilen, die die Zelle überdecken soll. Voreinstellung ist 1.



`valign` (optional, CSS Eigenschaft: vertical-align)
: Die vertikale Ausrichtung des Zelleninhalts.


  - `top`: Der Zellinhalt ist an der oberen Kante ausgerichtet.
  - `middle`: Der Zellinhalt vertikal zentriert.
  - `bottom`: Der Zellinhalt ist an der unteren Kante ausgerichtet.



## Bemerkungen

Die Kindelemente der Tabellenzelle können Blockobjekte oder Zeilenobjekte sein. Blockobjekte erzeugen eine neue Zeile, Zeilenobjekte werden von rechts nach links
        so lange in eine Zeile geschrieben, bis die Zeilenbreite einen Zeilenumbruch erzwingt. Blockobjekte sind [`Paragraph`]({{% relref "paragraph" %}}), [`Table`]({{% relref "table" %}}) und [`Box`]({{% relref "box" %}}), Zeilenobjekte sind [`Barcode`]({{% relref "barcode" %}}) und [`Image`]({{% relref "image" %}}).

Das Attribut align erzeugt implizit ein Textformat (nur in Bezug auf Ausrichtung) für alle Kindelemente Paragraph, sofern dort kein Textformat angegeben ist.




## Beispiel


```xml
<Tr>
  <Td colspan="2" align="right"><Paragraph><Value>Text</Value></Paragraph></Td>
  <Td rowspan="3"><Image width="3" file="bildname.jpg"/></Td>
</Tr>
```



