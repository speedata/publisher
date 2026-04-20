---
linktitle: "Column"
weight: 200
type: docs
---

# `Column`


Gibt die Eigenschaften einer Spalte in einer Tabelle an.



## Kindelemente

(keine)

## Elternelemente

<a href="../case"><code>Case</code></a>, <a href="../columns"><code>Columns</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`align` (optional)
: Die horizontale Ausrichtung des Tabelleninhalts. Kann in einer Zelle ([`Td`]({{% relref "td" %}})) überschrieben werden.


  - `left`: Die Tabellenzellen dieser Spalte werden linksbündig ausgerichtet.
  - `center`: Die Tabellenzellen dieser Spalte werden horizontal zentriert.
  - `right`: Die Tabellenzellen dieser Spalte werden rechtsbündig ausgerichtet.

`background-color` (Text, optional)
: Farbe der Tabellenspalte.



`minwidth` (Längenangabe, optional, _seit Version 4.13.9_)
: Minimale Breite der Spalte. Kann entweder in Rasterzellen (Zahl) oder in absoluten Maßangaben (z.B. 1cm) angegeben werden.



`padding-left` (Längenangabe, optional, _seit Version 3.1.8_)
: Setze das linke padding für diese Spalte



`padding-right` (Längenangabe, optional, _seit Version 3.1.8_)
: Setze das rechte padding für diese Spalte



`valign` (optional)
: Die vertikale Ausrichtung des Tabelleninhalts. Kann in einer Zelle (Td) überschrieben werden.


  - `top`: Die Tabellenzellen dieser Spalte werden oben ausgerichtet.
  - `middle`: Die Tabellenzellen dieser Spalte werden vertikal zentriert ausgerichtet.
  - `bottom`: Die Tabellenzellen dieser Spalte werden  unten ausgerichtet.

`width` (Zahl, Maßangabe oder *-Angaben, optional)
: Breite der Spalte. Kann entweder in Rasterzellen (Zahl), absoluten Maßangaben (z.B. 1cm), in `*`-Angaben (z.B. `4*`) oder mit den Schlüsselwörtern `min` und `max` angegeben werden.






## Beispiel


Siehe das Beispiel bei [`Columns`]({{% relref "columns" %}}).





