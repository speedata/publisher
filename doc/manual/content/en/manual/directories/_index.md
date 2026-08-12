---
title: "Directories & Lists"
weight: 75
type: docs
---

Creating directories, indexes, bookmarks and other navigation aids.

There are three methods for tables of contents and similar lists, differing in effort and flexibility:

| Method | How it works | Runs | Suitable when … |
|---|---|---|---|
| [Markers]({{< relref "directoriesmarker" >}}) | `<Mark>` marks positions in the text, `sd:pagenumber()` returns the page number; the Publisher takes care of storing the data | 2 | you only need page numbers for known names |
| [XML data set]({{< relref "directoriesxml" >}}) | entries are collected manually, saved with `<SaveDataset>` and processed in the next run | 2 to 3 | the list needs its own structure or additional information (e.g. article lists) |
| [Single run]({{< relref "tocinonerun" >}}) | pages are reserved with `<InsertPages>` and created at the end with `<SavePages>` | 1 | the length of the list is known in advance |

{{< cards >}}
  {{< card link="directoriesmarker" title="Markers" subtitle="Page markers for running heads and directories" >}}
  {{< card link="directoriesxml" title="Creating Lists" subtitle="Building XML structures for directories" >}}
  {{< card link="tocinonerun" title="Table of Contents" subtitle="TOC in a single run" >}}
  {{< card link="indexcreation" title="Sorting and Grouping" subtitle="Sorting data, keyword indexes with Makeindex" >}}
  {{< card link="bookmarks" title="Bookmarks" subtitle="Creating PDF bookmarks" >}}
{{< /cards >}}
