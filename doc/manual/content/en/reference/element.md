---
linktitle: "Element"
weight: 320
type: docs
---

# `Element`


Create a data structure that can be used to save on the hard-drive between consecutive runs (with [`SaveDataset`]({{% relref "savedataset" %}})).



## Child elements

<a href="../attribute"><code>Attribute</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../element"><code>Element</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../makeindex"><code>Makeindex</code></a>, <a href="../sortsequence"><code>SortSequence</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../value"><code>Value</code></a>

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../element"><code>Element</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../message"><code>Message</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../savedataset"><code>SaveDataset</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`name` (text)
: Name of the element that gets created.






## Example


```xml
<SetVariable variable="articles">
  <Element name="articlelist">
    <Attribute name="name" select=" @name "/>
    <Attribute name="page" select="sd:current-page()"/>
  </Element>
</SetVariable>

```



