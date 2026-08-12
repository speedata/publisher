---
title: "Inhaltsverzeichnis"
weight: 40
type: docs
---

## Aufgabe

Der Confixa-Katalog gibt jede Artikelgruppe auf einer eigenen Seite aus. Vorn soll ein Inhaltsverzeichnis stehen: für jede Gruppe eine Zeile mit Name, Werkstoff und der Seite, auf der die Gruppe beginnt.

![Seite 1 zeigt das Verzeichnis mit den Seitenzahlen, ab Seite 2 folgt der Katalog mit einer Gruppe je Seite.](/img/howto-tableofcontents.png)

## Entscheidung

Das Grundproblem jedes Verzeichnisses: Die Seitenzahlen stehen erst fest, wenn der Katalog gesetzt ist, das Verzeichnis steht aber vorn. Der Publisher löst das mit mehreren Durchläufen: Ein Durchlauf sammelt beim Setzen die Einträge und speichert sie in eine Datei, der nächste liest die Datei beim Start und gibt das Verzeichnis aus, noch bevor der Inhalt gesetzt wird.

Für das Sammeln gibt es drei Verfahren; die Vergleichstabelle steht im Kapitel [Verzeichnisse & Listen]({{< relref "/manual/directories" >}}):

* **Marken**: `<Mark>` markiert Stellen, `sd:pagenumber()` liefert die Seitenzahl, das Speichern übernimmt der Publisher. Der einfachste Weg, wenn nur Seitenzahlen zu bekannten Namen gebraucht werden.
* **XML-Datensatz**: Die Einträge werden selbst zusammengebaut und mit `<SaveDataset>` gespeichert. Der richtige Weg, sobald das Verzeichnis mehr enthalten soll als Seitenzahlen; hier ist das der Werkstoff der Gruppe.
* **Ein Durchlauf**: `<InsertPages>` reserviert die Verzeichnisseiten vorn, `<SavePages>` füllt sie am Ende desselben Laufs. Verlangt, dass die Länge des Verzeichnisses vorab bekannt ist.

Dieses Rezept nimmt den XML-Datensatz, das flexibelste der drei Verfahren und zugleich das Muster für alle weiteren Listen (Artikellisten, Bildverzeichnisse, Register).

## Lösung

### Schritt 1: Der Katalog, eine Seite je Gruppe

Der Katalog selbst ist schnell gebaut: Jede Gruppe bekommt eine Überschrift und ihre Artikeltabelle, `<ClearPage>` beendet die Seite. Damit die Seitenzahlen im Ergebnis sichtbar sind, gibt ein Seitentyp sie im Fuß aus; die Technik dazu erklärt das Rezept [Grundgerüst eines Datenblatts]({{< relref "datasheet" >}}).

```xml
<Record element="data">
  <ProcessNode select="group"/>
</Record>

<Record element="group">
  <PlaceObject>
    <Textblock>
      <Paragraph fontfamily="title"><Value select="@name"/></Paragraph>
    </Textblock>
  </PlaceObject>
  <PlaceObject row="{sd:current-row() + 1}">
    <Table stretch="max" padding="3pt">
      <!-- Tabellenkopf und Artikelzeilen wie im ersten Tabellenrezept -->
    </Table>
  </PlaceObject>
  <ClearPage/>
</Record>
```

### Schritt 2: Beim Setzen die Einträge sammeln

Für jede Gruppe wird ein Verzeichniseintrag in der Variablen `entries` ergänzt, und zwar in dem Moment, in dem die Gruppe gesetzt wird; `sd:current-page()` liefert dann die richtige Seite. Die Befehle [`<Element>`]({{< relref "/reference/commands/element" >}}) und [`<Attribute>`]({{< relref "/reference/commands/attribute" >}}) bauen dafür eine XML-Struktur zusammen, `<Copy-of>` übernimmt jeweils die bisherigen Einträge (der Pfad `$entries/entry` statt `$entries` hält die Liste dabei flach):

```xml
<Record element="group">
  <SetVariable variable="entries">
    <Copy-of select="$entries"/>
    <Element name="entry">
      <Attribute name="name" select="@name"/>
      <Attribute name="material" select="@material"/>
      <Attribute name="page" select="sd:current-page()"/>
    </Element>
  </SetVariable>
  <!-- Ausgabe wie in Schritt 1 -->
</Record>
```

