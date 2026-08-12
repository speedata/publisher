---
title: Basics
weight: 40
type: docs
---

The study of this chapter should be sufficient to create layout rules by yourself. Occasionally, more detailed topics will be covered in a later chapter. For example, only the most important formatting for tables is dealt with; a separate chapter ([Tables]({{< relref "tables" >}})) describes tables in detail. In such cases there is of course a cross-reference.

{{< callout >}}
Another note for the manual. Many examples only show the layout file and not the corresponding data. In the data file the simple structure `<data />` is always assumed. This can be recognized by the fact that the layout contains `<Record element="data">`. The easiest way to start the Publisher is to use `sp --dummy`, which simulates this data file.
{{< /callout >}}

{{< cards >}}
  {{< card link="structuredatafile" title="Data File Structure" subtitle="How to structure the data file" >}}
  {{< card link="outputtingobjects" title="Outputting Objects" subtitle="Text, images, boxes, barcodes, and more" >}}
  {{< card link="fileorganization" title="File Organization" subtitle="How the Publisher finds files" >}}
  {{< card link="grid" title="Grid" subtitle="The page grid and object placement" >}}
  {{< card link="pagetypes" title="Page Types" subtitle="Defining different page templates" >}}
  {{< card link="programming" title="Programming" subtitle="Variables, conditions, loops, and functions" >}}
  {{< card link="positioningframe" title="Placement areas" subtitle="Areas and frames on the page" >}}
{{< /cards >}}
