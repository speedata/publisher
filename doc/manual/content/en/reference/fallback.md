---
linktitle: "Fallback"
weight: 330
type: docs
---

# `Fallback`
_since version 3.7.7_

Define a fallback for [`LoadFontfile`]({{% relref "loadfontfile" %}})



## Child elements

(none)

## Parent elements

<a href="../loadfontfile"><code>LoadFontfile</code></a>

## Attributes


`filename` (text)
: The filename of the font to be used as a fallback.






## Example


```xml
<LoadFontfile name="zh" filename="Microsoft JhengHei.ttf" >
  <Fallback filename="texgyreheros-regular.otf" />
  <Fallback filename="ZapfDingbats.ttf" />
</LoadFontfile>

```



