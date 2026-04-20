---
linktitle: "HTML"
weight: 420
type: docs
---

# `HTML`
_since version 5.1.17_

Create HTML output



## Child elements

HTML elements

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../output"><code>Output</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`expand-text` (yes or no, optional)
: If set to "yes", expressions in curly braces {expr} within the HTML content are evaluated as XPath expressions (similar to XSLT 3.0 text value templates). Use {{ and }} for literal curly braces. Default is "no".



`select` ([XPath expression]({{% relref "../manual/xpathref/xpath" %}}), optional)
: The HTML selection






## Example


```xml
<Output>
  <HTML select="html" />
</Output>
```

Inline HTML with XPath expansion:



```xml
<Output>
  <HTML expand-text="yes">
    <p>Article <b>{@nr}</b> costs {$price} Euro.</p>
  </HTML>
</Output>
```



