---
title: speedata Publisher Documentation
type: docs
---

Automatically generate PDF files from XML data — with programmable layouts, typographic quality, and full control over every detail.

The Publisher reads two XML files — the data and the layout rules — and turns them into a PDF.
Once it is [installed]({{< relref "manual/setup" >}}), three commands take you to your first PDF:

```shell
sp new helloworld   # create a sample project with a data and a layout file
cd helloworld
sp                  # generate the PDF — the result is called publisher.pdf
```

The chapter [Hello, world!]({{< relref "manual/helloworld" >}}) explains step by step how the two files work together.

## Getting Started

{{< cards >}}
  {{< card link="manual/introduction" title="Introduction" subtitle="What the Publisher can do and what it's used for" >}}
  {{< card link="manual/helloworld" title="Hello, world!" subtitle="From zero to PDF in three commands" >}}
  {{< card link="manual/setup" title="Installation & Setup" subtitle="Installation, XML editor, and schema validation" >}}
{{< /cards >}}

## Topics

{{< cards >}}
  {{< card link="manual/basics" title="Basics" subtitle="Grid, page types, positioning, and data processing" >}}
  {{< card link="manual/text" title="Text & Fonts" subtitle="Text formatting, font loading, and hyphenation" >}}
  {{< card link="manual/imagesandgraphics" title="Images & Graphics" subtitle="Include, scale, and position images" >}}
  {{< card link="manual/tables" title="Tables" subtitle="Flexible tables with the HTML-like model" >}}
  {{< card link="manual/pagelayout" title="Page Layout" subtitle="Groups, virtual pages, and crop marks" >}}
  {{< card link="manual/colors" title="Colors" subtitle="Define and use colors" >}}
{{< /cards >}}

## Advanced

{{< cards >}}
  {{< card link="manual/webformats" title="Web Formats" subtitle="Use HTML, CSS, and Markdown in the Publisher" >}}
  {{< card link="manual/directories" title="Directories & Indices" subtitle="Table of contents, index, bookmarks, and markers" >}}
  {{< card link="manual/integration" title="Integration" subtitle="Lua filters, server mode, SaaS API, and accessibility" >}}
  {{< card link="manual/quality" title="Quality & Debugging" subtitle="Troubleshooting, performance, and quality assurance" >}}
{{< /cards >}}

## How-to guides

{{< cards >}}
  {{< card link="howto" title="How-to guides" subtitle="Task-oriented recipes with decision knowledge" >}}
  {{< card link="howto/datapreparation" title="Data preparation" subtitle="Transform up front or process in the layout?" >}}
  {{< card link="howto/tableorgroups" title="Table, groups or text flow?" subtitle="The central presentation decision" >}}
  {{< card link="howto/simpletable" title="Table with automatic breaking" subtitle="Article list with a repeating table head" >}}
  {{< card link="howto/columnwidths" title="Controlling column widths" subtitle="Fixed widths, star widths and mixed forms" >}}
  {{< card link="howto/continuationhead" title="Continuation head and note" subtitle="Varying head and foot per page" >}}
  {{< card link="howto/manualtablebreak" title="Breaking tables manually" subtitle="Portioning and measuring for custom break logic" >}}
  {{< card link="howto/datasheet" title="Basic structure of a data sheet" subtitle="Page type with head, foot and type area" >}}
  {{< card link="howto/tableofcontents" title="Table of contents" subtitle="Collecting page numbers, output in the next run" >}}
  {{< card link="howto/keywordindex" title="Keyword index" subtitle="Sorting and grouping with Makeindex" >}}
{{< /cards >}}

## Reference

{{< cards >}}
  {{< card link="reference/commands" title="Command Reference" subtitle="All commands and attributes at a glance" >}}
  {{< card link="reference/xpath" title="XPath & Layout Functions" subtitle="XPath expressions and sd: functions" >}}
  {{< card link="reference/commandline" title="Command Line" subtitle="All sp options in detail" >}}
  {{< card link="reference/configuration" title="Configuration" subtitle="Configuration file and environment variables" >}}
  {{< card link="reference/glossary" title="Glossary" subtitle="Terms and definitions" >}}
  {{< card link="reference/appendix" title="Appendix" subtitle="Defaults, file names, internal variables" >}}
{{< /cards >}}
