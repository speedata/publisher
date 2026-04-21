---
title: "Tabellen"
weight: 60
type: docs
---



Das im Publisher verwendete Tabellenmodell entspricht in den Grundzügen dem von HTML.

## Grundlegender Aufbau einer Tabelle

Die Struktur einer Tabelle sieht wie folgt aus:

```xml
<PlaceObject>
  <Table>
    <Tr>
      <Td>...</Td>
      <Td>...</Td>
    </Tr>
    <Tr>
      <Td>...</Td>
      <Td>...</Td>
    </Tr>
  </Table>
</PlaceObject>
```

`<Tr>` steht für tablerow und `<Td>` für tabledata.
Tabellen sind immer zeilenweise aufgebaut.
Jede Zeile muss dieselbe Zahl an Spalten enthalten, ansonsten gibt der Publisher eine Fehlermeldung aus.
Die Zahl der Zeilen hingegen ist beliebig.

Die Breite der Tabelle wird durch die Inhalte bestimmt.
Bei Angabe von `stretch="no"` (Voreinstellung) beim Befehl `<Table>` nimmt die Tabelle nur die minimale Breite ein, bei `stretch="max"` wird die volle angegebene Breite (bzw. der maximal verfügbare Platz) genutzt.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">
  <Trace grid="no" objects="yes"/>

  <Record element="data">
    <PlaceObject>
      <Table padding="2mm" stretch="no" >
        <Tr>
          <Td>
            <Paragraph><Value>Row 1 / Column 1</Value></Paragraph>
          </Td>
          <Td>
            <Paragraph><Value>Row 1 / Column 2</Value></Paragraph>
          </Td>
        </Tr>
        <Tr>
          <Td>
            <Paragraph><Value>Row 2 / Column 1</Value></Paragraph>
          </Td>
          <Td>
            <Paragraph><Value>Row 2 / Column 2</Value></Paragraph>
          </Td>
        </Tr>
      </Table>
    </PlaceObject>
  </Record>
</Layout>
```
{{% codecaption %}}Ein vollständiges Layout für eine Tabelle.{{% /codecaption %}}

![Bei stretch="no" (bzw. weglassen des Attributs stretch) ist die Tabelle nur so breit, wie nötig (oben). Die Angabe von stretch="max" bei der Tabelle hat zur Folge, dass die gesamte angegebene Breite genutzt wird. Die Voreinstellung für die Breite ist die Seitenbreite (unten).](/img/tablestretchmaxno.png)

Es gibt einige für die gesamte Tabelle gültige Einstellungen, wie die Schriftart, Innenabstand, Zeilen- und Spaltenabstand.
Diese sind im Anhang in der  [Referenz für den Befehl `<Table>`]({{< relref "/reference/table" >}}) beschrieben.

## Tabellenzellen und Tabellenzeilen, Linien in Tabellen


### Tabellenzeilen

Anweisungen in Tabellenzeilen (`<Tr>`) bestimmen Eigenschaften für alle Zellen in dieser Zeile, sofern sie nicht in der Zelle selber überschreiben werden. Z. B.  legen `align` und `valign` die horizontale und vertikale Ausrichtung der Zellen fest.
D. h. in der Zeile

```xml
<Tr align="left">
  <Td>...</Td>
  <Td>...</Td>
  <Td align="right">...</Td>
