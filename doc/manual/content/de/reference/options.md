---
linktitle: "Options"
weight: 630
type: docs
---

# `Options`


Setzt Publisher-spezifische Optionen.



## Kindelemente

(keine)

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`background-color` (Text, optional, _seit Version 4.19.11_)
: Füge einen farbigen Hintergrund hinter jede Seite ein. Voreinstellung ist 'white'. Farbname oder '-' für keinen Hintergrund.



`bleed` (Längenangabe, optional)
: Die Größe des Anschnitts (bleed). Voreinstellung ist 0mm.



`bleedmarks` (optional, _seit Version 2.3.24_)
: Beschnittzugabemarken werden ausgegeben. Diese Marken zeigen, wie groß die Beschnittzugabe ist. Der Abstand der Beschnittzugabemarken vom gedachten Mittelpunkt ergibt sich durch die Beschnittzugabe, mindestens beträgt sie jedoch 5pt. Die Länge der Schnittmarke ist 1cm. Voreinstellung ist nein, d.h. es werden keine Beschnittzugabemarken ausgegeben.


  - `yes`: Beschnittzugabemarken anzeigen.
  - `no`: Beschnittzugabemarken nicht anzeigen (Voreinstellung).

`crop` (yes, no oder Längenangabe, optional, _seit Version 2.3.21_)
: Beschneidet eine Seite, so dass die Objekte auf einer Seite die Größe bestimmen. Erlaubte Werte sind 'yes', 'no' und eine Längenangabe.



`cutmarks` (optional)
: Beschnittmarken (crop marks) werden ausgegeben. Der Abstand der Schnittmarken vom gedachten Mittelpunkt ergibt sich durch die Beschnittzugabe, mindestens beträgt sie jedoch 5pt. Die Länge der Schnittmarke ist 1cm. Voreinstellung ist nein, d.h. es werden keine Schnittmarken ausgegeben.


  - `yes`: Beschnittmarken anzeigen.
  - `no`: Beschnittmarken nicht anzeigen (Voreinstellung).

`defaultarea` (Text, optional, _seit Version 2.7.4_)
: Name des Bereichs, der bei [`Output`]({{% relref "output" %}}) und [`PlaceObject`]({{% relref "placeobject" %}}) benutzt wird. Die Seite hat den Namen `_page`.



`fontexpansion` (optional, _seit Version 4.19.17_)
: Erlaube dehnen und stauchen von Zeichen. Voreinstellung ist 'yes'.


  - `no`: Dehnen und stauchen nicht erlauben.
  - `some`: Dehnen und stauchen wird nach dem Textumbruch angewendet.
  - `yes`: Dehnen und stauchen wird vor dem Zeilenumbruch angewendet. Dadurch hat der Umbruchalgorithmus mehr Möglichkeiten und erzeugt damit einen besseren Textsatz.

`fontshrink` (Zahl, optional, _seit Version 4.19.17_)
: Setze den voreingestellten maximalen Stauchfaktor der Schriftart. Voreinstellung ist ausgeschaltet. Wert geteilt durch 10 = Prozent. Beispiel: 20 bedeutet eine maximale Stauchung von 2%.



`fontstep` (Zahl, optional, _seit Version 4.19.17_)
: Setze die voreingestellten Schritte für stauchen und dehnen. Wert geteilt durch 10 = Prozent. Beispiel: 20 erhöht/verringert die Schriftgröße bei Bedarf um 2%. Voreinstellung: 10



`fontstretch` (Zahl, optional, _seit Version 4.19.17_)
: Setze den voreingestellten maximalen Dehnungsfaktor der Schriftart. Voreinstellung ist ausgeschaltet. Wert geteilt durch 10 = Prozent. Beispiel: 20 bedeutet eine maximale Dehnung von 2%.



`html` (optional, _seit Version 5.3.12_)
: Voreinstellung für HTML-Parsing in Absätzen. Kann lokal in [`Paragraph`]({{% relref "paragraph" %}}) überschrieben werden. Das Setzen auf 'off' kann die Performance deutlich verbessern, wenn keine HTML-Tags wie <b> oder <i> verwendet werden.


  - `all`: HTML in allen Absätzen parsen (Voreinstellung).
  - `inner`: HTML nur in Kindelementen des aktuellen Datenelements parsen.
  - `off`: HTML-Parsing in Absätzen deaktivieren.

`ignoreeol` (optional)
: Zeilenenden in Daten ignorieren.


  - `yes`: Zeilenenden in Daten ignorieren.
  - `no`: Zeilenenden in Daten beachten.

`imagenotfound` (optional, _seit Version 2.3.43_)
: Falls ein Bild nicht gefunden wird: soll eine Warnung oder ein Fehler ausgegeben werden?


  - `warning`: Eine Warnung ausgeben
  - `error`: Fehler ausgeben (Voreinstellung).

