---
title: "Einfache Tabelle mit automatischem Umbruch"
weight: 20
type: docs
---

## Aufgabe

Eine Artikelliste soll als Preisliste ausgegeben werden. Die Liste ist länger als eine Seite: Der Publisher soll den Seitenumbruch selbst finden, der Tabellenkopf soll sich auf jeder Seite wiederholen, und unter der Tabelle steht eine Schlusszeile.

![Die Artikelliste läuft über zwei Seiten, der graue Tabellenkopf wiederholt sich auf der zweiten Seite.](/img/howto-simpletable.png)

## Entscheidung

Der automatische Tabellenumbruch ist der richtige Weg, wenn drei Dinge zusammenkommen:

* **Die Zeilen sind gleichförmig.** Jede Zeile hat dieselben Spalten, und die Inhalte sollen über alle Datensätze hinweg aneinander ausgerichtet sein.
* **Der Umbruchpunkt ist egal.** Es spielt keine Rolle, welcher Artikel als letzter auf eine Seite passt; die Tabelle darf auch mitten in einer Artikelgruppe umbrechen.
* **Folgeseiten brauchen keine Sonderbehandlung.** Der wiederholte Kopf und Fuß reichen aus.

Trifft eine der Bedingungen nicht zu, führt der Weg woanders hin: Bei festem Seitendesign, in das sich der Inhalt fügen muss, arbeitet man mit [Gruppen]({{< relref "/manual/pagelayout/groups" >}}) und absoluter Positionierung. Fließtext gehört in `<Output>`/`<Text>` statt in eine Tabelle. Und wenn Fortsetzungsseiten eigene Logik brauchen, muss man die Tabelle selbst portionieren (siehe [Grenzen](#grenzen)).

## Lösung

### Die Daten

Alle Anleitungen verwenden die Artikeldaten des fiktiven Herstellers Confixa: Artikelgruppen (`group`) enthalten Artikel (`article`) mit Artikelnummer, Abmessung, Antrieb, Verpackungseinheit (`pu`) und Preis je Einheit. Hier ein Ausschnitt, die vollständige Datei steht im Abschnitt [Vollständiges Beispiel](#vollständiges-beispiel):

```xml
<data company="Confixa">
  <group name="Chipboard screws" code="CS" material="steel, zinc plated">
    <article number="CS-3012" dim="3.0 × 12" drive="TX10" pu="1000" price="4.90"/>
    <article number="CS-3016" dim="3.0 × 16" drive="TX10" pu="1000" price="5.20"/>
    <!-- weitere Artikel -->
  </group>
  <group name="Wall plugs" code="WP" material="nylon">
    <article number="WP-0525" dim="5 × 25" pu="100" price="2.10"/>
    <!-- weitere Artikel -->
  </group>
  <!-- weitere Gruppen -->
</data>
```

### Schritt 1: Tabelle im Grundgerüst

Der Einsprungpunkt `data` gibt die Tabelle mit `<PlaceObject>` aus. Mehr braucht es für den Umbruch nicht: Ist die Tabelle länger als der Platz auf der Seite, verteilt der Publisher die Zeilen von sich aus auf Folgeseiten.

```xml
<Record element="data">
  <PlaceObject>
    <Table stretch="max" padding="3pt">
      <!-- Kopf, Fuß und Zeilen folgen in den nächsten Schritten -->
    </Table>
  </PlaceObject>
</Record>
```

`stretch="max"` zieht die Tabelle auf die volle Breite des Satzspiegels, `padding` gibt allen Zellen etwas Innenabstand. Die Spaltenbreiten verteilt der Publisher automatisch anhand der Inhalte.

### Schritt 2: Der Tabellenkopf wiederholt sich von selbst

Alles, was in `<Tablehead>` steht, wird am Anfang der Tabelle und nach jedem Seitenumbruch erneut ausgegeben:

```xml
<Tablehead>
  <Tr background-color="lightgray">
    <Td><Paragraph><B><Value>Artikelnummer</Value></B></Paragraph></Td>
    <Td><Paragraph><B><Value>Abmessung</Value></B></Paragraph></Td>
    <Td><Paragraph><B><Value>Antrieb</Value></B></Paragraph></Td>
    <Td align="right"><Paragraph><B><Value>VE</Value></B></Paragraph></Td>
    <Td align="right"><Paragraph><B><Value>Preis in €</Value></B></Paragraph></Td>
  </Tr>
</Tablehead>
```

Mit dem Attribut `page` lassen sich für die erste Seite und die Folgeseiten unterschiedliche Köpfe definieren (`page="first"` bzw. `page="all"`), etwa für einen Kopf mit dem Zusatz »Fortsetzung«. Das zeigt das Rezept [Fortsetzungskopf und Fortsetzungshinweis]({{< relref "continuationhead" >}}).

### Schritt 3: Die Zeilen kommen aus den Daten

Zwei verschachtelte `<ForAll>` erzeugen die Zeilen: Das äußere läuft über die Artikelgruppen, das innere über die Artikel. Jede Gruppe beginnt mit einer Überschriftszeile, die über alle fünf Spalten geht:

```xml
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
```

`top-distance` sorgt für Luft vor jeder Gruppenüberschrift, `border-bottom` zieht die Linie darunter. Mit `break-below="no"` lässt sich der automatische Umbruch zeilenweise steuern: Direkt unter dieser Zeile darf die Seite nicht umbrechen, die Gruppenüberschrift bleibt also nie allein am Seitenende zurück. Die Dübel haben kein Attribut `drive`; die Zelle bleibt dann einfach leer.

### Schritt 4: Der Tabellenfuß

`<Tablefoot>` wird am Ende jeder Seite ausgegeben, ebenso wiederholt wie der Kopf:

```xml
<Tablefoot>
  <Tablerule rulewidth="0.5pt"/>
  <Tr>
    <Td colspan="5" align="right">
      <Paragraph><Value>Preise netto je VE</Value></Paragraph>
    </Td>
  </Tr>
</Tablefoot>
```

### Vollständiges Beispiel

Zum Nachbauen die beiden Dateien `layout.xml` und `data.xml` in ein leeres Verzeichnis legen und dort `sp` aufrufen. Das lauffähige Projekt liegt auch im [Beispiele-Repository](https://github.com/speedata/examples/tree/master/manual/simpletable).

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Record element="data">
    <PlaceObject>
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

```xml
<data company="Confixa">
  <group name="Chipboard screws" code="CS" material="steel, zinc plated">
    <article number="CS-3012" dim="3.0 × 12" drive="TX10" pu="1000" price="4.90"/>
    <article number="CS-3016" dim="3.0 × 16" drive="TX10" pu="1000" price="5.20"/>
    <article number="CS-3020" dim="3.0 × 20" drive="TX10" pu="1000" price="5.60"/>
    <article number="CS-3516" dim="3.5 × 16" drive="TX15" pu="1000" price="5.40"/>
    <article number="CS-3520" dim="3.5 × 20" drive="TX15" pu="1000" price="5.80"/>
    <article number="CS-3525" dim="3.5 × 25" drive="TX15" pu="1000" price="6.30"/>
    <article number="CS-3530" dim="3.5 × 30" drive="TX15" pu="1000" price="6.90"/>
    <article number="CS-4020" dim="4.0 × 20" drive="TX20" pu="500" price="4.20"/>
    <article number="CS-4025" dim="4.0 × 25" drive="TX20" pu="500" price="4.50"/>
    <article number="CS-4030" dim="4.0 × 30" drive="TX20" pu="500" price="4.90"/>
    <article number="CS-4035" dim="4.0 × 35" drive="TX20" pu="500" price="5.30"/>
    <article number="CS-4040" dim="4.0 × 40" drive="TX20" pu="500" price="5.80"/>
    <article number="CS-4045" dim="4.0 × 45" drive="TX20" pu="500" price="6.20"/>
    <article number="CS-4050" dim="4.0 × 50" drive="TX20" pu="500" price="6.70"/>
    <article number="CS-4525" dim="4.5 × 25" drive="TX25" pu="500" price="4.90"/>
    <article number="CS-4530" dim="4.5 × 30" drive="TX25" pu="500" price="5.30"/>
    <article number="CS-4540" dim="4.5 × 40" drive="TX25" pu="500" price="6.10"/>
    <article number="CS-4550" dim="4.5 × 50" drive="TX25" pu="500" price="6.90"/>
    <article number="CS-4560" dim="4.5 × 60" drive="TX25" pu="500" price="7.80"/>
    <article number="CS-5030" dim="5.0 × 30" drive="TX25" pu="200" price="3.60"/>
    <article number="CS-5040" dim="5.0 × 40" drive="TX25" pu="200" price="4.10"/>
    <article number="CS-5050" dim="5.0 × 50" drive="TX25" pu="200" price="4.70"/>
    <article number="CS-5060" dim="5.0 × 60" drive="TX25" pu="200" price="5.30"/>
    <article number="CS-5070" dim="5.0 × 70" drive="TX25" pu="200" price="5.90"/>
    <article number="CS-5080" dim="5.0 × 80" drive="TX25" pu="200" price="6.60"/>
    <article number="CS-6040" dim="6.0 × 40" drive="TX30" pu="100" price="3.20"/>
    <article number="CS-6060" dim="6.0 × 60" drive="TX30" pu="100" price="4.10"/>
    <article number="CS-6080" dim="6.0 × 80" drive="TX30" pu="100" price="5.00"/>
    <article number="CS-60100" dim="6.0 × 100" drive="TX30" pu="100" price="6.10"/>
    <article number="CS-60120" dim="6.0 × 120" drive="TX30" pu="100" price="7.30"/>
  </group>
  <group name="Wall plugs" code="WP" material="nylon">
    <article number="WP-0525" dim="5 × 25" pu="100" price="2.10"/>
    <article number="WP-0630" dim="6 × 30" pu="100" price="2.40"/>
    <article number="WP-0840" dim="8 × 40" pu="100" price="3.60"/>
    <article number="WP-1050" dim="10 × 50" pu="50" price="3.20"/>
    <article number="WP-1260" dim="12 × 60" pu="25" price="2.90"/>
    <article number="WP-1470" dim="14 × 70" pu="20" price="3.80"/>
  </group>
  <group name="Wedge anchors" code="WA" material="steel, zinc plated">
    <article number="WA-0875" dim="M8 × 75" pu="50" price="12.40"/>
    <article number="WA-0895" dim="M8 × 95" pu="50" price="14.10"/>
    <article number="WA-1090" dim="M10 × 90" pu="25" price="9.80"/>
    <article number="WA-10115" dim="M10 × 115" pu="25" price="11.60"/>
    <article number="WA-12100" dim="M12 × 100" pu="20" price="13.20"/>
    <article number="WA-12140" dim="M12 × 140" pu="20" price="16.40"/>
    <article number="WA-16125" dim="M16 × 125" pu="10" price="15.90"/>
    <article number="WA-16180" dim="M16 × 180" pu="10" price="21.30"/>
  </group>
</data>
```

## Grenzen

* **Spaltenbreiten**: Der Publisher verteilt die Breiten anhand der Inhalte. Sollen Spalten feste oder anteilige Breiten bekommen, deklariert man sie mit `<Columns>`/`<Column>`; das zeigt das Rezept [Spaltenbreiten steuern]({{< relref "columnwidths" >}}).
* **Fortsetzungskopf und Fortsetzungshinweis**: Soll auf Folgeseiten »Fortsetzung« im Kopf stehen oder am Seitenende ein Hinweis auf die Fortsetzung, braucht es seitenabhängige Köpfe und Füße; das zeigt das Rezept [Fortsetzungskopf und Fortsetzungshinweis]({{< relref "continuationhead" >}}).
* **Eigene Logik auf Folgeseiten**: Hängt der Inhalt einer Folgeseite vom Umbruchpunkt ab (etwa bei komplexen Fortsetzungsbildern), reicht der Automatismus nicht mehr. Dann portioniert man die Daten selbst, misst mit Gruppen und gibt pro Portion eine Tabelle aus; das zeigt das Rezept [Komplexe Tabellen manuell umbrechen]({{< relref "manualtablebreak" >}}).
* Alle Details zu Tabellen: Handbuchkapitel [Tabellen]({{< relref "/manual/tables" >}}) sowie die Referenz zu [`<Table>`]({{< relref "/reference/commands/table" >}}), [`<Tablehead>`]({{< relref "/reference/commands/tablehead" >}}) und [`<Tablefoot>`]({{< relref "/reference/commands/tablefoot" >}}).
