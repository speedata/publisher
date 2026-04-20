---
linktitle: "ProcessNode"
weight: 760
type: docs
---

# `ProcessNode`


Executes all given nodes. The elements, that are to be executed, are given with the attribute `selection`.



## Child elements

(none)

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`limit` (number, optional, _since version 2.5.6_)
: Limits the number of items processed with this command



`mode` (text, optional)
: Name of the mode. This must match the mode at the corresponding [`Record`]({{% relref "record" %}}) element. With this it is possible to have different rules for the same element.



`select` ([XPath expression]({{% relref "../manual/xpathref/xpath" %}}))
: Selection of child elements, that are to be processed.






## Example


```xml
<ProcessNode select="*" mode="sum" />
```



