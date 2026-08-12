---
title: "Groups (virtual objects)"
weight: 39
type: docs
---



One of the most important features of the Publisher is the ability to place objects on a virtual area (Group) in order to subsequently measure them or place them together.
This virtual area initially has no width and no height.
The area adapts to the dimensions of the content.
This allows you to answer questions such as "Does the article (with picture and description) still fit on the page?" or "How much do you need to
reduce font size so that all the text fits on an A4 page?".

It is also possible to provide this virtual area with its own page grid.
This allows, for example, to position objects more finely than is possible with a coarser page grid of the main page.

There are a few things to consider when using the groups:

* The width specifications for text blocks and tables are now mandatory, since there is no "natural maximum".
* The group grid cannot be defined with 'nx' and 'ny' (division), but only with fixed values for height and width.
* Areas cannot be combined with groups. This means that 'area' must not be specified for 'PlaceObject>' and similar commands.
* Placements in groups must not be absolute (e.g. `row="2mm"`).


## How are groups used?

```xml
<Layout
  xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Trace grid="yes" objects="yes"/>

  <Record element="data">
    <Group name="test">
      <Contents>
        <PlaceObject row="2" column="2">
          <Image width="3" file="_sampleb.pdf"/>
        </PlaceObject>
      </Contents>
    </Group>

    <Message select="sd:group-height('test')"/>

    <PlaceObject groupname="test"/>
  </Record>
</Layout>
```

![The group takes up the minimum space.](/img/24-einfachegruppe.png)

If the group has been created but not yet placed, you can use various layout functions to measure the dimensions of the group: `sd:group-width('group name')` and `sd:group-height('group name')` output the width and height in whole grid cells.
The `<Message>` command in the example above prints the number 6, even though the group has only the height of about 5.2 cells.
The Publisher always calculates with whole grid cells.

This says it all about groups.
The applications are very diverse.
In principle, the question is always: how large are these objects?
Do they still fit on the page? Do I have to insert a page break here? And so on.
It's best to play a little with the virtual areas to get familiar with them.
Used correctly, they are a powerful tool.

## Layout optimization

A typical case with database publishing is that you don't know what data to expect. Text varies in length, images have different aspect ratios, the amount of data in the record varies, and so on. In order to still create a presentation that is appealing (i.e. follows certain rules), you can make queries. Besides static questions like "How many articles are in the article group?", dynamic questions can be answered:

* How wide is the headline?
* How high is the image?
* Does the table still fit on the page?

The idea is as follows: You create a group, place the elements that you want to measure there and then ask how large (width and height) the virtual area has become, in order to react differently to it.

The framework is as follows:

```xml
<Record element="data">
  <Group name="img">
    <Contents>
      <!--1-->
      <PlaceObject>
        <Image file="_samplea.pdf" width="4"/>
      </PlaceObject>
    </Contents>
  </Group>
  <!--2-->
  <Switch>
    <Case test="sd:group-height('img') > 5">
      ...
    </Case>
    <Otherwise>
      ...
    </Otherwise>
  </Switch>
</Record>
```
1. At the beginning the group has a width and height of 0. All objects increase the area.
2. The group now has a width of 4 and an unknown height (depending on the image). Now the height can be queried with `sd:group-height()` and the width with `sd:group-width()`. What happens in the case distinction depends on the concrete layout, of course.

The principle is always the same: the content in question is placed on a virtual area and measured. On the basis of the determined height or width, you can, for example

* simply output the group,
* insert a page break if the group no longer fits on the page,
* recreate the group in a loop with modified parameters until a condition is met (an example of this procedure is shown in the section [Virtual Pages]({{< relref "virtualpages" >}})),
* assemble a table row by row and check whether it still fits (see [Assembling tables]({{< relref "/manual/tables#assembling-tables" >}})).

## Separate grids in groups

The following is an example of a grid within a group that differs from the global grid.
Without the explicit `<Grid ... />` specification, the grid is taken from the page.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <SetGrid nx="4" ny="4"/>
  <Trace grid="yes" gridallocation="yes" objects="yes"/>

  <Record element="data">
    <Group name="table">
      <Grid width="1cm" height="12pt"/>
      <Contents>
        <PlaceObject>
          <Table width="4" stretch="max">
            <Tr>
              <Td><Paragraph><Value>Cell 1/1</Value></Paragraph></Td>
              <Td><Paragraph><Value>Cell 2/1</Value></Paragraph></Td>
            </Tr>
            <Tr>
              <Td><Paragraph><Value>Cell 1/2</Value></Paragraph></Td>
              <Td><Paragraph><Value>Cell 2/2</Value></Paragraph></Td>
            </Tr>
          </Table>
        </PlaceObject>
        <PlaceObject row="4" column="2">
          <Image file="ocean.pdf" width="3"/>
        </PlaceObject>
      </Contents>
    </Group>

    <PlaceObject groupname="table"/>
  </Record>
</Layout>
```
{{% codecaption %}}The group has its own grid that is independent of the page grid.{{% /codecaption %}}

![Section of a page. The grid within the group is much finer than the coarse page grid.](/img/08-raster4.png)

## Tracing

To help debug the layout within a group, you can turn on the grid visualization:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
	xmlns:sd="urn:speedata:2009/publisher/functions/en">
  <Pageformat height="6cm" width="9cm"></Pageformat>
  <Trace groups="yes" />

  <Record element="data">
    <Group name="foo">
      <Grid width="4mm" height="4mm"></Grid>
      <Contents>
        <PlaceObject>
          <Textblock width="11">
            <Paragraph>
              <Value>Hello world</Value>
            </Paragraph>
          </Textblock>
        </PlaceObject>
        <PlaceObject column="1" row="4">
          <Image width="3" file="_samplea.pdf" />
        </PlaceObject>
      </Contents>
    </Group>
    <PlaceObject groupname="foo" column="2" row="2" />
  </Record>
</Layout>
```

which gets rendered as

![The grid within the group gets displayed.](/img/group-tracing.png)

