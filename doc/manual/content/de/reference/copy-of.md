---
linktitle: "Copy-of"
weight: 240
type: docs
---

# `Copy-of`


Ersetzt dieses Element mit dem Inhalt von `select` als Elementstruktur. Dient zum „Zusammenbauen“ von Texten und Tabellen.



## Kindelemente

(keine)

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../columns"><code>Columns</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../element"><code>Element</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savedataset"><code>SaveDataset</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../table"><code>Table</code></a>, <a href="../tablefoot"><code>Tablefoot</code></a>, <a href="../tablehead"><code>Tablehead</code></a>, <a href="../td"><code>Td</code></a>, <a href="../text"><code>Text</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../tr"><code>Tr</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`select` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}))
: Die Auswahl (eine Variable) die kopiert werden soll.






## Beispiel


```xml
<SetVariable variable="meinabsatz">
  <Paragraph>
    <Value select="@name"/><Value>, Symbol=</Value><Value select="@symbol"/>
  </Paragraph>
</SetVariable>
<PlaceObject>
  <Textblock>
    <Copy-of select="$meinabsatz"/>
  </Textblock>
</PlaceObject>
```

ist dasselbe wie



```xml
<PlaceObject>
  <Textblock>
    <Paragraph>
      <Value select="@name"/><Value>, Symbol=</Value><Value select="@symbol"/>
    </Paragraph>
  </Textblock>
</PlaceObject>

```

nur mit dem Unterschied, dass der Inhalt vom Paragraph (`@name`, `@symbol`) ermittelt werden kann, bevor der Text ausgegeben wird. Die Zuweisung und die Textausgabe können in
        verschiedenen Regeln stehen.





