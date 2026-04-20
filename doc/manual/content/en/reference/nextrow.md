---
linktitle: "NextRow"
weight: 600
type: docs
---

# `NextRow`


The virtual cursor is set on the next free row.



## Child elements

(none)

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`area` (text, optional)
: Name of the area of the virtual cursor.



`row` (number, optional)
: The absolute number of the row for the cursor. If no row is given, the system tries to find a completely free row (perhaps on an empty page).



`rows` (number, optional)
: The number of rows to clear. Defaults to 1.






## Example




