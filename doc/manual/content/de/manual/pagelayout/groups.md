---
title: "Gruppen (virtuelle Objekte)"
weight: 39
type: docs
---


Eine der bedeutendsten Eigenschaften des Publishers ist die Möglichkeit, Objekte auf einer virtuellen Fläche (Group) zu platzieren, um sie anschließend auszumessen bzw. zusammenhängend zu platzieren.
Diese virtuelle Fläche hat zunächst keine Breite und keine Höhe.
Die Fläche passt sich den Ausmaßen des Inhalts an.
Somit lassen sich Fragen beantworten wie »Passt der Artikel (mit Bild und Beschreibung) noch auf die Seite?« oder »Wie sehr muss man die
Schriftgröße verkleinern, damit der ganze Text auf eine A4-Seite passt?«.

Ebenfalls ist es möglich, diese virtuelle Fläche mit einem eigenen Seitenraster zu versehen.
Damit lassen sich zum Beispiel Objekte feiner positionieren, als es mit einem gröberen Seitenraster der Hauptseite möglich ist.

Einige Dinge muss man beachten, wenn man die Gruppen einsetzt:

* Die Breitenangaben bei Textblöcken und Tabellen sind nun obligatorisch, da es kein »natürliches Maximum« gibt.
* Das Gruppenraster kann nicht mit `nx` und `ny` (Teilung) bestimmt werden, sondern nur mit festen Werten für Höhe und Breite.
* Bereiche können mit Gruppen nicht kombiniert werden. D. h. bei `<PlaceObject>` und ähnlichen Befehlen darf `area` nicht angegeben werden.
* Platzierungen in Gruppen dürfen nicht absolut (z. B. `row="2mm"`) erfolgen.


## Wie werden Gruppen benutzt?

```xml
<Layout
  xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Trace grid="yes" objects="yes"/>

  <Record element="data">
    <Group name="test">
      <Contents>
        <PlaceObject row="2" column="2">
          <Image width="3" file="_sampleb.pdf"/>
        </PlaceObject>
      </Contents>
    </Group>

    <Message select="sd:group-height('test')"/>

    <PlaceObject groupname="test"/>
  </Record>
</Layout>
```

![Die Gruppe nimmt den minimalen Platz in Anspruch.](/img/24-einfachegruppe.png)

Ist die Gruppe erzeugt, jedoch noch nicht platziert, dann kann man mit verschiedenen Layoutfunktionen die Maße der Gruppe ausmessen: `sd:group-width('gruppenname')` und `sd:group-height('gruppenname')` geben die Breite und Höhe in ganzen Rasterzellen aus.
Der Befehl `<Message>` im Beispiel oben gibt die Zahl 6 aus,  obwohl die Gruppe nur die Höhe von ca. 5,2 Zellen hat.
Der Publisher rechnet immer mit ganzen Rasterzellen.

Damit ist eigentlich schon alles gesagt, was zum Thema Gruppen gehört.
Die Anwendungsfälle sind sehr vielfältig.
Im Prinzip geht es hier immer um die Frage: wie groß sind diese Objekte?
Passen sie noch auf die Seite? Muss ich hier einen Umbruch einfügen? Und so fort.
Am besten spielt man ein wenig mit den virtuellen Bereichen, um sich damit vertraut zu machen.
Richtig benutzt sind sie ein mächtiges Werkzeug.

## Layout-Optimierung

Ein typischer Fall beim Database Publishing ist, dass man nicht weiß, welche Daten zu erwarten sind.
Texte sind unterschiedlich lang, Bilder haben andere Seitenverhältnisse, die Anzahl der Daten im Datensatz ist variabel und so fort.
Um trotzdem eine Darstellung zu erzeugen, die ansprechend ist (also gewissen Regeln folgt), kann man Abfragen stellen.
Neben statischen Fragen wie »Wie viele Artikel sind in der Artikelgruppe enthalten?« können dynamische Fragen beantwortet werden:

* Wie breit ist die Überschrift?
* Wie hoch ist das Bild?
* Passt die Tabelle noch auf die Seite?

Die Idee ist folgende: Man erzeugt eine Gruppe, platziert dort die Elemente, die man ausmessen möchte, und fragt anschließend, wie groß (Breite und Höhe) die virtuelle Fläche geworden ist, um daraufhin unterschiedlich zu reagieren.

