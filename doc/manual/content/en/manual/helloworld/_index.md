---
title: "Hello, world!"
weight: 20
type: docs
---


The classic: "Hello, world!".
Or: what does a simple document look like?

The Publisher always works with two files: a **data file** (`data.xml`) containing the content and a **layout file** (`layout.xml`) with the rules for how that content should appear in the PDF.
Both must be valid XML.
A good choice for editing them is an XML editor or the free [Visual Studio Code](https://code.visualstudio.com/) editor.

{{< callout >}}
Want to try this right away? Run `sp new helloworld` to create a directory with both files. Then `cd helloworld` and `sp` to generate the PDF.
{{< /callout >}}

![Hello World example on the command line](/img/helloworld.gif)

## The two files

The data file (`data.xml`) contains the data — here just a short text:

```xml
<data>Hello world!</data>
```

The layout file (`layout.xml`) describes what should happen with the data:

```xml
<Layout
  xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Record element="data">
    <PlaceObject>
      <Textblock>
        <Paragraph>
          <Value select="."/>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```

## Generating the PDF

Save both files in an empty directory, open a terminal in that directory and run the Publisher:

```shell
$ sp
```

The `$` represents the shell prompt and is not typed.
The result is a PDF file `publisher.pdf` with one page: the text "Hello world!" in the top left corner.

{{< callout >}}
For Windows users: if the Publisher cannot create the PDF, it may be because the same file is still open in another program (Adobe Reader, Windows Explorer).
{{< /callout >}}


## The example explained

The data file can have any structure as long as it is well-formed XML (see [Glossary]({{< relref "glossary" >}})).
In this case there is just one element `<data>` with the text content `Hello world!`.

The layout file step by step:

```xml
<Layout                                              <!--1-->
  xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Record element="data">                            <!--2-->
    <PlaceObject>                                     <!--3-->
      <Textblock>
        <Paragraph>
          <Value select="."/>                         <!--4-->
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```
1. The root element `Layout` with two namespaces. The second namespace (`sd:`) is not needed here yet, but should always be included — it is required for the built-in functions.
2. `Record` defines what should happen when the Publisher encounters the element `<data>` in the data file. Since `<data>` is the root element, this Record is called automatically at startup.
3. `PlaceObject` is the command to output something into the PDF — text, images, tables, boxes, etc.
4. `select="."` is an XPath expression: the dot `.` means "the current data element". Here the current element is `<data>`, and its text content is `Hello world!`. This is exactly the text that appears in the PDF.

## What's next?

The chapter [Programming]({{< relref "programming" >}}) explains in detail how layout and data work together — in particular the interplay of `Record` and `ProcessNode`, which allows processing nested data structures.
