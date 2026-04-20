---
linktitle: "Initial"
weight: 470
type: docs
---

# `Initial`
_since version 2.9.7_

Make some letters appear in a larger font at the beginning of the paragraph.



## Child elements

<a href="../value"><code>Value</code></a>

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`color` (text, optional, _since version 2.9.0_)
: Set the color of the initial. Defaults to black.



`fontfamily` (text, optional)
: Choose the font family. Only “Regular” shape is used at the moment.



`padding-bottom` (length, optional, _since version 4.1.25_)
: Insert space bottom of the initial.



`padding-left` (length, optional)
: Insert space left of the initial.



`padding-right` (length, optional)
: Insert space right of the initial.



`padding-top` (length, optional, _since version 4.1.25_)
: Insert space top of the initial.






## Example


```xml
<Textblock>
  <Paragraph>
    <Initial fontfamily="Large" padding-right="2pt">
      <Value select="'A'"/>
    </Initial>
    <Value>certain king had a beautiful garden,
    and in the garden stood a tree which bore golden
    apples.</Value>
  </Paragraph>
</Textblock>

```

![ref-initial-en.png](/img/ref-initial-en.png)



## Info


Make sure you set the font face for the surrounding Paragraph to get the spacing right (it defaults to text).




