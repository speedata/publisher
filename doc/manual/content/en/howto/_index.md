---
title: "How-to guides"
weight: 15
type: docs
---

While the [manual]({{< relref "/manual" >}}) explains the concepts and the [reference]({{< relref "/reference" >}}) is there for looking things up, the how-to guides lead to a finished result: each recipe solves a concrete task from practice, with a runnable layout and data to reproduce it.

The recipes contain more than step-by-step instructions; they also carry the decision knowledge behind them. Every recipe follows the same structure:

* **Task**: what is to be created, with a picture of the goal.
* **Decision**: which approaches exist and how to recognize the right one.
* **Solution**: the way to the result, step by step.
* **Limits**: when this approach no longer works and what to do then.

All recipes use the same fictional data set: the article data of “Confixa”, an invented manufacturer of fastening technology (screws, wall plugs, anchors). The data is introduced in the first recipe and grows with the tasks.

## Decision guides

Two questions come up in every project, even before the first recipe is used:

{{< cards >}}
  {{< card link="datapreparation" title="Data preparation" subtitle="Transform up front or process in the layout?" >}}
  {{< card link="tableorgroups" title="Table, groups or text flow?" subtitle="The central presentation decision" >}}
{{< /cards >}}

## Tables

{{< cards >}}
  {{< card link="simpletable" title="Simple table with automatic breaking" subtitle="Article list with a repeating table head across pages" >}}
  {{< card link="columnwidths" title="Controlling column widths" subtitle="Fixed widths, star widths and mixed forms" >}}
  {{< card link="continuationhead" title="Continuation head and continuation note" subtitle="Varying head and foot per page" >}}
  {{< card link="manualtablebreak" title="Breaking complex tables manually" subtitle="Portioning and measuring for continuation pages with custom logic" >}}
{{< /cards >}}

## Page scaffold

{{< cards >}}
  {{< card link="datasheet" title="Basic structure of a data sheet" subtitle="Page type with head, foot and type area, millimeter-exact" >}}
{{< /cards >}}

## Directories

{{< cards >}}
  {{< card link="tableofcontents" title="Table of contents" subtitle="Collecting page numbers and outputting them in the next run" >}}
  {{< card link="keywordindex" title="Keyword index" subtitle="Sorting and grouping with Makeindex, merging page numbers" >}}
{{< /cards >}}

More recipes will follow.
