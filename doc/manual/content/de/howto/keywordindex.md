---
title: "Stichwortverzeichnis"
weight: 41
type: docs
---

## Aufgabe

Der Confixa-Katalog aus dem Rezept [Inhaltsverzeichnis]({{< relref "tableofcontents" >}}) bekommt hinten ein Register: Für jeden Untergrund (Holz, Beton, Mauerwerk, …) steht dort, auf welchen Seiten passende Artikel zu finden sind. Die Stichwörter sind alphabetisch sortiert und nach Anfangsbuchstaben gruppiert, mehrfach vorkommende Seitenzahlen werden zusammengefasst.

![Die Katalogseiten nennen je Artikel den Untergrund, das Register am Ende führt zu den Seiten.](/img/howto-keywordindex.png)

## Entscheidung

Vom Inhaltsverzeichnis unterscheidet sich das Stichwortverzeichnis in zwei Punkten, und beide vereinfachen oder verändern den Weg:

* **Es steht hinten.** Wenn das Register gesetzt wird, sind alle Katalogseiten bereits fertig; die gesammelten Seitenzahlen sind vollständig. Das Speichern und Wiederladen über mehrere Durchläufe ([`<SaveDataset>`]({{< relref "/reference/commands/savedataset" >}})/[`<LoadDataset>`]({{< relref "/reference/commands/loaddataset" >}})) entfällt, ein einziger Durchlauf reicht.
* **Die Einträge kommen nicht in Dokumentreihenfolge.** Ein Register muss sortiert, nach Anfangsbuchstaben gruppiert und von Doppelnennungen befreit werden. Dafür gibt es [`<Makeindex>`]({{< relref "/reference/commands/makeindex" >}}), das sortiert, gruppiert und die Seitenzahlen gleicher Stichwörter aneinanderhängt, sowie die Funktion `sd:merge-pagenumbers()`, die solche Seitenzahllisten aufräumt.

Wer nur sortieren will, ohne Abschnitte und Seitenzahlen, nimmt stattdessen `<SortSequence>`; beide Befehle stellt das Kapitel [Sortieren und Gruppieren]({{< relref "/manual/directories/indexcreation" >}}) gegenüber.

## Lösung

### Schritt 1: Beim Setzen die Einträge sammeln

Wie beim Inhaltsverzeichnis wird beim Setzen des Katalogs eine Variable mit Einträgen gefüllt, hier ein Eintrag je Artikel mit dem Untergrund und der aktuellen Seite. Das Sammeln übernimmt ein eigener Abschnitt für das Element `article`, den der Katalogabschnitt vor der Ausgabe der Tabelle aufruft:

```xml
<Record element="group">
  <ProcessNode select="article"/>
  <!-- danach Überschrift und Tabelle wie im Rezept Inhaltsverzeichnis -->
</Record>

<Record element="article">
  <SetVariable variable="indexentries">
    <Copy-of select="$indexentries/indexentry"/>
    <Element name="indexentry">
      <Attribute name="name" select="@base"/>
      <Attribute name="page" select="sd:current-page()"/>
    </Element>
  </SetVariable>
</Record>
```

Zwei Details sind hier wichtig:

* **Das Stichwort muss im Attribut `name` stehen**; `<Makeindex>` erwartet diesen Namen beim Zusammenfassen gleicher Einträge.
* **`<Copy-of>` übernimmt die bisherigen Einträge über den Pfad `$indexentries/indexentry`**, nicht über `$indexentries` allein. Der Pfad hält die Liste flach; mit `$indexentries` entsteht bei jedem Schritt eine tiefer geschachtelte Struktur, aus der `<Makeindex>` später nur den letzten Eintrag herausliest.

Das Sammeln könnte statt über den eigenen Abschnitt auch direkt in einem `<ForAll select="article">` im Katalogabschnitt stehen; der eigene `<Record>` hält hier lediglich Sammeln und Ausgabe getrennt.

### Schritt 2: Sortieren und Gruppieren mit Makeindex

Nach dem Katalog enthält `$indexentries` einen Eintrag je Artikel, in Dokumentreihenfolge und voller Wiederholungen. `<Makeindex>` macht daraus die fertige Registerstruktur:

