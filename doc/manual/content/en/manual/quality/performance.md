---
title: "Performance Considerations"
weight: 68
type: docs
---


When processing large documents or documents with many formatting operations, performance can become an important consideration. This chapter describes various strategies to optimize the typesetting speed of the speedata Publisher.

## HTML Parsing

One of the most significant performance factors is HTML parsing in paragraphs. By default, the Publisher parses HTML tags like `<b>`, `<i>`, `<span>`, etc. in all text content. This parsing happens for every paragraph and can be expensive, especially in documents with many small text blocks.

### Disabling HTML Parsing

If your document does not use HTML formatting tags, you can significantly improve performance by disabling HTML parsing:

#### Global Setting

To disable HTML parsing for the entire document, use the `<Options>` command:

```xml
<Options html="off"/>
```

This can reduce typesetting time by up to 40% in documents with many paragraphs.

#### Local Setting

You can also control HTML parsing on a per-paragraph basis:

```xml
<Paragraph html="off">
  <Value>Text without HTML formatting</Value>
</Paragraph>
```

#### HTML Parsing Modes

The `html` attribute supports three values:

`all`
: Parse HTML in all paragraphs (default behavior).

`inner`
: Parse HTML only in child elements of the current data element.

`off`
: Disable HTML parsing completely. This provides the best performance but HTML tags like `<b>` or `<i>` will not be interpreted.

#### Command Line Option

You can also set the HTML parsing mode from the command line:

```shell
sp --option html=off
```

This is particularly useful for batch processing or testing performance optimizations.

### When to Use html="off"

Consider disabling HTML parsing when:

* Your data contains no HTML formatting tags
* Text formatting is handled entirely through text formats
* You are processing large documents with many paragraphs
* Performance is critical and you don't need inline HTML formatting

### When to Keep HTML Parsing Enabled

Keep HTML parsing enabled when:

* Your data contains HTML tags like `<b>`, `<i>`, `<span>`, etc.
* You need inline formatting within paragraphs
* You are using CSS styles with HTML elements
* Document generation time is not critical

