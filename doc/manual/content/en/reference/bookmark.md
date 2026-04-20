---
linktitle: "Bookmark"
weight: 120
type: docs
---

# `Bookmark`


Create a bookmark for the PDF viewer (e.g. Adobe Reader). When the user clicks on a bookmark, the PDF viewer jumps to that place in the document.



## Child elements

(none)

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../td"><code>Td</code></a>, <a href="../text"><code>Text</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`level` (number)
: 1 is the top level, 2 is the next level, etc.



`open` (optional)
: If yes, the child elements are shown. If no, the child elements are hidden.


  - `yes`: Show children.
  - `no`: Hide children.

`select` ([XPath expression]({{% relref "../manual/xpathref/xpath" %}}))
: Title of the bookmark






## Example


```xml
<Bookmark level="1" select="$title" open="no" />
```

Create a bookmark on level 1 (top level) with the title stored in the variable `title`.





