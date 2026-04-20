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

Der speedata Publisher verlässt sich bei der Formatierung der Objekte ausschließlich auf die eingebaute Sprache.
Einige Elemente können mithilfe von CSS gestaltet werden.
Im Publisher ist dies nur rudimentär vorgesehen:
Derzeit können die Befehle `<Box>`, `<Circle>`, `<Frame>`, `<Paragraph>`, `<Rule>`, `<Td>`, `<Tablerule>` und `<U>` per CSS formatiert werden.
[In der Befehlsreferenz]({{< relref "/reference" >}}) sind die Befehle mit den dazugehörigen Attributen aufgelistet, die über die CSS-Funktionalität angesprochen werden können.

{{< callout >}}
Die CSS-Implementierung im speedata Publisher hat eher den Charakter eines »Proof-of-Concepts« bzw. eines Prototyps. Die Befehle und die Eigenschaften, die sich über CSS steuern lassen, sind sehr begrenzt.
{{< /callout >}}

Ein CSS-Stylesheet kann als externe Datei vorliegen und eingebunden werden.
Alternativ kann man auch CSS-Anweisungen direkt in das Layoutregelwerk schreiben.
`<Stylesheet>` lautet der Befehl für beide Varianten:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Stylesheet filename="style.css"/>

  <Record element="data">
    <PlaceObject>
      <Textblock>
        <Paragraph>
          <Value>Test</Value>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>

</Layout>
```

ergibt mit der folgenden CSS-Datei:

```css

p {
	color: red;
}
```

ergibt das Wort »Test« im PDF in der Farbe rot.

Wenn die CSS-Anweisungen direkt eingefügt werden, ist die Syntax folgende:

```xml
  <Stylesheet>
    p {
      color: red;
    }
  </Stylesheet>
```


## Selektoren

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
Hier gelten die üblichen Spezifitätsregeln für CSS, `!important` wird jedoch nicht unterstützt.

## CSS und Elemente in Daten

Textauszeichnungen in den Daten funktionieren wie folgt:

```xml
<p>Text, Text, Text <b>Fettdruck</b>, Text Text</p>
```

Der Publisher sorgt dafür, dass der Text innerhalb  des Elements `b` in Fettdruck erscheint.

Man kann auch eigene Elemente mit CSS-Stilen versehen.
Wenn man z. B. folgende Daten hat

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

Derzeit lassen sich nur die Attribute Unterstreichen und Farbe (`text-decoration: underline;` und `color: ...`) per CSS festlegen.