`interaction` (yes oder no, optional, _seit Version 3.9.2_)
: Wenn »no«, werden alle Hyperlinks deaktiviert.



`mainlanguage` (optional)
: Die Sprache (Silbentrennung und Darstellung), die im Text benutzt wird, wenn keine andere Sprache angegeben ist. Sie kann global über die Kommandozeile gesteuert werden oder für jeden [`Paragraph`]({{% relref "paragraph" %}}) und [`Textblock`]({{% relref "textblock" %}}) einzeln.



`markdown-extensions` (Text, optional, _seit Version 4.17.11_)
: Setze die markdown-Erweiterungen. Eine Kommaseparierte Liste der folgenden Werte: table, strikethrough, linkify, tasklist, gfm, definitionlist, footnote, typographer, cjk.



`mpcolorwarning` (yes oder no, optional, _seit Version 5.1.9_)
: Gibt eine Warnung aus, wenn der Farbname nicht mit MetaPost kompatibel ist.



`namespaces` (optional, _seit Version 4.19.37_)
: Kontrolliert die Handhabung von XML Namensräumen. Die Voreinstellung ist 'lax', das alle Namensräume bei den Befehlen [`Record`]({{% relref "record" %}}) und [`ProcessNode`]({{% relref "processnode" %}}) ignoriert.


  - `lax`: Voreinstellung. XML Namensräume aus der Datendatei werden ignoriert.
  - `strict`: [`Record`]({{% relref "record" %}}) und [`ProcessNode`]({{% relref "processnode" %}}) beachten Namensräume.

`overfull-line` (optional, _seit Version 4.19.10_)
: Gib eine Warnung oder einen Fehler aus, wenn eine Textzeile zu lang ist.


  - `warning`: Eine Warnung ausgeben
  - `error`: Fehler ausgeben
  - `ignore`: Ignoriere diesen Fall.

`randomseed` (Zahl, optional, _seit Version 3.9.24_)
: Setze die Startzahl (seed) für den Zufallszahlengenerator (eine positive Ganzzahl).



`reportmissingglyphs` (optional, _seit Version 3.1.17_)
: Gibt einen Fehler aus, wenn ein Zeichen in einer Schriftart fehlt.


  - `yes`: Zeige Fehlermeldung (Voreinstellung)
  - `no`: Zeige keine Fehlermeldung
  - `warning`: Zeige eine Warnung

`resetmarks` (optional)
: Wenn 'yes', werden die Marker des letzten Laufs ignoriert.


  - `yes`: Marker aus dem vorherigen Lauf ignorieren.
  - `no`: Marker aus dem vorherigen Lauf weiter benutzen (Voreinstellung).

`startpage` (Zahl, optional)
: Gibt den Nummer der ersten Seite an.



`tablerulefix` (yes oder no, optional, _seit Version 4.21.3_)
: Zeichne die Tablellenlinien neu über der Tabelle. Das behebt einen Darstellungsfehler im Adobe Acrobat, wenn farbige Hintergründe benutzt werden.





## Bemerkungen

Bleed war in Version 2.7.6 und vorher »trim«




## Beispiel


```xml
<Options
   cutmarks="yes"
   bleed="3mm"
  />
      
```



## Hinweis


Die Liste der bekannten Sprachen und der Sprachcode im speedata Publisher sind:



`Ancient Greek` (`grc`), `Armenian` (`hy`), `Bahasa Indonesia` (`id`), `Basque` (`eu`), `Bulgarian` (`bg`), `Catalan` (`ca`), `Chinese` (`zh`), `Croatian` (`hr`), `Czech` (`cs`), `Danish` (`da`), `Dutch` (`nl`), `English` (`en_GB`), `English (Great Britain)` (`en_GB`), `English (USA)` (`en_US`), `Esperanto` (`eo`), `Estonian` (`et`), `Finnish` (`fi`), `French` (`fr`), `Galician` (`gl`), `German` (`de`), `Greek` (`el`), `Gujarati` (`gu`), `Hindi` (`hi`), `Hungarian` (`hu`), `Icelandic` (`is`), `Irish` (`ga`), `Italian` (`it`), `Kannada` (`kn`), `Kurmanji` (`ku`), `Latvian` (`lv`), `Lithuanian` (`lt`), `Malayalam` (`ml`), `Norwegian Bokmål` (`nb`), `Norwegian Nynorsk` (`nn`), `Other` (`--`), `Polish` (`pl`), `Portuguese` (`pt`), `Romanian` (`ro`), `Russian` (`ru`), `Sanskrit` (`sa`), `Serbian` (`sr`), `Serbian (cyrillic)` (`sc`), `Slovak` (`sk`), `Slovenian` (`sl`), `Spanish` (`es`), `Swedish` (`sv`), `Turkish` (`tr`), `Ukrainian` (`uk`), `Welsh` (`cy`)




