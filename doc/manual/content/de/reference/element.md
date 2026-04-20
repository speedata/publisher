---
linktitle: "Element"
weight: 320
type: docs
---

# `Element`


Erzeugt eine Datenstruktur, die mithilfe von [`SaveDataset`]({{% relref "savedataset" %}}) auf Festplatte gespeichert werden kann.



## Kindelemente

<a href="../attribute"><code>Attribute</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../element"><code>Element</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../makeindex"><code>Makeindex</code></a>, <a href="../sortsequence"><code>SortSequence</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../value"><code>Value</code></a>

## Elternelemente

<a href="../case"><code>Case</code></a>, <a href="../element"><code>Element</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../message"><code>Message</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../savedataset"><code>SaveDataset</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`name` (Text)
: Name des Elements, das erzeugt wird.






## Beispiel


```xml
<Element name="artikelliste">
  <Attribute name="name" select=" @name "/>
  <Attribute name="seite" select=" sd:current-page()"/>
</Element>
```



