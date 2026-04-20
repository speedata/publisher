---
linktitle: "SaveDataset"
weight: 800
type: docs
---

# `SaveDataset`


Saves an element/attribute structure to be used in the next publisher run. The contents must have a tree structure.



## Child elements

<a href="../copy-of"><code>Copy-of</code></a>, <a href="../element"><code>Element</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../makeindex"><code>Makeindex</code></a>, <a href="../sortsequence"><code>SortSequence</code></a>

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`attributes` ([XPath expression]({{% relref "../manual/xpathref/xpath" %}}), optional)
: The variable (as an XPath expression, e.g. `$foo`) which contains [`Attribute`]({{% relref "attribute" %}}) Elements. These attributes are added to the root element.



`elementname` (text)
: Name of the root element that surrounds the elements given by the child elements.



`name` (text)
: Name of the file. Example: toc. The resulting filename will be $jobname-$name.xml



`select` ([XPath expression]({{% relref "../manual/xpathref/xpath" %}}), optional)
: Alternative to giving the data structure in the child elements.






## Example


```xml
  <Record element="data">
    <SetVariable variable="attributesvar">
      <Attribute name="att1" select="'Hello'" />
      <Attribute name="att2" select="123" />
    </SetVariable>

    <SaveDataset name="toc" elementname="root" attributes="$attributesvar">
      <Element name="child">
        <Attribute name="attchild" select="999"/>
      </Element>
    </SaveDataset>
  </Record>

```

This code saves an XML file to the disc which has this structure:



```xml
<root att1="Hello" att2="123">
 <child attchild="999"/>
</root>

```

```xml
<SaveDataset name="toc" elementname="Contents">
  <Copy-of select="$contents"/>
</SaveDataset>

```

is equivalent to



```xml
<SaveDataset name="toc" elementname="Contents" select="$contents"/>
```