</Tr>
```

haben alle Spalten bis auf die letzte die Ausrichtung »linksbündig«.

In der Zeile kann auch die Hintergrundfarbe für die einzelnen Spalten festgelegt werden (`background-color`).
Ebenso kann die minimale Höhe (`minheight`, Angabe in Rasterzellen bzw. einer Maßangabe) und der Abstand oberhalb der Zelle, sofern sie nicht auf einen Seitenumbruch folgt, festgelegt werden.


### Zellen

Die Tabellenzellen (`<Td>`) haben umfangreiche Formatierungsmöglichkeiten. So kann der Innenabstand (`padding`) für jede der vier Seiten individuell festgelegt werden.
Ebenso kann sich die Zellenumrandung (`border`) auf jeder Seite in Dicke und Farbe unterscheiden.
Die Zellenumrandung liegt immer innerhalb einer Tabelle, mit der Ausnahme, dass bei benachbarten Zellen und der bei `<Table>` aktivierten Option `border-collapse` die Rahmen »überlappen«.
Die Ausrichtung des Tabelleninhalts lässt sich über die Parameter `valign` (vertikal) und `align` (horizontal) festlegen.

Zellen können verschiedene Inhalte haben, auch gemischt:

* Absätze (`Paragraph`, Block-Element)
* Tabellen (`Table`, Block-Element)
* Bilder (`Image`, Inline-Element)
* Barcodes (`Barcode`, Inline-Element)
* Kästchen (`Box`, Block-Element)
* Mehrfachobjekte (`Overlay`, s.u., Inline-Element)
* Vertikale Abstände (`Vspace`, s.u., Block-Element)
* Rahmen (`Frame`, Block-Element)

In Tabellenzellen gibt es horizontale Objekte (Inline-Elemente) und vertikale Objekte (Block-Elemente).
Das bezieht sich auf die Anordnung innerhalb der Tabellenzelle:

```xml
<PlaceObject>
  <Table width="8" stretch="max">
    <Tr align="center">
      <Td>
        <Image file="ocean.pdf" width="2"/>
        <Paragraph textformat="justified">
          <Value select="sd:dummytext()"/>
        </Paragraph>
        <Box width="2" height="1" background-color="green"/>
      </Td>
    </Tr>
  </Table>
</PlaceObject>
```
{{% codecaption %}}Eine Tabelle mit Inline- und Block-Elementen.{{% /codecaption %}}

![Block-Elemente in einer Tabellenzelle werden untereinander dargestellt.](/img/tab-inline-block.png)

Steht die Zeilenhöhe beispielsweise durch eine andere Zelle oder durch die Angabe von `minheight` im Zeilenanfang fest, so kann man mit `VSpace` einen vertikalen Leerraum einfügen.
Damit wird der Teil oberhalb des Leerraums soweit wie möglich nach oben geschoben und der untere Teil nach unten, eine Angabe von `valign` in dieser Zelle hat dann keine Auswirkung mehr.


### Linien

Zwischen einzelnen Zeilen können Linien gezeichnet werden.

```xml
<Table>
  <Tr>
     ...
  </Tr>
  <Tablerule rulewidth="3pt" color="green" />
</Table>
```

Die Angabe der Startspalte (`startcolumn`) ist möglich.

## Textformate in Tabellen

Im Gegensatz zu den Textformaten in Texten (siehe den Abschnitt über [Textformate]({{< relref "textformat" >}})), ist das voreingestellte Textformat (und damit die Textausrichtung) von der Ausrichtung der Tabellenzelle abhängig.

| Ausrichtung bei `<Td>` | Textformat | Beschreibung |
| --- | --- | --- |
| `left` | `__leftaligned` | Linksbündig, Flattersatz rechts |
| `right` | `__rightaligned` | Rechtsbündig, Flattersatz links |
| `center` | `__centered` | Zentriert, Flattersatz auf beiden Seiten |
| `justify` | `__justified` | Blocksatz, rechts- und linksbündig |


Das bedeutet, dass die beiden Beispiele identisch sind:

```xml
<Td align="left">
  <Paragraph>
    <Value>....</Value>
  </Paragraph>
</Td>

<Td align="left">
  <Paragraph textformat="__leftaligned">
    <Value>....</Value>
  </Paragraph>
</Td>

```

Damit können z.B. durch die Veränderung des Textformats `__leftaligned` alle Tabellenzellen mit linksbündiger Ausrichtung formatiert werden.

## Colspan und Rowspan

Die natürliche Eigenschaft einer Tabelle ist, dass alle Zellen einer Zeile gleich hoch und alle Zellen in einer Spalte gleich breit sind.
Zellen können sich aber über mehrere Spalten und Zeilen erstrecken.
Die Anzahl der überdeckten Spalten wird mit `colspan` angegeben, die Voreinstellung ist hier 1.
Die Anzahl der Zeilen wird mit `rowspan` angegeben, auch hier ist die Voreinstellung 1.
Hier muss beachtet werden, dass die Summe der Spalten in einer Zeile der Gesamtzahl entspricht.
Im nachfolgenden Beispiel enthält die zweite Zeile zwar nur zwei Zellen, diese erstreckt sich aber über zwei Spalten.
Die dritte Zeile hat sogar nur eine Zelldefinition, der Rest der Zeile wird durch das zwei Zellen breite Bild aus der Zeile darüber belegt (`rowspan="2"`).


```xml
    <PlaceObject>
      <Table width="10"
        columndistance="3mm"
        leading="2mm">
        <Tr>
          <Td padding-bottom="2mm">
            <Paragraph><Value>1/1</Value></Paragraph>
          </Td>
          <Td padding-left="1mm">
            <Paragraph><Value>1/2</Value></Paragraph>
          </Td>
          <Td align="center">
            <Paragraph><Value>1/3</Value></Paragraph>
          </Td>
        </Tr>
        <Tr background-color="yellow">
          <Td>
            <Paragraph><Value>2/1</Value></Paragraph>
          </Td>
          <Td rowspan="2" colspan="2" >
            <Image width="5" file="ocean.pdf"/>
          </Td>
        </Tr>
        <Tr align="center">
          <Td>
            <Paragraph><Value>3/1</Value></Paragraph>
          </Td>
        </Tr>
      </Table>
    </PlaceObject>
