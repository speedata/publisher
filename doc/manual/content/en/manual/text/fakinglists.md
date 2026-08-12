---
title: "Enumeration lists"
weight: 53
type: docs
---



The publisher has various options for creating enumeration lists.

## Enumeration lists with Ol and Ul

Numbered and unnumbered lists can be created with [`<Ul>`]({{< relref "/reference/commands/ul" >}}) and [`<Ol>`]({{< relref "/reference/commands/ol" >}}):

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

These enumeration lists cannot be nested within one another.

![olulstandard.png](/img/olulstandard.png)

## Enumeration lists with textformat

You can set a left margin or a hanging indent for text formats. This allows you to output bulleted lists:

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

## Enumeration lists with tables

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

## Enumeration lists with labels in Paragraph

The command [`<paragraph>`]({{< relref "/reference/commands/paragraph" >}}) can display characters to the left of the paragraph:

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

This can also be used for bulleted lists. This has the advantage that paragraphs can also be wrapped in the [`<output>`]({{< relref "/reference/commands/output" >}}) command.

![olulparlabel.png](/img/olulparlabel.png)

## Enumeration lists with HTML formatting

Here you have the option of nesting and specially formatting lists:

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

The lists and their markers can be styled with CSS, for example `li::marker` for the color and character of the bullet.
The details (indentation, supported properties, marker styling) are described in the section [Lists in HTML]({{< relref "/manual/webformats/html#lists-in-html" >}}).
