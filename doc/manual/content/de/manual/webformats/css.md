---
title: "CSS verwenden"
weight: 74
type: docs
---



CSS (Cascading Stylesheets) ist eine Sprache, die hauptsächlich im Web benutzt wird, um das Aussehen von Objekten zu bestimmen.
Die Idee ist, die Formatierung vom Inhalt zu trennen.
Im Web - so die reine Lehre - ist der Inhalt in HTML beschrieben, während das Aussehen mit CSS festgelegt wird.
Beim speedata Publisher ist die Trennung noch deutlicher.
Die Daten enthalten in der Regel keinerlei Informationen über das Aussehen, während das Layoutregelwerk keinerlei Informationen über die Daten hat.

CSS kommt im speedata Publisher an zwei getrennten Stellen zum Einsatz, die man auseinanderhalten muss:

1. **CSS für Layout-Befehle:** Einige Befehle im Layoutregelwerk können ihre Attributwerte aus CSS-Regeln beziehen. Dieser Weg ist bewusst rudimentär gehalten.
2. **CSS für HTML-Inhalte und Auszeichnungen in den Daten:** Inhalte, die über den Befehl [`<HTML>`]({{< relref "html" >}}) oder als Markup in Absatzinhalten verarbeitet werden, formatiert der Publisher mit einem deutlich größeren CSS-Umfang.

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

## CSS für Layout-Befehle

Derzeit können die Befehle `<Box>`, `<Circle>`, `<Frame>`, `<Image>`, `<PlaceObject>`, `<Rule>`, `<Span>`, `<Tablerule>`, `<Td>`, `<Tr>` und `<U>` per CSS formatiert werden.
Welche Eigenschaften ein Befehl versteht, zeigt die [Befehlsreferenz]({{< relref "/reference" >}}): dort ist bei jedem Attribut vermerkt, über welchen CSS-Eigenschaftsnamen es angesprochen werden kann (beim Befehl `<Box>` beispielsweise „CSS Eigenschaft: background-color").

{{< callout >}}
Die CSS-Unterstützung für Layout-Befehle hat eher den Charakter eines »Proof-of-Concepts« bzw. eines Prototyps. Die Befehle und die Eigenschaften, die sich so steuern lassen, sind sehr begrenzt.
{{< /callout >}}

Ein vollständiges Beispiel: die Box erhält ihre Hintergrundfarbe über die Klasse `warn`.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Stylesheet>
    .warn {
      background-color: red;
    }
  </Stylesheet>

  <Record element="data">
    <PlaceObject>
      <Box class="warn" width="5" height="2"/>
    </PlaceObject>
  </Record>
</Layout>
```

### Selektoren

Wie von HTML bekannt, werden die CSS-Anweisungen mit sogenannten Selektoren bestimmten Elementen zugeordnet.

```xml
<Table>
  <Tr minheight="4">
    <Td class="myclass" id="myid">
      <Paragraph>
        <Value>Hallo Welt</Value>
      </Paragraph>
    </Td>
  </Tr>
</Table>
```

Die Tabellenzelle im Beispiel oben könnte über die folgenden Selektoren angesprochen werden:

```css
#myid {
  vertical-align: top ;
}
```

```css
.myclass {
  vertical-align: top ;
}
```

und

```css
td {
  vertical-align: top ;
}
```

Der erste Fall ist über das Attribut `id`, die im Layoutregelwerk eindeutig sein muss.
Der zweite Fall wird über die Klasse `class="..."` angesprochen.
Die Klasse kann bei mehreren Elementen im Layoutregelwerk gleich sein.
Der dritte Fall bezieht sich auf alle Elemente `Td` im Layoutregelwerk.
Als Elementname im Selektor dient der kleingeschriebene Befehlsname (`td` für `<Td>`, `u` für `<U>`); nur der Befehl `<Image>` wird wie in HTML über `img` angesprochen.
Hier gelten die üblichen Spezifitätsregeln für CSS, `!important` wird jedoch nicht unterstützt.

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
* Text: `color`, `text-align`, `text-decoration` (bzw. `text-decoration-line`, `text-decoration-style`, `text-decoration-color`), `line-height`, `white-space` (`normal`, `pre`), `vertical-align` (`super`, `sub`) und `hyphens` (`none` bzw. `manual` schaltet die Silbentrennung aus)
* Box-Modell: `margin-*`, `padding-*`, `border-*` (Breite, Stil und Farbe je Seite sowie `border-radius` je Ecke), `width`
* Hintergrund: `background-color`
* Listen: `list-style-type`, `list-style-position`, `list-style` sowie das Pseudoelement `li::marker` (`content`, `color`, `font-family`, `font-size`, `padding-right`, `padding-bottom`)
* Tabellen: `border-collapse`
* Umbruch: `break-before`, `break-after`

Nicht jede Eigenschaft ist in jeder Situation vollständig umgesetzt; so wird bei `text-decoration` derzeit nur `underline` gezeichnet.
Den aktuellen Stand einzelner Eigenschaften dokumentiert der [Teststatus im HTML-Kapitel]({{< relref "html#teststatus" >}}).
