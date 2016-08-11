title: First steps with the speedata Publisher (hello world)
---


First steps with the speedata Publisher (hello world)
=====================================================

{{ img . "schema1.png" }}

The speedata Publisher is a so-called "database publishing system". That means
that the source of the publishing process is a data set. The output of the
software is PDF. The layout of data in the PDF is controlled via an XML file,
the layout file. The data also has to be in the XML format, therefore it might
be necessary to convert other formats (Excel spreadsheet, database) into XML
before starting the publishing process.

This introduction coves the classical "hello world" example.

Data file
---------

There are no special requirements for the structure of the data XML source. As long as it is [well-formed](https://en.wikipedia.org/wiki/Well-formed_document), the speedata Publisher will handle it. For our example the following data file is perfect:

    <root greeting="Hello world"/>

Save this with the file name `data.xml` in an empty directory on your harddrive.

Layout file
------------

The layout file (file name `layout.xml`) contains the instructions for how the data should be laid out. The root element is the element with the name `Layout` with the namespace `urn:speedata.de:2009/publisher/en`. A minimal (and pointless) layout file is:

    <Layout xmlns="urn:speedata.de:2009/publisher/en" />

The XML file contains a declarative part (master pages, color definitions and similar) and a data processing part (read child elements and attributes and act upon the data). Both parts can be mixed.

Data processing starts with the command `Record`:


    <Record element="(name of the root element)">
         ... instructions for the root element ...
    </Record>


The instruction to place an object in the PDF is called (surprise!) [`PlaceObject`](../commands-en/placeobject.html). It expects the kind of object as its child element ([Image](../commands-en/image.html), [Box](../commands-en/box.html), [Rule](../commands-en/rule.html), [Frame](../commands-en/frame.html), [Barcode](../commands-en/barcode.html), [Table](../commands-en/table.html), [Textblock](../commands-en/textblock.html), [Transformation](../commands-en/transformation.html)). Textblock (a rectangular shaped text with a fixed width) expects one or more paragraphs as its child elements. The content of the paragraph is encapsulated in the element `<Value>text that appears in the PDF</Value>`. Instead of giving the text within the element [Value](../commands-en/value.html), it is possible to use a subset of [XPath](xpath.html) expressions to select data from the data source. For example the familiar `@` notation for attribute access.

The complete hello world example is simple:

    <Layout
      xmlns="urn:speedata.de:2009/publisher/en"
      xmlns:sd="urn:speedata:2009/publisher/functions/en">

      <Record element="root">
        <PlaceObject>
          <Textblock>
            <Paragraph>
              <Value select="@greeting"/>
            </Paragraph>
          </Textblock>
        </PlaceObject>
      </Record>
    </Layout>

More examples can be found in the folder [manual/examples-en](../examples-en/index.html) in the distribution.

Running the speedata Publisher
------------------------------

If both files are saved in the same directory, the PDF file can be generated with the commmand:

    sp

The result is written to the file `publisher.pdf`.

{{ img . "helloworldframe.png" }}

The names of the data source and the layout rules can be set on the command line:

    sp --data <name of the data file.xml> --layout <name of the layout file.xml>

or you can fix the file names in the file `publisher.cfg`:

    data=<datafile.xml>
    layout=<layoutfile.xml>

More information on the subject in [Using the speedata Publisher](publisherusage.html) and [Running the speedata publisher on the command line](commandline.html).
