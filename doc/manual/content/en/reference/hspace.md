---
linktitle: "HSpace"
weight: 410
type: docs
---

# `HSpace`


Two modes: with a given width, the space takes up the given amount. 

With no width given: create a horizontal stretching space. The space will take up no width as a minimum but is able to stretch up to infinity. Useful in single line contexts. In normal text there will surprising little stretching involved due to the global paragraph optimization algorithm.
        You will see that all other word spaces will have the minimum width and the excessive whitespace is accumulated at the strechable space.



## Child elements

(none)

## Parent elements

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../i"><code>I</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../span"><code>Span</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`leader` (text, optional, _since version 2.3.50_)
: The text that should be displayed instead of the space. For example a dot (.).



`leader-width` (length, optional, _since version 2.3.50_)
: Distance between two leader text starting points



`minwidth` (length, optional, _since version 3.3.5_)
: The (optional) minimum width of the inserted space.



`width` (length, optional)
: Optional width of the space (a length).






## Example


```xml
<PlaceObject>
  <Textblock>
    <Paragraph>
      <Value>Hello</Value><HSpace/><Value>World</Value>
    </Paragraph>
  </Textblock>
</PlaceObject>
```



