---
title: "HTML"
weight: 75
type: docs
---


The speedata Publisher can process HTML content and render it to PDF. This chapter describes the different ways to use HTML and the supported features. These features are still under development and the HTML support is continuously being improved.

## Using HTML

There are several ways to include HTML content in your layout:

### Direct HTML in Output

The simplest way is to use the `<HTML>` command directly within `<Output>`:

```xml
<Output>
  <HTML>
    <h1>Heading</h1>
    <p>A paragraph with <b>bold</b> and <i>italic</i> text.</p>
    <ul>
      <li>Item 1</li>
      <li>Item 2</li>
    </ul>
  </HTML>
</Output>
```

### HTML from data with select

HTML content can come from the data file using the `select` attribute:

```xml
<Output>
  <HTML select="content" />
</Output>
```

If the HTML is stored as escaped text (e.g., `&lt;p&gt;`) or in a CDATA section, the `<HTML>` command will parse it correctly.

### HTML in Paragraph

HTML can also be used within `<Paragraph>` elements in a `<Textblock>` or `<Text>`. This is useful when you want to mix HTML with other Publisher elements:

```xml
<Record element="Paragraph">
  <PlaceObject>
    <Textblock>
      <Paragraph>
        <Value select="sd:decode-html(.)" />
      </Paragraph>
    </Textblock>
  </PlaceObject>
</Record>
```

With data containing HTML in CDATA:

```xml
<Paragraph><![CDATA[<ol><li>First item</li><li>Second item</li></ol>]]></Paragraph>
```

### XPath expansion with expand-text

When using inline HTML, you can include XPath expressions using curly braces with `expand-text="yes"`:

```xml
<Output>
  <HTML expand-text="yes">
    <p>Article <b>{@nr}</b> costs {$price} Euro.</p>
  </HTML>
</Output>
```

Use `{{` and `}}` for literal curly braces.

## Supported HTML elements

The following HTML elements are supported:

* Headings: `<h1>` to `<h6>`
* Paragraphs: `<p>`
* Text formatting: `<b>`, `<i>`, `<u>`, `<code>`, `<kbd>`, `<span>`
* Links: `<a href="...">`
* Lists: `<ul>`, `<ol>`, `<li>`
* Tables: `<table>`, `<thead>`, `<tbody>`, `<tr>`, `<th>`, `<td>`
* Line breaks: `<br>`

## CSS Styling

HTML elements can be styled using CSS. You can include CSS via the `<Stylesheet>` command:

```xml
<Stylesheet>
  h1 { color: blue; font-size: 24pt; }
  p { margin-bottom: 12pt; }
  .highlight { background-color: yellow; }
</Stylesheet>
```

Or load CSS from a file:

```xml
<Stylesheet filename="styles.css" />
```

### Supported CSS properties

The speedata Publisher supports a subset of CSS properties, including font, text and box model properties, background colors as well as list and break control.
The complete list can be found in the chapter [Using CSS]({{< relref "css" >}}); the implementation status of individual properties is shown in the [test status](#test-status).

## Lists in HTML

HTML lists (`<ul>`, `<ol>`, `<li>`) are supported. The list indentation is controlled via `padding-left` on `<ul>` or `<ol>`. The list marker (bullet, number) is placed within the indentation area.

### Marker styling with `::marker`

The CSS pseudo-element `li::marker` can be used to style the list marker. The following properties are supported:

* `content` – Custom marker text (e.g. `content: "→"`)
* `color` – Marker color
* `font-family` – Marker font family
* `font-size` – Marker font size
* `padding-right` – Gap between marker and text (default: 5pt)
* `padding-bottom` – Vertical shift of the marker upwards

### Example

```xml
<Stylesheet>
  ul { padding-left: 14pt; }
  li::marker { color: red; padding-right: 2pt; }
</Stylesheet>
```

This renders the bullet in red and reduces the gap between marker and text to 2pt.

## Tables in HTML

HTML tables are fully supported including headers and footers that repeat on page breaks:

```xml
<HTML>
  <table>
    <thead>
      <tr><th>Name</th><th>Price</th></tr>
    </thead>
    <tbody>
      <tr><td>Product A</td><td>10.00</td></tr>
      <tr><td>Product B</td><td>20.00</td></tr>
    </tbody>
  </table>
</HTML>
```

Tables can span multiple pages, with the `<thead>` content repeating at the top of each page.

## Test Status

In the repository, there is a set of HTML/CSS tests under `qa/htmloutput` that verify the various features and their support in the speedata Publisher.

### Working

* [*break-after*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/break-after) – Page breaks after HTML elements
* [*break-before*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/break-before) – Page breaks before HTML elements
* [*color*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/color) – Text color rendering with different color formats
* [*font-style-weight*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/font-style-weight) – Font style (italic) and font weight (bold) rendering and combinations
* [*list-style-type*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/list-style-type) – Various list marker types (disc, circle, square, decimal, alpha, roman) (may require font with corresponding glyphs)
* [*table-border*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/table-border) – Table cell borders and various formatting options
* [*table-border-collapse*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/table-border-collapse) – Differences between border-collapse separate and collapse modes
* [*tablebreak*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/tablebreak) – Multi-page table rendering with repeating table header
* [*text-align*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/text-align) – Text alignment options (left, right, center, justify)
* [*vertical-align*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/vertical-align) – Superscript and subscript rendering (*check: font size*)
* [*white-space*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/white-space) – White-space handling (normal, pre)

### Partially Working

Tests that pass but may need improvements:

* [*border-color*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/border-color) – Border color rendering with individual side colors and currentcolor support
* [*border-radius*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/border-radius) – Border radius rendering with uniform and individual corner radius values
* [*border-shorthand*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/border-shorthand) – Border shorthand property with various styles, widths, and colors
* [*border-width*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/border-width) – Border width rendering in different units and with individual values per side
* [*box-margin*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/box-margin) – Margin rendering with shorthand notation and individual values per side
* [*box-padding*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/box-padding) – Padding rendering with shorthand notation and individual values per side
* [*font-size*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/font-size) – Various font size units (pt, px, em, rem, %, keywords). *Top margin on 2nd page is too small.*
* [*list-style-position*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/list-style-position) – List marker position (outside, inside). *Markers are probably not correctly positioned.*
* [*text-decoration*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/text-decoration) – Text decoration (underline, line-through, various styles and colors). *Only underline is supported.*

### Broken

Tests that currently don't work correctly:

* [*background-color*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/background-color) – Background color rendering with different color formats (named colors, hex, RGB)
* [*border-style*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/border-style) – Various border styles (none, solid, dashed, dotted, double, groove, ridge, inset, outset)
* [*box-width-height*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/box-width-height) – Width and height rendering with percentage, pixel, and em units
* [*line-height*](https://github.com/speedata/publisher/tree/develop/qa/htmloutput/line-height) – Various line height values (normal, numeric, percentage, points)

