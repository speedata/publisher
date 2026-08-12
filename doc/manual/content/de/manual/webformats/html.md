---
title: "HTML"
weight: 75
type: docs
---


Der speedata Publisher kann HTML-Inhalte verarbeiten und als PDF ausgeben. Dieses Kapitel beschreibt die verschiedenen Möglichkeiten, HTML zu verwenden, und die unterstützten Funktionen. Diese sind noch in Entwicklung. Die HTML Unterstützung wird kontinuierlich verbessert.

## HTML verwenden

Es gibt mehrere Möglichkeiten, HTML-Inhalte in das Layout einzubinden:

### Direktes HTML in Output

Am einfachsten ist die Verwendung des `<HTML>`-Befehls direkt innerhalb von `<Output>`:

```xml
<Output>
  <HTML>
    <h1>Überschrift</h1>
    <p>Ein Absatz mit <b>fettem</b> und <i>kursivem</i> Text.</p>
    <ul>
      <li>Punkt 1</li>
      <li>Punkt 2</li>
    </ul>
  </HTML>
</Output>
```

### HTML aus Daten mit select

HTML-Inhalte können aus der Datendatei mit dem `select`-Attribut geladen werden:

```xml
<Output>
  <HTML select="content" />
</Output>
```

Wenn das HTML als maskierter Text (z.B. `&lt;p&gt;`) oder in einem CDATA-Abschnitt gespeichert ist, wird der `<HTML>`-Befehl es korrekt parsen.

### HTML in Paragraph

HTML kann auch innerhalb von `<Paragraph>`-Elementen in einem `<Textblock>` oder `<Text>` verwendet werden. Das ist nützlich, wenn HTML mit anderen Publisher-Elementen gemischt werden soll:

```xml
<Record element="Paragraph">
  <PlaceObject>
    <Textblock>
      <Paragraph>
        <Value select="sd:decode-html(.)" />
      </Paragraph>
    </Textblock>
  </PlaceObject>
</Record>
```

Mit Daten, die HTML in CDATA enthalten:

```xml
<Paragraph><![CDATA[<ol><li>Erster Punkt</li><li>Zweiter Punkt</li></ol>]]></Paragraph>
```

### XPath-Ersetzung mit expand-text

Bei Inline-HTML können XPath-Ausdrücke in geschweiften Klammern verwendet werden, wenn `expand-text="yes"` gesetzt ist:

```xml
<Output>
  <HTML expand-text="yes">
    <p>Artikel <b>{@nr}</b> kostet {$preis} Euro.</p>
  </HTML>
</Output>
```

Für literale geschweifte Klammern `{{` und `}}` verwenden.

## Unterstützte HTML-Elemente

Die folgenden HTML-Elemente werden unterstützt:

* Überschriften: `<h1>` bis `<h6>`
* Absätze: `<p>`
* Textformatierung: `<b>`, `<i>`, `<u>`, `<code>`, `<kbd>`, `<span>`
* Links: `<a href="...">`
* Listen: `<ul>`, `<ol>`, `<li>`
* Tabellen: `<table>`, `<thead>`, `<tbody>`, `<tr>`, `<th>`, `<td>`
* Zeilenumbrüche: `<br>`

## CSS-Styling

HTML-Elemente können mit CSS gestaltet werden. CSS kann über den `<Stylesheet>`-Befehl eingebunden werden:

```xml
<Stylesheet>
  h1 { color: blue; font-size: 24pt; }
  p { margin-bottom: 12pt; }
  .highlight { background-color: yellow; }
</Stylesheet>
```

Oder CSS aus einer Datei laden:

```xml
<Stylesheet filename="styles.css" />
```

### Unterstützte CSS-Eigenschaften

