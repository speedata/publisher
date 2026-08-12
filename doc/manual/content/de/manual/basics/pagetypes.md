---
title: "Seitentypen"
weight: 38
type: docs
---



Seitentypen (oder auch Masterseiten, Seitenvorlagen) dienen dazu, Ränder für Seiten zu definieren, Platzierungsrahmen zu erstellen und Aktionen auszuführen, wenn eine Seite erzeugt oder in die PDF Datei geschrieben wird.
Klassischerweise gibt es eine Seitenvorlage für linke Seiten und für rechte Seiten.
Im einfachsten Fall sieht eine Vorlage so aus:

```xml
<Pagetype name="page" test="sd:even(sd:current-page())">
    <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>
</Pagetype>
```

Die Bedingung im Attribut `test` kann beliebig komplex sein. Das Attribut muss immer angegeben werden.
Eine Seite wird ausgewählt, sobald ein Test eines Seitentyps _wahr_ ergibt.
Beispiele:

* `true()`: Diese Seite wird immer ausgewählt, da `true()` immer *wahr* ergibt.
* `sd:current-page() > 1`: Hier wird die Seitenvorlage für alle Seiten ausgewählt, die nach der ersten Seite folgen.
* `sd:even(sd:current-page())`: Wenn die Seitenzahl gerade ist, kommt dieser Seitentyp zu tragen. Das ist in der Regel dann, wenn es sich um eine linke Seite handelt.
* Es kann auch komplexer werden: `sd:even(sd:current-page()) and $abschnitt = 'innenteil'`. Solange die Bedingung zu _wahr_ oder _falsch_ ausgewertet werden kann, ist dies ein gültiger Ausdruck.

Was passiert, wenn es mehrere Bedingungen gibt, die gleichzeitig _wahr_ sind?
Seitentypen werden von »unten nach oben« ausgewertet.
Das heißt, dass spezielle Seitenvorlagen später definiert werden müssen als die allgemeinen.
Die voreingestellte Vorlage wird zuerst definiert und hat als Bedingung `true()`.
Also wird sie nach dieser Logik zuletzt ausgewertet und wird immer dann benutzt, wenn kein anderer Seitentyp im Test _wahr_ ergibt (Fallback).

```xml
<Pagetype name="left pages" test="sd:even(sd:current-page())">
  ...
</Pagetype>
<Pagetype name="right pages" test="sd:odd(sd:current-page())">
  ...
</Pagetype>
<Pagetype name="first page" test="sd:current-page() = 1">
  ...
</Pagetype>
```
{{% codecaption %}}Hier muss der Seitentyp für die erste Seite nach dem Seitentyp für rechte Seiten definiert werden, weil er sonst nicht in Betracht gezogen würde (sd:odd(1) ergibt wahr).{{% /codecaption %}}

## Platzierungsbereiche

In der Seitentyp-Definition können Platzierungsbereiche angelegt werden.
Diese werden ausführlich im Abschnitt [Platzierungsbereiche]({{< relref "positioningframe" >}}) beschrieben.

## AtPageCreation, AtPageShipout

Die beiden Befehle `<AtPageCreation>` und `<AtPageShipout>` sind dafür zuständig, Code auszuführen, wenn eine Seite erzeugt und wenn eine Seite in die PDF Datei geschrieben wird.
Diese können für vielfältige Zwecke benutzt werden.
Üblich ist, in `<AtPageCreation>` den Seitenkopf zu erzeugen und in `<AtPageShipout>` den Seitenfuß.

Es folgt ein Beispiel für einen Seitenfuß.


```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Pagetype name="page" test="true()">
    <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>

    <AtPageShipout>
      <PlaceObject column="1" row="{sd:number-of-rows() - 1}">
        <Table stretch="max">
          <Tablerule/>
          <Tr>
            <Td align="left">
              <Paragraph>
                <Value select="sd:current-page()"/>
              </Paragraph>
            </Td>
            <Td align="right">
              <Paragraph>
                <Value>Firmenname</Value>
              </Paragraph>
            </Td>
          </Tr>
        </Table>
      </PlaceObject>
    </AtPageShipout>
  </Pagetype>

  <Record element="data">
    <PlaceObject>
      <Textblock>
        <Paragraph>
          <Value>Inhalt</Value>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```

![Seite mit Fußzeile](/img/fusszeileseitentyp.png)

## ClearPage

Bei dem Befehl `<ClearPage>` kann angegeben werden, welcher Seitentyp für die nächste Seite ausgewählt werden soll, auch wenn die Bedingung (`test`) bei `<Pagetype>` nicht _wahr_ ergibt.

