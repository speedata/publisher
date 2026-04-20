---
linktitle: "VSpace"
weight: 1070
type: docs
---

# `VSpace`


Create a vertically stretching space. The space has a minimum height of 0 but is able to stretch up to infinity. Useful in table cells.



## Child elements

(none)

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../td"><code>Td</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`height` (length, optional, _since version 4.7.12_)
: Optional height of the space (a length).



`minheight` (length, optional, _since version 4.7.12_)
: The (optional) minimum height of the inserted space.






## Example


```xml
<Td valign="bottom">
  <VSpace/>
  <!-- vertically centered image -->
  <Image width="3" file="article.pdf"/>
  <VSpace/>
  <Paragraph><Value>Some text at the bottom of the cell</Value></Paragraph>
</Td>

```



