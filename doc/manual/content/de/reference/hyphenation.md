---
linktitle: "Hyphenation"
weight: 430
type: docs
---

# `Hyphenation`


Erzeugt einen Trennvorschlag für die automatische Silbentrennung. Die Trennvorschläge werden dann benutzt, wenn die automatische Silbentrennung fehlerhaft trennt. Alle Trennstellen müssen mit eine Bindestrich (-) markiert werden (s. Beispiel).



## Kindelemente

(keine)

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`language` (optional, _seit Version 4.3.12_)
: Die Sprache für diese Trennausnahme. Die Voreinstellung ist die Hauptsprache des Dokuments.






## Beispiel


```xml
<Hyphenation>Au-to-bahn</Hyphenation>
```



