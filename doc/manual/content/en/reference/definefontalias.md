---
linktitle: "DefineFontalias"
weight: 270
type: docs
---

# `DefineFontalias`
_since version 2.7.12_

Defines a font alias. When defining a font family, you can use the an alias for the fontname. Aliases are looked up recursively.



## Child elements

(none)

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`alias` (text)
: New (equivalent) name of the font



`existing` (text)
: The name of the existing font family.






## Example


```xml
<DefineFontalias existing="DejaVuSerif" alias="serif"/>
<DefineFontalias existing="DejaVuSerif-Bold" alias="serif-bold"/>
<DefineFontalias existing="DejaVuSerif-Italic" alias="serif-italic"/>
<DefineFontalias existing="DejaVuSerif-BoldItalic" alias="serif-bolditalic"/>
```

Now you can define a font family with



```xml
<DefineFontfamily name="title" fontsize="15" leading="17">
  <Regular fontface="serif"/>
  <Bold fontface="serif-bold"/>
  <BoldItalic fontface="serif-bolditalic"/>
  <Italic fontface="serif-italic"/>
</DefineFontfamily>
```



