---
linktitle: "Ul"
weight: 1050
type: docs
---

# `Ul`


Create an unordered list, just like in HTML



## Child elements

<a href="../forall"><code>ForAll</code></a>, <a href="../li"><code>Li</code></a>

## Parent elements

<a href="../setvariable"><code>SetVariable</code></a>, <a href="../text"><code>Text</code></a>, <a href="../textblock"><code>Textblock</code></a>

## Attributes


`fontfamily` (text, optional, _since version 4.3.1_)
: The name of the font family for the paragraph. The default is “text” (lowercase t).






## Example


```xml
<PlaceObject>
  <Textblock>
    <Ul>
      <Li><Value>First item</Value></Li>
      <Li><Value>Second item</Value></Li>
      <Li><Value>Third item</Value></Li>
    </Ul>
  </Textblock>
</PlaceObject>

```



