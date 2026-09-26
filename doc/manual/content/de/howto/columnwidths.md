---
title: "Spaltenbreiten steuern"
weight: 22
type: docs
---

## Aufgabe

Die Artikelliste aus dem Rezept [Einfache Tabelle mit automatischem Umbruch]({{< relref "simpletable" >}}) bekommt eine Spalte mit Anwendungshinweisen: Fließtext neben kurzen technischen Angaben. Artikelnummer, Abmessung, VE und Preis sollen stabil und einzeilig bleiben; den übrigen Platz bekommt der Anwendungstext.

![Feste Breiten für die technischen Spalten, der Anwendungstext erhält den Rest und umbricht mehrzeilig.](/img/howto-columnwidths.png)

## Entscheidung

Ohne weitere Angaben verteilt der Publisher die Spaltenbreiten selbst anhand der Inhalte. Das reicht, solange die Inhalte kurz und gleichförmig sind; die Artikelliste im ersten Rezept kam deshalb ganz ohne Breitenangaben aus. Woran man erkennt, dass die Automatik nicht mehr trägt:

* **Eine Spalte enthält Fließtext.** Die Automatik verteilt den Platz dann zulasten der kurzen Spalten, und dort brechen Werte um, die zusammengehören.
* **Untrennbare Angaben brechen um.** Artikelnummern oder Maße wie »6.0 × 120« landen auf zwei Zeilen; auch die Spaltentitel trennen sich.
* **Bilder in Zellen** brauchen eine verlässliche Spaltenbreite, sonst hängt die Bildgröße von den Inhalten der übrigen Zeilen ab.
* **Mehrere Tabellen auf derselben Seite** sollen dieselbe Spaltenflucht haben. Die Automatik berechnet jede Tabelle für sich, die Spalten stehen dann gegeneinander versetzt.

So sieht das Fehlerbild mit automatischer Verteilung aus, gleiche Daten wie oben:

![Die Automatik quetscht die kurzen Spalten: Abmessungen und Spaltentitel brechen um.](/img/howto-columnwidths-auto.png)

## Lösung

### Schritt 1: Spalten deklarieren

Die Spaltenbreiten werden mit `<Columns>` deklariert, als erstes Element innerhalb von `<Table>`. Die stabilen Spalten bekommen feste Breiten:

```xml
<Table stretch="max" padding="3pt">
  <Columns>
    <Column width="32mm"/>
    <Column width="24mm"/>
    <Column width="1*"/>
    <Column width="10mm" align="right"/>
    <Column width="17mm" align="right"/>
  </Columns>
  ...
```

Feste Breiten lassen sich in absoluten Maßen (`32mm`) oder in Rasterzellen (Zahl ohne Einheit) angeben. Die Breite muss auch für den Spaltentitel reichen, nicht nur für die Werte; im Zweifel den längsten Kopf messen.

### Schritt 2: Der Rest per Sternangabe

Die Anwendungsspalte bekommt `width="1*"`: Sternspalten teilen sich den Platz, der nach Abzug der festen Breiten übrig bleibt. Gibt es mehrere Sternspalten, wird im Verhältnis der Zahlen verteilt: `2*` erhält doppelt so viel wie `1*`. Die Zahlen dürfen Nachkommastellen haben (`1.5*`), ein Stern allein steht für `1*`. So entsteht die übliche Mischform: feste Breiten für alles Technische, Sternangaben für den Text.

### Schritt 3: Ausrichtung an der Spalte statt an der Zelle

Das Attribut `align` kann direkt an der `<Column>` stehen; damit entfällt das `align="right"` an jeder einzelnen Zelle, das im ersten Rezept noch nötig war. Einzelne Zellen können die Spaltenvorgabe weiterhin überschreiben.

### Vollständiges Beispiel