```
{{% codecaption %}}Ein etwas komplexeres Beispiel. Die Hintergrundfarbe des Bildes bestimmt sich aus der zweiten Zeile.{{% /codecaption %}}

![Auswirkung von rowspan und colspan](/img/tab-colspan-rowspan.png)

## Angabe der Spaltenbreiten

In den bisherigen Beispiele werden die Breiten der Zellen automatisch durch den Inhalt bestimmt.
Man kann auch die Spaltenbreiten fest vorgeben.
Der Befehl dazu lautet `Columns` und wird direkt als erster Befehl innerhalb von `Table` angeführt:

```xml
      <Table stretch="max">
        <Columns>
          <Column width="2mm"/>
          <Column width="1*"/>
          <Column width="3*"/>
        </Columns>
        <Tr>
          ...
        </Tr>
      </Table>
```

Hier wird festgelegt, dass die Tabelle drei Spalten hat.
Die erste Spalte hat eine Breite von 2mm, die zweite und die dritte Spalte teilen sich die übrige Breite im Verhältnis von 1 zu 3 auf. Es wird die Anzahl der Stern-Angaben berechnet und dann wird er verfügbare Platz anhand der Spaltenangaben im Verhältnis aufgeteilt.

Anstelle einer festen Breite oder eine Stern-Angabe kann man auch die Schlüsselwörter `min` und `max` angeben:

```xml
<Trace objects="yes" />
<Table>
    <Columns>
        <Column width="min" />
        <Column width="max" />
    </Columns>
    <Tr valign="top">
        <Td>
            <Paragraph>
                <Value>The quick brown fox</Value>
            </Paragraph>
        </Td>
        <Td>
            <Paragraph>
                <Value>The quick brown fox</Value>
            </Paragraph>
        </Td>
    </Tr>
</Table>
```

![Auswirkung von min und max bei Spaltenangaben](/img/tab-min-max.png)

`min` bei der Breitenangabe bedeutet dass die Spalte so schmal wie möglich wird, `max` bedeutet, dass die Spalte so breit wie nötig wird.

Zusätzlich zur Angabe von `min` oder `max` bei Spaltenbreiten kann man auch mit `minwidth` die minimale Breite einer Spalte bestimmen.

Ebenso kann mit einer "?" Angabe bei der Spalte der verfügbare Platz anhand der natürlichen Breite der Inhalte berechnet werden. Das ist im Zusammenhang mit festen Spaltenangaben sinnvoll:

```xml
<PlaceObject>
    <Table stretch="max" width="240pt" border-collapse="collapse">
        <Columns>
            <Column width="40pt" />
            <Column width="?" />
            <Column width="?" />
        </Columns>
        <Tr>
            <Td>
                <Paragraph><Value>40pt</Value></Paragraph>
            </Td>
            <Td>
                <Paragraph><Value>The quick</Value></Paragraph>
            </Td>
            <Td>
                <Paragraph>
                  <Value>The quick freezer jumps into the
                   kitchen and ate the brown fox.</Value>
                </Paragraph>
            </Td>
        </Tr>
    </Table>