Nach der letzten Gruppe enthält `$entries` das komplette Verzeichnis als Datenstruktur:

```xml
<entry name="Chipboard screws" material="steel, zinc plated" page="2"/>
<entry name="Wall plugs" material="nylon" page="3"/>
<entry name="Wedge anchors" material="steel, zinc plated" page="4"/>
```

### Schritt 3: Speichern und wieder laden

Der Einsprungpunkt `data` bekommt drei neue Zeilen: Am Anfang initialisiert `<SetVariable>` die Variable leer (damit das erste `<Copy-of>` etwas vorfindet), am Ende schreibt [`<SaveDataset>`]({{< relref "/reference/commands/savedataset" >}}) die gesammelten Einträge unter dem Wurzelelement `tableofcontents` auf die Festplatte. [`<LoadDataset>`]({{< relref "/reference/commands/loaddataset" >}}) liest die Datei beim nächsten Durchlauf wieder ein; im ersten Durchlauf existiert sie noch nicht, dann wird der Befehl stillschweigend übergangen.

```xml
<Record element="data">
  <LoadDataset name="toc"/>
  <SetVariable variable="entries"/>
  <ProcessNode select="group"/>
  <SaveDataset name="toc" elementname="tableofcontents"
               select="$entries"/>
</Record>
```

Die Datei landet als `publisher-toc.xml` im Arbeitsverzeichnis (der Name aus `name` mit dem Jobnamen als Präfix); ein Blick hinein hilft beim Nachvollziehen und bei der Fehlersuche.

### Schritt 4: Das Verzeichnis ausgeben

`<LoadDataset>` unterbricht die Verarbeitung und sucht einen `<Record>` für das Wurzelelement der geladenen Datei, hier also `tableofcontents`. Dieser Abschnitt gibt das Verzeichnis als Tabelle aus, eine Zeile je `entry`; das abschließende `<ClearPage>` schiebt den Katalog auf Seite 2:

```xml
<Record element="tableofcontents">
  <PlaceObject>
    <Textblock>
      <Paragraph fontfamily="title"><Value>Inhalt</Value></Paragraph>
    </Textblock>
  </PlaceObject>
  <PlaceObject row="{sd:current-row() + 1}">
    <Table stretch="max" padding="3pt">
      <ForAll select="entry">
        <Tr>
          <Td><Paragraph><B><Value select="@name"/></B></Paragraph></Td>
          <Td><Paragraph><Value select="@material"/></Paragraph></Td>
          <Td align="right"><Paragraph><Value select="@page"/></Paragraph></Td>
        </Tr>
      </ForAll>
    </Table>
  </PlaceObject>
  <ClearPage/>
</Record>
```

### Schritt 5: Drei Durchläufe

Den Rest erledigt die Kommandozeile:

```
sp --runs 3
```

Warum drei? Im ersten Durchlauf gibt es noch kein Verzeichnis, der Katalog beginnt auf Seite 1 und die Einträge werden mit diesen Seitenzahlen gespeichert. Im zweiten Durchlauf kommt das Verzeichnis vorn dazu, alle Gruppen rutschen eine Seite nach hinten, die gespeicherten Seitenzahlen ändern sich also noch einmal. Erst der dritte Durchlauf gibt das Verzeichnis mit den endgültigen Zahlen aus. Im Beispiel: 3 Seiten, dann 4 Seiten mit noch falschen Verzeichniszahlen, dann 4 Seiten korrekt.

Statt auf der Kommandozeile lässt sich die Zahl auch in der Konfigurationsdatei festlegen (`runs = 3`, siehe [Konfiguration]({{< relref "/reference/configuration" >}})).

### Vollständiges Beispiel

