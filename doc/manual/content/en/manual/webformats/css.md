---
title: "Using CSS with the speedata Publisher"
weight: 74
type: docs
aliases:
  - /en/advancedtopics/css/
---



CSS (Cascading Stylesheets) is a language mainly used on the web to determine the appearance of objects.
The idea is to separate formatting from content.
On the web - at least in theory - the content is described in HTML, while the appearance is determined by CSS.
With the speedata Publisher the separation is even clearer.
The data usually contains no information about the appearance, while the layout rules have no information about the data.

CSS is used in two distinct places in the speedata Publisher, which must be kept apart:

1. **CSS for layout commands:** Paragraphs, text blocks, tables and many other commands in the layout rules take fonts, colors, spacing and alignment from CSS rules.
2. **CSS for HTML content and markup in the data:** Content that is processed via the [`<HTML>`]({{< relref "html" >}}) command or as markup within paragraph contents is formatted with the full HTML processing of the Publisher.

Both paths use the same stylesheets.

## Including stylesheets

A CSS stylesheet can be available and integrated as an external file.
Alternatively, one can write CSS instructions directly into the layout rules.
`<Stylesheet>` is the command for both variants:

```xml
<Stylesheet filename="style.css"/>
```

or

```xml
<Stylesheet>
  td {
    vertical-align: top;
  }
</Stylesheet>
```

## CSS for layout commands {#css-layout}

Many commands in the layout rules can be styled with CSS: paragraphs, text blocks, tables, boxes, rules, lists and some more.
Selectors and the cascade work as in a web browser.
An attribute on the command takes precedence over a CSS rule, so you can keep the defaults in the stylesheet and override them where needed.

