---
title: "XPath-Ausdrücke"
weight: 160
type: docs
---

## Was ist XPath?

XPath ist eine Sprache, um durch XML-Bäume zu navigieren und Daten abzufragen.
Da die Eingabedaten des Publishers im XML-Format vorliegen, ist XPath das zentrale Werkzeug, um auf Elemente, Attribute und Texte zuzugreifen.
Beispiele: »Gib mir alle Artikel mit einem bestimmten Attribut« oder »Wie viele Artikel hat diese Artikelgruppe?«.

Eine allgemeine Einführung in XPath bietet das [Tutorial bei W3Schools](https://www.w3schools.com/xml/xpath_intro.asp).

## Wo werden XPath-Ausdrücke verwendet?

Der Publisher akzeptiert XPath-Ausdrücke an zwei Stellen:

1. **In den Attributen `select` und `test`** — hier wird der Wert direkt als XPath interpretiert.
2. **In allen anderen Attributen** — durch geschweifte Klammern (`{` und `}`) wird ein XPath-Ausdruck erzwungen.

```xml
<Textblock width="{$breite}">
  <Paragraph>
    <Value select="."/>
  </Paragraph>
</Textblock>
```
{{% codecaption %}}Die Breite wird aus der Variable `$breite` gelesen, der Absatzinhalt ist der Textwert des aktuellen Datenknotens.{{% /codecaption %}}


## Unterstützte Ausdrücke

* **Zahlen und Text**: `"5"`, `'hello world'` — werden direkt zurückgegeben.
* **Rechenoperationen**: `*`, `div`, `idiv`, `+`, `-`, `mod`. Beispiel: `( 6 + 4.5 ) * 2`
* **Variablen**: `$spalte + 2`
* **Aktueller Knoten** (Punkt-Operator): `. + 2`
* **Kindelemente**: `produktdaten`, `*`, `foo/bar`, `node()`
* **Elternknoten**: `../`
* **Attribute**: `@a`, `foo/@bar`
* **Filter**: `article[1]` wählt das erste Kindelement `article` aus.
* **Vergleiche**: `<`, `>`, `<=`, `>=`, `=`, `!=`. Achtung: `<` muss in XML als `&lt;` geschrieben werden.
* **If/then/else**: `if (...) then ... else ...`
* **For-Ausdrücke**: `for $i in (1,2,3) return $i * 2` oder `for $i in 1 to 3 return $i * 2`
* **Achsen**: `preceding-sibling`, `parent`, `descendant-or-self`, `following-sibling` usw.


## XPath und Namensräume

Der speedata Publisher ignoriert [XML-Namensräume](https://de.wikipedia.org/wiki/Namensraum_(XML)) in der Voreinstellung. Das ist in der Regel sehr hilfreich, da Namensräume nicht immer leicht zu handhaben sind.

Die XML-Datei:

```xml
<bar:data xmlns:bar="somenamespace">
    <bar:child>
        <bar:sub>sub</bar:sub>
    </bar:child>
</bar:data>
```

kann im Layout wie folgt angesprochen werden:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en">

    <Record element="data">
      ...
```

obwohl der Namensraum des Wurzelelements `somenamespace` ist.

Mit `<Options namespaces="strict" />` stellt man das um, so dass der Namensraum bei [`<Record>`]({{< relref "/reference/record" >}}) und bei [`<ProcessNode>`]({{< relref "/reference/processnode" >}}) anzugeben ist:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en"
    xmlns:sn="somenamespace">

    <Options namespaces="strict" />

    <Record element="sn:data">
        <PlaceObject>
            <Textblock>
                <Paragraph>
                    <Value select="local-name()"></Value>
                </Paragraph>
            </Textblock>
        </PlaceObject>
    </Record>
</Layout>
```

Wichtig ist, dass der Namensraum übereinstimmt, der Präfix (hier: `sn`) ist frei wählbar, solange er mit dem Namensraum verbunden ist.

[`<ProcessNode>`]({{< relref "/reference/processnode" >}}) funktioniert ähnlich:

```xml
<ProcessNode select="*:child" />
<ProcessNode select="sn:child" />
<ProcessNode select="sn:*" />
<ProcessNode select="*" />
```

rufen das Kindelement `bar:child` auf, da die Namensräume von `sn` (aus dem Layout) und `bar` (aus den Daten) übereinstimmen. `*` ist hier eine »Wildcard«, passt also auf alle Namen.

`<ProcessNode select="child" />` wird im obigen Fall nicht funktionieren, da der leere Namensraum aus dem Layout `urn:speedata.de:2009/publisher/en` ist und nicht mit dem Namensraum aus den Daten übereinstimmt.

Ebenfalls muss man in den XPath-Abfragen Namensräume benutzen, wenn sie in den Daten vorgegeben sind:

```xml
<Message select="count(sn:sub)" />
```

schreibt 1 in die Protokolldatei. Ohne Namensraum eine 0, da kein Element sub mit dem voreingestellten Namensraum gefunden wird.
