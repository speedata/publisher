---
title: "Creation of XML structures"
weight: 47
type: docs
---


The speedata Publisher can create, save and read in XML files.
This allows you to create tables of contents, cross-references and other applications.

The XML structure is not created directly, but indirectly via the two commands [`<Element>`]({{< relref "/reference/element" >}}) and [`<Attributes>`]({{< relref "/reference/attribute" >}}).
So the following XML file

```xml
<Root>
   <Greeting content="Hello, world!" />
</Root>
```

are generated from this structure in the layout rules:

```xml
<Element name="Root">
  <Element name="Greeting">
    <Attributes name="content" select="'Hello, world!'"/>
  </element>
</element>
```

can be generated.
Text content outside of attributes, such as mixed content, cannot be output with the Publisher.

