---
linktitle: "HTML"
weight: 420
type: docs
---

# `HTML`
_seit Version 5.1.17_

Erzeugt HTML-Ausgabe



## Kindelemente

HTML-Elemente

## Elternelemente

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../output"><code>Output</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`expand-text` (yes oder no, optional)
: Bei "yes" werden Ausdrücke in geschweiften Klammern {expr} im HTML-Inhalt als XPath-Ausdrücke ausgewertet (ähnlich wie XSLT 3.0 Text Value Templates). Für literale geschweifte Klammern {{ und }} verwenden. Standard ist "no".



`select` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}), optional)
: Das HTML-Element






## Beispiel


```xml
<Output>
  <HTML select="html" />
</Output>
```

Inline-HTML mit XPath-Ersetzung:



```xml
<Output>
  <HTML expand-text="yes">
    <p>Der Artikel <b>{@nr}</b> kostet {$preis} Euro.</p>
  </HTML>
</Output>
```



