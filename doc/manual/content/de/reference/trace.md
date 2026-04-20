---
linktitle: "Trace"
weight: 1010
type: docs
---

# `Trace`
_seit Version 2.7.4_

Setze Debugging-Schalter



## Kindelemente

(keine)

## Elternelemente

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`assignments` (optional)
: Schreibt Zusweisungen ([`SetVariable`]({{% relref "setvariable" %}})) in die Logdatei.


  - `yes`: Zusätzliche Ausgaben in der Logdatei.
  - `no`: Normaler Lauf (Voreinstellung).

`dump-structtree` (optional, _seit Version 4.19.8_)
: Schreibt den PDF/UA-Strukturbaum als XML-Datei.


  - `yes`: Strukturbaum in Datei schreiben.
  - `no`: Strukturbaum nicht schreiben (Voreinstellung).

`grid` (optional)
: Wenn 'yes', dann zeichnet der Publisher das zugrunde liegende Raster auf die Seiten.


  - `yes`: Zeige das Raster.
  - `no`: Das Raster wird nicht angezeigt (Voreinstellung).

`gridallocation` (optional)
: Wenn 'yes', dann markiert der Publisher die belegten Rasterzellen mit einer Hintergrundfarbe.


  - `yes`: Zeige Rasterbelegung.
  - `no`: Rasterbelegung nicht zeigen (Voreinstellung).

`gridlocation` (optional, _seit Version 4.15.0_)
: Ort des Rasters.


  - `foreground`: Zeichne das Raster über allen Objekten.
  - `background`: Zeichne das Raster unter allen Objekten (default).

`groups` (optional, _seit Version 4.21.8_)
: Wenn 'yes', dann zeichnet der Publisher das zugrunde liegende Raster in den Gruppen.


  - `yes`: Zeige das Raster.
  - `no`: Das Raster wird nicht angezeigt (Voreinstellung).

`hyphenation` (optional)
: Bei 'yes' markiert der speedata Publisher die möglichen Trennstellen für die Silbentrennung.


  - `yes`: Zeige Silbentrennungsmöglichkeiten.
  - `no`: Keine Silbentrennungsmöglichkeiten zeigen (Voreinstellung).

`kerning` (optional)
: Bei 'yes' markiert der speedata Publisher die Unterschneidungen.


  - `yes`: Zeige Unterschneidungen.
  - `no`: Keine Unterschneidungen zeigen (Voreinstellung).

`objects` (optional)
: Zeichnet Rechtecke um Objekte.


  - `yes`: Zeichnet Rechtecke
  - `no`: Keine Rechtecke um Objekte (Voreinstellung).

`textformat` (optional)
: Zeige Textformat als Tooltip im PDF


  - `yes`: Zeige Textformat
  - `no`: Zeige Textformat nicht (Voreinstellung).

`verbose` (optional)
: Erzeugt zusätzliche Ausgaben in der Protokolldatei.


  - `yes`: Zusätzliche Ausgaben in der Logdatei.
  - `no`: Normaler Lauf (Voreinstellung).




## Beispiel


```xml
<Trace textformat="yes"/>
```