Das lauffähige Projekt liegt auch im [Beispiele-Repository](https://github.com/speedata/examples/tree/master/manual/columnwidths). Das kleine Seitenformat dient nur der kompakten Abbildung.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Pageformat width="148mm" height="105mm"/>

  <Record element="data">
    <PlaceObject>
      <Table stretch="max" padding="3pt">
        <Columns>
          <Column width="32mm"/>
          <Column width="24mm"/>
          <Column width="1*"/>
          <Column width="10mm" align="right"/>
          <Column width="17mm" align="right"/>
        </Columns>
        <Tablehead>
          <Tr background-color="lightgray">
            <Td><Paragraph><B><Value>Artikelnummer</Value></B></Paragraph></Td>
            <Td><Paragraph><B><Value>Abmessung</Value></B></Paragraph></Td>
            <Td><Paragraph><B><Value>Anwendung</Value></B></Paragraph></Td>
            <Td><Paragraph><B><Value>VE</Value></B></Paragraph></Td>
            <Td><Paragraph><B><Value>Preis in €</Value></B></Paragraph></Td>
          </Tr>
        </Tablehead>
        <ForAll select="group/article">
          <Tr>
            <Td><Paragraph><Value select="@number"/></Paragraph></Td>
            <Td><Paragraph><Value select="@dim"/></Paragraph></Td>
            <Td><Paragraph><Value select="@application"/></Paragraph></Td>
            <Td><Paragraph><Value select="@pu"/></Paragraph></Td>
            <Td><Paragraph><Value select="@price"/></Paragraph></Td>
          </Tr>
        </ForAll>
      </Table>
    </PlaceObject>
  </Record>
</Layout>
```

Die Daten sind ein Ausschnitt aus dem Confixa-Bestand; neu ist das Attribut `application` mit dem Anwendungshinweis:

```xml
<data company="Confixa">
  <group name="Chipboard screws" code="CS" material="steel, zinc plated">
    <article number="CS-3012" dim="3.0 × 12" drive="TX10" pu="1000" price="4.90"
             application="Fine work in chipboard and MDF"/>
    <article number="CS-4030" dim="4.0 × 30" drive="TX20" pu="500" price="4.90"
             application="Universal screw for wood and chipboard, no pre-drilling required"/>
    <article number="CS-4050" dim="4.0 × 50" drive="TX20" pu="500" price="6.70"
             application="Universal screw for wood and chipboard, no pre-drilling required"/>
    <article number="CS-5070" dim="5.0 × 70" drive="TX25" pu="200" price="5.90"
             application="Load-bearing timber connections, pre-drill in hardwood"/>
    <article number="CS-6080" dim="6.0 × 80" drive="TX30" pu="100" price="5.00"
             application="Heavy-duty connections in solid timber"/>
    <article number="CS-60120" dim="6.0 × 120" drive="TX30" pu="100" price="7.30"
             application="Heavy-duty connections, requires pre-drilling near edges"/>
  </group>
</data>
```

## Variante: Anteile in Prozent

Statt in absoluten Maßen lassen sich Spalten auch als Anteil der Tabellenbreite angeben. Das ist praktisch, wenn dieselbe Tabelle in verschiedenen Breiten vorkommt, etwa einspaltig und zweispaltig, und die Proportionen erhalten bleiben sollen:

```xml
<Columns>
  <Column width="22%"/>
  <Column width="16%"/>
  <Column width="*"/>
  <Column width="7%" align="right"/>
  <Column width="12%" align="right"/>
</Columns>
```

Die Prozentangaben beziehen sich auf die Tabellenbreite ohne die Spaltenabstände (`columndistance`); die Sternspalte erhält wie bisher den Rest, hier 43 %. Prozent, feste Breiten und Sterne lassen sich beliebig mischen. Allerdings schrumpfen prozentuale Spalten mit der Tabelle: Für Werte, die nicht umbrechen dürfen, sind feste Breiten die sicherere Wahl.

## Variante: Breite nach Inhalt

Feste Breiten müssen ausgemessen werden und passen nur, solange die Daten es tun. Soll sich eine Spalte nach ihrem Inhalt richten, gibt es die Schlüsselwörter `max` und `min` und das Attribut `minwidth`:

* `max`: Die Spalte wird so breit wie ihr Inhalt ohne Umbruch (die natürliche Breite). Reicht der Platz nicht, wird sie schmaler, aber nie schmaler als ihr breitestes Wort.
* `min`: Die Spalte wird so schmal wie ihr breitestes Wort, der Text bricht so oft wie möglich um.
* `minwidth`: eine Untergrenze für die Spaltenbreite, zum Beispiel damit eine Spalte mit kurzen Werten nicht zu eng wirkt.

`min` und `max` lassen sich mit festen Breiten, Prozent- und Sternangaben kombinieren, die Sternspalten erhalten den Rest:

```xml
<Columns>
  <Column width="max"/>
  <Column width="max" minwidth="20mm"/>
  <Column width="*"/>
  <Column width="max" align="right"/>
  <Column width="max" align="right"/>
</Columns>
```

Für die Artikelliste ist das eine Alternative zu den ausgemessenen Breiten aus Schritt 1: Artikelnummer, Abmessung, VE und Preis werden genau so breit wie nötig, der Anwendungstext erhält den Rest. Der Preis dafür: Die Breiten hängen von den Daten ab, zwei Tabellen mit denselben `<Columns>` haben keine gemeinsame Spaltenflucht mehr.

Eine weitere Möglichkeit ist `?`. Solche Spalten werden wie bei einer Tabelle ohne `<Columns>` aus ihrem Inhalt berechnet, während die übrigen Spalten ihre feste Breite behalten. Mit `stretch="max"` teilen sich die `?`-Spalten den Platz, der nach den festen Breiten übrig bleibt, im Verhältnis ihrer natürlichen Breiten:

```xml
<Table stretch="max">
  <Columns>
    <Column width="32mm"/>
    <Column width="?"/>
    <Column width="?"/>
  </Columns>
  ...
```

Ohne `stretch="max"` erhalten die `?`-Spalten ihre natürliche Breite, die Tabelle kann dann schmaler sein als vorgegeben. Stehen in derselben Tabelle Stern-, `min`- oder `max`-Spalten, verhält sich `?` wie `max`. Eine `<Column>` ohne `width`, etwa nur mit `align`, gilt als `?`.

## Alle Breitenangaben im Überblick

| Angabe | Beispiel | Wirkung |
| --- | --- | --- |
| Länge | `32mm`, `1.5cm`, `40pt`, `8em` | feste Breite; `em` bezieht sich auf die Schriftgröße der Tabelle |
| Zahl | `4`, `2.5` | feste Breite in Rasterzellen (siehe `<SetGrid>`) |
| Prozent | `25%` | fester Anteil der Tabellenbreite ohne die Spaltenabstände |
| Stern | `1*`, `2.5*`, `*` | Anteil am Platz, der nach allen anderen Spalten übrig bleibt |
| `max` | | natürliche Breite des Inhalts, bei Platzmangel schmaler, aber nicht schmaler als das breiteste Wort |
| `min` | | Breite des breitesten Worts |
| `?` | | natürliche Breite des Inhalts; mit `stretch="max"` Anteil am Restplatz im Verhältnis der natürlichen Breiten |
| `minwidth` | `minwidth="20mm"` | eigenes Attribut: Untergrenze für jede Spaltenbreite |

Dazu gelten ein paar Regeln:

* **Tabellenbreite**: Prozent- und Sternangaben beziehen sich auf die Breite der Tabelle. Sie wird mit `width` an `<Table>` angegeben, als Länge oder in Rasterzellen; ohne Angabe ist es die verfügbare Breite.
* **Nur feste Breiten**: Enthalten die `<Columns>` nur Längen, Rasterzellen und Prozentangaben, ist die Tabelle genau so breit wie deren Summe, auch mit `stretch="max"`.
* **Ohne `<Columns>`** berechnet der Publisher die Breiten aus den Inhalten; `stretch="max"` dehnt die Tabelle dann auf die volle Breite.
* **Eine `<Column>` ohne `width`** wird wie `?` aus ihrem Inhalt berechnet.
* **`minwidth`** gilt für alle Angaben: Eine feste Breite wird auf `minwidth` angehoben, bei Sternspalten wird der übrige Platz unter den anderen Sternspalten verteilt.

## Grenzen

* **Der Text passt trotzdem nicht**: Wird die Sternspalte zu schmal, hilft nur kürzen, kleiner setzen oder die Silbentrennung prüfen (Attribut `language`); eine Tabelle, die breiter deklariert ist als der Satzspiegel, ragt über den Rand hinaus.
* **Gleiche Spaltenflucht über Tabellen hinweg** bekommt man, indem alle Tabellen dieselbe `<Columns>`-Deklaration verwenden; bei nur einer Sternspalte sind die Breiten dann in allen Tabellen identisch. Bei gleicher Tabellenbreite gilt das auch für Prozentangaben.
* Weitere Beispiele mit Abbildungen enthält das Handbuchkapitel [Tabellen, Abschnitt Spaltenbreiten]({{< relref "/manual/tables#angabe-der-spaltenbreiten" >}}).
* Ein Beispiel mit allen Breitenangaben (Prozent, Sterne, `min`, `max`, `minwidth` und `?`) liegt im [Beispiele-Repository](https://github.com/speedata/examples/tree/master/technical/columnwidths).
* Referenz: [`<Columns>`]({{< relref "/reference/commands/columns" >}}) und [`<Column>`]({{< relref "/reference/commands/column" >}}).
