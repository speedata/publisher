---
title: "Fortsetzungskopf und Fortsetzungshinweis"
weight: 24
type: docs
---

## Aufgabe

Bei einer mehrseitigen Artikelliste sollen die Leser erkennen, dass die Tabelle weitergeht und wo sie endet: Die erste Seite trägt den normalen Kopf, Folgeseiten einen Kopf mit dem Zusatz »Fortsetzung«. Am Ende jeder Seite außer der letzten steht »Fortsetzung nächste Seite«, nur auf der letzten Seite der Abschlussfuß.

![Erste Seite mit normalem Kopf, Folgeseiten mit »Fortsetzung«; der Hinweis unten entfällt auf der letzten Seite.](/img/howto-continuationhead.png)

## Entscheidung

Das Rezept [Einfache Tabelle mit automatischem Umbruch]({{< relref "simpletable" >}}) reicht, solange Kopf und Fuß auf allen Seiten gleich aussehen dürfen. Sollen sie sich je Seite unterscheiden, bleibt der Automatismus trotzdem erhalten: `<Tablehead>` und `<Tablefoot>` können mehrfach deklariert werden, das Attribut `page` bestimmt, welche Variante auf welcher Seite erscheint. Der Publisher wählt beim Umbruch selbst die passende aus.

Eine Grenze sollte man vor der Umsetzung kennen: Die Inhalte von Kopf und Fuß werden beim Aufbau der Tabelle ausgewertet, nicht beim Seitenumbruch. Eine echte Seitenzahl (»Fortsetzung auf Seite 17«) lässt sich hier deshalb nicht ausgeben; Details unter [Grenzen](#grenzen).

## Lösung

Die Daten sind unverändert die Confixa-Artikelliste aus dem [ersten Rezept]({{< relref "simpletable" >}}).

### Schritt 1: Zwei Tabellenköpfe

Der Kopf für die erste Seite bekommt `page="first"`, der für die Folgeseiten `page="all"`. Sobald eine `first`-Variante deklariert ist, gilt `all` für alle Seiten außer der ersten; die Reihenfolge der Deklaration spielt keine Rolle.

```xml
<Tablehead page="first">
  <Tr background-color="lightgray">
    <Td><Paragraph><B><Value>Artikelnummer</Value></B></Paragraph></Td>
    <!-- weitere Spaltentitel wie gehabt -->
  </Tr>
</Tablehead>
<Tablehead page="all">
  <Tr>
    <Td colspan="5"><Paragraph><I><Value>Fortsetzung</Value></I></Paragraph></Td>
  </Tr>
  <Tr background-color="lightgray">
    <Td><Paragraph><B><Value>Artikelnummer</Value></B></Paragraph></Td>
    <!-- weitere Spaltentitel wie gehabt -->
  </Tr>
</Tablehead>
```

Der Fortsetzungskopf darf mehr als eine Zeile haben: Hier steht über den Spaltentiteln eine zusätzliche Zeile mit dem kursiven »Fortsetzung«.

### Schritt 2: Zwei Tabellenfüße

Bei den Füßen heißt das Gegenstück zu `first` sinngemäß `last`: Ist eine `last`-Variante deklariert, erscheint die `all`-Variante auf allen Seiten außer der letzten. Damit wandert der Hinweis »Fortsetzung nächste Seite« genau auf die Seiten, auf denen die Tabelle weitergeht:

```xml
<Tablefoot page="all">
  <Tablerule rulewidth="0.5pt"/>
  <Tr>
    <Td colspan="5" align="right">
      <Paragraph><I><Value>Fortsetzung nächste Seite</Value></I></Paragraph>
    </Td>
  </Tr>
</Tablefoot>
<Tablefoot page="last">
  <Tablerule rulewidth="0.5pt"/>
  <Tr>
    <Td colspan="5" align="right">
      <Paragraph><Value>Preise netto je VE</Value></Paragraph>
    </Td>
  </Tr>
</Tablefoot>
```

Soll auf der letzten Seite gar kein Fuß stehen, deklariert man die Variante einfach leer: `<Tablefoot page="last"/>`.

### Vollständiges Beispiel

Das lauffähige Projekt liegt auch im [Beispiele-Repository](https://github.com/speedata/examples/tree/master/manual/continuationhead); die Datendatei ist dieselbe wie im [ersten Rezept]({{< relref "simpletable#vollständiges-beispiel" >}}). Das A5-Format und das großzügige `padding` dienen nur dazu, für die Abbildung drei Seiten zu erzeugen.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Pageformat width="148mm" height="210mm"/>

  <Record element="data">
    <PlaceObject>
      <Table stretch="max" padding="5pt">
        <Tablehead page="first">
          <Tr background-color="lightgray">
            <Td><Paragraph><B><Value>Artikelnummer</Value></B></Paragraph></Td>
            <Td><Paragraph><B><Value>Abmessung</Value></B></Paragraph></Td>
            <Td><Paragraph><B><Value>Antrieb</Value></B></Paragraph></Td>
            <Td align="right"><Paragraph><B><Value>VE</Value></B></Paragraph></Td>
            <Td align="right"><Paragraph><B><Value>Preis in €</Value></B></Paragraph></Td>
          </Tr>
        </Tablehead>
        <Tablehead page="all">
          <Tr>
            <Td colspan="5"><Paragraph><I><Value>Fortsetzung</Value></I></Paragraph></Td>
          </Tr>
          <Tr background-color="lightgray">
            <Td><Paragraph><B><Value>Artikelnummer</Value></B></Paragraph></Td>
            <Td><Paragraph><B><Value>Abmessung</Value></B></Paragraph></Td>
            <Td><Paragraph><B><Value>Antrieb</Value></B></Paragraph></Td>
            <Td align="right"><Paragraph><B><Value>VE</Value></B></Paragraph></Td>
            <Td align="right"><Paragraph><B><Value>Preis in €</Value></B></Paragraph></Td>
          </Tr>
        </Tablehead>
        <Tablefoot page="all">
          <Tablerule rulewidth="0.5pt"/>
          <Tr>
            <Td colspan="5" align="right">
              <Paragraph><I><Value>Fortsetzung nächste Seite</Value></I></Paragraph>
            </Td>
          </Tr>
        </Tablefoot>
        <Tablefoot page="last">
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

* **Keine echten Seitenzahlen im Hinweis.** Die Inhalte von `<Tablehead>` und `<Tablefoot>` werden einmal beim Aufbau der Tabelle ausgewertet, nicht bei jedem Seitenumbruch; `sd:current-page()` liefert deshalb in jedem Fuß dieselbe Zahl. Wer »Fortsetzung auf Seite 17« braucht, muss die Tabelle selbst portionieren und die Füße je Portion setzen; das zeigt das Rezept [Komplexe Tabellen manuell umbrechen]({{< relref "manualtablebreak" >}}).
* **Dynamische Inhalte im Kopf oder Fuß** (etwa Zwischensummen oder ein Übertrag) sind mit dem Mechanismus `data`-Attribut an `<Tr>` plus der Variablen `$_last_tr_data` möglich, siehe [Kopf- und Fußzeilen mit Übertrag]({{< relref "/manual/tables#kopf--und-fußzeilen-mit-übertrag" >}}).
* **Zwischenüberschriften wiederholen**: Soll nach dem Umbruch die aktuelle Gruppenüberschrift erneut erscheinen, markiert man deren Zeile mit `sethead="yes"`, siehe [Kopf- und Fußzeilen (dynamisch)]({{< relref "/manual/tables#kopf--und-fußzeilen-dynamisch" >}}).
* Referenz: [`<Tablehead>`]({{< relref "/reference/commands/tablehead" >}}) und [`<Tablefoot>`]({{< relref "/reference/commands/tablefoot" >}}).
