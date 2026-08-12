---
title: "Page types"
weight: 38
type: docs
---



Page types (or master pages, page templates) are used to define margins for pages, create page frames and perform actions when a page is created or written to the PDF file.
Classically, there is a page template for left pages and for right pages.
In the simplest case, a template looks like this:

```xml
<Pagetype name="page" test="sd:even(sd:current-page())">
    <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>
</Pagetype>
```

The condition in the attribute 'test' can be arbitrarily complex. This attribute must always be specified.
A page is selected as soon as a test of a page type yields _true_.
Examples:

* `true()`: This page is always selected, since `true()` always results in *true*.
* `sd:current-page() > 1`: Here the page template is selected for all pages following the first page.
* `sd:even(sd:current-page())`: If the page number is even, this page type is used. This is usually when the page is a left page.
* It can also be more complex: `sd:even(sd:current-page()) and $part = 'main'`. As long as the condition can be evaluated to _true_ or _false_, this is a valid expression.

What happens if there are multiple conditions that are _true_ at the same time?
Page types are evaluated from “bottom to top”.
This means that special page templates must be defined later than the general ones.
The default template is defined first and has as condition `true()`.
So it is evaluated last according to this logic and is always used if no other page type in the test returns _true_ (fallback).

```xml
<Pagetype name="left pages" test="sd:even(sd:current-page())">
  ...
</Pagetype>
<Pagetype name="right pages" test="sd:odd(sd:current-page())">
  ...
</Pagetype>
<Pagetype name="first page" test="sd:current-page() = 1">
  ...
</Pagetype>
```
{{% codecaption %}}Here, the page type for the first page after the page type for right pages must be defined, otherwise it would not be considered (sd:odd(1) returns true).{{% /codecaption %}}

## Placement areas

Placement areas can be created in the page type definition.
These are described in detail in the section [Placement areas]({{< relref "positioningframe" >}}).

## AtPageCreation, AtPageShipout

The two commands `<AtPageCreation>` and `<AtPageShipout>` are responsible for executing code when a page is created and when a page is written to the PDF file.
They can be used for many purposes.
The most common is to create the page header in `<AtPageCreation>` and the page footer in `<AtPageShipout>`.

The following is an example of a page footer.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Pagetype name="page" test="true()">
    <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>

    <AtPageShipout>
      <PlaceObject column="1" row="{sd:number-of-rows() - 1}">
        <Table stretch="max">
          <Tablerule/>
          <Tr>
            <Td align="left">
              <Paragraph>
                <Value select="sd:current-page()"/>
              </Paragraph>
            </Td>
            <Td align="right">
              <Paragraph>
                <Value>Name</Value>
              </Paragraph>
            </Td>
          </Tr>
        </Table>
      </PlaceObject>
    </AtPageShipout>
  </Pagetype>

  <Record element="data">
    <PlaceObject>
      <Textblock>
        <Paragraph>
          <Value>Content</Value>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```

![Page with footer](/img/fusszeileseitentyp.png)

## ClearPage

With the command `<ClearPage>` you can specify which page type should be selected for the next page, even if the condition (`test`) for `<Pagetype>` does not return _true_.

The following example defines two page types, a template “Standard”, which is always used and a template “Special”, which is explicitly selected with `<ClearPage>`.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Pageformat width="210mm" height="50mm"/>

  <Pagetype name="Special" test="false()">
    <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>
  </Pagetype>

  <Pagetype name="Standard" test="true()">
    <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>
  </Pagetype>

  <Record element="data">
    <PlaceObject>
      <Textblock>
        <Paragraph>
          <Value>Page 1</Value>
        </Paragraph>
      </Textblock>
    </PlaceObject>
    <ClearPage pagetype="Special" openon="right" />
    <PlaceObject>
      <Textblock>
        <Paragraph>
          <Value>Page 3</Value>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```

In the log file (`publisher-protocol.xml`) you can see which page types are selected:

```xml
<entry level="INFO" msg="Create page" type="Standard" pagenumber="1"></entry>
<entry level="INFO" msg="Number of rows: 3, number of columns = 19"></entry>
<entry level="INFO" msg="Create font metrics" name="texgyreheros-regular.otf" size="10.0" id="1" mode="harfbuzz"></entry>
<entry level="INFO" msg="Shipout page 1"></entry>
<entry level="INFO" msg="Create page" type="Standard" pagenumber="2"></entry>
<entry level="INFO" msg="Number of rows: 3, number of columns = 19"></entry>
<entry level="INFO" msg="Shipout page 2"></entry>
<entry level="INFO" msg="Create page" type="Special" pagenumber="3"></entry>
<entry level="INFO" msg="Number of rows: 3, number of columns = 19"></entry>
<entry level="INFO" msg="Shipout page 3"></entry>
```

## Pagenumbers

The page number of the current page can be determined with `sd:current-page()`. This function returns the number 1 on the first page, the number 2 on the second page and so on. The `startpage` attribute at [`<options>`]({{< relref "/reference/commands/options" >}}) can be used to set the start page number:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en">
    <Options startpage="4"></Options>
    <Record element="data">
        <PlaceObject>
            <Textblock>
                <Paragraph>
                    <!-- prints out sd:current-page() = 4 -->
                    <Value>sd:current-page() = </Value>
                    <Value select="sd:current-page()" />
                </Paragraph>
            </Textblock>
        </PlaceObject>
    </Record>
</Layout>
```

### Page x of y

For output such as “Page 1 of 10” you need the total number of pages in the document.
The [internal variable]({{< relref "internalvariables" >}}) `$_lastpage` contains the number of pages from the previous run:

```xml
<Value select="concat('Page ', sd:current-page(), ' of ', $_lastpage)"/>
```

Since the length of the document is only known at the end of a run, at least two runs are necessary before the value is correct.
Before version 3.9.26 the last page number had to be saved with `<SaveDataset>` and loaded again in the next run.
This general mechanism is described in the section [Creating lists (XML structure)]({{< relref "directoriesxml" >}}).

## Sections or matters

A document can be divided into sections (matters) that have their own numbering. The numbering of the sections does _not_ change the numbering with `sd:current-page()`, rather they have “visible page numbers”. The visible page number can be determined with the function `sd:visible-pagenumber()`. A number must be passed to this function, otherwise it takes the current page. Without custom matters, the output is identical:

```xml
<!-- prints out sd:current-page() = 1 -->
<Value>sd:current-page() = </Value>
<Value select="sd:current-page()" />
<Br/>
<!-- sd:visible‐pagenumber(sd:current‐page()) = 1 -->
<Value>sd:visible-pagenumber(sd:current-page()) = </Value>
<Value select="sd:visible-pagenumber(sd:current-page())" />
```

If you define and use your own sections or use a predefined section, this can change:

```xml
<ClearPage matter="frontmatter" />
<PlaceObject>
    <Textblock>
        <Paragraph>
            <!-- prints out sd:current-page() = 1 -->
            <Value>sd:current-page() = </Value>
            <Value select="sd:current-page()" />
            <Br/>
            <!-- sd:visible‐pagenumber(sd:current‐page()) = i -->
            <Value>sd:visible-pagenumber(sd:current-page()) = </Value>
            <Value select="sd:visible-pagenumber(sd:current-page())" />
        </Paragraph>
    </Textblock>
</PlaceObject>
```

Here (with [`<Clearpage>`]({{< relref "/reference/commands/clearpage" >}})) the matter `frontmatter` is used for the following pages. This causes the visible page number to be output as a Roman numeral in lower case, as this section has been defined as follows:

```xml
<DefineMatter name="frontmatter" label="lowercase-romannumeral" />
```

Matters can only start with the command [`<Clearpage>`]({{< relref "/reference/commands/clearpage" >}}).
