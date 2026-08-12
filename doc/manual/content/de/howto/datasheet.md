---
title: "Grundgerüst eines Datenblatts"
weight: 30
type: docs
---

## Aufgabe

Ein wiederverwendbares Seitengerüst für Datenblätter und Preislisten: Jede Seite trägt oben Firmenname, Dokumenttitel und eine Linie, unten eine Linie mit Adresszeile und Seitenzahl, alles mit exakten Abständen. Dazwischen liegt der Satzspiegel, in den die Inhalte fließen; als Inhalt dient hier die Artikelliste aus dem [ersten Tabellenrezept]({{< relref "simpletable" >}}).

![Kopf und Fuß erscheinen millimetergenau auf jeder Seite, die Tabelle fließt in den Satzspiegel und umbricht automatisch.](/img/howto-datasheet.png)

## Entscheidung

Drei Fragen bestimmen den Aufbau des Gerüsts:

* **Wo werden Kopf und Fuß definiert?** Im Seitentyp (`<Pagetype>`), nicht in der Datenverarbeitung: `<AtPageCreation>` läuft beim Anlegen der Seite (gut für den Kopf), `<AtPageShipout>` beim Schreiben der fertigen Seite in die PDF-Datei (gut für den Fuß, denn hier stimmt `sd:current-page()` für jede Seite). So bekommt jede Seite ihr Gerüst automatisch, egal wie viele Seiten der Inhalt erzeugt.
* **Raster oder Millimeter?** `<PlaceObject>` versteht bei `row` und `column` beides: Eine Zahl bedeutet Rasterzelle, eine Maßangabe den Abstand von der Blattkante. Faustregel: Was zum Seitendesign gehört (Kopf, Fuß, Linien), wird millimetergenau absolut platziert; was sich am Inhalt orientiert (die Tabelle), läuft über das Raster. Ein fein eingestelltes Raster (hier 3 mm) hält auch die Rasterplätze nah an den Designmaßen.
* **Wie bleibt der Inhalt aus Kopf und Fuß heraus?** Der Satzspiegel wird als Platzierungsbereich definiert. Inhalte werden mit `area="text"` ausgegeben und können dann nicht in die Kopf- und Fußzonen laufen.

## Lösung

### Schritt 1: Feines Raster und Seitentyp

```xml
<SetGrid height="3mm" width="3mm"/>

<Pagetype name="datasheet" test="true()">
  <Margin left="15mm" right="15mm" top="15mm" bottom="15mm"/>
  ...
</Pagetype>
```

Die Bedingung `test="true()"` wählt diesen Seitentyp für alle Seiten aus. Die Ränder von 15 mm ergeben mit dem 3-mm-Raster glatte 60 Spalten und 89 Zeilen; krumme Verhältnisse zwischen Satzspiegel und Rasterweite führen zu angeschnittenen Zellen am Rand.

### Schritt 2: Der Satzspiegel als Platzierungsbereich

```xml
<PositioningArea name="text">
  <PositioningFrame width="{sd:number-of-columns()}"
    height="{sd:number-of-rows() - 4}" row="4" column="1"/>
</PositioningArea>
```

Der Bereich `text` beginnt in Rasterzeile 4 (unterhalb der Kopfzone) und endet vier Zeilen vor dem unteren Rand, so bleibt Platz für den Fuß. Die Größe ist über `sd:number-of-rows()`/`sd:number-of-columns()` relativ ausgedrückt und passt sich damit an, wenn Ränder oder Raster geändert werden.

### Schritt 3: Der Kopf mit exakten Abständen

```xml
<AtPageCreation>
  <PlaceObject column="15mm" row="12mm" allocate="no">
    <Textblock width="60">
      <Paragraph fontfamily="head"><Value>Confixa</Value></Paragraph>
    </Textblock>
  </PlaceObject>
  <PlaceObject column="15mm" row="12mm" allocate="no">
    <Textblock width="60" textformat="right">
      <Paragraph><Value>Preisliste Verbindungstechnik</Value></Paragraph>
    </Textblock>
  </PlaceObject>
  <PlaceObject column="15mm" row="19mm" allocate="no">
    <Rule direction="horizontal" length="180mm" rulewidth="0.5pt"/>
  </PlaceObject>
</AtPageCreation>
```

