---
title: "Marken"
weight: 45
type: docs
---


Marker sind unsichtbare Zeichen, die in den Text eingefügt werden.
Diesen Zeichen wird immer ein Name zugeordnet.
Nach Ausgabe des Zeichens auf einer Seite kann man den Publisher nach der Seitenzahl fragen.
Der Aufbau ist folgendermaßen:

```xml
<PlaceObject>
  <Textblock>
    <Mark select="'textstart'"/>
    <Paragraph>
      <Value>
      Row
      Row
      Row
      Row
       </Value>
    </Paragraph>
  </Textblock>
</PlaceObject>
```

Nach Ausgabe der Seite ist nun mit `sd:pagenumber('textstart')` die Seitennummer ermittelbar.

Die Marker werden automatisch in einer internen Hilfsdatei `publisher.aux` gespeichert, so dass bei einem weiteren Durchlauf auf die Seitenzahlen über `sd:pagenumber()` bereits vor dem Platzieren der Seite verfügbar sind.
Als Beispiel wird eine einfache Textstruktur genommen (es ist dasselbe Beispiel wie im nächsten Abschnitt):

```xml
<data>
  <chapter title="Foreword">
    <text>...</text>
  </chapter>
  <chapter title="Introduction">
    <text>...</text>
  </chapter>
  <chapter title="Conclusion">
    <text>...</text>
  </chapter>
</data>
```

Die mit dem folgenden Layout ausgegeben wird:

```xml
<Layout
  xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <DefineFontfamily name="title" fontsize="18" leading="20">
    <Regular fontface="sans"/>
  </DefineFontfamily>

  <Record element="data">
    <!-- This point will be completed further below -->
    <ProcessNode select="chapter"/>
  </Record>

  <Record element="chapter">
    <PlaceObject>
      <Textblock>
        <Mark select="@title"/>
        <Paragraph fontfamily="title">
          <Value select="@title"/>
        </Paragraph>
        <Paragraph>
          <Value select="text"/>
        </Paragraph>
      </Textblock>
    </PlaceObject>
    <ClearPage/>
  </Record>
</Layout>
```
{{% codecaption %}}Das Grundgerüst für die Marker. Die Stelle für das Inhaltsverzeichnis wird später erweitert (siehe Kommentar).{{% /codecaption %}}

Der Publisher ordnet nun die Kapitel der Seitenzahl zu. Man kann nun das Verzeichnis im nächsten Durchlauf ausgeben:

```xml
  <PlaceObject>
    <Table padding="5pt">
      <ForAll select="chapter">
        <Tr>
          <Td><Paragraph><Value select="@title"/></Paragraph></Td>
          <Td><Paragraph>
               <Value select="sd:pagenumber(@title)"/> <!--1-->
          </Paragraph></Td>
        </Tr>
      </ForAll>
    </Table>
  </PlaceObject>
  <ClearPage/>
```
{{% codecaption %}}Dieser Teil wird in das Layout oben eingefügt, um das Inhaltsverzeichnis auszugeben.{{% /codecaption %}}

1. In einem weiteren Durchlauf stehen die Seitenzahlen zur Verfügung, bevor die eigentlichen Kapitel auf die Folgeseiten geschrieben werden.

