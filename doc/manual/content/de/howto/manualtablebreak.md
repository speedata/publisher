---
title: "Komplexe Tabellen manuell umbrechen"
weight: 26
type: docs
---

## Aufgabe

Die Confixa-Artikelliste soll am Ende jeder Seite auf die tatsächliche Folgeseite verweisen: »Fortsetzung auf Seite 2«, »Fortsetzung auf Seite 3« und so weiter, mit echten Seitenzahlen. Das Rezept [Fortsetzungskopf und Fortsetzungshinweis]({{< relref "continuationhead" >}}) endet genau an dieser Grenze: Mit dem automatischen Tabellenumbruch sind solche Hinweise nicht möglich. Dasselbe gilt für alle Fälle, in denen Fortsetzungsseiten eigene Logik brauchen, die vom Umbruchpunkt abhängt.

![Jede Seite verweist mit echter Seitenzahl auf die Fortsetzung; auf der letzten Seite entfällt der Hinweis.](/img/howto-manualtablebreak.png)

## Entscheidung

Der erste Reflex ist, bei der einen großen Tabelle zu bleiben und nur die Füße zu variieren. Das scheitert aus einem grundsätzlichen Grund: Die Inhalte von `<Tablehead>` und `<Tablefoot>` werden einmal beim Aufbau der Tabelle ausgewertet, nicht bei jedem Seitenumbruch. In diesem Moment ist noch keine einzige Seite ausgegeben; `sd:current-page()` liefert überall dieselbe Zahl, und welche Zeile auf welcher Seite landet, ist noch gar nicht bekannt.

Der tragfähige Weg dreht die Verantwortung um: Statt den Publisher umbrechen zu lassen, wird die Tabelle selbst portioniert. Die Kernidee ist Messen-dann-Platzieren mit [Gruppen]({{< relref "/manual/pagelayout/groups" >}}):

1. Die nächste Zeile probeweise zur aktuellen Portion legen, und zwar in einer Gruppe, die gesetzt, aber nicht ausgegeben wird.
2. Die Gruppenhöhe mit dem Restplatz auf der Seite vergleichen.
3. Passt es nicht mehr: die bisherige Portion als eigene, vollständige Tabelle ausgeben und auf einer neuen Seite weitermachen.

Weil jede Portion erst dann ausgegeben wird, wenn ihre Seite die aktuelle ist, stimmen alle seitenabhängigen Angaben, allen voran die Seitenzahlen. Und weil jede Portion eine eigene Tabelle ist, darf jede Seite anders aussehen: eigene Köpfe, eigene Füße, eigene Zwischenelemente, abhängig davon, wo der Umbruch fiel.

Der Preis ist deutlich mehr Layoutcode und Rechenzeit fürs Messen. Deshalb vorher prüfen, ob nicht ein einfacherer Weg reicht: Der Automatismus mit seitenabhängigen Köpfen und Füßen ([Fortsetzungskopf]({{< relref "continuationhead" >}})) deckt viele Fälle ab, und wer nur an bestimmten Stellen einen Seitenwechsel erzwingen will, kommt mit [`<TableNewPage>`]({{< relref "/reference/commands/tablenewpage" >}}) innerhalb der automatischen Tabelle aus.

<!-- TODO Patrick: Praxisbeispiel ergänzen, bei dem der Automatismus nicht reichte (komplexe Fortsetzungsbilder, die vom Umbruchpunkt abhängen): Wie sah die Anforderung aus, was musste je Fortsetzungsseite anders sein? -->

## Lösung

### Schritt 1: Zeilen als Bausteine in Variablen

Tabellenzeilen lassen sich in Variablen ablegen und später mit `<Copy-of>` in eine Tabelle einsetzen. Damit werden Kopf und Zeilen zu Bausteinen, aus denen sich jede Portionstabelle zusammensetzen lässt. Am Anfang werden die beiden Kopfvarianten definiert, der normale Kopf und der mit der Zusatzzeile »Fortsetzung«:

```xml
<SetVariable variable="headfirst">
  <Tr background-color="lightgray">
    <Td><Paragraph><B><Value>Artikelnummer</Value></B></Paragraph></Td>
    <!-- weitere Spaltentitel wie gehabt -->
  </Tr>
</SetVariable>
<SetVariable variable="headcont">
  <Tr>
    <Td colspan="5"><Paragraph><I><Value>Fortsetzung</Value></I></Paragraph></Td>
  </Tr>
  <Tr background-color="lightgray">
    <Td><Paragraph><B><Value>Artikelnummer</Value></B></Paragraph></Td>
    <!-- weitere Spaltentitel wie gehabt -->
  </Tr>
</SetVariable>

<SetVariable variable="headrow"><Copy-of select="$headfirst"/></SetVariable>
<SetVariable variable="tablerows"/>
```

`$headrow` ist der Kopf der jeweils aktuellen Portion; er startet mit der normalen Variante und wird nach dem ersten Umbruch auf die Fortsetzungsvariante umgestellt. `$tablerows` sammelt die Zeilen der aktuellen Portion. Anders als beim Sammeln von Datenstrukturen (Rezept [Stichwortverzeichnis]({{< relref "keywordindex" >}})) liegen hier fertige Layoutbausteine in den Variablen; `<Copy-of>` übernimmt sie ohne Pfadangabe.

### Schritt 2: Der Fortsetzungshinweis wird erst später ausgewertet

Der Hinweis braucht die Seitenzahl der Folgeseite, und die ist je Portion eine andere. Mit `execute="later"` speichert `<SetVariable>` seinen Inhalt unausgewertet; erst das `<Copy-of>` an der Einsatzstelle führt ihn aus. So liefert `sd:current-page() + 1` in jeder Portionstabelle die richtige Zahl:

```xml
<SetVariable variable="contfoot" execute="later">
  <Tablerule rulewidth="0.5pt"/>
  <Tr>
    <Td colspan="5" align="right">
      <Paragraph>
        <I>
          <Value>Fortsetzung auf Seite </Value>
          <Value select="sd:current-page() + 1"/>
        </I>
      </Paragraph>
    </Td>
  </Tr>
</SetVariable>
```

Die Rechnung `+ 1` stimmt, weil nach jeder ausgegebenen Portion mit `<ClearPage>` direkt die nächste Seite beginnt.

### Schritt 3: Messen mit einer Gruppe

Nun läuft ein `<ForAll>` über alle Artikel; die Gruppenzwischenzeilen aus dem [ersten Rezept]({{< relref "simpletable" >}}) lässt dieses Rezept weg, damit der Messkern klar bleibt (`select="group/article"` liefert alle Artikel als flache Liste). Für jeden Artikel wird die Zeile gebaut und die künftige Portionstabelle probeweise in einer Gruppe gesetzt, mitsamt Kopf, bisherigen Zeilen, neuer Zeile und dem Fortsetzungshinweis:

```xml
<ForAll select="group/article">
  <SetVariable variable="thisrow">
    <Tr>
      <Td><Paragraph><Value select="@number"/></Paragraph></Td>
      <Td><Paragraph><Value select="@dim"/></Paragraph></Td>
      <Td><Paragraph><Value select="@drive"/></Paragraph></Td>
      <Td align="right"><Paragraph><Value select="@pu"/></Paragraph></Td>
      <Td align="right"><Paragraph><Value select="@price"/></Paragraph></Td>
    </Tr>
  </SetVariable>

  <Group name="portion">
    <Contents>
      <PlaceObject>
        <Table stretch="max" padding="6pt">
          <Copy-of select="$headrow"/>
          <Copy-of select="$tablerows"/>
          <Copy-of select="$thisrow"/>
          <Copy-of select="$contfoot"/>
        </Table>
      </PlaceObject>
    </Contents>
  </Group>
  <!-- Auswertung folgt in Schritt 4 -->
</ForAll>
```