Das lauffähige Projekt liegt auch im [Beispiele-Repository](https://github.com/speedata/examples/tree/master/manual/tableofcontents); die Datendatei ist die Confixa-Artikelliste aus dem [ersten Rezept]({{< relref "simpletable#vollständiges-beispiel" >}}).

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Pagetype name="catalog" test="true()">
    <Margin left="20mm" right="20mm" top="20mm" bottom="20mm"/>
    <AtPageShipout>
      <PlaceObject column="20mm" row="280mm" allocate="no">
        <Textblock width="17" textformat="centered">
          <Paragraph><Value select="sd:current-page()"/></Paragraph>
        </Textblock>
      </PlaceObject>
    </AtPageShipout>
  </Pagetype>

  <DefineFontfamily name="title" fontsize="18" leading="22">
    <Regular fontface="sans-bold"/>
  </DefineFontfamily>

  <Record element="data">
    <LoadDataset name="toc"/>
    <SetVariable variable="entries"/>
    <ProcessNode select="group"/>
    <SaveDataset name="toc" elementname="tableofcontents"
                 select="$entries"/>
  </Record>

  <Record element="group">
    <SetVariable variable="entries">
      <Copy-of select="$entries/entry"/>
      <Element name="entry">
        <Attribute name="name" select="@name"/>
        <Attribute name="material" select="@material"/>
        <Attribute name="page" select="sd:current-page()"/>
      </Element>
    </SetVariable>

    <PlaceObject>
      <Textblock>
        <Paragraph fontfamily="title"><Value select="@name"/></Paragraph>
      </Textblock>
    </PlaceObject>
    <PlaceObject row="{sd:current-row() + 1}">
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
        <ForAll select="article">
          <Tr>
            <Td><Paragraph><Value select="@number"/></Paragraph></Td>
            <Td><Paragraph><Value select="@dim"/></Paragraph></Td>
            <Td><Paragraph><Value select="@drive"/></Paragraph></Td>
            <Td align="right"><Paragraph><Value select="@pu"/></Paragraph></Td>
            <Td align="right"><Paragraph><Value select="@price"/></Paragraph></Td>
          </Tr>
        </ForAll>
      </Table>
    </PlaceObject>
    <ClearPage/>
  </Record>

  <Record element="tableofcontents">
    <PlaceObject>
      <Textblock>
        <Paragraph fontfamily="title"><Value>Inhalt</Value></Paragraph>
      </Textblock>
    </PlaceObject>
    <PlaceObject row="{sd:current-row() + 1}">
      <Table stretch="max" padding="3pt">
        <ForAll select="entry">
          <Tr>
            <Td><Paragraph><B><Value select="@name"/></B></Paragraph></Td>
            <Td><Paragraph><Value select="@material"/></Paragraph></Td>
            <Td align="right"><Paragraph><Value select="@page"/></Paragraph></Td>
          </Tr>
        </ForAll>
      </Table>
    </PlaceObject>
    <ClearPage/>
  </Record>
</Layout>
```

## Grenzen

* **Die Anzahl der Durchläufe ist fest.** `--runs` prüft nicht, ob sich noch etwas ändert. Wächst das Verzeichnis selbst über eine Seite oder verschieben sich Einträge durch andere dynamische Inhalte erneut, braucht es entsprechend mehr Durchläufe.
* **Ein Durchlauf statt drei**: Ist die Länge des Verzeichnisses vorab bekannt (bei Katalogen fast immer), lassen sich die Seiten vorn mit `<InsertPages>` reservieren und am Ende mit `<SavePages>` füllen; das beschreibt [Inhaltsverzeichnis in einem Durchlauf]({{< relref "/manual/directories/tocinonerun" >}}).
* **Nur Seitenzahlen gebraucht?** Dann ist das [Marken-Verfahren]({{< relref "/manual/directories/directoriesmarker" >}}) einfacher: kein Sammeln, kein Speichern, der Publisher verwaltet die Marken selbst.
* **Stichwortverzeichnisse** brauchen zusätzlich Sortierung und das Zusammenfassen von Seitenzahlen; das zeigt das Rezept [Stichwortverzeichnis]({{< relref "keywordindex" >}}).
* Referenz: [`<SaveDataset>`]({{< relref "/reference/commands/savedataset" >}}), [`<LoadDataset>`]({{< relref "/reference/commands/loaddataset" >}}), [`<Element>`]({{< relref "/reference/commands/element" >}}), [`<Attribute>`]({{< relref "/reference/commands/attribute" >}}), [`<Copy-of>`]({{< relref "/reference/commands/copy-of" >}}).
