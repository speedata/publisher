---
linktitle: "AddSearchpath"
weight: 30
type: docs
---

# `AddSearchpath`
_seit Version 3.1.1_

Ein Verzeichnis auf der Festplatte, das zum Suchpfad des Publishers hinzugefügt wird.



## Kindelemente

(keine)

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`select` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}))
: Der Pfad, der hinzugefügt werden soll. Systemabhängig.






## Beispiel


```xml
<Switch>
  <Case test="sd:variable-exists('searchpath')">
    <AddSearchpath select="$searchpath" />
  </Case>
</Switch>

```



