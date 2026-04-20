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

Ein Hinweis auf das Kapitel [optimierung-mit-gruppen]({{< relref "optimizingwithgroups" >}}) sei noch erlaubt.
Dort wird die Optimierung mit einem Beispiel beschrieben.

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

