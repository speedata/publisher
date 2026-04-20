---
linktitle: "Stylesheet"
weight: 880
type: docs
---

# `Stylesheet`


Lädt eine CSS-Datei oder definiert CSS-Eigenschaften



## Kindelemente

(keine)

## Elternelemente

<a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../section"><code>Section</code></a>

## Attribute


`filename` (Text, optional)
: Der Dateiname der CSS Datei (inklusive Dateiendung).





## Bemerkungen

Wird kein Dateiname angegeben, so erwartet der speedata Publisher CSS-Eigenschaften als Inhalt des Elements.




## Beispiel


```xml
<Stylesheet filename="style.css" />
```

```xml
<Stylesheet>
  frame {
    border-bottom-right-radius: 1cm;
    border-bottom-left-radius: 1cm;
    border-top-right-radius: 1cm;
    border-top-left-radius: 1cm;
  }
  box {
    background-color: red;
  }
</Stylesheet>
```



