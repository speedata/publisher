---
linktitle: "Compatibility"
weight: 220
type: docs
---

# `Compatibility`


Setze Kompatibilität für ältere Layoutregeln



## Kindelemente

(keine)

## Elternelemente

<a href="../layout"><code>Layout</code></a>, <a href="../section"><code>Section</code></a>

## Attribute


`movecursoronplaceobject` (optional, _seit Version 2.7.4_)
: Wechselt das Verhalten bei dem Objekte (platziert mit PlaceObject) am rechten Rand den Cursor in Spalte »Anzahl Spalten + 1« setzt.


  - `yes`: Neues Verhalten (Voreinstellung): setzt den Cursor in Spalte 1 wenn ein Objekt an den rechten Rand stößt.
  - `no`: Altes Verhalten: setzt den Cursor auf die Spalte 1 hinter den rechten Rand des platzierten Objekts.




## Beispiel


```xml
<Compatibility
    movecursoronplaceobject="no"
/>

```



