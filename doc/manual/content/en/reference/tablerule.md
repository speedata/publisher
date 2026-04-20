---
linktitle: "Tablerule"
weight: 960
type: docs
---

# `Tablerule`


Insert a horizontal rule in a table



## Child elements

(none)

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../table"><code>Table</code></a>, <a href="../tablefoot"><code>Tablefoot</code></a>, <a href="../tablehead"><code>Tablehead</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`break-below` (yes or no, optional, _since version 3.5.2_)
: Allow break below the table rule?



`class` (text, optional)
: CSS class for this element.



`color` (text, optional, CSS property: background-color)
: The color of the rule. Defaults to black. A color named “-” (without quotes) is a transparent “color”.



`id` (text, optional)
: CSS id for this element.



`rulewidth` (length, optional, CSS property: height)
: The width (thickness) of the rule. Defaults to 0.25pt.



`start` (number, optional, CSS property: rule-start)
: The first column of the rule. Defaults to 1.






## Example


```xml
<Tablerule rulewidth="1pt"/>
<Tr>
  <Td align="center">Position</Td>
  <Td align="center">Club</Td>
  <Td align="center">Points</Td>
  <Td align="center">Difference</Td>
</Tr>
<Tablerule rulewidth="0.6pt"/>

```



