---
title: "How to write the layout"
weight: 50
type: docs
---



## XML Editor

By using standard XML (UTF-8), the layout rules can be edited with any text editor.

The supplied XML schemas ([RELAX NG](https://en.wikipedia.org/wiki/RELAX_NG) and [XML Schema (XSD)](https://en.wikipedia.org/wiki/XML_Schema_(W3C))) make it easy to enter the layout ruleset. Such a schema can be thought of as a computer-readable instruction as to which commands may appear at which position in the layout. The instructions also contain information about the parameters that are permitted in each case. In addition, the scheme also provides help by briefly explaining each command and parameter. In short: if the editor can integrate this schema and also "understands" it, it is an input help that should not be underestimated. You reduce the number of errors and the input time significantly, editing the layout rules starts to be really fun (believe me).

To include this schema, you need to use a suitable XML editor that can process RELAX NG or XML Schemas, e.g:

-   [OxygenXML](https://www.oxygenxml.com) (Mac, Windows, Linux)
-   [Visual Studio Code](https://code.visualstudio.com) (Mac, Windows, Linux, free)

The first two editors provide excellent cross-platform support for the schema.

-   [XMLSpy](https://www.altova.com/xml-editor/) (Windows)
-   [XML Blueprint](https://www.xmlblueprint.com/) (Windows)
-   [GNU Emacs](https://www.gnu.org/software/emacs/) with [nxml-mode](https://www.gnu.org/software/emacs/manual/html_mono/nxml-mode.html) (cross platform, free)
-   [jEdit](http://www.jedit.org) (Mac, Windows, Linux, free)

The schema files for the layout rules are located in the ZIP file in the `share/schema/` directory under the file names

```
layoutschema-de.rng
layoutschema-en.rng
```

for RELAX NG and

```
layoutschema-de.xsd
layoutschema-en.xsd
```

for XSD, depending on the desired language of the documentation. Further information on the schema can be found in the chapter [Schema-Validierung]({{< relref "schema" >}}) and in the appendix [appendix-schema-assigning]({{< relref "schema" >}}).

##  Namespace of the layout ruleset

The XML namespace of the layout ruleset is `urn:speedata.de:2009/publisher/en`. The additional XPath functions are in the namespace `urn:speedata:2009/publisher/functions/en`. A layout set should therefore always have this frame:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
        xmlns:sd="urn:speedata:2009/publisher/functions/en">
 ...
</Layout>
```

Then you can call speedata's own functions with the prefix `sd:`, for example: `sd:current-page()` to determine the current page number.

