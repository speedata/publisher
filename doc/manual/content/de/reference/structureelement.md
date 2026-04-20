---
linktitle: "StructureElement"
weight: 870
type: docs
---

# `StructureElement`
_seit Version 4.19.8_

Erzeugt eine hierarchische Struktur für tagged-PDF



## Kindelemente

<a href="../structureelement"><code>StructureElement</code></a>

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../structureelement"><code>StructureElement</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`id` (Text, optional)
: Eindeutige ID für dieses Strukturelement. Benutzt in in [`Paragraph`]({{% relref "paragraph" %}}) und [`Image`]({{% relref "image" %}}).



`parent` (Text, optional)
: ID für die Elternstruktur.



`role` ()
: Tagname für das Element.






## Beispiel


Das folgende Beispiel erzeugt einen H1 Title in einem Abschnitt des Dokuments:



```xml
<PDFOptions format="PDF/UA" />
<StructureElement role="Document">
  <StructureElement role="Sect" id="sect"/>
</StructureElement>
<Record element="data">
  <PlaceObject>
    <Textblock>
      <Paragraph role="H1" parent="sect">
        <Value>A title</Value>
      </Paragraph>
    </Textblock>
  </PlaceObject>
</Record>

```