</PlaceObject>
```

![Angaben von ?-Spalten lässt die Breiten wieder dynamisch berechnen](/img/tab-questionmark.png)

Im Befehl `Column` kann man noch weitere Angaben für die Spalte festlegen: die horizontale und vertikale Ausrichtung und die Hintergrundfarbe können vorgegeben werden.
Eine Angabe bei einer Zelle überschreibt die Vorgabe.

## Umbrüche in Tabellen

Ist die Tabelle zu hoch für die Seite, so umbricht sie und wird auf der nächsten Seite fortgesetzt.
Dabei wird der noch zur Verfügung stehende Platz auf der aktuellen Seite und auf den Folgeseiten beachtet.
Der Umbruch kann nach jeder Zeile eingefügt werden, sofern in der Zeile `break-below` nicht auf `yes` gesetzt ist.
Einzelne Tabellenzellen werden nicht getrennt.

Bei dem Tabellenumbruch kann man eigene Kopf- und Fußzeilen einfügen, die auf jeder Seite wiederholt werden.
Diese werden in den nächsten drei Abschnitten detailliert behandelt.

## Kopf- und Fußzeilen (statisch)

Es gibt zwei Arten, in Tabellen Tabellenköpfe zu definieren.
Die erste Variante wird in diesem Abschnitt vorgestellt.
Sie eignet sich besonders, wenn der Tabellenkopf zu Beginn bekannt ist (statisch).
Die zweite Variante eignet sich, wenn bestimmte Tabellenzellen als Kopfzeile dienen sollen (Abschnitte in Tabellen).
Beide Varianten kann man auch kombinieren.

Ausgangspunkt ist eine einfache Tabelle:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Record element="data">
    <PlaceObject>
      <Table>
        <Loop select="200">
          <Tr>
            <Td>
              <Paragraph>
                <Value>Tablecontents</Value>
              </Paragraph>
            </Td>
          </Tr>
        </Loop>
      </Table>
    </PlaceObject>
  </Record>
</Layout>
```

Die Kopfzeile definiert man in der Tabelle wie folgt (als Kindelement des Elements `<Table>`):

```xml
<Tablehead>
  <Tr background-color="gray">
    <Td>
      <Paragraph>
        <Value>Head</Value>
      </Paragraph>
    </Td>
  </Tr>
</Tablehead>
```

Man kann die Kopfzeile für die erste Seite separat definieren, in dem man das Attribut `page` spezifiziert (Voreinstellung ist `all`):

```xml
<Tablehead page="all">
  <!--1-->
</Tablehead>

<Tablehead page="first">
  <!--2-->
</Tablehead>
```
{{% codecaption %}}Schema für unterschiedliche Tabellenköpfe auf der ersten bzw. allen anderen Seiten. Die Reihenfolge der Deklaration ist nicht wichtig.{{% /codecaption %}}

1. Tabellenkopf für alle Seiten
2. Wenn `page="first"` wie hier definiert wird, gilt die obige Definition (1) für alle Seiten, jedoch nicht für die erste Seite, denn hier gilt (2).

Mit dieser Variante kann man nicht nur den (sich wiederholenden) Tabellenkopf bestimmen, sondern auch den Tabellenfuß.
Das geht analog zu `<Tablehead>`, nur dass bei der Seitenauswahl anstelle von `first` der Wert `last` erlaubt ist.

```xml
<Tablefoot page="last">
  <Tr background-color="gray">
    <Td>
      <Paragraph>
        <Value>Table foot last page</Value>
      </Paragraph>
    </Td>
  </Tr>
</Tablefoot>
<Tablefoot page="all">
  <Tr background-color="gray">
    <Td>
      <Paragraph>
        <Value>Table foot for all pages</Value>
      </Paragraph>
    </Td>
  </Tr>
</Tablefoot>
```

Tabellenköpfe und -füße müssen nicht nur aus einer Zeile bestehen.
Sie können auch Linien und mehrere Zeilen enthalten. Werden bestimmte Kopf- oder Fußbereiche leer gelassen (leeres Element), dann wird der Teil nicht angezeigt:

```xml
<Tablefoot page="last" />
<Tablefoot page="all">
  <Tr background-color="gray">
    <Td>
      <Paragraph>
        <Value>Table foot for all pages</Value>
      </Paragraph>
    </Td>
  </Tr>
</Tablefoot>
```
{{% codecaption %}}Der Tabellenfuß wird nicht auf der letzte Seite angezeigt, da das obere Element (`page="last"`) leer ist.{{% /codecaption %}}

## Kopf- und Fußzeilen (dynamisch)