Die Maßangaben bei `row` und `column` messen von der oberen bzw. linken Blattkante: Der Kopf beginnt exakt 12 mm von oben, die Linie liegt bei 19 mm. `allocate="no"` sorgt dafür, dass diese Ausgaben keine Rasterzellen belegen. Firmenname und Dokumenttitel stehen auf derselben Höhe; der Titel wird über das vordefinierte Textformat `right` an den rechten Rand gestellt (der `<Textblock>` ist dafür 60 Rasterzellen, also 180 mm breit).

### Schritt 4: Der Fuß mit Seitenzahl

```xml
<AtPageShipout>
  <PlaceObject column="15mm" row="283mm" allocate="no">
    <Rule direction="horizontal" length="180mm" rulewidth="0.25pt"/>
  </PlaceObject>
  <PlaceObject column="15mm" row="285mm" allocate="no">
    <Textblock width="60">
      <Paragraph><Value>Confixa GmbH · Musterstraße 1 · 12345 Musterstadt</Value></Paragraph>
    </Textblock>
  </PlaceObject>
  <PlaceObject column="15mm" row="285mm" allocate="no">
    <Textblock width="60" textformat="right">
      <Paragraph>
        <Value>Seite </Value>
        <Value select="sd:current-page()"/>
      </Paragraph>
    </Textblock>
  </PlaceObject>
</AtPageShipout>
```

Weil `<AtPageShipout>` erst beim Schreiben der Seite ausgeführt wird, liefert `sd:current-page()` hier auf jeder Seite die richtige Zahl. Das ist der Gegenpol zur Grenze aus dem Rezept [Fortsetzungskopf]({{< relref "continuationhead" >}}): Tabellenköpfe und -füße werden beim Tabellenaufbau ausgewertet, Seitenköpfe und -füße je Seite.

### Schritt 5: Inhalte in den Satzspiegel

```xml
<Record element="data">
  <PlaceObject area="text">
    <Table stretch="max" padding="3pt">
      <!-- Tabelle wie im Rezept »Einfache Tabelle mit automatischem Umbruch« -->
    </Table>
  </PlaceObject>
</Record>
```

Mit `area="text"` landet die Tabelle im Satzspiegel: Sie nutzt dessen Breite, umbricht an dessen Unterkante, und jede neue Seite bekommt automatisch Kopf und Fuß aus dem Seitentyp. Das Gerüst und die Tabellenrezepte greifen so ohne weitere Anpassung ineinander.

### Vollständiges Beispiel