Der Inhalt einer [`<Group>`]({{< relref "/reference/commands/group" >}}) wird gesetzt, aber nicht ausgegeben; `sd:group-height('portion')` liefert danach die Höhe in Rasterzeilen. Der Hinweis wird bewusst mitgemessen: Ob die Zeile noch passt, muss sich an der Tabelle bemessen, die im Umbruchfall tatsächlich ausgegeben wird.

### Schritt 4: Der Umbruch

Die Entscheidung fällt im Vergleich der Gruppenhöhe mit dem Restplatz; `sd:number-of-rows() - sd:current-row() + 1` ist die Zahl der noch freien Rasterzeilen auf der Seite:

```xml
<Switch>
  <Case test="sd:group-height('portion') > sd:number-of-rows() - sd:current-row() + 1">
    <PlaceObject>
      <Table stretch="max" padding="6pt">
        <Copy-of select="$headrow"/>
        <Copy-of select="$tablerows"/>
        <Copy-of select="$contfoot"/>
      </Table>
    </PlaceObject>
    <ClearPage/>
    <SetVariable variable="headrow"><Copy-of select="$headcont"/></SetVariable>
    <SetVariable variable="tablerows"><Copy-of select="$thisrow"/></SetVariable>
  </Case>
  <Otherwise>
    <SetVariable variable="tablerows">
      <Copy-of select="$tablerows"/>
      <Copy-of select="$thisrow"/>
    </SetVariable>
  </Otherwise>
</Switch>
```

Passt die neue Zeile nicht mehr, wird die Portion ohne sie ausgegeben, dahinter der Fortsetzungshinweis; `<ClearPage>` beendet die Seite. Ab jetzt gilt der Fortsetzungskopf, und die neue Portion beginnt mit genau der Zeile, die nicht mehr passte. Im Normalfall wird die Zeile einfach an die Portion angehängt.

### Schritt 5: Die letzte Portion

Nach dem `<ForAll>` stehen die restlichen Zeilen noch in `$tablerows`. Sie bilden die letzte Tabelle, diesmal ohne Fortsetzungshinweis:

```xml
<PlaceObject>
  <Table stretch="max" padding="6pt">
    <Copy-of select="$headrow"/>
    <Copy-of select="$tablerows"/>
  </Table>
</PlaceObject>
```

### Vollständiges Beispiel

