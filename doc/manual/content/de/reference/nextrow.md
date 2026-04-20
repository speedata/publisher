---
linktitle: "NextRow"
weight: 600
type: docs
---

# `NextRow`


Der virtuelle Cursor wird auf die nächste freie Zeile gesetzt.



## Kindelemente

(keine)

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`area` (Text, optional)
: Name des Bereichs, in dem der Cursor bewegt wird.



`row` (Zahl, optional)
: Zeile für den virtuellen Cursor. Wird keine Zeile angegeben, dann sucht sich der Publisher selbständig eine freie Zeile (ggf. auf einer neuen Seite oder in einem neuen Platzierungsrahmen).



`rows` (Zahl, optional)
: Anzahl der Zeilen, die frei gehalten werden sollen. Vorgabe: 1.






## Beispiel


```xml
<Record element="image">
  <NextRow row="5"/>
  <PlaceObject column="{column}">
    <Image width="10" file="{.}"/>
  </PlaceObject>
</Record>
```

This places the image on row 5.



```xml
<Record element="bild">
  <NeueZeile row="5" />
  <PlaceObject column="{$spalte}">
    <Image width="10" file="{.}" />
  </PlaceObject>
</Record>
```