Der speedata Publisher unterstützt eine Teilmenge von CSS-Eigenschaften, darunter Schrift-, Text- und Box-Modell-Eigenschaften, Hintergrundfarben sowie Listen- und Umbruchsteuerung.
Die vollständige Liste steht im Kapitel [CSS verwenden]({{< relref "css" >}}); den Umsetzungsstand einzelner Eigenschaften zeigt der [Teststatus](#teststatus).

## Listen in HTML

HTML-Listen (`<ul>`, `<ol>`, `<li>`) werden unterstützt. Der Einzug der Liste wird über `padding-left` auf `<ul>` oder `<ol>` gesteuert. Der Listenmarker (Aufzählungszeichen, Nummerierung) wird im Einzugsbereich platziert.

### Marker-Styling mit `::marker`

Mit dem CSS-Pseudo-Element `li::marker` kann der Listenmarker gestaltet werden. Folgende Eigenschaften werden unterstützt:

* `content` – Eigener Marker-Text (z.B. `content: "→"`)
* `color` – Farbe des Markers
* `font-family` – Schriftart des Markers
* `font-size` – Schriftgröße des Markers
* `padding-right` – Abstand zwischen Marker und Text (Standard: 5pt)
* `padding-bottom` – Vertikale Verschiebung des Markers nach oben

### Beispiel

```xml
<Stylesheet>
  ul { padding-left: 14pt; }
  li::marker { color: red; padding-right: 2pt; }
</Stylesheet>
```

Damit wird der Aufzählungspunkt rot dargestellt und der Abstand zwischen Marker und Text auf 2pt verringert.

## Tabellen in HTML

HTML-Tabellen werden vollständig unterstützt, einschließlich Kopf- und Fußzeilen, die bei Seitenumbrüchen wiederholt werden:

```xml
<HTML>
  <table>
    <thead>
      <tr><th>Name</th><th>Preis</th></tr>
    </thead>
    <tbody>
      <tr><td>Produkt A</td><td>10,00</td></tr>
      <tr><td>Produkt B</td><td>20,00</td></tr>
    </tbody>
  </table>
</HTML>
```

Tabellen können sich über mehrere Seiten erstrecken, wobei der `<thead>`-Inhalt oben auf jeder Seite wiederholt wird.

## Teststatus

Im Repository gibt es unter `qa/htmloutput` eine Reihe von HTML/CSS-Tests, die die verschiedenen Funktionen und deren Unterstützung im speedata Publisher überprüfen.

### Funktioniert

* [*break-after*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/break-after) – Seitenumbrüche nach HTML-Elementen
* [*break-before*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/break-before) – Seitenumbrüche vor HTML-Elementen
* [*color*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/color) – Textfarben mit unterschiedlichen Angabeformaten
* [*font-style-weight*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/font-style-weight) – Schriftstil (italic) und Schriftgewicht (bold) sowie Kombinationen
* [*list-style-type*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/list-style-type) – Verschiedene Listenmarker-Typen (disc, circle, square, decimal, alpha, roman) (benötigt evtl. Schriftart mit entsprechenden Glyphen)
* [*table-border*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/table-border) – Tabellenzellen mit Rahmen und verschiedenen Formatierungen
* [*table-border-collapse*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/table-border-collapse) – Unterschiede zwischen border-collapse: separate und collapse
* [*tablebreak*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/tablebreak) – Mehrseitige Tabellen mit wiederholendem Tabellenkopf
* [*text-align*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/text-align) – Textausrichtung (left, right, center, justify)
* [*vertical-align*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/vertical-align) – Hochgestellter und tiefgestellter Text (*prüfen: Schriftgröße*)
* [*white-space*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/white-space) – Leerzeichenbehandlung (normal, pre)

### Funktioniert teilweise

Tests, die erfolgreich sind, aber möglicherweise noch Verbesserungen benötigen:

* [*border-color*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/border-color) – Rahmenfarben mit Einzelfarbensetzung pro Seite und currentcolor
* [*border-radius*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/border-radius) – Abgerundete Ecken mit einheitlichem und individuellen Radius-Werten
* [*border-shorthand*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/border-shorthand) – Kurzschreibweise für Rahmen mit verschiedenen Stilen, Breiten und Farben
* [*border-width*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/border-width) – Rahmenbreiten in unterschiedlichen Einheiten und mit individuellen Werten pro Seite
* [*box-margin*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/box-margin) – Äußere Abstände mit Kurzschreibweisen und Einzelwerten pro Seite
* [*box-padding*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/box-padding) – Innere Abstände mit Kurzschreibweisen und Einzelwerten pro Seite
* [*font-size*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/font-size) – Verschiedene Schriftgrößenangaben (pt, px, em, rem, %, Schlüsselwörter). *oberer Rand auf 2. Seite ist zu klein*
* [*list-style-position*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/list-style-position) – Listenmarkerposition (outside, inside) *Die Marker sind höchstwahrscheinlich nicht richtig platziert.*
* [*text-decoration*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/text-decoration) – Textdekorationen (underline, line-through, verschiedene Stile und Farben) *Nur underline wird unterstützt.*

### Defekt

Tests, die derzeit nicht korrekt funktionieren:

* [*background-color*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/background-color) – Hintergrundfarben mit unterschiedlichen Angabeformaten (Named Color, Hex, RGB)
* [*border-style*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/border-style) – Verschiedene Rahmenstile (none, solid, dashed, dotted, double, groove, ridge, inset, outset)
* [*box-width-height*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/box-width-height) – Breite und Höhe mit Prozent-, Pixel- und Em-Angaben
* [*line-height*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/line-height) – Verschiedene Zeilenhöhen-Werte (normal, Zahlenwert, Prozent, Punkte)