Im vorherigen Abschnitt wird der Tabellenkopf über `<Tablehead>` (und dem Gegenstück `<Tablefoot>`) erzeugt.
Im Gegensatz dazu wird hier gezeigt, wie ein dynamischer Tabellenkopf erzeugt wird.
Beide Varianten können kombiniert werden.

```xml
<Tr sethead="yes" background-color="lightgray">
  <Td>
    <Paragraph>
      <Value>New head</Value>
    </Paragraph>
  </Td>
</Tr>
```

Die »Magie« steckt in `sethead="yes"` in der Tabellenzeile.
Dadurch wird diese Zeile auf der nächsten Seite ganz oben automatisch wiederholt, direkt unterhalb eines eventuell vorhandenen statischen Tabellenkopfs.
Das eignet sich sehr gut für Zwischenüberschriften oder Abschnitte in Tabellen.


## Beispiel

Ein etwas konstruiertes Beispiel.
Es gibt zwei Abschnitte in der Tabelle mit zwei und acht Zeilen. Die Datei `data.xml`:

```xml
<data>
  <section name="section 1" rows="2"/>
  <section name="section 2" rows="8"/>
</data>
```

Das Layout gibt eine Tabelle aus, für jeden Abschnitt wird die Überschrift als Zeile ausgegeben, in der das Attribut `sethead` auf `yes` gesetzt ist.
In einer Schleife werden die gewünschten Zeilen ausgegeben.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en">
  <Pageformat width="100mm" height="60mm"/>

  <Record element="data">
    <PlaceObject>
      <Table padding="1mm" stretch="max">
        <ForAll select="section">
          <Tr sethead="yes" background-color="lightgray">
            <Td>
              <Paragraph>
                <Value select="@name"/>
              </Paragraph>
            </Td>
          </Tr>
          <Loop select="@rows" variable="i">
            <Tr>
              <Td>
                <Paragraph>
                  <Value select="concat('Row ', $i)"/>
                </Paragraph>
              </Td>
            </Tr>
          </Loop>
        </ForAll>
      </Table>
    </PlaceObject>
  </Record>
</Layout>
```


![Die Abschnitte werden mit `sethead="yes"` markiert und werden im Tabellenkopf wiederholt.](/img/03-dyntabellenkopf.png)

## Kopf- und Fußzeilen mit Übertrag

Manchmal möchte man in Tabellen in Kopf- bzw. Fußzeilen eine Zwischensumme bzw. Übertrag (engl. etwa »running sum«) ausgeben.
Hier ist das Problem, dass das eine dynamische Information ist, die sich aus dem zur Verfügung stehenden Platz ergibt.
Ist die Seite kürzer, so ist die Summe eine andere.
Das heißt, dass man die Zahl nicht im Vorfeld als Kopf- oder Fußzeile definieren kann.

Dafür gibt es die Möglichkeit, Daten in einer Tabellenzeile zu speichern:

```xml
<Tr data="..." >
```

Diese Daten können später in Kopf- und Fußzeilen mit der speziellen Variablen `$_last_tr_data` abgefragt werden.
Die Variable wird bei jeder Benutzung von `data="..."` überschrieben.
Um dies zu illustrieren, gibt es ein vollständiges Layoutregelwerk, das diesen Mechanismus nutzt:

```xml
<Layout
  xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">
  <Pageformat width="80mm" height="80mm" />

  <Record element="data">
    <!-- Initialize value for the first header line -->
    <SetVariable variable="_last_tr_data" select="0"/>
    <SetVariable variable="sum" select="0"/>

    <PlaceObject>
      <Table stretch="max">
        <Tablehead>
          <Tr background-color="#eee">
            <Td>
              <Paragraph>
                <Value>Value of $_last_tr_data: </Value>
                <Value select="$_last_tr_data"/>
              </Paragraph>
            </Td>
          </Tr>
        </Tablehead>
        <Loop select="100" variable="i">
          <SetVariable variable="sum" select="$sum + $i"/>
          <Tr data="$sum">
            <Td>
              <Paragraph>
                <Value select="concat('i = ',$i)"/>
              </Paragraph>
            </Td>
          </Tr>
        </Loop>
      </Table>
    </PlaceObject>
  </Record>
