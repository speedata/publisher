---
title: "CSS verwenden"
weight: 74
type: docs
aliases:
  - /de/fortgeschrittenethemen/css/
---



CSS (Cascading Stylesheets) ist eine Sprache, die hauptsächlich im Web benutzt wird, um das Aussehen von Objekten zu bestimmen.
Die Idee ist, die Formatierung vom Inhalt zu trennen.
Im Web - so die reine Lehre - ist der Inhalt in HTML beschrieben, während das Aussehen mit CSS festgelegt wird.
Beim speedata Publisher ist die Trennung noch deutlicher.
Die Daten enthalten in der Regel keinerlei Informationen über das Aussehen, während das Layoutregelwerk keinerlei Informationen über die Daten hat.

CSS kommt im speedata Publisher an zwei getrennten Stellen zum Einsatz, die man auseinanderhalten muss:

1. **CSS für Layout-Befehle:** Absätze, Textblöcke, Tabellen und viele weitere Befehle im Layoutregelwerk beziehen Schrift, Farben, Abstände und Ausrichtung aus CSS-Regeln.
2. **CSS für HTML-Inhalte und Auszeichnungen in den Daten:** Inhalte, die über den Befehl [`<HTML>`]({{< relref "html" >}}) oder als Markup in Absatzinhalten verarbeitet werden, formatiert der Publisher mit dem vollen Umfang seiner HTML-Verarbeitung.

Beide Wege benutzen dieselben Stylesheets.

## Stylesheets einbinden

Ein CSS-Stylesheet kann als externe Datei vorliegen und eingebunden werden.
Alternativ kann man auch CSS-Anweisungen direkt in das Layoutregelwerk schreiben.
`<Stylesheet>` lautet der Befehl für beide Varianten:

```xml
<Stylesheet filename="style.css"/>
```

oder

```xml
<Stylesheet>
  td {
    vertical-align: top;
  }
</Stylesheet>
```

## CSS für Layout-Befehle {#css-layout}

Viele Befehle im Layoutregelwerk lassen sich mit CSS gestalten: Absätze, Textblöcke, Tabellen, Boxen, Linien, Listen und einige mehr.
Die Selektoren und die Kaskade funktionieren wie im Webbrowser.
Ein Attribut am Befehl hat Vorrang vor einer CSS-Regel; so lassen sich Vorgaben im Stylesheet bündeln und im Einzelfall überschreiben.

