---
title: "Silbentrennung / Spracheinstellungen"
weight: 43
type: docs
aliases:
  - /de/grundlagen/silbentrennung-sprache/
---


Silbentrennung ist in den meisten westlichen Sprachen notwendig, um ein akzeptables Erscheinungsbild für schmale Texte zu haben.
Silbentrennung ist ein integraler Bestandteil des Umbruchalgorithmus, beispielsweise weil vermieden werden soll, dass mehrere Trennungen in aufeinanderfolgenden Zeilen auftreten.

Die Silbentrennung wird im Publisher über die Sprache gesteuert und musterbasiert vorgenommen.
Die Sprache kann man global einstellen über `<Options mainlanguage="...">` oder Absatzweise.

```xml
<Options mainlanguage="German" />
```

stellt das gesamte Dokument auf deutsche Trennmuster um, während

```xml
<Paragraph language="German">
    <Value>Autobahn</Value>
</Paragraph>
```

nur für einen Absatz die Sprache umstellt.
Die verfügbaren Sprachen sind in der Befehlsreferenz unter [`<Options>`]({{< relref "/reference/commands/options" >}}) beschrieben.

Alternativ zu den ausgeschriebenen Namen wie `German` kann auch der Sprachcode verwendet werden.
Die beiden Beispiele oben können auch wie folgt benutzt werden:

```xml
<Options mainlanguage="de" />

<Paragraph language="de">
    <Value>Autobahn</Value>
</Paragraph>
```

Möchte man testen, ob die Wörter richtig getrennt werden, kann man mit `<Trace hyphenation="yes" />` kleine Markierungen erzeugen lassen. Alle Schalter des Befehls `<Trace>` listet das Kapitel [Fehlerbehebung / Debugging]({{< relref "troubleshooting" >}}) auf.


```xml
<Layout
  xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Options mainlanguage="German" />
  <Trace hyphenation="yes" />

  <Record element="data">
    <PlaceObject>
      <Textblock width="3">
        <Paragraph>
          <Value>Autobahn</Value>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```

ergibt folgendes:

![Trennstellen anzeigen im Text](/img/13-autobahn.png)

Mittels

```xml
<Hyphenation>er-go-no-mic</Hyphenation>
```

kann man für einzelne Wörter Trennvorschläge bzw. -ausnahmen definieren. So werden die Wörter dann nur an den mit Bindestrich angegebenen Stellen getrennt. Die Trennausnahme gilt für die Hauptsprache des Dokuments. Mit dem Attribut `language` kann man die Sprache festlegen, für die die Trennausnahme gilt.

{{< callout >}}
Mit optischem Randausgleich, der im Abschnitt [Optischer Randausgleich]({{< relref "textformatting#optischer-randausgleich" >}}) beschrieben ist, kann man die Anzahl der Silbentrennungen im Dokument etwas verringern.
{{< /callout >}}

## Trennungen für Absätze ausschalten

Für einzelne Absätze kann man die automatische Silbentrennung ausschalten, in dem man ein Textformat definiert mit `hyphenate="no"`

```xml
<DefineTextformat name="nohyphen" hyphenate="no"/>
```

In so markierten Absätzen werden keine Wörter getrennt.
Die Anwendung von Textformaten ist in einem [eigenen Abschnitt]({{< relref "textformat" >}}) beschrieben.

Das Zeichen für die Silbentrennung kann man ebenfalls über ein Textformat verändern:

```xml
<DefineTextformat name="dothyphen" hyphenchar="•"/>
```

![Anderes Zeichen für Worttrennungen](/img/13-dothyphen.png)

## Verschiedene Sprachen innerhalb eines Absatzes benutzen

Man kann die Sprache für einen Textblock, einen Absatz und sogar für Teile eines Absatzes setzen. Dazu umgibt man den Text mit `<Span language="...">` und `</Span>`.

```xml
<Paragraph language="en">
  <Span language="de">
    <Value>Also schön, Guido Heffels,
           nachfolgend meine Textempfehlung
           für das Blindtextbuch.
    </Value>
  </Span>
  <Br />
  <Span>
    <Value>A wonderful serenity has taken
           possession of my entire soul, like these sweet
           mornings of spring which I enjoy with my whole
           heart.
    </Value>
  </Span>
</Paragraph>
```

## Trennungen nur an bestimmten Zeichen zulassen

Eine Eigenschaft von `<Paragraph>` erlaubt die Zeichen einzugrenzen, an denen ein Zeilenumbruch  eingefügt werden darf.
Das ist bei technischen Daten oft wichtig, wo z. B. Typenbezeichnungen in der Form `12-345/AB` vorkommen, und nicht getrennt werden sollen.
Im folgenden Beispiel darf nur hinter einem Schrägstrich umbrochen werden:

```xml
<Paragraph allowbreak="/">
  <Value>https://download.speedata.de/publisher/development/</Value>
</Paragraph>
```

Die Voreinstellung für `allowbreak` ist `" -"`, also ein Umbruch an einem Leerzeichen oder einem Trennstrich.

{{< callout >}}
Das ist ein experimentelles Feature im Publisher. Wahrscheinlich wird dies in einer zukünftigen Version einem Textformat zugeordnet werden.
{{< /callout >}}

## Zeilenumbruch mit Sonderzeichen steuern

Einige Unicode-Zeichen steuern den Zeilenumbruch direkt im Text.
Sie sind unsichtbar und können in den Daten oder im Layout als numerische Zeichenreferenz geschrieben werden.

| Zeichen | Eingabe | Wirkung |
|---|---|---|
| U+00AD weicher Trennstrich | `&#xAD;` | Das Wort darf an dieser Stelle getrennt werden. Am Zeilenende erscheint das Trennzeichen des Textformats (`hyphenchar`), sonst bleibt das Zeichen unsichtbar. |
| U+200B Leerzeichen mit Nullbreite | `&#x200B;` | Ein Umbruch ohne Trennstrich ist erlaubt, zum Beispiel in langen Bezeichnungen oder bei Thai (siehe [Schriftsysteme]({{< relref "scripts" >}})). |
| U+2060 Wortverbinder | `&#x2060;` | Zwischen den beiden Zeichen wird nicht umbrochen. |
| U+00A0 geschütztes Leerzeichen | `&#xA0;` | Ein Leerzeichen, an dem nicht umbrochen wird, zum Beispiel zwischen Zahl und Einheit. |

```xml
<Paragraph>
  <Value>Donau&#xAD;dampf&#xAD;schiff&#xAD;fahrt, 12&#xA0;kg</Value>
</Paragraph>
```

Ein Umbruch hinter einem Bindestrich lässt sich mit U+2060 nicht verhindern, dafür gibt es das Attribut `allowbreak` (siehe oben).

## Andere Schriftsysteme

Rechtsläufige Schriften wie Arabisch und Hebräisch, Chinesisch, Japanisch und Koreanisch sowie Thai und verwandte Schriften haben eigene Regeln für Schreibrichtung, Zeilenumbruch und Zeichenformen.
Sie sind im Abschnitt [Schriftsysteme]({{< relref "scripts" >}}) beschrieben.
