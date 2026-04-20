---
linktitle: "Fallback"
weight: 330
type: docs
---

# `Fallback`
_seit Version 3.7.7_

Definiere ein Fallback für [`LoadFontfile`]({{% relref "loadfontfile" %}})



## Kindelemente

(keine)

## Elternelemente

<a href="../loadfontfile"><code>LoadFontfile</code></a>

## Attribute


`filename` (Text)
: Der Dateiname der Schriftart, die als Fallback benutzt werden soll.






## Beispiel


```xml
<LoadFontfile name="zh" filename="Microsoft JhengHei.ttf" >
  <Fallback filename="texgyreheros-regular.otf" />
  <Fallback filename="ZapfDingbats.ttf" />
</LoadFontfile>

```