Das lauffähige Projekt liegt auch im [Beispiele-Repository](https://github.com/speedata/examples/tree/master/manual/manualtablebreak); die Datendatei ist die Confixa-Artikelliste aus dem [ersten Rezept]({{< relref "simpletable#vollständiges-beispiel" >}}). Wie beim [Fortsetzungskopf]({{< relref "continuationhead" >}}) erzeugen das A5-Format und das großzügige `padding` drei Seiten für die Abbildung.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Pageformat width="148mm" height="210mm"/>

  <Record element="data">
    <SetVariable variable="headfirst">
      <Tr background-color="lightgray">
        <Td><Paragraph><B><Value>Artikelnummer</Value></B></Paragraph></Td>
        <Td><Paragraph><B><Value>Abmessung</Value></B></Paragraph></Td>
        <Td><Paragraph><B><Value>Antrieb</Value></B></Paragraph></Td>
        <Td align="right"><Paragraph><B><Value>VE</Value></B></Paragraph></Td>
        <Td align="right"><Paragraph><B><Value>Preis in €</Value></B></Paragraph></Td>
      </Tr>
    </SetVariable>
    <SetVariable variable="headcont">
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
    </SetVariable>
    <SetVariable variable="contfoot" execute="later">
      <Tablerule rulewidth="0.5pt"/>
      <Tr>
        <Td colspan="5" align="right">
          <Paragraph>
            <I>
              <Value>Fortsetzung auf Seite </Value>
              <Value select="sd:current-page() + 1"/>
            </I>
          </Paragraph>
        </Td>
      </Tr>
    </SetVariable>

    <SetVariable variable="headrow"><Copy-of select="$headfirst"/></SetVariable>
    <SetVariable variable="tablerows"/>

    <ForAll select="group/article">
      <SetVariable variable="thisrow">
        <Tr>
          <Td><Paragraph><Value select="@number"/></Paragraph></Td>
          <Td><Paragraph><Value select="@dim"/></Paragraph></Td>
          <Td><Paragraph><Value select="@drive"/></Paragraph></Td>
          <Td align="right"><Paragraph><Value select="@pu"/></Paragraph></Td>
          <Td align="right"><Paragraph><Value select="@price"/></Paragraph></Td>
        </Tr>
      </SetVariable>

      <Group name="portion">
        <Contents>
          <PlaceObject>
            <Table stretch="max" padding="6pt">
              <Copy-of select="$headrow"/>
              <Copy-of select="$tablerows"/>
              <Copy-of select="$thisrow"/>
              <Copy-of select="$contfoot"/>
            </Table>
          </PlaceObject>
        </Contents>
      </Group>

      <Switch>
        <Case test="sd:group-height('portion') > sd:number-of-rows() - sd:current-row() + 1">
          <PlaceObject>
            <Table stretch="max" padding="6pt">
              <Copy-of select="$headrow"/>
              <Copy-of select="$tablerows"/>
              <Copy-of select="$contfoot"/>
            </Table>
          </PlaceObject>
          <ClearPage/>
          <SetVariable variable="headrow"><Copy-of select="$headcont"/></SetVariable>
          <SetVariable variable="tablerows"><Copy-of select="$thisrow"/></SetVariable>
        </Case>
        <Otherwise>
          <SetVariable variable="tablerows">
            <Copy-of select="$tablerows"/>
            <Copy-of select="$thisrow"/>
          </SetVariable>
        </Otherwise>
      </Switch>
    </ForAll>

    <PlaceObject>
      <Table stretch="max" padding="6pt">
        <Copy-of select="$headrow"/>
        <Copy-of select="$tablerows"/>
      </Table>
    </PlaceObject>
  </Record>
</Layout>
```

## Grenzen

* **Messen kostet Zeit.** Für jede Zeile wird die gesamte bisherige Portion erneut gesetzt; der Aufwand wächst mit dem Quadrat der Zeilen je Seite. Bei Preislisten ist das unkritisch, bei sehr großen Katalogen wird es spürbar. <!-- TODO Patrick: Größenordnungen aus der Praxis ergänzen: ab wie vielen Seiten/Zeilen wurde das Messen zum Thema, und was hat geholfen? -->
* **Der Komfort des Automatismus ist weg.** Zeilenregeln wie `break-below="no"` (Gruppenüberschrift bleibt bei ihren Zeilen) müssen selbst nachgebaut werden, etwa indem Überschrifts- und erste Artikelzeile gemeinsam gemessen werden. Die Gruppenzwischenzeilen aus dem ersten Rezept sind im selben Muster weitere Bausteine.
* **Der Hinweis wird immer mitgemessen**, auch auf der letzten Seite, auf der er entfällt; dort bleibt schlimmstenfalls eine Zeile Luft. Wer das vermeiden will, muss vorab wissen, welcher Artikel der letzte ist.
* **Seitenzahl der Folgeseite**: `sd:current-page() + 1` setzt voraus, dass die nächste Portion direkt auf der nächsten Seite folgt. Bei eingeschobenen Seiten (etwa Kapiteltrennern) muss der Hinweis entsprechend rechnen.
* Referenz: [`<Group>`]({{< relref "/reference/commands/group" >}}), [`<Switch>`]({{< relref "/reference/commands/switch" >}}), [`<SetVariable>`]({{< relref "/reference/commands/setvariable" >}}) (Attribut `execute`), `sd:group-height()` und `sd:number-of-rows()` in den [Layoutfunktionen]({{< relref "/reference/xpath/layoutfunctions" >}}).
