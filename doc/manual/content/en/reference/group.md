---
linktitle: "Group"
weight: 390
type: docs
---

# `Group`


Create a virtual page that behaves like a real page but is not placed into the PDF.



## Child elements

<a href="../contents"><code>Contents</code></a>, <a href="../grid"><code>Grid</code></a>

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`name` (text)
: Name of the group that is created.






## Example


```xml
<Record element="data">
  <Group name="Some group">
    <!-- Optional, taken from the current page -->
    <Grid width="10mm" height="10mm"/>
    <Contents>
      <PlaceObject column="3" row="2">
        <Textblock width="14">
          <Paragraph>
            <Value>Text</Value>
          </Paragraph>
        </Textblock>
      </PlaceObject>
      <PlaceObject column="2" row="4">
        <Textblock width="14">
          <Paragraph>
            <Value>Next text</Value>
          </Paragraph>
        </Textblock>
      </PlaceObject>
    </Contents>
  </Group>
  <PlaceObject groupname="Some group" row="1" />
</Record>

```



