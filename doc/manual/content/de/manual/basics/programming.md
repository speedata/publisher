---
title: "Programmierung"
weight: 40
type: docs
---


Die sicherlich bedeutendste Eigenschaft des Publishers ist die Fähigkeit, sehr flexible Layoutanforderungen umzusetzen.
Das wird hauptsächlich durch die eingebaute Programmiersprache in Zusammenhang mit den Abfragemöglichkeiten des Publishers erreicht.

{{< callout >}}
Die Programmausführung läuft gleichzeitig mit der Erzeugung des PDFs.

Daher kann der speedata Publisher sehr flexibel auf die Eingabedaten reagieren.
Abfragen wie »Ist noch genügend Platz für dieses Objekt vorhanden?« sind damit möglich.
Das unterscheidet den Publisher von anderer Software zur Erstellung von PDF-Dateien.
{{< /callout >}}

Es sind grundlegende Programmierkenntnisse vonnöten, um die volle Funktionalität des Publishers auszureizen.
Die Programmiersprache ist so einfach wie möglich gehalten, um die Lesbarkeit des Layouts zu erhalten.

Die Programmierung gliedert sich in drei Bereiche:

1. **Datenverarbeitung**: Wie werden die XML-Eingabedaten verarbeitet und in PDF-Ausgabe umgewandelt?
2. **Kontrollfluss**: Bedingungen, Schleifen und Fallunterscheidungen steuern die Verarbeitung.
3. **Variablen und Funktionen**: Werte speichern, wiederverwenden und eigene Funktionen definieren.


## Zusammenspiel von Layout und Daten

Bevor wir in die Details der Programmiersprache einsteigen, ist es wichtig zu verstehen, wie Layout und Daten zusammenwirken.
Der Publisher arbeitet immer mit zwei Dateien: einer **Datendatei** (`data.xml`) und einer **Layoutdatei** (`layout.xml`).

Ein vollständiges Minimalbeispiel:

```xml
<productlist>
  <product name="Schreibtischlampe" price="29,95" />
  <product name="Stehlampe" price="79,00" />
  <product name="Deckenleuchte" price="149,90" />
</productlist>
```
{{% codecaption %}}Datendatei (`data.xml`): Eine einfache Produktliste mit drei Einträgen.{{% /codecaption %}}

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Record element="productlist">
    <PlaceObject>
      <Textblock>
        <Paragraph><Value>Produktkatalog</Value></Paragraph>
      </Textblock>
    </PlaceObject>
    <ProcessNode select="product"/>
  </Record>

  <Record element="product">
    <PlaceObject>
      <Textblock>
        <Paragraph>
          <Value select="@name"/>
          <Value> – </Value>
          <Value select="@price"/>
          <Value> €</Value>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>

