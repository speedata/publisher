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

Die Anwendungsspalte bekommt `width="1*"`: Sternspalten teilen sich den Platz, der nach Abzug der festen Breiten übrig bleibt. Gibt es mehrere Sternspalten, wird im Verhältnis der Zahlen verteilt: `2*` erhält doppelt so viel wie `1*`. So entsteht die übliche Mischform: feste Breiten für alles Technische, Sternangaben für den Text.

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

## Grenzen

* **Inhaltsabhängige Breiten**: Neben festen und Sternbreiten gibt es die Schlüsselwörter `min` und `max`, die Angabe `?` (natürliche Breite) und `minwidth` als Untergrenze. Diese Feinheiten beschreibt das Handbuchkapitel [Tabellen, Abschnitt Spaltenbreiten]({{< relref "/manual/tables#angabe-der-spaltenbreiten" >}}).
* **Der Text passt trotzdem nicht**: Wird die Sternspalte zu schmal, hilft nur kürzen, kleiner setzen oder die Silbentrennung prüfen (Attribut `language`); eine Tabelle, die breiter deklariert ist als der Satzspiegel, ragt über den Rand hinaus.
* **Gleiche Spaltenflucht über Tabellen hinweg** bekommt man, indem alle Tabellen dieselbe `<Columns>`-Deklaration verwenden; bei nur einer Sternspalte sind die Breiten dann in allen Tabellen identisch.
* Referenz: [`<Columns>`]({{< relref "/reference/commands/columns" >}}) und [`<Column>`]({{< relref "/reference/commands/column" >}}).
