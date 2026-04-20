---
linktitle: "Bookmark"
weight: 120
type: docs
---

# `Bookmark`


Erstellt ein Lesezeichen für den PDF Betrachter (z.B. Adobe Reader). Wenn der Leser auf das Lesezeichen klickt, springt der PDF Betrachter an diese Stelle im Dokument.



## Kindelemente

(keine)

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../td"><code>Td</code></a>, <a href="../text"><code>Text</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`level` (Zahl)
: Hierarchieebene. 1 ist die höchste Ebene, zwei die nächst tiefere Ebene etc.



`open` (optional)
: Bestimmt, ob die Kind-Lesezeichen dargestellt werden sollen oder nicht.


  - `yes`: Zeige Kinder.
  - `no`: Verstecke Kinder.

`select` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}))
: Titel des Lesezeichens






## Beispiel


```xml
<Bookmark level="1" select="$titel" open="no"/>
```

Erzeugt ein Lesezeichen der Stufe 1 (höchste Stufe) mit dem Titel, der in der Variablen `titel` steht.





