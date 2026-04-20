---
linktitle: "Attribute"
weight: 70
type: docs
---

# `Attribute`


Erzeugt ein Attribut für die [`Element`]({{% relref "element" %}}) Datenstruktur, die mithilfe von [`SaveDataset`]({{% relref "savedataset" %}}) auf Festplatte gespeichert werden kann.



## Kindelemente

(keine)

## Elternelemente

<a href="../case"><code>Case</code></a>, <a href="../element"><code>Element</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`name` (Text)
: Name des Attributs, das erzeugt wird.



`select` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}))
: Der Inhalt des Attributs






## Beispiel


```xml
<Element name="Eintrag">
  <Attribute name="kapitelname" select="@name"/>
  <Attribute name="seite" select="sd:current-page()"/>
</Element>
```

Erzeugt diese Datenstruktur:



```xml
<Eintrag kapitelname=" (Inhalt von @name) " seite=" (aktuelle Seitennummer) " />
```