</Layout>
```

![Die berechneten Zwischensummen](/img/22-runningsum.png)

Hier wird erst die Kopfzeile definiert, dann 100 Zeilen erzeugt (`<Loop select="100">`), die Schleifenzahl gespeichert und anschließend in jeder Zeile mit `data="$sum"` den errechneten Wert gespeichert, der später in der Kopfzeile ausgegeben wird.

{{< callout >}}
Die Breite der dynamischen Kopf- und Fußzeile wird ohne `$_last_tr_data` berechnet. Das kann zu Problemen führen, wenn die neu errechnete Kopf- oder Fußzeile ein anderes Format hat.
{{< /callout >}}

## Zusammenbauen von Tabellen

Tabellen werden manchmal nicht an einem Stück erzeugt.
Ein gängiges Muster bei der Erstellung von Tabellen ist die Probe, ob eine Tabelle noch an einen bestimmten Platz passt.
Dazu fügt man Zeile für Zeile an eine Tabelle an und platziert sie in eine Gruppe (eine virtuelle Fläche), um diese anschließend auszumessen.
Das Vorgehen hierfür ist folgendes:

```xml
<SetVariable variable="tabellenzeilenneu">
  <Copy-of select="$tabellenzeilen"/>
  <Copy-of select="$diesezeile"/>
</SetVariable>
```

Wobei `$diesezeile` jeweils eine Tabellenzeile mit Start- und Endetag `<Tr> .. </Tr>` enthält und `$tabellenzeilen` leer ist oder mehrere Zeilen derselben Form enthält.

Geprüft wird nun, in dem die Tabelle in einer Gruppe erzeugt wird und anschließend z. B die Höhe der Gruppe überprüft wird:

```xml
    <Group name="tbl">
      <Contents>
        <PlaceObject>
          <Table width="...">
            <Copy-of select="$tabellenzeilenneu"/>
          </Table>
        </PlaceObject>
      </Contents>
    </Group>

    <Switch>
      <Case test="sd:group-height('tbl') > ...">
        <!-- zu groß, Tabelle ohne die letzte Zeile ausgeben -->
        <PlaceObject>
          <Table width="...">
            <Copy-of select="$tabellenzeilen"/>
          </Table>
        </PlaceObject>
        <!-- letzte Zeile ist nun als Übertrag für die nächste Tabelle -->
        <SetVariable variable="tabellenzeilen">
          <Copy-of select="$diesezeile"/>
        </SetVariable>
      </Case>
      <Otherwise>
        <!-- passt, Tabelle ausgeben, Variable setzen -->
        <PlaceObject groupname="tbl"/>
        <SetVariable variable="tabellenzeilen">
            <Copy-of select="$tabellenzeilenneu"/>
        </SetVariable>
      </Otherwise>
    </Switch>
```
{{% codecaption %}}Mit diesem Muster kann man eine Tabelle zeilenweise vergrößern und ausmessen{{% /codecaption %}}

Eine etwas ausführlichere Beschreibung findet sich im Abschnitt [optimierung-mit-gruppen]({{< relref "optimizingwithgroups" >}}).

## Abwechselnde Zeilenfarben

Wechselnde Zeilenfarben werden häufig in Tabellen mit vielen Spalten benutzt, um eine Hilfe für das Auge beim Lesen der Tabelle zu geben.
Die Zeilenfarbe kann man durch `background-color="..."` bei `<Tr>` angeben.

```xml
<Table>
  <Loop select="5" variable="i">
    <Tr background-color="{sd:alternating('tab', 'white', 'gray')}">
      <Td>
        <Paragraph>
          <Value>Zeile </Value>
          <Value select="$i"/>
        </Paragraph>
      </Td>
    </Tr>
  </Loop>
</Table>
```
{{% codecaption %}}Wechselnde Zeilenfarben. Das erste Argument der Funktion  sd:alternating() ist eine Kennung, um verschiedene Alternierungen in einem Dokument zu unterscheiden.{{% /codecaption %}}

_Abwechselnde Hintergrundfarben_
![tab-wechselnde-zeilenfarben.png](/img/tab-wechselnde-zeilenfarben.png)

Der Trick ist hier die Anwendung der Layoutfunktion `sd:alternating()`, die zwischen den Argumenten wechselt.
Da das Attribut `background-color` einen festen Wert erwartet, muss mit den geschweiften Klammern in den »XPath-Modus« gesprungen werden.

Nach der Ausgabe der Tabelle ist nicht sichergestellt, dass beim nächsten Aufruf von `sd:alternating()` mit der Kennung `tab` wieder mit dem ersten Wert angefangen wird.
Das kommt darauf an, welcher Wert zuletzt benutzt wurde.
Um sicherzustellen, dass wieder bei dem ersten Wert angefangen wird, kann man bei `Table` das Attribut `eval="..."` nutzen:

```xml
<Table eval="sd:reset-alternating('tab')">
  ...
