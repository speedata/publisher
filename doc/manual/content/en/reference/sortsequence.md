---
linktitle: "SortSequence"
weight: 850
type: docs
---

# `SortSequence`


Sort a list.



## Child elements

(none)

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../element"><code>Element</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savedataset"><code>SaveDataset</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`criterion` (text)
: Name of the attribute that is used as the sort key.



`numerical` (optional, _since version 3.1.21_)
: Sort alphabetical or numerical


  - `yes`: Sort alphabetical
  - `no`: Sort alphabetical (default)

`order` (optional, _since version 3.1.22_)
: Select the sorting order


  - `ascending`: Use ascending sort order (default)
  - `descending`: Use descending sort order

`removeduplicates` (text, optional)
: If this attribute is used then it contains the name of the data-attribute that gets evaluated when duplicates are eliminated.



`select` ([XPath expression]({{% relref "../manual/xpathref/xpath" %}}))
: The data that should be sorted.






## Example


Data:



```xml
<data>
  <elt value="one"/>
  <elt value="two"/>
  <elt value="three"/>
</data>

```

Layout:



```xml
<Record element="data">
  <SetVariable variable="unsorted" select="*"/>
  <SetVariable variable="sorted">
    <SortSequence select="$unsorted" criterion="value"/>
  </SetVariable>
  <PlaceObject>
    <Textblock>
      <ForAll select="$sorted">
        <Paragraph><Value select="@value"></Value></Paragraph>
      </ForAll>
    </Textblock>
  </PlaceObject>
</Record>

```



