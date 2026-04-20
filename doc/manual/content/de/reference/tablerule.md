---
linktitle: "Tablerule"
weight: 960
type: docs
---

# `Tablerule`


Erzeugt eine horizontale Linie in einer Tabelle



## Kindelemente

(keine)

## Elternelemente

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../table"><code>Table</code></a>, <a href="../tablefoot"><code>Tablefoot</code></a>, <a href="../tablehead"><code>Tablehead</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`break-below` (yes oder no, optional, _seit Version 3.5.2_)
: Erlaube einen Umbruch unterhalb der Linie?



`class` (Text, optional)
: CSS Klasse für dieses Element.



`color` (Text, optional, CSS Eigenschaft: background-color)
: Farbe der Linie. (Default: Schwarz). Eine Farbe mit dem Namen »-« (ohne Anführungszeichen) ist eine transparente »Farbe«.



`id` (Text, optional)
: CSS id für dieses Element.



`rulewidth` (Längenangabe, optional, CSS Eigenschaft: height)
: Die »Dicke« der Linie. Voreinstellung ist 0.25 Punkt.



`start` (Zahl, optional, CSS Eigenschaft: rule-start)
: Die erste Spalte der Linie. Voreinstellung ist 1.





## Bemerkungen

Die Linie geht über die gesamte Breite der Tabelle und verschiebt nachfolgende Zeilen nach unten.




## Beispiel


```xml
<Tablerule rulewidth="1pt" />
<Tr>
  <Td align="center">Platz</Td>
  <Td align="center">Club</Td>
  <Td align="center">Punkte</Td>
  <Td align="center">Differenz</Td>
</Tr>
<Tablerule rulewidth="0.6pt" />
...
```



