---
linktitle: "Makeindex"
weight: 550
type: docs
---

# `Makeindex`


Eine Liste von Elementen sortieren und aufteilen um einen Index zu erzeugen.



## Kindelemente

(keine)

## Elternelemente

<a href="../element"><code>Element</code></a>, <a href="../savedataset"><code>SaveDataset</code></a>

## Attribute


`pagenumber` (Text, optional, _seit Version 2.7.11_)
: Der Name des Attributs der die Seitenzahl enthält. Voreinstellung ist 'page'.



`section` (Text)
: Erzeuge ein XML-Element mit diesem Namen für jeden Abschnitt (Buchstabe) in dem Index.



`select` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}))
: Der XPath-Ausdruck der die Elementstruktur für den Index enthält (`$Variable`).



`sortkey` (Text)
: Der Name des Attributs das den Indexeintrag enthält (der sortiert werden soll).






## Beispiel


Die Indexerstellung funktioniert in zwei Schritten. Im ersten Schritt werden die Daten in eine Elementstruktur gespeichert und mit diesem Befehl sortiert. Im zweiten Schritt wird die Elementstruktur ausgegeben ([`LoadDataset`]({{% relref "loaddataset" %}})).



```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Record element="data">
    <SetVariable variable="indexeinträge">
      <Element name="indexeintrag">
        <Attribute name="name" select="'Giraffe'" />
        <Attribute name="page" select="1" />
      </Element>
      <Element name="indexeintrag">
        <Attribute name="name" select="'Garage'" />
        <Attribute name="page" select="2" />
      </Element>
      <Element name="indexeintrag">
        <Attribute name="name" select="'Grußwort'" />
        <Attribute name="page" select="3" />
      </Element>
      <Element name="indexeintrag">
        <Attribute name="name" select="'Aufzug'" />
        <Attribute name="page" select="4" />
      </Element>
    </SetVariable>

    <SetVariable variable="index">
      <Element name="Index">
        <Makeindex select="$indexeinträge/indexeintrag" sortkey="name" section="teil" />
      </Element>
    </SetVariable>
    <ProcessNode select="$index/Index"></ProcessNode>
  </Record>

  <Record element="Index">
    <ForAll select="teil">
      <PlaceObject>
        <Table width="3" stretch="max">
          <Tr>
            <Td border-bottom="0.4pt" colspan="2">
              <Paragraph>
                <Value select="@name" />
              </Paragraph>
            </Td>
          </Tr>
          <ForAll select="indexeintrag">
            <Tr>
              <Td>
                <Paragraph>
                  <Value select="@name" />
                </Paragraph>
              </Td>
              <Td>
                <Paragraph>
                  <Value select="@page" />
                </Paragraph>
              </Td>
            </Tr>
          </ForAll>
        </Table>
      </PlaceObject>
      <NextRow />
    </ForAll>
  </Record>
</Layout>

```



