---
linktitle: "StructureElement"
weight: 870
type: docs
---

# `StructureElement`
_since version 4.19.8_

Create a structure hierarchy for tagged PDF.



## Child elements

<a href="../structureelement"><code>StructureElement</code></a>

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../structureelement"><code>StructureElement</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`id` (text, optional)
: A unique id for this structure element. Used in [`Paragraph`]({{% relref "paragraph" %}}) and [`Image`]({{% relref "image" %}}).



`parent` (text, optional)
: Id of the parent structure.



`role` ()
: Tag name of the element.






## Example


The following example creates a H1 heading within a Section of the Document:



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



