---
title: "Using CSS with the speedata Publisher"
weight: 74
type: docs
---



CSS (Cascading Stylesheets) is a language mainly used on the web to determine the appearance of objects.
The idea is to separate formatting from content.
On the web - at least in theory - the content is described in HTML, while the appearance is determined by CSS.
With the speedata Publisher the separation is even clearer.
The data usually contains no information about the appearance, while the layout rules have no information about the data.

CSS is used in two distinct places in the speedata Publisher, which must be kept apart:

1. **CSS for layout commands:** Some commands in the layout rules can take their attribute values from CSS rules. This path is deliberately kept rudimentary.
2. **CSS for HTML content and markup in the data:** Content that is processed via the [`<HTML>`]({{< relref "html" >}}) command or as markup within paragraph contents is formatted by the Publisher with a much larger set of CSS properties.

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

## CSS for layout commands

Currently the commands `<Box>`, `<Circle>`, `<Frame>`, `<Image>`, `<PlaceObject>`, `<Rule>`, `<Span>`, `<Tablerule>`, `<Td>`, `<Tr>` and `<U>` can be formatted via CSS.
The [command reference]({{< relref "/reference" >}}) shows which properties a command understands: each attribute that can be addressed via CSS is annotated with its CSS property name (for example “CSS property: background-color” for the command `<Box>`).

{{< callout >}}
The CSS support for layout commands has more the character of a "proof of concept" or prototype. The commands and properties that can be controlled this way are very limited.
{{< /callout >}}

A complete example: the box gets its background color via the class `warn`.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Stylesheet>
    .warn {
      background-color: red;
    }
  </Stylesheet>

  <Record element="data">
    <PlaceObject>
      <Box class="warn" width="5" height="2"/>
    </PlaceObject>
  </Record>
</Layout>
```

### Selectors

As known from HTML, the CSS instructions are assigned to certain elements with so-called selectors.

```xml
<Table>
  <Tr minheight="4">
    <Td class="myclass" id="myid">
      <Paragraph>
        <Value>Hello World</Value>
      </Paragraph>
    </Td>
  </Tr>
</Table>
```

The table cell in the example above could be accessed via the following selectors:

```css
#myid {
  vertical-align: top ;
}
```

```css
.myclass {
  vertical-align: top ;
}
```

and

```css
td {
  vertical-align: top ;
}
```

The first case is via the 'id' attribute, which must be unique in the layout rules.
The second case is addressed via the class `class="..."`.
The class can be the same for several elements in the layout set of rules.
The third case refers to all elements 'Td' in the layout set of rules.
The element name in the selector is the lowercase command name (`td` for `<Td>`, `u` for `<U>`); only the command `<Image>` is addressed via `img`, as in HTML.
Here the usual specificity rules for CSS apply, but `!important` is not supported.

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
* Text: `color`, `text-align`, `text-decoration` (or `text-decoration-line`, `text-decoration-style`, `text-decoration-color`), `line-height`, `white-space` (`normal`, `pre`), `vertical-align` (`super`, `sub`) and `hyphens` (`none` or `manual` turns off hyphenation)
* Box model: `margin-*`, `padding-*`, `border-*` (width, style and color per side plus `border-radius` per corner), `width`
* Background: `background-color`
* Lists: `list-style-type`, `list-style-position`, `list-style` and the pseudo-element `li::marker` (`content`, `color`, `font-family`, `font-size`, `padding-right`, `padding-bottom`)
* Tables: `border-collapse`
* Breaks: `break-before`, `break-after`

Not every property is fully implemented in every situation; for example, only `underline` is currently drawn for `text-decoration`.
The current state of individual properties is documented in the [test status in the HTML chapter]({{< relref "html#test-status" >}}).
