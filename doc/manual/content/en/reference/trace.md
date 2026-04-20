---
linktitle: "Trace"
weight: 1010
type: docs
---

# `Trace`
_since version 2.7.4_

Set debugging switches



## Child elements

(none)

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`assignments` (optional)
: Write assignments ([`SetVariable`]({{% relref "setvariable" %}})) to the log file.


  - `yes`: Verbose output in the protocol file.
  - `no`: Regular run (default).

`dump-structtree` (optional, _since version 4.19.8_)
: Dump the PDF/UA structure tree to an XML file.


  - `yes`: Write structure tree to file.
  - `no`: Don't write structure tree (default).

`grid` (optional)
: Draw the grid on the page.


  - `yes`: Show the grid.
  - `no`: Don't show the grid (default).

`gridallocation` (optional)
: Draw allocated cells with yellow and conflicts with red markers.


  - `yes`: Show grid allocation.
  - `no`: Don't show the grid allocation (default).

`gridlocation` (optional, _since version 4.15.0_)
: Location of the grid.


  - `foreground`: Draw the grid on top of all other objects.
  - `background`: Draw the grid below all other objects (default).

`groups` (optional, _since version 4.21.8_)
: Draw the grid inside all groups.


  - `yes`: Show the grid.
  - `no`: Don't show the grid (default).

`hyphenation` (optional)
: Draw little marks to show all hyphenation points.


  - `yes`: Show hyphenation points.
  - `no`: Don't show any hyphenation points (default).

`kerning` (optional)
: Draw little marks to show all kerning.


  - `yes`: Show kerning.
  - `no`: Don't show any kerning (default).

`objects` (optional)
: Draw rectangles around objects.


  - `yes`: Draw rectangles
  - `no`: No rectangles drawn around objects (default).

`textformat` (optional)
: Show textformt as a tooltip in the PDF


  - `yes`: Show textformat
  - `no`: Don't show textformat (default)

`verbose` (optional)
: Verbose output in the protocol file.


  - `yes`: Verbose output in the protocol file.
  - `no`: Regular run (default).




## Example


```xml
<Trace textformat="yes"/>
```



