---
linktitle: "TableNewPage"
weight: 930
type: docs
---

# `TableNewPage`
_seit Version 3.3.13_

Wechselt auf eine neue Seite innerhalb einer Tabelle.



## Kindelemente

(keine)

## Elternelemente

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../table"><code>Table</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute
(keine)



## Beispiel


```xml
<PlaceObject>
  <Table stretch="max">
    <Tr>
      <Td><Paragraph><Value>One</Value></Paragraph></Td>
    </Tr>
    <TableNewPage/>
    <Tr>
      <Td><Paragraph><Value>Two</Value></Paragraph></Td>
    </Tr>
  </Table>
</PlaceObject>

```

Die zweite Zeile der Tabelle ist auf der zweiten Seite.