</Layout>
```
{{% codecaption %}}Layoutdatei (`layout.xml`): Für jedes Element in der Datendatei gibt es einen passenden `Record`.{{% /codecaption %}}

![Zusammenspiel von Layout und Daten](/img/layout-data-flow.svg)

**①** Der Publisher findet das Wurzelelement `<productlist>` und sucht den passenden Record.
**②** `ProcessNode` delegiert jedes `<product>`-Element an den passenden Record. Innerhalb eines Records hat man Zugriff auf die Attribute des aktuellen Datenelements: `@name` liefert den Namen, `@price` den Preis.

### Was passiert beim Programmstart?

Der Publisher arbeitet diese Schritte ab:

1. **Layoutdatei einlesen**: Alle `Record`-Definitionen werden für die spätere Verarbeitung gespeichert. Befehle außerhalb von Records (z.B. `DefineColor`, `DefineFontFamily`) werden sofort ausgeführt.
2. **Datendatei öffnen**: Der Publisher liest die XML-Daten und beginnt mit dem Wurzelelement – hier `<productlist>`.
3. **Passenden Record suchen**: Für `<productlist>` wird der Record mit `element="productlist"` gefunden und ausgeführt.
4. **Kindelemente delegieren**: Der Befehl `ProcessNode select="product"` bewirkt, dass für jedes `<product>`-Element der passende Record gesucht und ausgeführt wird.
5. **Datenzugriff**: Innerhalb eines Records hat man Zugriff auf die Attribute und Kindelemente des aktuellen Datenelements. Im Record für `product` liefert `@name` den Produktnamen und `@price` den Preis.

Dieses Zusammenspiel von `Record` und `ProcessNode` ist das zentrale Konzept des Publishers.
Ohne `ProcessNode` werden Kindelemente der Datendatei nicht verarbeitet – der Publisher durchläuft den Datenbaum nicht automatisch.

Weitere Details zur Strukturierung der Datendatei finden sich im Kapitel [Struktur der Datendatei]({{< relref "structuredatafile" >}}).

## Datenverarbeitung mit Record und ProcessNode

Das Grundprinzip von [`Record`]({{< relref "/reference/record" >}}) und [`ProcessNode`]({{< relref "/reference/processnode" >}}) wurde oben bereits vorgestellt.
Ähnlich wie `xsl:template match` und `xsl:apply-templates` in XSLT, definiert `Record` Verarbeitungsregeln für Datenelemente und `ProcessNode` ruft diese auf.

In diesem Abschnitt werden die weiterführenden Möglichkeiten beschrieben: Pattern-Matching, Prioritäten und Modi.

### Pattern-Matching mit dem match-Attribut

Seit Version 5.5.8 kann anstelle von `element` das Attribut `match` verwendet werden.
Damit können Verarbeitungsregeln anhand von XPath-ähnlichen Patterns zugeordnet werden, nicht nur anhand des Elementnamens.

Ein einfacher Elementname in `match` ist gleichbedeutend mit `element`:

```xml
<!-- Diese beiden Zeilen sind gleichwertig: -->
<Record element="product">
<Record match="product">
```

Darüber hinaus unterstützt `match` weitere Muster:

Prädikate
Ermöglichen die Unterscheidung von Elementen anhand ihrer Attribute oder ihres Inhalts.
```xml
<Record match="item[@type='book']">
  <!-- Wird nur für item-Elemente mit type="book" ausgeführt -->
</Record>
```

Eltern/Kind-Muster
Ermöglichen kontextabhängiges Matching basierend auf dem Elternelement.
```xml
<Record match="catalog/product">
  <!-- Nur für product-Elemente, deren Elternelement catalog ist -->
</Record>
```

Vorfahren-Muster
Matching über beliebig tiefe Verschachtelung.
```xml
<Record match="catalog//item">
  <!-- Für item-Elemente, die irgendwo unterhalb von catalog liegen -->
</Record>
```

Wildcards
Matchen auf beliebige Elemente, nützlich als Fallback-Regel.
```xml
<Record match="*">
  <!-- Wird für alle Elemente aufgerufen, für die kein spezifischerer
       Record existiert -->
</Record>
```

Wildcards mit Prädikaten
```xml
<Record match="*[starts-with(local-name(), 'chap')]">
  <!-- Matcht alle Elemente, deren Name mit "chap" beginnt -->
</Record>
```

### Prioritäten bei mehreren passenden Records

Wenn für ein Datenelement mehrere Records passen, wird der spezifischste ausgewählt.
Ein Record mit `element` (oder `match` mit einfachem Elementnamen) hat immer Vorrang vor Pattern-basierten Records.
Bei den Patterns gilt: Muster mit Prädikaten oder Pfadangaben haben eine höhere Priorität als die Wildcard (`*`).

### Modi

Mit dem Attribut `mode` können unterschiedliche Verarbeitungsregeln für dasselbe Element definiert werden.
Der Modus in `ProcessNode` muss mit dem Modus im zugehörigen `Record` übereinstimmen.
`mode` funktioniert sowohl mit `element` als auch mit `match`.

```xml
<Record match="product" mode="summary">
  <!-- Kurzdarstellung -->
</Record>

<Record match="product" mode="detail">
  <!-- Detaildarstellung -->
</Record>
```

```xml
<ProcessNode select="product" mode="summary" />
<ProcessNode select="product" mode="detail" />
```

## Variablen

Alle Variablen sind global sichtbar.
Das heißt, dass eine Variable nie ungültig wird.
Ein Beispiel:

```xml
<data>
  <article number="1" />
  <article number="2" />
  <article number="3" />
</data>
```
{{% codecaption %}}Datendatei (`data.xml`){{% /codecaption %}}

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Record element="data">
    <ProcessNode select="article"/>
    <Message select="$nr"/>
  </Record>

  <Record element="article">
    <SetVariable variable="nr" select="@number"/>
  </Record>

</Layout>
```
{{% codecaption %}}Und die dazugehörige Layout-Datei (`layout.xml`). Die Ausgabe des Befehls `<Message>` ist 3. Wäre die Variable `nr` mit lokaler Sichtbarkeit deklariert, dann  könnte sie im Element `data` nicht ausgelesen werden.{{% /codecaption %}}

