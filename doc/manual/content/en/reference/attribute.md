---
linktitle: "Attribute"
weight: 70
type: docs
---

# `Attribute`


Create an attribute for the [`Element`]({{% relref "element" %}}) data structure that can be saved to the hard drive with [`SaveDataset`]({{% relref "savedataset" %}}).



## Child elements

(none)

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../element"><code>Element</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`name` (text)
: Name of the attribute that is created.



`select` ([XPath expression]({{% relref "../manual/xpathref/xpath" %}}))
: The contents of the attribute






## Example


```xml
<Element name="Entry">
  <Attribute name="chapter" select="@name"/>
  <Attribute name="page" select="sd:current-page()"/>
</Element>

```

creates the following structure:



```xml
<Entry chapter="(contents of @name)" page="(the current page number)" />
```



