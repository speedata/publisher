---
linktitle: "DefineMatter"
weight: 300
type: docs
---

# `DefineMatter`
_since version 4.3.5_

Define a new section of the document.



## Child elements

(none)

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`label` (optional)
: Set label for the user-visible page number.


  - `decimal`: Set the page number to decimal arabic numerals.
  - `lowercase-romannumeral`: Set the page numbering to lowercase romannumeral
  - `uppercase-romannumeral`: Set the page numbering to uppercase romannumeral
  - `lowercase-letter`: Set the page numbering to lowercase letter (a-z)
  - `uppercase-letter`: Set the page numbering to uppercase letter (A-Z)

`name` (text)
: The name of the section to be defined.



`prefix` (text, optional)
: Set the prefix of the displayed page number.



`resetafter` (yes or no, optional)
: Reset page numbering to 1 after this matter.



`resetbefore` (yes or no, optional)
: Set the page number to 1 at the section start.





## Remarks

There are two predefined matters: mainmatter (default) and frontmatter (which switches to lowercase romannumeral).




## Example


Set the page numbering to “A-1, A-2, ...”



```xml
<DefineMatter name="mainmatter" label="decimal" prefix="A-" />
```