Die globale Sichtbarkeit ist nötig, weil die Programmausführung im Layout manchmal »hin und her springt«.
Am Seitenende wird der Inhalt von `<AtPageShipout>` im aktuellen Seitentyp ausgeführt.
Dort muss auch auf die Variablen zugegriffen werden können.

In Variablen können nicht nur einfache Werte gespeichert werden, sondern auch komplexe XML-Abschnitte:

```xml
<Record element="data">
  <SetVariable variable="foo">
    <Paragraph>
      <Value>Hello world!</Value>
    </Paragraph>
  </SetVariable>

  <PlaceObject>
    <Textblock>
      <Copy-of select="$foo"/>
    </Textblock>
  </PlaceObject>
</Record>
```

Ergibt die erwartete Ausgabe von »Hello world!«. Ein Anwendungsfall ist, Tabellenbreitendeklarationen zu speichern:

```xml
<SetVariable variable="tablecolumns">
  <Columns>
    <Column width="1cm"/>
    <Column width="4mm"/>
    <Column width="1cm"/>
  </Columns>
</SetVariable>
```

um diese dann anschließend in mehreren Tabellen zu benutzen:

```xml
<PlaceObject>
  <Table>
    <Copy-of select="$tablecolumns"/>
    <Tr>
      ..
    </Tr>
  </Table>
</PlaceObject>
```

Durch die einmalige Definition und Wiederverwendung spart man sich Tipparbeit und verringert die Fehlerquellen.

## Copy-of

`<Copy-of>` wurde oben schon benutzt.
Damit werden Inhalte der Variablen an die aktuelle Stelle kopiert.
Der Inhalt der Variablen bleibt beim Kopieren unverändert.

```
variable =
   Copy-of variable
   neuer Wert
```
{{% codecaption %}}Pseudocode. Mit Copy-of fügt man den Inhalt der Variablen an diese Stelle ein. Der Inhalt können auch komplexe XML-Strukturen wie Absätze sein.{{% /codecaption %}}

damit wird der neue Wert an die vorherigen angehängt.

```xml
<SetVariable variable="chapter">
  <Copy-of select="$chapter"/>
  <Element name="entry">
    <Attribute name="chaptername" select="@name"/>
    <Attribute name="page" select="sd:current-page()"/>
  </Element>
</SetVariable>
```
{{% codecaption %}}Ein Beispiel für Copy-of in der Praxis ist das Zusammenbauen von XML-Strukturen, mit denen Informationen gespeichert werden können. Ausführlich beschrieben wird dieses Beispiel im Kochbuch (Kapitel 8), dort im Abschnitt Verzeichnisse erstellen (XML-Struktur).{{% /codecaption %}}


## Kontrollfluss

### If-then-else

In XPath kann man einfache Wenn-Dann Abfragen durchführen.
Die Syntax hierfür ist `if (Bedingung) then ... else ...`.

```xml
<PlaceObject>
  <Textblock>
    <Paragraph>
      <Value select="if (sd:odd(sd:current-page())) then 'recto' else 'verso'"/>
    </Paragraph>
  </Textblock>
</PlaceObject>
```
{{% codecaption %}}In XPath können einfache Wenn-Dann Abfragen benutzt werden.{{% /codecaption %}}

### Fallunterscheidungen

Fallunterscheidungen entsprechen der Konstruktion  `switch/case` aus C-ähnlichen Programmiersprachen.
Sie werden wie folgt im Publisher angewendet:

```xml
<Switch>
  <Case test="$i = 1">
    ...
  </Case>
  <Case test="$i = 2">
    ...
  </Case>
   ...
  <Otherwise>
    ...
  </Otherwise>
</Switch>
```

Alle Befehle innerhalb des ersten möglichen `<Case>`-Falls werden abgearbeitet, wenn die Bedingung in `test` dort zutrifft.
In `test` wird ein XPath-Ausdruck erwartet, der `true()` oder `false()` ergibt, etwa `$i = 1`.
Wenn kein Fall eintritt, so wird der Inhalt des optionalen `<Otherwise>`-Abschnittes ausgeführt.

### Schleifen

Es gibt verschiedene Schleifen im speedata Publisher.
Die einfache Variante ist `<Loop>`:

