---
linktitle: "Tablehead"
weight: 950
type: docs
---

# `Tablehead`


Create a repeating table head.



## Child elements

<a href="../copy-of"><code>Copy-of</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../tablerule"><code>Tablerule</code></a>, <a href="../tr"><code>Tr</code></a>, <a href="../value"><code>Value</code></a>

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../table"><code>Table</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`page` (optional)
: The page the table head should appear on. Defaults to “all”


  - `first`: Only appear on the first page.
  - `all`: All pages. If “first” is defined, the tablehead appears on all pages but the first.



## Remarks

The contents of the table head gets repeated on every page of a broken table.




## Example


See the explanation of [`Table`]({{% relref "table" %}}).





