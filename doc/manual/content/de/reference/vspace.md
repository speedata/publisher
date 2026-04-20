---
linktitle: "VSpace"
weight: 1070
type: docs
---

# `VSpace`


Erzeugt einen vertikal dehnbaren Leerraum. Der Leerraum hat die minimale Höhe 0 und die maximale Höhe »unendlich«. Sinnvoll nutzbar in Tabellenzellen.



## Kindelemente

(keine)

## Elternelemente

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../td"><code>Td</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`height` (Längenangabe, optional, _seit Version 4.7.12_)
: Optionale Höhe des Leerraums



`minheight` (Längenangabe, optional, _seit Version 4.7.12_)
: Die (optionale) minimale Höhe des eingefügten Leerraums.






## Beispiel


```xml
<Td valign="bottom">
  <VSpace/>
  <!-- vertikal zentriertes Bild-->
  <Image width="3" file="article.pdf"/>
  <VSpace/>
  <Paragraph><Value>Text am unteren Ende der Zelle</Value></Paragraph>
</Td>

```



