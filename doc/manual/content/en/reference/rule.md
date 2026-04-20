---
linktitle: "Rule"
weight: 790
type: docs
---

# `Rule`


Draw a horizontal or vertical rule in the grid.



## Child elements

(none)

## Parent elements

<a href="../clip"><code>Clip</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../position"><code>Position</code></a>, <a href="../transformation"><code>Transformation</code></a>

## Attributes


`color` (text, optional, CSS property: background-color)
: The color of the rule. Defaults to black.



`dashed` (optional, _since version 2.3.50_)
: Use a dashed rule instead of a solid rule.


  - `yes`: Draw a dashed rule.
  - `no`: Draw a solid rule.

`direction` ()
: The direction of the rule.


  - `horizontal`: Horizontal rule
  - `vertical`: Vertical rule

`length` (number or length)
: The length of the rule in grid cells or as an absolute length.



`rulewidth` (number or length, optional, CSS property: height)
: The rule thickness given in grid cells or as a length.






## Example


```xml
<Record element="data">
  <PlaceObject>
    <Rule direction="horizontal" length="10" rulewidth="3"/>
  </PlaceObject>
</Record>
```