A complete example: the box gets its background color from the class `warn`, the paragraph its font size and color from `paragraph.note`.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Stylesheet>
    .warn {
      background-color: red;
    }
    paragraph.note {
      font-size: 8pt;
      color: gray;
    }
  </Stylesheet>

  <Record element="data">
    <PlaceObject>
      <Box class="warn" width="5" height="2"/>
    </PlaceObject>
    <PlaceObject>
      <Textblock>
        <Paragraph class="note"><Value>Small gray text.</Value></Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```

### Element names

In selectors, a command is called by its name in lower case.
Only `<Image>` is called `img`, as in HTML.

| Command | Name in selectors |
|---|---|
| `<Box>`, `<Circle>`, `<Frame>` | `box`, `circle`, `frame` |
| `<Image>` | `img` |
| `<Paragraph>`, `<Span>`, `<U>` | `paragraph`, `span`, `u` |
| `<PlaceObject>` | `placeobject` |
| `<Rule>` | `rule` |
| `<Table>`, `<Tablehead>`, `<Tablefoot>` | `table`, `tablehead`, `tablefoot` |
| `<Tr>`, `<Td>`, `<Tablerule>` | `tr`, `td`, `tablerule` |
| `<Textblock>` | `textblock` |
| `<Ul>`, `<Ol>`, `<Li>` | `ul`, `ol`, `li` |

The reference gives the name in the section “CSS” of each of these commands.
Other commands such as `<Record>`, `<ForAll>`, `<Loop>` or `<Switch>` produce no output and do not appear in selectors.

### Selectors

The selectors from CSS apply, among others:

| Selector | matches |
|---|---|
| `td` | every table cell |
| `.price` | every command with `class="price"`, also with `class="price sale"` |
| `#head` | the command with `id="head"` |
| `td.price` | table cells with the class `price` |
| `table.list td` | cells inside a table with the class `list` |
| `tr > td` | cells directly inside a row |
| `tr:nth-child(even)` | every second table row (see [Tables](#css-tables)) |

For descendant selectors such as `table.list td`, the nesting while the layout is executed counts.
A paragraph in a `<Record>` that is called with `<ProcessNode>` from a table cell is inside the cell (`td paragraph`).

The attributes `class` and `id` can contain XPath expressions in curly braces, so the class can come from the data:

```xml
<Tr class="{if (@sale = 'yes') then 'sale' else ''}">
```

### One stylesheet for layout and HTML

All rules from all `<Stylesheet>` commands apply to layout commands *and* to HTML content.
Some names exist in both worlds, for example `table`, `td`, `span`, `ul` or `img`.
A rule `td { padding: 4pt }` therefore applies to table cells in the layout and in HTML content.

The two root elements keep them apart: layout commands are below the element `layout`, HTML content is below `html`.

```css
layout td { padding: 2pt }   /* only cells from <Td> in the layout */
html td   { padding: 4pt }   /* only cells in HTML content */
td        { color: black }   /* both */
```

### Cascade and precedence

All matching rules apply.
If two rules set the same property, the more specific one wins (an id before a class before an element name); with equal specificity, the rule that comes later in the stylesheet wins.

If a value comes from several places, this order applies, strongest first:

1. A CSS declaration with `!important`.
2. The attribute on the command.
3. The CSS rules for the command itself.
4. Values the command inherits from the surrounding commands (see the next section).
5. The defaults of the Publisher, such as the text format `text` and the font family `text`.

Some attributes stand for several CSS properties.
If the attribute is set, CSS rules and inherited values for these properties do not apply (except with `!important`):

| Attribute | stands for |
|---|---|
| `textformat` | `text-align`, `text-indent`, `margin-top`, `margin-bottom`, `hyphens`, `letter-spacing`, `break-before`, `break-after`, `orphans`, `widows` |
| `fontfamily` | `font-family`, `font-size`, `line-height` |
| `color` | `color` |
| `align` (on `<Tr>` and `<Td>`) | `text-align` |

```xml
<Stylesheet>
  paragraph { color: gray }
  paragraph.important { color: red !important }
</Stylesheet>
…
<Paragraph color="blue">…</Paragraph>                     <!-- blue -->
<Paragraph color="blue" class="important">…</Paragraph>   <!-- red -->
```

### Inheritance

As in CSS, the inner commands inherit font and text properties from the surrounding ones.
The inherited properties are `color`, `font-family`, `font-size`, `font-style`, `font-weight`, `line-height`, `text-align`, `text-indent`, `hyphens`, `letter-spacing`, `orphans` and `widows`.
`<Textblock>`, `<Paragraph>`, `<Table>`, `<Tablehead>`, `<Tablefoot>`, `<Tr>` and `<Td>` pass these values on to their contents.

```xml
<Stylesheet>
  textblock.note { color: gray; font-size: 8pt; text-align: right }
</Stylesheet>
…
<Textblock class="note">
  <Paragraph><Value>gray, 8pt, right aligned</Value></Paragraph>
  <Paragraph color="black"><Value>black, 8pt, right aligned</Value></Paragraph>
</Textblock>
```

Relative values such as `font-size: 1.2em` refer to the font of the surrounding command.
An attribute also replaces the inherited values it stands for: a paragraph with `fontfamily="..."` inherits no font size, and a text block with `textformat="..."` does not pass an alignment from CSS on to its paragraphs.

### Properties of the commands

| Command | CSS properties |
|---|---|
| `paragraph` | `color`, `background-color`, `font-family`, `font-size`, `font-weight`, `font-style`, `line-height`, `text-align`, `text-indent`, `hyphens`, `letter-spacing`, `margin-top`, `margin-bottom`, `break-before`, `break-after`, `orphans`, `widows` |
| `textblock` | the inherited properties (see above) and `width`, `column-count`, `column-gap` |
| `table` | the inherited properties, `padding` and `padding-*` (default for all cells), `border-collapse` |
| `tablehead`, `tablefoot` | the inherited properties |
| `tr` | the inherited properties, `background-color`, `vertical-align` |
| `td` | the inherited properties, `vertical-align`, `background-color`, `padding`, `padding-*`, `border-*-width`, `border-*-color` as well as `background-text` and the other background attributes |
| `tablerule` | `height` (rule width), `background-color` (color), `rule-start` |
| `span` | `background-color`, `background-padding-top`, `background-padding-bottom`, `letter-spacing` |
| `u` | `border-style` (`dashed` for a dashed line) |
| `ul`, `ol` | `color`, `list-style-type`, `list-style-position`, `padding-left`; for the marker `li::marker` with `content`, `color` and `padding-right` |
| `box` | `background-color`, `padding-*` |
| `circle` | `background-color`, `color` (frame color) |
| `frame` | `border-*-radius` |
| `img` | `padding`, `padding-*` |
| `placeobject` | `background-color` |
| `rule` | `height` (rule width), `background-color` (color) |

The command reference notes the name of the CSS property for every attribute that corresponds to one (for example “CSS property: background-color” for `<Box>`).

`font-family` names a font family from [`<DefineFontfamily>`]({{< relref "/reference/commands/definefontfamily" >}}), a font from `@font-face` or [`<LoadFontfile>`]({{< relref "/reference/commands/loadfontfile" >}}), or one of the generic families `serif`, `sans-serif` and `monospace`.
Several names, separated by commas, are tried in order.
With `font-size` or `line-height`, a new font family is created when needed; there is no need to define a matching one first.

```xml
<Stylesheet>
  @font-face { font-family: "Quote"; src: local("CrimsonPro-Regular") }
  @font-face { font-family: "Quote"; font-weight: bold; src: local("CrimsonPro-Bold") }
  paragraph.quote { font-family: Quote, serif; font-size: 11pt; line-height: 14pt }
</Stylesheet>
```

### Tables {#css-tables}

With CSS, the look of a table can be kept apart from its structure.
The commands only contain classes; colors, font and alignment are in the stylesheet:

```xml
<Stylesheet>
  table.prices { font-size: 9pt; padding: 2pt 4pt }
  table.prices tablehead td { color: white; font-weight: bold }
  table.prices tablehead tr { background-color: #37586e }
  table.prices tr:nth-child(even) { background-color: #e6edf1 }
  table.prices td:first-child { font-weight: bold }
  table.prices td:nth-child(5) { text-align: right }
  table.prices tr.sale { color: #a33a2a }
</Stylesheet>
```

![A price list that takes its look from CSS](/img/css-zebratable.png)

Rows and cells know the pseudo classes `:first-child` and `:nth-child()` with `even`, `odd` and formulas such as `3n+1`:

* For `tr`, the position of the row counts.
  The rows in the table head, the table foot and the body are counted separately, so the zebra stripes in the body start independently of the head.
* For `td`, the position of the cell in the row counts.
  A cell with `colspan` counts once, as in HTML.
* `:last-child` and `:nth-last-child()` have no effect, because the following rows and cells are not known yet when a command is evaluated.
  Commands other than `<Tr>` and `<Td>` do not know their position.

The position refers to the whole table, not to the page: when the table breaks, the zebra stripes continue on the next page.
To restart them on every page, use `sd:alternating()` with `eval-on-split` (see [Alternating line colors]({{< relref "/manual/tables#alternating-line-colors" >}})).
A table head that is evaluated again on every page keeps the rules of the table.

The complete example is in the [examples repository](https://github.com/speedata/examples/tree/master/technical/csstable).

## CSS for HTML content and markup in the data

HTML content (see the chapter [HTML]({{< relref "html" >}})) and paragraph contents with markup are typeset internally by the same HTML machinery.
The included stylesheets therefore also apply to this content.

Text markup in the data works as follows:

```xml
<p>Text, Text, Text <b>bold</b>, Text Text</p>
```

The Publisher will ensure that the text within the 'b' element appears in bold.

You can also add CSS styles to your own elements.
For example, if you have the following data

```xml
<data>hello <green>green</green> world</data>
```

you can use CSS to color the element:

```xml
<Layout
  xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Stylesheet>
    green {
      color: green;
    }
  </Stylesheet>

  <Record element="data">
    <PlaceObject>
      <Textblock>
        <Paragraph>
          <Value select="."/>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```

![Elements in data can now be colored](/img/32-hellogreenworld.png)

Besides the color, other properties can be set this way, for example `font-weight: bold`, `font-style: italic`, `text-decoration: underline` and `background-color`.
The font of the paragraph remains authoritative: `font-family` and `font-size` only take effect in paragraph contents if the text format in use has `cssfontsize="yes"` set (see [`<DefineTextformat>`]({{< relref "/reference/commands/definetextformat" >}})).

### Supported CSS properties

The following properties are evaluated by the HTML processing:

* Font: `font-family`, `font-size`, `font-style`, `font-weight`
* Text: `color`, `text-align`, `text-decoration` (or `text-decoration-line` with `underline` and `line-through`, `text-decoration-style` with `solid`, `double`, `dotted`, `dashed` and `wavy`, `text-decoration-color`), `line-height`, `white-space` (`normal`, `pre`), `vertical-align` (`super`, `sub`) and `hyphens` (`none` or `manual` turns off hyphenation)
* Box model: `margin-*`, `padding-*`, `border-*` (width, style and color per side plus `border-radius` per corner), `width`, `height`
* Background: `background-color`
* Lists: `list-style-type`, `list-style-position`, `list-style` and the pseudo-element `li::marker` (`content`, `color`, `font-family`, `font-size`, `padding-right`, `padding-bottom`)
* Tables: `border-collapse`
* Breaks: `break-before`, `break-after`

Not every property is fully implemented in every situation.
The current state of individual properties is documented in the [test status in the HTML chapter]({{< relref "html#test-status" >}}).
