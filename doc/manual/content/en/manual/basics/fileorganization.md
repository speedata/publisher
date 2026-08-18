---
title: "File organization"
weight: 33
type: docs
---



This section describes how the necessary files (layout, data, images and font files) must be organized, where they are stored, what they must be called, and so on.

When the Publisher starts, it reads the current (working) directory and all child directories and saves the file names in a list. As soon as a resource is loaded, this list is used to check whether a corresponding file exists. No distinction is made as to which directory the file is located in.

It follows from this:

1. If something changes in the file system during the run, the Publisher will not notice this.
2. It does not matter what the directories are called. The images can, but do not have to be stored in the directory with the name "images".
3. If the working directory is too large, the startup process is slow. A few thousand files in the working directory are usually no problem.
4. If there are duplicates in the file tree, a file is selected “at random”. E.g. `data.xml` in the main directory and in a subdirectory.

There are exceptions to the rule:

1. You can use `sp --no-local` to instruct the publisher not to search the working directory recursively.
2. With `--extra-dir` you can add a directory to be searched recursively.
3. With `sp --systemfonts`, font files are also searched in directories that are predefined by the system.
4. With `sp --wd DIR` the publisher changes to this directory before starting.

For a description of the parameters see the appendix [Running the speedata publisher on the command line]({{< relref "commandline" >}}).

## What names must the data file and the layout file have?

The speedata Publisher looks for the layout with the name layout.xml and the data file with the name data.xml. Both can be adjusted on the command line (`--layout=XYZ` and `--data=XYZ`) and in the configuration file (`layout=XYZ` and `data=XYZ`). See the appendices [Running the speedata publisher on the command line]({{< relref "commandline" >}}) and [How to configure the speedata publisher]({{< relref "configuration" >}}).

![Possible file organization in a directory. The name of the subdirectories (folders) is arbitrary.](/img/18-dateisystem.png)

## Splitting layout sets of rules into individual files

You can split the layout ruleset into several files and merge them with XInclude, here in the case of a font definition:

```xml
<Layout
  xmlns="urn:speedata.de:2009/publisher/en">

  <LoadFontfile name="DejaVuSerif" filename="DejaVuSerif.ttf" />
  ...

</Layout>
```

This file can then be included with

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en"
  xmlns:xi="http://www.w3.org/2001/XInclude"
  >

  <xi:include href="dejavu.xml"/>
  ...

</Layout>
```

The namespace for XInclude must be declared as above, otherwise there will be a syntax error in the XML file.

## Grouping layout instructions with Section

The `<Section>` element allows you to group layout instructions without affecting the output.
This is useful for organizing large layout files, e.g. for code folding in text editors.
The element has a `name` attribute that serves as a label.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Section name="Fonts and colors">
    <LoadFontfile name="title" filename="title.otf" />
    <DefineFontfamily name="title" fontsize="14"pt leading="16pt">
      <Regular fontface="title"/>
    </DefineFontfamily>
    <DefineColor name="highlight" value="#cc0000" />
  </Section>

  <Section name="Page setup">
    <Pageformat width="210mm" height="297mm" />
    <SetGrid height="12pt" width="5mm" />
  </Section>

  <Record element="data">
    ...
  </Record>
</Layout>
```

`<Section>` can also be used inside `<Record>` or other elements.
It can be freely combined with `<xi:include>`.

## Splitting data into individual files

The data file can also be split into several files. XInclude is used for this.

```xml
<catalog xmlns:xi="http://www.w3.org/2001/XInclude">
  <xi:include href="globalsettings.xml"/>
  <xi:include href="article0001.xml"/>
  <xi:include href="article0002.xml"/>
  ...
</catalog>
```

The namespace for XInclude must be declared in the root node (in the above example, 'catalog').

### XInclude and XML schema

If the XInclude mechanism is used, it is possible that the XML editor will flag the `<xi:include ...>` statements as unknown.
To prevent this, the RELAX NG schema must be linked to the editor instead of the XML schema. See the chapter [Associate XML editor with schema]({{< relref "schema" >}}).

