---
linktitle: "PlaceObject"
weight: 720
type: docs
---

# `PlaceObject`


Gibt ein rechteckiges Objekt (Bild, Tabelle, Box, Barcode oder Textblock) aus.



## Kindelemente

<a href="../a"><code>A</code></a>, <a href="../barcode"><code>Barcode</code></a>, <a href="../bookmark"><code>Bookmark</code></a>, <a href="../box"><code>Box</code></a>, <a href="../circle"><code>Circle</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../image"><code>Image</code></a>, <a href="../mark"><code>Mark</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../rule"><code>Rule</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../table"><code>Table</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../transformation"><code>Transformation</code></a>

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`allocate` (optional)
: Bestimmt, ob im Raster der Platz für das Objekt als »belegt« markiert wird. Bei `allocate="no"` wird auch die aktuelle Zeile im Raster nicht verändert.


  - `yes`: Platz im Raster reservieren (Voreinstellung für Platzierung im Raster).
  - `no`: Bereich nicht als Belegt markieren (Voreinstellung für absolute Positionierung)

`allocate-bottom` (Zahl oder Längenangabe, optional, _seit Version 2.9.6_)
: Zusätzliche Belegung unten.



`allocate-left` (Zahl oder Längenangabe, optional, _seit Version 2.9.6_)
: Zusätzliche Belegung links.



`allocate-right` (Zahl oder Längenangabe, optional, _seit Version 2.9.6_)
: Zusätzliche Belegung rechts.



`allocate-top` (Zahl oder Längenangabe, optional, _seit Version 2.9.6_)
: Zusätzliche Belegung oben.



`area` (Text, optional)
: Name des Bereichs (Platzierungsbereich), in dem das Objekt ausgegeben werden soll. Wird kein Bereich angegeben, so wird das Objekt auf der »Seite« (dem Bereich, der alle Rasterkästen beinhaltet) ausgegeben.



`background` (optional)
: Erzeugt einen farbigen Hintergrund für das Objekt. Das Attribut ›background-color‹ gibt die Farbe an.


  - `full`: Den Hintergrund in der angegebenen Farbe füllen (in background-color)
  - `without`: Leerer Hintergrund

`background-color` (Text, optional)
: Hintergrundfarbe wenn das Objekt mit einer Farbe hinterlegt werden soll.



`border-bottom-left-radius` (Längenangabe, optional)
: Radius der Ecke unten links.



`border-bottom-right-radius` (Längenangabe, optional)
: Radius der Ecke unten rechts.



`border-top-left-radius` (Längenangabe, optional)
: Radius der Ecke oben links.



`border-top-right-radius` (Längenangabe, optional)
: Radius der Ecke oben rechts.



`clipatmargin` (yes oder no, optional, _seit Version 4.21.9_)
: Schneide Objekte am Seitenrand ab.



`column` (Zahl oder Längenangabe, optional)
: Zahl: Die Spalte im Raster, in der das Objekt ausgegeben wird. Wird die Spalte nicht angegeben, so sucht sich das System selbständig eine passende freie Zeile für das Objekt. Maßangabe: die Position von der linken Blattkante.



`frame` (optional)
: Es wird ein Rahmen um das Objekt gezeichnet. Zusätzlich muss die Rahmenfarbe angegeben werden.


  - `solid`: Einen Rahmen um das Objekt zeichnen.
  - `without`: Keinen Rahmen zeichnen.

`framecolor` (Text, optional)
: Die Farbe des Rahmens, wenn ein Rahmen ausgegeben wird. Nur sinnvoll zusammen mit dem Attribut rahmen.



`groupname` (Text, optional)
: Wenn eine Gruppe ausgegeben werden soll, muss der Name hier angegeben werden.



`halign` (optional, _seit Version 2.3.55_)
: Wird ein Objekt ausgegeben, das kein vielfaches der Rasterbreite ist, dann gibt das Attribut die horizontale Ausrichtung an. ›left‹ beispielsweise bedeutet, dass der freie Platz rechts des Objekts bleibt. Voreinstellung ist ›left‹.


  - `left`: Das Objekt wird links ausgerichtet.
  - `center`: Das Objekt wird so platziert, dass der Leerraum links und rechts derselbe ist.
  - `right`: Das Objekt wird rechts ausgerichtet.

