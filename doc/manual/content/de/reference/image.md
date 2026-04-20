---
linktitle: "Image"
weight: 450
type: docs
---

# `Image`


Bindet eine externe Grafik ein. Erlaubte Grafikformate sind PDF (.pdf), PNG (.png) und JPEG (.jpg). Andere Dateitypen sind mit externen Konvertierungsprogrammen möglich. Siehe unten für die Einschränkung eingebundener PDF-Dateien.



## Kindelemente

<a href="../value"><code>Value</code></a>

## Elternelemente

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../i"><code>I</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../position"><code>Position</code></a>, <a href="../span"><code>Span</code></a>, <a href="../td"><code>Td</code></a>, <a href="../text"><code>Text</code></a>, <a href="../transformation"><code>Transformation</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`bleed` (optional, _seit Version 2.9.5_)
: Soll das Bild um die Beschnittzugabe ([`Options`]({{% relref "options" %}})) größer werden?


  - `auto`: Wenn das Bild die Papierkante berührt, vergrößere das Bild in diese Richtung.
  - `no`: Das Bild nicht vergrößern.

`class` (Text, optional, _seit Version 2.5.11_)
: CSS Klasse für dieses Element.



`clip` (optional)
: Wenn 'yes', dann behält das Bild sein Seitenverhältnis wenn Breite und Höhe gegeben ist. Um das Bild einzupassen, wird ein Teil abgeschnitten.


  - `yes`: Seitenverhältnis beibehalten und linken und rechten oder oberen und unteren Rand abschneiden.
  - `no`: Bild verzerren, damit es in den vorgegebenen Rahmen passt.

`description` (Text, optional, _seit Version 4.19.8_)
: Ein alternativer Text für Barrierefreiheit



`dpiwarn` (Zahl, optional)
: Warnung ausgeben, wenn das Bild eine geringere Auflösung bekommt als angegeben.



`fallback` (optional, _seit Version 2.3.77_)
: Der Dateiname für ein Ersatzbild, falls die Bilddatei nicht gefunden wurde. Wenn keiner angegeben wird, wird ein roter Platzhalter angezeigt.



`file` (Text, optional)
: Dateiname des Bildes. Kann entweder eine Datei im Suchpfad sein, ein absoluter Dateiname, ein file-URI-Schema (z.B. `file:///pfad/zum/bild.pdf`) oder eine Quelle im Web (http/https).



`height` (Zahl oder Längenangabe, optional)
: Bildhöhe. Angabe in der Form 'auto' (Voreinstellung, natürliche Bildbreite), Längenangabe wie '4cm' oder Zahl (Anzahl von Rasterspalten)



`id` (Text, optional, _seit Version 2.5.11_)
: CSS id für dieses Element.



`imageshape` (yes oder no, optional, _seit Version 4.9.8_)
: Versuche Bildumrisse zu laden. Voreinstellung ist nein.



`imagetype` (optional, _seit Version 3.9.1_)
: Setze den Konverter, der für das eingebettete Bild notwendig ist (sofern vorhanden).



`margin-bottom` (Längenangabe, optional, _seit Version 4.13.13_)
: Extra Leerraum unterhalb des Bildes.



`margin-left` (Längenangabe, optional, _seit Version 4.13.13_)
: Extra Leerraum links des Bildes.



`margin-right` (Längenangabe, optional, _seit Version 4.13.13_)
: Extra Leerraum rechts des Bildes.



`margin-top` (Längenangabe, optional, _seit Version 4.13.13_)
: Extra Leerraum oberhalb des Bildes.



`maxheight` (Zahl oder Längenangabe, optional)
: Die maximale Breite des Bilds. Nur, wenn clip="no". Angabe in absoluten Längen oder Anzahl Rasterzellen.



`maxwidth` (Zahl oder Längenangabe, optional)
: Die maximale Breite des Bilds. Nur, wenn clip="no". Angabe in absoluten Längen, Rasterzellen oder »100%« für volle Breite.



`minheight` (Zahl oder Längenangabe, optional)
: Die minimale Breite des Bilds. Nur, wenn clip="no". Angabe in absoluten Längen oder Anzahl Rasterzellen.



`minwidth` (Zahl oder Längenangabe, optional)
: Die minimale Breite des Bilds. Nur, wenn clip="no". Angabe in absoluten Längen, Rasterzellen oder »100%« für volle Breite.



`opacity` (Zahl, optional, _seit Version 4.3.15_)
: Setze den Deckungsgrad des Bildes (0-100, 100 = voll deckend).



`padding` (Längenangabe, optional, _seit Version 2.9.5_)
: Setze Padding für alle Seiten.



`padding-bottom` (Längenangabe, optional, CSS Eigenschaft: padding-bottom, _seit Version 2.5.11_)
: Bestimmt den Innenabstand des Bildes (unten)



`padding-left` (Längenangabe, optional, CSS Eigenschaft: padding-left, _seit Version 2.5.11_)
: Bestimmt den Innenabstand des Bildes (links)



`padding-right` (Längenangabe, optional, CSS Eigenschaft: padding-right, _seit Version 2.5.11_)
: Bestimmt den Innenabstand des Bildes (rechts)



