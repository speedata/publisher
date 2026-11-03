---
title: "Icons from an icon font"
weight: 35
type: docs
---

## Task

A product range overview is to show symbols: a house or a sun marks whether a product group is suitable for indoor use only or for outdoor use as well. In addition, there are descriptions from the web shop into which the editors have already put icons, using the markup of Font Awesome (`<i class="fa-solid fa-truck-fast"></i>`). The symbols come from an icon font, here Font Awesome Free.

![Every property line starts with a house or a sun; the descriptions from the web shop show a delivery truck, a check mark and a red warning triangle.](/img/howto-icons-en.png)

## Decision

An icon font is an ordinary font file whose characters are symbols. The symbols are usually in the Unicode Private Use Area (U+E000 to U+F8FF); in Font Awesome, for example, the house has the code U+F015. The codes are listed in the vendor's icon overview or in the stylesheet that comes with the font (`.fa-house::before { content: "\f015" }`).

How a symbol gets into the text depends on where it is decided which symbol appears:

| Where is it decided which symbol appears? | Way |
|---|---|
| The layout chooses the symbol based on the data, for example by an attribute. | A font family with the icon font, switched to with `<Fontface>` in the paragraph |
| The data contains HTML with classes, for example from a web shop or a content management system. | A stylesheet with `::before` rules, as in the browser |
| The character itself is in the data (`&#xf015;`). | The icon font as a replacement font (`<Fallback>`) of the text font |

* **Font family with `<Fontface>`**: The layout keeps full control. The mapping from data value to symbol is in an XPath expression, and the data stays free of symbol codes. The font family has a fixed size; symbols in headings need a second family in the heading size.
* **Stylesheet with `::before`**: The data stays unchanged, and the classes become symbols as in the browser. This is the way for content that comes from web applications. The symbol takes the size of the surrounding text.
* **Replacement font**: Only the font definition in the layout changes. Every character missing from the text font is looked up in the icon font. This fits when an upstream process already writes the codes into the data. The data then contains codes that only make sense together with exactly this icon font.

The first two ways can be combined; the example below uses both.

## Solution

### The data

The product groups of Confixa get two additions: the attribute `use` says whether a group is suitable for indoor use only (`indoor`) or for outdoor use as well (`outdoor`), and `description` contains the description from the web shop, as it is maintained there.

```xml
<data company="Confixa">
  <group name="Chipboard screws" code="CS" material="steel, zinc plated" use="indoor">
    <description>For chipboard, softwood and hardwood. <i class="fa-solid fa-truck-fast"></i> Ships within 24 hours.</description>
  </group>
  <group name="Wall plugs" code="WP" material="nylon" use="outdoor">
    <description>For concrete, brick and natural stone. <i class="fa-regular fa-circle-check"></i> Approved for facades.</description>
  </group>
  <group name="Wedge anchors" code="WA" material="steel, zinc plated" use="indoor">
    <description>For heavy loads in concrete. <i class="fa-solid fa-triangle-exclamation"></i> Not for cracked concrete.</description>
  </group>
</data>
```

### Step 1: the font files

