---
linktitle: "Regular"
weight: 780
type: docs
---

# `Regular`


The (symbolic) name of the fontface for regular text, i.e. without bold or italic.



## Child elements

(none)

## Parent elements

<a href="../definefontfamily"><code>DefineFontfamily</code></a>

## Attributes


`fontface` (text)
: The symbolic name of the font file.






## Example


```xml
<DefineFontfamily name="Title" fontsize="12" leading="14">
  <Regular fontface="Helvetica Regular"/>
  <Bold fontface="Helvetica Bold"/>
  <Italic fontface="Helvetica Italic"/>
  <BoldItalic fontface="Helvetica Bold Italic"/>
</DefineFontfamily>

```

This font family can now be accessed like this:



```xml
<Textblock fontfamily="Title">
  <Paragraph>
    <Value>...<Value>
  </Paragraph>
</Textblock>

```