Das Gerüst ist folgendes:

```xml
<Record element="data">
  <Group name="img">
    <Contents>
      <!--1-->
      <PlaceObject>
        <Image file="_samplea.pdf" width="4"/>
      </PlaceObject>
    </Contents>
  </Group>
  <!--2-->
  <Switch>
    <Case test="sd:group-height('img') > 5">
      ...
    </Case>
    <Otherwise>
      ...
    </Otherwise>
  </Switch>
</Record>
```
1. Zu Beginn hat die Gruppe eine Breite und Höhe von 0. Alle Objekte vergrößern die Fläche.
2. Die Gruppe hat nun eine Breite von 4 und eine unbekannte Höhe (abhängig vom Bild). Nun kann mit `sd:group-height()` die Höhe und `sd:group-width()` die Breite abgefragt werden. Was in der Fallunterscheidung passiert, ist natürlich vom konkreten Layout abhängig.

Das Prinzip ist immer dasselbe: die fraglichen Inhalte werden auf einen virtuellen Bereich gesetzt und ausgemessen.
Aufgrund der ermittelten Höhe oder Breite kann man z. B.

* die Gruppe einfach ausgeben,
* einen Seitenumbruch einfügen, wenn die Gruppe nicht mehr auf die Seite passt,
* die Gruppe in einer Schleife mit veränderten Parametern erneut erzeugen, bis eine Bedingung erfüllt ist (ein Beispiel für dieses Verfahren ist im Abschnitt [Virtuelle Seiten]({{< relref "virtualpages" >}}) gezeigt),
* eine Tabelle zeilenweise aufbauen und prüfen, ob sie noch passt (siehe [Zusammenbauen von Tabellen]({{< relref "/manual/tables#zusammenbauen-von-tabellen" >}})).

## Eigene Raster in Gruppen

Es folgt ein Beispiel für ein vom globalen Raster abweichendes Raster innerhalb einer Gruppe.
Ohne die explizite `<Grid ... />`-Angabe wird das Raster der Seite genommen.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <SetGrid nx="4" ny="4"/>
  <Trace grid="yes" gridallocation="yes" objects="yes"/>

  <Record element="data">
    <Group name="table">
      <Grid width="1cm" height="12pt"/>
      <Contents>
        <PlaceObject>
          <Table width="4" stretch="max">
            <Tr>
              <Td><Paragraph><Value>Cell 1/1</Value></Paragraph></Td>
              <Td><Paragraph><Value>Cell 2/1</Value></Paragraph></Td>
            </Tr>
            <Tr>
              <Td><Paragraph><Value>Cell 1/2</Value></Paragraph></Td>
              <Td><Paragraph><Value>Cell 2/2</Value></Paragraph></Td>
            </Tr>
          </Table>
        </PlaceObject>
        <PlaceObject row="4" column="2">
          <Image file="ocean.pdf" width="3"/>
        </PlaceObject>
      </Contents>
    </Group>

    <PlaceObject groupname="table"/>
  </Record>
</Layout>
```
{{% codecaption %}}Die Gruppe hat ein eigenes Raster, das vom Seitenraster unabhängig ist.{{% /codecaption %}}


![Ausschnitt aus einer Seite. Das Raster innerhalb der Gruppe ist deutlich feiner als das grobe Seitenraster.](/img/08-raster4.png)

## Tracing

Um das Debuggen des Layouts innerhalb einer Gruppe zu erleichtern, können Sie die Rastervisualisierung einschalten:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
	xmlns:sd="urn:speedata:2009/publisher/functions/en">
  <Pageformat height="6cm" width="9cm"></Pageformat>
  <Trace groups="yes" />

  <Record element="data">
    <Group name="foo">
      <Grid width="4mm" height="4mm"></Grid>
      <Contents>
        <PlaceObject>
          <Textblock width="11">
            <Paragraph>
              <Value>Hello world</Value>
            </Paragraph>
          </Textblock>
        </PlaceObject>
        <PlaceObject column="1" row="4">
          <Image width="3" file="_samplea.pdf" />
        </PlaceObject>
      </Contents>
    </Group>
    <PlaceObject groupname="foo" column="2" row="2" />
  </Record>
</Layout>
```

Das wird so angezeigt:

![Das Raster in der Gruppe kann angezeigt werden.](/img/group-tracing.png)