```xml
<Record element="data">
  <SetVariable variable="indexentries"/>
  <ProcessNode select="group"/>

  <SetVariable variable="index">
    <Element name="baseindex">
      <Makeindex select="$indexentries/indexentry" sortkey="name"
                 section="section" pagenumber="page"/>
    </Element>
  </SetVariable>
  <ProcessNode select="$index/baseindex"/>
</Record>
```

Sortiert wird nach dem Attribut aus `sortkey`, für jeden Anfangsbuchstaben entsteht ein Element mit dem Namen aus `section`, und die Seitenzahlen gleichnamiger Einträge werden im Attribut aus `pagenumber` aneinandergehängt. Das Ergebnis sieht so aus:

```xml
<baseindex>
  <section name="C">
    <indexentry name="chipboard" page="1, 1, 1, 1, 1, 1, 1"/>
    <indexentry name="concrete" page="2, 3, 3, 3, 3, 3, 3, 3, 3"/>
  </section>
  <section name="D">
    <indexentry name="drywall" page="2, 2"/>
  </section>
  <!-- weitere Abschnitte -->
</baseindex>
```

Das abschließende `<ProcessNode>` interpretiert die Variable als Datenstruktur und springt in den Abschnitt für `baseindex`, der das Register ausgibt.

### Schritt 3: Ausgeben und Seitenzahlen zusammenfassen

Die Ausgabe sind zwei verschachtelte `<ForAll>`: außen die Abschnitte, innen die Einträge. Die aufgesammelten Seitenzahllisten räumt `sd:merge-pagenumbers()` auf: Die Funktion sortiert, entfernt Doppelnennungen und fasst ab drei aufeinanderfolgenden Seiten zu Bereichen zusammen; aus `2, 3, 3, 3` wird `2, 3`, aus `4, 5, 6` wird `4–6`.

```xml
<Record element="baseindex">
  <PlaceObject>
    <Textblock>
      <Paragraph fontfamily="title"><Value>Register</Value></Paragraph>
    </Textblock>
  </PlaceObject>
  <PlaceObject row="{sd:current-row() + 1}">
    <Table padding="3pt">
      <Columns>
        <Column width="6cm"/>
        <Column width="3cm"/>
      </Columns>
      <ForAll select="section">
        <Tr break-below="no" top-distance="8pt">
          <Td colspan="2" border-bottom="1pt">
            <Paragraph><B><Value select="@name"/></B></Paragraph>
          </Td>
        </Tr>
        <ForAll select="indexentry">
          <Tr>
            <Td><Paragraph><Value select="@name"/></Paragraph></Td>
            <Td align="right">
              <Paragraph><Value select="sd:merge-pagenumbers(@page)"/></Paragraph>
            </Td>
          </Tr>
        </ForAll>
      </ForAll>
    </Table>
  </PlaceObject>
</Record>
```

Da das Register schmal ist, bekommt die Tabelle hier feste Spaltenbreiten statt `stretch="max"`; die Möglichkeiten zeigt das Rezept [Spaltenbreiten steuern]({{< relref "columnwidths" >}}).

### Vollständiges Beispiel

