---
title: "Data preparation: up front or in the layout?"
weight: 10
type: docs
---

This question comes up at the start of every project, and its answer shapes everything that follows: in what form does the data enter the Publisher? The closer the structure of the data file is to the finished document, the simpler the layout rules become. The reverse also holds: whoever takes the raw data from PIM, database or ERP unchanged moves all the restructuring work into the layout.

There are three ways, and they can be combined.

## Way 1: preprocessing with XSLT

XSLT is a language designed precisely for restructuring XML: regrouping, nesting, sorting, merging several source files. The Publisher ships with the XSLT processor Saxon; the transformation is started via a small [Lua filter]({{< relref "preprocessing" >}}):

```lua
runtime = require("runtime")
ok, msg = runtime.run_saxon("transform.xsl", "rawdata.xml", "data.xml")
if not ok then
    print(msg)
    os.exit(-1)
end
```

The call `sp --filter transform.lua` (or the entry `filter=transform.lua` in `publisher.cfg`) runs the script before every run.

The strengths: XSLT can restructure heavily (for example grouping with `for-each-group` or merging sources with `document()`), the transformation can be developed and tested independently of the Publisher, and the result is a file that can be inspected, validated and archived. The price: another language in the project that someone has to know and maintain.

## Way 2: Lua filter

The Lua filter can do more than start Saxon: it is the right way when the source is not XML at all. The built-in modules read CSV, Excel and arbitrary other files, fetch data from an API via HTTP and write the data file for the subsequent run with the `xml` module; validating the input with RELAX NG belongs here as well. The chapter [Lua filter / preprocessing]({{< relref "preprocessing" >}}) describes the possibilities including a function reference; runnable examples are in the [examples repository](https://github.com/speedata/examples/tree/master/technical) (CSV, JSON, Excel).

The strengths: arbitrary data sources and full programming logic, with the same inspectability advantage as XSLT (the result is a file). The price is the same: a programming language in the project.

## Way 3: processing in the layout

The layout rules themselves can sort, filter, group and calculate: XPath expressions select data, [`<ForAll>`]({{< relref "programming" >}}) iterates over element sequences, [`<SortSequence>` and `<Makeindex>`]({{< relref "indexcreation" >}}) sort and group, and structures can be built with variables and `<Copy-of>`. For small jobs this is the shortest way: no additional toolchain, everything in one file.

The price shows up as things grow: complex restructuring in the layout quickly becomes hard to follow, there is no intermediate result to look at when debugging, and the data logic gets mixed up with the design logic.

## How to recognize the right way

* **How much restructuring is needed?** Just sorting, filtering or summing: well placed in the layout. Regrouping, nesting, aggregating over several levels: transform up front.
* **Is the data XML at all?** CSV, Excel, JSON or an API point to the Lua filter.
* **Do several data sources have to be merged?** That belongs in the preprocessing (XSLT with `document()` or Lua), not in the layout.
* **Should the intermediate result be inspectable?** Preprocessing writes a file that can be examined, validated against a schema and archived with a problem report. This is worth gold when debugging; processing in the layout has no such checkpoint.
* **Who maintains the project later?** The best technology is useless if the person taking over knows no XSLT (or no Lua). In practice this question decides more often than any technical one.
* **How often does the data format change?** Frequent format changes favor a cleanly separated, independently testable preprocessing step behind which the layout can stay stable.

<!-- TODO PG: add experience from practice – e.g. typical project trajectories (when did a project switch from way 3 to way 1?), maintainability with customers, orders of magnitude (how many restructuring steps justify XSLT?). -->

## Rule of thumb

The data file should look like the document, not like the database. Everything needed to get there (order, grouping, merging) belongs in the preprocessing. The small jobs (a sort, a filter, a sum) may be done by the layout. And the ways are not mutually exclusive: a Lua filter can first read Excel and then start Saxon, and the layout can still reorder an article list at the end.

How to structure the data file sensibly is described in the section [Structure of the data file]({{< relref "structuredatafile" >}}).