</Table>
```

Damit wird der Zähler für die angegebene Kennung (`tab`) zurückgesetzt.

### Abwechselnde Farben bei Seitenumbrüchen

Wenn eine Tabelle mit wechselnden Zeilenfarben über mehrere Seiten geht, werden die Farben in der Erzeugungsreihenfolge fortgesetzt. Das bedeutet, dass die erste Zeile auf einer neuen Seite mit der falschen Farbe beginnen kann. Um das Farbmuster auf jeder Seite neu zu starten, kann das Attribut `eval-on-split` am `<Table>`-Element verwendet werden:

```xml
<Table eval-on-split="sd:reset-alternating('tab')">
  <Loop select="100" variable="i">
    <Tr background-color="{sd:alternating('tab', 'white', 'gray')}">
      <Td>
        <Paragraph>
          <Value>Zeile </Value>
          <Value select="$i"/>
        </Paragraph>
      </Td>
    </Tr>
  </Loop>
</Table>
```

Der Ausdruck in `eval-on-split` wird bei jedem Seitenumbruch ausgewertet, bevor die Tabelle fortgesetzt wird. Er setzt den Alternierungszähler zurück, sodass `sd:alternating()` auf jeder neuen Seite wieder mit dem ersten Wert beginnt. Nach der Auswertung wird das `background-color`-Attribut jeder `<Tr>`-Zeile auf der neuen Seite aus dem Original-Layout-XML neu ausgewertet.

Dies funktioniert auch mit dynamischen Kopfzeilen (`sethead="yes"`) und Abschnittsüberschriften. Um z.B. eine graue Abschnittsüberschrift zu haben, die den Alternierungszähler zurücksetzt, wird der Reset direkt in das `background-color`-Attribut geschrieben:

```xml
<Tr background-color="{sd:reset-alternating('tab')}lightgray"
    sethead="yes">
  <Td>
    <Paragraph><Value>Abschnittsüberschrift</Value></Paragraph>
  </Td>
</Tr>
```

Hier wird `{sd:reset-alternating('tab')}` ausgewertet (als Seiteneffekt wird der Zähler zurückgesetzt) und der Ergebnis-String ist leer. Danach wird `lightgray` als eigentlicher Farbwert angehängt. Da `eval-on-split` das `background-color`-Attribut jeder Zeile neu auswertet, wird der Reset auch ausgeführt, wenn die Überschrift auf einer neuen Seite wiederholt wird.

{{< callout >}}
`eval-on-split` wertet nur das `background-color`-Attribut von `<Tr>`-Elementen neu aus. Wenn die Alternierungsfarbe auf `<Td>`-Ebene oder über `<SetVariable>` gesetzt wird, wird sie bei Seitenumbrüchen nicht neu berechnet. Damit `eval-on-split` funktioniert, muss der `sd:alternating()`-Aufruf im `background-color`-Attribut des `<Tr>`-Elements stehen.
{{< /callout >}}

## Hintergrund in Tabellenzeilen

### Text im Hintergrund

Mit den Attributen `background-...` kann man Text in den Hintergrund legen.

```xml
<Table width="7">
  <Tr>
    <Td background-text="Neu"
      background-size="contain"
      background-textcolor="gray"
      background-transform="rotate(-40deg)">
      <Paragraph>
        <Value select="sd:loremipsum()"/>
      </Paragraph>
    </Td>
  </Tr>
</Table>
```

![Text im Hintergrund einer Zelle](/img/21-bgtext.png)

### Bild hinter dem Text

Mit dem Befehl `<Overlay>` kann man Elemente übereinander legen.
In Tabellenzellen kann man das nutzen, um Text (wie Hinweise auf den Autor eines
Bildes) über ein Bild zu legen. Man kann aber auch ganze Texte hinterlegen. Ob
es sinnvoll ist, oder nicht, mag mal dahin gestellt sein.

```xml
<DefineFontfamily name="mini" fontsize="6" leading="8">
  <Regular fontface="TeXGyreHeros-Regular"/>
</DefineFontfamily>