Im folgenden Beispiel werden zwei Seitentypen definiert, eine Vorlage »Standard«, die immer genommen wird und eine Vorlage »Spezial«, die explizit mit `<ClearPage>` ausgewählt wird.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Pageformat width="210mm" height="50mm"/>

  <Pagetype name="Special" test="false()">
    <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>
  </Pagetype>

  <Pagetype name="Standard" test="true()">
    <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>
  </Pagetype>

  <Record element="data">
    <PlaceObject>
      <Textblock>
        <Paragraph>
          <Value>Page 1</Value>
        </Paragraph>
      </Textblock>
    </PlaceObject>
    <ClearPage pagetype="Special" openon="right" />
    <PlaceObject>
      <Textblock>
        <Paragraph>
          <Value>Page 3</Value>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```

In der Logdatei (`publisher-protocol.xml`) sieht man, welche Seitentypen gewählt werden (Level info):

```xml
<entry level="INFO" msg="Create page" type="Standard" pagenumber="1"></entry>
<entry level="INFO" msg="Number of rows: 3, number of columns = 19"></entry>
<entry level="INFO" msg="Create font metrics" name="texgyreheros-regular.otf" size="10.0" id="1" mode="harfbuzz"></entry>
<entry level="INFO" msg="Shipout page 1"></entry>
<entry level="INFO" msg="Create page" type="Standard" pagenumber="2"></entry>
<entry level="INFO" msg="Number of rows: 3, number of columns = 19"></entry>
<entry level="INFO" msg="Shipout page 2"></entry>
<entry level="INFO" msg="Create page" type="Special" pagenumber="3"></entry>
<entry level="INFO" msg="Number of rows: 3, number of columns = 19"></entry>
<entry level="INFO" msg="Shipout page 3"></entry>
```

## Nummerierung von Seiten

Die Seitenzahl der aktuellen Seite kann mit `sd:current-page()` ermittelt werden. Diese Funktion gibt auf der ersten Seite die Zahl 1 zurück, auf der zweiten Seite die Zahl 2 und so fort. Mit dem `startpage`-Attribut bei [`<Options>`]({{< relref "/reference/commands/options" >}}) kann man die Startseitenzahl setzen:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en">
    <Options startpage="4"></Options>
    <Record element="data">
        <PlaceObject>
            <Textblock>
                <Paragraph>
                    <!-- prints out sd:current-page() = 4 -->
                    <Value>sd:current-page() = </Value>
                    <Value select="sd:current-page()" />
                </Paragraph>
            </Textblock>
        </PlaceObject>
    </Record>
</Layout>
```

### Seite x von y

Für Angaben wie »Seite 1 von 10« wird die Gesamtseitenzahl des Dokuments benötigt.
Die [interne Variable]({{< relref "internalvariables" >}}) `$_lastpage` enthält die Anzahl der Seiten aus dem vorherigen Durchlauf:

```xml
<Value select="concat('Seite ', sd:current-page(), ' von ', $_lastpage)"/>
```

Da erst am Ende eines Durchlaufs feststeht, wie lang das Dokument wird, sind mindestens zwei Durchläufe notwendig, bis der Wert stimmt.
Vor Version 3.9.26 musste die letzte Seitenzahl selbst mit `<SaveDataset>` gespeichert und im nächsten Durchlauf wieder geladen werden.
Dieser allgemeine Mechanismus ist im Abschnitt [Listen erstellen (XML-Struktur)]({{< relref "directoriesxml" >}}) beschrieben.

## Abschnitte

Ein Dokument kann in Abschnitte unterteilt werden, die eine eigene Nummerierung haben. Die Nummerierung der Abschnitte ändern _nicht_ die Nummerierung mit `sd:current-page()`, vielmehr haben sie »sichtbare Seitenzahl« (im speedata Publisher-Jargon: visible page numbers). Die sichtbare Seitenzahl kann mit dem Befehl `sd:visible-pagenumber()` ermittelt werden. Dieser Funktion muss eine Zahl übergeben werden, ansonsten nimmt sie die aktuelle Seite. _Ohne_ eigene Abschnitte ist die Ausgabe identisch:

```xml
<!-- prints out sd:current-page() = 1 -->
<Value>sd:current-page() = </Value>
<Value select="sd:current-page()" />
<Br/>
<!-- sd:visible‐pagenumber(sd:current‐page()) = 1 -->
<Value>sd:visible-pagenumber(sd:current-page()) = </Value>
<Value select="sd:visible-pagenumber(sd:current-page())" />
```

Werden eigene Abschnitte definiert und benutzt oder ein vordefinierter Abschnitt verwendet, kann sich das ändern:

```xml
<ClearPage matter="frontmatter" />
<PlaceObject>
    <Textblock>
        <Paragraph>
            <!-- prints out sd:current-page() = 1 -->
            <Value>sd:current-page() = </Value>
            <Value select="sd:current-page()" />
            <Br/>
            <!-- sd:visible‐pagenumber(sd:current‐page()) = i -->
            <Value>sd:visible-pagenumber(sd:current-page()) = </Value>
            <Value select="sd:visible-pagenumber(sd:current-page())" />
        </Paragraph>
    </Textblock>
</PlaceObject>
```

Hier (mit [`<Clearpage>`]({{< relref "/reference/commands/clearpage" >}})) wird der Abschnitt `frontmatter` für die folgenden Seiten benutzt. Das bewirkt die Ausgabe der sichtbaren Seitenzahl als römische Ziffer in Kleinbuchstaben, da dieser Abschnitt wie folgt definiert wurde:

```xml
<DefineMatter name="frontmatter" label="lowercase-romannumeral" />
```

Abschnitte können nur mit dem Befehl [`<Clearpage>`]({{< relref "/reference/commands/clearpage" >}}) eingeleitet werden.

