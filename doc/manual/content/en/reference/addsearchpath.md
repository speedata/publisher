---
linktitle: "AddSearchpath"
weight: 30
type: docs
---

# `AddSearchpath`
_since version 3.1.1_

Add a directory on the hard-drive to be added to the publisher's search path.



## Child elements

(none)

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`select` ([XPath expression]({{% relref "../manual/xpathref/xpath" %}}))
: The path to be added. System dependent.






## Example


```xml
<Switch>
  <Case test="sd:variable-exists('searchpath')">
    <AddSearchpath select="$searchpath" />
  </Case>
</Switch>

```



