---
title: "Enumeration lists"
weight: 53
type: docs
aliases:
  - fakinglists
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

![olulstandard.png](/img/olulstandard.png)

Since version 5.9.7 the lists can be styled and nested. Lists inside `<Li>` are indented by the width of the enclosing list:

```xml
<Ul marker="–" label-width="4mm" label-distance="1mm">
    <Li><Value>Lorem ipsum</Value></Li>
    <Li>
        <Value>dolor sit amet</Value>
        <Ol marker="lower-alpha" start="3">
            <Li><Value>consectetur adipisicing elit</Value></Li>
            <Li><Value>sed do eiusmod tempor</Value></Li>
        </Ol>
    </Li>
</Ul>
```

The most important attributes of `<Ul>` and `<Ol>`:

* `marker`: the bullet character of `<Ul>` (any text or `disc`, `circle`, `square`, `none`) or the numbering style of `<Ol>` (`decimal`, `lower-alpha`, `upper-roman`, ...). Nested unordered lists use disc, circle and square in turn.
* `label-width`, `label-align` and `label-distance`: the space reserved for the marker to the left of the text and the position of the marker within it.
* `padding-left`: additional indentation of the whole list.
* `start`: the number of the first item of `<Ol>`.
* `textformat`: the textformat of the items, for example for vertical spacing.
* `fontfamily` and `color`.

Alternatively the lists can be styled with CSS in [`<Stylesheet>`]({{< relref "/reference/commands/stylesheet" >}}) via the attributes `class` and `id`. The rules for `ul` and `ol` support `list-style-type`, `list-style-position`, `padding-left` and `color`, the rules for `li::marker` support `content`, `color` and `padding-right`:

```xml
<Stylesheet>
    ul.notes { list-style-type: square; padding-left: 3mm; }
    ul.notes li::marker { color: darkred; }
</Stylesheet>
...
<Ul class="notes">
    <Li><Value>Lorem ipsum</Value></Li>
</Ul>
```

Attributes take precedence over CSS.

In PDF/UA documents the lists are tagged automatically: the list becomes an `L` structure element, every item an `LI` with `Lbl` for the marker and `LBody` for the text. Nested lists are placed inside the `LBody` of their item.

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