Das lauffähige Projekt liegt auch im [Beispiele-Repository](https://github.com/speedata/examples/tree/master/manual/keywordindex). Die Daten sind die Confixa-Artikelliste aus dem [ersten Rezept]({{< relref "simpletable#vollständiges-beispiel" >}}), ergänzt um das Attribut `base` mit dem Untergrund; die Katalogtabelle zeigt es in einer eigenen Spalte:

```xml
<data company="Confixa">
  <group name="Chipboard screws" code="CS" material="steel, zinc plated">
    <article number="CS-3012" dim="3.0 × 12" drive="TX10" pu="1000"
             price="4.90" base="chipboard"/>
    <!-- weitere Artikel: base="chipboard" oder base="wood" -->
  </group>
  <group name="Wall plugs" code="WP" material="nylon">
    <article number="WP-0525" dim="5 × 25" pu="100"
             price="2.10" base="drywall"/>
    <!-- weitere Artikel: base="drywall", "masonry" oder "concrete" -->
  </group>
  <group name="Wedge anchors" code="WA" material="steel, zinc plated">
    <article number="WA-0875" dim="M8 × 75" pu="50"
             price="12.40" base="concrete"/>
    <!-- weitere Artikel: base="concrete" -->
  </group>
</data>
```

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
    <SetVariable variable="indexentries"/>
    <ProcessNode select="group"/>

    <SetVariable variable="index">
      <Element name="baseindex">
        <Makeindex select="$indexentries/indexentry" sortkey="name"
                   section="section" pagenumber="page"/>
      </Element>
    </SetVariable>
    <ProcessNode select="$index/baseindex"/>
  </Record>

  <Record element="group">
    <ProcessNode select="article"/>

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
            <Td><Paragraph><B><Value>Untergrund</Value></B></Paragraph></Td>
            <Td align="right"><Paragraph><B><Value>VE</Value></B></Paragraph></Td>
            <Td align="right"><Paragraph><B><Value>Preis in €</Value></B></Paragraph></Td>
          </Tr>
        </Tablehead>
        <ForAll select="article">
          <Tr>
            <Td><Paragraph><Value select="@number"/></Paragraph></Td>
            <Td><Paragraph><Value select="@dim"/></Paragraph></Td>
            <Td><Paragraph><Value select="@base"/></Paragraph></Td>
            <Td align="right"><Paragraph><Value select="@pu"/></Paragraph></Td>
            <Td align="right"><Paragraph><Value select="@price"/></Paragraph></Td>
          </Tr>
        </ForAll>
      </Table>
    </PlaceObject>
    <ClearPage/>
  </Record>

  <Record element="article">
    <SetVariable variable="indexentries">
      <Copy-of select="$indexentries/indexentry"/>
      <Element name="indexentry">
        <Attribute name="name" select="@base"/>
        <Attribute name="page" select="sd:current-page()"/>
      </Element>
    </SetVariable>
  </Record>

  <Record element="baseindex">
    <PlaceObject>
      <Textblock>
        <Paragraph fontfamily="title"><Value>Register</Value></Paragraph>
      </Textblock>
    </PlaceObject>
    <PlaceObject row="{sd:current-row() + 1}">
      <Table padding="3pt">
        <Columns>
          <Column width="6cm"/>
          <Column width="3cm"/>
        </Columns>
        <ForAll select="section">
          <Tr break-below="no" top-distance="8pt">
            <Td colspan="2" border-bottom="1pt">
              <Paragraph><B><Value select="@name"/></B></Paragraph>
            </Td>
          </Tr>
          <ForAll select="indexentry">
            <Tr>
              <Td><Paragraph><Value select="@name"/></Paragraph></Td>
              <Td align="right">
                <Paragraph><Value select="sd:merge-pagenumbers(@page)"/></Paragraph>
              </Td>
            </Tr>
          </ForAll>
        </ForAll>
      </Table>
    </PlaceObject>
  </Record>
</Layout>
```

## Grenzen

* **Umbrechende Inhalte.** `sd:current-page()` wird beim Aufbau der Tabelle ausgewertet, nicht beim Seitenumbruch. Hier stimmen die Seitenzahlen, weil jede Gruppe mit `<ClearPage>` auf ihrer eigenen Seite steht. Umbricht die Tabelle dagegen automatisch über Seiten, bekommen die Artikel der Folgeseiten die falsche Zahl. Dann sammelt man mit Marken statt mit einer Variablen: `<Mark append="yes">` wird beim Ausliefern der Seite ausgewertet, `sd:pagenumber()` liefert die Seitenliste und `sd:merge-pagenumbers()` fasst sie genauso zusammen; siehe [Marken]({{< relref "/manual/directories/directoriesmarker" >}}).
* **Einfache Sortierung.** `<Makeindex>` sortiert und gruppiert nach dem Anfangszeichen ohne Sprachregeln: Stichwörter mit Umlauten landen hinter »Z« und bilden keinen brauchbaren Abschnittsbuchstaben. Für deutschsprachige Register die Stichwörter in den Daten normalisieren oder die Daten vorab sortieren; die Wege dahin zeigt [Datenaufbereitung]({{< relref "datapreparation" >}}).
* **Nur eine Ebene.** Zweistufige Register (Haupt- und Untereinträge) kann `<Makeindex>` nicht; dafür baut man die Struktur selbst auf oder bereitet sie vorab mit XSLT auf.
* Referenz: [`<Makeindex>`]({{< relref "/reference/commands/makeindex" >}}), [`<SortSequence>`]({{< relref "/reference/commands/sortsequence" >}}), `sd:merge-pagenumbers()` und `sd:pagenumber()` in den [Layoutfunktionen]({{< relref "/reference/xpath/layoutfunctions" >}}).