Ein vollständiges Beispiel: die Box erhält ihre Hintergrundfarbe über die Klasse `warn`, der Absatz seine Schriftgröße und Farbe über `paragraph.hinweis`.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Stylesheet>
    .warn {
      background-color: red;
    }
    paragraph.hinweis {
      font-size: 8pt;
      color: gray;
    }
  </Stylesheet>

  <Record element="data">
    <PlaceObject>
      <Box class="warn" width="5" height="2"/>
    </PlaceObject>
    <PlaceObject>
      <Textblock>
        <Paragraph class="hinweis"><Value>Kleiner grauer Text.</Value></Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```

### Elementnamen

In den Selektoren heißt ein Befehl wie sein Name in Kleinbuchstaben.
Nur `<Image>` heißt wie in HTML `img`.

| Befehl | Name im Selektor |
|---|---|
| `<Box>`, `<Circle>`, `<Frame>` | `box`, `circle`, `frame` |
| `<Image>` | `img` |
| `<Paragraph>`, `<Span>`, `<U>` | `paragraph`, `span`, `u` |
| `<PlaceObject>` | `placeobject` |
| `<Rule>` | `rule` |
| `<Table>`, `<Tablehead>`, `<Tablefoot>` | `table`, `tablehead`, `tablefoot` |
| `<Tr>`, `<Td>`, `<Tablerule>` | `tr`, `td`, `tablerule` |
| `<Textblock>` | `textblock` |
| `<Ul>`, `<Ol>`, `<Li>` | `ul`, `ol`, `li` |

Die Referenz nennt bei jedem dieser Befehle im Abschnitt „CSS“ den Namen.
Andere Befehle wie `<Record>`, `<ForAll>`, `<Loop>` oder `<Switch>` geben nichts aus und tauchen in Selektoren nicht auf.

### Selektoren

Es gelten die Selektoren aus CSS, unter anderem:

| Selektor | trifft |
|---|---|
| `td` | jede Tabellenzelle |
| `.preis` | jeden Befehl mit `class="preis"`, auch mit `class="preis aktion"` |
| `#kopf` | den Befehl mit `id="kopf"` |
| `td.preis` | Tabellenzellen mit der Klasse `preis` |
| `table.liste td` | Zellen, die in einer Tabelle mit der Klasse `liste` stehen |
| `tr > td` | Zellen, die direkt in einer Zeile stehen |
| `tr:nth-child(even)` | jede zweite Tabellenzeile (siehe [Tabellen](#css-tables)) |

Für Nachfahren-Selektoren wie `table.liste td` zählt die Verschachtelung beim Ausführen des Layouts.
Ein Absatz, der in einem `<Record>` steht und per `<ProcessNode>` aus einer Tabellenzelle aufgerufen wird, steht also in der Zelle (`td paragraph`).

Die Attribute `class` und `id` dürfen XPath-Ausdrücke in geschweiften Klammern enthalten, so kann die Klasse aus den Daten kommen:

```xml
<Tr class="{if (@angebot = 'ja') then 'aktion' else ''}">
```

### Ein Stylesheet für Layout und HTML

Alle Regeln aus allen `<Stylesheet>`-Befehlen gelten für Layout-Befehle *und* für HTML-Inhalte.
Einige Namen gibt es in beiden Welten, zum Beispiel `table`, `td`, `span`, `ul` oder `img`.
Eine Regel `td { padding: 4pt }` gilt deshalb für Tabellenzellen im Layout und in HTML-Inhalten.

Zur Trennung dienen die beiden Wurzelelemente: Layout-Befehle stehen unter dem Element `layout`, HTML-Inhalte unter `html`.

```css
layout td { padding: 2pt }   /* nur Zellen von <Td> im Layout */
html td   { padding: 4pt }   /* nur Zellen in HTML-Inhalten */
td        { color: black }   /* beide */
```

### Kaskade und Vorrang

Alle passenden Regeln gelten.
Setzen zwei Regeln dieselbe Eigenschaft, gewinnt die spezifischere (eine Id vor einer Klasse vor einem Elementnamen); bei gleicher Spezifität gewinnt die Regel, die im Stylesheet später steht.

Kommt ein Wert von mehreren Seiten, gilt diese Reihenfolge, das Stärkste zuerst:

1. Eine CSS-Angabe mit `!important`.
2. Das Attribut am Befehl.
3. Die CSS-Regeln für den Befehl selbst.
4. Werte, die der Befehl von umgebenden Befehlen erbt (siehe nächster Abschnitt).
5. Die Vorgaben des Publishers, etwa das Textformat `text` und die Schriftart `text`.

Manche Attribute stehen für mehrere CSS-Eigenschaften.
Ist das Attribut gesetzt, gelten CSS-Regeln und geerbte Werte für diese Eigenschaften nicht (außer mit `!important`):

| Attribut | steht für |
|---|---|
| `textformat` | `text-align`, `text-indent`, `margin-top`, `margin-bottom`, `hyphens`, `letter-spacing`, `break-before`, `break-after`, `orphans`, `widows` |
| `fontfamily` | `font-family`, `font-size`, `line-height` |
| `color` | `color` |
| `align` (an `<Tr>` und `<Td>`) | `text-align` |

```xml
<Stylesheet>
  paragraph { color: gray }
  paragraph.wichtig { color: red !important }
</Stylesheet>
…
<Paragraph color="blue">…</Paragraph>                   <!-- blau -->
<Paragraph color="blue" class="wichtig">…</Paragraph>   <!-- rot -->
```

### Vererbung

Wie in CSS erben die inneren Befehle Schrift- und Texteigenschaften von den umgebenden.
Vererbt werden `color`, `font-family`, `font-size`, `font-style`, `font-weight`, `line-height`, `text-align`, `text-indent`, `hyphens`, `letter-spacing`, `orphans` und `widows`.
Diese Werte geben `<Textblock>`, `<Paragraph>`, `<Table>`, `<Tablehead>`, `<Tablefoot>`, `<Tr>` und `<Td>` an ihren Inhalt weiter.

```xml
<Stylesheet>
  textblock.hinweis { color: gray; font-size: 8pt; text-align: right }
</Stylesheet>
…
<Textblock class="hinweis">
  <Paragraph><Value>grau, 8pt, rechtsbündig</Value></Paragraph>
  <Paragraph color="black"><Value>schwarz, 8pt, rechtsbündig</Value></Paragraph>
</Textblock>
```

Relative Angaben wie `font-size: 1.2em` beziehen sich auf die Schrift des umgebenden Befehls.
Ein Attribut ersetzt auch die geerbten Werte, für die es steht: ein Absatz mit `fontfamily="..."` erbt keine Schriftgröße, ein Textblock mit `textformat="..."` gibt keine Ausrichtung aus CSS an seine Absätze weiter.

### Eigenschaften der Befehle

| Befehl | CSS-Eigenschaften |
|---|---|
| `paragraph` | `color`, `background-color`, `font-family`, `font-size`, `font-weight`, `font-style`, `line-height`, `text-align`, `text-indent`, `hyphens`, `letter-spacing`, `margin-top`, `margin-bottom`, `break-before`, `break-after`, `orphans`, `widows` |
| `textblock` | die vererbten Eigenschaften (siehe oben) sowie `width`, `column-count`, `column-gap` |
| `table` | die vererbten Eigenschaften, `padding` und `padding-*` (Vorgabe für alle Zellen), `border-collapse` |
| `tablehead`, `tablefoot` | die vererbten Eigenschaften |
| `tr` | die vererbten Eigenschaften, `background-color`, `vertical-align` |
| `td` | die vererbten Eigenschaften, `vertical-align`, `background-color`, `padding`, `padding-*`, `border-*-width`, `border-*-color` sowie `background-text` und die übrigen Hintergrund-Attribute |
| `tablerule` | `height` (Linienstärke), `background-color` (Farbe), `rule-start` |
| `span` | `background-color`, `background-padding-top`, `background-padding-bottom`, `letter-spacing` |
| `u` | `border-style` (`dashed` für eine gestrichelte Linie) |
| `ul`, `ol` | `color`, `list-style-type`, `list-style-position`, `padding-left`; für das Aufzählungszeichen `li::marker` mit `content`, `color` und `padding-right` |
| `box` | `background-color`, `padding-*` |
| `circle` | `background-color`, `color` (Rahmenfarbe) |
| `frame` | `border-*-radius` |
| `img` | `padding`, `padding-*` |
| `placeobject` | `background-color` |
| `rule` | `height` (Linienstärke), `background-color` (Farbe) |

Die Befehlsreferenz vermerkt bei jedem Attribut, das einer CSS-Eigenschaft entspricht, deren Namen (zum Beispiel „CSS-Eigenschaft: background-color“ bei `<Box>`).

`font-family` nennt eine Schriftfamilie aus [`<DefineFontfamily>`]({{< relref "/reference/commands/definefontfamily" >}}), eine Schrift aus `@font-face` oder [`<LoadFontfile>`]({{< relref "/reference/commands/loadfontfile" >}}) oder eine der allgemeinen Familien `serif`, `sans-serif` und `monospace`.
Mehrere Namen, durch Kommas getrennt, werden der Reihe nach probiert.
Mit `font-size` oder `line-height` entsteht bei Bedarf eine neue Schriftfamilie; vorher muss keine passende definiert werden.

```xml
<Stylesheet>
  @font-face { font-family: "Zitat"; src: local("CrimsonPro-Regular") }
  @font-face { font-family: "Zitat"; font-weight: bold; src: local("CrimsonPro-Bold") }
  paragraph.zitat { font-family: Zitat, serif; font-size: 11pt; line-height: 14pt }
</Stylesheet>
```

### Tabellen {#css-tables}

Mit CSS lässt sich das Aussehen einer Tabelle vom Aufbau trennen.
Die Befehle enthalten dann nur noch Klassen, Farben, Schrift und Ausrichtung stehen im Stylesheet:

```xml
<Stylesheet>
  table.preise { font-size: 9pt; padding: 2pt 4pt }
  table.preise tablehead td { color: white; font-weight: bold }
  table.preise tablehead tr { background-color: #37586e }
  table.preise tr:nth-child(even) { background-color: #e6edf1 }
  table.preise td:first-child { font-weight: bold }
  table.preise td:nth-child(5) { text-align: right }
  table.preise tr.aktion { color: #a33a2a }
</Stylesheet>
```

![Eine Preisliste, die ihr Aussehen aus CSS bezieht](/img/css-zebratable.png)

Für Zeilen und Zellen gibt es die Pseudoklassen `:first-child` und `:nth-child()` mit `even`, `odd` und Formeln wie `3n+1`:

* Bei `tr` zählt die Position der Zeile.
  Die Zeilen im Tabellenkopf, im Tabellenfuß und im Rumpf werden getrennt gezählt, so beginnen die Zebrastreifen im Rumpf unabhängig vom Kopf.
* Bei `td` zählt die Position der Zelle in der Zeile.
  Eine Zelle mit `colspan` zählt einfach, wie in HTML.
* `:last-child` und `:nth-last-child()` wirken nicht, weil die folgenden Zeilen und Zellen beim Auswerten noch nicht bekannt sind.
  Andere Befehle als `<Tr>` und `<Td>` kennen ihre Position nicht.

Die Position gilt für die ganze Tabelle, nicht für die Seite: Bricht die Tabelle um, setzen sich die Zebrastreifen auf der nächsten Seite fort.
Sollen sie auf jeder Seite neu beginnen, hilft `sd:alternating()` mit `eval-on-split` (siehe [Abwechselnde Zeilenfarben]({{< relref "/manual/tables#abwechselnde-zeilenfarben" >}})).
Ein Tabellenkopf, der auf jeder Seite neu ausgewertet wird, behält die Regeln der Tabelle.

Das vollständige Beispiel liegt im [Beispiele-Repository](https://github.com/speedata/examples/tree/master/technical/csstable).

## CSS für HTML-Inhalte und Auszeichnungen in den Daten

HTML-Inhalte (siehe das Kapitel [HTML]({{< relref "html" >}})) und Absatzinhalte mit Auszeichnungen werden intern von derselben HTML-Verarbeitung gesetzt.
Die eingebundenen Stylesheets gelten deshalb auch für diese Inhalte.

Textauszeichnungen in den Daten funktionieren wie folgt:

```xml
<p>Text, Text, Text <b>Fettdruck</b>, Text Text</p>
```

Der Publisher sorgt dafür, dass der Text innerhalb  des Elements `b` in Fettdruck erscheint.

Man kann auch eigene Elemente mit CSS-Stilen versehen.
Wenn man z. B. folgende Daten hat

```xml
<data>hello <green>green</green> world</data>
```

kann man mit CSS das Element einfärben:

```xml
<Layout
  xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Stylesheet>
    green {
      color: green;
    }
  </Stylesheet>

  <Record element="data">
    <PlaceObject>
      <Textblock>
        <Paragraph>
          <Value select="."/>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```

![Elemente in Daten kann man nun einfärben](/img/32-hellogreenworld.png)

Neben der Farbe lassen sich auf diesem Weg auch weitere Eigenschaften setzen, zum Beispiel `font-weight: bold`, `font-style: italic`, `text-decoration: underline` und `background-color`.
Die Schrift des Absatzes bleibt dabei maßgeblich: `font-family` und `font-size` wirken in Absatzinhalten nur, wenn das verwendete Textformat `cssfontsize="yes"` gesetzt hat (siehe [`<DefineTextformat>`]({{< relref "/reference/commands/definetextformat" >}})).

### Unterstützte CSS-Eigenschaften

Die folgenden Eigenschaften werden bei der HTML-Verarbeitung ausgewertet:

* Schrift: `font-family`, `font-size`, `font-style`, `font-weight`
* Text: `color`, `text-align`, `text-decoration` (bzw. `text-decoration-line` mit `underline` und `line-through`, `text-decoration-style` mit `solid`, `double`, `dotted`, `dashed` und `wavy`, `text-decoration-color`), `line-height`, `white-space` (`normal`, `pre`), `vertical-align` (`super`, `sub`) und `hyphens` (`none` bzw. `manual` schaltet die Silbentrennung aus)
* Box-Modell: `margin-*`, `padding-*`, `border-*` (Breite, Stil und Farbe je Seite sowie `border-radius` je Ecke), `width`, `height`
* Hintergrund: `background-color`
* Listen: `list-style-type`, `list-style-position`, `list-style` sowie das Pseudoelement `li::marker` (`content`, `color`, `font-family`, `font-size`, `padding-right`, `padding-bottom`)
* Tabellen: `border-collapse`
* Umbruch: `break-before`, `break-after`

Nicht jede Eigenschaft ist in jeder Situation vollständig umgesetzt.
Den aktuellen Stand einzelner Eigenschaften dokumentiert der [Teststatus im HTML-Kapitel]({{< relref "html#teststatus" >}}).
