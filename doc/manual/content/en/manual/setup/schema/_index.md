---
title: "Schema validation"
weight: 60
type: docs
---



A special feature of the speedata Publisher is that the input language is formulated in XML. Compared to other programming languages, XML is "chatty": You always have to write end tags for the start tags:

```xml
<PlaceObject>
   ...
</PlaceObject>
```

Compared to a C-like syntax like

```
placeObject(...)
```

this is more typing. The solution to this "problem" is to use a text editor that is good with XML. For example, entering a start tag would immediately insert the end tag. Or, if the tag name was changed, both the start tag and the end tag would be changed at the same time. Good XML editors do much more than just make it easier to enter tags, for example, to validate code against a schema.

## What is a schema?

A schema (e.g. [XML-Schema](https://de.wikipedia.org/wiki/XML_Schema) or [RELAX NG](https://de.wikipedia.org/wiki/RELAX_NG)) contains information about the permitted structure of an XML file. For example, the schema that is supplied with the speedata Publisher contains the following information:

* The root element must be called `<Layout>`
* The child element of `<PlaceObject>` must be either `<Barcode>`, `<Box>`, `<Circle>`, `<Frame>`, `<Image>`, `<Rule>`, `<Table>`, `<Textblock>` or `<Transformation>`.
* The attribute valign in the table row can be one of the values top, middle, or bottom
* and many more

The documentation of the individual commands and the selection options is also included in the supplied schematic. A good XML editor can import such a schema and make it *much easier* for the user to enter the source code. The input with a good schema is a lot of fun and has some advantages over the classic text editor:

* Syntax errors are displayed immediately
* Commands (tags) do not have to be entered completely, because the editor offers an auto-complete function
* The attributes are immediately checked for meaningful values
* Documentation is available directly in the editor

\... basically what you expect from an integrated development environment (IDE).

![Selection of allowed child elements](/img/29-autocomplete1.png)

![Allowed attributes for text block](/img/29-autocomplete2.png)

## Suitable editors

To use the schema you need an XML editor that can process RELAX NG or XML Schema (XSD), for example:

-   [OxygenXML](https://www.oxygenxml.com) (Mac, Windows, Linux)
-   [Visual Studio Code](https://code.visualstudio.com) (Mac, Windows, Linux, free)
-   [XMLSpy](https://www.altova.com/xml-editor/) (Windows)
-   [XML Blueprint](https://www.xmlblueprint.com/) (Windows)
-   [GNU Emacs](https://www.gnu.org/software/emacs/) with [nxml-mode](https://www.gnu.org/software/emacs/manual/html_mono/nxml-mode.html) (cross platform, free)
-   [jEdit](http://www.jedit.org) (Mac, Windows, Linux, free)

## Integration of the schemata

The schema files are located in the ZIP file in the `share/schema/` directory under the file names

```
layoutschema-de.rng
layoutschema-en.rng
```

for RELAX NG and

```
layoutschema-de.xsd
layoutschema-en.xsd
```

for XSD, depending on the desired language of the documentation.

How the schema is included depends on the editor.
There are step-by-step instructions for various editors ([oXygen XML Editor]({{< relref "oxygenxmlschema" >}}) or [Visual Studio Code]({{< relref "vscodeschema" >}})).
