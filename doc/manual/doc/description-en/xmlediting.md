title: How to edit the layout file
---
How to edit the layout file
===========================

The layout file is encoded in standard XML (UTF-8) and therefore it can
be edited with any text editor
([notepad++](http://notepad-plus-plus.org) for example). We provide a
full RelaxNG grammar which makes editing the layout XML with a good XML
editor a breeze. We know of the following editors that allow XML editing
with the support of RelaxNG. If you know of any other XML editors with
RelaxNG support, please drop us a note at
[info@speedata.de](mailto:info@speedata.de).

-   [OxygenXML](https://www.oxygenxml.com) (Mac, Windows, Linux)
-   [XMLSpy](http://www.altova.com/xml-editor/) (Windows)
-   [XML Blueprint](http://www.xmlblueprint.com/) (Windows only)
-   [GNU Emacs](https://www.gnu.org/software/emacs/) with [nxml-mode](http://www.thaiopensource.com/nxml-mode/) (all operating systems, free)
-   [jEdit](http://www.jedit.org) (Mac, Windows, Linux, free)

The schema for editing the layout XML can be found in the directory
`share/schema` in the file `layoutschema-en.rng`.

Note
----

The XML namespace of the layout rules is
`urn:speedata.de:2009/publisher/en`. The layout XML must look like this
if you wish to validate against the Schema:

    <Layout xmlns="urn:speedata.de:2009/publisher/en">
     ...
    </Layout>

To use layout specific functions, you should add the following namespace
declaration to the start tag:

    <Layout xmlns="urn:speedata.de:2009/publisher/en"
            xmlns:sd="urn:speedata:2009/publisher/functions/en">
     ...
    </Layout>

Connecting the RelaxNG Schema with the Layout XML in the OxygenXML editor
-------------------------------------------------------------------------

As an example, here is how to make OxygenXML automatically choose the
right Schema if you edit the layout xml file. The fastest way is to
manually connect the document to the schema:

{{ img . "oxygen-associateschema.png"}}

(You can click on any screenshot for a larger version.)

Better is to use the more persistent solution. You can associate all
documents in the namespace `urn:speedata.de:2009/publisher/en` with the
RelaxNG schema.

To do this, you need to create a new rule in “document type association”.

{{ img . "oxygen-associatedoc1.png"}}

Fill out the form as in the next screenshot:

{{ img . "oxygen-associatedoc.png"}}

and click on the `+` button to create the rule like this:

{{ img . "oxygen-associatenamespace.png"}}

After that, you need to supply the path to the RelaxNG schema file
(here: a local installation).

{{ img . "oxygen-associateschema2.png"}}

The dialog must be confirmed with `OK`. If you now open a layout XML
file, it should be automatically connected to the schema and you get
full editor support (command completion, tool tip help, validation).

If the XML editor support RelaxNG with Schematron, it is advisable to activate
that support for enhanced error reporting while editing.

