---
title: "Controlling column widths"
weight: 22
type: docs
---

## Task

The article list from the recipe [Simple table with automatic breaking]({{< relref "simpletable" >}}) gets a column with application notes: running text next to short technical values. Article number, dimensions, PU and price should stay stable on a single line; the remaining space goes to the application text.

![Fixed widths for the technical columns, the application text gets the rest and wraps onto several lines.](/img/howto-columnwidths-en.png)

## Decision

Without further instructions the Publisher distributes the column widths by itself, based on the contents. That is fine as long as the contents are short and uniform; the article list in the first recipe therefore worked without any width settings. How to recognize that the automatic distribution no longer works:

* **One column contains running text.** The automatic distribution then takes the space from the short columns, and values that belong together start to wrap there.
* **Unbreakable values wrap.** Article numbers or dimensions like “6.0 × 120” end up on two lines; the column heads hyphenate as well.
* **Images in cells** need a reliable column width, otherwise the image size depends on the contents of the other rows.
* **Several tables on the same page** should share the same column alignment. The automatic distribution calculates each table on its own, so the columns end up offset against each other.

This is what the failure looks like with automatic distribution, same data as above:

![The automatic distribution squeezes the short columns: dimensions and column heads wrap.](/img/howto-columnwidths-auto-en.png)

## Solution

### Step 1: declaring the columns

The column widths are declared with `<Columns>`, as the first element inside `<Table>`. The stable columns get fixed widths:

```xml
<Table stretch="max" padding="3pt">
  <Columns>
    <Column width="32mm"/>
    <Column width="24mm"/>
    <Column width="1*"/>
    <Column width="10mm" align="right"/>
    <Column width="17mm" align="right"/>
  </Columns>
  ...
```

Fixed widths can be given in absolute units (`32mm`) or in grid cells (number without a unit). The width must also accommodate the column head, not just the values; when in doubt, measure the longest head.

### Step 2: the rest via star widths

The application column gets `width="1*"`: star columns share the space that remains after the fixed widths are subtracted. With several star columns the space is distributed in the ratio of the numbers: `2*` receives twice as much as `1*`. This gives the usual mixed form: fixed widths for everything technical, star widths for the text.

### Step 3: alignment on the column instead of the cell

The attribute `align` can be set directly on `<Column>`; this removes the need for the `align="right"` on every single cell that was still necessary in the first recipe. Individual cells can still override the column setting.

### Complete example

The runnable project is also available in the [examples repository](https://github.com/speedata/examples/tree/master/manual/columnwidths). The small page format only serves the compact illustration.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Pageformat width="148mm" height="105mm"/>

  <Record element="data">
    <PlaceObject>
      <Table stretch="max" padding="3pt">
        <Columns>
          <Column width="32mm"/>
          <Column width="24mm"/>
          <Column width="1*"/>
          <Column width="10mm" align="right"/>
          <Column width="17mm" align="right"/>
        </Columns>
        <Tablehead>
          <Tr background-color="lightgray">
            <Td><Paragraph><B><Value>Item no.</Value></B></Paragraph></Td>
            <Td><Paragraph><B><Value>Dimensions</Value></B></Paragraph></Td>
            <Td><Paragraph><B><Value>Application</Value></B></Paragraph></Td>
            <Td><Paragraph><B><Value>PU</Value></B></Paragraph></Td>
            <Td><Paragraph><B><Value>Price in €</Value></B></Paragraph></Td>
          </Tr>
        </Tablehead>
        <ForAll select="group/article">
          <Tr>
            <Td><Paragraph><Value select="@number"/></Paragraph></Td>
            <Td><Paragraph><Value select="@dim"/></Paragraph></Td>
            <Td><Paragraph><Value select="@application"/></Paragraph></Td>
            <Td><Paragraph><Value select="@pu"/></Paragraph></Td>
            <Td><Paragraph><Value select="@price"/></Paragraph></Td>
          </Tr>
        </ForAll>
      </Table>
    </PlaceObject>
  </Record>
</Layout>
```

The data is an excerpt from the Confixa set; new is the attribute `application` with the application note:

```xml
<data company="Confixa">
  <group name="Chipboard screws" code="CS" material="steel, zinc plated">
    <article number="CS-3012" dim="3.0 × 12" drive="TX10" pu="1000" price="4.90"
             application="Fine work in chipboard and MDF"/>
    <article number="CS-4030" dim="4.0 × 30" drive="TX20" pu="500" price="4.90"
             application="Universal screw for wood and chipboard, no pre-drilling required"/>
    <article number="CS-4050" dim="4.0 × 50" drive="TX20" pu="500" price="6.70"
             application="Universal screw for wood and chipboard, no pre-drilling required"/>
    <article number="CS-5070" dim="5.0 × 70" drive="TX25" pu="200" price="5.90"
             application="Load-bearing timber connections, pre-drill in hardwood"/>
    <article number="CS-6080" dim="6.0 × 80" drive="TX30" pu="100" price="5.00"
             application="Heavy-duty connections in solid timber"/>
    <article number="CS-60120" dim="6.0 × 120" drive="TX30" pu="100" price="7.30"
             application="Heavy-duty connections, requires pre-drilling near edges"/>
  </group>
</data>
```

## Limits

* **Content-dependent widths**: Besides fixed and star widths there are the keywords `min` and `max`, the setting `?` (natural width) and `minwidth` as a lower bound. These refinements are described in the manual chapter [Tables, section on column widths]({{< relref "/manual/tables#specifying-the-column-widths" >}}).
* **The text still does not fit**: If the star column becomes too narrow, the only options are shortening, a smaller font or checking the hyphenation (attribute `language`); a table declared wider than the type area sticks out over the margin.
* **The same column alignment across tables** is achieved by using the same `<Columns>` declaration in all tables; with only one star column the widths are then identical in all tables.
* Reference: [`<Columns>`]({{< relref "/reference/commands/columns" >}}) and [`<Column>`]({{< relref "/reference/commands/column" >}}).
