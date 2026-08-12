---
title: "Structure of the data file"
weight: 31
type: docs
---


<blockquote class="quote">
You can use any data format so long as it is XML.
<cite>— Freely adapted from Henry Ford</cite>
</blockquote>

## Data source: XML - well-formed and structured

The first prerequisite is that the data source is in XML (Extensible Markup Language) format. Other formats are not processed with the Publisher (using the Lua filter, CSV and Excel files can also be processed). In practice, this does not matter because all (structured) data can be converted into XML format.

Often people ask how the data XML must be structured. The answer is simple: there are no specifications, except that the XML must comply with the usual rules (well-formedness). These rules are listed in the glossary.

In addition, there are useful structuring recommendations:

1. The data should appear in the XML tree when it is needed. Data processing in the Publisher costs time and memory, so the information should be available where it is needed. There are of course exceptions. For example, global settings (colors, texts to be translated and so on) can be defined at the beginning of the file.

2. Different representations (variants) must be readable from the data. If, for example, a page change is to occur for a new article group (in the product catalog), a change of article group must be recognizable in the data.

3. The data should be as structured as possible. For example, a product catalog could contain article numbers in the form 123-12345. If the first three digits represent the article group, this could be recognized with regular expressions. It is simpler if the article group is already created in the data structure, so that no recognition is required.

A simple example for the arrangement:

```xml
<productdata>
  <globalsettings>
    ...
  </globalsettings>
  <articlegroup name="interior lights" number="123">
    <article number="123-12345">
      <property1>...</property1>
      <property2>...</property2>
    </article>
    <article number="123-12346">
      <property1>...</property1>
      <property2>...</property2>
    </article>
  </articlegroup>
  <articlegroup name="exterior lights" number="124">
    <article number="124-23456">
      <property1>...</property1>
      <property2>...</property2>
    </article>
    <article number="124-54321">
      <property1>...</property1>
      <property2>...</property2>
    </article>
  </articlegroup>
</productdata>
```

Redundancy does not hurt here, on the contrary. Since the article group in the example has a clear sequence of digits (123 or 124), the last five digits would be sufficient for the articles. You can assemble the number from `articlegroup/@number`, - and `article/@number` yourself. To save yourself the step, simply save the complete number on the article.

To summarize it: If you have the possibility to influence the structure of the data: better save too much information than too little. Experiment with the order of the data, sometimes the right structure makes layout creation much easier.

## How do you access the data from the layout?

Processing the data file is the job of the layout: `<Record>` defines processing rules for the data elements, `<ProcessNode>` and `<ForAll>` descend into the child elements, and XPath expressions such as `@nr` or `description` access the attributes and child elements of the current element.
The chapter [Programming]({{< relref "programming" >}}) describes this interplay step by step; the expressions themselves are explained in the [XPath reference]({{< relref "/reference/xpath/xpath" >}}).