Font Awesome Free is available at [fontawesome.com](https://fontawesome.com/download). In the directory `webfonts`, the package contains among others `fa-solid-900.ttf` (filled symbols) and `fa-regular-400.ttf` (outlined symbols, only a selection in the free version). Put the two files into the project directory or a subdirectory of it, where the Publisher finds them. The fonts are licensed under the SIL Open Font License; embedding them in the PDF is allowed without restriction.

From version 7 on, the web package only contains files in the WOFF2 format, which the Publisher cannot read. Use the desktop package (`fontawesome-free-7.x-desktop.zip`) instead; its directory `otfs` contains the files `Font Awesome 7 Free-Solid-900.otf` and `Font Awesome 7 Free-Regular-400.otf`. In the examples below, use their names instead of `fa-solid-900.ttf` and `fa-regular-400.ttf`, for example `src: url("Font Awesome 7 Free-Solid-900.otf")`.

### Step 2: symbols from the layout

For the first way, the icon font is loaded and defined as a font family in the size of the body text:

```xml
<LoadFontfile name="fa-solid" filename="fa-solid-900.ttf"/>
<DefineFontfamily name="icons" fontsize="10" leading="12">
  <Regular fontface="fa-solid"/>
</DefineFontfamily>
```

In the paragraph, [`<Fontface>`]({{< relref "/reference/commands/fontface" >}}) switches to this family for the symbol. An XPath expression decides which symbol appears, based on the attribute `use`:

```xml
<Paragraph>
  <Fontface fontfamily="icons">
    <Value select="if (@use = 'outdoor') then '&#xf185;' else '&#xf015;'"/>
  </Fontface>
  <Value select="if (@use = 'outdoor') then ' Indoor and outdoor' else ' Indoor only'"/>
  <Value select="concat(' · ', @material)"/>
</Paragraph>
```

The character references `&#xf185;` (sun) and `&#xf015;` (house) are already resolved by the XML parser, so the XPath expression contains the characters themselves. With many different symbols the expression gets long; then a mapping table in the data or in a separate file is easier to maintain.

### Step 3: symbols from the web shop

For the second way, the icon font is declared with `@font-face` in the stylesheet, both faces under one name. The font weight distinguishes the faces, just as in the Font Awesome stylesheet:

```xml
<Stylesheet>
  @font-face { font-family: "FA"; font-weight: 400; src: url("fa-regular-400.ttf"); }
  @font-face { font-family: "FA"; font-weight: 900; src: url("fa-solid-900.ttf"); }
  .fa-solid, .fa-regular { font-family: "FA"; font-style: normal; }
  .fa-solid { font-weight: 900; }
  .fa-regular { font-weight: 400; }
  .fa-truck-fast::before { content: "\f48b"; }
  .fa-circle-check::before { content: "\f058"; }
  .fa-triangle-exclamation::before { content: "\f071"; color: red; }
</Stylesheet>
```

* The classes `fa-solid` and `fa-regular` select font and face. `font-style: normal` is needed because `<i>` sets italic text otherwise, and the icon font has no italic face.
* A `::before` rule creates the character for every symbol used. Other properties such as the color can be set in the same rule.

The description is then output like any other text with markup:

```xml
<Paragraph>
  <Value select="description"/>
</Paragraph>
```

The symbol appears in the size of the paragraph. If the same description is set in a larger font, the symbol grows with it.

Instead of a stylesheet of your own, you can also include the complete Font Awesome stylesheet. If the directories `css` and `webfonts` from the package are in the project directory, `<Stylesheet filename="css/all.css"/>` is enough; the Publisher finds the font files from the `@font-face` rules by their names. With version 7, these rules refer to the files in the WOFF2 format. A second stylesheet after it switches them to the files from the desktop package:

```css
@font-face { font-family: "Font Awesome 7 Free"; font-weight: 900; src: url("Font Awesome 7 Free-Solid-900.otf"); }
@font-face { font-family: "Font Awesome 7 Free"; font-weight: 400; src: url("Font Awesome 7 Free-Regular-400.otf"); }
@font-face { font-family: "Font Awesome 7 Brands"; font-weight: 400; src: url("Font Awesome 7 Brands-Regular-400.otf"); }
```

The complete stylesheet is about 140 KB, though, and describes more than 1800 symbols. A short stylesheet of your own with only the symbols you use is easier to keep track of and shows at a glance which classes may appear in the data.

### Variant: replacement font

If the characters are already in the data, it is enough to load the text font again with the icon font as a replacement font. For the default font TeX Gyre Heros, this looks like this:

```xml
<LoadFontfile name="TeXGyreHeros-Regular" filename="texgyreheros-regular.otf">
  <Fallback filename="fa-solid-900.ttf"/>
</LoadFontfile>
```

After that, all font families that use this font look up missing characters in the icon font, including the predefined family `text`. For bold or italic text, this only applies if that face (such as `TeXGyreHeros-Bold`) is also loaded with the replacement font. More about replacement fonts is in the section [Missing characters and replacement fonts]({{< relref "/manual/text/fonts#missing-characters-and-replacement-fonts" >}}).

### Complete example

The runnable project, including the font files, is also available in the [examples repository](https://github.com/speedata/examples/tree/master/manual/icons).

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Pageformat width="120mm" height="70mm"/>
  <Margin left="10mm" right="10mm" top="10mm" bottom="10mm"/>

  <DefineFontfamily name="head" fontsize="12" leading="14">
    <Regular fontface="sans-bold"/>
  </DefineFontfamily>
  <DefineTextformat name="grouphead" margin-top="8pt" break-below="no"/>

  <!-- Way 1: the icon font as a font family for the layout -->
  <LoadFontfile name="fa-solid" filename="fa-solid-900.ttf"/>
  <DefineFontfamily name="icons" fontsize="10" leading="12">
    <Regular fontface="fa-solid"/>
  </DefineFontfamily>

  <!-- Way 2: the icon classes from the web shop -->
  <Stylesheet>
    @font-face { font-family: "FA"; font-weight: 400; src: url("fa-regular-400.ttf"); }
    @font-face { font-family: "FA"; font-weight: 900; src: url("fa-solid-900.ttf"); }
    .fa-solid, .fa-regular { font-family: "FA"; font-style: normal; }
    .fa-solid { font-weight: 900; }
    .fa-regular { font-weight: 400; }
    .fa-truck-fast::before { content: "\f48b"; }
    .fa-circle-check::before { content: "\f058"; }
    .fa-triangle-exclamation::before { content: "\f071"; color: red; }
  </Stylesheet>

  <Record element="data">
    <PlaceObject>
      <Textblock>
        <ForAll select="group">
          <Paragraph fontfamily="head" textformat="grouphead">
            <Value select="@name"/>
          </Paragraph>
          <Paragraph>
            <Fontface fontfamily="icons">
              <Value select="if (@use = 'outdoor') then '&#xf185;' else '&#xf015;'"/>
            </Fontface>
            <Value select="if (@use = 'outdoor') then ' Indoor and outdoor' else ' Indoor only'"/>
            <Value select="concat(' · ', @material)"/>
          </Paragraph>
          <Paragraph>
            <Value select="description"/>
          </Paragraph>
        </ForAll>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```

## Limits

* **Missing symbols:** the regular face of the free version contains only part of the symbols. If a symbol is missing, the Publisher reports a missing character, as with any font.
* **Meaning in the text:** in the PDF, the symbols are characters from the Unicode Private Use Area. When copied or read aloud by a screen reader, they make no sense. What a symbol means should therefore also be in the text, as “Indoor only” here.
* **Multicolored symbols:** icon fonts like Font Awesome have one color per character. For multicolored symbols or logos, images in SVG or PDF format with [`<Image>`]({{< relref "/reference/commands/image" >}}) are the better way.
