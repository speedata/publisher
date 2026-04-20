---
linktitle: "ProcessNode"
weight: 760
type: docs
---

# `ProcessNode`


Bearbeitet alle angegebenen Datensätze. Die Elemente, für die die Regeln ausgeführt werden sollen, werden mit dem Attribut select angegeben.



## Kindelemente

(keine)

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`limit` (Zahl, optional, _seit Version 2.5.6_)
: Beschränkt die Anzahl der Datensätze, die mit diesem Befehl verarbeitet werden.



`mode` (Text, optional)
: Name des Modus. Dieser muss bei [`Record`]({{% relref "record" %}}) exakt übereinstimmen. Damit ist es möglich für dasselbe Element unterschiedliche Regeln aufzurufen.



`select` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}))
: Auswahl der Kindelemente, die verarbeitet werden sollen.






## Beispiel


```xml
<ProcessNode select="*" mode="summe" />
```



