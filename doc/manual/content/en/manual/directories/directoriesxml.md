---
title: "Creating lists (XML structure)"
weight: 46
type: docs
---


In the previous chapter, lists were created using markers.
In this chapter a mechanism is used which means a bit more manual work, but is more flexible.

The speedata Publisher can create any type of list or index.
Whether table of contents, article list or keyword index - all lists work on the same principle:
the necessary data (e.g. page numbers, article numbers) are explicitly stored in a separate data structure, written to disk.
The next time the Publisher is run, this data is read in and is available.

## Step 1: Collecting the information

The two commands [`<Element>`]({{< relref "/reference/element" >}}) and [`<Attribute>`]({{< relref "/reference/attribute" >}}) are used to structure data that is read during processing.
This has already been described in the chapter [elementattribute]({{< relref "elementattribut" >}}).
These commands can be used to create new XML data set files.
The following structure could be useful for an article list:

```xml
<articlelist>
  <article number="1" page="10"/>
  <article number="2" page="12"/>
  <article number="3" page="14"/>
</articlelist>
```

To create this structure in the layout rules, it must be composed of the commands `<Element>` and `<Attributes>` as follows

```xml
<Element name="articlelist">
  <Element name="article">
    <Attribute name="number" select="1"/>
    <Attribute name="page" select="10"/>
  </Element>
  <Element name="article">
    <Attribute name="number" select="2"/>
    <Attribute name="page" select="12"/>
  </Element>
  <Element name="article">
    <Attribute name="number" select="3"/>
    <Attribute name="page" select="14"/>
  </Element>
</Element>
```

## Step 2: Saving and loading the information

With the command [`<SaveDataset>`]({{< relref "/reference/savedataset" >}}) this structure is saved to disk and with [`<LoadDataset>`]({{< relref "/reference/loaddataset" >}}) it is loaded again.
If the file does not exist when loading, no error is reported, because it could be the first pass where the file naturally does not yet exist.

## Step 3: Processing the information

Immediately after loading, XML processing is continued with the first element of the currently loaded structure. In the example above, the following command would be searched for in the layout ruleset

```xml
<Record element="articlelist">
  ...
</Record>
```

This means that the actual data processing is temporarily interrupted and continued with the new data set from [`<LoadDataset>`]({{< relref "/reference/loaddataset" >}}).

## Example

This is the same example as in the previous section ([directories-marker]({{< relref "directoriesmarker" >}})). A simple data file is used as an example:

```xml
<data>
  <chapter title="Foreword">
    <text>...</text>
  </chapter>
  <chapter title="Introduction">
    <text>...</text>
  </chapter>
  <chapter title="Conclusion">
    <text>...</text>
  </chapter>
</data>
```

Which is output with the following layout:

```xml
<Layout
  xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <DefineFontfamily name="title" fontsize="18" leading="20">
    <Regular fontface="sans"/>
  </DefineFontfamily>

  <!--1-->

  <!--2-->
  <Record element="data">
    <ProcessNode select="chapter"/>
  </Record>

  <Record element="chapter">
    <!--3-->
    <PlaceObject>
      <Textblock>
        <Paragraph fontfamily="title">
          <Value select="@title"/>
        </Paragraph>
        <Paragraph>
          <Value select="text"/>
        </Paragraph>
      </Textblock>
    </PlaceObject>
    <ClearPage/>
  </Record>
</Layout>
```
{{% codecaption %}}Basic framework for the output of a table of contents via the XML structure. The code is added during the course of the section.{{% /codecaption %}}

1. The output of the actual table of contents is inserted here.
2. The section 'data' is extended by loading and saving the XML data for the directory
3. Here code is inserted that assembles the XML structure (see below)

Now a variable is defined (`entries`), which contains the information about the chapter beginnings.
The target structure should be as follows:

```xml
<tableofcontent>
  <entry chaptername="Foreword" page="2"/>
  <entry chaptername="Introduction" page="3"/>
  <entry chaptername="Conclusion" page="4"/>
</tableofcontent>
```

In the `chapter` section (point 3 in the layout above) the code is inserted at the top to fill the variable `entries` with the contents:

```xml
  <Record element="chapter">
    <SetVariable variable="entries">
      <Copy-of select="$entries"/>
      <Element name="entry">
        <Attribute name="chaptername" select="@title"/>
        <Attribute name="page" select="sd:current-page()"/>
      </Element>
    </SetVariable>

    <PlaceObject>
    ...
```

Thus, something new is added to a variable using `<Copy-of>`.

The structure must be loaded at the beginning and saved at the end of the run to ensure that it is always up-to-date.
If the file `toc` does not yet exist, the command is simply skipped.
The new section `data` now looks like this and is inserted at position 2 in the layout above (instead of the record existing there)

```xml
  <Record element="data">
    <LoadDataset name="toc"/>
    <SetVariable variable="entries"/>
    <ProcessNode select="chapter"/>
    <SaveDataset name="toc" elementname="tableofcontents"
                 select="$entries"/>
  </Record>
```

On the next run, the command `<LoadDataset>` takes effect and opens the previously saved XML file.
The layout ruleset searches for a section for the `tableofcontents` element, which is the root element of the saved file.
This has to be added to the layout rules (position 1 in the layout above):

```xml
  <Record element="tableofcontents">
    <PlaceObject>
      <Table padding="5pt">
        <ForAll select="entry">
          <Tr>
            <Td><Paragraph><Value select="@chaptername"/></Paragraph></Td>
            <Td><Paragraph><Value select="@page"/></Paragraph></Td>
          </Tr>
        </ForAll>
      </Table>
    </PlaceObject>
    <ClearPage/>
  </Record>
```

A table is output with one line for each child element `entry`.
The subsequent page break shifts the subsequent text backwards.
This means that you have to run through the document three times before the table of contents is correct:

1. In the first pass, the data structure is compiled.
2. Afterwards the table of contents can be created, the page break shifts the content one page backwards, the data structure is updated accordingly.
3. Only in the third pass is the table of contents correct.

If you know that the table of contents will only take up one page, you can insert the page break in the first pass.
This saves you one pass.

