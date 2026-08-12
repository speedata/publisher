---
title: "Aufzählungslisten"
weight: 53
type: docs
---


Der Publisher hat verschiedene Möglichkeiten, Aufzählungslisten zu erstellen.

## Aufzählungslisten mit Ol und Ul

Nummerierte und nicht nummerierte Listen können mit [`<Ul>`]({{< relref "/reference/commands/ul" >}}) und [`<Ol>`]({{< relref "/reference/commands/ol" >}}) erstellt werden:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en">

    <Record element="data">
        <PlaceObject>
            <Textblock>
                <Ol>
                    <Li><Value>Lorem ipsum</Value></Li>
                    <Li><Value>dolor sit amet</Value></Li>
                    <Li><Value>consectetur adipisicing elit</Value></Li>
                    <Li><Value>sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</Value></Li>
                </Ol>
            </Textblock>
        </PlaceObject>
        <PlaceObject>
            <Textblock>
                <Ul>
                    <Li><Value>Lorem ipsum</Value></Li>
                    <Li><Value>dolor sit amet</Value></Li>
                    <Li><Value>consectetur adipisicing elit</Value></Li>
                    <Li><Value>sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</Value></Li>
                </Ul>
            </Textblock>
        </PlaceObject>
    </Record>
</Layout>
```

Diese Aufzählungslisten lassen sich nicht ineinander schachteln.

![olulstandard.png](/img/olulstandard.png)

## Aufzählungslisten mit Textformaten

Man kann einen linken Rand bzw. einen hängenden Einzug bei Textformaten einstellen. Damit kann man Aufzählungslisten ausgeben:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <DefineTextformat name="li" indentation="6pt" rows="-1"/>
  <Record element="data">
    <PlaceObject>
      <Textblock textformat="li">
        <Paragraph><Value>• </Value><Value select="sd:dummytext()"></Value></Paragraph>
        <Paragraph><Value>• Two</Value></Paragraph>
        <Paragraph><Value>• Three</Value></Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>

</Layout>
```

![olulwithtext.png](/img/olulwithtext.png)

Das funktioniert in der Praxis sehr gut. Der offensichtliche Nachteil ist, dass man ausmessen muss, wie breit der linke Rand sein soll.

## Aufzählungslisten mit Tabellen

Verschachtelte Listen können über Tabellen realisiert werden, wobei man beachten muss, dass innerhalb der Tabellenzellen ja nicht umbrochen werden kann.

```xml
<Record element="data">
  <PlaceObject>
    <Table stretch="max">
      <Columns>
        <Column width="5mm"/>
        <Column width="5mm"/>
        <Column width="1*"/>
      </Columns>
      <Loop select="3" variable="i">
        <Tr valign="top">
          <Td>
            <Paragraph>
              <Value select="$i"/><Value>. </Value>
            </Paragraph>
          </Td>
          <Td colspan="2">
            <Paragraph textformat="justified">
              <Value select="sd:dummytext()"/>
            </Paragraph>
          </Td>
        </Tr>
        <Loop select="3">
          <Tr valign="top">
            <Td></Td>
            <Td><Paragraph><Value>•</Value></Paragraph></Td>
            <Td><Paragraph textformat="justified">
                  <Value select="sd:dummytext()"/>
                </Paragraph>
            </Td>
          </Tr>
        </Loop>
      </Loop>
    </Table>
  </PlaceObject>
</Record>
```

![olulwithtables.png](/img/olulwithtables.png)

## Aufzählungslisten mit Absatzetiketten

Der Befehl [`<Paragraph>`]({{< relref "/reference/commands/paragraph" >}}) kann Zeichen links vor den Absatz anzeigen:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en">

    <Pageformat width="100mm" height="100mm" />

    <Record element="data">
        <PlaceObject>
            <Textblock>
                <Paragraph label-left="•" label-left-distance="2mm" padding-left="4mm">
                    <Value>Lorem ipsum</Value>
                </Paragraph>
                <Paragraph label-left="•" label-left-distance="2mm" padding-left="4mm">
                    <Value>Lorem ipsum</Value>
                </Paragraph>
                <Paragraph label-left="•" label-left-distance="2mm" padding-left="4mm">
                    <Value>dolor sit amet</Value>
                </Paragraph>
                <Paragraph label-left="•" label-left-distance="2mm" padding-left="4mm">
                    <Value>consectetur adipisicing elit</Value>
                </Paragraph>
                <Paragraph label-left="•" label-left-distance="2mm" padding-left="4mm">
                    <Value>sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</Value>
                </Paragraph>
            </Textblock>
        </PlaceObject>
    </Record>

</Layout>
```

Auch das kann für Aufzählungslisten benutzt werden. Das hat den Vorteil, dass im Befehl [`<Output>`]({{< relref "/reference/commands/output" >}}) Absätze auch umbrochen werden können.

![olulparlabel.png](/img/olulparlabel.png)

## Aufzählungslisten über HTML-Formatierung

Hier hat man die Möglichkeit, Listen zu schachteln und besonders zu formatieren:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en">

    <Pageformat width="100mm" height="100mm" />

    <Record element="data">
        <PlaceObject>
            <Textblock>
                <Paragraph>
                    <Value select="." />
                </Paragraph>
            </Textblock>
        </PlaceObject>
    </Record>
</Layout>
```

```xml
<data>
   <ul>
      <li>Lorem ipsum</li>
      <li>dolor sit amet</li>
      <li>consectetur adipisicing elit</li>
      <li>
         <ol>
            <li>sed do eiusmod tempor incididunt ut labore et
               dolore magna aliqua.</li>
            <li>Lorem ipsum</li>
            <li>dolor sit amet</li>
         </ol>
      </li>
   </ul>
</data>
```

![olulhtmlnested.png](/img/olulhtmlnested.png)

Für die Formatierung der Listen und ihrer Marker können CSS-Anweisungen genutzt werden, zum Beispiel `li::marker` für Farbe und Zeichen des Aufzählungspunkts.
Die Einzelheiten (Einzug, unterstützte Eigenschaften, Marker-Styling) beschreibt der Abschnitt [Listen in HTML]({{< relref "/manual/webformats/html#listen-in-html" >}}).
