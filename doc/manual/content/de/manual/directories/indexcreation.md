---
title: "Sortieren und Gruppieren"
weight: 47
type: docs
---


Der speedata Publisher bietet zwei Befehle, um Daten im Layout zu sortieren:
[`<SortSequence>`]({{< relref "/reference/commands/sortsequence" >}}) für die einfache Sortierung und [`<Makeindex>`]({{< relref "/reference/commands/makeindex" >}}), der zusätzlich gruppiert und sich damit für Stichwortverzeichnisse eignet.
Reichen diese Möglichkeiten nicht aus, muss die Sortierung vorab über ein externes Programm wie XSLT durchgeführt werden.

## Sortieren mit SortSequence

Unter der Annahme, dass die Datendatei (`data.xml`) wie folgt aussieht:

```xml
<data>
  <item value="one"/>
  <item value="two"/>
  <item value="three"/>
</data>
```

Die Daten können nun mit `<SortSequence>` sortiert werden. Die ursprünglichen Daten werden dabei nicht verändert:

```xml
<Layout
  xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Record element="data">
    <SetVariable variable="unsorted" select="*"/>
    <SetVariable variable="sorted">
      <SortSequence select="$unsorted" criterion="value"/>
    </SetVariable>
    <PlaceObject>
      <Textblock>
        <ForAll select="$sorted">
          <Paragraph><Value select="@value"/></Paragraph>
        </ForAll>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```

## Stichwortverzeichnisse mit Makeindex

In der Regel sind Stichwortverzeichnisse am Ende eines Dokuments zu finden, um in gedruckten Werken relevante Seiten schnell aufzufinden.
Bei diesen Stichworten kann es sich um Wörter oder auch um Artikelnummern oder andere Bezeichnungen handeln.

Im Gegensatz zum Inhaltsverzeichnis (das meist vorne in einer Publikation ist), müssen die Daten nur zusammengestellt werden, ein Zwischenspeichern für den nächsten Lauf entfällt in der Regel.


### Beispiel

![Stichwortverzeichnis aus dem Beispiel](/img/stichwortverzeichnis.png)

Die Beispiele sind naturgemäß immer etwas konstruiert, das ist hier ganz besonders der Fall.
Der Index wird in der Praxis natürlich anders zusammengestellt.
Da hier nur die Sortierung gezeigt werden soll, wird das Stichwort und die Seitenzahl vorgegeben. Die Dateien sind auch im [Beispiele-Repository](https://github.com/speedata/examples/tree/master/technical/index) zu finden.

```xml
<data>
  <keyword word="Giraffe" page="1"/>
  <keyword word="Garage" page="2"/>
  <keyword word="Greeting" page="3"/>
  <keyword word="Elevator" page="4"/>
</data>
```

Die Layoutdatei besteht aus drei Abschnitten, die einzeln erläutert werden.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Record element="data"> <!--1-->
    ...
  </Record>

  <Record element="keyword"> <!--2-->
    ...
  </Record>

  <Record element="index"> <!--3-->
    ...
  </Record>
</Layout>
```
{{% codecaption %}}Das Gerüst für die Sortierung und Ausgabe des Stichwortverzeichnisses{{% /codecaption %}}

1. Der Rahmen, der erst die Einträge zusammenbaut, sortiert und anschließend ausgibt.
2. Hier werden die Einträge einzeln in der Variablen `indexentries` gespeichert.
3. Die sortierten Einträge werden in einer Tabelle ausgegeben.

Der Abschnitt `data` ist der erste Teil aus dem vorherigen Listing:

```xml
  <Record element="data">
    <SetVariable variable="indexentries"/> <!--1-->
    <ProcessNode select="keyword"/>

    <SetVariable variable="index">  <!--2-->
      <Element name="index">
        <Makeindex select="$indexentries/indexentry" sortkey="name" section="section"
                   pagenumber="page" />
      </Element>
    </SetVariable>

    <ProcessNode select="$index/index"/>  <!--3-->
  </Record>
```
1. Eine leere Variable `indexentries` wird deklariert. Diese wird im Record `entry` mit den einzelnen Elementen gefüllt (s.u.).
2. Die nun gefüllte Variable `indexentries` wird um das Eltern-Element `Index` ergänzt, sortiert und in `$index` gespeichert.
3. Hier wird der Inhalt der Variablen `$index` als Datenstruktur interpretiert und ausgeführt (siehe die Ergänzung unten).

Der Befehl `<Makeindex>` sortiert und gruppiert die Daten, die im Attribut `select` übergeben werden. Die Sortierung erfolgt anhand des Attributs, das bei `sortkey` angegeben ist. Die Gruppierung erfolgt anhand des ersten Buchstabens des Sortierschlüssels. Die Elementstruktur, die mit dem Befehl `<Makeindex>` aufgebaut wird, ist folgende:

```xml
<index>
  <section name="E">
    <indexentry name="Elevator" page="4"/>
  </section>
  <section name="G">
    <indexentry name="Garage" page="2"/>
    <indexentry name="Giraffe" page="1"/>
    <indexentry name="Greeting" page="3"/>
  </section>
</index>
```

Der Abschnitt zum Element `keyword` (einfügen an Stelle 1 im Listing ) ist einfach gehalten, und entspricht dem »Copy-of« Muster (siehe [Copy-of]({{< relref "programming#copy-of" >}})). Hier wird die Variable `indexentries` um jeweils einen Eintrag ergänzt.

```xml
  <Record element="keyword">
    <SetVariable variable="indexentries">
      <Copy-of select="$indexentries/indexentry"/> <!--1-->
      <Element name="indexentry">
        <Attribute name="name" select="@word"/> <!--2-->
        <Attribute name="page" select="@page"/>
      </Element>
    </SetVariable>
  </Record>
```
1. Der Pfad `$indexentries/indexentry` (statt nur `$indexentries`) hält die Liste flach; nur so bekommt `<Makeindex>` später alle Einträge zu sehen.
2. In der aktuellen Publisher-Version muss der Eintrag, der sortiert wird, in einem Attribut mit dem Namen `name` gespeichert werden.

Im letzten Teil wird die Tabelle ausgegeben (einfügen an Stelle 3 im Listing ).
Für jeden Abschnitt (Element `section` in `<Makeindex>`) wird eine Zeile in Hellgrau ausgegeben mit dem Sortierschlüssel.
Anschließend wird für jeden Eintrag innerhalb dieses Abschnittes eine Zeile mit dem Namen des Eintrags und der Seitenzahl ausgegeben.

```xml
<Record element="index">
  <PlaceObject column="1">
    <Table width="3" stretch="max">
      <ForAll select="section">
        <Tr break-below="no" top-distance="10pt">
          <Td colspan="2" background-color="lightgray">
            <Paragraph><Value select="@name"></Value></Paragraph>
          </Td>
        </Tr>
        <ForAll select="indexentry">
          <Tr>
            <Td>
              <Paragraph><Value select="@name"/></Paragraph>
            </Td>
            <Td align="right">
              <Paragraph><Value select="@page"/></Paragraph>
            </Td>
          </Tr>
        </ForAll>
      </ForAll>
    </Table>
  </PlaceObject>
</Record>
```