Das lauffähige Projekt liegt auch im [Beispiele-Repository](https://github.com/speedata/examples/tree/master/manual/datasheet); die Datendatei ist die Confixa-Artikelliste aus dem [ersten Rezept]({{< relref "simpletable#vollständiges-beispiel" >}}).

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <SetGrid height="3mm" width="3mm"/>

  <Pagetype name="datasheet" test="true()">
    <Margin left="15mm" right="15mm" top="15mm" bottom="15mm"/>

    <PositioningArea name="text">
      <PositioningFrame width="{sd:number-of-columns()}"
        height="{sd:number-of-rows() - 4}" row="4" column="1"/>
    </PositioningArea>

    <AtPageCreation>
      <PlaceObject column="15mm" row="12mm" allocate="no">
        <Textblock width="60">
          <Paragraph fontfamily="head"><Value>Confixa</Value></Paragraph>
        </Textblock>
      </PlaceObject>
      <PlaceObject column="15mm" row="12mm" allocate="no">
        <Textblock width="60" textformat="right">
          <Paragraph><Value>Preisliste Verbindungstechnik</Value></Paragraph>
        </Textblock>
      </PlaceObject>
      <PlaceObject column="15mm" row="19mm" allocate="no">
        <Rule direction="horizontal" length="180mm" rulewidth="0.5pt"/>
      </PlaceObject>
    </AtPageCreation>

    <AtPageShipout>
      <PlaceObject column="15mm" row="283mm" allocate="no">
        <Rule direction="horizontal" length="180mm" rulewidth="0.25pt"/>
      </PlaceObject>
      <PlaceObject column="15mm" row="285mm" allocate="no">
        <Textblock width="60">
          <Paragraph><Value>Confixa GmbH · Musterstraße 1 · 12345 Musterstadt</Value></Paragraph>
        </Textblock>
      </PlaceObject>
      <PlaceObject column="15mm" row="285mm" allocate="no">
        <Textblock width="60" textformat="right">
          <Paragraph>
            <Value>Seite </Value>
            <Value select="sd:current-page()"/>
          </Paragraph>
        </Textblock>
      </PlaceObject>
    </AtPageShipout>
  </Pagetype>

  <DefineFontfamily name="head" fontsize="14" leading="16">
    <Regular fontface="sans-bold"/>
  </DefineFontfamily>

  <Record element="data">
    <PlaceObject area="text">
      <Table stretch="max" padding="3pt">
        <Tablehead>
          <Tr background-color="lightgray">
            <Td><Paragraph><B><Value>Artikelnummer</Value></B></Paragraph></Td>
            <Td><Paragraph><B><Value>Abmessung</Value></B></Paragraph></Td>
            <Td><Paragraph><B><Value>Antrieb</Value></B></Paragraph></Td>
            <Td align="right"><Paragraph><B><Value>VE</Value></B></Paragraph></Td>
            <Td align="right"><Paragraph><B><Value>Preis in €</Value></B></Paragraph></Td>
          </Tr>
        </Tablehead>
        <Tablefoot>
          <Tablerule rulewidth="0.5pt"/>
          <Tr>
            <Td colspan="5" align="right">
              <Paragraph><Value>Preise netto je VE</Value></Paragraph>
            </Td>
          </Tr>
        </Tablefoot>
        <ForAll select="group">
          <Tr top-distance="8pt" break-below="no">
            <Td colspan="5" border-bottom="1pt">
              <Paragraph><B><Value select="@name"/></B></Paragraph>
            </Td>
          </Tr>
          <ForAll select="article">
            <Tr>
              <Td><Paragraph><Value select="@number"/></Paragraph></Td>
              <Td><Paragraph><Value select="@dim"/></Paragraph></Td>
              <Td><Paragraph><Value select="@drive"/></Paragraph></Td>
              <Td align="right"><Paragraph><Value select="@pu"/></Paragraph></Td>
              <Td align="right"><Paragraph><Value select="@price"/></Paragraph></Td>
            </Tr>
          </ForAll>
        </ForAll>
      </Table>
    </PlaceObject>
  </Record>
</Layout>
```

## Grenzen

* **Linke und rechte Seiten**: Sollen Ränder oder die Position der Seitenzahl zwischen linken und rechten Seiten wechseln, definiert man mehrere Seitentypen mit Bedingungen wie `sd:even(sd:current-page())`; die Auswahllogik beschreibt das Kapitel [Seitentypen]({{< relref "pagetypes" >}}).
* **Mehrspaltiger Satzspiegel**: Ein Bereich darf aus mehreren `<PositioningFrame>` bestehen; Text über `<Output>` fließt dann von Rahmen zu Rahmen, siehe [Platzierungsbereiche]({{< relref "/manual/basics/positioningframe" >}}).
* **Druckvorstufe**: Beschnittzugabe und Schnittmarken für das Gerüst behandelt das Kapitel [Druckvorstufe]({{< relref "cutmarks" >}}), Griffmarken am Seitenrand das Kapitel [Griffmarken]({{< relref "thumbindex" >}}).
* Referenz: [`<Pagetype>`]({{< relref "/reference/commands/pagetype" >}}), [`<AtPageCreation>`]({{< relref "/reference/commands/atpagecreation" >}}), [`<AtPageShipout>`]({{< relref "/reference/commands/atpageshipout" >}}), [`<PositioningFrame>`]({{< relref "/reference/commands/positioningframe" >}}).