`padding-top` (Längenangabe, optional, CSS Eigenschaft: padding-top, _seit Version 2.5.11_)
: Bestimmt den Innenabstand des Bildes (oben)



`page` (Zahl, optional)
: Die Seitenzahl aus dem PDF. Voreinstellung ist 1.



`parent` (Text, optional, _seit Version 4.19.8_)
: Die ID der Elternstruktur für tagged PDF



`role` (optional, _seit Version 4.19.23_)
: Die Rolle für PDF/UA (barrierefreiheit, tagged PDF)



`rotate` (Zahl, optional)
: Dreht das Bild in 90°-Schritten. Ein Winkel > 0 dreht das Objekt im Uhrzeigersinn, ein Winkel < 0 gegen den Uhrzeigersinn.



`stretch` (yes oder no, optional, _seit Version 4.3.8_)
: Dehnt das Bild bis eine der Angaben von maxheight und maxwidth erreich ist. Hilfreich um Bilder so groß wie möglich aber innerhalb gewisser Grenzen anzeigen zu lassen.



`vertical-align` (optional, _seit Version 5.5.8_)
: Vertikale Ausrichtung des Bildes bei Verwendung als Inline-Element in einem Absatz. Wirkt nur, wenn mehrere Bilder (oder Bilder und Text) im selben Absatz stehen. Standard ist baseline.


  - `baseline`: Die Unterkante des Bildes auf der Grundlinie ausrichten (Standard). Jedes Bild ragt nach oben.
  - `top`: Oberkanten aller Bilder auf einer Linie ausrichten. Die Grundlinie liegt an der Unterkante des höchsten Bildes. Text steht auf der Grundlinie.
  - `middle`: Die vertikalen Mitten aller Bilder auf einer Linie ausrichten. Die Grundlinie liegt auf halber Höhe des höchsten Bildes.
  - `hanging`: Die Oberkante des Bildes liegt auf der Grundlinie. Das Bild hängt unter dem Text. Jedes Bild ragt unabhängig nach unten.

`visiblebox` (optional)
: Die PDF-Box, die den sichtbaren Bereich angibt des eingebundenen PDFs angibt. Voreinstellung ist »cropbox«.


  - `artbox`: Nutze die artbox als sichtbaren Bereich. Diese Box ist normalerweise in PDF-Dateien nicht enthalten.
  - `bleedbox`: Nutze die bleedbox des eingebundenen PDFs.
  - `cropbox`: Nutze die cropbox der eingebundenen PDF-Datei (Voreinstellung).
  - `mediabox`: Nutze die mediabox der eingebundenen PDF-Datei. Das ist die größte Box.
  - `trimbox`: Nutze die trimbox der eingebundenen PDF-Datei. Die trimbox ist die Papiergröße. Beispielsweise hat die trimbox eines A4-PDFs die Größe 210mm x 297mm.

`width` (Zahl oder Längenangabe, optional)
: Bildbreite. Angabe in der Form 'auto' (Voreinstellung, natürliche Bildbreite), '100%' (Breite des aktuellen Platzierungsbereichs), Längenangabe wie '4cm' oder Zahl (Anzahl von Rasterspalten)





## Bemerkungen

Die Werte der Attribute naturalsize und maxsize können artbox, bleedbox, cropbox, mediabox und trimbox sein. Diese beiden Angaben werden dafür benutzt, um das eingebundene Bild
        für den Anschnitt zu vergrößern. Im zweiten Beispiel unten ist der gewünschte Bildausschnitt in der »artbox« definiert, die Grafik in der PDF-Datei hat aber noch eine Beschnittzugabe, deren
        Ausmaß hier in der »cropbox« beschrieben ist. Die im zweiten Beispiel angegebene Breite entspricht der Papierbreite, so dass das der Inhalt der »artbox« 21cm breit dargestellt wird, der
        Anschnitt um das Bild herum aber weiterhin existiert.




## Beispiel


```xml
<Record element="produktbild">
  <PlaceObject column="{ $spalte }">
    <Image width="10" file="{string(.)}" />
  </PlaceObject>
</Record>
```

Nimmt den Dateinamen des Bildes aus dem Elementinhalt »produktbild« aus der Datensatzdatei, z.B.



```xml
<produktbild>grafik.pdf</produktbild>
```

Folgendes Beispiel nimmt eine Seite aus einer PDF Datei:



```xml
<PlaceObject column="0mm" row="0mm">
  <Image width="210mm" file="katalog.pdf" page="132" naturalsize="artbox" />
</PlaceObject>
```



## Hinweis


Die Anzahl der Seiten in einer PDF-Datei kann mit der XPath-Funktion `sd:number-of-pages(<dateiname oder URI>)` ermittelt werden.



Vorsicht: die Anzahl der PDF-Dateien, die in einem Dokument eingebunden werden kann, ist begrenzt. Diese Grenze kann je nach System erhöht werden. Auf Mac OS X kann die Grenze mit `ulimit -a` angezeigt werden (open files) und mit beispielsweise `ulimit -n 1024` erhöht werden.




