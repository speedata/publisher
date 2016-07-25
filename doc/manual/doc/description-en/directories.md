title: speedata Publisher manual
---
Automatically generated lists / directories
===========================================

The speedata Publisher can create arbitrary types of directories. All
lists: table of contents, list of articles or keyword index, are created
by the same principle. The necessary data for the list (e.g. page
number, article number) are saved in its own XML data structure, saved
to the hard drive and used in the next publishing run.

To make the speedata publisher run more than once, it needs to be
instructed by a switch on the [command line](commandline.html)
(`sp --runs=2`) or in the [configuration file](configuration.html) with
`runs=2`. You can give any number, but normally two or three runs are
sufficient to generate the list.

Step 1: Collection the information
----------------------------------

Both commands [Element](../commands-en/element.html) and
[Attribute](../commands-en/attribute.html) are used to structure the
data, that are to be read on the next publishing run. You can create XML
data structures with the information for the list that you need to
generate. The data should have a structure that is suited for processing
with the speedata Publisher. The following is an example of a suitable
data structure:

    <articlelist>
      <article nummer="1" page="10"/>
      <article nummer="2" page="12"/>
      <article nummer="3" page="14"/>
    </articlelist>

To create this structure in the layout rules, you need to apply the
commands [Element](../commands-en/element.html) and
[Attribute](../commands-en/attribute.html) as follows:

    <Element name="articlelist">
      <Element name="article">
        <Attribute name="nummer" select="1"/>
        <Attribute name="page" select="10"/>
      </Element>
      <Element name="article">
        <Attribute name="nummer" select="2"/>
        <Attribute name="page" select="12"/>
      </Element>
      <Element name="article">
        <Attribute name="nummer" select="3"/>
        <Attribute name="page" select="14"/>
      </Element>
    </Element>

Instead of using the commands [Element](../commands-en/element.html) and
[Attribute](../commands-en/attribute.html) in one place you can create
the construct by using variables to save the data. See the example
below.

Step 2: Save and load the list information
------------------------------------------

The command [SaveDataset](../commands-en/savedataset.html) saves the
given structure to the hard drive which can be loaded again (in the next
run) with [LoadDataset](../commands-en/loaddataset.html). If the file
does not exist when loading it with
[LoadDataset](../commands-en/loaddataset.html) it will be silently
ignored, because it could be the first run which means the file does not
exist yet.

Step 3: Process the information
-------------------------------

Right after using [LoadDataset](../commands-en/loaddataset.html), data
processing continues with the matching rule for the\
 data set file. In the example above, a rule that matches `articlelist`
will be applied ([Record](../commands-en/record.html)
element=“articlelist”). When this rule finishes, the layout continues
right after `LoadDataset`.

Example
-------

The following example (planets) is included in the distribution. It
creates a table of contents for the following pages. The data processing
starts at the element `planets` (about the middle of the file). We load
the data file `toc` (it could be any name). In the first run, this file
is not found and the command
[LoadDataset](../commands-en/loaddataset.html) does not execute
anything. The data processing continues with the command after the
`LoadDataset` (here: `>SetVariable>`). During the first run data which
has the following structure is written on the disk (with the name
`toc`):

    <tableofcontents>
      <planetlisting name="Mercury" pagenumber="2"/>
      <planetlisting name="Venus" pagenumber="3"/>
      <planetlisting name="Earth" pagenumber="4"/>
      <planetlisting name="Mars" pagenumber="5"/>
      <planetlisting name="Jupiter" pagenumber="6"/>
      <planetlisting name="Saturn" pagenumber="7"/>
      <planetlisting name="Uranus" pagenumber="8"/>
      <planetlisting name="Neptune" pagenumber="9"/>
    </tableofcontents>

In the layout XML file, the data structure must have this format:

    <Element name="tableofcontents">
      <Element name="planetlisting">
        <Attribute name="name" select="'Mercury'"/>
        <Attribute name="pagenumber" select="2"/>
      </Element>
      <Element name="planetlisting">
        <Attribute name="name" select="'Venus'"/>
        <Attribute name="pagenumber" select="3"/>
      </Element>
      ...
      <Element name="planetlisting">
        <Attribute name="name" select="'Uranus'"/>
        <Attribute name="pagenumber" select="9"/>
      </Element>
    </Element>

The information in the attributes should be created dynamically. We use
the XPath expression `@name` and the XPath function `sd:current-page()`.

In the second run the file `toc` will be read by `LoadDataset`. The
layout XML processing jumps to the `<Record element=tableofcontents">`
at the beginning of the file, since `tableofcontents` is the root
element of the data set.

    <Record element="tableofcontents">
      <SetVariable variable="tableofcontents" select="''"/>
      <ProcessNode select="planetlisting"/>
      <PlaceObject column="3">
        <Textblock width="20" fontface="Header">
          <Paragraph><Value>Contents</Value></Paragraph>
        </Textblock>
      </PlaceObject>
      <PlaceObject column="3">
        <Textblock width="20">
          <Value select="$tableofcontents"/>
        </Textblock>
      </PlaceObject>
    </Record>
     
    <Record element="planetlisting">
      <SetVariable variable="tableofcontents">
        <Value select="$tableofcontents"/>
        <Paragraph>
          <Value select="@name"/>
          <Value>, page </Value>
          <Value select="@page"/>
        </Paragraph>
      </SetVariable>
    </Record>
     
    <!-- Root element -->
    <Record element="planets">
      <SetVariable variable="column" select="2" />
      <LoadDataset name="toc"/>
      <SetVariable variable="Contents" select="''"/>
      <NewPage/>
      <ProcessNode select="planet"/>
    </Record>
     
    <Record element="planet">
      <SetVariable variable="Contents">
        <Value select="$Contents"/>
        <Element name="planetlisting">
          <Attribute name="name" select=" @name "/>
          <Attribute name="page" select=" sd:current-page()"/>
        </Element>
      </SetVariable>
     
      <ProcessNode select="url" />
      ...
      <NewPage />
      <SaveDataset filename="toc" elementname="tableofcontents" select="$Contents"/>
    </Record>
     
    <Record element="url">
      ...
    </Record>

