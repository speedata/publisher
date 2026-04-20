---
linktitle: "PDFOptions"
weight: 670
type: docs
---

# `PDFOptions`
_seit Version 2.3.39_

Setze PDF Optionen wie Anzahl der Kopien



## Kindelemente

(keine)

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>

## Attribute


`author` (Text, optional, _seit Version 3.1.18_)
: Legt den Autor des Dokuments fest



`colorprofile` (optional, _seit Version 3.5.7_)
: Setzt das Farbprofile. Muss mit [`DefineColorprofile`]({{% relref "definecolorprofile" %}}) registriert worden sein.



`creator` (Text, optional, _seit Version 4.9.2_)
: Legt die Anwendung des Dokuments fest



`displaymode` (optional, _seit Version 4.11.8_)
: Wähle den PDF-Anzeigemodes (vornehmlich beim Adobe Acrobat).


  - `attachments`: Zeige die Anhänge.
  - `bookmarks`: Zeige die Lesezeichen (sofern das Dokument Lesezeichen enthält).
  - `fullscreen`: Öffne das Dokument im Vollbildmodus.
  - `none`: Keine besondere Anzeigeart wählen.
  - `thumbnails`: Die Vorschaubilder zeigen.

`dpi` (Zahl, optional, _seit Version 4.17.10_)
: Setze die maximale DPI Zahl für PNG/JPEG-Bilder



`duplex` (optional, _seit Version 2.3.47_)
: Setze PDF Anzeigeprogramm auf einseitigen oder doppelseitigen Druck. Voreinstellung: leer.


  - `simplex`: Eine Seite je Blatt
  - `duplexflipshortedge`: Beidseitig und an kurzer Kante umblättern
  - `duplexfliplongedge`: Beidseitig und an langer Kante umblättern

`format` (optional, _seit Version 3.5.7_)
: Setzt das Ausgabeformat.


  - `PDF/X-3`: Setzt die Ausgabe auf `PDF/X-3`.
  - `PDF/X-4`: Setzt die Ausgabe auf `PDF/X-4`.
  - `PDF/A-3`: Setzt die Ausgabe auf `PDF/A-3`.
  - `PDF/UA`: Setzt die Ausgabe auf `PDF/UA`.

`hyperlinkbordercolor` (Text, optional, _seit Version 4.11.8_)
: Setze die Rahmenfarbe von Hyperlinks wenn showhyperlinks aktiviert ist. Die Voreinstellung ist black. (Umbenannt von hyperlinksbordercolor)



`hyperlinkborderwidth` (Text, optional, _seit Version 4.15.6_)
: Setze die Rahmendicke von Hyperlinks wenn showhyperlinks aktiviert ist. Die Voreinstellung ist 1pt.



`keywords` (Text, optional, _seit Version 3.1.24_)
: Legt die Schlüsselwörter des Dokuments fest (kommaseparierte Liste)



`numcopies` (Zahl, optional)
: Setze Anzahl der Kopien. Maximal erlaubt sind 5 aufgrund der PDF-Spezifikation.



`pagelayout` (optional, _seit Version 4.15.1_)
: Bestimme das Seitenlayout im Adobe Acrobat.


  - `singlepage`: Seitenanzeige »Einzelansicht«.
  - `onecolumn`: Seitenanzeige »Bildlauf«.
  - `twocolumnleft`: Seitenanzeige »Bildlauf in Zweiseitenansicht«.
  - `twocolumnright`: Seitenanzeige »Bildlauf in Zweiseitenansicht« mit Deckblatt.
  - `twopageleft`: Seitenanzeige »Zweiseitenansicht«.
  - `twopageright`: Seitenanzeige »Zweiseitenansicht« mit Deckblatt.

`picktraybypdfsize` (optional, _seit Version 2.3.46_)
: Auswahlfeld im PDF-Viewer »Papierquelle gemäß PDF-Seitengröße auswählen«.


  - `yes`: Checkbox aktivieren
  - `no`: Checkbox deaktivieren

`printscaling` (optional, _seit Version 2.3.46_)
: Soll der Drucker die Seiten skalieren?


  - `appdefault`: Voreinstellung des PDF-Viewers benutzen
  - `none`: Keine Seitenskalierung

`producer` (Text, optional, _seit Version 4.19.3_)
: Legt die Erzeugeranwendung des Dokuments fest



`showbookmarks` (yes oder no, optional, _seit Version 3.9.8_, veraltet)
: Zeige Lesezeichen im Adobe Acrobat beim Öffnen des Dokuments. Veraltet - benutze stattedessen displaymode.



`showhyperlinks` (yes oder no, optional, _seit Version 4.3.15_)
: Zeige Hyperlinks im Adobe Acrobat und ggf anderen PDF-Anzeigeprogrammen.



`subject` (Text, optional, _seit Version 3.1.24_)
: Legt den Betreff (subject) des Dokuments fest



`title` (Text, optional, _seit Version 3.1.18_)
: Legt den Titel des Dokuments fest






## Beispiel


```xml
<PDFOptions numcopies="4"/>
```



