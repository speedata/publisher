---
linktitle: "Stylesheet"
weight: 880
type: docs
---

# `Stylesheet`


Load a CSS file or define CSS rules



## Child elements

(none)

## Parent elements

<a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../section"><code>Section</code></a>

## Attributes


`filename` (text, optional)
: The filename of the CSS stylesheet including the file extension.





## Remarks

If no filename is given, the speedata Publisher expects the CSS rules as the contents of this element.




## Example


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



