title: Default settings in the speedata Publisher
---

Default settings in the speedata Publisher
==========================================

The speedata Publisher defines some default settings that can be changed in the layout file. These defaults concern the colors, fonts and page size and margins.

Fonts
-----

The distribution includes the free font family TeXGyreHeros, a high quality clone of Helvetica. It comes in the variants regular, bold, italic and bolditalic. It is defined as follows:


    <LoadFontfile name="TeXGyreHeros-Regular" filename="texgyreheros-regular.otf" />
    <LoadFontfile name="TeXGyreHeros-Bold" filename="texgyreheros-bold.otf" />
    <LoadFontfile name="TeXGyreHeros-Italic" filename="texgyreheros-italic.otf" />
    <LoadFontfile name="TeXGyreHeros-BoldItalic" filename="texgyreheros-bolditalic.otf" />


The corresponding font family is defined as:

    <DefineFontfamily name="text" fontsize="10" leading="12">
      <Regular fontface="TeXGyreHeros-Regular"/>
      <Bold fontface="TeXGyreHeros-Bold"/>
      <Italic fontface="TeXGyreHeros-Italic"/>
      <BoldItalic fontface="TeXGyreHeros-BoldItalic"/>
    </DefineFontfamily>


and since the font family named `text` is taken as the default for the paragraphs, without any change the text appears in Helvetica 10pt/12pt. With re-defining the font family `text` you can change the document font.

The font aliases (since version 2.7.12) are defined for the default font:

* `TeXGyreHeros-Regular`  -> `sans`
* `TeXGyreHeros-Bold`  -> `sans-bold`
* `TeXGyreHeros-Italic`  -> `sans-italic`
* `TeXGyreHeros-BoldItalic`  -> `sans-bolditalic`

Textformats
-----------

The following text formats are predefined:

~~~xml
<DefineTextformat name="text" alignment="justified"/>
<DefineTextformat name="centered" alignment="centered" />
<DefineTextformat name="left" alignment="leftaligned"/>
<DefineTextformat name="right" alignment="rightaligned"/>
~~~


Page size and margin
--------------------

The page size defaults to A4 (210mm × 297mm)

The master page for all pages is defined as follows:

    <Pagetype name="Default Page" test="true()">
      <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>
    </Pagetype>

The page grid is set to 10mm × 10mm.

Colors
------

The CSS colors are defined in the RGB colorspace. The colors `black` and `white` are defined in the gray colorspace.