```xml
<Loop select="10">
  ...
</Loop>
```

{{% codecaption %}}Diese Schleife wird 10 Mal durchlaufen.{{% /codecaption %}}

Dieser Befehl führt die eingeschlossenen Befehle so oft aus, wie der Ausdruck in `select` ergibt.
Der Schleifenzähler ist, sofern nicht per `variable="..."` anders eingestellt, in der Variablen `_loopcounter` gespeichert.
Neben der einfachen Schleife gibt es noch Schleifen mit Bedingungen:

```xml
<Record element="data">
  <SetVariable variable="i" select="1"/>
  <While test="$i &lt;= 4">
    <PlaceObject>
      <Textblock>
        <Paragraph>
          <Value select="$i"/>
        </Paragraph>
      </Textblock>
    </PlaceObject>
    <SetVariable variable="i" select="$i + 1"/>
  </While>
</Record>
```
{{% codecaption %}}Die while-Schleife führt die eingeschlossenen Befehle aus, solange die Bedingung »wahr« ergibt. Es werden die Zahlen 1 bis 4 ausgegeben.{{% /codecaption %}}

Den Ausdruck `$i &lt;= 4` muss man als `$i <= 4` lesen, da die öffnende spitze Klammer an dieser Stelle im XML ein Syntaxfehler ist.
Die Schleife oben wird so oft ausgeführt, solange der Inhalt der Variablen i kleiner oder gleich 4 ist.
Nicht vergessen, die Variable auch zu erhöhen, sonst entsteht eine Endlosschleife.

Neben der while-Schleife gibt es noch die until-Schleife, die analog funktioniert:

```xml
<Record element="data">
  <SetVariable variable="i" select="1"/>
  <Until test="$i &lt;= 4">
    <PlaceObject>
      <Textblock>
        <Paragraph>
          <Value select="$i"/>
        </Paragraph>
      </Textblock>
    </PlaceObject>
    <SetVariable variable="i" select="$i + 1"/>
  </Until>
</Record>
```
{{% codecaption %}}Da die until-Schleife so lange ausgeführt wird, bis die Bedingung wahr ist, wird nur die Zahl 1 ausgegeben.{{% /codecaption %}}

## Funktionen

Es ist möglich, eigene Funktionen zu definieren:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en"
    xmlns:fn="mynamespace">

    <Record element="data">
        <PlaceObject>
            <Textblock>
                <Paragraph>
                    <Value select="fn:add(3,4)" />
                </Paragraph>
            </Textblock>
        </PlaceObject>
    </Record>

    <Function name="fn:add">
        <Param name="a" />
        <Param name="b" />
        <Value select="$a + $b" />
    </Function>
</Layout>
```

Die Funktionen können auch komplexere Ausdrücke enthalten:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en"
    xmlns:fn="mynamespace">

    <Record element="data">
        <Value select="fn:chapter('First chapter')" />
    </Record>

    <Function name="fn:chapter">
        <Param name="chaptername" />
        <PlaceObject>
            <Textblock>
                <Paragraph>
                    <Value select="$chaptername"/>
                </Paragraph>
            </Textblock>
        </PlaceObject>
    </Function>
</Layout>
```

Der Namensraum für die Funktion muss im Wurzelelement definiert werden (hier: `xmlns:fn="..."`). Variablen, die in der Funktion definiert werden, bleiben lokal, d.h. sind nicht in anderen Programmteilen sichtbar.

## Datenstrukturen

Der speedata Publisher unterstützt [Arrays und Maps]({{< relref "/manual/xpathref/datastructures" >}}) als native Datenstrukturen:

```xml
<!-- Array: geordnete Liste -->
<SetVariable variable="farben" select="['rot', 'grün', 'blau']"/>
<Value select="$farben?2"/>  <!-- ergibt: grün -->

<!-- Map: Schlüssel-Wert-Paare -->
<SetVariable variable="preise" select="map { 'Apfel': 1.50, 'Birne': 2.30 }"/>
<Value select="$preise?Apfel"/>  <!-- ergibt: 1.5 -->
```

Für Arrays stehen Funktionen wie `array:size()`, `array:append()` und `array:flatten()` zur Verfügung.
Für Maps gibt es `map:keys()`, `map:get()`, `map:put()` und weitere.
Alle Details und Praxisbeispiele finden sich im Kapitel [Arrays und Maps]({{< relref "/manual/xpathref/datastructures" >}}).
