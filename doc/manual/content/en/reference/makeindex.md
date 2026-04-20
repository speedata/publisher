---
linktitle: "Makeindex"
weight: 550
type: docs
---

# `Makeindex`


Sort and split a list of elements to make an index.



## Child elements

(none)

## Parent elements

<a href="../element"><code>Element</code></a>, <a href="../savedataset"><code>SaveDataset</code></a>

## Attributes


`pagenumber` (text, optional, _since version 2.7.11_)
: The name of the attribute that holds the page numbers. Defaults to 'page'.



`section` (text)
: Create an XML-element with this name for every section (letter) in the index.



`select` ([XPath expression]({{% relref "../manual/xpathref/xpath" %}}))
: The xpath expression ($variable) that holds the element structure for the index.



`sortkey` (text)
: The name of the attribute holding the indexentry (that should be sorted).






## Example


Index generation works in two steps: First, collect all the entries in a [`Element`]({{% relref "element" %}}) structure, then, while saving the generated structure, sort the keys and group them with this command.



```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Record element="data">
    <SetVariable variable="indexentries">
      <Element name="indexentry">
        <Attribute name="name" select="'Home'" />
        <Attribute name="page" select="1" />
      </Element>
      <Element name="indexentry">
        <Attribute name="name" select="'House'" />
        <Attribute name="page" select="2" />
      </Element>
      <Element name="indexentry">
        <Attribute name="name" select="'Hello'" />
        <Attribute name="page" select="3" />
      </Element>
      <Element name="indexentry">
        <Attribute name="name" select="'Garage'" />
        <Attribute name="page" select="4" />
      </Element>
    </SetVariable>
    <SetVariable variable="index">
      <Element name="Index">
        <Makeindex select="$indexentries/indexentry" sortkey="name" section="part" />
      </Element>
    </SetVariable>
    <ProcessNode select="$index/Index"/>
  </Record>

  <Record element="Index">
    <ForAll select="part">
      <PlaceObject>
        <Table width="3" stretch="max">
          <Tr>
            <Td border-bottom="0.4pt" colspan="2">
              <Paragraph><Value select="@name" /></Paragraph>
            </Td>
          </Tr>
          <ForAll select="indexentry">
            <Tr>
              <Td>
                <Paragraph><Value select="@name" /></Paragraph>
              </Td>
              <Td>
                <Paragraph><Value select="@page" /></Paragraph>
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



