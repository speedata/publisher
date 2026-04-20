---
linktitle: "Compatibility"
weight: 220
type: docs
---

# `Compatibility`


Set compatibility for older layouts



## Child elements

(none)

## Parent elements

<a href="../layout"><code>Layout</code></a>, <a href="../section"><code>Section</code></a>

## Attributes


`movecursoronplaceobject` (optional, _since version 2.7.4_)
: Switch the behavior where objects at the right page margin used in PlaceObject puts the cursor in #columns + 1.


  - `yes`: New behavior (default): set cursor in column 1 when an object goes to the right margin.
  - `no`: Old behavior: set the cursor to the column + 1 past the right edge of the placed object.




## Example


```xml
<Compatibility
    movecursoronplaceobject="no"
/>

```



