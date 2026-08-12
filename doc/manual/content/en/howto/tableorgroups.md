---
title: "Table, groups or text flow?"
weight: 12
type: docs
---

Once the shape of the data is settled (see [Data preparation]({{< relref "datapreparation" >}})), the central presentation decision follows: which way does the content get onto the page? The Publisher knows three basic forms, and most layout problems arise from starting with the wrong one.

## Table

The table arranges content in rows and columns: all records align to the same columns, breaking across pages happens [automatically and row by row]({{< relref "simpletable" >}}), head and foot repeat. The cells are rectangular boxes that never break internally.

Typical applications: article lists, price lists, technical data tables; everything where many uniform records sit below each other. Details in the manual chapter [Tables]({{< relref "/manual/tables" >}}).

## Groups and absolute positioning

A [group]({{< relref "groups" >}}) is a virtual area that is first assembled invisibly. Afterwards it can be measured with `sd:group-height()` and `sd:group-width()` to decide where (and whether) it goes onto the page: the pattern “measure first, then place”. Together with absolute positioning (fixed coordinates or grid positions at `<PlaceObject>`) this is the way for pages whose design is fixed and into which the content has to fit.

Typical applications: data sheets with a fixed page structure, catalogs built from modules of varying height where each module is checked against the remaining space before it is placed.

## Text flow

Running text belongs neither in a table nor in a group but in `<Output>`/`<Text>`: paragraphs flow across pages and placement areas, breaking happens at line boundaries, and images can be [wrapped around]({{< relref "wrappingaroundobjects" >}}). The introduction is in the section [Placing objects]({{< relref "outputtingobjects" >}}).

Typical applications: longer descriptions, editorial parts, everything paragraph-shaped.

## Guiding questions

* **Do contents have to align to columns across records?** Then table; with groups you only get column alignment by tedious manual work.
* **Is the design fixed and every position predetermined?** Then groups and absolute positioning; a table would fight against the design.
* **Does something have to be measured before placing** (“does the next module still fit on this page?”)? Then groups.
* **Does the content flow as text across pages** or should it wrap around images? Then `<Output>`/`<Text>`.
* **Is the list long and are the rows uniform?** Then the table with automatic breaking, see the [recipe]({{< relref "simpletable" >}}).

The forms are not mutually exclusive, quite the opposite: table cells can contain images and paragraphs, groups often contain tables (to measure a table before placing it), and a text flow can carry tables between its paragraphs. The decision concerns the outermost form of each content block, not the whole document.

<!-- TODO PG: add practice examples – e.g. a concrete case where table vs. groups was chosen wrongly and what that cost; a typical catalog page as a mixed form. Later link to the backlog recipe "one article group, implemented three times". -->

## Decision table

| If … | then … |
|---|---|
| contents should align to columns across records | table |
| long, uniform list with automatic page breaking | table ([recipe]({{< relref "simpletable" >}})) |
| fixed page design, exact positions | groups and absolute positioning |
| measuring before placing (“does it still fit?”) | groups ([manual]({{< relref "groups" >}})) |
| running text across several pages or areas | `<Output>`/`<Text>` |
| text should wrap around images | `<Output>`/`<Text>` ([manual]({{< relref "wrappingaroundobjects" >}})) |
