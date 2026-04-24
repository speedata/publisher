---
title: "XPath Expressions"
weight: 160
type: docs
---

## What is XPath?

XPath is a language for navigating XML trees and querying data.
Since the Publisher's input data is in XML format, XPath is the central tool for accessing elements, attributes and text.
Examples: "give me all articles with a certain attribute" or "how many articles are in this article group?".

For a general introduction to XPath, see the [tutorial at W3Schools](https://www.w3schools.com/xml/xpath_intro.asp).

## Where are XPath expressions used?

The Publisher accepts XPath expressions in two places:

1. **In the attributes `select` and `test`** — the value is interpreted directly as XPath.
2. **In all other attributes** — curly braces (`{` and `}`) force an XPath expression.

```xml
<Textblock width="{ $width }">
  <Paragraph>
    <Value select="."/>
  </Paragraph>
</Textblock>
```
{{% codecaption %}}The width is read from the variable `$width`, the paragraph content is the text value of the current data node.{{% /codecaption %}}


## Supported expressions

* **Numbers and text**: `"5"`, `'hello world'` — returned directly.
* **Arithmetic operations**: `*`, `div`, `idiv`, `+`, `-`, `mod`. Example: `( 6 + 4.5 ) * 2`
* **String concatenation**: `||` concatenates strings. Example: `'Hello' || ' ' || 'World'` returns `Hello World`.
* **Variables**: `$column + 2`
* **Current node** (dot operator): `. + 2`
* **Child elements**: `productdata`, `*`, `foo/bar`, `node()`
* **Parent node**: `../`
* **Attributes**: `@a`, `foo/@bar`
* **Filters**: `article[1]` selects the first `article` child element.
* **Comparisons**: `<`, `>`, `<=`, `>=`, `=`, `!=`. Note: `<` must be written as `&lt;` in XML.
* **If/then/else**: `if (...) then ... else ...`
* **For expressions**: `for $i in (1,2,3) return $i * 2` or `for $i in 1 to 3 return $i * 2`
* **Arrays**: `[1, 2, 3]` or `array { 1 to 3 }`. Access via lookup: `$arr?2`. See [Arrays and Maps]({{< relref "datastructures" >}}).
* **Maps**: `map { 'name': 'value' }`. Access via lookup: `$map?name`. See [Arrays and Maps]({{< relref "datastructures" >}}).
* **Axes**: `preceding-sibling`, `parent`, `descendant-or-self`, `following-sibling` etc.


## XPath and namespaces

The speedata Publisher ignores XML namespaces by default. This is usually very helpful, as namespaces are not always easy to handle.

The XML file:

```xml
<bar:data xmlns:bar="somenamespace">
    <bar:child>
        <bar:sub>sub</bar:sub>
    </bar:child>
</bar:data>
```

can be addressed in the layout as follows:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en">

    <Record element="data">
      ...
```

although the namespace of the root element is `somenamespace`.

With `<Options namespaces="strict" />` you can change this so that the namespace must be specified for [`<Record>`]({{< relref "/reference/record" >}}) and [`<ProcessNode>`]({{< relref "/reference/processnode" >}}):

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en"
    xmlns:sn="somenamespace">

    <Options namespaces="strict" />

    <Record element="sn:data">
        <PlaceObject>
            <Textblock>
                <Paragraph>
                    <Value select="local-name()"></Value>
                </Paragraph>
            </Textblock>
        </PlaceObject>
    </Record>
</Layout>
```

It is important that the namespace matches, the prefix (here: `sn`) is freely selectable as long as it is linked to the namespace.

[`<ProcessNode>`]({{< relref "/reference/processnode" >}}) works similar:

```xml
<ProcessNode select="*:child" />
<ProcessNode select="sn:child" />
<ProcessNode select="sn:*" />
<ProcessNode select="*" />
```

call the child element `bar:child`, as the namespaces of `sn` (from the layout) and `bar` (from the data) match. `*` is a 'wildcard' here, so it matches all names.

`<ProcessNode select="child" />` will not work in the above case, as the empty namespace from the layout is `urn:speedata.de:2009/publisher/en` and does not match the namespace from the data.

You must also use namespaces in the XPath queries if they are specified in the data:

```xml
<Message select="count(sn:sub)" />
```

writes 1 to the log file. Without namespace a 0, as no element sub with the preset namespace is found.