<Record element="data">
  <PlaceObject>
    <Table width="7">
      <Tr>
        <Td>
          <Overlay>
            <Image width="4.5cm" file="_samplea.pdf"/>
            <Position x="100" y="10">
              <!-- Drehung um 90 Grad -->
                <Transformation matrix="0 1 -1 0 0 0"
                  origin-x="0" origin-y="100">
                  <Textblock width="4" fontfamily="mini">
                    <Paragraph textformat="left">
                      <Value>Foto: Reinhard M.</Value>
                    </Paragraph>
                  </Textblock>
                </Transformation>
            </Position>
          </Overlay>
        </Td>
      </Tr>
    </Table>
  </PlaceObject>
</Record>
```

![Tabellenzelle mit Text und einem Bild im Hintergrund](/img/21-overlay.png)

## Ausgleichen von Spalten

In der Regel benutzt eine Tabelle erst den ersten Positionierungsrahmen eines Bereichs, dann den nächsten etc.

![ch-tab-tables-notbalanced.png](/img/ch-tab-tables-notbalanced.png)

Schaltet man nun bei `<Table balance="yes">`, so wird die Tabelle wie folgt ausgegeben:

![ch-tab-tables-balanced.png](/img/ch-tab-tables-balanced.png)

Damit das funktioniert, muss die Tabelle in einem Platzierungsbereich ausgegeben werden, nicht auf einer Seite. Die Anzahl der Spalten, auf die ausgeglichen werden soll, bestimmt sich durch die Anzahl der Platzierungsrahmen, die der Bereich enthält. Hier ein konkretes Beispiel:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">
  <Trace grid="yes"/>
  <SetGrid nx="2" dx="5mm" height="12pt"/>
  <Pageformat width="140mm" height="100mm"/>
  <Pagetype name="page" test="true()">
    <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>
    <PositioningArea name="twocolumns">
      <PositioningFrame width="1" height="{sd:number-of-rows()}" row="1" column="1"/>
      <PositioningFrame width="1" height="{sd:number-of-rows()}" row="1" column="2"/>
    </PositioningArea>
  </Pagetype>

  <Record element="data">
    <PlaceObject area="twocolumns">
      <Table balance="no">
        <Loop select="20" variable="i">
          <Tr>
            <Td><Paragraph><Value>Row </Value><Value select="$i"/></Paragraph></Td>
          </Tr>
        </Loop>
      </Table>
    </PlaceObject>
  </Record>
</Layout>
```

Mit `balance="no"` wie im Beispiel gibt es eine volle erste Spalte:

![ch-tab-balanceno.png](/img/ch-tab-balanceno.png)

Setzt man hingegen `balance="yes"`, so wird daraus:

![ch-tab-balanceyes.png](/img/ch-tab-balanceyes.png)

Die Angabe wird immer auf der letzte Seite einer Tabelle beachtet, da die vorherigen Seiten den Platz sowieso vollständig ausfüllen.

## Seitenwechsel in Tabellen

Ist eine Tabelle größer als der zur Verfügung stehende Platz auf der Seite, so wird die Tabelle auf der nächsten Seite bzw. im nächsten Platzierungsrahmen fortgeführt. Um solch einen Seitenwechsel zu erzwingen, gibt es [den Befehl `<TableNewPage>`]({{< relref "/reference/tablenewpage" >}}).

## Tabellen und Schriftgröße

Um Tabellen mit kleiner Schriftgröße zu setzen, muss die Schriftfamilie in der Tabellendefinition auf eine kleine Schriftfamilie gesetzt werden:

```xml
<DefineFontfamily fontsize="6pt" leading="6pt" name="mini">
    <Regular fontface="sans" />
</DefineFontfamily>
<Trace objects="yes" />
<Record element="data">
    <PlaceObject>
        <Table fontfamily="mini">
            <Loop select="4">
                <Tr>
                    <Loop select="4">
                        <Td>
                            <Paragraph fontfamily="mini">
                                <Value>Covfefe</Value>
                            </Paragraph>
                        </Td>
                    </Loop>
                </Tr>
            </Loop>
        </Table>
    </PlaceObject>
</Record>
```

Falls das Attribut `fontfamily` im Befehl `<Table>` nicht angegeben wird, vergrößert sich der vertikale Leerraum. Das ist nur wichtig für Schriftgrößen kleiner als die Schriftfamilie `text` (10pt/12pt in der Voreinstellung).

