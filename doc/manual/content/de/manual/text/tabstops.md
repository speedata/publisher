---
title: "Tabulatoren"
weight: 44
type: docs
---

Mit Tabulatoren lassen sich Texte innerhalb eines Absatzes an festen Positionen ausrichten, ganz ohne Tabelle. Typische Anwendungen sind Inhaltsverzeichnisse mit rechtsbündigen Seitenzahlen und Füllpunkten, Formulare mit Bezeichnung und Wert oder kleine Preislisten mit Zahlen, die am Komma ausgerichtet sind.

Die Tabstopps werden im Textformat mit dem Attribut `tab-stops` bei [`<DefineTextformat>`]({{< relref "/reference/commands/definetextformat" >}}) festgelegt. Ein Tabulatorzeichen (`&#9;`) im Text rückt den folgenden Text zum nächsten Tabstopp.

{{< callout type="info" >}}
Tabstopps gibt es seit Version 5.9.8.
{{< /callout >}}

## Tabstopps festlegen

Das Attribut `tab-stops` enthält eine durch Kommas getrennte Liste von Tabstopps. Jeder Tabstopp beginnt mit seiner Position, gemessen vom Anfang des Absatzes. Die Position ist eine Länge (`25mm`) oder ein Anteil der Textbreite in Prozent (`50%`, `100%` ist der rechte Rand).

```xml
<DefineTextformat name="form" alignment="leftaligned"
                  tab-stops="25mm" indentation="25mm" rows="-1"/>
...
<Paragraph textformat="form">
  <Value>Anschrift&#9;Heidestraße 17, 51147 Köln, ein längerer Text, der umbricht</Value>
</Paragraph>
```

![Formular mit Bezeichnung und Wert, der Wert beginnt bei 25 mm.](/img/tabstops-form.png)

Die Angaben `indentation="25mm"` und `rows="-1"` sind nicht nötig, sorgen aber für einen hängenden Einzug: Ohne sie beginnen Folgezeilen am linken Rand des Absatzes, mit ihnen stehen sie unter dem Wert.

Das Tabulatorzeichen kann in den Daten stehen oder im Layout eingefügt werden, entweder als eigenes `<Value>&#9;</Value>` oder in einem XPath-Ausdruck:

```xml
<Paragraph textformat="form">
  <Value select="concat(@label, '&#9;', @value)"/>
</Paragraph>
```

## Ausrichtung

Hinter der Position kann die Ausrichtung des Textes am Tabstopp stehen:

| Angabe | Wirkung |
| --- | --- |
| `left` | Der Text beginnt am Tabstopp (Voreinstellung). |
| `right` | Der Text endet am Tabstopp. |
| `center` | Der Text wird am Tabstopp zentriert. |
| `decimal` | Zahlen werden am Dezimalpunkt ausgerichtet. |
| `decimal(',')` | Zahlen werden am angegebenen Zeichen ausgerichtet, hier am Komma. |

Text ohne das Trennzeichen endet bei `decimal` am Tabstopp, wie bei `right`. So stehen ganze Zahlen richtig in der Spalte, und auch Spaltenköpfe lassen sich mit derselben Einstellung setzen:

```xml
<DefineTextformat name="prices" alignment="leftaligned"
                  tab-stops="50mm decimal(','), 85mm decimal(',')"/>
...
<Paragraph textformat="prices">
  <Value>Kaffee&#9;3,50&#9;4,17</Value>
</Paragraph>
```

![Preisliste, die Beträge sind am Komma ausgerichtet.](/img/tabstops-prices.png)

Mit `center` lassen sich zum Beispiel Beschriftungen unter Unterschriftslinien setzen: `tab-stops="25% center, 75% center"`.

## Füllzeichen

Mit `leader('...')` wird die Lücke vor dem Tabstopp mit dem angegebenen Text gefüllt, meistens mit Punkten. Die Füllzeichen stehen in allen Zeilen an denselben Positionen, damit die Punkte untereinander stehen. Leerzeichen im Füllzeichen vergrößern den Abstand der Punkte.

```xml
<DefineTextformat name="toc" alignment="leftaligned"
                  indentation="8mm" rows="-1"
                  tab-stops="8mm, 100% right leader(' . ')"/>
...
<Paragraph textformat="toc">
  <Value>2&#9;Tabulatoren und ein etwas längerer Titel, der in die nächste Zeile umbricht&#9;12</Value>
</Paragraph>
```

![Inhaltsverzeichnis mit Kapitelnummer, Titel, Füllpunkten und rechtsbündiger Seitenzahl.](/img/tabstops-toc.png)

Auch hier sorgt der hängende Einzug dafür, dass ein umbrechender Titel unter dem Titel weiterläuft und nicht unter der Kapitelnummer. Die Seitenzahl wird mit dem rechtsbündigen Tabstopp in die letzte Zeile gesetzt.

## Verhalten im Detail

* Ein Tabulator springt immer zum nächsten Tabstopp rechts von der aktuellen Position. Ist der Text schon über einen Tabstopp hinausgelaufen, wird dieser übersprungen.
* Gibt es in der Zeile keinen weiteren Tabstopp, ist der Tabulator ein normales Leerzeichen.
* Leerzeichen direkt vor und nach einem Tabulator werden entfernt. `Name &#9; Wert` ergibt dasselbe wie `Name&#9;Wert`.
* Text hinter einem Tabstopp mit `right`, `center` oder `decimal` wird nicht umbrochen, solange er in die Zeile passt.
* Prozentangaben beziehen sich auf die Breite des Absatzes, also zum Beispiel auf die Breite des Textblocks oder der Tabellenzelle.
* Ist `tab-stops` angegeben, hat es Vorrang vor dem Attribut `tab`.
* Zeilen mit Tabulatoren werden im Blocksatz nicht gedehnt, die übrigen Zeilen des Absatzes schon.

## Beispiel

Ein vollständiges Bestellblatt mit Inhaltsverzeichnis, Formularfeldern, Preisliste und Unterschriftslinien, ganz ohne Tabellen, liegt im [Beispiele-Repository](https://github.com/speedata/examples/tree/master/technical/tabstops).

## Tabulatoren oder Tabelle?

Tabulatoren eignen sich für einzeilige Einträge und einfache Spalten innerhalb von Fließtext, vor allem wenn Füllpunkte gebraucht werden. Sobald Zellen mehrzeilig werden, Rahmen oder Hintergrundfarben brauchen oder sich über Seiten mit wiederholtem Tabellenkopf erstrecken, ist eine [Tabelle]({{< relref "/manual/tables" >}}) die bessere Wahl.
