---
title: "Introduction"
weight: 10
type: docs
---

The speedata Publisher creates PDF files fully automatically from XML data.
Layout instructions are kept separate from the data and are written in a programming language specifically designed for this purpose.

![The Publisher creates PDF from XML data and layout rules](/img/xmltopdf-en.svg)

## Typical use cases

* Product catalogs
* Price lists and data sheets
* Travel guides and directories
* Invoices and business documents

Wherever documents need to be generated from structured data — reproducibly, fast and in high quality.

## What makes the Publisher special

**Programmable layouts:** Unlike template-based systems, layout decisions can be made during PDF generation. Queries like "Does this image still fit on the page?" or "How wide is the remaining space?" are possible at any time.

**No GUI, full control:** The Publisher is a command-line tool with no graphical interface. All instructions are defined before the run. This makes the process reproducible and automatable — ideal for integration into existing workflows and CI/CD pipelines.

**Typographic quality:** The Publisher uses the same typesetting technology as TeX/LaTeX (LuaTeX), achieving output quality otherwise reserved for interactive DTP programs like InDesign.

## Get started

```shell
$ sp new helloworld
$ cd helloworld
$ sp
```

Three commands, and you have your first PDF. A detailed walkthrough is in the [Hello World]({{< relref "helloworld" >}}) chapter, installation and configuration in [Getting Started]({{< relref "setup" >}}).

## Examples

The [speedata showcase](https://www.speedata.de/en/#showcase) features examples of real-world documents.
On GitHub you can find a [sample repository](https://github.com/speedata/examples) with complete, runnable projects to try out.

![Examples from the repository](/img/beispiele.png)