`hreference` (optional)
: Bestimmt, ob die angegebene Spalte die linke oder die rechte Kante vom Objekt bezeichnet.


  - `left`: Das Objekt wird in der angegebenen Spalte platziert.
  - `center`: Die Spalte bestimmt den Mittelpunkt des Objekts. Funktioniert nur mit absoluter Positionierung.
  - `right`: Das Objekt wird mit dem rechten Rand in der gegebenen Spalte ausgerichtet.

`keepposition` (optional)
: Den virtuellen Cursor nicht verändern.


  - `yes`: Den virtuellen Cursor nicht verändern.
  - `no`: Den virtuellen Cursor verschieben (Voreinstellung)

`maxheight` (Zahl, optional)
: Die maximale Höhe in Rasterzellen, die das Objekt belegen darf. Wird nur für den automatischen Tabellenumbruch benötigt. Die umbrochenen Tabellen auf den Folgeseiten haben maximal die angegebene Höhe.



`origin-x` (optional)
: Der Ursprung für die Drehung


  - `left`: Der Ursprung liegt links.
  - `center`: Der Ursprung liegt im Mittelpunkt des Objekts.
  - `right`: Der Ursprung liegt rechts.

`origin-y` (optional)
: Der Ursprung der Drehung (vertikale Achse)


  - `top`: Rotation um die obere Kante des Objekts.
  - `center`: Rotation um die vertikale Mitte.
  - `bottom`: Um einen Punkt am unteren Rand rotieren.

`page` (Zahl, optional)
: Die Seite (später im PDF), auf der das Objekt erscheinen soll. Angabe als Zahl oder »next« für die nächste Seite.



`rotate` (Zahl, optional)
: Dreht das Objekt. Ein Winkel > 0 dreht das Objekt im Uhrzeigersinn, ein Winkel < 0 gegen den Uhrzeigersinn. Wenn der Winkel ungleich 0 ist, wird die Rasterbelegung abgeschaltet.



`row` (Zahl oder Längenangabe, optional)
: Zahl: Die Zeile im Raster, in der das Objekt ausgegeben wird. Wird die Zeile nicht angegeben, so sucht sich das System selbständig eine passende freie Zeile für das Objekt. Maßangabe: die Position von der oberen Blattkante.



`rulewidth` (Längenangabe, optional)
: Die Dicke des Rahmens, der um das Objekt gezogen wird. Nur sinnvoll zusammen mit dem Attribut rahmen.



`valign` (optional)
: Wird ein Objekt ausgegeben, das kein vielfaches der Rasterhöhe ist, dann gibt das Attribut die vertikale Ausrichtung an. Bottom beispielsweise bedeutet, dass der freie Platz oberhalb des Objekts bleibt. Voreinstellung ist “top”.


  - `top`: Das Objekt wird oben ausgerichtet.
  - `middle`: Das Objekt wird so platziert, dass der Leerraum oberhalb und unterhalb derselbe ist.
  - `bottom`: Das Objekt wird unten ausgerichtet.

`vreference` (optional)
: Bestimmt die Platzierung des Objekts relativ zur angegebenen Zeile.


  - `bottom`: Die Zeile gibt die untere Kante des Objekts an.
  - `middle`: Die Zeile gibt die Mitte des Objekts an. Funktioniert nur bei absoluter Positionierung.
  - `top`: Die Zeile gibt die obere Kante des Objekts an (Voreinstellung).




## Beispiel


```xml
<Record element="bild">
  <PlaceObject column="12" frame="solid" framecolor="red">
    <Image width="10" file="_samplea.pdf" />
  </PlaceObject>
</Record>
```

Absolute Platzierung:



```xml
<Record element="bild">
  <PlaceObject column="1cm" row="4cm" frame="solid" framecolor="red">
    <Image width="10" file="_samplea.pdf" />
  </PlaceObject>
</Record>
```



## Hinweis


Die Ausgabe kann entweder im Raster erfolgen (Angabe bei `row` und `column` ist eine Zahl) oder als absolute Positionierung (die Angaben bei `row` und `column` müssen beide vorhanden sein und
        eine Maßgangabe sein).




